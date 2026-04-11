const app = document.getElementById('app');
const content = document.getElementById('content');
const menuTitle = document.getElementById('menuTitle');
const shopLabel = document.getElementById('shopLabel');
const subInfo = document.getElementById('subInfo');
const closeBtn = document.getElementById('closeBtn');

let current = null;

const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'tc5_mechanicjob';

function post(name, data = {}) {
  return fetch(`https://${resource}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
  });
}

function escapeHtml(value) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

function materialList(materials = []) {
  if (!materials.length) return '<div class="meta">No materials</div>';
  return materials.map(m => `<span class="pill">${escapeHtml(m.item)} x${escapeHtml(m.amount)}</span>`).join(' ');
}

function diagnosticCard(vehicle) {
  if (!vehicle) {
    return `<div class="card full"><h3>No vehicle scan yet</h3><p>Use /mech scan near a vehicle, or open the repair bay near a vehicle to populate diagnostics.</p></div>`;
  }
  const mods = (vehicle.mods || []).map(mod => `
    <div class="list-item"><div><strong>${escapeHtml(mod.label)}</strong></div><div class="mono">${escapeHtml(mod.value)}</div></div>
  `).join('');
  const history = (vehicle.history || []).length
    ? vehicle.history.map(row => `<div class="history-item"><strong>${escapeHtml(row.label)}</strong><div class="meta">${escapeHtml(row.mechanic)} • ${escapeHtml(row.shop)} • ${escapeHtml(row.time)}</div></div>`).join('')
    : '<p>No service history stored for this plate yet.</p>';
  return `
    <div class="card">
      <h3>Vehicle</h3>
      <div class="big-stat">${escapeHtml(vehicle.model)}</div>
      <div class="row"><span class="pill mono">${escapeHtml(vehicle.plate)}</span><span class="pill">Fuel ${escapeHtml(vehicle.fuelLevel)}%</span></div>
      <div class="two-col">
        <div class="notice">Engine <div class="big-stat">${escapeHtml(vehicle.engine)}%</div></div>
        <div class="notice">Body <div class="big-stat">${escapeHtml(vehicle.body)}%</div></div>
        <div class="notice">Tank <div class="big-stat">${escapeHtml(vehicle.petrol)}%</div></div>
      </div>
    </div>
    <div class="card">
      <h3>Existing upgrades</h3>
      <div class="grid-rows">${mods || '<p>No upgrade data found.</p>'}</div>
    </div>
    <div class="card full">
      <h3>Service history</h3>
      <div class="grid-rows">${history}</div>
    </div>
  `;
}

function renderCrafting(payload) {
  menuTitle.textContent = 'Crafting Bench';
  subInfo.textContent = `Create repair parts for ${payload.shopLabel}.`;
  content.innerHTML = (payload.recipes || []).map(recipe => `
    <div class="card">
      <div class="row"><h3>${escapeHtml(recipe.label)}</h3><span class="pill">${escapeHtml(recipe.amount)}x</span></div>
      <p>Item: <span class="mono">${escapeHtml(recipe.item)}</span></p>
      <p>Craft time: ${Math.floor((recipe.time || 0) / 1000)}s</p>
      <div>${materialList(recipe.materials)}</div>
      <button class="btn" data-action="craft" data-id="${escapeHtml(recipe.id)}">Craft</button>
    </div>
  `).join('');
}

function renderRepair(payload) {
  menuTitle.textContent = 'Repair Bay';
  subInfo.textContent = `Diagnostics and repair actions for ${payload.shopLabel}. No modding is included here.`;
  const repairCards = (payload.repairs || []).map(repair => `
    <div class="card">
      <div class="row"><h3>${escapeHtml(repair.label)}</h3><span class="pill">Grade ${escapeHtml(repair.minGrade)}</span></div>
      <p>Consumes: <span class="mono">${escapeHtml(repair.item)}</span></p>
      <p>Repair time: ${Math.floor((repair.time || 0) / 1000)}s</p>
      <button class="btn" data-action="repair" data-id="${escapeHtml(repair.id)}">Start repair</button>
    </div>
  `).join('');
  content.innerHTML = diagnosticCard(payload.vehicle) + repairCards;
}

function renderShop(payload) {
  menuTitle.textContent = 'Parts Shop';
  subInfo.textContent = `Internal stock and materials for ${payload.shopLabel}.`;
  const items = (payload.stock || []).map(item => `
    <div class="list-item">
      <div>
        <strong>${escapeHtml(item.label)}</strong>
        <div class="meta">Gives ${escapeHtml(item.amount)}x ${escapeHtml(item.item)} • ${escapeHtml(item.price)}</div>
      </div>
      <button class="btn ${payload.shopPurchasingEnabled ? '' : 'secondary'}" data-action="purchase" data-id="${escapeHtml(item.id)}">${payload.shopPurchasingEnabled ? 'Buy' : 'Unavailable'}</button>
    </div>
  `).join('');
  content.innerHTML = `
    <div class="card full">
      <h3>Stock counter</h3>
      <div class="notice">${escapeHtml(payload.shopNotice || '')}</div>
    </div>
    <div class="card full"><div class="grid-rows">${items || '<p>No stock configured.</p>'}</div></div>
  `;
}

function renderBoss(payload) {
  menuTitle.textContent = 'Boss Menu';
  subInfo.textContent = `Manage ${payload.shopLabel} staff with quick reference commands.`;
  const roster = (payload.roster || []).map(row => `
    <div class="list-item">
      <div>
        <strong>${escapeHtml(row.name)}</strong>
        <div class="meta">ID ${escapeHtml(row.id)} • ${escapeHtml(row.gradeLabel)} • ${row.onduty ? 'On duty' : 'Off duty'}</div>
      </div>
      <span class="pill">Grade ${escapeHtml(row.grade)}</span>
    </div>
  `).join('');
  const commands = (payload.commands || []).map(cmd => `<span class="pill mono">${escapeHtml(cmd)}</span>`).join(' ');
  content.innerHTML = `
    <div class="card full">
      <h3>Staff roster</h3>
      <div class="grid-rows">${roster || '<p>No online staff found for this shop.</p>'}</div>
    </div>
    <div class="card full">
      <h3>Chat commands</h3>
      <div>${commands}</div>
    </div>
  `;
}

function render(payload) {
  current = payload;
  shopLabel.textContent = (payload.shopLabel || 'MECHANIC').toUpperCase();
  document.documentElement.style.setProperty('--accent', payload.accent || '#d63b3b');
  if (payload.menu === 'crafting') renderCrafting(payload);
  if (payload.menu === 'repair') renderRepair(payload);
  if (payload.menu === 'shop') renderShop(payload);
  if (payload.menu === 'boss') renderBoss(payload);
}

window.addEventListener('message', (event) => {
  const { action, payload } = event.data || {};
  if (action === 'open') {
    app.classList.remove('hidden');
    render(payload || {});
  }
  if (action === 'close') {
    app.classList.add('hidden');
    content.innerHTML = '';
    current = null;
  }
});

closeBtn.addEventListener('click', () => post('close'));

document.addEventListener('keydown', (event) => {
  if (event.key === 'Escape') post('close');
});

document.addEventListener('click', (event) => {
  const button = event.target.closest('[data-action]');
  if (!button) return;
  const action = button.getAttribute('data-action');
  const id = button.getAttribute('data-id');
  if (action === 'craft') post('craft', { id });
  if (action === 'repair') post('repair', { id });
  if (action === 'purchase') post('purchase', { id });
});
