#!/bin/bash
echo "Configuring UFW"
apt-get update && apt-get install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow 80
ufw allow 443
ufw allow 13666