variable "instance_size" {
  description = "The size and type of Azure instance. Min required for kubeflow and microk8s is 14GB. For GPU support select instance with GPU."
  default     = "Standard_D4s_v3"
}

variable "nodes_count" {
  description = "Number of Azure VMs spawned during deployment."
  default     = 1
}

variable "location" {
  description = "Azure Location for deployment"
  default     = "West Europe"
}

variable "resource_group_name" {
  description = "Name of resource group created for deployment"
  default     = "kubeflow-demo"
}

variable "ssh_key_path" {
  description = "The path to ssh public key. The private key from pair is used to access Azure VMs."
  default     = "~/.ssh/id_rsa.pub"
}

variable "vm_disk_size" {
  description = "Size of OS disk in Azure VMs"
  default     = 80
}

variable "vm_storage_account_type" {
  description = "Storage account type of OS disk in Azure VMs"
  default     = "Premium_LRS"
}

variable "vm_user" {
  description = "Admin user for Azure VMs"
  default     = "adminuser"
}