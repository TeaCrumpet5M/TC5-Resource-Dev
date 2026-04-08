const app = document.getElementById('app');
const spawnList = document.getElementById('spawnList');
let spawns = [];

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

function render() {
  spawnList.innerHTML = spawns.map((spawn, index) => `
    <div class="card">
      <h3>${escapeHtml(spawn.label || `Spawn ${index + 1}`)}</h3>
      <div class="meta">${escapeHtml(spawn.description || 'Spawn location')}</div>
      <button data-spawn-index="${index}">Spawn Here</button>
    </div>
  `).join('');

  document.querySelectorAll('[data-spawn-index]').forEach((button) => {
    button.addEventListener('click', () => {
      const spawn = spawns[Number(button.dataset.spawnIndex)];
      if (spawn) {
        resourcePost('selectSpawn', spawn);
      }
    });
  });
}

window.addEventListener('message', (event) => {
  const { action, data } = event.data || {};
  if (action === 'open') {
    spawns = Array.isArray(data?.starterSpawns) ? data.starterSpawns : [];
    app.classList.remove('hidden');
    render();
  }
  if (action === 'close') {
    app.classList.add('hidden');
  }
});

document.addEventListener('keyup', (event) => {
  if (event.key === 'Escape') {
    resourcePost('close', {});
  }
});
