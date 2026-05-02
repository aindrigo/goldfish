function HOOKS:PlayerInitialSpawn(ply)
    goldfish.characters.playerLoadQueue[ply:UserID()] = true
end

function HOOKS:PlayerDisconnected(ply)
    local characterIds = goldfish.characters.playerCharacters[ply:SteamID()]
    if not istable(characterIds) then return end

    for _, characterId in ipairs(characterIds) do
        local character = goldfish.characters.data[characterId]
        character:Save()
        character:Remove()
        print( "Saving character", tostring( character ) )
    end

    goldfish.characters.playerCharacters[ply:SteamID()] = nil
end

gameevent.Listen("OnRequestFullUpdate")
function HOOKS:OnRequestFullUpdate(data)
    if not goldfish.characters.playerLoadQueue[data.userid] then return end
    goldfish.characters.playerLoadQueue[data.userid] = nil

    local ply = Player(data.userid)
    goldfish.characters.InitPlayer(ply)
end

function HOOKS:ShutDown()
    for id, character in pairs( goldfish.characters.data ) do
        print( "Saving character", tostring( character ) )
        character:Save()
    end
end
