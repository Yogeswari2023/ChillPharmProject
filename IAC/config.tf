provider "aws" {
    region = "us-east-1"
	access_key = "AKIARHX2TCIFDS6G5GP5"
	secret_key = "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"
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