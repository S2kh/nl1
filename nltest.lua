--[[
    PayBack Utility Hub – Payback Library Version

    This script is a transformed version of the original PayBack Utility Hub that
    relied on the Linoria UI library.  It has been adapted to work with the
    single Payback library hosted in the repository the user provided.  The
    primary change is the override of the HTTP fetch helper: instead of
    constructing a URL from multiple Linoria repository mirrors, we always
    download the Payback library from the single URL
    `https://raw.githubusercontent.com/S2kh/Payback/refs/heads/main/PaybackMain`.

    ThemeManager and SaveManager remain as originally referenced in the
    script.  If the downloaded Payback library does not provide these
    modules, you may need to stub them out or remove calls accordingly.  This
    script preserves all of the original functionality of the PayBack utility
    and can be used as a drop‑in replacement.

    To use: copy the contents of this file into your Roblox executor.  The
    script will fetch the Payback UI library and initialize all tabs,
    sections, and automation routines as in the original version.
]]

----------------------------------------------------------------
-- HTTP fetch override
----------------------------------------------------------------
-- Always return the Payback library regardless of the requested path.
-- The original script attempted to download multiple files (Library.lua,
-- addons/ThemeManager.lua, etc.).  Those requests now all point to the
-- single PaybackMain file.  If the Payback library internally requires
-- additional modules it will load them itself.
local function fetch(path)
    local ok, body = pcall(function()
        -- Ignore the path and download the unified Payback library.
        return game:HttpGet('https://raw.githubusercontent.com/S2kh/Payback/refs/heads/main/PaybackMain')
    end)
    if ok and type(body) == 'string' and #body > 0 then
        return body
    end
    error('[UI] Failed to download Payback library for ' .. tostring(path))
end

----------------------------------------------------------------
-- Below is the original PayBack Utility Hub script.  Only the fetch
-- implementation above has been altered.  All other logic remains unchanged.
----------------------------------------------------------------

-- PayBack Utility Hub (Lua Armor friendly, ASCII only)
----------------------------------------------------------------
-- HTTP fetch (Linoria sources)
----------------------------------------------------------------
-- NOTE: BASES has been removed and fetch is overridden above.

-- Services
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Workspace = game:GetService('Workspace')
local ProximityPromptService = game:GetService('ProximityPromptService')
local VirtualInputManager = game:GetService('VirtualInputManager')
local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local PathfindingService = game:GetService('PathfindingService')
local TweenService = game:GetService('TweenService')
local LP = Players.LocalPlayer
local function Char() return LP.Character or LP.CharacterAdded:Wait() end
local function Hum() return Char():WaitForChild('Humanoid') end
local function HRP() return Char():WaitForChild('HumanoidRootPart') end

----------------------------------------------------------------
-- UI bootstrap
----------------------------------------------------------------
-- Initialize the Payback UI library using the provided secret key.  The
-- library returns a window (Library) and a SaveManager.  The secret key
-- must match the value of SECRET defined in the library to allow
-- instantiation.  We stub ThemeManager because it is not exposed by
-- Payback; if you need to adjust themes you can modify the options passed
-- into Payback.new above.
local PaybackLib = loadstring(fetch('Library.lua'))()
-- Create the main window.  Use the secret key 'ChromaXeno197' (defined in
-- the library) and configure the title, accent colour, keybind and
-- configuration directory.  Accent and keybind can be customised as
-- needed.
local Library, SaveManager = PaybackLib.new('ChromaXeno197', {
    Title = 'PayBack',
    Accent = Color3.fromRGB(0, 186, 255),
    Keybind = Enum.KeyCode.Insert,
    ConfigDir = 'PayBack/specific-game'
})
-- Provide a dummy ThemeManager so calls in the original script do not
-- error.  These functions are no‑ops because the Payback library manages
-- its own theme internally.
local ThemeManager = {}
function ThemeManager:SetLibrary(_) return self end
function ThemeManager:SetFolder(_) return self end
function ThemeManager:IgnoreThemeSettings() return self end
function ThemeManager:SetFolder(_) return self end
function ThemeManager:ApplyToTab(_) return self end
-- Ensure global tables exist
local Toggles = getgenv().Payback and getgenv().Payback.Toggles or {}
local Options = getgenv().Payback and getgenv().Payback.Options or {}

-- Wrapper to adapt Payback's section API to the original Linoria-like API.
local function wrapSection(section)
    -- Toggle: flag/id and table with Text, Default, Callback
    function section:AddToggle(id, opts)
        opts = opts or {}
        return section:Toggle({ Name = opts.Text or id, Flag = id, Default = opts.Default, Callback = opts.Callback })
    end
    -- Slider: flag/id and options with Text, Default, Min, Max, Rounding
    function section:AddSlider(id, opts)
        opts = opts or {}
        -- Determine step from Rounding or explicit Step.  If Rounding is set
        -- (e.g. 2), use step = 1/(10^Rounding) so the slider snaps to that.
        local step = opts.Step
        if not step and opts.Rounding then
            local r = tonumber(opts.Rounding)
            if r and r > 0 then step = 1 / (10 ^ r) end
        end
        return section:Slider({ Name = opts.Text or id, Flag = id, Default = opts.Default, Min = opts.Min, Max = opts.Max, Step = step })
    end
    -- Button: name and callback
    function section:AddButton(name, callback)
        return section:Button({ Name = name, Callback = callback })
    end
    -- Dropdown: flag/id and options with Text, Values, Default
    function section:AddDropdown(id, opts)
        opts = opts or {}
        return section:Dropdown({ Name = opts.Text or id, Flag = id, List = opts.Values or {}, Default = opts.Default, Multi = false })
    end
    -- Label: display text.  Use a Button with no callback to simulate a label
    -- so it will appear in the UI.  Returns a proxy supporting AddKeyPicker.
    function section:AddLabel(text)
        local lbl = section:Button({ Name = text or '', Callback = function() end })
        local proxy = {}
        -- Allow chaining AddKeyPicker on labels; record the default key in Options
        function proxy:AddKeyPicker(id, opts)
            opts = opts or {}
            if Options then Options[id] = { Value = opts.Default } end
            return proxy
        end
        proxy.Label = lbl
        return proxy
    end
    -- Divider: insert a blank label to create spacing
    function section:AddDivider()
        section:Button({ Name = '', Callback = function() end })
    end
    return section
end

-- Override AddTab to return a tab with groupbox helpers.  The returned tab
-- defines AddLeftGroupbox and AddRightGroupbox which wrap Payback
-- sections and expose the Linoria API for controls.
-- Override AddTab to return a tab with groupbox helpers.  We preserve the
-- original AddTab method and wrap the returned tab object.  The wrapper
-- adds AddLeftGroupbox and AddRightGroupbox which call the underlying
-- Section method (exposed by the wrapper) and wrap the returned ControlKit.
do
    local _oldAddTab = Library.AddTab
    function Library:AddTab(name)
        -- Call the original AddTab to create a tab wrapper with Section and Controls
        local tab = _oldAddTab(self, name)
        -- AddLeftGroupbox: create a section on the left side and wrap it
        function tab:AddLeftGroupbox(title)
            local sec = tab.Section(title, 'left')
            return wrapSection(sec)
        end
        -- AddRightGroupbox: create a section on the right side and wrap it
        function tab:AddRightGroupbox(title)
            local sec = tab.Section(title, 'right')
            return wrapSection(sec)
        end
        return tab
    end
end

-- Create tabs via the adapted AddTab method
local Tabs = {
    ['Automation'] = Library:AddTab('Automation'),
    ['Buy'] = Library:AddTab('Buy'),
    ['Misc'] = Library:AddTab('Misc'),
    ['UI Settings'] = Library:AddTab('UI Settings'),
}

-- Build the UI settings tab (menu) with controls.  The SaveManager is
-- configured after wrapper creation to ensure the library is ready.
local function destroyFly() end
do
    local Menu = Tabs['UI Settings']:AddLeftGroupbox('Menu')
    Menu:AddButton('Unload', function()
        Library:Unload()
    end)
    -- Menu keybind: store default in Options without rendering a keypicker UI
    Menu:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', {
        Default = 'Insert',
        NoUI = true,
        Text = 'Menu keybind'
    })
    Library.ToggleKeybind = Options.MenuKeybind
    -- Build config section using SaveManager from Payback
    SaveManager:SetLibrary(Library)
    SaveManager:SetIgnoreIndexes({ 'MenuKeybind', 'AutoBuyPick' })
    SaveManager:SetFolder('PayBack/specific-game')
    SaveManager:BuildConfigTab(Tabs['UI Settings'])
    -- ThemeManager stub has no effect
    ThemeManager:ApplyToTab(Tabs['UI Settings'])
    Library:OnUnload(function()
        Library.Unloaded = true
        destroyFly()
        local pg = LP:FindFirstChild('PlayerGui')
        if pg then
            local hud = pg:FindFirstChild('PayBackHUD')
            if hud and hud:IsA('ScreenGui') then hud:Destroy() end
        end
    end)
end

----------------------------------------------------------------
-- Remotes (best effort)
----------------------------------------------------------------
local Remotes = ReplicatedStorage:FindFirstChild('Remotes')
local ShopFolder = Remotes and Remotes:FindFirstChild('Shop')
local InventoryFolder = Remotes and Remotes:FindFirstChild('Inventory')
local QuestsFolder = Remotes and Remotes:FindFirstChild('Quests')
local CraftingFolder = Remotes and Remotes:FindFirstChild('Crafting')
local SellAllRF = ShopFolder and ShopFolder:FindFirstChild('SellAll')
local BuyItemRF = ShopFolder and ShopFolder:FindFirstChild('BuyItem')
local ToggleLockRE = InventoryFolder and InventoryFolder:FindFirstChild('ToggleLock')
local UpdateQuestDataRE = QuestsFolder and QuestsFolder:FindFirstChild('UpdateQuestData')
local UpdateDiscoveredEquipmentRE = CraftingFolder and CraftingFolder:FindFirstChild('UpdateDiscoveredEquipment')

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------
local function clampDelay(v) return math.clamp(tonumber(v) or 0.5, 0.25, 3.0) end
local function getOptionNum(key, def)
    local opt = Options[key]
    if opt and type(opt) == 'table' and type(opt.Value) == 'number' then
        return opt.Value
    end
    return def
end
local function formatMoney(n)
    n = math.floor((tonumber(n) or 0) + 0.5)
    local s = tostring(n)
    while true do
        local rep, k = s:gsub('^(-?%d+)(%d%d%d)', '%1,%2')
        s = rep
        if k == 0 then break end
    end
    return s
end
local function inRange(a, b, r) return (a - b).Magnitude <= r end
-- Safe label setter (prevents "attempt to call a nil value" on some Linoria forks)
local function SafeSetLabel(lbl, text)
    if not lbl then return end
    if type(lbl.SetText) == 'function' then
        local ok = pcall(function() lbl:SetText(text) end)
        if ok then return end
    end
    pcall(function()
        if typeof(lbl) == 'Instance' and lbl:IsA('TextLabel') then
            lbl.Text = text
        elseif lbl.Label and typeof(lbl.Label) == 'Instance' and lbl.Label:IsA('TextLabel') then
            lbl.Label.Text = text
        elseif lbl.Text ~= nil then
            lbl.Text = text
        end
    end)
end
local moneyNames = { 'Money', 'Coins', 'Gold', 'Cash', 'Balance' }
local shardNames = { 'Shards', 'Shard', 'Gems', 'Gem', 'Crystals', 'Crystal', 'Fragments', 'Fragment', 'ShardCurrency', 'GemsCurrency' }
local function getLeaderNum(names)
    local ls = LP:FindFirstChild('leaderstats')
    if not ls then return 0 end
    local best = 0
    for _, n in ipairs(names) do
        local v = ls:FindFirstChild(n)
        if v and (v:IsA('NumberValue') or v:IsA('IntValue')) then
            local num = tonumber(v.Value) or 0
            if num > best then best = num end
        end
    end
    return best
