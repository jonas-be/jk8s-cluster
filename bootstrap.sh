#!/bin/bash

export NEW_USER="jonasbe"
export PW="abc"

servers=("nc1.jonasbe.de" "nc2.jonasbe.de" "ph1.jonasbe.de")

for server in "${servers[@]}" ; do
  printf "Node init for: \e[1m$server\e[0m\n"
  # Execute node init script on server
  echo $USER $PW $server
  ssh root@$server "NEW_USER=$NEW_USER PW=$PW NEW_HOSTNAME=$server bash -s" < bootstrap/node-init.sh

  sftp $NEW_USER@$server <<< $'put port-forward/install.sh'
  sftp $NEW_USER@$server <<< $'put port-forward/start-forward.sh'
done



