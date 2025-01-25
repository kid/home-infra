# resource "random_password" "flux_webhook_token" {
#   length  = 32
#   special = true
# }
#
# resource "kubernetes_secret" "flux_webhook_token" {
#   metadata {
#     name      = "webhook-token"
#     namespace = kubernetes_namespace.flux_system[0].metadata[0].name
#   }
#
#   data = {
#     token = random_password.flux_webhook_token.result
#   }
# }

