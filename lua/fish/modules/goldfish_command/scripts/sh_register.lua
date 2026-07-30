--- @enum goldfish.command.Type
goldfish.command.Type = {
    NUMBER = 1,
    PLAYER = 2,

}

--- @enum fish.Realm

--- @class goldfish.command.parameter
--- @field name string
--- @field summary? string
--- @field required? boolean defaults to false
--- @field type goldfish.command.Type

--- @class goldfish.command.data
--- @field name string
--- @field summary? string
--- @field Run fun( command: string, tokens: table, flags: table, text: string, ply: Player ): string
--- @field adminOnly? boolean
--- @field superAdminOnly? boolean
--- @field realm? fish.Realm defaults to fish.Realm.SERVER
--- @field params? goldfish.command.parameter[]
--- @field aliases? string[]

--- @param data goldfish.command.data
function goldfish.command.Register( data )
    assert( data.name, "no command name" )
    assert( data.Run, "no command run" )

    data.realm = data.realm or fish.Realm.SERVER
    data.params = data.params or {}

    goldfish.command.list[data.name] = data
end
