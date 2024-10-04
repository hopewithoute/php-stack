#!/bin/bash
echo "Installing Redis"

apt-get update && apt-get install redis-server
systemctl enable redis-server