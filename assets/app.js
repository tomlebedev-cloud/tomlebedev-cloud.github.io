(function () {
  'use strict';

  var photos = (window.PHOTOS || []).slice();
  var main = document.getElementById('darbai');

  document.getElementById('metai').textContent = new Date().getFullYear();

  /* Sekcijų tvarka ir jų paaiškinimai. Galerijos vardas ateina iš
     aplanko pavadinimo photos/_originalai/<vardas>/ */
  var SEKCIJOS = [
    { id:'keliones', vardas:'Kelionės',      antraste:'Kelionės',
      tekstas:'Keliai, miestai ir pakrantės — nuo Maroko medinų iki Mirties slėnio.' },
    { id:'gamta',    vardas:'Laukinė gamta', antraste:'Laukinė gamta',
      tekstas:'Tanzanija: kantrybė, atstumas ir šviesa, kurios negali suplanuoti.' },
    { id:'zmones',   vardas:'Žmonės',        antraste:'Žmonės',
      tekstas:'Portretai ir akimirkos, kurios įvyko pačios.' }
  ];

  var rodomi = [];   // visos nuotraukos ta pačia tvarka, kaip puslapyje
  var current = 0;

  if (!photos.length) {
    main.innerHTML = '<p class="empty">Nuotraukų dar nėra. Sudėk jas į ' +
      '<code>photos/_originalai/&lt;Galerija&gt;/</code> ir paleisk ' +
      '<code>tools/paruosti-nuotraukas.ps1</code>.</p>';
    return;
  }

  /* --- Sekcijų piešimas ---------------------------------------------- */
  SEKCIJOS.forEach(function (s) {
    var grupe = photos.filter(function (p) { return p.galerija === s.vardas; });
    if (!grupe.length) return;

    var sec = document.createElement('section');
    sec.className = 'sekcija';
    sec.id = s.id;

    var juosta = document.createElement('div');
    juosta.className = 'sekcija__juosta';
    juosta.innerHTML =
      '<h2>' + s.antraste + '</h2>' +
      '<p>' + s.tekstas + '</p>' +
      '<span class="sekcija__kiekis">' + grupe.length + ' nuotraukos</span>' +
      '<div class="lankas"></div>';
    sec.appendChild(juosta);

    var grid = document.createElement('div');
    grid.className = 'galerija';

    grupe.forEach(function (p) {
      var indeksas = rodomi.length;
      rodomi.push(p);

      var fig = document.createElement('figure');
      fig.className = 'tile';
      fig.tabIndex = 0;

      var img = document.createElement('img');
      img.src = p.thumb;
      img.alt = p.pavadinimas || 'Nuotrauka';
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
    var p = rodomi[current];
    lbImg.src = p.full;
    lbImg.alt = p.pavadinimas || 'Nuotrauka';
    lbCap.innerHTML = '';
    lbCap.appendChild(document.createTextNode(p.pavadinimas || ''));
    var meta = document.createElement('span');
    meta.textContent = (p.galerija ? p.galerija + '  ·  ' : '') +
                       (current + 1) + ' / ' + rodomi.length;
    lbCap.appendChild(meta);

    [current - 1, current + 1].forEach(function (n) {
      if (rodomi[n]) { var pre = new Image(); pre.src = rodomi[n].full; }
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
