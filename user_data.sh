#!/bin/bash
# -----------------------------------------------
# User Data Bootstrap Script
# Amazon Linux 2023 — FIPS 140-2 mode
# CFD Aerospace Simulation Environment
# -----------------------------------------------

set -e
exec > >(tee /var/log/user-data.log) 2>&1
echo "Bootstrap started: $(date)"

# -----------------------------------------------
# 1. ENABLE FIPS 140-2 MODE
# Required for ITAR/DFARS compliance
# -----------------------------------------------
echo "Enabling FIPS 140-2 mode..."
fips-mode-setup --enable
echo "FIPS mode enabled"

# -----------------------------------------------
# 2. SYSTEM UPDATES
# -----------------------------------------------
dnf update -y
dnf install -y \
  amazon-cloudwatch-agent \
  amazon-ssm-agent \
  nvme-cli \
  htop \
  sysstat

# -----------------------------------------------
# 3. FORMAT AND MOUNT VOLUMES
# -----------------------------------------------
echo "Configuring storage volumes..."

# Wait for volumes to attach
sleep 10

# Scratch volume — high IOPS simulation data
if [ -b /dev/xvdb ]; then
  mkfs.xfs -f /dev/xvdb
  mkdir -p /scratch
  mount /dev/xvdb /scratch
  echo "/dev/xvdb /scratch xfs defaults 0 0" >> /etc/fstab
  chmod 1777 /scratch
  echo "Scratch volume mounted at /scratch"
fi

# Checkpoint volume — recovery snapshots
if [ -b /dev/xvdc ]; then
  mkfs.xfs -f /dev/xvdc
  mkdir -p /checkpoint
  mount /dev/xvdc /checkpoint
  echo "/dev/xvdc /checkpoint xfs defaults 0 0" >> /etc/fstab
  chmod 755 /checkpoint
  echo "Checkpoint volume mounted at /checkpoint"
fi

# -----------------------------------------------
# 4. CLOUDWATCH AGENT
# -----------------------------------------------
echo "Configuring CloudWatch Agent..."
amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c ssm:/cloudwatch-agent/${project_name}/config \
  -s

systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent
echo "CloudWatch Agent started"

# -----------------------------------------------
# 5. SYSTEMS MANAGER AGENT
# -----------------------------------------------
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent
echo "SSM Agent started"

# -----------------------------------------------
# 6. CHECKPOINT SERVICE
# Runs every ${checkpoint_interval} minutes
# Limits data loss to ${checkpoint_interval} minutes
# -----------------------------------------------
echo "Configuring checkpoint service..."
mkdir -p /opt/scripts
mkdir -p /var/log/simulation

cat > /opt/scripts/checkpoint.sh << 'CHECKPOINT'
#!/bin/bash
# Simulation checkpoint script
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
CHECKPOINT_DIR="/checkpoint"
S3_BUCKET="${checkpoint_bucket}"
LOG_FILE="/var/log/simulation/checkpoint.log"

echo "[$TIMESTAMP] Starting checkpoint..." >> $LOG_FILE

# Sync checkpoint volume to S3 (encrypted via KMS)
if aws s3 sync $CHECKPOINT_DIR s3://$S3_BUCKET/checkpoints/$TIMESTAMP/ \
  --sse aws:kms \
  --no-progress \
  >> $LOG_FILE 2>&1; then
  echo "[$TIMESTAMP] Checkpoint complete" >> $LOG_FILE
else
  echo "[$TIMESTAMP] Checkpoint FAILED" >> $LOG_FILE
  # Send CloudWatch metric for failed checkpoint
  aws cloudwatch put-metric-data \
    --namespace "CFD/${project_name}" \
    --metric-name "CheckpointFailure" \
    --value 1 \
    --unit Count
fi
CHECKPOINT

chmod +x /opt/scripts/checkpoint.sh

# Cron job — every ${checkpoint_interval} minutes
echo "*/${checkpoint_interval} * * * * root /opt/scripts/checkpoint.sh" \
  > /etc/cron.d/simulation-checkpoint

echo "Checkpoint service configured (every ${checkpoint_interval} minutes)"

# -----------------------------------------------
# 7. SYSTEM TUNING FOR CFD WORKLOADS
# -----------------------------------------------
echo "Applying HPC system tuning..."

# Increase file descriptor limits
cat >> /etc/security/limits.conf << 'EOF'
*    soft nofile 65536
*    hard nofile 65536
*    soft nproc  65536
*    hard nproc  65536
EOF

# Network tuning for EFA
cat >> /etc/sysctl.conf << 'EOF'
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
EOF
sysctl -p

echo "HPC tuning applied"

# -----------------------------------------------
# 8. AUDIT LOGGING
# ITAR/DFARS: log all user activity
# -----------------------------------------------
systemctl enable auditd
systemctl start auditd

# Log all authentication events
cat >> /etc/audit/rules.d/audit.rules << 'EOF'
-w /var/log/lastlog -p wa -k logins
-w /var/run/faillock/ -p wa -k logins
-w /etc/passwd -p wa -k identity
-w /etc/sudoers -p wa -k identity
EOF

service auditd restart
echo "Audit logging configured"

echo "Bootstrap complete: $(date)"
echo "Environment ready for CFD simulations"
