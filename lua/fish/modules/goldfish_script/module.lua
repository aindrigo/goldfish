MODULE.Dependencies = { "goldfish_base", "serial" }

function MODULE:PreEnable()
    goldfish.script = {}

    --- @type table<goldfish.script.Instance>
    goldfish.script.data = {}

    goldfish.script.dead = {}

    --- @type table<goldfish.script.Extension>
    goldfish.script.extensions = {}

    --- @type Stack
    goldfish.script.stack = util.Stack()

    --- @enum goldfish.script.State
    goldfish.script.State = {
        INACTIVE = 0,
        ACTIVE = 1,
        PAUSED = 2
    }
end

function MODULE:PostDisable()
    goldfish.script = nil
end
