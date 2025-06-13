
#!/bin/bash

export AWS_DEFAULT_REGION=us-east-2

cd 01-ssm

terraform init
terraform destroy -auto-approve

cd ..
