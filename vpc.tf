# -----------------------------------------------
# VPC
# -----------------------------------------------
resource "aws_vpc" "cfd" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
    Compliance  = "ITAR/DFARS"
    Project     = var.project_name
  }
}

# -----------------------------------------------
# PRIVATE SUBNET
# CFD workloads run in private subnet only
# No direct internet exposure
# -----------------------------------------------
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.cfd.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.project_name}-private-subnet"
    Environment = var.environment
    Type        = "private"
  }
}

# -----------------------------------------------
# INTERNET GATEWAY
# Required for outbound AWS API calls and updates
# -----------------------------------------------
resource "aws_internet_gateway" "cfd" {
  vpc_id = aws_vpc.cfd.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
  }
}

# -----------------------------------------------
# ROUTE TABLE
# Outbound only — HTTPS to AWS APIs, NTP
# -----------------------------------------------
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.cfd.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cfd.id
  }

  tags = {
    Name        = "${var.project_name}-route-table"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# -----------------------------------------------
# NETWORK ACL
# ITAR/DFARS: restrict inbound to admin only
# -----------------------------------------------
resource "aws_network_acl" "cfd" {
  vpc_id     = aws_vpc.cfd.id
  subnet_ids = [aws_subnet.private.id]

  # Allow SSH from admin CIDR only
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.admin_cidr
    from_port  = 22
    to_port    = 22
  }

  # Allow HTTPS inbound from VPC (AWS service responses)
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 443
    to_port    = 443
  }

  # Allow ephemeral ports for return traffic
  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow HTTPS outbound (AWS APIs, updates)
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Allow NTP outbound
  egress {
    protocol   = "udp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 123
    to_port    = 123
  }

  # Allow ephemeral ports outbound for return traffic
  egress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name        = "${var.project_name}-nacl"
    Environment = var.environment
    Compliance  = "ITAR/DFARS"
  }
}

# -----------------------------------------------
# SECURITY GROUP
# Stateful — SSH admin only, HTTPS + NTP outbound
# -----------------------------------------------
resource "aws_security_group" "hpc" {
  name        = "${var.project_name}-hpc-sg"
  description = "Security group for HPC CFD instance - ITAR/DFARS compliant"
  vpc_id      = aws_vpc.cfd.id

  # SSH — admin CIDR only
  ingress {
    description = "SSH admin access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  # HTTPS inbound from VPC only (AWS service responses)
  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # HTTPS outbound — AWS APIs, SSM, CloudWatch
  egress {
    description = "HTTPS to AWS APIs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NTP outbound — time synchronization
  egress {
    description = "NTP time sync"
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-hpc-sg"
    Environment = var.environment
    Compliance  = "ITAR/DFARS"
  }
}
