--- @enum goldfish.config.OptionType
goldfish.config.OptionType = {
    NUMBER = 0,
    STRING = 1,
    BOOLEAN = 2,
    VECTOR = 3,
    ANGLES = 4,
    COLOR = 5
}

--- gets the goldfish.config.OptionType of a value
--- @param value any
--- @return goldfish.config.OptionType? type nil if not found
function goldfish.config.GetOptionType(value)
    assert(value ~= nil, "cannot get the option type of a nil value")
    if isnumber(value) then
        return goldfish.config.OptionType.NUMBER
    elseif isstring(value) then
        return goldfish.config.OptionType.STRING
    elseif isbool(value) then
        return goldfish.config.OptionType.BOOLEAN
    elseif isvector(value) then
        return goldfish.config.OptionType.VECTOR
    elseif isangle(value) then
        return goldfish.config.OptionType.ANGLES
    elseif IsColor(value) then
        return goldfish.config.OptionType.COLOR
    end

    return nil
end
