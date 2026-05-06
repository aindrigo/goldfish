function HOOKS:Goldfish_Sync_OnPlayerReady(data)
    local ply = Player(data.userid)
    if not IsValid(ply) then return end

    goldfish.sync.Reconcile(ply)
end