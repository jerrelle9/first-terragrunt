# aws-intern-infrastructure

Enterprise-style AWS Infrastructure as Code repository using **Terraform** and **Terragrunt**. Deploys VPC, EC2 instances, and AWS IAM Identity Center (SSO) permission sets to a `dev` account in `us-east-1`, establishing folder conventions and module patterns for future projects.

---

## Repository Structure

```
aws-intern-infrastructure/
├── _env/
│   └── terragrunt.hcl              # Root config: provider, remote state (inherited by all modules)
├── accounts/
│   └── dev/
│       ├── account.hcl             # Account-level vars: environment, account ID, region
│       └── us-east-1/
│           ├── vpc/
│           │   └── terragrunt.hcl
│           ├── ec2/
│           │   └── terragrunt.hcl
│           └── iam/permission-set/
│               ├── terragrunt.hcl
│               └── policy.json
└── modules/
    ├── vpc/
    │   ├── main.tf                 # VPC, subnets, IGW, route tables
    │   ├── outputs.tf
    │   └── variables.tf
    ├── ec2/
    │   ├── main.tf                 # EC2 instances, security groups
    │   ├── outputs.tf
    │   └── variables.tf
    └── iam-permission-set/
        ├── main.tf                 # SSO permission sets
        ├── outputs.tf
        ├── variables.tf
        └── policy.json             # IAM policy
```

### Design Conventions

| Layer | Purpose |
|---|---|
| `_env/terragrunt.hcl` | Root config provider & S3 remote state (inherited by all) |
| `accounts/<env>/account.hcl` | Per-account variables (environment, account ID, region) |
| `accounts/<env>/<region>/<service>/terragrunt.hcl` | Deployment unit — passes inputs to module |
| `modules/<service>/` | Reusable, environment-agnostic Terraform modules |

---

## Prerequisites

| Tool | Version |
|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/install) | `>= 1.5` |
| [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) | `>= 0.50` |
| [AWS CLI](https://aws.amazon.com/cli/) | `>= 2.x` |

AWS credentials must be available in your environment (e.g., `aws configure`, environment variables, or an IAM role).

---

## Initial Setup

### 1. Configure AWS Account

Update `accounts/dev/account.hcl` with your AWS account details:

```hcl
locals {
  environment = "dev"
  account_id  = "123456789012"   # ← Replace with your account ID
  aws_region  = "us-east-1"
}
```

### 2. Bootstrap S3 & DynamoDB (first-time only)

Terragrunt requires an S3 bucket and DynamoDB table for remote state and locking:

```bash
# Create S3 bucket
aws s3api create-bucket \
  --bucket terraform-state-123456789012-us-east-1 \
  --region us-east-1

# Create DynamoDB lock table
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### 3. Enable AWS IAM Identity Center (SSO)

Required for the IAM permission-set module:

1. Go to **AWS Console** → **IAM Identity Center**
2. Click **Enable**
3. Choose **AWS IAM Identity Center directory**
4. Once enabled, go to **Settings** and copy your **Instance ARN**
5. Update the instance ARN in `accounts/dev/us-east-1/iam/permission-set/terragrunt.hcl`:

```hcl
inputs = {
  instance_arn = "arn:aws:sso:::instance/ssoins-xxxxxxxxxxxxxxxxxx"  # ← Your instance ARN
  ...
}
```

---

## Deployment

### Deploy All Components

```bash
cd accounts/dev/us-east-1

# Deploy all modules (VPC → EC2 → IAM)
terragrunt run-all plan
terragrunt run-all apply
```

### Deploy Individual Components

**VPC:**
```bash
cd accounts/dev/us-east-1/vpc
terragrunt plan
terragrunt apply
```

**EC2 (requires VPC):**
```bash
cd accounts/dev/us-east-1/ec2
terragrunt plan
terragrunt apply
```

**IAM Permission Sets (requires SSO enabled):**
```bash
cd accounts/dev/us-east-1/iam/permission-set
terragrunt plan
terragrunt apply
```

---

## What Gets Deployed

### VPC Module

| Resource | Details |
|---|---|
| VPC | `10.0.0.0/16`, DNS support enabled |
| Public subnets | `10.0.1.0/24` (us-east-1a), `10.0.2.0/24` (us-east-1b) |
| Private subnets | `10.0.11.0/24` (us-east-1a), `10.0.12.0/24` (us-east-1b) |
| Internet Gateway | Routes public traffic |
| Route Tables | Public + private routes configured |

### EC2 Module

| Resource | Details |
|---|---|
| EC2 Instance | Amazon Linux 2, t2.micro (configurable) |
| Security Group | SSH (port 22) ingress, all egress allowed |
| Auto-assigned Public IP | Enabled |
| Tags | Name + Environment |

### IAM Permission Set Module

| Resource | Details |
|---|---|
| Permission Set | ReadAll-LimitedWrite-Dev (configurable) |
| Inline Policy | JSON policy (see `policy.json`) |

---

## Cleanup

To destroy all infrastructure:

```bash
cd accounts/dev/us-east-1
terragrunt run-all destroy
```

To destroy specific components:

```bash
cd accounts/dev/us-east-1/ec2
terragrunt destroy
```
| Internet Gateway | Attached to VPC, routed from public subnets |
| NAT Gateway | Single instance (cost-optimised for dev), routed from private subnets |
| Route tables | Separate tables for public and private tiers |

### Outputs

After `apply`, Terragrunt surfaces these values:

```
vpc_id              = vpc-xxxxxxxxxxxxxxxxx
vpc_cidr_block      = 10.0.0.0/16
public_subnet_ids   = ["subnet-xxx", "subnet-yyy"]
private_subnet_ids  = ["subnet-aaa", "subnet-bbb"]
internet_gateway_id = igw-xxxxxxxxxxxxxxxxx
nat_gateway_ids     = ["nat-xxxxxxxxxxxxxxxxx"]
```

---

## Destroying Resources

```bash
cd accounts/dev/us-east-1/vpc
terragrunt destroy
```

---

## Adding a New Environment or Region

1. Copy the `accounts/dev/` folder to `accounts/staging/` (or another name).
2. Update `account.hcl` with the new account ID and region.
3. Add service folders under the new region directory.
4. Run `terragrunt apply` from any service folder — the root config is inherited automatically.

No changes to `_env/terragrunt.hcl` or `modules/` are needed.

---

## Tagging Strategy

All resources receive these tags automatically via the provider's `default_tags` block:

| Tag | Value |
|---|---|
| `ManagedBy` | `Terragrunt` |
| `Environment` | `dev` (or the account name) |
| `Repository` | `aws-intern-infrastructure` |

---

## Remote State

State is stored in S3 with DynamoDB locking:

- **Bucket:** `terraform-state-<account_id>-<region>`
- **Key:** `accounts/dev/us-east-1/vpc/terraform.tfstate`
- **Lock table:** `terraform-locks`

Each deployment unit gets its own state file, preventing blast radius from spreading across services.
