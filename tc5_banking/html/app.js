
const app = document.getElementById('app');
const closeButton = document.getElementById('closeButton');
const refreshButton = document.getElementById('refreshButton');
const accountsList = document.getElementById('accountsList');
const characterName = document.getElementById('characterName');
const cashOnHand = document.getElementById('cashOnHand');
const jobInfo = document.getElementById('jobInfo');
const modeInfo = document.getElementById('modeInfo');
const selectedAccountName = document.getElementById('selectedAccountName');
const selectedAccountMeta = document.getElementById('selectedAccountMeta');
const selectedBalance = document.getElementById('selectedBalance');
const selectedType = document.getElementById('selectedType');
const selectedNumber = document.getElementById('selectedNumber');
const selectedSortCode = document.getElementById('selectedSortCode');
const statementList = document.getElementById('statementList');
const invoiceList = document.getElementById('invoiceList');
const payrollList = document.getElementById('payrollList');

const tabs = Array.from(document.querySelectorAll('.tab'));
const panes = Array.from(document.querySelectorAll('.tab-pane'));
const bankOnlyTabs = Array.from(document.querySelectorAll('.bank-only'));
const atmQuickActions = document.getElementById('atmQuickActions');

let state = {
  mode: 'bank',
  character: null,
  cashOnHand: 0,
  job: null,
  accounts: [],
  statements: {},
  payroll: {},
  pendingInvoices: [],
  focusAccountId: null,
  config: {}
};

let selectedAccountId = null;
let activeTab = 'overview';

const post = async (endpoint, payload = {}) => {
  await fetch(`https://${GetParentResourceName()}/${endpoint}`, {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify(payload)
  });
};

const money = (value) => `$${Number(value || 0).toLocaleString()}`;

const getSelectedAccount = () => {
  if (!state.accounts.length) return null;
  if (selectedAccountId) {
    const found = state.accounts.find((a) => Number(a.id) === Number(selectedAccountId));
    if (found) return found;
  }
  const fallback = state.accounts.find((a) => Number(a.id) === Number(state.focusAccountId))
    || state.accounts[0];
  selectedAccountId = fallback?.id || null;
  return fallback || null;
};

const switchTab = (tab) => {
  activeTab = tab;
  tabs.forEach((btn) => btn.classList.toggle('active', btn.dataset.tab === tab));
  panes.forEach((pane) => pane.classList.toggle('active', pane.id === `tab-${tab}`));
};

const setModeVisibility = () => {
  const mobile = state.mode === 'mobile';
  const atm = state.mode === 'atm';

  bankOnlyTabs.forEach((tab) => tab.classList.toggle('hidden', mobile || atm));
  document.getElementById('tab-manage').classList.toggle('hidden', mobile || atm);

  if (mobile && activeTab === 'manage') switchTab('overview');
  if (atm && activeTab === 'manage') switchTab('overview');

  const depositButton = document.getElementById('depositButton');
  const withdrawButton = document.getElementById('withdrawButton');

  if (state.mode === 'mobile') {
    document.getElementById('depositAmount').disabled = true;
    document.getElementById('depositReference').disabled = true;
    depositButton.disabled = true;
    document.getElementById('withdrawAmount').disabled = true;
    document.getElementById('withdrawReference').disabled = true;
    withdrawButton.disabled = true;
    atmQuickActions.classList.add('hidden');
  } else {
    const atmDepositDisabled = atm && state.config?.enableATMDeposits === false;
    document.getElementById('depositAmount').disabled = atmDepositDisabled;
    document.getElementById('depositReference').disabled = atmDepositDisabled;
    depositButton.disabled = atmDepositDisabled;
    document.getElementById('withdrawAmount').disabled = false;
    document.getElementById('withdrawReference').disabled = false;
    withdrawButton.disabled = false;
    atmQuickActions.classList.toggle('hidden', !atm);
  }

  const transferDisabled = atm && state.config?.enableATMTransfers === false;
  document.getElementById('transferTarget').disabled = transferDisabled;
  document.getElementById('transferAmount').disabled = transferDisabled;
  document.getElementById('transferReference').disabled = transferDisabled;
  document.getElementById('transferButton').disabled = transferDisabled;
};

const renderAccounts = () => {
  accountsList.innerHTML = '';
  if (!state.accounts.length) {
    accountsList.innerHTML = '<div class="statement-card empty">No accounts available yet.</div>';
    return;
  }

  const selected = getSelectedAccount();

  state.accounts.forEach((account) => {
    const card = document.createElement('div');
    card.className = `account-card ${selected && Number(selected.id) === Number(account.id) ? 'active' : ''}`;

    card.innerHTML = `
      <div class="account-top">
        <div>
          <div class="account-name">${account.name}</div>
          <div class="account-meta">${account.accountNumber} • ${account.sortCode}</div>
        </div>
        <div class="balance">${money(account.balance)}</div>
      </div>
      <div class="account-top" style="margin-top: 10px;">
        <div class="account-meta">${account.type}${account.businessJobName ? ' • ' + account.businessJobName : ''}</div>
        <div style="display:flex; gap:6px; flex-wrap:wrap;">
          ${account.isDefault ? '<span class="badge">default</span>' : ''}
          ${account.isFrozen ? '<span class="badge">frozen</span>' : ''}
          <span class="badge">${account.permissions?.role || 'member'}</span>
        </div>
      </div>
    `;

    card.addEventListener('click', () => {
      selectedAccountId = account.id;
      render();
    });

    accountsList.appendChild(card);
  });
};

