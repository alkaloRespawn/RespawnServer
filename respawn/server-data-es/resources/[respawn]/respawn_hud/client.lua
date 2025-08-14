local enabled = HUD.enabledByDefault
local state = {
  heat = 0, civis = 0, active = 'neutral',
  eligible = { heat = 0, civis = 0 },
  rep = 0
}

-- valores suavizados (draw)
local lerp = { heat = 0.0, civis = 0.0, rep = 0.0 }

-- ===== helpers draw =====
local function drawRect(x,y,w,h, c)
  DrawRect(x + w/2, y + h/2, w, h, c.r, c.g, c.b, c.a)
end

local function drawText(x,y, scale, txt, c, alignRight)
  SetTextFont(4); SetTextScale(scale, scale)
  SetTextColour(c.r, c.g, c.b, c.a)
  SetTextOutline()
  SetTextJustification(alignRight and 2 or 1)
  SetTextEntry('STRING'); AddTextComponentString(txt)
  DrawText(x, y)
end

local function clamp01(v) return math.max(0.0, math.min(1.0, v)) end
local function Lerp(a,b,t) return a + (b-a) * math.min(1.0, t) end

local function computeRep()
  local h, c = state.heat, state.civis
  if HUD.repFormula == 'avg' then
    return math.floor((h + c) * 0.5 + 0.5)
  elseif HUD.repFormula == 'dom' then
    if state.active == 'heat' then return h
    elseif state.active == 'civis' then return c
    else return math.max(h, c) end
  else -- 'max'
    return math.max(h, c)
  end
end

-- ===== update desde alignment =====
RegisterNetEvent('respawn:alignment:clientState', function(new)
  state.heat  = new.heat or state.heat
  state.civis = new.civis or state.civis
  state.active = new.active or state.active
  state.eligible = new.eligible or state.eligible
  state.rep = computeRep()
end)

-- toggle comando + keybind
RegisterCommand('respawn_hud', function()
  enabled = not enabled
  if enabled and state.rep == 0 then state.rep = computeRep() end
  if GetResourceState('ox_lib') == 'started' then
    lib.notify({ title='Respawn HUD', description=(enabled and 'Activado' or 'Ocultado'), type=(enabled and 'success' or 'warning') })
  end
end, false)
RegisterKeyMapping('respawn_hud', 'Mostrar/Ocultar HUD Respawn', 'keyboard', 'F7')

-- hilo draw
CreateThread(function()
  while true do
    if enabled then
      local dt = GetFrameTime() * (HUD.lerpSpeed or 6.0)
      local w  = HUD.width
      local h  = HUD.barH
      local gap = HUD.gap
      local offX = HUD.offsetX
      local offY = HUD.offsetY
      local anchorRight = (HUD.anchor == 'top-right')

      -- target widths
      local tHeat  = clamp01(state.heat / 100.0)
      local tCivis = clamp01(state.civis / 100.0)
      local tRep   = clamp01((state.rep or computeRep()) / 100.0)

      -- lerp
      lerp.heat  = Lerp(lerp.heat,  tHeat,  dt)
      lerp.civis = Lerp(lerp.civis, tCivis, dt)
      lerp.rep   = Lerp(lerp.rep,   tRep,   dt)

      -- anchor base
      local x = anchorRight and (1.0 - offX - w) or offX
      local y = offY

      local labels = {
        { name = 'HEAT',  val = state.heat,  fill = lerp.heat,  col = HUD.colors.heat  },
        { name = 'CIVIS', val = state.civis, fill = lerp.civis, col = HUD.colors.civis },
        { name = 'REP',   val = state.rep,   fill = lerp.rep,   col = HUD.colors.rep   }
      }

      for i,bar in ipairs(labels) do
        local by = y + (i-1) * (h + gap)

        -- back + edge
        drawRect(x, by, w, h, HUD.colors.back)
        -- edge (fino)
        drawRect(x - 0.001, by - 0.001, w+0.002, 0.001, HUD.colors.edge)
        drawRect(x - 0.001, by + h,     w+0.002, 0.001, HUD.colors.edge)

        -- fill
        local fw = w * bar.fill
        drawRect(x, by, fw, h, bar.col)

        -- textos
        local label = bar.name
        if bar.name == 'HEAT' and state.active == 'heat' then label = label .. ' ★' end
        if bar.name == 'CIVIS' and state.active == 'civis' then label = label .. ' ★' end

        drawText(anchorRight and (x + w - 0.002) or (x + 0.002), by - (h * 0.10), 0.30, label, HUD.colors.text, anchorRight)
        drawText(anchorRight and (x + w - 0.002) or (x + 0.002), by + (h * 0.10), 0.32, tostring(math.floor(bar.val)), HUD.colors.text, anchorRight)
      end

      -- “badge” del bando activo
      if state.active ~= 'neutral' then
        local tag = (state.active == 'heat') and 'HEAT' or 'CIVIS'
        local c = (state.active == 'heat') and HUD.colors.heat or HUD.colors.civis
        local bx = anchorRight and (x + w - 0.056) or (x)
        local by = y - (gap*0.90)
        drawRect(bx, by, 0.056, 0.018, HUD.colors.back)
        drawRect(bx, by, 0.056, 0.002, c)
        drawText(anchorRight and (bx + 0.052) or (bx + 0.004), by - 0.006, 0.30, tag, c, anchorRight)
      end

      Wait(0)
    else
      Wait(500)
    end
  end
end)
