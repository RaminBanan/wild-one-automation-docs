# Automatisierungsserver - Wild One Tattoo

Diese README enthält die wichtigsten Informationen zum Automatisierungsserver. Alle wichtigen Konfigurationsdateien, Passwörter und Referenzen sind in diesem Dokument oder den verlinkten Dateien zu finden.

## Wichtige Pfade

| Beschreibung | Pfad |
|-------------|------|
| Hauptdokumentation | `/opt/automation/docs/server-documentation.md` |
| API-Schlüssel | `/opt/automation/docs/api-keys.env` |
| Backup-Script | `/opt/automation/docs/backup.sh` |
| Monitoring-Script | `/opt/automation/docs/monitor.sh` |

## Schnellzugriff

- Für schnellen Zugriff auf alle Dokumentationsdateien wurde ein Symlink erstellt: `/root/automation-docs`
- Die vollständige Serverinstallation kann mit dem folgenden Befehl gestartet werden:

```bash
cd /opt/automation
docker-compose up -d

Wichtigste Dienste
DienstURLStandard-Zugangsdatenn8nhttps://n8n.wild-one-tattoo.comadmin / siehe .env-DateiPaperlesshttps://docs.wild-one-tattoo.comadmin / siehe .env-DateiWLED-Serverhttps://wled.wild-one-tattoo.comkeine Authentifizierung
Automatisierte Tasks

Backups: Täglich um 3:00 Uhr wird ein vollständiges Backup unter /opt/backup erstellt
Monitoring: Alle 15 Minuten wird der Server-Status überprüft
Zertifikate: Werden automatisch durch Certbot erneuert (alle 90 Tage)

Wichtige Befehle
# Server-Status prüfen
cd /opt/automation && docker-compose ps

# Logs anzeigen
cd /opt/automation && docker-compose logs -f [service_name]

# Manuelles Backup erstellen
/opt/automation/docs/backup.sh

# Monitoring ausführen
/opt/automation/docs/monitor.sh

Wartung und Updates
Um den Server zu aktualisieren:
cd /opt/automation
docker-compose pull
docker-compose up -d

Weiterführende Dokumentation
Die vollständige Dokumentation finden Sie in der Hauptdokumentationsdatei:
/opt/automation/docs/server-documentation.md
