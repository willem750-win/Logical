{ jsl_board.inc - onderdelen voor een echt Arduino-board (via USB en Firmata):
  TjanBoardIn (een echte drukknop als schakelaar in de kring) en TjanBoardUit
  (een lamp van 5 V die een echte pin hoog of laag zet). De verbinding zelf
  (seriële poort, Firmata) zit in het programma: zie BoardSchrijf en
  BoardVerbonden, en uBoard.pas in projects/LogicCEF. }

// naam van een pin van een Arduino Uno: 2..13 = D2..D13, 14..19 = A0..A5
function BoardPinNaam(APin: Integer): string;
begin
  if APin >= 14 then Result := 'A' + IntToStr(APin - 14)
  else Result := 'D' + IntToStr(APin);
end;

{ TjanBoardIn }

constructor TjanBoardIn.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Soort := 1;           // een drukknop: dicht zolang de echte knop ingedrukt is
  FPin := 2;
  HelpKeyword := 'board';
end;

procedure TjanBoardIn.SetPin(const Value: Integer);
begin
  if (Value < 2) or (Value > 19) or (Value = FPin) then Exit;
  FPin := Value;
  UpdateHintText;
  Invalidate;
end;

procedure TjanBoardIn.PinClick(Sender: TObject);
begin
  Pin := TMenuItem(Sender).Tag;
end;

// met een board volgt hij de echte knop; zonder board werkt hij met de muis
function TjanBoardIn.HandleClick(X, Y: Integer): Boolean;
begin
  if BoardVerbonden then
    Result := False
  else
    Result := inherited HandleClick(X, Y);
end;

procedure TjanBoardIn.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if BoardVerbonden then Exit;
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TjanBoardIn.AddMenuItems(APop: TPopupMenu);
var
  Mi, Sub: TMenuItem;
  i: Integer;
begin
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Pin van de Arduino', 'Arduino pin', 'Broche de l''Arduino', 'Pin des Arduino');
  APop.Items.Add(Mi);
  for i := 2 to 19 do
  begin
    Sub := TMenuItem.Create(APop);
    Sub.Caption := BoardPinNaam(i);
    Sub.Tag := i;
    Sub.RadioItem := True;
    Sub.Checked := i = FPin;
    Sub.Enabled := not FLock;
    Sub.OnClick := PinClick;
    Mi.Add(Sub);
  end;
end;

procedure TjanBoardIn.Paint;
begin
  inherited Paint;
  with Canvas do
  begin
    Brush.Style := bsClear;
    Font.Name := 'Arial'; Font.Size := 7; Font.Style := [fsBold];
    if BoardVerbonden then Font.Color := RGBToColor(0, 130, 140) else Font.Color := clGray;
    with TP(2, 0) do TextOut(X, Y, BoardPinNaam(FPin));
  end;
end;

procedure TjanBoardIn.UpdateHintText;
var
  S: string;
begin
  if BoardVerbonden then
    S := Tr(FTaal, 'Het board is verbonden: de echte drukknop bedient dit contact.',
      'The board is connected: the real push button operates this contact.',
      'La carte est connectée : le vrai bouton-poussoir commande ce contact.',
      'Das Board ist verbunden: Der echte Taster betätigt diesen Kontakt.')
  else
    S := Tr(FTaal, 'Geen board verbonden: druk er met de muis op, zoals op een drukknop.',
      'No board connected: press it with the mouse, like a push button.',
      'Aucune carte connectée : appuyez dessus avec la souris, comme sur un bouton-poussoir.',
      'Kein Board verbunden: Drücken Sie mit der Maus darauf, wie auf einen Taster.');
  Hint := Tr(FTaal, 'Arduino-ingang', 'Arduino input', 'Entrée Arduino', 'Arduino-Eingang') + ' ' +
    BoardPinNaam(FPin) + #13#10 + S + #13#10 +
    Tr(FTaal,
      'Sluit de drukknop aan tussen de pin en GND (een weerstand is niet nodig).' + #13#10 +
        'Ingedrukt is het contact dicht. Rechtsklik: pin kiezen.',
      'Connect the push button between the pin and GND (no resistor needed).' + #13#10 +
        'Pressed, the contact is closed. Right-click: choose the pin.',
      'Branchez le bouton-poussoir entre la broche et GND (pas besoin de résistance).' + #13#10 +
        'Appuyé, le contact est fermé. Clic droit : choisir la broche.',
      'Schließen Sie den Taster zwischen Pin und GND an (kein Widerstand nötig).' + #13#10 +
        'Gedrückt ist der Kontakt geschlossen. Rechtsklick: Pin wählen.');
end;

