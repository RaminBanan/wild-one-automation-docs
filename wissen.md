Hier sollen Beschreibungen reingeschrieben werden, die KIshelfen zu lernen

Hier ist dein erster Eintrag für die `wissen.md`, den du direkt als funktionierendes Beispiel übernehmen kannst:

```markdown
## 🔹 Wissen und wichtige Erkenntnisse zum Automatisierungssystem (Stand 14.03.2025)

### SSH-Zugang zum Ubuntu-Server bei Strato (Passwort & Schlüssel)

- ✅ Passwort-Login aktiviert:
  - Bearbeiten der Datei `/etc/ssh/sshd_config`
  ```bash
  PasswordAuthentication yes
  ```
  - Anschließend SSH-Dienst neu starten:
  ```bash
  service ssh restart
  ```
  - **Achtung:** Strato bietet **keinen** direkten Passwort-Reset über das Kunden-Webinterface an. Passwortänderung nur möglich, wenn bereits per SSH eingeloggt.

---

## 🔸 Docker-Befehle nur auf Ubuntu-Server ausführbar
- Docker-Befehle funktionieren nicht direkt im Mac-Terminal, da Docker dort nicht läuft.
- Docker-Container und Befehle müssen **immer per SSH auf dem Ubuntu-Server** ausgeführt werden:
```bash
ssh root@212.227.60.81
```

---

## 🔸 Verbindung zwischen Docker-n8n und lokalem Python-Server herstellen
- 🔴 **Problem:** Verbindung zu „localhost“ oder „127.0.0.1“ scheitert im Docker-Container, da Container standardmäßig eigene Netzwerkumgebung nutzt.
- ✅ **Lösung:** Docker-Container im Host-Netzwerkmodus starten:
```bash
docker run -d --network host --name n8n n8n/n8n:latest
```
- Danach ist Zugriff auf den lokalen Server unter `127.0.0.1:8080` problemlos möglich.

---

## 🔹 Wichtige Dateien und Pfade
- Passwort- und Schlüssel-Dateien sowie sonstige Zugangsdaten werden zentral hier gespeichert:
  - [GitHub Repository](https://github.com/RaminBanan/wild-one-automation-docs)
  - Ordner: `/config`

## Strato-Server Rescue-Modus

- 🔴 Standardmäßig läuft das Strato Rescue-System im **Read-Only-Modus**. Änderungen sind temporär und gehen verloren.
- ✅ **Endgültige, richtige Vorgehensweise:**  
  1. Mit **GParted** (Grafiktool) gewünschte Linux-Partition dauerhaft einhängen (Mount mit Schreibrechten).  
  2. Danach per Terminal `chroot /mnt` nutzen und Passwörter oder Einstellungen setzen.
  3. Änderungen werden jetzt dauerhaft gespeichert und bleiben erhalten.
 


Hier ist eine vollständige Dokumentation für dein n8n-Setup, die zur Ergänzung der wissen.md auf GitHub verwendet werden kann:

# n8n Server-Konfiguration

## Server-Details
- **IP-Adresse**: 212.227.60.81
- **Hosting-Provider**: Strato (VPS Linux VC1-1)
- **Betriebssystem**: Ubuntu 24.04.2 LTS

## Installationsverzeichnisse
- **Hauptverzeichnis**: `/opt/automation`
- **Workflow-Verzeichnis**: `/opt/automation/workflows`
- **Docker-Compose-Datei**: `/opt/automation/docker-compose.yml`

## n8n-Konfiguration
- **URL**: http://212.227.60.81
- **Ursprünglicher Port**: 5678 (nicht von außen erreichbar)
- **Aktueller Port**: 80 (nach außen freigegeben)
- **Login-Daten**:
  - **Benutzername**: raminbanan@gmx.de
  - **Passwort**: ryrryt-bEbhak-5vumby

## Datenbank-Konfiguration
- **Datenbank-Typ**: PostgreSQL
- **Container-Name**: automation-postgres-1
- **Datenbank**: n8n
- **Benutzer**: n8n_user
- **Passwort**: DeinNeuesPasswort
- **Port**: 5432

## Docker-Setup
- **Container-Namen**:
  - n8n: automation-n8n-1
  - PostgreSQL: automation-postgres-1
  - Nginx: automation-nginx-1
- **Netzwerke**:
  - automation_automation-network
  - automation_nginx-network

## Docker-Container-Start-Befehl
```bash
docker run -d --name automation-n8n-1 \
  --network automation_automation-network \
  -p 80:5678 \
  -e N8N_PROTOCOL=http \
  -e N8N_PORT=5678 \
  -e N8N_SECURE_COOKIE=false \
  -e DB_TYPE=postgresdb \
  -e DB_POSTGRESDB_HOST=postgres \
  -e DB_POSTGRESDB_PORT=5432 \
  -e DB_POSTGRESDB_DATABASE=n8n \
  -e DB_POSTGRESDB_USER=n8n_user \
  -e DB_POSTGRESDB_PASSWORD=DeinNeuesPasswort \
  -e N8N_BASIC_AUTH_ACTIVE=true \
  -e N8N_BASIC_AUTH_USER=raminbanan@gmx.de \
  -e N8N_BASIC_AUTH_PASSWORD=ryrryt-bEbhak-5vumby \
  n8nio/n8n:latest
