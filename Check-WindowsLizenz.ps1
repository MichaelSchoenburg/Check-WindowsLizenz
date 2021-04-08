#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Lizenzueberpruefung fuer das Solarwinds RMM

.DESCRIPTION
    Grundlegende Funktion:
        Gibt den Windows-Lizenzschluessel aus.
        Prueft, ob Windows lizenziert ist. 
        Gibt aus in wie vielen Tagen die Windows-Testversion auslaeuft.
        Gibt aus wie viele Rearms verbleiben.

    Funktion im Solarwinds RMM:
    Laeuft, als OK durch, wenn...
        ... Windows Lizenziert ist

    Laeuft, als fehlgeschlagen durch, wenn...
        ... Windows nicht lizenziert ist
        ... die Windows-Testversion in weniger als oder in sieben Tagen auslaeuft

.PARAMETER TageImVorausWarnen
    Gibt an, wie viele Tage vor dem Lizenzablauf man schon benachrichtigt werden moechte.

.EXAMPLE
    Check-WindowsLizenz -TageImVorausWarnen 10
    
.EXAMPLE
    Check-WindowsLizenz -Tage 5
    
.EXAMPLE
    Check-WindowsLizenz 2

.EXAMPLE
    Check-WindowsLizenz -TageImVorausWarnen 0

    Diese Pruefung schlaegt nur fehl, wenn Windows nicht lizenziert ist, 
    weil fuer TageImVorausWarnen die Zahl 0 spezifiziert wurde.
    Die Pruefung schlaegt somit nicht fehl, wenn Windows in einigen Tagen nicht mehr lizenziert ist.

.EXAMPLE
    Check-WindowsLizenz
    
    Wird TageImVorausWarnen nicht spezifiziert, wird dafuer der Standardwert 7 verwendet.

.NOTES
    Version:    0.1
    Datum:      08.04.2021
    Autor:      Michael Schoenburg (IT-Center Engels)
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, Position = 0)]
    [Alias('Tage')]
    [int]
    $TageImVorausWarnen = 7
)

# ---------------------------------------------- Funktionen ------------------------------------------------------

function Get-TageVonSlmgrWert {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
        Position = 0)]
        [array]
        $SlmgrAusgabe,
        [Parameter(Mandatory = $true,
        Position = 1)]
        [string]
        $Eigenschaft,
        [Parameter(Mandatory = $true,
        Position = 1)]
        [string]
        $Tagbezeichnung
    )
    
    Write-Debug 'SlmgrAusgabe:'
    for ($i = 0; $i -lt $SlmgrAusgabe.Count; $i++) {
        Write-Debug '$( $i ) = $( $SlmgrAusgabe[$i] )'
    }

    try {
        $tage = Get-SlmgrEigenschaft -SlmgrAusgabe $slmgrAusgabe -Eigenschaft $Eigenschaft
        Write-Debug "tage - initial = $( $tage )"

        # Tage auslesen
        $tage = $tage.Split('(')
        Write-Debug "tage - split nach ( = $( $tage )"

        $tage = $tage.Where{$_ -like "*$( $Tagbezeichnung )*"}
        Write-Debug "tage - initial = $( $tage )"

        $tage = $tage.Split(' ')
        Write-Debug "tage - initial = $( $tage )"

        $tage = $tage[0]
        Write-Debug "tage - initial = $( $tage )"
    }
    catch {
        if ($_.Exception.Message -eq 'Die gesuchte Eigenschaft konnte in der SLMGR-Ausgabe nicht gefunden werden.') {
            $tage = 999999999
        } else {
            throw 'Unbekannter Error beim Abfragen der Zeit.'
        }
    }
    
    Write-Debug "tage - fainal = $( $tage )"
    return [int]$tage
}

