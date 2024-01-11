# jk8s-cluster

## Bootstrap

### Start be preparing your nodes

1. Add an ssh key to the ``authorized_keys`` file on your hosts
2. Modify the script ``bootstrap/node-init.sh`` to your needs (change the hostname and username)
3. Copy your version of the ``bootstrap/node-init.sh`` on your nodes and run it as root
4. Set an password for the new user: execute ``passwd YOUR_USER``

### Initialize the cluster

1. Modify the ``bootstrap/kubeadm-init.sh`` script to your needs (change the *control-plane-endpoint*)
2. Copy your version of the ``bootstrap/kubeadm-init.sh`` on one of your nodes and run it as root (sudo with you user)

### Join the other nodes

You need to run on the node you initialized the cluster

```bash
kubeadm init phase upload-certs --upload-certs
```

Remember the output.

```bash
kubeadm token create --print-join-command
```

Then compose joining command for joinning-master-node from this output and add to it
```--control-plane --certificate-key xxxx```

### Install CNI

I use cilium as CNI. Just follow the [cilium docs](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/)

#### Install cilium cli

```bash
# Install script from the cilium docs
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
```

#### Install the CNI

```bash
# Install cilium CNI command from cilium docs
cilium install --version 1.14.5
```

### Port forwarding

To forward ports to a node port, you can look at the scripts in ``port-forward``.

**Do the following steps on all nodes!** 

First execute ``./port-forward/install.sh`` to install ``socat`` and ``screen``.
Then start the ``./port-forward/start-forward.sh`` script to forward the port configured in there.
By default it forwards port 80 and 443 to the nodeports configure in the Traefik deployment.

### Deploy Traefik Ingress

To install Traefik Ingress you first have to execute the script ``traefik/deploly.sh``,
which has some helm and kubectl commands to install ``Traefik`` and ``certmanager``. <br>
After the deploying of ``traefik`` and ``certmanger`` you can set up your issuer for letsencrypt ssl certificates. 
Edit the ``traefik/letsencrypt-issuer.yaml`` file and change the email to your email.
Then apply it ``kubectl apply -f traefik/letsencrypt-issuer.yaml``.

#### Test Deployment with Ingress and SSL

Edit the ``traefik/whoami/whoami.yaml``  file and change the domain to your domain.
Make sure the domain is pointing to all of your servers.
Then apply the manifest ``kubectl apply -f traefik/whoami/whoami.yaml``.


