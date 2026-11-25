unit uNiveau;

{ Niveaus voor de onderdelenbalk: Basis, Uitgebreid en Gevorderden (alles),
  naast "Eigen keuze" (wat de gebruiker zelf in Instellingen aan- en uitzet).

  Een niveau is een laag bovenop de bestaande instellingen: het zet de
  K-eigenschappen van de onderdelenbalk (welke knoppen zichtbaar zijn) volgens
  de tabel hieronder, maar schrijft nooit in ini\defaultschakel.ini of
  ini\defaultgrid.ini. Die twee bestanden blijven de "Eigen keuze". Alleen de
  naam van het niveau wordt bewaard: [Settings] Niveau in taal.ini.

  De niveaus zijn cumulatief en volgen het leerpad:
    Basis        energieblok, les 1-11, oefening 1-5
    Uitgebreid   ook magnetisme, stroom en spanning, rekenen, elektronica
    Gevorderden  alles: ook LogicRun (les 12-22) en het Arduino-board }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, IniFiles, TypInfo, janSimLogic, chatgridpcodeSmall, uLangPo;

type
  TNiveau = (nvEigen, nvBasis, nvUitgebreid, nvGevorderden);

const
  NiveauId: array[TNiveau] of string = ('eigen', 'basis', 'uitgebreid', 'gevorderden');
  // volgorde in de keuzelijst en in het menu
  NiveauVolgorde: array[0..3] of TNiveau = (nvBasis, nvUitgebreid, nvGevorderden, nvEigen);

// 'basis' -> nvBasis ...; onbekend of leeg -> nvEigen
function NiveauVanId(const S: string): TNiveau;
// plaats van het niveau in NiveauVolgorde
function NiveauIndex(N: TNiveau): Integer;
// naam en uitleg in de taal ATaal ('NL', 'ENG', 'FR', 'DU'; 'ENG' ook voor de extra talen)
function NiveauNaam(const ATaal: string; N: TNiveau): string;
function NiveauUitleg(const ATaal: string; N: TNiveau): string;

// de knoppen van niveau N tonen (N <> nvEigen); raakt de ini-bestanden niet
procedure PasNiveauToe(Box: TjanSimLogicBox; Grid: TjanGridS; N: TNiveau);
// alle knoppen van de instellingenlijst aan (voor het terugzetten van Eigen keuze)
procedure AllesAan(Box: TjanSimLogicBox);
// staan de knoppen van de instellingenlijst en KLogicRun precies zoals niveau N?
function NiveauKlopt(Box: TjanSimLogicBox; Grid: TjanGridS; N: TNiveau): Boolean;
// staat alles aan wat in het niveau Gevorderden hoort?
function AllesStaatAan(Box: TjanSimLogicBox; Grid: TjanGridS): Boolean;
// laagste niveau dat voor elk onderdeel op het paneel een knop toont
function NodigNiveau(Box: TjanSimLogicBox): TNiveau;

// [Settings] Niveau in taal.ini; Bekend = False als de sleutel ontbreekt
function LeesNiveau(const AIniFile: string; out Bekend: Boolean): TNiveau;
procedure SchrijfNiveau(const AIniFile: string; N: TNiveau);
// KLogicRun zoals de gebruiker het zelf instelde (ini\defaultgrid.ini)
function EigenKLogicRun(const AIniDir: string): Boolean;

implementation

type
  TNiveauRij = record
    Naam: string;      // K-eigenschap van TjanSimLogicBox (zoals in Instellingen)
    Vanaf: TNiveau;    // zichtbaar vanaf dit niveau
  end;

