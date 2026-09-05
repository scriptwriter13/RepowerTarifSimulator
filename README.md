# Repower Tarif-Simulation 2027

Simulation für das Jahr 2027: Was würde Ihr Stromverbrauch (basierend auf alten Verbrauchsdaten) mit den neuen Tarifen kosten?

Rechnungskontrolle im Jahr 2027: Es ermöglicht, anhand der heruntergeladenen Verbrauchsdaten die Rechnungskontrolle.

Dieses Bash-Skript vergleicht und simuliert Stromtarife (Basis, Basis Flex, Optima und Leistung) der Repower für das Jahr 2027. Insbesondere das dynamische **Optima-Modell** wird anhand Ihres Lastgangs stundengenau nach der offiziellen Ampel-Logik (Grün, Gelb, Rot) ausgewertet.

---

## Funktionen

* **Tarifvergleich (`ALL`):** Vergleicht alle verfügbaren Tarife (Basis, Basis Flex, Optima, Leistung) basierend auf Ihren tatsächlichen Lastgangdaten.
* **Detail-Auswertung (Optima):** Zeigt bei gezielter Abfrage des Optima-Tarifs exakt an, wie viel Energie (kWh) und welche Kosten (Energie & Netzarbeit) in den jeweiligen Ampel-Zonen (**Grün**, **Gelb**, **Rot**) angefallen sind.
* **Automatische Skalierung:** Erkennt den Zeitraum der CSV-Datei automatisch und rechnet die Fixkosten (Grundgebühr, Messtarif) taggenau auf das Jahr hoch.
* **Berücksichtigung von Abgaben:** Inklusive gesetzlicher Abgaben, Systemdienstleistungen (SDL), Stromreserve, Netzzuschlag, Gemeindeabgaben und Mehrwertsteuer (8.1%).

---

## Voraussetzungen & Datenaufbereitung

* **Linux / macOS:** Standard-Terminal mit `bash` und `awk`.
* **Windows:** Sie benötigen eine Bash-Umgebung, da es sich um ein Bash-Skript handelt. Empfohlen wird **Git Bash** (wird meist mit *Git for Windows* mitinstalliert) oder das **Windows Subsystem for Linux (WSL)**.
* **Lastgang-Daten (Miaenergia Portal):** 
  Das Skript verarbeitet **viertelstündliche** Messdaten (Lastgänge), die direkt im **Miaenergia Portal** (z. B. für die vergangenen 12 Monate) als **XLSX-Datei** exportiert werden können. 
  Da das Skript eine CSV-Datei erwartet, öffnen Sie den XLSX-Export in einem Tabellenprogramm (wie Microsoft Excel oder LibreOffice Calc) und speichern bzw. exportieren Sie die Datei im Format **CSV**, bevor Sie sie an das Skript übergeben.

---

## Anleitung für Windows-Benutzer

Falls Sie unter Windows arbeiten, führen Sie das Skript am besten über **Git Bash** aus:

1. Laden Sie **Git for Windows** herunter und installieren Sie es (falls noch nicht geschehen).
2. Öffnen Sie den Ordner mit dem Skript und Ihrer CSV-Datei im Windows Explorer.
3. Machen Sie einen **Rechtsklick** in den freien Raum des Ordners und wählen Sie **"Git Bash Here"** aus.
4. Machen Sie das Skript einmalig ausführbar (falls noch nicht geschehen):
   ```bash
   chmod +x simuliereRepowerTarife27.sh

## Kommandozeile


./simuliereRepowerTarife27.sh [Eingabedatei.csv] [Produkt] [Tarif-Typ] [Gemeinde]

Tariftyp ALL erzeugt eine Vergleichsübersicht

Detailansicht Beispiel:

./simuliereRepowerTarife27.sh lastgang.csv GRISCHUNPOWER Optima Malans