function Get-SlmgrEigenschaft {
    <#
    .SYNOPSIS
    Gibt den Wert zu einem Eigenschaft aus der SLMGR-Ausgabe zurueck.
    
    .DESCRIPTION
    Man gibt eine Eigenschaft aus der SLMGR-Ausgabe an und bekommt den zugehoerigen Wert zurueck.
    Eigenschaften sind die Strings die vor den Doppelpunkten stehen.
    Werte sind die kompletten Strings, die hinter dem Doppelpunkt stehen.
    
    .PARAMETER SlmgrAusgabe
    Die SLMGR-Ausgabe.

    .PARAMETER DeutscheRearms
    Gibt an, ob die Rearms abgefragt werden sollen. Ist nur notwendig, wenn 

    .PARAMETER Eigenschaft
    Die Eigenschaft aus der SLMGR-Ausgabe.
    Muss nur angegeben werden, wenn DeutscheRearms nicht gewaehlt ist.
    
    .EXAMPLE
    Get-SlmgrEigenschaft -SlmgrAusgabe $VariableWelcheDieSlmgrAusgabeEnthaelt -Eigenschaft 'Use License URL'
    Get-SlmgrEigenschaft -SlmgrAusgabe $VariableWelcheDieSlmgrAusgabeEnthaelt -Eigenschaft Description
    #>

    [CmdletBinding(DefaultParameterSetName = 'Standard')]
    param (
        [Parameter(ParameterSetName = 'Standard', Position = 0)]
        [Parameter(ParameterSetName = 'DeutscheRearms', Position = 0)]
        [Alias('Slmgr')]
        [string[]]
        $SlmgrAusgabe,
        [Parameter(ParameterSetName = 'DeutscheRearms', Position = 1)]
        [Alias('DE')]
        [Switch]
        $DeutscheRearms,
        [Parameter(ParameterSetName = 'Standard', Position = 1)]
        [Alias('E')]
        [string[]]
        $Eigenschaft
    )

    Write-Debug 'slmgrAusgabe:'
    for ($i = 0; $i -lt $slmgrAusgabe.Count; $i++) {
        Write-Debug "$( $i ) = $( $slmgrAusgabe[$i] )"
    }
    Write-Debug "eigenschaft = $( $eigenschaft )"
    
    # Im deutschen heißen die beiden Rearm-Eigenschaften beide "Verbleibende Windows Rearm-Anzahl".
    if ($DeutscheRearms) {
        Write-Debug "DeutscheRearms ist aktiv. "

        $eigenschaft = 'Verbleibende Windows Rearm-Anzahl'
        Write-Debug "eigenschaft = $( $eigenschaft )"

        # Wir holen uns die Zeile in welcher die Eigenschaft steht
        $zeile = $slmgrAusgabe.Where{$_ -like "$( $eigenschaft ): *"}
        Write-Debug "zeile.count = $( $zeile.count )"
        Write-Debug "zeile nach Suche nach Eigenschaft = $( $zeile )"

        # $zeile[0] ist der "Remaining Windows rearm count"
        # $zeile[1] ist der "Remaining SKU rearm count"
        Write-Debug 'Wir fahren mit mit dem Windows rearm count fort.'
        $zeile = $zeile[0]
    } else {
        # Wir holen uns die Zeile in welcher die Eigenschaft steht
        $zeile = $slmgrAusgabe.Where{$_ -like "$( $eigenschaft ): *"}
        Write-Debug "zeile.count = $( $zeile.count )"
        Write-Debug "zeile nach Suche nach Eigenschaft = $( $zeile )"

        # Pruefe ob die zu selektierende Eigenschaft einzigartig ist oder mehrere Funde vorliegen
        if ($zeile.count -eq 0) {
            throw 'Die gesuchte Eigenschaft konnte in der SLMGR-Ausgabe nicht gefunden werden.'
        } elseif ($zeile.count -gt 1) {
            # Erzeuge einen terminiereneden Error. Der rest der Funktion wird nicht ausgefuehrt. Die Funktion gibt 
            # also auch keinen Wert zurueck.
            throw 'Uneindeutige Eigenschaft. 
                Verwenden Sie den Parameter -Rearm, wenn Sie die DeutscheRearms herausfinden wollen.'            
        }
    }

    # Wir teilen die Zeile nach Leerzeichen auf und erhalten einen Array zurueck
    $wert = $zeile.Split(':')
    Write-Debug "wert nach Eigenschaftentfernung Part 1:"
    for ($i = 0; $i -lt $wert.Count; $i++) {
        Write-Debug "$( $i ) = $( $wert[$i] )"
    }

    # Final wollen wir alle Strings aus dem Array, außer den ersten. 
    # Der erste String ist die Eigenschaft.
    # Der Rest ist Wert der Eigenschaft.
    # Sollten in der Eigenschaft Doppelpunkte vorkommen, waere dies kein Problem
    # Beispiel: Product Key-Kanal: Retail:TB:Eval
    $wert = $wert[1..$wert.Length]
    Write-Debug 'wert nach der Eigenschaftentfernung Part 2:'
    for ($i = 0; $i -lt $wert.Count; $i++) {
        Write-Debug "$( $i ) = $( $wert[$i] )"
    }

    # Da wir durch die Trennung alle Doppelpunkte verloren haben, muessen wir diese wieder einfuegen.
    $wert = $wert -join ':'
    Write-Debug "wert nach Doppelpunkteinsetzung = $( $wert )"

    # Vorstehendes Leerzeichen entfernen, falls vorhanden
    $wert = $wert.Split(' ')
    $wert = $wert[1..$wert.Length]
    Write-Debug 'wert nach der Leerzeichenentfernung:'
    for ($i = 0; $i -lt $wert.Count; $i++) {
        Write-Debug "$( $i ) = $( $wert[$i] )"
    }

    # Da wir durch die Trennung alle Leerzeichen verloren haben, muessen wir diese wieder einfuegen.
    $wert = $wert -join ' '
    Write-Debug "wert nach Leerzeicheneinsetzung = $( $wert )"

    return $wert
}