```

## Aktive Workflows
1. GitHub-Dokumentation-Update (ID: uE637KZCGeSqgpxq)
2. GitHub-Dokument-Verarbeitung (ID: IxYjvHeS7EKa77vk)

## Wichtige Hinweise
- Die systemweite Nginx-Installation wurde deaktiviert (sie verursachte Portkonflikte)
- Die Strato-Firewall ist deaktiviert
- Der ursprüngliche Port 5678 war blockiert, daher die Umleitung auf Port 80
- Der n8n-Container ist so konfiguriert, dass er HTTP statt HTTPS verwendet

## Fehlerbehebung
Falls n8n nicht erreichbar ist:
1. Überprüfe, ob die Container laufen: `docker ps`
2. Prüfe die n8n-Logs: `docker logs automation-n8n-1`
3. Stelle sicher, dass der Port freigegeben ist: `netstat -tuln | grep 80`
4. Wenn nötig, starte den Container mit dem oben genannten Befehl neu

## Zugriff auf den Server
```bash
ssh root@212.227.60.81
```

Diese Dokumentation enthält alle wichtigen Informationen, um das n8n-Setup bei Bedarf zu rekonstruieren oder zu warten. Sie kann in die wissen.md-Datei im GitHub-Repository eingefügt werden.

Zusammenfassung dessen, was wir heute erreicht haben:

Wir haben die ursprüngliche Konfiguration analysiert und festgestellt, dass:

Die systemweite Nginx-Installation Konflikte verursachte
Der n8n-Container auf HTTPS konfiguriert war, ohne entsprechende Unterstützung
Port 5678 von außen nicht erreichbar war


Wir haben die Probleme behoben, indem wir:

Die systemweite Nginx-Installation deaktiviert haben
Den n8n-Container auf HTTP umgestellt haben
Die Port-Konfiguration auf 80:5678 geändert haben
N8N_SECURE_COOKIE auf false gesetzt haben
Die korrekten Volume-Mounts konfiguriert haben


Die docker-compose.yml-Datei wurde korrigiert, um sicherzustellen, dass:

Die Konfiguration dauerhaft ist
Alle Container korrekt miteinander kommunizieren
Die Workflows erhalten bleiben



Dein n8n-Setup ist jetzt stabil und sollte auch nach einem Serverneustart richtig funktionieren. Du kannst jetzt deine Automatisierungsworkflows nutzen und erweitern.

## 🔸 Aktueller Status des GitHub-Dokument-Verarbeitung Workflows

- 🔴 **Wichtiger Hinweis:** Der in der ursprünglichen Dokumentation erwähnte Python-Server auf Port 8080 ist aktuell nicht eingerichtet.
- Der Workflow "GitHub-Dokument-Verarbeitung" enthält eine HTTP-Request-Node, die versucht, mit `http://127.0.0.1:8080/pending-updates.json` zu kommunizieren.
- Diese Verbindung schlägt fehl, da kein entsprechender Server läuft.

### Lösungsoptionen:
1. **Empfohlen:** Workflow ohne lokalen Python-Server neu gestalten
   - Direkte Kommunikation mit GitHub über die integrierten GitHub-Nodes
   - Verwendung von GitHub Webhooks für ereignisbasierte Auslöser
   - Verarbeitung direkt innerhalb von n8n mit JavaScript-Code

2. **Alternative:** Python-Server einrichten, falls spezielle Verarbeitungslogik benötigt wird
   - Server muss auf allen Interfaces (0.0.0.0) hören, nicht nur auf localhost
   - Bei Verwendung des Python-Servers mit Docker muss die docker-compose.yml entsprechend konfiguriert sein
