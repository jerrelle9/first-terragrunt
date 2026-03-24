include{
    path = find_in_parent_folders()
}

terraform {
  source = "../../../../../modules/iam-permission-set"
}

inputs = {
    name = "ReadAll-LimitedWrite-Dev"
    description = "Read all resources, limited control based on tags"
    instance_arn = local.common.locals.instance_arn

    inline_policy = file("${get_terragrunt_dir()}/policy.json")
}