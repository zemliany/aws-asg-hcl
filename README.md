# vid-test

How to reproduce?

Firt - use packer to create referance AMI-Image

Correct the aws_access_key and aws_secret_key parameters in packer/web.json and terraform/terraform.tfvars

Then - create reference image via packer
after creation of ami-image - deploy infrastructure on Amazon Web Services
