# Geografické těžiště EU 2000–2025 (MATLAB)

Kam se posouvá „střed“ Evropské unie, když ho vážíme hlasy v Radě, mandáty v EP,
obyvatelstvem nebo ekonomikou? A jak s ním pohnula rozšíření 2004/2007/2013 a brexit?

Projekt počítá těžiště podle jednotlivých metrik (každý stát jako jeden bod) nad živými
daty Eurostatu v základním MATLABu.

## Spuštění

```matlab
cd eu-teziste-matlab   % kořen repozitáře
main             % těžiště podle jednotlivých metrik
```

Při prvním běhu se stáhnou data z Eurostat API do `data/raw/` (obyvatelstvo `demo_pjan`,
HDP `nama_10_gdp`). Pro aktualizaci stačí `data/raw/*.csv` smazat. Testováno v R2023b, stačí
základní MATLAB. Mapy kreslí vlastní třída `src/EuMap.m` na obyčejných osách, takže
nepotřebují Mapping Toolbox ani podkladové dlaždice z internetu. Členské státy EU jsou
světle modré, Spojené království (člen do 2020) světlejší a ostatní státy šedé.

| Soubor | Obsah |
|---|---|
| `main.m` | úroveň států: data → váhy → těžiště → souhrn → grafy |
| `src/EuMap.m` | třída pro mapy: projekce, státy EU / UK / ostatní (hranice GISCO), `line`/`scatter`/`text` v lat/lon |
| `src/spherical_centroid.m` | vážené těžiště na kouli (přes 3D vektory) |
| `src/council_rule.m` | pravidla kvalifikované většiny: Amsterdam (EU-15), Nice, Lisabon |
| `src/banzhaf_mc.m` | Banzhafův index hlasovací síly (Monte Carlo) |
| `src/fetch_eurostat.m` | stahování a parsování JSON-stat z Eurostatu, cache |
| `src/is_member.m` | matice členství rok × stát (k 31. 12.) |
| `data/countries.csv` | státy, přibližné středy území, plocha, data vstupu/odchodu |
| `data/council_votes.csv` | vážené hlasy v Radě: EU-15 (87) a Nice (až 352) |
| `data/ep_seats.csv` | mandáty v EP po volebních obdobích 1999–2024 |
| `results/` | CSV a PNG ze všech tří skriptů (viz níže) |

## Metoda

Každý stát *i* má bod (φᵢ, λᵢ) a váhu wᵢ. Bod se převede na jednotkový vektor
**xᵢ** = (cos φ cos λ, cos φ sin λ, sin φ), spočítá se vážený průměr Σ wᵢ**xᵢ** / Σ wᵢ
a promítne se zpět na povrch. Prostý průměr stupňů by byl chybný, protože jeden stupeň
délky měří na Kypru (35° s. š.) asi o 30 % víc než ve Finsku (64° s. š.).

Referenční datum je 31. 12. daného roku. Rok 2004 je tedy už EU-25, 2013 zahrnuje
Chorvatsko a 2020 už nezahrnuje Spojené království.

## Co je Banzhafova síla v Radě

V Radě EU se většina rozhodnutí přijímá **kvalifikovanou většinou**. Počet hlasů, které
stát má, ale neříká, jak velký má vliv. Vliv má stát jen tehdy, když jeho hlas
**rozhoduje**, tj. když koalice s ním návrh prosadí a bez něj ne. Takový stát je
v dané koalici **„swing“** (jazýček na vahách).

**Banzhafův index** spočítá pro každý stát, v kolika ze všech možných koalic je swing,
a normalizuje to tak, aby součet přes státy byl 100 %. Odpovídá na otázku: *jakou část
skutečné rozhodovací moci stát drží*, pokud předpokládáme, že každá koalice je stejně
pravděpodobná. Pro 27 států je koalic 2²⁷ ≈ 134 milionů, proto `banzhaf_mc.m` index
odhaduje Monte Carlem (náhodné koalice, chyba ~0,1 %).

**Proč se váha a síla liší (výpočet z dat projektu):**

