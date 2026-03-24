include{
  path = find_in_parent_folders()
}

locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
}

terraform {
  source = "../../../../modules/vpc"
}

inputs = {
  region = local.account_vars.locals.aws_region
  environment = local.account_vars.locals.environment
  name = "dev-vpc"
  cidr_block = "10.0.0.0/16"
}

