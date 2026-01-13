<# :
@echo off
cd /d "%~dp0"
:: Launch PowerShell Hidden
PowerShell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "& {[ScriptBlock]::Create((Get-Content '%~f0') -join [Char]10).Invoke()}"
exit /b
#>

# --- POWERSHELL STARTS HERE ---

# Load assembly for GUI
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 1. Setup
$localFFmpeg = ".\ffmpeg.exe"
$ffmpegCommand = ""

if (Test-Path $localFFmpeg) {
    $ffmpegCommand = $localFFmpeg
} elseif (Get-Command "ffmpeg" -ErrorAction SilentlyContinue) {
    $ffmpegCommand = "ffmpeg"
} else {
    [System.Windows.Forms.MessageBox]::Show("FFmpeg not found! Please check the folder.", "Error", 0, 16)
    Exit
}

# 2. Scan for Cameras (Hidden)
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
    if ($line -match "DirectShow video devices") { $captureMode = $true; continue }
    if ($line -match "DirectShow audio devices") { $captureMode = $false; break }
    
    if ($captureMode) {
        if ($line -match '\[dshow @ .+?\]\s+\"(.+?)\"') {
            $name = $matches[1]
            if ($line -notmatch "Alternative name") {
                $cameras += $name
            }
        }
    }
}

# 4. Logic: Selection
$selectedCam = $null

if ($cameras.Count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show("No cameras found.", "Error", 0, 16)
    Exit
}
elseif ($cameras.Count -eq 1) {
    $selectedCam = $cameras[0]
}
else {
    # --- BUILD THE CUSTOM GUI ---
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Select Webcam"
    $form.Size = New-Object System.Drawing.Size(350, 220)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10, 10)
    $label.Size = New-Object System.Drawing.Size(300, 20)
    $label.Text = "Please select a camera:"

    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(10, 35)
    $listBox.Size = New-Object System.Drawing.Size(315, 100)
    foreach ($cam in $cameras) { [void] $listBox.Items.Add($cam) }
    
    # Select first item by default
    if ($listBox.Items.Count -gt 0) { $listBox.SelectedIndex = 0 }

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(120, 145)
    $okButton.Size = New-Object System.Drawing.Size(90, 30)
    $okButton.Text = "OK"
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $okButton

    $form.Controls.Add($label)
    $form.Controls.Add($listBox)
    $form.Controls.Add($okButton)

    # Show the dialog
    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $selectedCam = $listBox.SelectedItem
    }
}

# 5. Open the Dialog
if ($selectedCam) {
    & $ffmpegCommand -f dshow -show_video_device_dialog true -i video="$selectedCam" 2> $null
}
