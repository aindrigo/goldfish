

net.Receive("goldfish.config.Sync", function()
    local count = net.ReadUInt(16)

    for _ = 1, count do
        goldfish.config.Option.static:_NetRead()
    end
end)