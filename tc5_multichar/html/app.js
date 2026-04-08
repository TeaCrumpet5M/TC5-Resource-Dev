const app = document.getElementById('app');
const characterList = document.getElementById('characterList');
const slotInfo = document.getElementById('slotInfo');
const firstNameInput = document.getElementById('firstName');
const lastNameInput = document.getElementById('lastName');
const createBtn = document.getElementById('createBtn');
const refreshBtn = document.getElementById('refreshBtn');

let payload = { maxSlots: 4, characters: [] };

function resourcePost(action, data = {}) {
  fetch(`https://${GetParentResourceName()}/${action}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
  }).catch(() => {});
}

function escapeHtml(value) {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}

function renderCharacters() {
  const characters = Array.isArray(payload.characters) ? payload.characters : [];
  slotInfo.textContent = `Slots used: ${characters.length}/${payload.maxSlots || 4}`;

  if (!characters.length) {
    characterList.innerHTML = '<div class="empty">No characters found yet. Create your first one on the right.</div>';
    return;
  }

  characterList.innerHTML = characters.map((character) => {
    const creatorState = character.hasCompletedCreator ? 'Creator complete' : 'Needs creator';
    const apartmentState = character.apartmentId ? `Apartment #${character.apartmentId}` : 'No apartment yet';
    return `
      <div class="card">
        <h3>${escapeHtml(character.fullName || `${character.firstName || 'New'} ${character.lastName || 'Citizen'}`)}</h3>
        <div class="meta">Cash: $${Number(character.cash || 0).toLocaleString()} • Bank: $${Number(character.bank || 0).toLocaleString()}</div>
        <div class="badges">
          <div class="badge">${escapeHtml(creatorState)}</div>
          <div class="badge">${escapeHtml(apartmentState)}</div>
          ${character.isSelected ? '<div class="badge">Previously selected</div>' : ''}
        </div>
        <button class="primary select-btn" data-character-id="${character.id}">Play this character</button>
      </div>
    `;
  }).join('');

  document.querySelectorAll('[data-character-id]').forEach((button) => {
    button.addEventListener('click', () => {
      resourcePost('selectCharacter', { characterId: Number(button.dataset.characterId) });
    });
  });
}

window.addEventListener('message', (event) => {
  const { action, data } = event.data || {};
  if (action === 'open') {
    payload = data || { maxSlots: 4, characters: [] };
    app.classList.remove('hidden');
    renderCharacters();
  }
  if (action === 'close') {
    app.classList.add('hidden');
  }
});

createBtn.addEventListener('click', () => {
  resourcePost('createCharacter', {
    firstName: firstNameInput.value.trim(),
    lastName: lastNameInput.value.trim()
  });
});

refreshBtn.addEventListener('click', () => {
  resourcePost('refresh', {});
});

document.addEventListener('keyup', (event) => {
  if (event.key === 'Escape') {
    resourcePost('close', {});
  }
});
