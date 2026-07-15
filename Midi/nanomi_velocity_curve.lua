-- ============================================================
--   MIDI Velocity Curve Draw  (v1.0)
-- ============================================================
--  Drag across the velocity lane to draw a velocity
--  line or curve.
--
--    Horizontal drag only  →  straight ramp (start vel → end vel)
--    Move UP while dragging  →  arch upward  (middle notes louder)
--    Move DOWN while dragging →  arch downward (middle notes softer)
--
--  Requires (install both BEFORE using):
--    1. SWS Extension   →  https://www.sws-extension.org/
--    2. js_ReaScriptAPI →  install via ReaPack
-- ============================================================

-- Adjust this to taste: higher = curve reacts more to mouse movement
local CURVE_SENSITIVITY = 0.4

-- ─────────────────────────────────────────────────────────────
local SCRIPT_NAME    = "MIDI Velocity Curve Draw"
local RIGHT_BTN_MASK = 2

-- ── Dependency check ─────────────────────────────────────────
if not reaper.BR_GetMouseCursorContext then
  reaper.ShowMessageBox(
    "This script needs the SWS Extension.\n"
    .. "Download from: https://www.sws-extension.org/",
    SCRIPT_NAME, 0)
  return
end
if not reaper.JS_Mouse_GetState then
  reaper.ShowMessageBox(
    "This script needs the js_ReaScriptAPI extension.\n"
    .. "Install it via ReaPack:\n"
    .. "Extensions > ReaPack > Browse packages\n"
    .. "Search: js_ReaScriptAPI",
    SCRIPT_NAME, 0)
  return
end

-- ── MIDI Editor ──────────────────────────────────────────────
local me = reaper.MIDIEditor_GetActive()
if not me then return end
local take = reaper.MIDIEditor_GetTake(me)
if not take then return end

-- ── Helpers ──────────────────────────────────────────────────
local pi = math.pi
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
local function lerp(a, b, t)   return a + (b - a) * t end
local function round(v)        return math.floor(v + 0.5) end

-- ── State ─────────────────────────────────────────────────────
local drag_started = false
local s_ppq, s_vel = nil, nil
local e_ppq, e_vel = nil, nil
local curve        = 0.0
local prev_y       = nil
local saved        = {}

-- ── Save / restore all note velocities ───────────────────────
local function save_all()
  saved = {}
  local cnt = reaper.MIDI_CountEvts(take)
  for i = 0, cnt - 1 do
    local ok, _, _, _, _, _, _, vel = reaper.MIDI_GetNote(take, i)
    if ok then saved[i] = vel end
  end
end

local function restore_all()
  for i, vel in pairs(saved) do
    local ok, sel, mut, sp, ep, ch, pt = reaper.MIDI_GetNote(take, i)
    if ok then
      reaper.MIDI_SetNote(take, i, sel, mut, sp, ep, ch, pt, vel, true)
    end
  end
end

-- ── Apply velocity curve to notes in range ───────────────────
local function apply()
  if not s_ppq or not e_ppq then return end

  local lo, hi = s_ppq, e_ppq
  local va, vb = s_vel, e_vel
  if lo > hi then
    lo, hi = hi, lo
    va, vb = vb, va
  end

  local range = hi - lo
  local cnt   = reaper.MIDI_CountEvts(take)

  for i = 0, cnt - 1 do
    local ok, sel, mut, sp, ep, ch, pt = reaper.MIDI_GetNote(take, i)
    if ok and sp >= lo and sp <= hi then
      local t = (range > 0) and ((sp - lo) / range) or 0.5
      -- Linear ramp + sinusoidal arch (peaks at the midpoint)
      local v = lerp(va, vb, t) + curve * math.sin(pi * t)
      reaper.MIDI_SetNote(take, i, sel, mut, sp, ep, ch, pt,
                          clamp(round(v), 1, 127), true)
    end
  end
end

-- ── Read mouse position and velocity from MIDI context ────────
local function read_mouse()
  reaper.BR_GetMouseCursorContext()
  local proj_pos = reaper.BR_GetMouseCursorContext_Position()
  local _, _, _, _, ccVal, _ = reaper.BR_GetMouseCursorContext_MIDI()
  local ppq = reaper.MIDI_GetPPQPosFromProjTime(take, proj_pos)
  local vel = (type(ccVal) == "number" and ccVal >= 0 and ccVal <= 127)
              and ccVal or 64
  return ppq, vel
end

-- ── Deferred main loop ────────────────────────────────────────
local function main()
  local btn       = reaper.JS_Mouse_GetState(RIGHT_BTN_MASK)
  local _, scr_y  = reaper.GetMousePosition()

  -- Mouse released: finalize and create undo point
  if btn == 0 then
    if drag_started then
      reaper.MIDI_Sort(take)
      reaper.Undo_EndBlock(SCRIPT_NAME, -1)
    end
    return
  end

  -- First frame: initialize drag
  if not drag_started then
    drag_started = true
    curve        = 0.0
    prev_y       = scr_y
    reaper.Undo_BeginBlock()
    save_all()
    s_ppq, s_vel = read_mouse()
    e_ppq, e_vel = s_ppq, s_vel

  -- Every subsequent frame: update
  else
    e_ppq, e_vel = read_mouse()

    -- Vertical mouse delta accumulates into curve
    -- Moving up (dy negative) = arch upward = positive curve
    local dy = scr_y - prev_y
    curve    = curve - dy * CURVE_SENSITIVITY
    prev_y   = scr_y

    -- Restore originals then apply fresh result (prevents drift)
    restore_all()
    apply()
  end

  reaper.defer(main)
end

main()
