const app = document.getElementById('app');
const cards = document.getElementById('cards');

function post(name, data = {}) {
  fetch(`https://${GetParentResourceName()}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
  });
}

function makeCard(label, description, coords, category) {
  const el = document.createElement('div');
  el.className = 'card';
  el.innerHTML = `
    <div class="chip">${category || 'spawn'}</div>
    <div class="card-title">${label}</div>
    <div class="card-sub">${description}</div>
    <button>Select Spawn</button>
  `;
  el.querySelector('button').addEventListener('click', () => post('selectSpawn', coords));
  return el;
}

window.addEventListener('message', (event) => {
  const { action, data } = event.data || {};
  if (action === 'open') {
    app.classList.remove('hidden');
    cards.innerHTML = '';

    (data.starterSpawns || []).forEach((spawn) => {
      cards.appendChild(makeCard(
        spawn.label,
        spawn.description || 'Spawn here.',
        spawn,
        spawn.category || 'spawn'
      ));
    });
  }

  if (action === 'close') {
    app.classList.add('hidden');
  }
});

document.getElementById('closeBtn').addEventListener('click', () => post('close'));
document.addEventListener('keyup', (e) => { if (e.key === 'Escape') post('close'); });
