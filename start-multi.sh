#!/bin/bash
# Start N StorX docker nodes on consecutive ports.
# Node i: host storage port 28966+i, dashboard DASH_BASE+i (default 24001+i)
#
# Path A (default): host network + local satellite trust so nodes check in to
# satellite/0 (CyberLS / org_nodes). Override with LOCAL_SATELLITE=0 for prod.
set -euo pipefail

NODE_COUNT="${NODE_COUNT:-10}"
STORX_ROOT="${STORX_ROOT:-$HOME/.storx}"
IMAGE="${STORX_IMAGE:-dhaval1204/storxnode-2:staging}"
# Use 24002+ by default so we don't clash with local sim (often binds 14002)
DASH_BASE="${DASH_BASE:-24001}"
NODE_PORT_BASE="${NODE_PORT_BASE:-28966}"
# Private RPC base (host network needs unique ports per node)
PRIVATE_PORT_BASE="${PRIVATE_PORT_BASE:-17700}"

# Local satellite (sim). Satellite listens on 127.0.0.1 only → host network required.
LOCAL_SATELLITE="${LOCAL_SATELLITE:-1}"
LOCAL_TRUST_SOURCE="${LOCAL_TRUST_SOURCE:-1KR2GWtpQBV49jWZLSyCyB1aYBVzHmFLH6hpignTW4JNBCHHgq@127.0.0.1:10000}"
LOCAL_VERSION_SERVER="${LOCAL_VERSION_SERVER:-http://127.0.0.1:12000/}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! [ -x "$(command -v docker)" ]; then
    echo "Docker is not installed."
    exit 1
fi

if [[ ! -f .env ]]; then
    echo ".env missing. Run bootstrap-multi.sh first."
    exit 1
fi

WALLET=$(grep '^WALLET=' .env | cut -d '=' -f2)
EMAIL=$(grep '^EMAIL=' .env | cut -d '=' -f2)
BASE_IP=$(grep '^ADDRESS=' .env | cut -d '=' -f2)
BASE_IP="${BASE_IP%%:*}"
STORAGE=$(grep '^STORAGE=' .env | cut -d '=' -f2 || echo '"1TB"')
USER_ID=$(grep '^USER_ID=' .env | cut -d '=' -f2 || true)

if [[ ! $WALLET =~ ^(xdc)[a-fA-F0-9]{40}$ ]]; then
    echo "Invalid WALLET in .env"
    exit 1
