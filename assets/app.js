/* Lightbox. Galerijos jau yra HTML'e - sis failas jokio turinio nekuria,
   tik prisikabina prie esamo DOM. */
(function () {
  'use strict';

  var plyteles = Array.prototype.slice.call(document.querySelectorAll('.tile'));
  if (!plyteles.length) return;

  var lb    = document.getElementById('lightbox');
  var lbImg = document.getElementById('lbImg');
  var lbCap = document.getElementById('lbCaption');
  if (!lb || !lbImg) return;

  /* Kiekvienai plytelei - jos vieta savo sekcijoje, kad skaitiklis rodytu
     "3 / 48", o ne bendra numeri per visa puslapi. */
  var irasai = plyteles.map(function (fig) {
    var sec  = fig.closest('.sekcija');
    var savos = sec ? Array.prototype.slice.call(sec.querySelectorAll('.tile')) : [fig];
    var cap  = fig.querySelector('figcaption');
    var img  = fig.querySelector('img');
    var h2   = sec ? sec.querySelector('h2') : null;
    return {
      fig:      fig,
      full:     fig.getAttribute('data-full'),
      alt:      img ? img.getAttribute('alt') : '',
      antraste: cap ? cap.textContent : '',
      sekcija:  h2 ? h2.textContent : '',
      nr:       savos.indexOf(fig) + 1,
      viso:     savos.length
    };
  });

  var dabar = 0;
  var grazintiFokusa = null;

  function rodyk() {
    var r = irasai[dabar];
    lbImg.src = r.full;
    lbImg.alt = r.alt;
    lbCap.innerHTML = '';
    lbCap.appendChild(document.createTextNode(r.antraste));
    var meta = document.createElement('span');
    meta.textContent = r.sekcija + '  \u00b7  ' + r.nr + ' / ' + r.viso;
    lbCap.appendChild(meta);

    [dabar - 1, dabar + 1].forEach(function (n) {
      if (irasai[n]) { var pre = new Image(); pre.src = irasai[n].full; }
    });
  }

  function atidaryk(i) {
    dabar = i;
    grazintiFokusa = irasai[i].fig;
    rodyk();
    lb.hidden = false;
    document.body.style.overflow = 'hidden';
    document.getElementById('lbClose').focus();
  }

  function uzdaryk() {
    lb.hidden = true;
    lbImg.removeAttribute('src');
    document.body.style.overflow = '';
    if (grazintiFokusa) grazintiFokusa.focus();
  }

  function zingsnis(d) {
    dabar = (dabar + d + irasai.length) % irasai.length;
    rodyk();
  }

  irasai.forEach(function (r, i) {
    r.fig.addEventListener('click', function () { atidaryk(i); });
    r.fig.addEventListener('keydown', function (e) {
      if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); atidaryk(i); }
    });
  });

  document.getElementById('lbClose').addEventListener('click', uzdaryk);
  document.getElementById('lbPrev').addEventListener('click', function () { zingsnis(-1); });
  document.getElementById('lbNext').addEventListener('click', function () { zingsnis(1); });
  lb.addEventListener('click', function (e) { if (e.target === lb) uzdaryk(); });

  document.addEventListener('keydown', function (e) {
    if (lb.hidden) return;
    if (e.key === 'Escape')     { uzdaryk();    return; }
    if (e.key === 'ArrowLeft')  { zingsnis(-1); return; }
    if (e.key === 'ArrowRight') { zingsnis(1);  return; }
    if (e.key === 'Tab') {
      var m = lb.querySelectorAll('button');
      if (!m.length) return;
      var pirmas = m[0], paskutinis = m[m.length - 1];
      if (e.shiftKey && document.activeElement === pirmas) { e.preventDefault(); paskutinis.focus(); }
      else if (!e.shiftKey && document.activeElement === paskutinis) { e.preventDefault(); pirmas.focus(); }
    }
  });

  var x0 = null;
  lb.addEventListener('touchstart', function (e) { x0 = e.changedTouches[0].clientX; }, { passive: true });
  lb.addEventListener('touchend', function (e) {
    if (x0 === null) return;
    var dx = e.changedTouches[0].clientX - x0;
    if (Math.abs(dx) > 50) zingsnis(dx < 0 ? 1 : -1);
    x0 = null;
  }, { passive: true });
})();
