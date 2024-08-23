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
    # copy .env_example to .env if it doesn't exist
    if [[ ! -f .env ]]; then
        cp .env.sample .env
    fi

    # check if .env file contains EMAIL and WALLET
    if grep -q "WALLET=WALLET" .env; then
        read -p "Please enter your XDC Address for StorX Rewards :- " WALLET
        # if WALLET don't have prefix xdc then give error and close the script
        if [[ ! $WALLET =~ ^(xdc)[a-fA-F0-9]{40}$ ]]; then
            echo "Invalid XDC Address. Please enter a valid XDC Address."
            exit 1
        fi
        sed -i "s/WALLET=WALLET/WALLET=${WALLET}/g" .env
    fi

    if grep -q "EMAIL=EMAIL" .env; then
        read -p "Please enter your Email Address :- " EMAIL
        # if EMAIL is not valid then give error and close the script
        if [[ ! $EMAIL =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            echo "Invalid Email Address. Please enter a valid Email Address."
            exit 1
        fi
        sed -i "s/EMAIL=EMAIL/EMAIL=${EMAIL}/g" .env
    fi

    if grep -q "ADDRESS=IP_ADDRESS" .env; then
        IP_ADDRESS=$(curl https://checkip.amazonaws.com)
        # if IP_ADDRESS is not valid then give error and close the script
        if [[ ! $IP_ADDRESS =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "Invalid IP Address. Please enter a valid IP Address."
            exit 1
        fi
        sed -i "s/ADDRESS=IP_ADDRESS/ADDRESS=${IP_ADDRESS}/g" .env
    fi

    # get the values from env file and print them
    WALLET=$(grep WALLET .env | cut -d '=' -f2)
    EMAIL=$(grep EMAIL .env | cut -d '=' -f2)
    ADDRESS=$(grep ADDRESS .env | cut -d '=' -f2)

    echo "Configured values are as follows:"
    echo "WALLET: $WALLET"
    echo "EMAIL: $EMAIL"
    echo "ADDRESS: $ADDRESS"
}

function main() {
    # Creation of config location if it doesn't exist
    sudo bash install_docker.sh
    remove_node_v1_if_exists
    env_creation_and_repo_setup

    if [[ ! -d ~/.storx ]]; then
        echo "Creating directories for StorX node"
        mkdir -p ~/.storx/identity
        mkdir -p ~/.storx/config
    fi

    sudo bash identity_creation.sh || exit 1

    echo "Setup completed successfully. You can now start the node by sh start-node.sh"
}

main
