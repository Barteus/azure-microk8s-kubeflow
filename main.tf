locals {
  common_tags = {
    terraform = true
  }
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = local.common_tags
}

resource "azurerm_virtual_network" "main" {
  name                = "main-network"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = ["10.0.0.0/16"]

  tags = local.common_tags
}

resource "azurerm_subnet" "main" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "main" {
  count               = var.nodes_count
  name                = "k8s-public-ip-${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"

  tags = local.common_tags
}

resource "azurerm_network_interface" "external" {
  count               = var.nodes_count
  name                = "external-nic-${count.index}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "public"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main[count.index].id
  }
}

module "network-security-group" {
  depends_on          = [azurerm_resource_group.main]
  source              = "Azure/network-security-group/azurerm"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  security_group_name = "kubeflow-k8s-nsg"
  predefined_rules    = [
    {
      name     = "SSH"
      priority = "500"
    }
  ]
  tags                = local.common_tags
}

resource "azurerm_linux_virtual_machine" "node" {
  count                 = var.nodes_count
  name                  = "kubeflow-k8s-${count.index}"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  size                  = var.instance_size
  priority              = "Spot"
  eviction_policy       = "Deallocate"
  max_bid_price         = -1
  admin_username        = var.vm_user
  network_interface_ids = [
    azurerm_network_interface.external[count.index].id,
  ]
  admin_ssh_key {
    username   = var.vm_user
    public_key = file(var.ssh_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.vm_storage_account_type
    disk_size_gb         = var.vm_disk_size
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  tags = local.common_tags
}

resource "azurerm_network_interface_security_group_association" "example" {
  count                     = var.nodes_count
  network_interface_id      = azurerm_network_interface.external[count.index].id
  network_security_group_id = module.network-security-group.network_security_group_id
}
