ScrubLegionRM = LibStub("AceAddon-3.0"):NewAddon("ScrubLegionRM", "AceConsole-3.0", "AceEvent-3.0")

local defaults = {
    profile = {
        imported = nil,
        rosterString = nil,
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
        wasOverlayDismissed = false
    }
}

local AceGUI = LibStub("AceGUI-3.0")

function ScrubLegionRM:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("ScrubLegionRMDB", defaults, true)
    -- Called when the addon is loaded
    self:RegisterChatCommand("slrm", "slrm")
    self:RegisterChatCommand("slrmdb", "slrmdb")
    self:RegisterChatCommand("slrmclear", "slrmclear")
    self:RegisterChatCommand("slrmtest", "slrmtest")
    self:RegisterChatCommand("roster", "showRoster")
    self:RegisterChatCommand("slrmhelp", "slrmhelp")
    print("ScrubLegionRM initialized. Type /slrm to open the main window.")
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

function ScrubLegionRM:ProcessRosterString(statusLabel, text)
    if not text or text == "" then
        statusLabel:SetText("|cFFFF0000Error: No roster string provided|r")
        print("Error: No roster string provided")
        return
    end

    -- Save the roster string to the database
    self.db.profile.rosterString = text

    -- Attempt to parse the roster string
    local success = RosterParse(text, self.db.profile)

    if success then
        statusLabel:SetText("|cFF00FF00Roster imported successfully!|r")
    else
        -- Don't try to set text on the edit box, use statusLabel instead
        statusLabel:SetText("|cFFFF0000Failed to parse roster data. Check your input.|r")
        print("Failed to parse roster data.")
    end
end

function ScrubLegionRM:RestoreData(editBox)
    if self.db.profile.imported and self.db.profile.rosterString then
        -- print("Restoring roster string...")
        -- Restore the roster string here
        editBox:SetText(self.db.profile.rosterString)
    else
        -- print("No roster string found.")
        editBox:SetText("")
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
    window:SetCallback("OnClose", function(widget, name)
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

        if name and name == "RosterDisplayWindow" then
            print("Closing window: " .. name)
            addon.db.profile.wasOverlayDismissed = true
            OverlayManager:HideAllOverlays()
        end

    end)
end

function ScrubLegionRM:ShowMainWindow()
    -- Check if the main window already exists
    if self.mainWindow then
        self.mainWindow = Utils:SafeReleaseWidget(self.mainWindow)
    end

    -- Create the main window if it doesn't exist
    self.mainWindow = AceGUI:Create("Frame")
    self.mainWindow:SetTitle("Scrub Legion Roster Manager")
    self.mainWindow:SetStatusText("Roster Management Tool")

    -- Critical: Use Fill layout for the main window for proper resizing
    self.mainWindow:SetLayout("Fill")

    -- Set initial size based on saved values or defaults
    local width = self.db.profile.windowPos.width or 600
    local height = self.db.profile.windowPos.height or 500
    self.mainWindow:SetWidth(width)
    self.mainWindow:SetHeight(height)

    -- Make sure the frame is resizable
    self.mainWindow.frame:SetResizable(true)

    -- Set minimum size constraints
    if self.mainWindow.frame.SetMinResize then
        self.mainWindow.frame:SetMinResize(400, 300)
    end

    -- Configure callbacks and window position
    self:SetCallBacks(self.mainWindow)
    self:ApplyWindowSettings(self.mainWindow)

    -- Main content container - use Fill layout with 100% height/width
    local mainContainer = AceGUI:Create("SimpleGroup")
    mainContainer:SetLayout("Flow")
    mainContainer:SetFullWidth(true)
    mainContainer:SetFullHeight(true)
    self.mainWindow:AddChild(mainContainer)

    -- Edit box container - takes most of the space
    local editBoxContainer = AceGUI:Create("SimpleGroup")
    editBoxContainer:SetLayout("Fill")
    editBoxContainer:SetFullWidth(true)
    -- Use SetHeight with percentage of the total height instead of SetRelativeHeight
    local editBoxHeight = height * 0.5 -- 85% of window height
    editBoxContainer:SetHeight(editBoxHeight)
    mainContainer:AddChild(editBoxContainer)

    -- Create the actual edit box
    local editBox = AceGUI:Create("MultiLineEditBox")
    if not editBox then
        print("ERROR: Failed to create EditBox!")
        return
    end

    editBox:SetLabel("Paste Roster String:")
    editBox:SetFullWidth(true)
    editBox:SetFullHeight(true)
    editBox:SetMaxLetters(0)
    self:RestoreData(editBox)
    editBoxContainer:AddChild(editBox)

    -- Footer container - takes remaining space at bottom
    local footerContainer = AceGUI:Create("SimpleGroup")
    footerContainer:SetLayout("Flow")
    footerContainer:SetFullWidth(true)
    -- Use fixed height instead of relative height
    footerContainer:SetHeight(height * 0.25) -- 25% of window height
    mainContainer:AddChild(footerContainer)

    -- Create a status label that fills most of the footer width
    local statusLabel = AceGUI:Create("Label")
    statusLabel:SetText("Ready to import roster data")
    -- Use fixed width instead of relative width
    statusLabel:SetWidth(width * 0.75) -- 75% of window width
    statusLabel:SetFontObject(GameFontNormal)
    footerContainer:AddChild(statusLabel)

    -- Create the re-import button that takes remaining footer width
    local reImportButton = AceGUI:Create("Button")
    reImportButton:SetText("Re-Import Roster")
    -- Use fixed width instead of relative width
    reImportButton:SetWidth(width * 0.25) -- 25% of window width
    footerContainer:AddChild(reImportButton)

    -- Set up the callbacks
    editBox:SetCallback("OnEnterPressed", function()
        self:ProcessRosterString(statusLabel, editBox:GetText())
    end)

    reImportButton:SetCallback("OnClick", function()
        self:ProcessRosterString(statusLabel, editBox:GetText())
    end)

    -- Track size changes to update the layout
    self.mainWindow.frame:HookScript("OnSizeChanged", function(_, newWidth, newHeight)
        -- Recalculate sizes based on new dimensions
        editBoxContainer:SetHeight(newHeight * 0.5)
        footerContainer:SetHeight(newHeight * 0.25)
        statusLabel:SetWidth(newWidth * 0.75)
        reImportButton:SetWidth(newWidth * 0.25)
    end)

    self.mainWindow:Show()
    _G["ScrubLegionRMMainWindow"] = self.mainWindow.frame
    tinsert(UISpecialFrames, "ScrubLegionRMMainWindow")
