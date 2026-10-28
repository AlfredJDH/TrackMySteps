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

Du brauchst einen **Mac mit Xcode** (kostenlos im App Store).

1. [XcodeGen](https://github.com/yonaskolb/XcodeGen) installieren: `brew install xcodegen`
2. Im Projektordner `xcodegen generate` ausführen → `TrackMySteps.xcodeproj` entsteht.
3. Projekt in Xcode öffnen, unter *Signing & Capabilities* Dein Team (Apple-ID) wählen.
   Ggf. die Bundle-ID (`de.familie.trackmysteps`) in etwas Eindeutiges ändern.
4. iPhone per Kabel anschließen, auswählen, ▶︎ drücken. Auf dem iPhone einmalig
   *Einstellungen → Allgemein → VPN & Geräteverwaltung* dem Entwickler vertrauen
   und ggf. den *Entwicklermodus* aktivieren.

**Wichtig zur Verteilung:**
- Mit einer **kostenlosen Apple-ID** läuft die App nur **7 Tage** und muss dann neu von Xcode aufgespielt werden. Für Deine Mutter ist das unpraktisch.
- Mit dem **Apple Developer Program** (99 $/Jahr) läuft sie ein Jahr, oder Du verteilst sie bequem über **TestFlight** (Builds jeweils 90 Tage gültig, Update per Tipp).

## Bekannte Grenzen

- Der Code wurde nicht auf einem Mac kompiliert – beim ersten Bauen können kleine Anpassungen nötig sein.
- Kein App-Icon hinterlegt (Platzhalter in `Assets.xcassets/AppIcon.appiconset`).
- Die Schritte kommen vom iPhone selbst. Sie werden nur gezählt, wenn das Handy **am Körper** getragen wird (Jacken-/Hosentasche ist ideal, Handtasche oder Rollator weniger zuverlässig).