function Get-WindowsProductKey {
    <#
    .SYNOPSIS
    Gibt den Windows Produktschluessel zurueck.
    
    .DESCRIPTION
    Gibt den Windows Produktschluessel zurueck.
    
    .EXAMPLE
    Get-WindowsProductKey
    
    .NOTES
    Version:    0.9
    Datum:      07.04.2021
    Autor:      Christian Hainke (Hainke Computer)
    #>

    $productKey = (Get-WmiObject -query 'select * from SoftwareLicensingService').OA3xOriginalproductKey

    if ($productKey.Length -ge 0)
    {
        # Produktschluessel finden / digitale Lizenz
        $map = 'BCDFGHJKMPQRTVWXY2346789'
        $value = (get-itemproperty 'HKLM:\\SOFTWARE\Microsoft\Windows NT\CurrentVersion').DigitalproductId[0x34..0x42]
        $productKey = ''
        for ($i = 24; $i -ge 0; $i--) {
            $r = 0
            for ($j = 14; $j -ge 0; $j--) {
                $r = ($r * 256) -bxor $value[$j]
                $value[$j] = [math]::Floor([double]($r/24))
                $r = $r % 24
            }
            $productKey = $map[$r] + $productKey
            if (($i % 5) -eq 0 -and $i -ne 0) {
                $productKey = "-" + $productKey
            }
        }
    }

    return $productKey
}

# -------------------------------------------- Deklarationenen ---------------------------------------------------

# Windowslizenzschluessel
$Windowslizenzschluessel = Get-WindowsProductKey

#region Ausgabe von SLMGR einfangen
$OriginalLizenzDetails = cscript C:\Windows\System32\slmgr.vbs /dlv
# Leere Zeilen aus der SLMGR-Ausgabe entfernen (optional)
$LizenzDetails = @()
foreach ($zeile in $OriginalLizenzDetails) {
    if ($zeile -ne "") {
        $LizenzDetails += $zeile
    }
}
#endregion Ausgabe von SLMGR einfangen