| Stát | 2003, EU-15: hlasy → síla | 2010, Nice: hlasy → síla | 2025, Lisabon: populace → síla |
|---|---|---|---|
| Německo | 11,5 % → 11,2 % | 8,4 % → 7,8 % | 18,6 % → **12,1 %** |
| Španělsko | 9,2 % → 9,2 % | 7,8 % → 7,4 % | 10,9 % → 7,8 % |
| Polsko | – | 7,8 % → 7,5 % | 8,1 % → 6,2 % |
| Česko | – | 3,5 % → 3,7 % | 2,4 % → 3,0 % |
| Lucembursko | 2,3 % → 2,3 % | 1,2 % → 1,3 % | 0,15 % → **1,75 %** |

- **Nice (2004–2014):** Polsko a Španělsko měly s 27 hlasy prakticky stejnou sílu jako
  Německo s 29, přestože mělo dvakrát víc obyvatel.
- **Lisabon (od 2014):** „hlasem“ je podíl na populaci, ale skutečná síla je jiná.
  Německo má 18,6 % obyvatel a jen 12,1 % síly. Lucembursko má 0,15 % obyvatel
  a 1,75 % síly, protože druhá podmínka (55 % **států**) dává každému státu stejnou váhu.
- Extrémní příklad je EHS v roce 1958: Lucembursko mělo 1 hlas ze 17, ale jeho síla
  byla **0 %**. Ostatní státy měly sudé počty hlasů a kvóta byla 12, takže jeho hlas
  nikdy nic nerozhodl. Přesný výpočet ze všech 64 koalic to potvrzuje.

V projektu jsou proto dvě metriky. **Hlasy v Radě** jsou formální váha (od roku 2014
totožná s populací). **Banzhafova síla v Radě** je skutečný vliv a její těžiště leží
o ~160 km východněji (2025), protože malé státy (často na východě) mají víc síly, než by
odpovídalo jejich velikosti.

## Návrhy metrik

Metriky ✅ jsou implementované, ostatní jsou návrhy na další práci.

### Politická váha

| Metrika | Co měří | Zdroj |
|---|---|---|
| ✅ **Státy 1:1** | „jeden stát, jeden hlas“: Komise (1 komisař/stát), jednomyslnost, Evropská rada | definice |
| ✅ **Hlasy v Radě EU** | 2000–2003 vážené hlasy EU-15 (87), 2004–2013 Nice (321/345/352), od 2014 dvojí většina, kde hlasem je populace | smlouvy |
| ✅ **Banzhafova síla v Radě** | jak často je stát rozhodující pro vznik většiny. Váha hlasů a skutečná moc se liší: podle Nice měly Polsko a Španělsko s 27 hlasy téměř stejnou sílu jako Německo s 29 | výpočet |
| ✅ **Mandáty v EP** | degresivní proporcionalita, malé státy jsou nadreprezentované | rozhodnutí o složení EP |
| Shapley–Shubikův index | alternativa k Banzhafovi (záleží na pořadí, ve kterém se koalice skládá) | výpočet |
| Síla v Radě guvernérů ECB | jen eurozóna, rotující hlasovací práva od 2015 | ECB |
| Kapitálový klíč ECB | 50 % populace + 50 % HDP, mění se po 5 letech | ECB |
| Váha frakcí v EP | těžiště EPP vs. S&D vs. Renew atd. (kde „sedí“ která frakce) | EP, ParlGov |

### Demografie a území

| Metrika | Poznámka |
|---|---|
| ✅ **Populace** (1. 1., Eurostat) | základní metrika, od 2014 totožná s hlasy v Radě |
| ✅ **Plocha** | čistě geometrické těžiště, Skandinávie táhne na sever |
| Populace 20–64 let / pracovní síla | ukáže stárnutí, v Itálii a ve východní Evropě rychlejší |
| Migrace (čisté saldo) | těžiště toho, *kam* se lidé stěhují |

### Ekonomika

