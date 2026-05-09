output "bind_service" {
  value = "${kubernetes_service.bind.metadata[0].name}.${kubernetes_service.bind.metadata[0].namespace}.svc.cluster.local"
}
