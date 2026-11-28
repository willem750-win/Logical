{ jsl_k8055.inc - onderdelen voor een Velleman K8055 (USB): TjanK8055In (een
  echte ingang als drukknop in de kring) en TjanK8055Uit (een lamp van 5 V die
  een echte uitgang aan of uit zet). De verbinding zelf zit in het programma:
  zie K8055Schrijf en K8055Verbonden, en uK8055.pas in projects/LogicCEF. }

var
  K8055Laatst: Integer = -1;   // laatst gestuurde uitgangen, -1 = onbekend

// de K8055 meldt de ingangen in een vreemde volgorde: INP1 = bit 4,
// INP2 = bit 5, INP3 = bit 0, INP4 = bit 6, INP5 = bit 7
function K8055Ingang(AData: Byte; ANr: Integer): Boolean;
const
  Bit: array[1..5] of Integer = (4, 5, 0, 6, 7);
begin
  if (ANr < 1) or (ANr > 5) then Exit(False);
  Result := (AData shr Bit[ANr]) and 1 = 1;
end;

procedure K8055Bijwerken(P: TWinControl; AltijdSturen: Boolean);
var
  i, M: Integer;
begin
  if (P = nil) or not K8055Verbonden or not Assigned(K8055Schrijf) then
  begin
    K8055Laatst := -1;
    Exit;
  end;
  M := 0;
  for i := 0 to P.ControlCount - 1 do
    if (P.Controls[i] is TjanK8055Uit) and TjanK8055Uit(P.Controls[i]).Aan then
      M := M or (1 shl (TjanK8055Uit(P.Controls[i]).Nr - 1));
  if AltijdSturen or (M <> K8055Laatst) then
  begin
    K8055Schrijf(Byte(M));
    K8055Laatst := M;
  end;
end;

{ TjanK8055In }

constructor TjanK8055In.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Soort := 1;           // een drukknop: dicht zolang de echte ingang aan is
  FNr := 1;
  HelpKeyword := 'k8055';
end;

procedure TjanK8055In.SetNr(const Value: Integer);
begin
  if (Value < 1) or (Value > 5) or (Value = FNr) then Exit;
  FNr := Value;
  UpdateHintText;
  Invalidate;
end;

procedure TjanK8055In.NrClick(Sender: TObject);
begin
  if not FLock then Nr := TMenuItem(Sender).Tag;
end;

// met een bordje volgt hij de echte ingang; zonder bordje werkt hij met de muis
function TjanK8055In.HandleClick(X, Y: Integer): Boolean;
begin
  if K8055Verbonden then
    Result := False
  else
    Result := inherited HandleClick(X, Y);
end;

procedure TjanK8055In.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if K8055Verbonden then Exit;
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TjanK8055In.AddMenuItems(APop: TPopupMenu);
var
  Mi, Sub: TMenuItem;
  i: Integer;
begin
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Ingang van de K8055', 'K8055 input', 'Entrée de la K8055', 'Eingang der K8055');
  APop.Items.Add(Mi);
  for i := 1 to 5 do
  begin
    Sub := TMenuItem.Create(APop);
    Sub.Caption := 'INP' + IntToStr(i);
    Sub.Tag := i;
    Sub.RadioItem := True;
    Sub.Checked := i = FNr;
    Sub.Enabled := not FLock;
    Sub.OnClick := NrClick;
    Mi.Add(Sub);
  end;
end;

procedure TjanK8055In.Paint;
begin
  inherited Paint;
  with Canvas do
  begin
    Brush.Style := bsClear;
    Font.Name := 'Arial'; Font.Size := 7; Font.Style := [fsBold];
    if K8055Verbonden then Font.Color := RGBToColor(200, 30, 30) else Font.Color := clGray;
    with TP(2, 0) do TextOut(X, Y, 'K8055 INP' + IntToStr(FNr));
  end;
end;

procedure TjanK8055In.UpdateHintText;
var
  S: string;
