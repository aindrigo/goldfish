MODULE.Dependencies = { "goldfish_base", "goldfish_class", "serial" }

function MODULE:PreEnable()
    goldfish.config = {}
    goldfish.config.options = {}
end

function MODULE:PreDisable()
    goldfish.config.Save()
end

function MODULE:PostDisable()
    goldfish.config.Option.static:Deregister()
    goldfish.config = nil
end