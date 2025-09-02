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
  zone = local.region_vars.inputs.zone
  project_id = local.account_vars.inputs.project_id
  domain_name = local.account_vars.inputs.domain_name

  # Base source URL for GKE module
  base_source_url = "git::git@github.com:terraform-google-modules/terraform-google-kubernetes-engine.git//modules/beta-autopilot-cluster"
}

inputs = {
  name                     = "gke-${local.domain_name}-${local.env}"
  project_id               = local.project_id
  region                   = local.region
  zone                     = local.zone
  network                  = "default"
  subnetwork               = "default"
  
  # Cluster configuration
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
      machine_type = "e2-standard-2"
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
