const app = document.getElementById('app');
const closeBtn = document.getElementById('closeBtn');
const refreshBtn = document.getElementById('refreshBtn');
const search = document.getElementById('search');
const playerList = document.getElementById('playerList');
const detailPanel = document.getElementById('detailPanel');
const detailTitle = document.getElementById('detailTitle');
const actionInput = document.getElementById('actionInput');
const moneyAmount = document.getElementById('moneyAmount');
const itemAmount = document.getElementById('itemAmount');
const itemSearch = document.getElementById('itemSearch');
const itemResults = document.getElementById('itemResults');
const itemPlayerSelect = document.getElementById('itemPlayerSelect');
const itemSelectedPlayer = document.getElementById('itemSelectedPlayer');
const itemSelectedCard = document.getElementById('itemSelectedCard');
const itemSelectedTitle = document.getElementById('itemSelectedTitle');
const itemSelectedMeta = document.getElementById('itemSelectedMeta');
const reportInput = document.getElementById('reportInput');
const reportsList = document.getElementById('reportsList');
const groupValue = document.getElementById('groupValue');
const jobSelectedPlayer = document.getElementById('jobSelectedPlayer');
const jobSelect = document.getElementById('jobSelect');
const gradeSelect = document.getElementById('gradeSelect');
const setJobBtn = document.getElementById('setJobBtn');
const devEnabledValue = document.getElementById('devEnabledValue');
const devX = document.getElementById('devX');
const devY = document.getElementById('devY');
const devZ = document.getElementById('devZ');
const devH = document.getElementById('devH');
const copyOutput = document.getElementById('copyOutput');
const copyVecBtn = document.getElementById('copyVecBtn');
const copyPlainBtn = document.getElementById('copyPlainBtn');
const vehicleSearch = document.getElementById('vehicleSearch');
const vehicleCategories = document.getElementById('vehicleCategories');
const vehicleGrid = document.getElementById('vehicleGrid');

let state = {
    group: 'unknown',
    permissions: {},
    players: [],
    reports: {},
    jobs: [],
    selectedPlayer: null,
    itemTargetId: null,
    itemCatalog: [],
    selectedItem: null,
    vehicleCategories: [],
    vehicleCatalog: [],
    selectedVehicleCategory: 'all',
    dev: {
        enabled: false,
        x: 0,
        y: 0,
        z: 0,
        heading: 0,
        vector: 'vec4(0.0000, 0.0000, 0.0000, 0.0000)',
        plain: '0.0000, 0.0000, 0.0000, 0.0000'
    }
};

