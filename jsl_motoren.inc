// janSimLogic.pas, deel: stappenmotor, servomotor en ventilator (ingevoegd met {$I jsl_motoren.inc})

{ TjanStappenmotor }

const
  StapW = 236;
  StapH = 128;
  StapCX = 86;                 // midden van de motor (vooraanzicht)
  StapCY = 64;
  StapDX = 192;                // midden van de wijzerplaat van de as
  StapDY = 34;
  StapDrempel = 0.020;         // A: vanaf hier trekt een spoel
  StapPerToer: array[0..2] of Integer = (4, 48, 200);
  StapStandaard = 1;           // 48 stappen per omwenteling

constructor TjanStappenmotor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := StapW;
  Height := StapH;
  HelpKeyword := 'stappenmotor';
  FStapIdx := StapStandaard;
  FRichting := 0;
  FTimer := TTimer.Create(Self);
  FTimer.Interval := 40;
  FTimer.OnTimer := Tik;
  FTimer.Enabled := True;
end;

function TjanStappenmotor.PinCount: Integer;
begin
  Result := 5;
end;

// A, B, C, D links onder elkaar, de gemeenschappelijke klem linksonder
function TjanStappenmotor.PinPos(I: Integer): TPoint;
begin
  if I < 4 then Result := Point(1, 10 + I * 24)
  else Result := Point(1, StapH - 16);
end;

function TjanStappenmotor.SpoelOhm: Double;
begin
  Result := 100;
end;

function TjanStappenmotor.SpoelStroom(I: Integer): Double;
begin
  Result := (FPinV[I] - FPinV[4]) / SpoelOhm;
end;

function TjanStappenmotor.SpoelAan(I: Integer): Boolean;
begin
  Result := Abs(SpoelStroom(I)) >= StapDrempel;
end;

function TjanStappenmotor.StappenPerToer: Integer;
begin
  Result := StapPerToer[FStapIdx];
end;

function TjanStappenmotor.Stappen: Double;
begin
  Result := FPos / 2;
end;

function TjanStappenmotor.Hoek: Double;
begin
  Result := Stappen * 360 / StappenPerToer;
end;

procedure TjanStappenmotor.NulZetten;
begin
  FPos := 0;
  FToon := 0;
  FRichting := 0;
  UpdateHintText;
  Invalidate;
end;

procedure TjanStappenmotor.SetStapIdx(const Value: Integer);
begin
  if (Value < Low(StapPerToer)) or (Value > High(StapPerToer)) or (Value = FStapIdx) then Exit;
  FStapIdx := Value;
  UpdateHintText;
  Invalidate;
end;

procedure TjanStappenmotor.StapClick(Sender: TObject);
begin
  if not FLock then StapIdx := TMenuItem(Sender).Tag;
end;

procedure TjanStappenmotor.NulClick(Sender: TObject);
begin
  if not FLock then NulZetten;
end;

procedure TjanStappenmotor.AddMenuItems(APop: TPopupMenu);
var
  Mi, Sub: TMenuItem;
  i: Integer;
begin
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Stappen per omwenteling', 'Steps per revolution', 'Pas par tour', 'Schritte pro Umdrehung');
  APop.Items.Add(Mi);
  for i := Low(StapPerToer) to High(StapPerToer) do
  begin
    Sub := TMenuItem.Create(APop);
    Sub.Caption := Format('%d (%s°)', [StapPerToer[i], FormatFloat('0.#', 360 / StapPerToer[i])]);
    Sub.Tag := i;
    Sub.RadioItem := True;
    Sub.Checked := i = FStapIdx;
    Sub.Enabled := not FLock;
    Sub.OnClick := StapClick;
    Mi.Add(Sub);
  end;
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Teller en as op nul', 'Reset counter and shaft', 'Remettre compteur et axe à zéro',
    'Zähler und Achse auf null');
  Mi.Enabled := not FLock;
  Mi.OnClick := NulClick;
  APop.Items.Add(Mi);
end;

// welke stand (in halve stappen, 0..7) vragen de spoelen? -1 = geen spoel,
// -2 = tegen elkaar in (twee spoelen tegenover elkaar, of alle vier)
function StapDoel(M: Integer): Integer;
begin
  case M of
    1: Result := 0;            // A
    3: Result := 1;            // A+B
    2: Result := 2;            // B
    6: Result := 3;            // B+C
    4: Result := 4;            // C
    12: Result := 5;           // C+D
    8: Result := 6;            // D
    9: Result := 7;            // D+A
    7: Result := 2;            // A+B+C: B in het midden
    14: Result := 4;           // B+C+D
    13: Result := 6;           // C+D+A
    11: Result := 0;           // D+A+B
    0: Result := -1;
  else
    Result := -2;              // A+C, B+D of alle vier
  end;
