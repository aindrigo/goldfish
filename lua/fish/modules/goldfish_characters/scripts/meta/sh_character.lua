--- @class goldfish.characters.Character
local character = goldfish.characters.Character

AccessorFunc(character, "_id", "Id", FORCE_NUMBER)
AccessorFunc(character, "_ownerSteamID", "OwnerSteamID", FORCE_STRING)
AccessorFunc(character, "_name", "Name", FORCE_STRING)

function character:Construct(id, steamId, name, data)
    assert(data == nil or istable(data), "invalid data type " .. type(data))
    self:SetId(id)
    self:SetOwnerSteamID(steamId)
    self:SetName(name)
    self:SetData(data or {})

    goldfish.characters.data[id] = self

    if SERVER then
        self._observers = {}
    end
end

--- builds a character from a row table
--- @param tbl table row
--- @return goldfish.characters.Character character
function character.static:From(tbl)
    return character.static:New(tbl.id, tbl.steamid, tbl.name, tbl.data)
end

--- @param key any|table if value is nil then the data is overriden to this 
--- @param value? any
function character:SetData(key, value)
    if istable(key) then
        self._data = key
        return
    end

    self._data[key] = value
end

--- @param key? any
--- @return any|table data if key is nil then returns the whole data table
function character:GetData(key)
    if key == nil then
        return self._data
    end

    return self._data[key]
end

--- internal: builds the character into a database row
--- @return table row
function character:Build()
    return {
        id = self:GetId(),
        steamid = self:GetOwnerSteamID(),
        data = self._data
    }
end

--- @return boolean
function character:IsValid()
    return istable(goldfish.characters.data[self:GetId()])
end

--- internal: removes the character, invalidating it
function character:_Remove()
    goldfish.characters.data[self:GetId()] = nil
end