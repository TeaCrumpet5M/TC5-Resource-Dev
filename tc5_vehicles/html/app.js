window.addEventListener('message', function (e) {
    const msg = e.data || {};
    const hud = document.getElementById('hud');
    if (!hud) return;

    if (msg.action === 'hide' || msg.action === 'hideHud') {
        hud.style.display = 'none';
        return;
    }

    const raw = msg.data || msg;

    if (msg.action !== 'update' && msg.action !== 'updateHud' && msg.action !== 'showHud') {
        return;
    }

    hud.style.display = 'block';

    const speed = Number(raw.speed ?? 0);
    const rpm = Number(raw.rpm ?? 0);
    const fuel = Number(raw.fuel ?? 0);
    const seatbelt = Boolean(raw.seatbelt);
    const engineOn = raw.engineOn === undefined ? true : Boolean(raw.engineOn);
    const gear = Number(raw.gear ?? 0);
    const lights = Number(raw.lights ?? 0);

    const speedNeedle = document.getElementById('speedNeedle');
    const rpmNeedle = document.getElementById('rpmNeedle');
    const fuelNeedle = document.getElementById('fuelNeedle');

    const speedEl = document.getElementById('speedReadout');
    const rpmEl = document.getElementById('rpmValue');
    const fuelEl = document.getElementById('fuelValue');

    const beltStatus = document.getElementById('beltStatus');
    const engineStatus = document.getElementById('engineStatus');
    const gearStatus = document.getElementById('gearStatus');
    const lightsStatus = document.getElementById('lightsStatus');

    const clampedSpeed = Math.max(0, Math.min(speed, 180));
    const clampedRpm = Math.max(0, Math.min(rpm, 1));
    const clampedFuel = Math.max(0, Math.min(fuel, 100));

    const speedAngle = -130 + (clampedSpeed / 180) * 260;
    const rpmAngle = -130 + clampedRpm * 260;
    const fuelAngle = -130 + (clampedFuel / 100) * 260;

    if (speedNeedle) speedNeedle.style.transform = `translateX(-50%) rotate(${speedAngle}deg)`;
    if (rpmNeedle) rpmNeedle.style.transform = `translateX(-50%) rotate(${rpmAngle}deg)`;
    if (fuelNeedle) fuelNeedle.style.transform = `translateX(-50%) rotate(${fuelAngle}deg)`;

    if (speedEl) {
        speedEl.textContent = Math.floor(clampedSpeed);
        speedEl.className = 'speed-readout';
        if (clampedSpeed < 40) speedEl.classList.add('speed-green');
        else if (clampedSpeed < 80) speedEl.classList.add('speed-yellow');
        else if (clampedSpeed < 120) speedEl.classList.add('speed-orange');
        else speedEl.classList.add('speed-red');
    }

    if (rpmEl) rpmEl.textContent = Math.floor(clampedRpm * 100);
    if (fuelEl) fuelEl.textContent = `${Math.floor(clampedFuel)}%`;

    if (beltStatus) {
        beltStatus.textContent = seatbelt ? 'BELT ON' : 'BELT OFF';
        beltStatus.style.color = seatbelt ? '#00ff88' : '#ff5a5a';
    }

    if (engineStatus) {
        engineStatus.textContent = engineOn ? 'ENGINE ON' : 'ENGINE OFF';
        engineStatus.style.color = engineOn ? '#00ff88' : '#ff5a5a';
    }

    if (gearStatus) {
        let gearText = 'N';
        if (gear > 0) gearText = String(gear);
        gearStatus.textContent = `GEAR ${gearText}`;
        gearStatus.style.color = '#ffffff';
    }

    if (lightsStatus) {
        lightsStatus.textContent = lights > 0 ? 'LIGHTS ON' : 'LIGHTS OFF';
        lightsStatus.style.color = lights > 0 ? '#ffee00' : '#ffffff';
    }
});
