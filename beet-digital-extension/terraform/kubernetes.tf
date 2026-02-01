resource "kubernetes_ingress_v1" "beet_app_ingress" {
  metadata {
    name      = "beet-app-ingress"
    namespace = "default"
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
      "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
    }
    labels = {
      "app" = "beet-app"
    }
  }

  spec {
    ingress_class_name = "nginx"

    # TLS Configuration
    tls {
      hosts      = ["wapps.beet.digital"]
      secret_name = "wapps-beet-digital-tls"
    }

    tls {
      hosts      = ["app.beet.digital"]
      secret_name = "beet-frontend-tls"
    }

    # Rule for WhatsApp Flows App
    rule {
      host = "wapps.beet.digital"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.beet_wf_app.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    # Rule for Frontend (Beet App)
    rule {
      host = "app.beet.digital"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.beet_frontend.metadata[0].name
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