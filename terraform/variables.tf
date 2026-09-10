variable "location" {
  type    = string
  default = "westeurope"
}

variable "resource_group_name" {
  type    = string
  default = "rg-secure-hubspoke-tf"
}

variable "tags" {
  type = map(string)
  default = {
    Project     = "Secure-Hub-Spoke"
    Environment = "Lab"
    Owner       = "Sven Velleman"
    CostCenter  = "IT-Training"
    ManagedBy   = "Terraform"
  }
}
