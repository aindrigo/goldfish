--- @class goldfish.script.Context
--- @field environment table
--- @field data table

--- @class goldfish.script.Instance
--- @field sources table<string>
--- @field realm fish.Realm
--- @field state goldfish.script.State
--- @field extensions table<string>
--- @field context goldfish.script.Context?


--- @param validate boolean
--- @return table<string>
function goldfish.script.ReadSources(validate)
    local length = net.ReadUInt(32)
    local buffer = net.ReadData(length)
    local sources = serial.DeserializeSingle(buffer, serial.Profile.PERFORMANCE)

    if validate then
        if not istable(sources) then
            return {}
        end

        local i = 1
        for index, source in pairs(sources) do
            if index ~= i or not isstring(source) then
                return {}
            end
            i = i + 1
        end
    end

    return sources
end

--- @param sources table<string>
function goldfish.script.WriteSources(sources)
    local buffer = serial.SerializeSingle(sources, serial.Profile.PERFORMANCE, serial.Type.ARRAY)
    local length = #buffer
    net.WriteUInt(length, 32)
    net.WriteData(buffer, length)
end

--- @param validate boolean
--- @return table<string>
function goldfish.script.ReadExtensions(validate)
    local length = net.ReadUInt(32)
    local buffer = net.ReadData(length)
    local extensions = serial.DeserializeSingle(buffer, serial.Profile.PERFORMANCE)

    if validate then
        if not istable(extensions) then
            return {}
        end

        local i = 1
        for index, name in pairs(extensions) do
            if index ~= i or not isstring(name) then
                return {}
            end
            i = i + 1
        end
    end

    return extensions
end

--- @param extensions table<string>
function goldfish.script.WriteExtensions(extensions)
    local buffer = serial.SerializeSingle(extensions, serial.Profile.PERFORMANCE, serial.Type.ARRAY)
    local length = #buffer
    net.WriteUInt(length, 32)
    net.WriteData(buffer, length)
end



--- @param validate boolean
--- @return goldfish.script.Instance, number
function goldfish.script.Read(validate)
    local id = net.ReadUInt(16)
    local realm = net.ReadUInt(8)
    local state = net.ReadUInt(8)
    local sources = goldfish.script.ReadSources(validate)
    local extensions = goldfish.script.ReadExtensions(validate)
    local context = goldfish.script._CreateContext(extensions)

    return {
        name = name,
        sources = sources,
        realm = realm,
        state = state,
        extensions = extensions,
        context = context
    }, id
end

--- @return goldfish.script.Context?
function goldfish.script.CurrentContext()
    return goldfish.script.stack:Top()
end

--- @private
--- @param source string
--- @param context goldfish.script.Context
--- @return string? only if errored
function goldfish.script._Load(source, context)
    local func = CompileString(source, "goldfish.script", false)
    if isstring(func) then
        --- @diagnostic disable-next-line
        return func
    end

    setfenv(func, context.environment)
    local ok = xpcall(func, function(msg)
        --- TODO: fucking handle this
        print("Error loading script: "..msg)
    end)

    if not ok then
        return
    end
end

--- @private
--- @param extensions? table<string>
--- @return goldfish.script.Context
function goldfish.script._CreateContext(extensions)
    local libraries = {}
    if extensions then
        for _, name in ipairs(extensions) do
            local ext = goldfish.script.extensions[name]
            if not ext then continue end

            for name, lib in pairs(ext.libraries) do
                libraries[name] = lib
            end
        end
    end

    local data = {}

    local env = {}
    env._G = env
    env.SERVER = SERVER
    env.CLIENT = CLIENT
    env.SCRIPT = data
    env.print = print
    setmetatable(env, {
        __index = function(env, key)
            local orig = rawget(env, key)
            if orig ~= nil then return orig end

            local lib = libraries[key]
            if lib then
                return lib
            end
        end
    })
    return {
        environment = env,
        data = data
    }
end

--- @private
--- @param instance goldfish.script.Instance
--- @param func function
--- @vararg any params
--- @return any result
function goldfish.script._Run(instance, func, ...)
    setfenv(func, instance.context.environment)

    if goldfish.script.stack:Size() >= 1023 then
        --- TODO: stack overflow
        return
    end

    goldfish.script.stack:Push(instance.context)
    local value = func(...)
    goldfish.script.stack:Pop(1)

    return value
end

--- @private
--- @param instance goldfish.script.Instance
function goldfish.script._Instantiate(instance)
    if not instance.context then return end

    local SCRIPT = instance.context.data
    if SCRIPT.Instantiate then
        goldfish.script._Run(instance, SCRIPT.Instantiate, SCRIPT)
    end
end

--- @private
--- @param instance goldfish.script.Instance
function goldfish.script._Destroy(instance)
    if not instance.context then return end

    local SCRIPT = instance.context.data
    if SCRIPT.Destroy then
        goldfish.script._Run(instance, SCRIPT.Destroy, SCRIPT)
    end
end
