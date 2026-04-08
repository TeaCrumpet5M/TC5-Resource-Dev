const app = document.getElementById('app');
const subtitle = document.getElementById('subtitle');
const officerName = document.getElementById('officerName');
const officerMeta = document.getElementById('officerMeta');
const dutyBadge = document.getElementById('dutyBadge');
const armoryList = document.getElementById('armoryList');
const garageList = document.getElementById('garageList');

let state = {
  isPolice: false,
  isOnDuty: false,
  officer: null,
  armory: { items: [] },
  garage: { vehicles: [] },
  activeTab: 'home'
};

function resourcePost(name, data = {}) {
  fetch(`https://${GetParentResourceName()}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
  });
}

function setTab(tab) {
  state.activeTab = tab;
  document.querySelectorAll('.tab').forEach(el => el.classList.remove('active'));
  document.querySelectorAll('.nav-btn').forEach(el => el.classList.remove('active'));
  document.getElementById(`tab-${tab}`)?.classList.add('active');
  document.querySelector(`.nav-btn[data-tab="${tab}"]`)?.classList.add('active');
}

function applyTheme(theme) {
  if (!theme) return;
  const root = document.documentElement;
  root.style.setProperty('--primary', theme.Primary || '#b10f1f');
  root.style.setProperty('--primary-soft', theme.PrimarySoft || 'rgba(177, 15, 31, 0.18)');
  root.style.setProperty('--bg', theme.Background || '#090909');
  root.style.setProperty('--panel', theme.Panel || '#121212');
  root.style.setProperty('--panel-alt', theme.PanelAlt || '#1a1a1a');
  root.style.setProperty('--border', theme.Border || 'rgba(255,255,255,0.08)');
  root.style.setProperty('--text', theme.Text || '#ffffff');
  root.style.setProperty('--muted', theme.Muted || '#c6c6c6');
  root.style.setProperty('--success', theme.Success || '#2ecc71');
  root.style.setProperty('--error', theme.Error || '#ff4d4f');
  root.style.setProperty('--warning', theme.Warning || '#f4b400');
}

function renderHome() {
  const officer = state.officer || {};
  officerName.textContent = officer.fullName || 'Unknown Officer';
  officerMeta.textContent = state.isPolice
    ? `${officer.gradeLabel || 'Officer'}${officer.callsign ? ` • Callsign ${officer.callsign}` : ''}${officer.badgeNumber ? ` • Badge ${officer.badgeNumber}` : ''}`
    : 'Not in roster';

  subtitle.textContent = state.isPolice
    ? 'Department systems online'
    : 'Roster access required';

  dutyBadge.textContent = state.isOnDuty ? 'ON DUTY' : 'OFF DUTY';
  dutyBadge.className = `badge ${state.isOnDuty ? 'on' : 'off'}`;
}

function renderArmory() {
  armoryList.innerHTML = '';
  (state.armory?.items || []).forEach(item => {
    const card = document.createElement('div');
    card.className = 'list-card';
    card.innerHTML = `
      <p class="label">Kit</p>
      <h4>${item.label}</h4>
      <p>${item.description || 'Duty kit'}</p>
      <div class="list-meta">
        <span>Min Grade: ${item.minGrade ?? 0}</span>
        <button class="primary-btn">Issue Kit</button>
      </div>
    `;
    card.querySelector('button').addEventListener('click', () => resourcePost('claimArmory', { id: item.id }));
    armoryList.appendChild(card);
  });
}

function renderGarage() {
  garageList.innerHTML = '';
  (state.garage?.vehicles || []).forEach(vehicle => {
    const card = document.createElement('div');
    card.className = 'list-card';
    card.innerHTML = `
      <p class="label">Vehicle</p>
      <h4>${vehicle.label}</h4>
      <p>Model: ${vehicle.model}</p>
      <div class="list-meta">
        <span>Min Grade: ${vehicle.minGrade ?? 0}</span>
        <button class="primary-btn">Deploy</button>
      </div>
    `;
    card.querySelector('button').addEventListener('click', () => resourcePost('spawnVehicle', { id: vehicle.id }));
    garageList.appendChild(card);
  });
}

function render() {
  renderHome();
  renderArmory();
  renderGarage();
  setTab(state.activeTab || 'home');
}

window.addEventListener('message', (event) => {
  const { action, data } = event.data || {};
  if (action === 'open') {
    app.classList.remove('hidden');
    state = { ...state, ...(data || {}) };
    applyTheme(data?.theme);
    render();
  } else if (action === 'close') {
    app.classList.add('hidden');
  } else if (action === 'sync') {
    state = { ...state, ...(data || {}) };
    applyTheme(data?.theme);
    render();
  }
});

document.getElementById('closeBtn').addEventListener('click', () => resourcePost('close'));
document.getElementById('toggleDutyBtn').addEventListener('click', () => resourcePost('toggleDuty'));

document.querySelectorAll('.nav-btn').forEach(btn => {
  btn.addEventListener('click', () => setTab(btn.dataset.tab));
});

document.querySelectorAll('[data-open-tab]').forEach(btn => {
  btn.addEventListener('click', () => setTab(btn.dataset.openTab));
});

document.addEventListener('keyup', (event) => {
  if (event.key === 'Escape') {
    resourcePost('close');
  }
});
