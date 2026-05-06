util.AddNetworkString("goldfish.actor.operations")

function HOOKS:Think()
    --- 1: op count, 2: buffer, 3: if its a full reconcile
    local playerData = {}

    for id, state in pairs(goldfish.actor.states) do
        local ply = Player(id)
        if not IsValid(ply) then continue end

        if not state.valid then
            for name, objects in pairs(goldfish.actor.objects) do
                for index, object in pairs(objects) do
                    if not object:HasObserver(ply) then continue end

                    playerData[ply] = playerData[ply] or { 0, serial.Buffer(), true }
                    local data = playerData[ply]
                    local buf = data[2]
        
                    goldfish.actor.SerializeOperation(buf, goldfish.actor.BuildOperation(goldfish.actor.OperationType.ObjectCreate, {}, name, index, object:GetVariables()))
                    data[1] = data[1] + 1

                    continue
                end
            end

            state.valid = true
            continue
        end
    end

    for _, operation in ipairs(goldfish.actor.queue) do
        for _, ply in ipairs(operation.observers) do
            if not IsValid(ply) then continue end

            local state = goldfish.actor.states[ply:UserID()]
            if not istable(state) then continue end

            playerData[ply] = playerData[ply] or { 0, serial.Buffer(), false }
            local data = playerData[ply]

            if data[3] then continue end
            local buf = data[2]

            goldfish.actor.SerializeOperation(buf, operation)
            data[1] = data[1] + 1
        end
    end

    goldfish.actor.queue = {}

    for ply, data in pairs(playerData) do
        net.Start("goldfish.actor.operations")
        net.WriteUInt(data[1], 32)

        local buf = data[2]:GetData()
        local len = #buf

        net.WriteUInt(len, 16)
        net.WriteData(buf, len)
        net.Send(ply)
    end
end

function HOOKS:Goldfish_Sync_OnPlayerReady(ply)
    local state = {}
    state.valid = false

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
            end
        end
    end

    table.insert(goldfish.actor.queue, operation)
end
