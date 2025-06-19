function RosterParse(rosterString)
    local decodedRosterString = C_EncodingUtil.DecodeBase64(rosterString)
    print(decodedRosterString)
    if decodedRosterString then
        local data = json.decode(decodedRosterString)
        if data then
            ScrubLegionRMDB.imported = data
            ScrubLegionRMDB.rosterString = rosterString -- Save the raw string!
            print("Roster imported successfully!")
            ProcessImportedRoster(data)
            return true
        else
            print("Failed to decode roster data.")
            return false
        end
    end
    return false
end
