function HOOKS:InitPostEntity()    
    local optionsToWrite = {}
    for _, options in pairs(goldfish.config.options) do
        for _, option in pairs(options) do
            if option:GetRealm() ~= fish.Realm.CLIENT then continue end
            if not option:HasFlag(goldfish.config.OptionFlags.REPLICATE) then continue end

            table.insert(optionsToWrite, option)
        end
    end

    if optionsToWrite[1] == nil then return end

    net.Start("goldfish.config.Sync")
    net.WriteUInt(#optionsToWrite, 16)
    for _, option in ipairs(optionsToWrite) do
        option:_NetWrite()
    end

    net.SendToServer()
end