# -----------------------------------------------
# OUTPUTS
# Values displayed after terraform apply
# -----------------------------------------------

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.cfd.id
}

output "instance_id" {
  description = "HPC EC2 instance ID"
  value       = aws_instance.hpc.id
}

output "private_ip" {
  description = "Static private IP of HPC instance"
  value       = var.static_private_ip
}

output "elastic_ip" {
  description = "Elastic IP for external access"
  value       = aws_eip.hpc.public_ip
}

output "kms_key_arn" {
  description = "KMS CMK ARN used for all encryption"
  value       = aws_kms_key.cfd.arn
}

output "kms_key_alias" {
  description = "KMS CMK alias"
  value       = aws_kms_alias.cfd.name
}

output "checkpoint_bucket" {
  description = "S3 bucket for checkpoints and session logs"
  value       = aws_s3_bucket.checkpoints.bucket
}

output "cloudtrail_bucket" {
  description = "S3 bucket for CloudTrail audit logs"
  value       = aws_s3_bucket.cloudtrail.bucket
}

output "ssm_connect_command" {
  description = "Command to connect via SSM Session Manager (no SSH needed)"
  value       = "aws ssm start-session --target ${aws_instance.hpc.id} --region ${var.aws_region}"
}

output "cloudwatch_namespace" {
  description = "CloudWatch metrics namespace for this project"
  value       = "CFD/${var.project_name}"
}

output "cost_summary" {
  description = "Estimated cost per simulation run"
  value       = "~$21 per simulation (hpc7a.48xlarge @ $3.50/hr x 6hrs) vs $384 on m5.24xlarge"
}
