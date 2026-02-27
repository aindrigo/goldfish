goldfish.ui.hiddenElements = {
    ["CHudAmmo"] = true,
    ["CHudHealth"] = true,
    ["CHudBattery"] = true
}

function HOOKS:HUDShouldDraw(element)
    if goldfish.ui.hiddenElements[element] then
        return false
    end
end

function HOOKS:HUDPaint()

end