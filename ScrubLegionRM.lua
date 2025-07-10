ScrubLegionRM = LibStub("AceAddon-3.0"):NewAddon("ScrubLegionRM", "AceConsole-3.0", "AceEvent-3.0")

local defaults = {
    profile = {
        imported = nil,
        rosterString = nil,
        windowPos = {
            x = nil,
            y = nil,
        }
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
    self:RegisterChatCommand("slrmhelp", "slrmhelp")
    print("ScrubLegionRM initialized. Type /slrm to open the main window.")
end

function ScrubLegionRM:RestorePosition()
    if self.db.profile.windowPos.x and self.db.profile.windowPos.y then
        -- Restore the position of the main window
        self.mainFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", self.db.profile.windowPos.x, self.db.profile.windowPos.y)
    else
        -- Default position if no previous position is saved
        self.mainFrame:SetPoint("CENTER", UIParent, "CENTER")
    end
end

function ScrubLegionRM:RestoreChild(editBox)
    if self.db.profile.rosterString then
        -- Restore the text in the edit box
        editBox:SetText(self.db.profile.rosterString)
    else
        -- Default text if no previous roster string is saved
        editBox:SetText("")
    end
end

function ScrubLegionRM:ShowMainWindow()
    print("ShowMainWindow called - Starting window creation")
    
    if self.mainFrame then
        print("Existing mainFrame found - Releasing...")
        AceGUI:Release(self.mainFrame)
        self.mainFrame = nil
        print("MainFrame released")
    end

    -- Create new window using AceGUI
    print("Creating new AceGUI Frame")
    self.mainFrame = AceGUI:Create("Frame")
    if not self.mainFrame then
        print("ERROR: Failed to create mainFrame!")
        return
    end
    
    -- Set frame properties
    self.mainFrame:SetTitle("ScrubLegion Roster Manager")
    self.mainFrame:SetLayout("Flow")
    self.mainFrame:SetWidth(400)
    self.mainFrame:SetHeight(400)

    ScrubLegionRM:RestorePosition()

    -- Set OnClose callback to save position
    self.mainFrame:SetCallback("OnClose", function(widget)
        print("OnClose callback triggered")
        -- Get position relative to UIParent TOPLEFT
        local frame = widget.frame
        local scale = frame:GetScale()
        local x, y = frame:GetLeft(), frame:GetTop()
        x = x * scale
        y = y * scale
        -- Save position
        self.db.profile.windowPos.x = x
        self.db.profile.windowPos.y = y
        print(string.format("Saving position: x=%s, y=%s", tostring(x), tostring(y)))
        AceGUI:Release(widget)
        self.mainFrame = nil
    end)

    self.mainFrame:SetTitle("SLRM")
    self.mainFrame:SetStatusText("ScrubLegionRM")
    self.mainFrame:SetLayout("Flow")
    self.mainFrame:SetWidth(400)
    self.mainFrame:SetHeight(400)


    local editBox = AceGUI:Create("MultiLineEditBox")
    editBox:SetLabel("Roster String")
    editBox:SetFullWidth(true)
    editBox:SetHeight(300)

    self.mainFrame:AddChild(editBox)
    
    ScrubLegionRM:RestoreChild(editBox)

    editBox:SetCallback("OnEnterPressed", function(_, _, text)
        -- Handle text input
        if text and text ~= "" then
            if RosterParse(text, self.db.profile) then
                print("Roster data imported successfully.")
            else
                print("Failed to import roster data.")
            end
        else
            print("No roster data provided.")
        end
    end)

end

function ScrubLegionRM:OnEnable()
    -- Called when the addon is enabled
    if ShouldEnableAddon() then
        print("ScrubLegionRM is enabled for this raid instance.")
        self:ShowMainWindow()
    else
        print("ScrubLegionRM is not enabled for this raid instance.")
    end
end

function ScrubLegionRM:OnDisable()
    -- Called when the addon is disabled
    print("ScrubLegionRM is disabled.")
end

function ScrubLegionRM:slrm()
    print("slrm command executed.")
    self:ShowMainWindow()
end

function ScrubLegionRM:slrmdb()
    print("ScrubLegionRM database command executed.")
    -- Add your command handling logic here
    if self.db then
        DeepPrint(self.db.profile)
    else
        print("No imported roster data found.")
    end
end

function ScrubLegionRM:slrmclear()
    print("ScrubLegionRM clear command executed.")
    -- Add your command handling logic here
    if self.db then
        self.db.profile.imported = nil
        self.db.profile.rosterString = nil
        self.db.profile.windowPos.x = nil
        self.db.profile.windowPos.y = nil
        print("ScrubLegionRM database cleared.")
    else
        print("No database to clear.")
    end
end

function ScrubLegionRM:slrmtest()
    print("ScrubLegionRM test command executed.")
    -- Add your command handling logic here
end

function ScrubLegionRM:slrmhelp()
    print("ScrubLegionRM help command executed.")
    print("Available commands:")
    print("/slrm - Show the main window")
    print("/slrmdb - Show the current database contents")
    print("/slrmclear - Clear the current database")
    print("/slrmtest - Run a test command")
end