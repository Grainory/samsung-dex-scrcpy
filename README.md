# 🚀 Samsung DeX Auto-Launcher for Scrcpy

Automatically trigger a dedicated **WUXGA (1920×1200)** desktop environment on your Windows laptop the moment you plug in your **Samsung Galaxy S24 Ultra, S25 Ultra, or Galaxy flagship** via USB.

Zero capture cards, zero wireless lag, high-bitrate hardware-accelerated video, and true 1:1 pixel sharpness.

---

## ✨ Features

- ⚡ **Auto-Detection**: Listens for your Galaxy S24 Ultra / S25 Ultra over ADB. Plug in your USB cable and desktop mode starts immediately.
- 🖥️ **WUXGA 16:10 Fullscreen**: Built for modern 1920×1200 laptop screens, mapping 1:1 hardware pixels without black letterboxing or downscale blur.
- 🎯 **Razor-Sharp Text (160 DPI)**: Configured at true native 1:1 `mdpi` density ($1\text{dp} = 1\text{px}$) with Windows High-DPI blur override.
- 🚀 **High-Performance USB 3 Stream**: Streams up to **40 Mbps** with hardware-accelerated **H.265** encoding for virtually zero latency and crystal-clear text.
- ⌨️ **Full Desktop Controls**: Passthrough for PC physical keyboard (UHID) and mouse pointer with right-click and scroll wheel support.
- 🔄 **Auto Re-Arming**: When you disconnect your phone, scrcpy cleans up automatically and stands by for the next plug-in.

---

## 📋 Compatibility

- **Samsung Galaxy S25 Ultra** (`SM-S938B`, `SM-S938U`, etc.)
- **Samsung Galaxy S24 Ultra** (`SM-S928B`, `SM-S928U`, etc.)
- **Samsung Galaxy S23 Ultra** (`SM-S918*`) & other Galaxy flagship models with desktop support.
- **Windows 10 / 11** with a USB 3.0 / USB-C cable.

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
Keep the console window open in the background. Whenever your phone is plugged in, **DeX / Desktop Mode** will automatically launch on your screen in crisp 1920×1200 fullscreen!

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

You can pass custom parameters via PowerShell:

```powershell
# Custom UI Scale (e.g. 200 DPI for larger text/icons, 160 for sharp compact layout)
.\dex-monitor.ps1 -Dpi 200

# Windowed mode instead of fullscreen
.\dex-monitor.ps1 -Fullscreen:$false

# Dynamic window resizing (Android resizes to match window dimensions)
.\dex-monitor.ps1 -FlexDisplay

# Custom Bitrate (e.g. 50 Mbps)
.\dex-monitor.ps1 -Bitrate 50M
```

---

## ❓ Troubleshooting

- **"Unauthorized device"**: Unlock your phone and accept the prompt asking to "Allow USB debugging". Check "Always allow from this computer".
- **Pixels look blurry?**: Press `F11` for fullscreen 1:1 hardware pixel mapping. If in windowed mode, press `Alt + G`.
- **Audio routing**: By default, Android audio forwards directly through your PC speakers via scrcpy.

---

## 📜 License
MIT License. Powered by [scrcpy](https://github.com/Genymobile/scrcpy).
