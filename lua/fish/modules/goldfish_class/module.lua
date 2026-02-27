MODULE.Dependencies = { "goldfish_base" }
MODULE.Realm = fish.Realm.SHARED

function MODULE:PreEnable()
    goldfish.class = {}
    goldfish.class.registry = {}
end

function MODULE:PostDisable()
    goldfish.class = nil
end