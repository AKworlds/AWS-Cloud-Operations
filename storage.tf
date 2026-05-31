# -----------------------------------------------
# THREE-VOLUME STORAGE ARCHITECTURE
# Lifecycle-matched storage = 80% cost reduction
#
# Root      100GB  gp3        3,000 IOPS  OS + apps
# Scratch   1000GB io2 Block  64,000 IOPS Active simulation
# Checkpoint 500GB gp3        3,000 IOPS  Recovery snapshots
#
# All volumes encrypted with CMK (ITAR/DFARS)
# -----------------------------------------------

# -----------------------------------------------
# ROOT VOLUME — OS and applications
# gp3: baseline performance sufficient
# -----------------------------------------------
resource "aws_ebs_volume" "root" {
  availability_zone = var.availability_zone
  size              = var.root_volume_size
  type              = "gp3"
  iops              = 3000
  throughput        = 125
  encrypted         = true
  kms_key_id        = aws_kms_key.cfd.arn

  tags = {
    Name        = "${var.project_name}-root"
    Environment = var.environment
    VolumeType  = "root"
    Compliance  = "ITAR/DFARS"
  }
}

resource "aws_volume_attachment" "root" {
  device_name = "/dev/xvda"
  volume_id   = aws_ebs_volume.root.id
  instance_id = aws_instance.hpc.id
}

# -----------------------------------------------
# SCRATCH VOLUME — Active simulation data
# io2 Block Express: 64,000 IOPS for CFD workloads
# High IOPS only where the simulation actually runs
# -----------------------------------------------
resource "aws_ebs_volume" "scratch" {
  availability_zone = var.availability_zone
  size              = var.scratch_volume_size
  type              = "io2"
  iops              = var.scratch_iops
  encrypted         = true
  kms_key_id        = aws_kms_key.cfd.arn

  tags = {
    Name        = "${var.project_name}-scratch"
    Environment = var.environment
    VolumeType  = "scratch"
    Purpose     = "active-simulation-data"
    Compliance  = "ITAR/DFARS"
  }
}

resource "aws_volume_attachment" "scratch" {
  device_name = "/dev/xvdb"
  volume_id   = aws_ebs_volume.scratch.id
  instance_id = aws_instance.hpc.id
}

# -----------------------------------------------
# CHECKPOINT VOLUME — Recovery snapshots
# gp3: moderate performance for periodic saves
# Limits data loss to 30 minutes on any failure
# -----------------------------------------------
resource "aws_ebs_volume" "checkpoint" {
  availability_zone = var.availability_zone
  size              = var.checkpoint_volume_size
  type              = "gp3"
  iops              = 3000
  throughput        = 125
  encrypted         = true
  kms_key_id        = aws_kms_key.cfd.arn

  tags = {
    Name        = "${var.project_name}-checkpoint"
    Environment = var.environment
    VolumeType  = "checkpoint"
    Purpose     = "recovery-snapshots"
    Compliance  = "ITAR/DFARS"
  }
}

resource "aws_volume_attachment" "checkpoint" {
  device_name = "/dev/xvdc"
  volume_id   = aws_ebs_volume.checkpoint.id
  instance_id = aws_instance.hpc.id
}

# -----------------------------------------------
# EBS SNAPSHOT LIFECYCLE POLICY
# Automated daily snapshots for compliance
# -----------------------------------------------
resource "aws_dlm_lifecycle_policy" "cfd" {
  description        = "CFD simulation volume snapshots - ITAR/DFARS"
  execution_role_arn = aws_iam_role.dlm.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = "Daily snapshots"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["02:00"]
      }

      retain_rule {
        count = 7
      }

      tags_to_add = {
        SnapshotCreator = "DLM"
        Compliance      = "ITAR/DFARS"
      }

      copy_tags = true
    }

    target_tags = {
      Compliance = "ITAR/DFARS"
    }
  }

  tags = {
    Name        = "${var.project_name}-snapshot-policy"
    Environment = var.environment
  }
}
