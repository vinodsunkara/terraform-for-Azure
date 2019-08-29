# Configure the Microsoft Azure Provider.
provider "azurerm" {
  
}

# Create a resource group
resource "azurerm_resource_group" "RG" {
    name     = "Vinod_RG"
    location = "Central US"
}
# Create virtual network
resource "azurerm_virtual_network" "VNet" {
    name                = "Vinod_Vnet"
    address_space       = ["10.0.0.0/16"]
    location            = "Central US"
    resource_group_name = "${azurerm_resource_group.RG.name}"
}

# Create subnet
resource "azurerm_subnet" "subnet" {
    name                 = "VinodSubNet"
    resource_group_name  = "${azurerm_resource_group.RG.name}"
    virtual_network_name = "${azurerm_virtual_network.VNet.name}"
    address_prefix       = "10.0.1.0/24"
}

# Create public IP
resource "azurerm_public_ip" "publicip" {
    name                         = "VinodIP"
    location                     = "Central US"
    resource_group_name          = "${azurerm_resource_group.RG.name}"
    public_ip_address_allocation = "dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg" {
    name                = "VinodNSG"
    location            = "Central US"
    resource_group_name = "${azurerm_resource_group.RG.name}"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

# Create network interface
resource "azurerm_network_interface" "nic" {
    name                      = "VinodNIC"
    location                  = "Central US"
    resource_group_name       = "${azurerm_resource_group.RG.name}"
    network_security_group_id = "${azurerm_network_security_group.nsg.id}"

    ip_configuration {
        name                          = "myNICConfg"
        subnet_id                     = "${azurerm_subnet.subnet.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.publicip.id}"
    }
}

# Create a Linux virtual machine
resource "azurerm_virtual_machine" "vm" {
    name                  = "VinodVM"
    location              = "Central US"
    resource_group_name   = "${azurerm_resource_group.RG.name}"
    network_interface_ids = ["${azurerm_network_interface.nic.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04 LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "VinodVM"
        admin_username = "vinodsunkara"
        admin_password = "Password@123"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }

}

