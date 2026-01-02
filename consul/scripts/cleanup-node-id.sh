#!/bin/bash
# Consul Node ID Cleanup Script
# This script fixes corrupted node-id files that prevent Consul from starting

set -e

echo "🧹 Consul Node ID Cleanup Script"
echo "================================="

# Function to cleanup node ID for a specific volume
cleanup_node_id() {
    local volume_name=$1
    local service_type=$2
    
    echo "🔍 Checking $service_type volume: $volume_name"
    
    # Check if volume exists
    if docker volume inspect "$volume_name" >/dev/null 2>&1; then
        echo "📁 Volume $volume_name exists, checking for corrupted node-id..."
        
        # Create a temporary container to access the volume
        docker run --rm -v "$volume_name:/data" alpine:latest sh -c "
            if [ -f /data/node-id ]; then
                echo '📄 Found node-id file, checking validity...'
                NODE_ID=\$(cat /data/node-id)
                echo 'Current node-id content: '\$NODE_ID
                
                # Check if node-id is a valid UUID (36 characters with hyphens)
                if echo \"\$NODE_ID\" | grep -E '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' >/dev/null; then
                    echo '✅ Node ID is valid'
                else
                    echo '❌ Node ID is invalid, removing...'
                    rm -f /data/node-id
                    echo '🗑️  Corrupted node-id file removed'
                fi
            else
                echo '📝 No node-id file found (this is normal for fresh installations)'
            fi
            
            # Also clean up any other potentially corrupted files
            if [ -f /data/raft/raft.db ]; then
                echo '🔍 Checking raft database...'
                # Remove raft data if it might be corrupted
                if [ ! -s /data/raft/raft.db ]; then
                    echo '🗑️  Removing empty raft database'
                    rm -rf /data/raft/
                fi
            fi
        "
        
        echo "✅ Cleanup completed for $service_type volume"
    else
        echo "📁 Volume $volume_name does not exist, will be created fresh"
    fi
    echo ""
}

# Cleanup server volume
cleanup_node_id "consul_server_data" "server"

# Cleanup client volume  
cleanup_node_id "consul_agent_data" "client"

echo "🎉 All Consul volumes have been cleaned up!"
echo ""
echo "📋 Next steps:"
echo "1. Deploy the Consul stack: docker stack deploy -c consul.yaml consul"
echo "2. Check logs: docker service logs consul_server"
echo "3. Verify cluster: docker exec \$(docker ps -q -f name=consul_server) consul members"
echo ""
echo "💡 If issues persist, you can completely reset by running:"
echo "   docker volume rm consul_server_data consul_agent_data"
