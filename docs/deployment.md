# Deployment & Scaling

This document covers how to deploy Muslim AI on Microsoft Azure, from a local development environment through to production, along with cost-saving guidance and SaaS configuration options.

---

## 1. Environment Overview

| Environment | Purpose | Azure Resources |
|---|---|---|
| **Local / Dev** | Feature development, unit testing | Docker Compose (no GPU required – use CPU inference with Llama 3 8B Q4 GGUF) |
| **Staging** | Integration testing, QA | Single NC4as T4 v3 VM (1× T4 GPU) + Azure Cognitive Search Free tier |
| **Training** | Fine-tuning experiments | NC24ads A100 v4 or spot ND A100 v4 cluster (temporary) |
| **Production** | Live SaaS serving | AKS cluster with GPU node pool + Azure Cognitive Search Standard tier |

---

## 2. Azure Resource Architecture

```
Azure Subscription
│
├── Resource Group: rg-muslimAI-prod
│   ├── Azure Kubernetes Service (AKS)
│   │   ├── System Node Pool (Standard_D4s_v3 × 3)
│   │   └── GPU Node Pool   (Standard_NC6s_v3 × 2, autoscale 1–4)
│   │
│   ├── Azure Container Registry (ACR)
│   │
│   ├── Azure API Management (APIM)
│   │
│   ├── Azure AD B2C Tenant
│   │
│   ├── Azure Blob Storage
│   │   ├── Container: islamic-corpus-raw
│   │   └── Container: islamic-corpus-indexed
│   │
│   ├── Azure Cognitive Search (Standard S1)
│   │   └── Index: muslim-ai-vectors
│   │
│   ├── Azure Key Vault
│   │
│   ├── Azure Application Insights
│   │
│   └── Azure Database for PostgreSQL (Flexible)
│       └── Stores: user accounts, subscription info, conversation history
│
└── Resource Group: rg-muslimAI-dev
    └── (mirrors prod at smaller SKUs)
```

---

## 3. Step-by-Step Deployment

### Prerequisites

- Azure CLI (`az`) installed and logged in.
- Docker Desktop or Docker CLI.
- `kubectl` installed.
- Python 3.11+.

### 3.1 Clone and Configure

```bash
git clone https://github.com/orkinosai25-org/muslim-ai.git
cd muslim-ai

# Copy environment template
cp .env.example .env
# Edit .env with your Azure credentials, resource names, and secrets
```

### 3.2 Local Development (CPU-only)

```bash
# Pull a quantised Llama 3 8B model for local inference
docker pull ollama/ollama
docker run -d -v ollama:/root/.ollama -p 11434:11434 --name ollama ollama/ollama
docker exec -it ollama ollama pull llama3:8b

# Start the API and dependencies
docker compose up --build
```

The API will be available at `http://localhost:8000`.

### 3.3 Build & Push Docker Image

```bash
# Log in to ACR
az acr login --name <your-acr-name>

# Build and push
docker build -t <your-acr-name>.azurecr.io/muslim-ai-api:latest .
docker push <your-acr-name>.azurecr.io/muslim-ai-api:latest
```

### 3.4 Provision AKS

```bash
# Create resource group
az group create --name rg-muslimAI-prod --location eastus

# Create AKS cluster with a GPU node pool
az aks create \
  --resource-group rg-muslimAI-prod \
  --name aks-muslimAI \
  --node-count 3 \
  --node-vm-size Standard_D4s_v3 \
  --enable-managed-identity \
  --attach-acr <your-acr-name>

# Add GPU node pool
az aks nodepool add \
  --resource-group rg-muslimAI-prod \
  --cluster-name aks-muslimAI \
  --name gpupool \
  --node-count 1 \
  --node-vm-size Standard_NC6s_v3 \
  --node-taints sku=gpu:NoSchedule \
  --labels sku=gpu \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 4

# Get credentials
az aks get-credentials --resource-group rg-muslimAI-prod --name aks-muslimAI
```

