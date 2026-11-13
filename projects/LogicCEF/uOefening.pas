unit uOefening;

{ Oefening-venster: een oefening is een gewoon paneelbestand (.lpl) met
  enkele regels extra (zie TjanSimLogicBox.Oefening):
    Titel;NL;Oefening 1: de EN-poort
    Opdracht;NL;tekst van de opdracht (| = nieuwe regel)
    Verwacht;2;1;000;010;100;111;
    Verboden;EXOF;
  Titel en Opdracht staan er per taal (NL, EN, FR, DE, en eventueel de
  code van een extra taal zoals IT). Verwacht geeft het aantal ingangen
  en uitgangen en dan de juiste waarheidstabel, rij per rij zoals
  TjanSimLogicBox.Waarheidstabel ze maakt (eerst de ingangen A, B ...,
  dan de uitgangen). Verboden: poorten die de leerling niet mag gebruiken.
  Met de knop Controleer rekent Logic de waarheidstabel van de schakeling
  uit en vergelijkt die met Verwacht.
  Gewoon LCL-venster, zonder .lfm, zodat het ook onder Linux werkt. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, StdCtrls, ExtCtrls,
  janSimLogic, uLangPo;

type
  TOefForm = class(TForm)
  private
    FBox: TjanSimLogicBox;
    FTaal: string;
    FTitel: TLabel;
    FOpdracht: TLabel;
    FUitslag: TMemo;
    FKnoppen: TPanel;
    BtControleer, BtSluit: TButton;
    FTimer: TTimer;
    FTekst: string;          // de oefening die nu getoond wordt
    function T(const NL, EN, FR, DE: string): string;
    function Regel(const Soort: string): string;
    function Velden(const Soort: string; L: TStrings): Boolean;
    procedure FillTexts;
    procedure ToonOpdracht;
    procedure BtControleerClick(Sender: TObject);
    procedure BtSluitClick(Sender: TObject);
    procedure TimerTick(Sender: TObject);
  public
    constructor CreateFor(AOwner: TComponent; ABox: TjanSimLogicBox);
    procedure SetTaal(const ATaal: string);
    // na het laden van een paneel: is het een oefening, dan het venster tonen
    procedure Toon;
    procedure Controleer;
  end;

// staat er een oefening op het paneel?
function IsOefening(ABox: TjanSimLogicBox): Boolean;

implementation

function IsOefening(ABox: TjanSimLogicBox): Boolean;
var
  i: Integer;
begin
  Result := False;
  if ABox = nil then Exit;
  for i := 0 to ABox.Oefening.Count - 1 do
    if Pos('Verwacht;', ABox.Oefening[i]) = 1 then
      Exit(True);
end;

constructor TOefForm.CreateFor(AOwner: TComponent; ABox: TjanSimLogicBox);
begin
  inherited CreateNew(AOwner);
  FBox := ABox;
  FTaal := 'NL';
  BorderStyle := bsSizeToolWin;
  FormStyle := fsStayOnTop;
  Width := 400;
  Height := 420;
  Position := poDesigned;

  FTitel := TLabel.Create(Self);
  FTitel.Parent := Self;
  FTitel.Align := alTop;
  FTitel.WordWrap := True;
  FTitel.AutoSize := True;
  FTitel.BorderSpacing.Around := 8;
  FTitel.Font.Style := [fsBold];
  FTitel.Font.Size := 11;

  FOpdracht := TLabel.Create(Self);
  FOpdracht.Parent := Self;
  FOpdracht.Align := alTop;
  FOpdracht.Top := 40;
  FOpdracht.WordWrap := True;
  FOpdracht.AutoSize := True;
  FOpdracht.BorderSpacing.Left := 8;
  FOpdracht.BorderSpacing.Right := 8;
  FOpdracht.BorderSpacing.Bottom := 8;

  FKnoppen := TPanel.Create(Self);
  FKnoppen.Parent := Self;
  FKnoppen.Align := alBottom;
  FKnoppen.Height := 40;
  FKnoppen.BevelOuter := bvNone;

  BtControleer := TButton.Create(Self);
  BtControleer.Parent := FKnoppen;
  BtControleer.SetBounds(8, 7, 140, 26);
  BtControleer.OnClick := @BtControleerClick;
  BtControleer.Default := True;
  BtSluit := TButton.Create(Self);
  BtSluit.Parent := FKnoppen;
  BtSluit.SetBounds(156, 7, 120, 26);
  BtSluit.OnClick := @BtSluitClick;
  BtSluit.Cancel := True;

  FUitslag := TMemo.Create(Self);
  FUitslag.Parent := Self;
  FUitslag.Align := alClient;
  FUitslag.BorderSpacing.Around := 8;
  FUitslag.ReadOnly := True;
  FUitslag.ScrollBars := ssAutoVertical;
  FUitslag.WordWrap := True;
  FUitslag.Font.Size := 10;

  // een ander paneel geopend (geen oefening meer): venster weg
  FTimer := TTimer.Create(Self);
  FTimer.Interval := 400;
  FTimer.OnTimer := @TimerTick;
  FTimer.Enabled := True;

  FillTexts;
end;

function TOefForm.T(const NL, EN, FR, DE: string): string;
begin
  if FTaal = 'ENG' then Result := PoTr(EN)   // of een extra taal (uLangPo)
  else if FTaal = 'FR' then Result := FR
  else if FTaal = 'DU' then Result := DE
  else Result := NL;
end;

procedure TOefForm.SetTaal(const ATaal: string);
begin
  FTaal := ATaal;
  FillTexts;
  ToonOpdracht;
end;

procedure TOefForm.FillTexts;
begin
  Caption := T('Oefening', 'Exercise', 'Exercice', 'Übung');
  BtControleer.Caption := T('Controleer', 'Check', 'Vérifier', 'Prüfen');
  BtSluit.Caption := T('Sluiten', 'Close', 'Fermer', 'Schließen');
end;

// de tekst van Titel of Opdracht in de taal van nu (anders Engels,
// anders Nederlands); | wordt een nieuwe regel
function TOefForm.Regel(const Soort: string): string;
var
  Codes: array[0..2] of string;
  i, k: Integer;
  S, Kop: string;
begin
  Result := '';
  if FTaal = 'ENG' then
  begin
    if PoActive then Codes[0] := UpperCase(PoCode) else Codes[0] := 'EN';
    Codes[1] := 'EN';
  end
  else if FTaal = 'FR' then begin Codes[0] := 'FR'; Codes[1] := 'EN'; end
  else if FTaal = 'DU' then begin Codes[0] := 'DE'; Codes[1] := 'EN'; end
  else begin Codes[0] := 'NL'; Codes[1] := 'EN'; end;
  Codes[2] := 'NL';
  for k := 0 to 2 do
    for i := 0 to FBox.Oefening.Count - 1 do
    begin
      Kop := Soort + ';' + Codes[k] + ';';
      S := FBox.Oefening[i];
      if Pos(Kop, S) = 1 then
      begin
        Result := Copy(S, Length(Kop) + 1, MaxInt);
        if (Result <> '') and (Result[Length(Result)] = ';') then
          Delete(Result, Length(Result), 1);
        Result := StringReplace(Result, '|', LineEnding, [rfReplaceAll]);
        Exit;
      end;
    end;
end;

// de velden van de regel Soort;a;b;c; (zonder de soort)
function TOefForm.Velden(const Soort: string; L: TStrings): Boolean;
var
  i: Integer;
begin
  L.Clear;
  Result := False;
  for i := 0 to FBox.Oefening.Count - 1 do
    if Pos(Soort + ';', FBox.Oefening[i]) = 1 then
    begin
      L.Delimiter := ';';
      L.StrictDelimiter := True;
      L.DelimitedText := Copy(FBox.Oefening[i], Length(Soort) + 2, MaxInt);
      while (L.Count > 0) and (Trim(L[L.Count - 1]) = '') do
        L.Delete(L.Count - 1);
      Exit(True);
    end;
end;

procedure TOefForm.ToonOpdracht;
begin
  if not IsOefening(FBox) then Exit;
  FTitel.Caption := Regel('Titel');
  FOpdracht.Caption := Regel('Opdracht');
end;

procedure TOefForm.Toon;
var
  S: string;
begin
  if not IsOefening(FBox) then
  begin
    FTekst := '';
    Hide;
    Exit;
  end;
  S := FBox.Oefening.Text;
  if S <> FTekst then
  begin
    FTekst := S;
    FUitslag.Clear;
    FUitslag.Color := clWindow;
    FUitslag.Lines.Add(T('Bouw de schakeling en klik dan op Controleer. Je mag ook eerst de simulatie aanzetten en het zelf proberen.',
      'Build the circuit and then click Check. You may also switch the simulation on first and try it yourself.',
      'Construisez le circuit puis cliquez sur Vérifier. Vous pouvez aussi lancer d''abord la simulation et essayer vous-même.',
      'Bauen Sie die Schaltung und klicken Sie dann auf Prüfen. Sie dürfen auch zuerst die Simulation einschalten und es selbst ausprobieren.'));
  end;
  ToonOpdracht;
  Show;
  BringToFront;
end;

procedure TOefForm.TimerTick(Sender: TObject);
begin
  if Visible and not IsOefening(FBox) then
  begin
    FTekst := '';
    Hide;
  end;
end;

procedure TOefForm.BtControleerClick(Sender: TObject);
begin
  Controleer;
end;

procedure TOefForm.BtSluitClick(Sender: TObject);
begin
  Hide;
end;

procedure TOefForm.Controleer;
const
  MaxFout = 8;
var
  Ins, Outs: TList;
  Rijen, V, Verb, Fout: TStringList;
  Geheugen: Boolean;
  Res, NIn, NOut, i, j, k, NL, NZ, NR, NM, ND: Integer;
  Namen: array of string;
  O: TObject;
  Rij, Moet, Is_, Stand, Poort: string;

  function Waarde(c: Char): string;
  begin
    if c = '1' then Result := T('aan', 'on', 'allumée', 'an')
    else if c = '0' then Result := T('uit', 'off', 'éteinte', 'aus')
    else Result := c;
  end;

begin
  if not IsOefening(FBox) then Exit;
  Ins := TList.Create;
  Outs := TList.Create;
  Rijen := TStringList.Create;
  V := TStringList.Create;
  Verb := TStringList.Create;
  Fout := TStringList.Create;
  try
    FUitslag.Clear;
    FUitslag.Color := RGBToColor(255, 228, 225);   // lichtrood: nog niet goed
    Velden('Verwacht', V);
    if V.Count < 3 then Exit;
    NIn := StrToIntDef(V[0], 0);
    NOut := StrToIntDef(V[1], 0);
    Res := FBox.Waarheidstabel(Ins, Outs, Rijen, Geheugen, 6);

    // de juiste ingangen en uitgangen?
    if Ins.Count <> NIn then
    begin
      FUitslag.Lines.Add(Format(T('Deze oefening heeft %d ingangen nodig (schakelaars, drukknoppen of sensoren); op het paneel staan er %d.',
        'This exercise needs %d inputs (switches, push buttons or sensors); there are %d on the panel.',
        'Cet exercice a besoin de %d entrées (interrupteurs, boutons-poussoirs ou capteurs) ; il y en a %d sur le panneau.',
        'Diese Übung braucht %d Eingänge (Schalter, Taster oder Sensoren); auf dem Panel sind %d.'), [NIn, Ins.Count]));
      Exit;
    end;
    if Outs.Count <> NOut then
    begin
      FUitslag.Lines.Add(Format(T('Deze oefening heeft %d uitgangen nodig (lampen, leds, zoemers ...); op het paneel staan er %d.',
        'This exercise needs %d outputs (lamps, LEDs, buzzers ...); there are %d on the panel.',
        'Cet exercice a besoin de %d sorties (lampes, LED, buzzers ...) ; il y en a %d sur le panneau.',
        'Diese Übung braucht %d Ausgänge (Lampen, LEDs, Summer ...); auf dem Panel sind %d.'), [NOut, Outs.Count]));
      Exit;
    end;
    if Res <> 0 then Exit;

    // poorten die niet mogen
    if Velden('Verboden', Verb) then
      for i := 0 to Verb.Count - 1 do
        if FBox.TelPoort(Trim(Verb[i])) > 0 then
        begin
          Poort := TjanSimLogicBox.PoortWoord(Trim(Verb[i]), FTaal);
          FUitslag.Lines.Add(Format(T('In deze oefening mag je geen %s-poort gebruiken. Bouw ze na met de andere poorten.',
            'In this exercise you may not use a %s gate. Build it from the other gates.',
            'Dans cet exercice, vous ne pouvez pas utiliser de porte %s. Reconstruisez-la avec les autres portes.',
            'In dieser Übung dürfen Sie kein %s-Gatter verwenden. Bauen Sie es mit den anderen Gattern nach.'), [Poort]));
          Exit;
        end;

    // namen van de uitgangen zoals in de waarheidstabel (L1, Z1, ...)
    SetLength(Namen, Outs.Count);
    NL := 0; NZ := 0; NR := 0; NM := 0; ND := 0;
    for j := 0 to Outs.Count - 1 do
    begin
      O := TObject(Outs[j]);
      if O is TjanSimBuzzer then begin Inc(NZ); Namen[j] := T('Z', 'B', 'B', 'S') + IntToStr(NZ); end
      else if O is TjanSimRelais then begin Inc(NR); Namen[j] := 'R' + IntToStr(NR); end
      else if O is TjanSimMotor then begin Inc(NM); Namen[j] := 'M' + IntToStr(NM); end
      else if O is TjanDisplay then begin Inc(ND); Namen[j] := 'D' + IntToStr(ND); end
      else begin Inc(NL); Namen[j] := 'L' + IntToStr(NL); end;
    end;

    // rij per rij vergelijken
    for k := 2 to V.Count - 1 do
    begin
      Moet := Trim(V[k]);
      if Length(Moet) <> NIn + NOut then Continue;
      Rij := '';
      for i := 0 to Rijen.Count - 1 do
        if Copy(Rijen[i], 1, NIn) = Copy(Moet, 1, NIn) then
        begin
          Rij := Rijen[i];
          Break;
        end;
      if Rij = Moet then Continue;
      Stand := '';
      for i := 1 to NIn do
      begin
        if Stand <> '' then Stand := Stand + ', ';
        Stand := Stand + Chr(Ord('A') + i - 1) + '=' + Moet[i];
      end;
      for j := 1 to NOut do
        if (Length(Rij) >= NIn + j) and (Rij[NIn + j] <> Moet[NIn + j]) then
        begin
          Is_ := Waarde(Rij[NIn + j]);
          Fout.Add(Format(T('Bij %s is %s %s, maar die moet %s zijn.',
            'With %s, %s is %s, but it should be %s.',
            'Avec %s, %s est %s, mais elle doit être %s.',
            'Bei %s ist %s %s, sollte aber %s sein.'),
            [Stand, Namen[j - 1], Is_, Waarde(Moet[NIn + j])]));
        end;
    end;

    if Fout.Count = 0 then
    begin
      FUitslag.Color := RGBToColor(220, 245, 220);   // lichtgroen: goed
      FUitslag.Lines.Add(Format(T('Goed zo! Je schakeling klopt in alle %d standen van de schakelaars.',
        'Well done! Your circuit is right in all %d positions of the switches.',
        'Bravo ! Votre circuit est juste dans les %d positions des interrupteurs.',
        'Gut gemacht! Ihre Schaltung stimmt in allen %d Stellungen der Schalter.'), [V.Count - 2]));
      if Geheugen then
        FUitslag.Lines.Add(T('(Op het paneel staan onderdelen met een geheugen; probeer het ook zelf in de simulatie.)',
          '(The panel has components with a memory; also try it yourself in the simulation.)',
          '(Le panneau contient des composants avec une mémoire ; essayez aussi vous-même dans la simulation.)',
          '(Auf dem Panel sind Bauteile mit einem Speicher; probieren Sie es auch selbst in der Simulation aus.)'));
    end
    else
    begin
      FUitslag.Lines.Add(T('Nog niet helemaal goed:', 'Not quite right yet:',
        'Pas encore tout à fait juste :', 'Noch nicht ganz richtig:'));
      for i := 0 to Fout.Count - 1 do
        if i < MaxFout then
          FUitslag.Lines.Add('- ' + Fout[i]);
      if Fout.Count > MaxFout then
        FUitslag.Lines.Add('...');
      FUitslag.Lines.Add('');
      FUitslag.Lines.Add(T('Tip: open de waarheidstabel en zet de simulatie aan om te zien wat je schakeling doet.',
        'Tip: open the truth table and switch the simulation on to see what your circuit does.',
        'Astuce : ouvrez la table de vérité et lancez la simulation pour voir ce que fait votre circuit.',
        'Tipp: Öffnen Sie die Wahrheitstabelle und schalten Sie die Simulation ein, um zu sehen, was Ihre Schaltung tut.'));
    end;
  finally
    Fout.Free;
    Verb.Free;
    V.Free;
    Rijen.Free;
    Outs.Free;
    Ins.Free;
  end;
end;

end.