begin
  if K8055Verbonden then
    S := Tr(FTaal, 'De K8055 is verbonden: de echte ingang bedient dit contact.',
      'The K8055 is connected: the real input operates this contact.',
      'La K8055 est connectée : la vraie entrée commande ce contact.',
      'Die K8055 ist verbunden: Der echte Eingang betätigt diesen Kontakt.')
  else
    S := Tr(FTaal, 'Geen K8055 verbonden: druk er met de muis op, zoals op een drukknop.',
      'No K8055 connected: press it with the mouse, like a push button.',
      'Aucune K8055 connectée : appuyez dessus avec la souris, comme sur un bouton-poussoir.',
      'Keine K8055 verbunden: Drücken Sie mit der Maus darauf, wie auf einen Taster.');
  Hint := Tr(FTaal, 'K8055-ingang', 'K8055 input', 'Entrée K8055', 'K8055-Eingang') + ' INP' + IntToStr(FNr) + #13#10 + S + #13#10 +
    Tr(FTaal,
      'INP1 tot INP3 hebben een drukknopje op het bordje; een eigen knop zet je tussen de ingang en GND.' + #13#10 +
        'Rechtsklik: ingang kiezen.',
      'INP1 to INP3 have a push button on the board; connect your own button between the input and GND.' + #13#10 +
        'Right-click: choose the input.',
      'INP1 à INP3 ont un bouton-poussoir sur la carte ; branchez votre propre bouton entre l''entrée et GND.' + #13#10 +
        'Clic droit : choisir l''entrée.',
      'INP1 bis INP3 haben einen Taster auf der Platine; einen eigenen Taster schließen Sie zwischen Eingang und GND an.' + #13#10 +
        'Rechtsklick: Eingang wählen.');
end;

procedure TjanK8055In.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Tr(FTaal, 'K8055-ingang', 'K8055 input', 'Entrée K8055', 'K8055-Eingang') + ' > ', 0);
  if Aan then
    FOnStatus(Self, 'INP' + IntToStr(FNr) + ': ' + Tr(FTaal, 'aan', 'on', 'active', 'an'), 1)
  else
    FOnStatus(Self, 'INP' + IntToStr(FNr) + ': ' + Tr(FTaal, 'uit', 'off', 'inactive', 'aus'), 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

{ TjanK8055Uit }

constructor TjanK8055Uit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Soort := Lamp2Standaard5V;   // een lamp van 5 V: hij brandt aan een poort
  FNr := 1;
  HelpKeyword := 'k8055';
end;

function TjanK8055Uit.LampLabel: string;
begin
  Result := 'K8055 OUT' + IntToStr(FNr);
end;

procedure TjanK8055Uit.SetNr(const Value: Integer);
begin
  if (Value < 1) or (Value > 8) or (Value = FNr) then Exit;
  FNr := Value;
  UpdateHintText;
  Invalidate;
  if Parent <> nil then K8055Bijwerken(Parent, True);
end;

procedure TjanK8055Uit.NrClick(Sender: TObject);
begin
  if not FLock then Nr := TMenuItem(Sender).Tag;
end;

procedure TjanK8055Uit.AddMenuItems(APop: TPopupMenu);
var
  Mi, Sub: TMenuItem;
  i: Integer;
begin
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Uitgang van de K8055', 'K8055 output', 'Sortie de la K8055', 'Ausgang der K8055');
  APop.Items.Add(Mi);
  for i := 1 to 8 do
  begin
    Sub := TMenuItem.Create(APop);
    Sub.Caption := 'OUT' + IntToStr(i);
    Sub.Tag := i;
    Sub.RadioItem := True;
    Sub.Checked := i = FNr;
    Sub.Enabled := not FLock;
    Sub.OnClick := NrClick;
    Mi.Add(Sub);
  end;
end;

procedure TjanK8055Uit.UpdateHintText;
var
  S: string;
begin
  if K8055Verbonden then
    S := Tr(FTaal, 'De K8055 is verbonden: brandt deze lamp, dan gaat de echte uitgang (en zijn ledje) aan.',
      'The K8055 is connected: when this lamp is lit, the real output (and its LED) switches on.',
      'La K8055 est connectée : quand cette lampe brille, la vraie sortie (et sa LED) s''allume.',
      'Die K8055 ist verbunden: Leuchtet diese Lampe, schaltet der echte Ausgang (und seine LED) ein.')
  else
    S := Tr(FTaal, 'Geen K8055 verbonden: alleen de lamp op het scherm brandt.',
      'No K8055 connected: only the lamp on the screen lights.',
      'Aucune K8055 connectée : seule la lampe à l''écran s''allume.',
      'Keine K8055 verbunden: Nur die Lampe auf dem Bildschirm leuchtet.');
  Hint := Tr(FTaal, 'K8055-uitgang', 'K8055 output', 'Sortie K8055', 'K8055-Ausgang') + ' OUT' + IntToStr(FNr) + #13#10 + S + #13#10 +
    Tr(FTaal, 'Elke uitgang heeft een ledje op het bordje. Rechtsklik: uitgang kiezen.',
      'Each output has an LED on the board. Right-click: choose the output.',
      'Chaque sortie a une LED sur la carte. Clic droit : choisir la sortie.',
      'Jeder Ausgang hat eine LED auf der Platine. Rechtsklick: Ausgang wählen.');
end;

procedure TjanK8055Uit.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Tr(FTaal, 'K8055-uitgang', 'K8055 output', 'Sortie K8055', 'K8055-Ausgang') + ' > ', 0);
  if Aan then
    FOnStatus(Self, 'OUT' + IntToStr(FNr) + ': ' + Tr(FTaal, 'aan', 'on', 'active', 'an'), 1)
  else
    FOnStatus(Self, 'OUT' + IntToStr(FNr) + ': ' + Tr(FTaal, 'uit', 'off', 'inactive', 'aus'), 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

{ TjanK8055Ana }

const
  K8055AnaW = 150;
  K8055AnaH = 74;

constructor TjanK8055Ana.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := K8055AnaW;
  Height := K8055AnaH;
  FNr := 1;
  FStand := 128;
  HelpKeyword := 'k8055';
end;

function TjanK8055Ana.PinCount: Integer;
begin
  Result := 2;
end;

// rechts: + boven, - onder
function TjanK8055Ana.PinPos(I: Integer): TPoint;
begin
  if I = 0 then Result := Point(K8055AnaW - 8, 10)
  else Result := Point(K8055AnaW - 8, K8055AnaH - 18);
end;

// met het bordje: de gemeten waarde; anders de schuif
function TjanK8055Ana.Emk: Double;
var
  S: Integer;
begin
  if K8055Verbonden then S := K8055Analoog[FNr] else S := FStand;
  Result := S * 5.0 / 255;
end;

function TjanK8055Ana.Ri: Double;
begin
  Result := 10;
end;

procedure TjanK8055Ana.SetNr(const Value: Integer);
begin
  if (Value < 1) or (Value > 2) or (Value = FNr) then Exit;
  FNr := Value;
  UpdateHintText;
  Invalidate;
  if Parent <> nil then VoedingBijwerken(Parent);
end;

procedure TjanK8055Ana.SetStand(const Value: Integer);
var
  V: Integer;
begin
  V := Value;
  if V < 0 then V := 0;
  if V > 255 then V := 255;
  if V = FStand then Exit;
  FStand := V;
  Invalidate;
  if (Parent <> nil) and not K8055Verbonden then VoedingBijwerken(Parent);
end;

procedure TjanK8055Ana.NrClick(Sender: TObject);
begin
  if not FLock then Nr := TMenuItem(Sender).Tag;
end;

procedure TjanK8055Ana.AddMenuItems(APop: TPopupMenu);
var
  Mi, Sub: TMenuItem;
  i: Integer;
begin
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Analoge ingang van de K8055', 'K8055 analog input', 'Entrée analogique de la K8055',
    'Analoger Eingang der K8055');
  APop.Items.Add(Mi);
  for i := 1 to 2 do
  begin
    Sub := TMenuItem.Create(APop);
    Sub.Caption := 'A' + IntToStr(i);
    Sub.Tag := i;
    Sub.RadioItem := True;
    Sub.Checked := i = FNr;
    Sub.Enabled := not FLock;
    Sub.OnClick := NrClick;
    Mi.Add(Sub);
  end;
