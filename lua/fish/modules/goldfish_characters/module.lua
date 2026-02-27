MODULE.Dependencies = { "goldfish_base", "goldfish_class", "goldfish_database", "goldfish_sync", "goldfish_config" }
function MODULE:PreEnable()
    goldfish.characters = {}
    goldfish.characters.data = {}
    goldfish.characters.config = {}
    goldfish.characters.playerCharacters = {}

    if SERVER then
        goldfish.characters.playerLoadQueue = {}
    end

    --- @class goldfish.characters.Character
    goldfish.characters.Character = goldfish.class("goldfish.characters.Character")
end

function MODULE:PostEnable()
    if SERVER then
        goldfish.characters.databasePool:Register()
    end

    goldfish.characters.config.maxCharactersPerPlayer:Register()
    goldfish.config.LoadNamespace("goldfish.characters")
end

function MODULE:PreDisable()
    goldfish.config.SaveNamespace("goldfish.characters")

    goldfish.characters.Character.static:Deregister()
    goldfish.characters.config.maxCharactersPerPlayer:Deregister()
end

function MODULE:PostDisable()
    goldfish.characters = nil
end