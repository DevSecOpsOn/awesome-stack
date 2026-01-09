#!/bin/bash

# Consul ACL Setup for Traefik
# Comprehensive script that handles ACL creation, token management, and Traefik service updates
# Usage: ./consul_acl_setup.sh

set -e

# Configuration
TOKENS_DIR="$(dirname "$0")/tokens"
TOKEN_FILE="$TOKENS_DIR/traefik_token.json"
CONSUL_HTTP_ADDR="${CONSUL_HTTP_ADDR:-http://127.0.0.1:8500}"

# Ensure tokens directory exists
mkdir -p "$TOKENS_DIR"

# Function to clean up problematic Traefik KV placeholder files
function cleanup_traefik_kv() {
  echo "🧹 Cleaning up Traefik KV store..."

  # Remove problematic placeholder files that can cause parsing errors
  local cleaned=0
  for key in $(consul kv get -keys traefik/ 2>/dev/null | grep -E '\.placeholder$' || true); do
    echo "  Removing placeholder: $key"
    if consul kv delete "$key" 2>/dev/null; then
      cleaned=$((cleaned + 1))
    fi
  done

  if [ $cleaned -eq 0 ]; then
    echo "✅ No placeholder files found - KV store is clean"
  else
    echo "✅ Cleaned up $cleaned placeholder files"
  fi
}

