#Azure Generic vNet Module
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = length(var.address_spaces) == 0 ? [var.address_space] : var.address_spaces
  dns_servers         = var.dns_servers
  tags                = var.tags
}

locals {
  subnet_delegation = {for key, value in var.subnet_delegation :
     key => {
      name = value.name
      service_delegation = [{
        name    = value.service
        actions = value.actions
      }]
      }
    }
}

resource "azurerm_subnet" "subnet" {
  count                                          = length(var.subnet_names)
  name                                           = var.subnet_names[count.index]
  resource_group_name                            = var.resource_group_name
  address_prefixes                               = [var.subnet_prefixes[count.index]]
  virtual_network_name                           = azurerm_virtual_network.vnet.name
  enforce_private_link_endpoint_network_policies = lookup(var.subnet_enforce_private_link_endpoint_network_policies, var.subnet_names[count.index], false)
  service_endpoints                              = lookup(var.subnet_service_endpoints, var.subnet_names[count.index], [])

  dynamic "delegation"{
    for_each = contains(keys(local.subnet_delegation),var.subnet_names[count.index] ) ? {"${var.subnet_names[count.index]}": lookup(local.subnet_delegation, var.subnet_names[count.index], [])} : {}
    content {
      name = delegation.value["name"]
      dynamic "service_delegation" {
        for_each = delegation.value["service_delegation"]
        content{
          name = service_delegation.value.name
          actions = service_delegation.value.actions
        }
      }
    }
  }
}
