local addonName, ns = ...

-- Two big buttons on screen, + and -, that zoom the camera in and out. Made
-- for the Steam Deck's touchscreen (a tap is a mouse click), and fine with a
-- mouse too. Tap for one step; hold to keep zooming.

-- How far one step moves the camera, in yards. The game's own mouse wheel
-- step is about 1.5 at its default zoom speed.
ns.STEPS = {
    { key = "small", label = "Small", yards = 1 },
    { key = "medium", label = "Medium", yards = 2 },
    { key = "large", label = "Large", yards = 4 },
}

-- The side of each button, in pixels before the UI's own scaling.
ns.SIZES = {
    { key = "small", label = "Small", pixels = 40 },
    { key = "medium", label = "Medium", pixels = 56 },
    { key = "large", label = "Large", pixels = 72 },
}

-- Holding a button: the first repeat comes after HOLD_DELAY seconds, then
-- one step every HOLD_EVERY seconds.
ns.HOLD_DELAY = 0.35
ns.HOLD_EVERY = 0.08

-- Where the buttons start: on the right edge, a little above the middle,
-- under the right thumb on a handheld.
ns.DEFAULT_POINT = { "RIGHT", "RIGHT", -40, 60 }

local defaults = {
    shown = true,
    onlyController = true,   -- the buttons only appear once a controller is used
    locked = false,
    step = "medium",
    size = "medium",
    point = nil,   -- { point, relativePoint, x, y } once moved
    minimapButton = true,
    -- Below-left on the rim (radians, 0 = east). Clear of the author's other
    -- addons' buttons: GatherLog 3.6, SessionRecap 4.4, MacroKit 5.4, AltBoard 2.6.
    minimapAngle = -1.9,
}

function ns.Print(msg)
    print("|cff7fc8ffZoomPad|r: " .. tostring(msg))
end

local function Find(list, key)
    for _, entry in ipairs(list) do
        if entry.key == key then return entry end
    end
    return list[2] or list[1]
end

