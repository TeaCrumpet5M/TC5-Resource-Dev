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

function post(action, data = {}) {
  return fetch(`https://${GetParentResourceName()}/${action}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
  });
}

function formatTime(dateString) {
  const date = dateString ? new Date(dateString) : new Date();
  return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
}

function tickClock() {
  const now = new Date();
  const formatted = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  phoneTime.textContent = formatted;
  lockTime.textContent = formatted;
}
setInterval(tickClock, 1000);
tickClock();

function applyTheme(theme) {
  if (!theme) return;
  for (const [key, value] of Object.entries(theme)) {
    const cssKey = '--' + key.replace(/[A-Z]/g, m => '-' + m.toLowerCase());
    document.documentElement.style.setProperty(cssKey, value);
  }
}

function showHome() {
  appScreen.classList.add('hidden');
  homeScreen.classList.remove('hidden');
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
    item.innerHTML = `
      <div class="icon-wrap" style="background: linear-gradient(180deg, rgba(177,15,31,.22), rgba(18,18,18,.95));">
        ${app.icon || '📦'}
      </div>
      <span>${app.label}</span>
    `;
    item.addEventListener('click', () => openApp(app.id));
    appsGrid.appendChild(item);
  });
}

function renderContacts() {
  const contacts = state.contacts || [];
  showApp('Contacts', 'Phase 1');
  appContent.innerHTML = `
    <div class="section-card stack">
      <div class="row">
        <strong>Add Contact</strong>
        <span class="pill">${contacts.length} saved</span>
      </div>
      <input id="contact-name" class="input" placeholder="Contact name" />
      <input id="contact-number" class="input" placeholder="Phone number" />
      <button id="save-contact" class="btn">Save contact</button>
    </div>
    <div class="section-card">
      <div class="stack" id="contact-list"></div>
    </div>
  `;

  const list = document.getElementById('contact-list');
  if (!contacts.length) {
    list.innerHTML = '<div class="center-note">No contacts yet.</div>';
  } else {
    contacts.forEach(contact => {
      const row = document.createElement('div');
      row.className = 'contact-item';
      row.innerHTML = `
        <div>
          <div><strong>${contact.contact_name}</strong></div>
          <div class="muted">${contact.contact_number}</div>
        </div>
        <div class="row">
          <button class="small-btn">Delete</button>
        </div>
      `;
      row.querySelector('button').addEventListener('click', (e) => {
        e.stopPropagation();
        post('deleteContact', { id: contact.id });
      });
      row.addEventListener('click', () => {
        activeThread = contact.contact_number;
        post('openThread', { peerNumber: contact.contact_number });
        renderMessages(contact.contact_number, contact.contact_name);
      });
      list.appendChild(row);
    });
  }

  document.getElementById('save-contact').addEventListener('click', () => {
    const name = document.getElementById('contact-name').value.trim();
    const number = document.getElementById('contact-number').value.trim();
    post('addContact', { name, number });
  });
}

function renderThreads() {
  const threads = state.threads || [];
  showApp('Messages', 'Phase 1');
  appContent.innerHTML = `
    <div class="section-card stack">
      <div class="row">
        <strong>New Message</strong>
        <span class="pill">${threads.length} threads</span>
      </div>
      <input id="manual-number" class="input" placeholder="Phone number" />
      <button id="open-manual-thread" class="btn secondary">Open thread</button>
    </div>
    <div class="section-card">
      <div class="stack" id="thread-list"></div>
    </div>
  `;
  const list = document.getElementById('thread-list');

  if (!threads.length) {
    list.innerHTML = '<div class="center-note">No conversations yet.</div>';
  } else {
    threads.forEach(thread => {
      const row = document.createElement('div');
      row.className = 'thread-card';
      row.innerHTML = `
        <div>
          <div><strong>${thread.label}</strong></div>
          <div class="muted">${thread.peer_number}</div>
        </div>
        <div class="muted">${formatTime(thread.last_at)}</div>
      `;
      row.addEventListener('click', () => {
        activeThread = thread.peer_number;
        post('openThread', { peerNumber: thread.peer_number });
        renderMessages(thread.peer_number, thread.label);
      });
      list.appendChild(row);
    });
  }

  document.getElementById('open-manual-thread').addEventListener('click', () => {
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
  appContent.innerHTML = `
    <div class="section-card" id="messages-list"></div>
    <div class="section-card stack">
      <textarea id="message-body" class="textarea" placeholder="Type a message"></textarea>
      <button id="send-message" class="btn">Send message</button>
    </div>
  `;

  const list = document.getElementById('messages-list');
  if (!threadMessages.length) {
    list.innerHTML = '<div class="center-note">No messages yet.</div>';
  } else {
    list.innerHTML = '';
    threadMessages.forEach(message => {
      const row = document.createElement('div');
      row.className = `message-row ${message.direction === 'outgoing' ? 'outgoing' : 'incoming'}`;
      row.innerHTML = `
        <div class="bubble">
          <div>${message.message}</div>
          <div class="muted" style="margin-top:.35rem;font-size:.78rem;">${formatTime(message.created_at)}</div>
        </div>
      `;
      list.appendChild(row);
    });
  }

  document.getElementById('send-message').addEventListener('click', () => {
    const message = document.getElementById('message-body').value.trim();
    if (!message) return;
    post('sendMessage', { peerNumber, message });
    document.getElementById('message-body').value = '';
  });
}

function renderCalls() {
  showApp('Calls', 'Phase 2');
  appContent.innerHTML = `
    <div class="section-card stack">
      <div class="row"><strong>Dialer</strong><span class="pill">Basic</span></div>
      <input id="dial-number" class="input" placeholder="Enter phone number" />
      <button id="mock-call" class="btn">Start basic call</button>
    </div>
    <div class="section-card center-note">
      This is a basic Phase 2 call app shell. It is ready to be connected to voice later.
    </div>
  `;

  document.getElementById('mock-call').addEventListener('click', () => {
    const number = document.getElementById('dial-number').value.trim();
    if (!number) return;
    post('notify', {
      title: 'Calls',
      message: `Calling ${number}...`,
      type: 'info',
      duration: 2500
    });
  });
}

function renderProfile() {
  const profile = state.profile || {};
  showApp('Profile', 'Phase 1');
  appContent.innerHTML = `
    <div class="section-card stack">
      <div><strong>${profile.fullName || 'Unknown Citizen'}</strong></div>
      <div class="muted">${profile.phoneNumber || '000-0000'}</div>
    </div>
    <div class="meta-grid">
      <div class="meta-box">
        <div class="eyebrow">Cash</div>
        <div>$${profile.cash || 0}</div>
      </div>
      <div class="meta-box">
        <div class="eyebrow">Bank</div>
        <div>$${profile.bank || 0}</div>
      </div>
    </div>
  `;
}

function renderJobs() {
  const job = (state.jobs && state.jobs.current) || {};
  showApp('Jobs', 'Phase 2');
  appContent.innerHTML = `
    <div class="section-card stack">
      <div class="row"><strong>${job.label || 'Unemployed'}</strong><span class="pill">${job.onduty ? 'On Duty' : 'Off Duty'}</span></div>
      <div class="muted">Grade: ${job.gradeLabel || 'Citizen'}</div>
      <div class="muted">Job Name: ${job.name || 'unemployed'}</div>
    </div>
    <div class="section-card center-note">
      This app is reading from tc5_jobs when available.
    </div>
  `;
}

function renderGarage() {
  const garage = state.garage || {};
  showApp('Garage', 'Phase 2');
  appContent.innerHTML = `
    <div class="section-card stack">
      <div class="row"><strong>Garage</strong><span class="pill">${(garage.vehicles || []).length} vehicles</span></div>
      <div class="muted">${garage.message || 'Integration pending.'}</div>
    </div>
  `;
}

function renderBank() {
  const bank = state.bank || {};
  showApp('Bank', 'Phase 2');
  appContent.innerHTML = `
    <div class="meta-grid">
      <div class="meta-box">
        <div class="eyebrow">Bank</div>
        <div>$${bank.balance || 0}</div>
      </div>
      <div class="meta-box">
        <div class="eyebrow">Cash</div>
        <div>$${bank.cash || 0}</div>
      </div>
    </div>
    <div class="section-card center-note">
      ${bank.message || 'Bank integration pending.'}
    </div>
  `;
}

function renderSettings() {
  showApp('Settings', 'Phase 1');
  appContent.innerHTML = `
    <div class="section-card stack">
      <div class="row"><strong>Settings</strong><span class="pill">Basic</span></div>
      <div class="muted">Theme is matched to TC5 red / black / white.</div>
      <button id="settings-refresh" class="btn secondary">Refresh phone data</button>
    </div>
  `;
  document.getElementById('settings-refresh').addEventListener('click', () => post('refresh'));
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
    if (activeThread === data.peerNumber) {
      renderMessages(data.peerNumber, data.peerNumber);
    }
  }
});

document.getElementById('nav-home').addEventListener('click', showHome);
document.getElementById('back-home').addEventListener('click', showHome);
document.getElementById('nav-close').addEventListener('click', () => post('close'));
document.getElementById('refresh-home').addEventListener('click', () => post('refresh'));
document.getElementById('lock-screen').addEventListener('click', showHome);
