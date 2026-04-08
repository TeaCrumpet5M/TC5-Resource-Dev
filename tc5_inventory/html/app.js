const app = document.getElementById('app');
const closeButton = document.getElementById('closeButton');
const playerSlots = document.getElementById('playerSlots');
const secondarySlots = document.getElementById('secondarySlots');
const playerLabel = document.getElementById('playerLabel');
const playerWeight = document.getElementById('playerWeight');
const secondaryLabel = document.getElementById('secondaryLabel');
const secondaryWeight = document.getElementById('secondaryWeight');
const playerSearch = document.getElementById('playerSearch');
const secondarySearch = document.getElementById('secondarySearch');
const splitModal = document.getElementById('splitModal');
const splitAmount = document.getElementById('splitAmount');
const splitConfirm = document.getElementById('splitConfirm');
const splitCancel = document.getElementById('splitCancel');
const secondaryPanel = document.getElementById('secondaryPanel');
const inventoryGrid = document.getElementById('inventoryGrid');

let state = {
    player: null,
    secondary: null
};

let dragData = null;
let splitContext = null;

const post = async (endpoint, payload = {}) => {
    await fetch(`https://${GetParentResourceName()}/${endpoint}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(payload)
    });
};

const formatWeight = (value) => `${Number(value || 0).toLocaleString()}g`;

const matchesSearch = (item, query) => {
    if (!query) return true;

    const term = query.toLowerCase();

    return (item.label || '').toLowerCase().includes(term)
        || (item.name || '').toLowerCase().includes(term)
        || (item.description || '').toLowerCase().includes(term);
};

const showSplitModal = (context, maxAmount) => {
    if (!splitModal || !splitAmount) return;

    splitContext = context;
    splitAmount.value = 1;
    splitAmount.max = Math.max(1, maxAmount - 1);
    splitModal.classList.remove('hidden');
};

const hideSplitModal = () => {
    splitContext = null;
    if (splitModal) {
        splitModal.classList.add('hidden');
    }
};

if (splitConfirm) {
    splitConfirm.addEventListener('click', async () => {
        if (!splitContext) return;

        const amount = Math.max(1, parseInt(splitAmount.value || '1', 10));

        await post('moveItem', {
            fromType: splitContext.fromType,
            fromOwner: splitContext.fromOwner,
            fromSlot: splitContext.fromSlot,
            toType: splitContext.toType,
            toOwner: splitContext.toOwner,
            toSlot: splitContext.toSlot,
            amount
        });

        hideSplitModal();
    });
}

if (splitCancel) {
    splitCancel.addEventListener('click', hideSplitModal);
}

const createSlot = (inventoryType, inventoryOwner, slotNumber, item, searchTerm) => {
    const slot = document.createElement('div');
    slot.className = 'slot';

    const number = document.createElement('div');
    number.className = 'slot-number';
    number.textContent = `#${slotNumber}`;
    slot.appendChild(number);

    if (!item || !matchesSearch(item, searchTerm)) {
        slot.classList.add('empty');
        return slot;
    }

    slot.draggable = inventoryType !== 'shop';

    const icon = document.createElement('img');
    icon.className = 'item-icon';
    icon.src = item.image ? `images/${item.image}` : 'images/default.png';
    icon.onerror = () => {
        icon.src = 'images/default.png';
    };

    const name = document.createElement('div');
    name.className = 'item-name';
    name.textContent = (item.metadata && item.metadata.label)
        ? item.metadata.label
        : (item.label || item.name);

    const desc = document.createElement('div');
    desc.className = 'item-desc';
    desc.textContent = item.description || 'No description';

    const metaLine = document.createElement('div');
    metaLine.className = 'item-meta';

    if (item.metadata?.durability !== undefined) {
        metaLine.textContent = `Durability: ${item.metadata.durability}%`;
    } else if (item.metadata?.serial) {
        metaLine.textContent = `Serial: ${item.metadata.serial}`;
    } else {
        metaLine.textContent = '';
    }

    const footer = document.createElement('div');
    footer.className = 'item-footer';

    const amount = document.createElement('div');
    amount.className = 'item-amount';
    amount.textContent = `x${item.amount}`;

    const weight = document.createElement('div');
    weight.className = 'item-weight';
    weight.textContent = formatWeight((item.weight || 0) * (item.amount || 0));

    footer.appendChild(amount);
    footer.appendChild(weight);

    slot.appendChild(icon);
    slot.appendChild(name);
    slot.appendChild(desc);

    if (inventoryType === 'shop' && item.metadata?.price !== undefined) {
        const price = document.createElement('div');
        price.className = 'item-price';
        price.textContent = `$${item.metadata.price}`;
        slot.appendChild(price);
    } else {
        slot.appendChild(metaLine);
    }

    slot.appendChild(footer);

    slot.addEventListener('click', async () => {
        if (inventoryType === 'player') {
            await post('useItem', { slot: slotNumber });
            return;
        }

        if (inventoryType === 'shop') {
            await post('buyShopItem', {
                shopId: inventoryOwner,
                slot: slotNumber,
                amount: 1
            });
        }
    });

    slot.addEventListener('contextmenu', async (e) => {
        e.preventDefault();

        if (inventoryType !== 'player') return;

        await post('dropItem', {
            slot: slotNumber,
            amount: 1
        });
    });

    slot.addEventListener('dragstart', () => {
        if (inventoryType === 'shop') return;

        dragData = {
            fromType: inventoryType,
            fromOwner: inventoryOwner,
            fromSlot: slotNumber,
            item
        };
    });

    slot.addEventListener('dragover', (e) => {
        if (inventoryType === 'shop') return;
        e.preventDefault();
        slot.classList.add('drag-over');
    });

    slot.addEventListener('dragleave', () => {
        slot.classList.remove('drag-over');
    });

    slot.addEventListener('drop', async (e) => {
        if (inventoryType === 'shop') return;

        e.preventDefault();
        slot.classList.remove('drag-over');

        if (!dragData) return;

        if (dragData.item.amount > 1 && e.shiftKey) {
            showSplitModal({
                fromType: dragData.fromType,
                fromOwner: dragData.fromOwner,
                fromSlot: dragData.fromSlot,
                toType: inventoryType,
                toOwner: inventoryOwner,
                toSlot: slotNumber
            }, dragData.item.amount);

            dragData = null;
            return;
        }

        await post('moveItem', {
            fromType: dragData.fromType,
            fromOwner: dragData.fromOwner,
            fromSlot: dragData.fromSlot,
            toType: inventoryType,
            toOwner: inventoryOwner,
            toSlot: slotNumber,
            amount: 1
        });

        dragData = null;
    });

    return slot;
};

const renderInventory = (container, inventory, searchTerm) => {
    container.innerHTML = '';

    if (!inventory) {
        for (let i = 1; i <= 25; i++) {
            container.appendChild(createSlot('none', 'none', i, null, searchTerm));
        }
        return;
    }

    for (let slot = 1; slot <= inventory.maxSlots; slot++) {
        const item = inventory.items?.[slot] || null;
        container.appendChild(createSlot(inventory.type, inventory.owner, slot, item, searchTerm));
    }
};

const updateLayout = () => {
    if (state.secondary) {
        secondaryPanel.classList.remove('hidden');
        inventoryGrid.classList.remove('single');
        inventoryGrid.classList.add('double');
    } else {
        secondaryPanel.classList.add('hidden');
        inventoryGrid.classList.remove('double');
        inventoryGrid.classList.add('single');
    }
};

const render = () => {
    updateLayout();

    playerLabel.textContent = state.player?.label || 'Inventory';
    playerWeight.textContent = `${formatWeight(state.player?.currentWeight || 0)} / ${formatWeight(state.player?.maxWeight || 0)}`;

    secondaryLabel.textContent = state.secondary?.label || 'Secondary';
    secondaryWeight.textContent = `${formatWeight(state.secondary?.currentWeight || 0)} / ${formatWeight(state.secondary?.maxWeight || 0)}`;

    renderInventory(playerSlots, state.player, playerSearch.value);

    if (state.secondary) {
        renderInventory(secondarySlots, state.secondary, secondarySearch.value);
    } else {
        secondarySlots.innerHTML = '';
    }
};

window.addEventListener('message', (event) => {
    const { action, data } = event.data || {};

    if (action === 'open') {
        state.player = data?.player || null;
        state.secondary = data?.secondary || null;
        app.classList.remove('hidden');
        render();
    }

    if (action === 'close') {
        app.classList.add('hidden');
        dragData = null;
        hideSplitModal();
    }

    if (action === 'refreshPlayer') {
        state.player = data?.player || null;
        render();
    }

    if (action === 'refreshOpenInventories') {
        state.player = data?.player || null;
        state.secondary = data?.secondary || null;
        render();
    }
});

if (closeButton) {
    closeButton.addEventListener('click', async () => {
        await post('close');
    });
}

if (playerSearch) {
    playerSearch.addEventListener('input', render);
}

if (secondarySearch) {
    secondarySearch.addEventListener('input', render);
}