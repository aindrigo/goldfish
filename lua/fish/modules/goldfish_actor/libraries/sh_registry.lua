--- defines an actor in the registry
--- @param name string
--- @param baseClass? string|boolean
function goldfish.actor.Define(name, baseClass)
    if istable(goldfish.actor.registry[name]) then
        return goldfish.actor.registry[name]
    end

    if baseClass == nil then
        baseClass = "actor_base"
    end

    local prototype = {}
    prototype.static = {}
    prototype.static.BaseClassName = baseClass

    prototype.metatable = {
        __index = function(_, key)
            local prototype = goldfish.actor.registry[name]
            if prototype[key] ~= nil then return prototype[key] end

            if isstring(prototype.static.BaseClassName) then
                local basePrototype = goldfish.actor.registry[prototype.static.BaseClassName]
                if istable(basePrototype) then
                    local value = basePrototype[key]
                    return value
                end
            end
        end,
        MetaName = name
    }

    function prototype.static:New(...)
        return goldfish.actor.Instantiate(name, ...)
    end

    function prototype.static:Get(id)
        return goldfish.actor.objects[name][id]
    end

    function prototype.static:Deregister()
        goldfish.actor.registry[name] = nil
        goldfish.actor.objects[name] = nil
    end

    function prototype:Construct() 
    end

    setmetatable(prototype, {
        __call = function(prototype, ...)
            local inst = prototype.static:Get(...)
            if IsValid(inst) then
                return inst
            end

            return prototype.static:New(...)
        end
    })

    goldfish.actor.registry[name] = prototype
    goldfish.actor.objects[name] = {}
    return prototype
end

--- gets an actor table
--- @param name string
--- @return table class
function goldfish.actor.GetDefinition(name)
    return goldfish.actor.registry[name]
end

--- generates an index for an actor type
--- @param name string
--- @return number id
function goldfish.actor.GenerateIndex(name)
    local objects = goldfish.actor.objects[name]
    if not istable(objects) then
        objects = {}
        goldfish.actor.objects[name] = objects

        return 1
    end

    local maxIndex = 1
    for i, _ in pairs(objects) do
        maxIndex = math.max(maxIndex, i)
    end

    for i = 1, maxIndex + 1 do
        if not istable(objects[i]) then
            return i
        end
    end

    error("wtf is going on")
end

--- instantiates an actor object
--- @param name string
--- @param id? number
--- @return table class
function goldfish.actor.Instantiate(name, id)
    local prototype = goldfish.actor.GetDefinition(name)
    assert(istable(prototype), "no such actor type " .. name)

    if not isnumber(id) then
        id = goldfish.actor.GenerateIndex(name)
    end

    local instance = {}
    setmetatable(instance, prototype.metatable)

    instance:SetActorName(name)
    instance:SetActorIndex(id)
    instance:Construct()

    goldfish.actor.objects[name][id] = instance
    return instance
end

--- @param name string
--- @param index number
--- @return string
function goldfish.actor.ToString(name, index)
    return string.format("%s %i", name, index)
end

setmetatable(goldfish.actor, {
    __call = function(_, ...)
        return goldfish.actor.Define(...)
    end
})

goldfish.actor.actor_base = goldfish.actor("actor_base", false)