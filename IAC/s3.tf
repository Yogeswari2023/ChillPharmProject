resource "aws_s3_bucket" "whoami_public_files" {
  bucket        = "whoami-files"
  force_destroy = true
}
