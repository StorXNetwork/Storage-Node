#!/bin/bash

echo "Upgrading StorX Network Configuration Scripts"
git pull

echo "Upgrading StorX Network node"
# run upgrade-steps.sh
sudo bash upgrade-steps.sh
