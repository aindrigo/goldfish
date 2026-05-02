--- @return table<number, goldfish.characters.Character>
function fish.meta.Player:GetCharacters()
    local characterIds = goldfish.characters.playerCharacters[self:SteamID()]
    if not istable(characterIds) then return {} end

    local characters = {}
    for _, id in ipairs(characterIds) do
        local character = goldfish.characters.Get(id)
        if not IsValid(character) then continue end

        table.insert(characters, character)
    end

    return characters
end

--- @return goldfish.characters.Character?
function fish.meta.Player:GetCharacter()
    local characterId = self:GetSyncVar("goldfish.characters.current")
    if not isnumber(characterId) then return nil end

    return goldfish.characters.Get(characterId)
end
