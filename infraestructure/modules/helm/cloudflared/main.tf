resource "helm_release" "cloudflared" {
  name       = "cloudflared"
  repository = "https://charts.kubito.dev"
  chart      = "cloudflared"
  version    = "1.6.0"

  set {
    name  = "local.enabled"
    value = "true"
  }

  set {
    name  = "local.auth.accountTag"
    value = "siluryan.xyz"
  }
  
  set {
    name  = "local.auth.tunnelName"
    value = "Kubernetes Dashboard"
  }

  set {
    name  = "local.auth.tunnelID"
    value = var.cloudflare_tunnel_id
  }

  set_sensitive {
    name  = "local.auth.tunnelSecret"
    value = var.cloudflare_tunnel_token
  }

  set {
    name  = "logLevel"
    value = "info"
  }

  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "resources.requests.memory"
    value = "128Mi"
  }
}