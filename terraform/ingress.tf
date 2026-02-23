resource "kubernetes_ingress_v1" "devsu_demo" {
  metadata {
    name      = "devsu-demo-ingress"
    namespace = kubernetes_namespace.devsu_demo.metadata[0].name

    labels = {
      "app.kubernetes.io/name"       = "devsu-demo-nodejs"
      "app.kubernetes.io/managed-by" = "terraform"
    }

    annotations = {
      "nginx.ingress.kubernetes.io/proxy-body-size" = "1m"
    }
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = "devsu-demo.local"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.devsu_demo.metadata[0].name
              port {
                number = var.port
              }
            }
          }
        }
      }
    }

  }
}
