net.Receive("goldfish.characters.Sync", function()
    local id = net.ReadUInt(32)

    local steamId = net.ReadString()
    local name = net.ReadString()

    local dataLength = net.ReadUInt(16)
    local data = serial.Deserialize(net.ReadData(dataLength))

    local varsLength = net.ReadUInt(16)
    local vars = serial.Deserialize(net.ReadData(varsLength))

    local character = goldfish.characters.Character(id, steamId, name, data)
    character.vars = vars
    goldfish.characters.data[id] = character
end)

net.Receive("goldfish.characters.Remove", function()
    local id = net.ReadUInt(32)
    local character = goldfish.characters.data[id]

    if not IsValid(character) then return end
    character:_Remove()
end)

net.Receive( "goldfish.characters.SyncVar", function( len )
    local characterId = net.ReadUInt( 32 )
    local id = net.ReadUInt( goldfish.characters.varBits )

    local binSize = len - (goldfish.characters.varBits + 32) * 8
    local value = serial.Deserialize( net.ReadData( binSize ) )

    local character = goldfish.characters.data[characterId]
    if not character then return end

    character:SetVar( id, value )
end )
