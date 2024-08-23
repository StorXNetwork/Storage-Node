# check if docker is installed
if ! [ -x "$(command -v docker)" ]; then
  echo 'Error: docker is not installed.' >&2
  exit 1
fi

# check if storage_node_container is running
if sudo docker ps | grep -q storage_node_container; then
    sudo docker stop storage_node_container
fi

# check if storage_node_container exists
if sudo docker ps -a | grep -q storage_node_container; then
    sudo docker rm storage_node_container
fi
