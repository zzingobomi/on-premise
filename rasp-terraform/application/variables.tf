variable "argocd_password" {
  description = "ArgoCD Password"
  type        = string  
}

variable "hatongsu_values" {
  type = object({
    front = object({
      image_tag            = string
      auth_secret          = string
      google_client_id     = string
      google_client_secret = string
    })
    album = object({
      image_tag         = string
      db_url            = string
      rabbitmq_url      = string
      minio_endpoint    = string      
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