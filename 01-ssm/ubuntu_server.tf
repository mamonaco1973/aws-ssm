# AMI Data Source
data "aws_ami" "ubuntu_ami" {
  most_recent = true                    # Fetch the most recent AMI
  owners      = ["099720109477"]        # Canonical's AWS Account ID

  filter {
    name   = "name"                           # Filter AMIs by name
    values = ["*ubuntu-noble-24.04-amd64-*"]  # Match Ubuntu AMI
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
