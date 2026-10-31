@echo off
title Detect Screen Resolution
cd /d "%~dp0"

echo ==========================================================
echo   Screen Resolution Detector
echo ==========================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command "& { Add-Type -AssemblyName System.Drawing; try { $sig = '[DllImport(\"user32.dll\")] public static extern IntPtr GetDC(IntPtr h); [DllImport(\"gdi32.dll\")] public static extern int GetDeviceCaps(IntPtr h, int i); [DllImport(\"user32.dll\")] public static extern int ReleaseDC(IntPtr h, IntPtr d); public static System.Drawing.Size Get() { IntPtr d = GetDC(IntPtr.Zero); int w = GetDeviceCaps(d, 118); int h = GetDeviceCaps(d, 117); ReleaseDC(IntPtr.Zero, d); return new System.Drawing.Size(w, h); }'; Add-Type -MemberDefinition $sig -Name 'D' -Namespace 'S' -ReferencedAssemblies 'System.Drawing' -ErrorAction Stop; $s = [S.D]::Get(); $res = \"$($s.Width)x$($s.Height)\" } catch { $vc = Get-CimInstance Win32_VideoController | Where-Object { $_.CurrentHorizontalResolution -gt 0 } | Select-Object -First 1; $res = \"$($vc.CurrentHorizontalResolution)x$($vc.CurrentVerticalResolution)\" }; Write-Host 'Primary Display Resolution : ' -NoNewline; Write-Host $res -ForegroundColor Green; Write-Host 'Aspect Ratio               : ' -NoNewline; if ($res -match '(\d+)x(\d+)') { $w=[int]$matches[1]; $h=[int]$matches[2]; $gcd = { param($a,$b) while ($b -ne 0) { $t=$b; $b=$a%%$b; $a=$t }; return $a }; $g=& $gcd $w $h; Write-Host \"$($w/$g):$($h/$g)\" -ForegroundColor Cyan }; Write-Host ''; Write-Host 'start-dex.bat will automatically use this native resolution!' -ForegroundColor Gray }"

echo.
pause
