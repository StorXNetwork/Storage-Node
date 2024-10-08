#!/bin/bash

function install_identity_generator() {
    # Check if identity file already exists
    if [[ -f "/usr/local/bin/identity" ]]; then
        echo "Identity binary already exists. Skipping download."
    else
        sudo apt-get install -y curl unzip
        # Download and install identity file

        # get linux architecture | amd64 or arm
        architecture=""
        # Get the architecture using uname -m
        # Determine the architecture and convert it to the required format
        case "$(uname -m)" in
            x86_64)
                architecture="amd64"
                ;;
            aarch64)
                architecture="arm64"
                ;;
            armv7l|armv8l|arm)
                architecture="arm"
                ;;
        esac

        # supported architecture are amd64, arm and arm64. if architecture is not supported then exit
        if [[ "$architecture" != "amd64" && "$architecture" != "arm" && "$architecture" != "arm64" ]]; then
            echo "Your architecture is not supported by the StorXMonitor. Please contact support@storx.io for help."
            exit 1
        fi

        identityZipfile="identity_linux_${architecture}.zip"
        echo "Downloading identity binary: ${identityZipfile}"

        curl -L https://github.com/StorXNetwork/StorXMonitor/releases/latest/download/${identityZipfile} -o /tmp/${identityZipfile}
        unzip -o /tmp/${identityZipfile} -d /usr/local/bin
        chmod +x /usr/local/bin/identity
        echo "Identity binary installed."
    fi
}

function identity_creation() {
    # Check if the identity files already exist
    if [[ -f ~/.storx/identity/ca.cert && -f ~/.storx/identity/identity.cert ]]; then
        echo "Identity cert and key files already exist. Skipping identity creation."
    elif [[ -f ~/.local/share/storj/identity/storagenode/ca.cert && -f ~/.local/share/storj/identity/storagenode/identity.cert ]]; then
        VAR=$(grep -c BEGIN ~/.local/share/storj/identity/storagenode/ca.cert)
        VAR2=$(grep -c BEGIN ~/.local/share/storj/identity/storagenode/identity.cert)

        if [ $VAR -eq 1 ] && [ $VAR2 -eq 2 ]; then
            echo "Identity file created successfully. Moving files to the correct location."
            mv ~/.local/share/storj/identity/storagenode/* ~/.storx/identity
        else
            echo "identity.cert not created properly. something went wrong. pleaes contact support@storx.io for help."
            exit 1
        fi
    else
        # check if identity create storagenode command is running in the background
        if [[ $(ps -ef | grep -v grep | grep "identity create storagenode" | wc -l) -gt 0 ]]; then
            echo "Identity creation is already running in the background. Please wait for it to finish."
            exit 1
        fi

        read -p "Do you want to create an identity file? (y/n) " confirmation
        if [[ "$confirmation" == "y" || "$confirmation" == "Y" ]]; then
            echo "Creating identity file. this process will take some hours."
            install_identity_generator
            /usr/local/bin/identity create storagenode &
            pid=$!

            disown $pid

            echo "Identity creation started in the background. This process will take some hours. please try same command after some time."
            exit 1
        else
            echo "Identity creation skipped."
        fi
    fi
}

identity_creation
