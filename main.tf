#### COMMAND LIST (In Order of use, generally)
### terraform <command>
## init -Prepare your working directory for other commands
## validate -Check whether the configuration is valid
## plan -Show changes required by the current configuration (review your plan and make sure its what you want it to do)
## apply -Create or update infrastructure
## destroy -Destroy previously-created infrastructure (not used generally, but destroys what you created)

## Can setup multiple providers, and give alias to them
# provider "azurerm" {
#   features {}
#   alias = "sub2"
# }

## Sub Id from specific Subscription below
provider "azurerm" {  
  # subscription_id = "12345678-0000-1234-5678-000000000000"
  features {}
}

## When you login, this will be in your console
# {
#   "cloudName": "AzureCloud",
#   "homeTenantId": "00000000-1234-5678-0000-000000000000",
#   "id": "12345678-0000-1234-5678-000000000000", <-- THIS IS WHAT YOU NEED FOR THE ABOVE VALUE
#   "isDefault": true,
#   "managedByTenants": [],
#   "name": "Visual Studio Professional Subscription",
#   "state": "Enabled",
#   "tenantId": "00000000-1234-5678-0000-000000000000",
#   "user": {
#     "name": "user@test.com",
#     "type": "user"
#   }
# }

locals {
  ##! This is a foreach in a foreach that can use the index to create x groups per a group of items in the list
  event_hub_namespaces_environments = { 
    for pair in setproduct(var.web_server, var.environment): "${pair[0]}.${pair[1]}" => {
      index = index(var.web_server, pair[0])
      env = pair[1]
    }
  }

  list = {
    "item" = "value"
  }
}

## resource <name of resource(actual azure resource)> <name(must be unique)>
## name -Actual name
## location -Where in the region
## by using the count, we create a array, that we can then cycle through the options
resource "azurerm_resource_group" "web_server_rg" {
  count         = length(var.web_server)
  # name          = var.web_server[count.index].name
  name          = "${var.companyPrefix}-${var.web_server[count.index].prefix}-web-rg"
  location      = var.web_server[count.index].location
}

resource "azurerm_virtual_network" "web_server_vnet" {
  count = length(var.web_server)
  name = "${var.companyPrefix}-${var.web_server[count.index].prefix}-${var.resource_prefix}-vnet"
  location = var.web_server[count.index].location
  resource_group_name = azurerm_resource_group.web_server_rg[count.index].name
  address_space = [var.web_server_address_space]
}

resource "azurerm_subnet" "web_server_subnet" {
  count = length(var.web_server)
  name = "${var.companyPrefix}-${var.web_server[count.index].prefix}-${var.resource_prefix}-subnet"
  resource_group_name = azurerm_resource_group.web_server_rg[count.index].name
  virtual_network_name = azurerm_virtual_network.web_server_vnet[count.index].name
  address_prefixes = [var.web_server_address_prefix]
}

resource "azurerm_network_interface" "web_server_nic" {
  count = length(var.web_server)
  name = "${var.companyPrefix}-${var.web_server[count.index].prefix}-${var.web_server_name}-nic"
  location      = var.web_server[count.index].location
  resource_group_name = azurerm_resource_group.web_server_rg[count.index].name

  ip_configuration {
    name = "${var.companyPrefix}-${var.web_server[count.index].prefix}-${var.web_server_name}-ip"
    subnet_id = azurerm_subnet.web_server_subnet[count.index].id
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_public_ip" "web_server_public_ip" {
  count = length(var.web_server)
  name = "${var.companyPrefix}-${var.web_server[count.index].prefix}-${var.resource_prefix}-public-ip"
  location = var.web_server[count.index].location
  resource_group_name = azurerm_resource_group.web_server_rg[count.index].name
  allocation_method = var.environment[count.index] == "production" ? "Static" : "Dynamic"
}

resource "azurerm_network_security_group" "web_server_nsg" {
  count = length(var.web_server)
  name = "${var.companyPrefix}-${var.web_server[count.index].prefix}-${var.resource_prefix}-nsg"
  location = var.web_server[count.index].location
  resource_group_name = azurerm_resource_group.web_server_rg[count.index].name
}

resource "azurerm_network_security_rule" "web_server_nsg_rule_rdp" {
  count = length(var.web_server)
  name = "RDP Inboud"
  priority = 100
  direction = "Inbound"
  access = "Allow"
  protocol = "Tcp"
  source_port_range = "*"
  destination_port_range = "3389"
  source_address_prefix = "*"
  destination_address_prefix = "*"
  resource_group_name = azurerm_resource_group.web_server_rg[count.index].name
  network_security_group_name = azurerm_network_security_group.web_server_nsg[count.index].name
}

resource "azurerm_network_interface_security_group_association" "web_server_nsg_association" {
  count = length(var.web_server)
  network_interface_id = azurerm_network_interface.web_server_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.web_server_nsg[count.index].id
}

resource "azurerm_eventhub_namespace" "eventhub_namespace" {
  count               = length(var.web_server)
  name                = "${var.companyPrefix}-${var.web_server[count.index].prefix}-${var.resource_prefix}-Hub"
  resource_group_name = (azurerm_resource_group.web_server_rg[count.index]).name
  location            = (azurerm_resource_group.web_server_rg[count.index]).location
  sku                 = "Standard"
  capacity            = 1
  tags                = module.azure_resourcename[count.index].common_tags
}

resource "azurerm_eventhub" "eventhub" {
  for_each = local.event_hub_namespaces_environments
  
  name                = each.value.env
  namespace_name      = azurerm_eventhub_namespace.eventhub_namespace[each.value.index].name
  resource_group_name = azurerm_eventhub_namespace.eventhub_namespace[each.value.index].resource_group_name
  partition_count     = 2
  message_retention   = 1
}