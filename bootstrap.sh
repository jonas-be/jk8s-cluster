#!/bin/bash
# Author: jonas-be

usage() {
  printf "\e[1mUsage:\e[0m\n"
  printf "You need the following environment variables set:\e[0m\n"
  echo
  printf "\e[3m# Username and Password of the new user\e[0m\n"
  printf "export \e[1mNEW_USER\e[0m='jonasbe'\e[0m\n"
  printf "export \e[1mPW\e[0m='abc'\e[0m\n"
  echo
  printf "\e[3m# Control plane endpoint\e[0m\n"
  printf "export \e[1mCP_ENDPOINT\e[0m='cp.k8s.jonasbe.de:6443'\e[0m\n"
  echo
  printf "\e[3m# Cluster name\e[0m\n"
  printf "export \e[1mCLUSTER_NAME\e[0m='jk8s'\e[0m\n"
  echo
  printf "\e[3m# Email for Let's Encrypt\e[0m\n"
  printf "export \e[1mEMAIL\e[0m='jonasbe.dev@gmail.com'\e[0m\n"
  echo
  printf "\e[3m# Servers to setup\e[0m\n"
  printf "\e[3m# it musst be the domain to connect and the hostname of a server\e[0m\n"
  printf "\e[3m# the first server is the node which runs kubeadm init\e[0m\n"
  printf "export \e[1mSERVERS\e[0m='nc1.jonasbe.de nc2.jonasbe.de ph1.jonasbe.de'\e[0m\n"
}

if [[ "${1-}" =~ ^-*h(elp)?$ ]]; then
    usage
    exit
fi


# Required environment variables
env_vars=("NEW_USER" "PW" "CP_ENDPOINT" "CLUSTER_NAME" "EMAIL" "SERVERS")

# Check if required environment variables are set
for var in "${env_vars[@]}"; do
  if [ "${!var}" == "" ]; then
    printf "\e[0;31mError: Environment variable \e[1m$var\e[0;31m is empty.\e[0m Use --help for help\n"
    exit 1
  fi
done


# Load servers from env
server_array=($SERVERS)


# Confirm execution

printf " User:                     \e[1m$NEW_USER\e[0m\n"
printf " Control plane endpoint:   \e[1m$CP_ENDPOINT\e[0m\n"
printf " Cluster name:             \e[1m$CLUSTER_NAME\e[0m\n"
printf " Let's Encrypt email:      \e[1m$EMAIL\e[0m\n\n"
echo 'Execute on the following servers:'
for server in "${server_array[@]}" ; do
  printf " >\e[1m $server \e[0m\n"
done
echo

if [[ ! "${1-}" =~ ^-*y(es)?$ ]]; then
  printf "\e[1;31mCRTL-C\e[0;31m to abort \e[0m| \e[1mAny Key\e[0m to Continue\n"
  read  -n 1 -p "(Abbort/Continue)? " mainmenuinput
fi


# Node init

for server in "${server_array[@]}" ; do
  echo "++++++++++++++++++++++++++++++++++"
  printf "Node init for: \e[1m$server\e[0m\n"
  echo "++++++++++++++++++++++++++++++++++"

  ssh root@$server "NEW_USER=$NEW_USER PW=$PW NEW_HOSTNAME=$server bash -s" < bootstrap/node-init.sh

  # Install and upload scripts for port forwarding
  ssh $NEW_USER@$server "echo $PW | sudo -S whoami; bash -s" < port-forward/install.sh
  sftp $NEW_USER@$server <<< $'put port-forward/start-forward.sh'

  # Start port-forward
  ssh $NEW_USER@$server "echo $PW | sudo -S ./start-forward.sh"
done


# Kubeadm init

master_server=${server_array[0]}

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
for ((i = 1; i < ${#server_array[@]}; i++)); do
  server="${server_array[$i]}"
  echo "++++++++++++++++++++++++++++++++++"
  printf "Kubeadm join on: \e[1m$server\e[0m\n"
  echo "++++++++++++++++++++++++++++++++++"

  ssh $NEW_USER@$server "$cp_join_command"
  ssh $NEW_USER@$server "echo $PW | sudo -S mkdir -p $HOME/.kube; sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config; sudo chown $(id -u):$(id -g) $HOME/.kube/config"
done


# Install CNI

ssh $NEW_USER@$master_server "echo $PW | sudo -S whoami; bash -s" < bootstrap/install-cni.sh


# Download kubeconfig

sftp $NEW_USER@$master_server <<< $'get .kube/config'
mv config kubeconfig-$CLUSTER_NAME


# Untaint all nodes
export KUBECONFIG=kubeconfig-$CLUSTER_NAME
kubectl taint nodes --all node-role.kubernetes.io/control-plane-


# Deploy Traefik Ingress

cd traefik
export KUBECONFIG=../kubeconfig-$CLUSTER_NAME
./deploy.sh
cd ..
export KUBECONFIG=kubeconfig-$CLUSTER_NAME

echo "Wait 10s for cert-manager to start if it fails retry 'cat traefik/letsencrypt-issuer.yaml | envsubst  | kubectl apply -f -'"
sleep 10

cat traefik/letsencrypt-issuer.yaml | envsubst  | kubectl apply -f -


# Deploy Longhorn

for server in "${server_array[@]}" ; do
  echo "++++++++++++++++++++++++++++++++++"
  printf "Longhorn pre-setup for: \e[1m$server\e[0m\n"
  echo "++++++++++++++++++++++++++++++++++"

  ssh $NEW_USER@$server "echo $PW | sudo -S whoami; bash -s" < longhorn/pre-install.sh
done

./longhorn/deploy.sh


echo "  +++++++++++++++++++++++++++++"
printf "  | \e[1;32m✔️ Cluster setup completed \e[0m|\n"
echo "  +++++++++++++++++++++++++++++"
