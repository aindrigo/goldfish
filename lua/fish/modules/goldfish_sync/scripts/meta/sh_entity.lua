--- @param id string
--- @param value any
function fish.meta.Entity:SetSyncVar(id, value)
    if isstring(id) then
        id = goldfish.sync.variableNames[id]
    end

    assert(isnumber(id), "no such variable " .. tostring(id))
    local variable = goldfish.sync.variables[id]

    assert(istable(variable), "invalid variable type")
    assert(value == nil or serial.GetType(value) == variable.type, "mismatching types")

    local entIndex = self:EntIndex()

    local entityData = goldfish.sync.data[entIndex] or {}
    local variableData = entityData.variables or {}

    variableData[id] = value
    entityData.variables = variableData

    goldfish.sync.data[entIndex] = entityData

    if SERVER then
        local isPrivate = bit.band(variable.flags, goldfish.sync.Flags.PRIVATE) == goldfish.sync.Flags.PRIVATE
        local target = isPrivate and self or player.GetAll()

        if value == nil then
            net.Start("goldfish.sync.unset")
            net.WriteUInt(entIndex, 16)
            net.WriteUInt(id, 16)
            net.Send(target)
        else
            net.Start("goldfish.sync.set")
            net.WriteUInt(entIndex, 16)
            net.WriteUInt(id, 16)

            local stream = serial.Serialize(value, variable.type)
            local streamSize = #stream
            net.WriteUInt(streamSize, 16)
            net.WriteData(stream, streamSize)
    
            net.Send(target)
        end
    end
end

--- @param id string
--- @param default any returned if value is nil
--- @return any value
function fish.meta.Entity:GetSyncVar(id, default)
    if isstring(id) then
        id = goldfish.sync.variableNames[id]
    end

    assert(isnumber(id), "no such variable " .. tostring(id))
    local variableData = goldfish.sync.variables[id]
    assert(istable(variableData), "invalid variable")

    local entIndex = self:EntIndex()

    local entityData = goldfish.sync.data[entIndex] or {}
    local variableData = entityData.variables or {}

    local value = variableData[id]
    if value == nil then
        return default
    end

    return value
end