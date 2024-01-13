#!/bin/bash

sudo apt-get install open-iscsi -y
sudo apt-get install nfs-common -y
sudo apt-get install bash curl findmnt grep awk blkid lsblk -y
sudo apt-get install jq -y
echo "Checking environment..."
curl -sSfL https://raw.githubusercontent.com/longhorn/longhorn/v1.5.3/scripts/environment_check.sh | bash

