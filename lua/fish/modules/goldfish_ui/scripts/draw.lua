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
--- @param type? goldfish.ui.BlurType
function goldfish.ui.DrawBlur(x, y, w, h, intensity, type)
    intensity = intensity or 1
    type = type or goldfish.ui.BlurType.CHEAP

    local ps = surface.GetPanelPaintState()
    x = ps.translate_x + x
    y = ps.translate_y + y

    goldfish.ui.PushScissor(x, y, x + w, y + h)
    render.UpdateScreenEffectTexture()

    local mat = nil
    if type == goldfish.ui.BlurType.CHEAP then
        mat = goldfish.ui.blurMaterialCheap

        mat:SetFloat("$blur", 5 * intensity)
    elseif type == goldfish.ui.BlurType.EXPENSIVE then
        mat = goldfish.ui.blurMaterialExpensive

        mat:SetFloat("$size", 6 * intensity)
        mat:SetFloat("$focus", 1)
        mat:SetFloat("$focusradius", 2)
    else
        error("unrecognized type: " .. tostring(type))
    end

    mat:SetTexture("$BASETEXTURE", render.GetScreenEffectTexture())
    mat:SetTexture("$DEPTHTEXTURE", render.GetResolvedFullFrameDepth())
    mat:Recompute()

    render.SetMaterial(mat)
    render.DrawScreenQuad()

    goldfish.ui.PopScissor()
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

--- draws a line similarly to surface.DrawLine but with thickness
--- @param xStart number
---@param yStart number
---@param xEnd number
---@param yEnd number
---@param thickness number
function goldfish.ui.DrawLine(xStart, yStart, xEnd, yEnd, thickness)
    thickness = thickness or 1

    if xEnd < xStart then
        local originalXStart = xStart
        xStart = xEnd
        xEnd = originalXStart
    end

    if yEnd < yStart then
        local originalYStart = yStart
        yStart = yEnd
        yEnd = originalYStart
    end

    local halfThickness = thickness / 2

    local v0 = { x = xStart - halfThickness, y = yStart - halfThickness }
    local v1 = { x = xEnd + halfThickness, y = yStart - halfThickness }
    local v2 = { x = xEnd + halfThickness, y = yEnd + halfThickness }
    local v3 = { x = xStart - halfThickness, y = yEnd + halfThickness }

    surface.DrawPoly({ v0, v1, v2, v3 })
end
