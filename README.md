# Spaziergang (TrackMySteps)

Eine sehr einfache iPhone-App, die bei Spaziergängen **Schritte** (über den Bewegungssensor des iPhones) und den **GPS-Weg** aufzeichnet – ohne Smartwatch, ohne Konto, ohne Cloud. Alle Daten bleiben auf dem iPhone.

## Bedienung

1. **Großer grüner Knopf „Los geht's“** – der Spaziergang startet.
2. Handy einstecken. Schritte und Weg werden auch bei gesperrtem Bildschirm weiter aufgezeichnet.
3. **„Spaziergang beenden“** (mit Sicherheitsabfrage, damit nichts aus Versehen beendet wird).
4. Es erscheint eine Zusammenfassung mit Karte.

Im Reiter **„Meine Spaziergänge“**: Summen für Woche/Monat/Jahr, Balkendiagramm der Schritte, Rekorde und eine Liste aller Spaziergänge mit Karte.

## Technik

| Bereich | Umsetzung |
|---|---|
| Schritte | `CMPedometer` (CoreMotion) – die Schritterkennung des iPhones selbst. Nach dem Beenden wird der gesamte Zeitraum nochmal abgefragt, damit auch Schritte bei gesperrtem Bildschirm vollständig gezählt sind. |
| GPS | `CLLocationManager` mit Hintergrundmodus + `CLBackgroundActivitySession`; ungenaue Punkte (> 25 m) und GPS-Zittern werden verworfen. |
| Speicherung | SwiftData, lokal. Zwischenspeicherung alle 30 s; wird die App während eines Spaziergangs beendet, wird er beim nächsten Start abgeschlossen statt verloren. |
| Oberfläche | SwiftUI, MapKit, Swift Charts. Mindestens iOS 17. |

## Auf das iPhone bringen

Ohne Mac: GitHub baut die App in der Cloud, signiert sie und lädt sie zu TestFlight hoch.
Schritt-für-Schritt: **[ANLEITUNG-TESTFLIGHT.md](ANLEITUNG-TESTFLIGHT.md)**

- `.github/workflows/build.yml` – prüft bei jedem Push, ob die App baut.
- `.github/workflows/testflight.yml` – manuell starten, lädt eine neue Version zu TestFlight hoch.

Mit Mac geht es auch lokal: `brew install xcodegen && xcodegen generate`, dann das Projekt in Xcode öffnen.

## Bekannte Grenzen

- Noch nicht auf einem echten iPhone getestet.
- Die Schritte kommen vom iPhone selbst. Sie werden nur gezählt, wenn das Handy **am Körper** getragen wird (Jacken-/Hosentasche ist ideal, Handtasche oder Rollator weniger zuverlässig).
