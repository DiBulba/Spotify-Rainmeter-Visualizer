$tmpFile = "$PSScriptRoot\..\audio_devices.txt"

# Собираем вообще все устройства, которые Windows считает аудио-точками
$devices = Get-CimInstance Win32_PnPEntity | Where-Object { 
    $_.PNPClass -eq "AudioEndpoint" -or 
    $_.Service -eq "AudioEndpoint" -or
    $_.DeviceID -like "*MMDEVAPI*"
}

if ($devices) {
    $results = foreach ($dev in $devices) {
        # Ищем GUID в формате {0.0.0.00000000}.{...}
        if ($dev.DeviceID -match "(\{0\.0\.0\..*\}|\{.*-.*-.*-.*-.*\})") {
            $dev.Name + "|" + $matches[1]
        }
    }
    $results | Unique | Out-File -FilePath $tmpFile -Encoding ascii
} else {
    "No devices found" | Out-File -FilePath $tmpFile -Encoding ascii
}