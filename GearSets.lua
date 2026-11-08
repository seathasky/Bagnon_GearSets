local _, GearSets = ...
local groups = setmetatable({}, {__mode = 'k'})
local headers = setmetatable({}, {__mode = 'k'})
local pending = false
local settings
local getEquipmentSetInfo

-- Use the slot API, not item IDs: two copies of the same item may belong
-- to different sets. Keep the complete set list for shared pieces.
local function Membership(button)
    if not button.hasItem or button:IsCached() then return end
    local inSet, names = getEquipmentSetInfo(button:GetBag(), button:GetID())
    if issecretvalue and (issecretvalue(inSet) or issecretvalue(names)) then return end
    if inSet and type(names) == 'string' and names ~= '' then
        return names
    end
end

local function UpdateLabel(button)
    local names = settings.labels and Membership(button)
    local label = button.BagnonGearSetLabel
    if names and not label then
        label = button:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
        label:SetPoint('TOPLEFT', button, 'TOPLEFT', 1, -3)
        label:SetPoint('TOPRIGHT', button, 'TOPRIGHT', -1, -3)
        label:SetFont(STANDARD_TEXT_FONT, 9, 'OUTLINE')
        label:SetTextColor(1, 0.82, 0.2)
        label:SetShadowColor(0, 0, 0, 1)
        label:SetShadowOffset(1, -1)
        label:SetWordWrap(false)
        button.BagnonGearSetLabel = label
    end
    if label then
        label:SetText(names and names:gsub('|', '||') or '')
        label:SetShown(names ~= nil and names ~= false)
    end
end

local function HideHeaders(group)
    for _, header in ipairs(headers[group] or {}) do header:Hide() end
end

local function IsReagentBag(bag)
    local reagentBag = Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag
    if reagentBag ~= nil then return bag == reagentBag end
    -- Some clients expose equipped bag counts instead of a reagent bag enum.
    return NUM_BAG_SLOTS and NUM_TOTAL_EQUIPPED_BAG_SLOTS
        and bag > NUM_BAG_SLOTS and bag <= NUM_TOTAL_EQUIPPED_BAG_SLOTS
end

local function Header(group, index, title, width, y)
    local pool = headers[group]
    if not pool then
        pool = {}
        headers[group] = pool
    end
    local header = pool[index]
    if not header then
        header = group:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
        header:SetJustifyH('LEFT')
        header:SetWordWrap(false)
        pool[index] = header
    end
    header:ClearAllPoints()
    header:SetPoint('TOPLEFT', group, 'TOPLEFT', 2, -y)
    header:SetSize(math.max(width - 4, 1), 18)
    -- Escape pipe markup in user-supplied equipment set names.
    header:SetText(title:gsub('|', '||'))
    header:Show()
end

