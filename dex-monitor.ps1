<#
.SYNOPSIS
    Monitors for a connected Samsung Galaxy S24 Ultra / S25 Ultra over ADB and
    automatically launches scrcpy matching the laptop's exact screen resolution in desktop/DeX mode.

.DESCRIPTION
    Continuously listens for ADB device connections. When a supported Samsung Galaxy
    phone is detected in an authorized state, it automatically detects the host laptop's
    native physical display resolution (FHD, WUXGA, 2K, 4K, etc.), configures desktop mode
    settings, and launches scrcpy in matching fullscreen mode.
#>

param(
    [string]$Resolution = "auto",                                    # "auto" (detects screen) or explicit e.g. 1920x1080, 1920x1200
    [int]$Dpi = 0,                                                   # 0 = auto (160 for <=1200p, 220 for 1440p/1600p, 320 for 4K)
    [string]$ModelPattern = "SM[-_]?S9[1234]8|pa[23]q|e[23]q|e2s",   # S24 Ultra (S928), S25 Ultra (S938), S23 Ultra (S918)
    [string]$Bitrate = "40M",                                        # Stream bitrate (40M for crisp text over USB)
    [bool]$Fullscreen = $true,                                       # Open scrcpy in fullscreen by default
    [switch]$FlexDisplay = $false,                                   # Dynamically match virtual display to window size
    [string]$CustomScrcpyPath = "",                                  # Optional explicit path to scrcpy.exe
    [string]$CustomAdbPath = ""                                      # Optional explicit path to adb.exe
)

# --- Physical Screen Resolution Detection ---
function Get-PrimaryDisplayResolution {
    # Method 1: Win32 API via Add-Type (returns true physical resolution unaffected by Windows DPI scaling)
    try {
        $signature = @'
[DllImport("user32.dll")]
public static extern IntPtr GetDC(IntPtr hwnd);
[DllImport("gdi32.dll")]
public static extern int GetDeviceCaps(IntPtr hdc, int nIndex);
[DllImport("user32.dll")]
public static extern int ReleaseDC(IntPtr hwnd, IntPtr hdc);
public static System.Drawing.Size GetPhysicalResolution() {
    IntPtr hdc = GetDC(IntPtr.Zero);
    int width = GetDeviceCaps(hdc, 118); // DESKTOPHORZRES
    int height = GetDeviceCaps(hdc, 117); // DESKTOPVERTRES
    ReleaseDC(IntPtr.Zero, hdc);
    return new System.Drawing.Size(width, height);
}
'@
        Add-Type -MemberDefinition $signature -Name "NativeScreen" -Namespace "DisplayUtil" -ReferencedAssemblies "System.Drawing" -ErrorAction Stop
        $size = [DisplayUtil.NativeScreen]::GetPhysicalResolution()
        if ($size.Width -gt 0 -and $size.Height -gt 0) {
            return "$($size.Width)x$($size.Height)"
        }
    } catch {}

    # Method 2: CIM Win32_VideoController
    try {
        $vc = Get-CimInstance -ClassName Win32_VideoController | Where-Object { $_.CurrentHorizontalResolution -gt 0 } | Select-Object -First 1
        if ($vc) {
            return "$($vc.CurrentHorizontalResolution)x$($vc.CurrentVerticalResolution)"
        }
    } catch {}

    # Method 3: .NET Windows Forms
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
        return "$($bounds.Width)x$($bounds.Height)"
    } catch {}

    return "1920x1080" # Default fallback
}

# Resolve Resolution
if ($Resolution -eq "auto" -or [string]::IsNullOrWhiteSpace($Resolution)) {
    $effectiveResolution = Get-PrimaryDisplayResolution
    $isAutoRes = $true
} else {
    $effectiveResolution = $Resolution
    $isAutoRes = $false
}

# Auto-calculate DPI if not specified
if ($Dpi -le 0) {
    if ($effectiveResolution -match "^(\d+)x(\d+)$") {
        $width = [int]$Matches[1]
        if ($width -ge 3840) {
            $effectiveDpi = 320 # 4K displays
        } elseif ($width -ge 2560) {
            $effectiveDpi = 220 # 1440p / 1600p displays
        } else {
            $effectiveDpi = 160 # 1080p / 1200p displays (native 1:1 mdpi)
        }
    } else {
        $effectiveDpi = 160
    }
} else {
    $effectiveDpi = $Dpi
}

# --- Path Discovery ---
function Find-Executable {
    param([string]$Name, [string]$ExplicitPath, [string[]]$Fallbacks)
    if ($ExplicitPath -and (Test-Path $ExplicitPath)) {
        return (Resolve-Path $ExplicitPath).Path
    }
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }
    foreach ($fb in $Fallbacks) {
        if ($fb -match "\*") {
            $matched = Get-ChildItem -Path $fb -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($matched) { return $matched.FullName }
        } elseif (Test-Path $fb) {
            return (Resolve-Path $fb).Path
        }
    }
    return $null
}

