const app = document.getElementById('app');
const closeButton = document.getElementById('closeButton');
const refreshButton = document.getElementById('refreshButton');
const accountsList = document.getElementById('accountsList');
const statementList = document.getElementById('statementList');
const cashOnHand = document.getElementById('cashOnHand');
const characterName = document.getElementById('characterName');
const jobInfo = document.getElementById('jobInfo');
const heroBrand = document.getElementById('heroBrand');
const heroSubtitle = document.getElementById('heroSubtitle');
const atmQuickActions = document.getElementById('atmQuickActions');

const selectedAccountName = document.getElementById('selectedAccountName');
const selectedAccountMeta = document.getElementById('selectedAccountMeta');
const selectedBalance = document.getElementById('selectedBalance');
const selectedType = document.getElementById('selectedType');
const selectedNumber = document.getElementById('selectedNumber');
const selectedSortCode = document.getElementById('selectedSortCode');

const depositAmount = document.getElementById('depositAmount');
const depositReference = document.getElementById('depositReference');
const withdrawAmount = document.getElementById('withdrawAmount');
const withdrawReference = document.getElementById('withdrawReference');
const transferTarget = document.getElementById('transferTarget');
const transferAmount = document.getElementById('transferAmount');
const transferReference = document.getElementById('transferReference');
const personalAccountName = document.getElementById('personalAccountName');
const businessJobName = document.getElementById('businessJobName');
const businessAccountName = document.getElementById('businessAccountName');

const depositButton = document.getElementById('depositButton');
const withdrawButton = document.getElementById('withdrawButton');
const transferButton = document.getElementById('transferButton');
const createPersonalButton = document.getElementById('createPersonalButton');
const createBusinessButton = document.getElementById('createBusinessButton');
const setDefaultButton = document.getElementById('setDefaultButton');

let state = {
  mode: 'bank',
  accounts: [],
  statements: {},
  selectedAccountId: null,
  cashOnHand: 0,
  character: null,
  job: null,
  config: {}
};

