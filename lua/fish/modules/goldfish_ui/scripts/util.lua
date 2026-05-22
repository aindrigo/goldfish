--- interpolates 2 colors
--- @param t number
--- @param a Color
--- @param b Color
--- @return Color result
function goldfish.ui.LerpColor(t, a, b)
    return Color(Lerp(t, a.r, b.r), Lerp(t, a.g, b.g), Lerp(t, a.b, b.b), Lerp(t, a.a, b.a))
end

--- @param w number width
--- @param referenceWidth? number defaults to 640
--- @return number scaled width
function goldfish.ui.ScreenScaleW(w, referenceWidth, screenWidth)
    if screenWidth == nil then
        screenWidth = ScrH()
    end

    return w * (screenWidth / (referenceWidth or 640))
end

--- @param h number height
--- @param referenceHeight? number defaults to 480
--- @param screenHeight? number defaults to ScrH()
--- @return number scaled height
function goldfish.ui.ScreenScaleH(h, referenceHeight, screenHeight)
    if screenHeight == nil then
        screenHeight = ScrH()
    end

    return h * (ScrH() / (referenceHeight or 480))
end

--- @param w number width
--- @param h number height
--- @param referenceWidth? number defaults to 640
--- @param referenceHeight? number defaults to 480
--- @return number scaled width
--- @return number scaled height
function goldfish.ui.ScreenScale(w, h, referenceWidth, referenceHeight)
    return goldfish.ui.ScreenScaleW(w, referenceWidth), goldfish.ui.ScreenScaleH(h, referenceHeight)
end

--- @param size number
--- @param referenceSize? number defaults to 480
--- @return number scaled size
function goldfish.ui.FontScale(size, referenceSize)
    return goldfish.ui.ScreenScaleH(size, referenceSize)
end

--- @param text number
--- @param fontName string
--- @return number text width
--- @return number text height
function goldfish.ui.TextSize(text, fontName)
    surface.SetFont(fontName)
    local tw, th = surface.GetTextSize(text)
    return tw, th
end