-- The entry after the current one, coming back round to the first.
function ns.NextKey(list, key)
    for index, entry in ipairs(list) do
        if entry.key == key then return list[index % #list + 1].key end
    end
    return list[1].key
end

function ns.Step() return Find(ns.STEPS, ns.db.step) end
function ns.Size() return Find(ns.SIZES, ns.db.size) end

-- Zooms one step. direction is "in" or "out". If the game refuses, says so
-- once rather than every tap.
local refusedSaid = false
function ns.Zoom(direction)
    local zoom = direction == "in" and CameraZoomIn or CameraZoomOut
    if type(zoom) ~= "function" then
        if not refusedSaid then
            refusedSaid = true
            ns.Print("This version of the game has no camera zoom for addons to use.")
        end
        return false
    end
    local ok = pcall(zoom, ns.Step().yards)
    if not ok and not refusedSaid then
        refusedSaid = true
        ns.Print("The game refused to zoom the camera. Please tell the author what you were doing.")
    end
    return ok
end

-- Whether a controller is in use: a controller button or stick has been
-- used since logging in (the game sends GAME_PAD_ACTIVE_CHANGED). Being
-- connected is not enough: on the author's PC the game reports two
-- controllers with none in use (2026-11-08). A touchscreen tap counts as
-- the mouse, so once a controller has been used the buttons stay for the
-- session rather than vanishing at every tap. Without C_GamePad the answer
-- is yes, so the buttons never vanish for good.
ns.controllerUsed = false
function ns.ControllerInUse()
    if not C_GamePad then return true end
    return ns.controllerUsed
end

-- Whether the zoom buttons are on screen right now: switched on, and a
-- controller in use unless that setting is off.
function ns.PadVisible()
    return ns.db.shown and (not ns.db.onlyController or ns.ControllerInUse()) and true or false
end

-- Shows or hides the zoom buttons, from the minimap button, the options or
-- a slash command, and keeps everything that shows the state in step.
function ns.SetPadShown(shown)
    ns.db.shown = shown and true or false
    ns.RefreshPad()
    ns.RefreshOptions()
    ns.UpdateMinimapButton()
end

local function Describe()
    if not ns.db.shown then
        return "The zoom buttons are hidden. Type /zoompad show to bring them back."
    end
    if not ns.PadVisible() then
        return "The zoom buttons appear once you use a controller. Type /zoompad always to show them without one."
    end
    return ("The zoom buttons are shown%s. Each tap zooms a %s step."):format(
        ns.db.locked and " and locked in place" or "", ns.Step().label:lower())
end

SLASH_ZOOMPAD1 = "/zoompad"
SLASH_ZOOMPAD2 = "/zpad"
SlashCmdList.ZOOMPAD = function(msg)
    local command = (msg or ""):lower():match("^%s*(%S*)")
    if command == "" or command == "options" then
        ns.ToggleOptions()
        return
    elseif command == "show" then
        ns.db.shown = true
    elseif command == "hide" then
        ns.db.shown = false
    elseif command == "toggle" then
        ns.db.shown = not ns.db.shown
    elseif command == "button" then
        ns.db.minimapButton = not ns.db.minimapButton
        ns.UpdateMinimapButton()
        ns.Print("Minimap button " .. (ns.db.minimapButton and "shown." or "hidden. Type /zoompad button to bring it back."))
        ns.RefreshOptions()
        return
    elseif command == "always" then
        ns.db.onlyController = not ns.db.onlyController
        ns.Print(ns.db.onlyController and "The zoom buttons now only appear once you use a controller."
            or "The zoom buttons now appear with or without a controller.")
    elseif command == "lock" then
        ns.db.locked = not ns.db.locked
    elseif command == "reset" then
        ns.db.point = nil
    elseif command == "in" or command == "out" then
        ns.Zoom(command)
        return
    else
        ns.Print("/zoompad - open the options")
        ns.Print("/zoompad show, hide or toggle - the zoom buttons on screen")
        ns.Print("/zoompad always - show the buttons with or without a controller (by default only with one)")
        ns.Print("/zoompad button - show or hide the minimap button")
        ns.Print("/zoompad lock - lock or unlock the buttons in place (unlocked, drag them to move)")
        ns.Print("/zoompad reset - put the buttons back in their starting place")
        ns.Print("/zoompad in or out - zoom one step, for a macro")
        return
    end
    ns.Print(Describe())
    ns.RefreshPad()
    ns.RefreshOptions()
    ns.UpdateMinimapButton()
end

-- Entry in the minimap's addon list.
function ZoomPad_OnAddonCompartmentClick()
    ns.ToggleOptions()
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, _, loaded)
    if loaded ~= addonName then return end
    ZoomPadDB = ZoomPadDB or {}
    for key, value in pairs(defaults) do
        if ZoomPadDB[key] == nil then
            ZoomPadDB[key] = value
        end
    end
    ns.db = ZoomPadDB
    -- 0.2.0 started the button at 3.6, on top of GatherLog's. If it was never
    -- dragged, move it to the new starting place.
    if ns.db.minimapAngle == 3.6 then ns.db.minimapAngle = defaults.minimapAngle end
    -- Before 0.2.3 the button drew no icon, and many ended up hidden under
    -- another addon's button. Put it back at the start once.
    if not ns.db.placed023 then ns.db.minimapAngle = defaults.minimapAngle; ns.db.placed023 = true end
    self:UnregisterEvent("ADDON_LOADED")
    ns.CreatePad()
    ns.RefreshPad()
    ns.UpdateMinimapButton()
end)

-- The first controller button or stick used: show the buttons for the rest
-- of the session.
local padWatcher = CreateFrame("Frame")
pcall(padWatcher.RegisterEvent, padWatcher, "GAME_PAD_ACTIVE_CHANGED")
padWatcher:SetScript("OnEvent", function(_, _, isActive)
    if not isActive or ns.controllerUsed then return end
    ns.controllerUsed = true
    if not ns.db then return end
    ns.RefreshPad()
    ns.UpdateMinimapButton()
end)
