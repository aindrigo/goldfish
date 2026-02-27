--- defines a class in the registry
--- @param id string
function goldfish.class.Define(id)
    if istable(goldfish.class.registry[id]) then
        return goldfish.class.registry[id]
    end

    local prototype = {}
    prototype.static = {}
    prototype.metatable = {
        __index = function(_, key)
            return goldfish.class.registry[id][key]
        end,
        MetaName = id
    }

    function prototype.static:New(...)
        local prototype = goldfish.class.registry[id]

        local instance = {}
        setmetatable(instance, prototype.metatable)

        instance:Construct(...)
        return instance
    end

    function prototype.static:Deregister()
        goldfish.class.registry[id] = nil
    end

    function prototype:Construct()
        
    end

    setmetatable(prototype, {
        __call = function(prototype, ...)
            return prototype.static:New(...)
        end
    })

    goldfish.class.registry[id] = prototype
    return prototype
end

--- gets a class table
--- @param id string
--- @return table class
function goldfish.class.Get(id)
    return goldfish.class.registry[id]
end

--- constructs the type with a given name
--- @param id string
--- @vararg any arguments passed to New()
function goldfish.class.New(id, ...)
    local class = goldfish.class.Get(id)
    assert(class, "no such class " .. id)

    return class(...)
end

setmetatable(goldfish.class, {
    __call = function(_, ...)
        return goldfish.class.Define(...)
    end
})
