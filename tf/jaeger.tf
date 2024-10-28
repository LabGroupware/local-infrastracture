locals {
  jaeger_repository = "https://jaegertracing.github.io/helm-charts"
  tracing_namespace = "tracing"
}

##################################################
# Jaeger
##################################################

resource "helm_release" "jaeger" {
  name             = "jaeger"
  repository       = local.jaeger_repository
  chart            = "jaeger"
  namespace        = local.tracing_namespace
  create_namespace = true

  # OAuth設定
  # set {
  #   name  = "query.oAuthSidecar.enabled"
  #   value = "true"
  # }

  # set {
  #   name  = "query.oAuthSidecar.args[0]"
  #   value = "--provider=oidc"
  # }

  # set {
  #   name  = "query.oAuthSidecar.args[1]"
  #   value = "--oidc-issuer-url=https://${var.cognito_endpoint}"
  # }

  # set {
  #   name  = "query.oAuthSidecar.args[2]"
  #   value = "--client-id=${aws_cognito_user_pool_client.admin_user_pool_jaeger[0].id}"
  # }

  # set {
  #   name  = "query.oAuthSidecar.args[3]"
  #   value = "--client-secret=${aws_cognito_user_pool_client.admin_user_pool_jaeger[0].client_secret}"
  # }

  # set {
  #   name  = "query.oAuthSidecar.args[4]"
  #   value = "--cookie-secure=true"
  # }

  # set {
  #   name  = "query.oAuthSidecar.args[5]"
  #   value = "--cookie-secret=${aws_secretsmanager_secret_version.cookie_secret[0].secret_string}"
  # }

  # set {
  #   name  = "query.oAuthSidecar.args[6]"
  #   value = "--redirect-url=https://${var.jaeger_virtual_service_host}/oauth2/callback"
  # }

  # set {
  #   name  = "query.oAuthSidecar.args[7]"
  #   value = "--email-domain=*"
  # }

  # set {
  #   name  = "query.oAuthSidecar.args[8]"
  #   value = "--cookie-name=_oauth2_proxy"
  # }

  # set {
  #   name  = "query.oAuthSidecar.args[9]"
  #   value = "--upstream=http://127.0.0.1:16686"
  # }

  # set {
  #   name  = "query.oAuthSidecar.args[10]"
  #   value = "http-address=:4180"
  # }

  # set {
  #   name  = "query.oAuthSidecar.args[11]"
  #   value = "--skip-provider-button=true"
  # }

  # set {
  #   name  = "query.oAuthSidecar.args[12]"
  #   value = "--oidc-groups-claim=cognito:groups"
  # }

  # set {
  #   name  = "query.oAuthSidecar.args[13]"
  #   value = "--user-id-claim=email"
  # }

  values = [
    "${file("${path.module}/helm/jaeger/values.yml")}"
  ]
}

resource "kubectl_manifest" "jaeger_virtual_service" {
  yaml_body = <<YAML
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: jaeger
  namespace: ${local.istio_namespace}
spec:
  hosts:
  - "jaeger.${var.domain}"
  gateways:
  - public-gateway
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: jaeger-query.${local.tracing_namespace}.svc.cluster.local
        port:
          number: 80
YAML

  depends_on = [
    helm_release.jaeger,
    helm_release.istio_base,
    helm_release.istiod
  ]
}
