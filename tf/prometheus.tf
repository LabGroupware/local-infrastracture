locals {
  prometheus_repository = "https://prometheus-community.github.io/helm-charts"
  metrics_namespace     = "metrics"
}

############################################
# Helm Chart for Prometheus
############################################

resource "helm_release" "prometheus" {
  name             = "prometheus"
  chart            = "kube-prometheus-stack"
  repository       = local.prometheus_repository
  namespace        = local.metrics_namespace
  create_namespace = true


  values = [
    "${file("${path.module}/helm/prometheus/values.yml")}"
  ]
}

