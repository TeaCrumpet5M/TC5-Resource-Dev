window.addEventListener('message', function(e){
    const d = e.data;

    if(d.action === 'update'){
        document.getElementById('speed').innerText = d.speed;
        document.getElementById('belt').innerText = 'Belt: ' + (d.seatbelt ? 'ON' : 'OFF');
    }

    if(d.action === 'hide'){
        document.getElementById('hud').style.display = 'none';
    } else {
        document.getElementById('hud').style.display = 'block';
    }
});