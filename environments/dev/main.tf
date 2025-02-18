terraform {
  required_version = ">=1.10.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.81.0"
    }
  }
  backend "s3" {
    encrypt = true
  }
}

module "cloudtrail" {
  source = "../../modules/cloudtrail"
  common = local.common
  bucket = var.bucket
}

module "monitoring" {
  source = "../../modules/monitoring"
  common = local.common
  target = var.target
  cloudtrail = module.cloudtrail
}
