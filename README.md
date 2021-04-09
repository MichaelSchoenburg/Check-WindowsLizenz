# Check-WindowsLizenz
Lizenzueberpruefung fuer das Solarwinds RMM

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