end;

procedure TjanStappenmotor.Tik(Sender: TObject);
var
  M, i, D, Hier: Integer;
  Oud: Boolean;
begin
  if (Parent = nil) or not Visible then Exit;
  M := 0;
  for i := 0 to 3 do
    if SpoelAan(i) then M := M or (1 shl i);
  Oud := FTrilt;
  D := StapDoel(M);
  FTrilt := D = -2;
  if D >= 0 then
  begin
    Hier := ((FPos mod 8) + 8) mod 8;
    D := D - Hier;
    if D > 4 then D := D - 8;
    if D < -3 then D := D + 8;
    // de rotor springt naar de spoel die trekt; staat die er recht
    // tegenover (of anderhalve stap ver), dan weet hij niet waarheen
    if (D <> 0) and (Abs(D) <= 2) then
    begin
      FPos := FPos + D;
      if D > 0 then FRichting := 1 else FRichting := -1;
      UpdateHintText;
    end
    else if Abs(D) > 2 then
      FTrilt := True;
  end;
  if (M <> FMasker) or (Oud <> FTrilt) then
  begin
    FMasker := M;
    Invalidate;
  end;
  // de tekening loopt de stand na
  if Abs(FToon - FPos) > 0.01 then
  begin
    FToon := FToon + (FPos - FToon) * 0.45;
    if Abs(FToon - FPos) < 0.03 then FToon := FPos;
    Invalidate;
  end;
end;

procedure TjanStappenmotor.Paint;
const
  Letters: array[0..3] of string = ('A', 'B', 'C', 'D');
var
  i, X, Y, PX, PY, Tw: Integer;
  A, S, C: Double;
  Aan: Boolean;
  T: string;
