# 🚀 Samsung DeX Auto-Launcher for Scrcpy

Automatically trigger a dedicated desktop environment on your Windows laptop the moment you plug in your **Samsung Galaxy S24 Ultra, S25 Ultra, or Galaxy flagship** via USB.

Zero capture cards, zero wireless lag, high-bitrate hardware-accelerated video, and true 1:1 pixel sharpness.

---

## ✨ Features

- 🖥️ **Automatic Screen Resolution Detection**: Automatically detects your laptop screen's physical resolution (**FHD 1920×1080**, **WUXGA 1920×1200**, **2K/QHD 2560×1440**, **QHD+ 2560×1600**, **4K**, etc.) and spawns a pixel-perfect matching display!
- ⚡ **Plug & Play Auto-Detection**: Listens for your Galaxy S24 Ultra / S25 Ultra over ADB. Plug in your USB cable and desktop mode starts immediately.
- 🎯 **Razor-Sharp Text (1:1 Native Density)**: Auto-calculates integer `mdpi` density scaling ($1\text{dp} = 1\text{px}$) with Windows High-DPI blur override so fonts are always sharp.
- 🚀 **High-Performance USB 3 Stream**: Streams at **40 Mbps** with hardware-accelerated **H.265** encoding for virtually zero latency.
- ⌨️ **Full Desktop Controls**: Passthrough for PC physical keyboard (UHID) and mouse pointer with right-click and scroll wheel support.
- 🔄 **Auto Re-Arming**: When you disconnect your phone, scrcpy cleans up automatically and stands by for the next plug-in.

---

## 📋 Compatibility

- **Samsung Galaxy S25 Ultra** (`SM-S938B`, `SM-S938U`, etc.)
- **Samsung Galaxy S24 Ultra** (`SM-S928B`, `SM-S928U`, etc.)
- **Samsung Galaxy S23 Ultra** (`SM-S918*`) & other Galaxy flagship models.
- **Any Windows 10 / 11 laptop or PC** (1080p, 1200p, 1440p, 1600p, 4K) with a USB 3.0 / USB-C cable.

---

## 🛠️ Quick Start Guide (For You & Friends)

### Step 1: Phone Setup (One-time)
1. On your Galaxy phone, go to **Settings > About phone > Software information**.
2. Tap **Build number** 7 times until you see *"Developer mode has been turned on"*.
3. Go back to **Settings > Developer options**:
   - Enable **USB debugging**.
   - Enable **Force desktop mode** (or *Force experimental desktop mode on secondary displays*).
   - Enable **Enable freeform windows** (recommended for floating resizable windows).
4. Plug your phone into the laptop with a USB cable.
5. On your phone screen, check **"Always allow from this computer"** and tap **Allow**.

---

### Step 2: Install Prerequisites on Windows (One-time)
If your computer doesn't have `adb` and `scrcpy` installed yet, simply double-click:
```bat
install-prerequisites.bat
```
*(Or open PowerShell / Terminal and run):*
```powershell
winget install Google.PlatformTools Genymobile.scrcpy
```

---

### Step 3: Run the Auto-Launcher
Double-click:
```bat
start-dex.bat
```
Keep the console window open in the background. The script will automatically detect your laptop's screen resolution and launch **DeX / Desktop Mode** in matching fullscreen whenever your phone is connected!

*(Optional: Run `detect-resolution.bat` anytime to preview your screen's detected resolution).*

---

## 🎮 Useful Shortcuts

| Shortcut | Action |
|---|---|
| `F11` or `Alt + F` | Toggle Fullscreen / Windowed mode |
| `Alt + G` | Resize window to 1:1 pixel-perfect (in windowed mode) |
| `Alt + Q` | Quit / Close session |
| `Alt + P` | Turn phone screen on / off (session keeps running) |
| `Alt + H` | Middle-click / Home screen |
| `Alt + B` / Right-click | Back button |
| `Alt + S` | App Switcher (Recents) |

---

## ⚙️ Advanced Customization

You can also pass custom arguments via PowerShell:

```powershell
# Manually specify a resolution instead of auto-detecting
.\dex-monitor.ps1 -Resolution 1920x1080

# Custom UI scale (e.g. 200 DPI for larger elements, 160 for compact)
.\dex-monitor.ps1 -Dpi 200

# Windowed mode instead of fullscreen
.\dex-monitor.ps1 -Fullscreen:$false

# Dynamic window resizing (Android adapts display to window dimensions)
.\dex-monitor.ps1 -FlexDisplay

# Custom Bitrate (e.g. 50 Mbps)
.\dex-monitor.ps1 -Bitrate 50M
```

---

## ❓ Troubleshooting

- **"Unauthorized device"**: Unlock your phone and accept the prompt asking to "Allow USB debugging". Check "Always allow from this computer".
- **Pixels look blurry?**: The script auto-detects your native resolution and applies high-DPI scaling overrides. Ensure `scrcpy` is in fullscreen (press `F11`) for exact 1:1 hardware pixel mapping.
- **Audio routing**: Android audio forwards directly through your PC speakers via scrcpy automatically.

---

## 📜 License
MIT License. Powered by [scrcpy](https://github.com/Genymobile/scrcpy).
