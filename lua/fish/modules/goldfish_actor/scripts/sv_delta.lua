util.AddNetworkString("goldfish.actor.operations")

net.Receive("goldfish.actor.operations", function(_, ply)
    local operationCount = net.ReadUInt(16)
    local len = net.ReadUInt(16)
    local data = net.ReadData(len)

    local cursor = 1
    for _ = 1, operationCount do
        local operation, size = goldfish.actor.DeserializeOperation(data, cursor)
        cursor = cursor + size

        local status, message = goldfish.actor.ClientCanPerform(ply, operation)
        if not status then
            print("player " .. ply:SteamID() .. " tried to perform operation: " .. message)
        end

        goldfish.actor.PerformOperation(operation)
    end
end)

function HOOKS:Think()
    --- @class goldfish.actor.PlayerUpdateData
    --- @field operationCount number
    --- @field stream string
    --- @field changedObservers table<string, boolean>

    --- @type table<goldfish.actor.PlayerUpdateData>
    local playerData = {}

    for id, state in pairs(goldfish.actor.states) do
        local ply = Player(id)
        if not IsValid(ply) then continue end

        for name, objects in pairs(goldfish.actor.objects) do
            for index, object in pairs(objects) do
                local data = playerData[ply]
                if not data then
                    data = {}
                    data.operationCount = 0
                    data.stream = ""
                    data.changedObservers = {}
                    playerData[ply] = data
                end

                local key = goldfish.actor.ToString(name, index)
                if object:HasObserver(ply) and not state.observing[key] then
                    data.stream = data.stream ..
                        goldfish.actor.SerializeOperation(goldfish.actor.BuildOperation(
                            goldfish.actor.OperationType.ObjectCreate, {}, name, index,
                            object:GetVariables()))

                    data.operationCount = data.operationCount + 1

                    state.observing[key] = true
                    data.changedObservers[key] = true
                elseif not object:HasObserver(ply) and state.observing[key] then
                    data.stream = data.stream ..
                        goldfish.actor.SerializeOperation(goldfish.actor.BuildOperation(
                            goldfish.actor.OperationType.ObjectDestroy, {}, name, index))
                    data.operationCount = data.operationCount + 1

                    state.observing[key] = nil
                    data.changedObservers[key] = true
                end

                continue
            end
        end
    end

    local queue = goldfish.actor.OptimizeOperations(goldfish.actor.queue)
    goldfish.actor.queue = {}

    if queue[1] ~= nil then
        for _, operation in ipairs(queue) do
            for _, ply in ipairs(operation.observers) do
                if not IsValid(ply) then continue end

                local state = goldfish.actor.states[ply:UserID()]
                if not istable(state) then continue end

                local data = playerData[ply]
                if not data then
                    data = {}
                    data.operationCount = 0
                    data.stream = ""
                    data.changedObservers = {}

                    playerData[ply] = data
                end

                local key = goldfish.actor.ToString(operation.objectName, operation.objectIndex)
                if data.changedObservers[key] then continue end

                data.stream = data.stream .. goldfish.actor.SerializeOperation(operation)
                data.operationCount = data.operationCount + 1
            end
        end
    end

    for ply, data in pairs(playerData) do
        if data.operationCount < 1 then continue end
        net.Start("goldfish.actor.operations")
        net.WriteUInt(data.operationCount, 16)

        local buf = data.stream
        local len = #buf

        net.WriteUInt(len, 16)
        net.WriteData(buf, len)
        net.Send(ply)
    end
end

function HOOKS:Goldfish_Sync_OnPlayerReady(ply)
    local state = {}
    state.observing = {}

    goldfish.actor.states[ply:UserID()] = state
end

function HOOKS:PlayerDisconnected(ply)
    goldfish.actor.states[ply:UserID()] = nil
end

--- server-only, internal: optimizes operation list
--- @param operations table<goldfish.actor.Operation>
--- @return table<goldfish.actor.Operation>
function goldfish.actor.OptimizeOperations(operations)
    if operations[1] == nil then return operations end

    local newOperations = {}
    local objectCreations = {}

    -- Iter 1: check for objects that are created or deleted
    for _, operation in ipairs(operations) do
        local key = goldfish.actor.ToString(operation.objectName, operation.objectIndex)
        if operation.type == goldfish.actor.OperationType.ObjectCreate then
            objectCreations[key] = true
        elseif operation.type == goldfish.actor.OperationType.ObjectDestroy then
            objectCreations[key] = false
        end
    end


    local objectInsertIndices = {}
    -- Iter 2: insert object creations/destructions
    for _, operation in ipairs(operations) do
        local key = goldfish.actor.ToString(operation.objectName, operation.objectIndex)
        if not objectCreations[key] then
            continue
        end

        if operation.type == goldfish.actor.OperationType.ObjectCreate or operation.type == goldfish.actor.OperationType.ObjectDestroy then
            objectInsertIndices[key] = table.insert(newOperations, operation)
        end
    end

    -- Iter 3: insert the rest
    for _, operation in ipairs(operations) do
        local key = goldfish.actor.ToString(operation.objectName, operation.objectIndex)
        if objectCreations[key] == false then
            continue
        end

        if operation.type == goldfish.actor.OperationType.VariableSet or operation.type == goldfish.actor.OperationType.VariableReset then
            local objectInsertIndex = objectInsertIndices[key]
            if objectInsertIndex ~= nil then
                local objectInsert = newOperations[objectInsertIndex]
                objectInsert.variables[operation.variableName] = operation.value
            else
                table.insert(newOperations, operation)
            end
        elseif operation.type ~= goldfish.actor.OperationType.ObjectCreate and operation.type ~= goldfish.actor.OperationType.ObjectDestroy then
            table.insert(newOperations, operation)
        end
    end

    return newOperations
end
