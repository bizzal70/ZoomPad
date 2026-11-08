-- ZoomPad: two on-screen buttons that zoom the camera.
local ns = LoadAddon(ADDON_DIR, "ZoomPad")
local function check(cond, what) if not cond then error("CHECK FAILED: " .. what, 2) end; io.write("pass  ", what, "\n") end

Fire("ADDON_LOADED", "SomeOtherAddon")
check(ZoomPadDB == nil, "another addon loading does not set it up")
Fire("ADDON_LOADED", "ZoomPad")
check(ns.db == ZoomPadDB and ns.db.shown and not ns.db.locked and ns.db.step == "medium" and ns.db.size == "medium",
    "settings start with their defaults")

local pad, buttons = ns.Pad()
local plus, minus = buttons[1], buttons[2]
check(pad:IsShown() and plus.direction == "in" and minus.direction == "out", "the pad is shown with + above -")
check(pad.__point[1] == "RIGHT" and pad.__point[4] == -40, "it starts on the right edge of the screen")

local function Down(b) b.__scripts.OnMouseDown(b, "LeftButton") end
local function Up(b) b.__scripts.OnMouseUp(b, "LeftButton") end
local function Wait(b, seconds) local t = 0; while t < seconds - 1e-9 do b.__scripts.OnUpdate(b, 0.02); t = t + 0.02 end end

-- a tap
CAMERA = 15
Down(plus); Up(plus)
check(CAMERA == 13, "a tap on + zooms in one medium step (2 yards)")
Down(minus); Up(minus)
check(CAMERA == 15, "a tap on - zooms back out one step")

-- a press that is a little slow is still one tap
Down(plus); Wait(plus, 0.3); Up(plus)
check(CAMERA == 13, "a press shorter than the hold delay counts as one tap")

-- holding
CAMERA = 20; ZOOM_CALLS = 0
Down(minus); Wait(minus, 0.35 + 0.08 * 4 + 0.01); Up(minus)
check(ZOOM_CALLS == 5, "holding - keeps zooming out: one step at the delay, then one every 0.08 s (" .. ZOOM_CALLS .. ")")
check(CAMERA == 30, "and lifting the finger stops it, with no extra step for the release")
ZOOM_CALLS = 0
Wait(minus, 1)
check(ZOOM_CALLS == 0, "nothing happens after release")

-- dragging moves, never zooms
CAMERA = 15
Down(plus); plus.__scripts.OnDragStart(plus); Wait(plus, 1); plus.__scripts.OnDragStop(plus); Up(plus)
check(CAMERA == 15, "dragging a button moves the pad and does not zoom")
check(ns.db.point and ns.db.point[1] == "CENTER", "the new place is saved")

-- locked: a drag does not move, and the press still behaves as a press
ns.db.locked = true
local moved = 0
pad.StartMoving = function() moved = moved + 1 end
CAMERA = 15
Down(plus); plus.__scripts.OnDragStart(plus); Up(plus)
check(moved == 0, "a locked pad does not move when dragged")
check(CAMERA == 13, "and the press still zooms like a tap")
ns.db.locked = false
Down(plus); plus.__scripts.OnDragStart(plus); plus.__scripts.OnDragStop(plus)
check(moved == 1, "unlocked, a drag moves it")

