net.Receive("goldfish.sync.reconcile", function()
    local entityCount = net.ReadUInt(16)
    local syncData = {}
    for i = 1, entityCount do
        local entityId = net.ReadUInt(16)
        local variableCount = net.ReadUInt(16)

        local variables = {}
        for _ = 1, variableCount do
            local variableId = net.ReadUInt(16)
            local stream = net.ReadData(net.ReadUInt(16))
            variables[variableId] = serial.DeserializeSingle(stream, goldfish.sync.serialSettings)
        end

        local entityData = {}
        entityData.variables = variables
        syncData[entityId] = entityData
    end

    goldfish.sync.data = syncData
end)

net.Receive("goldfish.sync.set", function()
    local entityId = net.ReadUInt(16)
    local variableId = net.ReadUInt(16)

    local entityData = goldfish.sync.data[entityId] or {}
    local variableData = entityData.variables or {}

    local stream = net.ReadData(net.ReadUInt(16))

    variableData[variableId] = serial.DeserializeSingle(stream, goldfish.sync.serialSettings)

    entityData.variables = variableData
    goldfish.sync.data[entityId] = entityData
end)

net.Receive("goldfish.sync.unset", function()
    local entityId = net.ReadUInt(16)
    local variableId = net.ReadUInt(16)

    local entityData = goldfish.sync.data[entityId] or {}
    local variableData = entityData.variables or {}

    variableData[variableId] = nil

    entityData.variables = variableData
    goldfish.sync.data[entityId] = entityData
end)
