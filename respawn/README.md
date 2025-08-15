
# Respawn — Documento de Diseño y Guía Conceptual
*Proyecto de servidor FiveM (QBCore) con progresión dual **HEAT / CIVIS**, árbol de armas por niveles y talleres con colas. Este README explica la **idea global**, el **diseño de juego**, las **herramientas usadas**, los **flujos** y las **mejores prácticas**. No incluye código: es la **visión y especificación**.*

---

## 1) Visión General

**Respawn** es un servidor de rol y acción con ADN de **MMORPG**: el progreso del jugador se construye a través de **elecciones morales** y **mejoras de equipo**. Toda la experiencia gira en torno a un **sistema de alineamiento** con dos ramas:

- **HEAT** → Fantasía de “forajido carismático”: crimen, contrabando, golpes, prestigio en el submundo.
- **CIVIS** → Fantasía de “buen ciudadano”: oficios regulados, contratos, apoyo comunitario, reputación cívica.

Ambas rutas ofrecen **progresión de armas** por familias y niveles **0 → ±1…±9**, **desbloqueos persistentes**, **apariencias** cada vez más “bonitas/limpias” (CIVIS) o “afiladas/amenazantes” (HEAT), y **attachments** al avanzar. La clave: **no se borra lo pasado**, se **desbloquea** y **se conserva** (con bloqueos de lealtad si cambias de bando).

**Públicos objetivo**: jugadores de roleplay que buscan progresión persistente + amantes del gunplay de GTA con metas claras a medio/largo plazo. Dos servidores hermanos: **ES** e **EN** (comunidades separadas).

---

## 2) Pilares de Diseño

1. **Elección con consecuencias**: HEAT y CIVIS abren caminos, cierran otros y definen estética, contratos y recompensas.
2. **Progresión clara y visible**: familias → grupos → niveles. El jugador siempre sabe qué falta para desbloquear lo siguiente.
3. **Desbloqueos persistentes y coleccionismo**: todo lo ganado se conserva (skins, attachments, familias), salvo **bloqueos de lealtad** al cruzar de rama en niveles altos.
4. **Economía controlada** (sinks/sources) para que “mejorar +9” siga siendo aspiracional, no trivial.
5. **Experiencia social**: trabajos, facciones, patrullas y eventos que refuercen la identidad de rama.
6. **Fair play**: validaciones server-side, logs y antifraude; progresión **earned, not bought** (cumpliendo políticas).

---

## 3) Fantasías y Fantasma del Jugador

- **HEAT**: piezas de aspecto improvisado que se vuelven “pro” al avanzar, contrabando, persecuciones, riesgos, reputación en barrios “calientes”.
- **CIVIS**: estética de servicio profesional, certificaciones, contratos legales, licencias, reputación con instituciones/empresas.
- **Neutral → Decantado**: al principio eres **neutro** (nivel 0), poco a poco tu juego te empuja a que el servidor te reconozca **por tus actos**.

---

## 4) Alineamiento HEAT / CIVIS

### 4.1. Fuentes de puntuación
- **HEAT**: robos, ventas ilegales, contrabando, evasión policial, misiones de bandas, corrupción.
- **CIVIS**: taxis, mecánico, EMS, limpieza, contratos públicos, donaciones, asistencia a eventos comunitarios, cumplimiento legal.
- **Ajustes finos**: acciones de poco impacto suman/restan poco; hitos (p.ej., “operación mayor” o “contrato AA”) mueven la aguja más.

### 4.2. Umbrales y rama activa
- Se evalúan **dos métricas** (0–100): `heat`, `civis`.  
- **Rama activa** = la **mayor** en el momento (con histéresis opcional para evitar “oscilación”).
- Mapeo a **elegibilidad de nivel**: 0..9 según el rango de tu puntuación (ej. 0–9, 10–19…90–100).

### 4.3. Bloqueos de lealtad (niveles altos)
- A partir de **niveles 7–9**, si cambias de rama (o la opuesta supera a la actual), **pierdes acceso** a lo mejor de la otra.
- Evita “cherry-picking” de top tier en ambas rutas.

---

## 5) Progresión de Armas

### 5.1. Estructura
- **Cuchillo (nivel 0)**: primer “check-in” de progresión. No tiene subniveles; te habilita a empezar la cadena.  
- **Familias** (p.ej., `pistol9mm`, `smg_compact`, `rifle556`…): cada una con niveles **0 → ±1…±9**.  
- **Grupos**: paquetes de familias; completar **+9/-9 de todas las familias** del grupo abre el **siguiente grupo**.

### 5.2. Niveles y estética
- **Nivel 0** es **neutro**.  
- **HEAT**: +1 “fea / remendada” → +9 “obra maestra criminal”.  
- **CIVIS**: -1 “servicio básico” → -9 “certificada premium”.  
- Las apariencias y **attachments** refuerzan el storytelling: linternas tácticas, miras, empuñaduras, cargadores, supresores legales/ilegales, etc.

