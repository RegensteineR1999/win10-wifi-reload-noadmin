# windows-wifi-reconnect

A lightweight PowerShell script that automatically reconnects your WiFi on startup — no admin rights required.

## The Problem

Windows 10 sometimes fails to connect to WiFi after booting or waking from sleep. The usual workaround is manually toggling WiFi off and on, or clicking "Show all networks" to force a refresh. This script automates that exact process.

## Features

- Auto-detects your WiFi adapter & SSID (No manual config needed)
- Detects WiFi turned off via taskbar toggle (`Software Off`) and exits cleanly with a message
- Disconnects, waits for the adapter to be ready, then reconnects
- Retries up to 4 times before giving up
- Checks internet connectivity after reconnect
- Works on English & German Windows 10
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

Right-click `noadmin_wifi_reload1.ps1` → "Run with PowerShell"

Or in PowerShell:

```powershell
.\noadmin_wifi_reload1.ps1
```

### 3. Run automatically on startup (recommended)

Use Task Scheduler to run the script at every login:

1. Press `Win + R`, type `taskschd.msc`, hit Enter
2. Click **Create Task** (right panel, not "Create Basic Task"!!!)
3. **General tab**: Name it `WiFi Reload1` — make sure your own user account is selected, not SYSTEM
4. **Triggers tab**: New → Begin the task: **At log on** → enable **Delay task for: 30 seconds** → OK
5. **Actions tab**: New →
   - Program/script: `powershell.exe`
   - Add arguments: `-ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\Users\YourName\path\to\noadmin_wifi_reload1.ps1"`
6. **Conditions tab**: Uncheck "Start only if on AC power"
7. **Settings tab**: Enable "If the task fails, restart every: 1 minute" up to 3 times
8. OK → done

To test before rebooting: right-click the task → **Run**. Remove `-WindowStyle Hidden` temporarily to see the output window.

## How It Works

1. Reads all radio status lines and checks for `Software Off` — if the WiFi taskbar toggle is off, exits with a clear message instead of running anyway
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
