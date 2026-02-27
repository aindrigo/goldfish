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

    net.Send(target)
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
