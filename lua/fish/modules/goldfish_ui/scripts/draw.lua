--- @param x number
--- @param y number
--- @param w number width
--- @param h number height
--- @param color? Color
function goldfish.ui.DrawRect(x, y, w, h, color)
    surface.SetDrawColor(color or color_white)
    surface.DrawRect(x, y, w, h)
end

--- @param x number
--- @param y number
--- @param w number width
--- @param h number height
--- @param thickness number
--- @param color? Color
function goldfish.ui.DrawRectOutline(x, y, w, h, thickness, color)
    surface.SetDrawColor(color or color_white)
    surface.DrawOutlinedRect(x, y, w, h, thickness)
end

--- @param x number
--- @param y number
--- @param w number
--- @param h number
--- @param intensity? number
--- @param distance? number
--- @param focus? number
function goldfish.ui.DrawBlur(x, y, w, h, intensity, distance, focus)
    goldfish.ui.PushScissor(x, y, x + w, y + h)
        intensity = intensity or 6
        distance = distance or 1
        focus = focus or 2

        local mat = goldfish.ui.blurMaterial

        render.UpdateScreenEffectTexture()
        mat:SetTexture("$BASETEXTURE", render.GetScreenEffectTexture())
    	mat:SetTexture("$DEPTHTEXTURE", render.GetResolvedFullFrameDepth())

    	mat:SetFloat("$size", intensity)
    	mat:SetFloat("$focus", distance)
    	mat:SetFloat("$focusradius", focus)

       	render.SetMaterial(mat)
       	render.DrawScreenQuad()
    goldfish.ui.PopScissor()
end

--- @param w number width
--- @param referenceWidth? number defaults to 640
--- @return number scaled width
function goldfish.ui.ScreenScaleW(w, referenceWidth)
    return w * ( ScrW() / (referenceWidth or 640) )
end

--- @param h number height
--- @param referenceHeight? number defaults to 480
--- @return number scaled height
function goldfish.ui.ScreenScaleH(h, referenceHeight)
    return h * ( ScrH() / (referenceHeight or 480) )
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

--- pushes a scissor rect onto The Stack
--- @param startX number
--- @param startY number
--- @param endX number
--- @param endY number
--- @param relative? boolean defaults to true
--- @param confine? boolean defaults to `relative`
function goldfish.ui.PushScissor(startX, startY, endX, endY, relative, confine)
    if relative == nil then
        relative = true
    end

    if confine == nil then
        confine = relative
    end

    if goldfish.ui.scissorStackIndex > 0 then
        local scissor = goldfish.ui.scissorStack[goldfish.ui.scissorStackIndex]
        if relative then
            startX = scissor[1] + startX
            startY = scissor[2] + startY
            endX = startX + endX
            endY = startY + endY
        end

        if confine then
            startX = math.Clamp(startX, scissor[1], scissor[3])
            startY = math.Clamp(startY, scissor[2], scissor[4])
            endX = math.Clamp(endX, scissor[1], scissor[3])
            endY = math.Clamp(endY, scissor[2], scissor[4])
        end
    end

    goldfish.ui.scissorStackIndex = goldfish.ui.scissorStackIndex + 1
    goldfish.ui.scissorStack[goldfish.ui.scissorStackIndex] = { startX, startY, endX, endY }
    render.SetScissorRect(startX, startY, endX, endY, true)
end

--- pops a scissor rect from The Stack
function goldfish.ui.PopScissor()
    goldfish.ui.scissorStack[goldfish.ui.scissorStackIndex] = nil
    goldfish.ui.scissorStackIndex = goldfish.ui.scissorStackIndex - 1

    if goldfish.ui.scissorStackIndex > 0 then
        local scissor = goldfish.ui.scissorStack[goldfish.ui.scissorStackIndex]
        render.SetScissorRect(scissor[1], scissor[2], scissor[3], scissor[4], true)
    else
        render.SetScissorRect(0, 0, 0, 0, false)
    end
end

--- begins a rectangular drawing context
--- @param x number
--- @param y number
--- @param w number width
--- @param h number height
function goldfish.ui.BeginRect(x, y, w, h)
    local matrix = Matrix()
    matrix:Translate(Vector(x, y, 0))
    
    cam.PushModelMatrix(matrix, true)
    goldfish.ui.PushScissor(x, y, x + w, y + h)
end

--- ends a rectangular drawing context
function goldfish.ui.EndRect()
    goldfish.ui.PopScissor()
    cam.PopModelMatrix()
end