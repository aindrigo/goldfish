util.AddNetworkString( "goldfish.command.run" )

function MODULE.Hooks:PlayerSay( client, text )
    if text[1] ~= "/" then return end

    local commandName, flags, tokens = goldfish.command.GetTokensAndFlags( text )
    local issue, problemToken = goldfish.command.VerifyTokensAndFlags( commandName, flags, tokens )

    if issue then
        client:ChatPrint( ("%s: %s - %s"):format( commandName, issue, problemToken ) )
        return
    end

    local command = goldfish.command.list[commandName]
    local output = goldfish.command.Run( command, tokens, flags, text, client )

    if istable( output )then
        for i = 1, #output do
            client:ChatPrint( output[i] )
        end
    elseif isstring( output ) then
        client:ChatPrint( output )
    end
end
