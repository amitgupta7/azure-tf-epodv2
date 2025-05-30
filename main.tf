terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.30.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id            = var.az_subscription_id
  skip_provider_registration = true
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.az_name_prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.region
  resource_group_name = var.az_resource_group
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.az_name_prefix}_pod-subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = var.az_resource_group
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "pod_sg" {
  name                = "${var.az_name_prefix}_pods-sg"
  location            = var.region
  resource_group_name = var.az_resource_group

  security_rule {
    name                       = "SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "${var.client_ip}"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "pod_ip" {
  name                = "${var.az_name_prefix}_jumpbox_ip"
  location            = var.region
  resource_group_name = var.az_resource_group
  allocation_method   = "Static"
  domain_name_label   = "${var.az_name_prefix}-jumpbox"
}

resource "azurerm_network_interface" "pod_nic" {
  name                = "${var.az_name_prefix}_jumpbox_nic"
  location            = var.region
  resource_group_name = var.az_resource_group
  ip_configuration {
    name                          = "${var.az_name_prefix}_jumpbox_ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.2.21"
    public_ip_address_id          = azurerm_public_ip.pod_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nsg" {
  network_interface_id      = azurerm_network_interface.pod_nic.id
  network_security_group_id = azurerm_network_security_group.pod_sg.id
}

resource "azurerm_linux_virtual_machine" "jumpbox-vm" {
  name                  = "${var.az_name_prefix}-jumpbox-vm"
  network_interface_ids = [azurerm_network_interface.pod_nic.id]
  //variables
  location            = var.region
  resource_group_name = var.az_resource_group
  size                = var.vm_size
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = var.os_publisher
    offer     = var.os_offer
    sku       = var.os_sku
    version   = var.os_version
  }
  admin_username                  = var.azuser
  admin_password                  = var.azpwd
  disable_password_authentication = false

}


resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.az_name_prefix}-aks"
  kubernetes_version  = var.kubernetes_version
  location            = var.region
  resource_group_name = var.az_resource_group
  dns_prefix          = var.az_name_prefix
  private_cluster_public_fqdn_enabled = true


  default_node_pool {
    name                = "system"
    node_count          = var.min_node_count
    vm_size             = var.node_vm_size
    linux_os_config {
      sysctl_config{
        vm_max_map_count = 262144
      }
    }
  }

    network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "dev"
  }
}

resource "null_resource" "install_jumpbox" {
    
  triggers = {
    build_number = "${timestamp()}"
  }  
  depends_on = [azurerm_linux_virtual_machine.jumpbox-vm]
  connection {
    type     = "ssh"
    user     = var.azuser
    password = var.azpwd
    host     = azurerm_public_ip.pod_ip.fqdn
  }

    provisioner "file" {
    source = "createAppliance.sh"
    destination = "/home/${var.azuser}/createAppliance.sh"
    }

    provisioner "remote-exec" {
    inline = [
      "chmod +x /home/${var.azuser}/createAppliance.sh && /home/${var.azuser}/createAppliance.sh -o ${var.pod_owner} -k ${var.X_API_Key} -s ${var.X_API_Secret} -t ${var.X_TIDENT} -n ${var.az_name_prefix}-pod",
      "curl -LO https://dl.k8s.io/release/v1.33.0/bin/linux/amd64/kubectl && sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl",
      "curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | sudo bash","sleep 1"
     ]
    }
}

resource "null_resource" "post_provisioning" {
    
  triggers = {
    build_number = "${timestamp()}"
  }  
  depends_on = [null_resource.install_jumpbox, azurerm_kubernetes_cluster.aks]
  connection {
    type     = "ssh"
    user     = var.azuser
    password = var.azpwd
    host     = azurerm_public_ip.pod_ip.fqdn
  }

  provisioner "local-exec" {
    command = "az aks get-credentials --resource-group ${var.az_resource_group} --name ${azurerm_kubernetes_cluster.aks.name} --file localfiles/config.aks --overwrite-existing"
  }

   provisioner "file" {
    source = "localfiles/config.aks"
    destination = "/home/${var.azuser}/.kube_config"
    
  }
    provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/${var.azuser}/.kube && mv /home/${var.azuser}/.kube_config /home/${var.azuser}/.kube/config && chmod 600 /home/${var.azuser}/.kube/config",
      "cd localfiles && kubectl apply -f secret.json -n default && cat install.sh | bash", 
      "cat /home/${var.azuser}/localfiles/register.sh | bash",
      "sleep 1" 
     ]
  }
}

resource "null_resource" "remove_pod" {
    triggers = {
    user     = var.azuser
    password = var.azpwd
    host     = azurerm_public_ip.pod_ip.fqdn
    X_API_Key  = var.X_API_Key
    X_API_Secret = var.X_API_Secret
    X_TIDENT = var.X_TIDENT
  }
  connection {
    type     = "ssh"
    user     = self.triggers.user
    password = self.triggers.password
    host = self.triggers.host
  }
  provisioner "remote-exec" {
    when = destroy
    inline = ["curl -s -X 'DELETE' \"https://app.securiti.ai/core/v1/admin/appliance/$(cat /home/${self.triggers.user}/localfiles/appliance.json| jq -r '.data.id')\" -H 'accept: application/json' -H 'X-API-Secret:  ${self.triggers.X_API_Secret}' -H 'X-API-Key:  ${self.triggers.X_API_Key}' -H 'X-TIDENT:  ${self.triggers.X_TIDENT}' | jq" ]
  }
}

output "ssh_credentials" {
  value = "ssh ${var.azuser}@${azurerm_public_ip.pod_ip.fqdn} \nwith password: ${var.azpwd}"
}