const post = async (endpoint, payload = {}) => {
    const res = await fetch(`https://${GetParentResourceName()}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
    });
    try {
        return await res.json();
    } catch {
        return null;
    }
};

const tabs = document.querySelectorAll('.tab-btn');
const tabPanels = document.querySelectorAll('.tab-panel');

tabs.forEach((btn) => {
    btn.addEventListener('click', () => {
        tabs.forEach((b) => b.classList.remove('active'));
        tabPanels.forEach((p) => p.classList.remove('active'));
        btn.classList.add('active');
        document.getElementById(`${btn.dataset.tab}Tab`).classList.add('active');
    });
});

const itemMatches = (item, term) => {
    const haystack = `${item.label || ''} ${item.name || ''} ${item.description || ''}`.toLowerCase();
    return haystack.includes(term);
};

const getActiveItemTarget = () => {
    const fromDropdown = Number(itemPlayerSelect && itemPlayerSelect.value ? itemPlayerSelect.value : 0);
    if (fromDropdown > 0) return fromDropdown;
    if (state.itemTargetId) return state.itemTargetId;
    if (state.selectedPlayer && state.selectedPlayer.id) return state.selectedPlayer.id;
    return null;
};

const ensureSelectedItemStillExists = () => {
    if (!state.selectedItem) return;
    const found = (state.itemCatalog || []).find((item) => item.name === state.selectedItem.name);
    if (!found) {
        state.selectedItem = null;
        return;
    }
    state.selectedItem = found;
};

const renderPlayers = () => {
    const term = (search.value || '').toLowerCase();
    playerList.innerHTML = '';
    const filtered = state.players.filter((p) => `${p.name} ${p.character} ${p.id}`.toLowerCase().includes(term));
    filtered.forEach((player) => {
        const card = document.createElement('div');
        card.className = 'player-card' + (state.selectedPlayer && state.selectedPlayer.id === player.id ? ' active' : '');
        const name = document.createElement('div');
        name.className = 'player-name';
        name.textContent = `${player.id} | ${player.name}`;
        const meta = document.createElement('div');
        meta.className = 'player-meta';
        const jobLabel = player.job && player.job.label ? `${player.job.label} (${player.job.gradeLabel || player.job.grade || 0})` : 'No job';
        meta.textContent = `${player.character || 'Unknown Character'} • ${player.ping}ms • ${jobLabel} • Cash: ${player.cash} • Bank: ${player.bank}`;
        card.appendChild(name);
        card.appendChild(meta);
        card.addEventListener('click', () => {
            state.selectedPlayer = player;
            state.itemTargetId = player.id;
            render();
        });
        playerList.appendChild(card);
    });
};

const renderReports = () => {
    reportsList.innerHTML = '';
    const reports = Object.values(state.reports || {});
    reports.sort((a, b) => (b.id || 0) - (a.id || 0));
    reports.forEach((report) => {
        const card = document.createElement('div');
        card.className = 'report-card';
        const name = document.createElement('div');
        name.className = 'player-name';
        name.textContent = `#${report.id} | ${report.playerName}`;
        const meta = document.createElement('div');
        meta.className = 'player-meta';
        meta.textContent = report.message || 'No message';
        const status = document.createElement('div');
        status.className = 'report-status';
        status.textContent = `Status: ${report.status || 'open'}`;
        card.appendChild(name);
        card.appendChild(meta);
        card.appendChild(status);
        if (report.status !== 'closed') {
            card.addEventListener('click', async () => {
                await post('action', { action: 'closereport', target: report.id });
            });
        }
        reportsList.appendChild(card);
    });
};

const renderDetail = () => {
    if (!state.selectedPlayer) {
        detailPanel.classList.add('hidden');
        jobSelectedPlayer.textContent = 'None';
        return;
    }
    detailPanel.classList.remove('hidden');
    detailTitle.textContent = `${state.selectedPlayer.id} | ${state.selectedPlayer.name}`;
    jobSelectedPlayer.textContent = `${state.selectedPlayer.id} | ${state.selectedPlayer.name}`;
};

const renderJobSelect = () => {
    const currentJob = state.selectedPlayer && state.selectedPlayer.job ? state.selectedPlayer.job.name : null;
    jobSelect.innerHTML = '';
    (state.jobs || []).forEach((job) => {
        const option = document.createElement('option');
        option.value = job.name;
        option.textContent = `${job.label} (${job.name})`;
        if (currentJob && currentJob === job.name) option.selected = true;
        jobSelect.appendChild(option);
    });
    renderGrades();
};

const renderGrades = () => {
    const selectedJob = (state.jobs || []).find((job) => job.name === jobSelect.value) || (state.jobs || [])[0];
    gradeSelect.innerHTML = '';
    if (!selectedJob) return;

    const currentGrade = state.selectedPlayer && state.selectedPlayer.job ? Number(state.selectedPlayer.job.grade || 0) : null;

    (selectedJob.grades || []).forEach((grade) => {
        const option = document.createElement('option');
        option.value = grade.grade;
        option.textContent = `${grade.grade} | ${grade.label}`;
        if (currentGrade !== null && currentGrade === Number(grade.grade)) option.selected = true;
        gradeSelect.appendChild(option);
    });
};

