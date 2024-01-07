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
