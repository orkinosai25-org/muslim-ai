#!/usr/bin/env bash
# =============================================================================
# deploy-azure-vm.sh
#
# Provisions an Azure VM for NurAI Stage 1 (Hello-World Llama 3 chatbot).
# The VM is bootstrapped with cloud-init (scripts/setup-ollama.sh) which
# installs Ollama and pulls llama3:8b automatically.
#
# Prerequisites:
#   - Azure CLI installed and authenticated (`az login`)
#   - .env file populated (or environment variables exported)
#
# Usage:
#   chmod +x scripts/deploy-azure-vm.sh
#   ./scripts/deploy-azure-vm.sh
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Load .env if present
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${SCRIPT_DIR}/../.env" ]]; then
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/../.env"
fi

# ---------------------------------------------------------------------------
# Configuration (with sensible defaults)
# ---------------------------------------------------------------------------
: "${AZURE_SUBSCRIPTION_ID:?ERROR: AZURE_SUBSCRIPTION_ID is not set}"
: "${AZURE_LOCATION:=eastus}"
: "${AZURE_RESOURCE_GROUP:=rg-muslimAI-stage1}"
: "${AZURE_VM_NAME:=muslimAI-llama3-vm}"
: "${AZURE_VM_ADMIN:=azureuser}"
: "${AZURE_VM_SIZE:=Standard_NC4as_T4_v3}"
: "${AZURE_SSH_KEY_PATH:=${HOME}/.ssh/id_rsa.pub}"
: "${AZURE_AUTO_SHUTDOWN_TIME:=2200}"

CLOUD_INIT_FILE="${SCRIPT_DIR}/setup-ollama.sh"
NSG_NAME="${AZURE_VM_NAME}-nsg"
NIC_NAME="${AZURE_VM_NAME}-nic"
VNET_NAME="${AZURE_VM_NAME}-vnet"
SUBNET_NAME="default"
PUBLIC_IP_NAME="${AZURE_VM_NAME}-ip"
DISK_SKU="Premium_LRS"
OS_IMAGE="Canonical:ubuntu-24_04-lts:server:latest"

echo "============================================================"
echo " NurAI Stage 1 — Azure VM Deployment"
echo "============================================================"
echo "  Subscription : ${AZURE_SUBSCRIPTION_ID}"
echo "  Location     : ${AZURE_LOCATION}"
echo "  Resource grp : ${AZURE_RESOURCE_GROUP}"
echo "  VM name      : ${AZURE_VM_NAME}"
echo "  VM size      : ${AZURE_VM_SIZE}"
echo "============================================================"

# ---------------------------------------------------------------------------
# Set subscription
# ---------------------------------------------------------------------------
az account set --subscription "${AZURE_SUBSCRIPTION_ID}"

# ---------------------------------------------------------------------------
# Create resource group
# ---------------------------------------------------------------------------
echo "→ Creating resource group '${AZURE_RESOURCE_GROUP}'…"
az group create \
  --name "${AZURE_RESOURCE_GROUP}" \
  --location "${AZURE_LOCATION}" \
  --output none

# ---------------------------------------------------------------------------
# Create VM
# ---------------------------------------------------------------------------
echo "→ Creating VM '${AZURE_VM_NAME}'…"
az vm create \
  --resource-group "${AZURE_RESOURCE_GROUP}" \
  --name "${AZURE_VM_NAME}" \
  --image "${OS_IMAGE}" \
  --size "${AZURE_VM_SIZE}" \
  --admin-username "${AZURE_VM_ADMIN}" \
  --ssh-key-values "${AZURE_SSH_KEY_PATH}" \
  --public-ip-sku Standard \
  --public-ip-address "${PUBLIC_IP_NAME}" \
  --vnet-name "${VNET_NAME}" \
  --subnet "${SUBNET_NAME}" \
  --nsg "${NSG_NAME}" \
  --os-disk-size-gb 64 \
  --storage-sku "${DISK_SKU}" \
  --custom-data "${CLOUD_INIT_FILE}" \
  --output json | tee /tmp/nurai-vm-create-output.json

