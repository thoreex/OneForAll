OneForAll_Name = "OneForAll"
OneForAll_FormalName = "One For All"
OneForAll_Version = "v1.2.3"
OneForAll_ButtonPrefix = "LibDBIcon10_"
OneForAll_Events = {}
OneForAll_Callbacks = {}
OneForAll_Scanned = {}
OneForAll_Included = {}
OneForAll_Excluded = {}
OneForAll_Ignored = {
    OneForAll_ButtonPrefix..OneForAll_Name,
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
    OneForAll_ToggleButtons()
    OneForAll_PositionButtons()
end

function OneForAll_OnTooltipShow(tooltip)
    if not tooltip or not tooltip.AddLine then return end
    tooltip:AddLine(OneForAll_FormalName.." "..OneForAll_Version)
    tooltip:AddLine("|cFFffffffClick to show/hide icons|r")
    tooltip:AddLine("|cFFffffffDrag and drop here to include/exclude icons|r")
end

function OneForAll_IncludeButton(button)
    -- Get button name
    local button_name = button:GetName()

    -- Store in a table
    tinsert(OneForAll_Included, button_name)

    -- Remove from a table
    local button_position = OneForAll_GetButtonExcludedPosition(button_name) 
    if (button_position > 0) then
        tremove(OneForAll_Excluded, button_position)
    end

    OneForAll_SortButtons()

    -- Hide original functionality
    button.HiddenVisibility = button:IsVisible()
    button.HiddenShow = button.Show
    button.HiddenHide = button.Hide
    button.HiddenClearAllPoints = button.ClearAllPoints
    button.HiddenSetPoint = button.SetPoint
    button.HiddenOnDragStart = button:GetScript("OnDragStart")
    button.HiddenOnDragStop = button:GetScript("OnDragStop")

    -- Save position
    if (button.HiddenPoint == nil and
        button.HiddenRelativeTo == nil and
        button.HiddenRelativePoint == nil and
        button.HiddenOffsetX == nil and
        button.HiddenOffsetY == nil) then
        button.HiddenPoint,
        button.HiddenRelativeTo,
        button.HiddenRelativePoint,
        button.HiddenOffsetX,
        button.HiddenOffsetY = button:GetPoint()
    end

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
    button:SetScript("OnDragStart", function(button)
        button:SetScript("OnUpdate", function(button)
            local x, y = GetCursorPosition()
            local r = button:GetWidth() / 2
            local scale = button:GetEffectiveScale()
            x, y = (x - r) / scale, (y - r) / scale
            button:HiddenSetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
        end)
    end)
    button:SetScript("OnDragStop", function(button)
        button:SetScript("OnUpdate", nil)
        if OneForAll_IsCursorColliding(OneForAll_MinimapIcon) then
            if (not OneForAll_IsShown) then
                OneForAll_ToggleButtons()
            end
            OneForAll_ExcludeButton(button)
        end
        OneForAll_PositionButtons()
    end)

    -- Hide the button
    if (not OneForAll_IsShown) then
        button:HiddenHide()
    end
end

function OneForAll_ExcludeButton(button)
    -- Get button name
    local button_name = button:GetName()

    -- Store in a table
    tinsert(OneForAll_Excluded, button_name)

    -- Remove from a table
    local button_position = OneForAll_GetButtonIncludedPosition(button_name) 
    if (button_position > 0) then
        tremove(OneForAll_Included, button_position)
    end

    OneForAll_SortButtons()

    -- Restore original functionality
    button.Show = button.HiddenShow
    button.Hide = button.HiddenHide
    button.ClearAllPoints = button.HiddenClearAllPoints
    button.SetPoint = button.HiddenSetPoint
    button:SetScript("OnDragStart", button.HiddenOnDragStart)
    button:SetScript("OnDragStop", button.HiddenOnDragStop)

    -- Restore position
    button:ClearAllPoints()
    if (button.HiddenPoint ~= nil and
        button.HiddenRelativeTo ~= nil and
        button.HiddenRelativePoint ~= nil and
        button.HiddenOffsetX ~= nil and
        button.HiddenOffsetY ~= nil) then
        button:SetPoint(button.HiddenPoint, button.HiddenRelativeTo, button.HiddenRelativePoint, button.HiddenOffsetX, button.HiddenOffsetY)
    else
        local point, relativeTo, relativePoint, offsetX, offsetY = OneForAll_MinimapIcon:GetPoint()
        button:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY)
    end

    -- Clear hidden functionality
    button.HiddenVisibility = nil
    button.HiddenPoint,
    button.HiddenRelativeTo,
    button.HiddenRelativePoint,
    button.HiddenOffsetX,
    button.HiddenOffsetY = nil, nil, nil, nil, nil
    button.HiddenShow = nil
    button.HiddenHide = nil
    button.HiddenClearAllPoints = nil
    button.HiddenSetPoint = nil
    button.HiddenOnDragStart = nil
    button.HiddenOnDragStop = nil

    -- Show the button
    if (not OneForAll_IsShown) then
        button:Show()
    end
end

function OneForAll_SetupDragAndDropButton(button)
    button:HookScript("OnDragStart", function(button)
        button.HiddenPoint,
        button.HiddenRelativeTo,
        button.HiddenRelativePoint,
        button.HiddenOffsetX,
        button.HiddenOffsetY = button:GetPoint()
    end)
    button:HookScript("OnDragStop", function(button)
        if OneForAll_IsCursorColliding(OneForAll_MinimapIcon) then
            if (not OneForAll_IsShown) then
                OneForAll_ToggleButtons()
            end
            OneForAll_IncludeButton(button)
        end
        OneForAll_PositionButtons()
    end)
