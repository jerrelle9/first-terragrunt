variable "org_name" {
  description = "Name of organization which vpc belong to"
  type = string
}

variable "vpc_cidr"{
  description = "CIDR blcok for the VPC"
  type = string
}

variable "region" {
  description = "Region in which vpc is placed"
  type = string
}

variable "environment" {
  description = "Development"
  type = string
}

variable "public_subnet_id" {
  description = "idk what to put here"
  type = string
}
