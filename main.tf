# Test example
variable "external_gateway" {
  default = "893a5b59-081a-4e3a-ac50-1e54e262c3fa"
}

variable "n3_gateway" {
  default = "893a5b59-081a-4e3a-ac50-1e54e262c3fa"
}

variable "n3_ip_pool" {
  default = "11.22.0.0/16"
}

# Configure the OpenStack Provider
provider "openstack" {
  # no need to define anything cos it gets pulled via the shell environments
}

# Define our network
resource "openstack_networking_network_v2" "network_1" {
  name           = "network_1"
  admin_state_up = "true"
}

# Create a subnet for our network
resource "openstack_networking_subnet_v2" "subnet_1" {
  name       = "subnet_1"
  network_id = "${openstack_networking_network_v2.network_1.id}"
  cidr       = "192.168.199.0/24"
  ip_version = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

# Define a router to connect to the internet
resource "openstack_networking_router_v2" "router_1" {
  name             = "my_router"
  external_gateway = "${var.external_gateway}"
}

# Now connect the router to the network using an interface
resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = "${openstack_networking_router_v2.router_1.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet_1.id}"
}

# Now add ssh public key so we can access the resource --// todo move public key to a variable
resource "openstack_compute_keypair_v2" "bastion-keypair" {
  name       = "bastion-keypair"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDggzO/9DNQzp8aPdvx0W+IqlbmbhpIgv1r2my1xOsVthFgx4HLiTB/2XEuEqVpwh5F+20fDn5Juox9jZAz+z3i5EI63ojpIMCKFDqDfFlIl54QPZVJUJVyQOe7Jzl/pmDJRU7vxTbdtZNYWSwjMjfZmQjGQhDd5mM9spQf3me5HsYY9Tko1vxGXcPE1WUyV60DrqSSBkrkSyf+mILXq43K1GszVj3JuYHCY/BBrupkhA126p6EoPtNKld4EyEJzDDNvK97+oyC38XKEg6lBgAngj4FnmG8cjLRXvbPU4gQNCqmrVUMljr3gYga+ZiPoj81NOuzauYNcbt6j+R1/B9qlze7VgNPYVv3ERzkboBdIx0WxwyTXg+3BHhY+E7zY1jLnO5Bdb40wDwl7AlUsOOriHL6fSBYuz2hRIdp0+upG6CNQnvg8pXNaNXNVPcNFPGLD1PuCJiG6x84+tLC2uAb0GWxAEVtWEMD1sBCp066dHwsivmQrYRxsYRHnlorlvdMSiJxpRo/peyiqEJ9Sa6OPl2A5JeokP1GxXJ6hyOoBn4h5WSuUVL6bS4J2ta7nA0fK6L6YreHV+dMdPZCZzSG0nV5qvSaAkdL7KuM4eeOvwcXAYMwZJPj+dCnGzwdhUIp/FtRy62mSHv5/kr+lVznWv2b2yl8L95SKAdfeOiFiQ== opensource@ukcloud.com"
}

resource "openstack_compute_keypair_v2" "secret-keypair" {
  name       = "secret-keypair"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCue01B/2Yzhz2y33HD3yn2dmid8Eh81jvUcwAv5dqyQODefqrR+znv9GxYdf43+Syy/Lz8XMVv1FNKdYKQ3SL9aPT4CL/by9cCF6hjOkqrGpCIxdI7q7aZpznlItcq+XyHqRHaab7Mj4GrU1SoWCpFiogU5Oxw0AvMb4fZyA7dsKr8adr6Ply1CZEsXbseSW5a7uAdpDidQn2jW7rFyxmi2uy/6y6aNzBqcz/zco8lk6nTdja0sAH44BzJK/fzrsNMlZrgSZRfy938mez7tfUmILr4zd07aQ3wSoToRJRn1yxJSBXOklXkJMLhnTGi8xj3a9wpVuH9t6SMP8m+7XoB"
}


