const tablet = document.getElementById('tablet');
const subtitle = document.getElementById('subtitle');
const closeBtn = document.getElementById('closeBtn');
const views = {
  home: document.getElementById('homeView'),
  boosting: document.getElementById('boostingView'),
  mechanic: document.getElementById('mechanicView')
};
const appsEl = document.getElementById('apps');
const boostingSummary = document.getElementById('boostingSummary');
const boostContracts = document.getElementById('boostContracts');
const startBoostBtn = document.getElementById('startBoostBtn');
const scanVehicleBtn = document.getElementById('scanVehicleBtn');
const toggleDutyBtn = document.getElementById('toggleDutyBtn');
const showCraftingBtn = document.getElementById('showCraftingBtn');
const mechanicStatus = document.getElementById('mechanicStatus');
const diagnosticPanel = document.getElementById('diagnosticPanel');
const repairButtons = document.getElementById('repairButtons');
const craftingPanel = document.getElementById('craftingPanel');
let mechanicDiagnostic = null;
let mechanicRecipes = {};

function nui(action, data = {}) {
  return fetch(`https://${GetParentResourceName()}/${action}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
  }).then((res) => res.json());
}

function showView(name) {
  Object.values(views).forEach(v => v.classList.add('hidden'));
  views[name].classList.remove('hidden');
}

function renderApps(apps) {
  appsEl.innerHTML = '';
  apps.forEach((app) => {
    const card = document.createElement('button');
    card.className = 'appCard';
    card.style.borderColor = `${app.accent || '#ffffff'}44`;
    card.innerHTML = `<div class="appIcon">${app.icon || 'APP'}</div><div class="appLabel">${app.label}</div>`;
    card.addEventListener('click', () => {
      if (app.id === 'boosting') {
        showView('boosting');
        nui('requestBoostingData');
      } else if (app.id === 'mechanic') {
        showView('mechanic');
        loadMechanicRecipes();
      }
    });
    appsEl.appendChild(card);
  });
}

function renderBoosting(data) {
  const boosting = data.boosting || { rep: 0, contracts: [] };
  boostingSummary.innerHTML = `<div class="cardRow"><span>Reputation</span><strong>${boosting.rep}</strong></div>`;
  boostContracts.innerHTML = '';
  boosting.contracts.forEach((contract) => {
    const item = document.createElement('div');
    item.className = 'card';
    item.innerHTML = `
      <div class="cardRow"><span>Tier</span><strong>${contract.tier}</strong></div>
      <div class="cardRow"><span>Min Rep</span><strong>${contract.minRep}</strong></div>
      <div class="cardRow"><span>Payout</span><strong>$${contract.payout.min} - $${contract.payout.max}</strong></div>
      <div class="cardRow"><span>Status</span><strong>${contract.unlocked ? 'Unlocked' : 'Locked'}</strong></div>`;
    boostContracts.appendChild(item);
  });
}

function renderMechanicDiagnostic(diag) {
  mechanicDiagnostic = diag;
  mechanicStatus.textContent = `${diag.shopLabel || 'Mechanic Shop'} • ${diag.model} | Plate ${diag.plate}`;

  const metrics = document.createElement('div');
  metrics.className = 'metricGrid';
  metrics.innerHTML = [
    ['Engine', `${diag.engine}%`],
    ['Body', `${diag.body}%`],
    ['Fuel Tank', `${diag.petrol}%`],
    ['Fuel Level', `${diag.fuelLevel}%`]
  ].map(([label, value]) => `<div class="metricBox"><div class="metricLabel">${label}</div><div class="metricValue">${value}</div></div>`).join('');

  const mods = document.createElement('div');
  mods.className = 'card';
  mods.innerHTML = `<div class="sectionHeader">Installed Mods</div>${diag.mods.map((mod) => `<div class="listRow"><span>${mod.label}</span><strong>${mod.value}</strong></div>`).join('')}`;

  const damage = document.createElement('div');
  damage.className = 'card';
  damage.innerHTML = `<div class="sectionHeader">Damage</div>
    ${diag.damage.tyres.map((tyre) => `<div class="listRow"><span>${tyre.label}</span><strong>${tyre.burst ? 'Burst' : 'OK'}</strong></div>`).join('')}
    ${diag.damage.doors.map((door) => `<div class="listRow"><span>Door ${door.index}</span><strong>${door.damaged ? 'Damaged' : 'OK'}</strong></div>`).join('')}`;

  const history = document.createElement('div');
  history.className = 'card';
  history.innerHTML = `<div class="sectionHeader">Service History</div>${(diag.history || []).length ? diag.history.map((entry) => `<div class="historyItem">${entry.label} by ${entry.mechanic}</div>`).join('') : '<div class="statusLine">No recorded services yet.</div>'}`;

  diagnosticPanel.innerHTML = '';
  diagnosticPanel.append(metrics, mods, damage, history);

  const repairs = [['engine', 'Engine Repair'], ['body', 'Body Repair'], ['tyres', 'Tyre Replacement'], ['electronics', 'Electronics Service'], ['fullservice', 'Full Service']];
  repairButtons.innerHTML = '';
  repairs.forEach(([repairId, label]) => {
    const btn = document.createElement('button');
    btn.textContent = label;
    btn.addEventListener('click', async () => {
      if (!mechanicDiagnostic) return;
      await nui('startMechanicRepair', { repairId, netId: mechanicDiagnostic.netId, plate: mechanicDiagnostic.plate });
    });
    repairButtons.appendChild(btn);
  });
}

async function loadMechanicRecipes() {
  const result = await nui('requestMechanicRecipes');
  mechanicRecipes = result.recipes || {};
  renderCrafting();
}

function renderCrafting() {
  craftingPanel.innerHTML = '';
  Object.entries(mechanicRecipes).forEach(([recipeId, recipe]) => {
    const card = document.createElement('div');
    card.className = 'card';
    const materials = Object.entries(recipe.materials || {}).map(([item, amount]) => `<div class="listRow"><span>${item}</span><strong>${amount}</strong></div>`).join('');
    card.innerHTML = `<div class="cardRow"><span>${recipe.label}</span><button data-recipe="${recipeId}">Craft</button></div>${materials}`;
    card.querySelector('button').addEventListener('click', async () => {
      await nui('craftMechanicRecipe', { recipeId });
    });
    craftingPanel.appendChild(card);
  });
}

window.addEventListener('message', (event) => {
  const { action, data } = event.data;
  if (action === 'boot') {
    tablet.classList.remove('hidden');
    subtitle.textContent = 'Booting…';
    return;
  }
  if (action === 'open') {
    subtitle.textContent = data.playerName ? `Welcome ${data.playerName}` : 'Ready';
    tablet.classList.remove('hidden');
    showView('home');
    renderApps(data.apps || []);
    renderBoosting(data);
    return;
  }
  if (action === 'close') { tablet.classList.add('hidden'); return; }
  if (action === 'boostingData') { renderBoosting(data); return; }
  if (action === 'mechanicDiagnostic') { renderMechanicDiagnostic(data); return; }
  if (action === 'mechanicHistory' && mechanicDiagnostic && mechanicDiagnostic.plate === data.plate) {
    mechanicDiagnostic.history = data.history || [];
    renderMechanicDiagnostic(mechanicDiagnostic);
  }
});

closeBtn.addEventListener('click', () => nui('close'));
startBoostBtn.addEventListener('click', () => nui('startBoostContract'));
scanVehicleBtn.addEventListener('click', async () => {
  const result = await nui('scanMechanicVehicle');
  mechanicStatus.textContent = result.ok ? 'Vehicle scanned.' : (result.message || 'Scan failed.');
  if (result.ok && result.payload) renderMechanicDiagnostic(result.payload);
});
toggleDutyBtn.addEventListener('click', () => nui('mechanicToggleDuty'));
showCraftingBtn.addEventListener('click', () => craftingPanel.classList.toggle('hidden'));
document.querySelectorAll('[data-back="home"]').forEach((btn) => btn.addEventListener('click', () => showView('home')));
document.addEventListener('keyup', (event) => { if (event.key === 'Escape') nui('close'); });
