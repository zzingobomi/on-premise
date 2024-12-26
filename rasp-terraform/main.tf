provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "rasp-cluster"
}

provider "helm" {
  
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  chart            = "${path.module}/local-charts/ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
}

resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  chart            = "${path.module}/local-charts/kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true

  values = [
    file("${path.module}/local-charts/kube-prometheus-stack/values-dev.yaml")
  ]
  
  set_sensitive {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }
}

resource "helm_release" "loki_stack" {
  name             = "loki-stack"
  chart            = "${path.module}/local-charts/loki-stack"
  namespace        = "monitoring"
  create_namespace = true

  set {
    name  = "loki.image.tag"
    value = "2.9.3"
  }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  chart            = "${path.module}/local-charts/argo-cd"
  namespace        = "argocd"
  create_namespace = true

  values = [
    file("${path.module}/local-charts/argo-cd/values-dev.yaml")
  ]
}

resource "helm_release" "argocd_image_updater" {
  name             = "argocd-image-updater"
  chart            = "${path.module}/local-charts/argocd-image-updater"
  namespace        = "argocd"
  create_namespace = true

  values = [
    file("${path.module}/local-charts/argocd-image-updater/values-dev.yaml")
  ]
}

resource "helm_release" "argo_rollouts" {
  name             = "argo-rollouts"
  chart            = "${path.module}/local-charts/argo-rollouts"
  namespace        = "argocd"
  create_namespace = true
}

module "application" {
  source = "./application"

  argocd_password = var.argocd_password
  delivery_values = var.delivery_values  
}