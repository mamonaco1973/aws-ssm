# --------------------
# VPC Definition Block
# --------------------
resource "aws_vpc" "ssm-vpc" {
  # Defines the CIDR range for the VPC (256 IPs total)
  cidr_block           = "10.0.0.0/24"
  # Enables internal DNS resolution within the VPC
  enable_dns_support   = true
  # Allows assigning DNS hostnames to EC2 instances
  enable_dns_hostnames = true

  tags = {
    Name = "ssm-vpc"  # Human-readable name for this VPC
  }
}

# ----------------------------
# Internet Gateway Definition
# ----------------------------
resource "aws_internet_gateway" "ssm-igw" {
  # Attach the IGW to the previously defined VPC
  vpc_id = aws_vpc.ssm-vpc.id

  tags = {
    Name = "ssm-igw"  # Tag for easy identification
  }
}

# --------------------------------
# Elastic IP for the NAT Gateway
# --------------------------------
resource "aws_eip" "nat_eip" {
  # Allocate the EIP to the VPC domain (not EC2-Classic)
  domain = "vpc"

  tags = {
    Name = "ssm-nat-eip"  # Tag for EIP identification
  }
}

# ----------------------------------------
# NAT Gateway for Private Subnet Egress
# ----------------------------------------
resource "aws_nat_gateway" "ssm-nat-gw" {
  # Use the EIP for external internet access
  allocation_id = aws_eip.nat_eip.id
  # NAT Gateway must be deployed in a public subnet (see nat-subnet)
  subnet_id     = aws_subnet.nat-subnet.id

  tags = {
    Name = "ssm-nat-gateway"
  }
}

# ------------------------------
# Public Route Table Definition
# ------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.ssm-vpc.id  # Associate with main VPC

  tags = {
    Name = "public-route-table"
  }
}

# -----------------------------------------------
# Route in Public Route Table to Internet Gateway
# -----------------------------------------------
resource "aws_route" "public_default_route" {
  # Routes all outbound traffic (0.0.0.0/0) to the IGW
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ssm-igw.id
}

# -------------------------------
# Private Route Table Definition
# -------------------------------
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.ssm-vpc.id  # Associate with main VPC

  tags = {
    Name = "private-route-table"
  }
}

# ----------------------------------------------------
# Route in Private Route Table to NAT for Egress Only
# ----------------------------------------------------
resource "aws_route" "private_default_route" {
  # Private subnets route traffic to the NAT Gateway for outbound internet
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ssm-nat-gw.id
}

# -------------------------------
# NAT Subnet (a.k.a. Public Subnet)
# -------------------------------
resource "aws_subnet" "nat-subnet" {
  vpc_id                  = aws_vpc.ssm-vpc.id
  cidr_block              = "10.0.0.0/26"  # First 64 IPs of the VPC CIDR
  # Disables auto-assignment of public IPs (assumes NAT GW will be manually exposed)
  map_public_ip_on_launch = false
  availability_zone       = "us-east-2a"  

  tags = {
    Name = "nat-subnet"
  }
}

# -----------------------------------
# Private Subnet 1 (for internal use)
# -----------------------------------
resource "aws_subnet" "ssm-private-subnet-1" {
  vpc_id               = aws_vpc.ssm-vpc.id
  cidr_block           = "10.0.0.128/26"  # 10.0.0.128 - 10.0.0.191
  availability_zone    = "us-east-2b"

  tags = {
    Name = "ssm-private-subnet-1"
  }
}

# -----------------------------------
# Private Subnet 2 (for internal use)
# -----------------------------------
resource "aws_subnet" "ssm-private-subnet-2" {
  vpc_id               = aws_vpc.ssm-vpc.id
  cidr_block           = "10.0.0.192/26"  # 10.0.0.192 - 10.0.0.255
  availability_zone_id = "use1-az4"

  tags = {
    Name = "ad-private-subnet-2"
  }
}

# ---------------------------------------
# Associate NAT Subnet to Public Route Table
# ---------------------------------------
resource "aws_route_table_association" "public_rta_1" {
  subnet_id      = aws_subnet.nat-subnet.id
  route_table_id = aws_route_table.public.id
}

# -------------------------------------------------
# Associate Private Subnet 1 to Private Route Table
# -------------------------------------------------
resource "aws_route_table_association" "private_rta_1" {
  subnet_id      = aws_subnet.ssm-private-subnet-1.id
  route_table_id = aws_route_table.private.id
}

# -------------------------------------------------
# Associate Private Subnet 2 to Private Route Table
# -------------------------------------------------
resource "aws_route_table_association" "private_rta_2" {
  subnet_id      = aws_subnet.ssm-private-subnet-2.id
  route_table_id = aws_route_table.private.id
}