const renderDev = () => {
    devEnabledValue.textContent = state.dev.enabled ? 'On' : 'Off';
    devX.textContent = Number(state.dev.x || 0).toFixed(4);
    devY.textContent = Number(state.dev.y || 0).toFixed(4);
    devZ.textContent = Number(state.dev.z || 0).toFixed(4);
    devH.textContent = Number(state.dev.heading || 0).toFixed(4);
    copyOutput.value = state.dev.vector || 'vec4(0.0000, 0.0000, 0.0000, 0.0000)';
};

const renderItemTargetSelect = () => {
    if (!itemPlayerSelect) return;
    const activeTarget = getActiveItemTarget();
    itemPlayerSelect.innerHTML = '';

    (state.players || []).forEach((player) => {
        const option = document.createElement('option');
        option.value = player.id;
        option.textContent = `${player.id} | ${player.name} (${player.character || 'Unknown'})`;
        if (Number(activeTarget) === Number(player.id)) option.selected = true;
        itemPlayerSelect.appendChild(option);
    });

    const selected = (state.players || []).find((player) => Number(player.id) === Number(itemPlayerSelect.value || activeTarget || 0));
    itemSelectedPlayer.textContent = selected ? `${selected.id} | ${selected.name}` : 'None';
    if (selected) state.itemTargetId = selected.id;
};

const renderItemSelectedCard = () => {
    ensureSelectedItemStillExists();
    if (!state.selectedItem) {
        itemSelectedCard.classList.add('hidden');
        itemSelectedTitle.textContent = 'No item selected';
        itemSelectedMeta.textContent = 'Choose an item from the catalogue below.';
        return;
    }

    itemSelectedCard.classList.remove('hidden');
    itemSelectedTitle.textContent = `${state.selectedItem.label || state.selectedItem.name}`;

    const bits = [state.selectedItem.name];
    if (state.selectedItem.weight !== undefined) bits.push(`Weight: ${state.selectedItem.weight}`);
    bits.push(state.selectedItem.stack ? 'Stackable' : 'Non-stack');
    if (state.selectedItem.description) bits.push(state.selectedItem.description);
    itemSelectedMeta.textContent = bits.join(' • ');
};

const renderItemResults = () => {
    if (!itemResults) return;
    itemResults.innerHTML = '';
    const term = (itemSearch.value || '').trim().toLowerCase();
    const sorted = [...(state.itemCatalog || [])].sort((a, b) => (a.label || a.name).localeCompare(b.label || b.name));
    const filtered = sorted.filter((item) => !term || itemMatches(item, term)).slice(0, 60);

    if (!filtered.length) {
        const empty = document.createElement('div');
        empty.className = 'empty-state';
        empty.textContent = term ? 'No items match this search.' : 'No item catalogue loaded.';
        itemResults.appendChild(empty);
        return;
    }

    filtered.forEach((item) => {
        const button = document.createElement('button');
        button.className = 'item-result-card' + (state.selectedItem && state.selectedItem.name === item.name ? ' active' : '');

        const title = document.createElement('div');
        title.className = 'item-result-title';
        title.textContent = `${item.label || item.name}`;

        const meta = document.createElement('div');
        meta.className = 'item-result-meta';
        const bits = [item.name];
        if (item.weight !== undefined) bits.push(`Weight: ${item.weight}`);
        bits.push(item.stack ? 'Stackable' : 'Non-stack');
        if (item.description) bits.push(item.description);
        meta.textContent = bits.join(' • ');

        button.appendChild(title);
        button.appendChild(meta);
        button.addEventListener('click', () => {
            state.selectedItem = item;
            renderItemSelectedCard();
            renderItemResults();
        });
        itemResults.appendChild(button);
    });
};

