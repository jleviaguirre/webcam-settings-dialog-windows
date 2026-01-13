<# :
@echo off
:: Force the script to run from the folder it is located in
cd /d "%~dp0"

:: Launch PowerShell
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {[ScriptBlock]::Create((Get-Content '%~f0') -join [Char]10).Invoke()}"
exit /b
#>

# --- POWERSHELL STARTS HERE ---

# 1. Setup
Clear-Host
$host.UI.RawUI.WindowTitle = "Webcam Selector"
$localFFmpeg = ".\ffmpeg.exe"
$ffmpegCommand = ""

# Check for FFmpeg location
if (Test-Path $localFFmpeg) {
    $ffmpegCommand = $localFFmpeg
} elseif (Get-Command "ffmpeg" -ErrorAction SilentlyContinue) {
    $ffmpegCommand = "ffmpeg"
} else {
    Write-Warning "FFmpeg not found!"
    Write-Host "Please ensure ffmpeg.exe is in: $((Get-Location).Path)" -ForegroundColor Red
    Pause; Exit
}

# 2. Scan for Cameras
Write-Host "Scanning for video devices..." -ForegroundColor Cyan
$processInfo = New-Object System.Diagnostics.ProcessStartInfo
$processInfo.FileName = $ffmpegCommand
$processInfo.Arguments = "-list_devices true -f dshow -i dummy"
$processInfo.RedirectStandardError = $true
$processInfo.UseShellExecute = $false
$processInfo.CreateNoWindow = $true

$process = [System.Diagnostics.Process]::Start($processInfo)
$output = $process.StandardError.ReadToEnd()
$process.WaitForExit()

# 3. Parse the List
$cameras = @()
$lines = $output -split "`r`n"
$captureMode = $false

foreach ($line in $lines) {
    # Start capturing when we see the Video header
    if ($line -match "DirectShow video devices") { $captureMode = $true; continue }
    # Stop capturing when we hit the Audio header
    if ($line -match "DirectShow audio devices") { $captureMode = $false; break }
    
    if ($captureMode) {
        # Regex to find names inside quotes, ignoring "Alternative name" lines
        if ($line -match '\[dshow @ .+?\]\s+\"(.+?)\"') {
            $name = $matches[1]
            if ($line -notmatch "Alternative name") {
                $cameras += $name
            }
        }
    }
}

# 4. Logic: One Camera vs Multiple
$selectedCam = ""

if ($cameras.Count -eq 0) {
    Write-Host "No cameras found." -ForegroundColor Red
    Pause; Exit
}
elseif ($cameras.Count -eq 1) {
    $selectedCam = $cameras[0]
    Write-Host "Only one camera found: $selectedCam" -ForegroundColor Green
}
else {
    # Multiple cameras found - Ask user
    Write-Host "`nMultiple cameras found. Please select one:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $cameras.Count; $i++) {
        Write-Host " [$($i+1)] $($cameras[$i])"
    }
    
    $selection = Read-Host "`nEnter number (1-$($cameras.Count))"
    
    # Validate input
    if ($selection -match "^\d+$" -and $selection -le $cameras.Count -and $selection -gt 0) {
        $selectedCam = $cameras[$selection - 1]
    } else {
        Write-Host "Invalid selection. Exiting." -ForegroundColor Red
        Pause; Exit
    }
}

# 5. Open the Dialog
Write-Host "`nOpening settings for: $selectedCam" -ForegroundColor Green
& $ffmpegCommand -f dshow -show_video_device_dialog true -i video="$selectedCam" 2> $null

# Brief pause to ensure command executes
Start-Sleep -Seconds 1
