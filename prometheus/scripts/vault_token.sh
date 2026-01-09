#!/bin/bash
set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_PROJECT="${HOME}/projects/personal/bitbucket/docker"
PROMETHEUS_CONFIG="${DOCKER_PROJECT}/prometheus/config"
TOKEN_FILE="${PROMETHEUS_CONFIG}/prometheus-token"
POLICY_NAME="prometheus-metrics"

# Ensure config directory exists
mkdir -p "${PROMETHEUS_CONFIG}"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

# Function to check if vault is available
check_vault() {
    if ! command -v vault >/dev/null 2>&1; then
        log "ERROR: vault command not found. Please install HashiCorp Vault CLI."
        exit 1
    fi

    if ! vault status >/dev/null 2>&1; then
        log "ERROR: Cannot connect to Vault server. Please check your VAULT_ADDR and authentication."
        exit 1
    fi
}

# Function to create vault policy
create_policy() {
    log "Creating Vault policy: ${POLICY_NAME}"

    vault policy write "${POLICY_NAME}" - << 'EOF'
path "sys/metrics" {
  capabilities = ["read"]
}
EOF

    if [ $? -eq 0 ]; then
        log "Policy '${POLICY_NAME}' created successfully"
    else
        log "ERROR: Failed to create policy '${POLICY_NAME}'"
        exit 1
    fi
}

# Function to create vault token
create_token() {
    log "Creating Vault token for Prometheus metrics"

    local token
    token=$(vault token create -field=token -policy="${POLICY_NAME}" 2>/dev/null)

    if [ $? -eq 0 ] && [ -n "${token}" ]; then
        echo "${token}" > "${TOKEN_FILE}"
        chmod 600 "${TOKEN_FILE}"
        log "Token created and saved to: ${TOKEN_FILE}"
    else
        log "ERROR: Failed to create Vault token"
        exit 1
    fi
}

# Main execution
main() {
    log "Starting Vault token setup for Prometheus..."

    check_vault
    create_policy
    create_token

    log "Vault token setup completed successfully"
}

# Run main function
main "$@"
