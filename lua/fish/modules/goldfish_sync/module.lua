MODULE.Dependencies = { "goldfish_base", "serial" }

function MODULE:PreEnable()
    goldfish.sync = {}
    goldfish.sync.data = {}
    goldfish.sync.connecting = {}
end

function MODULE:PostDisable()
    goldfish.sync = nil
end