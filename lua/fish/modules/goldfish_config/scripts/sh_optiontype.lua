--- @enum goldfish.config.OptionType
goldfish.config.OptionType = {
    NUMBER = serial.Types.NUMBER,
    STRING = serial.Types.STRING,
    BOOLEAN = serial.Types.BOOLEAN,
    VECTOR = serial.Types.VECTOR,
    ANGLES = serial.Types.ANGLES,
    COLOR = serial.Types.COLOR
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