function fish.meta.Player:SetCharacter(id)
    local oldCharacter = self:GetCharacter()
    if oldCharacter then
        oldCharacter:Save()
    end

    local character = goldfish.characters.Get(id)
    assert( character ~= nil and IsValid(character), "invalid character" )

    character:Sync( self )
    self:SetSyncVar("goldfish.characters.current", id)

    hook.Run( "Goldfish_Characters_SetCharacter", self, character, oldCharacter )
    hook.Run( "Goldfish_Characters_PostSetCharacter", self, character, oldCharacter )
end
