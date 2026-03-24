data "aws_ami" "amazon_linux"{
    most_recent = true
    owners = ["amazon"]

    filter{
        name = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
}

resource "aws_security_group" "this"{
    name = "${var.name}-sg"
    description = "EC2 Security group"
    vpc_id = var.vpc_id

    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port =0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = var.tags
}

resource "aws_instance" "this" {
    ami = data.aws_ami.amazon_linux.id
    instance_type = var.instance_type

    subnet_id = var.subnet_id
    vpc_security_group_ids = [aws_security_group.this.id]

    associate_public_ip_address = true

    tags = var.tags
}

terraform {
  backend "s3" {}
}