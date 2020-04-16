# Test example

variable "environment_prefix"{

}

variable "external_network_id" {
  default = "893a5b59-081a-4e3a-ac50-1e54e262c3fa"
}

variable "n3_network_id" {
  default = "893a5b59-081a-4e3a-ac50-1e54e262c3fa"
}

variable "n3_ip_pool" {
  default = "11.22.0.0/16"
}

variable "internet_router_name" {
  default = "internet"
}

variable "n3_router_name" {
  default = "n3"
}

variable "bastion_public_key_file" {
  default = "~/.ssh/id_rsa.pub"
}

variable "bastion_private_key_file" {
  default = "~/.ssh/id_rsa"
}


# Configure the OpenStack Provider
provider "openstack" {
  # no need to define anything cos it gets pulled via the shell environments
  auth_url = "https://cor00005.cni.ukcloud.com:13000/v2.0"
  user_name   = "tlawrence@ukcloud.com"
  tenant_name = "Tim_Demo"
  password    = "diesel8005SK!3"
  region      = "regionOne"
}



# Now add ssh public key so we can access the resource --// todo move public key to a variable
resource "openstack_compute_keypair_v2" "bastion-keypair" {
  name       = "${var.environment_prefix}_bastion-keypair"
  public_key = file(var.bastion_public_key_file)
}

resource "openstack_compute_keypair_v2" "secret-keypair" {
  name       = "${var.environment_prefix}_secret-keypair"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCue01B/2Yzhz2y33HD3yn2dmid8Eh81jvUcwAv5dqyQODefqrR+znv9GxYdf43+Syy/Lz8XMVv1FNKdYKQ3SL9aPT4CL/by9cCF6hjOkqrGpCIxdI7q7aZpznlItcq+XyHqRHaab7Mj4GrU1SoWCpFiogU5Oxw0AvMb4fZyA7dsKr8adr6Ply1CZEsXbseSW5a7uAdpDidQn2jW7rFyxmi2uy/6y6aNzBqcz/zco8lk6nTdja0sAH44BzJK/fzrsNMlZrgSZRfy938mez7tfUmILr4zd07aQ3wSoToRJRn1yxJSBXOklXkJMLhnTGi8xj3a9wpVuH9t6SMP8m+7XoB"
}




# Now declare security group with default ports open
resource "openstack_compute_secgroup_v2" "n3_demo_ssh" {
  name        = "${var.environment_prefix}_n3_demo_ssh"
  description = "ssh rules for n3 terraform demo"
  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

# Now declare security group with http ports open - 80 and 443
resource "openstack_compute_secgroup_v2" "http_group" {
  name        = "${var.environment_prefix}_http_group"
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















# For the fake n3 connection. delete when you have an n3 internet conenction
#resource "openstack_networking_router_interface_v2" "n3_internet_router_interface" {
#  router_id = "${openstack_networking_router_v2.n3_router.id}"
#  subnet_id = "${openstack_networking_subnet_v2.n3_internet_subnet.id}"
#}



# Now connect the router to the network using an interface - but we loop through the 3 subnets to connect them to the router
#resource "openstack_networking_router_interface_v2" "n3_router_interface" {
#  count = "7"
#  router_id = "${openstack_networking_router_v2.n3_router.id}"
#  subnet_id = "${element(openstack_networking_subnet_v2.n3_subnet.*.id, count.index)}"
#}





