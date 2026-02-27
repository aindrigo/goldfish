goldfish.config.saveDirectory = goldfish.config.saveDirectory or "goldfish"

--- internal: checks if save directories exists and if not then creates them
--- @param saveDirectory string
function goldfish.config._CheckDirectories(saveDirectory)
    saveDirectory = saveDirectory or goldfish.config.saveDirectory
    if not file.Exists("data/" .. saveDirectory, "GAME") then
        file.CreateDir(saveDirectory)
    end

    saveDirectory = saveDirectory .. "/" .. engine.ActiveGamemode()
    if not file.Exists("data/" .. saveDirectory, "GAME") then
        file.CreateDir(saveDirectory)
    end
end

--- internal: loads a namespace from a file
--- @param namespace string
--- @param saveDirectory? string
function goldfish.config.LoadNamespace(namespace, saveDirectory)
    saveDirectory = saveDirectory or goldfish.config.saveDirectory

    local filePath = string.format("%s/%s.bin", saveDirectory, namespace)
    local dataFilePath = "data/" .. filePath

    if not file.Exists(dataFilePath, "GAME") then return end

    local stream = file.Read(dataFilePath, "GAME")
    local optionValues = serial.Deserialize(stream, serial.Types.TABLE)

    for id, value in pairs(optionValues) do
        local option = options[id]
        if not istable(option) then continue end

        local realm = option:GetRealm()
        if (CLIENT and realm ~= fish.Realm.CLIENT) or (SERVER and realm ~= fish.Realm.SERVER) then
            continue
        end

        local typeId = goldfish.config.GetOptionType(value)
        if typeId ~= option:GetType() or not option:HasFlag(goldfish.config.OptionFlags.ARCHIVE) then continue end

        option:SetValue(value)
    end
end

--- internal: saves a namespace to a file
--- @param namespace string
--- @param saveDirectory? string
function goldfish.config.SaveNamespace(namespace, saveDirectory)
    saveDirectory = saveDirectory or goldfish.config.saveDirectory

    local filePath = string.format("%s/%s.bin", saveDirectory, namespace)
    local optionValues = {}

    for id, option in pairs(goldfish.config.options[namespace]) do
        if not option:HasFlag(goldfish.config.OptionFlags.ARCHIVE) then continue end

        local realm = option:GetRealm()
        if (CLIENT and realm ~= fish.Realm.CLIENT) or (SERVER and realm ~= fish.Realm.SERVER) then
            continue
        end

        optionValues[id] = option:GetValue()
    end

    if table.IsEmpty(optionValues) then return end

    local stream = serial.Serialize(optionValues, serial.Types.TABLE)
    file.Write(filePath, stream)
end

--- loads all options
--- @param saveDirectory? string
function goldfish.config.Load(saveDirectory)
    saveDirectory = saveDirectory or goldfish.config.saveDirectory
    goldfish.config._CheckDirectories(saveDirectory)

    for namespace, _ in pairs(goldfish.config.options) do
        goldfish.config.LoadNamespace(namespace, saveDirectory)
    end
end

--- saves all options
--- @param saveDirectory? string
function goldfish.config.Save(saveDirectory)
    saveDirectory = saveDirectory or goldfish.config.saveDirectory
    goldfish.config._CheckDirectories(saveDirectory)

    for namespace, _ in pairs(goldfish.config.options) do
        goldfish.config.SaveNamespace(namespace, saveDirectory)
    end
end