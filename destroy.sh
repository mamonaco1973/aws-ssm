
#!/bin/bash

cd 01-ssm

terraform init
terraform destroy -auto-approve

cd ..
