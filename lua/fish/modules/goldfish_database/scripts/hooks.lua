function HOOKS:Think()
    if goldfish.database.driver == nil then return end

    if isfunction(goldfish.database.driver.Think) then
        goldfish.database.driver:Think()
    end
end