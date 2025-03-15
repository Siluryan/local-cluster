module "cert_manager" {
    source = "./cert-manager"  
}

module "kubernetes_dashboard" {
    source = "./kubernetes-dashboard"  
}

module "oauth2_proxy" {
    source = "./oauth-proxy"

    client_id     = var.client_id
    client_secret = var.client_secret
    cookie_secret = var.cookie_secret  
}