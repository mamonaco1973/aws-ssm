# --------------------------------------------------------------------------------------------------
# FETCH THE AMI ID FOR UBUNTU 24.04 FROM AWS PARAMETER STORE
# --------------------------------------------------------------------------------------------------
data "aws_ssm_parameter" "ubuntu_24_04" {
  # Pull the latest stable Ubuntu 24.04 AMI ID published by Canonical via AWS Systems Manager
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

# --------------------------------------------------------------------------------------------------
# RESOLVE THE FULL AMI OBJECT USING THE ID FROM SSM
# --------------------------------------------------------------------------------------------------
data "aws_ami" "ubuntu_ami" {
  # Just in case there are multiple versions, this ensures the most recent one is picked
  most_recent = true

  # Canonical's AWS account ID contains the official Ubuntu AMIs
  owners = ["099720109477"]

  # Only fetch the AMI that matches the ID we just pulled from SSM
  filter {
    name   = "image-id"
    values = [data.aws_ssm_parameter.ubuntu_24_04.value]
  }
}

# --------------------------------------------------------------------------------------------------
# CREATE AN EC2 INSTANCE RUNNING UBUNTU 24.04
# --------------------------------------------------------------------------------------------------
resource "aws_instance" "ubuntu_instance" {
  # Use the resolved AMI ID for Ubuntu 24.04 (from the data source above)
  ami = data.aws_ami.ubuntu_ami.id

  # Choose a micro instance type – good enough for demo workloads, not prod
  instance_type = "t2.micro"

  # Drop this instance in the specified private subnet
  subnet_id = aws_subnet.ssm-private-subnet-1.id

  # Attach both the general SSM security group and one allowing HTTP access (if needed)
  vpc_security_group_ids = [
    aws_security_group.ssm_sg.id,
    aws_security_group.ssm_http_sg.id
  ]

  # Attach the IAM instance profile that allows this EC2 to talk to SSM
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_profile.name

  # ------------------------------------------------------------------------------------------------
  # BOOTSTRAP SCRIPT TO INSTALL AND ENABLE AMAZON SSM AGENT, AND ENABLE SSH PASSWORD LOGIN
  # ------------------------------------------------------------------------------------------------
  user_data = <<-EOF
                #!/bin/bash

                # Update package repositories (because duh)
                apt update

                # Install Amazon SSM agent using Snap (classic confinement mode)
                snap install amazon-ssm-agent --classic

                # Enable and start the agent right away, because we need this instance reachable via SSM
                systemctl enable --now snap.amazon-ssm-agent.amazon-ssm-agent.service

                # Optional but useful: enable SSH password authentication (default is disabled)
                # This tweak is often needed for manual troubleshooting or Packer SSH sessions
                sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' \
                   /etc/ssh/sshd_config.d/60-cloudimg-settings.conf

                # Restart SSH to apply config changes
                sudo systemctl restart ssh 
              EOF

  # Tag the instance with a recognizable name for filtering or UI display
  tags = {
    Name = "ubuntu-instance"
  }
}
