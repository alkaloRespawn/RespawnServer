# respawn_weapons (placeholder)

## Objetivo
- Representar catálogo por familia/branch/level (skins + attachments + perk note)
- Estados: Elegible/Desbloqueado/Equipado por jugador
- Integración con talleres (reclamo) y `respawn_alignment` (llaves de elegibilidad)

## Estados/Storage (futuro)
- player_weapon_catalog[family][branch] = set{levels}
- player_equipped_level[family]
- ascensions[family] (desbloqueos de chasis superior por rama)

## Eventos/Exports (plan)
- server export: GetCatalogEntry(family, branch, level) -> data
- server event: respawn:weapons:claimBlueprint(family, branch, level)
- server event: respawn:weapons:equipLevel(family, level)
- server export: CanEquipLevel(playerId, family, level) (chequea branch activo)
- server export: UnlockAscension(playerId, family, branch) (al reclamar +9)

## Reglas
- +7/+8/+9 requieren branch activo y no estar en cooldown de lealtad
- +1..+6 del bando opuesto = cosmético (sin bonus) o bloqueado (según setting)

# respawn_weapons
- Catálogo de skins/attachments por familia, rama y nivel (+1..+9).
- Estados por jugador: elegible, reclamado (blueprint), equipado.
- Reglas de exclusividad +7/+8/+9 (bando activo).

## Exports (planeados)
- GetCatalogEntry(family, branch, level)
- ClaimBlueprint(playerId, family, branch, level)
- EquipLevel(playerId, family, level)
- UnlockAscension(playerId, family, branch)
