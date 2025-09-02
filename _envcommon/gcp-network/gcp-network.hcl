locals {
  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Extract the variables we need for easy access
  env = local.environment_vars.inputs.env
  region = local.region_vars.inputs.region
  project_id = local.account_vars.inputs.project_id
  domain_name = local.account_vars.inputs.domain_name
  vpc_cidr_block = local.region_vars.inputs.vpc_cidr_block

  # Base source URL for VPC module
  base_source_url = "git::git@github.com:terraform-google-modules/terraform-google-network.git//modules/vpc"
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
