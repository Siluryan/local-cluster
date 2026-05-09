output "bucket_name" {
  value = oci_objectstorage_bucket.terraform_state.name
}

output "namespace" {
  value = data.oci_objectstorage_namespace.ns.namespace
}

output "s3_compatible_endpoint" {
  value = format(
    "https://%s.compat.objectstorage.%s.oraclecloud.com",
    data.oci_objectstorage_namespace.ns.namespace,
    var.region
  )
}
