net.Receive("goldfish.sync.reconcile", function()
    local entityCount = net.ReadUInt(16)
    local syncData = {}
    for i = 1, entityCount do
        local entityId = net.ReadUInt(16)
        local variableCount = net.ReadUInt(16)

        local variables = {}
        for i = 1, variableCount do
            local variableId = net.ReadUInt(16)
            local variableData = goldfish.sync.variables[variableId]

            local stream = net.ReadData(net.ReadUInt(16))
            variables[variableId] = serial.Deserialize(stream, variableData.type)
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

    local variable = goldfish.sync.variables[variableId]

    local entityData = goldfish.sync.data[entityId] or {}
    local variableData = entityData.variables or {}

    local stream = net.ReadData(net.ReadUInt(16))

    variableData[variableId] = serial.Deserialize(stream, variable.type)

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