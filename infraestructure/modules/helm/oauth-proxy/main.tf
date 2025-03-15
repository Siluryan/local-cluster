resource "helm_release" "oauth2_proxy" {
  name       = "oauth2-proxy"
  repository = "https://oauth2-proxy.github.io/manifests"
  chart      = "oauth2-proxy"
  version    = "7.12.5"

  set {
    name  = "config.clientID"
    value = var.client_id
  }

  set {
    name  = "config.clientSecret"
    value = var.client_secret
  }

  set {
    name  = "config.cookieSecret"
    value = var.cookie_secret
  }

  set {
    name  = "config.configFile"
    value = <<EOF
      email_domains = [ "*" ]
      upstreams = [ "file:///dev/null" ]
      EOF
  }

  set {
    name  = "extraArgs.provider"
    value = "google"
  }

  set {
    name  = "extraArgs.redirect-url"
    value = "https://in-definition.com/oauth2/callback" # TODO
  }

  set {
    name  = "extraArgs.email-domain"
    value = "*"
  }

  set {
    name  = "extraArgs.cookie-secure"
    value = "true"
  }

  set {
    name  = "extraArgs.scope"
    value = "https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/userinfo.profile"
  }
}
