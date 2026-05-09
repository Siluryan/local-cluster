check "oke_cluster_identification" {
  assert {
    condition = (
      (var.oke_cluster_id != null && var.oke_cluster_id != "") ||
      try(data.terraform_remote_state.cluster.outputs.cluster_id != null && data.terraform_remote_state.cluster.outputs.cluster_id != "", false)
    )
    error_message = "Apply the cluster stack first, or set oke_cluster_id."
  }
}