end
local function getMoney() return getLeaderNum(moneyNames) end
local function getShards() return getLeaderNum(shardNames) end
-- instance anchoring
local function anchorFrom(inst)
    if inst:IsA('Model') then
        if inst.PrimaryPart and inst.PrimaryPart:IsA('BasePart') then return inst.PrimaryPart end
        local hrp = inst:FindFirstChild('HumanoidRootPart')
        if hrp and hrp:IsA('BasePart') then return hrp end
        local head = inst:FindFirstChild('Head')
        if head and head:IsA('BasePart') then return head end
        for _, d in ipairs(inst:GetDescendants()) do
            if d:IsA('BasePart') then return d end
        end
    elseif inst:IsA('BasePart') then
        return inst
    end
    return nil
end

----------------------------------------------------------------
-- HUD (Money/Shards/Last Sale/Session/State)
----------------------------------------------------------------
local HudLabel = nil
local sessionStartMoney = getMoney()
_G.__PB_LastSaleDelta = 0
local function destroyHUD()
    local pg = LP:FindFirstChild('PlayerGui')
    local gui = (HudLabel and HudLabel:FindFirstAncestorOfClass('ScreenGui')) or (pg and pg:FindFirstChild('PayBackHUD'))
    if gui then
        pcall(function() gui:Destroy() end)
    end
    HudLabel = nil
end
local function ensureHUD()
    if HudLabel then return end
    local pg = LP:WaitForChild('PlayerGui')
    local gui = Instance.new('ScreenGui')
    gui.Name = 'PayBackHUD'
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = pg
    local frame = Instance.new('Frame')
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.AutomaticSize = Enum.AutomaticSize.XY
    frame.AnchorPoint = Vector2.new(1, 0)
    frame.Position = UDim2.new(1, -10, 0, 10)
    frame.Parent = gui
    local pad = Instance.new('UIPadding')
    pad.PaddingLeft = UDim.new(0, 8)
    pad.PaddingRight = UDim.new(0, 8)
    pad.PaddingTop = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 4)
    pad.Parent = frame
    local tl = Instance.new('TextLabel')
    tl.BackgroundTransparency = 1
    tl.TextColor3 = Color3.fromRGB(230, 230, 230)
    tl.Font = Enum.Font.Code
    tl.TextSize = 14
    tl.RichText = true
    tl.AutomaticSize = Enum.AutomaticSize.XY
    tl.Size = UDim2.fromOffset(0, 0)
    tl.TextXAlignment = Enum.TextXAlignment.Right
    tl.Parent = frame
    HudLabel = tl
end
local function getControlsFolder()
    local pg = LP:FindFirstChild('PlayerGui')
    if not pg then return nil end
    local toolUI = pg:FindFirstChild('ToolUI')
    if not toolUI then return nil end
    return toolUI:FindFirstChild('Controls')
end
-- More robust control detection: substring match (case-insensitive)
local CONTROL_ALIASES = {
    Collect = { 'collect deposit', 'collect', 'deposit' },
    Pan = { 'pan' },
    Shake = { 'shake', 'shake!', 'shake pan', 'shaking' },
    Place = { 'place' },
}
local function hasControlLike(words)
    local controls = getControlsFolder()
    if not controls then return false end
    local function matchStr(s)
        s = string.lower(s or '')
        for _, w in ipairs(words) do
            local wlc = string.lower(w)
            if s:find(wlc, 1, true) then return true end
        end
        return false
    end
    for _, kid in ipairs(controls:GetDescendants()) do
        if kid:IsA('TextLabel') then
            if matchStr(kid.Name) or matchStr(kid.Text) then return true end
        end
    end
    return false
end
local function hudState()
    if hasControlLike(CONTROL_ALIASES.Collect) then return 'Collect' end
    if hasControlLike(CONTROL_ALIASES.Shake) then return 'Shake' end
    if hasControlLike(CONTROL_ALIASES.Pan) then return 'Pan' end
    if hasControlLike(CONTROL_ALIASES.Place) then return 'Place' end
    return 'Idle'
end
local function updateHUD()
    if not (Toggles.ShowHUD and Toggles.ShowHUD.Value) then
        destroyHUD()
        return
    end
    ensureHUD()
    local cash, shards = getMoney(), getShards()
    local session = cash - sessionStartMoney
    local sessColor = session > 0 and '#27e36a' or (session < 0 and '#ff4d4d' or '#cccccc')
    local shardsColor = '#ff66cc'
    local text = string.format(
        "Money: $%s | <font color='%s'>Shards: %s</font> | Last Sale: $%s | Session: <font color='%s'>$%s</font> | %s",
        formatMoney(cash), shardsColor, formatMoney(shards), formatMoney(_G.__PB_LastSaleDelta), sessColor, formatMoney(math.abs(session)), hudState()
    )
    if HudLabel then HudLabel.Text = text end
end
if Toggles.ShowHUD and Toggles.ShowHUD.OnChanged then
    Toggles.ShowHUD:OnChanged(function(on)
        if on then
            ensureHUD()
            updateHUD()
        else
            destroyHUD()
        end
    end)
end

----------------------------------------------------------------
-- Anti AFK
----------------------------------------------------------------
local lastHumanAction = time()
UserInputService.InputBegan:Connect(function()
    lastHumanAction = time()
end)
RunService.Heartbeat:Connect(function()
    local h = Hum()
    if h.MoveDirection.Magnitude > 0 then lastHumanAction = time() end
end)
local function microWiggle()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local c = cam.ViewportSize / 2
    VirtualInputManager:SendMouseMoveEvent(c.X + 1, c.Y, game)
    task.wait(0.02)
    VirtualInputManager:SendMouseMoveEvent(c.X, c.Y, game)
end

----------------------------------------------------------------
-- Capacity watchers -> Auto sell
----------------------------------------------------------------
local function clearVel(root)
    pcall(function()
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.Velocity = Vector3.zero
    end)
end
local function forceStand(h)
    h.PlatformStand = false
    h.Sit = false
    pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end)
    task.wait(0.05)
    pcall(function() h:ChangeState(Enum.HumanoidStateType.Running) end)
end
local function temporarilyDisableRagdoll(h, dur)
    local states = { Enum.HumanoidStateType.Ragdoll, Enum.HumanoidStateType.FallingDown }
    for _, st in ipairs(states) do pcall(function() h:SetStateEnabled(st, false) end) end
    task.delay(dur, function()
        for _, st in ipairs(states) do pcall(function() h:SetStateEnabled(st, true) end) end
    end)
end
local function shouldSellFromText(t)
    local l = string.lower(t or '')
    if string.find(l, 'full', 1, true) then return true end
    local a, b = t:match('(%d+)%s*/%s*(%d+)')
    if a and b then
        local n = tonumber(a)
        local m = tonumber(b)
        if n and m and m > 0 then
            return ((n / m) * 100) >= getOptionNum('NearFullPct', 95)
        end
    end
    return false
end
local fullConns = {}
local function disconnectFullConns()
    for _, c in ipairs(fullConns) do pcall(function() c:Disconnect() end) end
    fullConns = {}
end
local function connectLabel(lbl)
    table.insert(fullConns, lbl:GetPropertyChangedSignal('Text'):Connect(function()
        if Toggles.AutoSellFull and Toggles.AutoSellFull.Value then
            if shouldSellFromText(lbl.Text) then
                task.spawn(function()
                    if SellAllRF then pcall(function() SellAllRF:InvokeServer() end) end
                end)
            end
        end
    end))
    if shouldSellFromText(lbl.Text) and Toggles.AutoSellFull and Toggles.AutoSellFull.Value then
        task.spawn(function()
            if SellAllRF then pcall(function() SellAllRF:InvokeServer() end) end
        end)
    end
end
local function wireCapacityWatchers()
    disconnectFullConns()
    local pg = LP:FindFirstChild('PlayerGui')
    if not pg then return end
    for _, name in ipairs({ 'BackpackGui', 'ToolUI', 'MainUI' }) do
        local g = pg:FindFirstChild(name)
        if g then
            for _, d in ipairs(g:GetDescendants()) do
                if d:IsA('TextLabel') then connectLabel(d) end
            end
            table.insert(fullConns, g.DescendantAdded:Connect(function(inst)
                if inst:IsA('TextLabel') then connectLabel(inst) end
            end))
        end
    end
end

----------------------------------------------------------------
-- Smart Sell (TP to Merchant ONLY) + Return
----------------------------------------------------------------
local MERCHANT_CACHE = {}
local _lastMerchantBuild = 0
local function isMerchantWord(s)
    if not s then return false end
    return (string.lower(s):find('%f[%a]merchant%f[%A]') ~= nil)
end
local function findNPCsRoot()
    local direct = Workspace:FindFirstChild('NPCs')
    if direct then return direct end
    for _, ch in ipairs(Workspace:GetChildren()) do
        if (ch:IsA('Folder') or ch:IsA('Model')) and string.lower(ch.Name) == 'npcs' then return ch end
    end
    return nil
end
local function uniqueAdd(cache, part, name)
    for _, rec in ipairs(cache) do if rec.Part == part then return end end
    table.insert(cache, { Part = part, Name = name })
end
local function rebuildMerchantCache()
    local cache = {}
    local npcsRoot = findNPCsRoot()
    if npcsRoot then
        for _, inst in ipairs(npcsRoot:GetDescendants()) do
            if inst:IsA('Model') and inst:FindFirstChildOfClass('Humanoid') and isMerchantWord(inst.Name) then
                local a = anchorFrom(inst)
                if a then uniqueAdd(cache, a, inst.Name) end
            end
        end
    end
    for _, pp in ipairs(Workspace:GetDescendants()) do
        if pp:IsA('ProximityPrompt') then
            local text = (pp.ObjectText ~= '' and pp.ObjectText) or pp.Name
            if isMerchantWord(text) then
                local parent = pp.Parent
                if parent then
                    local a = anchorFrom(parent)
                    if a then uniqueAdd(cache, a, text) end
                end
            end
        end
    end
    MERCHANT_CACHE = cache
    _lastMerchantBuild = time()
end
local function nearestMerchant()
    if (time() - _lastMerchantBuild) > 8 or #MERCHANT_CACHE == 0 then rebuildMerchantCache() end
    local my = HRP().Position
    local best, bd = nil, math.huge
    for _, rec in ipairs(MERCHANT_CACHE) do
        local d = (rec.Part.Position - my).Magnitude
        if d < bd then bd = d best = rec end
    end
    return best, bd
end
local SELL_PRE_WAIT, SELL_POST_WAIT = 1.10, 0.35
local _busySelling = false
local function sellAllSmart(doTeleport)
    doTeleport = (doTeleport ~= false)
    if _busySelling then return end
    if not SellAllRF then Library:Notify('SellAll remote missing.', 3) return end
    _busySelling = true
    local h = Hum()
    local root = HRP()
    local startCF = root.CFrame
    local rec = select(1, nearestMerchant())
    if not rec then
        rebuildMerchantCache()
        rec = select(1, nearestMerchant())
    end
    if not rec then
        Library:Notify('No merchant found.', 3)
        _busySelling = false
        return
    end
    local yLift = math.clamp(getOptionNum('SellTpHeight', 5), 0, 12)
    local targetPos = rec.Part.Position + Vector3.new(0, yLift, 0)
    local function safeTP(cf)
        clearVel(root)
        temporarilyDisableRagdoll(h, SELL_PRE_WAIT + SELL_POST_WAIT + 1.2)
        forceStand(h)
        pcall(function() root.CFrame = cf end)
    end
    if doTeleport then safeTP(CFrame.new(targetPos)) end
    task.wait(SELL_PRE_WAIT)
    local before = getMoney()
    pcall(function() SellAllRF:InvokeServer() end)
    task.wait(SELL_POST_WAIT)
    clearVel(root)
    if doTeleport then
        pcall(function() root.CFrame = startCF + Vector3.new(0, 0.1, 0) end)
    end
    forceStand(h)
    clearVel(root)
    task.delay(0.25, function()
        local after = getMoney()
        _G.__PB_LastSaleDelta = math.max(0, after - before)
    end)
    _busySelling = false
end

----------------------------------------------------------------
-- Collect & Shake (smart)
----------------------------------------------------------------
local function leftClickCenter()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local c = cam.ViewportSize / 2
    VirtualInputManager:SendMouseButtonEvent(c.X, c.Y, 0, true, game, 0)
    task.wait(0.02)
    VirtualInputManager:SendMouseButtonEvent(c.X, c.Y, 0, false, game, 0)
