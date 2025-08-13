# respawn_ui (placeholder)

## Objetivo
- Panel de armas (dos columnas HEAT/CIVIS, filas 0..9)
- Estados: Bloqueado/Elegible/Desbloqueado/Bloqueado por bando
- Botón RECLAMAR → confirmación de coste/tiempo/lugar

## Interfaz (plan)
- NUI <-> client: postMessage/events
- client <-> server: TriggerServerEvent para reclamos / consultas
- Datos mostrados: provenir de respawn_weapons + respawn_alignment

## Accesibilidad/UX
- Tooltips de attachments
- Etiquetas claras de exclusividad de bando y cooldown
