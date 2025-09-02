locals {

  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Extract the variables we need for easy access
  env = local.environment_vars.inputs.env
  region   = local.region_vars.inputs.region
  project_id = local.account_vars.inputs.project_id
  gcs_bucket_name = local.account_vars.inputs.gcs_bucket_name
}

generate "provider" {
  path = "provider.tf"
  if_exists = "skip"
  contents = <<EOF
provider "google" {
  project = "${local.project_id}"
  region  = "${local.region}"
}

provider "google-beta" {
  project = "${local.project_id}"
  region  = "${local.region}"
}
EOF
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "skip"
  contents = <<EOF
terraform {
  backend "gcs" {
    bucket = "${local.gcs_bucket_name}"
    prefix = "terragrunt/${path_relative_to_include()}"
  }
}
EOF
}

inputs = merge(
  local.account_vars.inputs,
  local.region_vars.inputs,
  local.environment_vars.inputs,
)