end;

function TjanK8055Ana.SchuifRect: TRect;
begin
  Result := Rect(12, K8055AnaH - 18, K8055AnaW - 30, K8055AnaH - 12);
end;

procedure TjanK8055Ana.SchuifNaar(X: Integer);
var
  R: TRect;
begin
  R := SchuifRect;
  Stand := Round((X - R.Left) / (R.Right - R.Left) * 255);
end;

// zonder bordje: met de muis op de schuif klikken of slepen
function TjanK8055Ana.HandleClick(X, Y: Integer): Boolean;
var
  R: TRect;
begin
  Result := False;
  if K8055Verbonden or FLock then Exit;
  R := SchuifRect;
  InflateRect(R, 6, 6);
  if not PtInRect(R, Point(X, Y)) then Exit;
  Result := True;
  FSchuift := True;
  SchuifNaar(X);
end;

procedure TjanK8055Ana.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  if FSchuift then
  begin
    if ssLeft in Shift then SchuifNaar(X) else FSchuift := False;
    Exit;
  end;
  inherited MouseMove(Shift, X, Y);
end;

procedure TjanK8055Ana.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if FSchuift then
  begin
    FSchuift := False;
    Exit;
  end;
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TjanK8055Ana.Paint;
var
  R: TRect;
  S, XK, CX, CY: Integer;
  A: Double;
