#!/bin/bash

# Farben für die Ausgabe
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funktionen
print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# Überprüfen, ob das Skript als Root ausgeführt wird
if [ "$(id -u)" != "0" ]; then
   print_error "Dieses Skript muss als Root ausgeführt werden" 
   exit 1
fi

print_info "Starte Einrichtung des Automatisierungsservers..."

# GitHub Einstellungen
GITHUB_USERNAME="RaminBanan"  # ÄNDERN Sie dies
GITHUB_REPO="wild-one-automation-docs"    # ÄNDERN Sie dies
GITHUB_TOKEN="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"             # ÄNDERN Sie dies
DOMAIN="wild-one-tattoo.com"              # ÄNDERN Sie dies
SERVER_IP="212.227.60.81"                # ÄNDERN Sie dies

# Sicherheitseinstellungen
WEBHOOK_PASSWORD=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | fold -w 24 | head -n 1)
SECURITY_KEY=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

# Basis-Verzeichnis
PROJECT_DIR="/opt/automation"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# Ordnerstruktur erstellen
print_info "Erstelle Ordnerstruktur..."
mkdir -p nginx/conf.d certs www documents/consume workflows wled-server/data wled-server/firmware docs

# Docker installieren, falls nicht vorhanden
if ! command -v docker &> /dev/null; then
    print_info "Installiere Docker..."
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    systemctl start docker
    systemctl enable docker
    print_success "Docker installiert"
else
    print_info "Docker ist bereits installiert"
fi

# Docker Compose installieren, falls nicht vorhanden
if ! command -v docker-compose &> /dev/null; then
    print_info "Installiere Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/download/v2.20.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    print_success "Docker Compose installiert"
else
    print_info "Docker Compose ist bereits installiert"
fi

# Umgebungsvariablen erstellen
print_info "Erstelle .env-Datei..."
cat > $PROJECT_DIR/.env << EOL
# PostgreSQL
POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

# n8n
N8N_ADMIN_PASSWORD=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | fold -w 24 | head -n 1)
N8N_ENCRYPTION_KEY=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | fold -w 24 | head -n 1)

# Paperless
PAPERLESS_ADMIN_PASSWORD=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | fold -w 24 | head -n 1)
PAPERLESS_SECRET_KEY=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
PAPERLESS_DB_PASSWORD=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | fold -w 24 | head -n 1)
EOL

# Docker Compose Datei erstellen
print_info "Erstelle docker-compose.yml..."
cat > $PROJECT_DIR/docker-compose.yml << EOL
version: '3.8'

networks:
  automation-network:
    driver: bridge
  nginx-network:
    driver: bridge

services:
  # PostgreSQL Datenbank für n8n
  postgres:
    image: postgres:13-alpine
    restart: always
    networks:
      - automation-network
    environment:
      - POSTGRES_USER=n8n_user
      - POSTGRES_PASSWORD=\${POSTGRES_PASSWORD}
      - POSTGRES_DB=n8n
    volumes:
      - postgres-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U n8n_user -d n8n"]
      interval: 10s
      timeout: 5s
      retries: 5

  # n8n Automatisierungsplattform
  n8n:
    image: n8nio/n8n:latest
    restart: always
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - automation-network
      - nginx-network
    environment:
      - N8N_HOST=n8n.${DOMAIN}
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_USER=n8n_user
      - DB_POSTGRESDB_PASSWORD=\${POSTGRES_PASSWORD}
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=\${N8N_ADMIN_PASSWORD}
      - N8N_ENCRYPTION_KEY=\${N8N_ENCRYPTION_KEY}
      - WEBHOOK_URL=http://${SERVER_IP}:5678/
      - EXECUTIONS_PROCESS=main
      - GENERIC_TIMEZONE=Europe/Berlin
      - N8N_EDITOR_BASE_URL=http://${SERVER_IP}:5678
    ports:
      - "5678:5678"
    volumes:
      - n8n-data:/home/node/.n8n
      - ./workflows:/home/node/.n8n/workflows

  # Nginx Reverse Proxy
  nginx:
    image: nginx:alpine
    restart: always
    networks:
      - nginx-network
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./certs:/etc/nginx/certs
      - ./www:/var/www/html
    depends_on:
      - n8n

volumes:
  postgres-data:
  n8n-data:
EOL

# Nginx-Konfigurationsdatei erstellen
print_info "Erstelle Nginx-Konfiguration..."
cat > $PROJECT_DIR/nginx/conf.d/default.conf << EOL
# Default Server
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN} www.${DOMAIN} n8n.${DOMAIN};

    location / {
        root /var/www/html;
        index index.html;
    }
}

