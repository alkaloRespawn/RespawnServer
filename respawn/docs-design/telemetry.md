# Respawn — Telemetría & KPIs

## Eventos
- alignment_state_changed
  - props: player_id, from, to, heat_score, civis_score, ts
- level_eligible
  - props: player_id, family, branch, level, score, ts
- level_claimed
  - props: player_id, family, branch, level, cost_cash, cost_materials, workshop_type, ts
- level_equipped
  - props: player_id, family, branch, level, ts
- equip_blocked_by_alignment
  - props: player_id, family, branch_required, level, active_branch, ts
- ascension_unlocked
  - props: player_id, family_from, branch, family_to, ts
- ascension_claimed
  - props: player_id, family_to, cost_cash, cost_materials, workshop_type, ts
- economy_sink
  - props: player_id, type (workshop|cooldown|license|repair|rent|tax), amount, ts
- economy_source
  - props: player_id, type (contract_legal|contract_illegal|service|event), amount, ts
- attachment_usage_sample
  - props: player_id, family, branch, level, attachments[], shots, hits, ttk_sample, ts

## KPIs
- % jugadores con **HEAT activo** vs **CIVIS activo**
- % jugadores que alcanzan **+7/+8/+9**
- Ratio **claim** vs **eligible** por nivel (fugas de conversión)
- % cambios de bando / día y **tiempo medio** entre cambios
- Top familias/skins equipadas — por rama
- Economía neta/día per cápita (source vs sink)
- Distribución de **workshop_type** (legal vs clandestino)
