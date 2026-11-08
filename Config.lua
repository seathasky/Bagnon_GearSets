local _, GearSets = ...

-- Bagnon_Config is load-on-demand. Use its existing Sushi panel system without
-- loading it early or modifying any Bagnon files.
local function RegisterOptions()
    if GearSets.OptionsPanel or GearSets.GetSetting('sections') == nil then return end
    if not (Bagnon and Bagnon.GeneralOptions) then return end

    local Sushi = LibStub('Sushi-3.2')
    local panel = Sushi.OptionsGroup(Bagnon.GeneralOptions, 'Gear Sets')
    GearSets.OptionsPanel = panel
    panel:SetSubtitle('Separate equipment sets and your reagent bag in Bagnon. Settings apply to all characters.')
    panel:SetChildren(function(self)
        self:Add('Header', 'Sections', 'GameFontHighlight', true)

        local function AddToggle(key, label, tip)
            local check = self:Add('Check', label)
            check:SetTip(label, tip)
            check:SetValue(GearSets.GetSetting(key))
            check:SetCall('OnInput', function(_, value)
                GearSets.SetSetting(key, value)
            end)
        end

        AddToggle('sections', 'Separate Gear Sets',
            'Group saved equipment sets into sections titled Gearset: Name.')
        AddToggle('reagents', 'Separate Reagent Bag',
            'Place the equipped reagent bag and its empty slots in a Reagent Bag section.')

        self:Add('Header', 'Item Labels', 'GameFontHighlight', true).top = 15
        AddToggle('labels', 'Show Equipment Set Labels',
            'Show saved equipment-set names on gear icons in live bags and banks.')
    end)
    panel:SetCall('OnRefresh', function() panel:Update() end)
end

local events = CreateFrame('Frame')
events:RegisterEvent('PLAYER_LOGIN')
events:RegisterEvent('ADDON_LOADED')
events:SetScript('OnEvent', function(_, event, addonName)
    if event == 'PLAYER_LOGIN' or addonName == 'Bagnon_Config' then
        RegisterOptions()
    end
end)
