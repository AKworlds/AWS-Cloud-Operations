# -----------------------------------------------
# MONITORING — FIVE AWS NATIVE SERVICES
# 1. CloudWatch Agent (metrics + logs)
# 2. Systems Manager (patch + remote access)
# 3. CloudWatch Alarms (proactive alerting)
# 4. AWS Inspector (vulnerability scanning)
# 5. Checkpoint Service (simulation state)
# -----------------------------------------------

# -----------------------------------------------
# SNS TOPIC — alarm notifications
# -----------------------------------------------
resource "aws_sns_topic" "alerts" {
  name              = "${var.project_name}-alerts"
  kms_master_key_id = aws_kms_key.cfd.id

  tags = {
    Name        = "${var.project_name}-alerts"
    Environment = var.environment
  }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# -----------------------------------------------
# 1. CLOUDWATCH LOG GROUPS
# /var/log/messages + simulation logs
# -----------------------------------------------
resource "aws_cloudwatch_log_group" "system" {
  name              = "/aws/ec2/${var.project_name}/messages"
  retention_in_days = 90
  kms_key_id        = aws_kms_key.cfd.arn

  tags = {
    Name        = "${var.project_name}-system-logs"
    Compliance  = "ITAR/DFARS"
  }
}

resource "aws_cloudwatch_log_group" "simulation" {
  name              = "/aws/ec2/${var.project_name}/simulation"
  retention_in_days = 365  # ITAR requires extended retention
  kms_key_id        = aws_kms_key.cfd.arn

  tags = {
    Name        = "${var.project_name}-simulation-logs"
    Compliance  = "ITAR/DFARS"
    Retention   = "1-year"
  }
}

# CloudWatch Agent configuration stored in SSM Parameter Store
resource "aws_ssm_parameter" "cloudwatch_config" {
  name  = "/cloudwatch-agent/${var.project_name}/config"
  type  = "String"
  value = jsonencode({
    agent = {
      metrics_collection_interval = 60
      run_as_user                 = "root"
    }
    metrics = {
      metrics_collected = {
        cpu = {
          measurement                 = ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"]
          metrics_collection_interval = 60
          per_cpu                     = true  # Per-core metrics for CFD analysis
          totalcpu                    = true
        }
        mem = {
          measurement                 = ["mem_used_percent", "mem_available_percent"]
          metrics_collection_interval = 60
        }
        disk = {
          measurement                 = ["disk_used_percent", "disk_inodes_free"]
          metrics_collection_interval = 60
          resources                   = ["/", "/scratch", "/checkpoint"]
        }
        diskio = {
          measurement                 = ["reads", "writes", "read_bytes", "write_bytes", "iops_in_progress"]
          metrics_collection_interval = 60
          resources                   = ["xvda", "xvdb", "xvdc"]
        }
        net = {
          measurement                 = ["bytes_sent", "bytes_recv", "packets_sent", "packets_recv"]
          metrics_collection_interval = 60
        }
      }
      append_dimensions = {
        InstanceId   = "$${aws:InstanceId}"
        InstanceType = "$${aws:InstanceType}"
      }
      namespace = "CFD/${var.project_name}"
    }
    logs = {
      logs_collected = {
        files = {
          collect_list = [
            {
              file_path        = "/var/log/messages"
              log_group_name   = aws_cloudwatch_log_group.system.name
              log_stream_name  = "{instance_id}/messages"
              timezone         = "UTC"
            },
            {
              file_path        = "/var/log/simulation/*.log"
              log_group_name   = aws_cloudwatch_log_group.simulation.name
              log_stream_name  = "{instance_id}/simulation"
              timezone         = "UTC"
            }
          ]
        }
      }
    }
  })

  tags = {
    Name = "${var.project_name}-cloudwatch-config"
  }
}

# -----------------------------------------------
# 3. CLOUDWATCH ALARMS
# CPU, Disk, Memory thresholds with SNS
# -----------------------------------------------

# CPU > 95% for 5 minutes
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-cpu-high"
  alarm_description   = "CPU utilization above 95% for 5 minutes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "cpu_usage_user"
  namespace           = "CFD/${var.project_name}"
  period              = 60
  statistic           = "Average"
  threshold           = 95
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.hpc.id
  }

  tags = {
    Name = "${var.project_name}-cpu-alarm"
  }
}

