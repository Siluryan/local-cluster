output "namespace" {
  value = kubernetes_namespace.mail.metadata[0].name
}

output "submission_host" {
  value = "postfix.mail.svc.cluster.local"
}