### 5.3. Desbloqueo vs evolución
- **No sustituyes** una versión por otra: **desbloqueas** niveles y quedan **disponibles** (coleccionismo, loadouts).
- Al alcanzar **+9/-9** en una familia, pueden abrirse **nuevas familias** en el mismo grupo o **el siguiente grupo**.

### 5.4. Armas exclusivas por rama
- Hay **familias exclusivas** para HEAT y **otras para CIVIS**.  
- Al cruzar el umbral, **máximos** del contrario quedan **bloqueados** (sigues “poseyendo” lo ganado, pero no equipas top tier).

---

## 6) Talleres (Workshops)

- **Dos talleres**: **Clandestino (HEAT)** y **Corporativo (CIVIS)**.
- **Flujo**: “Reclamar” (nivel N) → pagas **dinero**, cedes **materiales** (si se configuran) → entras en **cola** → **tiempo** → **listo** para recoger.
- **Costes**: por nivel (curva creciente). Materiales pueden variar por rama (p.ej., HEAT: chatarra/electrónicos; CIVIS: componentes certificados).
- **Validaciones**: elegibilidad por rama, nivel y progreso en grupos.
- **Órdenes persistentes**: si sales del server, el pedido sigue contando tiempo.

> *Opcional*: “PEDIDO EXPRESS” con sobrecoste, limitaciones diarias/semana, y anuncios a la facción contraria (riesgo/recompensa).

---

## 7) Integración de Rol (MMORPG + RP)

- **CIVIS**: oficios (Taxi, Mecánico, EMS, Basurero, Transporte legal, Licitaciones), reputación por puntualidad, siniestros y satisfacción.
- **HEAT**: robos, logística ilegal, hackeos básicos, “contratos” con NPCs, reputación con bandas (misiones de fidelidad).
- **Policía / Justicia**: checks de armas, licencias, decomisos, juicios RP (CIVIS sube si colaboras; HEAT sube si te fugas o chantajeas).
- **Eventos de ciudad**: ferias, Photo Hunts, carreras legales/ilegales, campañas cívicas, avisos públicos.
- **Grupos/Jefaturas**: líderes pueden abrir “ventanas de contrato” (bonus temporales de progreso o materiales).

---

## 8) Economía

### 8.1. Entradas (Sources)
- Sueldos base por oficio, contratos, comisiones por servicio, recompensas por misiones.
- Recompensas ilegales (cautela: control de riesgo, cooldowns, alertas).

### 8.2. Salidas (Sinks)
- Talleres (dinero + materiales), multas, licencias, alquileres/seguros, mantenimiento de vehículos, “impuestos” (CIVIS) y “peajes” clandestinos (HEAT).

### 8.3. Control de inflación
- Curva de costes de taller progresiva; límites diarios a órdenes; “materiales raros” (drop controlado).
- Supervisión con telemetría (KPI de M1/M2).

---

## 9) UX/UI & Accesibilidad

- **NUI**: panel de progreso (familias, estado: Bloqueado/Elegible/Desbloqueado), detalle por nivel (apariencia/attachments/coste/tiempo).
- **HUD**: rama activa, barra/medidor de progreso y avisos contextuales (p.ej., “te faltan materiales X”).
- **Mensajería clara**: errores legibles, sin códigos técnicos en cara de jugador.
- **Localización**: **ES** y **EN** desde el primer día (strings de UI + mensajes).
- **Accesibilidad**: contraste alto, tamaños legibles, navegación por teclado, tiempos suficientes para lectura.

---

## 10) Herramientas y Paquete Técnico

> *Este apartado es informativo: el repositorio ya contiene los recursos necesarios y bridges. Este README no incluye scripts.*

- **Marco MP**: FiveM (FXServer/txAdmin).  
- **Framework**: **QBCore**.  
- **Base de datos**: **oxmysql** (MariaDB/MySQL).  
- **Inventario actual**: **db-inventory** (alternativa: qb-inventory).  
- **Opcionales**: `ox_lib` (utilidades/UI), `ox_target` o `qb-target` (interacciones), `pma-voice` + `qb-radio` (voz), `bob74_ipl` (map extras).  
- **UI**: NUI (HTML/CSS/JS).  
- **Logs/Telemetría**: webhooks (Discord) o panel propio (más adelante).

---

## 11) Seguridad y Anti-cheat

- **Autoridad server-side** en dinero, órdenes de taller y desbloqueos.
- **Validaciones** de elegibilidad (rama, nivel, progresión por grupos).
- **Rate limiting** en eventos sensibles, **cooldowns** y **sanciones**.
- **Auditoría**: log de acciones clave (quién, qué, cuándo, desde dónde).
- **Integridad**: no confiar en datos del cliente para decisiones críticas.

---

## 12) Contenido Inicial (MVP) y Extensiones

### MVP (hito Alpha)
- 1 grupo con 3 familias (pistola, SMG, rifle) + **cuchillo 0**.
- Niveles 0→1/2 por rama (para validar el ciclo).
- Talleres activos con colas y costes básicos.
- UI mínima: estados y reclamación test.

