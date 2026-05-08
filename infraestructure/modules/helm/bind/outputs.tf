output "bind_service" {
  description = "DNS interno do servico BIND no cluster"
  value       = "${kubernetes_service.bind.metadata[0].name}.${kubernetes_service.bind.metadata[0].namespace}.svc.cluster.local"
}
