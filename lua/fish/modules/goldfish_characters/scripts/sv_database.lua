goldfish.characters.databasePool = goldfish.database.Pool("goldfish_characters")

goldfish.characters.databasePool:AddMember({
    name = "id",
    type = goldfish.database.MemberType.INTEGER,
    primary = true,
    autoincrement = true,
    nullable = false
})

goldfish.characters.databasePool:AddMember({
    name = "steamid",
    type = goldfish.database.MemberType.STRING,
    primary = false,
    autoincrement = false,
    nullable = false
})

goldfish.characters.databasePool:AddMember({
    name = "name",
    type = goldfish.database.MemberType.STRING,
    primary = false,
    autoincrement = false,
    nullable = true
})

goldfish.characters.databasePool:AddMember({
    name = "data",
    type = goldfish.database.MemberType.SERIALIZED,
    primary = false,
    autoincrement = false,
    nullable = false
})

goldfish.characters.databasePool:Register()

--- internal: loads characters from a list of rows
--- @param rows table<table>
--- @return table<goldfish.characters.Character> characters
function goldfish.characters._LoadCharacters(rows)
    local characters = {}
    for _, row in ipairs(rows) do
        table.insert(characters, goldfish.characters.Character.static:From(row))
    end

    return characters
end

--- loads a character by its id
--- @async
--- @param id integer
--- @return goldfish.characters.Character? character
function goldfish.characters.LoadCharacter(id)
    local query = goldfish.database.Query()
    query:Select(goldfish.database.Pool)
    query:AddSelector("id", id)
    query:Submit()

    local status, result = query:Yield()
    if not status then error(result) end
    assert(istable(result), "received non-table value from SELECT query")

    local row = result[1]
    if not istable(row) then return nil end

    return goldfish.characters.Character.static:From(row)
end

--- loads a character by its id
--- @async
--- @param steamId string SteamID
--- @return table<goldfish.characters.Character> characters
function goldfish.characters.LoadCharactersBySteamID(steamId)
    local query = goldfish.database.Query()
    query:Select(goldfish.characters.databasePool)
    query:AddSelector("steamid", steamId)
    query:Submit()

    local status, result = query:Yield()
    if not status then error(result) end

    return goldfish.characters._LoadCharacters(result)
end

--- creates a character and returns its id
--- @async
--- @param steamId string
--- @param name string
--- @param data? table
--- @return number id
function goldfish.characters.Insert(steamId, name, data)
    data = data or {}

    local query = goldfish.database.Query()
    query:Insert(goldfish.characters.databasePool)
    query:AddValue("steamid", steamId)
    query:AddValue("name", name)
    query:AddValue("data", data)

    query:Submit()
    local status, result = query:Yield()

    if not status then
        error(result)
    end

    assert(istable(result) and istable(result[1]), "value returned not a table or empty")
    return result[1].id
end