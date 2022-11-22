-- Floppy Rocker
-- by MineRobber___T
-- Requires aukit and an attached speaker

if not package.path:find("lib/?") then package.path=package.path..";lib/?;lib/?.lua;lib/?/init.lua" end

if not pcall(require,"aukit") then error"Requires aukit" end
local aukit=package.loaded.aukit

local fs=fs
local peripheral=peripheral
if _HOST:find("Recrafted") then -- nobody's gonna use this, let alone someone using Recrafted, but just in case
    fs=require"fs"
    peripheral=require"peripheral"
end

local function formatDuration(s)
    local m, s = math.floor(s/60), s%60
    if m<60 then return ("%d:%.2f"):format(m,s) end
    local h
    h, m = math.floor(m/60), m%60
    return ("%d:%d:%.2f"):format(h,m,s)
end

local speaker=peripheral.find"speaker"
if not speaker then error"Requires speaker" end

local disk=...

local filedata=""
if disk then
    if peripheral.getType(disk)=="drive" then -- drive
        disk=peripheral.call(disk,"getMountPath")
    else
        disk=shell.resolve(disk)
    end
    if fs.exists(disk) then -- path (or drive fallthrough)
        if not fs.isDir(disk) then -- allow playing raw files
            print("Loading "..disk.."...")
            local h=fs.open(disk,"rb")
            filedata=h.readAll()
            h.close()
            print("Loaded!")
        else
            local files=fs.list(disk)
            if #files>1 then error"Multiple-file disks are not supported at this time." end
            local start=os.epoch"utc"
            for chunk in io.lines(fs.combine(disk,files[1]),16*1024) do
                filedata=filedata..chunk
                if os.epoch"utc"-start>1000 then sleep(0) end
            end
        end
    else
        error"No file with that name, and no drive with that name."
    end
else
    print("Drag and drop a .fr file onto the screen.")
    local ev, files = os.pullEvent("file_transfer")
    local files=files.getFiles()
    if #files>1 then error"Multiple-file drops are not supported at this time." end
    local file=files[1]
    write("Loading "..file.getName().."... ")
    filedata=file.readAll()
    print("success!")
end

local version, divider = string.unpack("BB",filedata)
if version>0 then error("Unknown Floppy Rockers version "..version) end
local sounddata = filedata:sub(3)

print("Loading audio data... (this might take a while)")
local audio = aukit.dfpwm(sounddata,1,48000/divider)
print("Loaded!")
print("Sample rate: "..audio.sampleRate)
print("Length: "..formatDuration(audio:len()))
if audio.sampleRate~=48000 then
    print("Resampling...")
    audio=audio:resample(48000,"cubic")
    print("Done!")
end
local stream = audio:stream(128*1024)
local data = stream()
while data do
    while not speaker.playAudio(data[1]) do
        os.pullEvent("speaker_audio_empty")
    end
    data=stream()
end
