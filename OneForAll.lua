OneForAll_Name = "OneForAll"
OneForAll_FormalName = "One For All"
OneForAll_Version = "v1.0.0"
OneForAll_Events = {}
OneForAll_IsShown = false
OneForAll_LibDBIcon = nil
OneForAll_Frame = nil
OneForAll_MinimapIcon = nil

function OneForAll_OnLoad()
    OneForAll_Frame = CreateFrame("Frame")

    -- Register all events
    for OneForAll_Event, _ in pairs(OneForAll_Events) do
        OneForAll_Frame:RegisterEvent(OneForAll_Event);
    end

    OneForAll_Frame:SetScript("OnEvent", OneForAll_OnEvent)
end

function OneForAll_OnEvent(self, event, ...)
    OneForAll_Events[event](self, ...)
end

function OneForAll_OnClick(self, button)
    OneForAll_IsShown = not OneForAll_IsShown

    local buttons = OneForAll_LibDBIcon:GetButtonList()
    for _, name in ipairs(buttons) do
        local button = OneForAll_LibDBIcon:GetMinimapButton(name)
        if (OneForAll_IsShown) then
            (function()
                if (not button.HiddenVisibility) then return end
                button:HiddenShow()
            end)()
        else
            (function()
                if (not button.HiddenVisibility) then return end
                button:HiddenHide()
            end)()
        end
    end

    -- Reposition buttons
    OneForAll_PositionButtons()
end

function OneForAll_OnTooltipShow(tooltip)
    if not tooltip or not tooltip.AddLine then return end
    tooltip:AddLine(OneForAll_FormalName.." "..OneForAll_Version)
    tooltip:AddLine("|cFFffffffClick to show/hide icons|r");
end

function OneForAll_AddButton(name)
    if (name == OneForAll_Name) then return end

    -- Get the button using the name
    local button = OneForAll_LibDBIcon:GetMinimapButton(name)

    -- Hide original functionality
    button.HiddenVisibility = button:IsVisible()
    button.HiddenShow = button.Show
    button.HiddenHide = button.Hide
    button.HiddenClearAllPoints = button.ClearAllPoints
    button.HiddenSetPoint = button.SetPoint

    -- Avoid addons altering the positions and visibility
    button.Show = function()
        button.HiddenVisibility = true
        if (OneForAll_IsShown) then
            button:HiddenShow()
            OneForAll_PositionButtons()
        end
    end
    button.Hide = function()
        button.HiddenVisibility = false
        if (OneForAll_IsShown) then
            button:HiddenHide()
            OneForAll_PositionButtons()
        end
    end
    button.ClearAllPoints = function() end
    button.SetPoint = function() end

    -- Hide the button
    button:HiddenHide()
end

function OneForAll_PositionButtons()
    local buttons = OneForAll_LibDBIcon:GetButtonList()

    local count = 0
    for _, name in ipairs(buttons) do
        (function()
            if (name == OneForAll_Name) then return end
        
            local button = OneForAll_LibDBIcon:GetMinimapButton(name)
            if (not button.HiddenVisibility) then return end
        
            count = count + 1
        
            local xpos = count * OneForAll_MinimapIcon:GetWidth() * -1
            button:HiddenClearAllPoints()
            button:HiddenSetPoint("CENTER", OneForAll_MinimapIcon, "CENTER", xpos, 0)
        end)()
    end
end

function OneForAll_ScanButtons()
    local buttons = OneForAll_LibDBIcon:GetButtonList()
    for _, name in ipairs(buttons) do
        OneForAll_AddButton(name)
    end
end

function OneForAll_IconCreated(self, button, name)
    OneForAll_AddButton(name)
end

function OneForAll_AddMessage(message)
    DEFAULT_CHAT_FRAME:AddMessage(message);
end

function OneForAll_Events:ADDON_LOADED(addonName)
    if (addonName == OneForAll_Name) then
        -- Database initialization
        if (OneForAll_Database == nil) then
            OneForAll_Database = {}
        end

        -- Icon library initialization
        OneForAll_LibDBIcon = LibStub("LibDBIcon-1.0", true)
    
        -- Minimap icon initialization
        local minimapIcon = LibStub("LibDataBroker-1.1"):NewDataObject(OneForAll_Name, {
            type = "data source",
            text = "One For All",
            icon = "Interface\\HelpFrame\\ReportLagIcon-Loot",
            OnClick = OneForAll_OnClick,
            OnTooltipShow = OneForAll_OnTooltipShow,
        })
    
        -- Icon registration
        OneForAll_LibDBIcon:Register(OneForAll_Name, minimapIcon, OneForAll_Database)
    
        -- Get icon registrated
        OneForAll_MinimapIcon = OneForAll_LibDBIcon:GetMinimapButton(OneForAll_Name)
    
        -- Register buttons created after One For All loaded
        OneForAll_LibDBIcon.RegisterCallback(OneForAll_LibDBIcon, "LibDBIcon_IconCreated", OneForAll_IconCreated)
    
        -- Scan buttons
        OneForAll_ScanButtons()

        -- Load end
        OneForAll_AddMessage("|cffff0000"..OneForAll_FormalName.." "..OneForAll_Version.."|r loaded!")
    end
end

OneForAll_OnLoad()