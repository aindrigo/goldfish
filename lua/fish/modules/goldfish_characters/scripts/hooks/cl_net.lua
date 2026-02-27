net.Receive("goldfish.characters.Sync", function()
    local id = net.ReadUInt(32)

    local steamId = net.ReadString()
    local name = net.ReadString()

    local dataLength = net.ReadUInt(16)
    local data = serial.Deserialize(net.ReadData(dataLength))

    local character = goldfish.characters.Character(id, steamId, name, data)
    goldfish.characters.data[id] = character
end)

net.Receive("goldfish.characters.Remove", function()
    local id = net.ReadUInt(32)
    local character = goldfish.characters.data[id]

    if not IsValid(character) then return end
    character:_Remove()
end)