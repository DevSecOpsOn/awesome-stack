#!/bin/bash

CLUSTER=$1
NS=$2
MY_VAULT_ADDR="http://192.168.2.227:8200"
MY_VAULT_TOKEN="hvs.Xfipv6yfKAG08xRDva3R7FEV"

(

  VAULT_HELM_SECRET_NAME=$(kubectl -n security get secrets  --output=json | jq -r '.items[].metadata | select(.name|startswith("vault-token-")).name')
  TOKEN_REVIEW_JWT=$(kubectl -n security get secret $VAULT_HELM_SECRET_NAME -ojsonpath="{ .data.token }" | base64 -D > k8s_token)
  KUBE_CA_CERT=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 -D > k8s_ca)
  KUBE_HOST=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.server}' > k8s_host)

  kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: vault-token-g955r
  namespace: $NS
  annotations:
    kubernetes.io/service-account.name: vault
type: kubernetes.io/service-account-token
EOF


  kubectl -n security describe secret $VAULT_HELM_SECRET_NAME

  # Enable kubernetes auth method
  vault auth enable -address $MY_VAULT_ADDR -path=$CLUSTER -namespace=$NS kubernetes

  # Configure kubernetes cluster into vault
  vault write -address $MY_VAULT_ADDR auth/$CLUSTER/config \
     token_reviewer_jwt=@k8s_token \
     kubernetes_host=@k8s_host \
     kubernetes_ca_cert=@k8s_ca \
     issuer="https://kubernetes.default.svc.cluster.local"

  # Create application policy
  # vault policy write -address $MY_VAULT_ADDR $CLUSTER-app policies/$CLUSTER-app.hcl
  vault policy write -address $MY_VAULT_ADDR $CLUSTER-app - <<EOF
path "$CLUSTER/secret/data/*" {
  capabilities = ["read"]
}
EOF

  # Create kubernetes application role
  vault write -address $MY_VAULT_ADDR auth/$CLUSTER/role/$CLUSTER-app \
     bound_service_account_names=$CLUSTER-app \
     bound_service_account_namespaces="*" \
     policies=$CLUSTER-app \
     ttl=24h

  vault read -address $MY_VAULT_ADDR auth/$CLUSTER/role/$CLUSTER-app

  # Deploy ngnix test
  kubectl -n $NS create sa $CLUSTER-app
  kubectl -n $NS apply -R -f test
  kubectl -n $NS get sa,secret,deploy,svc,pod -owide
)

(
  vault secrets enable -address $MY_VAULT_ADDR -path=$CLUSTER/secret kv
  vault kv put -address $MY_VAULT_ADDR $CLUSTER/secret/data/config username="root" password="root"
  vault kv get -address $MY_VAULT_ADDR -format=json $CLUSTER/secret/data/config | jq ".data"

  kubectl -n $NS create sa $CLUSTER-app

  kubectl -n security describe serviceaccount vault
  VAULT_TOKEN=$(kubectl -n security get sa vault -ojsonpath="{.secrets[].name}")

  kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: $VAULT_TOKEN
  namespace: $NS
  labels:
    env: test
  annotations:
    kubernetes.io/service-account.name: vault
type: kubernetes.io/service-account-token
EOF
  kubectl -n $NS patch deployment app --patch "$(sed -e "s/__SA__/$CLUSTER-app/" -e "s/__ROLE__/$CLUSTER-app/" -e "s/__SECRET__/$CLUSTER/" patch/patch_vault_agent.yaml)"
  kubectl -n $NS get sa,secret,deploy,svc,pod -owide
)

(
  echo "Cleaning up files"
  rm k8s_*
)
