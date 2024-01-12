#!/bin/bash

export NEW_USER="jonasbe"
export PW="abc"

export CP_ENDPOINT="cp.k8s.jonasbe.de:6443"
export CLUSTER_NAME="jk8s"

export EMAIL="jonasbe.dev@gmail.com"

servers=("nc1.jonasbe.de" "nc2.jonasbe.de" "ph1.jonasbe.de")

# Node init

for server in "${servers[@]}" ; do
  echo "++++++++++++++++++++++++++++++++++"
  printf "Node init for: \e[1m$server\e[0m\n"
  echo "++++++++++++++++++++++++++++++++++"

  ssh root@$server "NEW_USER=$NEW_USER PW=$PW NEW_HOSTNAME=$server bash -s" < bootstrap/node-init.sh

  # Install and upload scripts for port forwarding
  ssh $NEW_USER@$master_server "echo $PW | sudo -S whoami; bash -s" < port-forward/install.sh
  sftp $NEW_USER@$server <<< $'put port-forward/start-forward.sh'

  # Start port-forward
  ssh $NEW_USER@$master_server "echo $PW | sudo -S ./start-forward.sh"
done


# Kubeadm init

master_server=${servers[0]}

echo "++++++++++++++++++++++++++++++++++"
printf "Kubeadm init on: \e[1m$master_server\e[0m\n"
echo "++++++++++++++++++++++++++++++++++"

ssh $NEW_USER@$master_server "CP_ENDPOINT=$CP_ENDPOINT CLUSTER_NAME=$CLUSTER_NAME PW=$PW bash -s" < bootstrap/kubeadm-init.sh


# Get cert key
cert_upload_output=$(ssh $NEW_USER@$master_server "echo $PW | sudo -S kubeadm init phase upload-certs --upload-certs")
cert_key=$(echo $cert_upload_output |grep -P '.*\[upload-certs\] Using certificate key: \K.*' -o)
# Get join command
join_command=$(ssh $NEW_USER@$master_server "echo $PW | sudo -S kubeadm token create --print-join-command")

# Compose the control plane join command
cp_join_command="echo $PW | sudo -S $join_command --control-plane --certificate-key $cert_key"

# Join all nodes to the cluster except the master node
for ((i = 1; i < ${#servers[@]}; i++)); do
  server="${servers[$i]}"
  echo "++++++++++++++++++++++++++++++++++"
  printf "Kubeadm join on: \e[1m$server\e[0m\n"
  echo "++++++++++++++++++++++++++++++++++"

  ssh $NEW_USER@$server "$cp_join_command"
  ssh $NEW_USER@$server "echo $PW | sudo -S mkdir -p $HOME/.kube; sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config; sudo chown $(id -u):$(id -g) $HOME/.kube/config"
done


# Install CNI

ssh $NEW_USER@$master_server "echo $PW | sudo -S whoami; bash -s" < bootstrap/install-cni.sh


# Start port-forward

for server in "${servers[@]}" ; do
  ssh $NEW_USER@$master_server "echo $PW | sudo -S ./install.sh"
  ssh $NEW_USER@$master_server "echo $PW | sudo -S ./start-forward.sh"
done


# Download kubeconfig

sftp $NEW_USER@$master_server <<< $'get .kube/config'
mv config kubeconfig-$CLUSTER_NAME


# Deploy Traefik Ingress

cd traefik
export KUBECONFIG=../kubeconfig-$CLUSTER_NAME
./deploy.sh
cd ..
export KUBECONFIG=kubeconfig-$CLUSTER_NAME

echo "Wait 5s for cert-manager to start if it fails retry 'cat traefik/letsencrypt-issuer.yaml | envsubst  | kubectl apply -f -'"
sleep 5

cat traefik/letsencrypt-issuer.yaml | envsubst  | kubectl apply -f -

echo "  +++++++++++++++++++++++++++++"
printf "  | \e[1;32m✔️ Cluster setup completed \e[0m|\n"
echo "  +++++++++++++++++++++++++++++"

