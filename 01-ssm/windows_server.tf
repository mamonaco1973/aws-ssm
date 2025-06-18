data "aws_ami" "windows_ami" {
  most_recent = true       # Fetch the latest Windows Server AMI
  owners      = ["amazon"] # AWS official account for Windows AMIs

  filter {
    name   = "name"                                      # Filter AMIs by name pattern
    values = ["Windows_Server-2022-English-Full-Base-*"] # Match Windows Server 2022 AMI
  }
}

resource "aws_instance" "windows_instance" {

  # AMAZON MACHINE IMAGE (AMI)
  # Reference the Windows AMI ID fetched dynamically via the data source.
  # This ensures the latest or specific Windows Server version is used.

  ami = data.aws_ami.windows_ami.id

  # INSTANCE TYPE
  # Defines the compute power of the EC2 instance.
  # "t2.medium" is selected to provide more RAM and CPU power, 
  # since Windows requires more resources than Linux.

  instance_type = "t2.medium"

  # NETWORK CONFIGURATION - SUBNET
  # Specifies the AWS subnet where the instance will be deployed.
  # The subnet is dynamically retrieved from a data source (ad_subnet_2).
  # This determines whether the instance is public or private.

  subnet_id = aws_subnet.ssm-private-subnet-2.id

  # SECURITY GROUPS  
  vpc_security_group_ids = [
    aws_security_group.ssm_sg.id,
    aws_security_group.ssm_http_sg.id
  ]

  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_profile.name

  # INSTANCE TAGS
  # Metadata tag used to identify and organize resources in AWS.
  tags = {
    Name = "windows-instance" # The EC2 instance name in AWS.
  }
}
