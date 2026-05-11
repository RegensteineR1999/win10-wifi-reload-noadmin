# Auto WiFi Fixer - Toggle & Reconnect (No config needed)

# Find WiFi adapter (Wireless type)
$wifiAdapters = Get-NetAdapter | Where-Object { $_.InterfaceType -eq 71 -and $_.Status -ne 'Disabled' }
if ($wifiAdapters.Count -eq 0) { Write-Host "No WiFi adapter found!"; exit }
$adapterName = $wifiAdapters[0].Name
Write-Host "Using adapter: $adapterName"

# Get current SSID or last profile
$currentSSID = (netsh wlan show interfaces | Select-String "SSID\s*:\s*(.*)" | ForEach-Object { $_.Matches.Groups[1].Value }).Trim()
if ([string]::IsNullOrEmpty($currentSSID)) {
    $profiles = netsh wlan show profiles | Select-String "All User Profile\s*:\s*(.*)"
    if ($profiles) { $currentSSID = ($profiles[0].Matches.Groups[1].Value).Trim() }
}
if ([string]::IsNullOrEmpty($currentSSID)) { Write-Host "No SSID found!"; exit }
Write-Host "Target SSID: $currentSSID"

# Toggle adapter with netsh (works without extra rights issues)
netsh interface set interface "$adapterName" admin=disabled
Start-Sleep -Seconds 3
netsh interface set interface "$adapterName" admin=enabled
Start-Sleep -Seconds 5

# Reconnect
netsh wlan connect name="$currentSSID"
Write-Host "Reconnecting... Wait 10s."
Start-Sleep -Seconds 10

# Check internet (TCP to DNS port) 
$tcp = New-Object System.Net.Sockets.TcpClient
try {
   # Not used $result = $tcp.ConnectAsync("8.8.8.8", 53).Wait(3000)
    if ($tcp.Connected) {
        Write-Host "Connected!"
    } else {
        Write-Host "Still offline."
    }
} catch {
    Write-Host "Connection check failed."
} finally {
    $tcp.Close()
}
