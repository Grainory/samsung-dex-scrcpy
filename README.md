# Samsung DeX – Scrcpy Auto-Bridge

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: Windows 10 / 11](https://img.shields.io/badge/Platform-Windows%2010%20%2F%2011-blue.svg)](https://microsoft.com/windows)
[![Scrcpy: v3.0+](https://img.shields.io/badge/Scrcpy-v3.0+-teal.svg)](https://github.com/Genymobile/scrcpy)
[![Target: Galaxy S24U / S25U](https://img.shields.io/badge/Samsung-Galaxy%20S24U%20%2F%20S25U-purple.svg)](https://www.samsung.com)

Autonomous desktop mode launcher and virtual display pipeline connecting **Samsung Galaxy S24 Ultra & S25 Ultra** devices to **Windows laptops** via **Scrcpy** over low-latency USB 3.0.

---

## Overview

Following the deprecation of Samsung's legacy "DeX for PC" desktop application on newer One UI builds (One UI 6 and 7), launching a dedicated desktop environment over a standard USB cable typically requires manual configuration, third-party adapters, or lossy wireless projection.

This utility automates the entire bridge: it monitors for device connections over ADB, queries the host laptop's native hardware display resolution, injects Android desktop flags, and instantiates an isolated high-bitrate virtual display surface with 1:1 hardware pixel mapping.

### Architecture

```
┌──────────────────────────────────────────────────────────┐
│             Samsung Galaxy Flagship Device               │
│         (Galaxy S25 Ultra, S24 Ultra, S23 Ultra)         │
│  - One UI Desktop Launcher (SecondaryLauncher)           │
│  - H.265 Hardware Video Encoder @ 40 Mbps                │
└────────────────────────────┬─────────────────────────────┘
                             │  USB 3.0 / USB-C (ADB Transport)
                             ▼
┌──────────────────────────────────────────────────────────┐
│              Samsung DeX Scrcpy Bridge                   │
│   ├── ADB Event Watcher (dex-monitor.ps1)                │
│   ├── Native Screen Resolution Detector (Win32 GDI)      │
│   └── 1-Click Runtime Launchers (start-dex.bat)          │
└──────────────┬────────────────────────────┬──────────────┘
               │ Auto Settings Injection    │ Stream Forwarding
               ▼                            ▼
┌──────────────────────────────┐ ┌─────────────────────────┐
│     Android System Settings  │ │     Scrcpy Core Engine  │
│  - force_desktop_mode = 1    │ │  - D3D11VA Hardware Accel│
│  - enable_freeform = 1       │ │  - 1:1 Pixel Mapping    │
│  - Virtual Display Creation  │ │  - UHID Keyboard/Mouse  │
└──────────────┬───────────────┘ └──────────┬──────────────┘
               │ Display Surface (DirectX)
               ▼
┌──────────────────────────────────────────────────────────┐
│               Host Windows Laptop Screen                 │
│         (Auto-detected FHD, WUXGA, 2K, 4K Fullscreen)    │
└──────────────────────────────────────────────────────────┘
```

### Key Capabilities

- **Autonomous Hot-Plug Detection**: Continuously monitors the ADB daemon for device attachment. As soon as an authorized Galaxy flagship is detected, the session launches automatically.
- **Dynamic Display Resolution Matching**: Uses native Win32 GDI calls (`DESKTOPHORZRES`/`DESKTOPVERTRES`) to read the host screen's physical hardware dimensions, avoiding Windows DWM display scaling interpolation blur.
- **Hardware-Accelerated Streaming**: Routes video over hardware H.265 at **40 Mbps** bitrate, eliminating compression artifacts and maintaining sharp text contours.
- **Integer Pixel Density Scaling**: Automatically computes integer `mdpi` density scaling (160 DPI on $\le 1200\text{p}$, 220 DPI on $1440\text{p}/1600\text{p}$) for true 1:1 subpixel rendering.
- **HID Peripheral Passthrough**: Captures and routes physical laptop keyboard events via UHID and provides high-precision mouse pointer integration.
- **Lifecycle Management**: Automatically detects device disconnection, cleans up orphan processes, and re-arms the listener loop.

---

## Prerequisites & Device Setup

### 1. Galaxy Phone Configuration (One-Time)

To allow the creation of virtual desktop surfaces on external displays:

1. Navigate to **Settings > About phone > Software information**.
2. Tap **Build number** 7 times to enable **Developer options**.
3. Open **Settings > Developer options** and enable:
   - **USB debugging**
   - **Force desktop mode** (or *Force experimental desktop mode on secondary displays*)
   - **Enable freeform windows** (recommended for floating resizable windows)
4. Connect the phone via USB cable and select **"Always allow from this computer"** when the authorization prompt appears.

### 2. Windows Dependencies

The bridge requires `adb` (Android Platform Tools) and `scrcpy` (v3.0+).

**Zero manual setup required**: `start-dex.bat` automatically verifies both dependencies upon launch. If either component is missing, it installs them automatically via the Windows Package Manager (WinGet).

*(Optional manual installation via terminal):*
```powershell
winget install Google.PlatformTools Genymobile.scrcpy
```

---

## Quick Start

1. Clone or download the repository:
   ```powershell
   git clone https://github.com/Grainory/samsung-dex-scrcpy.git
   cd samsung-dex-scrcpy
   ```

2. Double-click **`start-dex.bat`** (or execute via PowerShell):
   ```powershell
   .\dex-monitor.ps1
   ```
   *(On first run, it will automatically install ADB and Scrcpy if they are not already present).*

3. Connect your Galaxy S24 Ultra or S25 Ultra via USB. The bridge will automatically detect your phone, resolve your laptop's screen resolution, and launch fullscreen desktop mode.

---

## Command-Line Usage & Configuration

The core watcher script supports configurable CLI parameters for specialized displays and streaming targets:

```powershell
# Run with automatic hardware screen detection (default)
.\dex-monitor.ps1

# Specify an explicit resolution target (e.g., external monitor)
.\dex-monitor.ps1 -Resolution 1920x1080

# Configure custom UI scaling density
.\dex-monitor.ps1 -Dpi 200

# Run in windowed mode instead of fullscreen
.\dex-monitor.ps1 -Fullscreen:$false

# Enable dynamic display resizing (adapts virtual display to window bounds)
.\dex-monitor.ps1 -FlexDisplay

# Override video stream bitrate
.\dex-monitor.ps1 -Bitrate 50M
```

### Parameter Reference

| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `-Resolution` | `string` | `"auto"` | Target display resolution. When set to `"auto"`, queries the host panel via Win32. |
| `-Dpi` | `int` | `0` (auto) | Virtual display density. Auto-selects 160 DPI ($\le 1200\text{p}$), 220 DPI ($1440\text{p}$+), or 320 DPI ($4\text{K}$). |
| `-Bitrate` | `string` | `"40M"` | Video stream encoding bitrate (`K` or `M` suffix). |
| `-Fullscreen` | `bool` | `$true` | Toggles borderless fullscreen presentation. |
| `-FlexDisplay` | `switch` | `$false` | Continuously resizes the virtual display surface to match the active window bounds. |
| `-CustomScrcpyPath` | `string` | `""` | Explicit path to `scrcpy.exe` if not located in standard WinGet/Scoop paths. |
| `-CustomAdbPath` | `string` | `""` | Explicit path to `adb.exe` if not found in PATH or platform-tools. |

---

## Keyboard & Interaction Shortcuts

When focused inside the active Scrcpy desktop session:

| Shortcut | Action |
| :--- | :--- |
| `F11` or `Alt + F` | Toggle Fullscreen / Windowed presentation |
| `Alt + G` | Snap window to 1:1 pixel-perfect resolution (windowed mode) |
| `Alt + Q` | Terminate session |
| `Alt + P` | Toggle phone screen power state (keeps desktop streaming) |
| `Alt + H` | Trigger HOME button |
| `Alt + B` / Right-click | Trigger BACK action |
| `Alt + S` | Open App Switcher (Recent Apps) |

---

## Target Device Reference

| Device | Model Pattern | Board Codename | Architecture Support |
| :--- | :--- | :--- | :--- |
| **Samsung Galaxy S25 Ultra** | `SM-S938*` | `pa3q`, `e3q` | Full Hardware H.265 / AV1 |
| **Samsung Galaxy S24 Ultra** | `SM-S928*` | `pa2q`, `e2s` | Full Hardware H.265 / AV1 |
| **Samsung Galaxy S23 Ultra** | `SM-S918*` | `dm3q`, `e1q` | Full Hardware H.265 |
| **Galaxy Z Fold 5 / 6** | `SM-F946*`, `SM-F956*` | `q5q`, `q6q` | Supported via fallback detection |
| **Generic Galaxy Flagships** | `SM-S*`, `SM-N*` | Auto | Automatic manufacturer heuristic fallback |

---

## Project Structure

```
samsung-dex-scrcpy/
├── dex-monitor.ps1          # Core ADB watcher, auto-installer, and virtual display engine
├── start-dex.bat            # 1-click launcher with automatic dependency installation
├── .gitignore               # Repository ignore specifications
├── LICENSE                  # MIT License
└── README.md                # Technical documentation
```

---

## Troubleshooting

**Issue: Device status reported as `unauthorized`**
* Unlock the phone screen and check for the "Allow USB debugging?" dialog.
* Select the checkbox for "Always allow from this computer" and tap **Allow**.

**Issue: Output appears soft or text is blurred**
* The bridge runs in borderless fullscreen by default to guarantee 1:1 hardware pixel mapping. If running windowed, press `Alt + G` to eliminate downsampling interpolation, or pass `-FlexDisplay` to dynamically adapt the virtual display to the window dimensions.

**Issue: `adb` or `scrcpy` not found**
* `start-dex.bat` installs them automatically via WinGet. If your system restricts package managers, install them manually via `winget install Google.PlatformTools Genymobile.scrcpy` or add their directory to your user PATH.

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