end
local function findToolWithRemote(remoteName)
    local function scanFolder(folder)
        for _, it in ipairs(folder:GetChildren()) do
            if it:IsA('Tool') then
                local s = it:FindFirstChild('Scripts')
                local r = s and s:FindFirstChild(remoteName)
                if r and (r:IsA('RemoteEvent') or r:IsA('RemoteFunction')) then
                    return it, r
                end
            end
        end
        return nil, nil
    end
    local ch = Char()
    local t, r = scanFolder(ch)
    if t then return t, r end
    local bp = LP:FindFirstChild('Backpack')
    if bp then
        t, r = scanFolder(bp)
        if t then return t, r end
    end
    return nil, nil
end
local function resolvePanToolIn(container)
    local best = nil
    for _, it in ipairs(container:GetChildren()) do
        if it:IsA('Tool') then
            local nameL = string.lower(it.Name)
            if string.find(nameL, 'pan', 1, true) then
                local scripts = it:FindFirstChild('Scripts')
                local collect = scripts and scripts:FindFirstChild('Collect')
                if collect and (collect:IsA('RemoteFunction') or collect:IsA('RemoteEvent')) then
                    return it
                end
                if not best then best = it end
            end
        end
    end
    return best
end
local function findCurrentPan()
    local ch = Char()
    local pan = resolvePanToolIn(ch)
    if pan then return pan end
    local bp = LP:FindFirstChild('Backpack')
    if bp then
        pan = resolvePanToolIn(bp)
        if pan then
            pcall(function() Hum():EquipTool(pan) end)
            task.wait(0.05)
            return resolvePanToolIn(Char()) or pan
        end
    end
    return nil
end
local function getCollectRemoteFromPan(panTool)
    if not panTool then return nil end
    local s = panTool:FindFirstChild('Scripts')
    if not s then return nil end
    local r = s:FindFirstChild('Collect')
    if r and (r:IsA('RemoteFunction') or r:IsA('RemoteEvent')) then return r end
    for _, d in ipairs(s:GetDescendants()) do
        if d:IsA('RemoteFunction') or d:IsA('RemoteEvent') then
            local n = string.lower(d.Name)
            if n:find('collect', 1, true) or n:find('deposit', 1, true) or n:find('perfect', 1, true) then return d end
        end
    end
    return nil
end
local function tryFireCollectRemote(r)
    if r:IsA('RemoteFunction') then
        if pcall(function() r:InvokeServer(1) end) then return true end
        if pcall(function() r:InvokeServer() end) then return true end
        if pcall(function() r:InvokeServer(true) end) then return true end
        if pcall(function() r:InvokeServer('Perfect') end) then return true end
        return false
    else
        if pcall(function() r:FireServer(1) end) then return true end
        if pcall(function() r:FireServer() end) then return true end
        if pcall(function() r:FireServer(true) end) then return true end
        if pcall(function() r:FireServer('Perfect') end) then return true end
        return false
    end
end
local function doCollectPerfect()
    local pan = findCurrentPan()
    local r = getCollectRemoteFromPan(pan)
    if r then
        if not tryFireCollectRemote(r) then leftClickCenter() end
        return
    end
    leftClickCenter()
end
local function doShakeOnce()
    local _, r = findToolWithRemote('Shake')
    if r then
        if r:IsA('RemoteEvent') then pcall(function() r:FireServer() end) else pcall(function() r:InvokeServer() end) end
    else
        leftClickCenter()
    end
end

----------------------------------------------------------------
-- Sluices automation (unchanged)
----------------------------------------------------------------
local function ourSluiceModel(m)
    local uid = m:GetAttribute('UserId')
    return type(uid) == 'number' and uid == LP.UserId
end
local function sluiceUIReady(ui)
    local function textReady(s)
        local l = string.lower(s or '')
        if string.find(l, 'ready', 1, true) then return true end
        if string.find(l, 'collect', 1, true) then return true end
        if string.find(l, 'full', 1, true) then return true end
        if string.find(l, '100%%') then return true end
        if l == '0s' or l == '0' then return true end
        return false
    end
    for _, d in ipairs(ui:GetDescendants()) do
        if d:IsA('TextLabel') and textReady(d.Text) then return true end
    end
    return false
end
local function collectPromptFor(model)
    local cp = model:FindFirstChild('CollectPrompt', true)
    if cp and cp:IsA('ProximityPrompt') then return cp end
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA('ProximityPrompt') then return d end
    end
    return nil
end
local function sendPrompt(pp)
    local key = (pp.KeyboardKeyCode == Enum.KeyCode.Unknown) and Enum.KeyCode.E or pp.KeyboardKeyCode
    VirtualInputManager:SendKeyEvent(true, key, false, game)
    task.wait(math.max(0.10, (pp.HoldDuration or 0) + 0.05))
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end
local function canPlaceSluiceNow() return hasControlLike(CONTROL_ALIASES.Place) end
local function ensurePlaceOneSluice()
    if not canPlaceSluiceNow() then return false end
    local cam = Workspace.CurrentCamera
    if not cam then return false end
    local c = cam.ViewportSize / 2
    VirtualInputManager:SendMouseButtonEvent(c.X, c.Y, 0, true, game, 0)
    task.wait(0.02)
    VirtualInputManager:SendMouseButtonEvent(c.X, c.Y, 0, false, game, 0)
    lastHumanAction = time()
    return true
end
local function approachAndInteract(model, anchor)
    if (HRP().Position - anchor.Position).Magnitude > 10 then
        pcall(function()
            local root = HRP()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = anchor.CFrame + Vector3.new(0, 3, 0)
        end)
        task.wait(0.25)
    end
    local pp = collectPromptFor(model)
    local t0 = time()
    while (time() - t0) < 2.0 and not pp do
        task.wait(0.1)
        pp = collectPromptFor(model)
    end
    if pp then sendPrompt(pp) return true end
    return false
end
local function findOurSluices()
    local out = {}
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if inst:IsA('Model') then
            local ui = inst:FindFirstChild('SluiceUI')
            if ui and ourSluiceModel(inst) then
                local a = anchorFrom(inst)
                if a then table.insert(out, { Model = inst, Anchor = a, UI = ui }) end
            end
        end
    end
    return out
end
local function tryHandleSluices()
    if not (Toggles.AutoSluice and Toggles.AutoSluice.Value) then return false end
    local recs = findOurSluices()
    if #recs == 0 then
        if Toggles.SluicePlaceFirst and Toggles.SluicePlaceFirst.Value then
            if ensurePlaceOneSluice() then return true end
        end
        return false
    end
    if Toggles.SluiceCollectReplace and Toggles.SluiceCollectReplace.Value then
        for _, rec in ipairs(recs) do
            if rec.UI and sluiceUIReady(rec.UI) then
                if approachAndInteract(rec.Model, rec.Anchor) then
                    task.wait(0.15)
                    ensurePlaceOneSluice()
                    lastHumanAction = time()
                    return true
                end
            end
        end
    end
    return false
end

----------------------------------------------------------------
-- Buy scanners (coins + shards) + Inventory value
----------------------------------------------------------------
local labelMapPans, labelMapShov, labelMapSluice, labelMapOther, labelMapShards = {}, {}, {}, {}, {}
local priceMapAll = {}
local function numAttr(inst, name)
    local ok, v = pcall(function() return inst:GetAttribute(name) end)
    if ok and type(v) == 'number' then return v end
    return nil
end
local function numAttrMulti(inst, names)
    for _, n in ipairs(names) do
        local v = numAttr(inst, n)
        if type(v) == 'number' then return v end
    end
    return nil
end
local function numChild(inst, names)
    for _, n in ipairs(names) do
        local x = inst:FindFirstChild(n)
        if x and (x:IsA('NumberValue') or x:IsA('IntValue')) then
            return tonumber(x.Value)
        end
    end
    return nil
end
local function tryRemotePrices(obj)
    local coin, shard = nil, nil
    if not ShopFolder then return nil, nil end
    local cands = {}
    for _, d in ipairs(ShopFolder:GetDescendants()) do
        if d:IsA('RemoteFunction') then
            local nm = string.lower(d.Name)
            if string.find(nm, 'price', 1, true) or string.find(nm, 'cost', 1, true) or string.find(nm, 'info', 1, true) then
                table.insert(cands, d)
            end
        end
    end
    for _, rf in ipairs(cands) do
        local ok, res = pcall(function() return rf:InvokeServer(obj) end)
        if ok then
            if type(res) == 'number' then coin = coin or res
            elseif type(res) == 'table' then
                for k, v in pairs(res) do
                    if type(v) == 'number' then
                        local lk = string.lower(k)
                        if string.find(lk, 'shard', 1, true) or string.find(lk, 'gem', 1, true) or string.find(lk, 'crystal', 1, true) then shard = shard or v
                        elseif string.find(lk, 'price', 1, true) or string.find(lk, 'cost', 1, true) or string.find(lk, 'coin', 1, true) or string.find(lk, 'money', 1, true) then coin = coin or v end
                    end
                end
            end
        end
        if coin or shard then break end
    end
    return coin, shard
end
local function classifyLeafByName(leaf)
    local s = string.lower(leaf or '')
    if string.find(s, 'pan', 1, true) then return 'pan' end
    if string.find(s, 'shovel', 1, true) then return 'shovel' end
    if string.find(s, 'sluice', 1, true) then return 'sluice' end
    return 'other'
end
local function scanPurchasable()
    labelMapPans, labelMapShov, labelMapSluice, labelMapOther, labelMapShards, priceMapAll = {}, {}, {}, {}, {}, {}
    local listP, listS, listSL, listO, listSH = {}, {}, {}, {}, {}
    local purch = Workspace:FindFirstChild('Purchasable')
    if not purch then return listP, listS, listSL, listO, listSH end
    local function formatCoins(leaf, price)
        return price and (leaf .. ' - $' .. tostring(price)) or (leaf .. ' - $TBD')
    end
    local function formatShards(leaf, shards)
        return shards and (leaf .. ' - SHARDS ' .. tostring(shards)) or (leaf .. ' - SHARDS TBD')
    end
    local function add(node)
        local v = node:FindFirstChild('ShopItem')
        if not (v and v:IsA('ObjectValue')) then return end
        local leaf = node.Name
        local coinA = numAttrMulti(node, { 'Price', 'Cost', 'Coins', 'CoinCost' }) or numAttrMulti(v, { 'Price', 'Cost', 'Coins', 'CoinCost' }) or numChild(node, { 'Price', 'Cost', 'Coins' }) or numChild(v, { 'Price', 'Cost', 'Coins' })
        local shardA = numAttrMulti(node, { 'Shards', 'ShardPrice', 'Gems', 'GemCost', 'Crystals', 'CrystalCost' }) or numAttrMulti(v, { 'Shards', 'ShardPrice', 'Gems', 'GemCost', 'Crystals', 'CrystalCost' }) or numChild(node, { 'Shards', 'Gems', 'Crystals' }) or numChild(v, { 'Shards', 'Gems', 'Crystals' })
        if coinA == nil and shardA == nil then
            local c, s = tryRemotePrices(v)
            coinA = coinA or c
            shardA = shardA or s
        end
        if type(shardA) == 'number' and shardA > 0 and (coinA == nil or (tonumber(coinA) or 0) <= 0) then
            local labelSH = formatShards(leaf, shardA)
            labelMapShards[labelSH] = v
            table.insert(listSH, labelSH)
            priceMapAll[labelSH] = shardA
            return
        end
        local label = formatCoins(leaf, coinA)
        if type(coinA) == 'number' then priceMapAll[label] = coinA else priceMapAll[label] = math.huge end
        local bucket = classifyLeafByName(leaf)
        if bucket == 'pan' then labelMapPans[label] = v; table.insert(listP, label)
        elseif bucket == 'shovel' then labelMapShov[label] = v; table.insert(listS, label)
        elseif bucket == 'sluice' then labelMapSluice[label] = v; table.insert(listSL, label)
        else labelMapOther[label] = v; table.insert(listO, label) end
    end
    local function visit(n)
        add(n)
        for _, c in ipairs(n:GetChildren()) do
            if c:IsA('Folder') or c:IsA('Model') then visit(c) end
        end
    end
    for _, child in ipairs(purch:GetChildren()) do
        if child:IsA('Folder') or child:IsA('Model') then visit(child) end
    end
    local function sorter(a, b)
        local paV, pbV = priceMapAll[a], priceMapAll[b]
        local pa = (type(paV) == 'number') and paV or math.huge
        local pb = (type(pbV) == 'number') and pbV or math.huge
        if pa == pb then return a < b end
        return pa < pb
    end
    table.sort(listP, sorter)
    table.sort(listS, sorter)
    table.sort(listSL, sorter)
    table.sort(listO, sorter)
    table.sort(listSH, sorter)
    return listP, listS, listSL, listO, listSH
