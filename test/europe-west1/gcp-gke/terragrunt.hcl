include "root" {
  path = find_in_parent_folders()
}

locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  account_vars     = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Extract out common variables for reuse
  env         = local.environment_vars.inputs.env
  region      = local.region_vars.inputs.region
  zone        = local.region_vars.inputs.zone
  domain_name = local.account_vars.inputs.domain_name
  project_id  = local.account_vars.inputs.project_id
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/gcp-gke/gcp-gke.hcl"
  expose = true
}

terraform {
  source = "${include.envcommon.locals.base_source_url}"
}

inputs = {
  name                     = "gke-${local.domain_name}-${local.env}"
  project_id               = local.project_id
  region                   = local.region
  zone                     = local.zone
  network                  = dependency.vpc.outputs.network_name
  subnetwork               = dependency.vpc.outputs.subnets_names[0]
  
  # Cluster configuration matching the screenshot
  cluster_autoscaling = {
    enabled = true
    min_cpu_cores = 1
    max_cpu_cores = 8
    min_memory_gb = 1
    max_memory_gb = 32
  }

  # Node pool configuration
  node_pools = [
    {
      name         = "default-node-pool"
      machine_type = "e2-standard-8"
      min_count    = 1
      max_count    = 3
      disk_size_gb = 100
      disk_type    = "pd-standard"
      auto_repair  = true
      auto_upgrade = true
    }
  ]

  # Security and networking
  network_policy = true
  http_load_balancing = true
  horizontal_pod_autoscaling = true
  kubernetes_dashboard = false

  # Labels and tags
  cluster_resource_labels = {
    environment = local.env
    domain      = local.domain_name
    managed_by  = "terragrunt"
  }

  node_pools_labels = {
    all = {
      environment = local.env
      domain      = local.domain_name
    }
  }

  node_pools_tags = {
    all = [
      "gke-${local.domain_name}-${local.env}",
    ]
  }
}

dependency "vpc" {
  config_path = "../gcp-network"
  mock_outputs = {
    network_name    = "gcp-test-vpc"
    subnets_names   = ["gcp-test-subnet-1"]
    subnets_ips     = ["10.79.0.0/18"]
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
