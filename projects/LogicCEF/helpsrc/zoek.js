// Zoeken in de help van Logic. De zoekindex (ZOEKINDEX) staat per taal in
// zoekindex.js en wordt door make-help.ps1 gemaakt: per pagina en per kop een
// adres (u), een titel (t) en de tekst (x). Werkt zonder server (file://).
(function () {
  var vak = document.getElementById('zoekvak');
  var uit = document.getElementById('zoekuit');
  if (!vak || !uit || typeof ZOEKINDEX === 'undefined') return;

  // kleine letters, zonder accenten (é -> e, ü -> u)
  function plat(s) {
    s = s.toLowerCase();
    return s.normalize ? s.normalize('NFD').replace(/[̀-ͯ]/g, '') : s;
  }
  function esc(s) {
    return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }
  var lijst = ZOEKINDEX.map(function (e) {
    return { u: e.u, t: e.t, x: e.x, pt: plat(e.t), px: plat(e.x) };
  });

  // een stukje tekst rond het eerste gevonden woord, met dat woord gemarkeerd
  function stukje(e, w) {
    var i = e.px.indexOf(w);
    if (i < 0) return esc(e.x.slice(0, 110)) + (e.x.length > 110 ? '…' : '');
    var b = Math.max(0, i - 40), s = e.x.slice(b, i + w.length + 70), j = i - b;
    return (b > 0 ? '…' : '') + esc(s.slice(0, j)) + '<mark>' + esc(s.slice(j, j + w.length)) + '</mark>' +
      esc(s.slice(j + w.length)) + (i + w.length + 70 < e.x.length ? '…' : '');
  }

  function zoek() {
    var q = plat(vak.value.replace(/^\s+|\s+$/g, ''));
    uit.innerHTML = '';
    if (q.length < 2) { uit.style.display = 'none'; return; }
    var woorden = q.split(/\s+/), res = [];
    lijst.forEach(function (e) {
      var score = 0;
      for (var k = 0; k < woorden.length; k++) {
        var w = woorden[k], inT = e.pt.indexOf(w) >= 0, n = e.px.split(w).length - 1;
        if (!inT && n === 0) return;           // elk woord moet ergens staan
        score += (inT ? 20 : 0) + Math.min(n, 5);
      }
      res.push({ e: e, s: score });
    });
    res.sort(function (a, b) { return b.s - a.s; });
    uit.style.display = 'block';
    if (!res.length) {
      uit.innerHTML = '<div class="geen">' + esc(uit.getAttribute('data-geen') || '') + '</div>';
      return;
    }
    res.slice(0, 25).forEach(function (r) {
      var a = document.createElement('a');
      a.href = r.e.u;
      a.innerHTML = '<b>' + esc(r.e.t) + '</b><span>' + stukje(r.e, woorden[0]) + '</span>';
      uit.appendChild(a);
    });
  }

  vak.addEventListener('input', function () {
    zoek();
    try { sessionStorage.setItem('logic-zoek', vak.value); } catch (e) { }
  });
  vak.addEventListener('keydown', function (ev) {
    if (ev.key === 'Enter') {
      var a = uit.querySelector('a');
      if (a) location.href = a.href;
    } else if (ev.key === 'Escape') {
      vak.value = '';
      try { sessionStorage.removeItem('logic-zoek'); } catch (e) { }
      zoek();
    }
  });
  // de zoekterm blijft staan als je naar een gevonden pagina gaat
  try {
    var oud = sessionStorage.getItem('logic-zoek');
    if (oud) { vak.value = oud; zoek(); }
  } catch (e) { }
})();