# Scratch disk > 85% — immediate action (simulation data at risk)
resource "aws_cloudwatch_metric_alarm" "scratch_disk_high" {
  alarm_name          = "${var.project_name}-scratch-disk-high"
  alarm_description   = "Scratch disk utilization above 85%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1  # Alert immediately — 1 minute
  metric_name         = "disk_used_percent"
  namespace           = "CFD/${var.project_name}"
  period              = 60
  statistic           = "Average"
  threshold           = 85
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.hpc.id
    path       = "/scratch"
  }

  tags = {
    Name = "${var.project_name}-scratch-disk-alarm"
  }
}

# Memory > 90% for 5 minutes
resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${var.project_name}-memory-high"
  alarm_description   = "Memory utilization above 90% for 5 minutes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "mem_used_percent"
  namespace           = "CFD/${var.project_name}"
  period              = 60
  statistic           = "Average"
  threshold           = 90
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.hpc.id
  }

  tags = {
    Name = "${var.project_name}-memory-alarm"
  }
}

# Checkpoint disk > 80% — checkpoint data at risk
resource "aws_cloudwatch_metric_alarm" "checkpoint_disk_high" {
  alarm_name          = "${var.project_name}-checkpoint-disk-high"
  alarm_description   = "Checkpoint disk utilization above 80%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "disk_used_percent"
  namespace           = "CFD/${var.project_name}"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.hpc.id
    path       = "/checkpoint"
  }

  tags = {
    Name = "${var.project_name}-checkpoint-disk-alarm"
  }
}

# -----------------------------------------------
# 2. SYSTEMS MANAGER — patch + remote access
# SSM Session Manager replaces SSH bastion
# Session logs stored in S3 (ITAR audit trail)
# -----------------------------------------------
resource "aws_ssm_association" "patch" {
  name             = "AWS-RunPatchBaseline"
  association_name = "${var.project_name}-patch-baseline"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.hpc.id]
  }

  schedule_expression = "cron(0 2 ? * SUN *)"  # Weekly Sunday 2AM

  parameters = {
    Operation    = "Install"
    RebootOption = "RebootIfNeeded"
  }
}

# SSM document: session logging to S3
resource "aws_ssm_document" "session_logging" {
  name            = "${var.project_name}-session-preferences"
  document_type   = "Session"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "1.0"
    description   = "Session Manager preferences with S3 logging"
    sessionType   = "Standard_Stream"
    inputs = {
      s3BucketName        = aws_s3_bucket.checkpoints.bucket
      s3KeyPrefix         = "session-logs/"
      s3EncryptionEnabled = true
      cloudWatchLogGroupName      = aws_cloudwatch_log_group.system.name
      cloudWatchEncryptionEnabled = true
    }
  })
}

# -----------------------------------------------
# 4. AWS INSPECTOR — vulnerability scanning
# Weekly automated scans, CVE database checks
# -----------------------------------------------
resource "aws_inspector2_enabler" "cfd" {
  account_ids    = [data.aws_caller_identity.current.account_id]
  resource_types = ["EC2", "ECR"]
}

# -----------------------------------------------
# CLOUDTRAIL — full audit trail
# ITAR/DFARS: log all API calls including KMS usage
# -----------------------------------------------
resource "aws_cloudtrail" "cfd" {
  name                          = "${var.project_name}-audit-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.bucket
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.cfd.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::${aws_s3_bucket.checkpoints.bucket}/"]
    }
  }

  tags = {
    Name       = "${var.project_name}-cloudtrail"
    Compliance = "ITAR/DFARS"
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail]
}

# S3 bucket for CloudTrail logs
resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "${var.project_name}-cloudtrail-${data.aws_caller_identity.current.account_id}"
  force_destroy = false

  tags = {
    Name       = "${var.project_name}-cloudtrail"
    Compliance = "ITAR/DFARS"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket                  = aws_s3_bucket.cloudtrail.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}
