function RosterParse(rosterString, ScrubLegionRMDB)
    local decodedRosterString = C_EncodingUtil.DecodeBase64(rosterString)
    if decodedRosterString then
        local data = json.decode(decodedRosterString)
        if data then
            ScrubLegionRMDB.imported = data
            ScrubLegionRMDB.rosterString = rosterString -- Save the raw string!
            print("Roster imported successfully!")
            return true
        else
            print("Failed to decode roster data.")
            return false
        end
    end
    return false
end