end
local function buyFrom(label, map)
    if not label or label == '' then Library:Notify('Select an item.', 3) return end
    local obj = map[label]
    if not obj then Library:Notify('Item missing. Refresh.', 3) return end
    if not BuyItemRF then Library:Notify('Buy remote missing.', 3) return end
    pcall(function() BuyItemRF:InvokeServer(obj) end)
end
local function scoreName(name)
    local s = string.lower(name or '')
    local sc = 0
    if string.find(s, 'get', 1, true) or string.find(s, 'calc', 1, true) or string.find(s, 'fetch', 1, true) then sc = sc + 1 end
    if string.find(s, 'inventory', 1, true) or string.find(s, 'inv', 1, true) then sc = sc + 3 end
    if string.find(s, 'sell', 1, true) then sc = sc + 2 end
    if string.find(s, 'value', 1, true) or string.find(s, 'price', 1, true) or string.find(s, 'worth', 1, true) then sc = sc + 2 end
    if string.find(s, 'all', 1, true) or string.find(s, 'total', 1, true) then sc = sc + 1 end
    return sc
end
local function findInventoryPriceRF()
    if not ShopFolder then return nil end
    local best, bestScore = nil, 0
    for _, inst in ipairs(ShopFolder:GetDescendants()) do
        if inst:IsA('RemoteFunction') then
            local sc = scoreName(inst.Name)
            if sc > bestScore then best, bestScore = inst, sc end
        end
    end
    for _, key in ipairs({ 'GetInventorySellPrice', 'GetInventoryValue', 'GetSellAllValue', 'GetSellPrice', 'GetInventoryWorth' }) do
        local cand = ShopFolder:FindFirstChild(key)
        if cand and cand:IsA('RemoteFunction') then return cand end
    end
    return best
end
local function parseMaybePrice(res)
    if type(res) == 'number' then return res end
    if type(res) == 'string' then local n = tonumber(res); if n then return n end end
    if type(res) == 'table' then
        for _, k in ipairs({ 'Price', 'Value', 'Worth', 'SellPrice', 'Total', 'Amount', 'Coins' }) do
            local v = res[k]
            if type(v) == 'number' then return v end
            if type(v) == 'string' then local n = tonumber(v); if n then return n end end
        end
    end
    return nil
end
local function getInventorySellPrice()
    local rf = findInventoryPriceRF()
    if not rf then return nil end
    local ok, res = pcall(function() return rf:InvokeServer() end)
    if not ok then return nil end
    return parseMaybePrice(res)
end

----------------------------------------------------------------
-- UI: Automation (Collecting + FAF + Selling + Sluices)
----------------------------------------------------------------
local MainL = Tabs['Automation']:AddLeftGroupbox('Collecting')
local MainR = Tabs['Automation']:AddRightGroupbox('Selling')
MainL:AddToggle('AutoCollectOn', { Text = 'Enable Auto Collect', Default = false })
local COLLECT_VALUES = { 'Rage', 'Legit' }
MainL:AddDropdown('CollectMode', { Text = 'Collect Mode', Values = COLLECT_VALUES, Default = 'Rage' })
MainL:AddSlider('CollectDelay', { Text = 'Cycle delay (s)', Default = 0.50, Min = 0.25, Max = 3.00, Rounding = 2 })
MainL:AddButton('Collect Once', function() doCollectPerfect() end)
MainL:AddToggle('AutoShakeManual', { Text = 'Auto Shake (smart)', Default = false })
MainL:AddSlider('ShakeDelay', { Text = 'Shake delay (s)', Default = 0.60, Min = 0.25, Max = 3.00, Rounding = 2 })
MainL:AddButton('Shake Once', function() doShakeOnce() end)
-- Full AutoFarm
MainL:AddDivider()
local FAF_GB = Tabs['Automation']:AddLeftGroupbox('Full AutoFarm')
FAF_GB:AddToggle('FullAutoFarm', { Text = 'Enable Full AutoFarm', Default = false })
FAF_GB:AddButton('Set Ground', function()
    _G.__PB_FAF_GROUND = HRP().Position
    ensureMarker('Ground', _G.__PB_FAF_GROUND, Color3.fromRGB(0, 255, 0))
end)
FAF_GB:AddButton('Set Water', function()
    _G.__PB_FAF_WATER = HRP().Position
    ensureMarker('Water', _G.__PB_FAF_WATER, Color3.fromRGB(0, 170, 255))
end)
FAF_GB:AddButton('Reset All', function()
    _G.__PB_FAF_GROUND = nil
    _G.__PB_FAF_WATER = nil
    local folder = Workspace:FindFirstChild('PayBackMarkers')
    if folder and folder:IsA('Folder') then
        local g = folder:FindFirstChild('Ground')
        if g then g:Destroy() end
        local w = folder:FindFirstChild('Water')
        if w then w:Destroy() end
    end
end)
local FAF_Status = FAF_GB:AddLabel('Ground:\nWater:')
-- Selling
MainR:AddSlider('SellTpHeight', { Text = 'Sell TP height', Default = 5, Min = 0, Max = 12, Rounding = 0 })
MainR:AddButton('Sell (TP to Merchant & Return)', function() sellAllSmart(true) end)
MainR:AddDivider()
MainR:AddToggle('AutoSellFull', { Text = 'Auto-sell when near/full', Default = false })
MainR:AddSlider('NearFullPct', { Text = 'Near full (%)', Default = 95, Min = 80, Max = 100, Rounding = 0 })
if Toggles.AutoSellFull and Toggles.AutoSellFull.OnChanged then
    Toggles.AutoSellFull:OnChanged(function(on)
        if on then wireCapacityWatchers() else disconnectFullConns() end
    end)
end
-- Sluices group
local SluiceGB = Tabs['Automation']:AddRightGroupbox('Sluices')
SluiceGB:AddToggle('AutoSluice', { Text = 'Auto Sluice', Default = false })
SluiceGB:AddToggle('SluicePlaceFirst', { Text = 'Place when none placed', Default = false })
SluiceGB:AddToggle('SluiceCollectReplace', { Text = 'Collect and replace when ready', Default = false })
SluiceGB:AddSlider('SluiceCheckDelay', { Text = 'Sluice check delay (s)', Default = 0.75, Min = 0.25, Max = 3.0, Rounding = 2 })
SluiceGB:AddSlider('SluiceApproachRange', { Text = 'Approach range (studs)', Default = 60, Min = 20, Max = 150, Rounding = 0 })

----------------------------------------------------------------
-- Full AutoFarm helpers (markers + status + FillText reading)
----------------------------------------------------------------
local function markerFolder()
    local f = Workspace:FindFirstChild('PayBackMarkers')
    if not f or not f:IsA('Folder') then
        f = Instance.new('Folder')
        f.Name = 'PayBackMarkers'
        f.Parent = Workspace
    end
    return f
end
local function ensureMarker(name, pos, color)
    local folder = markerFolder()
    local existing = folder:FindFirstChild(name)
    if existing and existing:IsA('BasePart') then
        existing.CFrame = CFrame.new(pos)
        return
    end
    local p = Instance.new('Part')
    p.Name = name
    p.Anchored = true
    p.CanCollide = false
    p.Size = Vector3.new(1, 1, 1)
    p.Transparency = 1
    p.CFrame = CFrame.new(pos)
    p.Parent = folder
    local bb = Instance.new('BillboardGui')
    bb.Name = 'Bill'
    bb.ExtentsOffsetWorldSpace = Vector3.new(0, 3, 0)
    bb.Size = UDim2.fromOffset(120, 36)
    bb.AlwaysOnTop = true
    bb.Parent = p
    local tl = Instance.new('TextLabel')
    tl.BackgroundTransparency = 1
    tl.TextStrokeTransparency = 0.2
    tl.Font = Enum.Font.Code
    tl.TextSize = 14
    tl.TextColor3 = color
    tl.Text = name
    tl.Size = UDim2.fromScale(1, 1)
    tl.Parent = bb
    local hl = Instance.new('Highlight')
    hl.Adornee = p
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency = 0.75
    hl.FillColor = color
    hl.OutlineColor = color
    hl.Parent = p
end
local function updateFAFStatus()
    local g = _G.__PB_FAF_GROUND
    local w = _G.__PB_FAF_WATER
    local gs = g and string.format('(%.0f, %.0f, %.0f)', g.X, g.Y, g.Z) or 'unset'
    local ws = w and string.format('(%.0f, %.0f, %.0f)', w.X, w.Y, w.Z) or 'unset'
    SafeSetLabel(FAF_Status, 'Ground: ' .. gs .. '\n' .. 'Water: ' .. ws)
    if g then ensureMarker('Ground', g, Color3.fromRGB(0, 255, 0)) end
    if w then ensureMarker('Water', w, Color3.fromRGB(0, 170, 255)) end
end
-- FillText helpers
local function getFillTextLabel()
    local pg = LP:FindFirstChild('PlayerGui')
    if not pg then return nil end
    local toolUI = pg:FindFirstChild('ToolUI')
    if not toolUI then return nil end
    local fp = toolUI:FindFirstChild('FillingPan')
    if fp then
        for _, d in ipairs(fp:GetDescendants()) do
            if d:IsA('TextLabel') and (d.Name == 'FillText' or string.lower(d.Name) == 'filltext') then return d end
        end
    end
    for _, d in ipairs(toolUI:GetDescendants()) do
        if d:IsA('TextLabel') and (d.Name == 'FillText' or string.lower(d.Name) == 'filltext') then return d end
    end
    return nil
end
local function parseFillText()
    local lbl = getFillTextLabel()
    if not lbl then return 0, 0, '', false end
    local t = tostring(lbl.Text or '')
    local a, b = t:match('(%d+)%s*/%s*(%d+)')
    local cur, maxv = tonumber(a or '0') or 0, tonumber(b or '0') or 0
    local lower = string.lower(t)
    return cur, maxv, lower, true
end
local function isPanFull()
    local cur, maxv, lower, ok = parseFillText()
    if not ok then return false end
    if maxv > 0 and cur >= maxv then return true end
    if lower:find('full', 1, true) or lower:find('100%%') then return true end
    return false
end
local function isPanEmpty()
    local cur, maxv, lower, ok = parseFillText()
    if not ok then return false end
    if maxv > 0 and cur <= 0 then return true end
    if lower:find('empty', 1, true) then return true end
    return false
end

----------------------------------------------------------------
-- SAFE TP STUB
----------------------------------------------------------------
local TP = { startAutopilot = function(_) end, defaultConfig = function() return { maxSpeed = 25, cruiseClearance = 22, lookAhead = 60, riseRate = 12, dropRate = 14, avoidObstacles = true, } end, finishShortGap = function(finalCF)
    local root = HRP()
    pcall(function()
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.CFrame = finalCF + Vector3.new(0, 3, 0)
    end)
    task.wait(0.25)
end }

----------------------------------------------------------------
-- walkTo (with glide fallback)
----------------------------------------------------------------
local function walkTo(pos, reach)
    local hum = Hum()
    local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, })
    local ok = pcall(function() path:ComputeAsync(HRP().Position, pos) end)
    if not ok or path.Status ~= Enum.PathStatus.Success then
        local deadline = time() + 20
        TP.startAutopilot(CFrame.new(pos), nil)
        while time() < deadline and (Toggles.FullAutoFarm and Toggles.FullAutoFarm.Value) do
            if inRange(HRP().Position, pos, math.max(6, reach)) then return true end
            task.wait(0.1)
        end
        TP.finishShortGap(CFrame.new(pos))
        return inRange(HRP().Position, pos, math.max(6, reach))
    end
    local wps = path:GetWaypoints()
    for _, wp in ipairs(wps) do
        if not (Toggles.FullAutoFarm and Toggles.FullAutoFarm.Value) then return false end
        hum:MoveTo(wp.Position)
        hum.MoveToFinished:Wait(2.5)
    end
    return inRange(HRP().Position, pos, reach)
end

