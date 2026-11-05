--- @class goldfish.script.Extension
--- @field name string
--- @field libraries table<string, table>

--- @param extension goldfish.script.Extension
function goldfish.script.DefineExtension(extension)
    goldfish.script.extensions[extension.name] = extension
end
