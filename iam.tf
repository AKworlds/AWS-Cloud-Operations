# -----------------------------------------------
# IAM ROLES AND POLICIES
# HPC instance role: SSM, CloudWatch, KMS, S3
# DLM role: EBS snapshot lifecycle management
# -----------------------------------------------

# -----------------------------------------------
# HPC INSTANCE ROLE
# -----------------------------------------------
resource "aws_iam_role" "hpc" {
  name        = "${var.project_name}-hpc-role"
  description = "IAM role for HPC CFD instance - ITAR/DFARS"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.project_name}-hpc-role"
    Environment = var.environment
    Compliance  = "ITAR/DFARS"
  }
}

# SSM — Systems Manager access (no SSH bastion needed)
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.hpc.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch — metrics and log publishing
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.hpc.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Custom policy: KMS + S3 for simulation data
resource "aws_iam_policy" "hpc_custom" {
  name        = "${var.project_name}-hpc-custom"
  description = "Custom permissions for CFD HPC instance"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # KMS: decrypt and use CMK for EBS
      {
        Sid    = "KMSAccess"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.cfd.arn
      },
      # S3: store checkpoint data and session logs
      {
        Sid    = "S3CheckpointAccess"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.checkpoints.arn,
          "${aws_s3_bucket.checkpoints.arn}/*"
        ]
      },
      # CloudWatch: publish custom simulation metrics
      {
        Sid    = "CloudWatchMetrics"
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      },
      # EC2: describe instance metadata
      {
        Sid    = "EC2Describe"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "hpc_custom" {
  role       = aws_iam_role.hpc.name
  policy_arn = aws_iam_policy.hpc_custom.arn
}

# Instance profile — attaches role to EC2
resource "aws_iam_instance_profile" "hpc" {
  name = "${var.project_name}-hpc-profile"
  role = aws_iam_role.hpc.name
}

# -----------------------------------------------
# DLM ROLE — EBS snapshot lifecycle management
# -----------------------------------------------
resource "aws_iam_role" "dlm" {
  name        = "${var.project_name}-dlm-role"
  description = "DLM role for automated EBS snapshots"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "dlm.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "dlm" {
  role       = aws_iam_role.dlm.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"
}

# -----------------------------------------------
# S3 BUCKET — Checkpoint and session logs
# -----------------------------------------------
resource "aws_s3_bucket" "checkpoints" {
  bucket        = "${var.project_name}-checkpoints-${data.aws_caller_identity.current.account_id}"
  force_destroy = false

  tags = {
    Name        = "${var.project_name}-checkpoints"
    Environment = var.environment
    Compliance  = "ITAR/DFARS"
  }
}

resource "aws_s3_bucket_versioning" "checkpoints" {
  bucket = aws_s3_bucket.checkpoints.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "checkpoints" {
  bucket = aws_s3_bucket.checkpoints.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.cfd.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "checkpoints" {
  bucket                  = aws_s3_bucket.checkpoints.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
