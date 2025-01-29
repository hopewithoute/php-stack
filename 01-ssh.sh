#!/bin/bash
echo "Configuring SSH"
systemctl disable --now ssh.socket
systemctl enable --now ssh.service
sed -i 's/^#Port 22/Port 13666/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
service sshd restart