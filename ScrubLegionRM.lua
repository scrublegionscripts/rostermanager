local mainFrame = CreateFrame("Frame", "ScrubLegionRosterImport", UIParent, "BasicFrameTemplateWithInset")
mainFrame:SetSize(400, 400)
mainFrame:SetPoint("TOPLEFT", UIParent, "CENTER", 0, 0)
mainFrame.TitleBg:SetHeight(30)
mainFrame.title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
mainFrame.title:SetPoint("TOPLEFT", mainFrame.TitleBg, "TOPLEFT", 5, -3)
mainFrame.title:SetText("SLRM")
mainFrame:Hide()

mainFrame:EnableMouse(true)
mainFrame:SetMovable(true)
mainFrame:RegisterForDrag("LeftButton")

mainFrame:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

mainFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)

mainFrame:SetScript("OnShow", function()
    PlaySound(808)
    if RosterInputBox and ScrubLegionRMDB and ScrubLegionRMDB.rosterString then
        RosterInputBox:SetText(ScrubLegionRMDB.rosterString)
    elseif RosterInputBox then
        RosterInputBox:SetText("Paste Roster String here...")
    end
end)

mainFrame:SetScript("OnHide", function()
    PlaySound(808)
end)

-- Create text display frame
local rosterDisplay = CreateFrame("Frame", "SLRMRosterDisplay", UIParent)
rosterDisplay:SetSize(300, 400)
rosterDisplay:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -200)
rosterDisplay:SetMovable(true)
rosterDisplay:EnableMouse(true)
rosterDisplay:RegisterForDrag("LeftButton")
rosterDisplay:SetScript("OnDragStart", rosterDisplay.StartMoving)
rosterDisplay:SetScript("OnDragStop", rosterDisplay.StopMovingOrSizing)

-- Add background
rosterDisplay.bg = rosterDisplay:CreateTexture(nil, "BACKGROUND")
rosterDisplay.bg:SetAllPoints()
rosterDisplay.bg:SetColorTexture(0, 0, 0, 0.7)

-- Create scroll frame
rosterDisplay.scrollFrame = CreateFrame("ScrollFrame", nil, rosterDisplay, "UIPanelScrollFrameTemplate")
rosterDisplay.scrollFrame:SetPoint("TOPLEFT", 10, -30)
rosterDisplay.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

-- Create scrollable content frame
rosterDisplay.scrollChild = CreateFrame("Frame")
rosterDisplay.scrollFrame:SetScrollChild(rosterDisplay.scrollChild)
rosterDisplay.scrollChild:SetSize(270, 400) -- Initial size

-- Update text settings in the roster display creation
rosterDisplay.text = rosterDisplay.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
rosterDisplay.text:SetPoint("TOPLEFT")
rosterDisplay.text:SetPoint("TOPRIGHT", -10, 0)  -- Add right padding
rosterDisplay.text:SetJustifyH("LEFT")
rosterDisplay.text:SetJustifyV("TOP")
rosterDisplay.text:SetWordWrap(true)
rosterDisplay.text:SetSpacing(2)  -- Add some line spacing

-- Create a function to update scroll child height based on text
function rosterDisplay:UpdateScrollChildHeight()
    local textWidth = self.text:GetWidth()
    self.text:SetWidth(textWidth)                              -- Force text wrap calculation
    local textHeight = self.text:GetHeight()
    self.scrollChild:SetHeight(math.max(textHeight + 20, 400)) -- Add padding, minimum height of 400
end

-- Add a dismiss button to the roster display
rosterDisplay.dismissButton = CreateFrame("Button", nil, rosterDisplay, "UIPanelButtonTemplate")
rosterDisplay.dismissButton:SetSize(150, 24)
rosterDisplay.dismissButton:SetPoint("BOTTOM", rosterDisplay, "BOTTOM", 0, 10)
rosterDisplay.dismissButton:SetText("Dismiss Overlay/Roster")
rosterDisplay.dismissButton:SetScript("OnClick", function()
    DismissOverlay()
end)

table.insert(UISpecialFrames, "ScrubLegionRosterImport")

SLASH_SLRM1 = "/slrm"
SlashCmdList["SLRM"] = function()
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        mainFrame:Show()
    end
end

SLASH_SLRMDB1 = "/slrmdb"
SlashCmdList["SLRMDB"] = function()
    print("Current ScrubLegionRMDB contents:")
    for k, v in pairs(ScrubLegionRMDB) do
        print(k .. ": " .. tostring(v))
    end
end

SLASH_SLRMCLEAR1 = "/slrmclear"
SlashCmdList["SLRMCLEAR"] = function()
    ScrubLegionRMDB = {}
    print("ScrubLegionRMDB cleared.")
end

