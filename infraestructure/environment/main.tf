module "helm" {
    source = "./modules/helm"

    client_id     = var.oauth2_proxy_client_id
    client_secret = var.oauth2_proxy_client_secret
    cookie_secret = var.oauth2_proxy_cookie_secret  
}