const renderOverview = () => {
  const selected = getSelectedAccount();
  if (!selected) {
    selectedAccountName.textContent = 'No account selected';
    selectedAccountMeta.textContent = 'Create or select an account';
    selectedBalance.textContent = '$0';
    selectedType.textContent = '-';
    selectedNumber.textContent = '-';
    selectedSortCode.textContent = '-';
    payrollList.innerHTML = '';
    statementList.innerHTML = '<div class="statement-card empty">No transactions to show.</div>';
    return;
  }

  selectedAccountName.textContent = selected.name;
  selectedAccountMeta.textContent = selected.businessJobName
    ? `${selected.type} • ${selected.businessJobName}`
    : `${selected.type}${selected.isDefault ? ' • default' : ''}`;
  selectedBalance.textContent = money(selected.balance);
  selectedType.textContent = `${selected.type}${selected.permissions?.role ? ' • ' + selected.permissions.role : ''}`;
  selectedNumber.textContent = selected.accountNumber;
  selectedSortCode.textContent = selected.sortCode;

  const accessInput = document.getElementById('businessAccessGrade');
  if (accessInput && selected.permissions?.minGrade !== undefined) {
    accessInput.value = selected.permissions.minGrade;
  }

  const payroll = state.payroll?.[String(selected.id)] || [];
  payrollList.innerHTML = payroll.length
    ? payroll.map((row) => `<div class="mini-item"><span>Grade ${row.grade}</span><strong>${money(row.amount)}</strong></div>`).join('')
    : '<div class="statement-card empty">No payroll entries for this account.</div>';
};

const renderStatements = () => {
  const selected = getSelectedAccount();
  const statements = selected ? (state.statements?.[String(selected.id)] || []) : [];
  statementList.innerHTML = '';

  if (!statements.length) {
    statementList.innerHTML = '<div class="statement-card empty">No transactions to show.</div>';
    return;
  }

  statements.forEach((entry) => {
    const row = document.createElement('div');
    row.className = 'statement-card';
    row.innerHTML = `
      <div class="statement-top">
        <div>
          <div class="account-name">${entry.type.replaceAll('_', ' ')}</div>
          <div class="muted">${entry.createdAt}</div>
        </div>
        <div class="balance">${money(entry.amount)}</div>
      </div>
      <div class="muted" style="margin-top:8px;">${entry.reference || 'No reference'}</div>
      <div class="muted" style="margin-top:6px;">Balance after: ${money(entry.balanceAfter)}${entry.targetAccountNumber ? ` • ${entry.targetAccountNumber}` : ''}</div>
    `;
    statementList.appendChild(row);
  });
};

const renderInvoices = () => {
  invoiceList.innerHTML = '';
  const invoices = state.pendingInvoices || [];

  if (!invoices.length) {
    invoiceList.innerHTML = '<div class="statement-card empty">No pending invoices.</div>';
    return;
  }

  invoices.forEach((invoice) => {
    const card = document.createElement('div');
    card.className = 'invoice-card';
    card.innerHTML = `
      <div class="statement-top">
        <div>
          <div class="account-name">Invoice #${invoice.id}</div>
          <div class="muted">${invoice.fromName} • ${invoice.accountName}</div>
        </div>
        <div class="balance">${money(invoice.amount)}</div>
      </div>
      <div class="muted" style="margin-top:8px;">${invoice.reason || 'No reason provided'}</div>
      <div class="muted" style="margin-top:6px;">${invoice.createdAt}</div>
      <div class="invoice-actions">
        <button class="primary-btn" data-accept="${invoice.id}">Pay</button>
        <button class="ghost-btn" data-decline="${invoice.id}">Decline</button>
      </div>
    `;
    invoiceList.appendChild(card);
  });

  invoiceList.querySelectorAll('[data-accept]').forEach((button) => {
    button.addEventListener('click', async () => {
      await post('acceptInvoice', { invoiceId: Number(button.dataset.accept) });
    });
  });

  invoiceList.querySelectorAll('[data-decline]').forEach((button) => {
    button.addEventListener('click', async () => {
      await post('declineInvoice', { invoiceId: Number(button.dataset.decline) });
    });
  });
};