SLASH_SLRMROSTER1 = "/slrmroster"
SlashCmdList["SLRMROSTER"] = function()
    if rosterDisplay:IsShown() then
        rosterDisplay:Hide()
    else
        rosterDisplay:Show()
    end
end

SLASH_SLRMHELP1 = "/slrmhelp"
SlashCmdList["SLRMHELP"] = function()
    print("ScrubLegionRM Commands:")
    print("  /slrm - Toggle roster import window")
    print("  /slrmdb - Shows current ScrubLegionRMDB contents")
    print("  /slrmclear - Clear imported roster data")
    print("  /slrmroster - Toggle roster display window")
    print("  /slrmhelp - Show this help message")
end

-- Track last sent encounter to avoid spamming
local lastSentEncounterID = nil
local lastEncounteredBossID = nil
local overlayDismissed = false

local function GetEncounterByID(rosterTable, encounterID)
    if not rosterTable or not rosterTable.encounters then return nil end

    for _, encounter in ipairs(rosterTable.encounters) do
        if encounter.id == encounterID then
            return {
                id = encounter.id,
                name = encounter.name,
                selections = encounter.selections or {},
                unselected = encounter.unselected or {}
            }
        end
    end
    return nil
end

-- Helper to send both roster and encounterID to WeakAura
local function SendRosterAndEncounter(rosterTable, encounterID)
    -- Check if we should enable the addon first
    if not ShouldEnableAddon() or overlayDismissed then
        if rosterDisplay and rosterDisplay:IsShown() then
            rosterDisplay:Hide()
        end
        return
    end

    local encounter = GetEncounterByID(rosterTable, encounterID)
    if encounter then
        -- Build display text
        local lines = {}
        
        -- Add encounter name with larger font and centered
        table.insert(lines, string.format("|cff00ff00%s|r|r", encounter.name or "Unknown"))
        
        -- Handle selected players
        local selectedCount = #(encounter.selections or {})
        table.insert(lines, string.format("\nSelected (%d):", selectedCount))
        
        if encounter.selections then
            local playerList = {}
            for _, sel in ipairs(encounter.selections) do
                -- Clean up class name and ensure it exists
                local classUpper = sel.class:upper()
                -- Create colored name with explicit color close
                local coloredName = (CLASS_COLORS[classUpper] or "|cFFFFFFFF") .. 
                                  (sel.fullName or "Unknown") .. "|r"
                local baseName, _ = string.split("-", coloredName, 2)
                
                table.insert(playerList, baseName .. "|r")
            end
            
            -- Join all players with commas and let text wrapping handle the display
            table.insert(lines, table.concat(playerList, ", "))
        end
        
        rosterDisplay.text:SetText(table.concat(lines, "\n"))
        rosterDisplay:UpdateScrollChildHeight()
        rosterDisplay:Show()
    end

    -- Update raid frame overlays if available
    if ScrubLegionRMRaidFrameOverlay and encounter then
        local selectedLookup = ScrubLegionRMRaidFrameOverlay:BuildSelectedLookup(encounter)
        ScrubLegionRMRaidFrameOverlay:UpdateAll(selectedLookup)
    end
end

local function ScanForNearbyBosses()
    if not ShouldEnableAddon() then
        -- print("DEBUG: Not in correct zone")
        return false
    end

    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) then
            local guid = UnitGUID(unit)

            if guid then
                local _, _, _, _, _, npcID = string.split("-", guid)
                local npcIDNumber = tonumber(npcID)

                if npcIDNumber and BossToEncounter[npcIDNumber] then
                    local encounterID = BossToEncounter[npcIDNumber]
                    -- print("DEBUG: Found boss!", name, "->", encounterID)

                    -- Only update if it's a new encounter
                    if encounterID ~= lastEncounteredBossID then
                        -- print("DEBUG: New boss encounter detected")
                        lastEncounteredBossID = encounterID
                        lastSentEncounterID = encounterID
                        overlayDismissed = false

                        if ScrubLegionRMDB and ScrubLegionRMDB.imported then
                            ScrubLegionRMDB.currentEncounterID = encounterID
                            local encounter = GetEncounterByID(ScrubLegionRMDB.imported, encounterID)
                            if encounter then
                                -- print("DEBUG: Sending roster for encounter:", encounter.name)
                                SendRosterAndEncounter(ScrubLegionRMDB.imported, encounterID)
                                return true
                            end
                        end
                    else
                        -- print("DEBUG: Already tracking this boss encounter")
                    end
                end
            end
        end
    end
    return false
end

-- Boss detection logic
local function OnEncounterStart(self, encounterID)
    -- Reset states for new encounter
    lastSentEncounterID = encounterID

    if ScrubLegionRMDB and ScrubLegionRMDB.imported then
        ScrubLegionRMDB.currentEncounterID = encounterID
        SendRosterAndEncounter(ScrubLegionRMDB.imported, encounterID)
    end
