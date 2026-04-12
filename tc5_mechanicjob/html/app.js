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

function formatMoney(value) {
  const amount = Number(value || 0);
  return `$${amount.toLocaleString()}`;
}

function materialList(materials = []) {
  if (!materials.length) return '<div class="meta">No materials</div>';
  return materials.map(m => `<span class="pill">${escapeHtml(m.item)} x${escapeHtml(m.amount)}</span>`).join(' ');
}

function businessOptions(accounts = []) {
  if (!accounts.length) return '<option value="">No linked business account</option>';
  return accounts.map(acc => `<option value="${escapeHtml(acc.id)}">${escapeHtml(acc.name)} • ${escapeHtml(acc.accountNumber)} • ${formatMoney(acc.balance)}</option>`).join('');
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

function billingCard(payload) {
  if (!payload.billingEnabled) return '';
  return `
    <div class="card full">
      <div class="row"><h3>Banking invoice</h3><span class="pill">tc5_banking</span></div>
      <p>Create an invoice from your linked business account. The customer can accept it from bank mobile or the main bank UI.</p>
      <div class="form-grid two">
        <div class="field">
          <label>Customer server id</label>
          <input id="invoiceTargetId" type="number" min="1" placeholder="e.g. 7">
        </div>
        <div class="field">
          <label>Amount</label>
          <input id="invoiceAmount" type="number" min="1" max="${escapeHtml(payload.maxInvoiceAmount || 250000)}" placeholder="e.g. 850">
        </div>
      </div>
      <div class="form-grid two">
        <div class="field">
          <label>Business account</label>
          <select id="invoiceAccountId">${businessOptions(payload.businessAccounts || [])}</select>
        </div>
        <div class="field">
          <label>Reason</label>
          <input id="invoiceReason" type="text" maxlength="100" value="${escapeHtml(payload.defaultInvoiceReason || 'Mechanic service')}">
        </div>
      </div>
      <div class="actions">
        <button class="btn" data-action="createInvoice">Send invoice</button>
      </div>
    </div>
  `;
}

function payoutCard(payload) {
  if (!payload.payoutsEnabled) return '';
  return `
    <div class="card full">
      <div class="row"><h3>Business payout</h3><span class="pill">Boss only</span></div>
      <p>Pay an employee or contractor directly from a linked business account.</p>
      <div class="form-grid two">
        <div class="field">
          <label>Target server id</label>
          <input id="payTargetId" type="number" min="1" placeholder="e.g. 12">
        </div>
        <div class="field">
          <label>Amount</label>
          <input id="payAmount" type="number" min="1" placeholder="e.g. 500">
        </div>
      </div>
      <div class="form-grid two">
        <div class="field">
          <label>Business account</label>
          <select id="payAccountId">${businessOptions(payload.businessAccounts || [])}</select>
        </div>
        <div class="field">
          <label>Reason</label>
          <input id="payReason" type="text" maxlength="100" value="Shift payment">
        </div>
      </div>
      <div class="actions">
        <button class="btn" data-action="payEmployee">Send payout</button>
        <button class="btn secondary" data-action="openBank">Open banking</button>
      </div>
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
  content.innerHTML = diagnosticCard(payload.vehicle) + billingCard(payload) + repairCards;
}

function renderShop(payload) {
  menuTitle.textContent = 'Parts Shop';
  subInfo.textContent = `Internal stock and materials for ${payload.shopLabel}.`;
  const items = (payload.stock || []).map(item => `
    <div class="list-item">
      <div>
        <strong>${escapeHtml(item.label)}</strong>
        <div class="meta">Gives ${escapeHtml(item.amount)}x ${escapeHtml(item.item)} • ${formatMoney(item.price)}</div>
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
  subInfo.textContent = `Manage ${payload.shopLabel} staff and linked banking actions.`;
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
  const accounts = (payload.businessAccounts || []).length
    ? payload.businessAccounts.map(acc => `
      <div class="list-item">
        <div>
          <strong>${escapeHtml(acc.name)}</strong>
          <div class="meta mono">${escapeHtml(acc.accountNumber)} • Min grade ${escapeHtml(acc.minGrade)} • ${acc.isFrozen ? 'Frozen' : 'Active'}</div>
        </div>
        <span class="pill">${formatMoney(acc.balance)}</span>
      </div>
    `).join('')
    : '<p>No linked business account found for this shop yet.</p>';
  content.innerHTML = `
    <div class="card full">
      <h3>Staff roster</h3>
      <div class="grid-rows">${roster || '<p>No online staff found for this shop.</p>'}</div>
    </div>
    <div class="card full">
      <div class="row"><h3>Business accounts</h3><span class="pill">Mechanic finance</span></div>
      <div class="grid-rows">${accounts}</div>
      <div class="actions">
        ${payload.canCreateBusinessAccount ? '<button class="btn" data-action="createBusinessAccount">Create linked business account</button>' : ''}
        <button class="btn secondary" data-action="openBank">Open banking</button>
      </div>
    </div>
    ${payoutCard(payload)}
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
  if (action === 'openBank') post('openBank');
  if (action === 'createBusinessAccount') post('createBusinessAccount');
  if (action === 'createInvoice') {
    post('createInvoice', {
      targetId: document.getElementById('invoiceTargetId')?.value,
      accountId: document.getElementById('invoiceAccountId')?.value,
      amount: document.getElementById('invoiceAmount')?.value,
      reason: document.getElementById('invoiceReason')?.value
    });
  }
  if (action === 'payEmployee') {
    post('payEmployee', {
      targetId: document.getElementById('payTargetId')?.value,
      accountId: document.getElementById('payAccountId')?.value,
      amount: document.getElementById('payAmount')?.value,
      reason: document.getElementById('payReason')?.value
    });
  }
});
