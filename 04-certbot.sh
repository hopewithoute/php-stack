#!/bin/bash
apt-get update && apt-get install -y snapd
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot