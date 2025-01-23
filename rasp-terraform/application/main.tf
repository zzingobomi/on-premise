terraform {  
  required_providers {
    argocd = {      
      source = "argoproj-labs/argocd"
      version = "7.2.0"
    }
  }
}

provider "argocd" {
  server_addr = "argocd.practice-zzingo.net:80"
  username    = "admin"
  password    = var.argocd_password
  insecure    = true
  plain_text  = true
}

################################################################################
# Hatongsu
################################################################################

resource "argocd_application" "hatongsu" {
  metadata {
    name = "hatongsu"
    namespace = "argocd"
    annotations = {
      "argocd-image-updater.argoproj.io/hatongsu-front.allow-tags"               = "regexp:^\\d{4}-\\d{2}-\\d{2}T\\d{2}-\\d{2}-\\d{2}$"
      "argocd-image-updater.argoproj.io/hatongsu-front.helm.image-name"          = "front.image.repository"
      "argocd-image-updater.argoproj.io/hatongsu-front.helm.image-tag"           = "front.image.tag"
      "argocd-image-updater.argoproj.io/hatongsu-front.update-strategy"          = "alphabetical"

      "argocd-image-updater.argoproj.io/hatongsu-album.allow-tags"               = "regexp:^\\d{4}-\\d{2}-\\d{2}T\\d{2}-\\d{2}-\\d{2}$"
      "argocd-image-updater.argoproj.io/hatongsu-album.helm.image-name"          = "album.image.repository"
      "argocd-image-updater.argoproj.io/hatongsu-album.helm.image-tag"           = "album.image.tag"
      "argocd-image-updater.argoproj.io/hatongsu-album.update-strategy"          = "alphabetical"

      "argocd-image-updater.argoproj.io/hatongsu-gateway.allow-tags"             = "regexp:^\\d{4}-\\d{2}-\\d{2}T\\d{2}-\\d{2}-\\d{2}$"
      "argocd-image-updater.argoproj.io/hatongsu-gateway.helm.image-name"        = "gateway.image.repository"
      "argocd-image-updater.argoproj.io/hatongsu-gateway.helm.image-tag"         = "gateway.image.tag"
      "argocd-image-updater.argoproj.io/hatongsu-gateway.update-strategy"        = "alphabetical"      

      "argocd-image-updater.argoproj.io/hatongsu-user.allow-tags"                = "regexp:^\\d{4}-\\d{2}-\\d{2}T\\d{2}-\\d{2}-\\d{2}$"
      "argocd-image-updater.argoproj.io/hatongsu-user.helm.image-name"           = "user.image.repository"
      "argocd-image-updater.argoproj.io/hatongsu-user.helm.image-tag"            = "user.image.tag"
      "argocd-image-updater.argoproj.io/hatongsu-user.update-strategy"           = "alphabetical"

      "argocd-image-updater.argoproj.io/image-list"                              = "hatongsu-front=zzingo5/hatongsu-front,hatongsu-album=zzingo5/hatongsu-album,hatongsu-gateway=zzingo5/hatongsu-gateway,hatongsu-user=zzingo5/hatongsu-user"      
    }
  }

  spec {
    project = "default"

    source {
      repo_url         = "https://github.com/zzingobomi/on-premise"
      target_revision  = "main"
      path             = "hatongsu"

      helm {
        parameter {
          name  = "front.image.tag"
          value = var.hatongsu_values["front"].image_tag
        }

        parameter {
          name  = "front.auth_secret"
          value = var.hatongsu_values["front"].auth_secret
        }

        parameter {
          name  = "front.google_client_id"
          value = var.hatongsu_values["front"].google_client_id
        }

        parameter {
          name  = "front.google_client_secret"
          value = var.hatongsu_values["front"].google_client_secret
        }

        parameter {
          name  = "album.image.tag"
          value = var.hatongsu_values["album"].image_tag
        }

        parameter {
          name  = "album.db_url"
          value = var.hatongsu_values["album"].db_url
        }

        parameter {
          name  = "album.rabbitmq_url"
          value = var.hatongsu_values["album"].rabbitmq_url
        }

        parameter {
          name  = "album.minio_endpoint"
          value = var.hatongsu_values["album"].minio_endpoint
        }        

        parameter {
          name  = "album.minio_access_key"
          value = var.hatongsu_values["album"].minio_access_key
        }

        parameter {
          name  = "album.minio_secret_key"
          value = var.hatongsu_values["album"].minio_secret_key
        }

        parameter {
          name  = "album.minio_bucket_name"
          value = var.hatongsu_values["album"].minio_bucket_name
        }

        parameter {
          name  = "gateway.image.tag"
          value = var.hatongsu_values["gateway"].image_tag
        }

        parameter {
          name  = "gateway.album_rabbitmq_url"
          value = var.hatongsu_values["gateway"].album_rabbitmq_url
        }

        parameter {
          name  = "user.image.tag"
          value = var.hatongsu_values["user"].image_tag
        }

        parameter {
          name  = "user.db_url"
          value = var.hatongsu_values["user"].db_url
        }

        parameter {
          name  = "user.access_token_secret"
          value = var.hatongsu_values["user"].access_token_secret
        }

        parameter {
          name  = "user.refresh_token_secret"
          value = var.hatongsu_values["user"].refresh_token_secret
        }

        parameter {
          name  = "user.token_expire_time"
          value = var.hatongsu_values["user"].token_expire_time
        }

        parameter {
          name  = "user.google_client_id"
          value = var.hatongsu_values["user"].google_client_id
        }

        parameter {
          name  = "user.google_client_secret"
          value = var.hatongsu_values["user"].google_client_secret
        }
      }      
    }

    destination {
      server      = "https://kubernetes.default.svc"
      namespace   = "hatongsu"
    }

    sync_policy {
      automated {
        prune       = true
        self_heal   = true
        allow_empty = false
      }      
      sync_options = ["CreateNamespace=true"]
    }
  }
}