const renderVehicleCategories = () => {
    vehicleCategories.innerHTML = '';
    const all = document.createElement('button');
    all.className = `category-btn ${state.selectedVehicleCategory === 'all' ? 'active' : ''}`;
    all.textContent = 'All';
    all.addEventListener('click', () => {
        state.selectedVehicleCategory = 'all';
        renderVehicles();
        renderVehicleCategories();
    });
    vehicleCategories.appendChild(all);

    (state.vehicleCategories || []).forEach((category) => {
        const btn = document.createElement('button');
        btn.className = `category-btn ${state.selectedVehicleCategory === category.id ? 'active' : ''}`;
        btn.textContent = category.label;
        btn.addEventListener('click', () => {
            state.selectedVehicleCategory = category.id;
            renderVehicles();
            renderVehicleCategories();
        });
        vehicleCategories.appendChild(btn);
    });
};

const renderVehicles = () => {
    vehicleGrid.innerHTML = '';
    const term = (vehicleSearch.value || '').toLowerCase();
    const filtered = (state.vehicleCatalog || []).filter((vehicle) => {
        const inCategory = state.selectedVehicleCategory === 'all' || vehicle.category === state.selectedVehicleCategory;
        const matches = `${vehicle.label} ${vehicle.model} ${vehicle.brand}`.toLowerCase().includes(term);
        return inCategory && matches;
    });

    if (!filtered.length) {
        const empty = document.createElement('div');
        empty.className = 'empty-state';
        empty.textContent = 'No vehicles match this filter.';
        vehicleGrid.appendChild(empty);
        return;
    }

    filtered.forEach((vehicle) => {
        const card = document.createElement('div');
        card.className = 'vehicle-card';

        const img = document.createElement('img');
        img.className = 'vehicle-thumb';
        img.src = vehicle.image;
        img.alt = vehicle.label;
        card.appendChild(img);

        const title = document.createElement('div');
        title.className = 'vehicle-title';
        title.textContent = vehicle.label;
        card.appendChild(title);

        const meta = document.createElement('div');
        meta.className = 'vehicle-meta';
        meta.textContent = `${vehicle.brand} • ${vehicle.model}`;
        card.appendChild(meta);

        const row = document.createElement('div');
        row.className = 'vehicle-meta-row';
        row.innerHTML = `<span>${vehicle.category}</span><span>${vehicle.class || 'vehicle'}</span>`;
        card.appendChild(row);

        const btn = document.createElement('button');
        btn.className = 'vehicle-spawn-btn';
        btn.textContent = 'Spawn + Register';
        btn.addEventListener('click', async () => {
            await post('action', {
                action: 'spawnregisteredvehicle',
                model: vehicle.model
            });
        });
        card.appendChild(btn);

        vehicleGrid.appendChild(card);
    });
};

const render = () => {
    groupValue.textContent = state.group || 'unknown';
    renderPlayers();
    renderReports();
    renderDetail();
    renderJobSelect();
    renderItemTargetSelect();
    renderItemSelectedCard();
    renderItemResults();
    renderDev();
    renderVehicleCategories();
    renderVehicles();
};

