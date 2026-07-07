--- @param path string
--- @return function?
function goldfish.file.GetReadHandler( path )
    local deserialize

    if path:EndsWith( ".dat" ) then
        deserialize = serial.Deserialize
    elseif path:EndsWith( ".json" ) then
        deserialize = util.JSONToTable
    end

    return deserialize
end

--- @param path string
--- @return function?
function goldfish.file.GetWriteHandler( path )
    local serialize

    if path:EndsWith( ".dat" ) then
        serialize = serial.Serialize
    elseif path:EndsWith( ".json" ) then
        serialize = util.TableToJSON
    end

    return serialize
end

--- @param path string
--- @param data any
function goldfish.file.Write( path, data )
    local serialize = goldfish.file.GetWriteHandler( path )

    if not serialize then
        ErrorNoHaltWithTrace( "Couldn't save: invalid file extension for "..path.."\n" )
        return
    end

    local sData = serialize( data )
    file.write( path, sData )
end

--- @param path string
--- @return any|nil
function goldfish.file.Read( path )
    local deserialize = goldfish.file.GetReadHandler( path )
    if not deserialize then return end

    local fileData = file.Read( path, "DATA" )
    if not fileData then return nil end

    local data = deserialize( fileData )
    return data
end

--- @param module table
--- @param name string
--- @return string
function goldfish.file.Name( module, name )
    return "goldfish_saving/"..module.Path.."/"..name
end
