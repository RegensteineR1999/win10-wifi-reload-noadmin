# WiFi Reconnect Fixer - No Admin needed
# Runs silently at startup/user login via Task Scheduler
# Shows popup + opens Network Settings on failure or if WiFi is off

function Get-WlanOutput {
    return netsh wlan show interfaces 2>&1
}

function Show-Notice($title, $message) {
    Add-Type -AssemblyName System.Windows.Forms | Out-Null
    [System.Windows.Forms.MessageBox]::Show(
        $message,
        $title,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
}

function Is-SoftwareOff($output) {
    $radioLines = $output | Select-String "Radio status|Hardware|Software"
    $radioText = ($radioLines | ForEach-Object { $_.Line }) -join " "
    return $radioText -match "(?i)Software\s*Off"
}

function Get-State($output) {
    $line = $output | Select-String "^\s+State\s*:\s(.+)$" | Select-Object -First 1
    if ($line) { return ($line.Matches.Groups[1].Value).Trim() }
    return ""
}

function Get-SSID($output) {
    $line = $output | Select-String "^\s+SSID\s+:\s(.+)$" | Select-Object -First 1
    if ($line) { return ($line.Matches.Groups[1].Value).Trim() }
    $profiles = netsh wlan show profiles | Select-String "All User Profile\s*:\s*(.*)"
    if ($profiles) { return ($profiles[0].Matches.Groups[1].Value).Trim() }
    return ""
}

# --- Initial checks ---
$output = Get-WlanOutput

if (Is-SoftwareOff $output) {
    Write-Host "WiFi is turned off (Software Off). Opening Network settings..."
    Show-Notice "WiFi Reconnect" "WiFi is turned off via the taskbar toggle.`nNetwork settings will open so you can turn it back on."
    Start-Process ms-settings:network
    exit
}

$state = Get-State $output
if ($state -eq "connected") {
    Write-Host "Already connected. Nothing to do."
    exit
}

$ssid = Get-SSID $output
if ([string]::IsNullOrEmpty($ssid)) {
    Write-Host "No SSID found. Exiting."
    Show-Notice "WiFi Reconnect" "No known WiFi network found.`nPlease connect manually."
    Start-Process ms-settings:network
    exit
}

Write-Host "Target SSID: $ssid"

# --- One disconnect to reset state ---
Write-Host "Disconnecting..."
netsh wlan disconnect 2>&1 | Out-Null
Start-Sleep -Seconds 10

# --- Scan + connect loop (no repeated disconnects) ---
for ($i = 1; $i -le 5; $i++) {
    Write-Host "Attempt $i of 5 - scanning..."
    netsh wlan show networks mode=bssid 2>&1 | Out-Null
    Start-Sleep -Seconds 5

    Write-Host "Attempt $i of 5 - connecting..."
    netsh wlan connect name="$ssid" 2>&1 | Out-Null
    Start-Sleep -Seconds 10

    $check = Get-WlanOutput
    $newState = Get-State $check
    Write-Host "State: $newState"

    if ($newState -eq "connected") {
        Write-Host "Connected on attempt $i!"
        exit
    }
}

# --- All attempts failed ---
Write-Host "Failed to connect after 5 attempts."
Show-Notice "WiFi Reconnect" "Could not reconnect to '$ssid' after 5 attempts.`nNetwork settings will open now."
Start-Process ms-settings:network
