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

    git clone https://github.com/StorXNetwork/Storage-Node && cd Storage-Node
    sed -i "s/WALLET=WALLET/WALLET=${WALLET}/g" .env
    sed -i "s/EMAIL=EMAIL/EMAIL=${EMAIL}/g" .env
    sed -i "s/ADDRESS=IP_ADDRESS/ADDRESS=${IP_ADDRESS}/g" .env
}

function main() {
    # Creation of config location if it doesn't exist
    sudo sh install_docker.sh
    remove_node_v1_if_exists

    if [[ -d ~/.storx ]]; then
        echo "setup is already done. Skipping creation."
    else
        mkdir -p ~/.storx/identity
        mkdir -p ~/.storx/config
        env_creation_and_repo_setup
    fi

    sudo sh ./identity_creation.sh

    echo "Setup completed successfully. You can now start the node by sh start-node.sh"
}

main
