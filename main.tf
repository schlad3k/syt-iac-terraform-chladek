# ── SSH Key ────────────────────────────────────────────────────
resource "hcloud_ssh_key" "default" {
  name       = "terraform-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}

# ── Internes Netzwerk ─────────────────────────────────────────
resource "hcloud_network" "internal" {
  name     = "webserver-network"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "subnet" {
  network_id   = hcloud_network.internal.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

# ── Firewall ──────────────────────────────────────────────────
resource "hcloud_firewall" "web" {
  name = "web-firewall"

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

# ── Webserver (3 Stück) ───────────────────────────────────────
resource "hcloud_server" "web" {
  count        = var.server_count
  name         = "web-${count.index + 1}"
  server_type  = var.server_type
  image        = var.os_image
  location     = var.location
  ssh_keys     = [hcloud_ssh_key.default.id]
  firewall_ids = [hcloud_firewall.web.id]

  user_data = templatefile("${path.module}/cloud-init.yaml", {
    server_name   = "web-${count.index + 1}"
    server_number = count.index + 1
  })

  network {
    network_id = hcloud_network.internal.id
  }

  depends_on = [hcloud_network_subnet.subnet]
}

# ── Load Balancer ─────────────────────────────────────────────
resource "hcloud_load_balancer" "web" {
  name               = "web-lb"
  load_balancer_type = "lb11"
  location           = var.location
  algorithm {
    type = "round_robin"
  }
}

resource "hcloud_load_balancer_network" "web" {
  load_balancer_id = hcloud_load_balancer.web.id
  network_id       = hcloud_network.internal.id
}

resource "hcloud_load_balancer_service" "http" {
  load_balancer_id = hcloud_load_balancer.web.id
  protocol         = "http"
  listen_port      = 80
  destination_port = 80

  health_check {
    protocol = "http"
    port     = 80
    interval = 10
    timeout  = 5
    retries  = 3

    http {
      path         = "/"
      status_codes = ["2??", "3??"]
    }
  }
}

resource "hcloud_load_balancer_target" "web" {
  count            = var.server_count
  load_balancer_id = hcloud_load_balancer.web.id
  type             = "server"
  server_id        = hcloud_server.web[count.index].id
  use_private_ip   = false
}
