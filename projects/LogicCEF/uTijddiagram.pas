unit uTijddiagram;

{ Tijddiagram-venster (zoals een logic analyzer): tijdens de simulatie kijkt
  Logic tien keer per seconde naar de ingangen en uitgangen van het paneel
  en tekent ze als lijnen in de tijd: hoog = aan (1), laag = uit (0).
  De namen zijn dezelfde als in de waarheidstabel: A, B, C ... voor de
  schakelaars, drukknoppen en sensoren (van boven naar onder), P1, P2 ...
  voor de pulsgevers, L1 ... lampen, Z1 ... zoemers, R1 ... relais,
  M1 ... motoren (L/R) en D1 ... displays (cijfer).
  Gewoon LCL-venster, zonder .lfm, zodat het ook onder Linux werkt. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, StdCtrls, ExtCtrls,
  janSimLogic, uLangPo;

type
  TTijdForm = class(TForm)
  private
    FBox: TjanSimLogicBox;
    FTaal: string;
    FInfo: TLabel;
    FKnoppen: TPanel;
    BtPauze, BtWis, BtSluit: TButton;
    FSchuif: TScrollBar;
    FBeeld: TPaintBox;
    FTimer: TTimer;
    FSig: TList;              // de onderdelen, in de volgorde van de lijnen
    FNamen: TStringList;      // A, B, P1, L1 ...
    FNIn: Integer;            // aantal ingangen (eerste lijnen)
    FData: TStringList;       // één string per meting, één teken per lijn
    FWeg: Integer;            // aantal metingen dat al vooraan wegviel
    FVorm: string;
    FPauze: Boolean;
    FLoopt: Boolean;
    function T(const NL, EN, FR, DE: string): string;
    procedure FillTexts;
    procedure ZetInfo;
    procedure Signalen;
    function Waarde(C: TControl): Char;
    procedure Meet;
    procedure PasSchuifAan;
    procedure BtPauzeClick(Sender: TObject);
    procedure BtWisClick(Sender: TObject);
    procedure BtSluitClick(Sender: TObject);
    procedure SchuifChange(Sender: TObject);
    procedure TimerTick(Sender: TObject);
    procedure BeeldPaint(Sender: TObject);
    procedure SetLoopt(AValue: Boolean);
  public
    constructor CreateFor(AOwner: TComponent; ABox: TjanSimLogicBox);
    destructor Destroy; override;
    procedure SetTaal(const ATaal: string);
    procedure Wis;
    // True zolang de simulatie aan staat (gezet door het hoofdvenster)
    property Loopt: Boolean read FLoopt write SetLoopt;
  end;

implementation

const
  Interval = 100;       // ms tussen twee metingen
  PerSeconde = 1000 div Interval;
  Px = 4;               // pixels per meting (40 pixels = 1 seconde)
  MaxMetingen = 3000;   // 5 minuten
  Marge = 44;           // plaats voor de namen links
  RijH = 30;            // hoogte van één lijn
  Boven = 6;
  Onder = 22;

constructor TTijdForm.CreateFor(AOwner: TComponent; ABox: TjanSimLogicBox);
begin
  inherited CreateNew(AOwner);
  FBox := ABox;
  FTaal := 'NL';
  FSig := TList.Create;
  FNamen := TStringList.Create;
  FData := TStringList.Create;
  BorderStyle := bsSizeToolWin;
  FormStyle := fsStayOnTop;
  Width := 680;
  Height := 360;
  Position := poDesigned;
  DoubleBuffered := True;   // niet flikkeren bij het hertekenen

  FInfo := TLabel.Create(Self);
  FInfo.Parent := Self;
  FInfo.Align := alTop;
  FInfo.WordWrap := True;
  FInfo.AutoSize := True;
  FInfo.BorderSpacing.Around := 8;

  FKnoppen := TPanel.Create(Self);
  FKnoppen.Parent := Self;
  FKnoppen.Align := alBottom;
  FKnoppen.Height := 40;
  FKnoppen.BevelOuter := bvNone;

  BtPauze := TButton.Create(Self);
  BtPauze.Parent := FKnoppen;
  BtPauze.SetBounds(8, 7, 120, 26);
  BtPauze.OnClick := @BtPauzeClick;
  BtWis := TButton.Create(Self);
  BtWis.Parent := FKnoppen;
  BtWis.SetBounds(136, 7, 120, 26);
  BtWis.OnClick := @BtWisClick;
  BtSluit := TButton.Create(Self);
  BtSluit.Parent := FKnoppen;
  BtSluit.SetBounds(264, 7, 120, 26);
  BtSluit.OnClick := @BtSluitClick;
  BtSluit.Cancel := True;

  FSchuif := TScrollBar.Create(Self);
  FSchuif.Parent := Self;
  FSchuif.Kind := sbHorizontal;
  FSchuif.Align := alBottom;
  FSchuif.BorderSpacing.Left := 8;
  FSchuif.BorderSpacing.Right := 8;
  FSchuif.Min := 0;
  FSchuif.Max := 0;
  FSchuif.OnChange := @SchuifChange;

  FBeeld := TPaintBox.Create(Self);
  FBeeld.Parent := Self;
  FBeeld.Align := alClient;
  FBeeld.BorderSpacing.Around := 8;
  FBeeld.OnPaint := @BeeldPaint;

  FTimer := TTimer.Create(Self);
  FTimer.Interval := Interval;
  FTimer.OnTimer := @TimerTick;
  FTimer.Enabled := True;

  FillTexts;
end;

destructor TTijdForm.Destroy;
begin
  FTimer.Enabled := False;
  FData.Free;
  FNamen.Free;
  FSig.Free;
  inherited Destroy;
end;

function TTijdForm.T(const NL, EN, FR, DE: string): string;
begin
  if FTaal = 'ENG' then Result := PoTr(EN)   // of een extra taal (uLangPo)
  else if FTaal = 'FR' then Result := FR
  else if FTaal = 'DU' then Result := DE
  else Result := NL;
end;

procedure TTijdForm.SetTaal(const ATaal: string);
begin
  FTaal := ATaal;
  FillTexts;
  if FSig.Count > 0 then
  begin
    FVorm := '';      // namen opnieuw (Z/B/S voor de zoemer)
    Signalen;
  end;
  FBeeld.Invalidate;
end;

procedure TTijdForm.FillTexts;
begin
  Caption := T('Tijddiagram', 'Timing diagram', 'Chronogramme', 'Zeitdiagramm');
  if FPauze then
    BtPauze.Caption := T('Verder', 'Continue', 'Continuer', 'Weiter')
  else
    BtPauze.Caption := T('Pauze', 'Pause', 'Pause', 'Pause');
  BtWis.Caption := T('Wissen', 'Clear', 'Effacer', 'Löschen');
  BtSluit.Caption := T('Sluiten', 'Close', 'Fermer', 'Schließen');
  ZetInfo;
end;

procedure TTijdForm.ZetInfo;
var
  S: string;
begin
  if FSig.Count = 0 then
    S := T('Er staan geen ingangen of uitgangen op het paneel.',
           'There are no inputs or outputs on the panel.',
           'Il n''y a ni entrée ni sortie sur le panneau.',
           'Auf dem Panel sind keine Eingänge und keine Ausgänge.')
  else if (FData.Count = 0) and not FLoopt then
    S := T('Zet de simulatie aan en bedien de schakelaars: het tijddiagram tekent hoe de ingangen en uitgangen veranderen in de tijd.',
           'Switch the simulation on and operate the switches: the timing diagram draws how the inputs and outputs change over time.',
           'Lancez la simulation et manœuvrez les interrupteurs : le chronogramme dessine comment les entrées et les sorties changent dans le temps.',
           'Schalten Sie die Simulation ein und bedienen Sie die Schalter: Das Zeitdiagramm zeichnet, wie sich die Eingänge und Ausgänge mit der Zeit ändern.')
  else
    S := T('Elke lijn is een ingang of uitgang: hoog = aan (1), laag = uit (0). Eén vakje is één seconde. Met Pauze zet je het beeld stil en kun je terugschuiven.',
           'Each line is an input or output: high = on (1), low = off (0). One box is one second. With Pause you freeze the picture and can scroll back.',
           'Chaque ligne est une entrée ou une sortie : haut = allumé (1), bas = éteint (0). Une case vaut une seconde. Avec Pause, vous figez l''image et pouvez revenir en arrière.',
           'Jede Linie ist ein Eingang oder Ausgang: hoch = an (1), tief = aus (0). Ein Kästchen ist eine Sekunde. Mit Pause halten Sie das Bild an und können zurückschieben.');
  FInfo.Caption := S;
end;

procedure TTijdForm.SetLoopt(AValue: Boolean);
begin
  if FLoopt = AValue then Exit;
  FLoopt := AValue;
  ZetInfo;
end;

// de ingangen en uitgangen van het paneel, zoals in de waarheidstabel
procedure TTijdForm.Signalen;
var
  wc: TWinControl;
  c: TControl;
  Ins, Puls, Outs: TList;
  i, NL, NZ, NR, NM, ND: Integer;
  S: string;

  procedure Sorteer(L: TList);
  var a, b: Integer; t: Pointer;
  begin
    for a := 1 to L.Count - 1 do
    begin
      b := a;
      while (b > 0) and
        ((TControl(L[b - 1]).Top > TControl(L[b]).Top) or
         ((TControl(L[b - 1]).Top = TControl(L[b]).Top) and
          (TControl(L[b - 1]).Left > TControl(L[b]).Left))) do
      begin
        t := L[b - 1]; L[b - 1] := L[b]; L[b] := t;
        Dec(b);
      end;
    end;
  end;

begin
  FVorm := FBox.Paneelvorm;
  FSig.Clear;
  FNamen.Clear;
  FData.Clear;
  FWeg := 0;
  FNIn := 0;
  wc := FBox.Parent;
  if wc <> nil then
  begin
    Ins := TList.Create;
    Puls := TList.Create;
    Outs := TList.Create;
    try
      for i := 0 to wc.ControlCount - 1 do
      begin
        c := wc.Controls[i];
        if not c.Visible then Continue;
        if TjanSimLogicBox.IsInvoer(c) then Ins.Add(c)
        else if c is TjanSimPuls then Puls.Add(c)
        else if TjanSimLogicBox.IsUitvoer(c) then Outs.Add(c);
      end;
      Sorteer(Ins);
      Sorteer(Puls);
      Sorteer(Outs);
      for i := 0 to Ins.Count - 1 do
      begin
        FSig.Add(Ins[i]);
        if i < 26 then FNamen.Add(Chr(Ord('A') + i)) else FNamen.Add('I' + IntToStr(i + 1));
      end;
      for i := 0 to Puls.Count - 1 do
      begin
        FSig.Add(Puls[i]);
        FNamen.Add('P' + IntToStr(i + 1));
      end;
      FNIn := FSig.Count;
      NL := 0; NZ := 0; NR := 0; NM := 0; ND := 0;
      for i := 0 to Outs.Count - 1 do
      begin
        c := TControl(Outs[i]);
        if c is TjanSimBuzzer then
        begin
          Inc(NZ); S := T('Z', 'B', 'B', 'S') + IntToStr(NZ);
        end
        else if c is TjanSimRelais then
        begin
          Inc(NR); S := 'R' + IntToStr(NR);
        end
        else if c is TjanSimMotor then
        begin
          Inc(NM); S := 'M' + IntToStr(NM);
        end
        else if c is TjanDisplay then
        begin
          Inc(ND); S := 'D' + IntToStr(ND);
        end
        else
        begin
          Inc(NL); S := 'L' + IntToStr(NL);
        end;
        FSig.Add(c);
        FNamen.Add(S);
      end;
    finally
      Outs.Free;
      Puls.Free;
      Ins.Free;
    end;
  end;
  PasSchuifAan;
  ZetInfo;
  // venster zo hoog als de lijnen
  i := FInfo.Height + 16 + 24 + FSig.Count * RijH + 20 + FSchuif.Height + FKnoppen.Height;
  if i < 260 then i := 260;
  if i > 700 then i := 700;
  if Height < i then Height := i;
  FBeeld.Invalidate;
end;

function TTijdForm.Waarde(C: TControl): Char;
begin
  if C is TjanSimPuls then
  begin
    if TjanSimPuls(C).Pulsen then Result := '1' else Result := '0';
  end
  else if TjanSimLogicBox.IsInvoer(C) then
  begin
    if TjanSimLogicBox.InvoerAan(C) then Result := '1' else Result := '0';
  end
  else
    Result := TjanSimLogicBox.UitvoerTeken(C);
end;

procedure TTijdForm.Meet;
var
  i: Integer;
  S: string;
begin
  SetLength(S, FSig.Count);
  for i := 0 to FSig.Count - 1 do
    S[i + 1] := Waarde(TControl(FSig[i]));
  FData.Add(S);
  while FData.Count > MaxMetingen do
  begin
    FData.Delete(0);
    Inc(FWeg);
  end;
  if FData.Count = 1 then ZetInfo;
end;

// hoeveel metingen passen er in beeld
function Breedte(PB: TPaintBox): Integer;
begin
  Result := (PB.Width - Marge - 8) div Px;
  if Result < 1 then Result := 1;
end;

procedure TTijdForm.PasSchuifAan;
var
  M: Integer;
begin
  M := FData.Count - Breedte(FBeeld);
  if M < 0 then M := 0;
  FSchuif.OnChange := nil;
  FSchuif.Max := M;
  FSchuif.PageSize := 0;
  FSchuif.LargeChange := PerSeconde * 5;
  FSchuif.SmallChange := PerSeconde;
  if not FPauze then FSchuif.Position := M;
  FSchuif.Enabled := FPauze and (M > 0);
  FSchuif.OnChange := @SchuifChange;
end;

procedure TTijdForm.TimerTick(Sender: TObject);
begin
  if not Visible then Exit;
  // ander paneel of onderdeel erbij/weg: opnieuw beginnen
  if FBox.Paneelvorm <> FVorm then Signalen;
  if FLoopt and not FPauze and (FSig.Count > 0) then
  begin
    Meet;
    PasSchuifAan;
    FBeeld.Invalidate;
  end;
end;

procedure TTijdForm.BeeldPaint(Sender: TObject);
var
  C: TCanvas;
  W, H, Eerste, N, i, k, x, x2, y0, yH, yL, Sec: Integer;
  V, VOud: Char;
  Hoog, HoogOud: Boolean;
  Kl: TColor;
begin
  C := FBeeld.Canvas;
  W := FBeeld.Width;
  H := FBeeld.Height;
  C.Brush.Color := clWhite;
  C.FillRect(0, 0, W, H);
  N := Breedte(FBeeld);
  if FPauze then Eerste := FSchuif.Position
  else
  begin
    Eerste := FData.Count - N;
    if Eerste < 0 then Eerste := 0;
  end;

  // rooster: een lijn per seconde, met de tijd onderaan
  C.Font.Size := 8;
  C.Font.Style := [];
  C.Font.Color := clGray;
  for i := 0 to N do
  begin
    k := FWeg + Eerste + i;
    if (k mod PerSeconde) = 0 then
    begin
      x := Marge + i * Px;
      if (k mod (PerSeconde * 5)) = 0 then C.Pen.Color := $00C0C0C0
      else C.Pen.Color := $00E8E8E8;
      C.MoveTo(x, 0);
      C.LineTo(x, FSig.Count * RijH);
      if (k mod (PerSeconde * 5)) = 0 then
      begin
        Sec := k div PerSeconde;
        C.Brush.Style := bsClear;
        C.TextOut(x - C.TextWidth(IntToStr(Sec)) div 2, FSig.Count * RijH + 4, IntToStr(Sec) + ' s');
        C.Brush.Style := bsSolid;
      end;
    end;
  end;

  for k := 0 to FSig.Count - 1 do
  begin
    y0 := k * RijH;
    yH := y0 + Boven;
    yL := y0 + Onder;
    // scheidingslijn tussen de ingangen en de uitgangen
    if (k = FNIn) and (k > 0) then
    begin
      C.Pen.Color := clGray;
      C.Pen.Width := 2;
      C.MoveTo(0, y0 - 1);
      C.LineTo(W, y0 - 1);
      C.Pen.Width := 1;
    end;
    // naam
    C.Font.Size := 9;
    C.Font.Style := [fsBold];
    C.Font.Color := clBlack;
    C.Brush.Style := bsClear;
    C.TextOut(6, y0 + (RijH - C.TextHeight('A')) div 2 - 1, FNamen[k]);
    C.Brush.Style := bsSolid;
    if k < FNIn then Kl := $00F0C890 else Kl := $0060D060;
    VOud := #0;
    HoogOud := False;
    C.Font.Size := 7;
    C.Font.Style := [];
    for i := 0 to N - 1 do
    begin
      if Eerste + i >= FData.Count then Break;
      V := FData[Eerste + i][k + 1];
      Hoog := (V <> '0') and (V <> '-');
      x := Marge + i * Px;
      x2 := x + Px;
      if Hoog then
      begin
        C.Brush.Color := Kl;
        C.FillRect(x, yH, x2, yL);
      end;
      C.Pen.Color := clNavy;
      C.Pen.Width := 2;
      if (i > 0) and (Hoog <> HoogOud) then
      begin
        C.MoveTo(x, yH);
        C.LineTo(x, yL);
      end;
      if Hoog then
      begin
        C.MoveTo(x, yH); C.LineTo(x2, yH);
      end
      else
      begin
        C.MoveTo(x, yL); C.LineTo(x2, yL);
      end;
      C.Pen.Width := 1;
      // motor (L/R) en display (cijfer): het teken bij elke verandering
      if (V <> VOud) and (V <> '0') and (V <> '1') and (V <> '-') then
      begin
        C.Brush.Style := bsClear;
        C.Font.Color := clBlack;
        C.TextOut(x + 2, yH + 1, V);
        C.Brush.Style := bsSolid;
      end;
      VOud := V;
      HoogOud := Hoog;
    end;
  end;
  C.Brush.Style := bsSolid;
end;

procedure TTijdForm.Wis;
begin
  FData.Clear;
  FWeg := 0;
  PasSchuifAan;
  ZetInfo;
  FBeeld.Invalidate;
end;

procedure TTijdForm.BtPauzeClick(Sender: TObject);
begin
  FPauze := not FPauze;
  FillTexts;
  PasSchuifAan;
  FBeeld.Invalidate;
end;

procedure TTijdForm.BtWisClick(Sender: TObject);
begin
  Wis;
end;

procedure TTijdForm.SchuifChange(Sender: TObject);
begin
  FBeeld.Invalidate;
end;

procedure TTijdForm.BtSluitClick(Sender: TObject);
begin
  Close;
end;

end.
