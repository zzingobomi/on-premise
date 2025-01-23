variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  sensitive   = true
}

variable "argocd_password" {
  description = "ArgoCD Password"
  type        = string  
}


variable "hatongsu_values" {
  type = object({
    album = object({
      image_tag         = string
      db_url            = string
      rabbitmq_url      = string
      minio_endpoint    = string
      minio_port        = number
      minio_access_key  = string
      minio_secret_key  = string
      minio_bucket_name = string
    })
    gateway = object({
      image_tag           = string
      album_rabbitmq_url = string
    })
    user = object({
      image_tag           = string
      db_url              = string
      access_token_secret = string
      refresh_token_secret = string
      token_expire_time   = string
      google_client_id    = string
      google_client_secret = string
    })
  })
}


# variable "delivery_values" {
#   type = map(object({
#     image_tag = string
#     db_url    = string
#   }))
# }