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