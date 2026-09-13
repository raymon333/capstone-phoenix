variable "resource_group_name" {
  type    = string
  default = "rg-phoenix-capstone"
}

variable "location" {
  type    = string
  default = "uaenorth"
}

variable "vm_size" {
  type    = string
  default = "Standard_B2als_v2"
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}

variable "admin_ip" {
  description = "Your current public IP in CIDR form, e.g. 203.0.113.4/32 — used to lock down SSH."
  type        = string
}

variable "worker_count" {
  description = "Number of k3s agent (worker) nodes"
  type        = number
  default     = 2

  validation {
    condition     = var.worker_count >= 2
    error_message = "Spec requires at least 3 nodes total (1 control-plane + 2+ workers). worker_count must be >= 2."
  }
}