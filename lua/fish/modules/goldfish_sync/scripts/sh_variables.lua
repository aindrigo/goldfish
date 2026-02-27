goldfish.sync.variables = goldfish.sync.variables or {}
goldfish.sync.variableNames = goldfish.sync.variableNames or {}

--- defines a sync variable
--- @param name string
--- @param typeId string|serial.Types
--- @param flags goldfish.sync.Flags
--- @return number variable Id
function goldfish.sync.DefineVariable(name, typeId, flags)
    if isstring(typeId) then
        typeId = serial.typeNames[typeId]
    end

    local variableData = {
        ["name"] = name,
        ["type"] = typeId,
        ["flags"] = flags or 0
    }

    local id = goldfish.sync.variableNames[name]
    if isnumber(id) then
        goldfish.sync.variables[id] = variableData
    else
        id = table.insert(goldfish.sync.variables, variableData)
        goldfish.sync.variableNames[name] = id
    end
    
    return id
end