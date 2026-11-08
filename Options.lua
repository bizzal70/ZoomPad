local addonName, ns = ...

-- A small options window, drawn from plain colours so it needs no texture
-- files. Everything here can also be set with /zoompad.

local ACCENT_R, ACCENT_G, ACCENT_B = 0.50, 0.78, 1.00

local window
local controls = {}

local function Fill(frame, r, g, b, a)
    local texture = frame:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints()
    texture:SetColorTexture(r, g, b, a)
    return texture
end

local function Outline(frame, alpha)
    local function Edge(point1, point2, isVertical)
        local edge = frame:CreateTexture(nil, "BORDER")
        edge:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, alpha)
        edge:SetPoint(point1)
        edge:SetPoint(point2)
        if isVertical then edge:SetWidth(1) else edge:SetHeight(1) end
    end
    Edge("TOPLEFT", "TOPRIGHT", false)
    Edge("BOTTOMLEFT", "BOTTOMRIGHT", false)
    Edge("TOPLEFT", "BOTTOMLEFT", true)
    Edge("TOPRIGHT", "BOTTOMRIGHT", true)
end

-- A row that reads its text and tick from the saved settings each time it
-- is refreshed, and changes them when clicked.
local function CreateRow(parent, y, isCheckbox, getText, isTicked, onClick)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(300, 24)
    row:SetPoint("TOPLEFT", 14, y)
    local hover = row:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints()
    hover:SetColorTexture(1, 1, 1, 0.07)

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    local tick
    if isCheckbox then
        local box = CreateFrame("Frame", nil, row)
        box:SetSize(14, 14)
        box:SetPoint("LEFT", 2, 0)
        Fill(box, 0, 0, 0, 0.5)
        Outline(box, 0.7)
        tick = box:CreateTexture(nil, "ARTWORK")
        tick:SetPoint("TOPLEFT", 3, -3)
        tick:SetPoint("BOTTOMRIGHT", -3, 3)
        tick:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 1)
        label:SetPoint("LEFT", box, "RIGHT", 8, 0)
    else
        Fill(row, 1, 1, 1, 0.06)
        Outline(row, 0.35)
        label:SetPoint("CENTER")
    end

    function row.Refresh()
        label:SetText(getText())
        if tick then
            tick:SetShown(isTicked() and true or false)
        end
    end
    row:SetScript("OnClick", function()
        onClick()
        ns.RefreshOptions()
        ns.RefreshPad()
        ns.UpdateMinimapButton()
    end)
    controls[#controls + 1] = row
    return row
end

local function CreateWindow()
    window = CreateFrame("Frame", addonName .. "Options", UIParent)
    window:SetSize(328, 274)
    window:SetPoint("CENTER")
    window:SetFrameStrata("HIGH")
    window:SetToplevel(true)
    window:EnableMouse(true)
    window:SetMovable(true)
    window:SetClampedToScreen(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:Hide()
    Fill(window, 0.05, 0.05, 0.06, 0.97)
    Outline(window, 0.55)
    -- Lets Escape close the window.
    tinsert(UISpecialFrames, addonName .. "Options")

    local title = window:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 14, -12)
    title:SetText("ZoomPad")

    local close = CreateFrame("Button", nil, window)
    close:SetSize(30, 30)
    close:SetPoint("TOPRIGHT", -2, -2)
    local closeHover = close:CreateTexture(nil, "HIGHLIGHT")
    closeHover:SetAllPoints()
    closeHover:SetColorTexture(0.9, 0.2, 0.2, 0.45)
    local closeLabel = close:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    closeLabel:SetPoint("CENTER")
    closeLabel:SetText("x")
    close:SetScript("OnClick", function() window:Hide() end)

    CreateRow(window, -46, true,
        function() return "Show the zoom buttons" end,
        function() return ns.db.shown end,
        function() ns.db.shown = not ns.db.shown end)
    CreateRow(window, -74, true,
        function() return "Lock them in place" end,
        function() return ns.db.locked end,
        function() ns.db.locked = not ns.db.locked end)
    CreateRow(window, -102, true,
        function() return "Show the minimap button" end,
        function() return ns.db.minimapButton end,
        function() ns.db.minimapButton = not ns.db.minimapButton end)
    -- Each of these steps to the next choice.
    CreateRow(window, -138, false,
        function() return "Button size: " .. ns.Size().label end,
        nil,
        function() ns.db.size = ns.NextKey(ns.SIZES, ns.db.size) end)
    CreateRow(window, -170, false,
        function() return "Zoom per tap: " .. ns.Step().label end,
        nil,
        function() ns.db.step = ns.NextKey(ns.STEPS, ns.db.step) end)
    CreateRow(window, -202, false,
        function() return "Put the buttons back where they started" end,
        nil,
        function() ns.db.point = nil end)

    local hint = window:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", 16, -234)
    hint:SetWidth(296)
    hint:SetJustifyH("LEFT")
    hint:SetText("Tap + or - to zoom one step; hold to keep zooming. While unlocked, drag either button to move them.")
end

function ns.RefreshOptions()
    for _, control in ipairs(controls) do
        control.Refresh()
    end
end

function ns.ToggleOptions()
    if not window then CreateWindow() end
    if window:IsShown() then
        window:Hide()
    else
        ns.RefreshOptions()
        window:Show()
    end
end
