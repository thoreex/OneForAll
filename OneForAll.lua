OneForAll_Name = "OneForAll"
OneForAll_FormalName = "One For All"
OneForAll_Version = "v1.1.0"
OneForAll_Events = {}
OneForAll_Callbacks = {}
OneForAll_Included = {}
OneForAll_Ignored = {
    "LibDBIcon10_"..OneForAll_Name,
    "TimeManagerClockButton",
    "MiniMapBattlefieldFrame",
    "MiniMapLFGFrameIcon"
}
OneForAll_IsShown = false
OneForAll_LibDataBroker = LibStub("LibDataBroker-1.1", true)
OneForAll_LibDBIcon = LibStub("LibDBIcon-1.0", true)
OneForAll_Frame = nil
OneForAll_MinimapIcon = nil

function OneForAll_OnLoad()
    OneForAll_Frame = CreateFrame("Frame")

    -- Register all events
    for OneForAll_Event, _ in pairs(OneForAll_Events) do
        OneForAll_Frame:RegisterEvent(OneForAll_Event)
    end
    OneForAll_Frame:SetScript("OnEvent", OneForAll_OnEvent)

    -- Register all callbacks
    for OneForAll_Callback, _ in pairs(OneForAll_Callbacks) do
        OneForAll_LibDBIcon.RegisterCallback(OneForAll_Frame, OneForAll_Callback, OneForAll_OnCallback)
    end
end

function OneForAll_OnEvent(self, event, ...)
    OneForAll_Events[event](self, ...)
end

function OneForAll_OnCallback(callback, ...)
    OneForAll_Callbacks[callback](callback, ...)
end

function OneForAll_OnClick(self, button)
    OneForAll_IsShown = not OneForAll_IsShown

    for _, button in ipairs(OneForAll_Included) do
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
    tooltip:AddLine("|cFFffffffClick to show/hide icons|r")
end

function OneForAll_AddButton(button)
    -- Store in a table
    tinsert(OneForAll_Included, button)

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
    local count = 0
    for _, button in ipairs(OneForAll_Included) do
        (function()
            if (not button.HiddenVisibility) then return end
        
            count = count + 1
        
            local xpos = count * OneForAll_MinimapIcon:GetWidth() * -1
            button:HiddenClearAllPoints()
            button:HiddenSetPoint("CENTER", OneForAll_MinimapIcon, "CENTER", xpos, 0)
        end)()
    end
end

function OneForAll_IsButtonIncluded(button1)
    local button1_name = button1:GetName()
    for _, button2 in ipairs(OneForAll_Included) do
        local button2_name = button2:GetName()
        if(button1_name == button2_name) then
            return true
        end
    end
    return false
end

function OneForAll_IsButtonIgnored(button1)
    local button1_name = button1:GetName()
    for _, button2_name in ipairs(OneForAll_Ignored) do
        if(button1_name == button2_name) then
            return true
        end
    end
    return false
end

function OneForAll_IsObjectAButton(object)
    return object:IsObjectType("button")
end

function OneForAll_ScanLibraryButtons()
    local buttons = OneForAll_LibDBIcon:GetButtonList()
    for _, name in ipairs(buttons) do
        local button = OneForAll_LibDBIcon:GetMinimapButton(name)
        if(not OneForAll_IsButtonIncluded(button) and
            not OneForAll_IsButtonIgnored(button)) then
            OneForAll_AddButton(button)
        end
    end
end

function OneForAll_ScanNonLibraryButtons()
    local children = { Minimap:GetChildren() }
    for _, child in ipairs(children) do
        if(not OneForAll_IsButtonIncluded(child) and
            not OneForAll_IsButtonIgnored(child) and
            OneForAll_IsObjectAButton(child)) then
            OneForAll_AddButton(child)
        end
    end
end

function OneForAll_ScanButtons()
    OneForAll_ScanLibraryButtons()
    OneForAll_ScanNonLibraryButtons()
end

function OneForAll_AddMessage(message)
    DEFAULT_CHAT_FRAME:AddMessage(message)
end

function OneForAll_Events:ADDON_LOADED(addonName)
    if (addonName == OneForAll_Name) then
        -- Database initialization
        if (OneForAll_Database == nil) then
            OneForAll_Database = {}
        end
    
        -- Minimap icon initialization
        local minimapIcon = OneForAll_LibDataBroker:NewDataObject(OneForAll_Name, {
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

        -- Load end
        OneForAll_AddMessage("|cffff0000"..OneForAll_FormalName.." "..OneForAll_Version.."|r loaded!")
    end
end

function OneForAll_Events:PLAYER_LOGIN()
    OneForAll_ScanButtons()
end

function OneForAll_Callbacks:LibDBIcon_IconCreated(button, ...)
    if(not OneForAll_IsButtonIncluded(button) and
        not OneForAll_IsButtonIgnored(button)) then
        OneForAll_AddButton(button)
    end
end

OneForAll_OnLoad()