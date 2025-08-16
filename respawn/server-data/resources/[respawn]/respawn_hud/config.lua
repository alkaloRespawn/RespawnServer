HUD = {
  enabledByDefault = true,
  anchor = 'top-right',  -- 'top-right' | 'top-left'
  offsetX = 0.017,       -- separación desde el borde (relativo a pantalla)
  offsetY = 0.040,
  width   = 0.180,       -- ancho total del bloque HUD
  barH    = 0.012,       -- alto de cada barra
  gap     = 0.009,       -- separación vertical entre barras
  lerpSpeed = 6.0,       -- rapidez de interpolación (mayor = más rápido)
  colors = {
    heat  = { r=225, g=20,  b=80,  a=220 },
    civis = { r=40,  g=200, b=235, a=220 },
    rep   = { r=140, g=210, b=60,  a=220 },
    back  = { r=16,  g=16,  b=21,  a=180 },
    edge  = { r=60,  g=60,  b=60,  a=160 },
    text  = { r=230, g=230, b=230, a=240 }
  }
}

-- Fórmula de Reputación mostrada en HUD:
-- 'max' = mayor de (HEAT, CIVIS), 'avg' = promedio, 'dom' = HEAT si activo HEAT; CIVIS si activo CIVIS; si neutral = max.
HUD.repFormula = 'dom'
