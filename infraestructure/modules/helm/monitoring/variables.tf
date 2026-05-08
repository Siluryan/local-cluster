variable "cluster_domain" {
  description = "Dominio base usado nos ingressos de observabilidade"
  type        = string
}

variable "grafana_admin_password" {
  description = "Senha do usuario admin do Grafana"
  type        = string
}
