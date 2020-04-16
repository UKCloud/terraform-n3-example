#Create BASTION Instance
resource "openstack_compute_instance_v2" "bastion" {
  depends_on      = [openstack_networking_subnet_v2.n3_dmz]
  name            = "${var.environment_prefix}_bastion"
  image_id        = "c09aceb5-edad-4392-bc78-197162847dd1"
  flavor_name       = "t1.tiny"
  key_pair        = openstack_compute_keypair_v2.bastion-keypair.name
  security_groups = ["default", "${openstack_compute_secgroup_v2.n3_demo_ssh.name}"]

  metadata = {
    this = "centos 72 base"
  }

  network {
    name = openstack_networking_network_v2.internet_dmz.name
  }

  network {
    name = openstack_networking_network_v2.n3_dmz.name
    fixed_ip_v4 = "172.16.1.10"
  }
}

resource "null_resource" "bastion_config" {
    # This should upload the ssh private key from local config folder
    provisioner "file" {
      source = "./config/secret-key.pem"
      destination = "/home/centos/.ssh/id_rsa"
      connection {
        host = openstack_networking_floatingip_v2.floatip_1.address
        user = "centos"
        timeout = "1m"
        private_key = file(var.bastion_private_key_file)
      }
    }

    # This should upload the ssh private key from local config folder
    provisioner "remote-exec" {
      inline = [
        "sudo sh -c 'echo \"DEVICE=\"eth1\"\" > /etc/sysconfig/network-scripts/ifcfg-eth1'",
        "sudo sh -c 'echo \"IPADDR=172.16.1.10\" >> /etc/sysconfig/network-scripts/ifcfg-eth1'",
        "sudo sh -c 'echo \"NETMASK=255.255.255.0\"  >> /etc/sysconfig/network-scripts/ifcfg-eth1'",
        "sudo sh -c 'echo \"BOOTPROTO=\"static\"\"  >> /etc/sysconfig/network-scripts/ifcfg-eth1'",
        "sudo sh -c 'echo \"ONBOOT=\"yes\"\"  >> /etc/sysconfig/network-scripts/ifcfg-eth1'",
        "sudo sh -c 'echo \"TYPE=\"Ethernet\"\"  >> /etc/sysconfig/network-scripts/ifcfg-eth1'",
        "sudo sh -c 'echo \"USERCTL=\"no\"\"  >> /etc/sysconfig/network-scripts/ifcfg-eth1'",
        "sudo sh -c 'echo \"IPV6INIT=\"no\"\"  >> /etc/sysconfig/network-scripts/ifcfg-eth1'",

        "sudo sh -c 'service network restart'"
      ]
      connection {
        host = openstack_networking_floatingip_v2.floatip_1.address
        user = "centos"
        timeout = "1m"
        private_key = file(var.bastion_private_key_file)
      }
    }

    # set permissions on private key to 0600
    provisioner "remote-exec" {
      inline = [
        "chmod 0600 ~/.ssh/id_rsa"
      ]
      connection {
        host = openstack_networking_floatingip_v2.floatip_1.address
        user = "centos"
        timeout = "1m"
        private_key = file(var.bastion_private_key_file)
      }
  }

}

# Now acquire a public ip for our instance - here we specify 'internet' because that is the pool set up by UKCloud
resource "openstack_networking_floatingip_v2" "floatip_1" {
  pool = "internet"
}

# Now associate the public ip with our instance
resource "openstack_compute_floatingip_associate_v2" "fip_1" {
  floating_ip = openstack_networking_floatingip_v2.floatip_1.address
  instance_id = openstack_compute_instance_v2.bastion.id

}


# Create an N3 connected instance
resource "openstack_compute_instance_v2" "app" {
  depends_on      = [openstack_networking_subnet_v2.n3_app]
  name            = "${var.environment_prefix}_app"
  image_id        = "c09aceb5-edad-4392-bc78-197162847dd1"
  flavor_name       = "t1.tiny"
  key_pair        = openstack_compute_keypair_v2.secret-keypair.name
  security_groups = ["default", "${openstack_compute_secgroup_v2.n3_demo_ssh.name}"]

  metadata = {
    this = "centos 72 base"
  }

  network {
    name = openstack_networking_network_v2.n3_app.name
  }
}
