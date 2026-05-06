function HOOKS:Goldfish_Sync_OnPlayerReady(ply)
    goldfish.sync.Reconcile(ply)
end

function HOOKS:PlayerInitialSpawn(ply)
    goldfish.sync.connecting[ply:UserID()] = CurTime() + 120 -- 2 minutes before the client is kicked
end

function HOOKS:PlayerDisconnected(ply)
    goldfish.sync.connecting[ply:UserID()] = nil -- cheaper to just set than to check then set
end

function HOOKS:Think()
    for id, endTime in pairs(goldfish.sync.connecting) do
        if endTime <= CurTime() then
            local ply = Player(id)
            if IsValid(ply) then
                ply:Kick("Took too long to connect")
            end
        end
    end
end