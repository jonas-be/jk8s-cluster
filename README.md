# jk8s-cluster

## Requirements

- 3 Servers
  - Debain 12
  - Root access
- Domain
  - Be able to set DNS records
- Local machine
  - kubectl
  - helm

## Quickstart

**First prepare your nodes:**

1. Debain 12
2. Add your ssh key to the ``authorized_keys`` file on the root

**Create control plane endpoint:**

Create a sub domain for your control plane endpoint. <br>
Create an A record for the sub domain pointing to the first node. <br>
After the setup you can add A records for all nodes.

**Then configure the bootstrap script by setting the env vars:**

```bash
# Username and Password of the new user
export NEW_USER='jonasbe'
export PW='abc'

# Control plane endpoint
export CP_ENDPOINT='cp.k8s.jonasbe.de:6443'

# Cluster name
export CLUSTER_NAME='jk8s'

# Email for Let's Encrypt
export EMAIL='jonasbe.dev@gmail.com'

# Servers to setup
# it musst be the domain to connect and the hostname of a server
# the first server is the node which runs kubeadm init
export SERVERS='nc1.jonasbe.de nc2.jonasbe.de ph1.jonasbe.de'
```

**After configuring the setup, execute the script:**

```bash
./bootstrap.sh
```

## What happens?

### Initialize the nodes

1. Create a new user
2. Move ssh keys to new user and remove from root
3. Update the system
4. Install containerd
5. Install kubeadm, kubelet and kubectl

### Initialize the cluster

Runs on the first node you configured

1. Create a kubeadm config file
2. Kubeadm init with the created config file
3. Copy the kubeconfig file to the new user

### Join the other nodes

1. Runs ```upload-certs``` over kubeadm
2. Generate a join command
3. Combines the certs from step 1 and the join command from step 2 and uses it to join the node

### Install CNI

1. Install cilium cli on master node
2. Install cilium CNI command

### Untatint all nodes

All nodes get untainted, so that pods can be scheduled on them.

### Port forwarding

To forward ports to a node port, it uses socat.

By default it forwards port 80 and 443 to the nodeports configure in the Traefik deployment.

1. Install socat and screen
2. Start a screen session's *(you have start them after every reboot)*

**How to start the forwarding manually:**

```bash
./start-forward.sh
```

### Deploy Traefik Ingress

1. Install Traefik over helm
2. Install certmanager
3. Wait 10s to let certmanager get ready
4. Apply letsencrypt clusterissuer, for tls certificates

## Deployments

### Test Deployment with Ingress and SSL

Edit the ``traefik/whoami/whoami.yaml``  file and change the domain to your domain.
Make sure the domain is pointing to all of your servers.
Then apply the manifest ``kubectl apply -f traefik/whoami/whoami.yaml``.
