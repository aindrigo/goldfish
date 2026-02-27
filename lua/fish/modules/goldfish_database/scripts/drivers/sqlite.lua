goldfish.database.drivers = goldfish.database.drivers or {}

local sqliteDriver = goldfish.class("goldfish.database.drivers.SQLite")
function sqliteDriver:Construct()
    self._queries = {}
end

function sqliteDriver:Shutdown()
    self:Flush()
end

--- internal: builds the SQL selectors used in SELECT & UPDATE
--- @param selectors table
--- @return string selectorString
--- @return table selectorValues
function sqliteDriver:_BuildSelectors(selectors)
    local selectorCount = #selectors
    local selectorString = ""
    local selectorValues = {}

    for index, selector in ipairs(selectors) do
        local key, value, compareOperation = selector[1], selector[2], selector[3]
        local compareOpString = ""

        if compareOperation == goldfish.database.CompareOperation.AND then
            compareOpString = "AND"
        elseif compareOperation == goldfish.database.CompareOperation.OR then
            compareOpString = "OR"
        end

        selectorString = selectorString .. key .. " = ?"
        table.insert(selectorValues, value)

        if index < selectorCount then
            selectorString = selectorString .. string.format(" %s ", compareOpString)
        end
    end

    return selectorString, selectorValues
end

--- internal: transforms a query into a SQL query
--- @param query goldfish.database.Query
--- @return string queryString SQL query
--- @return table queryValues SQL values, passed to sql.QueryTyped
function sqliteDriver:_BuildQuery(query)
    local pool = query:GetPool()
    local queryType = query:GetType()
    local queryString = ""
    local queryValues = {}

    if queryType == goldfish.database.QueryType.SELECT then
        local selectors = query:GetSelectors()
        queryString = "SELECT * FROM " .. pool:GetName()
        if selectors[1] ~= nil then
            queryString = queryString .. " WHERE "

            local selectorString, selectorValues = self:_BuildSelectors(selectors)
            queryString = queryString .. selectorString

            table.Add(queryValues, selectorValues)
        end
    elseif queryType == goldfish.database.QueryType.INSERT then
        local values = query:GetValues()
        local count = #values

        queryString = "INSERT INTO " .. pool:GetName() .. " ("
        local valuesString = "VALUES ("
        for index, valueData in ipairs(values) do
            local key, value = valueData[1], valueData[2]
            table.insert(queryValues, value)

            queryString = queryString .. key
            valuesString = valuesString .. "?"

            if index < count then
                queryString = queryString .. ", "
                valuesString = valuesString .. ", "
            end
        end

        queryString = queryString .. ")"
        valuesString = valuesString .. ")"

        queryString = queryString .. " " .. valuesString
    elseif queryType == goldfish.database.QueryType.UPDATE then
        local values = query:GetValues()
        local valueCount = #values

        local selectors = query:GetSelectors()
        queryString = "UPDATE " .. pool:GetName()
        local valuesString = "SET"

        for index, valueData in ipairs(values) do
            local key, value = valueData[1], valueData[2]
            valuesString = valuesString .. " " .. key .. " = ?"

            table.insert(queryValues, value)

            if index < valueCount then
                valuesString = valuesString .. ", "
            end
        end

        if selectors[1] ~= nil then
            queryString = queryString .. " WHERE "
            local selectorString, selectorValues = self:_BuildSelectors(selectors)

            queryString = queryString .. selectorString
            table.Add(queryValues, selectorValues)
        end
    end

    return queryString, queryValues
end

--- submits the given query to this driver
--- @param query goldfish.database.Query
function sqliteDriver:SubmitQuery(query)
    table.insert(self._queries, query)
end

--- internal: flushes the query queue
function sqliteDriver:Flush()
    if self._queries[1] == nil then return end

    sql.Begin()
    for _, query in ipairs(self._queries) do
        local queryString, queryValues = self:_BuildQuery(query)

        local result = sql.QueryTyped(queryString, unpack(queryValues or {}))

        if result == false then
            query:OnError(queryString .. "\n" .. sql.LastError())
        else
            local pool = query:GetPool()
            local queryType = query:GetType()
            if queryType == goldfish.database.QueryType.INSERT then
                -- Ugly hack, but GMod's SQLite version is from around 2018 so we can't use RETURNING
                result = sql.QueryTyped("SELECT * FROM " .. pool:GetName() .. " WHERE rowid = last_insert_rowid()")
                if result == false then
                    error(sql.LastError())
                end
            end
            xpcall(query.OnFinish, function(message) query:OnError(queryString .. ": " .. message) end, query, result)
        end
    end
    sql.Commit()

    self._queries = {}
end

--- calls Flush()
function sqliteDriver:Think()
    self:Flush()
end

--- converts a goldfish.database.MemberType to a SQL type
--- @param member table
--- @return string typeName
function sqliteDriver:MemberToString(member)
    local typeName = nil
    if member.type == goldfish.database.MemberType.STRING then
        typeName = "TEXT"
    elseif member.type == goldfish.database.MemberType.INTEGER then
        typeName = "INTEGER"
    elseif member.type == goldfish.database.MemberType.BIG_INTEGER then
        typeName = "BIGINT"
    elseif member.type == goldfish.database.MemberType.FLOAT then
        typeName = "FLOAT"
    elseif member.type == goldfish.database.MemberType.DOUBLE then
        typeName = "DOUBLE"
    elseif member.type == goldfish.database.MemberType.SERIALIZED then
        typeName = "BLOB"
    else
        error("unknown type")
    end

    if member.primary then
        typeName = typeName .. " PRIMARY KEY"
    end

    if member.autoIncrement then
        typeName = typeName .. " AUTOINCREMENT"
    end

    if not member.nullable then
        typeName = typeName .. " NOT NULL"
    end

    return typeName
end

--- registers a pool to this driver
--- @param pool goldfish.database.Pool
function sqliteDriver:RegisterPool(pool)
    local sqlQuery = "CREATE TABLE IF NOT EXISTS " .. pool:GetName() .. " ("

    local members = pool:GetMembers()
    local count = #members

    for index, data in ipairs(members) do
        sqlQuery = sqlQuery .. data.name .. " " .. self:MemberToString(data)

        if index < count then
            sqlQuery = sqlQuery .. ", "
        else
            sqlQuery = sqlQuery .. ")"
        end
    end

    local result = sql.Query(sqlQuery)
    if result == false then
        error(result)
    end
end

--- @class goldfish.database.drivers.SQLite
goldfish.database.drivers.SQLite = sqliteDriver