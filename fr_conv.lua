-- Floppy Rockers converter
-- by MineRobber___T
-- MIT licensed

local function ext(s)
    local ss,e = s:find("%..+$")
    if not ss then return s end
    return s:sub(ss,e):sub(2)
end

local suffixes={
    ["kb"]=1000,
    ["kib"]=1024,
    ["mb"]=1000*1000,
    ["mib"]=1024*1024
}
local templates={
    ["drag-and-drop"]=512*1024,
    ["floppy"]=125*1000
}
local function parseSpace(s)
    if tonumber(s) then return s end
    if templates[s:lower()] then return templates[s:lower()] end
    for suffix, multiplier in pairs(suffixes) do
        if s:lower():find(suffix.."$") then
            return assert(tonumber(s:lower():gsub(suffix.."$","")),"Invalid specifier "..s)*multiplier
        end
    end
end

local aukit = require"aukit"

local input, output, space = ...
output = output or input..".fr"

space=parseSpace(space) or templates["drag-and-drop"]
local MAX_SAMPLES=(space-2)*8

local in_file = io.open(input,"rb")
local data = in_file:read("*a")
in_file:close()

print("Loading "..input.."...")
local audio
if input:match("%.dfpwm$") then audio = aukit.dfpwm(data, 1, 48000)
elseif input:match("%.wav$") then audio = aukit.wav(data)
elseif input:match("%.aiff?$") then audio = aukit.aiff(data)
elseif input:match("%.au$") then audio = aukit.au(data)
elseif input:match("%.flac$") then audio = aukit.flac(data)
else error("Cannot load "..ext(input).." file!",0) end
print("Loaded!")

-- only stores mono audio
audio = audio:mono()

-- Determine downsample divider
local audio_length = audio:len() -- audio length in seconds
local divider_w = 1
local divider_i = 1
-- tables of dividers to use (prevents fractional samplerate, which, while technically allowed, would not be good)
local GOOD_DIVIDERS = {1,2,3,4,5,6,8}
local MEH_DIVIDERS = {10,12,15,16,20,24,25,30,32}
local BAD_DIVIDERS = {40,48,50,60,64}
local DIVIDERS = {GOOD_DIVIDERS, MEH_DIVIDERS, BAD_DIVIDERS}
-- while:
--  * the current divider is not enough to make the input file fit,
--  * we're not out of divider buckets, and
--  * we're not out of dividers in that bucket,
-- move to the next divider.
while (MAX_SAMPLES/(48000/DIVIDERS[divider_w][divider_i]))<audio_length and divider_w<=#DIVIDERS and divider_i<=#DIVIDERS[divider_w] do
    if divider_i==#DIVIDERS[divider_w] then
        -- new bucket
        divider_w=divider_w+1
        divider_i=1
    else
        -- next divider in bucket
        divider_i=divider_i+1
    end
end
if divider_w>#DIVIDERS then -- ran out of buckets
    print("Could not find a good divider for "..audio_length.." seconds of audio.")
    print"Cowardly refusing to sacrifice that much audio quality..."
    error('',0)
end
-- now for warning messages
if divider_w==2 then -- meh divider
    print("WARNING: The input file ("..audio_length.." seconds) was too long for a 'good' divider.")
    print"The audio will still be encoded, but it may sound muffled, as a large amount of audio quality is lost at such low samplerates."
end
if divider_w==3 then -- bad divider
    print("WARNING: The input file ("..audio_length.." seconds) was too long for a 'good', or even 'meh' divider.")
    print"The audio will still be encoded, but it will sound extremely muffled, as a large amount of audio quality is lost at such low samplerates."
end
local divider = DIVIDERS[divider_w][divider_i]

-- now do it
print("Resampling to "..math.floor(48000/divider).."Hz...")
local resampled = audio:resample(48000/divider)
print("Done!")
local output_data = string.pack("BB",0,divider)..resampled:dfpwm()

-- abuse file chaining
io.open(output,"wb"):write(output_data):close()