# Now specify an image - using centos72 from openstack
resource "openstack_compute_instance_v2" "basic" {
  depends_on      = ["openstack_networking_subnet_v2.n3_subnet"]
  name            = "bastion"
  image_id        = "c09aceb5-edad-4392-bc78-197162847dd1"
  flavor_name       = "t1.tiny"
  key_pair        = "${openstack_compute_keypair_v2.bastion-keypair.name}"
  security_groups = ["default", "${openstack_compute_secgroup_v2.secgroup_1.name}"]

  metadata {
    this = "centos 72 base"
  }

  network {
    name = "${openstack_networking_network_v2.network_1.name}"
  }

  network {
    name = "${openstack_networking_network_v2.n3_network.0.name}"
    fixed_ip_v4 = "11.22.10.10"
  }
}

# Now declare security group with default ports open
resource "openstack_compute_secgroup_v2" "secgroup_1" {
  name        = "my_secgroup"
  description = "my security group"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

# Now declare security group with http ports open - 80 and 443
resource "openstack_compute_secgroup_v2" "http_group" {
  name        = "http_group"
  description = "Http only group"

  rule {
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

# Now acquire a public ip for our instance - here we specify 'internet' because that is the pool set up by UKCloud
resource "openstack_networking_floatingip_v2" "floatip_1" {
  pool = "internet"
}

# Now acquire a public ip for our instance - here we specify 'internet' because that is the pool set up by UKCloud
resource "openstack_networking_floatingip_v2" "floatip_2" {
  pool = "internet"
}

# Now associate the public ip with our instance
resource "openstack_compute_floatingip_associate_v2" "fip_1" {
  floating_ip = "${openstack_networking_floatingip_v2.floatip_1.address}"
  instance_id = "${openstack_compute_instance_v2.basic.id}"

    # This should upload the ssh private key from local config folder
    provisioner "file" {
      source = "./config/secret-key.pem"
      destination = "/home/centos/.ssh/id_rsa"
      connection {
        host = "${openstack_networking_floatingip_v2.floatip_1.address}"
        user = "centos"
        timeout = "1m"
      }
    }

    # This should upload the ssh private key from local config folder
    provisioner "remote-exec" {
      inline = [
        "sudo sh -c 'echo \"DEVICE=\"eth1\"\" > /etc/sysconfig/network-scripts/ifcfg-eth1'",
        "sudo sh -c 'echo \"IPADDR=11.22.10.10\" >> /etc/sysconfig/network-scripts/ifcfg-eth1'",
        "sudo sh -c 'echo \"NETMASK=255.255.255.0\"  >> /etc/sysconfig/network-scripts/ifcfg-eth1'",
        "sudo sh -c 'echo \"BOOTPROTO=\"static\"\"  >> /etc/sysconfig/network-scripts/ifcfg-eth1'",
        "sudo sh -c 'echo \"ONBOOT=\"yes\"\"  >> /etc/sysconfig/network-scripts/ifcfg-eth1'",
        "sudo sh -c 'echo \"TYPE=\"Ethernet\"\"  >> /etc/sysconfig/network-scripts/ifcfg-eth1'",
        "sudo sh -c 'echo \"USERCTL=\"no\"\"  >> /etc/sysconfig/network-scripts/ifcfg-eth1'",
        "sudo sh -c 'echo \"IPV6INIT=\"no\"\"  >> /etc/sysconfig/network-scripts/ifcfg-eth1'",

        "sudo sh -c 'service network restart'"
      ]
      connection {
        host = "${openstack_networking_floatingip_v2.floatip_1.address}"
        user = "centos"
        timeout = "1m"
      }
    }

    # set permissions on private key to 0600
    provisioner "remote-exec" {
      inline = [
        "chmod 0600 ~/.ssh/id_rsa"
      ]
      connection {
        host = "${openstack_networking_floatingip_v2.floatip_1.address}"
        user = "centos"
        timeout = "1m"
      }
  }
}

# Now associate the public ip with our APIgateway instance
resource "openstack_compute_floatingip_associate_v2" "fip_2" {
  floating_ip = "${openstack_networking_floatingip_v2.floatip_2.address}"
  instance_id = "${openstack_compute_instance_v2.w3_apigateway.id}"
}

# Now create API gateway instance

# Now specify an image - using centos72 from openstack for API gateway
resource "openstack_compute_instance_v2" "w3_apigateway" {
  name            = "w3_apigateway"
  image_id        = "c09aceb5-edad-4392-bc78-197162847dd1"
  flavor_name       = "t1.tiny"
  key_pair        = "${openstack_compute_keypair_v2.secret-keypair.name}"
  security_groups = ["default", "${openstack_compute_secgroup_v2.http_group.name}"]

  metadata {
    this = "centos 72 base"
  }

  network {
    name = "${openstack_networking_network_v2.network_1.name}"
  }
}

# Phase II  - recreate dummy N3 
# Define our network
resource "openstack_networking_network_v2" "n3_network" {
  count = "7"
  name           = "n3_network_${count.index}"
  admin_state_up = "true"
}

# Create a subnet for our network - but we need 3 sub nets and we use cidr host function to allocate 
# ip instead of adding it manually
resource "openstack_networking_subnet_v2" "n3_subnet" {
  name       = "n3_subnet_${count.index}"
  count = "7"
  network_id = "${element(openstack_networking_network_v2.n3_network.*.id, count.index)}"
  cidr       = "${cidrsubnet(var.n3_ip_pool, 8, (count.index+1)*10)}"
  ip_version = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

###
# BEGIN FAKE n3 STUFF 
###

# Create our Dummy N3 Internet - delete when you have an n3 internet connection
resource "openstack_networking_network_v2" "n3_internet" {
  name           = "n3_internet"
  admin_state_up = "true"
}

# Create a subnet for the N3 internet.
resource "openstack_networking_subnet_v2" "n3_internet_subnet" {
  network_id = "${openstack_networking_network_v2.n3_internet.id}"
  cidr       = "20.20.20.20/24"
  ip_version = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

# For the fake n3 connection. delete when you have an n3 internet conenction
resource "openstack_networking_router_interface_v2" "n3_internet_router_interface" {
  router_id = "${openstack_networking_router_v2.n3_router.id}"
  subnet_id = "${openstack_networking_subnet_v2.n3_internet_subnet.id}"
}

###
# END FAKE n3 STUFF 
###

# Define a router to connect to the internet 
resource "openstack_networking_router_v2" "n3_router" {
  name             = "n3_router"
  #external_gateway = "${var.n3_gateway}"
}

# Now connect the router to the network using an interface - but we loop through the 3 subnets to connect them to the router
resource "openstack_networking_router_interface_v2" "n3_router_interface" {
  count = "7"
  router_id = "${openstack_networking_router_v2.n3_router.id}"
  subnet_id = "${element(openstack_networking_subnet_v2.n3_subnet.*.id, count.index)}"
}

# Now create N3 API gateway instance
# Now specify an image - using centos72 from openstack for API gateway
resource "openstack_compute_instance_v2" "n3_apigateway" {
  depends_on      = ["openstack_networking_subnet_v2.n3_subnet"]
  name            = "n3_apigateway"
  image_id        = "c09aceb5-edad-4392-bc78-197162847dd1"
  flavor_name       = "t1.tiny"
  key_pair        = "${openstack_compute_keypair_v2.secret-keypair.name}"
  security_groups = ["default", "${openstack_compute_secgroup_v2.http_group.name}"]

  metadata {
    this = "centos 72 base"
  }

  network {
    name = "${openstack_networking_network_v2.n3_network.0.name}"
  }
}

# Get a public IP for N3 api gateway
resource "openstack_networking_floatingip_v2" "n3_floatip" {
  pool = "internet"
}

# Now associate the N3 public ip with our N3 APIgateway instance
#resource "openstack_compute_floatingip_associate_v2" "n3_fip" {
#  floating_ip = "${openstack_networking_floatingip_v2.n3_floatip.address}"
#  instance_id = "${openstack_compute_instance_v2.n3_apigateway.id}"
#}

# Now create db server - using centos72 from openstack
resource "openstack_compute_instance_v2" "db_server" {
  depends_on      = ["openstack_networking_subnet_v2.n3_subnet"]
  name            = "db_server"
  image_id        = "c09aceb5-edad-4392-bc78-197162847dd1"
  flavor_name     = "t1.tiny"
  key_pair        = "${openstack_compute_keypair_v2.secret-keypair.name}"
  security_groups = ["default"]

  metadata {
    this = "centos 72 base"
  }

  network {
    name = "${openstack_networking_network_v2.n3_network.1.name}"
  }
}

# Now create frontend servers - using centos72 from openstack
resource "openstack_compute_instance_v2" "frontend_server" {
  depends_on      = ["openstack_networking_subnet_v2.n3_subnet"]
  count           = 2
  name            = "frontend_server_${count.index}"
  image_id        = "c09aceb5-edad-4392-bc78-197162847dd1"
  flavor_name     = "t1.tiny"
  key_pair        = "${openstack_compute_keypair_v2.secret-keypair.name}"
  security_groups = ["default"]

  metadata {
    this = "centos 72 base"
  }

  network {
    name = "${openstack_networking_network_v2.n3_network.2.name}"
  }
}

# Now create backend servers - using centos72 from openstack
resource "openstack_compute_instance_v2" "backend_server" {
  depends_on      = ["openstack_networking_subnet_v2.n3_subnet"]
  count           = 2
  name            = "backend_server_${count.index}"
  image_id        = "c09aceb5-edad-4392-bc78-197162847dd1"
  flavor_name     = "t1.tiny"
  key_pair        = "${openstack_compute_keypair_v2.secret-keypair.name}"
  security_groups = ["default"]

  metadata {
    this = "centos 72 base"
  }

  network {
    name = "${openstack_networking_network_v2.n3_network.3.name}"
  }
}

# Now create cdr6 servers - using centos72 from openstack
resource "openstack_compute_instance_v2" "cdr6_server" {
  depends_on      = ["openstack_networking_subnet_v2.n3_subnet"]
  count           = 2
  name            = "cdr6_server_${count.index}"
  image_id        = "c09aceb5-edad-4392-bc78-197162847dd1"
  flavor_name     = "t1.tiny"
  key_pair        = "${openstack_compute_keypair_v2.secret-keypair.name}"
  security_groups = ["default"]

  metadata {
    this = "centos 72 base"
  }

  network {
    name = "${openstack_networking_network_v2.n3_network.4.name}"
  }
}


# Now create messagin servers - using centos72 from openstack
resource "openstack_compute_instance_v2" "messaging_server" {
  depends_on      = ["openstack_networking_subnet_v2.n3_subnet"]
  count           = 2
  name            = "messaging_server_${count.index}"
  image_id        = "c09aceb5-edad-4392-bc78-197162847dd1"
  flavor_name     = "t1.tiny"
  key_pair        = "${openstack_compute_keypair_v2.secret-keypair.name}"
  security_groups = ["default"]

  metadata {
    this = "centos 72 base"
  }

  network {
    name = "${openstack_networking_network_v2.n3_network.5.name}"
  }
}

# Now create haproxy servers - using centos72 from openstack
resource "openstack_compute_instance_v2" "haproxy_server" {
  depends_on      = ["openstack_networking_subnet_v2.n3_subnet"]
  count           = 2
  name            = "haproxy_server_${count.index}"
  image_id        = "c09aceb5-edad-4392-bc78-197162847dd1"
  flavor_name     = "t1.tiny"
  key_pair        = "${openstack_compute_keypair_v2.secret-keypair.name}"
  security_groups = ["default"]

  metadata {
    this = "centos 72 base"
  }

  network {
    name = "${openstack_networking_network_v2.n3_network.6.name}"
  }
}

# Now create haproxy servers - using centos72 from openstack
resource "openstack_compute_instance_v2" "database_server" {
  depends_on      = ["openstack_networking_subnet_v2.n3_subnet"]
  count           = 2
  name            = "database_server_${count.index}"
  image_id        = "c09aceb5-edad-4392-bc78-197162847dd1"
  flavor_name     = "t1.tiny"
  key_pair        = "${openstack_compute_keypair_v2.secret-keypair.name}"
  security_groups = ["default"]

  metadata {
    this = "centos 72 base"
  }

  network {
    name = "${openstack_networking_network_v2.n3_network.6.name}"
  }
}