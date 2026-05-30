local actor_base = goldfish.actor.actor_base

--- server-only, internal: builds an operation
--- @param operation goldfish.actor.OperationType
--- @return goldfish.actor.Operation
function actor_base:BuildOperation(operation, ...)
    return goldfish.actor.BuildOperation(operation, self:GetActorName(), self:GetActorIndex(), nil, ...)
end

--- server-only, internal: adds operation to queue
--- @param operation goldfish.actor.OperationType
function actor_base:QueueOperation(operation, ...)
    goldfish.actor.QueueOperation(self:BuildOperation(operation, ...))
end

function actor_base:Trigger(name, ...)
    self:QueueOperation(goldfish.actor.OperationType.RemoteProcedureCall, name, { ... })
end

function actor_base:On(eventName, eventID, callback)
    self._rpcEvents = self._rpcEvents or {}
    local events = self._rpcEvents[eventName]
    if not events then
        events = {}
        self._rpcEvents[eventName] = events
    end

    events[eventID] = callback
end

function actor_base:_PerformRPC(name, parameters)
    local events = self._rpcEvents
    if not istable(events) then return end

    local list = events[name]
    if not list then return end

    for _, callback in pairs(list) do
        callback(self, unpack(parameters))
    end
end
