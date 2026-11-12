unit uWaarheid;

{ Waarheidstabel-venster: Logic zet de schakelaars en drukknoppen van het
  paneel één voor één in elke stand en toont welke lampen en zoemers dan aan
  zijn. De ingangen heten A, B, C ... van boven naar onder (bij dezelfde
  hoogte van links naar rechts), de lampen L1, L2 ... in dezelfde volgorde.
  Het venster volgt het paneel: verandert er iets aan het paneel (onderdeel
  of draad erbij, weg of verplaatst), dan rekent het de tabel vanzelf
  opnieuw uit, en de rij van de huidige stand van de schakelaars krijgt een
  rode rand.
  Gewoon LCL-venster, zonder .lfm, zodat het ook onder Linux werkt. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, StdCtrls, ExtCtrls, Grids,
  Clipbrd, LCLIntf, LCLType, janSimLogic, chatgridpcodeSmall, uLangPo;

type
  TWaarheidForm = class(TForm)
  private
    FGrid: TjanGridS;
    FBox: TjanSimLogicBox;
    FTaal: string;
    FInfo: TLabel;
    FTabel: TStringGrid;
    FKnoppen: TPanel;
    BtOpnieuw, BtKopieer, BtSluit: TButton;
    FTimer: TTimer;
    FIns: TList;            // de schakelaars en drukknoppen (A, B, ...)
    FNIn: Integer;          // aantal ingangen (eerste kolommen)
    FVorm: string;          // vorm van het paneel bij de laatste berekening
    FHuidig: Integer;       // rij van de huidige stand (0 = geen)
    FBezig: Boolean;
    function T(const NL, EN, FR, DE: string): string;
    procedure FillTexts;
    procedure BtOpnieuwClick(Sender: TObject);
    procedure BtKopieerClick(Sender: TObject);
    procedure BtSluitClick(Sender: TObject);
    procedure TimerTick(Sender: TObject);
    procedure ToonHuidig;
    procedure TabelDrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
  public
    constructor CreateFor(AOwner: TComponent; AGrid: TjanGridS; ABox: TjanSimLogicBox);
    destructor Destroy; override;
    procedure SetTaal(const ATaal: string);
    procedure Bereken;
  end;

implementation

const
  MaxIngangen = 6;   // 64 rijen

constructor TWaarheidForm.CreateFor(AOwner: TComponent; AGrid: TjanGridS;
  ABox: TjanSimLogicBox);
begin
  inherited CreateNew(AOwner);
  FGrid := AGrid;
  FBox := ABox;
  FTaal := 'NL';
  FIns := TList.Create;
  BorderStyle := bsSizeToolWin;
  FormStyle := fsStayOnTop;
  Width := 420;
  Height := 480;
  Position := poDesigned;

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

  BtOpnieuw := TButton.Create(Self);
  BtOpnieuw.Parent := FKnoppen;
  BtOpnieuw.SetBounds(8, 7, 120, 26);
  BtOpnieuw.OnClick := @BtOpnieuwClick;
  BtKopieer := TButton.Create(Self);
  BtKopieer.Parent := FKnoppen;
  BtKopieer.SetBounds(136, 7, 120, 26);
  BtKopieer.OnClick := @BtKopieerClick;
  BtSluit := TButton.Create(Self);
  BtSluit.Parent := FKnoppen;
  BtSluit.SetBounds(264, 7, 120, 26);
  BtSluit.OnClick := @BtSluitClick;
  BtSluit.Cancel := True;

  FTabel := TStringGrid.Create(Self);
  FTabel.Parent := Self;
  FTabel.Align := alClient;
  FTabel.BorderSpacing.Around := 8;
  FTabel.FixedCols := 0;
  FTabel.FixedRows := 1;
  FTabel.DefaultColWidth := 44;
  FTabel.DefaultRowHeight := 22;
  FTabel.Options := [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine];
  FTabel.ScrollBars := ssAutoVertical;
  FTabel.OnDrawCell := @TabelDrawCell;

  // het paneel volgen: vorm en stand van de schakelaars
  FTimer := TTimer.Create(Self);
  FTimer.Interval := 250;
  FTimer.OnTimer := @TimerTick;
  FTimer.Enabled := True;

  FillTexts;
end;

destructor TWaarheidForm.Destroy;
begin
  FTimer.Enabled := False;
  FIns.Free;
  inherited Destroy;
end;

function TWaarheidForm.T(const NL, EN, FR, DE: string): string;
begin
  if FTaal = 'ENG' then Result := PoTr(EN)   // of een extra taal (uLangPo)
  else if FTaal = 'FR' then Result := FR
  else if FTaal = 'DU' then Result := DE
  else Result := NL;
end;

procedure TWaarheidForm.SetTaal(const ATaal: string);
begin
  FTaal := ATaal;
  FillTexts;
  if Visible then Bereken;
end;

procedure TWaarheidForm.FillTexts;
begin
  Caption := T('Waarheidstabel', 'Truth table', 'Table de vérité', 'Wahrheitstabelle');
  BtOpnieuw.Caption := T('Opnieuw', 'Again', 'Recalculer', 'Neu');
  BtKopieer.Caption := T('Kopiëren', 'Copy', 'Copier', 'Kopieren');
  BtSluit.Caption := T('Sluiten', 'Close', 'Fermer', 'Schließen');
end;

procedure TWaarheidForm.Bereken;
var
  Ins, Outs: TList;
  Rijen: TStringList;
  Res, i, j, NL, NZ, NR, NM, ND, OudCols, OudRows: Integer;
  O: TObject;
  Geheugen: Boolean;
  S, Uitleg: string;
begin
  if FBezig then Exit;
  FBezig := True;
  Ins := TList.Create;
  Outs := TList.Create;
  Rijen := TStringList.Create;
  try
    FVorm := FBox.Paneelvorm;
    OudCols := FTabel.ColCount;
    OudRows := FTabel.RowCount;
    Res := FBox.Waarheidstabel(Ins, Outs, Rijen, Geheugen, MaxIngangen);
    FNIn := Ins.Count;
    FIns.Clear;
    FHuidig := 0;
    case Res of
      1: Uitleg := T('Er staat geen schakelaar, drukknop of sensor op het paneel.',
                     'There is no switch, push button or sensor on the panel.',
                     'Il n''y a ni interrupteur, ni bouton-poussoir, ni capteur sur le panneau.',
                     'Auf dem Panel ist kein Schalter, Taster oder Sensor.');
      2: Uitleg := T('Er staat geen lamp, zoemer, relais, motor of display op het paneel.',
                     'There is no lamp, buzzer, relay, motor or display on the panel.',
                     'Il n''y a ni lampe, ni buzzer, ni relais, ni moteur, ni afficheur sur le panneau.',
                     'Auf dem Panel ist keine Lampe, kein Summer, kein Relais, kein Motor und keine Anzeige.');
      3: Uitleg := Format(T('Er staan %d ingangen (schakelaars, drukknoppen, sensoren) op het paneel; de tabel kan er hoogstens %d aan.',
                            'There are %d inputs (switches, push buttons, sensors) on the panel; the table can handle at most %d.',
                            'Il y a %d entrées (interrupteurs, boutons-poussoirs, capteurs) sur le panneau ; la table en accepte au plus %d.',
                            'Auf dem Panel sind %d Eingänge (Schalter, Taster, Sensoren); die Tabelle schafft höchstens %d.'),
                          [Ins.Count, MaxIngangen]);
    else
      Uitleg := T('Elke rij is een stand van de ingangen (schakelaars, drukknoppen, sensoren): A is de bovenste, B de volgende, ... Rechts staat of de uitgangen aan zijn (1) of uit (0): L = lamp of LED (L1 = de bovenste), Z = zoemer, R = relais. Een motor (M) draait L (linksom) of R (rechtsom), een display (D) toont zijn cijfer.',
                  'Each row is a position of the inputs (switches, push buttons, sensors): A is the top one, B the next, ... On the right you see whether the outputs are on (1) or off (0): L = lamp or LED (L1 = the top one), B = buzzer, R = relay. A motor (M) turns L (anticlockwise) or R (clockwise), a display (D) shows its digit.',
                  'Chaque ligne est une position des entrées (interrupteurs, boutons-poussoirs, capteurs) : A est celle du haut, B la suivante, ... À droite, vous voyez si les sorties sont actives (1) ou non (0) : L = lampe ou LED (L1 = celle du haut), B = buzzer, R = relais. Un moteur (M) tourne L (à gauche) ou R (à droite), un afficheur (D) montre son chiffre.',
                  'Jede Zeile ist eine Stellung der Eingänge (Schalter, Taster, Sensoren): A ist der oberste, B der nächste, ... Rechts sehen Sie, ob die Ausgänge an (1) oder aus (0) sind: L = Lampe oder LED (L1 = die oberste), S = Summer, R = Relais. Ein Motor (M) dreht L (links herum) oder R (rechts herum), eine Anzeige (D) zeigt ihre Ziffer.')
        + ' ' +
        T('De rij met de rode rand is de stand van nu: zet een schakelaar om en kijk hoe ze verspringt.',
          'The row with the red border is the current position: flip a switch and watch it move.',
          'La ligne avec le bord rouge est la position actuelle : basculez un interrupteur et regardez-la changer.',
          'Die Zeile mit dem roten Rand ist die jetzige Stellung: Legen Sie einen Schalter um und sehen Sie, wie sie wechselt.');
      if Geheugen then
        Uitleg := Uitleg + LineEnding + LineEnding +
          T('Let op: op het paneel staan onderdelen met een geheugen (flipflop, teller, ...). Daar hangt de uitgang ook af van wat er vroeger gebeurde; de tabel geldt dan niet altijd.',
            'Note: the panel has components with a memory (flip-flop, counter, ...). Their output also depends on what happened before, so the table does not always apply.',
            'Attention : le panneau contient des composants avec une mémoire (bascule, compteur, ...). Leur sortie dépend aussi de ce qui s''est passé avant ; la table ne vaut donc pas toujours.',
            'Achtung: Auf dem Panel sind Bauteile mit einem Speicher (Flipflop, Zähler, ...). Deren Ausgang hängt auch davon ab, was vorher geschah; die Tabelle gilt dann nicht immer.');
    end;
    FInfo.Caption := Uitleg;

    if Res <> 0 then
    begin
      FTabel.ColCount := 1;
      FTabel.RowCount := 1;
      FTabel.Cells[0, 0] := '';
      Exit;
    end;

    for i := 0 to Ins.Count - 1 do FIns.Add(Ins[i]);
    FTabel.ColCount := Ins.Count + Outs.Count;
    FTabel.RowCount := Rijen.Count + 1;
    for i := 0 to Ins.Count - 1 do
      FTabel.Cells[i, 0] := Chr(Ord('A') + i);
    NL := 0; NZ := 0; NR := 0; NM := 0; ND := 0;
    for j := 0 to Outs.Count - 1 do
    begin
      O := TObject(Outs[j]);
      if O is TjanSimBuzzer then
      begin
        Inc(NZ);
        S := T('Z', 'B', 'B', 'S') + IntToStr(NZ);
      end
      else if O is TjanSimRelais then
      begin
        Inc(NR);
        S := 'R' + IntToStr(NR);
      end
      else if O is TjanSimMotor then
      begin
        Inc(NM);
        S := 'M' + IntToStr(NM);
      end
      else if O is TjanDisplay then
      begin
        Inc(ND);
        S := 'D' + IntToStr(ND);
      end
      else
      begin
        Inc(NL);
        S := 'L' + IntToStr(NL);
      end;
      FTabel.Cells[Ins.Count + j, 0] := S;
    end;
    for i := 0 to Rijen.Count - 1 do
      for j := 1 to Length(Rijen[i]) do
        FTabel.Cells[j - 1, i + 1] := Rijen[i][j];
    // het venster alleen aanpassen als de tabel een andere grootte kreeg
    // (anders blijft de grootte die de gebruiker koos)
    if (OudCols <> FTabel.ColCount) or (OudRows <> FTabel.RowCount) then
    begin
      // zo breed als de tabel (met plaats voor de schuifbalk)
      i := FTabel.ColCount * (FTabel.DefaultColWidth + 1) + 40;
      if i < 420 then i := 420;
      Width := i;
      // en zo hoog als de rijen (met de uitleg en de knoppen erbij)
      i := 170 + FTabel.RowCount * (FTabel.DefaultRowHeight + 1);
      if Geheugen then Inc(i, 60);
      if i < 280 then i := 280;
      if i > 640 then i := 640;
      Height := i;
    end;
  finally
    Rijen.Free;
    Outs.Free;
    Ins.Free;
    FBezig := False;
  end;
  ToonHuidig;
  FTabel.Invalidate;
end;

// welke rij hoort bij de huidige stand van de schakelaars en drukknoppen
procedure TWaarheidForm.ToonHuidig;
var
  i, k, Rij: Integer;
  C: TControl;
  D: Boolean;
begin
  Rij := 0;
  if (FIns.Count > 0) and (FTabel.RowCount = (1 shl FIns.Count) + 1) then
  begin
    k := 0;
    for i := 0 to FIns.Count - 1 do
    begin
      C := TControl(FIns[i]);
      D := TjanSimLogicBox.InvoerAan(C);
      k := k * 2;
      if D then Inc(k);
    end;
    Rij := k + 1;
  end;
  if Rij = FHuidig then Exit;
  FHuidig := Rij;
  // de rij in beeld brengen
  if Rij > 0 then
  begin
    if Rij < FTabel.TopRow then
      FTabel.TopRow := Rij
    else if Rij >= FTabel.TopRow + FTabel.VisibleRowCount then
      FTabel.TopRow := Rij - FTabel.VisibleRowCount + 1;
  end;
  FTabel.Invalidate;
end;

procedure TWaarheidForm.TimerTick(Sender: TObject);
begin
  if (not Visible) or FBezig then Exit;
  // een object aan de muis of de muisknop ingedrukt (slepen): nog niet
  // opnieuw rekenen. De rij van nu wel volgen (een drukknop is alleen
  // ingedrukt zolang de muisknop ingedrukt is).
  if (not FBox.NewObject) and (GetKeyState(VK_LBUTTON) >= 0) and
     (FBox.Paneelvorm <> FVorm) then
    Bereken
  else
    ToonHuidig;
end;

procedure TWaarheidForm.TabelDrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
var
  C: TCanvas;
  S: string;
  W: Integer;
  Nu: Boolean;
begin
  C := FTabel.Canvas;
  S := FTabel.Cells[aCol, aRow];
  Nu := (aRow > 0) and (aRow = FHuidig);
  // ingangen lichtblauw, uitgangen lichtgeel; een 1 bij een uitgang groen.
  // De rij van de huidige stand is wat feller.
  if aRow = 0 then
    C.Brush.Color := clBtnFace
  else if aCol < FNIn then
  begin
    if Nu then C.Brush.Color := $00F0C890 else C.Brush.Color := $00F5E6D8;
  end
  else if (S <> '0') and (S <> '-') and (S <> '') then
  begin
    if Nu then C.Brush.Color := $0040D040 else C.Brush.Color := $0090EE90;
  end
  else
  begin
    if Nu then C.Brush.Color := $0090E8F8 else C.Brush.Color := $00D8F5FA;
  end;
  C.FillRect(aRect);
  C.Font.Color := clBlack;
  if (aRow = 0) or ((aCol >= FNIn) and (S <> '0') and (S <> '-')) or Nu then C.Font.Style := [fsBold] else C.Font.Style := [];
  // een dikkere lijn tussen de ingangen en de uitgangen
  if (aCol = FNIn) and (FNIn > 0) then
  begin
    C.Pen.Color := clGray;
    C.Pen.Width := 2;
    C.MoveTo(aRect.Left + 1, aRect.Top);
    C.LineTo(aRect.Left + 1, aRect.Bottom);
    C.Pen.Width := 1;
  end;
  // rode rand rond de rij van de huidige stand
  if Nu then
  begin
    C.Pen.Color := clRed;
    C.Pen.Width := 2;
    C.MoveTo(aRect.Left, aRect.Top + 1);
    C.LineTo(aRect.Right, aRect.Top + 1);
    C.MoveTo(aRect.Left, aRect.Bottom - 1);
    C.LineTo(aRect.Right, aRect.Bottom - 1);
    if aCol = 0 then
    begin
      C.MoveTo(aRect.Left + 1, aRect.Top);
      C.LineTo(aRect.Left + 1, aRect.Bottom);
    end;
    if aCol = FTabel.ColCount - 1 then
    begin
      C.MoveTo(aRect.Right - 1, aRect.Top);
      C.LineTo(aRect.Right - 1, aRect.Bottom);
    end;
    C.Pen.Width := 1;
  end;
  W := C.TextWidth(S);
  C.Brush.Style := bsClear;
  C.TextOut(aRect.Left + (aRect.Right - aRect.Left - W) div 2,
    aRect.Top + (aRect.Bottom - aRect.Top - C.TextHeight(S)) div 2, S);
  C.Brush.Style := bsSolid;
end;

procedure TWaarheidForm.BtOpnieuwClick(Sender: TObject);
begin
  Bereken;
end;

procedure TWaarheidForm.BtKopieerClick(Sender: TObject);
var
  L: TStringList;
  r, k: Integer;
  S: string;
begin
  L := TStringList.Create;
  try
    for r := 0 to FTabel.RowCount - 1 do
    begin
      S := '';
      for k := 0 to FTabel.ColCount - 1 do
      begin
        if k > 0 then S := S + #9;
        S := S + FTabel.Cells[k, r];
      end;
      L.Add(S);
    end;
    Clipboard.AsText := L.Text;
  finally
    L.Free;
  end;
end;

procedure TWaarheidForm.BtSluitClick(Sender: TObject);
begin
  Close;
end;

end.
