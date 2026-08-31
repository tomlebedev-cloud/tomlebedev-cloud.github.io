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

Jis sukuria `photos/full/` (2560 px) ir `photos/thumb/` (700 px) bei atnaujina `photos.js`.
Jau apdorotas nuotraukas praleidžia, todėl paleisti pakartotinai yra greita.

**3. Nusiųsk į GitHub**

```
git add .
git commit -m "Naujos nuotraukos"
git push
```

Puslapis atsinaujina per ~1 minutę.

## Peržiūra kompiuteryje

Atsidaryk `index.html` naršyklėje — veikia ir be serverio.

## Ką kur keisti

| Failas | Kas ten |
|---|---|
| `index.html` | Tekstai: pavadinimas, „Apie“, kontaktai |
| `assets/style.css` | Išvaizda, spalvos (viršuje `:root`) |
| `assets/app.js` | Galerijos ir lightbox veikimas |
| `photos.js` | **Generuojamas automatiškai** — ranka neredaguoti |

## Svarbu

`photos/_originalai/` yra `.gitignore` sąraše — originalai lieka tik tavo kompiuteryje.
Į GitHub keliauja tik sumažintos versijos. Originalų atsarginė kopija — OneDrive.