const
  // De 41 knoppen van Instellingen > SchakelElementen (zie maaksettingsframe in
  // main.pas). KPersoon, KWagen, KMuziek en KVerkeer staan er niet in: die
  // volgen Grid.KLogicRun. KBoard (Arduino) staat niet in Instellingen en
  // wordt apart gezet. Een knop die hier ontbreekt, wordt nooit verborgen.
  Tabel: array[0..40] of TNiveauRij = (
    // Basis: energieblok, les 1-11, oefeningen
    (Naam: 'KDraad'; Vanaf: nvBasis),
    (Naam: 'KVoeding'; Vanaf: nvBasis),
    (Naam: 'KBron'; Vanaf: nvBasis),
    (Naam: 'KSchakelaar2'; Vanaf: nvBasis),
    (Naam: 'KLamp2'; Vanaf: nvBasis),
    (Naam: 'KLogicAnd'; Vanaf: nvBasis),
    (Naam: 'KLogicOr'; Vanaf: nvBasis),
    (Naam: 'KLogicNot'; Vanaf: nvBasis),
    (Naam: 'KBuzzer'; Vanaf: nvBasis),
    (Naam: 'KRelais'; Vanaf: nvBasis),
    (Naam: 'KWeerstand'; Vanaf: nvBasis),
    (Naam: 'KLDR'; Vanaf: nvBasis),
    (Naam: 'KNTC'; Vanaf: nvBasis),
    (Naam: 'KPuls2'; Vanaf: nvBasis),
    (Naam: 'KDip2'; Vanaf: nvBasis),
    (Naam: 'KTeller'; Vanaf: nvBasis),
    (Naam: 'KMemory'; Vanaf: nvBasis),
    (Naam: 'KDisplay'; Vanaf: nvBasis),
    (Naam: 'KVoltmeter2'; Vanaf: nvBasis),
    (Naam: 'KAmpMeter'; Vanaf: nvBasis),
    (Naam: 'KTransistor'; Vanaf: nvBasis),
    // Uitgebreid: magnetisme, stroom en spanning, rekenen, elektronica
    (Naam: 'KMagnetisme'; Vanaf: nvUitgebreid),
    (Naam: 'KWisselbron'; Vanaf: nvUitgebreid),
    (Naam: 'KZekering'; Vanaf: nvUitgebreid),
    (Naam: 'KMeter'; Vanaf: nvUitgebreid),
    (Naam: 'KLogicXor'; Vanaf: nvUitgebreid),
    (Naam: 'KLogicNand'; Vanaf: nvUitgebreid),
    (Naam: 'KLogicNor'; Vanaf: nvUitgebreid),
    (Naam: 'KFlipFlop'; Vanaf: nvUitgebreid),
    (Naam: 'KLed2'; Vanaf: nvUitgebreid),
    (Naam: 'KCondensator'; Vanaf: nvUitgebreid),
    (Naam: 'KPotmeter'; Vanaf: nvUitgebreid),
    (Naam: 'KDiode'; Vanaf: nvUitgebreid),
    (Naam: 'KScoop'; Vanaf: nvUitgebreid),
    (Naam: 'KWattMeter'; Vanaf: nvUitgebreid),
    (Naam: 'KWisselschakelaar'; Vanaf: nvUitgebreid),
    // Gevorderden: wat bij LogicRun hoort (de modellen volgen Grid.KLogicRun)
    (Naam: 'KMotor'; Vanaf: nvGevorderden),
    (Naam: 'KStappen'; Vanaf: nvGevorderden),
    (Naam: 'KStopwatch'; Vanaf: nvGevorderden),
    (Naam: 'KSlagboom'; Vanaf: nvGevorderden),
    // In geen enkel niveau (Vanaf = nvEigen): de oude lamp met een ingang. De
    // lessen gebruiken de lamp met twee klemmen (KLamp2); de oude lamp werkt nog
    // in oudere panelen en is alleen via Eigen keuze in de balk te zetten.
    (Naam: 'KLamp'; Vanaf: nvEigen)
  );

  // Onderdelen waarvan de knop pas in een hoger niveau staat. Vergeleken op
  // de exacte klassenaam: veel onderdelen stammen af van een onderdeel uit
  // een lager niveau (TjanRelais2 van TjanRelaisModel, TjanZoemer2 en
  // TjanSpoel van TjanWeerstand, TjanWisselbron van TjanBron, TjanScoop van
  // TjanVoltmeter2, TjanDiode van TjanLed2, TjanWattMeter van TjanAmpMeter,
  // TjanBoardIn van TjanSchakelaar2 ...), dus "is" zou hier fout tellen.
  KlassenUitgebreid: array[0..21] of string = (
    'TjanMagneet', 'TjanKompas', 'TjanVeldplaat', 'TjanSpoel', 'TjanIJzer', 'TjanRelaisModel',
    'TjanSchommel', 'TjanElektromotor', 'TjanNulmeter', 'TjanDraaimagneet', 'TjanTransformator',
    'TjanWisselbron', 'TjanZekering', 'TjanMeter', 'TjanSimFlipFlop', 'TjanLed2', 'TjanCondensator',
    'TjanPotmeter', 'TjanDiode', 'TjanScoop', 'TjanWattMeter', 'TjanWissel2');
  KlassenGevorderden: array[0..10] of string = (
    'TjanLogicRun', 'TjanSimPersoon', 'TjanSimWagen', 'TjanSimMuziek', 'TjanSimVerkeerslicht',
    'TjanSimSlagboom', 'TjanSimMotor', 'TjanSimStappenteller', 'TjanSimStopwatch',
    'TjanBoardIn', 'TjanBoardUit');

