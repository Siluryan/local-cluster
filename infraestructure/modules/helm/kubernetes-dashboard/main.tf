resource "helm_release" "kubernetes_dashboard" {
  name       = "kubernetes-dashboard"
  repository = "https://kubernetes.github.io/dashboard/"
  chart      = "kubernetes-dashboard"
  version    = "7.11.1"
  namespace  = "kube-system"

  set {
    name  = "service.type"
    value = "ClusterIP"
  }

  set {
    name  = "ingress.enabled"
    value = "true"
  }

  set {
    name  = "ingress.hosts[0]"
    value = "dashboard.k8s.siluryan.xyz"
  }

  set {
    name  = "ingress.annotations.cert-manager\\.io/cluster-issuer"
    value = "letsencrypt-prod"
  }

  set {
    name  = "ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/backend-protocol"
    value = "HTTPS"
  }

  set {
    name  = "ingress.tls[0].secretName"
    value = "kubernetes-dashboard-tls"
  }

  set {
    name  = "ingress.tls[0].hosts[0]"
    value = "dashboard.k8s.siluryan.xyz"
  }

  set {
    name  = "rbac.clusterReadOnlyRole"
    value = "true"
  }

  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "resources.requests.memory"
    value = "100Mi"
  }

  set {
    name  = "resources.limits.cpu"
    value = "200m"
  }

  set {
    name  = "resources.limits.memory"
    value = "200Mi"
  }
}