function CreateRosterInput(parentFrame)
    -- Create a label for messages
    local messageLabel = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    messageLabel:SetPoint("CENTER", parentFrame, "TOP", 0, -50)
    messageLabel:SetText("")

    -- Create a scroll frame for multi-line input
    local scrollFrame = CreateFrame("ScrollFrame", nil, parentFrame, "UIPanelScrollFrameTemplate,BackdropTemplate")
    scrollFrame:SetSize(255, 100)
    scrollFrame:SetPoint("CENTER", parentFrame, "TOP", 0, -125)
    scrollFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    scrollFrame:SetBackdropColor(0, 0, 0, 0.7)

    -- Create a multi-line edit box
    local rosterInput = CreateFrame("EditBox", nil, scrollFrame)
    rosterInput:SetMultiLine(true)
    rosterInput:SetFontObject(GameFontHighlightLarge)
    rosterInput:SetWidth(230)
    rosterInput:SetHeight(80)
    rosterInput:SetAutoFocus(false)
    rosterInput:SetMaxLetters(65536)
    rosterInput:SetTextColor(1, 1, 1)
    rosterInput:SetJustifyH("LEFT")
    rosterInput:SetJustifyV("TOP")
    rosterInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    rosterInput:SetTextInsets(5, 5, 5, 5) -- Add padding inside the edit box
    
    -- Add a background to the edit box
    local bg = rosterInput:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.3)

    -- Enable text wrapping
    rosterInput:SetScript("OnTextChanged", function(self)
        scrollFrame:UpdateScrollChildRect()
    end)

    scrollFrame:SetScrollChild(rosterInput)

    rosterInput:SetScript("OnEditFocusGained", function(self)
        if self:GetText() == "Paste Roster String here..." then
            self:SetText("")
        end
    end)

    rosterInput:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then
            self:SetText("Paste Roster String here...")
        end
    end)

    -- Save/validate function for reuse
    local function saveRoster()
        local text = rosterInput:GetText()
        if text ~= "" and text ~= "Paste Roster String here..." then
            ScrubLegionRMDB.rosterString = text
            -- Attempt to parse the roster string
            local parsedSuccess = RosterParse(ScrubLegionRMDB.rosterString)
            if parsedSuccess then
                messageLabel:SetText("|cff00ff00Roster successfully parsed!|r")
                print("Roster successfully parsed!")
            else
                messageLabel:SetText("|cffff0000Failed to parse roster.|r")
                print("Failed to parse roster.")
            end
            rosterInput:ClearFocus()
        end
    end

    rosterInput:SetScript("OnEnterPressed", saveRoster)

    -- Add an "Enter" button
    local enterBtn = CreateFrame("Button", nil, parentFrame, "UIPanelButtonTemplate")
    enterBtn:SetSize(60, 22)
    enterBtn:SetPoint("TOPRIGHT", scrollFrame, "BOTTOMRIGHT", 0, -8)
    enterBtn:SetText("Enter")
    enterBtn:SetScript("OnClick", saveRoster)

    -- Adjust the "Clear" button to be next to "Enter"
    local clearBtn = CreateFrame("Button", nil, parentFrame, "UIPanelButtonTemplate")
    clearBtn:SetSize(60, 22)
    clearBtn:SetPoint("TOPLEFT", scrollFrame, "BOTTOMLEFT", 0, -8)
    clearBtn:SetText("Clear")
    clearBtn:SetScript("OnClick", function()
        -- Clear the input box
        rosterInput:SetText("")
        messageLabel:SetText("")
        
        -- Clear all stored data
        ScrubLegionRMDB = {
            rosterString = nil,
            imported = nil,
            currentEncounterID = nil
        }
        
        -- Reset any active overlays
        if ScrubLegionRMRaidFrameOverlay then
            ScrubLegionRMRaidFrameOverlay:HideAll()
        end
        
        -- Notify user
        print("ScrubLegionRMDB has been cleared and reset.")
    end)

    return rosterInput
end