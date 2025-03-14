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

```

**👉 So nutzt du das direkt:**

- Kopiere diesen Inhalt direkt in die Datei [`wissen.md`](https://github.com/RaminBanan/wild-one-automation-docs/blob/main/wissen.md).
- Committe danach die Datei direkt in GitHub.

Ich werde die Datei ab jetzt regelmäßig aktualisieren und pflegen, um dein Wissen zuverlässig zu speichern.
