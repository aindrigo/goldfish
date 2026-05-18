MODULE.Dependencies = { "goldfish_base", "goldfish_sync", "serial" } -- goldfish_sync for ready event

function MODULE:PreEnable()
    goldfish.actor = {}
    goldfish.actor.registry = {}
    goldfish.actor.objects = {}
    goldfish.actor.queue = {}
    goldfish.actor.states = {}

    --- @enum goldfish.actor.OperationType
    goldfish.actor.OperationType = {
        VariableSet = 0,
        VariableReset = 1,

        ObjectCreate = 2,
        ObjectDestroy = 3,

        RemoteProcedureCall = 4
    }

    goldfish.actor.serialSettings = serial.Profile.PERSISTENCE
end

function MODULE:PostDisable()
    goldfish.actor = nil
end
