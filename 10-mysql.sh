#!/bin/bash
apt-get update && apt-get install -y mysql-server
cp -rf ./config/mysql /etc

service mysql start
systemctl enable mysql

echo "Mysql Secure Installation"
mysql_secure_installation
echo "New User"

mysql --user=root <<_EOF_
  CREATE USER 'db'@'localhost' IDENTIFIED BY 'yourpassword';
  GRANT ALL PRIVILEGES ON *.* TO 'db'@'localhost' WITH GRANT OPTION;
  FLUSH PRIVILEGES;
  SELECT User, Host, plugin FROM mysql.user;
_EOF_
