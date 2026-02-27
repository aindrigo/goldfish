function MODULE:PreEnable()
    goldfish = goldfish or {} 
end

function MODULE:PostDisable()
    goldfish = nil
end