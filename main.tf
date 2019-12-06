provider "scaleway" {
  organization = var.scaleway_organization
  token        = var.scaleway_token
  region       = var.scaleway_region
  version      = "~> 1.10"
}

variable "scaleway_organization" {}
variable "scaleway_token" {}
variable "scaleway_region" {}

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

resource "scaleway_server" "k3s_server" {
  image               = data.scaleway_image.bionic.id
  type                = var.server_type
  name                = "${var.prefix}-k3s-server"
  security_group      = scaleway_security_group.k3s_common.id
  dynamic_ip_required = true
  cloudinit           = data.template_file.k3s_server.rendered
  tags                = ["k3s"]
}

resource "scaleway_server" "k3s_agent" {
  count               = var.agent_count
  image               = data.scaleway_image.bionic.id
  type                = var.agent_type
  name                = "${var.prefix}-k3s-agent-${count.index}"
  security_group      = scaleway_security_group.k3s_common.id
  dynamic_ip_required = true
  cloudinit           = data.template_file.k3s_agent.rendered
  tags                = ["k3s"]
}

#===============================================================================
# Security Group
#===============================================================================

resource "scaleway_security_group" "k3s_common" {
  name        = "k3s-common"
  description = "k3s rules"
}

resource "scaleway_security_group_rule" "inbound_smtp_drop_25" {
  security_group = scaleway_security_group.k3s_common.id
  action         = "drop"
  direction      = "inbound"
  ip_range       = "0.0.0.0/0"
  protocol       = "TCP"
  port           = 25
}

resource "scaleway_security_group_rule" "inbound_smtp_drop_465" {
  security_group = scaleway_security_group.k3s_common.id

  action    = "drop"
  direction = "inbound"
  ip_range  = "0.0.0.0/0"
  protocol  = "TCP"
  port      = 465
}

resource "scaleway_security_group_rule" "inbound_smtp_drop_587" {
  security_group = scaleway_security_group.k3s_common.id

  action    = "drop"
  direction = "inbound"
  ip_range  = "0.0.0.0/0"
  protocol  = "TCP"
  port      = 587
}

# [CUSTOM] Closed flannel port 
# See https://github.com/rancher/k3s#open-ports--network-security
# Because we use private_ip as --node-ip(not floating ip), we use them in rules below.

resource "scaleway_security_group_rule" "inbound_flannel_accept_server" {
  security_group = scaleway_security_group.k3s_common.id

  action    = "accept"
  direction = "inbound"
  ip_range  = scaleway_server.k3s_server.private_ip
  protocol  = "UDP"
  port      = 8472
}

resource "scaleway_security_group_rule" "inbound_flannel_accept_agent" {
  security_group = scaleway_security_group.k3s_common.id

  count     = var.agent_count
  action    = "accept"
  direction = "inbound"
  ip_range  = element(scaleway_server.k3s_agent.*.private_ip, count.index)
  protocol  = "UDP"
  port      = 8472
}

locals {
  scaleway_security_groups_flannel_ids = concat(
    [scaleway_security_group_rule.inbound_flannel_accept_server.id],
    scaleway_security_group_rule.inbound_flannel_accept_agent[*].id,
  )
}

resource "null_resource" "sync_flannel_rules" {
  triggers = {
    depends = "${join(",", local.scaleway_security_groups_flannel_ids)}"
  }
}

resource "scaleway_security_group_rule" "inbound_flannel_drop_default" {
  security_group = scaleway_security_group.k3s_common.id

  action    = "drop"
  direction = "inbound"
  ip_range  = "0.0.0.0/0"
  protocol  = "UDP"
  port      = 8472

  depends_on = [null_resource.sync_flannel_rules]
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
    server_url     = "https://${scaleway_server.k3s_server.public_ip}:6443"
  }
}

#===============================================================================
# Output
#===============================================================================

output "k3s_server_url" {
  value = "https://${cloudflare_record.k3s_server.hostname}:6443"
}

output "k3s_server_ip" {
  value = scaleway_server.k3s_server.public_ip
}

output "k3s_agent_ip" {
  value = [scaleway_server.k3s_agent.*.public_ip]
}
