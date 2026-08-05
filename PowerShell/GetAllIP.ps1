# 1. SCHRITT: Alle registrierten Domänen-Geräte über den DC abfragen
Write-Host "1. Frage Domänencontroller nach registrierten Computern ab..." -ForegroundColor Cyan
try {
    $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
    $Context = New-Object System.DirectoryServices.DirectorySearcher
    $Context.Filter = "(objectCategory=computer)"
    $Context.PageSize = 1000
    
    $ADComputers = $Context.FindAll() | ForEach-Object { $_.Properties.name.ToLower() }
    Write-Host "-> $($ADComputers.Count) Geräte im Active Directory gefunden." -ForegroundColor Green
} catch {
    Write-Error "Keine Verbindung zur Domäne möglich."
    exit
}

# 2. SCHRITT: Subnetz des aktuellen PCs automatisch ermitteln
Write-Host "Ermittle lokales IP-Subnetz..." -ForegroundColor Cyan
$ActiveIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
    $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" -and (Get-NetRoute -DestinationPrefix "0.0.0.0/0" -NextHop * -ErrorAction SilentlyContinue).InterfaceIndex -contains $_.InterfaceIndex
} | Select-Object -First 1).IPAddress

if (-not $ActiveIP) {
    Write-Error "Keine aktive Netzwerkverbindung gefunden."
    exit
}

$Subnet = ($ActiveIP -split "\.")[0..2] -join "."
Write-Host "-> Eigene IP: $ActiveIP | Scanne Subnetz: $Subnet.1 bis $Subnet.254" -ForegroundColor Green

# 3. SCHRITT: Subnetz per .NET-Ping scannen (Extrem schnell)
Write-Host "Scanne IP-Netzwerk mit High-Speed .NET-Ping (inkl. CNC)..." -ForegroundColor Cyan

$NetworkDevices = New-Object System.Collections.Generic.List[PSCustomObject]
$TotalIPs = 254

# Initialisiere das .NET-Ping-Objekt
$PingProvider = New-Object System.Net.NetworkInformation.Ping
$TimeoutMS = 10 # Ultra-kurzer Timeout für lokale Netzwerke

for ($i = 1; $i -le $TotalIPs; $i++) {
    $TargetIP = "$Subnet.$i"
    
    try {
        # Führt den schnellen .NET-Ping aus
        $PingResult = $PingProvider.Send($TargetIP, $TimeoutMS)
        
        if ($PingResult.Status -eq "Success") {
            try {
                $HostName = [System.Net.Dns]::GetHostByAddress($TargetIP).HostName
                $ShortName = ($HostName -split "\.").ToLower()
            } catch {
                $HostName = "Unbekannt"
                $ShortName = "unbekannt"
            }
            
            $Device = [PSCustomObject]@{
                IPAddress    = $TargetIP
                ComputerName = $HostName
                ShortName    = $ShortName
            }
            $NetworkDevices.Add($Device)
        }
    } catch {
        # Ignoriere Fehler bei toten IPs
    }
    
    # Live-Fortschritt im Terminal anzeigen
    $Percent = [Math]::Round(($i / $TotalIPs) * 100)
    Write-Progress -Activity "High-Speed Netzwerk-Scan läuft" -Status "$Percent% komplett ($i/$TotalIPs IPs geprüft)" -PercentComplete $Percent
}

# Ressourcen sauber freigeben
$PingProvider.Dispose()
Write-Host "-> Netzwerk-Scan abgeschlossen." -ForegroundColor Green

# 4. SCHRITT: Abgleich & Filterung
Write-Host "Vergleiche Ergebnisse und filtere AD-Geräte heraus..." -ForegroundColor Cyan

$NonADDevices = New-Object System.Collections.Generic.List[PSCustomObject]
foreach ($Device in $NetworkDevices) {
    if ($ADComputers -notcontains $Device.ShortName) {
        $NonADObj = [PSCustomObject]@{
            IPAddress    = $Device.IPAddress
            ComputerName = $Device.ComputerName
        }
        $NonADDevices.Add($NonADObj)
    }
}

# 5. SCHRITT: Live-Ausgabe im Terminal & CSV-Export
if ($NonADDevices.Count -gt 0) {
    Write-Host "`n=== GEFUNDENE REINE NETZWERKGERÄTE (NICHT IM AD) ===" -ForegroundColor Yellow
    $NonADDevices | Format-Table -AutoSize
    Write-Host "====================================================`n" -ForegroundColor Yellow
    
    $ExportPath = "$env:USERPROFILE\Desktop\Reine_Netzwerk_Geraete.csv"
    $NonADDevices | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
    Write-Host "Ergebnis wurde als CSV auf dem Desktop gespeichert: $ExportPath" -ForegroundColor Green
} else {
    Write-Host "-> Keine unbekannten Netzwerkgeräte außerhalb des ADs gefunden." -ForegroundColor Yellow
}