// zoals MyTr in main.pas: 'ENG' (en een onbekende code) gaat langs de extra
// talen (uLangPo); make-pot.ps1 verzamelt de Engelse tekst van elke Tr(...)
// staat de knop van rij i in niveau N?
function InNiveau(i: Integer; N: TNiveau): Boolean;
begin
  Result := (Tabel[i].Vanaf <> nvEigen) and (Tabel[i].Vanaf <= N);
end;

function Tr(const ATaal, NL, ENG, FR, DU: string): string;
begin
  if ATaal = 'NL' then Result := NL
  else if ATaal = 'FR' then Result := FR
  else if ATaal = 'DU' then Result := DU
  else Result := PoTr(ENG);
end;

function NiveauVanId(const S: string): TNiveau;
var
  N: TNiveau;
begin
  Result := nvEigen;
  for N := Low(TNiveau) to High(TNiveau) do
    if SameText(Trim(S), NiveauId[N]) then Exit(N);
end;

function NiveauIndex(N: TNiveau): Integer;
var
  i: Integer;
begin
  Result := High(NiveauVolgorde);
  for i := Low(NiveauVolgorde) to High(NiveauVolgorde) do
    if NiveauVolgorde[i] = N then Exit(i);
end;

function NiveauNaam(const ATaal: string; N: TNiveau): string;
begin
  case N of
    nvBasis:
      Result := Tr(ATaal, 'Basis', 'Basic', 'Base', 'Basis');
    nvUitgebreid:
      Result := Tr(ATaal, 'Uitgebreid', 'Extended', 'Étendu', 'Erweitert');
    nvGevorderden:
      Result := Tr(ATaal, 'Gevorderden (alles)', 'Advanced (everything)', 'Avancé (tout)', 'Fortgeschritten (alles)');
  else
    Result := Tr(ATaal, 'Eigen keuze (Instellingen)', 'Own selection (Settings)',
      'Choix personnel (Réglages)', 'Eigene Auswahl (Einstellungen)');
  end;
end;

function NiveauUitleg(const ATaal: string; N: TNiveau): string;
begin
  case N of
    nvBasis:
      Result := Tr(ATaal,
        'De eerste lessen: bron, schakelaar, lamp, de poorten EN, OF en NIET, teller en display.',
        'The first lessons: source, switch, lamp, the AND, OR and NOT gates, counter and display.',
        'Les premières leçons : source, interrupteur, lampe, les portes ET, OU et NON, compteur et afficheur.',
        'Die ersten Lektionen: Quelle, Schalter, Lampe, die Gatter UND, ODER und NICHT, Zähler und Anzeige.');
    nvUitgebreid:
      Result := Tr(ATaal,
        'Ook meten, magnetisme en elektronica: zekering, led, diode, scoop, spoel en alle poorten.',
        'Also measuring, magnetism and electronics: fuse, LED, diode, scope, coil and all gates.',
        'Aussi la mesure, le magnétisme et l''électronique : fusible, LED, diode, oscilloscope, bobine et toutes les portes.',
        'Auch Messen, Magnetismus und Elektronik: Sicherung, LED, Diode, Oszilloskop, Spule und alle Gatter.');
    nvGevorderden:
      Result := Tr(ATaal,
        'Alles, ook programmeren met LogicRun: motor, persoon, wagentje, verkeerslicht en het Arduino-board.',
        'Everything, also programming with LogicRun: motor, person, cart, traffic light and the Arduino board.',
        'Tout, aussi la programmation avec LogicRun : moteur, personne, chariot, feu de signalisation et la carte Arduino.',
        'Alles, auch Programmieren mit LogicRun: Motor, Person, Wagen, Ampel und das Arduino-Board.');
  else
    Result := Tr(ATaal,
      'De onderdelen die je zelf aan- en uitzet in Instellingen.',
      'The components you switch on and off yourself in Settings.',
      'Les composants que vous activez et désactivez vous-même dans Réglages.',
      'Die Bauteile, die Sie selbst in den Einstellungen ein- und ausschalten.');
  end;
end;

procedure ZetVlag(Box: TjanSimLogicBox; const ANaam: string; AWaarde: Boolean);
begin
  try
    SetPropValue(Box, ANaam, BoolToStr(AWaarde, True));
  except
    // een eigenschap die niet (meer) bestaat: overslaan
  end;
end;

function LeesVlag(Box: TjanSimLogicBox; const ANaam: string; AStandaard: Boolean): Boolean;
begin
  Result := AStandaard;
  try
    Result := GetOrdProp(Box, ANaam) <> 0;
  except
    // een eigenschap die niet (meer) bestaat: telt als goed
  end;
