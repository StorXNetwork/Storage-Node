#!/bin/bash
# Bootstrap N StorX nodes: shared .env + per-node identity under ~/.storx/nodes/<id>
set -euo pipefail

NODE_COUNT="${NODE_COUNT:-10}"
DIFFICULTY="${DIFFICULTY:-5}"
STORX_ROOT="${STORX_ROOT:-$HOME/.storx}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

function ensure_env() {
    if [[ ! -f .env ]]; then
        cp .env.sample .env
    fi

    if grep -q "WALLET=WALLET" .env; then
        read -p "Please enter your XDC Address for StorX Rewards :- " WALLET
        if [[ ! $WALLET =~ ^(xdc)[a-fA-F0-9]{40}$ ]]; then
            echo "Invalid XDC Address. Please enter a valid XDC Address."
            exit 1
        fi
        sed -i "s/WALLET=WALLET/WALLET=${WALLET}/g" .env
    fi

    if grep -q "EMAIL=EMAIL" .env; then
        read -p "Please enter your Email Address :- " EMAIL
        if [[ ! $EMAIL =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            echo "Invalid Email Address. Please enter a valid Email Address."
            exit 1
        fi
        sed -i "s/EMAIL=EMAIL/EMAIL=${EMAIL}/g" .env
    fi

    if grep -q "ADDRESS=IP_ADDRESS" .env; then
        ADDRESS=$(curl -s https://checkip.amazonaws.com)
        if [[ ! $ADDRESS =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "Invalid IP Address."
            exit 1
        fi
        # Base ADDRESS without port; start-multi adds per-node port
        sed -i "s/ADDRESS=IP_ADDRESS/ADDRESS=${ADDRESS}/g" .env
    fi

    if ! grep -q '^USER_ID=' .env; then
        echo "USER_ID=" >> .env
    fi

    # Normalize ADDRESS to IP only (strip any existing :port) for multi-node base
    ADDR_LINE=$(grep '^ADDRESS=' .env | cut -d '=' -f2-)
    BASE_IP="${ADDR_LINE%%:*}"
    if [[ ! $BASE_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Invalid ADDRESS in .env (expected IP). Got: $ADDR_LINE"
        exit 1
    fi
    sed -i "s|^ADDRESS=.*|ADDRESS=${BASE_IP}|" .env

    echo "Configured:"
    echo "  WALLET=$(grep '^WALLET=' .env | cut -d '=' -f2)"
    echo "  EMAIL=$(grep '^EMAIL=' .env | cut -d '=' -f2)"
    echo "  ADDRESS_IP=$(grep '^ADDRESS=' .env | cut -d '=' -f2)"
    echo "  NODE_COUNT=$NODE_COUNT  DIFFICULTY=$DIFFICULTY"
}

function ensure_identity_binary() {
    if [[ -f /usr/local/bin/identity ]]; then
        return
    fi
    echo "Identity binary not found at /usr/local/bin/identity."
    echo "Install it first (identity_creation.sh download path) or re-run after installing."
    exit 1
}

function create_node_identity() {
    local i=$1
    local node_dir="$STORX_ROOT/nodes/$i"
    local id_dir="$node_dir/identity"

    mkdir -p "$node_dir/config" "$id_dir"

    if [[ -f "$id_dir/ca.cert" && -f "$id_dir/identity.cert" ]]; then
        echo "Node $i: identity already exists, skipping."
        return
    fi

    # identity create writes under <identity-dir>/storagenode/
    local gen_root="$node_dir/gen"
    rm -rf "$gen_root"
    mkdir -p "$gen_root"

    echo "Node $i: creating identity (difficulty $DIFFICULTY)..."
    /usr/local/bin/identity create storagenode \
        --difficulty "$DIFFICULTY" \
        --identity-dir "$gen_root"

    if [[ ! -f "$gen_root/storagenode/ca.cert" || ! -f "$gen_root/storagenode/identity.cert" ]]; then
        echo "Node $i: identity generation failed."
        exit 1
    fi

    mv "$gen_root/storagenode/"* "$id_dir/"
    rm -rf "$gen_root"
    echo "Node $i: identity ready -> $id_dir"
}

function main() {
    if ! command -v docker >/dev/null 2>&1; then
        sudo bash install_docker.sh
    else
        echo "Docker is already installed."
    fi
    ensure_env
    ensure_identity_binary

    mkdir -p "$STORX_ROOT/nodes"

    for i in $(seq 1 "$NODE_COUNT"); do
        create_node_identity "$i"
    done

    echo ""
    echo "Bootstrap for $NODE_COUNT nodes completed."
    echo "Port map: node N -> storage (28966+N), dashboard (24001+N)"
    echo "  e.g. node 1: 28967 / 24002 ... node 10: 28976 / 24011"
    echo "Start with: bash start-multi.sh"
}

main