end

function OneForAll_ToggleButtons()
    OneForAll_IsShown = not OneForAll_IsShown
    for _, button_name in ipairs(OneForAll_Included) do
        local button = _G[button_name]
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
end

function OneForAll_SortButtons()
    table.sort(OneForAll_Included, function(button1_name, button2_name)
        return button1_name:upper() < button2_name:upper()
    end)
end

function OneForAll_PositionButtons()
    local count = 0
    for _, button_name in ipairs(OneForAll_Included) do
        (function()
            local button = _G[button_name]

            if (not button.HiddenVisibility) then return end
        
            count = count + 1
            local xpos = count * OneForAll_MinimapIcon:GetWidth() * -1

            button:HiddenClearAllPoints()
            button:HiddenSetPoint("CENTER", OneForAll_MinimapIcon, "CENTER", xpos, 0)
        end)()
    end
end

function OneForAll_IsCursorColliding(button)
    local x, y = GetCursorPosition()
    local scale = button:GetEffectiveScale()
    x, y = x / scale, y / scale

    return (x >= button:GetLeft() and x <= button:GetRight()
        and y >= button:GetBottom() and y <= button:GetTop())
end

function OneForAll_IsButtonScanned(button1_name)
    for _, button2_name in ipairs(OneForAll_Scanned) do
        if(button1_name == button2_name) then
            return true
        end
    end
    return false
end

function OneForAll_IsButtonIncluded(button1_name)
    for _, button2_name in ipairs(OneForAll_Included) do
        if(button1_name == button2_name) then
            return true
        end
    end
    return false
end

function OneForAll_IsButtonExcluded(button1_name)
    for _, button2_name in ipairs(OneForAll_Excluded) do
        if(button1_name == button2_name) then
            return true
        end
    end
    return false
end

function OneForAll_IsButtonIgnored(button1_name)
    for _, button2_name in ipairs(OneForAll_Ignored) do
        if(button1_name == button2_name) then
            return true
        end
    end
    return false
end

function OneForAll_GetButtonIncludedPosition(button1_name)
    for index, button2_name in ipairs(OneForAll_Included) do
        if(button1_name == button2_name) then
            return index
        end
    end
    return 0
end

function OneForAll_GetButtonExcludedPosition(button1_name)
    for index, button2_name in ipairs(OneForAll_Excluded) do
        if(button1_name == button2_name) then
            return index
        end
    end
    return 0
end

function OneForAll_IsObjectAButton(object)
    return object:IsObjectType("button") and
        object:GetScript("OnDragStart") ~= nil and
        object:GetScript("OnDragStop") ~= nil and
        object:GetScript("OnEnter") ~= nil and
        object:GetScript("OnLeave") ~= nil and
        object:GetScript("OnClick") ~= nil
end

function OneForAll_ScanLibraryButtons()
    local buttons = OneForAll_LibDBIcon:GetButtonList()
    for _, name in ipairs(buttons) do
        local button = OneForAll_LibDBIcon:GetMinimapButton(name)
        local button_name = OneForAll_ButtonPrefix..name
        if(not OneForAll_IsButtonScanned(button_name) and
            not OneForAll_IsButtonIgnored(button_name)) then
            tinsert(OneForAll_Scanned, button_name)
            OneForAll_SetupDragAndDropButton(button)
            if (not OneForAll_IsButtonExcluded(button_name)) then
                OneForAll_IncludeButton(button)
            end
        end
    end
end

function OneForAll_ScanNonLibraryButtons()
    local children = { Minimap:GetChildren() }
    for _, child in ipairs(children) do
        local child_name = child:GetName()
        if(not OneForAll_IsButtonScanned(child_name) and
            not OneForAll_IsButtonIgnored(child_name) and
            OneForAll_IsObjectAButton(child)) then
            tinsert(OneForAll_Scanned, child_name)
            OneForAll_SetupDragAndDropButton(child)
            if (not OneForAll_IsButtonExcluded(child_name)) then
                OneForAll_IncludeButton(child)
            end
        end
    end
end

function OneForAll_ScanButtons()
    OneForAll_ScanLibraryButtons()
    OneForAll_ScanNonLibraryButtons()
end

function OneForAll_LoadDatabase()
    OneForAll_Database = OneForAll_Database or {}
    OneForAll_Excluded = OneForAll_Database["excludedButtons"] or {}
end

function OneForAll_SaveDatabase()
    OneForAll_Database["excludedButtons"] = OneForAll_Excluded
end

function OneForAll_AddMessage(message)
    DEFAULT_CHAT_FRAME:AddMessage(message)
end

function OneForAll_Events:ADDON_LOADED(addonName)
    if (addonName == OneForAll_Name) then
        -- Database loading
        OneForAll_LoadDatabase()
    
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

function OneForAll_Events:PLAYER_LOGOUT()
    OneForAll_SaveDatabase()
end

function OneForAll_Callbacks:LibDBIcon_IconCreated(button, name)
    local button_name = OneForAll_ButtonPrefix..name
    if(not OneForAll_IsButtonScanned(button_name) and
        not OneForAll_IsButtonIgnored(button_name)) then
        tinsert(OneForAll_Scanned, button_name)
        OneForAll_SetupDragAndDropButton(button)
        if (not OneForAll_IsButtonExcluded(button_name)) then
            OneForAll_IncludeButton(button)
        end
    end
end

OneForAll_OnLoad()