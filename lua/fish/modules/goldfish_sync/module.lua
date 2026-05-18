MODULE.Dependencies = { "goldfish_base", "serial" }

function MODULE:PreEnable()
    goldfish.sync = {}
    goldfish.sync.data = {}
    goldfish.sync.connecting = {}

    goldfish.sync.serialSettings = serial.Profile.Performance

    --- @enum goldfish.sync.VariableType
    goldfish.sync.VariableType = {
        NUMBER = 0,
        BOOLEAN = 1,
        STRING = 2,
        TABLE = 3,
        VECTOR = 4,
        ANGLES = 5,
        COLOR = 6,
        ENTITY = 7
    }
end

function MODULE:PostDisable()
    goldfish.sync = nil
end
