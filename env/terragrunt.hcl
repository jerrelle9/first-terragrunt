remote_state{
    backend = "s3"

    config = {
        bucket = "aws-infrastructure1"
        key = "dev/us-east-1/vpc/terraform.tfstate"
        region = "us-east-1"
        encrypt = true
        dynamodb_table = "terraform-locks"
    }
}


generate "provider"{
    path = "provider.tf"
    if_exists = "overwrite"
    contents = <<EOF
EOF
}