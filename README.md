# LabGroupware for API Composition + State Based Pattern Implementation

## Local Infrastructure

### Prerequire
- [asdf](./setup_asdf.md)

### Setup
#### コマンドセットアップ
``` sh
asdf plugin add terraform
asdf plugin add kind
asdf plugin add kubectl
asdf plugin add helm
asdf plugin add istioctl
asdf plugin add yq
asdf install
```

#### hostsへの追加
```
127.0.0.1       cresplanex.test
127.0.0.1       grafana.cresplanex.test
127.0.0.1       kiali.cresplanex.test
127.0.0.1       jaeger.cresplanex.test
127.0.0.1       ws.cresplanex.test
127.0.0.1       api.cresplanex.test
```

#### Kubectlの補完
> すでに行っている場合は不要
``` sh
echo "source <(kubectl completion bash)" >> ~/.bashrc
source ~/.bashrc
```

#### Set Up

### Kind Cluster構築

``` sh
kind create cluster --config kind-config.yaml
kubectl config use-context kind-kind
```

### Terraform

``` sh
source ./load_kube.sh kind-kind
terraform -chdir=tf init
terraform -chdir=tf apply
```

### Kind Cluster Delete

``` sh
terraform -chdir=tf destroy
kind delete cluster
```