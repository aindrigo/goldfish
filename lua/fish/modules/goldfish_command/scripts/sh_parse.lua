
--- @param text string full command text
function goldfish.command.GetTokensAndFlags( text )
    local command
    local flags = {}
    local tokens = {}
    local skip = 0
    local inString = false
    local escapeNext = false
    local working_token = ""

    for i = 1, #text do
        if i <= skip then continue end
        local escape = escapeNext
        escapeNext = false

        local char = text[i]

        if char == "\"" and not escape then
            if inString then
                tokens[#tokens + 1] = working_token
                working_token = ""
            else
                inString = true
            end
        elseif char == "\\" and not escape then
            escapeNext = true
        elseif inString then
            working_token = working_token..char
        elseif char == "-" and not escape then
            local flagsStart = text:sub(i) .. " "
            local textFlags = flagsStart:match( "%b- " ):sub( 2, -2 )
            local newFlags = string.Explode( "", textFlags )
            for f = 1, #newFlags do
                flags[newFlags[f]] = true
            end

            skip = i + #textFlags + 1
        elseif char == " " and working_token ~= "" and not escape then
            -- end current token
            tokens[#tokens + 1] = working_token
            working_token = ""
        else
            -- discard extra whitespace
            if char == " " and working_token == "" and not escape then
                continue
            end

            working_token = working_token..char
        end
    end

    if working_token ~= "" then
        tokens[#tokens + 1] = working_token
    end

    command = ( tokens[1] ):lower()
    table.remove( tokens, 1 )



    return command, flags, tokens
end


--- @param commandName string
--- @return string
function goldfish.command.GetRealCommandName( commandName )
    local command = goldfish.command.list[commandName]
    if command then return commandName end

    local aliasDef = goldfish.command.aliases[commandName]
    return aliasDef
end


--- @param commandName string
--- @param flags table
--- @param tokens table
--- @return string? error code
--- @return string? problem token/flag
function goldfish.command.VerifyTokensAndFlags( commandName, flags, tokens )
    local command = goldfish.command.list[commandName]

    local aliasDef = goldfish.command.aliases[commandName]
    if (not command) and aliasDef then
        command = goldfish.command.list[aliasDef]
        commandName = command.id
    end

    if not command then
        return "bad command", commandName
    end

    if command.flags then
        for flag in pairs( flags ) do
            if not command.flags[flag] then
                return "bad flag", flag
            end
        end
    end

    local params = command.params
    for i = 1, #params do
        local param = params[i]
        local token = tokens[i]

        if not token then
            if param.required then
                return "missing argument", param.name
            else
                break
            end
        end

        if param.type == goldfish.command.Type.NUMBER then
            token = tonumber( token )
            if not token then
                return "bad argument", token
            end
            tokens[i] = token
        elseif param.type == goldfish.command.Type.PLAYER then
            local ply = fish.utilities.FindPlayer( token )
            if not IsValid( ply ) then
                return "bad argument", token
            end
            tokens[i] = ply
        end
    end
end

--- @param command string
--- @param tokens table
--- @param flags table
--- @param text string
--- @param client Player
--- @return string
function goldfish.command.Run( command, tokens, flags, text, client )
    assert( command.Run, "missing command.Run" )
    return command:Run( tokens, flags, text, client ) or ""
end
