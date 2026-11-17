// Versiion 1.0 - This is just to trigger this terragrunt.hcl

# Centralized Terragrunt caching to avoid deep .terragrunt-cache folders in every subdirectory
download_dir = "${get_parent_terragrunt_dir()}/.terragrunt-cache"

locals {
  # env.yaml holds REPLACE_ME_* placeholders; real values come from the gitignored env.local.yaml.
  env_vars = merge(yamldecode(file(find_in_parent_folders("env.yaml"))), try(yamldecode(file(replace(find_in_parent_folders("env.yaml"), "/\\.yaml$/", ".local.yaml"))), {}))
}

remote_state {
  backend = "s3"
  config = {
    bucket       = "${local.env_vars.aws_account_name}-${local.env_vars.env_name}-terraform-state"
    key          = "${local.env_vars.aws_account_id}/${path_relative_to_include()}/terraform.tfstate"
    region       = "${local.env_vars.aws_region}"
    encrypt      = true
    use_lockfile = true
    s3_bucket_tags = {
      "Name"       = "${local.env_vars.aws_account_name}-${local.env_vars.env_name}-terraform-state"
      "Stage"      = "${local.env_vars.stage}"
      "Attributes" = "infra-base"
      "Team"       = "DevOps"
      "Org"        = "SystemEngg"
    }
  }
}

terraform {
  extra_arguments "common_vars" {
    commands = get_terraform_commands_that_need_vars()
    arguments = [
      "-lock-timeout=1m",
      "-input=false",
      "-no-color"
    ]

    env_vars = {
      TF_VAR_stage        = "${local.env_vars.stage}"
      TF_VAR_account_name = "${local.env_vars.aws_account_name}"
      TF_VAR_region       = "${local.env_vars.aws_region}" # replaces the former common.tfvars (same value)
      TF_VAR_namespace    = "${local.env_vars.namespace}"
      TF_VAR_account_id   = "${local.env_vars.aws_account_id}"
      AWS_DEFAULT_REGION  = "${local.env_vars.aws_region}"
      # Shared provider cache to avoid re-downloading large binaries
      TF_PLUGIN_CACHE_DIR         = "${get_parent_terragrunt_dir()}/.terraform.d/plugin-cache"
      TERRAGRUNT_PLUGIN_CACHE_DIR = "${get_parent_terragrunt_dir()}/.terraform.d/plugin-cache"
      TERRAGRUNT_PROVIDER_CACHE   = "true"
    }
  }
  extra_arguments "init_cache" {
    commands = ["init", "plan", "apply"]
    env_vars = {
      TF_PLUGIN_CACHE_DIR         = "${get_parent_terragrunt_dir()}/.terraform.d/plugin-cache"
      TERRAGRUNT_PLUGIN_CACHE_DIR = "${get_parent_terragrunt_dir()}/.terraform.d/plugin-cache"
    }
  }
}


