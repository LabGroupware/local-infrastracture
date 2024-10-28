# ELB -> Istio Ingress

locals {
  cert_secret_name = "istio-ingressgateway-certs"
  ##############################################
  # Istio
  ##############################################
  istio_namespace  = "istio-system"
  istio_repository = "https://istio-release.storage.googleapis.com/charts"

  ##############################################
  # Kiali
  ##############################################
  kiali_repository = "https://kiali.org/helm-charts"
}

##############################################
# Istio
##############################################

resource "helm_release" "istio_base" {
  name             = "istio-base"
  chart            = "base"
  repository       = local.istio_repository
  namespace        = local.istio_namespace
  create_namespace = true

  version = "1.23.2"
}

resource "helm_release" "istiod" {
  name             = "istio"
  chart            = "istiod"
  repository       = local.istio_repository
  namespace        = local.istio_namespace
  create_namespace = true

  version = "1.23.2"

  set {
    name  = "autoscaleEnabled"
    value = "true"
  }

  set {
    name  = "autoscaleMin"
    value = 1
  }

  set {
    name  = "autoscaleMax"
    value = 5
  }

  set {
    name  = "resources.requests.cpu"
    value = "500m"
  }

  set {
    name  = "resources.requests.memory"
    value = "2Gi"
  }

  set {
    name  = "cpu.targetAverageUtilization"
    value = 75
  }
}

##############################################
# Istio Ingress
##############################################

resource "helm_release" "istio_ingress" {
  name             = "istio-ingressgateway"
  chart            = "gateway"
  repository       = local.istio_repository
  namespace        = local.istio_namespace
  create_namespace = true

  version = "1.23.2"

  set {
    name  = "service.type"
    value = "NodePort"
  }

  set {
    name  = "autoscaling.minReplicas"
    value = 1
  }

  set {
    name  = "autoscaling.maxReplicas"
    value = 5
  }

  set {
    name  = "service.ports[0].name"
    value = "status-port"
  }

  set {
    name  = "service.ports[0].port"
    value = 15021
  }

  set {
    name  = "service.ports[0].targetPort"
    value = 15021
  }

  set {
    name  = "service.ports[0].nodePort"
    value = 30021
  }

  set {
    name  = "service.ports[0].protocol"
    value = "TCP"
  }


  set {
    name  = "service.ports[1].name"
    value = "http2"
  }

  set {
    name  = "service.ports[1].port"
    value = 80
  }

  set {
    name  = "service.ports[1].targetPort"
    value = 80
  }

  set {
    name  = "service.ports[1].nodePort"
    value = 30080
  }

  set {
    name  = "service.ports[1].protocol"
    value = "TCP"
  }


  set {
    name  = "service.ports[2].name"
    value = "https"
  }

  set {
    name  = "service.ports[2].port"
    value = 443
  }

  set {
    name  = "service.ports[2].targetPort"
    value = 443
  }

  set {
    name  = "service.ports[2].nodePort"
    value = 30443
  }

  set {
    name  = "service.ports[2].protocol"
    value = "TCP"
  }

  depends_on = [
    helm_release.istio_base,
    helm_release.istiod
  ]
}

##############################################
# Kiali
##############################################

