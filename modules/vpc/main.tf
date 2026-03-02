terraform {
  backend "s3" {
    
  }
}

provider "aws" {
  region = var.region
  
}

data "aws_availability_zones" "available" {
  state = "available"
}


resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  # enable_dns_support = true
  # enable_dns_hostnames = true

  tags = {
    Name = var.org_name
    Environment = var.environment
  }
}