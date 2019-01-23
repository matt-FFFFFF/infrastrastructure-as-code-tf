resource "azurerm_resource_group" "vmss" {
  name     = "${var.vmss-resource_group_name}"
  location = "${var.vmss-location}"
  tags     = "${var.vmss-tags}"
}

resource "random_string" "fqdn" {
  length  = 6
  special = false
  upper   = false
  number  = false
}

resource "azurerm_virtual_network" "vmss" {
  name                = "vmss-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.vmss-location}"
  resource_group_name = "${azurerm_resource_group.vmss.name}"
  tags                = "${var.vmss-tags}"
}

resource "azurerm_subnet" "vmss" {
  name                 = "vmss-subnet"
  resource_group_name  = "${azurerm_resource_group.vmss.name}"
  virtual_network_name = "${azurerm_virtual_network.vmss.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "vmss" {
  name                = "vmss-public-ip"
  location            = "${var.vmss-location}"
  resource_group_name = "${azurerm_resource_group.vmss.name}"
  allocation_method   = "Static"
  domain_name_label   = "${random_string.fqdn.result}"
  tags                = "${var.vmss-tags}"
}

resource "azurerm_lb" "vmss" {
  name                = "vmss-lb"
  location            = "${var.vmss-location}"
  resource_group_name = "${azurerm_resource_group.vmss.name}"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.vmss.id}"
  }

  tags = "${var.vmss-tags}"
}

resource "azurerm_lb_backend_address_pool" "bpepool" {
  resource_group_name = "${azurerm_resource_group.vmss.name}"
  loadbalancer_id     = "${azurerm_lb.vmss.id}"
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "vmss" {
  resource_group_name = "${azurerm_resource_group.vmss.name}"
  loadbalancer_id     = "${azurerm_lb.vmss.id}"
  name                = "healthprobe"
  port                = "${var.application_port}"
}

resource "azurerm_lb_rule" "lbnatrule" {
  resource_group_name            = "${azurerm_resource_group.vmss.name}"
  loadbalancer_id                = "${azurerm_lb.vmss.id}"
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = "${var.application_port}"
  backend_port                   = "${var.application_port}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.bpepool.id}"
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = "${azurerm_lb_probe.vmss.id}"
}

resource "azurerm_virtual_machine_scale_set" "vmss" {
  name                 = "vmscaleset"
  location             = "${var.vmss-location}"
  resource_group_name  = "${azurerm_resource_group.vmss.name}"
  upgrade_policy_mode  = "Rolling"
  automatic_os_upgrade = true

  rolling_upgrade_policy {
    max_batch_instance_percent              = 20
    max_unhealthy_instance_percent          = 20
    max_unhealthy_upgraded_instance_percent = 5
    pause_time_between_batches              = "PT0S"
  }

  health_probe_id = "${azurerm_lb_probe.vmss.id}"

  sku {
    name     = "Standard_DS1_v2"
    tier     = "Standard"
    capacity = 2
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_profile_data_disk {
    lun           = 0
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = 10
  }

  os_profile {
    computer_name_prefix = "vmssdemo"
    admin_username       = "${var.admin_user}"
    custom_data          = "${file("vmss.conf")}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/matt/.ssh/authorized_keys"
      key_data = "${file("vmss-ssh.pub")}"
    }
  }

  network_profile {
    name    = "terraformnetworkprofile"
    primary = true

    ip_configuration {
      name                                   = "IPConfiguration"
      subnet_id                              = "${azurerm_subnet.vmss.id}"
      load_balancer_backend_address_pool_ids = ["${azurerm_lb_backend_address_pool.bpepool.id}"]
      primary                                = true
    }
  }

  tags = "${var.vmss-tags}"
}

resource "azurerm_autoscale_setting" "vmss" {
  name                = "myAutoscaleSetting"
  resource_group_name = "${azurerm_resource_group.vmss.name}"
  location            = "${azurerm_resource_group.vmss.location}"
  target_resource_id  = "${azurerm_virtual_machine_scale_set.vmss.id}"

  profile {
    name = "defaultProfile"

    capacity {
      default = 2
      minimum = 2
      maximum = 10
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = "${azurerm_virtual_machine_scale_set.vmss.id}"
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = "${azurerm_virtual_machine_scale_set.vmss.id}"
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  notification {
    email {
      send_to_subscription_administrator    = true
      send_to_subscription_co_administrator = false
    }
  }
}

# Jumpbox
resource "azurerm_public_ip" "jumpbox" {
  name                = "jumpbox-public-ip"
  location            = "${var.vmss-location}"
  resource_group_name = "${azurerm_resource_group.vmss.name}"
  allocation_method   = "Static"
  domain_name_label   = "${random_string.fqdn.result}-ssh"
  tags                = "${var.vmss-tags}"
}

resource "azurerm_network_interface" "jumpbox" {
  name                = "jumpbox-nic"
  location            = "${var.vmss-location}"
  resource_group_name = "${azurerm_resource_group.vmss.name}"

  ip_configuration {
    name                          = "IPConfiguration"
    subnet_id                     = "${azurerm_subnet.vmss.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.jumpbox.id}"
  }

  tags = "${var.vmss-tags}"
}

resource "azurerm_virtual_machine" "jumpbox" {
  name                  = "jumpbox"
  location              = "${var.vmss-location}"
  resource_group_name   = "${azurerm_resource_group.vmss.name}"
  network_interface_ids = ["${azurerm_network_interface.jumpbox.id}"]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "jumpbox-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "jumpbox"
    admin_username = "${var.admin_user}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/matt/.ssh/authorized_keys"
      key_data = "${file("vmss-ssh.pub")}"
    }
  }

  tags = "${var.vmss-tags}"
}
