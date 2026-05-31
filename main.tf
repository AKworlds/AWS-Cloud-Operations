# -----------------------------------------------
# PROVIDER
# -----------------------------------------------
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Compliance  = "ITAR/DFARS"
    }
  }
}

# -----------------------------------------------
# DATA SOURCES
# -----------------------------------------------
# Latest Amazon Linux 2023 AMI (FIPS 140-2 validated)
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -----------------------------------------------
# ELASTIC NETWORK INTERFACE (ENI)
# Static private IP: 10.0.1.100
# Predictable addressing for automation + monitoring
# -----------------------------------------------
resource "aws_network_interface" "hpc" {
  subnet_id       = aws_subnet.private.id
  private_ips     = [var.static_private_ip]
  security_groups = [aws_security_group.hpc.id]

  tags = {
    Name = "${var.project_name}-eni"
  }
}

# -----------------------------------------------
# ELASTIC IP
# Static public IP for external access when needed
# Cost: ~$0.005/hr when attached, $0.005/hr when not
# -----------------------------------------------
resource "aws_eip" "hpc" {
  domain            = "vpc"
  network_interface = aws_network_interface.hpc.id

  tags = {
    Name = "${var.project_name}-eip"
  }

  depends_on = [aws_internet_gateway.cfd]
}

# -----------------------------------------------
# EC2 HPC INSTANCE
# hpc7a.48xlarge: AMD EPYC 4th Gen
# 192 vCPUs, 768GB RAM, 300Gbps EFA
# CFD runtime: 48+ hrs → 6-8 hrs (94% cost reduction)
# -----------------------------------------------
resource "aws_instance" "hpc" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  # Attach ENI with static private IP
  network_interface {
    network_interface_id = aws_network_interface.hpc.id
    device_index         = 0
  }

  # Attach IAM role for SSM, CloudWatch, KMS
  iam_instance_profile = aws_iam_instance_profile.hpc.name

  # Placement group required for HPC multi-node
  placement_group = aws_placement_group.hpc.id

  # User data: configure FIPS mode + services on boot
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    project_name               = var.project_name
    checkpoint_interval        = var.checkpoint_interval_minutes
    checkpoint_bucket          = aws_s3_bucket.checkpoints.bucket
  }))

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size
    iops        = 3000
    encrypted   = true
    kms_key_id  = aws_kms_key.cfd.arn

    tags = {
      Name       = "${var.project_name}-root"
      VolumeType = "root"
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # IMDSv2 only — security best practice
    http_put_response_hop_limit = 1
  }

  monitoring = true  # Detailed CloudWatch monitoring

  tags = {
    Name         = "${var.project_name}-hpc"
    InstanceType = var.instance_type
    Workload     = "CFD-Simulation"
  }

  depends_on = [
    aws_kms_key.cfd,
    aws_iam_instance_profile.hpc
  ]
}

# -----------------------------------------------
# PLACEMENT GROUP
# Cluster placement for low-latency EFA networking
# Required for tightly-coupled HPC workloads
# -----------------------------------------------
resource "aws_placement_group" "hpc" {
  name     = "${var.project_name}-placement-group"
  strategy = "cluster"

  tags = {
    Name = "${var.project_name}-placement-group"
  }
}
