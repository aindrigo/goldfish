MODULE.Dependencies = { "goldfish_base" }
MODULE.Realm = fish.Realm.CLIENT

function MODULE:PreEnable()
    goldfish.ui = {}
    goldfish.ui.textShadowColor = Color(10, 10, 10, 200)
    goldfish.ui.blurMaterial = Material("pp/bokehblur")

    goldfish.ui.fonts = {}
    goldfish.ui.scissorStack = {}
    goldfish.ui.scissorStackIndex = 0
end

function MODULE:PostDisable()
    goldfish.ui = nil
end