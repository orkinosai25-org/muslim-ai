#!/usr/bin/env bash
# =============================================================================
# setup-ollama.sh
#
# Cloud-init / VM bootstrap script.
# Runs automatically on first boot when passed to `az vm create --custom-data`.
# Also safe to run manually via SSH on an existing VM.
#
# What it does:
#   1. Updates system packages
#   2. Installs Ollama
#   3. Starts the Ollama service
#   4. Pulls the llama3:8b model
#   5. Installs Python / Streamlit dependencies
#   6. Deploys the NurAI Streamlit app as a systemd service
#   7. Installs and enables the idle-shutdown timer
# =============================================================================

set -euo pipefail

OLLAMA_MODEL="${OLLAMA_MODEL:-llama3:8b}"
NURAI_USER="${NURAI_USER:-azureuser}"
APP_DIR="/opt/nurai"

echo "======================================================"
echo " NurAI Stage 1 — VM bootstrap starting"
echo "======================================================"

# ---------------------------------------------------------------------------
# 1. System updates
# ---------------------------------------------------------------------------
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y
apt-get install -y curl git python3 python3-pip python3-venv

# ---------------------------------------------------------------------------
# 2. Install Ollama
# ---------------------------------------------------------------------------
echo "→ Installing Ollama…"
curl -fsSL https://ollama.com/install.sh | sh

# ---------------------------------------------------------------------------
# 3. Start Ollama service
# ---------------------------------------------------------------------------
echo "→ Starting Ollama service…"
systemctl enable ollama
systemctl start ollama

# Wait for Ollama to be ready
echo "→ Waiting for Ollama to become ready…"
for attempt in $(seq 1 30); do
  if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "   Ollama is ready."
    break
  fi
  echo "   Attempt ${attempt}/30 — retrying in 5 s…"
  sleep 5
done

# ---------------------------------------------------------------------------
# 4. Pull the Llama 3 model
# ---------------------------------------------------------------------------
echo "→ Pulling model: ${OLLAMA_MODEL}  (this may take several minutes)…"
ollama pull "${OLLAMA_MODEL}"
echo "→ Model pulled successfully."

# ---------------------------------------------------------------------------
# 5. Install the NurAI Streamlit app
# ---------------------------------------------------------------------------
echo "→ Setting up NurAI Streamlit app…"
mkdir -p "${APP_DIR}"

# Copy app files from the cloud-init payload directory if available,
# otherwise pull from GitHub (fallback).
if [[ -d "/var/lib/cloud/instance/scripts" ]]; then
  cp -r /var/lib/cloud/instance/scripts/. "${APP_DIR}/" 2>/dev/null || true
fi

# Create a minimal app.py if not already present
if [[ ! -f "${APP_DIR}/app.py" ]]; then
  cat > "${APP_DIR}/app.py" << 'PYEOF'
"""NurAI Hello-World Chatbot — Stage 1 (auto-deployed fallback)."""
import os, json, requests, streamlit as st

OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
OLLAMA_MODEL    = os.getenv("OLLAMA_MODEL", "llama3:8b")
SYSTEM_PROMPT   = (
    "You are NurAI, a helpful Islamic assistant. Answer questions about the "
    "Quran, Hadith, and daily Muslim life based on verified scholarly sources. "
    "Always be respectful and acknowledge uncertainty."
)

def chat_stream(messages):
    url = f"{OLLAMA_BASE_URL}/api/chat"
    payload = {"model": OLLAMA_MODEL, "messages": messages, "stream": True}
    try:
        with requests.post(url, json=payload, stream=True, timeout=120) as r:
            r.raise_for_status()
            for line in r.iter_lines():
                if line:
                    chunk = json.loads(line)
                    yield chunk.get("message", {}).get("content", "")
                    if chunk.get("done"):
                        break
    except requests.exceptions.ConnectionError:
        yield f"⚠️ Cannot reach Ollama at {OLLAMA_BASE_URL}."

st.set_page_config(page_title="NurAI", page_icon="🌙")
st.title("🌙 NurAI — Islamic Assistant")
st.caption(f"Model: `{OLLAMA_MODEL}` · Endpoint: `{OLLAMA_BASE_URL}`")
if "messages" not in st.session_state:
    st.session_state.messages = []
for msg in st.session_state.messages:
    with st.chat_message(msg["role"]):
        st.markdown(msg["content"])