################################################################################
# Delivery
################################################################################

# resource "argocd_application" "delivery" {
#   metadata {
#     name = "delivery"
#     namespace = "argocd"
#     annotations = {
#       "argocd-image-updater.argoproj.io/fc-nestjs-gateway.allow-tags"             = "regexp:^\\d{4}-\\d{2}-\\d{2}T\\d{2}-\\d{2}-\\d{2}$"
#       "argocd-image-updater.argoproj.io/fc-nestjs-gateway.helm.image-name"        = "gateway.image.repository"
#       "argocd-image-updater.argoproj.io/fc-nestjs-gateway.helm.image-tag"         = "gateway.image.tag"
#       "argocd-image-updater.argoproj.io/fc-nestjs-gateway.update-strategy"        = "alphabetical"

#       "argocd-image-updater.argoproj.io/fc-nestjs-notification.allow-tags"        = "regexp:^\\d{4}-\\d{2}-\\d{2}T\\d{2}-\\d{2}-\\d{2}$"
#       "argocd-image-updater.argoproj.io/fc-nestjs-notification.helm.image-name"   = "notification.image.repository"
#       "argocd-image-updater.argoproj.io/fc-nestjs-notification.helm.image-tag"    = "notification.image.tag"
#       "argocd-image-updater.argoproj.io/fc-nestjs-notification.update-strategy"   = "alphabetical"

#       "argocd-image-updater.argoproj.io/fc-nestjs-order.allow-tags"               = "regexp:^\\d{4}-\\d{2}-\\d{2}T\\d{2}-\\d{2}-\\d{2}$"
#       "argocd-image-updater.argoproj.io/fc-nestjs-order.helm.image-name"          = "order.image.repository"
#       "argocd-image-updater.argoproj.io/fc-nestjs-order.helm.image-tag"           = "order.image.tag"
#       "argocd-image-updater.argoproj.io/fc-nestjs-order.update-strategy"          = "alphabetical"

