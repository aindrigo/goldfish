local actor_base = goldfish.actor.actor_base

AccessorFunc(actor_base, "m_sActorName", "ActorName", FORCE_STRING)
AccessorFunc(actor_base, "m_iActorIndex", "ActorIndex", FORCE_NUMBER)

function actor_base.metatable:__tostring()
    return goldfish.actor.ToString(self:GetActorName(), self:GetActorIndex())
end

function actor_base:IsValid()
    local index = self:GetActorIndex()
    local name = self:GetActorName()

    return isstring(name) and isnumber(index) and istable(goldfish.actor.objects[name][index])
end

--- @param id string
--- @param type goldfish.sync.VariableType
--- @param default? any
function actor_base:VariableDefine(id, type, default)
    self.m_tVariables = self.m_tVariables or {}
    self.m_tVariables[id] = { ["type"] = type, ["default"] = default }
end

--- @param variableId string
--- @param identifier string
--- @param callback fun(string, any?)
function actor_base:VariableChangeCallbackAdd(variableId, identifier, callback)
    self.m_tVariableCallbacks = self.m_tVariableCallbacks or {}
    local callbacks = self.m_tVariableCallbacks[variableId]
    if not istable(callbacks) then
        callbacks = {}
        self.m_tVariableCallbacks[variableId] = callbacks
    end

    callbacks[identifier] = callback
end

--- @param variableId string
--- @param identifier string
function actor_base:VariableChangeCallbackRemove(variableId, identifier, callback)
    self.m_tVariableCallbacks = self.m_tVariableCallbacks or {}
    local callbacks = self.m_tVariableCallbacks[variableId]
    assert(istable(callbacks), "no callbacks for " .. variableId)

    callbacks[identifier] = nil
    if table.Count(callbacks) < 1 then
        self.m_tVariableCallbacks[variableId] = nil

        if table.Count(m_tVariableCallbacks) < 1 then
            self.m_tVariableCallbacks = nil
        end
    end
end
--- server-only: sets a variable's data
--- @param id string
--- @param default any
--- @return any value
function actor_base:VariableGet(id, default)
    self.m_tVariables = self.m_tVariables or {}
    self.m_tVariableData = self.m_tVariableData or {}

    local var = self.m_tVariables[id]
    assert(istable(var), "no such variable " .. id)

    local value = self.m_tVariableData[id]
    if value == nil then
        if var.default ~= nil then
            return var.default
        end

        return default
    end

    return value
end

--- internal: set the value of a variable
--- @param id string
--- @param value any
function actor_base:_VariableSet(id, value)
    self.m_tVariableData = self.m_tVariableData or {}

    self.m_tVariableData[id] = value

    if istable(self.m_tVariableCallbacks) then
        local callbacks = self.m_tVariableCallbacks[id]
        if istable(callbacks) then
            for _, cb in pairs(callbacks) do
                cb(id, value)
            end
        end
    end
end

--- gets all variables of this object
--- @return table<string, any> variables
function actor_base:GetVariables()
    return self.m_tVariableData or {}
end

--- internal: sets all variables of this object
--- @param variables table<string, any>
function actor_base:SetVariables(variables)
    for id, value in pairs(variables) do
        self:_VariableSet(id, value)
    end
end

--- internal: destroys this object
function actor_base:_Destroy()
    if isfunction(self.OnDestroy) then
        self:OnDestroy()
    end

    goldfish.actor.objects[self:GetActorName()][self:GetActorIndex()] = nil
end
