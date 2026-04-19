DEVICES = {}
MAX_DEVICES = 8
SELECTED = ''

function Initialize()
    SELECTED = SKIN:GetVariable('AudioDevice') or ''
    RefreshDevices()
end

function Update()
end

function RefreshDevices()
    local tmpFile = SKIN:GetVariable('CURRENTPATH') .. 'audio_devices.txt'
    local cmd = 'powershell -NoProfile -Command "' ..
        'Get-WmiObject Win32_SoundDevice | Select-Object -ExpandProperty Name | ' ..
        'Select-Object -Unique | Out-File -FilePath \'' .. tmpFile .. '\' -Encoding ASCII"'
    os.execute(cmd)

    DEVICES = {}
    local f = io.open(tmpFile, 'r')
    if f then
        local content = f:read('*all')
        f:close()
        content = content:gsub('^\xEF\xBB\xBF', '')
        for line in content:gmatch('[^\r\n]+') do
            line = line:match('^%s*(.-)%s*$')
            if line ~= '' and #DEVICES < MAX_DEVICES then
                table.insert(DEVICES, line)
            end
        end
    end

    UpdateButtons()
end

function EscapeForRainmeter(str)
    str = str:gsub('\\', '\\\\')
    str = str:gsub('"', '\\"')
    return str
end

function UpdateButtons()
    SELECTED = SKIN:GetVariable('AudioDevice') or ''

    for i = 1, MAX_DEVICES do
        local name = DEVICES[i] or ''
        if name == '' then
            SKIN:Bang('!HideMeter DeviceBtn' .. i)
        else
            local escapedName = EscapeForRainmeter(name)
            SKIN:Bang('!SetOption DeviceBtn' .. i .. ' Text "' .. escapedName .. '"')
            
            if name == SELECTED then
                SKIN:Bang('!SetOption DeviceBtn' .. i .. ' SolidColor "80,180,80,220"')
                SKIN:Bang('!SetOption DeviceBtn' .. i .. ' FontColor "255,255,255,255"')
            else
                SKIN:Bang('!SetOption DeviceBtn' .. i .. ' SolidColor "255,255,255,180"')
                SKIN:Bang('!SetOption DeviceBtn' .. i .. ' FontColor "0,0,0,255"')
            end
            SKIN:Bang('!ShowMeter DeviceBtn' .. i)
        end
    end

    local currentLabel = 'Current: System default'
    if SELECTED ~= '' then
        currentLabel = 'Current: ' .. EscapeForRainmeter(SELECTED)
    end
    SKIN:Bang('!SetOption LabelAudioCurrent Text "' .. currentLabel .. '"')

    SKIN:Bang('!UpdateMeter *')
    SKIN:Bang('!Redraw')
end

function SelectDevice(idx)
    idx = tonumber(idx)
    if not idx or idx < 1 or idx > #DEVICES then return end
    
    SELECTED = DEVICES[idx]
    local varFile = SKIN:GetVariable('ROOTCONFIGPATH') .. '@Resources\\variables.inc'
    
    local escapedDevice = EscapeForRainmeter(SELECTED)
    
    SKIN:Bang('!WriteKeyValue Variables AudioDevice "' .. escapedDevice .. '" "' .. varFile .. '"')
    SKIN:Bang('!WriteKeyValue Variables AudioDeviceIndex "' .. tostring(idx - 1) .. '" "' .. varFile .. '"')
    
    SKIN:Bang('!Refresh')
    SKIN:Bang('!Refresh "Minimalism Spotify Player (MSP)" "MinimalSpotifyVisualizer.ini"')
    
    UpdateButtons()
end

function ResetDevice()
    SELECTED = ''
    local varFile = SKIN:GetVariable('ROOTCONFIGPATH') .. '@Resources\\variables.inc'
    SKIN:Bang('!WriteKeyValue Variables AudioDevice "" "' .. varFile .. '"')
    SKIN:Bang('!WriteKeyValue Variables AudioDeviceIndex "" "' .. varFile .. '"')
    
    SKIN:Bang('!Refresh')
    SKIN:Bang('!Refresh "Minimalism Spotify Player (MSP)" "MinimalSpotifyVisualizer.ini"')
    
    UpdateButtons()
end