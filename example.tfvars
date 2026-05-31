# -----------------------------------------------
# Example variable values
# Copy this to terraform.tfvars and fill in your values
# DO NOT commit terraform.tfvars to GitHub
# -----------------------------------------------

aws_region          = "us-east-1"
environment         = "production"
project_name        = "cfd-aerospace"
vpc_cidr            = "10.0.0.0/16"
private_subnet_cidr = "10.0.1.0/24"
availability_zone   = "us-east-1a"

# HPC instance — change to smaller instance for testing
# instance_type = "t3.micro"    # for testing only
instance_type = "hpc7a.48xlarge"  # production CFD

static_private_ip = "10.0.1.100"

# Restrict SSH to your IP — replace with your IP/32
admin_cidr = "YOUR_IP/32"

# Storage
root_volume_size       = 100
scratch_volume_size    = 1000
checkpoint_volume_size = 500
scratch_iops           = 64000

# Alerts
alarm_email = "your-email@example.com"

# Checkpoint interval in minutes
checkpoint_interval_minutes = 30
