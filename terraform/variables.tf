variable "resource_group_name" {
  type = string
  default = "rg-stock_market-dev-westeu"
}

variable "location" {
  type = string
  default= "westeurope"
}

variable "app_port" {
  type = number
  default= 8080
}

variable "public_subnet" {
  description = "web public ip"
  type = string
  default = "10.0.1.0/24"
}

variable "database_private_ip" {
  description = "database private ip"
  type = string
  default = "10.0.2.4"
}

variable "admin_user" {
  description = "vm username"
  type = string
}

variable "admin_password" {
  description = "vm password"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.admin_password) > 8
    error_message = "password too short"
  }
}