locals {
  host                = "backstage.${var.cluster_domain}"
  public_url          = "https://${local.host}"
  postgres_host       = "${helm_release.postgresql.name}"
  github_token_set    = length(trimspace(var.github_token)) > 0
  github_oauth_set    = length(trimspace(var.github_oauth_client_id)) > 0 && length(trimspace(var.github_oauth_client_secret)) > 0
  app_config_k8s_yaml = yamlencode({
    app = {
      title   = "Local Cluster Lab"
      baseUrl = local.public_url
    }
    backend = {
      baseUrl = local.public_url
      listen  = ":7007"
      cors = {
        origin      = local.public_url
        methods     = ["GET", "HEAD", "PATCH", "POST", "PUT", "DELETE"]
        credentials = true
      }
      database = {
        client = "pg"
        connection = {
          host     = "${POSTGRES_HOST}"
          port     = "${POSTGRES_PORT}"
          user     = "${POSTGRES_USER}"
          password = "${POSTGRES_PASSWORD}"
          database = "backstage"
        }
      }
    }
    auth = merge(
      { providers = { guest = {} } },
      local.github_oauth_set ? {
        environment = "production"
        providers = {
          guest = {}
          github = {
            production = {
              clientId     = var.github_oauth_client_id
              clientSecret = var.github_oauth_client_secret
              signIn = {
                resolvers = [
                  { resolver = "usernameMatchingUserEntityName" }
                ]
              }
            }
          }
        }
      } : {}
    )
    integrations = local.github_token_set ? {
      github = [{
        host  = "github.com"
        token = "${GITHUB_TOKEN}"
      }]
    } : {}
    catalog = {
      locations = [
        {
          type   = "url"
          target = var.catalog_repo_url
        }
      ]
    }
  })
}

resource "kubernetes_namespace" "backstage" {
  metadata {
    name = "backstage"
  }
}

resource "helm_release" "postgresql" {
  name             = "backstage-postgresql"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "postgresql"
  version          = "15.5.38"
  namespace        = kubernetes_namespace.backstage.metadata[0].name
  create_namespace = false
  timeout          = 600

  values = [
    yamlencode({
      global = {
        security = {
          allowInsecureImages = true
        }
      }
      image = {
        registry   = "docker.io"
        repository = "bitnamilegacy/postgresql"
        tag        = "17.6.0-debian-12-r4"
      }
      auth = {
        username = "backstage"
        password = var.postgres_password
        database = "backstage"
      }
      primary = {
        persistence = {
          enabled = true
          size    = var.storage_size
        }
        resources = {
          requests = {
            cpu    = "100m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
      }
    })
  ]
}

resource "kubernetes_secret" "backstage" {
  metadata {
    name      = "backstage-secrets"
    namespace = kubernetes_namespace.backstage.metadata[0].name
  }

  data = merge(
    { POSTGRES_PASSWORD = var.postgres_password },
    local.github_token_set ? { GITHUB_TOKEN = var.github_token } : {}
  )

  type = "Opaque"
}

resource "kubernetes_config_map" "backstage" {
  metadata {
    name      = "backstage-config"
    namespace = kubernetes_namespace.backstage.metadata[0].name
  }

  data = {
    "app-config.kubernetes.yaml" = local.app_config_k8s_yaml
  }
}

resource "kubernetes_deployment" "backstage" {
  metadata {
    name      = "backstage"
    namespace = kubernetes_namespace.backstage.metadata[0].name
    labels = {
      app = "backstage"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "backstage"
      }
    }

    template {
      metadata {
        labels = {
          app = "backstage"
        }
      }

      spec {
        container {
          name  = "backstage"
          image = "${var.image_repository}:${var.image_tag}"
          image_pull_policy = var.image_pull_policy

          command = [
            "node",
            "packages/backend",
            "--config",
            "app-config.yaml",
            "--config",
            "app-config.production.yaml",
            "--config",
            "app-config.kubernetes.yaml",
          ]

          port {
            name           = "http"
            container_port = 7007
          }

          env {
            name = "POSTGRES_HOST"
            value = local.postgres_host
          }

          env {
            name = "POSTGRES_PORT"
            value = "5432"
          }

          env {
            name = "POSTGRES_USER"
            value = "backstage"
          }

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.backstage.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          dynamic "env" {
            for_each = local.github_token_set ? [1] : []
            content {
              name = "GITHUB_TOKEN"
              value_from {
                secret_key_ref {
                  name = kubernetes_secret.backstage.metadata[0].name
                  key  = "GITHUB_TOKEN"
                }
              }
            }
          }

          volume_mount {
            name       = "config"
            mount_path = "/app/app-config.kubernetes.yaml"
            sub_path   = "app-config.kubernetes.yaml"
          }

          resources {
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "1500m"
              memory = "1536Mi"
            }
          }

          readiness_probe {
            http_get {
              path = "/healthcheck"
              port = 7007
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold       = 12
          }

          liveness_probe {
            http_get {
              path = "/healthcheck"
              port = 7007
            }
            initial_delay_seconds = 60
            period_seconds        = 20
            timeout_seconds       = 5
            failure_threshold       = 6
          }
        }

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.backstage.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [helm_release.postgresql]
}

resource "kubernetes_service" "backstage" {
  metadata {
    name      = "backstage"
    namespace = kubernetes_namespace.backstage.metadata[0].name
    labels = {
      app = "backstage"
    }
  }

  spec {
    selector = {
      app = "backstage"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 7007
    }

    type = "ClusterIP"
  }
}

resource "terraform_data" "backstage_route_dns" {
  triggers_replace = [var.cluster_domain]

  depends_on = [kubernetes_deployment.backstage]

  provisioner "local-exec" {
    command = <<-EOT
      kubectl wait --for=condition=Established --timeout=180s crd/httproutes.gateway.networking.k8s.io
      kubectl wait --for=condition=Established --timeout=180s crd/dnsendpoints.externaldns.k8s.io
      cat <<'EOF' | kubectl apply -f -
      apiVersion: gateway.networking.k8s.io/v1
      kind: HTTPRoute
      metadata:
        name: backstage
        namespace: backstage
      spec:
        parentRefs:
          - name: envoy-gateway
            namespace: envoy-gateway-system
        hostnames:
          - backstage.${var.cluster_domain}
        rules:
          - backendRefs:
              - name: backstage
                port: 80
      ---
      apiVersion: externaldns.k8s.io/v1alpha1
      kind: DNSEndpoint
      metadata:
        name: backstage-public
        namespace: backstage
      spec:
        endpoints:
          - dnsName: backstage.${var.cluster_domain}
            recordTTL: 60
            recordType: CNAME
            targets:
              - envoy-gateway.envoy-gateway-system
      EOF
    EOT
  }
}
