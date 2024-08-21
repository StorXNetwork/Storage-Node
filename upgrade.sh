#!/bin/bash

echo "Upgrading StorX Network Configuration Scripts"
git pull

echo "Upgrading StorX Network node"
# run upgrade-steps.sh
./upgrade-steps.sh
