OverlayManager = OverlayManager or {}

function OverlayManager:HideAllOverlays()
    for _, overlay in pairs(self.activeOverlays) do
        overlay:Hide()
    end
end

function OverlayManager:GetBossName(encounterID, database)
    if not encounterID or not database or not database.encounters then
        print("Error: Invalid encounter ID or database structure.")
        return "Unknown Boss"
    end

    for _, encounter in pairs(database.encounters) do
        if encounter.id == encounterID then
            return encounter.name or "Unknown Boss"
        end
    end
    return "Unknown Boss"
end

function OverlayManager:GetFullName(database, characterID)
    if not database or not database.signups then
        return "Unknown"
    end
    for _, character in pairs(database.signups) do
        if character.character.id == characterID then
            local normalizedName = string.format("%s-%s", character.character.name, character.character.realm) or
                "Unknown"
            return normalizedName
        end
    end
    return "Unknown"
end

function OverlayManager:GetBaseName(fullName)
    if not fullName or type(fullName) ~= "string" then
        return "Unknown"
    end
    local nameParts = { strsplit("-", fullName) }
    return nameParts[1] or "Unknown"
end

function OverlayManager:GetRosterTable(encounterID, database)
    if not database then
        return nil
    end

    for _, encounter in pairs(database.encounters) do
        if encounter.id == encounterID then
            local filteredSelections = {}
            for _, selection in pairs(encounter.selections) do
                if selection.selected == true then
                    local fullName = self:GetFullName(database, selection.character_id)
                    selection = {
                        character_id = selection.character_id or "Unknown",
                        selected = selection.selected,
                        class = selection.class or "Unknown",
                        role = selection.role or "Unknown",
                        name = fullName,
                        baseName = self:GetBaseName(fullName)
                    }
                    table.insert(filteredSelections, selection)
                end
            end

            table.sort(filteredSelections, function(a, b)
                local rolePriority =
                {
                    ["TANK"] = 1,
                    ["HEAL"] = 2,
                    ["MELEE"] = 3,
                    ["RANGED"] = 4
                }

                return rolePriority[string.upper(a.role)] < rolePriority[string.upper(b.role)]
            end)

            return filteredSelections
        end
    end
    return nil
end

function OverlayManager:FormatRosterData(rosterTable)
    if not rosterTable or not Utils:AllTableElementsAreNonNil(rosterTable) then
        return "No valid roster data available."
    end

    local formattedData = "Roster Data:\n"
    local row = {}
    local currentRole = nil
    for _, player in pairs(rosterTable) do
        if player.role ~= currentRole then
            currentRole = player.role
            table.insert(row, "")
            table.insert(row, string.format("%s:", currentRole))
        end
        if player.class then
            table.insert(row,
                string.format("%s%s|r", CLASS_COLORS[string.upper(player.class)], OverlayManager:GetBaseName(player.name)))
        else
            table.insert(row, string.format("%s", OverlayManager:GetBaseName(player.name)))
        end
    end
    return formattedData .. table.concat(row, "\n")
end

function OverlayManager:isPlayerSelected(selectedPlayers, unitName)
    for _, player in pairs(selectedPlayers) do
        if player and (player.name == unitName or player.baseName == unitName) then
            return true
        end
    end
    return false
end

function OverlayManager:CreateAndSelectOverlay(frame, selectedPlayers, unitName)
    local overlay = CreateFrame("Frame", nil, frame)
    overlay:SetAllPoints(frame)
    overlay:SetFrameStrata("HIGH")
    overlay:SetFrameLevel(15)

    local raidIndex = UnitInRaid(frame.unit)
    if not raidIndex then return nil end

    local _, _, subgroup = GetRaidRosterInfo(raidIndex)
    if not subgroup then return nil end

    local lowerGroups = subgroup >= 1 and subgroup <= 4
    local upperGroups = subgroup >= 5 and subgroup <= 8

    -- Create a dark background for better text visibility
    overlay.bg = overlay:CreateTexture(nil, "BACKGROUND")
    overlay.bg:SetAllPoints()
    overlay.bg:SetColorTexture(0, 0, 0, 0.5)

    -- Create text with improved styling using default WoW font
    overlay.text = overlay:CreateFontString(nil, "OVERLAY")
    overlay.text:SetPoint("CENTER")
    overlay.text:SetFont("fonts/arialn.ttf", 12, "OUTLINE")
    overlay.text:SetShadowOffset(1, -1)
    overlay.text:SetShadowColor(0, 0, 0, 1)

    local isSelected = self:isPlayerSelected(selectedPlayers, unitName)
    if isSelected and upperGroups then
        overlay.text:SetText("|cff00ff00IN|r")
    elseif not isSelected and lowerGroups then
        overlay.text:SetText("|cffff0000OUT|r")
    end

    return overlay
end

function OverlayManager:CreateRosterDisplay(encounterID, database)
    local rosterTable = self:GetRosterTable(encounterID, database)

    if not rosterTable then
        return "No roster data available."
    end

    return self:FormatRosterData(rosterTable), rosterTable
end

function OverlayManager:ShowOverlays(selectedPlayers)
    if not selectedPlayers or #selectedPlayers == 0 then
        print("No players selected for overlay display.")
        return
    end

    -- Generic Raid Frame location loop
    self.activeOverlays = self.activeOverlays or {}

    if #self.activeOverlays > 0 then
        for _, overlay in pairs(self.activeOverlays) do
            if overlay and overlay:IsShown() then
                overlay:Hide()
            end
        end
    end

    local raidFrames = self:GetRaidFrames()

    if not next(selectedPlayers) then
        print("No selected players to display overlays for.")
        return
    end

    -- Utils:DeepPrint(selectedPlayers)

    for _, frame in pairs(raidFrames) do
        if frame and frame.unit and UnitExists(frame.unit) then
            local name = frame:GetName()
            local unitName = UnitName(frame.unit)
            local overlay = self:CreateAndSelectOverlay(frame, selectedPlayers, unitName)
            if overlay then
                self.activeOverlays[name] = overlay
                overlay:Show()
            end
        end
    end
end

function OverlayManager:GetRaidFrames()
    local frames = {}

    if C_AddOns.IsAddOnLoaded("Cell") then
        local framePattern = "CellRaidFrameHeader%dUnitButton%d"
        for i = 1, 6 do
            for j = 1, 5 do
                local cellFrameTarget = _G[framePattern:format(i, j)]
                if cellFrameTarget then
                    table.insert(frames, cellFrameTarget)
                end
            end
        end
    elseif C_AddOns.IsAddOnLoaded("ElvUI") then
        local raidFrameDisplayed = nil
        local framePattern = "ElvUF_Raid%dGroup%dUnitButton%d"
        if _G[framePattern:format(1, 1, 1)] then
            raidFrameDisplayed = 1
        else
            raidFrameDisplayed = 2
        end

        for i = 1, 6 do
            for j = 1, 5 do
                local elvFrameTarget = _G[framePattern:format(raidFrameDisplayed, i, j)]
                if elvFrameTarget then
                    table.insert(frames, elvFrameTarget)
                end
            end
        end
    else -- Blizzard Frames
        for i = 1, 40 do
            local frame = _G["RaidFrame" .. i]
            if frame then
                table.insert(frames, frame)
            end
        end
    end

    return frames
end
