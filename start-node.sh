#!/bin/bash
echo "A StorX Nodes ..."

STORXDATA=~/.storx
CONFIGPATH="$STORXDATA"/config
IdentityPath="$STORXDATA"/identity/ca.cert

if [ ! -e "$STORXDATA" ] || [ ! -e "$IdentityPath" ]; then
    echo "Setup is not complete. Please run setup.sh first."
    exit 1
fi

if [ ! -e "$CONFIGPATH"/config.yaml ]; then
    echo "Config file not found. Running setup..."
    docker run --rm -e SETUP="true" --mount type=bind,source="/root/.storx/identity",destination=/app/identity --mount type=bind,source="/root/.storx/config",destination=/app/config --name storage_node_container storxnetwork/storxnode-2:latest
fi

echo "Starting the StorX Node..."
# Start the node
docker run -d --restart unless-stopped --stop-timeout 300 \
    -p 28967:28967/tcp -p 28967:28967/udp -p 14002:14002 \
    --env-file .env \
    --mount type=bind,source="/root/.storx/identity",destination=/app/identity \
    --mount type=bind,source="/root/.storx/config",destination=/app/config \
    --name storage_node_container storxnetwork/storxnode-2:latest

echo "StorX Node started successfully."
