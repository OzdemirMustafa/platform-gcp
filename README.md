# Platform GCP - Infrastructure as Code

This repository contains the Infrastructure as Code (IaC) structure for managing platform components on Google Cloud Platform (GCP) using Terraform and Terragrunt.

## 📋 Table of Contents

- [Project Structure](#project-structure)
- [Environments](#environments)
- [Prerequisites](#prerequisites)
- [Setup and Configuration](#setup-and-configuration)
- [Deployment Guide](#deployment-guide)
- [Configuration Details](#configuration-details)
- [Security](#security)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## 🏗️ Project Structure

```
platform-gcp/
├── terragrunt.hcl              # Main terragrunt configuration
├── _envcommon/                 # Shared configurations across environments
│   ├── gcp-network/
│   │   └── gcp-network.hcl    # Network common configuration
│   └── gcp-gke/
│       └── gcp-gke.hcl        # GKE common configuration
├── test/                       # Test environment
│   ├── account.hcl            # Account level variables
│   ├── env.hcl                # Environment variables
│   └── europe-west1/          # Region configuration
│       ├── region.hcl         # Region variables
│       ├── gcp-network/       # VPC Network module
│       └── gcp-gke/           # GKE cluster module
├── preprod/                    # Pre-production environment
│   ├── account.hcl
│   ├── env.hcl
│   └── europe-west1/
│       ├── region.hcl
│       ├── gcp-network/
│       └── gcp-gke/
└── prod/                       # Production environment
    ├── account.hcl
    ├── env.hcl
    └── europe-west1/
        ├── region.hcl
        ├── gcp-network/
        └── gcp-gke/
```

### Directory Descriptions

- **`_envcommon/`**: Common Terragrunt configurations shared across all environments
- **`test/`, `preprod/`, `prod/`**: Isolated environments with their own configurations
- **`account.hcl`**: Account-level variables (GCP project, state bucket, etc.)
- **`env.hcl`**: Environment-specific variables (env name, upstream env)
- **`region.hcl`**: Region-specific variables (region, zone, CIDR blocks)

## 🌍 Environments

### Test Environment
- **Purpose**: Development and testing activities
- **VPC CIDR**: `10.79.0.0/18`
- **Characteristics**: Minimal resource usage, fast deployment

### Pre-Production Environment
- **Purpose**: Final testing and staging before production
- **VPC CIDR**: `10.80.0.0/18`
- **Characteristics**: Production-like structure, performance testing

### Production Environment
- **Purpose**: Live system and customer traffic
- **VPC CIDR**: `10.81.0.0/18`
- **Characteristics**: High availability, auto-scaling, monitoring

## 🛠️ Prerequisites

### Required Tools and Versions

| Tool | Minimum Version | Installation |
|------|-----------------|--------------|
| Google Cloud SDK | Latest | [Installation Guide](https://cloud.google.com/sdk/docs/install) |
| Terraform | >= 1.0 | [terraform.io](https://www.terraform.io/downloads) |
| Terragrunt | >= 0.50 | [terragrunt.io](https://terragrunt.gruntwork.io/docs/getting-started/install/) |
| kubectl | >= 1.24 | [kubernetes.io](https://kubernetes.io/docs/tasks/tools/) |
| jq | >= 1.6 | `brew install jq` (MacOS) |

### GCP Permissions

Minimum required IAM roles:
- `roles/compute.admin`
- `roles/container.admin`
- `roles/iam.serviceAccountAdmin`
- `roles/storage.admin`
- `roles/resourcemanager.projectIamAdmin`

## 🚀 Setup and Configuration

### 1. Environment Variables Configuration

Create a `.env` file or add to your shell profile:

```bash
# GCP Core Variables
export GCP_PROJECT_ID="your-project-id"
export GCP_ORG_ID="your-org-id"
export GCP_BILLING_ACCOUNT="your-billing-account"

# Region and Zone
export GCP_REGION="europe-west1"
export GCP_ZONE="europe-west1-b"

# Terraform State
export BUCKET_NAME="${GCP_PROJECT_ID}-terraform-state"

# Domain
export DOMAIN_NAME="your-domain"
```

### 2. GCP Authentication

```bash
# Login to GCP
gcloud auth login

# Set Application Default Credentials
gcloud auth application-default login

# Set the project
gcloud config set project $GCP_PROJECT_ID
```

### 3. State Bucket Creation

```bash
# Create GCS bucket for Terraform state
gsutil mb -p $GCP_PROJECT_ID \
  -c STANDARD \
  -l $GCP_REGION \
  gs://$BUCKET_NAME

# Enable versioning
gsutil versioning set on gs://$BUCKET_NAME

# Add lifecycle policy (optional)
cat > lifecycle.json <<EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {
          "age": 90,
          "isLive": false
        }
      }
    ]
  }
}
EOF

gsutil lifecycle set lifecycle.json gs://$BUCKET_NAME
```

## 📦 Deployment Guide

### Full Environment Deployment

```bash
# 1. Deploy network infrastructure
cd platform-gcp/<environment>/europe-west1/gcp-network
terragrunt init
terragrunt plan
terragrunt apply

# 2. Deploy GKE cluster
cd ../gcp-gke
terragrunt init
terragrunt plan
terragrunt apply

# 3. Connect to the cluster
gcloud container clusters get-credentials gke-gcp-<environment> \
  --region $GCP_REGION \
  --project $GCP_PROJECT_ID

# 4. Test the connection
kubectl cluster-info
kubectl get nodes
```

### Environment-Specific Deployment

#### Test Environment
```bash
cd platform-gcp/test/europe-west1
terragrunt run-all apply
```

#### Pre-Production Environment
```bash
cd platform-gcp/preprod/europe-west1
terragrunt run-all apply --terragrunt-non-interactive
```

#### Production Environment
```bash
cd platform-gcp/prod/europe-west1
# Approval workflow for production
terragrunt run-all plan -out=tfplan
# Review the plan
terragrunt run-all apply tfplan
```

## ⚙️ Configuration Details

### Network Configuration

| Feature | Test | Pre-Prod | Prod |
|---------|------|----------|------|
| VPC CIDR | 10.79.0.0/18 | 10.80.0.0/18 | 10.81.0.0/18 |
| Pods CIDR | 10.80.0.0/14 | 10.84.0.0/14 | 10.88.0.0/14 |
| Services CIDR | 10.84.0.0/20 | 10.88.0.0/20 | 10.92.0.0/20 |
| NAT Gateway | Single | Single | Multi-zone |
| Firewall Rules | Basic | Enhanced | Strict |

### GKE Cluster Features

#### Node Pool Configuration

| Feature | Test | Pre-Prod | Prod |
|---------|------|----------|------|
| Machine Type | e2-standard-8 | n2-standard-16 | n2-standard-32 |
| Min Nodes | 1 | 2 | 3 |
| Max Nodes | 3 | 10 | 50 |
| Disk Size | 100GB | 200GB | 500GB |
| Disk Type | pd-standard | pd-ssd | pd-ssd |
| Auto Repair | ✓ | ✓ | ✓ |
| Auto Upgrade | ✓ | ✓ | Manual |

#### Cluster Features

- **Workload Identity**: Enabled
- **Network Policy**: Calico
- **Binary Authorization**: Production only
- **Private Cluster**: All environments
- **Authorized Networks**: Configured per environment
- **Pod Security Policy**: Enabled
- **Shielded Nodes**: Production only

### Monitoring and Logging

```yaml
monitoring:
  - Cloud Monitoring
  - Prometheus (in-cluster)
  - Custom metrics

logging:
  - Cloud Logging
  - Log aggregation
  - Log retention: 30 days (test), 90 days (prod)
```

## 🔐 Security

### Best Practices

1. **Secrets Management**
   - Google Secret Manager integration
   - Workload Identity federation
   - Encrypted environment variables

2. **Network Security**
   - Private GKE clusters
   - Cloud NAT for egress traffic
   - Firewall rules with least privilege
   - Network segmentation

3. **Access Control**
   - RBAC policies
   - IAM bindings
   - Service Account key rotation

### Security Checklist

- [ ] All sensitive data retrieved from environment variables
- [ ] State bucket encrypted
- [ ] Network policies enabled
- [ ] Pod Security Policies configured
- [ ] Audit logging enabled
- [ ] Vulnerability scanning active

## 🔧 Troubleshooting

### Common Issues and Solutions

#### 1. State Lock Error
```bash
# Manually remove the lock
terragrunt force-unlock <lock-id>
```

#### 2. Insufficient Quota
```bash
# Check quotas
gcloud compute project-info describe --project=$GCP_PROJECT_ID
```

#### 3. Cluster Connection Issue
```bash
# Refresh credentials
gcloud container clusters get-credentials gke-gcp-<env> \
  --region $GCP_REGION \
  --project $GCP_PROJECT_ID

# Check current context
kubectl config current-context
```

### Debug Commands

```bash
# Terragrunt debug output
export TF_LOG=DEBUG
terragrunt apply

# GKE cluster status
gcloud container clusters describe gke-gcp-<env> \
  --region $GCP_REGION

# Network connectivity test
gcloud compute networks vpc-access connectors describe <connector-name> \
  --region $GCP_REGION
```

## 🤝 Contributing

### Git Workflow

1. Create a feature branch
```bash
git checkout -b feature/your-feature
```

2. Commit your changes
```bash
git commit -m "feat: add new feature"
```

3. Push the branch
```bash
git push origin feature/your-feature
```

4. Open a Pull Request

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `refactor`: Code refactoring
- `test`: Adding/fixing tests
- `chore`: Maintenance

## 📚 Additional Resources

- [Terraform GCP Provider Docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/docs/)
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
- [GCP Security Best Practices](https://cloud.google.com/security/best-practices)


**Last Updated**: 2025-09-03
**Version**: 1.0.0