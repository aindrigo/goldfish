MODULE.Dependencies = { "goldfish_base" }
MODULE.Realm = fish.Realm.CLIENT

function MODULE:PreEnable()
    goldfish.ui = {}
    goldfish.ui.fonts = {}
end

function MODULE:PostDisable()
    goldfish.ui = nil
end