MODULE.Dependencies = { "goldfish_base", "goldfish_class", "serial" }
MODULE.Realm = fish.Realm.SERVER

function MODULE:PreEnable()
    goldfish.database = {}
end

function MODULE:PostEnable()
    goldfish.database.driver = goldfish.database.driver or goldfish.database.drivers.SQLite()
end

function MODULE:PreDisable()
    if goldfish.database.driver ~= nil then
        goldfish.database.driver:Shutdown()
    end

    goldfish.database.Query.static:Deregister()
    goldfish.database.Pool.static:Deregister()
    goldfish.database.drivers.SQLite.static:Deregister()
end

function MODULE:PostDisable()
    goldfish.database = nil
end