end;

procedure PasNiveauToe(Box: TjanSimLogicBox; Grid: TjanGridS; N: TNiveau);
var
  i: Integer;
begin
  if N = nvEigen then Exit;
  for i := Low(Tabel) to High(Tabel) do
    ZetVlag(Box, Tabel[i].Naam, InNiveau(i, N));
  Box.KBoard := N = nvGevorderden;
  // de knop LogicRun en de modellen (persoon, wagentje, muziekdoos,
  // verkeerslicht) volgen deze ene eigenschap van het paneel
  Grid.KLogicRun := N = nvGevorderden;
  Box.Invalidate;
end;

procedure AllesAan(Box: TjanSimLogicBox);
var
  i: Integer;
begin
  for i := Low(Tabel) to High(Tabel) do
    ZetVlag(Box, Tabel[i].Naam, True);
  Box.KBoard := True;
end;

function NiveauKlopt(Box: TjanSimLogicBox; Grid: TjanGridS; N: TNiveau): Boolean;
var
  i: Integer;
  Wil: Boolean;
begin
  Result := False;
  if N = nvEigen then Exit;
  for i := Low(Tabel) to High(Tabel) do
  begin
    Wil := InNiveau(i, N);
    if LeesVlag(Box, Tabel[i].Naam, Wil) <> Wil then Exit;
  end;
  Result := Grid.KLogicRun = (N = nvGevorderden);
end;

// Staat alles aan wat in het hoogste niveau hoort (en KLogicRun)? De knoppen
// die in geen enkel niveau zitten (de oude lamp) tellen niet mee.
function AllesStaatAan(Box: TjanSimLogicBox; Grid: TjanGridS): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := Low(Tabel) to High(Tabel) do
    if (Tabel[i].Vanaf <> nvEigen) and not LeesVlag(Box, Tabel[i].Naam, True) then Exit;
  Result := Grid.KLogicRun;
end;

function NodigNiveau(Box: TjanSimLogicBox): TNiveau;
var
  P: TWinControl;
  i, k: Integer;
  S: string;
begin
  Result := nvBasis;
  P := Box.Parent;
  if P = nil then Exit;
  for i := 0 to P.ControlCount - 1 do
  begin
    // een onderdeel dat nog aan de muis hangt, is onzichtbaar: niet meetellen
    if not P.Controls[i].Visible then Continue;
    S := P.Controls[i].ClassName;
    for k := Low(KlassenGevorderden) to High(KlassenGevorderden) do
      if SameText(S, KlassenGevorderden[k]) then Exit(nvGevorderden);
    if Result = nvBasis then
      for k := Low(KlassenUitgebreid) to High(KlassenUitgebreid) do
        if SameText(S, KlassenUitgebreid[k]) then Result := nvUitgebreid;
  end;
  // de poorten EX-OF, NEN en NOF zijn hetzelfde onderdeel als EN, OF en NIET
  if (Result = nvBasis) and
     ((Box.TelPoort('EXOF') > 0) or (Box.TelPoort('NEN') > 0) or (Box.TelPoort('NOF') > 0)) then
    Result := nvUitgebreid;
end;

function LeesNiveau(const AIniFile: string; out Bekend: Boolean): TNiveau;
var
  Ini: TIniFile;
  S: string;
begin
  Result := nvEigen;
  Bekend := False;
  try
    Ini := TIniFile.Create(AIniFile);
    try
      S := Trim(Ini.ReadString('Settings', 'Niveau', ''));
    finally
      Ini.Free;
    end;
    if S <> '' then
    begin
      Bekend := True;
      Result := NiveauVanId(S);
    end;
  except
    // niet leesbaar: zoals vroeger (Eigen keuze)
  end;
end;

procedure SchrijfNiveau(const AIniFile: string; N: TNiveau);
var
  Ini: TIniFile;
begin
  try
    Ini := TIniFile.Create(AIniFile);
    try
      Ini.WriteString('Settings', 'Niveau', NiveauId[N]);
    finally
      Ini.Free;
    end;
  except
    // map niet schrijfbaar: het niveau geldt dan tot het afsluiten
  end;
end;

function EigenKLogicRun(const AIniDir: string): Boolean;
var
  Ini: TIniFile;
begin
  Result := True;
  try
    Ini := TIniFile.Create(IncludeTrailingPathDelimiter(AIniDir) + 'defaultgrid.ini');
    try
      Result := not SameText(Trim(Ini.ReadString('Properties', 'KLogicRun', 'True')), 'False');
    finally
      Ini.Free;
    end;
  except
    // geen bestand: alles aan
  end;
end;

end.