#region Herausfinden, ob die Ausgabe in Englisch oder Deutsch geschrieben ist
$Copyright = $LizenzDetails.Where{$_ -like 'Copyright (C) Microsoft Corporation.*'}
switch ($Copyright) {
    'Copyright (C) Microsoft Corporation. All rights reserved.' { 
        Write-Debug 'Sprache Englisch wurde erkannt.'
        $Sprache = 'Englisch' 
    }
    'Copyright (C) Microsoft Corporation. Alle Rechte vorbehalten.' { 
        Write-Debug 'Sprache Deutsch wurde erkannt.'
        $Sprache = 'Deutsch' 
    }
    Default { Throw 'Die Sprache konnte nicht erkannt werden.' }
}
#endregion Herausfinden, ob die Ausgabe in Englisch oder Deutsch geschrieben ist

#region Mapping der SLMGR-Ausgabe (je nach Sprache)
switch ($Sprache) {
    'Englisch' {
        $WindowsVersionPhrase = 'Name'
        $LizenzStatusPhrase = 'License Status'
        $VerbleibendeTagePhrase = 'Timebased activation expiration'
        $Tagbezeichnung = 'Day'
        $IstLizenziertPhrase = 'Licensed'
        $Rearms = Get-SlmgrEigenschaft -SlmgrAusgabe $LizenzDetails -Eigenschaft 'Remaining Windows rearm count'
    }
    'Deutsch' {
        $WindowsVersionPhrase = 'Name'
        $LizenzStatusPhrase = 'Lizenzstatus'
        $VerbleibendeTagePhrase = 'Ablauf der zeitbegrenzten Aktivierung'
        $Tagbezeichnung = 'Tag'
        $IstLizenziertPhrase = 'Lizenziert'
        $Rearms = Get-SlmgrEigenschaft -SlmgrAusgabe $LizenzDetails -DeutscheRearms
    }
}

$WindowsVersion = Get-SlmgrEigenschaft -SlmgrAusgabe $LizenzDetails -Eigenschaft $WindowsVersionPhrase
$Lizenzstatus = Get-SlmgrEigenschaft -SlmgrAusgabe $LizenzDetails -Eigenschaft $LizenzStatusPhrase

if ($Lizenzstatus -eq $IstLizenziertPhrase) {
    $IstLizenziert = $true
} else {
    $IstLizenziert = $false
}

[int]$VerbleibendeTage = Get-TageVonSlmgrWert -SlmgrAusgabe $LizenzDetails -Eigenschaft $VerbleibendeTagePhrase -Tagbezeichnung $Tagbezeichnung
#endregion Mapping der SLMGR-Ausgabe (je nach Sprache)

# -------------------------------------- Ausgabe fuer Solarwinds RMM ----------------------------------------------

Write-Host '================= Ergebnis ================='
Write-Host "WindowsVersion        = $( $WindowsVersion )"
Write-Host "Lizenzschluessel      = $( $Windowslizenzschluessel )"
Write-Host "Lizenzstatus          = $( $Lizenzstatus )"
Write-Host "Verbleibende Rearms   = $( $Rearms )"
Write-Host "Verbleibende Tage     = $( $VerbleibendeTage )"

if ($IstLizenziert) {
    # Wenn wenier als oder genau sieben Tage verbleiben
    # Wenn $tageImVorausWarnen null ist, wird nie im Vorausgewarnt
    Write-Debug 'Windows ist lizenziert.'
    if ($VerbleibendeTage -le $tageImVorausWarnen) {
        # Die Solarwinds RMM-ueberpruefung laeuft als Fehlgeschlagen durch
        Write-Debug '$VerbleibendeTage ist weniger als $tageImVorausWarnen.'
        exit 1001
    } else {
        # Die Solarwinds RMM-ueberpruefung laeuft als OK durch
        Write-Debug '$VerbleibendeTage ist NICHT weniger als oder gleich $tageImVorausWarnen.'
        exit 0
    }
} else {
    # Die Solarwinds RMM-ueberpruefung laeuft als Fehlgeschlagen durch
    Write-Debug 'Windows ist nicht lizenziert.'
    exit 1001
}
