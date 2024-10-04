#!/bin/bash
echo "Installing Redis"

apt-get update && apt-get install -y redis-server
systemctl enable redis-server