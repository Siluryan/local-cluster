module "cert_manager" {
    source = "./cert-manager"
    depends_on = [ module.nginx ]  
}

module "k8s_dashboard_oauth2_proxy" {
    source = "./k8s_dashboard_oauth-proxy"
    client_id     = var.client_id
    client_secret = var.client_secret
    cookie_secret = var.cookie_secret
    depends_on    = [ module.kubernetes_dashboard ]  
}

module "kubernetes_dashboard" {
    source = "./kubernetes-dashboard"
    depends_on = [ module.cert_manager ]  
}

module "nginx" {
    source = "./nginx"  
}

module "cloudflared" {
    source = "./cloudflared"
    cloudflare_email        = var.cloudflare_email
    cloudflare_tunnel_id    = var.cloudflare_tunnel_id
    cloudflare_tunnel_token = var.cloudflare_tunnel_token
    depends_on              = [ module.nginx ]  
}