| Metrika | Poznámka |
|---|---|
| ✅ **HDP v EUR (běžné ceny)** | ekonomická váha na trhu. Výrazně západněji než populace |
| ✅ **HDP v PPS** | HDP očištěné o cenové hladiny, východ v něm váží víc |
| Rozpočet EU: příspěvky / čistá pozice | těžiště plátců vs. příjemců. Dva body, mezi kterými se dá měřit vzdálenost |
| Vnitrounijní obchod (export do EU) | těžiště jednotného trhu |
| Přímé zahraniční investice uvnitř EU | kam proudí kapitál |
| Emise CO₂ / spotřeba energie | těžiště klimatického břemene |

### Kombinované a kontrafaktuální scénáře

- **Složený index** = vážená kombinace normalizovaných metrik. Váhy nastaví uživatel,
  případně se odvodí z PCA.
- **Podmnožiny:** eurozóna (vývoj 12 → 21 států), Schengen, NATO-EU.
- **Kontrafaktuál „bez brexitu“:** UK zůstává po roce 2020 (populace z ONS).
- **Budoucí rozšíření:** Ukrajina, Moldavsko, západní Balkán. Zajímavé je, kolik zemí
  přibude a jak velký skok těžiště to způsobí.

## Výsledky (první běh, data Eurostatu ke 2026-10)

Posun 2000 → 2025 (`results/souhrn_posunu.csv`):

| Metrika | 2000 | 2025 | Posun | Směr |
|---|---|---|---|---|
| Státy 1:1 | 50,37 N 6,66 E (Lucembursko/Porýní) | 49,18 N 14,15 E (**jižní Čechy**) | **553 km** | V |
| Banzhafova síla v Radě | 49,10 N 5,97 E | 48,53 N 11,53 E (Bavorsko) | 412 km | V |
| Mandáty v EP | 48,77 N 5,68 E | 48,40 N 11,04 E | 396 km | V |
| Plocha | 50,67 N 6,90 E | 50,25 N 11,55 E (Durynsko) | 333 km | V |
| Populace | 48,48 N 5,57 E (Lotrinsko) | 47,95 N 9,58 E (u Bodamského jezera) | 303 km | V |
| Hlasy v Radě | 49,00 N 5,92 E | 47,95 N 9,58 E | 294 km | VJV |
| HDP v PPS | 48,87 N 5,85 E | 48,41 N 8,96 E | 234 km | V |
| HDP v EUR | 49,54 N 5,66 E | 48,78 N 8,44 E (Bádensko-Württembersko) | 220 km | VJV |

Co je z toho vidět:

1. **Skoky dělají rozšíření a brexit, ne demografie.** Populační těžiště se posunulo
   o 164 km při rozšíření 2004, o 79 km v roce 2007 a o 141 km při brexitu 2020.
   V ostatních letech se meziročně hýbe jen o 1–4 km.
2. **Čím „rovnostářštější“ metrika, tím dál na východ.** Pořadí od západu na východ je
   HDP → populace → EP → Banzhaf → státy 1:1. Malé východní státy mají v institucích
   víc váhy, než odpovídá jejich obyvatelstvu, a ještě víc v poměru k jejich ekonomice.
3. **Mezi rozšířeními se populační těžiště plíží zpátky na západ** (2007–2019 z 8,61° na 8,35° v. d.,
   2020–2025 z 9,75° na 9,58° v. d.). Příčinou je vylidňování východu a jihovýchodu
   a migrace na západ.
4. **Ekonomické těžiště se mezi rozšířeními naopak posouvá na východ** (HDP v EUR
   2004–2019 z 6,18° na 6,81° v. d.). To je ekonomická konvergence nových členů.
5. **Lisabonská reforma 2014 posunula těžiště hlasů v Radě o ~150 km na západ**
   (viz skok červené křivky v `casove_rady.png`). Systém z Nice nadhodnocoval
   středně velké státy, hlavně Polsko a Španělsko, a dvojí většina tuto výhodu
   přesunula k Německu.
6. Brexit posunul **všechny** metriky na jihovýchod, protože UK leželo na severozápadním
   okraji.

![mapa](results/mapa_teziste.png)
![časové řady](results/casove_rady.png)
