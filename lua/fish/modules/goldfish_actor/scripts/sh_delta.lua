--- @class goldfish.actor.Operation
--- @field objectName string
--- @field objectIndex number
--- @field observers? table<Player>
--- @field type goldfish.actor.OperationType
--- @field value? any
--- @field variables? table<string, any>

--- @param operation goldfish.actor.OperationType
--- @param objectName string
--- @param objectIndex number
--- @param observers? table<Player>
--- @return goldfish.actor.Operation
function goldfish.actor.BuildOperation(operation, objectName, objectIndex, observers, ...)
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
    elseif operation == goldfish.actor.OperationType.RemoteProcedureCall then
        local rpcName, rpcParameters = ...
        return {
            ["type"] = operation,
            ["observers"] = observers,
            ["objectName"] = objectName,
            ["objectIndex"] = objectIndex,
            ["rpcName"] = rpcName,
            ["rpcParameters"] = rpcParameters
        }
    end

    error("not supposed to be here")
end

--- internal: serializes goldfish.actor.Operation
--- @param operation goldfish.actor.Operation
--- @return string stream
function goldfish.actor.SerializeOperation(operation)
    local observers = operation.observers
    operation.observers = nil

    local data = serial.SerializeSingle(operation, goldfish.actor.serialSettings)
    operation.observers = observers

    return data
end

--- internal: deserializes a goldfish.actor.Operation
--- @param stream string
--- @param cursor? number
--- @return goldfish.actor.Operation operation
--- @return number size
function goldfish.actor.DeserializeOperation(stream, cursor)
    local value, valueSize = serial.DeserializeSingle(stream, goldfish.actor.serialSettings, cursor)
    if not istable(value) then
        print(stream:sub(1, cursor), "p2:", stream:sub(cursor), value, cursor)
        error("invalid operation data received")
    end

    return value, valueSize
end

--- @param operation goldfish.actor.Operation
--- @param ply? Player server-only
--- @return boolean, string success or error
function goldfish.actor.PerformOperation(operation, ply)
    if SERVER and IsValid(ply) then
        local status, message = goldfish.actor.ClientCanPerform(ply, operation)
        if not status then
            print("player " .. ply:SteamID() .. " tried to perform operation: " .. message)
        end
    end

    local op = operation.type

    local objects = goldfish.actor.objects[operation.objectName]
    if not istable(objects) then
        return false, "no registry objects with name " .. tostring(operation.objectName)
    end

    local object = objects[operation.objectIndex]
    if op == goldfish.actor.OperationType.VariableSet then
        if not IsValid(object) then
            return false, "no such object " .. goldfish.actor.ToString(operation.objectName, operation.objectIndex)
        end

        object:_VariableSet(operation.variableName, operation.value)
    elseif op == goldfish.actor.OperationType.VariableReset then
        object:_VariableSet(operation.variableName, nil)
    elseif op == goldfish.actor.OperationType.ObjectCreate then
        if IsValid(object) then
            return false, "tried to duplicate object " .. goldfish.actor.ToString(operation.objectName, operation.objectIndex)
        end

        object = goldfish.actor.Instantiate(operation.objectIndex, operation.objectName)
        object:SetVariables(operation.variables)

        if isfunction(object.OnSpawn) then
            object:OnSpawn()
        end
    elseif op == goldfish.actor.OperationType.ObjectDestroy then
        if not IsValid(object) then
            return false, "tried to destroy non-existent object " .. goldfish.actor.ToString(operation.objectName, operation.objectIndex)
        end
        object:_Destroy()
    elseif op == goldfish.actor.OperationType.RemoteProcedureCall then
        if SERVER then
            object:_PerformRPC(ply, operation.rpcName, operation.rpcParameters)
        else
            object:_PerformRPC(operation.rpcName, operation.rpcParameters)
        end
    end

    return true, ""
end

--- checks if the client can perform an operation type
--- @param ply Player
--- @param operation goldfish.actor.Operation
--- @return boolean can execute
--- @return string message
function goldfish.actor.ClientCanPerform(ply, operation)
    if operation.type ~= goldfish.actor.OperationType.RemoteProcedureCall then
        return false, "cannot perform non-rpc"
    end

    if SERVER then
        local obj = goldfish.actor.objects[operation.objectName][operation.objectIndex]
        if IsValid(obj) and not obj:HasObserver(ply) then
            return false, "player not observing object"
        end
    end

    return true, ""
end

--- internal: queues an operation
--- @param operation goldfish.actor.Operation
function goldfish.actor.QueueOperation(operation)
    if CLIENT then
        local status, message = goldfish.actor.ClientCanPerform(ply, operation)
        if not status then error(message) end
    end

    goldfish.actor.queue[#goldfish.actor.queue + 1] = operation
end
