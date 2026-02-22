resource "kubernetes_secret" "devsu_demo" {
  metadata {
    name      = "devsu-demo-secret"
    namespace = kubernetes_namespace.devsu_demo.metadata[0].name

    labels = {
      "app.kubernetes.io/name"       = "devsu-demo-nodejs"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  type = "Opaque"

  # The provider accepts plain text and handles base64 encoding for Secret data.
  data = {
    DATABASE_USER     = var.database_user
    DATABASE_PASSWORD = var.database_password
  }
}
