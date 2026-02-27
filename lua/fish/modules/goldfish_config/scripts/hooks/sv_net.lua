util.AddNetworkString("goldfish.config.Sync")


net.Receive("goldfish.config.Sync", function(_, ply)
    local count = net.ReadUInt(16)

    for _ = 1, count do
        goldfish.options.static:_NetRead(ply)
    end
end)