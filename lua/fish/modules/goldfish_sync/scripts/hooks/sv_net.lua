util.AddNetworkString("goldfish.sync.reconcile")
util.AddNetworkString("goldfish.sync.set")
util.AddNetworkString("goldfish.sync.unset")
util.AddNetworkString("goldfish.sync.ready")


net.Receive("goldfish.sync.ready", function(_, ply)
    if not goldfish.sync.connecting[ply:UserID()] then return end
    goldfish.sync.connecting[ply:UserID()] = nil

    hook.Run("Goldfish_Sync_OnPlayerReady", ply)
end)