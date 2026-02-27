function fish.meta.Player:SetCharacter(id)
    local character = goldfish.characters.Get(id)
    assert(IsValid(character), "invalid character")

    character:SetPublic(true)
    character:Sync()

    self:SetSyncVar("goldfish.characters.current", id)
end