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
  rows = {},            -- will now be “active sequence” for this render
  pool = { section = {}, row = {} }, -- reusable frames by kind
  id = 0,               -- unique name counter
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
local function AcquireRow(parent, prev, kind)
  local template = (kind == "section") and "KillKountSectionTemplate" or "KillKountRowTemplate"
  local bucket   = (kind == "section") and S.pool.section or S.pool.row
  local row = table.remove(bucket)

  if not row then
    S.id = S.id + 1
    local suffix = (kind == "section") and ("Sec"..S.id) or ("Row"..S.id)
    local name = parent:GetName() .. suffix
    row = CreateFrame("Frame", name, parent, template)
  else
    row:ClearAllPoints()
  end

  row._kind = kind

  -- (Re)bind child regions so we never depend on _G lookups later
  row.Text  = nil
  row.Left  = nil
  row.Right = nil
  if kind == "section" then
    row.Text = _G[row:GetName().."Text"]
  else
    row.Left  = _G[row:GetName().."Left"]
    row.Right = _G[row:GetName().."Right"]
  end

  -- anchor
  if prev then
    row:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -2)
  else
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -2)
  end
  row:SetPoint("RIGHT", parent, "RIGHT")

  row:Show()
  S.rows[#S.rows+1] = row
  return row
end

local function HideExtraRows(_startIgnored)
  for i = 1, #S.rows do
    local r = S.rows[i]
    if r then
      if r.Left  then r.Left:SetText("")  end
      if r.Right then r.Right:SetText("") end
      if r.Text  then r.Text:SetText("")  end
      r:Hide()
      if r._kind == "section" then
        table.insert(S.pool.section, r)
      else
        table.insert(S.pool.row, r)
      end
    end
  end
  wipe(S.rows)
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

local function BuildDisplay()
  local sections = {}               -- map header -> section index
  local ordered  = {}               -- array of sections in display order

  local function addItem(header, name, count)
    if count <= 0 then return end
    local idx = sections[header]
    if not idx then
      idx = #ordered + 1
      ordered[idx] = { header = header, items = {}, total = 0 }
      sections[header] = idx
    end
    table.insert(ordered[idx].items, { name = name, count = count })
    ordered[idx].total = ordered[idx].total + count
  end

  local continentLabel = S.continent
  if continentLabel == "---" then continentLabel = "" end

  for _, rec in ipairs(ns.KK.IterateNPCs()) do
    if PassesFilters(rec) then
      for zoneKey, count in pairs(rec.byZone or {}) do
        local isWorld = isWorldZoneKey(zoneKey)
        local zname   = displayZoneFromKey(zoneKey)

        local zoneOK = true
        if endsWith(S.continent, " Dungeons") or endsWith(S.continent, " Raids") then
          zoneOK = not isWorld
          if zoneOK and S.zone ~= "---" then
            zoneOK = (zname == S.zone)
          end
        elseif S.continent ~= "---" then
          zoneOK = isWorld and ((S.zone == "---" and true) or (zname == S.zone))
          if zoneOK and S.zone == "---" then
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

  -- Release all previously active rows first
  HideExtraRows(1)

  -- Build the data model for this view
  local model = BuildDisplay()

  local totalItems   = 0
  local sectionCount = 0
  local prev

  local function fmt(n)
    if BreakUpLargeNumbers then return BreakUpLargeNumbers(n) end
    return tostring(n or 0)
  end

  if #model == 0 then
    local srow = AcquireRow(content, prev, "section")
    if srow.Text then srow.Text:SetText("No results") end
    prev = srow
    sectionCount = 1
  else
    for _, sec in ipairs(model) do
      local srow = AcquireRow(content, prev, "section")
      if srow.Text then
        -- Show "Zone Name — Total"
        srow.Text:SetFormattedText("%s — %s", sec.header or "", fmt(sec.total or 0))
      end
      prev = srow
      sectionCount = sectionCount + 1

      for _, it in ipairs(sec.items) do
        local row = AcquireRow(content, prev, "row")

        -- "NPC Name: <number>" inline in left label
        local name  = it.name or ""
        local count = tonumber(it.count) or 0
        if row.Left  then row.Left:SetFormattedText("%s: %s", name, fmt(count)) end
        if row.Right then row.Right:SetText("") end

        prev = row
        totalItems = totalItems + 1
      end
    end
  end

  -- Resize scroll content
  local height = (sectionCount * 20) + (totalItems * 18) + 8
  if content.SetHeight then content:SetHeight(math.max(height, 1)) end

  local scroll = KillKountFrameScroll
  if scroll and content and content:GetWidth() < 50 then
    local avail = (scroll:GetWidth() or 480) - 20 -- scrollbar + padding
    if avail > 50 then content:SetWidth(avail) end
  end

  KillKountFrameStatus:SetText(string.format("%d entries", totalItems))
end

-- =======================
-- Search / checkbox
-- =======================
function KillKount_OnSearchChanged(box)
  local q = (box:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
  if S.search ~= q then
    S.search = q
    KillKount_Refresh()
  end
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

  if selected then
    UIDropDownMenu_SetSelectedValue(dd, selected)
    UIDropDownMenu_SetText(dd, selected)
  else
    UIDropDownMenu_SetSelectedValue(dd, nil)
    UIDropDownMenu_SetText(dd, "---")
  end

  local function pick(btn)
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

  -- Try classic backdrop first (works if not skinned)
  if self.SetBackdrop then
    self:SetBackdrop({
      bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile     = true, tileSize = 16, edgeSize = 16,
      insets   = { left = 5, right = 5, top = 5, bottom = 5 },
    })
    self:SetBackdropColor(0, 0, 0, 0.85)
    self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
  end
  self:SetFrameStrata("DIALOG")

  -- Hard background + 1px border (skin-proof)
  do
    if not self._kkBG then
      local bg = self:CreateTexture(nil, "BACKGROUND")
      bg:SetTexture("Interface\\Buttons\\WHITE8x8")
      bg:SetVertexColor(0, 0, 0, 0.85)
      bg:SetPoint("TOPLEFT", 1, -1)
      bg:SetPoint("BOTTOMRIGHT", -1, 1)
      self._kkBG = bg
    end
    local function edge(field, a1, x1, y1, a2, x2, y2, w, h)
      local t = self[field] or self:CreateTexture(nil, "BORDER")
      self[field] = t
      t:SetTexture("Interface\\Buttons\\WHITE8x8")
      t:SetVertexColor(0.35, 0.35, 0.35, 1)
      t:ClearAllPoints()
      t:SetPoint(a1, self, a1, x1, y1)
      t:SetPoint(a2, self, a2, x2, y2)
      if w then t:SetWidth(w) end
      if h then t:SetHeight(h) end
    end
    edge("_kkTop",    "TOPLEFT",   1, -1, "TOPRIGHT",   -1, -1, nil, 1)
    edge("_kkBottom", "BOTTOMLEFT",1,  1, "BOTTOMRIGHT", -1,  1, nil, 1)
    edge("_kkLeft",   "TOPLEFT",   1, -1, "BOTTOMLEFT",  1,  1, 1,  nil)
    edge("_kkRight",  "TOPRIGHT", -1, -1, "BOTTOMRIGHT", -1,  1, 1,  nil)
  end

  self:SetClampedToScreen(true)
  self:SetResizable(true)
  if self.SetResizeBounds then
    -- keep your current bounds; adjust if you want later
    self:SetResizeBounds(280, 350, 280, 800)
  end

  if KillKountFrameSearch then
    if KillKountFrameSearch.SetMaxLetters then
      KillKountFrameSearch:SetMaxLetters(60)
    end
    KillKountFrameSearch:SetAutoFocus(false)
    KillKountFrameSearch:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    KillKountFrameSearch:SetScript("OnEnterPressed",  function(self) self:ClearFocus() end)

    if not KillKountSearchFocusDrop then
      local catcher = CreateFrame("Button", "KillKountSearchFocusDrop", UIParent)
      catcher:SetAllPoints(UIParent)
      catcher:EnableMouse(true)
      catcher:Hide()
      catcher:SetFrameStrata("FULLSCREEN_DIALOG")
      catcher:SetScript("OnMouseDown", function()
        if KillKountFrameSearch and KillKountFrameSearch:HasFocus() then
          KillKountFrameSearch:ClearFocus()
        end
        catcher:Hide()
      end)
    end

    KillKountFrameSearch:SetScript("OnEditFocusGained", function() KillKountSearchFocusDrop:Show() end)
    KillKountFrameSearch:SetScript("OnEditFocusLost",   function(self)
      self:HighlightText(0, 0)
      if KillKountSearchFocusDrop then KillKountSearchFocusDrop:Hide() end
    end)
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
      KillKountFrameScrollContent:SetWidth(math.max(1, w - 0))
    end
  end)

  local w = self:GetWidth() or 480
  if KillKountFrameScrollContent then
    KillKountFrameScrollContent:SetWidth(math.max(1, w - 0))
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
  UIDropDownMenu_SetWidth(KillKountFrameContinentDrop, 200) -- same width
  UIDropDownMenu_SetSelectedValue(KillKountFrameContinentDrop, S.continent)
  UIDropDownMenu_SetText(KillKountFrameContinentDrop, S.continent)

  UIDropDownMenu_Initialize(KillKountFrameZoneDrop, KillKount_InitZoneDrop)
  UIDropDownMenu_SetWidth(KillKountFrameZoneDrop, 200)       -- same width

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

do
  local want = false
  local t = 0
  local driver = CreateFrame("Frame")
  driver:SetScript("OnUpdate", function(_, dt)
    if not want then return end
    t = t + dt
    if t > 0.1 then
      want = false
      t = 0
      if KillKountFrame and KillKountFrame:IsShown() then
        KillKount_Refresh()
      end
    end
  end)

  function ns.GUI_RequestRefresh()
    want = true
  end
end