# Function to update token file with latest valid token data
function update_token_file() {
  local token_id="$1"

  if [ -z "$token_id" ]; then
    echo "❌ No token ID provided to update_token_file"
    return 1
  fi

  echo "  Updating token file with latest data..."

  # Get the latest token information from Consul using the secret ID
  local token_data=$(CONSUL_HTTP_TOKEN="$token_id" consul acl token read -self -format json 2>/dev/null)

  if [ $? -eq 0 ] && [ -n "$token_data" ]; then
    echo "$token_data" > "$TOKEN_FILE"
    echo "  ✅ Token file updated: $TOKEN_FILE"
    return 0
  else
    # Fallback: try with accessor ID if we have it in the existing file
    if [ -f "$TOKEN_FILE" ] && command -v jq >/dev/null 2>&1; then
      local accessor_id=$(jq -r '.AccessorID // empty' "$TOKEN_FILE" 2>/dev/null)
      if [ -n "$accessor_id" ] && [ "$accessor_id" != "null" ]; then
        token_data=$(consul acl token read -accessor-id "$accessor_id" -format json 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$token_data" ]; then
          echo "$token_data" > "$TOKEN_FILE"
          echo "  ✅ Token file updated using accessor ID: $TOKEN_FILE"
          return 0
        fi
      fi
    fi

    echo "  ⚠️  Could not fetch latest token data from Consul, keeping existing file"
    return 1
  fi
}

# Function to create or validate Traefik ACL policy and token
function traefik_acl() {
  echo "🔐 Setting up Traefik ACL..."

  # Check if token already exists and is valid
  if [ -f "$TOKEN_FILE" ] && command -v jq >/dev/null 2>&1; then
    local existing_token=$(jq -r '.SecretID // .ID // empty' "$TOKEN_FILE" 2>/dev/null)
    local existing_accessor=$(jq -r '.AccessorID // empty' "$TOKEN_FILE" 2>/dev/null)

    if [ -n "$existing_token" ] && [ "$existing_token" != "null" ]; then
      if consul acl token read -accessor-id "$existing_accessor" >/dev/null 2>&1; then
        echo "✅ Existing token is valid, using it"
        export CONSUL_TRAEFIK_TOKEN="$existing_token"

        # Always update the token file with latest data to keep it fresh
        update_token_file "$existing_token"
        return 0
      else
        echo "⚠️  Existing token is invalid, creating new one..."
      fi
    fi
  fi

  # Create comprehensive Traefik policy
  local traefik_policy='key_prefix "traefik/" { policy = "write" }
service_prefix "" { policy = "write" }
node_prefix "" { policy = "read" }
session_prefix "" { policy = "write" }
agent_prefix "" { policy = "read" }
event_prefix "" { policy = "write" }'

  # Create or update policy
  echo "  Creating/updating Traefik policy..."
  if ! consul acl policy create -name "traefik-policy" -description "Traefik load balancer policy" -rules "$traefik_policy" 2>/dev/null; then
    # Policy might exist, try to update it
    if consul acl policy update -name "traefik-policy" -description "Traefik load balancer policy" -rules "$traefik_policy" 2>/dev/null; then
      echo "  ✅ Policy updated successfully"
    else
      echo "  ⚠️  Policy creation/update had issues, but continuing..."
    fi
  else
    echo "  ✅ Policy created successfully"
  fi

  # Create token
  echo "  Creating Traefik token..."
  local token_response=$(consul acl token create -description "Traefik Load Balancer Token" -policy-name "traefik-policy" -format json 2>/dev/null)

  if [ $? -eq 0 ] && [ -n "$token_response" ]; then
    local token_id=$(echo "$token_response" | jq -r '.SecretID')
    if [ -n "$token_id" ] && [ "$token_id" != "null" ]; then
      # Save the token response immediately
      echo "$token_response" > "$TOKEN_FILE"

      echo "✅ Traefik token created: ${token_id:0:8}..."
      echo "  Token saved to: $TOKEN_FILE"

      # Export token for immediate use
      export CONSUL_TRAEFIK_TOKEN="$token_id"
      echo "✅ CONSUL_TRAEFIK_TOKEN exported"

      # Always update with latest data from Consul to ensure consistency
      update_token_file "$token_id"
      return 0
    fi
  fi

  echo "❌ Failed to create Traefik token"
  return 1
}

# Function to export token and update shell profiles
function export_traefik_token() {
  echo "📤 Exporting Traefik token..."

  if [ ! -f "$TOKEN_FILE" ]; then
    echo "❌ Token file not found: $TOKEN_FILE"
    return 1
  fi

  if ! command -v jq >/dev/null 2>&1; then
    echo "❌ jq is required but not installed"
    return 1
  fi

  local token_id=$(jq -r '.SecretID // .ID // empty' "$TOKEN_FILE" 2>/dev/null)

  if [ -z "$token_id" ] || [ "$token_id" = "null" ]; then
    echo "❌ Could not extract token from $TOKEN_FILE"
    return 1
  fi

  # Export token for current session
  export CONSUL_TRAEFIK_TOKEN="$token_id"
  echo "✅ CONSUL_TRAEFIK_TOKEN exported: ${token_id:0:8}..."

  # Only update shell profiles if not in container mode
  if [ -z "$CONSUL_CONTAINER_MODE" ]; then
    echo "  Updating shell profiles for persistence..."
    local export_line="export CONSUL_TRAEFIK_TOKEN=$token_id"

    # Update .zshrc if it exists or if using zsh
    if [ -f "$HOME/.zshrc" ] || [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ]; then
      if ! grep -q "CONSUL_TRAEFIK_TOKEN" "$HOME/.zshrc" 2>/dev/null; then
        echo "$export_line" >> "$HOME/.zshrc"
        echo "  ✅ Added to ~/.zshrc"
      else
        # Update existing line
        if sed -i.bak "s/export CONSUL_TRAEFIK_TOKEN=.*/export CONSUL_TRAEFIK_TOKEN=$token_id/" "$HOME/.zshrc" 2>/dev/null; then
          echo "  ✅ Updated in ~/.zshrc"
        else
          echo "  ⚠️  Could not update ~/.zshrc automatically"
        fi
      fi
    fi

    # Update .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
      if ! grep -q "CONSUL_TRAEFIK_TOKEN" "$HOME/.bashrc" 2>/dev/null; then
        echo "$export_line" >> "$HOME/.bashrc"
        echo "  ✅ Added to ~/.bashrc"
      else
        # Update existing line
        if sed -i.bak "s/export CONSUL_TRAEFIK_TOKEN=.*/export CONSUL_TRAEFIK_TOKEN=$token_id/" "$HOME/.bashrc" 2>/dev/null; then
          echo "  ✅ Updated in ~/.bashrc"
        else
          echo "  ⚠️  Could not update ~/.bashrc automatically"
        fi
      fi
    fi
  fi

  return 0
}

# Function to sync token from Traefik service if it has a valid one
function sync_token_from_service() {
  echo "🔄 Checking for valid CONSUL_TRAEFIK_TOKEN in Traefik service..."

  if ! command -v docker >/dev/null 2>&1; then
    return 1
  fi

  # Try different common Traefik service names
  local service_names=("traefik_traefik" "traefik" "traefik_stack_traefik")

  for service_name in "${service_names[@]}"; do
    if docker service ls --format "{{.Name}}" | grep -q "^${service_name}$" 2>/dev/null; then
      echo "  Found service: $service_name"

      # Get CONSUL_TRAEFIK_TOKEN from service (don't touch CONSUL_HTTP_TOKEN)
      local service_traefik_token=$(docker service inspect "$service_name" --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' 2>/dev/null | grep "^CONSUL_TRAEFIK_TOKEN=" | cut -d'=' -f2)
      local service_consul_token=$(docker service inspect "$service_name" --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' 2>/dev/null | grep "^CONSUL_HTTP_TOKEN=" | cut -d'=' -f2)

      echo "  ℹ️  Service CONSUL_HTTP_TOKEN: ${service_consul_token:0:8}... (preserved)"

      # Only check CONSUL_TRAEFIK_TOKEN
      if [ -n "$service_traefik_token" ] && [ "$service_traefik_token" != "null" ]; then
        if CONSUL_HTTP_TOKEN="$service_traefik_token" consul acl token read -self >/dev/null 2>&1; then
          echo "  ✅ Service has valid CONSUL_TRAEFIK_TOKEN: ${service_traefik_token:0:8}..."
          export CONSUL_TRAEFIK_TOKEN="$service_traefik_token"
          update_token_file "$service_traefik_token"
          return 0
        else
          echo "  ⚠️  Service CONSUL_TRAEFIK_TOKEN is not valid in Consul"
        fi
      else
        echo "  ⚠️  No CONSUL_TRAEFIK_TOKEN found in service"
      fi

      break
    fi
  done

  return 1
}

# Function to update Traefik Docker service with new token
function update_traefik_service() {
  echo "🔄 Updating Traefik Docker service..."

  if [ -z "$CONSUL_TRAEFIK_TOKEN" ]; then
    echo "❌ CONSUL_TRAEFIK_TOKEN not available"
    return 1
  fi

  if ! command -v docker >/dev/null 2>&1; then
    echo "⚠️  Docker not available - cannot update Traefik service"
    echo "   Run manually: docker service update --env-add CONSUL_TRAEFIK_TOKEN=$CONSUL_TRAEFIK_TOKEN --force <traefik_service_name>"
    return 1
  fi

  # Try different common Traefik service names
  local service_names=("traefik_traefik" "traefik" "traefik_stack_traefik")
  local updated=false

  for service_name in "${service_names[@]}"; do
    if docker service ls --format "{{.Name}}" | grep -q "^${service_name}$" 2>/dev/null; then
      echo "  Found service: $service_name"

      # Check current CONSUL_TRAEFIK_TOKEN in service (leave CONSUL_HTTP_TOKEN intact)
      local current_traefik_token=$(docker service inspect "$service_name" --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' 2>/dev/null | grep "^CONSUL_TRAEFIK_TOKEN=" | cut -d'=' -f2)
      local current_consul_token=$(docker service inspect "$service_name" --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' 2>/dev/null | grep "^CONSUL_HTTP_TOKEN=" | cut -d'=' -f2)

      if [ "$current_traefik_token" = "$CONSUL_TRAEFIK_TOKEN" ]; then
        echo "✅ Service '$service_name' already has correct CONSUL_TRAEFIK_TOKEN"
        echo "  ℹ️  CONSUL_HTTP_TOKEN preserved: ${current_consul_token:0:8}..."
        updated=true
        break
      fi

      echo "  Updating CONSUL_TRAEFIK_TOKEN (preserving CONSUL_HTTP_TOKEN)..."
      if docker service update \
        --env-rm CONSUL_TRAEFIK_TOKEN \
        --env-add CONSUL_TRAEFIK_TOKEN="$CONSUL_TRAEFIK_TOKEN" \
        --force "$service_name" 2>/dev/null; then
        echo "✅ Traefik service '$service_name' updated successfully"
        echo "  ✅ CONSUL_TRAEFIK_TOKEN: ${CONSUL_TRAEFIK_TOKEN:0:8}..."
        echo "  ℹ️  CONSUL_HTTP_TOKEN preserved: ${current_consul_token:0:8}..."
        updated=true
        break
      else
        echo "  ⚠️  Failed to update service '$service_name'"
      fi
    fi
  done

  if [ "$updated" = false ]; then
    echo "⚠️  Could not find or update Traefik service automatically"
    echo "   Available services:"
    docker service ls --format "  {{.Name}}" 2>/dev/null || echo "   (could not list services)"
    echo ""
    echo "   Run manually: docker service update --env-add CONSUL_TRAEFIK_TOKEN=$CONSUL_TRAEFIK_TOKEN --force <service_name>"
    return 1
  fi

  return 0
}

# Function to display usage information
function show_usage_info() {
  echo ""
  echo "💡 Usage Information:"
  echo "  Environment Variable: CONSUL_TRAEFIK_TOKEN=${CONSUL_TRAEFIK_TOKEN:0:8}..."
  echo ""
  echo "  For traefik.yaml configuration:"
  echo "    environment:"
  echo "      CONSUL_HTTP_TOKEN: \${CONSUL_TRAEFIK_TOKEN}"
  echo ""
  echo "  ⚠️  Note: This script only manages CONSUL_TRAEFIK_TOKEN"
  echo "     CONSUL_HTTP_TOKEN is preserved for other services"
  echo ""

  if [ -z "$CONSUL_CONTAINER_MODE" ]; then
    echo "  To use token in current session:"
    echo "    source ~/.zshrc    # for zsh users"
    echo "    source ~/.bashrc   # for bash users"
    echo "    # or start a new terminal session"
    echo ""
  fi

  echo "  Manual service update (if needed):"
  echo "    docker service update --env-add CONSUL_TRAEFIK_TOKEN=\$CONSUL_TRAEFIK_TOKEN --force <service_name>"
}

# Main execution function
function main() {
  echo "🚀 Consul ACL Setup for Traefik"
  echo "==============================="
  echo "  Consul Address: $CONSUL_HTTP_ADDR"
  echo "  Container Mode: ${CONSUL_CONTAINER_MODE:-false}"
  echo ""

  # Step 1: Clean up KV store
  cleanup_traefik_kv
  echo ""

  # Step 2: Try to sync valid token from service first (if available)
  if sync_token_from_service; then
    echo "✅ Synced valid token from Traefik service"
  else
    echo "  No valid token found in service, proceeding with ACL setup..."
  fi
  echo ""

  # Step 3: Create/validate ACL and token (will use existing if valid)
  if ! traefik_acl; then
    echo "❌ Failed to set up Traefik ACL"
    exit 1
  fi
  echo ""

  # Step 4: Export token and update shell profiles
  if ! export_traefik_token; then
    echo "❌ Failed to export Traefik token"
    exit 1
  fi
  echo ""

  # Step 5: Update Traefik Docker service
  update_traefik_service
  echo ""

  # Step 6: Final token file update to ensure it's current
  if [ -n "$CONSUL_TRAEFIK_TOKEN" ]; then
    echo "🔄 Final token file synchronization..."
    update_token_file "$CONSUL_TRAEFIK_TOKEN"
    echo ""
  fi

  # Step 7: Show usage information
  show_usage_info
  echo ""

  echo "🎉 Setup completed successfully!"
  echo "   Token: ${CONSUL_TRAEFIK_TOKEN:0:8}..."
  echo "   File: $TOKEN_FILE"
}

# Execute main function with all arguments
main "$@"
