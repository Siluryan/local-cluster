variable "oauth2_proxy_client_id" {
  description = "Google OAuth Client ID"
  type        = string
}

variable "oauth2_proxy_client_secret" {
  description = "Google OAuth Client Secret"
  type        = string
}

variable "oauth2_proxy_cookie_secret" {
  description = "Cookie Secret for OAuth2-Proxy"
  type        = string
}

variable "client_id" {
  description = "Google OAuth Client ID"
  type        = string
}

variable "client_secret" {
  description = "Google OAuth Client Secret"
  type        = string
}

variable "cookie_secret" {
  description = "Cookie Secret for OAuth2-Proxy"
  type        = string
}

variable "cloudflare_email" {
    description = "Clouflare account email"
    type = string
}

variable "cloudflare_tunnel_id" {
    description = "Cloudflare tunnel ID"
    type = string
}

variable "cloudflare_tunnel_token" {
    description = "CLoudflare tunnel Token"
    type = string
}