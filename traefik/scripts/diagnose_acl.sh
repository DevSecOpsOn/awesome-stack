#!/bin/bash

# Consul ACL Diagnostic Script
# Checks current ACL state and token validity

set -e

CONSUL_HTTP_ADDR="${CONSUL_HTTP_ADDR:-http://127.0.0.1:8500}"
TOKENS_DIR="$(dirname "$0")/tokens"
TOKEN_FILE="$TOKENS_DIR/traefik_token.json"

echo "🔍 Consul ACL Diagnostic"
echo "========================"
echo "Consul Address: $CONSUL_HTTP_ADDR"
echo ""

# Check if Consul is accessible
echo "1. Checking Consul connectivity..."
if consul members >/dev/null 2>&1; then
    echo "✅ Consul is accessible"
else
    echo "❌ Cannot connect to Consul"
    exit 1
fi

# Check ACL system status
echo ""
echo "2. Checking ACL system status..."
acl_status=$(consul acl bootstrap 2>&1 || true)
if echo "$acl_status" | grep -q "ACL system is currently in legacy mode"; then
    echo "⚠️  ACL system is in legacy mode"
elif echo "$acl_status" | grep -q "ACL bootstrap no longer allowed"; then
    echo "✅ ACL system is bootstrapped and active"
else
    echo "❓ ACL system status unclear: $acl_status"
fi

# Check current token file
echo ""
echo "3. Checking saved token file..."
if [ -f "$TOKEN_FILE" ]; then
    echo "✅ Token file exists: $TOKEN_FILE"
    if command -v jq >/dev/null 2>&1; then
        token_id=$(jq -r '.SecretID // .ID // empty' "$TOKEN_FILE" 2>/dev/null)
        accessor_id=$(jq -r '.AccessorID // empty' "$TOKEN_FILE" 2>/dev/null)

        if [ -n "$token_id" ] && [ "$token_id" != "null" ]; then
            echo "  Token ID: ${token_id:0:8}..."

            # Check if token exists in Consul
            echo ""
            echo "4. Validating token in Consul..."
            if [ -n "$accessor_id" ] && [ "$accessor_id" != "null" ]; then
                if consul acl token read -accessor-id "$accessor_id" >/dev/null 2>&1; then
                    echo "✅ Token is valid in Consul"

                    # Show token details
                    echo ""
                    echo "5. Token details:"
                    consul acl token read -accessor-id "$accessor_id" 2>/dev/null | head -10
                else
                    echo "❌ Token not found in Consul (this is the problem!)"
                    echo "  The token in the file doesn't exist in Consul anymore"
                fi
            else
                echo "❌ No accessor ID found in token file"
            fi
        else
            echo "❌ No valid token ID found in file"
        fi
    else
        echo "⚠️  jq not available - cannot parse token file"
    fi
else
    echo "❌ No token file found"
fi

# Check environment variable
echo ""
echo "6. Checking environment variable..."
if [ -n "$CONSUL_TRAEFIK_TOKEN" ]; then
    echo "✅ CONSUL_TRAEFIK_TOKEN is set: ${CONSUL_TRAEFIK_TOKEN:0:8}..."
else
    echo "❌ CONSUL_TRAEFIK_TOKEN not set"
fi

# Check Traefik service
echo ""
echo "7. Checking Traefik Docker service..."
if command -v docker >/dev/null 2>&1; then
    service_names=("traefik_traefik" "traefik" "traefik_stack_traefik")
    found_service=false

    for service_name in "${service_names[@]}"; do
        if docker service ls --format "{{.Name}}" | grep -q "^${service_name}$" 2>/dev/null; then
            echo "✅ Found Traefik service: $service_name"
            found_service=true

            # Check service environment
            echo "  Service environment variables:"
            docker service inspect "$service_name" --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' 2>/dev/null | grep -i consul || echo "    (no Consul-related env vars found)"
            break
        fi
    done

    if [ "$found_service" = false ]; then
        echo "❌ No Traefik service found"
        echo "  Available services:"
        docker service ls --format "  {{.Name}}" 2>/dev/null || echo "  (could not list services)"
    fi
else
    echo "⚠️  Docker not available"
fi

echo ""
echo "🎯 Diagnosis Summary:"
echo "====================="
if [ -f "$TOKEN_FILE" ] && command -v jq >/dev/null 2>&1; then
    token_id=$(jq -r '.SecretID // .ID // empty' "$TOKEN_FILE" 2>/dev/null)
    accessor_id=$(jq -r '.AccessorID // empty' "$TOKEN_FILE" 2>/dev/null)

    if [ -n "$accessor_id" ] && [ "$accessor_id" != "null" ]; then
        if consul acl token read -accessor-id "$accessor_id" >/dev/null 2>&1; then
            echo "✅ Token is valid - no action needed"
        else
            echo "❌ Token is invalid - need to recreate"
            echo ""
            echo "🔧 Recommended action:"
            echo "   Run: ./consul_acl_setup.sh"
            echo "   This will create a new token and update Traefik"
        fi
    else
        echo "❌ Token file is corrupted - need to recreate"
        echo ""
        echo "🔧 Recommended action:"
        echo "   Run: ./consul_acl_setup.sh"
    fi
else
    echo "❌ No valid token found - need to create"
    echo ""
    echo "🔧 Recommended action:"
    echo "   Run: ./consul_acl_setup.sh"
fi
