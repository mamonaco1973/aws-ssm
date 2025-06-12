# Provider Configuration
provider "aws" {
  region = "us-east-2"  # AWS region where resources will be created
}

# VPC Configuration
resource "aws_vpc" "setup_vpc" {
  cidr_block = "10.0.0.0/16"  # IP range for the VPC
  tags = {
    Name = "setup-vpc"        # Tag to identify the VPC
  }
}

# Internet Gateway
resource "aws_internet_gateway" "setup_igw" {
  vpc_id = aws_vpc.setup_vpc.id      # Attach to the created VPC
  tags = {
    Name = "setup-internet-gateway"  # Tag to identify the Internet Gateway
  }
}

# Route Table Configuration
resource "aws_route_table" "setup_route_table" {
  vpc_id = aws_vpc.setup_vpc.id                     # Associate with the created VPC

  route {
    cidr_block = "0.0.0.0/0"                        # Allow all outbound traffic
    gateway_id = aws_internet_gateway.setup_igw.id  # Route traffic to the Internet Gateway
  }

  tags = {
    Name = "setup-route-table"                      # Tag to identify the Route Table
  }
}

# Route Table Association
resource "aws_route_table_association" "setup_route_table_assoc" {
  subnet_id      = aws_subnet.setup_public_subnet.id     # Associate with the public subnet
  route_table_id = aws_route_table.setup_route_table.id  # Use the created Route Table
}

# Public Subnet Configuration
resource "aws_subnet" "setup_public_subnet" {
  vpc_id                  = aws_vpc.setup_vpc.id  # Associate with the created VPC
  cidr_block              = "10.0.1.0/24"         # IP range for the subnet
  map_public_ip_on_launch = true                  # Enable public IPs for launched instances
  availability_zone       = "us-east-2a"          # Specify the availability zone
  tags = {
    Name = "setup-public-subnet"                  # Tag to identify the subnet
  }
}

# Security Group
resource "aws_security_group" "setup_sg" {
  vpc_id = aws_vpc.setup_vpc.id  # Associate with the created VPC

  ingress {
    from_port   = 22               # SSH port
    to_port     = 22               # SSH port
    protocol    = "tcp"            # Protocol type
    cidr_blocks = ["0.0.0.0/0"]    # Open to all for SSH
  }

  ingress {
    from_port   = 80               # HTTP port
    to_port     = 80               # HTTP port
    protocol    = "tcp"            # Protocol type
    cidr_blocks = ["0.0.0.0/0"]    # Open to all for HTTP
  }

  egress {
    from_port   = 0                # All outbound ports
    to_port     = 0                # All outbound ports
    protocol    = "-1"             # Allow all protocols
    cidr_blocks = ["0.0.0.0/0"]    # Allow all outbound traffic
  }

  tags = {
    Name = "setup-security-group"  # Tag to identify the security group
  }
}

# Key Pair Configuration
resource "aws_key_pair" "setup_key_pair" {
  key_name   = "setup-key-pair"           # Key pair name
  public_key = file("./keys/Public_Key")  # Path to the public key file
}

# AMI Data Source
data "aws_ami" "setup_ubuntu" {
  most_recent = true                    # Fetch the most recent AMI
  owners      = ["099720109477"]        # Canonical's AWS Account ID

  filter {
    name   = "name"                           # Filter AMIs by name
    values = ["*ubuntu-noble-24.04-amd64-*"]  # Match Ubuntu AMI
  }
}

# EC2 Instance Configuration
resource "aws_instance" "setup_ec2_instance" {
  ami                      = data.aws_ami.setup_ubuntu.id          # Use the selected AMI
  instance_type            = "t2.micro"                            # Instance type
  subnet_id                = aws_subnet.setup_public_subnet.id     # Launch in the public subnet
  security_groups          = [aws_security_group.setup_sg.id]      # Apply the security group
  associate_public_ip_address = true                               # Enable public IP assignment

  key_name = aws_key_pair.setup_key_pair.key_name                  # Use the created key pair

  user_data = file("./scripts/userdata.sh")                        # Bootstrap script to initialize instance

  tags = {
    Name = "setup-ec2-instance"                                    # Tag to identify the EC2 instance
  }
}

# Output Configuration
output "setup_ec2_public_ip" {
  value       = aws_instance.setup_ec2_instance.public_ip    # Output the instance's public IP
  description = "The public IP address of the EC2 instance"  # Description of the output
}
