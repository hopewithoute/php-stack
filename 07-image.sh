#!/bin/bash
echo "Install Image Processing Library"
apt-get update
apt-get install -y jpegoptim
apt-get install -y optipng
apt-get install -y pngquant
apt-get install -y gifsicle
apt-get install -y webp
apt-get install -y libavif-bin # minimum 0.9.3
npm install -g svgo