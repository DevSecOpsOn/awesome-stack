#!/bin/bash
set -euo pipefail

# Security check script for Docker stacks
echo "🔒 Starting comprehensive security checks..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to log messages
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $*${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $*${NC}"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*${NC}"
}

# Check for hardcoded secrets
check_secrets() {
    log "Checking for hardcoded secrets..."

    local secret_patterns=(
        "password.*=.*['\"][^'\"]{8,}['\"]"
        "token.*=.*['\"][^'\"]{20,}['\"]"
        "key.*=.*['\"][^'\"]{20,}['\"]"
        "secret.*=.*['\"][^'\"]{20,}['\"]"
        "api_key.*=.*['\"][^'\"]{20,}['\"]"
    )

    local found_secrets=0

    for pattern in "${secret_patterns[@]}"; do
        if grep -r -i -E "$pattern" . --include="*.yaml" --include="*.yml" --exclude-dir=".git"; then
            error "Potential hardcoded secret found!"
            found_secrets=1
        fi
    done

    if [ $found_secrets -eq 0 ]; then
        log "✅ No hardcoded secrets detected"
    else
        error "❌ Hardcoded secrets detected - please use environment variables or Docker secrets"
        return 1
    fi
}

# Check for insecure configurations
check_insecure_configs() {
    log "Checking for insecure configurations..."

    local issues=0

    # Check for privileged containers
    if grep -r "privileged.*true" . --include="*.yaml" --include="*.yml"; then
        warn "Privileged containers detected"
        issues=1
    fi

    # Check for host network mode
    if grep -r "network_mode.*host" . --include="*.yaml" --include="*.yml"; then
        warn "Host network mode detected"
        issues=1
    fi

    # Check for bind mounts to sensitive paths
    if grep -r "/etc:" . --include="*.yaml" --include="*.yml"; then
        warn "Bind mount to /etc detected"
        issues=1
    fi

    if [ $issues -eq 0 ]; then
        log "✅ No insecure configurations detected"
    else
        warn "⚠️  Some potentially insecure configurations detected"
    fi
}

# Check for latest tags
check_image_tags() {
    log "Checking for 'latest' image tags..."

    local latest_count=0
    latest_count=$(grep -r "image:.*:latest" . --include="*.yaml" --include="*.yml" | wc -l || true)

    if [ "$latest_count" -gt 0 ]; then
        warn "Found $latest_count services using 'latest' tag"
        grep -r "image:.*:latest" . --include="*.yaml" --include="*.yml" || true
        warn "Consider using specific version tags for production"
    else
        log "✅ No 'latest' tags detected"
    fi
}

# Check resource limits
check_resource_limits() {
    log "Checking for resource limits..."

    local services_without_limits=0

    # Find all service definitions and check for resource limits
    while IFS= read -r file; do
        if grep -q "services:" "$file"; then
            # Extract service names and check for resource limits
            services=$(grep -A 50 "services:" "$file" | grep -E "^  [a-zA-Z]" | cut -d: -f1 | sed 's/^  //')

            for service in $services; do
                if ! grep -A 20 "$service:" "$file" | grep -q "resources:"; then
                    warn "Service '$service' in $file has no resource limits"
                    services_without_limits=$((services_without_limits + 1))
                fi
            done
        fi
    done < <(find . -name "*.yaml" -o -name "*.yml" | grep -v ".git")

    if [ $services_without_limits -eq 0 ]; then
        log "✅ All services have resource limits"
    else
        warn "⚠️  $services_without_limits services without resource limits"
    fi
}

# Main execution
main() {
    log "Starting security audit for Docker stacks..."

    local exit_code=0

    check_secrets || exit_code=1
    check_insecure_configs
    check_image_tags
    check_resource_limits

    if [ $exit_code -eq 0 ]; then
        log "🎉 Security audit completed successfully!"
    else
        error "❌ Security audit failed - please address the issues above"
    fi

    return $exit_code
}

# Run main function
main "$@"
