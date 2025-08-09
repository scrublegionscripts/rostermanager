ScrubLegionRM = LibStub("AceAddon-3.0"):NewAddon("ScrubLegionRM", "AceConsole-3.0", "AceEvent-3.0")

local defaults = {
    profile = {
        windowPos = {
            point = nil,
            relativeTo = nil,
            relativePoint = nil,
            xOffset = nil,
            yOffset = nil,
            width = nil or 500,
            height = nil or 500
        },
        lastDetectedBoss = nil,
        lastDetectedEncounter = nil,
        selectedEncounterID = nil,
        wasOverlayDismissed = false,
        customNotes = {},
        defaultNotes = "Reminder: \nCheck Talents, import MDT groups, remind people of unique assignments."
    }
}

local AceGUI = LibStub("AceGUI-3.0")

function ScrubLegionRM:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("ScrubLegionRMDB", defaults, true)
    -- Called when the addon is loaded
    self:RegisterChatCommand("slrm", "slrm")
    self:RegisterChatCommand("slrmclear", "slrmclear")
    self:RegisterChatCommand("slrmtest", "slrmtest")
    print("ScrubLegionRM initialized. Type /slrm to open the main window.")

    self.db.profile.lastDetectedInstanceID = LIBERATION_OF_UNDERMINE_ID
end

function ScrubLegionRM:ApplyWindowSettings(window)
    -- Safety check
    if not window then
        print("Warning: window is nil in ApplyWindowPosition")
        return
    end

    -- Check if we have valid position data
    if Utils:AllTableElementsAreNonNil(self.db.profile.windowPos) then
        -- Get the frame referenced by name - with better error handling
        local relToName = self.db.profile.windowPos.relativeTo
        local relativeTo

        if relToName and type(relToName) == "string" then
            relativeTo = _G[relToName]
        end

        if not relativeTo then
            relativeTo = UIParent
            print("Could not find relativeTo frame: " .. (relToName or "nil") .. ", using UIParent instead")
        end

        -- Apply the position with safety checks
        window:ClearAllPoints()
        window:SetPoint(
            self.db.profile.windowPos.point or "CENTER",
            relativeTo,
            self.db.profile.windowPos.relativePoint or "CENTER",
            self.db.profile.windowPos.xOffset or 0,
            self.db.profile.windowPos.yOffset or 0
        )
    else
        window:ClearAllPoints()
        window:SetPoint("CENTER", UIParent, "CENTER")
        print("No valid window position data, centered window")
    end
end

function ScrubLegionRM:SetCallBacks(window, name)
    -- Store a reference to self for use in the callback
    local addon = self

    -- IMPORTANT: Check if this is actually an AceGUI widget
    if not window or not window.frame then
        print("Error: Invalid window passed to SetCallBacks")
        return
    end

    -- Add a global hook for window movement
    local frame = window.frame
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)

    -- Store the current window position to a global variable when drag stops
    frame:HookScript("OnDragStop", function()
        local left = frame:GetLeft()
        local bottom = frame:GetBottom()

        if left and bottom then
            addon.db.profile.windowPos = {
                point = "BOTTOMLEFT",
                relativeTo = "UIParent",
                relativePoint = "BOTTOMLEFT",
                xOffset = left,
                yOffset = bottom,
                width = frame:GetWidth(),
                height = frame:GetHeight()
            }
        end
    end)

    -- Ensure the title bar properly handles dragging
    local titleframe = frame:GetChildren()
    if titleframe then
        -- First, clear any existing scripts
        titleframe:SetScript("OnMouseDown", nil)
        titleframe:SetScript("OnMouseUp", nil)

        -- Now set our custom scripts
        titleframe:SetScript("OnMouseDown", function()
            frame:StartMoving()
        end)

        titleframe:SetScript("OnMouseUp", function()
            frame:StopMovingOrSizing()

            -- Get absolute position
            local left = frame:GetLeft()
            local bottom = frame:GetBottom()

            if left and bottom then
                addon.db.profile.windowPos = {
                    point = "BOTTOMLEFT",
                    relativeTo = "UIParent",
                    relativePoint = "BOTTOMLEFT",
                    xOffset = left,
                    yOffset = bottom
                }
            else
                print("Warning: Could not get valid position after drag")
            end
        end)
    end

    -- Add OnClose callback
    window:SetCallback("OnClose", function()
        -- Get final position before closing
        local left = frame:GetLeft()
        local bottom = frame:GetBottom()

        if left and bottom then
            addon.db.profile.windowPos = {
                point = "BOTTOMLEFT",
                relativeTo = "UIParent",
                relativePoint = "BOTTOMLEFT",
                xOffset = left,
                yOffset = bottom,
                width = frame:GetWidth(),
                height = frame:GetHeight()
            }
        end
    end)
end

