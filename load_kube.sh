#!/bin/bash

# YAMLファイルのパス
CONTEXT_NAME="$1"
YAML_FILE="$HOME/.kube/config"

if [ -z "$CONTEXT_NAME" ]; then
  echo "Usage: $0 <cluster-name>"
  exit 1
fi

# 必要な情報を抽出して環境変数に代入
TF_VAR_host=$(yq e ".clusters[] | select(.name == \"${CONTEXT_NAME}\").cluster.server" $YAML_FILE)
TF_VAR_client_certificate=$(yq e ".users[] | select(.name == \"${CONTEXT_NAME}\").user[\"client-certificate-data\"]" $YAML_FILE)
TF_VAR_client_key=$(yq e ".users[] | select(.name == \"${CONTEXT_NAME}\").user[\"client-key-data\"]" $YAML_FILE)
TF_VAR_cluster_ca_certificate=$(yq e ".clusters[] | select(.name == \"${CONTEXT_NAME}\").cluster[\"certificate-authority-data\"]" $YAML_FILE)

export TF_VAR_host
export TF_VAR_client_certificate
export TF_VAR_client_key
export TF_VAR_cluster_ca_certificate

echo "kubernetes settings for Terraform Successfully loaded"