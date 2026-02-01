resource "kubernetes_ingress_v1" "beet_app_ingress" {
  metadata {
    name      = "beetdigital-ingress"
    namespace = "beetdigital"
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
      "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
    }
    labels = {
      "app" = "beetdigital"
    }
  }

  spec {
    ingress_class_name = "nginx"

    # TLS Configuration
    tls {
      hosts      = ["platform.beet.digital"]
      secret_name = "platform-beet-digital-tls"
    }



    # Rule for Frontend (Beet App)
    rule {
      host = "platform.beet.digital"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.platform.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}