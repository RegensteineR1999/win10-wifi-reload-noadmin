# WiFi Reconnect Fixer - No Admin needed
# Automatically reconnects to WiFi on startup or after connection loss

# Check if WiFi radio is on
$ifaceOutput = netsh wlan show interfaces 2>&1
$radioLines = $ifaceOutput | Select-String "Radio status|Hardware|Software"
$radioText = ($radioLines | ForEach-Object { $_.Line }) -join " "

if ($radioText -match "(?i)Software\s*Off") {
    Write-Host "WiFi is turned off. Please enable WiFi first."
    exit
}

# Check if already connected and internet works - if so, nothing to do
$stateNow = ($ifaceOutput | Select-String "^\s+State\s*:\s(.+)$" | Select-Object -First 1)
$stateNowValue = ($stateNow.Matches.Groups[1].Value).Trim()

if ($stateNowValue -eq "connected") {
    $tcp = New-Object System.Net.Sockets.TcpClient
    try {
        $tcp.ConnectAsync("8.8.8.8", 53).Wait(3000)
        if ($tcp.Connected) {
            Write-Host "Already connected and online. Nothing to do."
            exit
        }
    } catch {} finally { $tcp.Close() }
}

# Get SSID
$ssidLine = $ifaceOutput | Select-String "^\s+SSID\s+:\s(.+)$" | Select-Object -First 1
if (-not $ssidLine) {
    $profiles = netsh wlan show profiles | Select-String "All User Profile\s*:\s*(.*)"
    if ($profiles) { $currentSSID = ($profiles[0].Matches.Groups[1].Value).Trim() }
} else {
    $currentSSID = ($ssidLine.Matches.Groups[1].Value).Trim()
}

if ([string]::IsNullOrEmpty($currentSSID)) {
    Write-Host "No SSID found!"
    exit
}
Write-Host "Target SSID: $currentSSID"

# Disconnect
Write-Host "Disconnecting..."
netsh wlan disconnect
Start-Sleep -Seconds 5

# Wait until adapter ready (max 15s)
Write-Host "Waiting for adapter..."
$ready = $false
for ($w = 1; $w -le 5; $w++) {
    $check = netsh wlan show interfaces 2>&1
    if ($check -match "State|Zustand|Status") {
        $ready = $true; break
    }
    Write-Host "Not ready yet ($w/5)..."
    Start-Sleep -Seconds 3
}

if (-not $ready) {
    Write-Host "Adapter stuck. Try toggling WiFi manually once."
    exit
}

# Scan
netsh wlan show networks 2>&1 | Out-Null
Start-Sleep -Seconds 3

# Reconnect loop
for ($i = 1; $i -le 4; $i++) {
    Write-Host "Attempt $i..."
    netsh wlan connect name="$currentSSID" 2>&1 | Out-Null
    Start-Sleep -Seconds 8

    $state = (netsh wlan show interfaces | Select-String "^\s+State\s*:\s(.+)$" | Select-Object -First 1)
    $stateValue = ($state.Matches.Groups[1].Value).Trim()
    Write-Host "State: $stateValue"

    if ($stateValue -eq "connected") {
        Write-Host "Connected on attempt $i!"
        exit
    }
}

Write-Host "Failed to reconnect after 4 attempts."
