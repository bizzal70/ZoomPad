local addonName, ns = ...

-- The on-screen buttons: + above -. A tap zooms one step when the finger
-- (or mouse button) comes up. Holding zooms continuously after a short
-- pause. While unlocked, dragging either button moves the pair, and a drag
-- never zooms.

local ACCENT_R, ACCENT_G, ACCENT_B = 0.50, 0.78, 1.00
local GAP = 6

local pad
local buttons = {}

local function Fill(frame, r, g, b, a, layer)
    local texture = frame:CreateTexture(nil, layer or "BACKGROUND")
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
        if isVertical then edge:SetWidth(2) else edge:SetHeight(2) end
    end
    Edge("TOPLEFT", "TOPRIGHT", false)
    Edge("BOTTOMLEFT", "BOTTOMRIGHT", false)
    Edge("TOPLEFT", "BOTTOMLEFT", true)
    Edge("TOPRIGHT", "BOTTOMRIGHT", true)
end

-- The + and - are drawn from two bars, so they look the same in every font.
local function Symbol(button, isPlus)
    local bars = {}
    local across = button:CreateTexture(nil, "ARTWORK")
    across:SetColorTexture(1, 1, 1, 0.95)
    across:SetPoint("CENTER")
    bars[#bars + 1] = { texture = across, wide = true }
    if isPlus then
        local down = button:CreateTexture(nil, "ARTWORK")
        down:SetColorTexture(1, 1, 1, 0.95)
        down:SetPoint("CENTER")
        bars[#bars + 1] = { texture = down, wide = false }
    end
    button.bars = bars
end

local function SizeSymbol(button, pixels)
    local long, thick = math.floor(pixels * 0.5), math.max(3, math.floor(pixels * 0.1))
    for _, bar in ipairs(button.bars) do
        if bar.wide then bar.texture:SetSize(long, thick) else bar.texture:SetSize(thick, long) end
    end
end

local function SavePosition()
    local point, _, relativePoint, x, y = pad:GetPoint()
    if point then
        ns.db.point = { point, relativePoint, math.floor((x or 0) + 0.5), math.floor((y or 0) + 0.5) }
    end
end

-- Puts a button back to rest: not pressed, not repeating.
local function Release(button)
    button.down = false
    button.dragging = false
    button.repeats = 0
    button.held = 0
    button.pressed:Hide()
end

local function CreateZoomButton(direction)
    local button = CreateFrame("Button", addonName .. (direction == "in" and "In" or "Out"), pad)
    button.direction = direction
    Fill(button, 0.04, 0.05, 0.07, 0.72)
    Outline(button, 0.6)
    button.pressed = Fill(button, ACCENT_R, ACCENT_G, ACCENT_B, 0.35, "ARTWORK")
    Symbol(button, direction == "in")
    button:RegisterForDrag("LeftButton")
    Release(button)

    button:SetScript("OnMouseDown", function(self, mouseButton)
        if mouseButton and mouseButton ~= "LeftButton" then return end
        self.down = true
        self.held = 0
        self.repeats = 0
        self.pressed:Show()
    end)
    button:SetScript("OnMouseUp", function(self)
        -- A quick tap that neither repeated nor dragged zooms once.
        if self.down and not self.dragging and self.repeats == 0 then
            ns.Zoom(self.direction)
        end
        Release(self)
    end)
    button:SetScript("OnUpdate", function(self, elapsed)
        if not self.down or self.dragging then return end
        self.held = self.held + elapsed
        if self.held < ns.HOLD_DELAY then return end
        -- Steps owed since the hold began repeating, at one per HOLD_EVERY.
        local owed = math.floor((self.held - ns.HOLD_DELAY) / ns.HOLD_EVERY) + 1
        while self.repeats < owed do
            self.repeats = self.repeats + 1
            ns.Zoom(self.direction)
        end
    end)
    button:SetScript("OnHide", Release)
    button:SetScript("OnDragStart", function(self)
        if ns.db.locked then return end
        self.dragging = true
        pad:StartMoving()
    end)
    button:SetScript("OnDragStop", function(self)
        pad:StopMovingOrSizing()
        SavePosition()
        Release(self)
    end)
    buttons[#buttons + 1] = button
    return button
end

function ns.CreatePad()
    if pad then return pad end
    pad = CreateFrame("Frame", addonName .. "Frame", UIParent)
    pad:SetMovable(true)
    pad:SetClampedToScreen(true)
    pad:SetFrameStrata("MEDIUM")
    CreateZoomButton("in")
    CreateZoomButton("out")
    return pad
end

function ns.RefreshPad()
    if not pad or not ns.db then return end
    local pixels = ns.Size().pixels
    pad:SetSize(pixels, pixels * 2 + GAP)
    buttons[1]:SetSize(pixels, pixels)
    buttons[1]:SetPoint("TOP", pad, "TOP", 0, 0)
    buttons[2]:SetSize(pixels, pixels)
    buttons[2]:SetPoint("BOTTOM", pad, "BOTTOM", 0, 0)
    for _, button in ipairs(buttons) do SizeSymbol(button, pixels) end

    local point = ns.db.point or ns.DEFAULT_POINT
    pad:ClearAllPoints()
    pad:SetPoint(point[1], UIParent, point[2], point[3], point[4])
    pad:SetShown(ns.PadVisible())
end

function ns.Pad() return pad, buttons end
