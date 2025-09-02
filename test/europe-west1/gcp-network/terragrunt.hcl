include "root" {
  path = find_in_parent_folders()
}

locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  account_vars     = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Extract out common variables for reuse
  env = local.environment_vars.inputs.env
  region = local.region_vars.inputs.region
  domain_name = local.account_vars.inputs.domain_name
  project_id = local.account_vars.inputs.project_id
  vpc_cidr_block = local.region_vars.inputs.vpc_cidr_block
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/gcp-network/gcp-network.hcl"
  expose = true
}

terraform {
  source = "${include.envcommon.locals.base_source_url}"
}

inputs = {
  project_id   = local.project_id
  network_name = "${local.domain_name}-${local.env}-vpc"
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name           = "${local.domain_name}-${local.env}-subnet-1"
      subnet_ip             = local.vpc_cidr_block
      subnet_region         = local.region
      subnet_private_access = "true"
      subnet_flow_logs      = "true"
      description           = "Subnet for ${local.domain_name} ${local.env} environment"
    }
  ]

  secondary_ranges = {
    "${local.domain_name}-${local.env}-subnet-1" = [
      {
        range_name    = "${local.domain_name}-${local.env}-pods"
        ip_cidr_range = "10.80.0.0/14"
      },
      {
        range_name    = "${local.domain_name}-${local.env}-services"
        ip_cidr_range = "10.84.0.0/20"
      }
    ]
  }

  # Firewall rules
  firewall_rules = [
    {
      name        = "${local.domain_name}-${local.env}-allow-internal"
      direction   = "INGRESS"
      priority    = 1000
      ranges      = [local.vpc_cidr_block]
      allow = [
        {
          protocol = "tcp"
          ports    = ["0-65535"]
        },
        {
          protocol = "udp"
          ports    = ["0-65535"]
        },
        {
          protocol = "icmp"
        }
      ]
    },
    {
      name        = "${local.domain_name}-${local.env}-allow-ssh"
      direction   = "INGRESS"
      priority    = 1000
      ranges      = ["0.0.0.0/0"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["22"]
        }
      ]
    }
  ]

  # Labels
  labels = {
    environment = local.env
    domain      = local.domain_name
    managed_by  = "terragrunt"
  }
}

generate "provider_default" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
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
