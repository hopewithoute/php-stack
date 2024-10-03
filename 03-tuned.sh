#!/bin/bash
echo "Configuring Tuned"
apt-get update && apt-get install -y tuned
systemctl enable tuned
systemctl start tuned