window.addEventListener('message', (event) => {
    const { action, data } = event.data || {};
    if (action === 'open') {
        state.group = data.group || 'unknown';
        state.permissions = data.permissions || {};
        state.players = data.players || [];
        state.reports = data.reports || {};
        state.jobs = data.jobs || [];
        state.itemCatalog = data.itemCatalog || [];
        state.vehicleCatalog = data.vehicleCatalog || [];
        state.vehicleCategories = data.vehicleCategories || [];
        state.selectedPlayer = null;
        state.itemTargetId = null;
        state.selectedItem = null;
        app.classList.remove('hidden');
        render();
    }
    if (action === 'refresh') {
        state.group = data.group || state.group;
        state.permissions = data.permissions || state.permissions;
        state.players = data.players || [];
        state.reports = data.reports || state.reports;
        state.jobs = data.jobs || state.jobs || [];
        state.itemCatalog = data.itemCatalog || state.itemCatalog || [];
        state.vehicleCatalog = data.vehicleCatalog || state.vehicleCatalog || [];
        state.vehicleCategories = data.vehicleCategories || state.vehicleCategories || [];
        if (state.selectedPlayer) {
            state.selectedPlayer = state.players.find((p) => p.id === state.selectedPlayer.id) || null;
        }
        render();
    }
    if (action === 'jobs') {
        state.jobs = data.jobs || state.jobs || [];
        state.players = data.players || state.players || [];
        if (state.selectedPlayer) {
            state.selectedPlayer = state.players.find((p) => p.id === state.selectedPlayer.id) || null;
        }
        render();
    }
    if (action === 'vehicleCatalog') {
        state.vehicleCatalog = data.vehicleCatalog || state.vehicleCatalog || [];
        state.vehicleCategories = data.vehicleCategories || state.vehicleCategories || [];
        renderVehicleCategories();
        renderVehicles();
    }
    if (action === 'reports') {
        state.reports = data || {};
        renderReports();
    }
    if (action === 'devmode') {
        state.dev = {
            ...state.dev,
            ...data
        };
        renderDev();
    }
    if (action === 'close') {
        app.classList.add('hidden');
    }
});

closeBtn.addEventListener('click', async () => {
    await post('close');
});
refreshBtn.addEventListener('click', async () => {
    await post('refresh');
});
search.addEventListener('input', render);
vehicleSearch.addEventListener('input', renderVehicles);
if (itemSearch) itemSearch.addEventListener('input', renderItemResults);
if (itemPlayerSelect) itemPlayerSelect.addEventListener('change', () => {
    state.itemTargetId = Number(itemPlayerSelect.value || 0) || null;
    renderItemTargetSelect();
});
jobSelect.addEventListener('change', renderGrades);

setJobBtn.addEventListener('click', async () => {
    if (!state.selectedPlayer) return;
    await post('action', {
        action: 'setjob',
        target: state.selectedPlayer.id,
        jobName: jobSelect.value,
        grade: Number(gradeSelect.value || 0)
    });
});

copyVecBtn.addEventListener('click', async () => {
    const transform = await post('copyCoords');
    const value = transform && transform.vector ? transform.vector : copyOutput.value;
    copyOutput.value = value;
    await navigator.clipboard.writeText(value);
});

copyPlainBtn.addEventListener('click', async () => {
    const transform = await post('copyCoords');
    const value = transform && transform.plain ? transform.plain : (state.dev.plain || '');
    copyOutput.value = value;
    await navigator.clipboard.writeText(value);
});

document.querySelectorAll('[data-action]').forEach((button) => {
    button.addEventListener('click', async () => {
        const action = button.dataset.action;
        if (!state.selectedPlayer && !['togglenoclip', 'togglegodmode', 'toggledevmode', 'spawnvehicle', 'spawnregisteredvehicle', 'deletevehicle', 'fixvehicle', 'cleanvehicle', 'givekeys', 'stopspectate', 'createreport', 'refreshself', 'giveitem', 'removeitem'].includes(action)) {
            return;
        }
        if (action === 'refreshself') {
            await post('refresh');
            return;
        }

        let input = actionInput ? actionInput.value || '' : '';
        let amount = moneyAmount ? moneyAmount.value || '' : '';
        let target = state.selectedPlayer ? state.selectedPlayer.id : null;

        if (action === 'giveitem' || action === 'removeitem') {
            input = state.selectedItem ? state.selectedItem.name : '';
            amount = itemAmount ? itemAmount.value || '1' : '1';
            target = getActiveItemTarget();
            if (!target || !input) {
                return;
            }
        }

        if (action === 'createreport') {
            input = reportInput ? reportInput.value || '' : '';
            amount = '';
        }

        await post('action', {
            action,
            target,
            input,
            amount
        });
    });
});
