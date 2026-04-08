const eye = document.getElementById('eye');
const optionsEl = document.getElementById('options');

function post(action, data = {}) {
  return fetch(`https://${GetParentResourceName()}/${action}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
  });
}

function renderOptions(options) {
  optionsEl.innerHTML = '';
  if (!options || !options.length) return;

  options.forEach(option => {
    const el = document.createElement('div');
    el.className = 'option';
    el.innerHTML = `<div class="icon">${option.icon || '•'}</div><div>${option.label || 'Interact'}</div>`;
    el.addEventListener('click', () => post('select', { id: option.id }));
    optionsEl.appendChild(el);
  });
}

window.addEventListener('message', (event) => {
  const { action, data } = event.data || {};
  if (action === 'open') eye.classList.remove('hidden');
  if (action === 'close') eye.classList.add('hidden');
  if (action === 'setOptions') renderOptions(data.options || []);
});
