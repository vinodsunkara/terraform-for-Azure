Terraform
=======

**HashiCorp Terraform is installed by default in the Azure Cloud Shell. Cloud shell can be run standalone, or as an integrated command-line terminal from the Azure portal. If you would like to continue to install in your local machine, you need to install and follow the below prerequisites.**

Prerequisites
---
* An Azure account
* A system with Terraform installed
* Azure CLI or Azure Service Principal account to authenticate

Creating Service Principal Account:
---

**Service Principal:** 
An Azure service principal is an identity created for use with applications, hosted services, and automated tools to access Azure resources. This access is restricted by the roles assigned to the service principal, giving you control over which resources can be accessed and at which level.
Azure active directory: Azure Active Directory (Azure AD) is Microsoft's cloud-based identity and access management service, which helps your employees sign in and access resources in

**Tenant:** 
A tenant represents an organization in Azure Active Directory. It's a dedicated Azure AD service instance that an organization receives and owns when it signs up for a Microsoft cloud service such as Azure

**Subscription:** 
An Azure subscription has a trust relationship with Azure Active Directory (Azure AD), which means that the subscription trusts Azure AD to authenticate users, services, and devices.

**How to create a service principal?**  
Azure Portal => Active Directory => App Registrations => New Registration 

**How to create a service principal secret key?**  
Azure Portal => Active Directory => App Registrations => Select the application => Certificates & Secrets => New client secret

Terraform Installation:
---
* Find the appropriate Terraform distribution package for your system and download it. Terraform is distributed as a single .zip file
* After downloading Terraform, unzip the package to a directory of your choosing. 
* Terraform runs as a single binary named terraform.
* Any other files in the package can be safely removed and Terraform will still function
* Modify the path to include the directory that contains the Terraform binary.
* Link for path change on Windows:  https://stackoverflow.com/questions/1618280/where-can-i-set-path-to-make-exe-on-windows

Configuration
---
* The set of files used to describe infrastructure in Terraform is known as a Terraform configuration.
* A configuration can be composed of both `.tf` and `.tf.json` files. (For ex the file ends with `main.tf` or `main.tf.json`)


Providers
---
The provider block is used to configure the named provider, in this instance the Azure provider `(azurerm)`. The Azure provider is responsible for creating and managing resources on Azure. The version argument is optional but recommended.

```
provider "azurerm" {
    version = "=1.20.0"
}
```
Resources
---
A resource block defines a resource that exists within the infrastructure. A resource might be a physical component such as a network interface or resource group.
A resource block has two string parameters before opening the block.
1.	The resource type (first parameter) and 
2.	The resource name (second parameter)
```
resource "azurerm_resource_group" "RG" {
    name     = "Vinod_RG"
    location = "Central US"
}
```
So, after combining the provider part and resource part the `.tf` file looks like below. With this configuration we can simply deploy the Resource Group on Azure.
```
# Configure the provider
provider "azurerm" {
    version = "=1.20.0"
}
# Create a new resource group
resource "azurerm_resource_group" "RG" {
    name     = "Vinod_RG"
    location = "Central US"
}
```
Initialization
---
* The first command to run for a new configuration is `“terraform init”` which initializes various local settings and data that will be used by subsequent commands.
* Please see the link below for more details
https://www.terraform.io/docs/commands/init.html

Apply Changes
---
With the `“terraform plan”` command is used to create an execution plan. The output will describe which actions Terraform will take in order to change real infrastructure to match the configuration.
With the `“terraform apply”` command is used the make the changes in real infrastructure (like deploying the resources to azure)

Terraform State
---
When Terraform created the resource group it also wrote data into the `“terraform.tfstate”` file. State keeps track of the IDs of created resources so that Terraform knows what it is managing.
You can inspect the current state using `“terraform state show”`

Destroy
---
Resources can be destroyed using the `“terraform destroy”` command, which is like terraform apply but it behaves as if all of the resources have been removed from the configuration.

Variables, Credentials, Interpolation, Dependencies, VNET, Subnets
---
**Variables:** Terraform has three types of native variables `(strings, maps & lists)`. Terraform supports a few different variable formats. Depending on the usage, the variables are generally divided into inputs and outputs. 
The input variables are used to define values that configure your infrastructure. These values can be used again and again without having to remember their every occurrence in the event it needs to be updated.
Output variables, in contrast, are used to get information about the infrastructure after deployment. These can be useful for passing on information such as IP addresses for connecting to the server.

Terraform uses this dependency information to determine the correct order in which to create the different resources.

In the below example, you can see dependencies which we have to create before creating a Virtual Machine.

Installing a Ubuntu Linux Virtual Machine with all the dependencies using terraform
---

```
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

```

**Hopefully, I will update the document soon with all the other resources**