const render = () => {
  characterName.textContent = state.character?.fullName || 'Unknown';
  cashOnHand.textContent = money(state.cashOnHand);
  jobInfo.textContent = state.job?.name ? `${state.job.name} (grade ${state.job.grade})` : 'None';
  modeInfo.textContent = state.mode.charAt(0).toUpperCase() + state.mode.slice(1);

  setModeVisibility();
  renderAccounts();
  renderOverview();
  renderStatements();
  renderInvoices();
};

window.addEventListener('message', (event) => {
  const { action, data } = event.data || {};

  if (action === 'open' || action === 'refresh') {
    state = data || state;
    selectedAccountId = data?.focusAccountId || selectedAccountId || state.accounts?.[0]?.id || null;
    app.classList.remove('hidden');
    render();
  }

  if (action === 'close') {
    app.classList.add('hidden');
  }
});

tabs.forEach((button) => {
  button.addEventListener('click', () => switchTab(button.dataset.tab));
});

closeButton?.addEventListener('click', async () => {
  await post('close');
});

refreshButton?.addEventListener('click', async () => {
  await post('refresh', { focusAccountId: selectedAccountId });
});

Array.from(document.querySelectorAll('.quick-action')).forEach((button) => {
  button.addEventListener('click', async () => {
    const selected = getSelectedAccount();
    if (!selected) return;
    await post('withdraw', {
      accountId: selected.id,
      amount: Number(button.dataset.amount),
      reference: 'ATM quick withdraw'
    });
  });
});

document.getElementById('depositButton')?.addEventListener('click', async () => {
  const selected = getSelectedAccount();
  if (!selected) return;
  await post('deposit', {
    accountId: selected.id,
    amount: Number(document.getElementById('depositAmount').value || 0),
    reference: document.getElementById('depositReference').value || ''
  });
});

document.getElementById('withdrawButton')?.addEventListener('click', async () => {
  const selected = getSelectedAccount();
  if (!selected) return;
  await post('withdraw', {
    accountId: selected.id,
    amount: Number(document.getElementById('withdrawAmount').value || 0),
    reference: document.getElementById('withdrawReference').value || ''
  });
});

document.getElementById('transferButton')?.addEventListener('click', async () => {
  const selected = getSelectedAccount();
  if (!selected) return;
  await post('transfer', {
    fromAccountId: selected.id,
    targetAccountNumber: document.getElementById('transferTarget').value || '',
    amount: Number(document.getElementById('transferAmount').value || 0),
    reference: document.getElementById('transferReference').value || ''
  });
});

document.getElementById('createPersonalButton')?.addEventListener('click', async () => {
  await post('createPersonalAccount', {
    name: document.getElementById('personalAccountName').value || ''
  });
});

document.getElementById('createBusinessButton')?.addEventListener('click', async () => {
  await post('createBusinessAccount', {
    jobName: document.getElementById('businessJobName').value || '',
    name: document.getElementById('businessAccountName').value || ''
  });
});

document.getElementById('setDefaultButton')?.addEventListener('click', async () => {
  const selected = getSelectedAccount();
  if (!selected) return;
  await post('setDefaultAccount', { accountId: selected.id });
});

document.getElementById('createInvoiceButton')?.addEventListener('click', async () => {
  const selected = getSelectedAccount();
  if (!selected) return;
  await post('createInvoice', {
    accountId: selected.id,
    targetSrc: Number(document.getElementById('invoiceTarget').value || 0),
    amount: Number(document.getElementById('invoiceAmount').value || 0),
    reason: document.getElementById('invoiceReason').value || ''
  });
});

document.getElementById('businessPayButton')?.addEventListener('click', async () => {
  const selected = getSelectedAccount();
  if (!selected) return;
  await post('businessPayPlayer', {
    accountId: selected.id,
    targetSrc: Number(document.getElementById('businessPayTarget').value || 0),
    amount: Number(document.getElementById('businessPayAmount').value || 0),
    reference: document.getElementById('businessPayReason').value || ''
  });
});

document.getElementById('setBusinessAccessButton')?.addEventListener('click', async () => {
  const selected = getSelectedAccount();
  if (!selected) return;
  await post('setBusinessAccess', {
    accountId: selected.id,
    minGrade: Number(document.getElementById('businessAccessGrade').value || 0)
  });
});

document.getElementById('toggleFrozenButton')?.addEventListener('click', async () => {
  const selected = getSelectedAccount();
  if (!selected) return;
  await post('setBusinessFrozen', {
    accountId: selected.id,
    frozen: !selected.isFrozen
  });
});

document.getElementById('setPayrollButton')?.addEventListener('click', async () => {
  const selected = getSelectedAccount();
  if (!selected) return;
  await post('setPayroll', {
    accountId: selected.id,
    grade: Number(document.getElementById('payrollGrade').value || 0),
    amount: Number(document.getElementById('payrollAmount').value || 0)
  });
});
