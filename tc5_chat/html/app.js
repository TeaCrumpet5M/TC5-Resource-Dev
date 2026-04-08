const messageStack = document.getElementById('message-stack');
const inputShell = document.getElementById('input-shell');
const input = document.getElementById('chat-input');
const suggestionBox = document.getElementById('suggestion-box');
const suggestionName = document.getElementById('suggestion-name');
const suggestionHelp = document.getElementById('suggestion-help');

const state = {
    suggestions: {}
};

const resourceName = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'tc5_chat';

function post(endpoint, payload = {}) {
    fetch(`https://${resourceName}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(payload)
    }).catch(() => {});
}

function getSuggestionMatches(text) {
    if (!text || !text.startsWith('/')) return [];

    const raw = text.trim();
    const commandToken = raw.split(' ')[0].toLowerCase();
    const all = Object.values(state.suggestions || {});

    if (!commandToken) return [];

    const startsWithMatches = all.filter((entry) =>
        (entry.name || '').toLowerCase().startsWith(commandToken)
    );

    if (startsWithMatches.length > 0) {
        return startsWithMatches.sort((a, b) => (a.name || '').localeCompare(b.name || ''));
    }

    const containsMatches = all.filter((entry) =>
        (entry.name || '').toLowerCase().includes(commandToken)
    );

    return containsMatches.sort((a, b) => (a.name || '').localeCompare(b.name || ''));
}

function renderSuggestion(text) {
    const matches = getSuggestionMatches(text);
    if (matches.length === 0) {
        suggestionBox.classList.add('hidden');
        return;
    }

    const top = matches[0];
    suggestionName.textContent = top.name || '';

    const extraNames = matches.slice(1, 5).map((entry) => entry.name).filter(Boolean);
    const extraText = extraNames.length > 0 ? ` · Also: ${extraNames.join(', ')}` : '';
    suggestionHelp.textContent = `${top.help || 'Command available'}${extraText}`;
    suggestionBox.classList.remove('hidden');
}

function addMessage({ author, text, color }) {
    const item = document.createElement('div');
    item.className = 'message';

    if (Array.isArray(color) && color.length >= 3) {
        item.style.setProperty('--primary', `rgb(${color[0]}, ${color[1]}, ${color[2]})`);
        item.style.setProperty('--primary-soft', `rgba(${color[0]}, ${color[1]}, ${color[2]}, 0.18)`);
    }

    const meta = document.createElement('div');
    meta.className = 'meta';
    meta.innerHTML = author ? `<span class="author">${escapeHtml(author)}</span><span>message</span>` : '<span>system</span>';

    const body = document.createElement('div');
    body.className = 'body';
    body.textContent = text || '';

    item.appendChild(meta);
    item.appendChild(body);
    messageStack.appendChild(item);

    while (messageStack.children.length > 10) {
        messageStack.removeChild(messageStack.firstChild);
    }

    scheduleFade(item);
}

function scheduleFade(element) {
    clearTimeout(element._fadeTimer);
    clearTimeout(element._removeTimer);

    element._fadeTimer = setTimeout(() => {
        if (!inputShell.classList.contains('hidden')) return;
        element.classList.add('fade');
    }, 12000);

    element._removeTimer = setTimeout(() => {
        if (element.parentNode) element.parentNode.removeChild(element);
    }, 12600);
}

function clearMessages() {
    messageStack.innerHTML = '';
}

function escapeHtml(value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
}

window.addEventListener('message', (event) => {
    const { action, data } = event.data || {};

    switch (action) {
        case 'bootstrap':
            return;
        case 'toggleInput':
            if (data?.state) {
                inputShell.classList.remove('hidden');
                input.value = '';
                renderSuggestion('');
                setTimeout(() => input.focus(), 50);
            } else {
                inputShell.classList.add('hidden');
                suggestionBox.classList.add('hidden');
            }
            break;
        case 'addMessage':
            addMessage(data || {});
            break;
        case 'clearMessages':
            clearMessages();
            break;
        case 'setSuggestions':
            state.suggestions = data?.suggestions || {};
            renderSuggestion(input.value);
            break;
    }
});

input.addEventListener('input', () => {
    renderSuggestion(input.value);
});

input.addEventListener('keydown', (event) => {
    if (event.key === 'Enter') {
        event.preventDefault();
        post('submit', { text: input.value || '' });
        return;
    }

    if (event.key === 'Escape') {
        event.preventDefault();
        post('close');
    }
});

document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && !inputShell.classList.contains('hidden')) {
        event.preventDefault();
        post('close');
    }
});
