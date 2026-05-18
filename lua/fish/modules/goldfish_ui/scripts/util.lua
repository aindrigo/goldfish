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
function goldfish.ui.ScreenScaleW(w, referenceWidth)
    return w * (ScrW() / (referenceWidth or 640))
end

--- @param h number height
--- @param referenceHeight? number defaults to 480
--- @return number scaled height
function goldfish.ui.ScreenScaleH(h, referenceHeight)
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
--- @param referenceSize? number defaults to ScrH() / 480
--- @return number scaled width
--- @return number scaled height
function goldfish.ui.FontScale(size, referenceSize)
    if not isnumber(referenceSize) then
        referenceSize = ScrH() / 480
    end

    return size * referenceSize
end
