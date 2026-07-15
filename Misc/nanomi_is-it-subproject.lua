-- Tell REAPER this script supports a toggle state
reaper.set_action_options(1)

-- Get script identity
local _, _, sectionId, cmdId, _, _, _ = reaper.get_action_context()

-- Check selected item
local item = reaper.GetSelectedMediaItem(0, 0)
local newState = 0

if item then
  local take = reaper.GetActiveTake(item)
  if take then
    local source = reaper.GetMediaItemTake_Source(take)
    local _, sourceType = reaper.GetMediaSourceType(source, "")
    if sourceType == "RPP" then
      newState = 1  -- subproject = true
    end
  end
end

-- Apply the state
reaper.SetToggleCommandState(sectionId, cmdId, newState)
reaper.RefreshToolbar2(sectionId, cmdId)
