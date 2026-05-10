variable "cluster_domain" {
  type = string
}

variable "admin_token" {
  type      = string
  sensitive = true
}

variable "allow_signups" {
  type    = bool
  default = false
}

variable "smtp_host" {
  type    = string
  default = ""
}

variable "smtp_port" {
  type    = string
  default = "587"

  validation {
    condition     = can(tonumber(var.smtp_port)) && tonumber(var.smtp_port) >= 1 && tonumber(var.smtp_port) <= 65535
    error_message = "smtp_port must be a number between 1 and 65535."
  }
}

variable "smtp_security" {
  type    = string
  default = "starttls"

  validation {
    condition     = contains(["starttls", "force_tls", "off"], var.smtp_security)
    error_message = "smtp_security must be starttls, force_tls, or off."
  }
}

variable "smtp_username" {
  type    = string
  default = ""

  validation {
    condition     = trimspace(var.smtp_username) == "" || length(trimspace(var.smtp_password)) > 0
    error_message = "smtp_password is required when smtp_username is set."
  }
}

variable "smtp_password" {
  type      = string
  sensitive = true
  default   = ""
}

variable "smtp_from" {
  type    = string
  default = ""

  validation {
    condition     = trimspace(var.smtp_host) == "" || length(trimspace(var.smtp_from)) > 0
    error_message = "smtp_from must be set when smtp_host is non-empty."
  }
}

variable "smtp_from_name" {
  type    = string
  default = "Vaultwarden"
}

variable "smtp_accept_invalid_certs" {
  type    = bool
  default = false
}
