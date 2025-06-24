terraform {
  backend "s3" {
    bucket         = "victor-mashyka"
    key            = "lesson-5/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

