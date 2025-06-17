BossToEncounter = {
    -- [npcID] = encounterID,
    [225822] = 16713,
    [225821] = 16713, -- Example: Vexie and the Geargrinders
    [229181] = 16714, -- CoC
    [229177] = 16714, -- CoC
    [228652] = 16715, -- Rik Reverb
    [230322] = 16716, -- Stix Bunk
    [230583] = 16717, -- Sprocketmonger
    [228458] = 16718, -- OaB
    [229953] = 16719, -- Mug'Zee
    [239651] = 16720, -- Gallywix
    -- Add more boss NPC IDs and their encounter IDs here
}

local LIBERATION_OF_UNDERMINE_ID = 2769 -- Instance ID for Liberation of Undermine raid

function ShouldEnableAddon()
    local isInstance, instanceType = IsInInstance()
    if not isInstance or instanceType ~= "raid" then
        -- print("DEBUG: Not in raid instance")
        return false
    end

    local _, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    -- print("DEBUG: Current Instance ID:", instanceID)
    
    return instanceID == LIBERATION_OF_UNDERMINE_ID
end