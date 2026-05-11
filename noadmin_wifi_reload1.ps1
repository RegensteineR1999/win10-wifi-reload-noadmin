# WiFi Reconnect Fixer - No Admin needed

# Get SSID - only the first match (not BSSID line)
$ssidLine = netsh wlan show interfaces | Select-String "^\s+SSID\s+:\s(.+)$" | Select-Object -First 1
if (-not $ssidLine) {
    $profiles = netsh wlan show profiles | Select-String "All User Profile\s*:\s*(.*)"
    if ($profiles) { $currentSSID = ($profiles[0].Matches.Groups[1].Value).Trim() }
} else {
    $currentSSID = ($ssidLine.Matches.Groups[1].Value).Trim()
}

if ([string]::IsNullOrEmpty($currentSSID)) { Write-Host "No SSID found!"; exit }
Write-Host "Target SSID: $currentSSID"

# Restart WLAN AutoConfig service (no adapter disable needed, no admin for connect)
Write-Host "Disconnecting..."
netsh wlan disconnect
Start-Sleep -Seconds 3

# Force scan
netsh wlan show networks | Out-Null
Start-Sleep -Seconds 4

# Reconnect loop (up to 4 tries)
for ($i = 1; $i -le 4; $i++) {
    Write-Host "Attempt $i..."
    netsh wlan connect name="$currentSSID"
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
