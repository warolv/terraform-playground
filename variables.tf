variable "access_key" {}

variable "secret_key" {}

variable "vpc_id" {}

variable "subnet1" {}

variable "subnet2" {}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

variable "alb_port" {
  description = "The port the aLB will use for HTTP requests"
  type        = number
  default     = 80
}