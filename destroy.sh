#!/bin/bash

# Set the default AWS region to us-east-2 for all AWS CLI and Terraform operations.
export AWS_DEFAULT_REGION=us-east-2

# Navigate to the directory containing the Terraform configuration for SSM resources.
cd 01-ssm

# Initialize the Terraform working directory (downloads providers and sets up backend).
terraform init

# Destroy all Terraform-managed infrastructure in this directory without prompting for confirmation.
terraform destroy -auto-approve

# Return to the parent directory after destroying resources.
cd ..