-- size and step choices
SlashCmdList.ZOOMPAD("")
check(ZoomPadOptions:IsShown(), "/zoompad opens the options")
local rows = {}
for _, f in ipairs(Frames()) do
    if rawget(f, "Refresh") and f.__scripts.OnClick then rows[#rows + 1] = f end
end
check(#rows == 6, "the options have six controls")
rows[1].__scripts.OnClick(rows[1]); check(not ns.db.shown and not pad:IsShown(), "the first hides the buttons")
rows[1].__scripts.OnClick(rows[1]); check(ns.db.shown and pad:IsShown(), "and shows them again")
rows[2].__scripts.OnClick(rows[2]); check(ns.db.locked, "the second locks them")
rows[2].__scripts.OnClick(rows[2])
rows[3].__scripts.OnClick(rows[3]); check(not ns.db.minimapButton and not ns.MinimapButton():IsShown(), "the third hides the minimap button")
rows[3].__scripts.OnClick(rows[3]); check(ns.db.minimapButton and ns.MinimapButton():IsShown(), "and shows it again")
rows[4].__scripts.OnClick(rows[4]); check(ns.db.size == "large", "the fourth makes the buttons bigger")
rows[4].__scripts.OnClick(rows[4]); check(ns.db.size == "small", "and comes round to small")
rows[5].__scripts.OnClick(rows[5]); check(ns.db.step == "large", "the fifth makes each tap zoom further")
CAMERA = 15; Down(plus); Up(plus)
check(CAMERA == 11, "a large step is 4 yards")
ns.db.point = { "TOPLEFT", "TOPLEFT", 10, -10 }
rows[6].__scripts.OnClick(rows[6]); check(ns.db.point == nil and pad.__point[1] == "RIGHT", "the sixth puts the pad back where it started")
ZoomPad_OnAddonCompartmentClick()
check(not ZoomPadOptions:IsShown(), "the minimap addon list entry toggles the options")

-- the minimap button
local mb = ns.MinimapButton()
local desaturated
mb.icon.SetDesaturated = function(_, v) desaturated = v end
check(mb:IsShown() and ns.db.minimapAngle == -1.9, "the minimap button is shown on the rim, below-left")
mb.__scripts.OnClick(mb, "LeftButton")
check(not ns.db.shown and not pad:IsShown() and desaturated == true, "clicking it hides the zoom buttons and greys its icon")
mb.__scripts.OnClick(mb, "LeftButton")
check(ns.db.shown and pad:IsShown() and desaturated == false, "clicking again brings them back in colour")
mb.__scripts.OnClick(mb, "RightButton")
check(ZoomPadOptions:IsShown() and ns.db.shown, "right-click opens the options and leaves the zoom buttons alone")
mb.__scripts.OnClick(mb, "RightButton")
mb.__scripts.OnEnter(mb)
mb.__scripts.OnDragStart(mb); mb.__scripts.OnUpdate(mb); mb.__scripts.OnDragStop(mb)
check(ns.db.minimapAngle ~= -1.9, "dragging slides it to a new place on the rim, which is saved")
-- the game never sends OnDragStop: the button stops by itself once the mouse button is up
mb.__scripts.OnDragStart(mb)
check(mb.__scripts.OnUpdate ~= nil, "while dragging, the button follows the cursor")
MOUSE_DOWN = false
mb.__scripts.OnUpdate(mb)
check(mb.__scripts.OnUpdate == nil, "once the mouse button is up it stops following, even without OnDragStop")
MOUSE_DOWN = true
SlashCmdList.ZOOMPAD("button"); check(not mb:IsShown(), "/zoompad button hides the minimap button")
SlashCmdList.ZOOMPAD("button"); check(mb:IsShown(), "and brings it back")
SlashCmdList.ZOOMPAD("hide"); check(desaturated == true, "hiding the zoom buttons any other way greys the icon too")
SlashCmdList.ZOOMPAD("show")

-- slash commands
SlashCmdList.ZOOMPAD("hide"); check(not pad:IsShown(), "/zoompad hide")
SlashCmdList.ZOOMPAD("show"); check(pad:IsShown(), "/zoompad show")
CAMERA = 15; SlashCmdList.ZOOMPAD("out"); check(CAMERA == 19, "/zoompad out zooms, for a macro")
SlashCmdList.ZOOMPAD("help")

-- a game that refuses
local said = #PRINTED
CameraZoomIn = function() error("blocked") end
Down(plus); Up(plus); Down(plus); Up(plus)
check(#PRINTED == said + 1, "if the game refuses to zoom, it says so once, without an error")

-- saved choices kept, missing ones filled in
ZoomPadDB = { size = "large", shown = false }
local ns2 = LoadAddon(ADDON_DIR, "ZoomPad")
Fire("ADDON_LOADED", "ZoomPad")
check(ns2.db.size == "large" and ns2.db.shown == false and ns2.db.step == "medium", "saved choices are kept and new settings get defaults")

-- a button left where 0.2.0 put it moves; one the player dragged stays
ZoomPadDB = { minimapAngle = 3.6, placed023 = true }
local ns3 = LoadAddon(ADDON_DIR, "ZoomPad"); Fire("ADDON_LOADED", "ZoomPad")
check(ns3.db.minimapAngle == -1.9, "a minimap button never moved from 0.2.0's spot goes to the new one")
ZoomPadDB = { minimapAngle = 1.2, placed023 = true }
local ns4 = LoadAddon(ADDON_DIR, "ZoomPad"); Fire("ADDON_LOADED", "ZoomPad")
check(ns4.db.minimapAngle == 1.2, "a minimap button the player placed stays put")

-- texture paths keep their backslashes (lost once, which made the button invisible)
local h = io.open(ADDON_DIR .. "/MinimapButton.lua"); local src = h:read("*a"); h:close()
local B = string.char(92)
check(not src:find('"Interface' .. B .. "%a") and src:find('"Interface' .. B .. B .. "Icons"), "texture paths in MinimapButton.lua use doubled backslashes")
ZoomPadDB = { minimapAngle = 2.88 }
local ns5 = LoadAddon(ADDON_DIR, "ZoomPad"); Fire("ADDON_LOADED", "ZoomPad")
check(ns5.db.minimapAngle == -1.9 and ns5.db.placed023, "a button from before 0.2.3 is put back at the start once")
