provider "aws" {
    region = "us-east-1"
	access_key = "AKIARHX2TCIFLJAQWR6D"
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