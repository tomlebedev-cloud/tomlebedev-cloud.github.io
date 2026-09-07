# Fotografijos portfolio

Statinis puslapis, veikiantis GitHub Pages. Jokių priklausomybių — tik HTML, CSS ir JavaScript.

## Puslapiai

| Failas | Kas ten |
|---|---|
| `index.html` | Titulinis: nuotrauka-hero, atranka, įėjimai į darbų kūnus |
| `tanzania.html` | Tanzania |
| `morocco.html` | Morocco |
| `elsewhere.html` | Elsewhere |

Darbai suskirstyti pagal **vietą**, ne pagal žanrą. Viena kelionė lieka vientisa —
anksčiau ta pati Tanzanija buvo išdraskyta tarp „Wildlife“ ir „People“.

## Kaip pridėti nuotraukų

**1. Eksportuok iš Lightroom** į `photos/_originalai/<Aplankas>/`

Lightroom eksporto nustatymai:

| Nustatymas | Reikšmė |
|---|---|
| File Settings → Format | JPEG |
| Quality | 85 |
| Color Space | **sRGB** |
| Image Sizing | galima palikti pilną dydį — skriptas sumažins |
| Metadata | *Copyright & Contact Info Only* |
| ☑ Remove Location Info | **būtinai pažymėk** |

Aplanko pavadinimas svetainėje nebematomas — jis tik rikiuoja failus diske.
Kur nuotrauka pateks, sprendžia `photos/puslapiai.txt`.

**2. Aprašyk nuotrauką**

`photos/_originalai/<Aplankas>/alt.txt` — alt tekstas ekrano skaitytuvams ir SEO:

```
DSC_1234.jpg = A zebra facing the camera with its mouth wide open, Tanzania
```

**3. Įtrauk į puslapį**

`photos/puslapiai.txt` valdo, kas ir kokia tvarka rodoma:

```
== tanzania | tanzania.html | Tanzania | Ngorongoro and the northern parks, 2019.
Wildlife/DSC_1234.jpg | Zebra yawning
Wildlife/DSC_0931.jpg | By the lake | Ngorongoro
```

Trečias laukas — vietovė — nebūtinas. Jei jis yra, rodomas nuotraukos lange
po pavadinimu. Sekcija `== selected` yra titulinio atranka; ten pakanka kelio,
nes pavadinimas paimamas iš to puslapio, kuriame nuotrauka aprašyta.

**Nuotrauka, kurios `puslapiai.txt` nėra, lieka diske, bet svetainėje nerodoma.**
Taip atranką galima keisti nieko netrinant.

**4. Paleisk paruošimo skriptą**

```
powershell -ExecutionPolicy Bypass -File tools\paruosti-nuotraukas.ps1
```

Jis sukuria `photos/full/` (2000 px), `photos/thumb/` (700 px) ir
`photos/thumb-sm/` (400 px) bei įrašo galerijas į visus keturis puslapius
tarp `GALLERY:START` ir `GALLERY:END`. Jau apdorotas nuotraukas praleidžia.

Dvi miniatiūrų versijos reikalingos `srcset`: telefonas ir ne-retina ekranas
atsisiunčia 400 px, o retina — 700 px.

**5. Nusiųsk į GitHub**

```
git add .
git commit -m "Naujos nuotraukos"
git push
```

Puslapis atsinaujina per ~1 minutę.

> **Keitei `style.css`, `app.js` ar HTML?** Padidink `VERSIJA` failo `sw.js`
> viršuje (`photography-v16` → `v16`). Service worker talpina senas versijas, ir be
> šito grįžtantis lankytojas dar ilgai matys seną puslapį.

## Peržiūra kompiuteryje

Atsidaryk `index.html` naršyklėje — veikia ir be serverio.

## Ką kur keisti

| Failas | Kas ten |
|---|---|
| `photos/puslapiai.txt` | **Atranka ir tvarka** — kas į kurį puslapį patenka |
| `assets/style.css` | Išvaizda, spalvos (viršuje `:root`) |
| `assets/app.js` | Nuotraukos lango (lightbox) veikimas |
| `sw.js` | Talpyklos versija — didinti po kiekvieno pakeitimo |
| `index.html` | Hero nuotrauka, „About“, kontaktai |

### Rankomis prižiūrimi dalykai

Šito skriptas neliečia, tad keisdamas hero nuotrauką ar OG korteles daryk pats:

- **Hero nuotrauka** `index.html` faile turi tris dydžius `photos/hero/`
  (900, 1400 ir 2000 px). Pakeitęs kadrą sugeneruok visus tris, kitaip
  telefonas siųsis pilno dydžio failą.
- **`og:image`** kiekviename puslapyje rodo to darbų kūno nuotrauką —
  dalinantis nuoroda matosi fotografija, ne bendra kortelė. Tituliniam
  palikta `og-image.png` su vardu.

> Galerijų HTML tarp `GALLERY:START` ir `GALLERY:END` **generuojamas automatiškai**.
> Keisdamas plytelių žymėjimą, tą patį pakeitimą daryk ir
> `tools/paruosti-nuotraukas.ps1` — kitaip kitas importas jį ištrins.
> Visa kita puslapių dalis (antraštė, hero, „About“) redaguojama ranka —
> skriptas jos neliečia.

## Svarbu

`photos/_originalai/` yra `.gitignore` sąraše — originalai lieka tik tavo kompiuteryje.
Į GitHub keliauja tik sumažintos versijos. Originalų atsarginė kopija — OneDrive.
