goldfish.characters.config.maxCharactersPerPlayer = goldfish.config.Option({
    namespace = "goldfish.characters",
    category = "Goldfish - Characters",
    id = "maxCharactersPerPlayer",
    displayName = "Max Characters Per Player",

    min = 0,
    max = 50,

    realm = fish.Realm.SERVER,
    type = goldfish.config.OptionType.NUMBER,
    defaultValue = 6,

    flags = goldfish.config.OptionFlags.REPLICATE
})

goldfish.characters.config.freezeWhenNoCharacter = goldfish.config.Option({
    namespace = "goldfish.characters",
    category = "Goldfish - Characters",
    id = "freezeWhenNoCharacter",
    displayName = "Freeze When No Character",

    realm = fish.Realm.SERVER,
    type = goldfish.config.OptionType.BOOLEAN,
    defaultValue = true
})
