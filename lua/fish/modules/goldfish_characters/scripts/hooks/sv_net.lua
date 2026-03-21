util.AddNetworkString("goldfish.characters.Sync")
util.AddNetworkString("goldfish.characters.Remove")
util.AddNetworkString("goldfish.characters.Create")
util.AddNetworkString("goldfish.characters.Select")

net.Receive("goldfish.characters.Create", function(len, ply)
    local ct = CurTime()
    if (ply._goldfish_characters_nextCreate or 0) > ct then return end
    ply._goldfish_characters_nextCreate = ct + 6

    local characterIds = goldfish.characters.playerCharacters[ply:SteamID()]
    if not istable(characterIds) then
        ply:Kick("Tried to create a character before characters were loaded")
        return
    end

    local userDataStream = net.ReadData(len / 8)
    local userData = serial.Deserialize(userDataStream)
    assert(isstring(userData.name), "missing name")

    local name = userData.name
    local characterData = {}

    hook.Run("Goldfish_Characters_PreCreate", ply, userData, characterData)

    local co = coroutine.create(function()
        local steamId = ply:SteamID()
        local id = goldfish.characters.Insert(steamId, name, characterData)
        if not IsValid(ply) then return end

        local character = goldfish.characters.Character(id, steamId, name, characterData)
        character:AddObserver(ply)

        table.insert(characterIds, id)

        hook.Run("Goldfish_Characters_PostCreate", ply, character)
    end)

    local status, result = coroutine.resume(co)
    if not status then
        error(result)
    end
end)

net.Receive("goldfish.characters.Select", function(_, ply)
    local ct = CurTime()
    if (ply._goldfish_characters_nextSelect or 0) > ct then return end
    ply._goldfish_characters_nextSelect = ct + 6

    local characterIds = goldfish.characters.playerCharacters[ply:SteamID()]
    if not istable(characterIds) then
        ply:Kick("Tried to select a character before characters were loaded")
        return
    end

    local characterId = net.ReadUInt(16)
    local character = goldfish.characters.data[characterId]

    if character:GetOwnerSteamID() ~= ply:SteamID() then
        ply:Kick("Tried to load someone else's character")
        return
    end

    hook.Run("Goldfish_Characters_Select", ply, character)
    ply:SetCharacter( characterId )
end)
