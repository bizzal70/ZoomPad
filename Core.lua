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
    locked = false,
    step = "medium",
    size = "medium",
    point = nil,   -- { point, relativePoint, x, y } once moved
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

local function Describe()
    if not ns.db.shown then
        return "The zoom buttons are hidden. Type /zoompad show to bring them back."
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
        ns.Print("/zoompad lock - lock or unlock the buttons in place (unlocked, drag them to move)")
        ns.Print("/zoompad reset - put the buttons back in their starting place")
        ns.Print("/zoompad in or out - zoom one step, for a macro")
        return
    end
    ns.Print(Describe())
    ns.RefreshPad()
    ns.RefreshOptions()
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
    self:UnregisterEvent("ADDON_LOADED")
    ns.CreatePad()
    ns.RefreshPad()
end)
