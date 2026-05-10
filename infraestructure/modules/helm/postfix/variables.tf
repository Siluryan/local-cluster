variable "allowed_sender_domains" {
  type = string
}

variable "smtpd_sasl_users" {
  type      = string
  sensitive = true
}

variable "relayhost" {
  type    = string
  default = ""
}

variable "relayhost_username" {
  type    = string
  default = ""
}

variable "relayhost_password" {
  type      = string
  sensitive = true
  default   = ""

  validation {
    condition     = trimspace(var.relayhost) == "" || trimspace(var.relayhost_username) == "" || length(trimspace(var.relayhost_password)) > 0
    error_message = "relayhost_password is required when relayhost and relayhost_username are set."
  }
}

variable "postfix_image" {
  type    = string
  default = "boky/postfix:v5.0.0"
}
