Progression = {
  starter = { "knife_basic" },

  -- Por rama: grupos secuenciales. Debes llevar las familias del grupo ACTUAL a +9 (o -9)
  -- para que se habilite reclamar nivel 0 del siguiente grupo de esa rama.
  heat = {
    { "pistol9mm", "smg_compact" }, -- Grupo 1 (tras cuchillo)
    { "rifle556" }                   -- Grupo 2
  },
  civis = {
    { "pistol9mm", "smg_compact" }, -- Grupo 1
    { "rifle556" }                   -- Grupo 2
  },

  firstBatchMax = 2  -- al salir de cuchillo puedes reclamar hasta 2 familias de nivel 0 del Grupo 1 (tu rama)
}
