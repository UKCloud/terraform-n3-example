# Define internet_dmz network
resource "openstack_networking_network_v2" "internet_dmz" {
  name           = "internet_dmz"
  admin_state_up = "true"
}

# Create a subnet for internet_dmz network
resource "openstack_networking_subnet_v2" "internet_dmz" {
  name       = "internet_dmz"
  network_id = "${openstack_networking_network_v2.internet_dmz.id}"
  cidr       = "172.16.0.0/24"
  ip_version = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

# Define a router to connect to the internet
resource "openstack_networking_router_v2" "www" {
  name             = "${var.internet_router_name}"
  external_gateway = "${var.external_gateway}"
}

# Now connect the www router to the www_dmz network using an interface
resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = "${openstack_networking_router_v2.www.id}"
  subnet_id = "${openstack_networking_subnet_v2.internet_dmz.id}"
}

# Now connect the n3 router to the n3_dmz network using an interface
resource "openstack_networking_router_interface_v2" "router_interface_2" {
  router_id = "${openstack_networking_router_v2.n3.id}"
  subnet_id = "${openstack_networking_subnet_v2.n3_dmz.id}"
}

# Now connect the n3 router to the n3_app network using an interface
resource "openstack_networking_router_interface_v2" "router_interface_3" {
  router_id = "${openstack_networking_router_v2.n3.id}"
  subnet_id = "${openstack_networking_subnet_v2.n3_app.id}"
}

# Define our N3_DMZ network
resource "openstack_networking_network_v2" "n3_dmz" {
  name           = "n3_dmz"
  admin_state_up = "true"
}

# Create a subnet for n3_dmz network
resource "openstack_networking_subnet_v2" "n3_dmz" {
  name       = "n3_dmz"
  network_id = "${openstack_networking_network_v2.n3_dmz.id}"
  cidr       = "172.16.1.0/24"
  ip_version = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

# Define our n3_app network
resource "openstack_networking_network_v2" "n3_app" {
  name           = "n3_app"
  admin_state_up = "true"
}

# Create a subnet for n3_app network
resource "openstack_networking_subnet_v2" "n3_app" {
  name       = "n3_app"
  network_id = "${openstack_networking_network_v2.n3_app.id}"
  cidr       = "172.16.2.0/24"
  ip_version = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

# Define a router to connect to the n3 
resource "openstack_networking_router_v2" "n3" {
  name             = "${var.n3_router_name}"
  #external_gateway = "${var.n3_gateway}"
}
