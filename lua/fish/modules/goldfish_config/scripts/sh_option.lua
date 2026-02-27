--- @class goldfish.config.Option
local option = goldfish.class("goldfish.config.Option")

AccessorFunc(option, "_data", "Data")

--- @class goldfish.config.OptionData
--- @field namespace string
--- @field id string
--- @field category string
--- @field displayName string
--- @field realm number
--- @field type goldfish.config.OptionType
--- @field flags? goldfish.config.OptionFlags|table<goldfish.config.OptionType>
--- @field defaultValue? any

--- @param data goldfish.config.OptionData data
function option:Construct(data)
    assert(isstring(data.namespace), "expected string for data.namespace, got " .. type(data.namespace))
    assert(isstring(data.id), "expected string for data.id, got " .. type(data.id))
    assert(isstring(data.category), "expected string for data.category, got " .. type(data.category))
    assert(isstring(data.displayName), "expected string for data.displayName, got " .. type(data.displayName))
    assert(isnumber(data.realm), "expected number for data.realm, got " .. type(data.realm))
    assert(isnumber(data.type), "expected number for data.type, got " .. type(data.type))

    if istable(data.flags) then
        data.flags = bit.bor(table.unpack(data.flags))
    elseif data.flags ~= nil then
        assert(isnumber(data.flags), "expected number or table for data.flags, got " .. type(data.flags))
    else
        data.flags = 0
    end

    self:SetData(data)
end

function option:GetNamespace()
    return self:GetData()["namespace"]
end

function option:GetId()
    return self:GetData()["id"]
end

function option:GetCategory()
    return self:GetData()["category"]
end

function option:GetRealm()
    return self:GetData()["realm"]
end

function option:GetType()
    return self:GetData()["type"]
end

function option:GetFlags()
    return self:GetData()["flags"]
end

function option:GetDefaultValue()
    return self:GetData()["defaultValue"]
end

function option:GetValue(ply)
    local value = nil

    if SERVER and self:GetRealm() == fish.Realm.CLIENT then
        self._values = self._values or {}
        value = self._values[ply:UserID()]
    else
        value = self._value
    end

    if value == nil then
        return self:GetDefaultValue()
    end

    return value
end

function option:SetValue(value)
    self:_SetValue(value, nil)
    self:Sync()
end

--- internal: sets the value of this option. call Sync afterwards
--- @param value any
--- @param ply? Player ignored on client
function option:_SetValue(value, ply)
    local currentValue = self:GetValue()
    if value ~= nil then
        assert(goldfish.config.GetOptionType(value) == self:GetType(), "mismatching type")
    end

    hook.Run("Goldfish_Config_OnOptionChange", self, currentValue, value, ply)

    if SERVER and IsValid(ply) then
        self._values = self._values or {}
        self._values[ply:UserID()] = value
    else
        self._value = value
    end
end

--- puts this option in the registry
function option:Register()
    local namespace = self:GetNamespace()
    local id = self:GetId()

    goldfish.config.options[namespace] = goldfish.config.options[namespace] or {}
    goldfish.config.options[namespace][id] = self
end

--- removes this option from the registry
function option:Deregister()
    local namespace = self:GetNamespace()
    local id = self:GetId()

    goldfish.config.options[namespace] = goldfish.config.options[namespace] or {}
    goldfish.config.options[namespace][id] = nil
end

--- internal: writes this object to the network stack
function option:_NetWrite()
    net.WriteString(self:GetNamespace())
    net.WriteString(self:GetId())
    
    local data = serial.Serialize(self:GetValue(), self:GetType())
    local dataLength = #data

    net.WriteUInt(dataLength, 16)
    net.WriteData(data, dataLength)
end

--- syncs this option's value to a target
--- @param target? Player|CRecipientFilter|table ignored on client
function option:Sync(target)
    net.Start("goldfish.config.Sync")
    net.WriteUInt(1, 16)
    self:_NetWrite()
    if CLIENT then
        net.SendToServer()
    else
        target = target or player.GetAll()
        net.Send(target)
    end
end

--- @param flag goldfish.config.OptionFlags
--- @return boolean hasFlag
function option:HasFlag(flag)
    return bit.band(self:GetFlags(), flag) == flag
end

--- internal: reads from the network stack and updates the value
--- @param sender? Player ignored on client
function option.static:_NetRead(sender)
    local namespace = net.ReadString()
    local id = net.ReadString()

    local options = goldfish.config.options[namespace]
    if not istable(options) then return end

    local option = options[id]
    if not istable(option) or not option:HasFlag(goldfish.config.OptionFlags.REPLICATE) then return end

    local realm = option:GetRealm()
    if SERVER and realm ~= fish.Realm.CLIENT then return end

    local length = net.ReadUInt(16)
    local data = net.ReadData(length)

    local value = serial.Deserialize(data, option:GetType())
    if value == nil then return end
    
    option:_SetValue(value, sender)
end
goldfish.config.Option = option