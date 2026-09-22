provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      project    = "aws-ram-poc"
      deployment = "terraform"
    }
  }
}