if prompt := st.chat_input("Ask a question about Islam…"):
    st.session_state.messages.append({"role": "user", "content": prompt})
    with st.chat_message("user"):
        st.markdown(prompt)
    full_msgs = [{"role": "system", "content": SYSTEM_PROMPT}] + st.session_state.messages
    with st.chat_message("assistant"):
        placeholder = st.empty()
        resp = ""
        for token in chat_stream(full_msgs):
            resp += token
            placeholder.markdown(resp + "▌")
        placeholder.markdown(resp)
    st.session_state.messages.append({"role": "assistant", "content": resp})
PYEOF
fi

# Create requirements.txt
cat > "${APP_DIR}/requirements.txt" << 'EOF'
streamlit>=1.35.0
requests>=2.31.0
EOF

# Create Python virtual environment and install dependencies
python3 -m venv "${APP_DIR}/.venv"
"${APP_DIR}/.venv/bin/pip" install --upgrade pip
"${APP_DIR}/.venv/bin/pip" install -r "${APP_DIR}/requirements.txt"

# Ensure correct ownership
chown -R "${NURAI_USER}:${NURAI_USER}" "${APP_DIR}"

# ---------------------------------------------------------------------------
# 6. Create systemd service for Streamlit
# ---------------------------------------------------------------------------
echo "→ Creating nurai-streamlit systemd service…"
cat > /etc/systemd/system/nurai-streamlit.service << EOF
[Unit]
Description=NurAI Streamlit Chat UI
After=network.target ollama.service
Wants=ollama.service

[Service]
Type=simple
User=${NURAI_USER}
WorkingDirectory=${APP_DIR}
Environment="OLLAMA_BASE_URL=http://localhost:11434"
Environment="OLLAMA_MODEL=${OLLAMA_MODEL}"
ExecStart=${APP_DIR}/.venv/bin/streamlit run ${APP_DIR}/app.py \
    --server.port=8501 \
    --server.address=0.0.0.0 \
    --server.headless=true \
    --browser.gatherUsageStats=false
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable nurai-streamlit
systemctl start nurai-streamlit

# ---------------------------------------------------------------------------
# 7. Install the idle-shutdown timer
# ---------------------------------------------------------------------------
echo "→ Installing idle-shutdown timer…"
cp "$(dirname "$0")/idle-shutdown.sh" /usr/local/bin/nurai-idle-shutdown.sh \
  2>/dev/null || true

# Create a fallback idle-shutdown script if the copy above failed
if [[ ! -f /usr/local/bin/nurai-idle-shutdown.sh ]]; then
  cat > /usr/local/bin/nurai-idle-shutdown.sh << 'SHUTEOF'
#!/usr/bin/env bash
# Shut down the VM if Ollama has had no activity for IDLE_MINUTES.
IDLE_MINUTES="${IDLE_MINUTES:-30}"
LOG_FILE="${OLLAMA_LOG:-/var/log/ollama.log}"
THRESHOLD=$(( IDLE_MINUTES * 60 ))
if [[ -f "${LOG_FILE}" ]]; then
  LAST_MOD=$(stat -c %Y "${LOG_FILE}")
  NOW=$(date +%s)
  IDLE=$(( NOW - LAST_MOD ))
  if (( IDLE >= THRESHOLD )); then
    echo "$(date -u): Idle for ${IDLE}s — shutting down." | tee -a /var/log/nurai-idle.log
    shutdown -h now
  fi
fi
SHUTEOF
fi

chmod +x /usr/local/bin/nurai-idle-shutdown.sh

# Systemd timer to run the idle-shutdown check every 15 minutes
cat > /etc/systemd/system/nurai-idle-shutdown.service << 'SVCEOF'
[Unit]
Description=NurAI idle shutdown check

[Service]
Type=oneshot
ExecStart=/usr/local/bin/nurai-idle-shutdown.sh
SVCEOF

cat > /etc/systemd/system/nurai-idle-shutdown.timer << 'TIMEREOF'
[Unit]
Description=Run NurAI idle shutdown check every 15 minutes

[Timer]
OnBootSec=15min
OnUnitActiveSec=15min
Unit=nurai-idle-shutdown.service

[Install]
WantedBy=timers.target
TIMEREOF

systemctl daemon-reload
systemctl enable nurai-idle-shutdown.timer
systemctl start nurai-idle-shutdown.timer

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "======================================================"
echo " NurAI VM bootstrap complete!"
echo "======================================================"
echo "  Ollama API  : http://$(hostname -I | awk '{print $1}'):11434"
echo "  Streamlit   : http://$(hostname -I | awk '{print $1}'):8501"
echo "======================================================"
