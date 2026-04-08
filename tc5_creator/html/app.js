const creator = document.getElementById('creator');
const firstName = document.getElementById('firstName');
const lastName = document.getElementById('lastName');

function post(name, data = {}) {
  fetch(`https://${GetParentResourceName()}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
  });
}

window.addEventListener('message', (event) => {
  const { action, data } = event.data || {};
  if (action === 'open') {
    creator.classList.remove('hidden');
    firstName.value = data.firstName || '';
    lastName.value = data.lastName || '';
  }
  if (action === 'close') {
    creator.classList.add('hidden');
  }
});

document.getElementById('cancel').addEventListener('click', () => post('close'));
document.getElementById('save').addEventListener('click', () => {
  post('submit', { firstName: firstName.value.trim(), lastName: lastName.value.trim() });
});
document.addEventListener('keyup', (e) => {
  if (e.key === 'Escape') post('close');
});
