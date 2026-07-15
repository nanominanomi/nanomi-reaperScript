-- Tell REAPER this script supports a toggle state
reaper.set_action_options(1)

-- Get script identity
local _, _, sectionId, cmdId, _, _, _ = reaper.get_action_context()

-- Check selected item
local item = reaper.GetSelectedMediaItem(0, 0)
local newState = 0

if item then
  local take = reaper.GetActiveTake(item)
  if take and not reaper.TakeIsMIDI(take) then
    newState = 1  -- audio = true
  end
end

-- Apply the state
reaper.SetToggleCommandState(sectionId, cmdId, newState)
reaper.RefreshToolbar2(sectionId, cmdId)