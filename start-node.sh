#!/bin/bash
# check if identity create storagenode command is running in the background
if [[ $(ps -ef | grep -v grep | grep "identity create storagenode" | wc -l) -gt 0 ]]; then
    echo "Identity creation is already running in the background. Please wait for it to finish."
    exit 1
fi

if [[ ! -f ~/.storx/identity/ca.cert && ! -f ~/.storx/identity/identity.cert ]]; then
    echo "Identity cert and key files already exist. Skipping identity creation."
    exit 1
fi

echo "Starting the StorX Node setup..."

STORXDATA=~/.storx
CONFIGPATH="$STORXDATA"/config
IdentityPath="$STORXDATA"/identity/ca.cert

if [ ! -e "$STORXDATA" ] || [ ! -e "$IdentityPath" ]; then
    echo "Setup is not complete. Please run bootstrap.sh first."
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
