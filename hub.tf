provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "VWAN_HUB_DEMO_TF"
  location = "West Europe"
}

resource "azurerm_virtual_network" "spoke1" {
  name                = "VNET_SPOKE1"
  address_space       = ["10.100.3.0/24"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "spoke1_web" {
  name                 = "WEB"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke1.name
  address_prefixes     = ["10.100.3.0/26"]
}

resource "azurerm_subnet" "spoke1_worker" {
  name                 = "WORKER"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke1.name
  address_prefixes     = ["10.100.3.64/26"]
}

resource "azurerm_subnet" "spoke1_db" {
  name                 = "DB"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke1.name
  address_prefixes     = ["10.100.3.128/26"]
}

resource "azurerm_virtual_network" "spoke2" {
  name                = "VNET_SPOKE2"
  address_space       = ["10.100.4.0/24"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "spoke2_web" {
  name                 = "WEB"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke2.name
  address_prefixes     = ["10.100.4.0/26"]
}

resource "azurerm_subnet" "spoke2_worker" {
  name                 = "WORKER"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke2.name
  address_prefixes     = ["10.100.4.64/26"]
}

resource "azurerm_subnet" "spoke2_db" {
  name                 = "DB"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke2.name
  address_prefixes     = ["10.100.4.128/26"]
}

resource "azurerm_virtual_network" "dmz_in" {
  name                = "VNET_DMZ_IN"
  address_space       = ["10.100.2.0/24"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "dmz_in_untrust" {
  name                 = "UNTRUST"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.dmz_in.name
  address_prefixes     = ["10.100.2.0/26"]
}

resource "azurerm_subnet" "dmz_in_trust" {
  name                 = "TRUST"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.dmz_in.name
  address_prefixes     = ["10.100.2.64/26"]
}

resource "azurerm_subnet" "dmz_in_mgmt" {
  name                 = "MGMT"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.dmz_in.name
  address_prefixes     = ["10.100.2.128/26"]
}

resource "azurerm_subnet" "dmz_in_firewall_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.dmz_in.name
  address_prefixes     = ["10.100.2.192/26"]
}

resource "azurerm_virtual_network" "dmz_out" {
  name                = "VNET_DMZ_OUT"
  address_space       = ["10.100.5.0/24"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "dmz_out_untrust" {
  name                 = "UNTRUST"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.dmz_out.name
  address_prefixes     = ["10.100.5.0/26"]
}

resource "azurerm_subnet" "dmz_out_trust" {
  name                 = "TRUST"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.dmz_out.name
  address_prefixes     = ["10.100.5.64/26"]
}

resource "azurerm_subnet" "dmz_out_mgmt" {
  name                 = "MGMT"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.dmz_out.name
  address_prefixes     = ["10.100.5.128/26"]
}

resource "azurerm_subnet" "dmz_out_firewall_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.dmz_out.name
  address_prefixes     = ["10.100.5.192/26"]
}

resource "azurerm_virtual_network_peering" "spoke1_dmz_out" {
  name                      = "PEER_SPOKE1_TO_DMZ_OUT"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.spoke1.name
  remote_virtual_network_id = azurerm_virtual_network.dmz_out.id
}

resource "azurerm_virtual_network_peering" "spoke2_dmz_out" {
  name                      = "PEER_SPOKE2_TO_DMZ_OUT"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.spoke2.name
  remote_virtual_network_id = azurerm_virtual_network.dmz_out.id
}

resource "azurerm_virtual_network_peering" "dmz_out_spoke1" {
  name                      = "PEER_DMZ_OUT_TO_SPOKE1"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.dmz_out.name
  remote_virtual_network_id = azurerm_virtual_network.spoke1.id
}

resource "azurerm_virtual_network_peering" "dmz_out_spoke2" {
  name                      = "PEER_SPOKE2_TO_DMZ_OUT"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.dmz_out.name
  remote_virtual_network_id = azurerm_virtual_network.spoke2.id
}

resource "azurerm_virtual_wan" "vwan" {
  name                = "VWAN"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_virtual_hub" "vwan_hub" {
  name                = "VWAN_HUB"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  virtual_wan_id      = azurerm_virtual_wan.vwan.id
  address_prefix      = "10.0.1.0/24"
  route {
    address_prefixes = ["10.100.3.0/24", "10.100.4.0/24"]
    next_hop_ip_address = "10.100.2.4"
  }
}

resource "azurerm_virtual_hub_connection" "spoke1" {
  name                      = "CONN_SPOKE1"
  virtual_hub_id            = azurerm_virtual_hub.vwan_hub.id
  remote_virtual_network_id = azurerm_virtual_network.spoke1.id
  # default values, TF wants to destroy without changes without explicitly defining
  vitual_network_to_hub_gateways_traffic_allowed = true
  hub_to_vitual_network_traffic_allowed          = true
  internet_security_enabled                      = false
  depends_on = [time_sleep.wait_10_min]
}

resource "azurerm_virtual_hub_connection" "spoke2" {
  name                      = "CONN_SPOKE2"
  virtual_hub_id            = azurerm_virtual_hub.vwan_hub.id
  remote_virtual_network_id = azurerm_virtual_network.spoke2.id
  # default values, TF wants to destroy without changes without explicitly defining
  vitual_network_to_hub_gateways_traffic_allowed = true
  hub_to_vitual_network_traffic_allowed          = true
  internet_security_enabled                      = false
  depends_on = [azurerm_virtual_hub_connection.spoke1]
}

resource "azurerm_virtual_hub_connection" "dmz_out" {
  name                      = "CONN_DMZ_OUT"
  virtual_hub_id            = azurerm_virtual_hub.vwan_hub.id
  remote_virtual_network_id = azurerm_virtual_network.dmz_out.id
  # default values, TF wants to destroy without changes without explicitly defining
  vitual_network_to_hub_gateways_traffic_allowed = true
  hub_to_vitual_network_traffic_allowed          = true
  internet_security_enabled                      = false
  depends_on = [azurerm_virtual_hub_connection.spoke1]
}

resource "azurerm_virtual_hub_connection" "dmz_in" {
  name                      = "CONN_DMZ_IN"
  virtual_hub_id            = azurerm_virtual_hub.vwan_hub.id
  remote_virtual_network_id = azurerm_virtual_network.dmz_in.id
  # default values, TF wants to destroy without changes without explicitly defining
  vitual_network_to_hub_gateways_traffic_allowed = true
  hub_to_vitual_network_traffic_allowed          = true
  internet_security_enabled                      = false
  depends_on = [azurerm_virtual_hub_connection.spoke1]
}

resource "azurerm_express_route_gateway" "vwan_hub" {
  name                = "ER_GW"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  virtual_hub_id      = azurerm_virtual_hub.vwan_hub.id
  scale_units         = 1
  depends_on = [azurerm_virtual_hub_connection.spoke1]
}

resource "azurerm_public_ip" "pip_dmz_in" {
  name                = "PIP_FW_DMZ_IN"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "dmz_in" {
  name                = "FW_DMZ_IN"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "FW_IP_CONFIG_DMZ_IN"
    subnet_id            = azurerm_subnet.dmz_in_firewall_subnet.id
    public_ip_address_id = azurerm_public_ip.pip_dmz_in.id
  }
}

resource "azurerm_public_ip" "pip_dmz_out" {
  name                = "PIP_FW_DMZ_OUT"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "dmz_out" {
  name                = "FW_DMZ_OUT"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "FW_IP_CONFIG_DMZ_OUT"
    subnet_id            = azurerm_subnet.dmz_out_firewall_subnet.id
    public_ip_address_id = azurerm_public_ip.pip_dmz_out.id
  }
}

resource "azurerm_route_table" "rt_spoke_to_dmz_out" {
  name                          = "RT_SPOKE_TO_DMZ_OUT"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name

  route {
    name                   = "SPOKE-TO-CORP"
    address_prefix         = "10.1.0.0/20"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.100.5.196"
  }
}

resource "azurerm_subnet_route_table_association" "spoke1_to_dmz_out" {
  subnet_id      = azurerm_subnet.spoke1_web.id
  route_table_id = azurerm_route_table.rt_spoke_to_dmz_out.id
}

resource "azurerm_subnet_route_table_association" "spoke2_to_dmz_out" {
  subnet_id      = azurerm_subnet.spoke2_web.id
  route_table_id = azurerm_route_table.rt_spoke_to_dmz_out.id
}

resource "azurerm_firewall_network_rule_collection" "corp_out" {
  name                = "CORP"
  azure_firewall_name = azurerm_firewall.dmz_out.name
  resource_group_name = azurerm_resource_group.rg.name
  priority            = 100
  action              = "Allow"

  rule {
    name = "RULE_CORP_OUT"

    source_addresses = [
      "10.0.0.0/16",
    ]

    destination_ports = [
      "*",
    ]

    destination_addresses = [
      "10.1.0.0/20",
    ]

    protocols = [
      "Any",
    ]
  }
}

resource "azurerm_firewall_network_rule_collection" "corp_in" {
  name                = "CORP"
  azure_firewall_name = azurerm_firewall.dmz_in.name
  resource_group_name = azurerm_resource_group.rg.name
  priority            = 100
  action              = "Allow"

  rule {
    name = "RULE_CORP_OUT"

    source_addresses = [
      "10.1.0.0/20",
    ]

    destination_ports = [
      "*",
    ]

    destination_addresses = [
      "10.100.0.0/16",
    ]

    protocols = [
      "Any",
    ]
  }
}

resource "azurerm_network_security_group" "nsg_spoke" {
  name                = "NSG_SPOKE"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "RULE_ALLOW_CORP_OUT"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "10.1.0.0/20"
  }

  security_rule {
    name                       = "RULE_ALLOW_SPOKE_TO_SPOKE_OUT"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.100.0.0/16"
    destination_address_prefix = "10.100.0.0/16"
  }

    security_rule {
    name                       = "RULE_ALLOW_CORP_IN"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.100.2.0/24"
    destination_address_prefix = "10.1.0.0/20"
  }

  security_rule {
    name                       = "RULE_ALLOW_SPOKE_TO_SPOKE_IN"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.100.0.0/16"
    destination_address_prefix = "10.100.0.0/16"
  }

    security_rule {
    name                       = "RULE_ALLOW_SSH_IN"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "VirtualNetwork"
  }
}

resource "azurerm_subnet_network_security_group_association" "spoke1" {
  subnet_id                 = azurerm_subnet.spoke1_web.id
  network_security_group_id = azurerm_network_security_group.nsg_spoke.id
}

resource "azurerm_subnet_network_security_group_association" "spoke2" {
  subnet_id                 = azurerm_subnet.spoke2_web.id
  network_security_group_id = azurerm_network_security_group.nsg_spoke.id
}

# SPOKE 1

resource "azurerm_resource_group" "spoke1" {
  name     = "VWAN_HUB_DEMO_TF_SPOKE1"
  location = "West Europe"
}

# resource "azurerm_linux_virtual_machine" "spoke1vm" {
#   name                = "VMSS-SPOKE1"
#   resource_group_name = azurerm_resource_group.spoke1.name
#   location            = azurerm_resource_group.spoke1.location
#   sku                 = "Standard_F2"
#   instances           = 2
#   admin_username      = "thevmlogin"
#   admin_password      = "SuperSecur3!"
#   disable_password_authentication = false

#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "UbuntuServer"
#     sku       = "18.04-LTS"
#     version   = "latest"
#   }

#   os_disk {
#     storage_account_type = "Standard_LRS"
#     caching              = "ReadWrite"
#   }

#   network_interface {
#     name    = "NIC_SPOKE1"
#     primary = true

#     ip_configuration {
#       name      = "WEB"
#       primary   = true
#       subnet_id = azurerm_subnet.spoke1_web.id
#     }
#   }
# }