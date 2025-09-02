# Platform GCP

Bu klasör GCP (Google Cloud Platform) üzerinde çalışan platform bileşenlerini içerir.

## Yapı

```
platform-gcp/
├── terragrunt.hcl              # Ana terragrunt konfigürasyonu
├── test/                       # Test environment
│   ├── account.hcl            # Account seviyesi değişkenler
│   ├── env.hcl                # Environment değişkenleri
│   └── europe-west1/          # Region konfigürasyonu
│       ├── region.hcl         # Region değişkenleri
│       ├── gcp-network/       # VPC Network
│       │   └── terragrunt.hcl # Network terragrunt konfigürasyonu
│       └── gcp-gke/           # GKE cluster
│           └── terragrunt.hcl # GKE terragrunt konfigürasyonu
├── _envcommon/                # Ortak environment konfigürasyonları
│   ├── gcp-network/
│   │   └── gcp-network.hcl    # Network ortak konfigürasyonu
│   └── gcp-gke/
│       └── gcp-gke.hcl        # GKE ortak konfigürasyonu
└── shared/                    # Paylaşılan kaynaklar
```

## GKE Cluster Konfigürasyonu

Resimdeki `gke-gitops-test` cluster'ına benzer şekilde yapılandırılmıştır:

- **Cluster Name**: `gke-gcp-test`
- **Location**: `europe-west1-b`
- **Node Count**: 1
- **Total vCPUs**: 8
- **Total Memory**: 32 GB
- **Machine Type**: `e2-standard-8`

## Kullanım

### Gerekli Araçlar

- Google Cloud SDK
- Terraform >= 1.0
- Terragrunt >= 0.50
- kubectl

### Environment Variables

Konfigürasyon dosyaları environment variable'ları kullanır. `.zshrc` dosyasında tanımlı değişkenler:

```bash
export GCP_PROJECT_ID="grand-harbor-470517-i5"
export BUCKET_NAME="${GCP_PROJECT_ID}-terraform-state"
export GCP_REGION="europe-west1"
export GCP_ZONE="europe-west1-b"
```

### Deployment

1. Environment variable'ları yükleyin:
```bash
source ~/.zshrc
```

2. GCP projesini ayarlayın:
```bash
gcloud config set project $GCP_PROJECT_ID
```

3. GCS bucket'ını oluşturun (state dosyaları için):
```bash
gsutil mb gs://$BUCKET_NAME
```

4. Terragrunt ile deploy edin (önce network, sonra GKE):
```bash
# Network'i deploy et
cd platform-gcp/test/europe-west1/gcp-network
terragrunt plan
terragrunt apply

# GKE'yi deploy et
cd ../gcp-gke
terragrunt plan
terragrunt apply
```

5. Cluster'a bağlanın:
```bash
gcloud container clusters get-credentials gke-gcp-test --region $GCP_REGION --project $GCP_PROJECT_ID
```

## Konfigürasyon Detayları

### Network Özellikleri

- **VPC Name**: `gcp-test-vpc`
- **Subnet Name**: `gcp-test-subnet-1`
- **CIDR Block**: `10.79.0.0/18`
- **Secondary Ranges**:
  - Pods: `10.80.0.0/14`
  - Services: `10.84.0.0/20`
- **Firewall Rules**: Internal traffic, SSH access

### Cluster Özellikleri

- **Autopilot Mode**: Enabled
- **Network Policy**: Enabled
- **HTTP Load Balancing**: Enabled
- **Horizontal Pod Autoscaling**: Enabled
- **Cluster Autoscaling**: 1-8 vCPU, 1-32GB RAM

### Node Pool

- **Machine Type**: e2-standard-8 (8 vCPU, 32GB RAM)
- **Min Nodes**: 1
- **Max Nodes**: 3
- **Disk Size**: 100GB
- **Auto Repair**: Enabled
- **Auto Upgrade**: Enabled

### Labels ve Tags

- Environment: test
- Domain: gcp
- Managed by: terragrunt