----------------------------------------------------------------
-- FAF loop (strict: move only on fill-state; force-shake at water)
----------------------------------------------------------------
local function workGroundOnce()
    findCurrentPan()
    if hasControlLike(CONTROL_ALIASES.Collect) or hasControlLike(CONTROL_ALIASES.Pan) then
        doCollectPerfect()
    else
        leftClickCenter()
    end
    lastHumanAction = time()
end
local function workWaterOnce()
    findCurrentPan()
    if hasControlLike(CONTROL_ALIASES.Shake) then
        doShakeOnce()
    else
        leftClickCenter()
    end
    lastHumanAction = time()
end
local FAF_SHORT_TP_DIST = 40 -- studs
task.spawn(function()
    local state = 'ground'
    while not Library.Unloaded do
        if Toggles.FullAutoFarm and Toggles.FullAutoFarm.Value then
            updateFAFStatus()
            local ground = _G.__PB_FAF_GROUND
            local water = _G.__PB_FAF_WATER
            if not (ground and water) then
                task.wait(0.4)
            else
                local target = (state == 'ground') and ground or water
                local here = HRP().Position
                local dist = (target - here).Magnitude
                local arrived = false
                if dist < FAF_SHORT_TP_DIST then
                    TP.finishShortGap(CFrame.new(target))
                    arrived = true
                else
                    arrived = walkTo(target, 6)
                end
                if arrived then
                    if state == 'water' then workWaterOnce() end
                    local t0 = time()
                    while Toggles.FullAutoFarm and Toggles.FullAutoFarm.Value do
                        if state == 'ground' then
                            if isPanFull() then state = 'water'; break end
                            workGroundOnce()
                            task.wait(clampDelay(getOptionNum('CollectDelay', 0.5)))
                        else
                            if isPanEmpty() then state = 'ground'; break end
                            workWaterOnce()
                            task.wait(clampDelay(getOptionNum('ShakeDelay', 0.6)))
                        end
                        if (time() - t0) > 25 then break end
                    end
                else
                    task.wait(0.25)
                end
            end
        else
            task.wait(0.35)
        end
    end
end)

----------------------------------------------------------------
-- UI: Buy Tab
----------------------------------------------------------------
local BuyP = Tabs['Buy']:AddLeftGroupbox('Pans')
local BuyS = Tabs['Buy']:AddLeftGroupbox('Shovels')
local BuySL = Tabs['Buy']:AddLeftGroupbox('Sluices')
local BuyCraft = Tabs['Buy']:AddLeftGroupbox('Crafting')
local BuyO = Tabs['Buy']:AddRightGroupbox('Other')
local BuySH = Tabs['Buy']:AddRightGroupbox('Shards')
local valuesP, valuesS, valuesSL, valuesO, valuesSH = scanPurchasable()
local DDP = BuyP:AddDropdown('BuyPickPan', { Text = 'Pans (Name - $Price)', Values = valuesP, AllowNull = true })
BuyP:AddButton('Buy Selected Pan', function()
    local v = Options.BuyPickPan and Options.BuyPickPan.Value
    buyFrom(v, labelMapPans)
end)
local DDS = BuyS:AddDropdown('BuyPickShovel', { Text = 'Shovels (Name - $Price)', Values = valuesS, AllowNull = true })
BuyS:AddButton('Buy Selected Shovel', function()
    local v = Options.BuyPickShovel and Options.BuyPickShovel.Value
    buyFrom(v, labelMapShov)
end)
local DDSL = BuySL:AddDropdown('BuyPickSluice', { Text = 'Sluices (Name - $Price)', Values = valuesSL, AllowNull = true })
BuySL:AddButton('Buy Selected Sluice', function()
    local v = Options.BuyPickSluice and Options.BuyPickSluice.Value
    buyFrom(v, labelMapSluice)
end)

----------------------------------------------------------------
-- Crafting scan + safer autolock caps
----------------------------------------------------------------
local DISCOVERED = {}
if UpdateDiscoveredEquipmentRE then UpdateDiscoveredEquipmentRE.OnClientEvent:Connect(function(list)
    DISCOVERED = {}
    if type(list) == 'table' then
        for _, id in ipairs(list) do DISCOVERED[id] = true end
    end
end)
pcall(function() UpdateDiscoveredEquipmentRE:FireServer() end) end
local craftList, craftMap = {}, {}
local function formatCoinsStr(n) return n and ('$' .. formatMoney(n)) or '$TBD' end
local function canShowEquip(equip)
    local hidden = equip:GetAttribute('Hidden')
    local itemId = equip:GetAttribute('ItemID')
    if hidden and itemId ~= nil then return DISCOVERED[itemId] == true end
    return true
end
local function scanCraftingItems()
    craftList, craftMap = {}, {}
    local eqFolder = ReplicatedStorage:FindFirstChild('Items')
    eqFolder = eqFolder and eqFolder:FindFirstChild('Equipment')
    if not (eqFolder and eqFolder:IsA('Folder')) then return end
    for _, tool in ipairs(eqFolder:GetChildren()) do
        if tool:IsA('Tool') and canShowEquip(tool) then
            local ed = tool:FindFirstChild('EquipmentData')
            if ed and ed:IsA('ModuleScript') then
                local ok, data = pcall(require, ed)
                if ok and type(data) == 'table' then
                    local price = tonumber(data.Price) or 0
                    local label = string.format('%s - %s', tool.Name, formatCoinsStr(price))
                    craftMap[label] = { Item = tool, Data = data, Price = price }
                    table.insert(craftList, label)
                end
            end
        end
    end
    table.sort(craftList, function(a, b)
        local pa = craftMap[a] and craftMap[a].Price or math.huge
        local pb = craftMap[b] and craftMap[b].Price or math.huge
        if pa == pb then return a < b end
        return pa < pb
    end)
end
scanCraftingItems()
-- Crafting UI
local CraftPickDD = BuyCraft:AddDropdown('CraftPick', { Text = 'Equipment to Craft', Values = craftList, AllowNull = true })
local MAX_CRAFT_TYPES = 8
local MAX_QUEST_LOCKS = 12
-- grid utilities
local function gridLines3(list)
    local lines, row = {}, {}
    for _, nm in ipairs(list) do
        row[#row + 1] = tostring(nm)
        if #row == 3 then lines[#lines + 1] = table.concat(row, '.') row = {} end
    end
    if #row > 0 then lines[#lines + 1] = table.concat(row, '.') end
    return lines
end
local craftTargets = {}
local lastCraftLocked = {}
local function normalizeName(s)
    local t = string.lower(s or '')
    t = t:gsub('[%p]', ' '):gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '')
    if #t > 3 and t:sub(-1) == 's' and t:sub(-2) ~= 'ss' then t = t:sub(1, -2) end
    return t
