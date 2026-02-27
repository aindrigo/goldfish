MODULE.Dependencies = { "goldfish_base", "serial" }

function MODULE:PreEnable()
    goldfish.sync = {}
    goldfish.sync.data = {}
end

function MODULE:PostDisable()
    goldfish.sync = nil
end