### 3.5 Deploy to AKS

```bash
# Apply Kubernetes manifests (stored in /k8s/)
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secrets.yaml       # references Key Vault via CSI driver
kubectl apply -f k8s/llama3-deployment.yaml
kubectl apply -f k8s/api-deployment.yaml
kubectl apply -f k8s/ingress.yaml
```

### 3.6 Index the Islamic Corpus

```bash
# Upload raw corpus files to Blob Storage
az storage blob upload-batch \
  --destination islamic-corpus-raw \
  --source ./corpus/ \
  --account-name <storage-account>

# Run the indexing job (chunks, embeds, and pushes to Azure Cognitive Search)
python scripts/index_corpus.py \
  --storage-account <storage-account> \
  --search-service <search-service-name> \
  --index-name muslim-ai-vectors
```

---

## 4. Azure Cost Management & Savings

### Estimated Monthly Costs (Production, USD)

| Service | SKU / Config | Est. Cost/mo |
|---|---|---|
| AKS – System nodes | 3× D4s_v3 | ~$300 |
| AKS – GPU node pool | 1–2× NC6s_v3 (autoscale) | ~$600–$1,200 |
| Azure Cognitive Search | Standard S1 | ~$250 |
| Azure Blob Storage | 500 GB LRS | ~$10 |
| Azure APIM | Developer/Consumption tier | ~$50 |
| Azure AD B2C | First 50k MAU free | $0–$50 |
| PostgreSQL Flexible | Burstable B2ms | ~$50 |
| Application Insights | Pay-per-use | ~$20 |
| **Total (approx.)** | | **~$1,300–$1,900/mo** |

> These are rough estimates. Use the [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/) for accurate quotes.

### Cost-Saving Tips

1. **Use Azure Spot VMs / Spot Node Pools** for the GPU inference layer. Spot pricing can reduce GPU costs by 60–80%.
2. **Enable AKS Cluster Autoscaler** to scale the GPU node pool to zero overnight or during low traffic.
3. **Use Azure Savings Plans / Reserved Instances** for the system node pool if traffic is predictable.
4. **Use Llama 3 8B for simple queries** and only route complex reasoning to 70B.
5. **Cache common answers** (prayer times, well-known Hadith) with Azure Cache for Redis to reduce LLM calls.
6. **Apply for Microsoft for Nonprofits** or **Azure for Startups** credits if eligible.
7. **Use Azure Cognitive Search Free tier** (1 index, 50 MB) for development and staging.

---

## 5. SaaS Configuration Options

### Multi-Tenant Architecture

Each tenant (school, mosque, organisation) gets:

- A dedicated API key (managed in Azure APIM).
- An isolated conversation history partition in PostgreSQL.
- Optional: a custom system prompt overlay (e.g., specific school curriculum focus).
- Shared Llama 3 inference layer (cost sharing).

### Subscription Plans (Example)

| Plan | Features | Price (suggested) |
|---|---|---|
| **Free** | 50 queries/month, English only | $0 |
| **Individual** | 1,000 queries/month, multi-language | $5/month |
| **Family** | 5 users, 5,000 queries/month | $15/month |
| **Institution** | Unlimited queries, admin panel, custom prompt | $99/month |

### Donation Flow

For mosques and non-profits, a donation-based access model is supported:

- Users donate via Stripe or PayPal integration.
- Donation amount determines monthly query credit.
- Surplus donations fund scholar review hours and corpus expansion.

---

## 6. Continuous Integration / Continuous Deployment (CI/CD)

A GitHub Actions pipeline is recommended:

```
Push to main branch
   │
   ▼
CI: Run unit tests + linting
   │
   ▼
Build Docker image & push to ACR
   │
   ▼
Deploy to AKS staging namespace
   │
   ▼
Run integration tests (smoke tests against staging API)
   │
   ▼
Manual approval gate (scholar review if corpus changed)
   │
   ▼
Deploy to AKS production namespace
```
