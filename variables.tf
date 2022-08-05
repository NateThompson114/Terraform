# variable "web_server_location" {
#   type = list(string)
# }

# variable "web_server_rg" {
#   type = list(string)
# }

variable "web_server" {
  type = list(any)
  default = [
    {
      "ResourceGroup" : "East Us",
      "location" : "eastus",
      "prefix" : "ae1"
    },
    {
      "ResourceGroup" : "West Us",
      "location" : "westus",      
      "prefix":"aw1"
    }    
   ]   
}

#! nt stands for Nate Thompson, but it is your company identifier
variable "companyPrefix" {
  type = string
  default = "nt"
}

variable "resource_prefix" {
  type = string
}

variable "web_server_address_space" {
  type = string
}

variable "web_server_address_prefix" {
  type = string
}

variable "web_server_name" {
  type = string  
}

variable "environment" {
  type = string
}