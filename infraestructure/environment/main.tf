module "helm" {
    source = "../modules/helm"

    client_id     = var.oauth2_proxy_client_id
    client_secret = var.oauth2_proxy_client_secret
    cookie_secret = var.oauth2_proxy_cookie_secret

    cloudflare_email        = var.cloudflare_email
    cloudflare_tunnel_id    = var.cloudflare_tunnel_id
    cloudflare_tunnel_token = var.cloudflare_tunnel_token
}