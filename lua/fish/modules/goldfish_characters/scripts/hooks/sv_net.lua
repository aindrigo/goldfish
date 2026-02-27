util.AddNetworkString("goldfish.characters.Sync")
util.AddNetworkString("goldfish.characters.Remove")
util.AddNetworkString("goldfish.characters.Create")

net.Receive("goldfish.characters.Create", function(_, ply)
    local ct = CurTime()
    if (ply._goldfish_characters_nextCreate or 0) > ct then return end
    ply._goldfish_characters_nextCreate = ct + 6

    local characterIds = goldfish.characters.playerCharacters[ply:SteamID()] 
    if not istable(characterIds) then
        ply:Kick("Tried to create a character before characters were loaded")
        return
    end

    local userDataLength = net.ReadUInt(16)
    local userDataStream = net.ReadData(userDataLength)

    local userData = serial.Deserialize(userDataStream, serial.Types.TABLE)
    assert(isstring(userData.name), "missing name")

    local name = userData.name
    local characterData = {}

    hook.Run("Goldfish_Characters_Init", userData, characterData)

    local co = coroutine.create(function()
        local steamId = ply:SteamID()
        local id = goldfish.characters.Insert(steamId, name, characterData)
        if not IsValid(ply) then return end

        local character = goldfish.characters.Character(id, steamId, name, characterData)
        character:AddObserver(ply)

        table.insert(characterIds, id)
    end)

    local status, result = coroutine.resume(co)
    if not status then
        error(result)
    end
end)