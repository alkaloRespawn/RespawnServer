
// NUI helper
const RES = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'respawn_ui';
const Nui = {
  post: (name, data={}) =>
    fetch(`https://${RES}/${name}`, { method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify(data) })
      .then(r => r.json()).catch(() => ({}))
};

const AppState = {
  locale: 'es-ES',
  locales: {},
  data: null, // weapons + alignment
  familyKey: null,
  activeBranch: 'neutral',
  claimed: {},
  eligible: { heat: 0, civis: 0 },
};

const els = {
  app: document.getElementById('app'),
  title: document.getElementById('title'),
  tagHeat: document.getElementById('tag-heat'),
  tagCivis: document.getElementById('tag-civis'),
  colHeatTitle: document.getElementById('col-heat-title'),
  colCivisTitle: document.getElementById('col-civis-title'),
  levelsHeat: document.getElementById('levels-heat'),
  levelsCivis: document.getElementById('levels-civis'),
  familySelect: document.getElementById('family-select'),
  neutralText: document.getElementById('neutral-text'),
  btnClose: document.getElementById('btn-close'),
  hudHeat: document.querySelector('.fill.heat'),
  hudCivis: document.querySelector('.fill.civis'),
  hudRep: document.querySelector('.fill.rep'),

  modal: document.getElementById('modal'),
  modalTitle: document.getElementById('modal-title'),
  lblCost: document.getElementById('lbl-cost'),
  lblTime: document.getElementById('lbl-time'),
  lblPlace: document.getElementById('lbl-place'),
  valCost: document.getElementById('val-cost'),
  valTime: document.getElementById('val-time'),
  valPlace: document.getElementById('val-place'),
  valAtts: document.getElementById('val-atts'),
  btnClaim: document.getElementById('btn-claim'),
  btnEquip: document.getElementById('btn-equip'),
  btnCancel: document.getElementById('btn-cancel'),
};

async function loadLocale(lang) {
  try {
    const res = await fetch(`locales/${lang}.json`);
    if (res.ok) {
      AppState.locales = await res.json();
      return;
    }
  } catch {}
  // Fallback mínimo
  AppState.locales = {
    panel_title: 'Respawn — HEAT / CIVIS',
    branch_heat: 'HEAT',
    branch_civis: 'CIVIS',
    level_neutral: 'Progreso neutral hasta +0',
    btn_claim: 'Reclamar',
    btn_equip: 'Equipar',
    btn_close: 'Cerrar',
    hud_heat: 'HEAT',
    hud_civis: 'CIVIS',
    hud_reputation: 'REP',
    modal_claim_cost: 'Coste',
    modal_claim_time: 'Tiempo',
    modal_claim_place: 'Lugar',
    status_claimed: 'Reclamado',
    status_blocked_by_branch: 'Bloqueado por bando',
    status_eligible: 'Reclamable',
    status_locked: 'Bloqueado',
    modal_claim_title: 'Nivel {level} — {skin}'
  };
}

function t(key, vars={}) {
  let s = AppState.locales[key] || key;
  for (const k in vars) s = s.replaceAll(`{${k}}`, vars[k]);
  return s;
}

function setLocaleTexts() {
  els.title.textContent = t('panel_title');
  els.tagHeat.textContent = t('branch_heat');
  els.tagCivis.textContent = t('branch_civis');
  els.colHeatTitle.textContent = t('branch_heat');
  els.colCivisTitle.textContent = t('branch_civis');
  els.neutralText.textContent = t('level_neutral');

  els.btnClaim.textContent = t('btn_claim');
  els.btnEquip.textContent = t('btn_equip');
  els.btnCancel.textContent = t('btn_close');

  els.hudHeat.parentElement.querySelector('span').textContent = t('hud_heat');
  els.hudCivis.parentElement.querySelector('span').textContent = t('hud_civis');
  els.hudRep.parentElement.querySelector('span').textContent = t('hud_reputation');

  els.lblCost.textContent = t('modal_claim_cost');
  els.lblTime.textContent = t('modal_claim_time');
  els.lblPlace.textContent = t('modal_claim_place');
}

function fillFamilySelect() {
  const families = AppState.data.wep.families;
  els.familySelect.innerHTML = '';
  Object.keys(families).forEach(key => {
    const opt = document.createElement('option');
    opt.value = key;
    opt.textContent = families[key].display_name;
    if (key === AppState.familyKey) opt.selected = true;
    els.familySelect.appendChild(opt);
  });
}

function levelState(branch, level, claimedLevels) {
  if (claimedLevels.includes(level)) return { cls:'claimed', text:t('status_claimed') };
  const eligibleMax = AppState.eligible[branch] || 0;
  if (level <= eligibleMax) {
    const high = (AppState.data.align && AppState.data.align.exclusiveHighTiers) || [];
    if (high.includes(level) && AppState.activeBranch !== branch) return { cls:'blocked', text:t('status_blocked_by_branch') };
    return { cls:'eligible', text:t('status_eligible') };
  }
  return { cls:'locked', text:t('status_locked') };
}

