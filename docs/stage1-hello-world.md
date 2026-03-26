# Stage 1: Hello-World Chatbot with Llama 3 on Azure

This document covers the **Stage 1** milestone: deploying a minimal Llama 3-powered Islamic chatbot ("NurAI") on Azure, complete with a simple chat UI, automated deployment, and cost-saving guardrails.

---

## Table of Contents

1. [Overview](#overview)
2. [Repository Structure](#repository-structure)
3. [Local Development (Docker Compose)](#local-development-docker-compose)
4. [Azure VM Deployment](#azure-vm-deployment)
   - [Prerequisites](#prerequisites)
   - [Manual Deployment](#manual-deployment-bash)
   - [Automated Deployment (GitHub Actions)](#automated-deployment-github-actions)
5. [Chat UI](#chat-ui)
6. [Cost Management](#cost-management)
7. [Configuration Reference](#configuration-reference)
8. [Troubleshooting](#troubleshooting)
9. [Next Steps (Stage 2)](#next-steps-stage-2)

---

## Overview

Stage 1 delivers:

| Component | Technology | Purpose |
|---|---|---|
| **LLM inference** | [Ollama](https://ollama.com) + Llama 3 8B | Serves the language model via a local REST API |
| **Chat UI** | [Streamlit](https://streamlit.io) | Browser-based Q&A interface |
| **Azure host** | Ubuntu 24.04 VM (NC4as T4 v3) | GPU-accelerated inference on Azure |
| **Deployment automation** | GitHub Actions / Bash | Reproducible one-command deploys |
| **Credit protection** | Azure auto-shutdown + idle-shutdown timer | Stops the VM when idle |

The architecture is intentionally minimal — no vector DB, no RAG, no auth — to establish a working baseline that later stages build upon.

```
Browser ──HTTPS──► Streamlit (port 8501)
                       │
                       ▼
                  Ollama API (port 11434)
                       │
                       ▼
                  llama3:8b (local inference)
```

---

## Repository Structure

Files added in Stage 1:

```
muslim-ai/
├── app/
│   ├── app.py               # Streamlit chat UI
│   └── requirements.txt     # Python dependencies
├── scripts/
│   ├── deploy-azure-vm.sh   # Provision Azure VM + enable auto-shutdown
│   ├── setup-ollama.sh      # Cloud-init bootstrap (installs Ollama + Streamlit)
│   └── idle-shutdown.sh     # Shuts VM down after N minutes of inactivity
├── .github/workflows/
│   └── deploy-stage1.yml    # GitHub Actions workflow (deploy/start/stop/destroy)
├── docker-compose.yml       # Local dev: Ollama + Streamlit
├── Dockerfile               # Container image for the Streamlit app
├── .env.example             # Environment variable template
└── docs/
    └── stage1-hello-world.md  # This document
```

---

## Local Development (Docker Compose)

The quickest way to run NurAI on your laptop (CPU inference — no GPU required).

### Requirements

- Docker Desktop ≥ 4.x (or Docker Engine + Compose plugin)
- ~5 GB free disk space for the Llama 3 8B Q4 model

### Steps

```bash
# 1. Clone the repo
git clone https://github.com/orkinosai25-org/muslim-ai.git
cd muslim-ai

# 2. Start Ollama and the Streamlit UI
docker compose up --build -d

# 3. Pull the Llama 3 model (first run only — ~4 GB download)
docker compose exec ollama ollama pull llama3:8b

# 4. Open the chat UI
open http://localhost:8501
```

> **Note:** First-time model pull may take several minutes depending on your connection. Subsequent starts are instant (the model is cached in the `ollama_data` Docker volume).

To stop (and preserve the model cache):

```bash
docker compose down
```

---

## Azure VM Deployment

### Prerequisites

- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed (`az --version`)
- Active Azure subscription with **GPU quota** for `Standard_NC4as_T4_v3` in your target region
  - Check quota: `az vm list-usage --location eastus -o table | grep NC4`
  - If quota is insufficient, use `Standard_D4s_v3` (CPU-only, slower)
- SSH key pair (`~/.ssh/id_rsa` / `~/.ssh/id_rsa.pub`)
- Authenticated Azure CLI: `az login`

### Manual Deployment (Bash)

```bash
# 1. Copy the environment template
cp .env.example .env

# 2. Edit .env with your Azure subscription ID and preferences
#    Required: AZURE_SUBSCRIPTION_ID
nano .env

# 3. Make the script executable and run it
chmod +x scripts/deploy-azure-vm.sh
./scripts/deploy-azure-vm.sh
```

The script will:
1. Create the resource group `rg-muslimAI-stage1`
2. Provision the VM with Ubuntu 24.04
3. Pass `scripts/setup-ollama.sh` as cloud-init to bootstrap Ollama automatically
4. Open ports 11434 (Ollama) and 8501 (Streamlit)
5. Enable the Azure auto-shutdown schedule (default: 22:00 UTC)

**Check bootstrap progress:**

```bash
ssh azureuser@<vm-ip> 'tail -f /var/log/cloud-init-output.log'
```

Once cloud-init completes (usually 5–10 minutes), the Streamlit UI will be live at:

```
http://<vm-public-ip>:8501
```

### Automated Deployment (GitHub Actions)

The workflow `.github/workflows/deploy-stage1.yml` supports four actions triggered manually via **Actions → Stage 1 — Deploy Hello-World Chatbot → Run workflow**.

#### Required GitHub Secrets

| Secret | Description |
|---|---|
| `AZURE_CREDENTIALS` | JSON output of `az ad sp create-for-rbac --sdk-auth` |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |
| `AZURE_SSH_PUBLIC_KEY` | Contents of `~/.ssh/id_rsa.pub` |

#### Creating the service principal

```bash
az ad sp create-for-rbac \
  --name "nurai-github-actions" \
  --role Contributor \
  --scopes /subscriptions/<subscription-id> \
  --sdk-auth
```

Copy the JSON output and save it as the `AZURE_CREDENTIALS` secret in GitHub → Settings → Secrets and variables → Actions.

#### Workflow actions

| Action | Description |
|---|---|
| `deploy` | Create the resource group, provision the VM, and bootstrap Ollama |
| `start` | Start a previously deallocated VM |
| `stop` | **Deallocate** the VM (stops compute billing) |
| `destroy` | Delete the entire `rg-muslimAI-stage1` resource group |

---

## Chat UI

The Streamlit app (`app/app.py`) provides a conversational interface:

- **System persona:** NurAI — a respectful Islamic assistant grounded in scholarly sources
- **Streaming responses:** tokens appear in real time as the model generates them
- **Session history:** the full conversation is maintained in the browser session
- **Disclaimer:** displayed prominently at the top of the UI

### Running Streamlit standalone (without Docker)

```bash
# Install dependencies
pip install -r app/requirements.txt

# Point at your Ollama server
export OLLAMA_BASE_URL=http://localhost:11434
export OLLAMA_MODEL=llama3:8b

# Run
streamlit run app/app.py
```

---

## Cost Management

Stage 1 uses three layers of credit protection:

### 1. Azure Auto-Shutdown

Configured during deployment (22:00 UTC by default). The VM is **shut down** (not deallocated — use the GitHub Actions `stop` workflow or `az vm deallocate` for full billing stop).

Modify the shutdown time in `.env`:

```bash
AZURE_AUTO_SHUTDOWN_TIME=1800   # 18:00 UTC
```

### 2. Idle-Shutdown Timer (`scripts/idle-shutdown.sh`)

A systemd timer runs every 15 minutes on the VM and checks whether Ollama's log file has been modified recently. If the VM has been idle for `IDLE_MINUTES` (default: 30), it initiates a graceful shutdown.

Customise the idle threshold on the VM:

```bash
sudo IDLE_MINUTES=60 /usr/local/bin/nurai-idle-shutdown.sh
```

### 3. Manual VM Control

```bash
# Stop billing immediately (deallocate = no compute charges)
az vm deallocate -g rg-muslimAI-stage1 -n muslimAI-llama3-vm

# Start again when needed
az vm start -g rg-muslimAI-stage1 -n muslimAI-llama3-vm

# Delete all Stage 1 resources when the stage is complete
az group delete --name rg-muslimAI-stage1 --yes
```

### Estimated Monthly Cost (eastus, as of 2025)

| VM size | GPU | Approx. cost (24 h/day) | With 8 h/day usage |
|---|---|---|---|
| Standard_NC4as_T4_v3 | 1× NVIDIA T4 | ~$220/month | ~$75/month |
| Standard_D4s_v3 | None (CPU) | ~$140/month | ~$47/month |

> Costs are estimates. Use the [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) for accurate figures.

---

## Configuration Reference

All configuration is via environment variables (see `.env.example`).

| Variable | Default | Description |
|---|---|---|
| `OLLAMA_BASE_URL` | `http://localhost:11434` | Ollama server URL |
| `OLLAMA_MODEL` | `llama3:8b` | Model tag (e.g. `llama3:70b`, `llama3:8b-instruct`) |
| `AZURE_SUBSCRIPTION_ID` | *(required)* | Azure subscription |
| `AZURE_LOCATION` | `eastus` | Azure region |
| `AZURE_RESOURCE_GROUP` | `rg-muslimAI-stage1` | Resource group name |
| `AZURE_VM_NAME` | `muslimAI-llama3-vm` | VM name |
| `AZURE_VM_SIZE` | `Standard_NC4as_T4_v3` | VM SKU |
| `AZURE_VM_ADMIN` | `azureuser` | SSH admin username |
| `AZURE_SSH_KEY_PATH` | `~/.ssh/id_rsa.pub` | SSH public key path |
| `AZURE_AUTO_SHUTDOWN_TIME` | `2200` | Daily auto-shutdown time (UTC HHMM) |
| `IDLE_MINUTES` | `30` | Minutes idle before VM shutdown |

---

## Troubleshooting

### "Cannot reach the Ollama server"

The Streamlit UI displays this error when it cannot connect to Ollama.

1. Confirm Ollama is running: `systemctl status ollama`
2. Check `OLLAMA_BASE_URL` is set correctly
3. If running on Azure, verify the NSG allows inbound TCP on port 11434
4. If using Docker Compose locally, check container logs: `docker compose logs ollama`

### Model not found / pull error

```bash
# SSH into the VM and pull manually
ollama pull llama3:8b

# Check available models
ollama list
```

### Cloud-init not completing

```bash
ssh azureuser@<vm-ip> 'sudo cat /var/log/cloud-init-output.log'
```

### Streamlit service not starting

```bash
ssh azureuser@<vm-ip> 'sudo journalctl -u nurai-streamlit -n 50'
```

### GPU not detected

```bash
# Check NVIDIA driver
nvidia-smi

# Verify Ollama is using the GPU
ollama run llama3:8b "hello"
# Should show GPU layers in the Ollama log
```

---

## Next Steps (Stage 2)

Stage 1 establishes the foundation. Stage 2 will add:

- **Retrieval-Augmented Generation (RAG)** — indexed Islamic corpus (Quran, Hadith, Risale-i Nur)
- **Azure Cognitive Search** vector index
- **FastAPI backend** with guardrail pre/post-filters
- **User authentication** via Azure AD B2C
- **Persistent conversation history** in PostgreSQL
