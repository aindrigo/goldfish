local character = goldfish.characters.Character

AccessorFunc(character, "_public", "Public", FORCE_BOOL)

--- networks this character to a target or all observers
--- @param target? Player|CRecipientFilter|table
function character:Sync(target)
    if target == nil then
        target = self:GetObservers()
    end

    net.Start("goldfish.characters.Sync")

    net.WriteUInt(self:GetId(), 32)
    net.WriteString(self:GetOwnerSteamID())
    net.WriteString(self:GetName())

    local data = serial.Serialize(self:GetData())
    local dataLength = #data
    net.WriteUInt(dataLength, 16)
    net.WriteData(data, dataLength)

    local vars = serial.Serialize(self.vars)
    local varsLength = #vars

    net.WriteUInt(varsLength, 16)
    net.WriteData(vars, varsLength)

    net.Send(target)

    hook.Run( "Goldfish_Characters_Sync", target, self )
end

--- @return table observers
function character:GetObservers()
    if self:GetPublic() then
        return player.GetAll()
    end

    local observers = {}
    for _, observer in ipairs(self._observers) do
        if not IsValid(observer) then continue end
        table.insert(observers, observer)
    end

    self._observers = observers
    return observers
end

--- adds a player to the observer list
--- @param target Player
function character:AddObserver(target)
    if self:GetPublic() then return end

    table.insert(self._observers, target)
    self:Sync(target)
end

--- removes a player from the observer list
--- @param target Player
function character:RemoveObserver(target)
    if self:GetPublic() then return end

    if not table.RemoveByValue(self._observers, target) then return end

    net.Start("goldfish.characters.Remove")
    net.WriteUInt(self:GetId(), 32)
    net.Send(target)
end

--- unloads this character's data
function character:Remove()
    net.Start("goldfish.characters.Remove")
    net.WriteUInt(self:GetId(), 32)
    net.Send(self:GetObservers())

    self:_Remove()
end

function character:Delete()
    local query = goldfish.database.Query()
        query:Delete( goldfish.characters.databasePool )
        query:AddSelector( "id", self:GetId() )
    query:Submit()

    hook.Run( "Goldfish_Characters_Delete", self )
    self:Remove()
end

function character:Save()
    hook.Run( "Goldfish_Characters_Save", self )

    local query = goldfish.database.Query()
        query:Update( goldfish.characters.databasePool )
        query:AddSelector( "id", self:GetId() )
        query:AddValue( "name", self:GetName() )
        query:AddValue( "data", self:GetData() )
    query:Submit()
end


--- @param id string
function character:SyncVar( id )
    local data = goldfish.characters.vars[id]
    if not data then return end
    local receivers = (data.isPrivate and self:GetObservers()) or player.GetAll()
    local stream = serial.Serialize( self:GetVar( id ) )

    net.Start( "goldfish.characters.SyncVar" )
        net.WriteUInt( self:GetId(), 32 )
        net.WriteUInt( data.index, goldfish.characters.varBits )
        net.WriteData( stream, #stream )
    net.Send( receivers )
end
