#!/bin/bash
echo "Configuring Aws CLI"
apt-get update && apt-get install -y curl unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf ./aws
rm -rf awscliv2.zip
aws configure