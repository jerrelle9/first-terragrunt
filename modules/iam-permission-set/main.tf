resource "aws_ssoadmin_permission_set" "this"{
    name = var.name
    description = var.description
    instance_arn = var.instance_arn

    session_duration = "PT8H"

}

resource "aws_ssoadmin_permission_set_inline_policy" "this"{
    instance_arn = var.instance_arn
    permission_set_arn = aws_ssoadmin_permission_set.this.arn

    inline_policy = var.inline_policy
}

terraform {
  backend "s3" {}
}