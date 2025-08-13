# Respawn — UI Panel de Armas

## HUD
- Barras compactas: HEAT / CIVIS / Reputación
- Toasts: “+Nivel elegible (CIVIS +5)”, “Reclamado (HEAT +7)”, “Bloqueado por bando”

## Panel de Arma (NUI)
- Layout: 2 columnas (Izq = HEAT, Der = CIVIS), filas 0→+9
- Cada celda muestra:
  - Icono/miniatura de skin
  - Estado: Bloqueado | Elegible | Desbloqueado | Bloqueado por bando
- Al seleccionar una celda:
  - Card con **skin_name**, lista de **attachments**, **nota de perk**
  - Botón **RECLAMAR** → modal de coste/tiempo y **lugar** (Taller CIVIS / Clandestino)
  - Si `cooldown de lealtad` activo: aviso y timer

## Flujo
1) Jugador abre panel → ve niveles según branch/score
2) Selecciona nivel elegible → RECLAMAR
3) Confirma → genera “encargo” (folio) → progreso de taller → entrega
4) Tras reclamar, puede **equipar** desde su catálogo (coste montaje opcional)
