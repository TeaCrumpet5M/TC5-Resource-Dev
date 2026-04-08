const radial = document.getElementById('radial');
const itemsEl = document.getElementById('items');

function post(action, data = {}) {
  return fetch(`https://${GetParentResourceName()}/${action}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
  });
}

function render(items) {
  itemsEl.innerHTML = '';
  if (!items || !items.length) return;

  const radius = 180;
  const step = (Math.PI * 2) / items.length;

  items.forEach((item, index) => {
    const angle = (index * step) - (Math.PI / 2);
    const x = Math.cos(angle) * radius;
    const y = Math.sin(angle) * radius;

    const el = document.createElement('div');
    el.className = 'radial-item';
    el.style.transform = `translate(${x}px, ${y}px)`;
    el.innerHTML = `<div class="icon">${item.icon || '•'}</div><div class="label">${item.label || 'Action'}</div>`;
    el.addEventListener('click', () => post('select', { id: item.id }));
    itemsEl.appendChild(el);
  });
}

window.addEventListener('message', (event) => {
  const { action, data } = event.data || {};
  if (action === 'open') radial.classList.remove('hidden');
  if (action === 'close') radial.classList.add('hidden');
  if (action === 'setItems') render(data.items || []);
});

document.addEventListener('keyup', (e) => {
  if (e.key === 'Escape') post('close');
});
