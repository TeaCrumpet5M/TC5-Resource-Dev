const app = document.getElementById('app');
const cards = document.getElementById('cards');

function post(name, data = {}) {
  fetch(`https://${GetParentResourceName()}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
  });
}

window.addEventListener('message', (event) => {
  const { action, data } = event.data || {};

  if (action === 'openSelection') {
    app.classList.remove('hidden');
    cards.innerHTML = '';

    (data.choices || []).forEach((choice) => {
      const el = document.createElement('div');
      el.className = 'card';
      el.innerHTML = `
        <div class="card-title">${choice.label}</div>
        <div class="card-sub">Choose this apartment for your character. The apartment stash will use your TC5 inventory stash system.</div>
        <button>Select Apartment</button>
      `;
      el.querySelector('button').addEventListener('click', () => post('selectApartment', { id: choice.id }));
      cards.appendChild(el);
    });
  }

  if (action === 'closeSelection') {
    app.classList.add('hidden');
  }
});

document.getElementById('closeBtn').addEventListener('click', () => post('closeApartmentSelection'));
document.addEventListener('keyup', (e) => { if (e.key === 'Escape') post('closeApartmentSelection'); });
