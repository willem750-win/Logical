# Logic

Simulator voor digitale schakelingen, gemaakt met Lazarus / Free Pascal.
Je bouwt een schakeling op een paneel met schakelaars, sensoren, logische
poorten, tellers, geheugens, lampen en displays, en verbindt ze met draden.
Daarna zet je de simulatie aan en zie je de schakeling werken.

*English summary: see [below](#english).*

## Onderdelen

| Groep      | Onderdelen |
|------------|------------|
| Invoer     | drukknop, schakelaar, dipschakelaar (0–15), impulsgenerator, lichtsensor, warmtesensor |
| Verwerking | EN-poort, OF-poort, NIET-poort, tellerblok, geheugenblok |
| Uitvoer    | lamp, relais, zoemer, 7-segmentdisplay, meter |

Het 7-segmentdisplay toont 0–F als het aan de display-uitgang van een teller of
geheugen hangt, en 1 of 0 als het aan een gewone uitgang hangt (drukknop,
schakelaar, poort ...).

Verder:

- raster, linialen, richtlijnen, kader en titel op het paneel;
- kant-en-klare oefenpanelen (beslissen, teller, geheugen) in `Resultaat/panels`;
- gebruikersinterface en help in het **Nederlands, Engels, Frans en Duits**;
- werkt onder **Windows** en **Linux** (GTK2).

## Inhoud van de repository

| Map / bestand | Wat |
|---------------|-----|
| `jwlogic.lpk` | Lazarus-pakket met de simulatiecomponenten (palet **JWLOGIC**), o.a. `janSimLogic.pas` |
| `tiphtml.lpk` | Hulppakket voor HTML-hints |
| `projects/LogicCEF/` | Het programma voor Windows, met ingebouwde browser (CEF) voor de help |
| `projects/LogicCEF/helpsrc/` | Bronbestanden van de help (nl/en/fr/de) en `make-help.ps1` |
| `projects/LogicCEF/Resultaat/` | Uitvoermap: hier komt het programma. In de repo staan alleen `panels`, `ini`, `html`, `ImmoSetup` en `help-oud` |
| `Linux/` | Projectbestanden voor Linux (help opent in de standaardbrowser) |

## Bouwen

Nodig: [Lazarus](https://www.lazarus-ide.org/) 4.x met Free Pascal 3.2.2 of nieuwer.

```
git clone https://github.com/willem750-win/Logical.git
```

1. Open en installeer `jwlogic.lpk` in Lazarus (*Package → Open Package File*,
   daarna *Use → Install*). Het pakket heeft ook `rx` en `ComboBox_image` nodig.
2. Open het project:
   - Windows: `projects/LogicCEF/logic.lpi`
   - Linux: `Linux/logic.lpi`

   Installeer de pakketten die Lazarus als ontbrekend meldt.
   Voor LogicCEF hoort daar **CEF4Delphi** bij.
3. Bouw het project. Het programma komt in `projects/LogicCEF/Resultaat/`.

### CEF-bestanden (Windows)

De CEF-runtime staat niet in de repo (te groot). Kopieer de CEF-binaries
die bij je CEF4Delphi-versie horen (`libcef.dll`, `chrome_elf.dll`,
`icudtl.dat`, de `.pak`- en `.bin`-bestanden en de map `locales`) naar
`projects/LogicCEF/Resultaat/`.

### Help opbouwen

De help in `Resultaat/help` wordt gemaakt uit `helpsrc`:

```
powershell -ExecutionPolicy Bypass -File projects\LogicCEF\helpsrc\make-help.ps1
```

---

## English

**Logic** is a digital circuit simulator written in Lazarus / Free Pascal.
Place switches, sensors, logic gates (AND, OR, NOT), counters, memories, lamps,
relays, buzzers, 7-segment displays and meters on a panel, connect them with
wires and run the simulation. User interface and help are available in Dutch,
English, French and German. It runs on Windows and Linux (GTK2).

To build: install `jwlogic.lpk` in Lazarus 4.x, then open
`projects/LogicCEF/logic.lpi` (Windows, needs CEF4Delphi and the matching CEF
binaries copied into `projects/LogicCEF/Resultaat/`) or `Linux/logic.lpi`.
Generate the help with `projects/LogicCEF/helpsrc/make-help.ps1`.
