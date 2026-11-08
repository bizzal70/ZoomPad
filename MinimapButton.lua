local addonName, ns = ...

-- A button on the rim of the minimap. Click: hide or show the zoom buttons.
-- Right-click: the options. Drag: slide it round the minimap. The icon
-- turns grey while the zoom buttons are hidden.

local button = CreateFrame("Button", addonName .. "MinimapButton", Minimap)
button:SetSize(31, 31)
button:SetFrameStrata("MEDIUM")
button:SetFrameLevel(8)
button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
button:RegisterForDrag("LeftButton")
button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
button:Hide()

local background = button:CreateTexture(nil, "BACKGROUND")
background:SetSize(24, 24)
background:SetPoint("CENTER")
background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

local icon = button:CreateTexture(nil, "ARTWORK")
icon:SetSize(18, 18)
icon:SetPoint("CENTER")
icon:SetTexture("Interface\\Icons\\INV_Misc_Spyglass_03")
icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
button.icon = icon

local border = button:CreateTexture(nil, "OVERLAY")
border:SetSize(50, 50)
border:SetPoint("TOPLEFT")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

local function Place()
    local angle = ns.db.minimapAngle
    local radius = Minimap:GetWidth() / 2 + 5
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

-- Dragging slides the button around the rim of the minimap.
local function FollowCursor(self)
    -- Stop as soon as the mouse button is up, even if the game never sent
    -- OnDragStop (it can go missing when two buttons overlap); otherwise the
    -- button would keep following the cursor and drag along with another.
    if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then
        self:SetScript("OnUpdate", nil)
        return
    end
    local centerX, centerY = Minimap:GetCenter()
    local cursorX, cursorY = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    ns.db.minimapAngle = math.atan2(cursorY / scale - centerY, cursorX / scale - centerX)
    Place()
end

local function ShowTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("ZoomPad")
    GameTooltip:AddLine(ns.db.shown and "Click: hide the zoom buttons" or "Click: show the zoom buttons", 1, 1, 1)
    if ns.db.shown and not ns.PadVisible() then
        GameTooltip:AddLine("No controller connected: the buttons appear when one is.", 1, 0.82, 0, true)
    end
    GameTooltip:AddLine("Right-click: options", 1, 1, 1)
    GameTooltip:AddLine("Drag: move this button", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end

button:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", FollowCursor) end)
button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
button:SetScript("OnHide", function(self) self:SetScript("OnUpdate", nil) end)
button:SetScript("OnClick", function(self, mouseButton)
    if mouseButton == "RightButton" then
        ns.ToggleOptions()
    else
        ns.SetPadShown(not ns.db.shown)
        if GameTooltip:IsOwned(self) then ShowTooltip(self) end
    end
end)
button:SetScript("OnEnter", ShowTooltip)
button:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Shows or hides the minimap button as the setting says, and greys the
-- icon while the zoom buttons are hidden.
function ns.UpdateMinimapButton()
    if not ns.db then return end
    icon:SetDesaturated(not ns.PadVisible())
    if ns.db.minimapButton then
        Place()
        button:Show()
    else
        button:Hide()
    end
end

function ns.MinimapButton() return button end
