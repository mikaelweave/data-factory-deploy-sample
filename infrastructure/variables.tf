# Shared
variable "location" {
  type    = string
}

variable "environment" {
  type    = string
}

variable "base_name" {
  type    = string
}

# Data Factory 
variable "adf_link_github" {
  type    = bool
}

variable "adf_account_name" {
  type    = string
  default = "mikaelweave"
}

variable "adf_repository_name" {
  type    = string
  default = "data-factory-deploy-sample"
}

variable "adf_branch_name" {
  type    = string
  default = "master"
}

# Key Vault
variable "keyvault_admin_object_ids" {
  type    = list(string)
  default = []
}

variable "keyvault_reader_object_ids" {
  type    = list(string)
  default = []
}