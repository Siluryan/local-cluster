resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "66.2.2"
  namespace        = "monitoring"
  create_namespace = true

  values = [
    yamlencode({
      grafana = {
        adminPassword = var.grafana_admin_password
        ingress = {
          enabled          = true
          ingressClassName = "envoy"
          annotations = {
            "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
          }
          hosts = [
            "grafana.${var.cluster_domain}"
          ]
          tls = [
            {
              secretName = "grafana-tls"
              hosts = [
                "grafana.${var.cluster_domain}"
              ]
            }
          ]
        }
      }
      prometheus = {
        ingress = {
          enabled          = true
          ingressClassName = "envoy"
          annotations = {
            "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
          }
          hosts = [
            "prometheus.${var.cluster_domain}"
          ]
          tls = [
            {
              secretName = "prometheus-tls"
              hosts = [
                "prometheus.${var.cluster_domain}"
              ]
            }
          ]
        }
      }
      alertmanager = {
        enabled = true
      }
    })
  ]
}
