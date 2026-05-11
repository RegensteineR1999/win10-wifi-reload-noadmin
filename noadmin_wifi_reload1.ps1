# WiFi Reconnect Fixer - No Admin needed

# Check if WiFi radio is on at all
$radioState = (netsh wlan show interfaces | Select-String "Radio status\s*:\s*(.+)" | Select-Object -First 1)
if ($radioState) {
    $radioValue = ($radioState.Matches.Groups[1].Value).Trim()
    if ($radioValue -notmatch "Hardware On|Software On|on") {
        Write-Host "WiFi radio is OFF. Please turn WiFi on first (use the taskbar toggle)."
        Read-Host "Press Enter to exit"
        exit
    }
}

# Check adapter is not powered down
$ifaceCheck = netsh wlan show interfaces 2>&1
if ($ifaceCheck -match "powered down" -or $ifaceCheck -notmatch "State") {
    Write-Host "WiFi adapter is powered down or unavailable."
    Read-Host "Press Enter to exit"
    exit
}

# Get SSID
$ssidLine = netsh wlan show interfaces | Select-String "^\s+SSID\s+:\s(.+)$" | Select-Object -First 1
if (-not $ssidLine) {
    $profiles = netsh wlan show profiles | Select-String "All User Profile\s*:\s*(.*)"
    if ($profiles) { $currentSSID = ($profiles[0].Matches.Groups[1].Value).Trim() }
} else {
    $currentSSID = ($ssidLine.Matches.Groups[1].Value).Trim()
}

if ([string]::IsNullOrEmpty($currentSSID)) {
    Write-Host "No SSID found!"
    Read-Host "Press Enter to exit"
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
    if ($check -notmatch "powered down" -and $check -match "State") {
        $ready = $true; break
    }
    Write-Host "Not ready yet ($w/5)..."
    Start-Sleep -Seconds 3
}

if (-not $ready) {
    Write-Host "Adapter stuck. Try toggling WiFi manually once."
    Read-Host "Press Enter to exit"
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
        break
    }
}

# Internet check
$tcp = New-Object System.Net.Sockets.TcpClient
try {
    $tcp.ConnectAsync("8.8.8.8", 53).Wait(3000)
    if ($tcp.Connected) { Write-Host "Internet OK!" } else { Write-Host "Still no internet." }
} catch { Write-Host "Check failed." } finally { $tcp.Close() }

Read-Host "Press Enter to exit"
