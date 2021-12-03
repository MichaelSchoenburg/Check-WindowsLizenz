# Check-WindowsLizenz
Eine Lizenzueberpruefung fuer das N-able RMM

## Grundlegende Funktion:
  Gibt den Windows-Lizenzschluessel aus.
  Prueft, ob Windows lizenziert ist. 
  Gibt aus in wie vielen Tagen die Windows-Testversion auslaeuft.
  Gibt aus wie viele Rearms verbleiben.
    
## Funktion im Solarwinds RMM:
Laeuft, als OK durch, wenn:
- Windows Lizenziert ist.

Laeuft, als fehlgeschlagen durch, wenn:
- Windows nicht lizenziert ist.
- die Windows-Testversion in weniger als oder in sieben Tagen auslaeuft.

Beispiel für die Konfiguration:

<img src=".\Images\Beispiel-Konfiguration.jpg">

Beispiel für eine Fehlermeldung:

<img src=".\Images\Beispiel-Fehler.jpg">

## Wie nutzen?
Check-WindowsLizenz.amp -> Dies ist die AutomationManager-Projektdatei, welche in das N-able RMM Dashboard hochgeladen werden muss.

Check-WindowsLizenz.ps1 -> Dies ist der rohe PowerShell-Code, zwecks einfacherer Bearbeitung und anschließendem Copy and Paste in die Projektdatei - wird für das Projekt nicht benötigt.
