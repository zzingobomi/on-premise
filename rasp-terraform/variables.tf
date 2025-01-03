variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  sensitive   = true
}

variable "argocd_password" {
  description = "ArgoCD Password"
  type        = string  
}

variable "delivery_values" {
  type = map(object({
    image_tag = string
    db_url    = string
  }))
}