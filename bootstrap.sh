#!/bin/bash

function remove_node_v1_if_exists() {
    # Check if storxdata directory exists
    if [[ -d storxdata ]]; then
        rm -rf storxdata/data
        rm -rf storxdata/logs
    fi

    container_name="storx-node_storxnetwork_1"
    # Check if the container exists
    if docker inspect "$container_name" > /dev/null 2>&1; then
        echo "The container $container_name exists."

        # Check if the container is running
        if $(docker inspect -f '{{.State.Status}}' "$container_name" | grep -q "running"); then
            echo "The container $container_name is running."
        else
            echo "The container $container_name is not running."

            # Start the container if it is not running
            docker start "$container_name"
        fi
    fi
}

function env_creation_and_repo_setup(){
    read -p "Please enter your XDC Address for StorX Rewards :- " WALLET
    read -p "Please enter your Email Address :- " EMAIL
    IP_ADDRESS=$(curl https://checkip.amazonaws.com)

    echo "Your XDC Wallet Address is ${WALLETADD}, Email Address is ${EMAILADD} and IP Address is ${IP_ADDRESS}"

    echo "Installing Git      "

    sudo apt-get update

    sudo apt-get install \
            apt-transport-https \
            ca-certificates \
            curl \
            git \
            software-properties-common -y

    echo "Clone StorX Node"

    git clone https://github.com/StorXNetwork/StorX-Node && cd StorX-Node
    sed -i "s/WALLET=WALLET/WALLET=${WALLET}/g" .env
    sed -i "s/EMAIL=EMAIL/EMAIL=${EMAIL}/g" .env
    sed -i "s/ADDRESS=IP_ADDRESS/ADDRESS=${IP_ADDRESS}/g" .env

}

function install_docker() {
    if command -v docker &> /dev/null; then
        echo "Docker is already installed."
    else
        echo "Installing Docker..."
        # Add Docker's official GPG key:
        sudo apt-get update
        sudo apt-get install -y ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

        # Add the repository to Apt sources:
        echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
            $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | \
            sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    fi
}

function install_identity_generator() {
    # Check if identity file already exists
    if [[ -f "/usr/local/bin/identity" ]]; then
        echo "Identity binary already exists. Skipping download."
    else
        # Download and install identity file
        cd
        curl -L https://github.com/StorXNetwork/StorXMonitor/releases/latest/download/identity_linux_amd64.zip -o identity_linux_amd64.zip
        unzip -o identity_linux_amd64.zip
        chmod +x identity
        sudo mv identity /usr/local/bin/identity
        echo "Identity binary installed."
    fi
}

function identity_creation() {
    # Check if the identity files already exist
    if [[ -f ~/.storx/identity/ca.cert && -f ~/.storx/identity/identity.cert ]]; then
        echo "Identity cert and key files already exist. Skipping identity creation."
    else
        read -p "Do you want to create an identity file? (y/n) " confirmation
        if [[ "$confirmation" == "y" || "$confirmation" == "Y" ]]; then
            echo "Creating identity file..."
            install_identity_generator
            identity create storagenode

            VAR=$(grep -c BEGIN ~/.local/share/storj/identity/storagenode/ca.cert)
            VAR2=$(grep -c BEGIN ~/.local/share/storj/identity/storagenode/identity.cert)

            if [ $VAR -eq 1 ] && [ $VAR2 -eq 2 ]; then
                echo "Identity file created successfully."
                mv ~/.local/share/storj/identity/storagenode/* ~/.storx/identity
            else
                echo "identity.cert not created properly. something went wrong. pleaes contact support@storx.io for help."
            fi
        else
            echo "Identity creation skipped."
        fi
    fi
}

function main() {
    # Creation of config location if it doesn't exist
    install_docker
    remove_node_v1_if_exists

    if [[ -d ~/.storx ]]; then
        echo "setup is already done. Skipping creation."
    else
        mkdir -p ~/.storx/identity
        mkdir -p ~/.storx/config
        env_creation_and_repo_setup
    fi

    identity_creation

    echo "Setup completed successfully. You can now start the node by sh start.sh"
}