function Get-DeviceFriendlyName {
    param([string]$RawLine, [string]$Model)
    if ($RawLine -match "SM[-_]?S938" -or $Model -match "SM[-_]?S938" -or $RawLine -match "pa3q|e3q") {
        return "Samsung Galaxy S25 Ultra"
    } elseif ($RawLine -match "SM[-_]?S928" -or $Model -match "SM[-_]?S928" -or $RawLine -match "pa2q|e2s") {
        return "Samsung Galaxy S24 Ultra"
    } elseif ($RawLine -match "SM[-_]?S918" -or $Model -match "SM[-_]?S918") {
        return "Samsung Galaxy S23 Ultra"
    } elseif ($Model) {
        return "Samsung Galaxy ($Model)"
    }
    return "Samsung Galaxy Device"
}

$wingetBase = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages"
$adbFallbacks = @(
    "$wingetBase\Google.PlatformTools*\*\adb.exe",
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
    "C:\platform-tools\adb.exe"
)

$scrcpyFallbacks = @(
    "$wingetBase\Genymobile.scrcpy*\*\scrcpy.exe",
    "$env:LOCALAPPDATA\Programs\scrcpy\scrcpy.exe",
    "$env:USERPROFILE\scoop\apps\scrcpy\current\scrcpy.exe",
    "C:\Program Files\scrcpy\scrcpy.exe",
    "C:\scrcpy\scrcpy.exe"
)

$adbPath = Find-Executable -Name "adb.exe" -ExplicitPath $CustomAdbPath -Fallbacks $adbFallbacks
$scrcpyPath = Find-Executable -Name "scrcpy.exe" -ExplicitPath $CustomScrcpyPath -Fallbacks $scrcpyFallbacks

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "      Samsung Galaxy DeX Auto-Launcher (Scrcpy)           " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Screen Resolution : $effectiveResolution $(if ($isAutoRes) { '(Auto-Detected from Laptop)' } else { '(Custom)' }) @ $effectiveDpi DPI" -ForegroundColor Gray
Write-Host "Display Mode      : $(if ($Fullscreen) { 'Fullscreen' } else { 'Windowed' })" -ForegroundColor Gray
Write-Host "Bitrate           : $Bitrate" -ForegroundColor Gray
Write-Host "Supported Devices : Galaxy S24 Ultra, S25 Ultra & Flagship Series" -ForegroundColor Gray

if (-not $adbPath) {
    Write-Host "[!] adb.exe not found. Installing Google Platform Tools via WinGet..." -ForegroundColor Yellow
    winget install Google.PlatformTools --accept-source-agreements --accept-package-agreements
    $adbPath = Find-Executable -Name "adb.exe" -ExplicitPath $CustomAdbPath -Fallbacks $adbFallbacks
    if (-not $adbPath) {
        Write-Host "[ERROR] Failed to locate adb.exe after installation. Please restart your terminal." -ForegroundColor Red
        exit 1
    }
}
Write-Host "Using ADB         : $adbPath" -ForegroundColor DarkGray

if (-not $scrcpyPath) {
    Write-Host "[!] scrcpy.exe not found. Installing Scrcpy via WinGet..." -ForegroundColor Yellow
    winget install Genymobile.scrcpy --accept-source-agreements --accept-package-agreements
    $scrcpyPath = Find-Executable -Name "scrcpy.exe" -ExplicitPath $CustomScrcpyPath -Fallbacks $scrcpyFallbacks
    if (-not $scrcpyPath) {
        Write-Host "[ERROR] Failed to locate scrcpy.exe after installation. Please restart your terminal." -ForegroundColor Red
        exit 1
    }
}
Write-Host "Using Scrcpy      : $scrcpyPath" -ForegroundColor DarkGray

Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "Waiting for your Samsung phone to be plugged in via USB..." -ForegroundColor Green
Write-Host "Press Ctrl+C to terminate." -ForegroundColor DarkGray
Write-Host ""

$scrcpyProcess = $null
$lastReportedState = ""

