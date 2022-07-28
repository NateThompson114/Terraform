# Azure Terraform
## Azure CLI
- `az login` : *To login to your az account*
- `az account list-locations -o table` : ***-o** for output, **table** outputs as a table*
- `az vm image list -o table` : *Available vm images*
- `az vm image list-publishers -l eastus -o table` : *List of publishers*
- `az vm image list-offers -l eastus -p MicrosoftWindowsServer -o table` : *The offerings of a specific publisher using the **-p***
- `az vm list-sizes -l eastus -o table` : *List of machine hardware sizes*

## Terraform CLI
- `terraform init`  : Initialized terraform
- `terraform plan`  : Builds a plan
- `terraform apply` : Applies the plan

## Variables
- A variables.tf is where the variable name and types are declared
- terraform.tfvars is where you define the variables declared
- main.tf is where the variables are consumed

## Dependencies
***Resource Group***
```
resource "azurerm_resource_group" "web_server_rg" {
    location = "westus2"
    name     = "web-rg"
}
```

*No Dependcy*
```
resource "azurerm_virtual_network" "web_server_vnet" {
    name                = "web-server-vnet"
    resource_group_name = "web-rg"
}
```

*Implicit dependancy*
```
resource "azurerm_virtual_network" "web_server_vnet" {
    name                = "web-server-vnet"
    resource_group_name = azurerm_resource_group.web_server_rg.name
}
```

*Explicit dependancy*
```
resource "azurerm_virtual_network" "web_server_vnet" {
    name                = "web-server-vnet"
    resource_group_name = "web-rg"
    depends_on          = [azurerm_resource_group.web_server_rg]
}
```

## To Remote State
***This allows more than one person to work on it, also moves sensitive data to azure***

# Azure Additional info
## Azure Network Interface
- Connects to Subnets/VNET
- Has Private and Public IP options
  - Can be Static or Dynamic
- All network settings must be setup by Azure
- Can setup DNS Settings
- NSG (Network Security Group : IE port 443 is allowed of not)/ASG (Application Security Group) Security groups

## Azure VM
- Needs Defined
  - Hardware Model
  - Image
    - Packer Makes custom Images
  - Network Interface
  - Disk