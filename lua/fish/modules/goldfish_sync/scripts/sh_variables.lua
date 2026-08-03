goldfish.sync.variables = goldfish.sync.variables or {}
goldfish.sync.variableNames = goldfish.sync.variableNames or {}


--- @param value any
--- @return goldfish.sync.VariableType?
function goldfish.sync.GetType(value)
    if IsColor(value) then
        return goldfish.sync.VariableType.COLOR
    elseif isvector(value) then
        return goldfish.sync.VariableType.VECTOR
    elseif isangle(value) then
        return goldfish.sync.VariableType.ANGLES
    elseif isentity(value) then
        return goldfish.sync.VariableType.ENTITY
    elseif istable(value) then
        return goldfish.sync.VariableType.TABLE
    elseif isnumber(value) then
        return goldfish.sync.VariableType.NUMBER
    elseif isbool(value) then
        return goldfish.sync.VariableType.BOOLEAN
    elseif isstring(value) then
        return goldfish.sync.VariableType.STRING
    end

    return nil
end

local typeNames = {
    ["number"] = goldfish.sync.VariableType.NUMBER,
    ["string"] = goldfish.sync.VariableType.STRING,
    ["table"] = goldfish.sync.VariableType.TABLE,
    ["boolean"] = goldfish.sync.VariableType.BOOLEAN,
    ["Color"] = goldfish.sync.VariableType.COLOR,
    ["Vector"] = goldfish.sync.VariableType.VECTOR,
    ["Angle"] = goldfish.sync.VariableType.ANGLES,
    ["Entity"] = goldfish.sync.VariableType.ENTITY,
}
--- defines a sync variable
--- @param name string
--- @param typeId string|goldfish.sync.VariableType
--- @param flags? number
--- @return number variable id
function goldfish.sync.DefineVariable(name, typeId, flags)
    if isstring(typeId) then
        typeId = typeNames[typeId]
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
        goldfish.sync.variables[#goldfish.sync.variables + 1] = variableData
        id = #goldfish.sync.variables
        goldfish.sync.variableNames[name] = id
    end

    return id
end
