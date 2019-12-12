provider "scaleway" {
  organization_id = var.scaleway_organization
  access_key      = var.scaleway_access_key
  secret_key      = var.scaleway_token
  region          = var.scaleway_region
  zone            = var.scaleway_zone
  version         = "~> 1.13"
}

variable "scaleway_organization" {}
variable "scaleway_access_key" {}
variable "scaleway_token" {}
variable "scaleway_region" {
  default = "fr-par"
}
variable "scaleway_zone" {
  default = "fr-par-1"
}

variable "prefix" {
  default = "cluster"
}

variable "server_type" {
  default = "DEV1-S"
}

variable "agent_count" {
  default = "1"
}

variable "agent_type" {
  default = "DEV1-S"
}

variable "cluster_secret" {}

data "scaleway_image" "bionic" {
  architecture = "x86_64"
  name         = "Ubuntu Bionic"
}

#===============================================================================
# Instances
#===============================================================================

resource "scaleway_instance_server" "k3s_server" {
  image = data.scaleway_image.bionic.id
  type  = var.server_type
  name  = "${var.prefix}-k3s-server"
  tags  = ["k3s"]

  ip_id = scaleway_instance_ip.k3s_server.id

  security_group_id = scaleway_instance_security_group.k3s.id

  cloud_init = data.template_file.k3s_server.rendered
}

resource "scaleway_instance_server" "k3s_agent" {
  count = var.agent_count
  image = data.scaleway_image.bionic.id
  type  = var.agent_type
  name  = "${var.prefix}-k3s-agent-${count.index}"
  tags  = ["k3s"]

  ip_id = scaleway_instance_ip.k3s_agent[count.index].id

  security_group_id = scaleway_instance_security_group.k3s.id

  cloud_init = data.template_file.k3s_agent.rendered
}

#===============================================================================
# IP
#===============================================================================

resource "scaleway_instance_ip" "k3s_server" {}

resource "scaleway_instance_ip" "k3s_agent" {
  count = var.agent_count
}

#===============================================================================
# Security Group
#===============================================================================

resource "scaleway_instance_security_group" "k3s" {
  name = "${var.prefix}-k3s"

  inbound_default_policy  = "accept"
  outbound_default_policy = "accept"

  inbound_rule {
    action   = "drop"
    protocol = "TCP"
    port     = 25
    ip_range = "0.0.0.0/0"
  }

  inbound_rule {
    action   = "drop"
    protocol = "TCP"
    port     = 465
    ip_range = "0.0.0.0/0"
  }

  inbound_rule {
    action   = "drop"
    protocol = "TCP"
    port     = 587
    ip_range = "0.0.0.0/0"
  }

  inbound_rule {
    action   = "accept"
    protocol = "UDP"
    port     = 8472
    ip       = scaleway_instance_ip.k3s_server.address
  }

  dynamic "inbound_rule" {
    for_each = scaleway_instance_ip.k3s_agent.*.address

    content {
      action   = "accept"
      protocol = "UDP"
      port     = 8472
      ip       = inbound_rule.value
    }
  }

  inbound_rule {
    action   = "drop"
    protocol = "UDP"
    port     = 8472
    ip_range = "0.0.0.0/0"
  }
}

#===============================================================================
# Cloud-init
#===============================================================================

data "template_file" "k3s_server" {
  template = file("files/k3s_server.sh")

  vars = {
    cluster_secret = var.cluster_secret
  }
}

data "template_file" "k3s_agent" {
  template = file("files/k3s_agent.sh")

  vars = {
    cluster_secret = var.cluster_secret
    server_url     = "https://${scaleway_instance_server.k3s_server.public_ip}:6443"
  }
}

#===============================================================================
# Output
#===============================================================================

output "k3s_server_url" {
  value = "https://${cloudflare_record.k3s_server.hostname}:6443"
}

output "k3s_server_ip" {
  value = scaleway_instance_server.k3s_server.public_ip
}

output "k3s_agent_ip" {
  value = [scaleway_instance_server.k3s_agent.*.public_ip]
}
