const app = document.getElementById('app');
const managerView = document.getElementById('manager-view');
const editorView = document.getElementById('editor-view');
const doorList = document.getElementById('door-list');
const search = document.getElementById('search');

const fields = {
  name: document.getElementById('name'),
  model: document.getElementById('model'),
  doorType: document.getElementById('doorType'),
  rollerOpenRatio: document.getElementById('rollerOpenRatio'),
  locked: document.getElementById('locked'),
  double: document.getElementById('double'),
  distance: document.getElementById('distance'),
  doorRate: document.getElementById('doorRate'),
  jobs: document.getElementById('jobs'),
  gangs: document.getElementById('gangs'),
  characters: document.getElementById('characters')
};

let managerDoors = [];
let currentMode = 'create';
let currentDoor = null;

function post(action, data = {}) {
  return fetch(`https://${GetParentResourceName()}/${action}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
  });
}

function openRoot() { app.classList.remove('hidden'); }
function closeRoot() { app.classList.add('hidden'); }
function showManager() { managerView.classList.remove('hidden'); editorView.classList.add('hidden'); }
function showEditor() { managerView.classList.add('hidden'); editorView.classList.remove('hidden'); }

function renderDoorList() {
  const q = (search.value || '').trim().toLowerCase();
  doorList.innerHTML = '';
  const filtered = managerDoors.filter(door => !q || String(door.id).includes(q) || String(door.name || '').toLowerCase().includes(q));

  if (!filtered.length) {
    doorList.innerHTML = '<div class="meta">No doors found.</div>';
    return;
  }

  filtered.forEach(door => {
    const row = document.createElement('div');
    row.className = 'door-row';
    row.innerHTML = `<div><div><strong>#${door.id}</strong> ${door.name || 'Unnamed Door'}</div><div class="meta">${door.locked ? 'Locked' : 'Unlocked'} • ${door.doorType || 'standard'} • model ${door.model}</div></div><button class="small-btn">Edit</button>`;
    row.querySelector('button').addEventListener('click', () => post('requestEditDoor', { doorId: door.id }));
    doorList.appendChild(row);
  });
}

function fillEditor(door, mode) {
  currentMode = mode || 'create';
  currentDoor = door || {};
  fields.name.value = door?.name || '';
  fields.model.value = door?.model || '';
  fields.doorType.value = door?.doorType || 'standard';
  fields.rollerOpenRatio.value = door?.rollerOpenRatio ?? 1.0;
  fields.locked.value = String(door?.locked !== false);
  fields.double.value = String(door?.double === true);
  fields.distance.value = door?.distance || 2.5;
  fields.doorRate.value = door?.doorRate || 1.0;
  fields.jobs.value = JSON.stringify(door?.access?.jobs || {}, null, 2);
  fields.gangs.value = JSON.stringify(door?.access?.gangs || {}, null, 2);
  fields.characters.value = JSON.stringify(door?.access?.characters || {}, null, 2);
  showEditor();
}

function collectEditor() {
  return {
    ...currentDoor,
    name: fields.name.value,
    model: fields.model.value,
    doorType: fields.doorType.value,
    rollerOpenRatio: parseFloat(fields.rollerOpenRatio.value || '1.0'),
    locked: fields.locked.value === 'true',
    double: fields.double.value === 'true',
    distance: parseFloat(fields.distance.value || '2.5'),
    doorRate: parseFloat(fields.doorRate.value || '1.0'),
    access: {
      jobs: JSON.parse(fields.jobs.value || '{}'),
      gangs: JSON.parse(fields.gangs.value || '{}'),
      characters: JSON.parse(fields.characters.value || '{}')
    }
  };
}

window.addEventListener('message', (event) => {
  const { action, data } = event.data || {};
  if (action === 'open') openRoot();
  if (action === 'close') closeRoot();
  if (action === 'showManager') { managerDoors = data?.doors || []; renderDoorList(); showManager(); }
  if (action === 'updateDoorList') { managerDoors = data?.doors || []; renderDoorList(); }
  if (action === 'showEditor') fillEditor(data?.door || {}, data?.mode || 'create');
});

document.getElementById('close').addEventListener('click', () => post('close'));
document.getElementById('back-manager').addEventListener('click', showManager);
document.getElementById('create-door').addEventListener('click', () => post('requestCreateFromAim'));
document.getElementById('save').addEventListener('click', () => {
  try {
    post('saveDoor', { mode: currentMode, door: collectEditor() });
  } catch (err) {
    alert('Invalid JSON in access fields.');
  }
});
document.getElementById('delete').addEventListener('click', () => {
  if (!currentDoor?.id) return;
  post('deleteDoor', { doorId: currentDoor.id });
});
search.addEventListener('input', renderDoorList);
