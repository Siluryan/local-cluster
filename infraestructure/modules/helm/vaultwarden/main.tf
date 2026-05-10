resource "kubernetes_namespace" "vaultwarden" {
  metadata {
    name = "vaultwarden"
  }
}

locals {
  vaultwarden_domain_url = "https://vaultwarden.${var.cluster_domain}"
  vaultwarden_base_env = {
    ADMIN_TOKEN     = var.admin_token
    SIGNUPS_ALLOWED = var.allow_signups ? "true" : "false"
    DOMAIN          = local.vaultwarden_domain_url
  }
  vaultwarden_smtp_auth = length(trimspace(var.smtp_username)) > 0 ? {
    SMTP_USERNAME = var.smtp_username
    SMTP_PASSWORD = var.smtp_password
  } : {}
  vaultwarden_smtp_insecure = var.smtp_accept_invalid_certs && trimspace(var.smtp_host) != "" ? {
    SMTP_ACCEPT_INVALID_CERTS = "true"
  } : {}
  vaultwarden_smtp_env = trimspace(var.smtp_host) != "" ? merge({
    SMTP_HOST      = trimspace(var.smtp_host)
    SMTP_PORT      = var.smtp_port
    SMTP_SECURITY  = var.smtp_security
    SMTP_FROM      = trimspace(var.smtp_from)
    SMTP_FROM_NAME = var.smtp_from_name
  }, local.vaultwarden_smtp_auth, local.vaultwarden_smtp_insecure) : {}
}

resource "kubernetes_secret" "vaultwarden_env" {
  metadata {
    name      = "vaultwarden-env"
    namespace = kubernetes_namespace.vaultwarden.metadata[0].name
  }

  data = merge(local.vaultwarden_base_env, local.vaultwarden_smtp_env)

  type = "Opaque"
}

resource "kubernetes_persistent_volume_claim" "vaultwarden_data" {
  wait_until_bound = false

  metadata {
    name      = "vaultwarden-data"
    namespace = kubernetes_namespace.vaultwarden.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }
}

resource "kubernetes_deployment" "vaultwarden" {
  metadata {
    name      = "vaultwarden"
    namespace = kubernetes_namespace.vaultwarden.metadata[0].name
    labels = {
      app = "vaultwarden"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "vaultwarden"
      }
    }

    template {
      metadata {
        labels = {
          app = "vaultwarden"
        }
      }

      spec {
        container {
          name  = "vaultwarden"
          image = "vaultwarden/server:1.33.2"

          port {
            container_port = 80
            name           = "http"
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.vaultwarden_env.metadata[0].name
            }
          }

          volume_mount {
            name       = "vaultwarden-data"
            mount_path = "/data"
          }
        }

        volume {
          name = "vaultwarden-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.vaultwarden_data.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "vaultwarden" {
  metadata {
    name      = "vaultwarden"
    namespace = kubernetes_namespace.vaultwarden.metadata[0].name
  }

  spec {
    selector = {
      app = "vaultwarden"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

resource "terraform_data" "vaultwarden_route_dns" {
  triggers_replace = [var.cluster_domain]

  depends_on = [kubernetes_service.vaultwarden]

  provisioner "local-exec" {
    command = <<-EOT
      kubectl wait --for=condition=Established --timeout=180s crd/httproutes.gateway.networking.k8s.io
      kubectl wait --for=condition=Established --timeout=180s crd/dnsendpoints.externaldns.k8s.io
      cat <<'EOF' | kubectl apply -f -
      apiVersion: gateway.networking.k8s.io/v1
      kind: HTTPRoute
      metadata:
        name: vaultwarden
        namespace: ${kubernetes_namespace.vaultwarden.metadata[0].name}
      spec:
        parentRefs:
          - name: envoy-gateway
            namespace: envoy-gateway-system
        hostnames:
          - vaultwarden.${var.cluster_domain}
        rules:
          - backendRefs:
              - name: ${kubernetes_service.vaultwarden.metadata[0].name}
                port: 80
      ---
      apiVersion: externaldns.k8s.io/v1alpha1
      kind: DNSEndpoint
      metadata:
        name: vaultwarden-public
        namespace: ${kubernetes_namespace.vaultwarden.metadata[0].name}
      spec:
        endpoints:
          - dnsName: vaultwarden.${var.cluster_domain}
            recordTTL: 60
            recordType: CNAME
            targets:
              - envoy-gateway.envoy-gateway-system
      EOF
    EOT
  }
}