while ($true) {
    if (-not $scrcpyPath) {
        $scrcpyPath = Find-Executable -Name "scrcpy.exe" -ExplicitPath $CustomScrcpyPath -Fallbacks $scrcpyFallbacks
    }

    $rawOutput = & $adbPath devices -l 2>$null
    $lines = $rawOutput -split "`r?`n" | Where-Object { $_.Trim() -and -not $_.StartsWith("List of devices") }

    $targetDevice = $null
    $isUnauthorized = $false

    foreach ($line in $lines) {
        if ($line -match $ModelPattern) {
            $parts = -split $line
            $serial = $parts[0]
            $state = $parts[1]

            if ($state -eq "device") {
                $targetDevice = [PSCustomObject]@{
                    Serial = $serial
                    Raw = $line
                    Model = ""
                }
                break
            } elseif ($state -eq "unauthorized") {
                $isUnauthorized = $true
            }
        }
    }

    # If no specific regex matched, check any connected Samsung phone
    if (-not $targetDevice -and -not $isUnauthorized) {
        foreach ($line in $lines) {
            $parts = -split $line
            if ($parts.Length -ge 2 -and $parts[1] -eq "device") {
                $candidateSerial = $parts[0]
                $devModel = (& $adbPath -s $candidateSerial shell getprop ro.product.model 2>$null).Trim()
                $devManuf = (& $adbPath -s $candidateSerial shell getprop ro.product.manufacturer 2>$null).Trim()
                if ($devModel -match $ModelPattern -or $devManuf -like "*samsung*") {
                    $targetDevice = [PSCustomObject]@{
                        Serial = $candidateSerial
                        Raw = $line
                        Model = $devModel
                    }
                    break
                }
            }
        }
    }

    if ($isUnauthorized) {
        if ($lastReportedState -ne "unauthorized") {
            Write-Host "[!] Samsung phone detected, but USB Debugging is unauthorized." -ForegroundColor Yellow
            Write-Host "    Check your phone screen and tap 'Always allow from this computer'." -ForegroundColor Yellow
            $lastReportedState = "unauthorized"
        }
    }

    if ($scrcpyProcess -ne $null -and $scrcpyProcess.HasExited) {
        Write-Host "[-] Scrcpy session ended." -ForegroundColor Gray
        $scrcpyProcess = $null
        $lastReportedState = ""
    }

    if ($targetDevice -ne $null) {
        if ($scrcpyProcess -eq $null) {
            if (-not $scrcpyPath) {
                Write-Host "[!] Samsung device connected ($($targetDevice.Serial)), but scrcpy is not installed!" -ForegroundColor Red
                Write-Host "    Run install-prerequisites.bat to install it." -ForegroundColor Yellow
                Start-Sleep -Seconds 5
                continue
            }

            $friendlyName = Get-DeviceFriendlyName -RawLine $targetDevice.Raw -Model $targetDevice.Model

            Write-Host "[+] $friendlyName detected! Serial: $($targetDevice.Serial)" -ForegroundColor Green
            Write-Host "    Configuring desktop mode & freeform window settings on phone..." -ForegroundColor Gray
            & $adbPath -s $targetDevice.Serial shell settings put global force_desktop_mode_on_external_displays 1 2>$null
            & $adbPath -s $targetDevice.Serial shell settings put global enable_freeform_support 1 2>$null

            Write-Host "    Starting Scrcpy at $effectiveResolution Desktop Mode..." -ForegroundColor Cyan

            $env:ADB = $adbPath

            try {
                $layersKey = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
                if (-not (Test-Path $layersKey)) { New-Item -Path $layersKey -Force | Out-Null }
                Set-ItemProperty -Path $layersKey -Name $scrcpyPath -Value '~ HIGHDPIAWARE' -ErrorAction SilentlyContinue
            } catch {}

            $scrcpyArgs = @(
                "-s", $targetDevice.Serial,
                "--new-display=$effectiveResolution/$effectiveDpi",
                "-K",
                "-M",
                "-w",
                "-b", $Bitrate,
                "--video-codec=h265",
                ('--window-title="Samsung DeX (' + $friendlyName + ' - ' + $effectiveResolution + ')"')
            )

            if ($Fullscreen) {
                $scrcpyArgs += "-f"
            }

            if ($FlexDisplay) {
                $scrcpyArgs += "-x"
            }

            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = $scrcpyPath
            $psi.Arguments = $scrcpyArgs -join " "
            $psi.UseShellExecute = $false

            $scrcpyProcess = [System.Diagnostics.Process]::Start($psi)
            $lastReportedState = "running"
        }
    } else {
        if ($scrcpyProcess -ne $null) {
            Write-Host "[-] Device disconnected. Closing Scrcpy..." -ForegroundColor Yellow
            try {
                $scrcpyProcess.Kill()
            } catch {}
            $scrcpyProcess = $null
            $lastReportedState = ""
        }
        if ($lastReportedState -ne "waiting" -and -not $isUnauthorized) {
            Write-Host "[*] Waiting for Samsung Galaxy phone connection..." -ForegroundColor DarkGray
            $lastReportedState = "waiting"
        }
    }

    Start-Sleep -Seconds 2
}
