#!/usr/bin/env bash
# =============================================================================
# idle-shutdown.sh
#
# Monitors Ollama activity and shuts the VM down when it has been idle for
# longer than IDLE_MINUTES (default: 30).  Run as a systemd timer (see
# setup-ollama.sh) or via cron.
#
# This script helps conserve Azure credits when the chatbot is not in use.
#
# Environment variables:
#   IDLE_MINUTES   – Minutes of inactivity before shutdown (default: 30)
#   OLLAMA_LOG     – Path to Ollama log file (default: /var/log/ollama.log)
# =============================================================================

set -euo pipefail

IDLE_MINUTES="${IDLE_MINUTES:-30}"
OLLAMA_LOG="${OLLAMA_LOG:-/var/log/ollama.log}"
IDLE_LOG="/var/log/nurai-idle.log"
THRESHOLD=$(( IDLE_MINUTES * 60 ))

log() {
  echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') $*" | tee -a "${IDLE_LOG}"
}

# ---------------------------------------------------------------------------
# Determine last-activity time
# ---------------------------------------------------------------------------

# Prefer Ollama's log file modification time; fall back to Ollama API check.
if [[ -f "${OLLAMA_LOG}" ]]; then
  LAST_ACTIVE=$(stat -c %Y "${OLLAMA_LOG}")
else
  # If the log file is absent, use the Ollama process start time as a proxy.
  OLLAMA_PID=$(pgrep -x ollama 2>/dev/null || true)
  if [[ -z "${OLLAMA_PID}" ]]; then
    log "Ollama process not found — skipping idle check."
    exit 0
  fi
  LAST_ACTIVE=$(stat -c %Y "/proc/${OLLAMA_PID}" 2>/dev/null || date +%s)
fi

NOW=$(date +%s)
IDLE_SECS=$(( NOW - LAST_ACTIVE ))

log "Idle for ${IDLE_SECS}s (threshold: ${THRESHOLD}s / ${IDLE_MINUTES} min)"

# ---------------------------------------------------------------------------
# Shutdown if idle threshold exceeded
# ---------------------------------------------------------------------------
if (( IDLE_SECS >= THRESHOLD )); then
  log "Idle threshold exceeded — initiating shutdown to conserve Azure credits."
  shutdown -h now "NurAI idle shutdown: no activity for ${IDLE_MINUTES} minutes."
else
  REMAINING=$(( THRESHOLD - IDLE_SECS ))
  log "Still active — ${REMAINING}s remaining before auto-shutdown."
fi
