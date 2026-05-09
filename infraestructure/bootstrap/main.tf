data "oci_objectstorage_namespace" "ns" {}

resource "oci_objectstorage_bucket" "terraform_state" {
  compartment_id = coalesce(var.compartment_id, var.tenancy_id)
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = var.bucket_name
  access_type    = "NoPublicAccess"
  versioning     = "Enabled"
}
