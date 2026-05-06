util.AddNetworkString("goldfish.sync.reconcile")
util.AddNetworkString("goldfish.sync.set")
util.AddNetworkString("goldfish.sync.unset")
util.AddNetworkString("goldfish.sync.ready")


net.Receive("goldfish.sync.ready", function(_, ply)
    if ply.m_bGoldfishSyncReady then return end
    ply.m_bGoldfishSyncReady = true

    hook.Run("Goldfish_Sync_OnPlayerReady", ply)
end)