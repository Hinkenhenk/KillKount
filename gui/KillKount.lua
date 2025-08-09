---@diagnostic disable: undefined-global
-- Globals created by XML (for LuaLS)
KillKountFrame = KillKountFrame
KillKountFrameScrollContent = KillKountFrameScrollContent
KillKountFrameContinentDrop = KillKountFrameContinentDrop
KillKountFrameZoneDrop = KillKountFrameZoneDrop
KillKountFrameStatus = KillKountFrameStatus
KillKountFrameCharOnly = KillKountFrameCharOnly

local AddonName, ns = ...

-- =======================
-- GUI state
-- =======================
local S = {
  charOnly = true,
  search = "",
  continent = "---",
  zone = "---",
  rows = {},
}

-- =======================
-- Position save/restore
-- =======================
function KillKount_SaveFramePosition(f)
  KillKountFrameState = KillKountFrameState or {}
  local point, _, relPoint, xOfs, yOfs = f:GetPoint(1)
  KillKountFrameState.point, KillKountFrameState.relPoint = point, relPoint
  KillKountFrameState.xOfs, KillKountFrameState.yOfs = xOfs, yOfs
  KillKountFrameState.w, KillKountFrameState.h = f:GetWidth(), f:GetHeight()
end

local function RestorePosition(f)
  local s = KillKountFrameState or {}
  f:ClearAllPoints()
  if s.point and s.relPoint and s.xOfs and s.yOfs then
    f:SetPoint(s.point, UIParent, s.relPoint, s.xOfs, s.yOfs)
  else
    f:SetPoint("CENTER")
  end
  if s.w and s.h and s.w > 100 and s.h > 100 then
    f:SetSize(s.w, s.h)
  end
end

-- =======================
-- Rows
-- =======================
-- =======================
-- Rows
-- =======================
local function AcquireRow(parent, i, kind)
  local row = S.rows[i]
  local template = (kind == "section") and "KillKountSectionTemplate" or "KillKountRowTemplate"

  if not row or row._kind ~= kind then
    if row then row:Hide() end
    row = CreateFrame("Button", parent:GetName().."Row"..i, parent, template)
    row._kind = kind
    S.rows[i] = row
    if i == 1 then
      row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -2)
    else
      row:SetPoint("TOPLEFT", S.rows[i-1], "BOTTOMLEFT", 0, -2)
    end
    row:SetPoint("RIGHT", parent, "RIGHT")
  end
  row:Show()
  return row
end

local function HideExtraRows(start)
  for i = start, #S.rows do
    local r = S.rows[i]
    if r then r:Hide() end
  end
end

-- =======================
-- Filtering helpers
-- =======================
local CZ = ns.ContinentZones or {}

