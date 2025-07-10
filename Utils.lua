function DeepPrint(e)
    if type(e) == "table" then
        for k, v in pairs(e) do
            print("Key:", k)
            DeepPrint(v)
        end
    else
        print("Value:", e)
    end
end