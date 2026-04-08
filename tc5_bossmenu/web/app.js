const app = document.getElementById('app');
const jobLabel = document.getElementById('jobLabel');
const jobInfo = document.getElementById('jobInfo');
const societyBalance = document.getElementById('societyBalance');
const moneyAmount = document.getElementById('moneyAmount');
const employeesEl = document.getElementById('employees');
const nearbyEl = document.getElementById('nearbyPlayers');
const salaryListEl = document.getElementById('salaryList');
const employeeCount = document.getElementById('employeeCount');
const salaryCount = document.getElementById('salaryCount');

let state = {
  job: null,
  society: { balance: 0 },
  employees: [],
  salaries: [],
  nearbyPlayers: []
};

function post(action, data = {}) {
  return fetch(`https://${GetParentResourceName()}/${action}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
  });
}

function setTab(name) {
  document.querySelectorAll('.tab').forEach((el) => el.classList.toggle('active', el.dataset.tab === name));
  document.querySelectorAll('.tab-panel').forEach((el) => el.classList.toggle('active', el.id === `tab-${name}`));
}

function renderEmployees() {
  employeesEl.innerHTML = '';
  if (!state.employees.length) {
    employeesEl.innerHTML = '<div class="employee"><div><strong>No employees</strong><div class="employee-meta">No employee records found yet.</div></div></div>';
    return;
  }

  state.employees.forEach((employee) => {
    const row = document.createElement('div');
    row.className = 'employee';
    row.innerHTML = `
      <div>
        <div><strong>${employee.full_name || 'Unknown Employee'}</strong></div>
        <div class="employee-meta">Character ID: ${employee.character_id} • Grade: ${employee.grade} • Salary: $${employee.salary || 0}</div>
      </div>
      <div class="employee-actions">
        <input type="number" min="0" value="${employee.grade}" />
        <button>Save Grade</button>
        <button class="secondary">Fire</button>
      </div>
    `;

    const gradeInput = row.querySelector('input');
    const saveBtn = row.querySelectorAll('button')[0];
    const fireBtn = row.querySelectorAll('button')[1];

    saveBtn.addEventListener('click', () => {
      post('updateGrade', {
        characterId: employee.character_id,
        grade: Number(gradeInput.value || 0)
      });
    });

    fireBtn.addEventListener('click', () => {
      post('fireEmployee', { characterId: employee.character_id });
    });

    employeesEl.appendChild(row);
  });
}

function renderNearbyPlayers() {
  nearbyEl.innerHTML = '';
  if (!state.nearbyPlayers.length) {
    nearbyEl.innerHTML = '<div class="employee"><div><strong>No nearby players</strong><div class="employee-meta">Move closer to a player and scan again.</div></div></div>';
    return;
  }

  state.nearbyPlayers.forEach((entry) => {
    const row = document.createElement('div');
    row.className = 'employee';
    row.innerHTML = `
      <div>
        <div><strong>${entry.fullName || 'Unknown Player'}</strong></div>
        <div class="employee-meta">Source: ${entry.source} • Distance: ${Number(entry.distance || 0).toFixed(2)}m</div>
      </div>
      <div class="employee-actions">
        <button>Hire</button>
      </div>
    `;
    row.querySelector('button').addEventListener('click', () => {
      post('hireNearby', { source: entry.source });
    });
    nearbyEl.appendChild(row);
  });
}

function renderSalaries() {
  salaryListEl.innerHTML = '';
  if (!state.salaries.length) {
    salaryListEl.innerHTML = '<div class="employee"><div><strong>No salaries configured</strong><div class="employee-meta">Create your first grade salary above.</div></div></div>';
    return;
  }

  state.salaries.forEach((entry) => {
    const row = document.createElement('div');
    row.className = 'employee';
    row.innerHTML = `
      <div>
        <div><strong>Grade ${entry.grade}</strong></div>
        <div class="employee-meta">Salary: $${entry.salary}</div>
      </div>
    `;
    salaryListEl.appendChild(row);
  });
}

function render() {
  jobLabel.textContent = state.job?.label || state.job?.name || 'Boss Menu';
  jobInfo.textContent = `Manage ${state.job?.label || state.job?.name || 'your job'} society, staff, storage, and pay grades.`;
  societyBalance.textContent = `$${Number(state.society?.balance || 0).toLocaleString()}`;
  employeeCount.textContent = String(state.employees.length || 0);
  salaryCount.textContent = String(state.salaries.length || 0);
  renderEmployees();
  renderNearbyPlayers();
  renderSalaries();
}

window.addEventListener('message', (event) => {
  const { action, data } = event.data || {};

  if (action === 'open') {
    state = { ...(data || {}), nearbyPlayers: [] };
    app.classList.remove('hidden');
    setTab('society');
    render();
  }

  if (action === 'refresh') {
    state = { ...(data || {}), nearbyPlayers: state.nearbyPlayers || [] };
    render();
  }

  if (action === 'setNearbyPlayers') {
    state.nearbyPlayers = data?.players || [];
    renderNearbyPlayers();
  }

  if (action === 'close') {
    app.classList.add('hidden');
  }
});

document.getElementById('closeBtn').addEventListener('click', () => post('close'));
document.getElementById('refreshBtn').addEventListener('click', () => post('refresh'));
document.getElementById('nearbyBtn').addEventListener('click', () => post('getNearbyPlayers'));
document.getElementById('depositBtn').addEventListener('click', () => post('deposit', { amount: Number(moneyAmount.value || 0) }));
document.getElementById('withdrawBtn').addEventListener('click', () => post('withdraw', { amount: Number(moneyAmount.value || 0) }));
document.getElementById('salarySaveBtn').addEventListener('click', () => post('setSalary', {
  grade: Number(document.getElementById('salaryGrade').value || 0),
  salary: Number(document.getElementById('salaryAmount').value || 0)
}));
document.getElementById('bossStashBtn').addEventListener('click', () => post('openBossStash'));
document.getElementById('societyInventoryBtn').addEventListener('click', () => post('openSocietyInventory'));

document.querySelectorAll('.tab').forEach((btn) => {
  btn.addEventListener('click', () => setTab(btn.dataset.tab));
});
