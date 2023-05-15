terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.AWS_REGION
}

provider "helm" {
  kubernetes {
    config_path = pathexpand(var.kube_config)
  }
}


provider "kubernetes" {
  config_path = pathexpand(var.kube_config)
}