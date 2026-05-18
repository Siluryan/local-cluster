output "namespace" {
  value = kubernetes_namespace.backstage.metadata[0].name
}

output "url" {
  value = "https://backstage.${var.cluster_domain}"
}

output "port_forward_command" {
  value = "kubectl -n backstage port-forward svc/backstage 7007:80"
}