# Retrieve public IP
VM_PUBLIC_IP=$(az vm show \
  --resource-group "${AZURE_RESOURCE_GROUP}" \
  --name "${AZURE_VM_NAME}" \
  --show-details \
  --query "publicIps" \
  --output tsv)

echo "→ VM public IP: ${VM_PUBLIC_IP}"

# ---------------------------------------------------------------------------
# Open port 11434 for Ollama API (restrict to your IP in production!)
# ---------------------------------------------------------------------------
echo "→ Opening port 11434 (Ollama API)…"
az network nsg rule create \
  --resource-group "${AZURE_RESOURCE_GROUP}" \
  --nsg-name "${NSG_NAME}" \
  --name "Allow-Ollama" \
  --priority 1100 \
  --protocol Tcp \
  --direction Inbound \
  --source-address-prefixes "*" \
  --destination-port-ranges 11434 \
  --access Allow \
  --output none

# Open port 8501 for Streamlit UI
echo "→ Opening port 8501 (Streamlit UI)…"
az network nsg rule create \
  --resource-group "${AZURE_RESOURCE_GROUP}" \
  --nsg-name "${NSG_NAME}" \
  --name "Allow-Streamlit" \
  --priority 1200 \
  --protocol Tcp \
  --direction Inbound \
  --source-address-prefixes "*" \
  --destination-port-ranges 8501 \
  --access Allow \
  --output none

# ---------------------------------------------------------------------------
# Enable auto-shutdown to conserve Azure credits
# ---------------------------------------------------------------------------
if [[ -n "${AZURE_AUTO_SHUTDOWN_TIME}" ]]; then
  echo "→ Enabling auto-shutdown at ${AZURE_AUTO_SHUTDOWN_TIME} UTC…"
  VM_ID=$(az vm show \
    --resource-group "${AZURE_RESOURCE_GROUP}" \
    --name "${AZURE_VM_NAME}" \
    --query "id" \
    --output tsv)

  az resource create \
    --resource-group "${AZURE_RESOURCE_GROUP}" \
    --resource-type "Microsoft.DevTestLab/schedules" \
    --name "shutdown-computevm-${AZURE_VM_NAME}" \
    --location "${AZURE_LOCATION}" \
    --properties "{
      \"status\": \"Enabled\",
      \"taskType\": \"ComputeVmShutdownTask\",
      \"dailyRecurrence\": {\"time\": \"${AZURE_AUTO_SHUTDOWN_TIME}\"},
      \"timeZoneId\": \"UTC\",
      \"targetResourceId\": \"${VM_ID}\"
    }" \
    --output none
  echo "   Auto-shutdown enabled at ${AZURE_AUTO_SHUTDOWN_TIME} UTC."
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "============================================================"
echo " Deployment complete!"
echo "============================================================"
echo "  VM public IP  : ${VM_PUBLIC_IP}"
echo "  Ollama API    : http://${VM_PUBLIC_IP}:11434"
echo "  Streamlit UI  : http://${VM_PUBLIC_IP}:8501  (after setup)"
echo ""
echo "  SSH access:"
echo "    ssh ${AZURE_VM_ADMIN}@${VM_PUBLIC_IP}"
echo ""
echo "  The VM is installing Ollama and pulling llama3:8b in the"
echo "  background (cloud-init). Check progress:"
echo "    ssh ${AZURE_VM_ADMIN}@${VM_PUBLIC_IP} 'tail -f /var/log/cloud-init-output.log'"
echo ""
echo "  To stop the VM (save credits):"
echo "    az vm deallocate -g ${AZURE_RESOURCE_GROUP} -n ${AZURE_VM_NAME}"
echo ""
echo "  To start the VM again:"
echo "    az vm start -g ${AZURE_RESOURCE_GROUP} -n ${AZURE_VM_NAME}"
echo ""
echo "  To delete all Stage 1 resources when done:"
echo "    az group delete --name ${AZURE_RESOURCE_GROUP} --yes --no-wait"
echo "============================================================"
