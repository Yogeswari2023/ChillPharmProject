provider "aws" {
    region = "us-east-1"
	access_key = "<aws access key>"
	secret_key = "<aws secret key>"
}
provider "aws" {
    alias = "dns_zones"
    # ... access keys etc/assume role block
}
locals {
  prefix = "${var.prefix}-${terraform.workspace}"
  common_tags = {
    Environment = terraform.workspace
    ManagedBy   = "Terraform"
  }
}
data "aws_region" "current" {}