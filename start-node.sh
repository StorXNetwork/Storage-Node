#!/bin/bash
# check if there is docker installed or not
if ! [ -x "$(command -v docker)" ]; then
    echo "Docker is not installed. Please install docker first. for that you can use bootstrap.sh, install_docker.sh or install manually."
    exit 1
fi

# check if there is any container with the same name storage_node_container
if [[ $(docker ps -a --format '{{.Names}}' | grep storage_node_container | wc -l) -gt 0 ]]; then
    echo "A container with the name storage_node_container already exists. Please remove the container first. for that use stop-node.sh or upgrade.sh"
    exit 1
fi

# check if identity create storagenode command is running in the background
if [[ $(ps -ef | grep -v grep | grep "identity create storagenode" | wc -l) -gt 0 ]]; then
    echo "Identity creation is already running in the background. Please wait for it to finish."
    exit 1
fi

if [[ ! -f ~/.storx/identity/ca.cert || ! -f ~/.storx/identity/identity.cert ]]; then
    echo "Identity cert/key missing. Please run bootstrap.sh first."
    exit 1
fi

echo "Validating env values"
WALLET=$(grep '^WALLET=' .env | cut -d '=' -f2)
EMAIL=$(grep '^EMAIL=' .env | cut -d '=' -f2)
ADDRESS=$(grep '^ADDRESS=' .env | cut -d '=' -f2)
USER_ID=$(grep '^USER_ID=' .env | cut -d '=' -f2 || true)


if [[ ! $WALLET =~ ^(xdc)[a-fA-F0-9]{40}$ ]]; then
    echo "Invalid XDC Address. Please enter a valid XDC Address." $WALLET
    exit 1
fi

# if EMAIL is not valid then give error and close the script
if [[ ! $EMAIL =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "Invalid Email Address. Please enter a valid Email Address."
    exit 1
fi

if [[ ! $ADDRESS =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(:28967)$ ]]; then
    echo "Invalid IP Address. Please enter a valid IP Address."
    exit 1
fi

# USER_ID is optional for public nodes; set from CyberLS setup for own-nodes bind.
if [[ -n "$USER_ID" && "$USER_ID" != "USER_ID" ]]; then
    if [[ ! $USER_ID =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]; then
        echo "Invalid USER_ID. Expected a UUID from CyberLS setup."
        exit 1
    fi
else
    USER_ID=""
fi

echo "Starting the StorX Node setup..."
echo "Wallet: $WALLET"
echo "Email: $EMAIL"
echo "Address: $ADDRESS"
if [[ -n "$USER_ID" ]]; then
    echo "User ID (CyberLS bind): $USER_ID"
fi


STORXDATA=~/.storx
CONFIGPATH="$STORXDATA"/config
IdentityPath="$STORXDATA"/identity/ca.cert

if [ ! -e "$STORXDATA" ] || [ ! -e "$IdentityPath" ]; then
    echo "Setup is not complete. Please run bootstrap.sh first."
    exit 1
fi

if [ ! -e "$CONFIGPATH"/config.yaml ]; then
    echo "Config file not found. Running setup..."
    docker run --rm -e SETUP="true" --mount type=bind,source="/root/.storx/identity",destination=/app/identity --mount type=bind,source="/root/.storx/config",destination=/app/config --name storage_node_container dhaval1204/storxnode-2:staging
fi

echo "Starting the StorX Node..."
# Start the node
docker run -d --restart unless-stopped --stop-timeout 300 \
    -p 28967:28967/tcp -p 28967:28967/udp -p 14002:14002 \
    --env-file .env \
    --mount type=bind,source="/root/.storx/identity",destination=/app/identity \
    --mount type=bind,source="/root/.storx/config",destination=/app/config \
    --name storage_node_container dhaval1204/storxnode-2:staging

echo "StorX Node started successfully."
