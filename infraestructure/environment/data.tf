data "oci_containerengine_cluster_kube_config" "oke" {
  cluster_id    = local.oke_cluster_id
  endpoint      = var.oke_kubernetes_endpoint
  token_version = "2.0.0"
}