const post = async (endpoint, payload = {}) => {
  await fetch(`https://${GetParentResourceName()}/${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  });
};

const money = (value) => `$${Number(value || 0).toLocaleString()}`;

const getSelectedAccount = () => state.accounts.find((account) => Number(account.id) === Number(state.selectedAccountId)) || null;

const setSelectedAccount = (accountId) => {
  state.selectedAccountId = Number(accountId);
  render();
};

const renderAccountList = () => {
  accountsList.innerHTML = '';

  if (!state.accounts.length) {
    const empty = document.createElement('div');
    empty.className = 'empty-state';
    empty.textContent = 'No accounts available yet.';
    accountsList.appendChild(empty);
    return;
  }

  state.accounts.forEach((account) => {
    const card = document.createElement('div');
    card.className = 'account-card';
    if (Number(account.id) === Number(state.selectedAccountId)) {
      card.classList.add('active');
    }

    const top = document.createElement('div');
    top.className = 'account-top';
    top.innerHTML = `
      <div>
        <div class="account-title">${account.name}</div>
        <div class="account-subtitle">${account.accountNumber} • ${account.sortCode}</div>
      </div>
      <div class="account-balance">${money(account.balance)}</div>
    `;

    const bottom = document.createElement('div');
    bottom.className = 'account-bottom';
    bottom.innerHTML = `
      <div class="account-type">${account.type}</div>
      <div class="account-role">${account.permissions?.role || ''}</div>
    `;

    const badges = document.createElement('div');
    badges.className = 'badges';
    if (account.isDefault) {
      const badge = document.createElement('div');
      badge.className = 'badge default';
      badge.textContent = 'Default';
      badges.appendChild(badge);
    }
    if (account.type === 'business') {
      const badge = document.createElement('div');
      badge.className = 'badge business';
      badge.textContent = account.businessJobName || 'Business';
      badges.appendChild(badge);
    }
    if (account.isFrozen) {
      const badge = document.createElement('div');
      badge.className = 'badge';
      badge.textContent = 'Frozen';
      badges.appendChild(badge);
    }

    card.appendChild(top);
    card.appendChild(bottom);
    if (badges.childNodes.length) card.appendChild(badges);

    card.addEventListener('click', () => setSelectedAccount(account.id));
    accountsList.appendChild(card);
  });
};

const renderOverview = () => {
  const selected = getSelectedAccount();

  if (!selected) {
    selectedAccountName.textContent = 'No account selected';
    selectedAccountMeta.textContent = 'Choose an account from the left';
    selectedBalance.textContent = '$0';
    selectedType.textContent = 'Type';
    selectedNumber.textContent = '-';
    selectedSortCode.textContent = '-';
    return;
  }

  selectedAccountName.textContent = selected.name;
  selectedAccountMeta.textContent = `${selected.permissions?.role || 'member'} access`;
  selectedBalance.textContent = money(selected.balance);
  selectedType.textContent = `${selected.type}${selected.type === 'business' && selected.businessJobName ? ` • ${selected.businessJobName}` : ''}`;
  selectedNumber.textContent = selected.accountNumber;
  selectedSortCode.textContent = selected.sortCode;
};

const renderStatements = () => {
  statementList.innerHTML = '';
  const selected = getSelectedAccount();
  if (!selected) {
    const empty = document.createElement('div');
    empty.className = 'empty-state';
    empty.textContent = 'Select an account to view statements.';
    statementList.appendChild(empty);
    return;
  }

  const rows = state.statements?.[String(selected.id)] || [];
  if (!rows.length) {
    const empty = document.createElement('div');
    empty.className = 'empty-state';
    empty.textContent = 'No transaction history yet.';
    statementList.appendChild(empty);
    return;
  }

  rows.forEach((row) => {
    const element = document.createElement('div');
    element.className = 'statement-row';

    const isNegative = ['withdraw', 'transfer_out', 'fee'].includes(row.type);
    const amountClass = isNegative ? 'negative' : 'positive';
    const symbol = isNegative ? '-' : '+';

    element.innerHTML = `
      <div>
        <div class="statement-type">${row.type.replaceAll('_', ' ')}</div>
        <div class="statement-date">${row.createdAt || ''}</div>
      </div>
      <div class="statement-amount ${amountClass}">${symbol}${money(row.amount)}</div>
      <div class="statement-ref">${row.reference || 'No reference'}${row.targetAccountNumber ? ` • ${row.targetAccountNumber}` : ''}</div>
      <div class="statement-balance">Balance: ${money(row.balanceAfter)}</div>
    `;

    statementList.appendChild(element);
  });
};

const applyMode = () => {
  const bankOnlyTabs = document.querySelectorAll('.bank-only');
  if (state.mode === 'atm') {
    heroBrand.textContent = 'TC5 ATM';
    heroSubtitle.textContent = 'Quick access cash machine';
    bankOnlyTabs.forEach((el) => el.classList.add('hidden'));
    atmQuickActions.classList.remove('hidden');
  } else {
    heroBrand.textContent = 'TC5 BANK';
    heroSubtitle.textContent = 'Branch banking and account management';
    bankOnlyTabs.forEach((el) => el.classList.remove('hidden'));
    atmQuickActions.classList.remove('hidden');
  }
};

const render = () => {
  cashOnHand.textContent = money(state.cashOnHand);
  characterName.textContent = state.character?.fullName || 'Unknown';
  jobInfo.textContent = state.job?.name ? `${state.job.name} (${state.job.grade ?? 0})` : 'None';

  if (!state.selectedAccountId && state.accounts.length) {
    const defaultAccount = state.accounts.find((account) => account.isDefault) || state.accounts[0];
    state.selectedAccountId = defaultAccount.id;
  }

  applyMode();
  renderAccountList();
  renderOverview();
  renderStatements();
};

window.addEventListener('message', (event) => {
  const { action, data } = event.data || {};

  if (action === 'open' || action === 'refresh') {
    state = {
      ...state,
      ...data,
      accounts: data?.accounts || [],
      statements: data?.statements || {},
      selectedAccountId: data?.focusAccountId || state.selectedAccountId
    };
    app.classList.remove('hidden');
    render();
  }

  if (action === 'close') {
    app.classList.add('hidden');
  }
});

closeButton?.addEventListener('click', async () => post('close'));
refreshButton?.addEventListener('click', async () => post('refresh', { focusAccountId: state.selectedAccountId }));

document.querySelectorAll('.tab').forEach((tabButton) => {
  tabButton.addEventListener('click', () => {
    const tabName = tabButton.dataset.tab;
    document.querySelectorAll('.tab').forEach((tab) => tab.classList.remove('active'));
    document.querySelectorAll('.tab-pane').forEach((pane) => pane.classList.remove('active'));
    tabButton.classList.add('active');
    document.getElementById(`tab-${tabName}`)?.classList.add('active');
  });
});

depositButton?.addEventListener('click', async () => {
  const selected = getSelectedAccount();
  if (!selected) return;
  await post('deposit', {
    accountId: selected.id,
    amount: Number(depositAmount.value || 0),
    reference: depositReference.value || ''
  });
});

withdrawButton?.addEventListener('click', async () => {
  const selected = getSelectedAccount();
  if (!selected) return;
  await post('withdraw', {
    accountId: selected.id,
    amount: Number(withdrawAmount.value || 0),
    reference: withdrawReference.value || ''
  });
});

transferButton?.addEventListener('click', async () => {
  const selected = getSelectedAccount();
  if (!selected) return;
  await post('transfer', {
    fromAccountId: selected.id,
    targetAccountNumber: transferTarget.value || '',
    amount: Number(transferAmount.value || 0),
    reference: transferReference.value || ''
  });
});

createPersonalButton?.addEventListener('click', async () => {
  await post('createPersonalAccount', { name: personalAccountName.value || '' });
});

createBusinessButton?.addEventListener('click', async () => {
  await post('createBusinessAccount', {
    jobName: businessJobName.value || '',
    name: businessAccountName.value || ''
  });
});

setDefaultButton?.addEventListener('click', async () => {
  const selected = getSelectedAccount();
  if (!selected) return;
  await post('setDefaultAccount', { accountId: selected.id });
});

document.querySelectorAll('.quick-action').forEach((button) => {
  button.addEventListener('click', async () => {
    const selected = getSelectedAccount();
    if (!selected) return;
    await post('withdraw', {
      accountId: selected.id,
      amount: Number(button.dataset.amount || 0),
      reference: 'ATM quick withdrawal'
    });
  });
});