# n8n Proxy (für direkten Zugriff, falls die n8n-Domain nicht eingerichtet ist)
server {
    listen 80;
    server_name ${SERVER_IP};

    location / {
        proxy_pass http://n8n:5678;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Websocket Unterstützung
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts erhöhen
        proxy_read_timeout 90;
        proxy_connect_timeout 90;
        proxy_send_timeout 90;
    }
}
EOL

# Startseite erstellen
print_info "Erstelle einfache Startseite..."
cat > $PROJECT_DIR/www/index.html << EOL
<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Automatisierungsserver - Wild One Tattoo</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 0;
            color: #333;
            background-color: #f4f4f4;
        }
        .container {
            width: 80%;
            margin: auto;
            overflow: hidden;
            padding: 20px;
        }
        header {
            background: #333;
            color: #fff;
            padding: 20px 0;
            text-align: center;
        }
        header h1 {
            margin: 0;
        }
        footer {
            background: #333;
            color: #fff;
            text-align: center;
            padding: 10px;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <header>
        <div class="container">
            <h1>Automatisierungsserver</h1>
            <p>Wild One Tattoo</p>
        </div>
    </header>
    
    <div class="container">
        <h2>Dienste</h2>
        <ul>
            <li><a href="http://${SERVER_IP}:5678" target="_blank">n8n - Automatisierungsplattform</a></li>
        </ul>
    </div>
    
    <footer>
        <div class="container">
            <p>&copy; 2025 Wild One Tattoo - Automatisierungsserver</p>
        </div>
    </footer>
</body>
</html>
EOL

# GitHub-Update-Workflow-Datei erstellen
print_info "Erstelle n8n-Workflow für GitHub-Updates..."
mkdir -p $PROJECT_DIR/workflows
cat > $PROJECT_DIR/workflows/github-update.json << EOL
{
  "name": "GitHub-Dokumentation-Update",
  "nodes": [
    {
      "parameters": {
        "path": "github-doc-update",
        "responseMode": "lastNode",
        "options": {
          "rawBody": true
        },
        "authentication": "basicAuth",
        "httpBasicAuth": {
          "user": "admin",
          "password": "${WEBHOOK_PASSWORD}"
        }
      },
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 1,
      "position": [
        250,
        300
      ]
    },
    {
      "parameters": {
        "functionCode": "const { file, content, message, key } = $input.body;\n\nif (!file || !content || !message) {\n  return { success: false, error: \"Fehlende Pflichtfelder\" };\n}\n\nconst validKey = \"${SECURITY_KEY}\";\nif (key !== validKey) {\n  return { success: false, error: \"Ungültiger Sicherheitsschlüssel\" };\n}\n\nreturn {\n  file: file,\n  content: content,\n  message: message\n};"
      },
      "name": "Anfrage validieren",
      "type": "n8n-nodes-base.function",
      "typeVersion": 1,
      "position": [
        470,
        300
      ]
    },
    {
      "parameters": {
        "url": "=https://api.github.com/repos/${GITHUB_USERNAME}/${GITHUB_REPO}/contents/{{$node[\"Anfrage validieren\"].json[\"file\"]}}",
        "authentication": "basicAuth",
        "userName": "${GITHUB_USERNAME}",
        "password": "${GITHUB_TOKEN}"
      },
      "name": "Get SHA",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 3,
      "position": [
        690,
        300
      ]
    },
    {
      "parameters": {
        "url": "=https://api.github.com/repos/${GITHUB_USERNAME}/${GITHUB_REPO}/contents/{{$node[\"Anfrage validieren\"].json[\"file\"]}}",
        "method": "PUT",
        "authentication": "basicAuth",
        "userName": "${GITHUB_USERNAME}",
        "password": "${GITHUB_TOKEN}",
        "jsonParameters": true,
        "options": {},
        "bodyParametersJson": "{\n  \"message\": \"{{$node[\\\"Anfrage validieren\\\"].json[\\\"message\\\"]}}\",\n  \"content\": \"{{Buffer.from($node[\\\"Anfrage validieren\\\"].json[\\\"content\\\"]).toString('base64')}}\",\n  \"sha\": \"{{$node[\\\"Get SHA\\\"].json[\\\"sha\\\"]}}\"\n}"
      },
      "name": "GitHub Update",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 3,
      "position": [
        910,
        300
      ]
    }
  ],
  "connections": {
    "Webhook": {
      "main": [
        [
          {
            "node": "Anfrage validieren",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Anfrage validieren": {
      "main": [
        [
          {
            "node": "Get SHA",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Get SHA": {
      "main": [
        [
          {
            "node": "GitHub Update",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  },
  "active": true
}
EOL

# API-Schlüssel Dokumentation erstellen
print_info "Erstelle API-Schlüssel-Datei..."
cat > $PROJECT_DIR/docs/api-keys.env << EOL
# API-Schlüssel für Automatisierungsserver
# WARNUNG: Diese Datei enthält sensible Daten - Zugriff einschränken!
# Erstellt: $(date +"%d.%m.%Y")

# GitHub Update Webhook
GITHUB_UPDATE_URL=http://${SERVER_IP}:5678/webhook/github-doc-update
GITHUB_UPDATE_USERNAME=admin
GITHUB_UPDATE_PASSWORD=${WEBHOOK_PASSWORD}
GITHUB_UPDATE_KEY=${SECURITY_KEY}

# Claude AI (Anthropic)
ANTHROPIC_API_KEY=your_key_here

# OpenAI (ChatGPT)
OPENAI_API_KEY=your_key_here
EOL

# Zugriffsrechte einschränken
chmod 600 $PROJECT_DIR/docs/api-keys.env

# GitHub-Zugriffsdokumentation erstellen
print_info "Erstelle GitHub-Zugriffsdokumentation..."
cat > $PROJECT_DIR/docs/github-access.md << EOL
# GitHub Repository Zugriff

## Repository Details
- Repository-URL: https://github.com/${GITHUB_USERNAME}/${GITHUB_REPO}
- Branch: main

## Webhook Details
- Webhook-URL: http://${SERVER_IP}:5678/webhook/github-doc-update
- Authentifizierung: Basic Auth (Username/Password)
- Benutzername: admin
- Passwort: ${WEBHOOK_PASSWORD}
- Sicherheitsschlüssel: ${SECURITY_KEY}

## Beispiel für Update-Anfrage
\`\`\`bash
curl -X POST http://${SERVER_IP}:5678/webhook/github-doc-update \\
  -u "admin:${WEBHOOK_PASSWORD}" \\
  -H "Content-Type: application/json" \\
  -d '{
    "file": "README.md",
    "content": "# Neuer Inhalt der README-Datei\\n\\nAktualisiert durch Claude/ChatGPT.",
    "message": "Update README.md durch AI",
    "key": "${SECURITY_KEY}"
  }'
\`\`\`

## Hinweise für Claude und ChatGPT
- Beim Aktualisieren von Dateien müssen alle Parameter (file, content, message, key) angegeben werden
- Der Sicherheitsschlüssel ist erforderlich und muss in jeder Anfrage enthalten sein
- Für Markdown-Dateien (.md) und Shell-Skripte (.sh) muss der gesamte Dateiinhalt gesendet werden
EOL

# Docker starten
print_info "Starte Docker Container..."
cd $PROJECT_DIR
docker-compose up -d

# Fertigstellungsmeldung
print_success "=============================================="
print_success "Automatisierungsserver-Setup abgeschlossen!"
print_success "=============================================="
print_info "n8n ist erreichbar unter: http://${SERVER_IP}:5678"
print_info "Zugangsdaten für n8n:"
print_info "  Benutzername: admin"
print_info "  Passwort: $(grep N8N_ADMIN_PASSWORD $PROJECT_DIR/.env | cut -d '=' -f2)"
print_info ""
print_info "GitHub-Update-Webhook-Details:"
print_info "  URL: http://${SERVER_IP}:5678/webhook/github-doc-update"
print_info "  Benutzername: admin"
print_info "  Passwort: ${WEBHOOK_PASSWORD}"
print_info "  Sicherheitsschlüssel: ${SECURITY_KEY}"
print_info ""
print_info "Passen Sie bitte folgende Einstellungen in den Dateien an:"
print_info "1. GitHub-Benutzername, Repository und Token in der Workflow-Datei"
print_info "2. Domain-Namen in der nginx-Konfiguration"
print_info ""
print_info "Dokumentation wurde erstellt unter: ${PROJECT_DIR}/docs/"
print_info "Sie können den Webhook nach der Einrichtung mit folgendem Befehl testen:"
print_info "curl -X POST http://${SERVER_IP}:5678/webhook/github-doc-update \\"
print_info "  -u \"admin:${WEBHOOK_PASSWORD}\" \\"
print_info "  -H \"Content-Type: application/json\" \\"
print_info "  -d '{ \"file\": \"test.md\", \"content\": \"# Test\\n\\nDies ist ein Test.\", \"message\": \"Test-Commit\", \"key\": \"${SECURITY_KEY}\" }'"