function renderColumn(branch) {
  const listEl = branch === 'heat' ? els.levelsHeat : els.levelsCivis;
  listEl.innerHTML = '';
  const fam = AppState.data.wep.families[AppState.familyKey];
  const rows = fam.levels[branch];
  const claimedLevels = ((AppState.claimed[AppState.familyKey] || {})[branch]) || [];

  rows.forEach(entry => {
    const li = document.createElement('li');
    li.className = 'level';

    const lv = entry.level;
    let levelLabel = '0';
    if (lv > 0) levelLabel = (branch === 'civis') ? `-${lv}` : `+${lv}`;

    const nm = document.createElement('div');
    nm.className='name';
    nm.textContent = `${levelLabel} — ${entry.skin_name}`;

    const at = document.createElement('div');
    at.className='atts';
    at.textContent = (entry.attachments||[]).join(', ') || '—';

    const stInfo = levelState(branch, entry.level, claimedLevels);
    const st = document.createElement('div');
    st.className = `state ${stInfo.cls}`;
    st.textContent = stInfo.text;

    li.appendChild(nm); li.appendChild(at); li.appendChild(st);
    li.addEventListener('click', () => openModal(branch, entry));
    listEl.appendChild(li);
  });
}

function renderAll() {
  setLocaleTexts();
  fillFamilySelect();
  renderColumn('heat');
  renderColumn('civis');

  els.app.classList.remove('hidden');
  // HUD mock updated based on eligible (approximate)
  els.hudHeat.style.width = Math.min(100, (AppState.eligible.heat||0) * 5) + '%';
  els.hudCivis.style.width = Math.min(100, (AppState.eligible.civis||0) * 5) + '%';
  els.hudRep.style.width = '20%';
}

async function openModal(branch, entry) {
  const r = await Nui.post('inspect', { family: AppState.familyKey, branch, level: entry.level });
  const prev = (r && r.preview) || { placeLabel:'—', costCash:0, timeSec:0, materials:{} };

  els.modalTitle.textContent = t('modal_claim_title', { level: (branch==='civis' && entry.level>0 ? `-${entry.level}` : `+${entry.level}`), skin: entry.skin_name });
  els.valPlace.textContent = prev.placeLabel || '—';
  els.valCost.textContent  = (prev.costCash || 0) > 0 ? `$ ${prev.costCash}` : '$ 0';
  els.valTime.textContent  = (prev.timeSec || 0) + 's';
  const mats = prev.materials || {};
  const matsStr = Object.keys(mats).length ? Object.entries(mats).map(([k,v])=>`${k}×${v}`).join(', ') : '—';
  els.valAtts.textContent = (entry.attachments||[]).join(', ') || '—';
  els.valAtts.textContent += (matsStr==='—' ? '' : ` | Mats: ${matsStr}`);

  els.btnClaim.onclick = async () => { await Nui.post('claim', { family: AppState.familyKey, branch, level: entry.level }); closeModal(); };
  els.btnEquip.onclick = async () => { await Nui.post('equip', { family: AppState.familyKey, level: entry.level }); closeModal(); };
  els.btnCancel.onclick = closeModal;

  els.modal.classList.remove('hidden');
}
function closeModal(){ els.modal.classList.add('hidden'); }

function closeUI(){
  els.app.classList.add('hidden');
  Nui.post('close', {});
}

els.btnClose.addEventListener('click', closeUI);

// Single message handler
let isOpen = false;
window.addEventListener('message', async (ev) => {
  const data = ev.data || {};
  if (data.action === 'open') {
    if (isOpen) return;
    isOpen = true;
    document.body.classList.add('is-open');
    document.getElementById('root').removeAttribute('inert');

    AppState.locale = data.locale || 'es-ES';
    await loadLocale(AppState.locale);

    const r = await Nui.post('ui_ready');
    const st = (r && r.state) || {};
    if (st.catalog) {
      AppState.data = { wep: st.catalog, align: st.align || {} };
      AppState.familyKey = Object.keys(st.catalog.families)[0];
      AppState.activeBranch = st.activeBranch || 'neutral';
      AppState.eligible = st.eligible || { heat: 0, civis: 0 };
      AppState.claimed = st.claimed || {};
    }
    renderAll();
  }

  if (data.action === 'close') {
    if (!isOpen) return;
    isOpen = false;
    document.body.classList.remove('is-open');
    document.getElementById('root').setAttribute('inert', '');
    closeUI();
  }

  if (data.action === 'state' && data.state) {
    const st = data.state;
    AppState.data = { wep: st.catalog, align: st.align || {} };
    AppState.familyKey = AppState.familyKey || Object.keys(st.catalog.families)[0];
    AppState.activeBranch = st.activeBranch || 'neutral';
    AppState.eligible = st.eligible || {heat:0,civis:0};
    AppState.claimed = st.claimed || {};
    renderAll();
  }
});

// Close with ESC
document.addEventListener('keydown', (ev) => {
  if (ev.key === 'Escape') {
    ev.preventDefault();
    window.postMessage({ action: 'close' }, '*');
  }
});
