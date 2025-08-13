Workshops = {
  civis = {
    label = 'Taller Corporativo',
    coords = vec3(-339.60, -136.75, 39.00), -- cambia a tu gusto
    previewMultiplier = 1.0
  },
  heat = {
    label = 'Taller Clandestino',
    coords = vec3(1173.35, -1325.70, 35.20),
    previewMultiplier = 1.0
  }
}

-- Costes/tiempos por nivel (+1..+9). Puedes tunear después.
Pricing = {
  cash = {  -- $ base por nivel
    [1]=500, [2]=900, [3]=1500, [4]=2400, [5]=3600, [6]=5200, [7]=8000, [8]=12000, [9]=18000
  },
  timeSec = { -- tiempo de trabajo (segundos)
    [1]=15, [2]=25, [3]=35, [4]=45, [5]=60, [6]=90, [7]=120, [8]=180, [9]=240
  }
}

-- Materiales por rama y tramo
Materials = {
  civis = {
    [1] = { items = { cert_oem=1 } },
    [3] = { items = { cert_oem=1, license_form=1 } },
    [5] = { items = { cert_oem=2, license_form=1 } },
    [7] = { items = { cert_oem=2, kit_ceramic=1, folio_blank=1 } },
    [9] = { items = { cert_oem=3, kit_ceramic=2, folio_blank=1 } }
  },
  heat = {
    [1] = { items = { hot_parts=1 } },
    [3] = { items = { hot_parts=1, powder_fine=1 } },
    [5] = { items = { hot_parts=2, powder_fine=1 } },
    [7] = { items = { hot_parts=2, powder_fine=2, folio_blank=1 } },
    [9] = { items = { hot_parts=3, powder_fine=2, folio_blank=1 } }
  }
}

-- Util para buscar el “tramo” más cercano <= level
function GetMatBlock(branch, level)
  local map = Materials[branch]; if not map then return {items={}} end
  local best = 1
  for k,_ in pairs(map) do if k<=level and k>best then best=k end end
  return map[best] or {items={}}
end