local function endsWith(s, suf)
  return s and suf and s:sub(-#suf) == suf
end

local function isWorldZoneKey(zoneKey)
  return zoneKey and zoneKey:sub(1,7) == "world::"
end

local function instanceNameFromKey(zoneKey)
  return zoneKey:match("^%w+::([^:]+)")
end

local function toSet(list)
  local t = {}
  for _, v in ipairs(list or {}) do t[v] = true end
  return t
end

local function displayZoneFromKey(zoneKey)
  if not zoneKey then return "" end
  if isWorldZoneKey(zoneKey) then
    return zoneKey:sub(8) -- strip "world::"
  else
    return instanceNameFromKey(zoneKey) or zoneKey
  end
end

local function PassesFilters(rec)
  if S.search ~= "" then
    local n = string.lower(tostring(rec.name or ""))
    if not string.find(n, S.search, 1, true) then return false end
  end

  if S.continent ~= "---" then
    local match = false

    if endsWith(S.continent, " Dungeons") or endsWith(S.continent, " Raids") then
      if S.zone ~= "---" then
        for zk in pairs(rec.byZone or {}) do
          if not isWorldZoneKey(zk) and instanceNameFromKey(zk) == S.zone then
            match = true; break
          end
        end
      else
        local allowed = toSet(CZ[S.continent])
        for zk in pairs(rec.byZone or {}) do
          if not isWorldZoneKey(zk) and allowed[instanceNameFromKey(zk)] then
            match = true; break
          end
        end
      end
    else
      if S.zone ~= "---" then
        match = (rec.byZone and rec.byZone["world::"..S.zone]) ~= nil
      else
        local allowed = toSet(CZ[S.continent])
        for zk in pairs(rec.byZone or {}) do
          if allowed[zk] then match = true; break end
          if isWorldZoneKey(zk) and allowed[zk:sub(8)] then match = true; break end
        end
      end
    end

    if not match then return false end
  end

  return true
end

-- Returns a table like:
-- { { header = "Outland - Shadowmoon Valley", items = { {name="Enraged Air Spirit", count=1}, ... } }, ... }
local function BuildDisplay()
  local sections = {}               -- map header -> section index
  local ordered = {}                -- array of sections in display order

  local function addItem(header, name, count)
    if count <= 0 then return end
    local idx = sections[header]
    if not idx then
      idx = #ordered + 1
      ordered[idx] = { header = header, items = {} }
      sections[header] = idx
    end
    table.insert(ordered[idx].items, { name = name, count = count })
  end

  local continentLabel = S.continent
  if continentLabel == "---" then continentLabel = "" end

  for _, rec in ipairs(ns.KK.IterateNPCs()) do
    if PassesFilters(rec) then
      -- Walk the per-zone counts for this NPC and add only the ones that match current view
      for zoneKey, count in pairs(rec.byZone or {}) do
        local isWorld = isWorldZoneKey(zoneKey)
        local zname   = displayZoneFromKey(zoneKey)

        -- filter logic matches PassesFilters, but localized per zone entry
        local zoneOK = true
        if endsWith(S.continent, " Dungeons") or endsWith(S.continent, " Raids") then
          zoneOK = not isWorld
          if zoneOK and S.zone ~= "---" then
            zoneOK = (zname == S.zone)
          end
        elseif S.continent ~= "---" then
          zoneOK = isWorld and ((S.zone == "---" and true) or (zname == S.zone))
          if zoneOK and S.zone == "---" then
            -- still require it to belong to the chosen continent list
            local allowed = toSet(CZ[S.continent] or {})
            zoneOK = allowed[zname] == true
          end
        end

        if zoneOK then
          local header
          if S.continent == "---" then
            header = zname
          else
            header = (continentLabel ~= "" and (continentLabel .. " - " .. zname)) or zname
          end
          addItem(header, rec.name or ("NPC:"..rec.npcID), tonumber(count) or 0)
        end
      end
    end
  end

  -- sort sections by header; items by count desc, then name
  table.sort(ordered, function(a,b) return a.header < b.header end)
  for _, sec in ipairs(ordered) do
    table.sort(sec.items, function(a,b)
      if a.count ~= b.count then return a.count > b.count end
      return a.name < b.name
    end)
  end

  return ordered
end

-- =======================
-- Refresh
-- =======================
function KillKount_Refresh()
  if not KillKountFrame or not KillKountFrame:IsShown() then return end

  local content = KillKountFrameScrollContent
  local model = BuildDisplay()

  local rowIndex = 1
  local totalItems = 0

  for _, sec in ipairs(model) do
    -- section header
    local srow = AcquireRow(content, rowIndex, "section")
    _G[srow:GetName().."Text"]:SetText(sec.header)
    rowIndex = rowIndex + 1

    -- items
    for _, it in ipairs(sec.items) do
      local row = AcquireRow(content, rowIndex, "row")
      _G[row:GetName().."Left"]:SetText(it.name)
      _G[row:GetName().."Right"]:SetText(it.count)
      rowIndex = rowIndex + 1
      totalItems = totalItems + 1
    end
  end

  HideExtraRows(rowIndex)

  -- approx height: 20 for section rows, 18 for item rows. Worst-case, treat all as 18 + padding.
  local height = (rowIndex - 1) * 18 + 8
  content:SetSize(1, math.max(height, 1))

  KillKountFrameStatus:SetText(string.format("%d entries", totalItems))
end

function KillKount_Reset()
  ns.KK.ResetCurrentCharacter()
  KillKount_Refresh()
  ns.log("Current character data reset.")
end

-- =======================
-- Search / checkbox
-- =======================
function KillKount_OnSearchChanged(box)
  S.search = string.lower(box:GetText() or "")
  KillKount_Refresh()
end

function KillKount_OnCharOnlyChanged(checked)
  S.charOnly = not not checked
  KillKount_Refresh()
end

-- =======================
-- Dropdowns
-- =======================
local function SetContinent(value, text)
  local label = text or tostring(value)
  S.continent = value
  UIDropDownMenu_SetSelectedValue(KillKountFrameContinentDrop, value)
  UIDropDownMenu_SetText(KillKountFrameContinentDrop, label)

  UIDropDownMenu_Initialize(KillKountFrameZoneDrop, KillKount_InitZoneDrop)
  S.zone = "---"
  KillKountFrameZoneDrop.selectedValue = nil
  KillKountFrameZoneDrop.selectedName  = nil
  UIDropDownMenu_SetSelectedValue(KillKountFrameZoneDrop, nil)
  UIDropDownMenu_SetText(KillKountFrameZoneDrop, "---")
  local zText = _G[KillKountFrameZoneDrop:GetName().."Text"]
  if zText then zText:SetText("---") end

  KillKount_Refresh()
end

local function AddMenuItem(text, value, onclick, level, checked)
  local info = UIDropDownMenu_CreateInfo()
  info.text  = text
  info.value = value
  info.func  = onclick
  info.checked = checked
  UIDropDownMenu_AddButton(info, level)
end

function KillKount_InitContinentDrop(self, level)
  local onPick = function(btn) SetContinent(btn.value, btn.text) end
  local selected = S.continent

  AddMenuItem("---", "---", onPick, level, selected == "---")

  local keys = {}
  for k in pairs(CZ) do keys[#keys+1] = k end
  table.sort(keys)

  for _, continent in ipairs(keys) do
    AddMenuItem(continent, continent, onPick, level, selected == continent)
  end
end

function KillKount_InitZoneDrop(self, level)
  local dd = KillKountFrameZoneDrop
  local selected = (S.zone ~= "---") and S.zone or nil

  -- keep label in sync on open
  if selected then
    UIDropDownMenu_SetSelectedValue(dd, selected)
    UIDropDownMenu_SetText(dd, selected)
  else
    UIDropDownMenu_SetSelectedValue(dd, nil)
    UIDropDownMenu_SetText(dd, "---")
  end

  local function pick(btn)
    -- MoP quirk: btn.text is often nil; use GetText()
    local label = (btn.GetText and btn:GetText()) or btn.text or tostring(btn.value)

    S.zone = btn.value
    dd.selectedValue = btn.value
    dd.selectedName  = label

    UIDropDownMenu_SetSelectedValue(dd, btn.value)
    UIDropDownMenu_SetText(dd, label)

    local t = _G[dd:GetName().."Text"]
    if t then t:SetText(label) end

    CloseDropDownMenus()
    KillKount_Refresh()
  end

  local info = UIDropDownMenu_CreateInfo()
  info.text, info.value, info.func = "---", "---", pick
  info.checked = (selected == nil)
  UIDropDownMenu_AddButton(info, level)

  local zones = CZ[S.continent] or {}
  local copy = {}
  for i = 1, #zones do copy[i] = zones[i] end
  table.sort(copy)

  for _, z in ipairs(copy) do
    info = UIDropDownMenu_CreateInfo()
    info.text, info.value, info.func = z, z, pick
    info.checked = (selected == z)
    UIDropDownMenu_AddButton(info, level)
  end
end

-- =======================
-- Lifecycle
-- =======================
function KillKount_OnLoad(self)
  RestorePosition(self)

  if self.SetBackdrop then
    self:SetBackdrop({
      bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile     = true, tileSize = 16, edgeSize = 16,
      insets   = { left = 4, right = 4, top = 4, bottom = 4 },
    })
  end

  self:SetClampedToScreen(true)
  self:SetResizable(true)
  if self.SetResizeBounds then
    self:SetResizeBounds(380, 260, 1600, 1200)
  end

  if KillKountFrameSearch and KillKountFrameSearch.SetMaxLetters then
    KillKountFrameSearch:SetMaxLetters(60)
  end

  if not self.Resizer then
    local g = CreateFrame("Button", nil, self)
    g:SetPoint("BOTTOMRIGHT", -4, 4)
    g:SetSize(16, 16)
    g:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    g:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    g:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    g:SetScript("OnMouseDown", function() self:StartSizing("BOTTOMRIGHT") end)
    g:SetScript("OnMouseUp",   function()
      self:StopMovingOrSizing()
      KillKount_SaveFramePosition(self)
      KillKount_Refresh()
    end)
    self.Resizer = g
  end

  self:SetScript("OnSizeChanged", function(_, w)
    if KillKountFrameScrollContent then
      KillKountFrameScrollContent:SetWidth(math.max(1, w - 40))
    end
  end)

  local w = self:GetWidth() or 480
  if KillKountFrameScrollContent then
    KillKountFrameScrollContent:SetWidth(math.max(1, w - 40))
  end

  if not self.ScaleWatcher then
    local f = CreateFrame("Frame")
    f:RegisterEvent("UI_SCALE_CHANGED")
    f:SetScript("OnEvent", function()
      self:SetClampedToScreen(true)
      local x, y = self:GetCenter()
      if not x or not y then
        self:ClearAllPoints()
        self:SetPoint("CENTER")
      end
    end)
    self.ScaleWatcher = f
  end

  UIDropDownMenu_Initialize(KillKountFrameContinentDrop, KillKount_InitContinentDrop)
  UIDropDownMenu_SetWidth(KillKountFrameContinentDrop, 180)
  UIDropDownMenu_SetSelectedValue(KillKountFrameContinentDrop, S.continent)
  UIDropDownMenu_SetText(KillKountFrameContinentDrop, S.continent)

  UIDropDownMenu_Initialize(KillKountFrameZoneDrop, KillKount_InitZoneDrop)
  UIDropDownMenu_SetWidth(KillKountFrameZoneDrop, 200)

  if S.zone ~= "---" then
    KillKountFrameZoneDrop.selectedValue = S.zone
    KillKountFrameZoneDrop.selectedName  = S.zone
    UIDropDownMenu_SetSelectedValue(KillKountFrameZoneDrop, S.zone)
    UIDropDownMenu_SetText(KillKountFrameZoneDrop, S.zone)
  else
    KillKountFrameZoneDrop.selectedValue = nil
    KillKountFrameZoneDrop.selectedName  = nil
    UIDropDownMenu_SetSelectedValue(KillKountFrameZoneDrop, nil)
    UIDropDownMenu_SetText(KillKountFrameZoneDrop, "---")
  end

  if KillKountFrameCharOnly then
    KillKountFrameCharOnly:SetChecked(true)
  end
end

function KillKount_OnShow(self) KillKount_Refresh() end
function KillKount_OnHide(self) KillKount_SaveFramePosition(self) end

function ns.GUI_Show() KillKountFrame:Show() end
function ns.GUI_Hide() KillKountFrame:Hide() end
function ns.GUI_Toggle() if KillKountFrame:IsShown() then KillKountFrame:Hide() else KillKountFrame:Show() end end
function ns.GUI_Refresh() KillKount_Refresh() end
