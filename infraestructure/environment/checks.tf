check "kubeconfig_present" {
  assert {
    condition     = fileexists(pathexpand(var.kubeconfig_path))
    error_message = "kubeconfig_path must reference an existing file."
  }
}