#       "argocd-image-updater.argoproj.io/fc-nestjs-payment.allow-tags"             = "regexp:^\\d{4}-\\d{2}-\\d{2}T\\d{2}-\\d{2}-\\d{2}$"
#       "argocd-image-updater.argoproj.io/fc-nestjs-payment.helm.image-name"        = "payment.image.repository"
#       "argocd-image-updater.argoproj.io/fc-nestjs-payment.helm.image-tag"         = "payment.image.tag"
#       "argocd-image-updater.argoproj.io/fc-nestjs-payment.update-strategy"        = "alphabetical"

#       "argocd-image-updater.argoproj.io/fc-nestjs-product.allow-tags"             = "regexp:^\\d{4}-\\d{2}-\\d{2}T\\d{2}-\\d{2}-\\d{2}$"
#       "argocd-image-updater.argoproj.io/fc-nestjs-product.helm.image-name"        = "product.image.repository"
#       "argocd-image-updater.argoproj.io/fc-nestjs-product.helm.image-tag"         = "product.image.tag"
#       "argocd-image-updater.argoproj.io/fc-nestjs-product.update-strategy"        = "alphabetical"

#       "argocd-image-updater.argoproj.io/fc-nestjs-user.allow-tags"                = "regexp:^\\d{4}-\\d{2}-\\d{2}T\\d{2}-\\d{2}-\\d{2}$"
#       "argocd-image-updater.argoproj.io/fc-nestjs-user.helm.image-name"           = "user.image.repository"
#       "argocd-image-updater.argoproj.io/fc-nestjs-user.helm.image-tag"            = "user.image.tag"
#       "argocd-image-updater.argoproj.io/fc-nestjs-user.update-strategy"           = "alphabetical"

#       "argocd-image-updater.argoproj.io/image-list"                               = "fc-nestjs-gateway=zzingo5/fc-nestjs-gateway,fc-nestjs-notification=zzingo5/fc-nestjs-notification,fc-nestjs-order=zzingo5/fc-nestjs-order,fc-nestjs-payment=zzingo5/fc-nestjs-payment,fc-nestjs-product=zzingo5/fc-nestjs-product,fc-nestjs-user=zzingo5/fc-nestjs-user"      
#     }
#   }

#   spec {
#     project = "default"

#     source {
#       repo_url         = "https://github.com/zzingobomi/on-premise"
#       target_revision  = "main"
#       path             = "delivery"

#       helm {
#         parameter {
#           name  = "gateway.image.tag"
#           value = var.delivery_values["gateway"].image_tag
#         }

#         parameter {
#           name  = "notification.image.tag"
#           value = var.delivery_values["notification"].image_tag
#         }

#         parameter {
#           name  = "notification.db_url"
#           value = var.delivery_values["notification"].db_url
#         }

#         parameter {
#           name  = "order.image.tag"
#           value = var.delivery_values["order"].image_tag
#         }

#         parameter {
#           name  = "order.db_url"
#           value = var.delivery_values["order"].db_url
#         }

#         parameter {
#           name  = "payment.image.tag"
#           value = var.delivery_values["payment"].image_tag
#         }

#         parameter {
#           name  = "payment.db_url"
#           value = var.delivery_values["payment"].db_url
#         }

#         parameter {
#           name  = "product.image.tag"
#           value = var.delivery_values["product"].image_tag
#         }

#         parameter {
#           name  = "product.db_url"
#           value = var.delivery_values["product"].db_url
#         }

#         parameter {
#           name  = "user.image.tag"
#           value = var.delivery_values["user"].image_tag
#         }

#         parameter {
#           name  = "user.db_url"
#           value = var.delivery_values["user"].db_url
#         }
#       }      
#     }

#     destination {
#       server      = "https://kubernetes.default.svc"
#       namespace   = "delivery"
#     }

#     sync_policy {
#       automated {
#         prune       = true
#         self_heal   = true
#         allow_empty = false
#       }      
#       sync_options = ["CreateNamespace=true"]
#     }
#   }
# }