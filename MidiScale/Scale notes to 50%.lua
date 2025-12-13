-- Scale selected MIDI notes to 50%, using earliest note as anchor

local take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
if not take then return end

local _, noteCount = reaper.MIDI_CountEvts(take)
local min_t = math.huge

-- Find earliest selected note
for i = 0, noteCount - 1 do
    local _, sel, _, startppq = reaper.MIDI_GetNote(take, i)
    if sel and startppq < min_t then
        min_t = startppq
    end
end

if min_t == math.huge then return end

local scale = 0.5

reaper.Undo_BeginBlock()

for i = 0, noteCount - 1 do
    local _, sel, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
    if sel then
        local length = endppq - startppq

        local new_start = min_t + (startppq - min_t) * scale
        local new_end = new_start + length * scale

        reaper.MIDI_SetNote(take, i, true, muted, new_start, new_end, chan, pitch, vel, true)
    end
end

reaper.MIDI_Sort(take)
reaper.Undo_EndBlock("Scale notes 50% (anchor = earliest note)", -1)
