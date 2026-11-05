net.Receive("goldfish.script.Instantiate", function()
    local instance, id = goldfish.script.Read(false)

    for _, source in ipairs(instance.sources) do
        goldfish.script._Load(source, instance.context)
    end

    goldfish.script.data[id] = instance
    goldfish.script._Instantiate(instance)
end)

net.Receive("goldfish.script.Destroy", function()
    local id = net.ReadUInt(16)
    goldfish.script._Destroy(goldfish.script.data[id])
    goldfish.script.data[id] = nil
end)

net.Receive("goldfish.script.FullUpdate", function()
    if goldfish.script.data[1] ~= nil then
        for i, instance in ipairs(goldfish.script.data) do
            goldfish.script._Destroy(instance)
            goldfish.script.data[i] = nil
        end
    end

    local count = net.ReadUInt(16)
    for _ = 1, count do
        local instance, id = goldfish.script.Read(false)

        for _, source in ipairs(instance.sources) do
            goldfish.script._Load(source, instance.context)
        end

        goldfish.script.data[id] = instance
        goldfish.script._Instantiate(instance)
    end
end)


net.Receive("goldfish.script.UpdateSources", function()
    local id = net.ReadUInt(16)
    local sources = goldfish.script.ReadSources()

    local instance = goldfish.script.data[id]
    instance.sources = sources
    for _, source in ipairs(sources) do
        goldfish.script._Load(source, instance.data)
    end
end)

net.Receive("goldfish.script.SetState", function()
    local id = net.ReadUInt(16)
    local state = net.ReadUInt(8)

    local instance = goldfish.script.data[id]
    instance.state = state
end)
