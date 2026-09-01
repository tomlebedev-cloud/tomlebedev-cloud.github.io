(function () {
  'use strict';

  var photos = (window.PHOTOS || []).slice();
  var main = document.getElementById('work');

  document.getElementById('metai').textContent = new Date().getFullYear();

  /* Sekcijų tvarka ir jų paaiškinimai. Galerijos vardas ateina iš
     aplanko pavadinimo photos/_originalai/<vardas>/ */
  var SELECTED = { id:"selected", antraste:"Selected",
      tekstas:"Twenty frames I would show first." };

  var SEKCIJOS = [
    { id:"travel",   vardas:"Travel",   antraste:"Travel",
      tekstas:"Roads, cities and coastlines — from the medinas of Marrakech to Death Valley." },
    { id:"wildlife", vardas:"Wildlife", antraste:"Wildlife",
      tekstas:"Tanzania: patience, distance, and light you cannot plan for." },
    { id:"people",   vardas:"People",   antraste:"People",
      tekstas:"Portraits and moments that happened by themselves." }
  ];

  var rodomi = [];   // visos nuotraukos ta pačia tvarka, kaip puslapyje
  var current = 0;

  if (!photos.length) {
    main.innerHTML = '<p class="empty">No photographs yet. Put them in ' +
      '<code>photos/_originalai/&lt;Gallery&gt;/</code> and run ' +
      '<code>tools/paruosti-nuotraukas.ps1</code>.</p>';
    return;
  }

  function forma(n) { return n === 1 ? "photograph" : "photographs"; }

  /* --- Sekcijų piešimas ---------------------------------------------- */
  function piesk(s, grupe) {
    if (!grupe.length) return;

    var sec = document.createElement('section');
    sec.className = 'sekcija';
    sec.id = s.id;

    var juosta = document.createElement('div');
    juosta.className = 'sekcija__juosta';
    juosta.innerHTML =
      '<h2>' + s.antraste + '</h2>' +
      '<p>' + s.tekstas + '</p>' +
      '<span class="sekcija__kiekis">' +
        (s.id === 'selected'
          ? grupe.length + ' of ' + photos.length + ' ' + forma(photos.length)
          : grupe.length + ' ' + forma(grupe.length)) +
      '</span>' +
      '<div class="lankas"></div>';
    sec.appendChild(juosta);

    var grid = document.createElement('div');
    grid.className = 'galerija';

    grupe.forEach(function (p) {
      var indeksas = rodomi.length;
      rodomi.push({ p: p, sekcija: s.antraste, nr: grupe.indexOf(p) + 1, viso: grupe.length });

      var fig = document.createElement('figure');
      fig.className = 'tile';
      fig.tabIndex = 0;

      var img = document.createElement('img');
      img.src = p.thumb;
      img.alt = p.pavadinimas || 'Photograph';
      img.loading = 'lazy';
      img.decoding = 'async';
      img.addEventListener('load', function () { img.classList.add('loaded'); });
      if (img.complete) img.classList.add('loaded');
      fig.appendChild(img);

      if (p.pavadinimas) {
        var cap = document.createElement('figcaption');
        cap.textContent = p.pavadinimas;
        fig.appendChild(cap);
      }

      fig.addEventListener('click', function () { open(indeksas); });
      fig.addEventListener('keydown', function (e) {
        if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); open(indeksas); }
      });

      grid.appendChild(fig);
    });

    sec.appendChild(grid);
    main.appendChild(sec);
  }

  // Atranka pirma: tos pačios nuotraukos, tik atrinktos ir savo tvarka.
  var atrinktos = photos
    .filter(function (p) { return p.atranka; })
    .sort(function (a, b) { return a.atrankaNr - b.atrankaNr; });
  piesk(SELECTED, atrinktos);

  // Po jos - pilnos temos.
  SEKCIJOS.forEach(function (s) {
    piesk(s, photos.filter(function (p) { return p.galerija === s.vardas; }));
  });

  /* --- Lightbox ------------------------------------------------------ */
  var lb = document.getElementById('lightbox');
  var lbImg = document.getElementById('lbImg');
  var lbCap = document.getElementById('lbCaption');
  var grazintiFokusa = null;

  function open(i) {
    current = i;
    grazintiFokusa = main.querySelectorAll('.tile')[i] || null;
    show();
    lb.hidden = false;
    document.body.style.overflow = 'hidden';
    document.getElementById('lbClose').focus();
  }

  function close() {
    lb.hidden = true;
    lbImg.removeAttribute('src');
    document.body.style.overflow = '';
    if (grazintiFokusa) grazintiFokusa.focus();
  }

  function show() {
    var irasas = rodomi[current];
    var p = irasas.p;
    lbImg.src = p.full;
    lbImg.alt = p.pavadinimas || 'Nuotrauka';
    lbCap.innerHTML = '';
    lbCap.appendChild(document.createTextNode(p.pavadinimas || ''));
    var meta = document.createElement('span');
    meta.textContent = irasas.sekcija + '  ·  ' + irasas.nr + ' / ' + irasas.viso;
    lbCap.appendChild(meta);

    [current - 1, current + 1].forEach(function (n) {
      if (rodomi[n]) { var pre = new Image(); pre.src = rodomi[n].p.full; }
    });
  }

  function step(d) { current = (current + d + rodomi.length) % rodomi.length; show(); }

  document.getElementById('lbClose').addEventListener('click', close);
  document.getElementById('lbPrev').addEventListener('click', function () { step(-1); });
  document.getElementById('lbNext').addEventListener('click', function () { step(1); });
  lb.addEventListener('click', function (e) { if (e.target === lb) close(); });

  document.addEventListener('keydown', function (e) {
    if (lb.hidden) return;
    if (e.key === 'Escape') { close(); return; }
    if (e.key === 'ArrowLeft')  { step(-1); return; }
    if (e.key === 'ArrowRight') { step(1);  return; }
    if (e.key === 'Tab') {
      var m = lb.querySelectorAll('button');
      if (!m.length) return;
      var pirmas = m[0], paskutinis = m[m.length - 1];
      if (e.shiftKey && document.activeElement === pirmas) { e.preventDefault(); paskutinis.focus(); }
      else if (!e.shiftKey && document.activeElement === paskutinis) { e.preventDefault(); pirmas.focus(); }
    }
  });

  /* --- Braukimas telefone -------------------------------------------- */
  var x0 = null;
  lb.addEventListener('touchstart', function (e) { x0 = e.changedTouches[0].clientX; }, { passive: true });
  lb.addEventListener('touchend', function (e) {
    if (x0 === null) return;
    var dx = e.changedTouches[0].clientX - x0;
    if (Math.abs(dx) > 50) step(dx < 0 ? 1 : -1);
    x0 = null;
  }, { passive: true });
})();
