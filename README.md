# Amazon Web Services Auto Scaling Group via Terraform + Packer

How to reproduce?

1. First - use Packer to create referance AMI-Image

Fill your own parameters in variables section in `packer/web.json` file

Variable | Description
------------ | -------------
aws_access_key | IAM Access Key
aws_secret_key | IAM Secret Key
aws_region | Region (for example: `us-east-2`)
aws_ami | Public AMI (by default `ami-cf172aaa` - Ubuntu Server 16.04)
aws_it | Instance Type (for example: `t2.micro`)
aws_az | Availability zone (for example: `us-east-2a`)

Validate json

`packer validate web.json`

If validation was successful - then create image via packer by following command:

`packer build web.json`

2. After creation of ami-image - deploy auto scaling infrastructure on Amazon Web Services via Terraform

Fill your own parameters in variables section in `terraform/terraform.tfvars` file:

Variable | Description
------------ | -------------
aws_access_key | IAM Access Key
aws_secret_key | IAM Secret Key
aws_region | Region (for example: `us-east-2`)
aws_it | Instance Type (for example: `t2.micro`)
aws_ssh_key | Key-pairs name (for example: `production_key`)
aws_vpc | VPC ID (for example: `vpc-xxxxxxxx`)

Init terraform for download modules:

`terraform init`

Validate terraform files:

`terraform validate` 

Generate and show an execution plan:

`terraform plan` 

Then deploy infrastructure via terraform by following command:

`terraform apply`

For destroy terraform-managed infrastructure use:

`terraform destroy`