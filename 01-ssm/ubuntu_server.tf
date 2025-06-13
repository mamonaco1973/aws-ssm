# AMI Data Source
data "aws_ami" "ubuntu_ami" {
  most_recent = true                    # Fetch the most recent AMI
  owners      = ["099720109477"]        # Canonical's AWS Account ID

  filter {
    name   = "name"                           # Filter AMIs by name
    values = ["*ubuntu-noble-24.04-amd64-*"]  # Match Ubuntu AMI
  }
}

# EC2 Instance Configuration
resource "aws_instance" "ubuntu_instance" {
  ami                      = data.aws_ami.ubuntu_ami.id          # Use the selected AMI
  instance_type            = "t2.micro"                          # Instance type
  subnet_id                = aws_subnet.ssm-private-subnet-1.id  # Launch in the public subnet
  security_groups          = [aws_security_group.ssm_sg.id]      # Apply the security group
  iam_instance_profile     = aws_iam_instance_profile.ec2_ssm_profile
                                                                 # Use the IAM instance profile for SSM access

  tags = {
    Name = "ubuntu-instance"                                    # Tag to identify the EC2 instance
  }
}