begin
  with Canvas do
  begin
    Pen.Style := psSolid;
    Pen.Width := 1;
    Font.Name := 'Arial';
    Font.Size := 8;
    Font.Style := [fsBold];
    Brush.Style := bsClear;
    // letters bij de klemmen
    for i := 0 to 3 do
    begin
      if SpoelAan(i) then Font.Color := RGBToColor(220, 50, 20) else Font.Color := clBlack;
      TextOut(PinPos(i).X + 10, PinPos(i).Y - 3, Letters[i]);
    end;
    Font.Color := clBlack;
    TextOut(PinPos(4).X + 10, PinPos(4).Y - 4, '-');
    // het huis (stator)
    Brush.Style := bsSolid;
    Brush.Color := RGBToColor(205, 205, 210);
    Pen.Color := RGBToColor(90, 90, 100);
    Ellipse(StapCX - 50, StapCY - 50, StapCX + 51, StapCY + 51);
    Brush.Color := RGBToColor(245, 245, 245);
    Ellipse(StapCX - 26, StapCY - 26, StapCX + 27, StapCY + 27);
    // de vier spoelen: A boven, B rechts, C onder, D links
    for i := 0 to 3 do
    begin
      A := i * Pi / 2;
      S := Sin(A); C := Cos(A);
      X := StapCX + Round(38 * S);
      Y := StapCY - Round(38 * C);
      Aan := SpoelAan(i);
      if Aan then Brush.Color := RGBToColor(235, 70, 30) else Brush.Color := RGBToColor(200, 140, 80);
      Pen.Color := RGBToColor(110, 60, 20);
      if (i = 0) or (i = 2) then
        Rectangle(X - 11, Y - 8, X + 12, Y + 9)
      else
        Rectangle(X - 8, Y - 11, X + 9, Y + 12);
      // wikkelingen
      Pen.Color := RGBToColor(120, 70, 25);
      if (i = 0) or (i = 2) then
      begin
        MoveTo(X - 6, Y - 7); LineTo(X - 6, Y + 8);
        MoveTo(X, Y - 7); LineTo(X, Y + 8);
        MoveTo(X + 6, Y - 7); LineTo(X + 6, Y + 8);
      end
      else
      begin
        MoveTo(X - 7, Y - 6); LineTo(X + 8, Y - 6);
        MoveTo(X - 7, Y); LineTo(X + 8, Y);
        MoveTo(X - 7, Y + 6); LineTo(X + 8, Y + 6);
      end;
      // letter in de spoel
      Brush.Style := bsClear;
      Font.Size := 7;
      if Aan then Font.Color := clWhite else Font.Color := RGBToColor(60, 30, 10);
      TextOut(X - TextWidth(Letters[i]) div 2, Y - TextHeight(Letters[i]) div 2, Letters[i]);
      Brush.Style := bsSolid;
    end;
    // de rotor: een magneetje, de noordpool (rood) wijst naar de stand
    A := FToon * Pi / 4;
    S := Sin(A); C := Cos(A);
    PX := Round(19 * S); PY := Round(19 * C);
    Pen.Width := 9;
    Pen.Color := RGBToColor(215, 40, 40);
    MoveTo(StapCX, StapCY); LineTo(StapCX + PX, StapCY - PY);
    Pen.Color := RGBToColor(40, 90, 200);
    MoveTo(StapCX, StapCY); LineTo(StapCX - PX, StapCY + PY);
    Pen.Width := 1;
    Pen.Color := clBlack;
    Brush.Color := RGBToColor(80, 80, 80);
    Ellipse(StapCX - 3, StapCY - 3, StapCX + 4, StapCY + 4);
    Brush.Style := bsClear;
    Font.Size := 7;
    Font.Color := clWhite;
    TextOut(StapCX + Round(13 * S) - 3, StapCY - Round(13 * C) - 6, 'N');
    if FTrilt then
    begin
      Font.Size := 12;
      Font.Color := clRed;
      TextOut(StapCX + 30, StapCY + 22, '!');
    end;
    // de as met een wijzer
    Brush.Style := bsSolid;
    Brush.Color := clWhite;
    Pen.Color := RGBToColor(90, 90, 100);
    Ellipse(StapDX - 24, StapDY - 24, StapDX + 25, StapDY + 25);
    for i := 0 to 11 do
    begin
      A := i * Pi / 6;
      if i mod 3 = 0 then X := 18 else X := 21;
      MoveTo(StapDX + Round(X * Sin(A)), StapDY - Round(X * Cos(A)));
      LineTo(StapDX + Round(23 * Sin(A)), StapDY - Round(23 * Cos(A)));
    end;
    A := FToon / 2 * 2 * Pi / StappenPerToer;
    Pen.Color := RGBToColor(200, 0, 0);
    Pen.Width := 3;
    MoveTo(StapDX, StapDY);
    LineTo(StapDX + Round(19 * Sin(A)), StapDY - Round(19 * Cos(A)));
    Pen.Width := 1;
    Pen.Color := clBlack;
    Brush.Color := RGBToColor(60, 60, 60);
    Ellipse(StapDX - 3, StapDY - 3, StapDX + 4, StapDY + 4);
    // hoek, stappen en richting
    Brush.Style := bsClear;
    Font.Size := 7;
    Font.Style := [];
    Font.Color := RGBToColor(40, 40, 40);
    T := Tr(FTaal, 'Hoek', 'Angle', 'Angle', 'Winkel') + ': ' + FormatFloat('0.#', Hoek) + '°';
    Tw := TextWidth(T);
    TextOut(StapDX - Tw div 2, 64, T);
    T := Tr(FTaal, 'Stappen', 'Steps', 'Pas', 'Schritte') + ': ' + FormatFloat('0.#', Stappen);
    TextOut(StapDX - TextWidth(T) div 2, 78, T);
    if FTrilt then
      T := Tr(FTaal, 'tegenover elkaar!', 'opposite coils!', 'bobines opposées !', 'gegenüber!')
    else if FRichting > 0 then
      T := Tr(FTaal, 'rechtsom', 'clockwise', 'sens horaire', 'rechtsherum')
    else if FRichting < 0 then
      T := Tr(FTaal, 'linksom', 'anticlockwise', 'sens antihoraire', 'linksherum')
    else
      T := '';
    if FTrilt then Font.Color := clRed;
    TextOut(StapDX - TextWidth(T) div 2, 92, T);
    Font.Color := RGBToColor(90, 90, 90);
    T := Format(Tr(FTaal, '%d stappen/omw', '%d steps/rev', '%d pas/tour', '%d Schritte/U'), [StappenPerToer]);
    TextOut(StapDX - TextWidth(T) div 2, 108, T);
  end;
  for i := 0 to 4 do
    PaintPin(PinPos(i).X, PinPos(i).Y, FPinV[i] >= RailMinVolt);
  PaintSelection;
end;

procedure TjanStappenmotor.UpdateHintText;
var
  S: string;
