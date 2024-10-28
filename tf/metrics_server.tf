locals {
  metrics_server_repository = "https://kubernetes-sigs.github.io/metrics-server/"
}

resource "helm_release" "metrics_server_release" {
  name       = "metrics-server"
  repository = local.metrics_server_repository
  chart      = "metrics-server"
  namespace  = "kube-system"

  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }
}
