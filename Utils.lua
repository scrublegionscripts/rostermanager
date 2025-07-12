Utils = Utils or {}

function Utils:DeepPrint(e)
    if type(e) == "table" then
        for k, v in pairs(e) do
            print("Key:", k)
            Utils:DeepPrint(v)
        end
    else
        print("Value:", e)
    end
end

function Utils:AllTableElementsAreNonNil(t)
    for _, v in pairs(t) do
        if v == nil then
            return false
        end
    end
    return true
end

function Utils:ShouldEnableAddon()
    local isInstance, instanceType = IsInInstance()
    if not isInstance or instanceType ~= "raid" then
        return false
    end

    local _, _, difficulty, _, _, _, _, instanceID = GetInstanceInfo()

    return instanceID == LIBERATION_OF_UNDERMINE_ID and difficulty == 16 and instanceType == "raid"
end

function Utils:IsBossDetected(lastDetectedEncounter)
    for i = 1, 40 do
        local unitID = "nameplate" .. i
        if UnitExists(unitID) then
            local guid = UnitGUID(unitID)
            if guid then
                local _, _, _, _, _, npcID = string.split("-", guid)
                if npcID and BossToEncounter[tonumber(npcID)] then
                    local isNewBoss = BossToEncounter[tonumber(npcID)] ~= lastDetectedEncounter
                    if isNewBoss then
                        return true, npcID, BossToEncounter[tonumber(npcID)]
                    else
                        return false, nil, nil
                    end
                end
            end
        end
    end
    return false, nil, nil
end

function Utils:SafeReleaseWidget(widget)
    if widget and type(widget) == "table" then
        -- Check if the widget is actually valid and has a frame
        if widget.frame and widget.frame:IsShown() then
            if not AceGUI then
                AceGUI = LibStub and LibStub("AceGUI-3.0", true)
            end
            if AceGUI then
                pcall(function()
                    AceGUI:Release(widget)
                end)
            else
                print("Error: AceGUI is not available.")
            end
        end
        return nil
    end
    return nil
end
