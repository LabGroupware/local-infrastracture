##################################################
# Helm Grafana
##################################################
locals {
  grafana_repository = "https://grafana.github.io/helm-charts"
}

resource "helm_release" "grafana" {


  name             = "grafana"
  namespace        = local.metrics_namespace
  chart            = "grafana"
  repository       = local.grafana_repository
  create_namespace = true

  # Auth Config
  set {
    name  = "grafana\\.ini.auth\\.anonymous.enabled"
    value = "true"
  }
  # set {
  #   name  = "grafana\\.ini.security.disable_initial_admin_creation"
  #   value = "true"
  # }

  # set {
  #   name  = "grafana\\.ini.auth.disable_login_form"
  #   value = "true"
  # }

  # set {
  #   name  = "grafana\\.ini.auth\\.generic_oauth.enabled"
  #   value = "true"
  # }

  # set {
  #   name  = "grafana\\.ini.auth\\.generic_oauth.client_id"
  #   value = aws_cognito_user_pool_client.admin_user_pool_grafana[0].id
  # }

  # set {
  #   name  = "env.GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET"
  #   value = aws_cognito_user_pool_client.admin_user_pool_grafana[0].client_secret
  # }

  # set {
  #   name  = "grafana\\.ini.auth\\.generic_oauth.scopes"
  #   value = "openid profile email aws.cognito.signin.user.admin"
  # }

  # set {
  #   name  = "grafana\\.ini.auth\\.generic_oauth.auth_url"
  #   value = format("https://%s/oauth2/authorize", var.auth_domain)
  # }

  # set {
  #   name  = "grafana\\.ini.auth\\.generic_oauth.token_url"
  #   value = format("https://%s/oauth2/token", var.auth_domain)
  # }

  # set {
  #   name  = "grafana\\.ini.auth\\.generic_oauth.api_url"
  #   value = format("https://%s/oauth2/userInfo", var.auth_domain)
  # }

  # set {
  #   name  = "grafana\\.ini.server.root_url"
  #   value = format("https://%s/", var.grafana_virtual_service_host)
  # }

  # set {
  #   name  = "serviceAccount.name"
  #   value = "grafana"
  # }

  # set {
  #   name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
  #   value = aws_iam_role.grafana_role[0].arn
  # }

  # set {
  #   name  = "grafana\\.ini.auth.sigv4_auth_enabled"
  #   value = "true"
  # }

  # set {
  #   name  = "grafana\\.ini.auth.sigv4_auth_region"
  #   value = var.region
  # }

  set {
    name  = "plugins[0]"
    value = "grafana-clock-panel"
  }

  # set {
  #   name  = "plugins[0]"
  #   value = "grafana-amazonprometheus-datasource"
  # }

  set {
    name  = "datasources.datasources\\.yaml.apiVersion"
    value = "1"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].name"
    value = "Prometheus"
  }

  # The SigV4 authentication in the core Prometheus data source is deprecated. Please use the Amazon Managed Service for Prometheus data source to authenticate with SigV4.
  # AWS Managed Prometheusのデータソースを使う場合は, grafana-amazonprometheus-datasourceを利用
  set {
    name  = "datasources.datasources\\.yaml.datasources[0].type"
    value = "prometheus"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].url"
    value = "http://prometheus-kube-prometheus-prometheus.${local.metrics_namespace}.svc.cluster.local:9090" #api/v1/queryは自動で付与される
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].access"
    value = "proxy"
  }


  # AWS Managed Prometheusのデータソースを使う場合は, 以下の設定を利用
  # set {
  #   name  = "datasources.datasources\\.yaml.datasources[0].url"
  #   value = format("%s", aws_prometheus_workspace.main[0].prometheus_endpoint) #api/v1/queryは自動で付与される
  # }

  # set {
  #   name  = "datasources.datasources\\.yaml.datasources[0].access"
  #   value = "proxy"
  # }

  # set {
  #   name  = "datasources.datasources\\.yaml.datasources[0].jsonData.sigV4Auth"
  #   value = "true"
  # }

  # set {
  #   name  = "datasources.datasources\\.yaml.datasources[0].jsonData.sigV4AuthType"
  #   value = "default"
  # }

  # set {
  #   name  = "datasources.datasources\\.yaml.datasources[0].jsonData.sigV4Region"
  #   value = var.region
  # }

  values = [
    "${file("${path.module}/helm/grafana/values.yml")}"
  ]
}

resource "kubectl_manifest" "grafana_virtual_service" {

  yaml_body = <<YAML
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: grafana
  namespace: ${local.istio_namespace}
spec:
  hosts:
  - "grafana.${var.domain}"
  gateways:
  - public-gateway
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: grafana.${local.metrics_namespace}.svc.cluster.local
        port:
          number: 80
YAML

  depends_on = [
    helm_release.grafana,
    helm_release.istio_base,
    helm_release.istiod
  ]
}
