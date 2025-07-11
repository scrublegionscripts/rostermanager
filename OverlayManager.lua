OverlayManager = OverlayManager or {}

function OverlayManager:HideAllOverlays()
    for _, overlay in pairs(self.activeOverlays) do
        overlay:Hide()
    end
end

function OverlayManager:GetFullName(database, characterID)
    if not database or not database.signups then
        return "Unknown"
    end
    for _, character in pairs(database.signups) do
        if character.id == characterID then
            return string.format("%s-%s", character.name, character.realm) or "Unknown"
        end
    end
    return "Unknown"
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
                    selection = {
                        character_id = selection.character_id or "Unknown",
                        selected = selection.selected,
                        class = selection.class or "Unknown",
                        role = selection.role or "Unknown",
                        fullName = self:GetFullName(database, selection.character_id),
                    }
                    table.insert(filteredSelections, selection)
                end
            end
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
    for _, player in pairs(rosterTable) do
        if player.class then
            table.insert(row, string.format("|c%s%s|r", CLASS_COLORS[string.upper(player.class)], player.fullName))
        else
            table.insert(row, string.format("%s", player.fullName))
        end
    end
    return formattedData .. table.concat(row, "\n")
end

function OverlayManager:CreateRosterDisplay(encounterID, database)
    local rosterTable = self:GetRosterTable(encounterID, database)
    Utils:DeepPrint(rosterTable) -- Debugging line to check the roster data

    if not rosterTable then
        return "No roster data available."
    end

    return self:FormatRosterData(rosterTable)
end