end

local function OnAddonLoaded(self, addonName)
    if addonName == "ScrubLegionRM" and RosterInputBox then
        if ScrubLegionRMDB.imported then
            ProcessImportedRoster(ScrubLegionRMDB.imported)
        end

        if not ShouldEnableAddon() then
            if rosterDisplay and rosterDisplay:IsShown() then
                rosterDisplay:Hide()
            end
        end
    end
end

mainFrame:RegisterEvent("ADDON_LOADED")
mainFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
mainFrame:RegisterEvent("ENCOUNTER_START")
mainFrame:RegisterEvent("ENCOUNTER_END")

mainFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        OnAddonLoaded(self, ...)
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        ScanForNearbyBosses()
    elseif event == "ENCOUNTER_START" then
        OnEncounterStart(self, ...)
    end
end)

RosterInputBox = CreateRosterInput(mainFrame)

local dismissButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
dismissButton:SetSize(150, 24)
dismissButton:SetPoint("BOTTOM", mainFrame, "BOTTOM", 0, 10)
dismissButton:SetText("Dismiss Overlay/Roster")
dismissButton:SetScript("OnClick", function()
    DismissOverlay()
end)



print("SLRM successfully loaded!")

function ProcessImportedRoster(rosterTable)
    if type(rosterTable) ~= "table" then
        print("No valid roster data to process.")
        return
    end

    -- Build a lookup table for character_id -> "Name-Realm"
    local idToNameRealm = {}
    if rosterTable.signups then
        for _, signup in ipairs(rosterTable.signups) do
            if signup.character and signup.character.id and signup.character.name and signup.character.realm then
                idToNameRealm[signup.character.id] = signup.character.name .. "-" .. signup.character.realm
            end
        end
    end

    -- For each encounter, split selections into selected and unselected, and add fullName
    if rosterTable.encounters then
        for _, encounter in ipairs(rosterTable.encounters) do
            local selected = {}
            local unselected = {}
            if encounter.selections then
                for _, selection in ipairs(encounter.selections) do
                    if selection.character_id then
                        local fullName = idToNameRealm[selection.character_id] or
                            ("Unknown(" .. tostring(selection.character_id) .. ")")
                        local name, realm = fullName:match("^(.-)%-(.+)$")
                        if name and realm then
                            fullName = ScrubLegionRMRaidFrameOverlay:NormalizeFullName(name, realm)
                        end
                        local entry = {
                            character_id = selection.character_id,
                            fullName = fullName,
                            class = selection.class,
                            role = selection.role,
                            selected = selection.selected
                        }
                        if selection.selected then
                            table.insert(selected, entry)
                        else
                            table.insert(unselected, entry)
                        end
                    end
                end
            end
            encounter.selections = selected
            encounter.unselected = unselected
        end
    else
        print("No encounters found in roster data.")
    end
    -- No longer auto-sending to WeakAura here; only send on boss detection/encounter start
    for _, encounter in ipairs(rosterTable.encounters or {}) do
        print("Roster encounter:", encounter.id, encounter.name)
    end
end

local function EnableAddonFeatures()
    -- Place your main addon initialization code here
    mainFrame:Show()
    print("SLRM enabled in this instance!")
end

local function DisableAddonFeatures()
    mainFrame:Hide()
    -- print("SLRM disabled in this zone.")
end

local function CheckZoneAndToggleAddon()
    if ShouldEnableAddon() then
        EnableAddonFeatures()
    else
        DisableAddonFeatures()
    end
end

local zoneFrame = CreateFrame("Frame")
zoneFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
zoneFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
zoneFrame:SetScript("OnEvent", function(self, event)
    CheckZoneAndToggleAddon()
end)

-- Modify the event handler for GROUP_ROSTER_UPDATE
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:SetScript("OnEvent", function()
    C_Timer.After(0.1, function()
        if ScrubLegionRMRaidFrameOverlay and lastSentEncounterID ~= nil and not overlayDismissed then
            local encounter = GetEncounterByID(ScrubLegionRMDB.imported, lastSentEncounterID)
            if encounter then
                local selected = ScrubLegionRMRaidFrameOverlay:BuildSelectedLookup(encounter)
                ScrubLegionRMRaidFrameOverlay:UpdateAll(selected)
            end
        end
    end)
end)

-- Update the DismissOverlay function
function DismissOverlay()
    overlayDismissed = true

    -- Use the HideAll method from RaidFrameOverlay
    if ScrubLegionRMRaidFrameOverlay then
        ScrubLegionRMRaidFrameOverlay:HideAll()
    end

    if rosterDisplay and type(rosterDisplay.Hide) == "function" then
        rosterDisplay:Hide()
    end
end
