--- @enum goldfish.sync.Flags
goldfish.sync.Flags = {
    NONE = 0,
    PRIVATE = 1
}

--- updates the target's internal sync variable cahce
--- @param target Player|CRecipientFilter|table
function goldfish.sync.Reconcile(target)
    local isPlayer = isentity(target) and target:IsPlayer()

    local dataCount = 0
    local data = {}
    
    for index, entitySyncData in pairs(goldfish.sync.data) do
        local allVariables = entitySyncData.variables or {}

        local variables = {}
        local variableCount = 0

        for id, value in pairs(allVariables) do
            local variableData = goldfish.sync.variables[id]
            local isPrivate = bit.band(variableData.flags, goldfish.sync.Flags.PRIVATE) == goldfish.sync.Flags.PRIVATE

            if not isPrivate or (isPlayer and target:EntIndex() == index) then
                variables[id] = value
                variableCount = variableCount + 1
            end
        end

        if variableCount > 0 then
            local entityData = {}
            entityData.variables = variables
            entityData.variableCount = variableCount

            data[index] = entityData
            dataCount = dataCount + 1
        end
    end

    if dataCount < 1 then return end

    net.Start("goldfish.sync.reconcile")
    net.WriteUInt(dataCount, 16)
    for index, entityData in pairs(data) do
        net.WriteUInt(index, 16)
        net.WriteUInt(entityData.variableCount, 16)
        for variableId, value in pairs(entityData.variables) do
            local variableData = goldfish.sync.variables[variableId]
            net.WriteUInt(variableId, 16)

            local stream = serial.Serialize(value, variableData.type)
            local streamSize = #stream

            net.WriteUInt(streamSize, 16)
            net.WriteData(stream, streamSize)
        end
    end

    net.Send(target)
end