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