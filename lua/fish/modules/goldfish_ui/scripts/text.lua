--- gets or creates a font
--- @param properties table see surface.CreateFont
--- @return string fontId
function goldfish.ui.Font(properties)
    properties.weight = properties.weight or 800
    if properties.antialias == nil then
        properties.antialias = true
    end

    local id = ""
    for _, value in SortedPairs(properties) do
        id = id .. tostring(value) .. ";"
    end

    id = string.TrimRight(id, ";")

    if goldfish.ui.fonts[id] then
        return id
    end

    properties.shadow = false

    goldfish.ui.fonts[id] = properties
    surface.CreateFont(id, properties)

    local flags = properties.flags or 0
    if istable(flags) then
        local flagList = flags
        flags = 0

        for _, flag in ipairs(flagList) do
            flags = bit.bor(flags, flag)
        end
    end

    properties.flags = flags

    if bit.band(flags, goldfish.ui.FontFlag.Shadow) == goldfish.ui.FontFlag.Shadow then
        local oldBlurSize = properties.blursize

        properties.blursize = properties.shadowsize or 4
        surface.CreateFont(id .. "-shadow", properties)

        properties.blursize = oldBlurSize
    end

    if bit.band(flags, goldfish.ui.FontFlag.Glow) == goldfish.ui.FontFlag.Glow then
        local oldBlurSize = properties.blursize

        properties.blursize = properties.glowsize or 16
        surface.CreateFont(id .. "-glow", properties)

        properties.blursize = oldBlurSize
    end

    return id
end

--- @param text string
--- @param x number
--- @param y number
--- @param font string see goldfish.ui.Font
--- @param alignmentX? number
--- @param alignmentY? number
--- @param color? Color
--- @return number text width
--- @return number text height
function goldfish.ui.DrawText(text, x, y, font, alignmentX, alignmentY, color)
    local fontProperties = goldfish.ui.fonts[font]
    assert(istable(fontProperties), "no such font " .. font)
    alignmentX = alignmentX or TEXT_ALIGN_LEFT
    alignmentY = alignmentY or TEXT_ALIGN_TOP

    surface.SetFont(font)
    local textSizeW, textSizeH = surface.GetTextSize(text)
    if alignmentX == TEXT_ALIGN_CENTER then
        x = x - textSizeW / 2
    elseif alignmentX == TEXT_ALIGN_RIGHT then
        x = x - textSizeW
    end

    if alignmentY == TEXT_ALIGN_BOTTOM then
        y = y - textSizeH
    elseif alignmentY == TEXT_ALIGN_CENTER then
        y = y - (textSizeH / 2)
    end

    if bit.band(fontProperties.flags, goldfish.ui.FontFlag.Shadow) == goldfish.ui.FontFlag.Shadow then
        local shadowX = x + 2
        local shadowY = y + 2
        surface.SetFont(font .. "-shadow")
        surface.SetTextPos(shadowX, shadowY)
        surface.SetTextColor(fontProperties.shadowcolor or goldfish.ui.textShadowColor)
        surface.DrawText(text)
    end

    if bit.band(fontProperties.flags, goldfish.ui.FontFlag.Glow) == goldfish.ui.FontFlag.Glow then
        surface.SetFont(font .. "-glow")
        surface.SetTextPos(x, y)
        surface.SetTextColor(color or color_white)
        surface.DrawText(text)
    end

    surface.SetFont(font)
    surface.SetTextColor(color or color_white)
    surface.SetTextPos(x, y)
    surface.DrawText(text)

    return textSizeW, textSizeH
end
