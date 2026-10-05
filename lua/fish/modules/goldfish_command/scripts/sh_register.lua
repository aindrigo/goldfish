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
--- @field name string | string[]
--- @field summary? string
--- @field Run fun( command: string, tokens: table, flags: table, text: string, ply: Player ): string?
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

    if isstring( data.name ) then
        --- @diagnostic disable-next-line
        local name = data.name:lower()
        data.id = name
        goldfish.command.list[name] = data
    elseif istable( data.name ) then
        local realName = data.name[1]:lower()
        data.id = realName
        goldfish.command.list[realName] = data

        for i = 2, #data.name do
            goldfish.command.aliases[data.name[i]:lower()] = realName
        end
    end

end
