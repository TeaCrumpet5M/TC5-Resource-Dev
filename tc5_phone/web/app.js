const root = document.getElementById('phone-root');
const homeScreen = document.getElementById('home-screen');
const appScreen = document.getElementById('app-screen');
const appTitle = document.getElementById('app-title');
const appSubtitle = document.getElementById('app-subtitle');
const appContent = document.getElementById('app-content');
const appsGrid = document.getElementById('apps-grid');
const homeName = document.getElementById('home-name');
const homeNumber = document.getElementById('home-number');
const phoneTime = document.getElementById('phone-time');
const lockTime = document.getElementById('lock-time');
let state = null;
let activeThread = null;
let mechanicDiag = null;
let mechanicRecipes = {};
let mechanicBoss = { employees: [] };

function post(action, data = {}) {
  return fetch(`https://${GetParentResourceName()}/${action}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
  }).then((res) => res.json());
}

function applyTheme(theme = {}) {
  const rootStyle = document.documentElement.style;
  Object.entries(theme).forEach(([key, value]) => rootStyle.setProperty(`--${key.replace(/[A-Z]/g, m => `-${m.toLowerCase()}`)}`, value));
}

function updateClock() {
  const now = new Date();
  const time = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: false });
  phoneTime.textContent = time;
  lockTime.textContent = time;
}
setInterval(updateClock, 1000); updateClock();

function showHome() {
  homeScreen.classList.remove('hidden');
  appScreen.classList.add('hidden');
}

function showApp(title, subtitle = 'Application') {
  appTitle.textContent = title;
  appSubtitle.textContent = subtitle;
  homeScreen.classList.add('hidden');
  appScreen.classList.remove('hidden');
}

function renderApps() {
  appsGrid.innerHTML = '';
  const apps = (state && state.apps) || [];
  apps.forEach(app => {
    const item = document.createElement('div');
    item.className = 'app-icon';
    item.innerHTML = `<div class="icon-wrap">${app.icon || ''}</div><span>${app.label}</span>`;
    item.addEventListener('click', () => openApp(app.id));
    appsGrid.appendChild(item);
  });
}

function renderContacts() {
  const contacts = state.contacts || [];
  showApp('Contacts', 'Phase 1');
  appContent.innerHTML = `
    <div class="section-card stack">
      <div class="row"><strong>Add Contact</strong><span class="pill">${contacts.length} saved</span></div>
      <input id="contact-name" class="input" placeholder="Contact name" />
      <input id="contact-number" class="input" placeholder="Phone number" />
      <button id="save-contact" class="btn">Save contact</button>
    </div>
    <div class="section-card"><div class="stack" id="contact-list"></div></div>`;
  const list = document.getElementById('contact-list');
  if (!contacts.length) list.innerHTML = '<div class="center-note">No contacts saved.</div>';
  contacts.forEach(contact => {
    const row = document.createElement('div');
    row.className = 'contact-item';
    row.innerHTML = `<div><strong>${contact.contact_name}</strong><div class="muted">${contact.contact_number}</div></div><button class="small-btn">Delete</button>`;
    row.querySelector('button').addEventListener('click', () => post('deleteContact', { id: contact.id }));
    list.appendChild(row);
  });
  document.getElementById('save-contact').addEventListener('click', () => {
    post('addContact', { name: document.getElementById('contact-name').value.trim(), number: document.getElementById('contact-number').value.trim() });
  });
}

function renderThreads() {
  const threads = state.messages?.threads || [];
  showApp('Messages', 'Inbox');
  appContent.innerHTML = `
    <div class="section-card stack">
      <input id="manual-number" class="input" placeholder="Enter number" />
      <button id="new-thread" class="btn">Open thread</button>
    </div>
    <div id="thread-list"></div>`;
  const list = document.getElementById('thread-list');
  if (!threads.length) list.innerHTML = '<div class="center-note">No message threads yet.</div>';
  threads.forEach(thread => {
    const row = document.createElement('div');
    row.className = 'thread-card';
    row.innerHTML = `<div><strong>${thread.label || thread.peer_number}</strong><div class="muted">${thread.last_message || ''}</div></div><span class="pill">${thread.peer_number}</span>`;
    row.addEventListener('click', () => { activeThread = thread.peer_number; post('openThread', { peerNumber: thread.peer_number }); renderMessages(thread.peer_number, thread.label || thread.peer_number); });
    list.appendChild(row);
  });
  document.getElementById('new-thread').addEventListener('click', () => {
    const peerNumber = document.getElementById('manual-number').value.trim();
    if (!peerNumber) return;
    activeThread = peerNumber;
    post('openThread', { peerNumber });
    renderMessages(peerNumber, peerNumber);
  });
}

function renderMessages(peerNumber, label) {
  const threadMessages = (window.threadStore && window.threadStore[peerNumber]) || [];
  showApp(label || 'Thread', peerNumber);
  appContent.innerHTML = `<div class="section-card" id="messages-list"></div><div class="section-card stack"><textarea id="message-body" class="textarea" placeholder="Type a message"></textarea><button id="send-message" class="btn">Send message</button></div>`;
  const list = document.getElementById('messages-list');
  if (!threadMessages.length) list.innerHTML = '<div class="center-note">No messages yet.</div>';
  threadMessages.forEach(message => {
    const row = document.createElement('div');
    row.className = `message-row ${message.direction === 'outgoing' ? 'outgoing' : 'incoming'}`;
    row.innerHTML = `<div class="bubble">${message.message}</div>`;
    list.appendChild(row);
  });
  document.getElementById('send-message').addEventListener('click', () => {
    const message = document.getElementById('message-body').value.trim();
    if (!message) return;
    post('sendMessage', { peerNumber, message });
    document.getElementById('message-body').value = '';
  });
}

function renderCalls() {
  showApp('Calls', 'Phase 2');
  appContent.innerHTML = `<div class="section-card stack"><div class="row"><strong>Dialer</strong><span class="pill">Basic</span></div><input class="input" placeholder="Enter phone number" /><div class="center-note">Call routing can be expanded later.</div></div>`;
}

function renderProfile() {
  const profile = state.profile || {};
  showApp('Profile', 'Identity');
  appContent.innerHTML = `<div class="section-card stack"><div><strong>${profile.fullName || 'Unknown Citizen'}</strong></div><div class="muted">${profile.phoneNumber || '000-0000'}</div></div><div class="meta-grid"><div class="meta-box"><div class="eyebrow">Cash</div><div>$${profile.cash || 0}</div></div><div class="meta-box"><div class="eyebrow">Bank</div><div>$${profile.bank || 0}</div></div></div>`;
}

function renderJobs() {
  const job = (state.jobs && state.jobs.current) || {};
  showApp('Jobs', 'Phase 2');
  appContent.innerHTML = `<div class="section-card stack"><div class="row"><strong>${job.label || 'Unemployed'}</strong><span class="pill">${job.onduty ? 'On Duty' : 'Off Duty'}</span></div><div class="muted">Grade: ${job.gradeLabel || 'Citizen'}</div><div class="muted">Job Name: ${job.name || 'unemployed'}</div></div><div class="section-card center-note">This app is reading from tc5_jobs when available.</div>`;
}

function renderGarage() {
  const garage = state.garage || {};
  showApp('Garage', 'Phase 2');
  appContent.innerHTML = `<div class="section-card stack"><div class="row"><strong>Garage</strong><span class="pill">${(garage.vehicles || []).length} vehicles</span></div><div class="muted">${garage.message || 'Integration pending.'}</div></div>`;
}

function renderBank() {
  const bank = state.bank || {};
  showApp('Bank', 'Phase 2');
  appContent.innerHTML = `<div class="meta-grid"><div class="meta-box"><div class="eyebrow">Bank</div><div>$${bank.balance || 0}</div></div><div class="meta-box"><div class="eyebrow">Cash</div><div>$${bank.cash || 0}</div></div></div><div class="section-card center-note">${bank.message || 'Bank integration pending.'}</div>`;
}

function renderSettings() {
  showApp('Settings', 'Phase 1');
  appContent.innerHTML = `<div class="section-card stack"><div class="row"><strong>Settings</strong><span class="pill">Basic</span></div><div class="muted">Theme is matched to TC5 red / black / white.</div><button id="settings-refresh" class="btn secondary">Refresh phone data</button></div>`;
  document.getElementById('settings-refresh').addEventListener('click', () => post('refresh'));
}

function renderMechanicDiag(diag) {
  mechanicDiag = diag;
  appContent.innerHTML = `
    <div class="mech-hero">
      <div><strong>${diag.model}</strong></div>
      <div class="muted">${diag.shopLabel || 'Mechanic Shop'} · ${diag.gradeLabel || ''}</div>
      <div class="muted">Plate ${diag.plate}</div>
    </div>
    <div class="mech-grid">
      <div class="mech-box"><div class="mech-title">Engine</div><div class="mech-value">${diag.engine}%</div></div>
      <div class="mech-box"><div class="mech-title">Body</div><div class="mech-value">${diag.body}%</div></div>
      <div class="mech-box"><div class="mech-title">Fuel Tank</div><div class="mech-value">${diag.petrol}%</div></div>
      <div class="mech-box"><div class="mech-title">Fuel Level</div><div class="mech-value">${diag.fuelLevel}%</div></div>
    </div>
    <div class="section-card stack">
      <div class="row"><strong>Installed Mods</strong><span class="pill">${diag.mods.length}</span></div>
      ${diag.mods.map(mod => `<div class="row"><span>${mod.label}</span><span>${mod.value}</span></div>`).join('')}
    </div>
    <div class="section-card stack">
      <div class="row"><strong>Repairs</strong><span class="pill">Parts required</span></div>
      <div class="action-grid">
        <button class="btn mech-repair" data-repair="engine">Engine</button>
        <button class="btn mech-repair" data-repair="body">Body</button>
        <button class="btn mech-repair" data-repair="tyres">Tyres</button>
        <button class="btn mech-repair" data-repair="electronics">Electronics</button>
        <button class="btn mech-repair" data-repair="fullservice">Full Service</button>
      </div>
    </div>
    <div class="section-card stack">
      <div class="row"><strong>Service History</strong><span class="pill">${(diag.history || []).length}</span></div>
      ${diag.history && diag.history.length ? diag.history.map(entry => `<div class="row"><span>${entry.label}</span><span>${entry.mechanic}</span></div>`).join('') : '<div class="center-note">No recorded services yet.</div>'}
    </div>`;
  document.querySelectorAll('.mech-repair').forEach((btn) => btn.addEventListener('click', () => {
    post('startMechanicRepair', { repairId: btn.dataset.repair, netId: mechanicDiag.netId, plate: mechanicDiag.plate });
  }));
}

function renderMechanicCrafting() {
  showApp('Mechanic', 'Crafting');
  appContent.innerHTML = `<div class="section-card stack"><div class="row"><strong>Crafting bench</strong><span class="pill">Materials → Parts</span></div><div id="recipe-list" class="stack"></div></div>`;
  const list = document.getElementById('recipe-list');
  Object.entries(mechanicRecipes).forEach(([recipeId, recipe]) => {
    const row = document.createElement('div');
    row.className = 'section-card';
    row.innerHTML = `<div class="row"><strong>${recipe.label}</strong><button class="small-btn">Craft</button></div>${Object.entries(recipe.materials || {}).map(([item, amount]) => `<div class="row"><span>${item}</span><span>${amount}</span></div>`).join('')}`;
    row.querySelector('button').addEventListener('click', () => post('craftMechanicRecipe', { recipeId }));
    list.appendChild(row);
  });
}

function renderMechanicBoss() {
  showApp('Mechanic', (mechanicBoss.shopLabel || 'Workshop'));
  appContent.innerHTML = `<div class="section-card stack"><div class="row"><strong>Workshop staff</strong><button id="refresh-boss" class="small-btn">Refresh</button></div><div id="boss-list"></div><input id="boss-target" class="input" placeholder="Server ID" /><div class="action-grid"><button id="boss-hire" class="btn">Hire</button><button id="boss-promote" class="btn secondary">Promote</button><button id="boss-demote" class="btn secondary">Demote</button><button id="boss-fire" class="btn secondary">Fire</button></div></div>`;
  const list = document.getElementById('boss-list');
  if (!((mechanicBoss.employees || []).length)) list.innerHTML = '<div class="center-note">No mechanic staff online or no permission.</div>';
  (mechanicBoss.employees || []).forEach((employee) => {
    const row = document.createElement('div');
    row.className = 'thread-card';
    row.innerHTML = `<div><strong>${employee.name}</strong><div class="muted">${employee.gradeLabel}</div></div><span class="pill">${employee.onduty ? 'On' : 'Off'}</span>`;
    list.appendChild(row);
  });
  document.getElementById('refresh-boss').addEventListener('click', () => post('requestMechanicBossData'));
  const getId = () => Number(document.getElementById('boss-target').value || 0);
  document.getElementById('boss-hire').addEventListener('click', () => post('mechanicHire', { targetId: getId() }));
  document.getElementById('boss-promote').addEventListener('click', () => post('mechanicPromote', { targetId: getId() }));
  document.getElementById('boss-demote').addEventListener('click', () => post('mechanicDemote', { targetId: getId() }));
  document.getElementById('boss-fire').addEventListener('click', () => post('mechanicFire', { targetId: getId() }));
}

async function renderMechanicHome() {
  showApp('Mechanic', (mechanicDiag && mechanicDiag.shopLabel) || 'Diagnostics');
  appContent.innerHTML = `<div class="section-card stack"><div class="row"><strong>Mechanic Console</strong><span class="pill">Job locked</span></div><div class="action-grid"><button id="mech-toggle-duty" class="btn secondary">Toggle Duty</button><button id="mech-scan" class="btn">Scan Vehicle</button><button id="mech-crafting" class="btn secondary">Craft Parts</button><button id="mech-boss" class="btn secondary">Workshop</button></div><div class="center-note" id="mech-status">Ready.</div></div>`;
  document.getElementById('mech-toggle-duty').addEventListener('click', () => post('mechanicToggleDuty'));
  document.getElementById('mech-crafting').addEventListener('click', async () => { const res = await post('requestMechanicRecipes'); mechanicRecipes = res.recipes || {}; renderMechanicCrafting(); });
  document.getElementById('mech-boss').addEventListener('click', () => { post('requestMechanicBossData'); renderMechanicBoss(); });
  document.getElementById('mech-scan').addEventListener('click', async () => {
    const result = await post('requestMechanicPhoneData');
    document.getElementById('mech-status').textContent = result.ok ? 'Vehicle scanned.' : (result.message || 'Scan failed.');
    if (result.ok && result.payload) renderMechanicDiag(result.payload);
  });
}

function openApp(appId) {
  switch (appId) {
    case 'contacts': return renderContacts();
    case 'messages': return renderThreads();
    case 'calls': return renderCalls();
    case 'profile': return renderProfile();
    case 'jobs': return renderJobs();
    case 'garage': return renderGarage();
    case 'bank': return renderBank();
    case 'settings': return renderSettings();
    case 'mechanic': return renderMechanicHome();
    default:
      showApp(appId, 'Custom App');
      appContent.innerHTML = '<div class="section-card center-note">This custom app is registered, but does not yet have a rendered page.</div>';
  }
}

function setState(nextState) {
  state = nextState || {};
  document.querySelector('.phone-screen').style.background = state.profile?.wallpaper || 'linear-gradient(180deg, #15090b 0%, #090909 55%, #000000 100%)';
  homeName.textContent = state.profile?.fullName || 'Unknown Citizen';
  homeNumber.textContent = state.profile?.phoneNumber || '000-0000';
  renderApps();
  showHome();
}

window.threadStore = {};
window.addEventListener('message', (event) => {
  const payload = event.data || {};
  const action = payload.action;
  const data = payload.data;
  if (action === 'theme') applyTheme(data);
  if (action === 'open') root.classList.remove('hidden');
  if (action === 'close') root.classList.add('hidden');
  if (action === 'state') setState(data);
  if (action === 'messages' && data) {
    window.threadStore[data.peerNumber] = data.messages || [];
    if (activeThread === data.peerNumber) renderMessages(data.peerNumber, data.peerNumber);
  }
  if (action === 'mechanicHistory' && mechanicDiag && data && mechanicDiag.plate === data.plate) {
    mechanicDiag.history = data.history || [];
    renderMechanicDiag(mechanicDiag);
  }
  if (action === 'mechanicBossData') {
    mechanicBoss = data || [];
    if (appTitle.textContent === 'Mechanic' && appSubtitle.textContent === 'Workshop') renderMechanicBoss();
  }
  if (action === 'mechanicDiagnostic' && data) renderMechanicDiag(data);
});

document.getElementById('nav-home').addEventListener('click', showHome);
document.getElementById('nav-close').addEventListener('click', () => post('close'));
document.getElementById('nav-back').addEventListener('click', showHome);
document.getElementById('refresh-home').addEventListener('click', () => post('refresh'));
document.addEventListener('keyup', (event) => { if (event.key === 'Escape') post('close'); });
