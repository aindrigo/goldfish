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
