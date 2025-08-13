// Utilidad mínima NUI
const Nui = {
  post: (name, data={}) =>
    fetch(`https://respawn_ui/${name}`, { method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify(data) })
      .then(r => r.json()).catch(() => ({}))
};

const AppState = {
  locale: 'es-ES',
  locales: {},
  data: null, // weapons + alignment
  familyKey: null,
  activeBranch: 'neutral', // mock por ahora
  claimed: {}, // mock { [family]: { heat:[levels], civis:[levels] } }
  eligible: { heat: 0, civis: 0 }, // mock
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
  const res = await fetch(`locales/${lang}.json`);
  AppState.locales = await res.json();
}

async function loadData() {
  const [wep, align] = await Promise.all([
    fetch('data/weapons_catalog.json').then(r => r.json()),
    fetch('data/alignment.config.json').then(r => r.json())
  ]);
  AppState.data = { wep, align };
  // Mock elegible: +5 civis / +3 heat para ver estados
  AppState.eligible = { heat: 3, civis: 5 };
  // Por defecto primera familia
  AppState.familyKey = Object.keys(wep.families)[0];
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
  const active = AppState.activeBranch; // 'heat' | 'civis' | 'neutral'
  if (claimedLevels.includes(level)) return { cls:'claimed', text:t('status_claimed') };

  const eligibleMax = AppState.eligible[branch] || 0;
  if (level <= eligibleMax) {
    // Si es nivel alto exclusivo y el bando no coincide → bloqueado por bando
    const high = AppState.data.align.exclusiveHighTiers || [7,8,9];
    if (high.includes(level) && active !== branch) return { cls:'blocked', text:t('status_blocked_by_branch') };
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

    const nm = document.createElement('div'); nm.className='name'; nm.textContent = `+${entry.level} — ${entry.skin_name}`;
    const at = document.createElement('div'); at.className='atts'; at.textContent = (entry.attachments||[]).join(', ') || '—';

    const stInfo = levelState(branch, entry.level, claimedLevels);
    const st = document.createElement('div'); st.className = `state ${stInfo.cls}`; st.textContent = stInfo.text;

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
  // HUD mock (solo para pintar algo)
  els.hudHeat.style.width = '35%';
  els.hudCivis.style.width = '55%';
  els.hudRep.style.width = '20%';
}

function openModal(branch, entry) {
  // Determinar si es HEAT o CIVIS para lugar/coste/tiempo mock
  const place = branch === 'civis' ? t('modal_claim_place_civis') : t('modal_claim_place_heat');
  els.modalTitle.textContent = t('modal_claim_title', { level: `+${entry.level}`, skin: entry.skin_name });
  els.valPlace.textContent = place;
  els.valCost.textContent = '$ —';
  els.valTime.textContent = '—';
  els.valAtts.textContent = (entry.attachments||[]).join(', ') || '—';

  els.btnClaim.onclick = async () => {
    const r = await Nui.post('claim', { family: AppState.familyKey, branch, level: entry.level });
    closeModal();
  };
  els.btnEquip.onclick = async () => {
    const r = await Nui.post('equip', { family: AppState.familyKey, level: entry.level });
    closeModal();
  };
  els.btnCancel.onclick = closeModal;

  els.modal.classList.remove('hidden');
}
function closeModal(){ els.modal.classList.add('hidden'); }

function closeUI(){
  els.app.classList.add('hidden');
  Nui.post('close', {});
}

els.btnClose.addEventListener('click', closeUI);
els.familySelect.addEventListener('change', (e) => { AppState.familyKey = e.target.value; renderAll(); });

window.addEventListener('message', async (ev) => {
  const data = ev.data || {};
  if (data.action === 'open') {
    AppState.locale = data.locale || 'es-ES';
    await loadLocale(AppState.locale);

    // Pide estado al server:
    const res = await Nui.post('ui_ready', {});
    if (res && res.state) {
      const st = res.state;
      AppState.data = { wep: st.catalog, align: {
        hysteresis: 10,
        loyaltyCooldownHours: 48,
        exclusiveHighTiers: [7,8,9]
      }};
      AppState.familyKey = Object.keys(st.catalog.families)[0];
      AppState.activeBranch = st.activeBranch || 'neutral';
      AppState.eligible = st.eligible || {heat:0,civis:0};
      AppState.claimed = st.claimed || {};
    }

    renderAll();
  }
  if (data.action === 'close') {
    closeUI();
  }

  // (NUEVO) El cliente LUA nos envía estado actualizado
  if (data.action === 'state' && data.state) {
    const st = data.state;
    AppState.data = { wep: st.catalog, align: {
      hysteresis: 10,
      loyaltyCooldownHours: 48,
      exclusiveHighTiers: [7,8,9]
    }};
    AppState.familyKey = AppState.familyKey || Object.keys(st.catalog.families)[0];
    AppState.activeBranch = st.activeBranch || 'neutral';
    AppState.eligible = st.eligible || {heat:0,civis:0};
    AppState.claimed = st.claimed || {};
    renderAll();
  }
});

