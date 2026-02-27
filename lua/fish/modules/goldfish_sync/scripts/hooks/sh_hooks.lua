function HOOKS:EntityRemoved(entity, fullUpdate)
    if CLIENT and fullUpdate and not entity:IsDormant() then return end
    goldfish.sync.data[entity:EntIndex()] = nil
    
end