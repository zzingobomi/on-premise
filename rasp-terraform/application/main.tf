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
# Delivery
################################################################################

resource "argocd_application" "delivery" {
  metadata {
    name = "delivery"
    namespace = "argocd"
    annotations = {
      "argocd-image-updater.argoproj.io/fc-nestjs-gateway.allow-tags"             = "regexp:^\\d{4}-\\d{2}-\\d{2}T\\d{2}-\\d{2}-\\d{2}$"
      "argocd-image-updater.argoproj.io/fc-nestjs-gateway.helm.image-name"        = "gateway.image.repository"
      "argocd-image-updater.argoproj.io/fc-nestjs-gateway.helm.image-tag"         = "gateway.image.tag"
      "argocd-image-updater.argoproj.io/fc-nestjs-gateway.update-strategy"        = "alphabetical"

      "argocd-image-updater.argoproj.io/fc-nestjs-notification.allow-tags"        = "regexp:^\\d{4}-\\d{2}-\\d{2}T\\d{2}-\\d{2}-\\d{2}$"
      "argocd-image-updater.argoproj.io/fc-nestjs-notification.helm.image-name"   = "notification.image.repository"
      "argocd-image-updater.argoproj.io/fc-nestjs-notification.helm.image-tag"    = "notification.image.tag"
      "argocd-image-updater.argoproj.io/fc-nestjs-notification.update-strategy"   = "alphabetical"

      "argocd-image-updater.argoproj.io/fc-nestjs-order.allow-tags"               = "regexp:^\\d{4}-\\d{2}-\\d{2}T\\d{2}-\\d{2}-\\d{2}$"
      "argocd-image-updater.argoproj.io/fc-nestjs-order.helm.image-name"          = "order.image.repository"
      "argocd-image-updater.argoproj.io/fc-nestjs-order.helm.image-tag"           = "order.image.tag"
      "argocd-image-updater.argoproj.io/fc-nestjs-order.update-strategy"          = "alphabetical"

      "argocd-image-updater.argoproj.io/fc-nestjs-payment.allow-tags"             = "regexp:^\\d{4}-\\d{2}-\\d{2}T\\d{2}-\\d{2}-\\d{2}$"
      "argocd-image-updater.argoproj.io/fc-nestjs-payment.helm.image-name"        = "payment.image.repository"
      "argocd-image-updater.argoproj.io/fc-nestjs-payment.helm.image-tag"         = "payment.image.tag"
      "argocd-image-updater.argoproj.io/fc-nestjs-payment.update-strategy"        = "alphabetical"

      "argocd-image-updater.argoproj.io/fc-nestjs-product.allow-tags"             = "regexp:^\\d{4}-\\d{2}-\\d{2}T\\d{2}-\\d{2}-\\d{2}$"
      "argocd-image-updater.argoproj.io/fc-nestjs-product.helm.image-name"        = "product.image.repository"
      "argocd-image-updater.argoproj.io/fc-nestjs-product.helm.image-tag"         = "product.image.tag"
      "argocd-image-updater.argoproj.io/fc-nestjs-product.update-strategy"        = "alphabetical"

      "argocd-image-updater.argoproj.io/fc-nestjs-user.allow-tags"                = "regexp:^\\d{4}-\\d{2}-\\d{2}T\\d{2}-\\d{2}-\\d{2}$"
      "argocd-image-updater.argoproj.io/fc-nestjs-user.helm.image-name"           = "user.image.repository"
      "argocd-image-updater.argoproj.io/fc-nestjs-user.helm.image-tag"            = "user.image.tag"
      "argocd-image-updater.argoproj.io/fc-nestjs-user.update-strategy"           = "alphabetical"

      "argocd-image-updater.argoproj.io/image-list"                               = "fc-nestjs-gateway=zzingo5/fc-nestjs-gateway,fc-nestjs-notification=zzingo5/fc-nestjs-notification,fc-nestjs-order=zzingo5/fc-nestjs-order,fc-nestjs-payment=zzingo5/fc-nestjs-payment,fc-nestjs-product=zzingo5/fc-nestjs-product,fc-nestjs-user=zzingo5/fc-nestjs-user"      
    }
  }

  spec {
    project = "default"

    source {
      repo_url         = "https://github.com/zzingobomi/on-premise"
      target_revision  = "main"
      path             = "delivery"

      helm {
        parameter {
          name  = "gateway.image.tag"
          value = var.delivery_values["gateway"].image_tag
        }

        parameter {
          name  = "notification.image.tag"
          value = var.delivery_values["notification"].image_tag
        }

        parameter {
          name  = "notification.db_url"
          value = var.delivery_values["notification"].db_url
        }

        parameter {
          name  = "order.image.tag"
          value = var.delivery_values["order"].image_tag
        }

        parameter {
          name  = "order.db_url"
          value = var.delivery_values["order"].db_url
        }

        parameter {
          name  = "payment.image.tag"
          value = var.delivery_values["payment"].image_tag
        }

        parameter {
          name  = "payment.db_url"
          value = var.delivery_values["payment"].db_url
        }

        parameter {
          name  = "product.image.tag"
          value = var.delivery_values["product"].image_tag
        }

        parameter {
          name  = "product.db_url"
          value = var.delivery_values["product"].db_url
        }

        parameter {
          name  = "user.image.tag"
          value = var.delivery_values["user"].image_tag
        }

        parameter {
          name  = "user.db_url"
          value = var.delivery_values["user"].db_url
        }
      }      
    }

    destination {
      server      = "https://kubernetes.default.svc"
      namespace   = "delivery"
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