variable "tenancy_id" {
  type = string
}

variable "user_id" {
  type = string
}

variable "api_fingerprint" {
  type = string
}

variable "api_private_key_path" {
  type = string
}

variable "region" {
  type = string
}

variable "home_region" {
  type    = string
  default = null
}

variable "compartment_id" {
  type = string
}

variable "availability_domain_number" {
  type        = number
  default     = null
  nullable    = true
  description = "Opcional: 1–3 para colocar bastion, operator e workers no mesmo domínio de disponibilidade. Usar quando aparecer 'Out of host capacity' no AD por defeito — tenta noutro número ou volta a aplicar mais tarde."

  validation {
    condition     = var.availability_domain_number == null || contains(range(1, 10), var.availability_domain_number)
    error_message = "availability_domain_number deve ser null ou um inteiro entre 1 e 9 (típico 1–3 em regiões com vários ADs)."
  }
}

variable "ssh_public_key_path" {
  type        = string
  description = "Caminho para o ficheiro da chave *pública* OpenSSH (.pub), ex. ~/.ssh/id_ed25519.pub — não uses chave privada PEM (-----BEGIN)."
  validation {
    condition = (
      fileexists(pathexpand(var.ssh_public_key_path)) &&
      !startswith(trimspace(file(pathexpand(var.ssh_public_key_path))), "-----BEGIN") &&
      can(regex(
        "^\\s*(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521|sk-ssh-ed25519|sk-ecdsa-sha2-nistp256)\\s",
        trimspace(file(pathexpand(var.ssh_public_key_path)))
      ))
    )
    error_message = "ssh_public_key_path deve ser um ficheiro .pub OpenSSH (uma linha começando por ssh-rsa, ssh-ed25519, ecdsa-sha2-*, etc.). Chaves PEM privadas (-----BEGIN ...) são inválidas para OKE."
  }
}
