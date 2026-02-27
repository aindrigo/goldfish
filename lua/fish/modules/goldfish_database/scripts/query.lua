--- @enum goldfish.database.QueryType
goldfish.database.QueryType = {
    SELECT = 0,
    INSERT = 1,
    UPDATE = 2
}

--- @enum goldfish.database.QueryState
goldfish.database.QueryState = {
    BUILDING = 0,
    SUBMITTED = 1,
    SUCCEEDED = 2,
    ERRORED = 3
}

--- @enum goldfish.database.CompareOperation
goldfish.database.CompareOperation = {
    AND = 0,
    OR = 1
}

--- @class goldfish.database.Query
local query = goldfish.class("goldfish.database.Query")

AccessorFunc(query, "_type", "Type", FORCE_NUMBER)
AccessorFunc(query, "_state", "State", FORCE_NUMBER)
AccessorFunc(query, "_result", "Result")

function query:Construct()
end

--- resets the query to be reusable
function query:Reset()
    self._callbacks = {}
    self._coroutines = {}
    
    self._selectors = nil
    self._values = nil
    
    self._pool = nil
end

--- @return table selectors
function query:GetSelectors()
    return self._selectors or {}
end

--- @param selectors table
function query:SetSelectors(selectors)
    assert(istable(selectors), "expected table, found " .. type(selectors))
    self._selectors = selectors
end

--- @return table values
function query:GetValues()
    return self._values or {}
end

--- @param values table
function query:SetValues(values)
    assert(istable(values), "expected table, found " .. type(selectors))
    self._values = values
end

--- @return goldfish.database.Pool? pool
function query:GetPool()
    return self._pool
end

--- @param pool goldfish.database.Pool
function query:SetPool(pool)
    self._pool = pool
end

--- adds a selector to this query
--- @param key string
--- @param value any
--- @param compareOperation goldfish.database.CompareOperation
function query:AddSelector(key, value, compareOperation)
    compareOperation = compareOperation or goldfish.database.CompareOperation.AND

    local pool = self:GetPool()

    local memberType = pool:GetMemberType(key)
    if memberType == goldfish.database.MemberType.SERIALIZED then
        value = serial.Serialize(value)
    end

    table.insert(self._selectors, { key, value, compareOperation })
end

--- adds a value to this query
--- @param key string
--- @param value any
function query:AddValue(key, value)
    local pool = self:GetPool()

    local memberType = pool:GetMemberType(key)
    if memberType == goldfish.database.MemberType.SERIALIZED then
        value = serial.Serialize(value)
    end

    table.insert(self._values, { key, value })
end

--- initializes this query to be a SELECT query
--- @param pool goldfish.database.Pool
function query:Select(pool)
    self:SetState(goldfish.database.QueryState.BUILDING)
    self:Reset()

    self:SetType(goldfish.database.QueryType.SELECT)
    self:SetPool(pool)
    self:SetSelectors({})
end

--- initializes this query to be an INSERT query
--- @param pool goldfish.database.Pool
function query:Insert(pool)
    self:SetState(goldfish.database.QueryState.BUILDING)
    self:Reset()

    self:SetType(goldfish.database.QueryType.INSERT)
    self:SetPool(pool)
    self:SetValues({})
end

--- initializes this query to be an UPDATE query
--- @param pool goldfish.database.Pool
function query:Update(pool)
    self:SetState(goldfish.database.QueryState.BUILDING)
    self:Reset()

    self:SetType(goldfish.database.QueryType.UPDATE)
    self:SetPool(pool)
    self:SetSelectors({})
    self:SetValues({})
end

--- submits this query to the driver
--- @param driver? any
function query:Submit(driver)
    driver = driver or goldfish.database.driver
    driver:SubmitQuery(self)

    self:SetState(goldfish.database.QueryState.SUBMITTED)
end

--- adds a callback to be triggered when this query is finished
--- @param callback function
function query:AddCallback(callback)
    self._callbacks = self._callbacks or {}
    table.insert(self._callbacks, callback)
end

--- used in coroutines to yield until the query is finished
--- @return boolean status
--- @return any result error message if errored
function query:Yield()
    assert(self:GetState() >= goldfish.database.QueryState.SUBMITTED, "cannot yield when not submitted")

    local co = coroutine.running()
    assert(co ~= nil, "not in a coroutine, cannot yield")

    local state = self:GetState()
    if state > goldfish.database.QueryState.SUBMITTED then
        return self:GetResult()
    end

    table.insert(self._coroutines, co)
    local status, result = coroutine.yield()
    return status, result
end

--- called by the driver when an error occurs
--- @param message string
function query:OnError(message)
    for _, callback in ipairs(self._callbacks) do
        callback(self, false, message) 
    end

    for _, co in ipairs(self._coroutines) do
        local status, result = coroutine.resume(co, false, message)
        if not status then
            ErrorNoHalt(result .. "\n")
        end
    end

    self:SetResult(message)
    self:SetState(goldfish.database.QueryState.ERRORED)
end

--- called by the driver when the query is successful
--- @param queryResult any
function query:OnFinish(queryResult)
    if istable(queryResult) then
        local pool = self:GetPool()
        for _, result in ipairs(queryResult) do
            for key, value in pairs(result) do
                local memberType = pool:GetMemberType(key)
                if memberType == goldfish.database.MemberType.SERIALIZED then
                    value = serial.Deserialize(value)
                    result[key] = value
                end            
            end
        end
    end

    self:SetResult(queryResult)

    for _, callback in ipairs(self._callbacks) do
        callback(self, true, queryResult) 
    end

    for _, co in ipairs(self._coroutines) do
        local status, result = coroutine.resume(co, true, queryResult)
        if not status then
            ErrorNoHalt(result .. "\n")
        end
    end

    self:SetState(goldfish.database.QueryState.SUCCEEDED)
end

goldfish.database.Query = query