#!/bin/bash

export AWS_DEFAULT_REGION=us-east-2

windows_ip=$(aws ec2 describe-instances   \
             --filters "Name=tag:Name,Values=windows-instance" "Name=instance-state-name,Values=running"  \
             --query "Reservations[*].Instances[*].PrivateIpAddress" --output text | head -n1)

if [[ -z "$windows_ip" ]]; then
  echo "No running EC2 instance found with name 'windows-instance'. Exiting."
  exit 1
fi

echo $windows_ip



