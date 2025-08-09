local AddonName, ns = ...

local function AddKillLine(tooltip, unit)
    if not unit or not UnitExists(unit) then return end
    local guid = UnitGUID(unit)
    local npcID = ns.GetNPCIDFromGUID(guid)
    if not npcID then return end

    local kills = ns.KK.GetCharKills(npcID) or 0

    -- Add line (always present, even if 0)
    tooltip:AddLine(string.format("Kills: %d", kills))
    tooltip:Show()
end

GameTooltip:HookScript("OnTooltipSetUnit", function(tooltip)
    local name, unit = tooltip:GetUnit()
    if unit then
        AddKillLine(tooltip, unit)
    end
end)

-- Also cover the target-of-target tooltip etc. if needed
ItemRefTooltip:HookScript("OnTooltipSetUnit", function(tooltip)
    local name, unit = tooltip:GetUnit()
    if unit then
        AddKillLine(tooltip, unit)
    end
end)
