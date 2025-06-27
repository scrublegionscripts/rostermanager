local RaidFrameOverlay = {}

-- ELVUI Cringe!
local ElvUIFrames = {
    "ElvUF_Raid2Group1UnitButton1", "ElvUF_Raid2Group1UnitButton2", "ElvUF_Raid2Group1UnitButton3",
    "ElvUF_Raid2Group1UnitButton4", "ElvUF_Raid2Group1UnitButton5", "ElvUF_Raid2Group2UnitButton1",
    "ElvUF_Raid2Group2UnitButton2", "ElvUF_Raid2Group2UnitButton3", "ElvUF_Raid2Group2UnitButton4",
    "ElvUF_Raid2Group2UnitButton5", "ElvUF_Raid2Group3UnitButton1", "ElvUF_Raid2Group3UnitButton2",
    "ElvUF_Raid2Group3UnitButton3", "ElvUF_Raid2Group3UnitButton4", "ElvUF_Raid2Group3UnitButton5",
    "ElvUF_Raid2Group4UnitButton1", "ElvUF_Raid2Group4UnitButton2", "ElvUF_Raid2Group4UnitButton3",
    "ElvUF_Raid2Group4UnitButton4", "ElvUF_Raid2Group4UnitButton5", "ElvUF_Raid2Group5UnitButton1",
    "ElvUF_Raid2Group5UnitButton2", "ElvUF_Raid2Group5UnitButton3", "ElvUF_Raid2Group5UnitButton4",
    "ElvUF_Raid2Group5UnitButton5", "ElvUF_Raid2Group6UnitButton1", "ElvUF_Raid2Group6UnitButton2",
    "ElvUF_Raid2Group6UnitButton3", "ElvUF_Raid2Group6UnitButton4", "ElvUF_Raid2Group6UnitButton5",
}

function RaidFrameOverlay:NormalizeFullName(name, realm)
    if not name then return nil end
    name = name:gsub("[%s%c]+", "")
    if not realm or realm == "" then
        realm = GetRealmName():gsub("[%s%c]+", "")
    else
        realm = realm:gsub("[%s%c]+", "")
    end

    return name .. "-" .. realm
end

function RaidFrameOverlay:BuildSelectedLookup(encounter)
    local selected = {}
    if not encounter then return selected end

    if encounter.selections then
        for i, sel in ipairs(encounter.selections) do
            if sel.fullName then
                selected[sel.fullName] = true
            end
        end
    end

    return selected
end

function RaidFrameOverlay:BuildCurrentRosterLookup()
    local lookup = {}
    local numMembers = GetNumGroupMembers()

    for i = 1, numMembers do
        local name, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, guid = GetRaidRosterInfo(i)
        if name then
            local fullName
            if not name:find("-") then
                fullName = self:NormalizeFullName(name, GetRealmName())
            else
                fullName = name
            end
            if fullName then
                lookup[fullName] = true
            end
        end
    end

    return lookup
end

RaidFrameOverlay.activeOverlays = {}

function RaidFrameOverlay:HideAll()
    for _, overlay in pairs(self.activeOverlays) do
        if overlay and overlay:IsShown() then
            overlay:Hide()
        end
    end
    wipe(self.activeOverlays)
end

function RaidFrameOverlay:ShowOverlay(frame, text)
    if not frame or not frame.GetName or not frame:GetName() then return end
    local frameName = frame:GetName()
    local overlay = self.activeOverlays[frameName]
    if not overlay then
        overlay = CreateFrame("Frame", nil, frame)
        overlay:SetFrameStrata("HIGH")
        overlay:SetFrameLevel(frame:GetFrameLevel() + 10)
        overlay:SetSize(frame:GetWidth(), frame:GetHeight())
        overlay:SetPoint("CENTER", frame, "CENTER", 0, 0)

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

        -- Update the SetText function to handle colors
        function overlay:SetText(string)
            if string == "IN" then
                self.text:SetTextColor(0, 1, 0, 1) -- Bright green
            else
                self.text:SetTextColor(1, 0, 0, 1) -- Bright red
            end
            self.text:SetText(string)
        end

        self.activeOverlays[frameName] = overlay
    end

    overlay:SetSize(frame:GetWidth(), frame:GetHeight())
    overlay:ClearAllPoints()
    overlay:SetPoint("CENTER", frame, "CENTER", 0, 0)
    overlay:SetText(text)
    overlay:SetAlpha(1)
    overlay:Show()
