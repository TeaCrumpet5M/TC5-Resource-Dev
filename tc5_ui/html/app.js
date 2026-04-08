const notifications = document.getElementById('notifications');
const loading = document.getElementById('loading');
const loadingTitle = document.getElementById('loading-title');
const loadingMessage = document.getElementById('loading-message');
const statusHud = document.getElementById('status-hud');
const statusHealthFill = document.getElementById('status-health-fill');
const statusArmourFill = document.getElementById('status-armour-fill');
const statusFoodFill = document.getElementById('status-food-fill');
const statusDrinkFill = document.getElementById('status-drink-fill');
const statusHealthValue = document.getElementById('status-health-value');
const statusArmourValue = document.getElementById('status-armour-value');
const statusFoodValue = document.getElementById('status-food-value');
const statusDrinkValue = document.getElementById('status-drink-value');
const statusArmourItem = document.getElementById('status-armour-item');

const setBar = (fillEl, valueEl, value) => {
  const safeValue = Math.max(0, Math.min(100, Number(value) || 0));
  fillEl.style.width = `${safeValue}%`;
  valueEl.textContent = `${Math.round(safeValue)}%`;
};

window.addEventListener('message', (event) => {
  const { action, data } = event.data || {};

  if (action === 'theme' && data) {
    for (const [key, value] of Object.entries(data)) {
      const cssKey = '--' + key.replace(/[A-Z]/g, (m) => '-' + m.toLowerCase());
      document.documentElement.style.setProperty(cssKey, value);
    }
  }

  if (action === 'status:config' && data) {
    if (data.positionBottom !== undefined) {
      statusHud.style.bottom = `${data.positionBottom}vh`;
    }

    if (data.positionLeft !== undefined) {
      statusHud.style.left = `${data.positionLeft}vw`;
    }

    if (data.scale !== undefined) {
      statusHud.style.transform = `scale(${data.scale})`;
      statusHud.style.transformOrigin = 'left bottom';
    }
  }

  if (action === 'status:update') {
    const visible = data && data.visible !== false;
    statusHud.classList.toggle('hidden', !visible);

    if (!visible) return;

    setBar(statusHealthFill, statusHealthValue, data.health);
    setBar(statusArmourFill, statusArmourValue, data.armour);
    setBar(statusFoodFill, statusFoodValue, data.food);
    setBar(statusDrinkFill, statusDrinkValue, data.drink);

    statusArmourItem.classList.toggle('hidden', !data.showArmour);
  }

  if (action === 'notify') {
    const card = document.createElement('div');
    card.className = `notification ${data.type || 'info'}`;
    card.innerHTML = `<div class="title">${data.title || 'TC5'}</div><div class="message">${data.message || ''}</div>`;
    notifications.appendChild(card);

    setTimeout(() => {
      card.style.opacity = '0';
      card.style.transform = 'translateX(120%)';
      card.style.transition = 'all .2s ease';
      setTimeout(() => card.remove(), 220);
    }, data.duration || 3500);
  }

  if (action === 'loading:open') {
    loadingTitle.textContent = data.title || 'Loading';
    loadingMessage.textContent = data.message || 'Please wait...';
    loading.classList.remove('hidden');
  }

  if (action === 'loading:close') {
    loading.classList.add('hidden');
  }
});