end

function ScrubLegionRM:ShowRosterDisplay(npcID, encounterID)
    if self.rosterWindow then
        self.rosterWindow = Utils:SafeReleaseWidget(self.rosterWindow)
    end

    self.rosterWindow = AceGUI:Create("Frame")
    self.rosterWindow:SetTitle("Roster for " .. (encounterID and encounterID or "Unknown"))
    self.rosterWindow:SetStatusText("Roster Display for Boss: " .. (npcID or "Unknown"))
    self.rosterWindow:SetLayout("Fill")
    self:SetCallBacks(self.rosterWindow)
    self:ApplyWindowSettings(self.rosterWindow)

    local rosterScroll = AceGUI:Create("ScrollFrame")
    rosterScroll:SetLayout("Flow")
    rosterScroll:SetFullWidth(true)
    rosterScroll:SetFullHeight(true)

    local rosterText = AceGUI:Create("Label")
    rosterText:SetFontObject(GameFontNormal)
    rosterText:SetFullWidth(true)
    rosterText:SetText(OverlayManager:CreateRosterDisplay(encounterID, self.db.profile.imported))

    rosterScroll:AddChild(rosterText)

    self.rosterWindow:AddChild(rosterScroll)

    self.rosterWindow:Show()
end

function ScrubLegionRM:OnEnable()
    -- Called when the addon is enabled
    if Utils:ShouldEnableAddon() then
        print("ScrubLegionRM is enabled for this raid instance.")
        self:ShowMainWindow()

        self:RegisterEvent("NAME_PLATE_UNIT_ADDED", function()
            local isBossDetected, npcID, encounterID = Utils:IsBossDetected()
            if isBossDetected and not self.db.profile.wasOverlayDismissed then
                if npcID ~= self.db.profile.lastDetectedBoss then
                    print("Boss detected! NPC ID:", npcID, "Encounter ID:", encounterID)
                    ScrubLegionRM:ShowRosterDisplay(npcID, encounterID)
                    self.db.profile.lastDetectedBoss = npcID
                    self.db.profile.lastDetectedEncounter = encounterID
                end
            end
        end)
    end
end

function ScrubLegionRM:OnDisable()
    -- Called when the addon is disabled
    print("ScrubLegionRM is disabled.")
end

function ScrubLegionRM:slrm()
    self:ShowMainWindow()
    return true
end

function ScrubLegionRM:slrmdb()
    print("ScrubLegionRM database command executed.")
    -- Add your command handling logic here
    if self.db then
        Utils:DeepPrint(self.db.profile)
    else
        print("No imported roster data found.")
    end
    return true
end

function ScrubLegionRM:slrmclear()
    print("ScrubLegionRM clear command executed.")
    -- Add your command handling logic here
    if self.db then
        self.db.profile.imported = nil
        self.db.profile.rosterString = nil
        self.db.profile.windowPos.x = nil
        self.db.profile.windowPos.y = nil
        self.db.profile.windowPos.width = nil
        self.db.profile.windowPos.height = nil
        self.db.profile.lastDetectedBoss = nil
        self.db.profile.wasOverlayDismissed = false
        print("ScrubLegionRM database cleared.")
    else
        print("No database to clear.")
    end
    return true
end

function ScrubLegionRM:slrmtest()
    print("ScrubLegionRM test command executed.")
    -- Add your command handling logic here
    return true
end

function ScrubLegionRM:showRoster()
    self.db.profile.wasOverlayDismissed = false
    self:ShowRosterDisplay(self.db.profile.lastDetectedBoss, self.db.profile.lastDetectedEncounter)
end

function ScrubLegionRM:slrmhelp()
    print("ScrubLegionRM help command executed.")
    print("Available commands:")
    print("/slrm - Show the main window")
    print("/slrmdb - Show the current database contents")
    print("/slrmclear - Clear the current database")
    print("/slrmtest - Run a test command")
    return true
end
