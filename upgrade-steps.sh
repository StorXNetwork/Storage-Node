#!/bin/bash

sudo docker pull storxnetwork/storxnode-2:latest

echo "Stopping and Removing the existing StorX Node Container"
sudo docker stop storage_node_container
sudo docker rm storage_node_container

echo "Starting the StorX Node Container with updated configuration"
docker run -d --restart unless-stopped --stop-timeout 300 \
    -p 28967:28967/tcp -p 28967:28967/udp -p 14002:14002 \
    --env-file .env \
    --mount type=bind,source="/root/.storx/identity",destination=/app/identity \
    --mount type=bind,source="/root/.storx/config",destination=/app/config \
    --name storage_node_container storxnetwork/storxnode-2:latest

echo "Congrats! Your Node has been successfully updated with latest changes!"
