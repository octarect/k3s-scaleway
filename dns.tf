variable "cloudflare_email" {}

variable "cloudflare_token" {}

variable "cloudflare_zone" {}

variable "cloudflare_hostname" {}

provider "cloudflare" {
  email = "${var.cloudflare_email}"
  token = "${var.cloudflare_token}"
}

resource "cloudflare_record" "k3s_server" {
  domain = "${var.cloudflare_zone}"
  name   = "${var.cloudflare_hostname}"
  value  = "${scaleway_instance_server.k3s_server.public_ip}"
  type   = "A"
  ttl    = 3600
}
