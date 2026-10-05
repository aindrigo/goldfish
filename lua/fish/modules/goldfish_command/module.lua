MODULE.Dependencies = { "goldfish_base" }

function MODULE:PreEnable()
    goldfish.command = {}
    goldfish.command.list = {}
    goldfish.command.aliases = {}
end

function MODULE:PostDisable()
    goldfish.command = nil
end
