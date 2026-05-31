# -----------------------------------------------
# KMS CUSTOMER MANAGED KEY (CMK)
# ITAR/DFARS: AES-256-GCM encryption
# All EBS volumes encrypted with this key
# Full audit trail via CloudTrail
# -----------------------------------------------

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "cfd" {
  description             = "CMK for CFD aerospace simulation data - ITAR/DFARS"
  deletion_window_in_days = 30
  enable_key_rotation     = true  # Annual automatic rotation

  # FIPS 140-2 validated key policy
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Allow root account full access
      {
        Sid    = "RootAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      # Allow EC2 to use the key for EBS encryption
      {
        Sid    = "EC2EBSEncryption"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ec2.${var.aws_region}.amazonaws.com"
          }
        }
      },
      # Allow IAM role for HPC instance
      {
        Sid    = "HPCInstanceAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.hpc.arn
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      # Allow CloudTrail to audit all key usage
      {
        Sid    = "CloudTrailAudit"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:DescribeKey",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-cmk"
    Environment = var.environment
    Compliance  = "ITAR/DFARS"
    FIPS        = "140-2"
    Project     = var.project_name
  }
}

# Human-readable alias for the key
resource "aws_kms_alias" "cfd" {
  name          = "alias/${var.project_name}-cmk"
  target_key_id = aws_kms_key.cfd.key_id
}
