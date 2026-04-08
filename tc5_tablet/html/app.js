
const app = document.getElementById('app');
const homeView = document.getElementById('homeView');
const boostingView = document.getElementById('boostingView');
const appGrid = document.getElementById('appGrid');
const emptyState = document.getElementById('emptyState');
const statusTime = document.getElementById('statusTime');
const statusName = document.getElementById('statusName');
const repValue = document.getElementById('repValue');
const statusValue = document.getElementById('statusValue');
const contractsList = document.getElementById('contractsList');
const bootOverlay = document.getElementById('bootOverlay');

const state = { apps: [], boosting: { rep: 0, contracts: [] }, activeContract: null, currentView: 'home' };

function hardHide() {
    document.documentElement.style.background = 'transparent';
    document.body.style.background = 'transparent';
    app.classList.remove('visible');
    app.style.display = 'none';
}

function showApp() {
    app.style.display = 'flex';
    app.classList.add('visible');
}

function post(action, data = {}) {
    fetch(`https://${GetParentResourceName()}/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
    }).catch(() => {});
}

function setView(viewName) {
    state.currentView = viewName;
    homeView.classList.toggle('hidden', viewName !== 'home');
    boostingView.classList.toggle('hidden', viewName !== 'boosting');
}

function renderApps() {
    appGrid.innerHTML = '';
    emptyState.classList.toggle('hidden', state.apps.length > 0);
    state.apps.forEach((appData) => {
        const tile = document.createElement('button');
        tile.className = 'app-tile';
        tile.innerHTML = `<div class="app-icon" style="background:${appData.accent || '#71a7ff'}">${appData.icon || 'APP'}</div><div class="app-label">${appData.label}</div>`;
        tile.addEventListener('click', () => {
            if (appData.id === 'boosting') {
                setView('boosting');
                post('requestBoostingData');
            }
        });
        appGrid.appendChild(tile);
    });
}

function renderBoosting() {
    repValue.textContent = String(state.boosting.rep || 0);
    statusValue.textContent = state.activeContract ? `Active ${state.activeContract.tier}` : 'Idle';
    contractsList.innerHTML = '';
    (state.boosting.contracts || []).forEach((entry) => {
        const card = document.createElement('div');
        card.className = 'contract-card';
        const payout = `$${entry.payout.min.toLocaleString()} - $${entry.payout.max.toLocaleString()}`;
        card.innerHTML = `<div class="contract-main"><div class="contract-tier">Tier ${entry.tier}</div><div class="contract-meta">Min rep: ${entry.minRep} · Vehicles: ${entry.vehicleCount} · Payout: ${payout}</div></div><div class="contract-pill ${entry.unlocked ? 'open' : 'locked'}">${entry.unlocked ? 'UNLOCKED' : 'LOCKED'}</div>`;
        contractsList.appendChild(card);
    });
}

function updateClock() {
    const now = new Date();
    statusTime.textContent = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
}

document.addEventListener('DOMContentLoaded', hardHide);
window.onload = hardHide;
window.addEventListener('message', (event) => {
    const { action, data } = event.data || {};
    switch (action) {
        case 'boot': {
            bootOverlay.classList.remove('hidden');
            const delay = (data && data.delay) || 900;
            window.clearTimeout(window.__bootTimer);
            window.__bootTimer = window.setTimeout(() => bootOverlay.classList.add('hidden'), delay);
            break;
        }
        case 'open': {
            showApp();
            state.apps = data.apps || [];
            state.boosting = data.boosting || { rep: 0, contracts: [] };
            state.activeContract = data.activeContract || null;
            statusName.textContent = (data.playerName || 'USER').toUpperCase();
            setView('home');
            renderApps();
            renderBoosting();
            break;
        }
        case 'boostingData': {
            state.boosting = data.boosting || state.boosting;
            state.activeContract = data.activeContract || null;
            renderBoosting();
            break;
        }
        case 'boostContractStarted': {
            state.activeContract = data;
            renderBoosting();
            break;
        }
        case 'boostContractCompleted': {
            state.activeContract = null;
            state.boosting.rep = data.rep || state.boosting.rep;
            renderBoosting();
            break;
        }
        case 'close': {
            hardHide();
            break;
        }
    }
});

document.getElementById('closeBtn').addEventListener('click', () => post('close'));
document.getElementById('backBtn').addEventListener('click', () => setView('home'));
document.getElementById('refreshBoostingBtn').addEventListener('click', () => post('requestBoostingData'));
document.getElementById('startBoostingBtn').addEventListener('click', () => post('startBoostContract'));
document.addEventListener('keyup', (event) => { if (event.key === 'Escape') post('close'); });

updateClock();
setInterval(updateClock, 15000);
hardHide();
