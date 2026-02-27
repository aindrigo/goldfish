goldfish.ui.textShadowColor = Color(40, 40, 40, 200)

--- gets or creates a font
--- @param fontName string
--- @param fontSize number
--- @param fontWeight? number
--- @return string fontId
function goldfish.ui.Font(fontName, fontSize, fontWeight)
    fontWeight = fontWeight or 800
    
    local id = fontName .. "-" .. tostring(fontSize) .. "-" .. tostring(fontWeight)
    if goldfish.ui.fonts[id] then
        return id
    end

    goldfish.ui.fonts[id] = true
    surface.CreateFont(id, {
        font = fontName,
        size = fontSize,
        weight = fontWeight,
        antialias = true,
        shadow = false
    })

    surface.CreateFont(id .. "-shadow", {
        font = fontName,
        size = fontSize,
        weight = fontWeight,
        antialias = true,
        shadow = false,
        blursize = 4
    })

    return id
end

function goldfish.ui.DrawText(text, x, y, font, alignmentX, alignmentY, color)
    assert(goldfish.ui.fonts[font], "no such font " .. id)
    alignmentX = alignmentX or TEXT_ALIGN_LEFT
    alignmentY = alignmentY or TEXT_ALIGN_TOP

    surface.SetFont(font)
    local textSizeX, textSizeY = surface.GetTextSize(text)
    if alignmentX == TEXT_ALIGN_CENTER then
        x = x - textSizeX / 2
    elseif alignmentX == TEXT_ALIGN_RIGHT then
        x = x - textSizeX
    end

    if alignmentY == TEXT_ALIGN_CENTER then
        y = y + textSizeY / 2
    elseif alignmentY == TEXT_ALIGN_BOTTOM then
        y = y + textSizeY
    end

    local shadowX = x + 4
    local shadowY = y + 4
    surface.SetFont(id .. "-shadow")
    surface.SetTextPos(shadowX, shadowY)
    surface.SetDrawColor(goldfish.ui.textShadowColor)
    surface.DrawText(text)

    surface.SetFont(id)
    surface.SetDrawColor(color)
    surface.SetTextPos(x, y)
    surface.DrawText(text)
end