begin
  if FTrilt then
    S := Tr(FTaal, 'Twee spoelen tegenover elkaar trekken tegelijk: de rotor weet niet waarheen en blijft staan.',
      'Two opposite coils pull at the same time: the rotor does not know where to go and stays put.',
      'Deux bobines opposées tirent en même temps : le rotor ne sait pas où aller et reste sur place.',
      'Zwei gegenüberliegende Spulen ziehen gleichzeitig: Der Rotor weiß nicht, wohin, und bleibt stehen.')
  else
    S := Format(Tr(FTaal, 'Stappen: %s   hoek van de as: %s°', 'Steps: %s   shaft angle: %s°',
      'Pas : %s   angle de l''axe : %s°', 'Schritte: %s   Winkel der Achse: %s°'),
      [FormatFloat('0.#', Stappen), FormatFloat('0.#', Hoek)]);
  Hint := Tr(FTaal, 'Stappenmotor', 'Stepper motor', 'Moteur pas à pas', 'Schrittmotor') +
    Format(' (%d ', [StappenPerToer]) + Tr(FTaal, 'stappen per omwenteling)', 'steps per revolution)',
      'pas par tour)', 'Schritte pro Umdrehung)') + #13#10 + S + #13#10 +
    Tr(FTaal,
      'Vier spoelen A, B, C, D (elk 100 ohm) naar de gemeenschappelijke klem - (naar de - rail).' + #13#10 +
        'Een spoel trekt vanaf 20 mA, ook aan de uitgang van een poort. A, B, C, D na elkaar: rechtsom; D, C, B, A: linksom.' + #13#10 +
        'Rechtsklik: stappen per omwenteling, teller op nul.',
      'Four coils A, B, C, D (100 ohm each) to the common terminal - (to the - rail).' + #13#10 +
        'A coil pulls from 20 mA, also on the output of a gate. A, B, C, D in turn: clockwise; D, C, B, A: anticlockwise.' + #13#10 +
        'Right-click: steps per revolution, reset the counter.',
      'Quatre bobines A, B, C, D (100 ohms chacune) vers la borne commune - (vers le rail -).' + #13#10 +
        'Une bobine tire à partir de 20 mA, aussi à la sortie d''une porte. A, B, C, D l''une après l''autre : sens horaire ; D, C, B, A : sens antihoraire.' + #13#10 +
        'Clic droit : pas par tour, remettre le compteur à zéro.',
      'Vier Spulen A, B, C, D (je 100 Ohm) zur gemeinsamen Klemme - (zur - Schiene).' + #13#10 +
        'Eine Spule zieht ab 20 mA, auch am Ausgang eines Gatters. A, B, C, D nacheinander: rechtsherum; D, C, B, A: linksherum.' + #13#10 +
        'Rechtsklick: Schritte pro Umdrehung, Zähler auf null.');
end;

procedure TjanStappenmotor.SendStatusToBar;
var
  i: Integer;
  S: string;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Tr(FTaal, 'Stappenmotor', 'Stepper motor', 'Moteur pas à pas', 'Schrittmotor') + ' > ', 0);
  S := '';
  for i := 0 to 3 do
    if SpoelAan(i) then S := S + Chr(Ord('A') + i);
  if S = '' then S := '-';
  FOnStatus(Self, Tr(FTaal, 'spoelen', 'coils', 'bobines', 'Spulen') + ': ' + S + '   ' +
    Tr(FTaal, 'stappen', 'steps', 'pas', 'Schritte') + ': ' + FormatFloat('0.#', Stappen) + '   ' +
    FormatFloat('0.#', Hoek) + '°', 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

{ TjanServo }

const
  ServoW = 186;
  ServoH = 118;
  ServoCX = 110;              // draaipunt van de arm
  ServoCY = 66;
  ServoBoog = 52;             // straal van de schaal
  ServoMinVolt = 4.0;         // daaronder werkt hij niet
  ServoMaxStuur = 5.0;        // stuurspanning voor 180 graden
  ServoSnelheid = 12;         // graden per tik (40 ms)

constructor TjanServo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := ServoW;
  Height := ServoH;
  HelpKeyword := 'servo';
  FHoek := 90;
  FGestuurd := -1;
  FTimer := TTimer.Create(Self);
  FTimer.Interval := 40;
  FTimer.OnTimer := Tik;
  FTimer.Enabled := True;
end;

function TjanServo.PinCount: Integer;
begin
  Result := 3;
end;

// links: + boven, S in het midden, - onder (klem 0, 2, 1)
function TjanServo.PinPos(I: Integer): TPoint;
begin
  case I of
    0: Result := Point(1, 14);
    2: Result := Point(1, 44);
  else
    Result := Point(1, 74);
  end;
end;

function TjanServo.MotorOhm: Double;
begin
  Result := 100;
end;

function TjanServo.Voeding: Double;
begin
  Result := FPinV[0] - FPinV[1];
end;

function TjanServo.Stuurspanning: Double;
begin
  Result := FPinV[2] - FPinV[1];
end;

function TjanServo.Werkt: Boolean;
begin
  Result := Voeding >= ServoMinVolt;
end;

function TjanServo.Doel: Double;
var
  U: Double;
begin
  U := Stuurspanning;
  if U < 0 then U := 0;
  if U > ServoMaxStuur then U := ServoMaxStuur;
  Result := U / ServoMaxStuur * 180;
end;

procedure TjanServo.SetHoek(const Value: Double);
var
  V: Double;
begin
  V := Value;
  if V < 0 then V := 0;
  if V > 180 then V := 180;
  if V = FHoek then Exit;
  FHoek := V;
  Invalidate;
end;

procedure TjanServo.SetPin(const Value: Integer);
begin
  if (Value <> 0) and ((Value < 2) or (Value > 13)) then Exit;
  if Value = FPin then Exit;
  FPin := Value;
  FGestuurd := -1;
  UpdateHintText;
  Invalidate;
end;

procedure TjanServo.PinClick(Sender: TObject);
begin
  if not FLock then Pin := TMenuItem(Sender).Tag;
end;

procedure TjanServo.AddMenuItems(APop: TPopupMenu);
var
  Mi, Sub: TMenuItem;
  i: Integer;
begin
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Echte servo op het Arduino-board', 'Real servo on the Arduino board',
    'Vrai servo sur la carte Arduino', 'Echter Servo am Arduino-Board');
  APop.Items.Add(Mi);
  for i := 1 to 13 do
  begin
    Sub := TMenuItem.Create(APop);
    if i = 1 then
    begin
      Sub.Caption := Tr(FTaal, 'geen', 'none', 'aucun', 'keiner');
      Sub.Tag := 0;
    end
    else
    begin
      Sub.Caption := BoardPinNaam(i);
      Sub.Tag := i;
    end;
    Sub.RadioItem := True;
    Sub.Checked := Sub.Tag = FPin;
    Sub.Enabled := not FLock;
    Sub.OnClick := PinClick;
    Mi.Add(Sub);
  end;
