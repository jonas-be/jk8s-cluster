# External Secrets Operator Vault

## Deploy

### 1. Policy erstellen *k8s-readonly*

```
path "k8s/*" {
  capabilities = ["read", "list"]
}
```

### 2. Enable access approle

### 3. Exec in vault pod

**FIRST login**

```bash
vault write auth/approle/role/k8s-secret-injector \
  token_policies=k8s-readonly \
  secret_id_num_uses=0 \
  secret_id_ttl=0 \
  token_ttl=20m \
  token_max_ttl=30m

# Notice the role_id
vault read auth/approle/role/k8s-secret-injector/role-id

# Only exec once!!! Notice the secret_id
vault write -f auth/approle/role/k8s-secret-injector/secret-id
```

### 4. Create secret

```bash
kubectl create secret generic k8s-secret-injector -n external-secrets --from-literal=secret-id=<SECRET_VALUE>
```

### 5. Deployment

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: vault-css
spec:
  provider:
    vault:
      server: "http://vault-service.vault:8200"
      path: "k8s/"
      version: "v2"
      auth:
        appRole:
          path: "approle"
          roleId: "<your-role-id>"
          secretRef:
            name: "k8s-secret-injector"
            namespace: "external-secrets"
            key: "secret-id"
```

apply it

## How to Vault

### Init

You have to init the vault and unseal it to get the pod ready

```bash
kubectl exec -ti <name of vault pod> -- vault operator init
```

### Unseal

You have to unseal 3 times in a row to unseal the vault.

```bash
kubectl exec -ti <name of vault pod> -- vault operator unseal
```