begin
  if K8055Verbonden then S := K8055Analoog[FNr] else S := FStand;
  with Canvas do
  begin
    Pen.Style := psSolid;
    Pen.Width := 1;
    // het bordje (rood) met een draaiknop
    Brush.Style := bsSolid;
    Brush.Color := RGBToColor(200, 40, 40);
    Pen.Color := RGBToColor(120, 20, 20);
    Rectangle(0, 0, K8055AnaW - 16, K8055AnaH);
    CX := 26; CY := 28;
    Brush.Color := RGBToColor(60, 60, 70);
    Ellipse(CX - 15, CY - 15, CX + 16, CY + 16);
    // de stand van de knop: van linksonder (0) naar rechtsonder (255)
    A := (225 - S / 255 * 270) * Pi / 180;
    Pen.Color := clWhite;
    Pen.Width := 3;
    MoveTo(CX, CY);
    LineTo(CX + Round(12 * Cos(A)), CY - Round(12 * Sin(A)));
    Pen.Width := 1;
    Brush.Style := bsClear;
    Font.Name := 'Arial';
    Font.Style := [fsBold];
    Font.Size := 7;
    if K8055Verbonden then Font.Color := clWhite else Font.Color := RGBToColor(255, 200, 200);
    TextOut(48, 4, 'K8055 A' + IntToStr(FNr));
    Font.Size := 11;
    Font.Color := clWhite;
    TextOut(48, 18, FormatFloat('0.00', Emk) + ' V');
    Font.Size := 7;
    Font.Style := [];
    TextOut(48, 38, IntToStr(S) + ' / 255');
    // de schuif (alleen te gebruiken zonder bordje)
    R := SchuifRect;
    Brush.Style := bsSolid;
    if K8055Verbonden then Brush.Color := RGBToColor(150, 60, 60) else Brush.Color := RGBToColor(240, 220, 220);
    Pen.Color := RGBToColor(90, 20, 20);
    Rectangle(R);
    XK := R.Left + Round((R.Right - R.Left) * S / 255);
    Brush.Color := RGBToColor(40, 40, 50);
    Rectangle(XK - 3, R.Top - 4, XK + 4, R.Bottom + 4);
    // draadjes naar de klemmen, + en -
    Pen.Color := clBlack;
    MoveTo(K8055AnaW - 16, PinPos(0).Y + 3); LineTo(PinPos(0).X, PinPos(0).Y + 3);
    MoveTo(K8055AnaW - 16, PinPos(1).Y + 3); LineTo(PinPos(1).X, PinPos(1).Y + 3);
    Brush.Style := bsClear;
    Font.Size := 8; Font.Style := [fsBold];
    Font.Color := clWhite;
    TextOut(K8055AnaW - 28, PinPos(0).Y - 4, '+');
    TextOut(K8055AnaW - 28, PinPos(1).Y - 6, '-');
  end;
  PaintPin(PinPos(0).X, PinPos(0).Y, FPinV[0] >= RailMinVolt);
  PaintPin(PinPos(1).X, PinPos(1).Y, FPinV[1] >= RailMinVolt);
  PaintSelection;
end;

procedure TjanK8055Ana.UpdateHintText;
var
  S: string;
begin
  if K8055Verbonden then
    S := Tr(FTaal, 'De K8055 is verbonden: de spanning volgt het draaiknopje (of de sensor) op deze ingang.',
      'The K8055 is connected: the voltage follows the knob (or the sensor) on this input.',
      'La K8055 est connectée : la tension suit le bouton rotatif (ou le capteur) de cette entrée.',
      'Die K8055 ist verbunden: Die Spannung folgt dem Drehknopf (oder dem Sensor) an diesem Eingang.')
  else
    S := Tr(FTaal, 'Geen K8055 verbonden: stel de spanning in met de schuif.',
      'No K8055 connected: set the voltage with the slider.',
      'Aucune K8055 connectée : réglez la tension avec le curseur.',
      'Keine K8055 verbunden: Stellen Sie die Spannung mit dem Schieber ein.');
  Hint := Tr(FTaal, 'K8055-analoge ingang', 'K8055 analog input', 'Entrée analogique K8055', 'Analoger K8055-Eingang') +
    ' A' + IntToStr(FNr) + ': ' + FormatFloat('0.00', Emk) + ' V' + #13#10 + S + #13#10 +
    Tr(FTaal,
      'Een spanningsbron van 0 tot 5 V met twee klemmen: + boven, - onder (naar de - rail).' + #13#10 +
        'Rechtsklik: A1 of A2 kiezen.',
      'A voltage source from 0 to 5 V with two terminals: + at the top, - at the bottom (to the - rail).' + #13#10 +
        'Right-click: choose A1 or A2.',
      'Une source de tension de 0 à 5 V à deux bornes : + en haut, - en bas (vers le rail -).' + #13#10 +
        'Clic droit : choisir A1 ou A2.',
      'Eine Spannungsquelle von 0 bis 5 V mit zwei Klemmen: + oben, - unten (zur - Schiene).' + #13#10 +
        'Rechtsklick: A1 oder A2 wählen.');
end;

procedure TjanK8055Ana.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Tr(FTaal, 'K8055-analoge ingang', 'K8055 analog input', 'Entrée analogique K8055', 'Analoger K8055-Eingang') + ' > ', 0);
  FOnStatus(Self, 'A' + IntToStr(FNr) + ': ' + FormatFloat('0.00', Emk) + ' V', 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;
