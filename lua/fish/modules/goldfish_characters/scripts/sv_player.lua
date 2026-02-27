--- internal: initializes a player's characters
function goldfish.characters.InitPlayer(ply)
    local co = coroutine.create(function()
        local steamId = ply:SteamID()
        local characters = goldfish.characters.LoadCharactersBySteamID(steamId)
        if not IsValid(ply) then 
            for _, character in ipairs(characters) do
                character:Remove()
            end

            return
        end

        local characterIds = {}
        for _, character in ipairs(characters) do
            character:AddObserver(ply)
            table.insert(characterIds, character:GetId())
        end

        goldfish.characters.playerCharacters[ply:SteamID()] = characterIds

        hook.Run("Goldfish_Characters_PlayerLoaded", ply, characters)
    end)

    local status, result = coroutine.resume(co)
    if not status then
        error(result)
    end
end