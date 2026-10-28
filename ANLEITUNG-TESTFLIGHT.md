# Anleitung: Die App auf das iPhone Deiner Mutter bringen

Alles geht im Browser – kein Mac nötig. Rechne mit etwa einer Stunde (plus Wartezeit bei Apple).

---

## Teil 1 – Apple-Entwicklerkonto (einmalig)

- [ ] **1.1** Auf <https://developer.apple.com/programs/enroll/> mit Deiner Apple-ID als **Einzelperson („Individual“)** anmelden und die 99 $ bezahlen.
  Apple prüft das, das kann bis zu 48 Stunden dauern. Du bekommst eine E-Mail.
- [ ] **1.2** Auf <https://developer.apple.com/account> unter **„Mitgliedschaftsdetails“** die **Team-ID** notieren (10 Zeichen, z. B. `AB12CD34EF`).

## Teil 2 – Die App bei Apple anmelden

- [ ] **2.1** <https://developer.apple.com/account/resources/identifiers/list> → **„+“** → **App IDs** → **App** → Weiter.
  - Beschreibung: `Spaziergang`
  - Bundle ID: **Explicit** → `io.github.alfredjdh.trackmysteps` (genau so!)
  - Bei „Capabilities“ nichts ankreuzen → **Register**.
- [ ] **2.2** <https://appstoreconnect.apple.com/apps> → **„+“** → **Neue App**
  - Plattform: **iOS**
  - Name: z. B. `Spaziergang für Mama` (muss im ganzen App Store einmalig sein – sieht aber nur Ihr)
  - Primäre Sprache: **Deutsch**
  - Bundle-ID: die eben angelegte auswählen
  - SKU: beliebig, z. B. `spaziergang1`
  - Benutzerzugriff: Uneingeschränkt → **Erstellen**

## Teil 3 – Schlüssel für GitHub erstellen

- [ ] **3.1** <https://appstoreconnect.apple.com/access/integrations/api> → ggf. „Zugriff anfordern“ bestätigen → **Team-Schlüssel** → **„+“**
  - Name: `GitHub`
  - Zugriff: **Admin** (nötig, damit Apple das Signier-Zertifikat selbst verwalten kann)
- [ ] **3.2** Notieren: **Key ID** (in der Tabelle) und **Issuer ID** (steht über der Tabelle).
- [ ] **3.3** **„API-Schlüssel laden“** → Du bekommst eine Datei `AuthKey_XXXXXXXXXX.p8`.
  ⚠️ Die kann man **nur einmal** herunterladen. Gut aufbewahren und niemandem geben – wer sie hat, kann in Deinem Namen Apps hochladen.

## Teil 4 – Schlüssel bei GitHub hinterlegen

- [ ] **4.1** <https://github.com/AlfredJDH/TrackMySteps/settings/secrets/actions> → **„New repository secret“**, viermal:

  | Name | Inhalt |
  |---|---|
  | `APPLE_TEAM_ID` | Team-ID aus 1.2 |
  | `ASC_KEY_ID` | Key ID aus 3.2 |
  | `ASC_ISSUER_ID` | Issuer ID aus 3.2 |
  | `ASC_KEY_P8` | Den **kompletten Inhalt** der `.p8`-Datei (mit einem Texteditor öffnen, alles kopieren inkl. `-----BEGIN PRIVATE KEY-----` und `-----END PRIVATE KEY-----`) |

  Secrets sind verschlüsselt und auch in einem öffentlichen Repository für niemanden sichtbar.

## Teil 5 – App bauen und hochladen

- [ ] **5.1** <https://github.com/AlfredJDH/TrackMySteps/actions/workflows/testflight.yml> → **„Run workflow“** → Branch wählen → **„Run workflow“**.
- [ ] **5.2** Nach ca. 5 Minuten sollte ein grüner Haken erscheinen. Bei einem roten Kreuz: Sag mir Bescheid, dann schaue ich mir das an.
- [ ] **5.3** Apple verarbeitet den Build noch ca. 10–30 Minuten. Danach ist er in App Store Connect unter **Deine App → TestFlight** sichtbar.

## Teil 6 – Deine Mutter einladen

- [ ] **6.1** In App Store Connect → Deine App → **TestFlight** → links bei „Externes Testen“ **„+“** → Gruppe `Familie` anlegen.
- [ ] **6.2** In der Gruppe: **Tester hinzufügen** → E-Mail-Adresse Deiner Mutter (die mit ihrer Apple-ID verknüpft ist).
- [ ] **6.3** **Build hinzufügen** → den hochgeladenen Build wählen. Beim ersten Mal fragt Apple nach Testinformationen:
  - Was soll getestet werden: `Spaziergänge aufzeichnen und ansehen.`
  - Feedback-E-Mail: Deine E-Mail
  - Anmeldung erforderlich: **Nein**
- [ ] **6.4** Zur **Beta-Prüfung einreichen**. Apple prüft das erste Mal, meist innerhalb eines Tages.

## Teil 7 – Auf dem iPhone Deiner Mutter

- [ ] **7.1** Aus dem App Store die kostenlose App **„TestFlight“** (von Apple) installieren.
- [ ] **7.2** Die Einladungs-E-Mail öffnen → **„Testen starten“** → in TestFlight auf **„Installieren“** tippen.
- [ ] **7.3** App öffnen → **Weiter** → beide Male **„Erlauben“** tippen.
  Beim Standort **„Beim Verwenden der App erlauben“** wählen – das reicht, auch bei gesperrtem Bildschirm.
- [ ] **7.4** Tipp: Die App auf den ersten Home-Bildschirm legen, den TestFlight-Ordner dagegen eher wegschieben.

---

## Später: Updates und Ablauf

- **Neue Version:** Nach jeder Änderung einfach Schritt 5.1 wiederholen. Die App aktualisiert sich bei Deiner Mutter automatisch (sofern in TestFlight „Automatische Updates“ an ist).
- **Wichtig – 90 Tage:** Jeder TestFlight-Build läuft nach 90 Tagen ab. **Trag Dir alle 2 Monate eine Erinnerung ein**, Schritt 5.1 auszuführen. Das dauert eine Minute.
  Wenn Dir das auf Dauer lästig ist, ist der nächste Schritt eine „nicht gelistete“ App im App Store – die läuft nicht ab.
