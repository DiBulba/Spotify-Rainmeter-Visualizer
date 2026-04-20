local MAX_DEVICES = 8
local DEVICES = {}
local SELECTED_ID = ''
function Initialize()
    RES_PATH = SKIN:GetVariable('@')
    VAR_FILE = RES_PATH .. 'variables.inc'
    TMP_FILE = RES_PATH .. 'audio_devices.txt'
    SELECTED_ID = SKIN:GetVariable('AudioDeviceID', '')
    print('LOG: Script Initialized')
    RefreshDevices()
end
function RefreshDevices()
    if not TMP_FILE or TMP_FILE == "" then return end
    local f = io.open(TMP_FILE, 'w')
    if f then f:close() end
    local psPath = TMP_FILE:gsub('%(', '`('):gsub('%)', '`)')
    local psCommand = [[
        [Console]::OutputEncoding = [Text.Encoding]::Default;
        $path = ']] .. psPath .. [[';
        $devs = Get-CimInstance Win32_PnPEntity | Where-Object { $_.DeviceID -like '*MMDEVAPI*' };
        $out = foreach ($d in $devs) {
            $id = $d.DeviceID -split '\\' | Select-Object -Last 1;
            $d.Name + '|' + $id
        };
        $out | Out-File -FilePath $path -Encoding Default
    ]]
    psCommand = psCommand:gsub('\n', ' ')
    os.execute('powershell -NoProfile -ExecutionPolicy Bypass -Command "' .. psCommand .. '"')
    local start = os.clock()
    while os.clock() - start < 1.2 do end
    DEVICES = {}
    local readF = io.open(TMP_FILE, 'r')
    if readF then
        local content = readF:read('*all')
        readF:close()
        content = content:gsub('^\239\187\191', '')
        for line in content:gmatch('[^\r\n]+') do
            local name, id = line:match('^(.+)|(.+)$')
            if name and id then
                table.insert(DEVICES, {
                    name = name:gsub('^%s*(.-)%s*$', '%1'),
                    id   = id:gsub('^%s*(.-)%s*$', '%1')
                })
            end
        end
    end
    print('LOG: Devices found: ' .. #DEVICES)
    UpdateButtons()
end
function UpdateButtons()
    for i = 1, MAX_DEVICES do
        SKIN:Bang('!HideMeter', 'DeviceBtn' .. i)
    end
    for i, dev in ipairs(DEVICES) do
        if i <= MAX_DEVICES then
            SKIN:Bang('!SetOption', 'DeviceBtn' .. i, 'Text', dev.name)
            if dev.id == SELECTED_ID then
                SKIN:Bang('!SetOption', 'DeviceBtn' .. i, 'SolidColor', '0,150,0,180')
            else
                SKIN:Bang('!SetOption', 'DeviceBtn' .. i, 'SolidColor', '255,255,255,180')
            end
            SKIN:Bang('!ShowMeter', 'DeviceBtn' .. i)
        end
    end
    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
end
function SelectDevice(idx)
    idx = tonumber(idx)
    if not idx or not DEVICES[idx] then return end
    local newID = DEVICES[idx].id
    local newName = DEVICES[idx].name
    SKIN:Bang('!WriteKeyValue', 'Variables', 'AudioDeviceID', newID, VAR_FILE)
    SKIN:Bang('!WriteKeyValue', 'Variables', 'AudioDevice', newName, VAR_FILE)
    SKIN:Bang('!SetOption', 'MeasureAudioOutput', 'ID', newID, 'Minimalism_Spotify_Player')
    SKIN:Bang('!Refresh', 'Minimalism_Spotify_Player')
    SELECTED_ID = newID
    UpdateButtons()
end
function ResetDevice()
    SKIN:Bang('!WriteKeyValue', 'Variables', 'AudioDeviceID', '', VAR_FILE)
    SKIN:Bang('!WriteKeyValue', 'Variables', 'AudioDevice', 'System Default', VAR_FILE)
    SKIN:Bang('!Refresh', 'Minimalism_Spotify_Player')
    SKIN:Bang('!Refresh')
end