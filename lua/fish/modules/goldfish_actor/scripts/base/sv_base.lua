local actor_base = goldfish.actor.actor_base

AccessorFunc(actor_base, "m_bSpawned", "Spawned", FORCE_BOOL)

--- server-only, internal: builds an operation
--- @param operation goldfish.actor.OperationType
--- @param observers table<Player>
--- @return goldfish.actor.Operation
function actor_base:BuildOperation(operation, observers, ...)
    return goldfish.actor.BuildOperation(operation, self:GetActorName(), self:GetActorIndex(), observers, ...)
end

--- server-only, internal: adds operation to queue
--- @param operation goldfish.actor.OperationType
--- @param observers table<Player>
function actor_base:QueueOperation(operation, observers, ...)
    goldfish.actor.QueueOperation(self:BuildOperation(operation, observers, ...))
end

--- server-only: sets a variable's data
--- @param id string
--- @param value any
function actor_base:VariableSet(id, value)
    self.m_tVariables = self.m_tVariables or {}

    local var = self.m_tVariables[id]
    assert(istable(var), "no such variable " .. id)

    self:_VariableSet(id, value)
    if not self:GetSpawned() then return end

    local observers = self:GetObservers()
    for i = 1, #observers do
        if not self:ObserverCanSee(observers[i], id) then
            table.remove(observers, i)
            i = i - 1
        end
    end

    if value ~= nil then
        assert(goldfish.sync.GetType(value) == var.type, "mismatching type for variable " .. id )
        self:QueueOperation(goldfish.actor.OperationType.VariableSet, observers, id, value)
    else
        self:QueueOperation(goldfish.actor.OperationType.VariableReset, observers, id)
    end

end

--- server-only: get observers, defined to be re-implemented if necessary
--- @return table<Player> observers
function actor_base:GetObservers()
    return player.GetAll()
end

--- server-only: checks if this actor has this observer, defined to be re-implemented if necessary
--- @param observer Player
--- @return boolean
function actor_base:HasObserver(observer)
    return true
end

--- server-only: checks if an observer can see a variable, defined to be re-implemented if necessary
--- @param observer Player
--- @param id string
--- @return boolean
function actor_base:ObserverCanSee(observer, id)
    return true
end

--- server-only: destroys this object
function actor_base:Destroy()
    self:_Destroy()
    self:QueueOperation(goldfish.actor.OperationType.ObjectDestroy, self:GetObservers())
end

--- server-only: spawns this object
function actor_base:Spawn()
    assert(not self:GetSpawned(), "cannot spawn twice")
    self:SetSpawned(true)

    self:QueueOperation(goldfish.actor.OperationType.ObjectCreate, self:GetObservers(), self:GetVariables())
    if isfunction(self.OnSpawn) then
        self:OnSpawn()
    end
end

function actor_base:Trigger(name, ...)
    self:QueueOperation(goldfish.actor.OperationType.RemoteProcedureCall, self:GetObservers(), name, { ... })
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

function actor_base:_PerformRPC(ply, name, parameters)
    local events = self._rpcEvents
    if not istable(events) then return end

    local list = events[name]
    if not list then return end

    for _, callback in pairs(list) do
        callback(self, ply, unpack(parameters))
    end
end
