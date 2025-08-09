local AddonName, ns = ...

-- String split helper (no allocations in hot paths)
function ns.split(str, delim)
    local out, from = {}, 1
    while true do
        local i, j = string.find(str, delim, from, true)
        if not i then
            out[#out+1] = string.sub(str, from)
            break
        end
        out[#out+1] = string.sub(str, from, i - 1)
        from = j + 1
    end
    return out
end

-- Extract NPC ID from a GUID that looks like: Creature-0-...-<npcID>-<spawnUID>
-- Safe for Classic MoP GUID formats. Returns number or nil.
function ns.GetNPCIDFromGUID(guid)
    if not guid then return nil end
    -- Common modern format: type-0-instance-zone-server-npcId-unique
    -- We split by '-' and take the 6th field if type is Creature/Vehicle
    local t = ns.split(guid, "-")
    local typ = t[1]
    if typ == "Creature" or typ == "Vehicle" then
        local id = tonumber(t[6])
        return id
    end
    -- Fallback: older hex GUIDs (unlikely here, but safe guard)
    -- Example: 0xF1300013B9000046 -> mask the middle; skip for MoP Classic unless needed
    return nil
end

-- Zone / instance info
function ns.GetLocationContext()
    local inInstance, instanceType = IsInInstance()
    local zoneText = GetRealZoneText() or GetZoneText() or "Unknown"
    local subZone = GetSubZoneText()
    local mapID = nil
    if C_Map and C_Map.GetBestMapForUnit then
        mapID = C_Map.GetBestMapForUnit("player")
    end
    local instName, _, difficultyID = GetInstanceInfo()
    return {
        inInstance   = inInstance or false,
        instanceType = instanceType or "none",
        zone         = zoneText,
        subZone      = (subZone and subZone ~= "" and subZone) or nil,
        mapID        = mapID,
        instanceName = (inInstance and instName) or nil,
        difficultyID = (inInstance and difficultyID) or nil,
        zoneKey      = (inInstance and (instanceType .. "::" .. (instName or zoneText) .. "::" .. tostring(difficultyID or 0)))
                       or ("world::" .. zoneText)
    }
end

-- Current character key "Realm-Name"
function ns.GetCharKey()
    local name = UnitName("player")
    local realm = GetRealmName()
    return string.format("%s-%s", realm or "Unknown", name or "Unknown")
end

-- Safe table get/create
function ns.deepget(tbl, k, defaultFactory)
    local v = tbl[k]
    if v == nil and defaultFactory then
        v = defaultFactory()
        tbl[k] = v
    end
    return v
end

-- Simple print tag
local prefix = "|cff00ff00KillKount|r:"
function ns.log(msg)
    print(prefix, msg)
end

