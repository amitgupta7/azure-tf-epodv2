variable "az_subscription_id" {
  description = "azure subscription id"
  type        = string
}

variable "region" {
  default = "westus2"
}

variable "vm_size" {
  default = "Standard_B1s"
}


variable "os_disk_size_in_gb" {
  default = 1024
}


variable "os_publisher" {
  default = "Canonical"
}

variable "os_offer" {
  default = "ubuntu-24_04-lts"
}

variable "os_sku" {
  default = "server"
}

variable "os_version" {
  default = "latest"
}

variable "azpwd" {
  description = "common vm password, 16 characters containg --> [chars-alpha-num-special-char]"
  default = "1qaz!QAZ1qaz!QAZ"
}

variable "client_ip" {
    description = "Optional, add the client public IP address to whitelist ssh communication"
    default = "*"
    type = string
}


variable "azuser" {
  default = "azuser"
}


variable "az_resource_group" {
  description = "resource group name to create these resources"
}

variable "az_name_prefix" {
  description = "prefix to add to resource names"
  default     = "azure-tf-aks"
}

variable "node_vm_size" {
  default = "Standard_D4_v2"
}

variable "min_node_count" {
  default     = "2"
  description = "AKS min nodes"
}

variable "max_node_count" {
  default     = "4"
  description = "AKS max nodes"
}

variable "kubernetes_version" {
  default     = "1.33"
  description = "Kubernetes version"
}


variable "X_API_Secret" {
  type        = string
  description = "SAI API secret"
}
  
variable "X_API_Key" {
  type        = string
  description = "SAI API key"
}

variable "X_TIDENT" {
  type        = string
  description = "SAI Tenant ID"
}

variable "pod_owner" {
  type        = string
  description = "POD Owner Email, must be SAI tenant admin"
}
