goldfish.sync.DefineVariable("goldfish.characters.current", "number")

--- @class goldfish.characters.VarData
--- @field id string
--- @field name string
--- @field isPrivate? boolean

goldfish.characters.vars = {}
goldfish.characters.varBits = 2


--- @param varData goldfish.characters.VarData
--- @param noAccessors? boolean
--- @return number
function goldfish.characters.DefineVar( varData, noAccessors )
    assert( isstring(varData.id), "string expected as varData.id" )
    assert( isstring(varData.name), "string expected as varData.name" )

    goldfish.characters.vars[varData.id] = varData
    varData.index = table.Count(goldfish.characters.vars)

    if varData.index > bit.lshift( 1, goldfish.characters.varBits ) then
        goldfish.characters.varBits = goldfish.characters.varBits + 1
    end

    if not noAccessors then
        local name = varData.name
        local character = goldfish.characters.Character

        character.vars = character.vars or {}
        character["Set"..name] = function( self, value )
            self.vars[varData.id] = value

            if SERVER then
                self:SyncVar( varData.id )
            end
        end

        character["Get"..name] = function( self, default )
            return self:GetVar( varData.id, default )
        end
    end

    return index
end
