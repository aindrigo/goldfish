function fish.meta.Player:GetCharacters()
    local characterIds = goldfish.characters.playerCharacters[self:UserID()]
    if not istable(characterIds) then return nil end

    local characters = {}
    for _, id in ipairs(characterIds) do
        local character = goldfish.characters.Get(id)
        if not IsValid(character) then continue end

        table.insert(characters, character)
    end

    return characters
end

function fish.meta.Player:GetCharacter()
    local characterId = self:GetSyncVar("goldfish.characters.current")
    if not isnumber(characterId) then return nil end

    return goldfish.characters.Get(characterId)
end