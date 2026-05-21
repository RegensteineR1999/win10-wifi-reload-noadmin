# WiFi Reconnect Fixer

> File: `noadmin_wifi_reload1.ps1`

A lightweight PowerShell script that automatically reconnects your WiFi on startup — no admin rights required.

## The Problem

~~My???~~ Windows 10 sometimes fails to connect to WiFi after booting or waking 
from sleep. The usual workaround is manually toggling WiFi off and on, or 
clicking "Show all networks" to force a refresh.

This happens because Windows sometimes just sits there after boot — 
the adapter shows as connected, but no actual network traffic flows 
until you manually poke the UI. This script does that poking for you, 
automatically.

## Features

- Auto-detects your WiFi adapter and SSID — no manual config needed
- Skips everything if WiFi is already connected — no unnecessary reconnects
- Detects WiFi turned off via taskbar toggle (`Software Off`) and opens Network Settings with a popup
- Disconnects once to reset state, then scans and reconnects
- Retries up to 5 times before giving up
- Shows a popup and opens Network Settings if all attempts fail
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

Right-click `noadmin_wifi_reload1.ps1` → "Run with PowerShell"

Or in PowerShell:

```powershell
.\noadmin_wifi_reload1.ps1
```

### 3. Run automatically on startup (recommended)

Use Task Scheduler to run the script at every login:

1. Press `Win + R`, type `taskschd.msc`, hit Enter
2. Click **Create Task** (right panel, not "Create Basic Task"!!!)
3. **General tab**: Name it `WiFi Reconnect Fixer` — make sure your own user account is selected, not SYSTEM
4. **Triggers tab**: New → Begin the task: **At log on** → enable **Delay task for: 30 or 60 seconds** → OK
5. **Actions tab**: New →
   - Program/script: `powershell.exe`
   - Add arguments: `-ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\Users\YourName\path\to\noadmin_wifi_reload1.ps1"`
6. **Conditions tab**: Uncheck "Start only if on AC power"
7. **Settings tab**: Enable "If the task fails, restart every: 1 minute" up to 3 times
8. OK → done

To test before rebooting: right-click the task → **Run**. Remove/Add `-WindowStyle Hidden` temporarily to see the output window.

## Task Scheduler Export

A pre-configured `wifi_reconnect_task.xml` is included for convenience.

> ⚠️ Before importing: open the XML in Notepad and update the hardcoded path
> `C:\Users\Nuka1one\standaloneexc\` to match your own system.
> Then import via Task Scheduler → **Action** → **Import Task**.

## How It Works

1. Checks all radio status lines for `Software Off` — if the WiFi taskbar toggle is off, shows a popup and opens Network Settings so you can turn it back on manually
2. Checks if WiFi is already connected — exits immediately if nothing needs to be done
3. Reads the current or last known SSID from `netsh wlan show interfaces`
4. Disconnects once to reset the adapter state
5. Waits for the adapter to be ready
6. Forces a network scan before each connect attempt (mimics "Show all networks" click)
7. Reconnects to the saved SSID profile — up to 5 attempts
8. If all attempts fail — shows a popup with the SSID name and opens Network Settings automatically

## Notes

- The script uses only `netsh wlan` commands — no third-party tools, no registry edits
- Toggling the adapter on/off (full disable/enable) requires admin rights on Windows — this script uses disconnect + reconnect instead
- If the script still fails after 4 attempts, try running Task Scheduler with "Run with highest privileges" and your Windows password
-  **The present project was developed in collaboration with Claude Sonnet 4.6**

## License

MIT