function ScrubLegionRM:OnEnable()
    -- Called when the addon is enabled
    if Utils:ShouldEnableAddon() then
        print("ScrubLegionRM is enabled for this raid instance.")

        self.db.profile.lastDetectedInstanceID = GetInstanceInfo()[8]
        print("Last detected instance ID:", self.db.profile.lastDetectedInstanceID)

        self:RegisterEvent("NAME_PLATE_UNIT_ADDED", function()
            local isBossDetected, npcID, encounterID = Utils:IsBossDetected()
            if isBossDetected then
                if encounterID ~= self.db.profile.lastDetectedEncounter then
                    if not UnitAffectingCombat("player") then
                        print("Boss detected! NPC ID:", npcID, "Encounter ID:", encounterID)
                        ScrubLegionRM:ShowMainWindow(encounterID)
                        self.db.profile.lastDetectedBoss = npcID
                        self.db.profile.lastDetectedEncounter = encounterID
                    else
                        print("Boss detected! NPC ID:", npcID, "Encounter ID:", encounterID)
                        print("We are in combat, delaying window opening.")
                        -- We are in combat, and need to delay the window opening
                        self:RegisterEvent("PLAYER_REGEN_ENABLED", function()
                            self:UnregisterEvent("PLAYER_REGEN_ENABLED")
                            ScrubLegionRM:ShowMainWindow(encounterID)
                            self.db.profile.lastDetectedBoss = npcID
                            self.db.profile.lastDetectedEncounter = encounterID
                        end)
                    end
                end
            end
        end)
    end
end

function ScrubLegionRM:OnDisable()
    -- Called when the addon is disabled
    print("ScrubLegionRM is disabled.")
end

function ScrubLegionRM:ShowMainWindow(encounterID)
    local window = AceGUI:Create("Frame")
    window:SetTitle("Scrub Legion RM")
    window:SetStatusText("Encounter ID: " .. (encounterID or "Unknown"))
    window:SetWidth(self.db.profile.windowPos.width or 500)
    window:SetHeight(self.db.profile.windowPos.height or 500)
    window:SetLayout("Fill")

    self:ApplyWindowSettings(window)
    self:SetCallBacks(window, "ScrubLegionRMMainWindow")

    local innerGroup = AceGUI:Create("SimpleGroup")
    innerGroup:SetLayout("Flow")

    local editBox = AceGUI:Create("MultiLineEditBox")
    editBox:SetFullWidth(true)
    editBox:SetFullHeight(self.db.profile.windowPos.height - 250)
    editBox:SetCallback("OnEnterPressed", function(_, _, text)
        self.db.profile.customNotes[self.db.profile.selectedEncounterID] = text
    end)

    local bossTabs = AceGUI:Create("TabGroup")
    bossTabs:SetTitle(InstanceToName[self.db.profile.lastDetectedInstanceID] or "Unknown Instance")
    bossTabs:SetFullWidth(true)
    local validTabs = self:BuildBossTabs(window, bossTabs, editBox, self.db.profile.lastDetectedInstanceID, encounterID)

    if validTabs then
        innerGroup:AddChild(bossTabs)
    end

    innerGroup:AddChild(editBox)

    window:AddChild(innerGroup)
    -- Show the window
    window:Show()
end

function ScrubLegionRM:UpdateEditBoxForEncounter(window, editBox, encounterID)
    if not editBox or not editBox.SetText then
        print("Error: Invalid edit box provided")
        return
    end

    local notes = self.db.profile.defaultNotes
    if self.db.profile.customNotes[encounterID] then
        notes = self.db.profile.customNotes[encounterID]
    end

    editBox:SetLabel("Notes for " .. (EncounterToName[encounterID] or "Unknown Encounter"))
    editBox:SetText(notes)

    window:SetStatusText("Encounter ID: " .. (encounterID or "Unknown"))
end

function ScrubLegionRM:BuildBossTabs(window, bossTabsObject, editBox, instanceID, encounterID)
    local bossList = InstanceToBosses[instanceID] or {}
    if not bossList or bossList == {} then
        return false
    end

    local allTabs = {}
    for _, bossID in pairs(bossList) do
        local bossName = EncounterToName[bossID] or "Unknown Boss"
        table.insert(allTabs, {
            value = bossID,
            text = bossName
        })
    end

    bossTabsObject:SetTabs(allTabs)
    bossTabsObject:SetCallback("OnGroupSelected", function(_, _, bossID)
        self.db.profile.selectedEncounterID = bossID
        self:UpdateEditBoxForEncounter(window, editBox, bossID)
    end)

    bossTabsObject:SelectTab(encounterID)
    self.db.profile.selectedEncounterID = encounterID

    return true
end

function ScrubLegionRM:slrm()
    self:ShowMainWindow(self.db.profile.lastDetectedBoss, self.db.profile.lastDetectedEncounter)
    return true
end

function ScrubLegionRM:slrmclear()
    self.db.profile.customNotes = {}
    print("Custom notes cleared.")
end


function ScrubLegionRM:slrmtest(input)
    local instanceID, encounterID = strsplit(" ", input)
    
    -- Convert string arguments to numbers
    local instID = tonumber(instanceID)
    local encID = tonumber(encounterID)
    
    self.db.profile.lastDetectedInstanceID = (instID or self.db.profile.lastDetectedInstanceID)
    self:ShowMainWindow((encID or self.db.profile.lastDetectedEncounter))
    return true
end