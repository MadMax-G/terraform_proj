resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-stock_market"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "public" {
  name                 = "public-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.public_subnet]
}

resource "azurerm_subnet" "private" {
  name                 = "private-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "public_nsg" {
  name                = "public-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "opentoport22"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = var.app_port
    source_address_prefix      = "*" # depends on current ip
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "private_nsg" {
  name                = "private-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "5432open"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allowssshtoprivateip"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*" # depends on current ip
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg-web-associate" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.public_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "nsg-db-associate" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.private_nsg.id
}

resource "azurerm_public_ip" "web_public_ip" {
  name                = "web-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku = "Basic"
}

resource "azurerm_public_ip" "database_public_ip" {
  name                = "database-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku = "Basic"
}

resource "azurerm_network_interface" "web_nic" {
  name                = "web-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "public-ip"
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web_public_ip.id
  }
}

resource "azurerm_network_interface" "database_nic" {
  name                = "database-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name             = "private-ip"
    subnet_id        = azurerm_subnet.private.id
    private_ip_address_allocation = "Static"
    private_ip_address = var.database_private_ip
    public_ip_address_id = azurerm_public_ip.database_public_ip.id
  }
}

resource "tls_private_key" "vm_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "local_file" "ssh_pem" {
  filename = "${path.module}\\private_key.pem"
  content = tls_private_key.vm_ssh.private_key_pem
}

resource "azurerm_virtual_machine" "web_vm" {
  name                = "web-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  vm_size             = "Standard_B2ats_v2"
  network_interface_ids = [
    azurerm_network_interface.web_nic.id,
  ]

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "web-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "web-vm"
    admin_username = var.admin_user
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  depends_on = [azurerm_virtual_machine.database_vm]
}

resource "azurerm_virtual_machine" "database_vm" {
  name                = "database-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  vm_size             = "Standard_B2ats_v2"
  network_interface_ids = [
    azurerm_network_interface.database_nic.id,
  ]

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "database-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "database-vm"
    admin_username = var.admin_user
    admin_password = var.admin_password

  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_managed_disk" "web-disk" {
  name                 = "${azurerm_virtual_machine.web_vm.name}-disk1"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 10
}
#attach web disk to web vm
resource "azurerm_virtual_machine_data_disk_attachment" "web_disk_attach" {
  managed_disk_id    = azurerm_managed_disk.web-disk.id
  virtual_machine_id = azurerm_virtual_machine.web_vm.id
  lun                = "10"
  caching            = "ReadWrite"
}
#web provision to mount disk
resource "null_resource" "web_vm_prov" {
  connection {
    type = "ssh"
    user = var.admin_user
    private_key = tls_private_key.vm_ssh.private_key_pem
    host = azurerm_public_ip.web_public_ip.id
  }
  provisioner "remote-exec" {
    inline=[
    "sudo mkfs -t ext4 /dev/sdc",
    "sudo mkdir /data1",
    "sudo mount /dev/sdc /data1"
    ]
  }
  depends_on = [
    azurerm_virtual_machine_data_disk_attachment.web_disk_attach
  ]
}

#create db vm managed disk
resource "azurerm_managed_disk" "database-disk" {
  name                 = "${azurerm_virtual_machine.database_vm.name}-disk1"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 10
}
#attach db disk to web vm
resource "azurerm_virtual_machine_data_disk_attachment" "database_disk_attach" {
  managed_disk_id    = azurerm_managed_disk.database-disk.id
  virtual_machine_id = azurerm_virtual_machine.database_vm.id
  lun                = "10"
  caching            = "ReadWrite"
}
#db provision to mount disk
resource "null_resource" "db_vm_prov" {
  connection {
    type = "ssh"
    user = var.admin_user
    private_key = tls_private_key.vm_ssh.private_key_pem
    host = azurerm_public_ip.database_public_ip.id
  }
  provisioner "remote-exec" {
    inline=[
    "sudo mkfs -t ext4 /dev/sdc",
    "sudo mkdir /data1",
    "sudo mount /dev/sdc /data1"
    ]
  }
  depends_on = [
    azurerm_virtual_machine_data_disk_attachment.database_disk_attach
  ]
}

resource "azurerm_virtual_machine_extension" "database_ext" {
  name                 = "init_postgresql"
  virtual_machine_id   = azurerm_virtual_machine.database_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
 {
  "commandToExecute": "sudo apt-get update && sudo apt install git -y && git clone https://github.com/MadMax-G/terraform_proj.git && sudo sh /var/lib/waagent/custom-script/download/0/terraform_proj/scripts/database_script.sh '${var.app_port}' '${var.database_private_ip}' '${var.admin_user}' '${var.admin_password}' '${var.public_subnet}'"
}
SETTINGS
  depends_on = [
  azurerm_virtual_machine.database_vm
  ]
}

#creating web extension
resource "azurerm_virtual_machine_extension" "web_ext" {
  name                 = "install_run_flask"
  virtual_machine_id   = azurerm_virtual_machine.web_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
 {
  "commandToExecute": "sudo apt-get update && sudo apt install git -y && git clone https://github.com/MadMax-G/terraform_proj.git && sudo sh /var/lib/waagent/custom-script/download/0/terraform_proj/scripts/web_script.sh '${var.app_port}' '${var.database_private_ip}' '${var.admin_user}' '${var.admin_password}' '${var.public_subnet}'"
}
SETTINGS
  depends_on = [
  azurerm_virtual_machine.database_vm,
    azurerm_virtual_machine_extension.database_ext,
    azurerm_virtual_machine.web_vm
  ]
}