end;

procedure TjanServo.Stuur(AltijdSturen: Boolean);
var
  V: Integer;
begin
  if (FPin < 2) or not (BoardVerbonden and Assigned(BoardServo)) then
  begin
    FGestuurd := -1;
    Exit;
  end;
  if not Werkt then Exit;
  V := Round(FHoek);
  if AltijdSturen or (V <> FGestuurd) then
    BoardServo(FPin, V);
  FGestuurd := V;
end;

procedure TjanServo.Tik(Sender: TObject);
var
  D: Double;
begin
  if (Parent = nil) or not Visible then Exit;
  if Werkt then
  begin
    D := Doel - FHoek;
    if Abs(D) > 0.05 then
    begin
      if D > ServoSnelheid then D := ServoSnelheid;
      if D < -ServoSnelheid then D := -ServoSnelheid;
      FHoek := FHoek + D;
      Invalidate;
    end;
  end;
  Stuur;
end;

procedure TjanServo.Paint;
var
  i, X, Y, X2, Y2: Integer;
  A: Double;
  T: string;

  function BoogPt(AHoek: Double; R: Integer): TPoint;
  begin
    // 0 graden rechts, 90 boven, 180 links (zoals op een gradenboog)
    Result := Point(ServoCX + Round(R * Cos(AHoek * Pi / 180)),
      ServoCY - Round(R * Sin(AHoek * Pi / 180)));
  end;

