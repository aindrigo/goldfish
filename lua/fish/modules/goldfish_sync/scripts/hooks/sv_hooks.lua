gameevent.Listen("OnRequestFullUpdate")
function HOOKS:OnRequestFullUpdate(data)
    local ply = Player(data.userid)
    if not IsValid(ply) then return end

    goldfish.sync.Reconcile(ply)
end