fi
if [[ ! $EMAIL =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "Invalid EMAIL in .env"
    exit 1
fi
if [[ ! $BASE_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid ADDRESS IP in .env (use IP only for multi-node). Got: $BASE_IP"
    exit 1
fi

if [[ -n "${USER_ID:-}" && "$USER_ID" != "USER_ID" ]]; then
    if [[ ! $USER_ID =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]; then
        echo "Invalid USER_ID in .env"
        exit 1
    fi
else
    USER_ID=""
fi

if [[ "$LOCAL_SATELLITE" == "1" ]]; then
    # Satellite on host must dial 127.0.0.1:<published-or-host-port>
    if [[ "$BASE_IP" != "127.0.0.1" ]]; then
        echo "LOCAL_SATELLITE=1: overriding ADDRESS host $BASE_IP → 127.0.0.1 (satellite must reach nodes on loopback)"
        BASE_IP="127.0.0.1"
    fi
    echo "Starting $NODE_COUNT nodes → LOCAL satellite ($LOCAL_TRUST_SOURCE)"
else
    echo "Starting $NODE_COUNT nodes → production trust (LOCAL_SATELLITE=0)"
fi
echo "Wallet: $WALLET  Email: $EMAIL  USER_ID: ${USER_ID:-<none>}"

for i in $(seq 1 "$NODE_COUNT"); do
    NODE_PORT=$((NODE_PORT_BASE + i))
    DASH_PORT=$((DASH_BASE + i))
    PRIVATE_PORT=$((PRIVATE_PORT_BASE + i))
    NAME="storage_node_${i}"
    NODE_DIR="$STORX_ROOT/nodes/$i"
    ID_DIR="$NODE_DIR/identity"
    CFG_DIR="$NODE_DIR/config"
    ADDRESS="${BASE_IP}:${NODE_PORT}"

    if [[ ! -f "$ID_DIR/ca.cert" || ! -f "$ID_DIR/identity.cert" ]]; then
        echo "Node $i: identity missing at $ID_DIR. Run bootstrap-multi.sh first."
        exit 1
    fi

    if docker ps -a --format '{{.Names}}' | grep -qx "$NAME"; then
        echo "Node $i: container $NAME already exists. Run stop-multi.sh first."
        exit 1
    fi

    mkdir -p "$CFG_DIR"

    # Per-node env file (ADDRESS must include this node's port)
    ENV_FILE="$NODE_DIR/.env"
    {
        echo "WALLET=$WALLET"
        echo "EMAIL=$EMAIL"
        echo "ADDRESS=$ADDRESS"
        echo "STORAGE=$STORAGE"
        if [[ -n "$USER_ID" ]]; then
            echo "USER_ID=$USER_ID"
        fi
    } > "$ENV_FILE"

    if [[ ! -f "$CFG_DIR/config.yaml" ]]; then
        echo "Node $i: running setup..."
        docker run --rm -e SETUP="true" \
            --mount type=bind,source="$ID_DIR",destination=/app/identity \
            --mount type=bind,source="$CFG_DIR",destination=/app/config \
            --name "${NAME}_setup" \
            "$IMAGE"
    fi

    # Extra CLI args appended after entrypoint defaults (last wins for trust/version).
    EXTRA_ARGS=()
    if [[ "$LOCAL_SATELLITE" == "1" ]]; then
        EXTRA_ARGS+=(
            --server.address=":${NODE_PORT}"
            --server.private-address="127.0.0.1:${PRIVATE_PORT}"
            --console.address="127.0.0.1:${DASH_PORT}"
            --storage2.trust.sources="${LOCAL_TRUST_SOURCE}"
            --version.server-address="${LOCAL_VERSION_SERVER}"
        )
    fi

    echo "Node $i: starting $NAME  storage=$NODE_PORT  dashboard=$DASH_PORT  ADDRESS=$ADDRESS"
    if [[ "$LOCAL_SATELLITE" == "1" ]]; then
        # Host network: reach 127.0.0.1:10000 / :12000; unique listen ports via EXTRA_ARGS.
        docker run -d --restart unless-stopped --stop-timeout 300 \
            --network host \
            --env-file "$ENV_FILE" \
            --mount type=bind,source="$ID_DIR",destination=/app/identity \
            --mount type=bind,source="$CFG_DIR",destination=/app/config \
            --name "$NAME" \
            "$IMAGE" \
            "${EXTRA_ARGS[@]}"
    else
        docker run -d --restart unless-stopped --stop-timeout 300 \
            -p "${NODE_PORT}:28967/tcp" -p "${NODE_PORT}:28967/udp" -p "${DASH_PORT}:14002" \
            --env-file "$ENV_FILE" \
            --mount type=bind,source="$ID_DIR",destination=/app/identity \
            --mount type=bind,source="$CFG_DIR",destination=/app/config \
            --name "$NAME" \
            "$IMAGE"
    fi
done

echo ""
echo "All $NODE_COUNT nodes started."
if [[ "$LOCAL_SATELLITE" == "1" ]]; then
    echo "Mode: LOCAL_SATELLITE (host network → 127.0.0.1:10000 / version :12000)"
fi
echo "Dashboards:"
for i in $(seq 1 "$NODE_COUNT"); do
    echo "  node $i -> http://${BASE_IP}:$((DASH_BASE + i))  (storage port $((NODE_PORT_BASE + i)))"
done
