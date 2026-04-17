# SYT10 — Infrastructure as Code mit Terraform

Automatische Provisionierung von 3 Webservern hinter einem Load Balancer auf Hetzner Cloud.

## Architektur

```
                    ┌──────────────────┐
                    │   Load Balancer  │
          Internet ─►   (HTTP :80)    │
                    └──────┬───────────┘
                           │ Round Robin
              ┌────────────┼────────────┐
              ▼            ▼            ▼
        ┌──────────┐ ┌──────────┐ ┌──────────┐
        │  web-1   │ │  web-2   │ │  web-3   │
        │  nginx   │ │  nginx   │ │  nginx   │
        │  cx22    │ │  cx22    │ │  cx22    │
        └──────────┘ └──────────┘ └──────────┘
              │            │            │
              └────────────┼────────────┘
                    10.0.1.0/24
                  Internes Netzwerk
```

## Voraussetzungen

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- [Hetzner Cloud Account](https://console.hetzner.cloud)
- SSH Key (`~/.ssh/id_ed25519.pub`)

## Hetzner Cloud einrichten

1. Account erstellen auf https://console.hetzner.cloud
2. Neues Projekt anlegen (z.B. "SYT-IaC")
3. API Token generieren: **Security → API Tokens → Generate API Token** (Read/Write)
4. Token kopieren

## Deployment

```bash
# 1. Terraform initialisieren
terraform init

# 2. Token setzen
export TF_VAR_hcloud_token="dein-api-token-hier"

# 3. Plan anzeigen (was wird erstellt?)
terraform plan

# 4. Infrastruktur erstellen
terraform apply

# 5. Load Balancer URL öffnen
terraform output url
```

## Testen

Nach dem Deployment (ca. 2 Minuten) zeigt `terraform output` die Load Balancer IP.
Im Browser öffnen — bei jedem Reload antwortet ein anderer Server.

```bash
# Einzelne Server testen
curl http://$(terraform output -raw load_balancer_ip)

# Mehrfach aufrufen → verschiedene Server antworten
for i in 1 2 3 4 5; do
  curl -s http://$(terraform output -raw load_balancer_ip) | grep "<h1>"
done
```

## Aufräumen

```bash
# Alle Ressourcen wieder löschen (keine Kosten mehr)
terraform destroy
```

## Kosten

| Ressource | Typ | Preis |
|---|---|---|
| 3× Server | cx22 | 3 × €3,29/Monat |
| 1× Load Balancer | lb11 | €5,39/Monat |
| **Gesamt** | | **~€15,26/Monat** |

Nach dem Test mit `terraform destroy` sofort löschen um Kosten zu vermeiden.

## Dateien

| Datei | Beschreibung |
|---|---|
| `providers.tf` | Terraform + Hetzner Provider |
| `variables.tf` | Konfigurierbare Parameter |
| `main.tf` | Server, Load Balancer, Netzwerk, Firewall |
| `outputs.tf` | Ausgaben (IPs, URL) |
| `cloud-init.yaml` | Server-Konfiguration (nginx + HTML) |