local function Layout(group)
    if group.BagnonGearSetsBusy then return end
    local id = group:GetFrameID()
    if id ~= 'inventory' and id ~= 'bank' then return end
    groups[group] = true
    HideHeaders(group)
    for _, button in ipairs(group.buttons) do UpdateLabel(button) end

    -- Bagnon precreates inventory item buttons for combat and lays them out
    -- normally during lockdown. Reuse those buttons in combat as well; this
    -- addon never creates item buttons or changes their item actions.
    -- Cached owners and transposed grids retain Bagnon's native layout.
    if not (settings.sections or settings.reagents) or group:IsCached() or group.Transposed then return end
    local byName, sections, other, reagents = {}, {}, {}, {}
    for _, button in ipairs(group.buttons) do
        local names = settings.sections and Membership(button)
        if settings.reagents and id == 'inventory' and IsReagentBag(button:GetBag()) then
            reagents[#reagents + 1] = button
        elseif names then
            local section = byName[names]
            if not section then
                section = {name = 'Gearset: ' .. names, buttons = {}}
                byName[names] = section
                sections[#sections + 1] = section
            end
            section.buttons[#section.buttons + 1] = button
        else
            other[#other + 1] = button
        end
    end
    local hasGearSets = #sections > 0
    -- Reagent bags should remain separate even with no equipment sets saved.
    if not hasGearSets and #reagents == 0 then return end
    table.sort(sections, function(a, b) return a.name < b.name end)
    if #other > 0 then
        sections[#sections + 1] = {
            name = id == 'bank' and 'Bank Contents' or 'Bag Contents',
            buttons = other,
        }
    end
    if #reagents > 0 then
        sections[#sections + 1] = {name = 'Reagent Bag', buttons = reagents}
    end

    local columns, scale, size = group:LayoutTraits()
    columns = math.max(1, columns)
    local step = size * scale
    local width, y = columns * step, 0
    local headerOffset = hasGearSets and 1 or 0
    if hasGearSets then
        Header(group, 1, 'Gear Sets', width, y)
        y = y + 22
    end
    for index, section in ipairs(sections) do
        Header(group, index + headerOffset, section.name, width, y)
        y = y + 20
        for i, button in ipairs(section.buttons) do
            local column = (i - 1) % columns
            local row = math.floor((i - 1) / columns)
            button:ClearAllPoints()
            button:SetScale(scale)
            -- Button offsets are expressed in its own scaled coordinates.
            button:SetPoint('TOPLEFT', group, 'TOPLEFT', column * size, -(y / scale + row * size))
        end
        y = y + math.ceil(#section.buttons / columns) * step + 8
    end
    group.BagnonGearSetsBusy = true
    group:SetSize(math.max(width, 1), math.max(y - 8, 1))
    group.BagnonGearSetsBusy = nil
end

local function Refresh()
    pending = false
    for group in pairs(groups) do
        if group:IsShown() then group:Layout() end
    end
end

local function QueueRefresh()
    if not pending then
        pending = true
        C_Timer.After(0, Refresh)
    end
end

function GearSets.GetSetting(key)
    return settings and settings[key]
end

function GearSets.SetSetting(key, value)
    if settings and (key == 'sections' or key == 'labels' or key == 'reagents') then
        settings[key] = not not value
        QueueRefresh()
    end
end

local events = CreateFrame('Frame')
events:RegisterEvent('PLAYER_LOGIN')
events:SetScript('OnEvent', function(self, event)
    if event ~= 'PLAYER_LOGIN' then
        QueueRefresh()
        return
    end

    BagnonGearSetsDB = type(BagnonGearSetsDB) == 'table' and BagnonGearSetsDB or {}
    settings = BagnonGearSetsDB
    if settings.sections == nil then settings.sections = true end
    if settings.labels == nil then settings.labels = true end
    if settings.reagents == nil then settings.reagents = true end

    local addon = Bagnon
    -- Retail and Forever share the layout integration. Resolve the API by
    -- capability, including clients that expose the older global function.
    getEquipmentSetInfo = C_Container and C_Container.GetContainerItemEquipmentSetInfo
        or GetContainerItemEquipmentSetInfo
    if not (addon and addon.ItemGroup and addon.ContainerItem
        and type(getEquipmentSetInfo) == 'function') then
        print('|cffffcc00Bagnon Gear Sets:|r This Bagnon/client version is not supported.')
        return
    end

    hooksecurefunc(addon.ItemGroup, 'Layout', Layout)
    hooksecurefunc(addon.ContainerItem, 'Update', UpdateLabel)
    self:RegisterEvent('BAG_UPDATE_DELAYED')
    self:RegisterEvent('PLAYER_REGEN_ENABLED')
    -- The installed Bagnon already subscribes to this client event.
    self:RegisterEvent('EQUIPMENT_SETS_CHANGED')

    -- Bagnon can create its inventory before our PLAYER_LOGIN handler.
    -- UPDATE_ALL brings existing groups through the hooked class method.
    addon:SendSignal('UPDATE_ALL')

    SLASH_BAGNON_GEARSETS1 = '/bgs'
    SlashCmdList.BAGNON_GEARSETS = function(message)
        local command = message:lower():match('^%s*(%S+)')
        if command == 'labels' or command == 'sections' or command == 'reagents' then
            GearSets.SetSetting(command, not settings[command])
            if GearSets.OptionsPanel then GearSets.OptionsPanel:Update() end
        end
        print('|cffffcc00Bagnon Gear Sets:|r sections ' .. (settings.sections and 'on' or 'off')
            .. ', labels ' .. (settings.labels and 'on' or 'off')
            .. ', reagent bag ' .. (settings.reagents and 'on' or 'off')
            .. '. /bgs sections, /bgs labels, or /bgs reagents to toggle.')
    end
end)

-- Exposed only in the addon's private namespace for isolated integration tests.
GearSets.Membership = Membership
GearSets.Layout = Layout
