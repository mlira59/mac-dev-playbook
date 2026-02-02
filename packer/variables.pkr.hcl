// Variables for macOS test VM

variable "macos_version" {
  type        = string
  default     = "sequoia"
  description = "macOS version to build: sonoma, sequoia"
}

variable "vm_user" {
  type = object({
    username = string
    password = string
  })
  default = {
    username = "testuser"
    password = "testpass"
  }
  sensitive   = true
  description = "VM user credentials"
}

variable "vm_specs" {
  type = object({
    cpus   = number
    memory = number
  })
  default = {
    cpus   = 4
    memory = 8192
  }
  description = "VM resource allocation"
}

variable "output_directory" {
  type    = string
  default = "output"
}

variable "ipsw_url" {
  type        = string
  default     = ""
  description = "URL to macOS IPSW file (leave empty to use local recovery)"
}

// Locals
locals {
  machine_name = "macos-test-${var.macos_version}"
  ssh_username = var.vm_user.username
  ssh_password = var.vm_user.password
  output_dir   = "${var.output_directory}/${local.machine_name}"
}
