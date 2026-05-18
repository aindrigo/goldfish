MODULE.Dependencies = { "goldfish_base", "goldfish_class", "serial" }

function MODULE:PreEnable()
    goldfish.config = {}
    goldfish.config.options = {}
    goldfish.config.serialSettings = serial.Profile.PERSISTENCE
end

function MODULE:PreDisable()
    goldfish.config.Save()
end

function MODULE:PostDisable()
    goldfish.config.Option.static:Deregister()
    goldfish.config = nil
end