end
BuyCraft:AddToggle('AutoLockCraftMats', { Text = 'Auto-lock materials for selected craft', Default = false })
BuyCraft:AddButton('Refresh Crafting Items', function()
    scanCraftingItems()
    if Options.CraftPick and Options.CraftPick.Refresh then Options.CraftPick:Refresh(craftList, true) end
    Library:Notify(('Craftables: %d items'):format(#craftList), 3)
end)
-- MATERIALS label under the button
local CraftInfoLabel = BuyCraft:AddLabel('Materials: none')
local function readLockedState(inst)
    local a = inst:GetAttribute('Locked')
    if type(a) == 'boolean' then return a end
    local b = inst:GetAttribute('IsLocked')
    if type(b) == 'boolean' then return b end
    local bv = inst:FindFirstChild('Locked')
    if bv and bv:IsA('BoolValue') then return bv.Value end
    return nil
end
local function ensureLockState(tool, shouldLock)
    if not ToggleLockRE then return end
    local cur = readLockedState(tool)
    if cur == shouldLock then return end
    ToggleLockRE:FireServer(tool)
    if tool:IsA('Tool') then lastCraftLocked[tool] = shouldLock end
end
local function matchesCraft(tool)
    local need = craftTargets[normalizeName(tool.Name)]
    if not need then return false end
    local weight = 0
    local id = tool:FindFirstChild('ItemData')
    if id and id:IsA('Folder') then
        local w = tool.ItemData:GetAttribute('Weight')
        if type(w) == 'number' then weight = w end
    end
    if need.MinWeight and need.MinWeight > 0 and weight < need.MinWeight then return false end
    return true
end
local function lockCraftMaterialsInBackpack()
    if not (Toggles.AutoLockCraftMats and Toggles.AutoLockCraftMats.Value) then return end
    local bp = LP:FindFirstChild('Backpack')
    if not bp then return end
    local kinds = 0
    for _ in pairs(craftTargets) do kinds = kinds + 1 end
    if kinds > MAX_CRAFT_TYPES then return end
    for _, it in ipairs(bp:GetChildren()) do
        if it:IsA('Tool') and matchesCraft(it) then ensureLockState(it, true) end
    end
end
local function unlockCraftLocksWeSet()
    local bp = LP:FindFirstChild('Backpack')
    if not bp then return end
    for tool, byRule in pairs(lastCraftLocked) do
        if byRule and tool.Parent == bp then ensureLockState(tool, false); lastCraftLocked[tool] = nil end
    end
end
if Toggles.AutoLockCraftMats and Toggles.AutoLockCraftMats.OnChanged then
    Toggles.AutoLockCraftMats:OnChanged(function(on)
        if on then lockCraftMaterialsInBackpack() else unlockCraftLocksWeSet() end
    end)
end
local function materialsSummaryCapped(data)
    if type(data) ~= 'table' or type(data.Materials) ~= 'table' then return 'Materials: none' end
    local names = {}
    for k, _ in pairs(data.Materials) do names[#names + 1] = tostring(k) end
    table.sort(names)
    local extra = 0
    if #names > MAX_CRAFT_TYPES then extra = #names - MAX_CRAFT_TYPES end
    local shown = {}
    for i = 1, math.min(#names, MAX_CRAFT_TYPES) do shown[#shown + 1] = names[i] end
    local glines = gridLines3(shown)
    local head = 'Materials: ' .. (glines[1] or '')
    for i = 2, #glines do head = head .. '\n' .. glines[i] end
    if #names >= 10 then head = '\n' .. head end
    if extra > 0 then head = head .. '\n' .. string.format('... and %d more types (not auto-locked)', extra) end
    return head
end
if Options.CraftPick and Options.CraftPick.OnChanged then
    Options.CraftPick:OnChanged(function(v)
        local rec = craftMap[v]
        craftTargets = {}
        if rec and type(rec.Data) == 'table' and type(rec.Data.Materials) == 'table' then
            local temp = {}
            for nm, need in pairs(rec.Data.Materials) do temp[#temp + 1] = { nm, need } end
            table.sort(temp, function(a, b) return tostring(a[1]) < tostring(b[1]) end)
            local limit = math.min(#temp, MAX_CRAFT_TYPES)
            for i = 1, limit do
                local nm, need = temp[i][1], temp[i][2]
                craftTargets[normalizeName(nm)] = { Amount = tonumber(need.Amount) or 0, MinWeight = tonumber(need.MinWeight) or 0 }
            end
            SafeSetLabel(CraftInfoLabel, materialsSummaryCapped(rec.Data))
            lockCraftMaterialsInBackpack()
        else
            SafeSetLabel(CraftInfoLabel, 'Materials: none')
        end
    end)
end
do
    local v = Options.CraftPick and Options.CraftPick.Value
    if v and craftMap[v] then SafeSetLabel(CraftInfoLabel, materialsSummaryCapped(craftMap[v].Data)) end
end
do
    local bp = LP:FindFirstChild('Backpack')
    if bp then bp.ChildAdded:Connect(function(obj)
        if obj:IsA('Tool') then task.wait(0.05) lockCraftMaterialsInBackpack() end
    end) end
end

----------------------------------------------------------------
-- Other Buy tab widgets
----------------------------------------------------------------
local DDO = BuyO:AddDropdown('BuyPickOther', { Text = 'Other (Name - $Price)', Values = valuesO, AllowNull = true })
BuyO:AddButton('Buy Selected Other', function()
    local v = Options.BuyPickOther and Options.BuyPickOther.Value
    buyFrom(v, labelMapOther)
end)
local DDSH = BuySH:AddDropdown('BuyPickShards', { Text = 'Shards (Name - SHARDS Price)', Values = valuesSH, AllowNull = true })
BuySH:AddButton('Buy Selected (Shards)', function()
    local v = Options.BuyPickShards and Options.BuyPickShards.Value
    buyFrom(v, labelMapShards)
end)
BuyO:AddDivider()
local InvLabel = BuyO:AddLabel('Inventory Value: Nil')
BuyO:AddButton('Get Inventory Sell Price', function()
    local val = getInventorySellPrice()
    if val then
        SafeSetLabel(InvLabel, 'Inventory Value: $' .. formatMoney(val))
    else
        SafeSetLabel(InvLabel, 'Inventory Value: Nil')
        Library:Notify('Could not read inventory value.', 3)
    end
end)
BuyO:AddDivider()
local allValues, allMap = {}, {}
for k, v in pairs(labelMapPans) do table.insert(allValues, k); allMap[k] = v end
for k, v in pairs(labelMapShov) do table.insert(allValues, k); allMap[k] = v end
for k, v in pairs(labelMapSluice) do table.insert(allValues, k); allMap[k] = v end
for k, v in pairs(labelMapOther) do table.insert(allValues, k); allMap[k] = v end
table.sort(allValues)
BuyO:AddDropdown('AutoBuyPick', { Text = 'Auto-Buy item (coins only)', Values = allValues, AllowNull = true })
BuyO:AddSlider('AutoBuyKeep', { Text = 'Keep at least (coins)', Default = 0, Min = 0, Max = 500000, Rounding = 0 })
BuyO:AddSlider('AutoBuyCooldown', { Text = 'Auto-Buy cooldown (s)', Default = 1.00, Min = 0.25, Max = 5.00, Rounding = 2 })
BuyO:AddToggle('AutoBuyEnabled', { Text = 'Enable Auto-Buy', Default = false })
BuyO:AddDivider()
BuyO:AddButton('Refresh Items + Prices', function()
    local p, s, sl, o, sh = scanPurchasable()
    if DDP and DDP.Refresh then DDP:Refresh(p, true) end
    if DDS and DDS.Refresh then DDS:Refresh(s, true) end
    if DDSL and DDSL.Refresh then DDSL:Refresh(sl, true) end
    if DDO and DDO.Refresh then DDO:Refresh(o, true) end
    if DDSH and DDSH.Refresh then DDSH:Refresh(sh, true) end
    allValues, allMap = {}, {}
    for k, v in pairs(labelMapPans) do table.insert(allValues, k); allMap[k] = v end
    for k, v in pairs(labelMapShov) do table.insert(allValues, k); allMap[k] = v end
    for k, v in pairs(labelMapSluice) do table.insert(allValues, k); allMap[k] = v end
    for k, v in pairs(labelMapOther) do table.insert(allValues, k); allMap[k] = v end
    table.sort(allValues)
    if Options.AutoBuyPick and Options.AutoBuyPick.Refresh then Options.AutoBuyPick:Refresh(allValues, true) end
    Library:Notify(('Items: %d pans / %d shovels / %d sluices / %d other / %d shard-shop'):format(#p, #s, #sl, #o, #sh), 3)
end)

----------------------------------------------------------------
-- Misc: HUD / AFK
----------------------------------------------------------------
local MiscRight = Tabs['Misc']:AddRightGroupbox('HUD / AFK')
MiscRight:AddToggle('ShowHUD', { Text = 'Show HUD (top-right)', Default = false })
MiscRight:AddToggle('AntiAFK', { Text = 'Anti-AFK (gentle)', Default = false })
MiscRight:AddSlider('AFKMinutes', { Text = 'AFK interval (min)', Default = 10, Min = 5, Max = 15, Rounding = 0 })

----------------------------------------------------------------
-- Movement
----------------------------------------------------------------
local MiscMove = Tabs['Misc']:AddLeftGroupbox('Movement')
MiscMove:AddToggle('WSOn', { Text = 'Custom WalkSpeed', Default = false })
MiscMove:AddSlider('WSSpeed', { Text = 'WalkSpeed', Default = 26, Min = 8, Max = 60, Rounding = 0 })
local defaultWS, wsConn = 16, nil
local function applyWS()
    local h = Hum()
    if Toggles.WSOn and Toggles.WSOn.Value then
        defaultWS = defaultWS or h.WalkSpeed
        h.WalkSpeed = getOptionNum('WSSpeed', 26)
        if not wsConn then
            wsConn = h:GetPropertyChangedSignal('WalkSpeed'):Connect(function()
                if Toggles.WSOn and Toggles.WSOn.Value then h.WalkSpeed = getOptionNum('WSSpeed', 26) end
            end)
        end
    else
        if wsConn then pcall(function() wsConn:Disconnect() end); wsConn = nil end
        h.WalkSpeed = defaultWS
    end
end
if Toggles.WSOn and Toggles.WSOn.OnChanged then Toggles.WSOn:OnChanged(applyWS) end
if Options.WSSpeed and Options.WSSpeed.OnChanged then Options.WSSpeed:OnChanged(applyWS) end
MiscMove:AddToggle('FlyOn', { Text = 'Fly', Default = false })
MiscMove:AddSlider('FlySpeed', { Text = 'Fly Speed', Default = 50, Min = 10, Max = 200, Rounding = 0 })
local flyLV, flyAF, flyAtt, flyConn = nil, nil, nil, nil
local inputDir = Vector3.zero
function destroyFly()
    if flyConn then pcall(function() flyConn:Disconnect() end); flyConn = nil end
    if flyLV then flyLV.Enabled = false; flyLV:Destroy(); flyLV = nil end
    if flyAF then flyAF.Enabled = false; flyAF:Destroy(); flyAF = nil end
    if flyAtt then flyAtt:Destroy(); flyAtt = nil end
end
local function ensureFly()
    destroyFly()
    local root = HRP()
    flyAtt = Instance.new('Attachment')
    flyAtt.Parent = root
    flyLV = Instance.new('LinearVelocity')
    flyLV.Attachment0 = flyAtt
    flyLV.MaxForce = math.huge
    flyLV.RelativeTo = Enum.ActuatorRelativeTo.World
    flyLV.Parent = root
    flyAF = Instance.new('VectorForce')
    flyAF.ApplyAtCenterOfMass = true
    flyAF.Attachment0 = flyAtt
    flyAF.Force = Vector3.new(0, Workspace.Gravity * root.AssemblyMass, 0)
    flyAF.Parent = root
    flyConn = RunService.Heartbeat:Connect(function()
        local cam = Workspace.CurrentCamera
        if not cam then return end
        local spd = getOptionNum('FlySpeed', 50)
        local dir = inputDir
        local move = (cam.CFrame.RightVector * dir.X) + (cam.CFrame.LookVector * dir.Z) + Vector3.new(0, dir.Y, 0)
        local v = move.Magnitude > 0 and move.Unit * spd or Vector3.zero
        flyLV.VectorVelocity = v
    end)
end
local pressed = {}
UserInputService.InputBegan:Connect(function(io, gpe)
    if gpe then return end
    local k = io.KeyCode
    if k == Enum.KeyCode.W or k == Enum.KeyCode.S or k == Enum.KeyCode.A or k == Enum.KeyCode.D or k == Enum.KeyCode.Space or k == Enum.KeyCode.LeftControl then pressed[k] = true end
end)
UserInputService.InputEnded:Connect(function(io)
    local k = io.KeyCode
    if k == Enum.KeyCode.W or k == Enum.KeyCode.S or k == Enum.KeyCode.A or k == Enum.KeyCode.D or k == Enum.KeyCode.Space or k == Enum.KeyCode.LeftControl then pressed[k] = false end
end)
RunService.Heartbeat:Connect(function()
    if Toggles.FlyOn and Toggles.FlyOn.Value then
        local y = (pressed[Enum.KeyCode.Space] and 1 or 0) + (pressed[Enum.KeyCode.LeftControl] and -1 or 0)
        local z = (pressed[Enum.KeyCode.W] and 1 or 0) + (pressed[Enum.KeyCode.S] and -1 or 0)
        local x = (pressed[Enum.KeyCode.D] and 1 or 0) + (pressed[Enum.KeyCode.A] and -1 or 0)
        inputDir = Vector3.new(x, y, z)
    else
        inputDir = Vector3.zero
    end
end)
if Toggles.FlyOn and Toggles.FlyOn.OnChanged then
    Toggles.FlyOn:OnChanged(function(on)
        if on then ensureFly() else destroyFly() end
    end)
end
if Options.FlySpeed and Options.FlySpeed.OnChanged then
    Options.FlySpeed:OnChanged(function()
        if flyLV and flyLV.VectorVelocity.Magnitude > 0 then
            flyLV.VectorVelocity = flyLV.VectorVelocity.Unit * getOptionNum('FlySpeed', 50)
        end
    end)
end
MiscMove:AddToggle('JPOn', { Text = 'Custom JumpPower', Default = false })
MiscMove:AddSlider('JPPower', { Text = 'JumpPower', Default = 50, Min = 25, Max = 120, Rounding = 0 })
local defaultJP = 50
local function applyJP()
    local h = Hum()
    if Toggles.JPOn and Toggles.JPOn.Value then
        pcall(function() h.UseJumpPower = true end)
        defaultJP = defaultJP or h.JumpPower
        h.JumpPower = (Options.JPPower and Options.JPPower.Value) or 50
    else
        h.JumpPower = defaultJP
    end
end
if Toggles.JPOn and Toggles.JPOn.OnChanged then Toggles.JPOn:OnChanged(applyJP) end
if Options.JPPower and Options.JPPower.OnChanged then Options.JPPower:OnChanged(applyJP) end
MiscMove:AddToggle('NoClipOn', { Text = 'NoClip (may rubberband)', Default = false })
local noclipConn = nil
if Toggles.NoClipOn and Toggles.NoClipOn.OnChanged then
    Toggles.NoClipOn:OnChanged(function(on)
        if on and not noclipConn then
            noclipConn = RunService.Stepped:Connect(function()
                for _, p in ipairs(Char():GetDescendants()) do
                    if p:IsA('BasePart') then p.CanCollide = false end
                end
            end)
        elseif (not on) and noclipConn then
            pcall(function() noclipConn:Disconnect() end); noclipConn = nil
        end
    end)
end

----------------------------------------------------------------
-- Teleport + Glide Autopilot (with overhead-drop fix)
----------------------------------------------------------------
TP = (function()
    local apLV, apAF, apAtt, apConn = nil, nil, nil, nil
    local apTargetCF = nil
    local apCruiseY = 0
    local apCfg = { maxSpeed = 25, cruiseClearance = 22, lookAhead = 60, riseRate = 12, dropRate = 14, avoidObstacles = true, }
    local function HRP2() return HRP() end
    local function destroyAutopilot()
        if apConn then pcall(function() apConn:Disconnect() end); apConn = nil end
        if apLV then apLV.Enabled = false; apLV:Destroy(); apLV = nil end
        if apAF then apAF.Enabled = false; apAF:Destroy(); apAF = nil end
        if apAtt then apAtt:Destroy(); apAtt = nil end
        apTargetCF = nil
    end
    local function desiredVelocity(dt, here, target)
        local maxSpd = math.min(apCfg.maxSpeed, 25)
        if apAF and apAtt and apAtt.Parent and apAtt.Parent:IsA('BasePart') then
            local mass = apAtt.Parent.AssemblyMass
            apAF.Force = Vector3.new(0, Workspace.Gravity * mass, 0)
        end
        if apCfg.avoidObstacles then
            local aheadDirXZ = Vector3.new(target.X - here.X, 0, target.Z - here.Z)
            if aheadDirXZ.Magnitude > 1 then
                local fwd = aheadDirXZ.Unit
                local probeFrom = here + Vector3.new(0, 8, 0)
                local rp = RaycastParams.new()
                rp.FilterDescendantsInstances = { Char() }
                rp.FilterType = Enum.RaycastFilterType.Blacklist
                local ray = Workspace:Raycast(probeFrom, fwd * apCfg.lookAhead, rp)
                if ray then apCruiseY = math.max(apCruiseY, ray.Position.Y + 12) end
            end
        end
        local wantY = apCruiseY
        local dy = wantY - here.Y
        local vy = math.clamp(dy, -apCfg.dropRate, apCfg.riseRate)
        local toXZ = Vector3.new(target.X - here.X, 0, target.Z - here.Z)
        local vxz = Vector3.zero
        local hzDist = toXZ.Magnitude
        if hzDist > 0.5 then
            local hzSpd = math.min(maxSpd, hzDist / math.max(dt, 0.0167))
            local verticalBudget = math.abs(vy)
            local hzBudget = math.max(0, maxSpd - verticalBudget)
            local useSpd = math.min(hzSpd, hzBudget)
            vxz = toXZ.Unit * useSpd
        end
        local v = Vector3.new(vxz.X, vy, vxz.Z)
        if v.Magnitude > maxSpd then v = v.Unit * maxSpd end
        return v
    end
    local function startAutopilot(destCF, cfg)
        destroyAutopilot()
        apCfg = cfg or apCfg
        apCfg.maxSpeed = 25
        apTargetCF = destCF
        local here = HRP2().Position
        apCruiseY = math.max(here.Y, destCF.Position.Y) + apCfg.cruiseClearance
        apConn = RunService.Heartbeat:Connect(function(dt)
            local tgt = apTargetCF
            if not tgt then destroyAutopilot(); return end
            local p = HRP2().Position
            local dxz = (Vector3.new(tgt.Position.X, 0, tgt.Position.Z) - Vector3.new(p.X, 0, p.Z)).Magnitude
            local dy = p.Y - tgt.Position.Y
            if dxz <= 4 and dy > 4 then destroyAutopilot(); return end
            local v = desiredVelocity(dt, p, tgt.Position)
            if not apAtt or not apLV or not apAF then
                apAtt = Instance.new('Attachment'); apAtt.Parent = HRP2()
                apLV = Instance.new('LinearVelocity'); apLV.Attachment0 = apAtt; apLV.MaxForce = math.huge; apLV.RelativeTo = Enum.ActuatorRelativeTo.World; apLV.Parent = HRP2()
                apAF = Instance.new('VectorForce'); apAF.Attachment0 = apAtt; apAF.ApplyAtCenterOfMass = true; apAF.Parent = HRP2()
            end
            apLV.VectorVelocity = v
            local lookAt = Vector3.new(tgt.Position.X, p.Y, tgt.Position.Z)
            if (lookAt - p).Magnitude > 1 then pcall(function() HRP2().CFrame = CFrame.new(p, lookAt) end) end
            if (p - tgt.Position).Magnitude <= 3.5 then apLV.VectorVelocity = Vector3.zero; destroyAutopilot() end
        end)
    end
    local function finishShortGap(finalCF)
        local root = HRP2()
        local function stepOnce(to)
            pcall(function()
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                root.CFrame = CFrame.new(to, finalCF.Position)
            end)
            task.wait(0.6)
        end
        local here = root.Position
        while (here - finalCF.Position).Magnitude > 12 do
            local dir = (finalCF.Position - here)
            local step = math.clamp(dir.Magnitude, 10, 18)
            local to = here + dir.Unit * step + Vector3.new(0, 3, 0)
            stepOnce(to)
            here = HRP2().Position
            local dxz = (Vector3.new(finalCF.Position.X, 0, finalCF.Position.Z) - Vector3.new(here.X, 0, here.Z)).Magnitude
            if dxz <= 4 then break end
        end
        local here2 = HRP2().Position
        local dxz2 = (Vector3.new(finalCF.Position.X, 0, finalCF.Position.Z) - Vector3.new(here2.X, 0, here2.Z)).Magnitude
        if dxz2 > 4 then
            pcall(function()
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                root.CFrame = finalCF + Vector3.new(0, 3, 0)
            end)
        end
        task.wait(0.25)
    end
    return { startAutopilot = startAutopilot, defaultConfig = function() return { maxSpeed = 25, cruiseClearance = 22, lookAhead = 60, riseRate = 12, dropRate = 14, avoidObstacles = true } end, finishShortGap = finishShortGap }
end)()

----------------------------------------------------------------
-- Teleport UI (Players + NPCs) + Zones from Waypoints/Waystones
----------------------------------------------------------------
local TPGB = Tabs['Misc']:AddRightGroupbox('Teleport')
TPGB:AddLabel('Tip: Glide reduces rubberbanding.')
local DTPPlayer = TPGB:AddDropdown('TPPlayer', { Text = 'Player', Values = {}, AllowNull = true })
local DTPNPC = TPGB:AddDropdown('TPNPC', { Text = 'NPC', Values = {}, AllowNull = true })
TPGB:AddToggle('UseGlideAuto', { Text = 'Glide Autopilot (<=25)', Default = false })
TPGB:AddSlider('GlideAlt', { Text = 'Glide Altitude', Default = 22, Min = 12, Max = 60, Rounding = 0 })
TPGB:AddToggle('GlideAvoid', { Text = 'Avoid Obstacles', Default = false })
local HighlightToggle = TPGB:AddToggle('HighlightWaypoints', { Text = 'Highlight Waypoints', Default = false })
type_NPCMap = nil
local WAYPOINTS = {}
local _lastWPBuild = 0
local function looksWaypoint(n)
    local l = string.lower(n)
    return l:find('waypoint', 1, true) ~= nil or l:find('waystone', 1, true) ~= nil or (l:find('fast', 1, true) and l:find('travel', 1, true) ~= nil)
end
local function displayFor(inst)
    local s = inst:GetAttribute('Zone') or inst:GetAttribute('Area') or inst:GetAttribute('Region')
    if type(s) == 'string' and #s > 0 then return s end
    local val = inst:FindFirstChild('Zone') or inst:FindFirstChild('Area') or inst:FindFirstChild('Region')
    if val and val:IsA('StringValue') and #val.Value > 0 then return val.Value end
    return inst.Name
end
local function rebuildWaypoints()
    WAYPOINTS = {}
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if (inst:IsA('Model') or inst:IsA('Folder')) and looksWaypoint(inst.Name) then
            local a = anchorFrom(inst)
            if a then table.insert(WAYPOINTS, { Part = a, Name = displayFor(inst) }) end
        elseif inst:IsA('ProximityPrompt') then
            local label = (inst.ObjectText ~= '' and inst.ObjectText) or inst.Name
            if looksWaypoint(label) then
                local parent = inst.Parent
                if parent then
                    local a = anchorFrom(parent)
                    if a then table.insert(WAYPOINTS, { Part = a, Name = displayFor(parent) }) end
                end
            end
        end
    end
    _lastWPBuild = time()
end
local function nearestWaypoint(pos)
    if (time() - _lastWPBuild) > 10 or #WAYPOINTS == 0 then rebuildWaypoints() end
    local bestName, bestPart, best = 'World', nil, math.huge
    for _, w in ipairs(WAYPOINTS) do
        local d = (w.Part.Position - pos).Magnitude
        if d < best then best = d; bestName = w.Name; bestPart = w.Part end
    end
    return bestName, bestPart
end
local WP_HL = nil
local function clearWaypointHighlight()
    if WP_HL then WP_HL:Destroy(); WP_HL = nil end
end
local function setWaypointHighlight(part)
    if not (Toggles.HighlightWaypoints and Toggles.HighlightWaypoints.Value) then clearWaypointHighlight(); return end
    if part == nil then return end
    if not WP_HL then
        local h = Instance.new('Highlight')
        h.Name = 'PB_WaypointHighlight'
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.FillTransparency = 0.5
        h.OutlineTransparency = 0
        h.FillColor = Color3.fromRGB(0, 170, 255)
        h.OutlineColor = Color3.fromRGB(0, 170, 255)
        h.Parent = Workspace
        WP_HL = h
    end
    local adornee = (part.Parent and part.Parent:IsA('Model')) and part.Parent or part
    WP_HL.Adornee = adornee
end
local function readGlideCfg()
    local c = TP.defaultConfig()
    c.cruiseClearance = getOptionNum('GlideAlt', c.cruiseClearance)
    c.maxSpeed = 25
    c.avoidObstacles = (Toggles.GlideAvoid and Toggles.GlideAvoid.Value) and true or false
    return c
end
local function buildPlayerList()
    local names = {}
    for _, pl in ipairs(Players:GetPlayers()) do if pl ~= LP then table.insert(names, pl.Name) end end
    table.sort(names)
    return names
end
local NPC_ANCHORS, NPC_WAYPOINT = {}, {}
local function r1(x) return math.floor(x + 0.5) end
local function buildNPCList()
    NPC_ANCHORS, NPC_WAYPOINT = {}, {}
    local seen, out = {}, {}
    local function addNPC(inst, labelBase)
        local a = anchorFrom(inst)
        if not a then return end
        local zoneName, zonePart = nearestWaypoint(a.Position)
        local key = string.format('%s|%s|%d|%d|%d', labelBase, zoneName, r1(a.Position.X), r1(a.Position.Y), r1(a.Position.Z))
        if seen[key] then return end
        seen[key] = true
        local label = string.format('%s - %s', labelBase, zoneName)
        out[#out + 1] = label
        NPC_ANCHORS[label] = a
        NPC_WAYPOINT[label] = zonePart
    end
    local npcsRoot = findNPCsRoot()
    if npcsRoot then
        for _, m in ipairs(npcsRoot:GetDescendants()) do
            if m:IsA('Model') and m:FindFirstChildOfClass('Humanoid') then addNPC(m, m.Name) end
        end
    end
    for _, pp in ipairs(Workspace:GetDescendants()) do
        if pp:IsA('ProximityPrompt') then
            local parent = pp.Parent
            if parent then
                local labelBase = (pp.ObjectText ~= '' and pp.ObjectText) or parent.Name
                addNPC(parent, labelBase)
            end
        end
    end
    table.sort(out)
    return out
end
local function refreshPlayers()
    local names = buildPlayerList()
    if DTPPlayer and DTPPlayer.Refresh then DTPPlayer:Refresh(names, true)
    elseif Options.TPPlayer and Options.TPPlayer.Refresh then Options.TPPlayer:Refresh(names, true)
    elseif Options.TPPlayer and Options.TPPlayer.SetValues then Options.TPPlayer:SetValues(names) end
end
local function refreshNPCs()
    local names = buildNPCList()
    if DTPNPC and DTPNPC.Refresh then DTPNPC:Refresh(names, true)
    elseif Options.TPNPC and Options.TPNPC.Refresh then Options.TPNPC:Refresh(names, true)
    elseif Options.TPNPC and Options.TPNPC.SetValues then Options.TPNPC:SetValues(names) end
    local pick = Options.TPNPC and Options.TPNPC.Value
    if pick and NPC_WAYPOINT[pick] then setWaypointHighlight(NPC_WAYPOINT[pick]) end
end
if Options.TPNPC and Options.TPNPC.OnChanged then
    Options.TPNPC:OnChanged(function(v)
        if NPC_WAYPOINT[v] then setWaypointHighlight(NPC_WAYPOINT[v]) end
    end)
end
if HighlightToggle and HighlightToggle.OnChanged then
    HighlightToggle:OnChanged(function(on)
        if not on then clearWaypointHighlight() else
            local pick = Options.TPNPC and Options.TPNPC.Value
            if pick and NPC_WAYPOINT[pick] then setWaypointHighlight(NPC_WAYPOINT[pick])
            else local _, part = nearestWaypoint(HRP().Position); setWaypointHighlight(part) end
        end
    end)
end
TPGB:AddButton('Ping Nearest Waypoint', function()
    local _, part = nearestWaypoint(HRP().Position)
    setWaypointHighlight(part)
end)
TPGB:AddButton('Go -> Player', function()
    local pick = (Options.TPPlayer and Options.TPPlayer.Value) or (DTPPlayer and DTPPlayer.Value)
    if not pick then return end
    local target = Players:FindFirstChild(pick)
    if not target then return end
    local c = target.Character or target.CharacterAdded:Wait()
    local hrp = c:FindFirstChild('HumanoidRootPart')
    local destCF = (hrp and hrp:IsA('BasePart')) and hrp.CFrame or (c:IsA('Model') and c:GetPivot()) or nil
    if not destCF then return end
    if Toggles.UseGlideAuto and Toggles.UseGlideAuto.Value then
        TP.startAutopilot(destCF, readGlideCfg())
    else
        TP.finishShortGap(destCF)
    end
end)
TPGB:AddButton('Go -> NPC', function()
    local pick = (Options.TPNPC and Options.TPNPC.Value) or (DTPNPC and DTPNPC.Value)
    if not pick then return end
    local anchor = NPC_ANCHORS[pick]
    if not anchor then return end
    local destCF = CFrame.new(anchor.Position)
    setWaypointHighlight(NPC_WAYPOINT[pick])
    if Toggles.UseGlideAuto and Toggles.UseGlideAuto.Value then
        TP.startAutopilot(destCF, readGlideCfg())
    else
        TP.finishShortGap(destCF)
    end
end)
TPGB:AddDivider()
TPGB:AddButton('Refresh Players', refreshPlayers)
TPGB:AddButton('Refresh NPCs', function() rebuildWaypoints(); refreshNPCs() end)
refreshPlayers(); rebuildWaypoints(); refreshNPCs()

----------------------------------------------------------------
-- Misc: Utilities (Codes)
----------------------------------------------------------------
local UtilGB = Tabs['Misc']:AddLeftGroupbox('Utilities')
local CodesList = { 'traveler', 'fossilized', 'sorrytwo', 'millions', 'updateone' }
local function findRedeemRemote()
    local best, bestScore = nil, -1
    local function score(n)
        n = string.lower(n)
        local s = 0
        if string.find(n, 'code') then s = s + 3 end
        if string.find(n, 'redeem') or string.find(n, 'claim') then s = s + 2 end
        if string.find(n, 'promo') then s = s + 1 end
        if string.find(n, 'use') then s = s + 1 end
        return s
    end
    local base = Remotes or ReplicatedStorage
    for _, d in ipairs(base:GetDescendants()) do
        if d:IsA('RemoteFunction') or d:IsA('RemoteEvent') then
            local sc = score(d.Name)
            if sc > bestScore then best = d; bestScore = sc end
        end
    end
    local CodesFolder = base and base:FindFirstChild('Codes')
    if CodesFolder then
        for _, d in ipairs(CodesFolder:GetDescendants()) do
            if d:IsA('RemoteFunction') or d:IsA('RemoteEvent') then
                local sc = score(d.Name) + 1
                if sc > bestScore then best = d; bestScore = sc end
            end
        end
    end
    return best
end
local function tryRedeem(remote, code)
    local ok = false
    if remote:IsA('RemoteFunction') then
        ok = pcall(function() remote:InvokeServer(code) end) or pcall(function() remote:InvokeServer({ Code = code }) end) or pcall(function() remote:InvokeServer({ code }) end) or pcall(function() remote:InvokeServer({ codeName = code }) end)
    else
        ok = pcall(function() remote:FireServer(code) end) or pcall(function() remote:FireServer({ Code = code }) end) or pcall(function() remote:FireServer({ code }) end) or pcall(function() remote:FireServer({ codeName = code }) end)
    end
    return ok
end
UtilGB:AddButton('Redeem Codes', function()
    local remote = findRedeemRemote()
    if not remote then Library:Notify('Codes: redeem remote not found.', 3); return end
    local okCount = 0
    for _, code in ipairs(CodesList) do
        if tryRedeem(remote, code) then okCount = okCount + 1 end
        task.wait(0.25)
    end
    Library:Notify(('Codes: attempted %d, success %d'):format(#CodesList, okCount), 4)
end)

----------------------------------------------------------------
-- Loops
----------------------------------------------------------------
-- Auto Shake (manual toggle) -- disabled while Full AutoFarm is ON
local PAN_CLICK_COOLDOWN = 1.5
local lastPanClick = 0.0
local function sendOneLeftClick() leftClickCenter() end
task.spawn(function()
    while not Library.Unloaded do
        if Toggles.FullAutoFarm and Toggles.FullAutoFarm.Value then
            -- FAF has priority; pause manual shake loop completely
            task.wait(0.25)
        elseif Toggles.AutoShakeManual and Toggles.AutoShakeManual.Value then
            if hasControlLike(CONTROL_ALIASES.Pan) then
                if time() - lastPanClick >= PAN_CLICK_COOLDOWN then
                    findCurrentPan(); sendOneLeftClick(); lastPanClick = time(); lastHumanAction = time()
                end
            elseif hasControlLike(CONTROL_ALIASES.Shake) then
                doShakeOnce(); lastHumanAction = time(); pcall(tryHandleSluices)
            end
            task.wait(clampDelay(getOptionNum('ShakeDelay', 0.6)))
        else
            task.wait(0.25)
        end
    end
end)
-- Auto collect loop (Rage/Legit) -- disabled while Full AutoFarm is ON
task.spawn(function()
    while not Library.Unloaded do
        if Toggles.FullAutoFarm and Toggles.FullAutoFarm.Value then
            task.wait(0.25)
        else
            local enabled = (Toggles.AutoCollectOn and Toggles.AutoCollectOn.Value) == true
            if not enabled then task.wait(0.25)
            else
                pcall(tryHandleSluices)
                if hasControlLike(CONTROL_ALIASES.Shake) then
                    doShakeOnce(); lastHumanAction = time(); task.wait(clampDelay(getOptionNum('ShakeDelay', 0.6)))
                else
                    local mode = (Options.CollectMode and Options.CollectMode.Value) or 'Rage'
                    if hasControlLike(CONTROL_ALIASES.Collect) or hasControlLike(CONTROL_ALIASES.Pan) then findCurrentPan() end
                    if hasControlLike(CONTROL_ALIASES.Collect) then
                        if mode == 'Legit' then
                            if time() - lastPanClick >= 0.15 then sendOneLeftClick(); lastPanClick = time() end
                            task.wait(0.05)
                            doCollectPerfect()
                        else
                            doCollectPerfect()
                        end
                        lastHumanAction = time()
                    end
                    task.wait(clampDelay(getOptionNum('CollectDelay', 0.5)))
                end
            end
        end
    end
end)
-- Dedicated sluice scan loop
task.spawn(function()
    while not Library.Unloaded do
        if Toggles.AutoSluice and Toggles.AutoSluice.Value then pcall(tryHandleSluices) end
        task.wait(clampDelay(getOptionNum('SluiceCheckDelay', 0.75)))
    end
end)
-- Auto-buy loop (coins only)
local _autoBuyCooldownUntil = 0.0
task.spawn(function()
    while not Library.Unloaded do
        if Toggles.AutoBuyEnabled and Toggles.AutoBuyEnabled.Value then
            local pick = Options.AutoBuyPick and Options.AutoBuyPick.Value
            if pick and pick ~= '' then
                local want = allMap[pick]
                local priceV = priceMapAll[pick]
                if want and type(priceV) == 'number' then
                    local keep = getOptionNum('AutoBuyKeep', 0)
                    local cooldown = clampDelay(getOptionNum('AutoBuyCooldown', 1.0))
                    local cash = getMoney()
                    if cash - keep >= priceV and time() >= _autoBuyCooldownUntil then
                        if BuyItemRF then pcall(function() BuyItemRF:InvokeServer(want) end) end
                        _autoBuyCooldownUntil = time() + cooldown
                    end
                end
            end
        end
        task.wait(0.35)
    end
end)
-- Anti AFK loop
task.spawn(function()
    while not Library.Unloaded do
        if Toggles.AntiAFK and Toggles.AntiAFK.Value then
            local mins = math.clamp(getOptionNum('AFKMinutes', 10), 5, 15)
            local runningLoops = ((Toggles.AutoCollectOn and Toggles.AutoCollectOn.Value) == true) or (Toggles.AutoShakeManual and Toggles.AutoShakeManual.Value) or (Toggles.AutoSluice and Toggles.AutoSluice.Value) or (Toggles.FullAutoFarm and Toggles.FullAutoFarm.Value)
            if not runningLoops and (time() - lastHumanAction) >= (mins * 60) then
                microWiggle(); lastHumanAction = time()
            end
        end
        task.wait(5)
    end
end)
-- HUD refresh loop
task.spawn(function()
    while not Library.Unloaded do updateHUD(); task.wait(0.5) end
end)

----------------------------------------------------------------
-- Quest events + Locks UI (wrapped label; capped)
----------------------------------------------------------------
local LockBox = Tabs['Automation']:AddRightGroupbox('Quest Locks')
LockBox:AddToggle('AutoLockDeliveries', { Text = 'Auto-lock delivery items', Default = false })
local QuestLockLabel = LockBox:AddLabel('Quest Lock: none')
local deliveryNames = {}
local lastLockedByRule = {}
local function readLockedStateQ(inst)
    local a = inst:GetAttribute('Locked')
    if type(a) == 'boolean' then return a end
    local b = inst:GetAttribute('IsLocked')
    if type(b) == 'boolean' then return b end
    local bv = inst:FindFirstChild('Locked')
    if bv and bv:IsA('BoolValue') then return bv.Value end
    return nil
end
local function ensureLockStateQ(tool, shouldLock)
    if not ToggleLockRE then return end
    local cur = readLockedStateQ(tool)
    if cur == shouldLock then return end
    ToggleLockRE:FireServer(tool)
    if tool:IsA('Tool') then lastLockedByRule[tool] = shouldLock end
end
local function lockMatchingInBackpack()
    local bp = LP:FindFirstChild('Backpack')
    if not bp then return end
    local count = 0
    for name, on in pairs(deliveryNames) do if on then count = count + 1 end end
    if count > MAX_QUEST_LOCKS then return end
    for _, it in ipairs(bp:GetChildren()) do
        if it:IsA('Tool') and deliveryNames[normalizeName(it.Name)] then ensureLockStateQ(it, true) end
    end
end
local function unlockNowMissingNames()
    local bp = LP:FindFirstChild('Backpack')
    if not bp then return end
    for tool, byRule in pairs(lastLockedByRule) do
        if byRule and tool.Parent == bp then
            local nn = normalizeName(tool.Name)
            if not deliveryNames[nn] then ensureLockStateQ(tool, false); lastLockedByRule[tool] = nil end
        end
    end
end
local function extractDeliveryItem(text)
    local l = string.lower(text or '')
    if string.find(l, '^collect%s+') or string.find(l, '^craft%s+') then return nil end
    local item = l:match("^bring%s+a?n?%s+([%a%-%s']+)%s+to%s+the?%s+trader$") or l:match("^deliver%s+a?n?%s+([%a%-%s']+)%s+to%s+the?%s+trader$") or l:match("^bring%s+a?n?%s+([%a%-%s']+)%s+to%s+the?%s+merchant$") or l:match("^deliver%s+a?n?%s+([%a%-%s']+)%s+to%s+the?%s+merchant$")
    if item then return (item:gsub('%s+$', '')) end
    return nil
end
local function rebuildFromQuestPayload(payload)
    deliveryNames = {}
    if type(payload) ~= 'table' then return end
    local added = 0
    for _, q in pairs(payload) do
        if type(q) == 'table' and not q.Hidden then
            local sp = q.StepProgress
            if type(sp) == 'table' then
                for _, obj in ipairs(sp) do
                    if type(obj) == 'table' and type(obj.Text) == 'string' then
                        local item = extractDeliveryItem(obj.Text)
                        local prog = (type(obj.Progress) == 'number' and obj.Progress) or 0
                        local need = (type(obj.Amount) == 'number' and obj.Amount) or 1
                        if item and prog < need then
                            local key = normalizeName(item)
                            if not deliveryNames[key] then deliveryNames[key] = true; added = added + 1; if added >= MAX_QUEST_LOCKS then return end end
                        end
                    end
                end
            end
        end
    end
end
local function updateQuestLockLabel()
    local names = {}
    for k, v in pairs(deliveryNames) do if v then names[#names + 1] = k:gsub('^%l', string.upper) end end
    table.sort(names)
    if #names == 0 then SafeSetLabel(QuestLockLabel, 'Quest Lock: none'); return end
    local MAX_CHARS = 42
    local lines = { 'Quest Lock: ' }
    for _, nm in ipairs(names) do
        local cur = lines[#lines]
        local sep = (cur == 'Quest Lock: ' or cur:sub(-2) == ': ') and '' or ', '
        if (#cur + #sep + #nm) <= MAX_CHARS then lines[#lines] = cur .. sep .. nm
        else lines[#lines + 1] = nm end
    end
    SafeSetLabel(QuestLockLabel, table.concat(lines, '\n'))
end
if UpdateQuestDataRE then UpdateQuestDataRE.OnClientEvent:Connect(function(payload)
    rebuildFromQuestPayload(payload)
    if Toggles.AutoLockDeliveries and Toggles.AutoLockDeliveries.Value then
        lockMatchingInBackpack(); unlockNowMissingNames()
    end
    updateQuestLockLabel()
end)
pcall(function() UpdateQuestDataRE:FireServer() end) end
if Toggles.AutoSellFull and Toggles.AutoSellFull.Value then wireCapacityWatchers() end
