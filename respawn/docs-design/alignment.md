# Respawn — Alineación (HEAT / CIVIS)

## Escalas
- HEAT: 0–100 (exposición ilegal)
- CIVIS: 0–100 (prestigio cívico)

## Alineación activa (con histéresis)
- B = 10 (histéresis)
- Activa HEAT si: HEAT ≥ CIVIS + B
- Activa CIVIS si: CIVIS ≥ HEAT + B
- Si ninguna condición se cumple → Neutral

**Cooldown de lealtad:** 48 horas (tiempo mínimo desde el último cambio de bando para poder **reclamar** niveles altos del nuevo bando).

## Progresión por puntuación → nivel elegible
- 1–10 → +1
- 11–20 → +2
- 21–30 → +3
- 31–40 → +4
- 41–50 → +5
- 51–60 → +6
- 61–70 → +7
- 71–85 → +8
- 86–100 → +9
- 0 → nivel 0 (neutro, sin progreso de rama)

## Exclusividad por bando
- Niveles **+7 / +8 / +9**: **solo equipables** si el bando activo coincide.
- Niveles **+1…+6** del bando opuesto: **cosméticos solamente** (sin ventajas), o bloquearlos por completo (decisión de diseño final: **cosméticos**).

## Entradas de sistema (ejemplos)
- HEAT ↑: actos ilegales, mejoras HEAT altas, disparos/impactos, encargos clandestinos.
- HEAT ↓: enfriar (pago/tiempo en zonas frías), inactividad delictiva.
- CIVIS ↑: servicios públicos (EMS/Mecánico/Taxi/Periodismo/Abogacía), multas pagadas a tiempo, donaciones verificadas, reportes 911 válidos.
- CIVIS ↓: infracciones/mentiras comprobadas, “escándalo” por delitos con CIVIS alto.

## Estados
- `active_branch ∈ {heat, civis, neutral}`
- `eligible_level[heat|civis] ∈ {0..9}`
- `claimed_levels[family][branch] ⊆ {1..9}` (blueprints desbloqueados)
- `equipped_level[family]` (el look/attachments activos)

## Reglas de cambio de bando
- Para cambiar a HEAT/CIVIS activo debe cumplirse la histéresis.
- Tras cambiar, se activa **cooldown de lealtad (48h)**: durante ese tiempo **no se pueden reclamar** niveles +7/+8/+9 del nuevo bando (sí usar +1…+6 según regla cosmética).
