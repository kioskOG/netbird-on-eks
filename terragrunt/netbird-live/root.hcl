# NetBird Dedicated Terragrunt Live Root
# Enforces complete state isolation from AWS infrastructure state.
# Baseline: Terraform 1.16.5, Terragrunt 1.1.6, NetBird Provider 0.0.11

download_dir = "${get_parent_terragrunt_dir()}/.terragrunt-cache"

locals {
  # Load account and environment configurations from hierarchy. Committed YAML holds
  # REPLACE_ME_* placeholders; a gitignored <name>.local.yaml next to it overrides them.
  account_vars = merge(yamldecode(file(find_in_parent_folders("account.yaml", "${get_terragrunt_dir()}/account.yaml"))), try(yamldecode(file(replace(find_in_parent_folders("account.yaml", "${get_terragrunt_dir()}/account.yaml"), "/\\.yaml$/", ".local.yaml"))), {}))
  env_vars     = merge(yamldecode(file(find_in_parent_folders("env.yaml", "${get_terragrunt_dir()}/env.yaml"))), try(yamldecode(file(replace(find_in_parent_folders("env.yaml", "${get_terragrunt_dir()}/env.yaml"), "/\\.yaml$/", ".local.yaml"))), {}))

  aws_account_id   = local.account_vars.aws_account_id
  aws_account_name = local.account_vars.aws_account_name
  aws_region       = local.account_vars.aws_region
  env_name         = local.env_vars.env_name
  management_url   = local.env_vars.management_url
}

# Generate netbird provider for all child units.
# The management_url is dynamically populated from environment context.
# Admin token is deliberately NOT written to HCL or state;
# the provider automatically resolves NB_PAT from the execution environment.
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "netbird" {
  management_url = "${local.management_url}"
  # Admin PAT is supplied via the NB_PAT environment variable.
  # No credentials are hardcoded or tracked in version control.
}
EOF
}

# S3 remote state backend with logical isolation from AWS state.
# Key prefix is explicitly namespaced under '${local.aws_account_id}/netbird/'.
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket       = "${local.aws_account_name}-${local.env_name}-terraform-state"
    key          = "${local.aws_account_id}/netbird/${path_relative_to_include()}/terraform.tfstate"
    region       = "${local.aws_region}"
    encrypt      = true
    use_lockfile = true
    s3_bucket_tags = {
      "Name"      = "${local.aws_account_name}-${local.env_name}-netbird-terraform-state"
      "Stage"     = "${local.env_name}"
      "Team"      = "DevOps"
      "Org"       = "SystemEngg"
      "Component" = "netbird-overlay"
    }
  }
}

terraform {
  # Terraform fails init if TF_PLUGIN_CACHE_DIR does not exist; create it on fresh checkouts.
  before_hook "plugin_cache_dir" {
    commands = ["init"]
    execute  = ["mkdir", "-p", "${get_parent_terragrunt_dir()}/.terraform.d/plugin-cache"]
  }

  # A revoked/invalid NB_PAT makes NetBird return 404, which the provider reads as
  # "resource deleted" and plans to recreate everything. Stop before that happens.
  before_hook "netbird_auth_check" {
    commands = ["plan", "apply", "destroy", "refresh", "import"]
    execute  = ["sh", "${get_parent_terragrunt_dir()}/scripts/check-netbird-auth.sh", local.management_url]
  }

  extra_arguments "common_cli_args" {
    commands = get_terraform_commands_that_need_vars()
    arguments = [
      "-lock-timeout=1m",
      "-input=false",
      "-no-color"
    ]
  }

  # Shared provider cache so every unit reuses one downloaded provider binary.
  extra_arguments "plugin_cache" {
    commands = concat(["init"], get_terraform_commands_that_need_vars())
    env_vars = {
      TF_PLUGIN_CACHE_DIR = "${get_parent_terragrunt_dir()}/.terraform.d/plugin-cache"
    }
  }
}
