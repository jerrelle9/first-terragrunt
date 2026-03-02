# aws-intern-infrastructure

Enterprise-style AWS Infrastructure as Code repository using **Terraform** and **Terragrunt**. Phase 1 deploys a single VPC in the `dev` account (`us-east-1`), establishing the folder conventions and module patterns used for all future projects.

---

## Repository Structure

```
aws-intern-infrastructure/
├── _env/
│   └── terragrunt.hcl          # Root config: provider, remote state (inherited by all modules)
├── accounts/
│   └── dev/
│       ├── account.hcl         # Account-level vars: name, ID, region
│       └── us-east-1/
│           └── vpc/
│               └── terragrunt.hcl  # VPC deployment inputs for dev/us-east-1
└── modules/
    └── vpc/
        ├── main.tf             # VPC, subnets, IGW, NAT Gateway, route tables
        ├── variables.tf        # Input variable declarations
        └── outputs.tf          # Exported values (VPC ID, subnet IDs, etc.)
```

### Design Conventions

| Layer | Purpose |
|---|---|
| `_env/terragrunt.hcl` | Single source of truth for provider config and S3 remote state |
| `accounts/<env>/account.hcl` | Per-account variables (account ID, region) — no duplication |
| `accounts/<env>/<region>/<service>/terragrunt.hcl` | Deployment unit — passes inputs to a module |
| `modules/<service>/` | Reusable, environment-agnostic Terraform module |

---

## Prerequisites

| Tool | Version |
|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/install) | `>= 1.5` |
| [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) | `>= 0.50` |
| [AWS CLI](https://aws.amazon.com/cli/) | `>= 2.x` |

AWS credentials must be available in your environment (e.g. `aws configure`, environment variables, or an IAM role).

---

## Bootstrap (first-time only)

Terragrunt manages remote state automatically, but the S3 bucket and DynamoDB table must exist before the first `apply`. Create them once per account:

```bash
# Replace with your actual account ID
aws s3api create-bucket \
  --bucket terraform-state-123456789012-us-east-1 \
  --region us-east-1

aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

Then update `accounts/dev/account.hcl` with your real AWS account ID:

```hcl
locals {
  account_name = "dev"
  account_id   = "123456789012"   # ← your account ID here
  aws_region   = "us-east-1"
}
```

---

## Deploying the Dev VPC

```bash
# Navigate to the VPC deployment unit
cd accounts/dev/us-east-1/vpc

# Preview the plan
terragrunt plan

# Apply
terragrunt apply
```

Terragrunt will automatically generate `provider.tf` and `backend.tf` before running Terraform.

### What Gets Deployed

| Resource | Details |
|---|---|
| VPC | `10.0.0.0/16`, DNS support + hostnames enabled |
| Public subnets | `10.0.1.0/24`, `10.0.2.0/24` — `us-east-1a` / `us-east-1b` |
| Private subnets | `10.0.11.0/24`, `10.0.12.0/24` — `us-east-1a` / `us-east-1b` |
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
