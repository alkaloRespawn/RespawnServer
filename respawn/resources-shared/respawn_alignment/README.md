# respawn_alignment (placeholder)

## Objetivo
- Calcular y exponer `active_branch` (heat/civis/neutral) con histéresis B=10
- Mapear score→nivel elegible (0..9)
- Enforce cooldown de lealtad (48h) para reclamar +7/+8/+9 tras cambio

## Estados/Storage (futuro)
- player_alignment: heat, civis, neutral
- scores: heat_score, civis_score
- timestamps: last_branch_switch

## Eventos/Exports (plan)
- server export: GetActiveBranch(playerId) → 'heat'|'civis'|'neutral'
- server export: GetEligibleLevel(playerId, branch) → 0..9
- server event: respawn:alignment:addHeat / addCivis (validados)
- server event: respawn:alignment:requestBranchSwitch (aplica histéresis)
- server export: CanClaimHighTier(playerId, branch) → respeta cooldown

## Seguridad
- Validación server-authoritative de cambios de score
- Rate limit por acción
- Logs de auditoría

# respawn_alignment
- Expone branch activo con histéresis (B=10) y cooldown de lealtad (48h).
- Mapea scores a nivel elegible 0..9.
- Validación server-side (sin implementación en esta fase).

## Exports (planeados)
- GetActiveBranch(playerId) -> 'heat'|'civis'|'neutral'
- GetEligibleLevel(playerId, branch) -> 0..9
- CanClaimHighTier(playerId, branch) -> bool (respeta cooldown)
