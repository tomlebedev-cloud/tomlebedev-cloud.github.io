(function () {
  'use strict';

  var photos = (window.PHOTOS || []).slice();
  var grid = document.getElementById('grid');
  var filters = document.getElementById('filters');
  var empty = document.getElementById('empty');
  var view = [];          // kas šiuo metu rodoma (po filtro)
  var current = 0;

  document.getElementById('metai').textContent = new Date().getFullYear();

  if (!photos.length) {
    empty.hidden = false;
    return;
  }

  /* --- Filtrai pagal galerijas ---------------------------------------- */
  var groups = [];
  photos.forEach(function (p) {
    if (p.galerija && groups.indexOf(p.galerija) === -1) groups.push(p.galerija);
  });

  if (groups.length > 1) {
    makeButton('Visos', null, true);
    groups.forEach(function (g) { makeButton(g, g, false); });
  }

  function makeButton(label, value, active) {
    var b = document.createElement('button');
    b.textContent = label;
    b.setAttribute('aria-pressed', active ? 'true' : 'false');
    b.addEventListener('click', function () {
      Array.prototype.forEach.call(filters.children, function (c) {
        c.setAttribute('aria-pressed', 'false');
      });
      b.setAttribute('aria-pressed', 'true');
      render(value);
    });
    filters.appendChild(b);
  }

  /* --- Galerijos piešimas --------------------------------------------- */
  function render(group) {
    view = group ? photos.filter(function (p) { return p.galerija === group; }) : photos;
    grid.textContent = '';

    view.forEach(function (p, i) {
      var fig = document.createElement('figure');
      fig.className = 'tile';
      fig.tabIndex = 0;

      var img = document.createElement('img');
      img.src = p.thumb;
      img.alt = p.pavadinimas || '';
      img.loading = 'lazy';
      img.decoding = 'async';
      if (p.w && p.h) { img.width = p.w; img.height = p.h; }
      img.addEventListener('load', function () { img.classList.add('loaded'); });
      if (img.complete) img.classList.add('loaded');

      fig.appendChild(img);

      if (p.pavadinimas) {
        var cap = document.createElement('figcaption');
        cap.textContent = p.pavadinimas;
        fig.appendChild(cap);
      }

      fig.addEventListener('click', function () { open(i); });
      fig.addEventListener('keydown', function (e) {
        if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); open(i); }
      });

      grid.appendChild(fig);
    });
  }

  /* --- Lightbox -------------------------------------------------------- */
  var lb = document.getElementById('lightbox');
  var lbImg = document.getElementById('lbImg');
  var lbCap = document.getElementById('lbCaption');
  var grazintiFokusa = null;   // i kuria plytele grizti uzdarius

  function open(i) {
    current = i;
    grazintiFokusa = grid.children[i] || null;
    show();
    lb.hidden = false;
    document.body.style.overflow = 'hidden';
    document.getElementById('lbClose').focus();
  }

  function close() {
    lb.hidden = true;
    lbImg.removeAttribute('src');
    document.body.style.overflow = '';
    if (grazintiFokusa) grazintiFokusa.focus();   // fokusas grizta ten, kur buvo
  }

  function show() {
    var p = view[current];
    lbImg.src = p.full;
    lbImg.alt = p.pavadinimas || 'Nuotrauka';

    // antraste surenkam tik is to, kas is tikruju yra
    var dalys = [];
    if (p.pavadinimas) dalys.push(p.pavadinimas);
    if (p.galerija) dalys.push(p.galerija);
    dalys.push((current + 1) + '/' + view.length);
    lbCap.textContent = dalys.join('  ·  ');

    [current - 1, current + 1].forEach(function (n) {
      if (view[n]) { var pre = new Image(); pre.src = view[n].full; }
    });
  }

  function step(delta) {
    current = (current + delta + view.length) % view.length;
    show();
  }

  document.getElementById('lbClose').addEventListener('click', close);
  document.getElementById('lbPrev').addEventListener('click', function () { step(-1); });
  document.getElementById('lbNext').addEventListener('click', function () { step(1); });
  lb.addEventListener('click', function (e) { if (e.target === lb) close(); });

  document.addEventListener('keydown', function (e) {
    if (lb.hidden) return;

    if (e.key === 'Escape') { close(); return; }
    if (e.key === 'ArrowLeft')  { step(-1); return; }
    if (e.key === 'ArrowRight') { step(1);  return; }

    // fokuso gaudykle: Tab sukasi tik tarp lightbox mygtuku,
    // kitaip fokusas nukeliautu i puslapi uz atidarytos nuotraukos
    if (e.key === 'Tab') {
      var mygtukai = lb.querySelectorAll('button');
      if (!mygtukai.length) return;
      var pirmas = mygtukai[0];
      var paskutinis = mygtukai[mygtukai.length - 1];
      if (e.shiftKey && document.activeElement === pirmas) {
        e.preventDefault(); paskutinis.focus();
      } else if (!e.shiftKey && document.activeElement === paskutinis) {
        e.preventDefault(); pirmas.focus();
      }
    }
  });

  /* --- Braukimas telefone ---------------------------------------------- */
  var x0 = null;
  lb.addEventListener('touchstart', function (e) { x0 = e.changedTouches[0].clientX; }, { passive: true });
  lb.addEventListener('touchend', function (e) {
    if (x0 === null) return;
    var dx = e.changedTouches[0].clientX - x0;
    if (Math.abs(dx) > 50) step(dx < 0 ? 1 : -1);
    x0 = null;
  }, { passive: true });

  render(null);
})();
