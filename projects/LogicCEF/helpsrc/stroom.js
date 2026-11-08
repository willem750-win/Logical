/* Logic help: elektronen stromen door een kring met een bron en een lamp van 120 ohm.
   Een schuifregelaar zet de spanning (0 - 12 V). Bij 0 V staan de elektronen stil;
   hoe hoger de spanning, hoe sneller ze schuiven en hoe feller de lamp brandt.
   Een vergrootglas toont een stukje koperdraad: atomen blijven staan, elektronen schuiven.
   Gebruik: <div class="stroomdemo" data-dec="," data-label="..." data-stil="..."></div> */
(function () {
  var NS = 'http://www.w3.org/2000/svg';
  var R = 120, nr = 0;

  function el(name, attrs, parent) {
    var e = document.createElementNS(NS, name);
    for (var k in attrs) e.setAttribute(k, attrs[k]);
    if (parent) parent.appendChild(e);
    return e;
  }

  function init(box) {
    nr++;
    var dec = box.getAttribute('data-dec') || ',';
    var svg = el('svg', { viewBox: '0 0 480 260', role: 'img' });
    box.appendChild(svg);

    var defs = el('defs', {}, svg);
    var cp = el('clipPath', { id: "zoomclip" + nr }, defs);
    el('circle', { cx: 230, cy: 122, r: 58 }, cp);
    var rg = el('radialGradient', { id: "gloed" + nr }, defs);
    el('stop', { offset: '0', 'stop-color': '#fff7a8' }, rg);
    el('stop', { offset: '0.55', 'stop-color': '#ffd400', 'stop-opacity': '0.8' }, rg);
    el('stop', { offset: '1', 'stop-color': '#ffd400', 'stop-opacity': '0' }, rg);

    el('rect', { width: 480, height: 260, fill: '#ffffff' }, svg);

    // de kring: elektronen gaan uit de - pool (onder), rond, en terug in de + pool (boven)
    var d = 'M60 148 L60 220 L400 220 L400 40 L60 40 L60 112';
    var baan = el('path', { d: d, fill: 'none', stroke: '#b87333', 'stroke-width': 8, 'stroke-linejoin': 'round' }, svg);
    var L = baan.getTotalLength();

    var dots = [], N = 44;
    var eg = el('g', {}, svg);
    for (var i = 0; i < N; i++) dots.push(el('circle', { r: 3, fill: '#1f5fbf' }, eg));

    // bron
    el('rect', { x: 34, y: 108, width: 52, height: 44, fill: '#ffffff' }, svg);
    el('line', { x1: 36, y1: 116, x2: 84, y2: 116, stroke: '#1f2328', 'stroke-width': 3 }, svg);
    el('line', { x1: 48, y1: 144, x2: 72, y2: 144, stroke: '#1f2328', 'stroke-width': 7 }, svg);
    var t = el('text', { x: 94, y: 112, 'font-size': 20, 'font-weight': 'bold', fill: '#c0392b' }, svg); t.textContent = '+';
    t = el('text', { x: 94, y: 156, 'font-size': 22, 'font-weight': 'bold', fill: '#1f2328' }, svg); t.textContent = '−';
    var uText = el('text', { x: 40, y: 250, 'font-size': 15, 'font-weight': 'bold', fill: '#1f2328' }, svg);

    // lamp
    var glow = el('circle', { cx: 400, cy: 130, r: 40, fill: 'url(#gloed' + nr + ')', opacity: 0 }, svg);
    var bol = el('circle', { cx: 400, cy: 130, r: 20, fill: '#ffffff', stroke: '#1f2328', 'stroke-width': 3 }, svg);
    el('line', { x1: 386, y1: 116, x2: 414, y2: 144, stroke: '#1f2328', 'stroke-width': 3 }, svg);
    el('line', { x1: 414, y1: 116, x2: 386, y2: 144, stroke: '#1f2328', 'stroke-width': 3 }, svg);
    t = el('text', { x: 428, y: 135, 'font-size': 14, fill: '#1f2328' }, svg); t.textContent = '120 Ω';

    // vergrootglas op de onderste draad
    el('line', { x1: 216, y1: 210, x2: 184, y2: 172, stroke: '#5b636e', 'stroke-width': 1.5 }, svg);
    el('line', { x1: 244, y1: 210, x2: 276, y2: 172, stroke: '#5b636e', 'stroke-width': 1.5 }, svg);
    el('circle', { cx: 230, cy: 220, r: 16, fill: 'rgba(31,95,191,0.08)', stroke: '#5b636e', 'stroke-width': 2 }, svg);
    var zg = el('g', { 'clip-path': 'url(#zoomclip' + nr + ')' }, svg);
    el('rect', { x: 160, y: 60, width: 140, height: 130, fill: '#f6f7f9' }, zg);
    el('rect', { x: 160, y: 94, width: 140, height: 56, fill: '#f3dcc4' }, zg);
    var atoms = [];
    for (var r = 0; r < 2; r++)
      for (var c = 0; c < 7; c++) {
        var ax = 172 + c * 20 + (r ? 10 : 0), ay = 110 + r * 24;
        atoms.push({ x: ax, y: ay, e: el('circle', { cx: ax, cy: ay, r: 7, fill: '#9aa1aa' }, zg) });
        t = el('text', { x: ax, y: ay + 4, 'font-size': 11, 'text-anchor': 'middle', fill: '#ffffff' }, zg); t.textContent = '+';
      }
    var ze = [];
    for (i = 0; i < 12; i++) {
      var g = el('g', {}, zg);
      el('circle', { r: 4.5, fill: '#1f5fbf' }, g);
      t = el('text', { y: 3.5, 'font-size': 9, 'text-anchor': 'middle', fill: '#ffffff' }, g); t.textContent = '−';
      ze.push({ x: 160 + i * 12.5, y: (i % 3 === 0) ? 100 : (i % 3 === 1 ? 122 : 144), g: g });
    }
    el('circle', { cx: 230, cy: 122, r: 58, fill: 'none', stroke: '#5b636e', 'stroke-width': 3 }, svg);
    t = el('text', { x: 230, y: 250, 'font-size': 13, 'text-anchor': 'middle', fill: '#1f5fbf' }, svg);
    t.textContent = 'e− →';

    // regelaar en uitlezing
    var lab = document.createElement('label');
    lab.textContent = (box.getAttribute('data-label') || 'U') + ' ';
    var inp = document.createElement('input');
    inp.type = 'range'; inp.min = '0'; inp.max = '12'; inp.step = '0.5'; inp.value = '6';
    lab.appendChild(inp);
    box.appendChild(lab);
    var out = document.createElement('div');
    out.className = 'uitlezing';
    box.appendChild(out);

    function f(v, n) { return v.toFixed(n).replace('.', dec); }
    var U = 6;
    function update() {
      U = parseFloat(inp.value);
      var I = U / R, P = U * I;
      uText.textContent = 'U = ' + f(U, 1) + ' V';
      var k = P / 1.2;
      glow.setAttribute('opacity', k.toFixed(3));
      bol.setAttribute('fill', k > 0 ? 'rgb(255,' + Math.round(255 - 43 * k) + ',' + Math.round(255 - 255 * k) + ')' : '#ffffff');
      out.style.fontFamily = U === 0 ? 'inherit' : '';
      if (U === 0) out.innerHTML = box.getAttribute('data-stil') || '';
      else out.innerHTML = 'I = U / R = ' + f(U, 1) + ' V / 120 Ω = ' + f(I, 3) + ' A = ' + f(I * 1000, 0) + ' mA<br>' +
        'P = U × I = ' + f(U, 1) + ' V × ' + f(I, 3) + ' A = ' + f(P, 2) + ' W';
    }
    inp.addEventListener('input', update);

    var pos = 0, last = null;
    function draw() {
      for (var i = 0; i < N; i++) {
        var p = baan.getPointAtLength((pos + i * L / N) % L);
        dots[i].setAttribute('cx', p.x.toFixed(1));
        dots[i].setAttribute('cy', p.y.toFixed(1));
      }
      for (i = 0; i < ze.length; i++)
        ze[i].g.setAttribute('transform', 'translate(' + ze[i].x.toFixed(1) + ',' + ze[i].y + ')');
      // atomen trillen een beetje meer naarmate de draad warmer wordt
      var a = U / 12 * 1.2;
      for (i = 0; i < atoms.length; i++) {
        atoms[i].e.setAttribute('cx', (atoms[i].x + (Math.random() - 0.5) * a).toFixed(1));
      }
    }
    function frame(ts) {
      var dt = last === null ? 0 : Math.min((ts - last) / 1000, 0.1);
      last = ts;
      var v = U * 7;                     // px per seconde in de kring
      pos = (pos + v * dt) % L;
      for (var i = 0; i < ze.length; i++) {
        ze[i].x += v * 0.6 * dt;         // in het vergrootglas: zelfde zin, naar rechts
        if (ze[i].x > 300) ze[i].x -= 150;
      }
      draw();
      requestAnimationFrame(frame);
    }
    update();
    draw();
    requestAnimationFrame(frame);
  }

  var boxes = document.querySelectorAll('.stroomdemo');
  for (var i = 0; i < boxes.length; i++) init(boxes[i]);
})();
