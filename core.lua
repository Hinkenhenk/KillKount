local AddonName, ns = ...

-- Public namespace table
local KK = {}
ns.KK = KK

--========================
-- Saved DB layout (per character focus):
-- KillKountDB = {
--   version = 1,
--   chars = {
--     ["Realm-Name"] = {
--        byNPC = {
--          [npcID] = {
--            name = "Boar",
--            total = 12,
--            byZone = { ["world::Durotar"]=5, ["party::Ragefire Chasm::1"]=7 },
--          }
--        }
--     }
--   }
-- }
--========================

local FRAME = CreateFrame("Frame")
FRAME:RegisterEvent("ADDON_LOADED")
FRAME:RegisterEvent("PLAYER_LOGIN")
FRAME:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

local function EnsureDB()
    KillKountDB = KillKountDB or { version = 1, chars = {} }
    local charKey = ns.GetCharKey()
    local charDB = ns.deepget(KillKountDB.chars, charKey, function() return { byNPC = {} } end)
    return charDB
end

-- Record a kill for an NPC with optional zone/instance breakdown
function KK.RecordKill(npcID, npcName, loc)
    if not npcID then return end
    local charDB = EnsureDB()
    local rec = ns.deepget(charDB.byNPC, npcID, function() return { name = npcName or ("NPC:"..npcID), total = 0, byZone = {} } end)
    if npcName and npcName ~= "" then rec.name = npcName end
    rec.total = (rec.total or 0) + 1
    if loc and loc.zoneKey then
        rec.byZone[loc.zoneKey] = (rec.byZone[loc.zoneKey] or 0) + 1
    end
end

-- Query kills for tooltip (per-character)
function KK.GetCharKills(npcID)
    if not npcID then return 0 end
    if not KillKountDB or not KillKountDB.chars then return 0 end
    local charDB = KillKountDB.chars[ns.GetCharKey()]
    if not charDB or not charDB.byNPC then return 0 end
    local rec = charDB.byNPC[npcID]
    return (rec and rec.total) or 0
end

-- Export a flat list for the GUI
function KK.IterateNPCs()
    local out = {}
    local charDB = EnsureDB()
    for npcID, rec in pairs(charDB.byNPC) do
        out[#out+1] = { npcID = npcID, name = rec.name or ("NPC:"..npcID), total = rec.total or 0, byZone = rec.byZone or {} }
    end
    table.sort(out, function(a, b)
        if a.total == b.total then
            return tostring(a.name) < tostring(b.name)
        end
        return a.total > b.total
    end)
    return out
end

-- Reset current character data
function KK.ResetCurrentCharacter()
    local charKey = ns.GetCharKey()
    if KillKountDB and KillKountDB.chars then
        KillKountDB.chars[charKey] = { byNPC = {} }
    end
end

--========================
-- Event handling
--========================

local function OnCombatLogEventUnfiltered()
    local timestamp, subevent, _, srcGUID, _, _, _, dstGUID, dstName = CombatLogGetCurrentEventInfo()
    if subevent ~= "PARTY_KILL" then return end
    -- Only count kills YOU (the player) made
    if srcGUID ~= UnitGUID("player") then return end

    local npcID = ns.GetNPCIDFromGUID(dstGUID)
    if not npcID then return end

    local loc = ns.GetLocationContext()
    ns.KK.RecordKill(npcID, dstName, loc)
end

FRAME:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == AddonName then
        EnsureDB()
        KillKountFrameState = KillKountFrameState or {}
    elseif event == "PLAYER_LOGIN" then
        -- Ready
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        OnCombatLogEventUnfiltered()
    end
end)
