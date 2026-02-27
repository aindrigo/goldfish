gameevent.Listen("OnRequestFullUpdate")

function HOOKS:OnRequestFullUpdate(data)
    local ply = Player(data.userid)
    if not IsValid(ply) then return end

    local optionsToWrite = {}
    for _, options in pairs(goldfish.config.options) do
        for _, option in pairs(options) do
            if option:GetRealm() ~= fish.Realm.SERVER then continue end
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

    net.Send(ply)
end

function HOOKS:PlayerDisconnected(ply)
    for _, options in ipairs(goldfish.config.options) do
        for _, option in pairs(options) do
            if not option:HasFlag(goldfish.config.OptionFlags.REPLICATE) then continue end
            if option:GetRealm() ~= fish.Realm.CLIENT then continue end

            if istable(option._values) then
                option._values[ply:UserID()] = nil
            end
        end
    end
end