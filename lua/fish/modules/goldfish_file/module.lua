MODULE.Dependencies = { "goldfish_base", "serial" }
MODULE.Realm = fish.Realm.SHARED

function MODULE:PreEnable()
    goldfish.file = {}
    goldfish.file.handlers = {}
end

function MODULE:PostEnable()
end

function MODULE:PostReload()
end

function MODULE:PreDisable()
end

function MODULE:PostDisable()
    goldfish.file = nil
end
