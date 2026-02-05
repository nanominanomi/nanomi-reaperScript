-- Arrange: Scale selected items to 50% (anchor = earliest item)

local item_count = reaper.CountSelectedMediaItems(0)
if item_count == 0 then return end

local min_pos = math.huge

-- Find anchor (earliest item start)
for i = 0, item_count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    if pos < min_pos then
        min_pos = pos
    end
end

local scale = 0.5

reaper.Undo_BeginBlock()

for i = 0, item_count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)

    local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

    local new_pos = min_pos + (pos - min_pos) * scale
    local new_len = len * scale

    reaper.SetMediaItemInfo_Value(item, "D_POSITION", new_pos)
    reaper.SetMediaItemInfo_Value(item, "D_LENGTH", new_len)
end

reaper.UpdateArrange()
reaper.Undo_EndBlock("Arrange: Scale items 50% (anchor earliest)", -1)