### Extensiones
- Más familias y grupos, apariencias y attachments por nivel.
- Misiones de rama, contratos periódicos, eventos ciudad.
- Efectos de arma (recoil/damage sutil) y audio/partículas temáticos.
- Contratos EXPRESS, materiales raros, progresión social (rangos/placas).

---

## 13) Onboarding y Retención

- **Tutorial express** en spawn: elegir fantasía, reclamar cuchillo, hacer primer encargo.
- **Guías** in-game (NUI) y un **Job Center** con contratos de inicio.
- **Misiones diarias/semanales**: objetivos cortos, recompensas útiles.
- **Reconocimiento social**: títulos, iconos en scoreboard/HUD, “vitrina” de top logros (sin pay-to-win).

---

## 14) Gobernanza de Comunidad

- **Reglas RP** claras: miedo al arma, valor a la vida, metagaming, powergaming, failRP.
- **Moderación**: escalado de sanciones, apelaciones, transparencia.
- **Eventos staff**: balanceados entre HEAT y CIVIS.
- **Comunidades separadas** ES/EN (infra y reglamento por idioma).

---

## 15) Legal y Monetización

- Cumplimiento con políticas Rockstar/Cfx.re: **no** loot boxes, **no** cripto/NFT, **no** venta de moneda in-game, **no** IPs de terceros sin permiso.
- Si se monetiza: **Tebex** (rutas cosméticas, prioridad de cola, paquetes de apoyo **no** pay-to-win).
- Separación total de GTA Online oficial. Avisos legales en Discord/foros.

---

## 16) Roadmap (propuesto)

- **M1 (2–3 semanas)**: MVP jugable en local (Alpha cerrada).  
- **M2 (2–4 semanas)**: balance, materiales reales, +familias, QA con 10–20 jugadores.  
- **M3**: UI avanzada (árbol visual), efectos de armas, contratos EXPRESS.  
- **M4**: Eventos ciudad, KPIs de economía, preparación de VPS.  
- **M5**: Beta abierta (ES), réplica infra para EN.

> Los tiempos son orientativos; priorizar **calidad** y **estabilidad**.

---

## 17) KPIs y Telemetría

- **Engagement**: horas/jugador, retención 1/7 días, DAU/MAU.  
- **Progresión**: % jugadores por nivel (0..9), familias completadas, tiempos medios de cola.  
- **Economía**: inflow/outflow, precios efectivos, tasa de uso de EXPRESS, rareza de materiales.  
- **Moderación**: reportes/hora, ratio de apelaciones, reincidencia.  

---

## 18) QA y Pruebas

- **Unitarias**: validaciones de elegibilidad y bloqueos de lealtad.  
- **Integración**: pedidos → cobros → cola → entrega.  
- **Carga**: 10–30 jugadores, picos de órdenes simultáneas.  
- **UX**: claridad de mensajes y tutorial.  
- **Exploit hunt**: duplicaciones, bypass de costes, spam de eventos.

---

## 19) Operación y Migración a VPS

- **Local**: desarrollo, test y perf base.  
- **VPS**: cuando el build sea estable → puertos, backups (DB + recursos), health checks (txAdmin), rotación de logs, mitigación DDoS.
- **Backups**: diarios (DB) + semanales (full). Pruebas de restauración.
- **Versionado**: ramas dev/main, changelog, comunicación de actualizaciones a la comunidad.

---

## 20) FAQ (rápida)

- **¿Puedo tener top tiers de ambos bandos?** No. Los **bloqueos de lealtad** lo impiden.
- **¿Pierdo mis skins al cambiar de bando?** No se borran, pero **no podrás equipar niveles altos** del contrario.
- **¿Cómo subo mi rama?** Jugando acorde a su fantasía (misiones/contratos/acciones propias).
- **¿Hay pay-to-win?** No. Monetización (si la hay) será cosmética/servicios no competitivos.
- **¿Puedo jugar solo legal o solo ilegal?** Sí, el contenido de ambas ramas se ha diseñado para ser “completo”.

---

## 21) Glosario

- **Familia**: conjunto de armas del mismo tipo (p.ej., `pistol9mm`).  
- **Grupo**: lote de familias que debes completar para abrir el siguiente.  
- **Nivel**: 0 → ±1..±9; define apariencia/attachments/elegibilidad.  
- **Taller**: lugar donde creas **órdenes** (cola, coste, tiempo) para desbloquear niveles.  
- **Lealtad**: restricción que evita top tiers de ambas ramas a la vez.

---

### Cierre

**Respawn** busca un equilibrio entre **rol**, **progresión satisfactoria** y **fantasías claras**. La meta: que cada sesión te acerque a un hito visible (una skin, un attachment, una familia, un grupo), y que tus elecciones **construyan tu identidad** en la ciudad.  
Para cualquier cambio, refuerza estos pilares: **elección con consecuencias**, **progresión clara**, **economía sana** y **fair play**.