begin
  with Canvas do
  begin
    Pen.Style := psSolid;
    Pen.Width := 2;
    // de drie draadjes van de klemmen naar het huis
    Pen.Color := RGBToColor(210, 30, 30);
    MoveTo(PinPos(0).X + 7, PinPos(0).Y + 3); LineTo(22, PinPos(0).Y + 3); LineTo(22, 82); LineTo(40, 82);
    Pen.Color := RGBToColor(240, 150, 20);
    MoveTo(PinPos(2).X + 7, PinPos(2).Y + 3); LineTo(26, PinPos(2).Y + 3); LineTo(26, 88); LineTo(40, 88);
    Pen.Color := RGBToColor(90, 50, 30);
    MoveTo(PinPos(1).X + 7, PinPos(1).Y + 3); LineTo(30, PinPos(1).Y + 3); LineTo(30, 94); LineTo(40, 94);
    Pen.Width := 1;
    Brush.Style := bsClear;
    Font.Name := 'Arial';
    Font.Size := 8;
    Font.Style := [fsBold];
    Font.Color := RGBToColor(200, 20, 20);
    TextOut(PinPos(0).X + 10, PinPos(0).Y - 12, '+');
    Font.Color := RGBToColor(200, 110, 0);
    TextOut(PinPos(2).X + 10, PinPos(2).Y - 12, 'S');
    Font.Color := clBlack;
    TextOut(PinPos(1).X + 10, PinPos(1).Y - 12, '-');
    // het huis
    Brush.Style := bsSolid;
    Brush.Color := RGBToColor(40, 80, 160);
    Pen.Color := RGBToColor(20, 40, 90);
    Rectangle(40, ServoCY + 6, ServoW - 6, ServoH - 4);
    // de schaal van 0 tot 180 graden
    Pen.Color := RGBToColor(120, 120, 130);
    Brush.Style := bsClear;
    Arc(ServoCX - ServoBoog, ServoCY - ServoBoog, ServoCX + ServoBoog + 1, ServoCY + ServoBoog + 1,
      ServoCX + ServoBoog, ServoCY, ServoCX - ServoBoog, ServoCY);
    for i := 0 to 6 do
    begin
      A := i * 30;
      if i mod 3 = 0 then X := ServoBoog - 8 else X := ServoBoog - 4;
      MoveTo(BoogPt(A, X)); LineTo(BoogPt(A, ServoBoog));
    end;
    Font.Size := 7;
    Font.Style := [];
    Font.Color := RGBToColor(60, 60, 60);
    TextOut(ServoCX + ServoBoog + 3, ServoCY - 7, '0°');
    TextOut(ServoCX - TextWidth('90°') div 2, ServoCY - ServoBoog - 13, '90°');
    TextOut(ServoCX - ServoBoog - 3 - TextWidth('180°'), ServoCY - 7, '180°');
    // gevraagde hoek: een oranje driehoekje op de schaal
    if Werkt then
    begin
      Brush.Style := bsSolid;
      Brush.Color := RGBToColor(240, 150, 20);
      Pen.Color := RGBToColor(160, 90, 0);
      X := BoogPt(Doel, ServoBoog + 1).X; Y := BoogPt(Doel, ServoBoog + 1).Y;
      X2 := BoogPt(Doel - 5, ServoBoog + 8).X; Y2 := BoogPt(Doel - 5, ServoBoog + 8).Y;
      Polygon([Point(X, Y), Point(X2, Y2), BoogPt(Doel + 5, ServoBoog + 8)]);
    end;
    // de arm
    Pen.Color := clBlack;
    Pen.Width := 9;
    MoveTo(ServoCX, ServoCY); LineTo(BoogPt(FHoek, 40));
    Pen.Color := clWhite;
    Pen.Width := 7;
    MoveTo(ServoCX, ServoCY); LineTo(BoogPt(FHoek, 40));
    Pen.Width := 1;
    Pen.Color := clBlack;
    Brush.Style := bsSolid;
    Brush.Color := clWhite;
    Ellipse(ServoCX - 7, ServoCY - 7, ServoCX + 8, ServoCY + 8);
    Brush.Color := RGBToColor(120, 120, 120);
    Ellipse(ServoCX - 2, ServoCY - 2, ServoCX + 3, ServoCY + 3);
    // hoek en stuurspanning in het huis
    Brush.Style := bsClear;
    Font.Color := clWhite;
    Font.Size := 9;
    Font.Style := [fsBold];
    TextOut(46, ServoCY + 10, FormatFloat('0', FHoek) + '°');
    Font.Size := 7;
    Font.Style := [];
    if Werkt then
      T := 'S: ' + VoltText(Stuurspanning)
    else
      T := Tr(FTaal, 'geen voeding', 'no power', 'pas d''alim.', 'keine Spannung');
    TextOut(46, ServoCY + 28, T);
    if FPin >= 2 then
    begin
      Font.Color := RGBToColor(120, 230, 230);
      TextOut(ServoW - 10 - TextWidth(BoardPinNaam(FPin)), ServoCY + 28, BoardPinNaam(FPin));
    end;
  end;
  PaintPin(PinPos(0).X, PinPos(0).Y, FPinV[0] >= RailMinVolt);
  PaintPin(PinPos(1).X, PinPos(1).Y, FPinV[1] >= RailMinVolt);
  PaintPin(PinPos(2).X, PinPos(2).Y, FPinV[2] >= RailMinVolt);
  PaintSelection;
end;

procedure TjanServo.UpdateHintText;
var
  S, B: string;
