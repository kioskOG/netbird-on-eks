include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../..//netbird-terraform/modules/token"
}

dependency "users" {
  config_path = "../users"
  mock_outputs = {
    user_ids = {
      cicd_bot = "mock-user-cicd-bot"
    }
  }
}

inputs = {
  items = {
    "cicd_pat" = {
      name            = "cicd-pipeline-token"
      expiration_days = 90
      user_id         = dependency.users.outputs.user_ids["cicd_bot"]
    }
  }
}
