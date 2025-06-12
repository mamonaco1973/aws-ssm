# Define an IAM Role for EC2 instances to interact with AWS Systems Manager (SSM)
resource "aws_iam_role" "ec2_ssm_role" {
  name = "EC2SSMRole"

  # Define the trust policy allowing EC2 instances to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"  # Only EC2 instances can assume this role
      }
      Action = "sts:AssumeRole"  # Allows EC2 instances to request temporary credentials
    }]
  })
}

# Attach the AmazonSSMManagedInstanceCore policy to the SSM role
# This ensures instances using the SSM role can be managed via AWS Systems Manager
resource "aws_iam_role_policy_attachment" "attach_ssm_policy" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create an IAM Instance Profile for EC2 instances using the SSM role
resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "EC2SSMProfile"
  role = aws_iam_role.ec2_ssm_role.name  # Associate the EC2SSMRole with this profile
}
