#!/bin/bash
# Stop and remove all multi-node storage containers (storage_node_1 .. storage_node_N)
set -euo pipefail

NODE_COUNT="${NODE_COUNT:-10}"

if ! [ -x "$(command -v docker)" ]; then
    echo "Error: docker is not installed." >&2
    exit 1
fi

for i in $(seq 1 "$NODE_COUNT"); do
    name="storage_node_${i}"
    if docker ps -a --format '{{.Names}}' | grep -qx "$name"; then
        docker stop "$name" >/dev/null 2>&1 || true
        docker rm "$name" >/dev/null 2>&1 || true
        echo "Removed $name"
    fi
done

# Also remove legacy single-node container if present
if docker ps -a --format '{{.Names}}' | grep -qx storage_node_container; then
    docker stop storage_node_container >/dev/null 2>&1 || true
    docker rm storage_node_container >/dev/null 2>&1 || true
    echo "Removed storage_node_container"
fi

echo "Done."
