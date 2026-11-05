--- @param instance goldfish.script.Instance
function goldfish.script.Write(id, instance)
    net.WriteUInt(id, 16)
    net.WriteUInt(instance.realm, 8)
    net.WriteUInt(instance.state, 8)

    goldfish.script.WriteSources(instance.sources)
    goldfish.script.WriteExtensions(instance.extensions)
end

--- @param sources table<string>|string
--- @param realm fish.Realm
--- @param extensions? table<string> {}
--- @param initialState? goldfish.script.State goldfish.script.State.ACTIVE
--- @return number id
function goldfish.script.Instantiate(sources, realm, extensions, initialState)
    local context

    if realm ~= fish.Realm.CLIENT then
        context = goldfish.script._CreateContext(extensions)

        if isstring(sources) then
            sources = { sources }
        end

        for _, source in ipairs(sources) do
            goldfish.script._Load(source, context)
        end
    end

    local instance = {
        sources = sources,
        realm = realm,
        state = initialState or goldfish.script.State.ACTIVE,
        extensions = extensions or {},
        context = context
    }

    local id = 1
    if goldfish.script.dead[1] ~= nil then
        id = goldfish.script.dead[1]
        table.remove(goldfish.script.dead, 1)
    elseif goldfish.script.data[1] ~= nil then
        id = table.Count(goldfish.script.data) + 1
    end

    goldfish.script.data[id] = instance

    if realm == fish.Realm.SHARED or realm == fish.Realm.CLIENT then
        net.Start("goldfish.script.Instantiate")
        goldfish.script.Write(id, instance)
        net.Broadcast()
    end

    goldfish.script._Instantiate(instance)

    return id
end

--- @param id number
function goldfish.script.Destroy(id)
    local instance = goldfish.script.data[id]
    goldfish.script.data[id] = nil
    table.insert(goldfish.script.dead, id)

    if instance.realm == fish.Realm.SHARED or instance.realm == fish.Realm.CLIENT then
        net.Start("goldfish.script.Destroy")
        net.WriteUInt(id, 16)
        net.Broadcast()
    end

    goldfish.script._Destroy(instance)
end


--- @param target Player|CRecipientFilter|table<Player>
function goldfish.script.FullUpdate(target)
    local scripts = {}
    local count = 0
    for id, instance in pairs(goldfish.script.data) do
        if instance.realm == fish.Realm.SERVER then continue end
        scripts[id] = instance
        count = count + 1
    end

    if count < 1 then return end
    net.Start("goldfish.script.FullUpdate")
    net.WriteUInt(count, 16)
    for id, instance in pairs(scripts) do
        goldfish.script.Write(id, instance)
    end
    net.Send(target)
end

--- @param id number
--- @param sources table<string>|string
function goldfish.script.UpdateSources(id, sources)
    local instance = goldfish.script.data[id]
    if realm ~= fish.realm.CLIENT then
        if isstring(sources) then
            goldfish.script._Load(sources, instance.context)
        else
            for _, source in ipairs(sources) do
                goldfish.script._Load(source, instance.context)
            end
        end
    end

    if realm == fish.Realm.SHARED or realm == fish.Realm.CLIENT then
        net.Start("goldfish.script.UpdateSources")
        net.WriteUInt(id, 16)
        goldfish.script.WriteSources(sources)
        net.Broadcast()
    end
end

--- @param id number
--- @param state goldfish.script.State
function goldfish.script.SetState(id, state)
    local instance = goldfish.script.data[id]
    instance.state = state

    if realm == fish.Realm.SHARED or realm == fish.Realm.CLIENT then
        net.Start("goldfish.script.SetState")
        net.WriteUInt(id, 16)
        net.WriteUInt(state, 8)
        net.Broadcast()
    end
end
