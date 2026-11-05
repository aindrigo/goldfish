function HOOKS:Think()
    for _, instance in pairs(goldfish.script.data) do
        if instance.state ~= goldfish.script.State.ACTIVE then continue end

        local isRealm = instance.realm == fish.Realm.SHARED or (SERVER and fish.Realm.SERVER) or (CLIENT and fish.Realm.CLIENT)
        if not isRealm then continue end

        -- TODO: hooks, etc
    end
end
