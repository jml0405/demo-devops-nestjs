resource "kubernetes_deployment" "devsu_demo" {
  metadata {
    name      = "devsu-demo-deployment"
    namespace = kubernetes_namespace.devsu_demo.metadata[0].name

    labels = {
      "app.kubernetes.io/name"       = "devsu-demo-nodejs"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = "devsu-demo-nodejs"
      }
    }

    template {
      metadata {
        labels = {
          app = "devsu-demo-nodejs"
        }
      }

      spec {
        # Run as non-root (matches Dockerfile USER node, uid=1000)
        security_context {
          run_as_non_root = true
          run_as_user     = 1000
          fs_group        = 1000
        }

        container {
          name              = "devsu-demo-nodejs"
          image             = "${var.image_name}:${var.image_tag}"
          image_pull_policy = "IfNotPresent"

          port {
            name           = "http"
            container_port = var.port
          }

          # Inject non-sensitive config from ConfigMap
          env_from {
            config_map_ref {
              name = kubernetes_config_map.devsu_demo.metadata[0].name
            }
          }

          # Inject credentials from Secret
          env_from {
            secret_ref {
              name = kubernetes_secret.devsu_demo.metadata[0].name
            }
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }
          }

          # Liveness probe – restart container if it stops responding
          liveness_probe {
            http_get {
              path = "/api/users"
              port = var.port
            }
            initial_delay_seconds = 15
            period_seconds        = 20
            failure_threshold     = 3
          }

          # Readiness probe – only send traffic once the app is up
          readiness_probe {
            http_get {
              path = "/api/users"
              port = var.port
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            failure_threshold     = 3
          }

        }
      }
    }
  }

  # Wait for rollout to complete before Terraform considers apply done
  wait_for_rollout = true

  timeouts {
    create = "3m"
    update = "3m"
  }
}
