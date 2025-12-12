-- ============================================================
-- QuickFx-Instrument: Select your most used instruments
-- ============================================================

local FX_LIST = {
    "OTT (Xfer Records)",
    "Squash (Minimal)",
    "Fuse Compressor (Minimal)",
    "TDR Molotok (Tokyo Dawn Labs)",
    "UAD La-2A (Universal Audio (UADx))",
    "UADx Century Tube Channel Strip (Universal Audio (UADx))",
    "The Glue (Cytomic)",
    "-------------------",
    "Edit this script..."
}

-- ============================================================
-- Utility: Popup menu builder
-- ============================================================

local function show_menu(title, items)
    local menu_str = ""
    for i, item in ipairs(items) do
        menu_str = menu_str .. item .. "|"
    end

    gfx.init(title, 0, 0, 0, 0, 0)
    gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
    local choice = gfx.showmenu(menu_str)
    gfx.quit()

    return choice
end

-- ============================================================
-- Open script in external editor
-- ============================================================

local function open_script_in_editor()
    local path = debug.getinfo(1, "S").source:sub(2)

    if reaper.GetOS():match("Win") then
        os.execute('start "" "' .. path .. '"')
    elseif reaper.GetOS():match("OSX") then
        os.execute('open "' .. path .. '"')
    else
        os.execute('xdg-open "' .. path .. '"')
    end
end

-- ============================================================
-- Main
-- ============================================================

local track = reaper.GetSelectedTrack(0, 0)
if not track then
    reaper.ShowMessageBox("No track selected.", "Error", 0)
    return
end

local choice = show_menu("Select FX", FX_LIST)

if choice == #FX_LIST then
    open_script_in_editor()
    return
end

if choice > 0 and choice < #FX_LIST then
    local fx_name = FX_LIST[choice]
    reaper.TrackFX_AddByName(track, fx_name, false, -1)
end
