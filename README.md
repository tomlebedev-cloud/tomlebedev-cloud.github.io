# Fotografijos portfolio

Statinis puslapis, veikiantis GitHub Pages. Jokių priklausomybių — tik HTML, CSS ir JavaScript.

## Kaip pridėti nuotraukų

**1. Eksportuok iš Lightroom** į `photos/_originalai/<Galerijos pavadinimas>/`

Lightroom eksporto nustatymai:

| Nustatymas | Reikšmė |
|---|---|
| File Settings → Format | JPEG |
| Quality | 85 |
| Color Space | **sRGB** |
| Image Sizing | galima palikti pilną dydį — skriptas sumažins |
| Metadata | *Copyright & Contact Info Only* |
| ☑ Remove Location Info | **būtinai pažymėk** |

Galerija = aplanko pavadinimas. Pavyzdžiui:

```
photos/_originalai/Portugalija/DSC_1234.jpg
photos/_originalai/Šachmatai/DSC_5678.jpg
```

**2. Paleisk paruošimo skriptą**

```
powershell -ExecutionPolicy Bypass -File tools\paruosti-nuotraukas.ps1
```

Jis sukuria `photos/full/` (2560 px), `photos/thumb/` (700 px) ir `photos/thumb-sm/` (400 px)
bei įrašo galerijas tiesiai į `index.html` tarp `GALLERY:START` ir `GALLERY:END`.
Jau apdorotas nuotraukas praleidžia, todėl paleisti pakartotinai yra greita.

Dvi miniatiūrų versijos reikalingos `srcset`: telefonas ir ne-retina ekranas
atsisiunčia 400 px, o retina — 700 px.

**3. Nusiųsk į GitHub**

```
git add .
git commit -m "Naujos nuotraukos"
git push
```

Puslapis atsinaujina per ~1 minutę.

> **Keitei `style.css`, `app.js` ar `index.html`?** Padidink `VERSIJA` failo `sw.js`
> viršuje (`photography-v13` → `v14`). Service worker talpina senas versijas, ir be
> šito grįžtantis lankytojas dar ilgai matys seną puslapį.

## Peržiūra kompiuteryje

Atsidaryk `index.html` naršyklėje — veikia ir be serverio.

## Ką kur keisti

| Failas | Kas ten |
|---|---|
| `index.html` | Tekstai: pavadinimas, „Apie“, kontaktai |
| `assets/style.css` | Išvaizda, spalvos (viršuje `:root`) |
| `assets/app.js` | Galerijos ir lightbox veikimas |
| `sw.js` | Talpyklos versija — didinti po kiekvieno pakeitimo |

> Galerijų HTML `index.html` faile tarp `GALLERY:START` ir `GALLERY:END`
> **generuojamas automatiškai**. Keisdamas plytelių žymėjimą, tą patį pakeitimą
> daryk ir `tools/paruosti-nuotraukas.ps1` — kitaip kitas nuotraukų importas jį ištrins.

## Svarbu

`photos/_originalai/` yra `.gitignore` sąraše — originalai lieka tik tavo kompiuteryje.
Į GitHub keliauja tik sumažintos versijos. Originalų atsarginė kopija — OneDrive.
