# windows-wifi-reconnect

A lightweight PowerShell script that automatically reconnects your WiFi on startup — no admin rights required.

## The Problem

Windows 10 sometimes fails to connect to WiFi after booting or waking from sleep. The usual workaround is manually toggling WiFi off and on, or clicking "Show all networks" to force a refresh. This script automates that exact process.

## Features

- Auto-detects your WiFi adapter and SSID — no manual config needed
- Disconnects, waits for the adapter to be ready, then reconnects
- Retries up to 4 times before giving up
- Checks internet connectivity after reconnect
- Detects if WiFi is turned off (via taskbar toggle) and exits cleanly
- Works on English and German Windows 10
- No admin rights required

## Requirements

- Windows 10
- PowerShell 5.1 or later (pre-installed on Windows 10)
- WiFi must be enabled (radio on)

## Setup

### 1. Allow script execution (one-time)

Open PowerShell and run:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 2. Run manually

Right-click `wifi_reconnect.ps1` → "Run with PowerShell"

Or in PowerShell:

```powershell
.\wifi_reconnect.ps1
```

### 3. Run automatically on startup (recommended)

Use Task Scheduler to run the script at every login:

1. Press `Win + R`, type `taskschd.msc`, hit Enter
2. Click **Create Task** (right panel)
3. **General tab**: Name it `WiFi Reconnect`, leave user account as-is
4. **Triggers tab**: New → Begin the task: **At log on** → OK
5. **Actions tab**: New → Program: `powershell.exe` → Arguments:
   ```
   -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\Path\To\wifi_reconnect.ps1"
   ```
6. **Conditions tab**: Uncheck "Start only if on AC power"
7. Click OK

> Remove `-WindowStyle Hidden` if you want to see the output window on startup.

## How It Works

1. Checks if the WiFi radio is on (`Software Off` = WiFi kachel was pressed → exits with message)
2. Reads the current or last known SSID from `netsh wlan show interfaces`
3. Disconnects from the network
4. Waits until the adapter is ready again (up to 15 seconds)
5. Forces a network scan
6. Reconnects to the saved SSID profile (up to 4 attempts)
7. Verifies internet via TCP connection to `8.8.8.8:53`

## Notes

- The script uses only `netsh wlan` commands — no third-party tools, no registry edits
- Toggling the adapter on/off (full disable/enable) requires admin rights on Windows, so this script uses disconnect + reconnect instead
- If the script still fails after 4 attempts, try running Task Scheduler with "Run with highest privileges" and your Windows password

## License

MIT