resource "helm_release" "kiali_server" {
  name             = "kiali-server"
  chart            = "kiali-server"
  repository       = local.kiali_repository
  namespace        = local.istio_namespace
  create_namespace = true

  version = "1.89.7"

  set {
    name  = "server.web_fqdn"
    value = format("kiali.%s", var.domain)
  }

  set {
    name  = "auth.strategy"
    value = "anonymous"
  }

  # set {
  #   name  = "auth.strategy"
  #   value = "openid"
  # }

  # set {
  #   name  = "auth.openid.client_id"
  #   value = aws_cognito_user_pool_client.admin_user_pool_kiali.id
  # }

  # set {
  #   name  = "auth.openid.client_secret"
  #   value = aws_cognito_user_pool_client.admin_user_pool_kiali.client_secret
  # }

  # set {
  #   name  = "auth.openid.issuer_uri"
  #   value = "https://${var.cognito_endpoint}"
  # }

  # set {
  #   name  = "auth.openid.scopes[0]"
  #   value = "openid"
  # }

  # set {
  #   name  = "auth.openid.scopes[1]"
  #   value = "email"
  # }

  # set {
  #   name  = "auth.openid.scopes[2]"
  #   value = "profile"
  # }

  # set {
  #   name  = "auth.openid.scopes[3]"
  #   value = "aws.cognito.signin.user.admin"
  # }

  # # RBACありの挙動が異常なので無効化
  # # TODO: 修正
  # set {
  #   name  = "auth.openid.disable_rbac"
  #   value = "true"
  # }

  # # ログインユーザーは閲覧のみ
  # set {
  #   name  = "deployment.view_only_mode"
  #   value = "true"
  # }

  # set {
  #   name  = "auth.openid.username_claim"
  #   value = "email"
  # }

  set {
    name  = "external_services.tracing.enabled"
    value = true
  }

  set {
    name  = "external_services.tracing.use_grpc"
    value = false
  }

  set {
    name  = "external_services.tracing.in_cluster_url"
    value = "http://jaeger-query.${local.tracing_namespace}.svc.cluster.local:80"
  }

  set {
    name  = "external_services.prometheus.url"
    value = "http://prometheus-kube-prometheus-prometheus.${local.metrics_namespace}.svc.cluster.local:9090"
  }

  set {
    name  = "external_services.grafana.enabled"
    value = true
  }

  set {
    name  = "external_services.grafana.url"
    value = "http://grafana.${local.metrics_namespace}.svc.cluster.local:80"
  }

  set {
    name  = "external_services.grafana.in_cluster_url"
    value = "http://grafana.${local.metrics_namespace}.svc.cluster.local:80"
  }

  # level=info msg="Failed to authenticate request" client=auth.client.api-key error="[api-key.invalid] API key is invalid"
  # set {
  #   name  = "external_services.grafana.auth.type"
  #   value = "basic"
  # }

  # set {
  #   name  = "external_services.grafana.auth.username"
  #   value = "admin"
  # }

  # set {
  #   name  = "external_services.grafana.auth.password"
  #   value = "YOUR_SECURE_PASSWORD"
  # }

  # set {
  #   name  = "external_services.grafana.auth.type"
  #   value = "bearer"
  # }

  # set {
  #   name  = "external_services.grafana.auth.token"
  #   value = ""
  # }

  # set {
  #   name  = "external_services.grafana.auth.use_kiali_token"
  #   value = true
  # }

  set {
    name  = "external_services.grafana.dashboards[0].name"
    value = "kubernetes-cluster-monitoring"
  }

  set {
    name  = "external_services.grafana.dashboards[1].name"
    value = "node-exporter-full"
  }

  set {
    name  = "external_services.grafana.dashboards[2].name"
    value = "prometheus-overview"
  }

  set {
    name  = "external_services.grafana.dashboards[3].name"
    value = "kubernetes-pod"
  }

  set {
    name  = "external_services.grafana.dashboards[4].name"
    value = "node-exporter"
  }

  set {
    name  = "external_services.grafana.dashboards[5].name"
    value = "cluster-monitoring-for-kubernetes"
  }

  set {
    name  = "external_services.grafana.dashboards[6].name"
    value = "k8s-cluster-summary"
  }

  set {
    name  = "external_services.grafana.dashboards[7].name"
    value = "kubernetes-cluster"
  }

  values = [
    "${file("${path.module}/helm/kiali/values.yml")}"
  ]


  depends_on = [
    helm_release.istio_base,
    helm_release.istiod,
  ]
}

# Auth RBAC
# resource "kubernetes_cluster_role_binding_v1" "admin_kiali_binding" {
#   metadata {
#     name = "kiali-admin-binding"
#   }

#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = "kiali"
#     # name      = "kiali-viewer" # view_only_mode: falseの場合はkiali
#   }

#   subject {
#     kind      = "User"
#     name      = var.admin_email
#     api_group = "rbac.authorization.k8s.io"
#   }

#   depends_on = [helm_release.kiali_server]
# }

resource "kubectl_manifest" "public_gateway" {
  yaml_body = <<YAML
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: public-gateway
  namespace: ${local.istio_namespace}
spec:
  selector:
    istio: ingressgateway
  servers:
    - port:
        number: 80
        protocol: HTTP
        name: http
      hosts:
        - "*"
    - port:
        number: 443
        protocol: HTTPS
        name: https
      tls:
        mode: SIMPLE
        credentialName: ${local.cert_secret_name}
      hosts:
        - "*"
YAML

  depends_on = [
    helm_release.istio_base,
    helm_release.istiod,
    kubernetes_secret.istio_tls_secret
  ]
}

resource "kubectl_manifest" "kiali_virtual_service" {
  yaml_body = <<YAML
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: kiali
  namespace: ${local.istio_namespace}
spec:
  hosts:
    - "kiali.${var.domain}"
  gateways:
    - public-gateway
  http:
    - match:
      - uri:
          prefix: /
      route:
      - destination:
          host: kiali.${local.istio_namespace}.svc.cluster.local
          port:
            number: 20001
YAML

  depends_on = [
    helm_release.kiali_server,
    helm_release.istio_base,
    helm_release.istiod
  ]
}
