Workshops = {
  civis = {
    label = 'Taller Corporativo',
    coords = vec3(-339.60, -136.75, 39.00),
    heading = 70.0,
    pedModel = `s_m_m_autoshop_02`,   -- modelo ped sugerido
    scenario = 'WORLD_HUMAN_CLIPBOARD'
  },
  heat = {
    label = 'Taller Clandestino',
    coords = vec3(1173.35, -1325.70, 35.20),
    heading = 180.0,
    pedModel = `g_m_m_cartelguards_01`,
    scenario = 'WORLD_HUMAN_HAMMERING'
  }
}

-- Costes / tiempos
Pricing = {
  cash = { [0]=250, [1]=500,[2]=900,[3]=1500,[4]=2400,[5]=3600,[6]=5200,[7]=8000,[8]=12000,[9]=18000 },
  timeSec = { [0]=8, [1]=15,[2]=25,[3]=35,[4]=45,[5]=60,[6]=90,[7]=120,[8]=180,[9]=240 }
}

-- Materiales por rama (bloques)
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

-- util (servida a server y client)
function GetMatBlock(branch, level)
  local map = Materials[branch]; if not map then return {items={}} end
  local best = 1
  for k,_ in pairs(map) do if k<=level and k>best then best=k end end
  return map[best] or {items={}}
end
