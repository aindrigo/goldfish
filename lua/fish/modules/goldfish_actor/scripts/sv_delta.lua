util.AddNetworkString("goldfish.actor.operations")


function HOOKS:Think()
    --- @class goldfish.actor.PlayerUpdateData
    --- @field operationCount number
    --- @field buffer serial.Buffer
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
                    data.buffer = serial.Buffer()
                    data.changedObservers = {}
                    playerData[ply] = data
                end

                local key = goldfish.actor.ToString(name, index)
                if object:HasObserver(ply) and not state.observing[key] then
                    goldfish.actor.SerializeOperation(data.buffer, goldfish.actor.BuildOperation(goldfish.actor.OperationType.ObjectCreate, {}, name, index, object:GetVariables()))
                    data.operationCount = data.operationCount + 1

                    state.observing[key] = true
                    data.changedObservers[key] = true
                elseif not object:HasObserver(ply) and state.observing[key] then
                    goldfish.actor.SerializeOperation(data.buffer, goldfish.actor.BuildOperation(goldfish.actor.OperationType.ObjectDestroy, {}, name, index))
                    data.operationCount = data.operationCount + 1

                    state.observing[key] = nil
                    data.changedObservers[key] = true
                end
                
                continue
            end
        end
    end

    for _, operation in ipairs(goldfish.actor.queue) do
        for _, ply in ipairs(operation.observers) do
            if not IsValid(ply) then continue end

            local state = goldfish.actor.states[ply:UserID()]
            if not istable(state) then continue end


            local data = playerData[ply]
            if not data then
                data = {}
                data.operationCount = 0
                data.buffer = serial.Buffer()
                data.changedObservers = {}

                playerData[ply] = data
            end

            local key = goldfish.actor.ToString(operation.objectName, operation.objectIndex)
            if data.changedObservers[key] then continue end

            goldfish.actor.SerializeOperation(data.buffer, operation)
            data.operationCount = data.operationCount + 1
        end
    end

    goldfish.actor.queue = {}

    for ply, data in pairs(playerData) do
        if data.operationCount < 1 then continue end
        net.Start("goldfish.actor.operations")
        net.WriteUInt(data.operationCount, 32)

        local buf = data.buffer:GetData()
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

--- server-only, internal: builds an operation
--- @param operation goldfish.actor.Operation
function goldfish.actor.QueueOperation(operation)
    local isVariableOp = operation.type == goldfish.actor.OperationType.VariableReset or operation.type == goldfish.actor.OperationType.VariableSet
    for i = 1, #goldfish.actor.queue do
        local op = goldfish.actor.queue[i]
        local isThisVariableOp = (op.type == goldfish.actor.OperationType.VariableReset or op.type == goldfish.actor.OperationType.VariableSet)
        if op.objectName == operation.objectName and op.objectIndex == operation.objectIndex then
            if isThisVariableOp and isVariableOp then
                if variableName == operation.variableName then
                    table.remove(goldfish.actor.queue, i)
                    i = i - 1
                end
            elseif op.type == goldfish.actor.OperationType.ObjectCreate and isVariableOp then
                if operation == goldfish.actor.OperationType.VariableReset then
                    op.variables[operation.variableName] = nil
                elseif operation == goldfish.actor.OperationType.VariableSet then
                    op.variables[operation.variableName] = value
                end

                return
            elseif (operation.type == goldfish.actor.OperationType.ObjectCreate or operation.type == goldfish.actor.OperationType.ObjectDestroy) and isThisVariableOp then
                table.remove(goldfish.actor.queue, i)
                i = i - 1
            elseif operation.type == goldfish.actor.OperationType.ObjectDestroy and op.type == goldfish.actor.OperationType.ObjectCreate then
                table.remove(goldfish.actor.queue, i)
                i = i - 1
                return
            end
        end
    end

    table.insert(goldfish.actor.queue, operation)
end
