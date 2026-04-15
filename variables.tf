variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "server_count" {
  description = "Anzahl der Webserver"
  type        = number
  default     = 3
}

variable "server_type" {
  description = "Hetzner Server-Typ"
  type        = string
  default     = "cx23"
}

variable "location" {
  description = "Rechenzentrum (nbg1=Nürnberg, fsn1=Falkenstein, hel1=Helsinki)"
  type        = string
  default     = "nbg1"
}

variable "os_image" {
  description = "Betriebssystem-Image"
  type        = string
  default     = "ubuntu-24.04"
}
