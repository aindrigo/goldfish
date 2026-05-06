MODULE.Dependencies = { "goldfish_base", "goldfish_sync" } -- goldfish_sync for ready event

function MODULE:PreEnable()
    goldfish.actor = {}
    goldfish.actor.registry = {}
    goldfish.actor.objects = {}
    goldfish.actor.queue = {}
    goldfish.actor.states = {}
end

function MODULE:PostDisable()
    goldfish.actor = nil
end
