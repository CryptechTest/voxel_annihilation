
function va_structures.get_all_structures()
    local structures = va_structures.get_active_structures()
    local s_ents = {}
    for _,s in pairs(structures) do
        local ent = s:get_entity()
        if s:is_active() and ent ~= nil then
            table.insert(s_ents, s:get_entity())
        end
    end
    return s_ents
end