procedure TjanBoardIn.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Tr(FTaal, 'Arduino-ingang', 'Arduino input', 'Entrée Arduino', 'Arduino-Eingang') + ' > ', 0);
  if Aan then
    FOnStatus(Self, BoardPinNaam(FPin) + ': ' + Tr(FTaal, 'ingedrukt', 'pressed', 'appuyé', 'gedrückt'), 1)
  else
    FOnStatus(Self, BoardPinNaam(FPin) + ': ' + Tr(FTaal, 'los', 'released', 'relâché', 'los'), 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

{ TjanBoardUit }

constructor TjanBoardUit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Soort := Lamp2Standaard5V;   // een lamp van 5 V: hij brandt aan een poort
  FPin := 13;                  // D13: daar zit ook het ledje op het board
  FGestuurd := -1;
  HelpKeyword := 'board';
end;

function TjanBoardUit.LampLabel: string;
begin
  Result := 'UNO ' + BoardPinNaam(FPin);
end;

procedure TjanBoardUit.SetPin(const Value: Integer);
begin
  if (Value < 2) or (Value > 13) or (Value = FPin) then Exit;
  // de oude pin laag zetten, de nieuwe meteen sturen
  if BoardVerbonden and Assigned(BoardSchrijf) and (FGestuurd = 1) then
    BoardSchrijf(FPin, False);
  FPin := Value;
  FGestuurd := -1;
  Stuur;
  UpdateHintText;
  Invalidate;
end;

procedure TjanBoardUit.PinClick(Sender: TObject);
begin
  Pin := TMenuItem(Sender).Tag;
end;

procedure TjanBoardUit.AddMenuItems(APop: TPopupMenu);
var
  Mi, Sub: TMenuItem;
  i: Integer;
begin
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Pin van de Arduino', 'Arduino pin', 'Broche de l''Arduino', 'Pin des Arduino');
  APop.Items.Add(Mi);
  for i := 2 to 13 do
  begin
    Sub := TMenuItem.Create(APop);
    Sub.Caption := BoardPinNaam(i);
    Sub.Tag := i;
    Sub.RadioItem := True;
    Sub.Checked := i = FPin;
    Sub.Enabled := not FLock;
    Sub.OnClick := PinClick;
    Mi.Add(Sub);
  end;
end;

procedure TjanBoardUit.Stuur(AltijdSturen: Boolean);
var
  V: Integer;
begin
  if not (BoardVerbonden and Assigned(BoardSchrijf)) then
  begin
    FGestuurd := -1;
    Exit;
  end;
  V := Ord(Aan);
  if AltijdSturen or (V <> FGestuurd) then
    BoardSchrijf(FPin, V = 1);
  FGestuurd := V;
end;

procedure TjanBoardUit.UpdateHintText;
var
  S: string;
begin
  if BoardVerbonden then
    S := Tr(FTaal, 'Het board is verbonden: brandt deze lamp, dan is de pin hoog (5 V).',
      'The board is connected: when this lamp is lit, the pin is high (5 V).',
      'La carte est connectée : quand cette lampe brille, la broche est haute (5 V).',
      'Das Board ist verbunden: Leuchtet diese Lampe, ist der Pin hoch (5 V).')
  else
    S := Tr(FTaal, 'Geen board verbonden: alleen de lamp op het scherm brandt.',
      'No board connected: only the lamp on the screen lights.',
      'Aucune carte connectée : seule la lampe à l''écran s''allume.',
      'Kein Board verbunden: Nur die Lampe auf dem Bildschirm leuchtet.');
  Hint := Tr(FTaal, 'Arduino-uitgang', 'Arduino output', 'Sortie Arduino', 'Arduino-Ausgang') + ' ' +
    BoardPinNaam(FPin) + #13#10 + S + #13#10 +
    Tr(FTaal,
      'Sluit op de pin een led aan met een weerstand van 220 ohm naar GND. Een pin geeft hoogstens 20 mA:' + #13#10 +
        'een lamp, motor of relais stuur je via een transistor. Rechtsklik: pin kiezen.',
      'Connect an LED with a 220 ohm resistor to GND on the pin. A pin gives at most 20 mA:' + #13#10 +
        'drive a lamp, motor or relay through a transistor. Right-click: choose the pin.',
      'Branchez sur la broche une LED avec une résistance de 220 ohms vers GND. Une broche donne au plus 20 mA :' + #13#10 +
        'commandez une lampe, un moteur ou un relais par un transistor. Clic droit : choisir la broche.',
      'Schließen Sie am Pin eine LED mit einem Widerstand von 220 Ohm nach GND an. Ein Pin liefert höchstens 20 mA:' + #13#10 +
        'eine Lampe, einen Motor oder ein Relais steuern Sie über einen Transistor. Rechtsklick: Pin wählen.');
end;

procedure TjanBoardUit.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Tr(FTaal, 'Arduino-uitgang', 'Arduino output', 'Sortie Arduino', 'Arduino-Ausgang') + ' > ', 0);
  if Aan then
    FOnStatus(Self, BoardPinNaam(FPin) + ': ' + Tr(FTaal, 'hoog (5 V)', 'high (5 V)', 'haut (5 V)', 'hoch (5 V)'), 1)
  else
    FOnStatus(Self, BoardPinNaam(FPin) + ': ' + Tr(FTaal, 'laag (0 V)', 'low (0 V)', 'bas (0 V)', 'niedrig (0 V)'), 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;