begin
  if not Werkt then
    S := Tr(FTaal, 'Hij krijgt te weinig voeding (minstens 4 V tussen + en -): de arm staat stil.',
      'It gets too little power (at least 4 V between + and -): the arm does not move.',
      'Il reçoit trop peu d''alimentation (au moins 4 V entre + et -) : le bras ne bouge pas.',
      'Er bekommt zu wenig Spannung (mindestens 4 V zwischen + und -): Der Arm bewegt sich nicht.')
  else
    S := Format(Tr(FTaal, 'Stuurspanning %s: de arm draait naar %s°.', 'Control voltage %s: the arm turns to %s°.',
      'Tension de commande %s : le bras tourne vers %s°.', 'Steuerspannung %s: Der Arm dreht sich auf %s°.'),
      [VoltText(Stuurspanning), FormatFloat('0', Doel)]);
  if FPin >= 2 then
  begin
    if BoardVerbonden then
      B := Format(Tr(FTaal, 'De echte servo op %s draait mee.', 'The real servo on %s turns along.',
        'Le vrai servo sur %s tourne aussi.', 'Der echte Servo an %s dreht mit.'), [BoardPinNaam(FPin)])
    else
      B := Format(Tr(FTaal, 'Echte servo op %s: geen board verbonden.', 'Real servo on %s: no board connected.',
        'Vrai servo sur %s : aucune carte connectée.', 'Echter Servo an %s: kein Board verbunden.'), [BoardPinNaam(FPin)]);
    S := S + #13#10 + B;
  end;
  Hint := Tr(FTaal, 'Servomotor', 'Servo motor', 'Servomoteur', 'Servomotor') + ': ' +
    FormatFloat('0', FHoek) + '°' + #13#10 + S + #13#10 +
    Tr(FTaal,
      'Drie klemmen: + en - voor de motor, S voor het stuursignaal. 0 V op S geeft 0°, 5 V geeft 180°.' + #13#10 +
        'Bv. een potentiometer tussen + en - met de loper aan S. Rechtsklik: een echte servo op het Arduino-board.',
      'Three terminals: + and - for the motor, S for the control signal. 0 V on S gives 0°, 5 V gives 180°.' + #13#10 +
        'E.g. a potentiometer between + and - with the wiper on S. Right-click: a real servo on the Arduino board.',
      'Trois bornes : + et - pour le moteur, S pour le signal de commande. 0 V sur S donne 0°, 5 V donne 180°.' + #13#10 +
        'Par ex. un potentiomètre entre + et - avec le curseur sur S. Clic droit : un vrai servo sur la carte Arduino.',
      'Drei Klemmen: + und - für den Motor, S für das Steuersignal. 0 V an S ergibt 0°, 5 V ergibt 180°.' + #13#10 +
        'Z. B. ein Potentiometer zwischen + und - mit dem Schleifer an S. Rechtsklick: ein echter Servo am Arduino-Board.');
end;

