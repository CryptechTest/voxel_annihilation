
function va_structures.get_all_structures()
    local structures = va_structures.get_active_structures()
    local s_ents = {}
    for _,s in pairs(structures) do
        table.insert(s_ents, s.get_entity())
    end
    return s_ents
end