end

function RaidFrameOverlay:AddOverlayToFrame(frame, selectedLookup, currentRosterLookup)
    if not frame or not frame.unit or not UnitExists(frame.unit) then return end

    local raidIndex = UnitInRaid(frame.unit)
    if not raidIndex then return end

    local _, _, subgroup = GetRaidRosterInfo(raidIndex)
    if not subgroup then return end

    local unitNameOnly, unitRealm = UnitName(frame.unit)
    local fullName = self:NormalizeFullName(unitNameOnly, unitRealm)
    local frameName = frame:GetName()
    local overlay = self.activeOverlays[frameName]

    -- Clear any existing overlay first
    if overlay and overlay:IsShown() then
        overlay:Hide()
    end

    -- Skip if selectedLookup is empty
    if not next(selectedLookup) then return end

    -- Determine player status and group position
    local isSelected = selectedLookup[fullName]
    local isInLowerGroups = (subgroup >= 1 and subgroup <= 4)
    local isInUpperGroups = (subgroup >= 5 and subgroup <= 6)

    -- Show overlay only in specific cases
    if isInLowerGroups and not isSelected then
        self:ShowOverlay(frame, "|cffff0000OUT|r")
    elseif isInUpperGroups and isSelected then
        self:ShowOverlay(frame, "|cff00ff00IN|r")
    end
end

local function IsUsingElvUI()
    return C_AddOns.IsAddOnLoaded("ElvUI")
end

local function IsUsingSUF()
    return C_AddOns.IsAddOnLoaded("ShadowedUnitFrames")
end

local function IsUsingCell()
    return C_AddOns.IsAddOnLoaded("Cell")
end

local function IsUsingBlizzardRaidFrames()
    return not (IsUsingElvUI() or IsUsingSUF() or IsUsingCell())
end

function RaidFrameOverlay:UpdateAll(selectedLookup)
    local currentRosterLookup = self:BuildCurrentRosterLookup()

    -- print("DEBUG: Current roster lookup built with", table.maxn(currentRosterLookup), "players")
    -- print("DEBUG: Selected lookup contains", table.maxn(selectedLookup), "players")

    -- ElvUI frames handling
    if IsUsingElvUI() then
        for _, frameName in ipairs(ElvUIFrames) do
            local frame = _G[frameName]
            if frame then
                self:AddOverlayToFrame(frame, selectedLookup, currentRosterLookup)
            end
        end
    end

    -- Blizzard CompactRaidFrames
    if IsUsingBlizzardRaidFrames() then
        for i = 1, 6 do
            for j = 1, 5 do
                local frame = _G["CompactRaidGroup" .. i .. "Member" .. j]
                if frame then
                    self:AddOverlayToFrame(frame, selectedLookup)
                end
            end
        end
    end

    -- Shadowed Unit Frames (SUF)
    if IsUsingSUF() then
        for i = 1, 40 do
            local frame = _G["SUFHeaderraidUnitButton" .. i]
            if frame then
                self:AddOverlayToFrame(frame, selectedLookup)
            end
        end
    end

    -- Cell
    if IsUsingCell() then
        local CellRaidFramePattern = "CellRaidFrameHeader%dUnitButton%d"
        for i = 1, 5 do
            for j = 1, 5 do
                local frame = _G[string.format(CellRaidFramePattern, i, j)]
                if frame then
                    self:AddOverlayToFrame(frame, selectedLookup)
                end
            end
        end
    end
end

_G.ScrubLegionRMRaidFrameOverlay = RaidFrameOverlay