procedure TjanServo.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Tr(FTaal, 'Servomotor', 'Servo motor', 'Servomoteur', 'Servomotor') + ' > ', 0);
  FOnStatus(Self, FormatFloat('0', FHoek) + '°   S = ' + VoltText(Stuurspanning) + '   ' +
    Tr(FTaal, 'voeding', 'supply', 'alim.', 'Speisung') + ' = ' + VoltText(Voeding), 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

{ TjanVentilator }

const
  VentW = 90;
  VentH = 110;
  VentCX = 45;
  VentCY = 40;
  VentMinVolt = 1.0;          // daaronder draait hij niet
  VentToerPerVolt = 100;      // omw/min per volt

constructor TjanVentilator.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := VentW;
  Height := VentH;
  HelpKeyword := 'ventilator';
  FTimer := TTimer.Create(Self);
  FTimer.Interval := 40;
  FTimer.OnTimer := Tik;
  FTimer.Enabled := True;
end;

function TjanVentilator.KanDraaien: Boolean;
begin
  Result := False;
end;

function TjanVentilator.StdMaat: TPoint;
begin
  Result := Point(VentW, VentH);
end;

function TjanVentilator.ExtraBreedte: Integer;
begin
  Result := 0;
end;

procedure TjanVentilator.AddMenuItems(APop: TPopupMenu);
begin
  // geen soorten zoals bij de weerstand
end;

function TjanVentilator.PinPos(I: Integer): TPoint;
begin
  if I = 0 then Result := Point(1, 82) else Result := Point(VentW - 8, 82);
end;

function TjanVentilator.Ohm: Double;
begin
  Result := 25;
end;

function TjanVentilator.Toeren: Double;
var
  U: Double;
begin
  U := FInVolt - FUitVolt;
  if Abs(U) < VentMinVolt then Result := 0
  else Result := U * VentToerPerVolt;
end;

function TjanVentilator.Aan: Boolean;
begin
  Result := Toeren <> 0;
end;

procedure TjanVentilator.Tik(Sender: TObject);
var
  T, Stap: Double;
begin
  if (Parent = nil) or not Visible then Exit;
  T := Toeren;
  if Abs(T - FToeren) > 0.5 then
    FToeren := FToeren + (T - FToeren) * 0.12
  else
    FToeren := T;
  if FToeren = 0 then Exit;
  // op het scherm niet sneller dan 45 graden per tik
  Stap := FToeren * 0.025;
  if Stap > 45 then Stap := 45;
  if Stap < -45 then Stap := -45;
  FHoek := FHoek + Stap;
  while FHoek >= 360 do FHoek := FHoek - 360;
  while FHoek < 0 do FHoek := FHoek + 360;
  Invalidate;
end;

procedure TjanVentilator.Paint;
var
  k: Integer;
  A: Double;
  T: string;

  function P(R: Integer; AGraden: Double): TPoint;
  begin
    Result := Point(VentCX + Round(R * Sin(AGraden * Pi / 180)),
      VentCY - Round(R * Cos(AGraden * Pi / 180)));
  end;

begin
  with Canvas do
  begin
    Pen.Style := psSolid;
    Pen.Width := 1;
    // de draden naar het motortje
    Pen.Color := clBlack;
    MoveTo(PinPos(0).X + 7, PinPos(0).Y + 3); LineTo(VentCX - 9, PinPos(0).Y + 3);
    MoveTo(PinPos(1).X, PinPos(1).Y + 3); LineTo(VentCX + 9, PinPos(1).Y + 3);
    // het motortje met een M
    Brush.Style := bsSolid;
    Brush.Color := RGBToColor(200, 200, 205);
    Rectangle(VentCX - 9, 76, VentCX + 10, 93);
    Brush.Style := bsClear;
    Font.Name := 'Arial';
    Font.Size := 8;
    Font.Style := [fsBold];
    Font.Color := clBlack;
    TextOut(VentCX - TextWidth('M') div 2, 78, 'M');
    // het huis (rooster)
    Brush.Style := bsSolid;
    Brush.Color := RGBToColor(235, 240, 245);
    Pen.Color := RGBToColor(90, 90, 100);
    Pen.Width := 2;
    Ellipse(VentCX - 36, VentCY - 36, VentCX + 37, VentCY + 37);
    Pen.Width := 1;
    // drie schoepen
    Brush.Color := RGBToColor(90, 160, 220);
    Pen.Color := RGBToColor(30, 80, 130);
    for k := 0 to 2 do
    begin
      A := FHoek + k * 120;
      Polygon([P(6, A - 30), P(31, A - 14), P(32, A + 12), P(6, A + 30)]);
    end;
    Brush.Color := RGBToColor(70, 70, 80);
    Ellipse(VentCX - 6, VentCY - 6, VentCX + 7, VentCY + 7);
    // toerental
    Brush.Style := bsClear;
    Font.Size := 7;
    Font.Style := [];
    Font.Color := RGBToColor(60, 60, 60);
    T := FormatFloat('0', Abs(Toeren)) + ' ' + Tr(FTaal, 'omw/min', 'rpm', 'tr/min', 'U/min');
    TextOut(VentCX - TextWidth(T) div 2, 96, T);
  end;
  PaintPin(PinPos(0).X, PinPos(0).Y, FInVolt >= RailMinVolt);
  PaintPin(PinPos(1).X, PinPos(1).Y, FUitVolt >= RailMinVolt);
  PaintSelection;
end;

procedure TjanVentilator.UpdateHintText;
var
  S: string;
begin
  if Toeren > 0 then
    S := Format(Tr(FTaal, 'Hij draait rechtsom: %s omw/min.', 'It turns clockwise: %s rpm.',
      'Il tourne dans le sens horaire : %s tr/min.', 'Er dreht sich rechtsherum: %s U/min.'), [FormatFloat('0', Toeren)])
  else if Toeren < 0 then
    S := Format(Tr(FTaal, 'Hij draait linksom: %s omw/min.', 'It turns anticlockwise: %s rpm.',
      'Il tourne dans le sens antihoraire : %s tr/min.', 'Er dreht sich linksherum: %s U/min.'), [FormatFloat('0', -Toeren)])
  else
    S := Tr(FTaal, 'Hij staat stil: minder dan 1 V.', 'It stands still: less than 1 V.',
      'Il est à l''arrêt : moins de 1 V.', 'Er steht still: weniger als 1 V.');
  Hint := Tr(FTaal, 'Ventilator', 'Fan', 'Ventilateur', 'Ventilator') + ': ' + OhmText(Ohm) + #13#10 +
    StroomRegel(FStroom) + #13#10 + S + #13#10 +
    Tr(FTaal,
      'Een gewone motor: hij draait rond zolang er stroom door gaat, sneller bij meer spanning.' + #13#10 +
        'Wissel je + en - om, dan draait hij andersom.',
      'An ordinary motor: it keeps turning as long as current flows, faster with more voltage.' + #13#10 +
        'Swap + and - and it turns the other way.',
      'Un moteur ordinaire : il tourne tant que le courant passe, plus vite avec plus de tension.' + #13#10 +
        'Inversez + et - et il tourne dans l''autre sens.',
      'Ein gewöhnlicher Motor: Er dreht sich, solange Strom fließt, schneller bei mehr Spannung.' + #13#10 +
        'Vertauscht man + und -, dreht er sich andersherum.');
end;

procedure TjanVentilator.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Tr(FTaal, 'Ventilator', 'Fan', 'Ventilateur', 'Ventilator') + ' > ', 0);
  FOnStatus(Self, FormatFloat('0', Abs(Toeren)) + ' ' + Tr(FTaal, 'omw/min', 'rpm', 'tr/min', 'U/min') +
    '   I = ' + FormatFloat('0', FStroom * 1000) + ' mA', 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;
