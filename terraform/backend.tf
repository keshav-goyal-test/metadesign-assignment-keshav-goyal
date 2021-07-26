
# Initializing backend

terraform {
  #   required_version = "1.21.0"
  backend "s3" {
    bucket = "meta-bucket-keshav"
    key    = "infra/ec2.tfstate"
    region = "us-east-1"
  }
}