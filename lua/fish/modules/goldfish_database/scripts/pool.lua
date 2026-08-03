--- @class goldfish.database.Pool
local pool = goldfish.class("goldfish.database.Pool")

AccessorFunc(pool, "_name", "Name", FORCE_STRING)

function pool:Construct(name)
    self:SetName(name)
    self._members = {}
    self._memberMap = {}
end

--- @param name string
--- @return goldfish.database.MemberType
function pool:GetMemberType(name)
    local id = self._memberMap[name]
    if not isnumber(id) then
        debug.Trace()
    end

    assert(isnumber(id), "no such value " .. name)

    local data = self._members[id]
    return data.type
end

--- adds a member to this pool
--- @param data table
function pool:AddMember(data)
    assert(isstring(data.name), "expected string for .name, found " .. type(data.name))

    if data.primary == nil then
        data.primary = self._members[1] == nil
    end

    if data.autoIncrement == nil then
        data.autoIncrement = false
    end

    if data.nullable == nil then
        data.nullable = true
    end

    local newIndex = #self._members + 1
    self._members[newIndex] = data
    self._memberMap[data.name] = newIndex
end

--- @return table members
function pool:GetMembers()
    return self._members or {}
end

--- registers this pool with the driver
--- @param driver? any
function pool:Register(driver)
    assert(self._members[1] ~= nil, "cannot have no keys in a pool")

    driver = driver or goldfish.database.driver
    driver:RegisterPool(self)
end

goldfish.database.Pool = pool
