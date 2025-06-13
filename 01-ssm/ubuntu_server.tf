data "aws_ami" "ubuntu_ami" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_instance" "ubuntu_instance" {
  ami                         = data.aws_ami.ubuntu_ami.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.ssm-private-subnet-1.id
  security_groups             = [aws_security_group.ssm_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm_profile.name

  user_data = <<-EOF
                #!/bin/bash
                apt update
                snap install amazon-ssm-agent --classic
                systemctl enable --now snap.amazon-ssm-agent.amazon-ssm-agent.service
              EOF

  tags = {
    Name = "ubuntu-instance"
  }
}
