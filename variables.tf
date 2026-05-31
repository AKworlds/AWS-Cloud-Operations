variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name used for resource tagging"
  type        = string
  default     = "cfd-aerospace"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability zone for HPC instance (hpc7a only available in specific AZs)"
  type        = string
  default     = "us-east-1a"
}

variable "instance_type" {
  description = "EC2 instance type for CFD workloads"
  type        = string
  default     = "hpc7a.48xlarge"
}

variable "static_private_ip" {
  description = "Static private IP for the HPC instance"
  type        = string
  default     = "10.0.1.100"
}

variable "admin_cidr" {
  description = "CIDR block allowed SSH access — restrict to your IP"
  type        = string
  default     = "10.0.0.0/8"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 100
}

variable "scratch_volume_size" {
  description = "Scratch volume size in GB for active simulation data"
  type        = number
  default     = 1000
}

variable "checkpoint_volume_size" {
  description = "Checkpoint volume size in GB for recovery snapshots"
  type        = number
  default     = 500
}

variable "scratch_iops" {
  description = "IOPS for scratch volume (io2 Block Express)"
  type        = number
  default     = 64000
}

variable "alarm_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  default     = "ops@example.com"
}

variable "checkpoint_interval_minutes" {
  description = "How often checkpoints run in minutes"
  type        = number
  default     = 30
}
