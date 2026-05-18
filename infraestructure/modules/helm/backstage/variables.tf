variable "cluster_domain" {
  type = string
}

variable "postgres_password" {
  type      = string
  sensitive = true
}

variable "image_repository" {
  type    = string
  default = "backstage"
}

variable "image_tag" {
  type    = string
  default = "latest"
}

variable "image_pull_policy" {
  type    = string
  default = "IfNotPresent"
}

variable "github_token" {
  type      = string
  sensitive = true
  default   = ""
}

variable "github_oauth_client_id" {
  type      = string
  sensitive = true
  default   = ""
}

variable "github_oauth_client_secret" {
  type      = string
  sensitive = true
  default   = ""
}

variable "catalog_repo_url" {
  type    = string
  default = "https://github.com/Siluryan/local-cluster/raw/main/catalog-info.yaml"
}

variable "storage_size" {
  type    = string
  default = "8Gi"
}
