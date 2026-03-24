include {
    path = find_in_parent_folders()
}

terraform {
    source = "../../../../modules/ec2"
}

dependency "vpc" {
    config_path = "../vpc"
}

inputs = {
    name = "dev-ec2"
    vpc_id = dependency.vpc.outputs.vpc_id
    subnet_id = dependency.vpc.outputs.public_subnet_id
    instance_type = "t3.micro"

    tags = {
        Name = "dev-ec2-instance"
        Environment = "dev"
    }
}

# dependency "vpc" {
#   config_path  = "../vpc"
#   skip_outputs = true
# }



