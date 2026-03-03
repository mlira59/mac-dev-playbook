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

variable "ipsw_checksum" {
  type        = string
  default     = "none"
  description = "Checksum for the IPSW file (e.g., 'sha256:...'). Use 'none' to skip verification."
}

// macOS Sequoia TCC workaround: Go binaries are blocked from local network
// access by the Local Network privacy restriction. We use Parallels NAT port
// forwarding through localhost to bypass this.
variable "vm_static_ip" {
  type        = string
  default     = "10.211.55.100"
  description = "Static IP assigned to VM during build for NAT forwarding"
}

variable "ssh_forward_port" {
  type        = number
  default     = 22222
  description = "Host port forwarded to VM SSH via Parallels NAT"
}

// Locals
locals {
  machine_name = "macos-test-${var.macos_version}"
  ssh_username = var.vm_user.username
  ssh_password = var.vm_user.password
  output_dir   = "${var.output_directory}/${local.machine_name}"
}
