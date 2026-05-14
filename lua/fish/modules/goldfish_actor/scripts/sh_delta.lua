--- @enum goldfish.actor.OperationType
goldfish.actor.OperationType = {
    VariableSet = 0,
    VariableReset = 1,

    ObjectCreate = 2,
    ObjectDestroy = 3
}


--- @class goldfish.actor.Operation
--- @field objectName string
--- @field objectIndex number
--- @field observers table<Player>
--- @field type goldfish.actor.OperationType
--- @field value? any
--- @field variables? table<string, any>

--- @param operation goldfish.actor.OperationType
--- @param observers table<Player>
--- @param objectName string
--- @param objectIndex number
--- @return goldfish.actor.Operation
function goldfish.actor.BuildOperation(operation, observers, objectName, objectIndex, ...)
    if operation == goldfish.actor.OperationType.VariableSet then
        local variableName, value = ...
        return {
            ["type"] = operation,
            ["observers"] = observers,
            ["objectName"] = objectName,
            ["objectIndex"] = objectIndex,
            ["variableName"] = variableName,
            ["value"] = value,
        }
    elseif operation == goldfish.actor.OperationType.VariableReset then
        local variableName = ...
        return {
            ["type"] = operation,
            ["observers"] = observers,
            ["objectName"] = objectName,
            ["objectIndex"] = objectIndex,
            ["variableName"] = variableName,
        }
    elseif operation == goldfish.actor.OperationType.ObjectCreate then
        local variables = ...
        return {
            ["type"] = operation,
            ["observers"] = observers,
            ["variables"] = variables,
            ["objectName"] = objectName,
            ["objectIndex"] = objectIndex
        }
    elseif operation == goldfish.actor.OperationType.ObjectDestroy then
        return {
            ["type"] = operation,
            ["observers"] = observers,
            ["objectName"] = objectName,
            ["objectIndex"] = objectIndex
        }
    end

    error("not supposed to be here")
end

--- internal: serializes goldfish.actor.Operation
--- @param buf serial.Buffer
--- @param operation goldfish.actor.Operation
function goldfish.actor.SerializeOperation(buf, operation)
    buf:WriteByte(operation.type, true)
    buf:WriteString(operation.objectName)
    buf:WriteShort(operation.objectIndex, true)

    local op = operation.type

    if op == goldfish.actor.OperationType.VariableSet then
        buf:WriteString(operation.variableName)
        buf:Write(operation.value)
    elseif op == goldfish.actor.OperationType.VariableReset then
        buf:WriteString(operation.variableName)
    elseif op == goldfish.actor.OperationType.ObjectCreate then
        buf:Write(operation.variables, serial.Types.TABLE)
    end
end

--- internal: deserializes a goldfish.actor.Operation
--- @param buf serial.Buffer
--- @return goldfish.actor.Operation
function goldfish.actor.DeserializeOperation(buf)
    local op = buf:ReadByte(true)
    local objectName = buf:ReadString()
    local objectIndex = buf:ReadShort(true)

    if op == goldfish.actor.OperationType.VariableSet then
        return goldfish.actor.BuildOperation(op, {}, objectName, objectIndex, buf:ReadString(), buf:Read())
    elseif op == goldfish.actor.OperationType.VariableReset then
        return goldfish.actor.BuildOperation(op, {}, objectName, objectIndex, buf:ReadString())
    elseif op == goldfish.actor.OperationType.ObjectCreate then
        return goldfish.actor.BuildOperation(op, {}, objectName, objectIndex, buf:Read(serial.Types.TABLE))
    elseif op == goldfish.actor.OperationType.ObjectDestroy then
        return goldfish.actor.BuildOperation(op, {}, objectName, objectIndex)
    end

    error("invalid operation type " .. tostring(op))
end

--- @param operation goldfish.actor.Operation
--- @return boolean, string success or error
function goldfish.actor.PerformOperation(operation)
    local op = operation.type

    local objects = goldfish.actor.objects[operation.objectName]
    if not istable(objects) then
        return false, "no registry objects with name " .. operation.objectName
    end

    local object = objects[operation.objectIndex]
    if op == goldfish.actor.OperationType.VariableSet then
        if not IsValid(object) then
            return false, "no such object " .. tostring(operation.objectIndex)
        end

        object:_VariableSet(operation.variableName, operation.value)
    elseif op == goldfish.actor.OperationType.VariableReset then
        object:_VariableSet(operation.variableName, nil)
    elseif op == goldfish.actor.OperationType.ObjectCreate then
        if IsValid(object) then
            return false, "tried to duplicate object " .. tostring(operation.objectIndex)
        end

        object = goldfish.actor.Instantiate(operation.objectName, operation.objectIndex)
        object:SetVariables(operation.variables)
        if isfunction(object.OnSpawn) then
            object:OnSpawn()
        end
    elseif op == goldfish.actor.OperationType.ObjectDestroy then
        if not IsValid(object) then
            return false, "tried to destroy non-existent object " .. tostring(operation.objectIndex)
        end

        object:_Destroy()
    end

    return true, ""
end
