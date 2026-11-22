// janSimLogic.pas, deel: motor, persoon, wagentje, muziekdoos, verkeerslicht, slagboom (ingevoegd met {$I jsl_bewegend.inc})


// ============================================================
// TjanSimMotor: motor met ingangen L (linksom) en R (rechtsom)
// ============================================================

const
  MO_W = 80;            // breedte van de motor
  MO_H = 52;            // hoogte van de motor
  MO_CX = 50;           // middelpunt en straal van de motorcirkel
  MO_CY = 26;
  MO_R = 17;

constructor TjanSimMotor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := MO_W;
  Height := MO_H;
  Connectors := TList.Create;
  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.Interval := 60;
  FTimer.OnTimer := TimerTick;
  FAngle := 90;
  FTaal := 'NL';
  FNaam := 'Motor';
  HelpKeyword := 'motor';
  ShowHint := True;
end;

destructor TjanSimMotor.Destroy;
begin
  FTimer.Enabled := False;
  Connectors.Free;
  inherited;
end;

class function TjanSimMotor.InputPinY(I: Integer): Integer;
begin
  if I = 0 then Result := 8 else Result := 36;
end;

function TjanSimMotor.InputPinAt(const P: TPoint): Integer;
var
  i: Integer;
begin
  Result := -1;
  if (P.X < Left - 8) or (P.X > Left + 18) then Exit;
  for i := 0 to 1 do
    if Abs(P.Y - (Top + InputPinY(i) + 3)) <= 10 then
      Exit(i);
end;

function TjanSimMotor.GetInput(I: Integer): Boolean;
begin
  Result := FIn[I];
end;

function TjanSimMotor.Fault: Boolean;
begin
  Result := FIn[0] and FIn[1];
end;

function TjanSimMotor.Direction: Integer;
begin
  if FIn[0] and not FIn[1] then Result := -1
  else if FIn[1] and not FIn[0] then Result := 1
  else Result := 0;
end;

procedure TjanSimMotor.SetInput(I: Integer; Value: Boolean);
begin
  if (I < 0) or (I > 1) or (FIn[I] = Value) then Exit;
  FIn[I] := Value;
  UpdateTimer;
  Invalidate;
  if FMouseOver then
    SendStatusToBar;
end;

procedure TjanSimMotor.UpdateTimer;
begin
  FTimer.Enabled := Direction <> 0;
end;

procedure TjanSimMotor.TimerTick(Sender: TObject);
begin
  // rechtsom = met de klok mee: de hoek (tegen de klok in gemeten) daalt
  FAngle := (FAngle - Direction * 15 + 360) mod 360;
  Invalidate;
end;

procedure TjanSimMotor.SetTaal(const Value: string);
begin
  FTaal := Value;
  UpdateHintText;
  if FMouseOver then
    SendStatusToBar;
end;

procedure TjanSimMotor.Paint;
var
  i, y: Integer;
  BW, BH: Integer;   // maten van de motor (in 'with Canvas' zijn Width/Height die van het canvas)
  S: TjanSymbolen;
  Q: TPoint;
begin
  BW := Self.Width;
  BH := Self.Height;
  S := SymOf(Self);
  with Canvas do
  begin
    // aansluitdraden: L en R naar de motor, rechts naar de - kant
    SymPen(Canvas, clBlack);
    for i := 0 to 1 do
    begin
      y := InputPinY(i) + 3;
      Line(8, y, 24, y);
      if i = 0 then
        Q := Point(MO_CX - Round(MO_R * 0.82), MO_CY - Round(MO_R * 0.57))
      else
        Q := Point(MO_CX - Round(MO_R * 0.82), MO_CY + Round(MO_R * 0.57));
      Line(24, y, Q.X, Q.Y);
    end;
    Line(MO_CX + MO_R, MO_CY, BW, MO_CY);

    DrawMotorSymbol(Canvas, MO_CX, MO_CY, MO_R, FAngle, Direction, Fault, S);

    // aansluitingen en letters
    for i := 0 to 1 do
    begin
      y := InputPinY(i);
      Brush.Style := bsSolid;
      Brush.Color := clLime;
      Pen.Color := clGray;
      Rectangle(1, y, 8, y + 7);
      Brush.Style := bsClear;
      Font.Name := 'Arial';
      Font.Size := 7;
      Font.Style := [fsBold];
      if FIn[i] then Font.Color := clRed else Font.Color := clNavy;
      if i = 0 then TextOut(11, y - 9, 'L') else TextOut(11, y + 6, 'R');
    end;
    if Fault then
    begin
      Brush.Style := bsClear;
      Font.Name := 'Arial';
      Font.Size := 12;
      Font.Style := [fsBold];
      Font.Color := clRed;
      TextOut(BW - 10, 0, '!');
    end;
    if FSelect or FSelected then
    begin
      Brush.Style := bsClear;
      if FSelected then Pen.Color := clRed else Pen.Color := clBlack;
      Pen.Style := psDot;
      Rectangle(0, 0, BW, BH);
      Pen.Style := psSolid;
    end;
    Brush.Style := bsSolid;
  end;
end;

function TjanSimMotor.StatusText: string;
begin
  if Fault then
    Result := Tr(FTaal, 'L en R samen aan: fout!', 'L and R on together: fault!',
                        'L et R ensemble : défaut !', 'L und R zusammen ein: Fehler!')
  else if Direction < 0 then
    Result := Tr(FTaal, 'draait linksom', 'turning left', 'tourne à gauche', 'dreht links')
  else if Direction > 0 then
    Result := Tr(FTaal, 'draait rechtsom', 'turning right', 'tourne à droite', 'dreht rechts')
  else
    Result := Tr(FTaal, 'stil', 'stopped', 'arrêté', 'steht still');
end;

procedure TjanSimMotor.UpdateHintText;
begin
  Hint := BuildSimHint(FNaam, FTaal) + #13#10 +
    Tr(FTaal, 'L: linksom, R: rechtsom', 'L: turn left, R: turn right',
              'L : à gauche, R : à droite', 'L: links, R: rechts');
end;

procedure TjanSimMotor.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, FNaam + ' > ', 0);
  FOnStatus(Self, StatusText, 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

procedure TjanSimMotor.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
  UpdateHintText;
  if Assigned(FOnEnter) then
    FOnEnter(Self);
  FMouseOver := True;
  SendStatusToBar;
  if not FLock then
  begin
    FSelect := True;
    Invalidate;
  end;
end;

procedure TjanSimMotor.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
  if Assigned(FOnExit) then
    FOnExit(Self);
  if not FMouseOver then Exit;
  FMouseOver := False;
  if Assigned(FOnStatus) then
  begin
    FOnStatus(Self, '', 0);
    FOnStatus(Self, '', 1);
    FOnStatus(Self, '', 2);
    FOnStatus(Self, '', 3);
  end;
  FSelect := False;
  Invalidate;
end;

procedure TjanSimMotor.BuildPopup;
var
  Mi: TMenuItem;
begin
  if not Assigned(PopupMenu) then
    PopupMenu := TPopupMenu.Create(Self)
  else
    PopupMenu.Items.Clear;
  Mi := TMenuItem.Create(PopupMenu);
  if FLock then
    Mi.Caption := Tr(FTaal, 'Ontgrendel', 'Unlock', 'Déverrouiller', 'Entsperren')
  else
    Mi.Caption := Tr(FTaal, 'Vergrendel', 'Lock', 'Verrouiller', 'Sperren');
  Mi.OnClick := LockClick;
  PopupMenu.Items.Add(Mi);
  Mi := TMenuItem.Create(PopupMenu);
  Mi.Caption := Tr(FTaal, 'Selecteer object', 'Select object', 'Sélectionner l''objet', 'Objekt auswählen');
  Mi.OnClick := SelectClick;
  PopupMenu.Items.Add(Mi);
end;

procedure TjanSimMotor.LockClick(Sender: TObject);
begin
  FLock := not FLock;
  Invalidate;
end;

procedure TjanSimMotor.SelectClick(Sender: TObject);
begin
  if Assigned(FBox) then
    FBox.SelectObject(Self);
end;

procedure TjanSimMotor.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
begin
  inherited;
  if (Button = mbRight) and not FLock then
  begin
    BuildPopup;
    P := ClientToScreen(Point(0, Height));
    PopupMenu.Popup(P.X, P.Y - 1);
    Exit;
  end;
  doMove := False;
  mdp := Point(X, Y);
  Screen.Cursor := crDefault;
  if Button <> mbLeft then Exit;
  doMove := True;
  AnchorConnectors;
  if Parent is TjanGridS then
    TjanGridS(Parent).BeginGuideLines(Left + Width div 2, Top + Height div 2);
end;

procedure TjanSimMotor.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  P, SnapP: TPoint;
  Grid: TjanGridS;
  WorkR: TRect;
begin
  inherited;
  if FLock or (Parent = nil) then Exit;
  if not ((ssLeft in Shift) and doMove) then Exit;
  P := Parent.ScreenToClient(ClientToScreen(Point(X, Y)));
  NewLeft := P.X - mdp.X;
  NewTop := P.Y - mdp.Y;
  if Parent is TjanGridS then
  begin
    Grid := TjanGridS(Parent);
    WorkR := Grid.GetWorkAreaRect;
    SnapP := Grid.SnapPointToRuler(Point(NewLeft + Width div 2, NewTop + Height div 2), WorkR);
    NewLeft := SnapP.X - Width div 2;
    NewTop := SnapP.Y - Height div 2;
  end;
  StraightenWires(Connectors, NewLeft, NewTop);
  SnapToRail(Self, NewLeft);
  Left := NewLeft;
  Top := NewTop;
  MoveConnectors;
  if Parent is TjanGridS then
    TjanGridS(Parent).UpdateGuideLines(Left + Width div 2, Top + Height div 2);
  FMouseOver := True;
  SendStatusToBar;
end;

procedure TjanSimMotor.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Parent is TjanGridS then
    TjanGridS(Parent).EndGuideLines;
  doMove := False;
  if Assigned(Parent) then
    Parent.Invalidate;   // stekker en bolletje van de voedingsrail
end;

procedure TjanSimMotor.AnchorConnectors;
var
  i: Integer;
  Con: TjanConnector;
  R: TRect;
begin
  Connectors.Clear;
  if Parent = nil then Exit;
  R := BoundsRect;
  InflateRect(R, 8, 8);
  for i := 0 to Parent.ControlCount - 1 do
    if Parent.Controls[i] is TjanConnector then
    begin
      Con := TjanConnector(Parent.Controls[i]);
      // alleen de echte uiteinden van de draad (zie TjanConnector.AnchorToRect)
      if Con.AnchorToRect(R, Point(Left, Top)) then
        Connectors.Add(Con);
    end;
end;

procedure TjanSimMotor.MoveConnectors;
var
  i: Integer;
begin
  for i := 0 to Connectors.Count - 1 do
    TjanConnector(Connectors[i]).MoveConnector(Point(NewLeft, NewTop));
end;


// ============================================================
// TjanSimPersoon: persoon die heen en weer loopt, met eindschakelaars
// ============================================================

const
  PE_W = 260;           // breedte van het blok
  PE_H = 90;            // hoogte van het blok
  PE_TL = 40;           // linker eindschakelaar (x)
  PE_TR = PE_W - 44;    // rechter eindschakelaar (x)
  PE_VLOER = 82;        // hoogte van de vloer (y)
  PE_BREED = 20;        // breedte van de persoon
  PE_STAP = 3;          // pixels per tik van de timer

constructor TjanSimPersoon.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := PE_W;
  Height := PE_H;
  Connectors := TList.Create;
  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.Interval := 60;
  FTimer.OnTimer := TimerTick;
  FKijk := 1;
  FTaal := 'NL';
  FNaam := 'Persoon';
  HelpKeyword := 'persoon';
  ShowHint := True;
end;

destructor TjanSimPersoon.Destroy;
begin
  FTimer.Enabled := False;
  Connectors.Free;
  inherited;
end;

// De ingangen L en R zitten links bovenaan: rechts van LogicRun gezet (in
// de uitvoer) komen de draden van UIT0/UIT1 er recht op toe. Rechts zit de
// - kant (voedingsbolletje) voor de rail.
class function TjanSimPersoon.PinY(I: Integer): Integer;
begin
  Result := 6 + 16 * I;   // 6 en 22
end;

function TjanSimPersoon.OutputCount: Integer;
begin
  Result := 2;
end;

function TjanSimPersoon.OutputName(I: Integer): string;
begin
  Result := 'S' + IntToStr(I + 1);
end;

function TjanSimPersoon.PulsTeller(I: Integer): Integer;
begin
  Result := -1;
end;

function TjanSimPersoon.InputCount: Integer;
begin
  Result := 2;
end;

function TjanSimPersoon.InPinY(I: Integer): Integer;
begin
  Result := PinY(I);
end;

function TjanSimPersoon.InputPinAt(const P: TPoint): Integer;
var
  i: Integer;
begin
  Result := -1;
  if (P.X < Left - 8) or (P.X > Left + 18) then Exit;
  for i := 0 to InputCount - 1 do
    if Abs(P.Y - (Top + InPinY(i) + 3)) <= 5 then
      Exit(i);
end;

// voor elke stand (S1, S2 of Start, Tel, Finish) een eindschakelaar in de
// invoer, links op het paneel en onder elkaar vanaf de hoogte van het blok
procedure TjanSimPersoon.PlaatsEindschakelaars;
var
  i, X, Y: Integer;
  E: TjanSimEindschakelaar;

  // staat er al iets (geen draad of rail) op die plaats?
  function Bezet(const R: TRect): Boolean;
  var
    k: Integer;
    C: TControl;
    T: TRect;
  begin
    Result := False;
    for k := 0 to Parent.ControlCount - 1 do
    begin
      C := Parent.Controls[k];
      if (C is TjanConnector) or (C is TjanRail) or not C.Visible then Continue;
      if IntersectRect(T, R, C.BoundsRect) then Exit(True);
    end;
  end;

begin
  if Parent = nil then Exit;
  X := 100;
  if Parent is TjanGridS then
    X := TjanGridS(Parent).GetWorkAreaRect.Left + 100;
  Y := Top;
  for i := 0 to OutputCount - 1 do
  begin
    // naar beneden tot er een vrije plaats is
    while Bezet(Rect(X, Y - 4, X + 60, Y + 40)) and (Y < Top + 600) do
      Inc(Y, 10);
    E := TjanSimEindschakelaar.Create(Owner);
    E.Parent := Parent;
    E.Kanaal := i;
    E.BTaal := FTaal;
    E.SetBounds(X, Y, E.Width, E.Height);
    Inc(Y, E.Height + 10);
  end;
end;

procedure TjanSimPersoon.EindClick(Sender: TObject);
begin
  PlaatsEindschakelaars;
end;

// verandert er een stand (S1, S2 of Start, Tel, Finish), dan meteen de
// eindschakelaars op het paneel laten hertekenen (hun eigen timer is reserve)
procedure TjanSimPersoon.MeldEindschakelaars;
var
  i, M: Integer;
begin
  M := 0;
  for i := 0 to OutputCount - 1 do
    if Outputs[i] then M := M or (1 shl i);
  if M = FUitMask then Exit;
  FUitMask := M;
  if Parent = nil then Exit;
  for i := 0 to Parent.ControlCount - 1 do
    if Parent.Controls[i] is TjanSimEindschakelaar then
      Parent.Controls[i].Invalidate;
end;

function TjanSimPersoon.Range: Integer;
begin
  Result := PE_TR - PE_TL - PE_BREED;
end;

function TjanSimPersoon.GetInput(I: Integer): Boolean;
begin
  Result := FIn[I];
end;

function TjanSimPersoon.GetOutput(I: Integer): Boolean;
begin
  if I = 0 then Result := FPos <= 0 else Result := FPos >= Range;
end;

function TjanSimPersoon.Fault: Boolean;
begin
  Result := FIn[0] and FIn[1];
end;

function TjanSimPersoon.Direction: Integer;
begin
  if FIn[0] and not FIn[1] then Result := -1
  else if FIn[1] and not FIn[0] then Result := 1
  else Result := 0;
end;

procedure TjanSimPersoon.SetInput(I: Integer; Value: Boolean);
begin
  if (I < 0) or (I >= InputCount) or (FIn[I] = Value) then Exit;
  FIn[I] := Value;
  if Direction <> 0 then FKijk := Direction;
  UpdateTimer;
  Invalidate;
  if FMouseOver then
    SendStatusToBar;
end;

procedure TjanSimPersoon.UpdateTimer;
begin
  FTimer.Enabled := Direction <> 0;
  if not FTimer.Enabled then FFrame := 0;
end;

procedure TjanSimPersoon.Tick;
var
  NewPos: Integer;
begin
  if Direction = 0 then Exit;
  NewPos := FPos + Direction * PE_STAP;
  if NewPos < 0 then NewPos := 0;
  if NewPos > Range then NewPos := Range;
  // tegen de eindschakelaar: blijven staan (de benen ook)
  if NewPos = FPos then
    FFrame := 0
  else
    FFrame := (FFrame + 1) mod 4;
  FPos := NewPos;
  Invalidate;
  MeldEindschakelaars;
  if FMouseOver then
    SendStatusToBar;
end;

procedure TjanSimPersoon.TimerTick(Sender: TObject);
begin
  Tick;
end;

procedure TjanSimPersoon.ToStart;
begin
  FPos := 0;
  FFrame := 0;
  FKijk := 1;
  UpdateTimer;   // slagboom met O aan: weer omhoog
  Invalidate;
  MeldEindschakelaars;
end;

procedure TjanSimPersoon.SetTaal(const Value: string);
begin
  FTaal := Value;
  UpdateHintText;
  if FMouseOver then
    SendStatusToBar;
end;

procedure TjanSimPersoon.Paint;
const
  Benen: array[0..3] of Integer = (7, 4, 1, 4);   // halve spreiding per stand
  Huid = $0099CCFF;
var
  i, y, cx, s, a: Integer;
  BW, BH: Integer;
  Aan: Boolean;
  Lbl: string;
begin
  BW := Self.Width;
  BH := Self.Height;
  with Canvas do
  begin
    Font.Name := 'Arial';
    Font.Size := 7;
    Font.Style := [fsBold];

    // vloer met arcering
    Pen.Width := 1;
    Pen.Color := clGray;
    Line(PE_TL, PE_VLOER, PE_TR + 1, PE_VLOER);
    i := PE_TL + 4;
    while i <= PE_TR do
    begin
      Line(i, PE_VLOER + 1, i - 4, PE_VLOER + 5);
      Inc(i, 8);
    end;

    // eindschakelaars: paaltje met een lampje, rood als hij ingedrukt is
    for i := 0 to 1 do
    begin
      Aan := Outputs[i];
      if i = 0 then a := PE_TL - 6 else a := PE_TR + 1;
      Brush.Style := bsSolid;
      Brush.Color := clSilver;
      Pen.Color := clGray;
      Rectangle(a, PE_VLOER - 22, a + 6, PE_VLOER + 1);
      if Aan then Brush.Color := clRed else Brush.Color := clWhite;
      Ellipse(a - 1, PE_VLOER - 31, a + 7, PE_VLOER - 23);
      Brush.Style := bsClear;
      if Aan then Font.Color := clRed else Font.Color := clNavy;
      Lbl := 'S' + IntToStr(i + 1);
      TextOut(a + 3 - TextWidth(Lbl) div 2, PE_VLOER - 43, Lbl);
    end;

    // ingangen L en R links (de eindschakelaars lees je met een
    // TjanSimEindschakelaar in de invoer)
    for i := 0 to 1 do
    begin
      y := PinY(i);
      Brush.Style := bsSolid;
      Brush.Color := clLime;
      Pen.Color := clGray;
      Rectangle(1, y, 8, y + 7);
      Brush.Style := bsClear;
      if FIn[i] then Font.Color := clRed else Font.Color := clNavy;
      if i = 0 then Lbl := 'L' else Lbl := 'R';
      TextOut(12, y - 2, Lbl);
    end;

    // de persoon
    cx := PE_TL + PE_BREED div 2 + FPos;
    if Direction <> 0 then s := Benen[FFrame] else s := 2;
    // benen (broek) met schoenen
    Pen.Width := 3;
    Pen.Color := $00404040;
    Line(cx, PE_VLOER - 17, cx + s, PE_VLOER - 3);
    Line(cx, PE_VLOER - 17, cx - s, PE_VLOER - 3);
    Pen.Color := clBlack;
    Line(cx + s, PE_VLOER - 2, cx + s + 3 * FKijk, PE_VLOER - 2);
    Line(cx - s, PE_VLOER - 2, cx - s + 3 * FKijk, PE_VLOER - 2);
    // armen zwaaien tegengesteld aan de benen
    Pen.Width := 2;
    Pen.Color := Huid;
    Line(cx, PE_VLOER - 30, cx - s, PE_VLOER - 19);
    Line(cx, PE_VLOER - 30, cx + s, PE_VLOER - 19);
    // romp: blauw shirt
    Pen.Width := 1;
    Pen.Color := clNavy;
    Brush.Style := bsSolid;
    Brush.Color := $00D07020;
    RoundRect(cx - 5, PE_VLOER - 33, cx + 6, PE_VLOER - 15, 4, 4);
    // hoofd met haar en een oog in de kijkrichting
    Pen.Color := $00305080;
    Brush.Color := Huid;
    Ellipse(cx - 6, PE_VLOER - 46, cx + 7, PE_VLOER - 33);
    Brush.Color := $00305080;
    Pie(cx - 6, PE_VLOER - 46, cx + 7, PE_VLOER - 33,
        cx + 7, PE_VLOER - 41, cx - 6, PE_VLOER - 41);
    Pen.Color := clBlack;
    Brush.Color := clBlack;
    Rectangle(cx + 3 * FKijk, PE_VLOER - 40, cx + 3 * FKijk + 2, PE_VLOER - 38);

    if Fault then
    begin
      Brush.Style := bsClear;
      Font.Size := 12;
      Font.Color := clRed;
      TextOut(BW div 2 - 2, 0, '!');
    end;
    if FSelect or FSelected then
    begin
      Brush.Style := bsClear;
      if FSelected then Pen.Color := clRed else Pen.Color := clBlack;
      Pen.Style := psDot;
      Rectangle(0, 0, BW, BH);
      Pen.Style := psSolid;
    end;
    Brush.Style := bsSolid;
    Pen.Width := 1;
  end;
end;

function TjanSimPersoon.StatusText: string;
begin
  if Fault then
    Result := Tr(FTaal, 'L en R samen aan: blijft staan', 'L and R on together: stands still',
                        'L et R ensemble : reste immobile', 'L und R zusammen ein: bleibt stehen')
  else if Outputs[0] and (Direction <= 0) then
    Result := Tr(FTaal, 'staat links (S1 aan)', 'at the left (S1 on)',
                        'à gauche (S1 actif)', 'steht links (S1 ein)')
  else if Outputs[1] and (Direction >= 0) then
    Result := Tr(FTaal, 'staat rechts (S2 aan)', 'at the right (S2 on)',
                        'à droite (S2 actif)', 'steht rechts (S2 ein)')
  else if Direction < 0 then
    Result := Tr(FTaal, 'loopt naar links', 'walking left', 'marche vers la gauche', 'geht nach links')
  else if Direction > 0 then
    Result := Tr(FTaal, 'loopt naar rechts', 'walking right', 'marche vers la droite', 'geht nach rechts')
  else
    Result := Tr(FTaal, 'staat stil', 'standing still', 'immobile', 'steht still');
end;

procedure TjanSimPersoon.UpdateHintText;
begin
  Hint := BuildSimHint(FNaam, FTaal) + #13#10 +
    Tr(FTaal, 'L: naar links, R: naar rechts' + #13#10 + 'S1/S2: eindschakelaar links/rechts' + #13#10 + 'rechtsklik: eindschakelaars plaatsen',
              'L: walk left, R: walk right' + #13#10 + 'S1/S2: limit switch left/right' + #13#10 + 'right-click: place limit switches',
              'L : à gauche, R : à droite' + #13#10 + 'S1/S2 : fin de course gauche/droite' + #13#10 + 'clic droit : placer les fins de course',
              'L: nach links, R: nach rechts' + #13#10 + 'S1/S2: Endschalter links/rechts' + #13#10 + 'Rechtsklick: Endschalter setzen');
end;

procedure TjanSimPersoon.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, FNaam + ' > ', 0);
  FOnStatus(Self, StatusText, 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

procedure TjanSimPersoon.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
  UpdateHintText;
  if Assigned(FOnEnter) then
    FOnEnter(Self);
  FMouseOver := True;
  SendStatusToBar;
  if not FLock then
  begin
    FSelect := True;
    Invalidate;
  end;
end;

procedure TjanSimPersoon.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
  if Assigned(FOnExit) then
    FOnExit(Self);
  if not FMouseOver then Exit;
  FMouseOver := False;
  if Assigned(FOnStatus) then
  begin
    FOnStatus(Self, '', 0);
    FOnStatus(Self, '', 1);
    FOnStatus(Self, '', 2);
    FOnStatus(Self, '', 3);
  end;
  FSelect := False;
  Invalidate;
end;

procedure TjanSimPersoon.BuildPopup;
var
  Mi: TMenuItem;
begin
  if not Assigned(PopupMenu) then
    PopupMenu := TPopupMenu.Create(Self)
  else
    PopupMenu.Items.Clear;
  Mi := TMenuItem.Create(PopupMenu);
  if FLock then
    Mi.Caption := Tr(FTaal, 'Ontgrendel', 'Unlock', 'Déverrouiller', 'Entsperren')
  else
    Mi.Caption := Tr(FTaal, 'Vergrendel', 'Lock', 'Verrouiller', 'Sperren');
  Mi.OnClick := LockClick;
  PopupMenu.Items.Add(Mi);
  Mi := TMenuItem.Create(PopupMenu);
  Mi.Caption := Tr(FTaal, 'Selecteer object', 'Select object', 'Sélectionner l''objet', 'Objekt auswählen');
  Mi.OnClick := SelectClick;
  PopupMenu.Items.Add(Mi);
  Mi := TMenuItem.Create(PopupMenu);
  if Self is TjanSimWagen then
    Mi.Caption := Tr(FTaal, 'Terug naar de start', 'Back to the start',
                            'Retour au départ', 'Zurück zum Start')
  else if Self is TjanSimSlagboom then
    Mi.Caption := Tr(FTaal, 'Boom meteen dicht', 'Close the barrier now',
                            'Fermer la barrière maintenant', 'Schranke sofort schließen')
  else
    Mi.Caption := Tr(FTaal, 'Terug naar links (S1)', 'Back to the left (S1)',
                            'Retour à gauche (S1)', 'Zurück nach links (S1)');
  Mi.OnClick := StartClick;
  PopupMenu.Items.Add(Mi);
  Mi := TMenuItem.Create(PopupMenu);
  Mi.Caption := Tr(FTaal, 'Eindschakelaars plaatsen', 'Place limit switches',
                          'Placer les fins de course', 'Endschalter setzen');
  Mi.OnClick := EindClick;
  PopupMenu.Items.Add(Mi);
end;

procedure TjanSimPersoon.LockClick(Sender: TObject);
begin
  FLock := not FLock;
  Invalidate;
end;

procedure TjanSimPersoon.SelectClick(Sender: TObject);
begin
  if Assigned(FBox) then
    FBox.SelectObject(Self);
end;

procedure TjanSimPersoon.StartClick(Sender: TObject);
begin
  ToStart;
end;

procedure TjanSimPersoon.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
begin
  inherited;
  if (Button = mbRight) and not FLock then
  begin
    BuildPopup;
    P := ClientToScreen(Point(0, Height));
    PopupMenu.Popup(P.X, P.Y - 1);
    Exit;
  end;
  doMove := False;
  mdp := Point(X, Y);
  Screen.Cursor := crDefault;
  if Button <> mbLeft then Exit;
  doMove := True;
  AnchorConnectors;
  if Parent is TjanGridS then
    TjanGridS(Parent).BeginGuideLines(Left + Width div 2, Top + Height div 2);
end;

procedure TjanSimPersoon.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  P, SnapP: TPoint;
  Grid: TjanGridS;
  WorkR: TRect;
begin
  inherited;
  if FLock or (Parent = nil) then Exit;
  if not ((ssLeft in Shift) and doMove) then Exit;
  P := Parent.ScreenToClient(ClientToScreen(Point(X, Y)));
  NewLeft := P.X - mdp.X;
  NewTop := P.Y - mdp.Y;
  if Parent is TjanGridS then
  begin
    Grid := TjanGridS(Parent);
    WorkR := Grid.GetWorkAreaRect;
    SnapP := Grid.SnapPointToRuler(Point(NewLeft + Width div 2, NewTop + Height div 2), WorkR);
    NewLeft := SnapP.X - Width div 2;
    NewTop := SnapP.Y - Height div 2;
  end;
  StraightenWires(Connectors, NewLeft, NewTop);
  SnapToRail(Self, NewLeft);
  Left := NewLeft;
  Top := NewTop;
  MoveConnectors;
  if Parent is TjanGridS then
    TjanGridS(Parent).UpdateGuideLines(Left + Width div 2, Top + Height div 2);
  FMouseOver := True;
  SendStatusToBar;
end;

procedure TjanSimPersoon.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Parent is TjanGridS then
    TjanGridS(Parent).EndGuideLines;
  doMove := False;
  if Assigned(Parent) then
    Parent.Invalidate;   // stekker en bolletje van de voedingsrail
end;

procedure TjanSimPersoon.AnchorConnectors;
var
  i: Integer;
  Con: TjanConnector;
  R: TRect;
begin
  Connectors.Clear;
  if Parent = nil then Exit;
  R := BoundsRect;
  InflateRect(R, 8, 8);
  for i := 0 to Parent.ControlCount - 1 do
    if Parent.Controls[i] is TjanConnector then
    begin
      Con := TjanConnector(Parent.Controls[i]);
      if Con.AnchorToRect(R, Point(Left, Top)) then
        Connectors.Add(Con);
    end;
end;

procedure TjanSimPersoon.MoveConnectors;
var
  i: Integer;
begin
  for i := 0 to Connectors.Count - 1 do
    TjanConnector(Connectors[i]).MoveConnector(Point(NewLeft, NewTop));
end;



// ============================================================
// TjanSimWagen: wagentje over een kronkelweg, met paaltjes om te tellen
// ============================================================

const
  WG_W = 300;           // breedte van het blok
  WG_H = 165;           // hoogte van het blok
  WG_STAP = 4;          // pixels per tik van de timer
  WG_TEL = 8;           // Tel is aan tot zo ver voor en na een paaltje
  // middenlijn van de weg, van START naar FINISH (alleen rechte stukken)
  WG_PAD: array[0..5] of TPoint = ((X: 90; Y: 62), (X: 250; Y: 62), (X: 250; Y: 102),
                                   (X: 90; Y: 102), (X: 90; Y: 142), (X: 250; Y: 142));
  WG_LEN = 560;         // lengte van de weg (som van de stukken)

constructor TjanSimWagen.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := WG_W;
  Height := WG_H;
  FNaam := 'Wagentje';
  HelpKeyword := 'wagen';
end;

function TjanSimWagen.OutputCount: Integer;
begin
  Result := 3;
end;

function TjanSimWagen.PulsTeller(I: Integer): Integer;
begin
  if I = 1 then Result := FTelTeller else Result := -1;
end;

function TjanSimWagen.OutputName(I: Integer): string;
begin
  case I of
    0: Result := 'Start';
    1: Result := 'Tel';
  else
    Result := 'Finish';
  end;
end;

function TjanSimWagen.Range: Integer;
begin
  Result := WG_LEN;
end;

class function TjanSimWagen.PaaltjePos(N: Integer): Integer;
begin
  Result := (WG_LEN * N) div 6;
end;

function TjanSimWagen.PaaltjeBij: Integer;
var
  N: Integer;
begin
  Result := 0;
  for N := 1 to 5 do
    if Abs(FPos - PaaltjePos(N)) <= WG_TEL then
      Exit(N);
end;

function TjanSimWagen.GetOutput(I: Integer): Boolean;
begin
  case I of
    0: Result := FPos <= 0;
    1: Result := PaaltjeBij > 0;
  else
    Result := FPos >= Range;
  end;
end;

function TjanSimWagen.Direction: Integer;
begin
  if FIn[0] and not FIn[1] then Result := 1
  else if FIn[1] and not FIn[0] then Result := -1
  else Result := 0;
end;

procedure TjanSimWagen.Tick;
var
  NewPos: Integer;
begin
  if Direction = 0 then Exit;
  NewPos := FPos + Direction * WG_STAP;
  if NewPos < 0 then NewPos := 0;
  if NewPos > Range then NewPos := Range;
  FPos := NewPos;
  // bij een paaltje aangekomen: een puls meer voor Tel
  if (PaaltjeBij > 0) and not FOpPaaltje then Inc(FTelTeller);
  FOpPaaltje := PaaltjeBij > 0;
  Invalidate;
  MeldEindschakelaars;
  if FMouseOver then
    SendStatusToBar;
end;

// punt op de weg op afstand D van de start, met de rijrichting (Dx, Dy)
// van dat stuk weg
function TjanSimWagen.PointAt(D: Integer; out Dx, Dy: Integer): TPoint;
var
  i, L: Integer;
begin
  if D < 0 then D := 0;
  Dx := 1;
  Dy := 0;
  Result := WG_PAD[0];
  for i := 0 to High(WG_PAD) - 1 do
  begin
    Dx := 0;
    Dy := 0;
    if WG_PAD[i + 1].X > WG_PAD[i].X then Dx := 1
    else if WG_PAD[i + 1].X < WG_PAD[i].X then Dx := -1;
    if WG_PAD[i + 1].Y > WG_PAD[i].Y then Dy := 1
    else if WG_PAD[i + 1].Y < WG_PAD[i].Y then Dy := -1;
    L := Abs(WG_PAD[i + 1].X - WG_PAD[i].X) + Abs(WG_PAD[i + 1].Y - WG_PAD[i].Y);
    if (D <= L) or (i = High(WG_PAD) - 1) then
    begin
      if D > L then D := L;
      Exit(Point(WG_PAD[i].X + Dx * D, WG_PAD[i].Y + Dy * D));
    end;
    Dec(D, L);
  end;
end;

procedure TjanSimWagen.Paint;
var
  i, y, N, Dx, Dy, HalfL, HalfB: Integer;
  P: TPoint;
  BW, BH: Integer;
  Lbl: string;

  // rechthoek ten opzichte van het midden van de wagen: A langs de
  // rijrichting, B dwars erop (de wagen draait mee met de weg)
  procedure Blok(A1, B1, A2, B2: Integer);
  begin
    if Dx <> 0 then
      Canvas.Rectangle(P.X + Dx * A1, P.Y + B1, P.X + Dx * A2, P.Y + B2)
    else
      Canvas.Rectangle(P.X + B1, P.Y + Dy * A1, P.X + B2, P.Y + Dy * A2);
  end;

begin
  BW := Self.Width;
  BH := Self.Height;
  with Canvas do
  begin
    Font.Name := 'Arial';
    Font.Size := 7;
    Font.Style := [fsBold];

    // de weg met een gestippelde middenlijn
    Pen.Style := psSolid;
    Pen.Width := 16;
    Pen.Color := $00A0A0A0;
    Pen.JoinStyle := pjsRound;
    Pen.EndCap := pecRound;
    Polyline(WG_PAD);
    Pen.Width := 1;
    Pen.Color := clWhite;
    Pen.Style := psDot;
    Polyline(WG_PAD);
    Pen.Style := psSolid;

    // start (groene streep) en finish (geblokte vlag)
    Brush.Style := bsSolid;
    Pen.Color := clGreen;
    Brush.Color := clLime;
    Rectangle(WG_PAD[0].X - 2, WG_PAD[0].Y - 8, WG_PAD[0].X + 3, WG_PAD[0].Y + 9);
    P := WG_PAD[High(WG_PAD)];
    Pen.Color := clBlack;
    Brush.Color := clWhite;
    Rectangle(P.X - 4, P.Y - 8, P.X + 5, P.Y + 9);
    Brush.Color := clBlack;
    for i := 0 to 3 do
      FillRect(Rect(P.X - 4 + 4 * (i mod 2), P.Y - 8 + 4 * i, P.X + 4 * (i mod 2), P.Y - 4 + 4 * i));
    Brush.Style := bsClear;
    if Outputs[0] then Font.Color := clRed else Font.Color := clGreen;
    TextOut(WG_PAD[0].X - TextWidth('START') div 2, WG_PAD[0].Y - 22, 'START');
    if Outputs[2] then Font.Color := clRed else Font.Color := clBlack;
    TextOut(P.X - TextWidth('FINISH') div 2, P.Y + 9, 'FINISH');

    // paaltjes 1..5 naast de weg; het lampje is rood als de wagen er staat
    for N := 1 to 5 do
    begin
      P := PointAt(PaaltjePos(N), Dx, Dy);
      if Dy = 0 then
        Dec(P.Y, 13)
      else if P.X > BW div 2 then
        Inc(P.X, 13)
      else
        Dec(P.X, 13);
      Brush.Style := bsSolid;
      Pen.Color := clGray;
      if PaaltjeBij = N then Brush.Color := clRed else Brush.Color := clWhite;
      Ellipse(P.X - 4, P.Y - 4, P.X + 5, P.Y + 5);
      Brush.Style := bsClear;
      if PaaltjeBij = N then Font.Color := clRed else Font.Color := clNavy;
      TextOut(P.X + 6, P.Y - 6, IntToStr(N));
    end;

    // ingangen V en A links (Start, Tel en Finish lees je met een
    // TjanSimEindschakelaar in de invoer)
    for i := 0 to 1 do
    begin
      y := PinY(i);
      Brush.Style := bsSolid;
      Brush.Color := clLime;
      Pen.Color := clGray;
      Rectangle(1, y, 8, y + 7);
      Brush.Style := bsClear;
      if FIn[i] then Font.Color := clRed else Font.Color := clNavy;
      if i = 0 then Lbl := 'V' else Lbl := 'A';
      TextOut(12, y - 2, Lbl);
    end;

    // de wagen (bovenaanzicht), de neus wijst altijd naar de finish
    P := PointAt(FPos, Dx, Dy);
    HalfL := 11;     // halve lengte
    HalfB := 6;      // halve breedte
    Pen.Color := clBlack;
    Brush.Style := bsSolid;
    Brush.Color := clBlack;
    Blok(-9, -HalfB - 2, -3, -HalfB + 1);     // wielen
    Blok(-9, HalfB - 1, -3, HalfB + 2);
    Blok(3, -HalfB - 2, 9, -HalfB + 1);
    Blok(3, HalfB - 1, 9, HalfB + 2);
    Pen.Color := $00000080;
    Brush.Color := $002828E0;           // rode carrosserie
    Blok(-HalfL, -HalfB, HalfL, HalfB);
    Brush.Color := $00F0D8A0;           // voorruit
    Blok(3, -HalfB + 2, 7, HalfB - 2);
    Brush.Color := $00C0A070;           // achterruit
    Blok(-8, -HalfB + 2, -5, HalfB - 2);
    if Direction < 0 then
    begin
      // achteruitrijlichten
      Pen.Color := clGray;
      Brush.Color := clWhite;
      Blok(-HalfL - 2, -HalfB + 1, -HalfL + 1, -HalfB + 4);
      Blok(-HalfL - 2, HalfB - 4, -HalfL + 1, HalfB - 1);
    end;

    if Fault then
    begin
      Brush.Style := bsClear;
      Font.Size := 12;
      Font.Color := clRed;
      TextOut(BW div 2 - 2, 0, '!');
    end;
    if FSelect or FSelected then
    begin
      Brush.Style := bsClear;
      if FSelected then Pen.Color := clRed else Pen.Color := clBlack;
      Pen.Style := psDot;
      Rectangle(0, 0, BW, BH);
      Pen.Style := psSolid;
    end;
    Brush.Style := bsSolid;
    Pen.Width := 1;
  end;
end;

function TjanSimWagen.StatusText: string;
var
  N: Integer;
begin
  N := PaaltjeBij;
  if Fault then
    Result := Tr(FTaal, 'V en A samen aan: blijft staan', 'V and A on together: stands still',
                        'V et A ensemble : reste immobile', 'V und A zusammen ein: bleibt stehen')
  else if Outputs[0] and (Direction <= 0) then
    Result := Tr(FTaal, 'staat aan de start (Start aan)', 'at the start (Start on)',
                        'au départ (Start actif)', 'steht am Start (Start ein)')
  else if Outputs[2] and (Direction >= 0) then
    Result := Tr(FTaal, 'staat aan de finish (Finish aan)', 'at the finish (Finish on)',
                        'à l''arrivée (Finish actif)', 'steht im Ziel (Finish ein)')
  else if N > 0 then
    Result := Format(Tr(FTaal, 'bij paaltje %d (Tel aan)', 'at post %d (Tel on)',
                               'au poteau %d (Tel actif)', 'an Pfosten %d (Tel ein)'), [N])
  else if Direction > 0 then
    Result := Tr(FTaal, 'rijdt vooruit', 'driving forward', 'roule en avant', 'fährt vorwärts')
  else if Direction < 0 then
    Result := Tr(FTaal, 'rijdt achteruit', 'driving backward', 'roule en arrière', 'fährt rückwärts')
  else
    Result := Tr(FTaal, 'staat stil', 'standing still', 'immobile', 'steht still');
end;

procedure TjanSimWagen.UpdateHintText;
begin
  Hint := BuildSimHint(FNaam, FTaal) + #13#10 +
    Tr(FTaal, 'V: vooruit, A: achteruit' + #13#10 + 'Start/Finish: begin en einde van de weg' + #13#10 +
              'Tel: een puls bij elk paaltje (1-5)' + #13#10 + 'rechtsklik: eindschakelaars plaatsen',
              'V: forward, A: backward' + #13#10 + 'Start/Finish: begin and end of the road' + #13#10 +
              'Tel: a pulse at each post (1-5)' + #13#10 + 'right-click: place limit switches',
              'V : en avant, A : en arrière' + #13#10 + 'Start/Finish : début et fin de la route' + #13#10 +
              'Tel : une impulsion à chaque poteau (1-5)' + #13#10 + 'clic droit : placer les fins de course',
              'V: vorwärts, A: rückwärts' + #13#10 + 'Start/Finish: Anfang und Ende der Straße' + #13#10 +
              'Tel: ein Impuls an jedem Pfosten (1-5)' + #13#10 + 'Rechtsklick: Endschalter setzen');
end;



// ============================================================
// Klank voor de muziekdoos: een toon (of akkoord) als WAV in het geheugen,
// op Windows gespeeld met PlaySound, op Linux met aplay (of pw-play, paplay)
// ============================================================

const
  MZ_RATE = 22050;      // samples per seconde
  MZ_DUUR = 4;          // seconden: zo lang klinkt een noot hoogstens
  // do re mi fa sol la si do' (C5 tot C6)
  MZ_FREQ: array[0..7] of Double = (523.25, 587.33, 659.26, 698.46, 783.99, 880.00, 987.77, 1046.50);

var
  MuziekWav: TBytes;            // de WAV die nu speelt (PlaySound leest uit het geheugen)
  MuziekBron: TObject = nil;    // de muziekdoos die nu klinkt
  {$IFDEF UNIX}
  MuziekProc: TProcess = nil;
  {$ENDIF}
  // per noot de hele toon (met aanslag en uitsterven), één keer berekend:
  // een nieuwe noot of een akkoord is dan alleen nog optellen, zodat de
  // simulatie en LogicRun niet stilvallen tijdens het rekenen
  MuziekToon: array[0..7] of array of Single;

procedure MaakToonTabel;
var
  i, k, n: Integer;
  t, Env: Double;
begin
  if Length(MuziekToon[0]) > 0 then Exit;
  n := MZ_RATE * MZ_DUUR;
  for k := 0 to 7 do
  begin
    SetLength(MuziekToon[k], n);
    for i := 0 to n - 1 do
    begin
      t := i / MZ_RATE;
      Env := 0.35 + 0.65 * Exp(-3 * t);
      if t < 0.005 then Env := Env * t / 0.005;                    // geen klik bij het begin
      if t > MZ_DUUR - 0.3 then Env := Env * (MZ_DUUR - t) / 0.3;  // uitdoven
      MuziekToon[k][i] := Env * (Sin(2 * Pi * MZ_FREQ[k] * t) + 0.3 * Sin(4 * Pi * MZ_FREQ[k] * t)
                                 + 0.1 * Sin(6 * Pi * MZ_FREQ[k] * t));
    end;
  end;
end;

// WAV (16 bit mono) met de noten van Mask: een aanslag, uitsterven tot een
// zachtere toon en op het einde uitdoven, zoals een elektrische piano
function MaakNootWav(Mask: Integer): TBytes;
var
  B: TBytes;
  i, k, n, Aantal: Integer;
  v, Schaal: Single;
  S: SmallInt;

  procedure Zet32(P: Integer; V: LongWord);
  begin
    B[P] := Byte(V); B[P + 1] := Byte(V shr 8); B[P + 2] := Byte(V shr 16); B[P + 3] := Byte(V shr 24);
  end;

  procedure Zet16(P: Integer; V: Word);
  begin
    B[P] := Byte(V); B[P + 1] := Byte(V shr 8);
  end;

  procedure ZetTekst(P: Integer; const T: string);
  var
    j: Integer;
  begin
    for j := 1 to 4 do B[P + j - 1] := Ord(T[j]);
  end;

begin
  n := MZ_RATE * MZ_DUUR;
  SetLength(B, 44 + 2 * n);
  ZetTekst(0, 'RIFF'); Zet32(4, 36 + 2 * n); ZetTekst(8, 'WAVE');
  ZetTekst(12, 'fmt '); Zet32(16, 16); Zet16(20, 1); Zet16(22, 1);
  Zet32(24, MZ_RATE); Zet32(28, MZ_RATE * 2); Zet16(32, 2); Zet16(34, 16);
  ZetTekst(36, 'data'); Zet32(40, 2 * n);
  Aantal := 0;
  for k := 0 to 7 do
    if Mask and (1 shl k) <> 0 then Inc(Aantal);
  if Aantal = 0 then Aantal := 1;
  MaakToonTabel;
  Schaal := 0.6 * 32767 / (1.4 * Aantal);
  for i := 0 to n - 1 do
  begin
    v := 0;
    for k := 0 to 7 do
      if Mask and (1 shl k) <> 0 then
        v := v + MuziekToon[k][i];
    S := Round(v * Schaal);
    Zet16(44 + 2 * i, Word(S));
  end;
  Result := B;
end;

procedure MuziekStil;
begin
  {$IFDEF WINDOWS}
  PlaySound(nil, 0, 0);
  {$ENDIF}
  {$IFDEF UNIX}
  if Assigned(MuziekProc) then
  begin
    try
      if MuziekProc.Running then
      begin
        MuziekProc.Terminate(0);
        MuziekProc.WaitOnExit;
      end;
    except
    end;
    FreeAndNil(MuziekProc);
  end;
  {$ENDIF}
end;

procedure MuziekSpeel(Mask: Integer);
{$IFDEF UNIX}
const
  Spelers: array[0..3] of string = ('aplay', 'pw-play', 'paplay', 'afplay');
var
  Pad, Prog: string;
  F: TFileStream;
  j: Integer;
{$ENDIF}
begin
  MuziekStil;
  if Mask = 0 then Exit;
  MuziekWav := MaakNootWav(Mask);
  {$IFDEF WINDOWS}
  PlaySound(PChar(@MuziekWav[0]), 0, SND_MEMORY or SND_ASYNC or SND_NODEFAULT);
  {$ENDIF}
  {$IFDEF UNIX}
  Prog := '';
  for j := 0 to High(Spelers) do
  begin
    Prog := ExeSearch(Spelers[j], GetEnvironmentVariable('PATH'));
    if Prog <> '' then Break;
  end;
  if Prog = '' then Exit;
  Pad := GetTempDir(False) + 'logic-muziek.wav';
  try
    F := TFileStream.Create(Pad, fmCreate);
    try
      F.WriteBuffer(MuziekWav[0], Length(MuziekWav));
    finally
      F.Free;
    end;
    MuziekProc := TProcess.Create(nil);
    MuziekProc.Executable := Prog;
    if ExtractFileName(Prog) = 'aplay' then MuziekProc.Parameters.Add('-q');
    MuziekProc.Parameters.Add(Pad);
    MuziekProc.Execute;
  except
    FreeAndNil(MuziekProc);
  end;
  {$ENDIF}
end;

// ============================================================
// TjanSimMuziek: muziekdoos met 8 pianotoetsen
// ============================================================

const
  MZ_W = 260;           // breedte van het blok (zoals de persoon)
  MZ_H = 140;           // hoogte van het blok
  MZ_X = 40;            // eerste toets (x)
  MZ_TOETS = 26;        // breedte van een witte toets
  MZ_BOVEN = 22;        // bovenkant van de toetsen
  MZ_ONDER = 128;       // onderkant van de toetsen

constructor TjanSimMuziek.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := MZ_W;
  Height := MZ_H;
  FNaam := 'Muziekdoos';
  HelpKeyword := 'muziek';
  FGeluid := True;
  FKlankTimer := TTimer.Create(Self);
  FKlankTimer.Enabled := False;
  FKlankTimer.Interval := 20;
  FKlankTimer.OnTimer := KlankTick;
  MaakToonTabel;   // meteen, dan hapert de eerste noot niet
end;

destructor TjanSimMuziek.Destroy;
begin
  FKlankTimer.Enabled := False;
  if MuziekBron = Self then
  begin
    MuziekStil;
    MuziekBron := nil;
  end;
  inherited;
end;

function TjanSimMuziek.InputCount: Integer;
begin
  Result := 8;
end;

// zelfde hoogte als UIT0..UIT7 van LogicRun: met de bovenkant gelijk lopen
// de draden recht
function TjanSimMuziek.InPinY(I: Integer): Integer;
begin
  Result := TjanLogicRun.OutputPinY(I);
end;

function TjanSimMuziek.OutputCount: Integer;
begin
  Result := 0;
end;

function TjanSimMuziek.Direction: Integer;
begin
  Result := 0;
end;

function TjanSimMuziek.Noten: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if FIn[i] then Result := Result or (1 shl i);
end;

// do re mi in alle talen (zo leren de leerlingen de noten), met ré in het Frans
function TjanSimMuziek.NootNaam(I: Integer): string;
const
  NL: array[0..7] of string = ('do', 're', 'mi', 'fa', 'sol', 'la', 'si', 'do''');
begin
  if (I < 0) or (I > 7) then Exit('');
  if (FTaal = 'FR') and (I = 1) then Result := 'ré'
  else Result := NL[I];
end;

// lettername (C D E ...; in het Duits H in plaats van B), klein onder op de toets
function TjanSimMuziek.NootLetter(I: Integer): string;
const
  EN: array[0..7] of string = ('C', 'D', 'E', 'F', 'G', 'A', 'B', 'C''');
begin
  if (I < 0) or (I > 7) then Exit('');
  if (FTaal = 'DU') and (I = 6) then Result := 'H'
  else Result := EN[I];
end;

procedure TjanSimMuziek.SetInput(I: Integer; Value: Boolean);
begin
  if (I < 0) or (I >= InputCount) or (FIn[I] = Value) then Exit;
  FIn[I] := Value;
  Invalidate;
  // pas klinken als alle draden van deze stap er zijn (geen kort akkoord
  // tussen twee noten)
  FKlankTimer.Enabled := False;
  FKlankTimer.Enabled := True;
  if FMouseOver then
    SendStatusToBar;
end;

procedure TjanSimMuziek.KlankTick(Sender: TObject);
begin
  FKlankTimer.Enabled := False;
  Klink;
end;

procedure TjanSimMuziek.Klink;
var
  M: Integer;
begin
  if FGeluid then M := Noten else M := 0;
  if (M = FSpeelt) and ((M = 0) or (MuziekBron = Self)) then Exit;
  FSpeelt := M;
  if M = 0 then
  begin
    if MuziekBron = Self then
    begin
      MuziekStil;
      MuziekBron := nil;
    end;
  end
  else
  begin
    MuziekSpeel(M);
    MuziekBron := Self;
  end;
end;

procedure TjanSimMuziek.GeluidClick(Sender: TObject);
begin
  FGeluid := not FGeluid;
  Klink;
  Invalidate;
end;

procedure TjanSimMuziek.BuildPopup;
var
  Mi: TMenuItem;
begin
  if not Assigned(PopupMenu) then
    PopupMenu := TPopupMenu.Create(Self)
  else
    PopupMenu.Items.Clear;
  Mi := TMenuItem.Create(PopupMenu);
  if FLock then
    Mi.Caption := Tr(FTaal, 'Ontgrendel', 'Unlock', 'Déverrouiller', 'Entsperren')
  else
    Mi.Caption := Tr(FTaal, 'Vergrendel', 'Lock', 'Verrouiller', 'Sperren');
  Mi.OnClick := LockClick;
  PopupMenu.Items.Add(Mi);
  Mi := TMenuItem.Create(PopupMenu);
  Mi.Caption := Tr(FTaal, 'Selecteer object', 'Select object', 'Sélectionner l''objet', 'Objekt auswählen');
  Mi.OnClick := SelectClick;
  PopupMenu.Items.Add(Mi);
  Mi := TMenuItem.Create(PopupMenu);
  Mi.Caption := Tr(FTaal, 'Geluid', 'Sound', 'Son', 'Ton');
  Mi.Checked := FGeluid;
  Mi.OnClick := GeluidClick;
  PopupMenu.Items.Add(Mi);
end;

function TjanSimMuziek.StatusText: string;
var
  i: Integer;
  S: string;
begin
  S := '';
  for i := 0 to 7 do
    if FIn[i] then
    begin
      if S <> '' then S := S + ' ';
      S := S + NootNaam(i);
    end;
  if S = '' then
    Result := Tr(FTaal, 'stil', 'silent', 'silence', 'still')
  else
    Result := Tr(FTaal, 'speelt ', 'plays ', 'joue ', 'spielt ') + S;
  if not FGeluid then
    Result := Result + Tr(FTaal, ' (geluid uit)', ' (sound off)', ' (son coupé)', ' (Ton aus)');
end;

procedure TjanSimMuziek.UpdateHintText;
begin
  Hint := BuildSimHint(FNaam, FTaal) + #13#10 +
    Tr(FTaal, 'een ingang per noot (do re mi fa sol la si do'')' + #13#10 + 'aan: de toets licht op en de noot klinkt' + #13#10 + 'rechtsklik: geluid aan/uit',
              'one input per note (C D E F G A B C'')' + #13#10 + 'on: the key lights up and the note sounds' + #13#10 + 'right-click: sound on/off',
              'une entrée par note (do ré mi fa sol la si do'')' + #13#10 + 'actif : la touche s''allume et la note sonne' + #13#10 + 'clic droit : son activé/coupé',
              'ein Eingang pro Note (C D E F G A H C'')' + #13#10 + 'ein: die Taste leuchtet und die Note klingt' + #13#10 + 'Rechtsklick: Ton ein/aus');
end;

procedure TjanSimMuziek.Paint;
const
  // zwarte toetsen staan op de grens na witte toets 1, 2, 4, 5 en 6
  Zwart: array[0..4] of Integer = (1, 2, 4, 5, 6);
  Kast = $00305878;      // bruin hout
  Licht = $0000D0FF;     // geel-oranje: speelt
var
  i, x, y: Integer;
  BW, BH: Integer;
  Lbl: string;
begin
  BW := Self.Width;
  BH := Self.Height;
  with Canvas do
  begin
    Font.Name := 'Arial';
    Font.Size := 7;
    Font.Style := [fsBold];

    // kast
    Pen.Width := 1;
    Pen.Color := $00203848;
    Brush.Style := bsSolid;
    Brush.Color := Kast;
    RoundRect(MZ_X - 6, 4, MZ_X + 8 * MZ_TOETS + 6, BH - 4, 8, 8);
    Brush.Style := bsClear;
    Font.Color := clWhite;
    Lbl := FNaam;
    if not FGeluid then
      Lbl := Lbl + Tr(FTaal, ' (geluid uit)', ' (sound off)', ' (son coupé)', ' (Ton aus)');
    TextOut(MZ_X, 7, Lbl);

    // de noot (of het akkoord) die nu speelt, groot rechts in de kop
    Lbl := '';
    for i := 0 to 7 do
      if FIn[i] then
      begin
        if Lbl <> '' then Lbl := Lbl + ' ';
        Lbl := Lbl + NootNaam(i);
      end;
    if Lbl <> '' then
    begin
      Font.Size := 9;
      Font.Color := Licht;
      x := MZ_X + 8 * MZ_TOETS - TextWidth(Lbl);
      TextOut(x, 5, Lbl);
      // muzieknootje ervoor
      Brush.Style := bsSolid;
      Brush.Color := Licht;
      Pen.Color := Licht;
      Ellipse(x - 12, 13, x - 6, 18);
      Line(x - 7, 15, x - 7, 6);
      Line(x - 7, 6, x - 3, 9);
      Brush.Style := bsClear;
      Font.Size := 7;
    end;

    // witte toetsen met de naam van de noot, en klein de letter eronder
    for i := 0 to 7 do
    begin
      x := MZ_X + i * MZ_TOETS;
      Brush.Style := bsSolid;
      if FIn[i] then Brush.Color := Licht else Brush.Color := clWhite;
      Pen.Color := clGray;
      Rectangle(x, MZ_BOVEN, x + MZ_TOETS + 1, MZ_ONDER);
      Brush.Style := bsClear;
      if FIn[i] then Font.Color := clRed else Font.Color := clNavy;
      Font.Size := 7;
      Lbl := NootNaam(i);
      TextOut(x + (MZ_TOETS - TextWidth(Lbl)) div 2, MZ_ONDER - 25, Lbl);
      Font.Size := 6;
      Font.Style := [];
      Font.Color := clGray;
      Lbl := NootLetter(i);
      TextOut(x + (MZ_TOETS - TextWidth(Lbl)) div 2, MZ_ONDER - 13, Lbl);
      Font.Style := [fsBold];
      Font.Size := 7;
      // muzieknootje boven een toets die speelt
      if FIn[i] then
      begin
        Brush.Style := bsSolid;
        Brush.Color := clBlack;
        Pen.Color := clBlack;
        Ellipse(x + 8, MZ_ONDER - 38, x + 15, MZ_ONDER - 32);
        Line(x + 14, MZ_ONDER - 35, x + 14, MZ_ONDER - 50);
        Line(x + 14, MZ_ONDER - 50, x + 18, MZ_ONDER - 46);
      end;
    end;

    // zwarte toetsen (alleen versiering)
    Brush.Style := bsSolid;
    Brush.Color := $00202020;
    Pen.Color := clBlack;
    for i := 0 to High(Zwart) do
    begin
      x := MZ_X + Zwart[i] * MZ_TOETS;
      Rectangle(x - 8, MZ_BOVEN, x + 9, MZ_BOVEN + 50);
    end;

    // ingangen links, met de naam van de noot
    for i := 0 to 7 do
    begin
      y := InPinY(i);
      Brush.Style := bsSolid;
      Brush.Color := clLime;
      Pen.Color := clGray;
      Rectangle(1, y, 8, y + 7);
      Brush.Style := bsClear;
      if FIn[i] then Font.Color := clRed else Font.Color := clNavy;
      TextOut(11, y - 3, NootNaam(i));
    end;

    if FSelect or FSelected then
    begin
      Brush.Style := bsClear;
      if FSelected then Pen.Color := clRed else Pen.Color := clBlack;
      Pen.Style := psDot;
      Rectangle(0, 0, BW, BH);
      Pen.Style := psSolid;
    end;
    Brush.Style := bsSolid;
    Pen.Width := 1;
  end;
end;

// ============================================================
// TjanSimVerkeerslicht: verkeerslicht met voetgangerslicht
// ============================================================

const
  VL_W = 120;           // breedte van het blok
  VL_H = 140;           // hoogte van het blok
  VL_AX = 40;           // autolicht: links, boven, breedte, hoogte van de kast
  VL_AY = 6;
  VL_AW = 32;
  VL_AH = 96;
  VL_VX = 84;           // voetgangerslicht: links, boven, breedte, hoogte
  VL_VY = 30;
  VL_VW = 28;
  VL_VH = 58;

constructor TjanSimVerkeerslicht.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := VL_W;
  Height := VL_H;
  FNaam := 'Verkeerslicht';
  HelpKeyword := 'verkeerslicht';
end;

function TjanSimVerkeerslicht.InputCount: Integer;
begin
  Result := 5;
end;

// zelfde hoogte als UIT0..UIT4 van LogicRun: met de bovenkant gelijk lopen
// de draden recht
function TjanSimVerkeerslicht.InPinY(I: Integer): Integer;
begin
  Result := TjanLogicRun.OutputPinY(I);
end;

function TjanSimVerkeerslicht.OutputCount: Integer;
begin
  Result := 0;
end;

function TjanSimVerkeerslicht.Direction: Integer;
begin
  Result := 0;
end;

function TjanSimVerkeerslicht.Gevaar: Boolean;
begin
  Result := FIn[2] and FIn[4];
end;

procedure TjanSimVerkeerslicht.BuildPopup;
var
  Mi: TMenuItem;
begin
  if not Assigned(PopupMenu) then
    PopupMenu := TPopupMenu.Create(Self)
  else
    PopupMenu.Items.Clear;
  Mi := TMenuItem.Create(PopupMenu);
  if FLock then
    Mi.Caption := Tr(FTaal, 'Ontgrendel', 'Unlock', 'Déverrouiller', 'Entsperren')
  else
    Mi.Caption := Tr(FTaal, 'Vergrendel', 'Lock', 'Verrouiller', 'Sperren');
  Mi.OnClick := LockClick;
  PopupMenu.Items.Add(Mi);
  Mi := TMenuItem.Create(PopupMenu);
  Mi.Caption := Tr(FTaal, 'Selecteer object', 'Select object', 'Sélectionner l''objet', 'Objekt auswählen');
  Mi.OnClick := SelectClick;
  PopupMenu.Items.Add(Mi);
end;

function TjanSimVerkeerslicht.StatusText: string;
var
  S: string;

  procedure Voeg(const T: string);
  begin
    if S <> '' then S := S + ', ';
    S := S + T;
  end;

begin
  S := '';
  if FIn[0] then Voeg(Tr(FTaal, 'rood', 'red', 'rouge', 'rot'));
  if FIn[1] then Voeg(Tr(FTaal, 'oranje', 'amber', 'orange', 'gelb'));
  if FIn[2] then Voeg(Tr(FTaal, 'groen', 'green', 'vert', 'grün'));
  if S = '' then S := Tr(FTaal, 'uit', 'off', 'éteint', 'aus');
  Result := Tr(FTaal, 'auto''s: ', 'cars: ', 'voitures : ', 'Autos: ') + S;
  S := '';
  if FIn[3] then Voeg(Tr(FTaal, 'rood', 'red', 'rouge', 'rot'));
  if FIn[4] then Voeg(Tr(FTaal, 'groen', 'green', 'vert', 'grün'));
  if S = '' then S := Tr(FTaal, 'uit', 'off', 'éteint', 'aus');
  Result := Result + Tr(FTaal, ' - voetgangers: ', ' - pedestrians: ', ' - piétons : ', ' - Fußgänger: ') + S;
  if Gevaar then
    Result := Result + Tr(FTaal, ' - GEVAAR: allebei groen!', ' - DANGER: both green!',
                                 ' - DANGER : les deux au vert !', ' - GEFAHR: beide grün!');
end;

procedure TjanSimVerkeerslicht.UpdateHintText;
begin
  Hint := BuildSimHint(FNaam, FTaal) + #13#10 +
    Tr(FTaal, 'ingangen R, O, G: rood, oranje, groen voor de auto''s' + #13#10 + 'VR, VG: rood en groen mannetje voor de voetgangers' + #13#10 + 'zelfde hoogte als UIT0..UIT4 van LogicRun',
              'inputs R, A, G: red, amber, green for the cars' + #13#10 + 'PR, PG: red and green figure for the pedestrians' + #13#10 + 'same height as OUT0..OUT4 of LogicRun',
              'entrées R, O, V : rouge, orange, vert pour les voitures' + #13#10 + 'PR, PV : bonhomme rouge et vert pour les piétons' + #13#10 + 'même hauteur que UIT0..UIT4 de LogicRun',
              'Eingänge R, G, Gr: rot, gelb, grün für die Autos' + #13#10 + 'FR, FG: rotes und grünes Männchen für die Fußgänger' + #13#10 + 'gleiche Höhe wie UIT0..UIT4 von LogicRun');
end;

procedure TjanSimVerkeerslicht.Paint;
const
  // kleur van de lampen: aan en uit (donker)
  KleurAan: array[0..4] of TColor = (clRed, $0080FF, clLime, clRed, clLime);
  KleurUit: array[0..4] of TColor = ($000040, $004060, $004000, $000040, $004000);
var
  BW, BH, i, y, cx, cy, r: Integer;

  // mannetje: staand (rood) of stappend (groen), in het vak R
  procedure Mannetje(const R: TRect; Loopt: Boolean; Kleur: TColor);
  var
    mx, top: Integer;
  begin
    mx := (R.Left + R.Right) div 2;
    top := R.Top + 3;
    Canvas.Pen.Color := Kleur;
    Canvas.Brush.Color := Kleur;
    Canvas.Ellipse(mx - 2, top, mx + 3, top + 5);          // hoofd
    Canvas.Pen.Width := 2;
    Canvas.Line(mx, top + 6, mx, top + 14);                 // lijf
    if Loopt then
    begin
      Canvas.Line(mx, top + 8, mx - 4, top + 12);           // armen
      Canvas.Line(mx, top + 8, mx + 4, top + 10);
      Canvas.Line(mx, top + 14, mx - 4, top + 20);          // benen in een stap
      Canvas.Line(mx, top + 14, mx + 4, top + 20);
    end
    else
    begin
      Canvas.Line(mx - 3, top + 8, mx - 3, top + 13);       // armen langs het lijf
      Canvas.Line(mx + 3, top + 8, mx + 3, top + 13);
      Canvas.Line(mx - 1, top + 14, mx - 1, top + 20);      // benen naast elkaar
      Canvas.Line(mx + 1, top + 14, mx + 1, top + 20);
    end;
    Canvas.Pen.Width := 1;
  end;

  function Kleur(I: Integer): TColor;
  begin
    if FIn[I] then Result := KleurAan[I] else Result := KleurUit[I];
  end;

begin
  BW := Self.Width;
  BH := Self.Height;
  with Canvas do
  begin
    Pen.Width := 1;
    // blok
    Brush.Style := bsSolid;
    Brush.Color := clCream;
    Pen.Color := clGray;
    Rectangle(12, 0, BW - 1, BH);
    // aansluitdraden en -vierkantjes met een kleurbolletje of mannetje als naam
    for i := 0 to 4 do
    begin
      y := InPinY(i) + 3;
      Pen.Color := clBlack;
      Line(8, y, 12, y);
      Brush.Color := clLime;
      Pen.Color := clGray;
      Rectangle(1, InPinY(i), 8, InPinY(i) + 7);
      Brush.Color := KleurAan[i];
      Pen.Color := clGray;
      if i <= 2 then
        Ellipse(15, y - 4, 24, y + 5)
      else
      begin
        Rectangle(15, y - 4, 24, y + 5);
        Pen.Color := clWhite;
        Line(19, y - 2, 19, y + 3);
      end;
    end;
    // paal
    Brush.Color := clGray;
    Pen.Color := clGray;
    Rectangle(VL_AX + VL_AW div 2 - 3, VL_AY + VL_AH, VL_AX + VL_AW div 2 + 3, BH - 4);
    Rectangle(VL_AX + VL_AW, VL_VY + VL_VH div 2 - 2, VL_VX, VL_VY + VL_VH div 2 + 2);
    Brush.Color := clDkGray;
    Rectangle(VL_AX + 2, BH - 6, VL_AX + VL_AW - 2, BH - 2);
    // kast van het autolicht met rood, oranje en groen
    Brush.Color := $303030;
    Pen.Color := clBlack;
    RoundRect(VL_AX, VL_AY, VL_AX + VL_AW, VL_AY + VL_AH, 10, 10);
    r := 11;
    cx := VL_AX + VL_AW div 2;
    for i := 0 to 2 do
    begin
      cy := VL_AY + 16 + i * 32;
      Brush.Color := Kleur(i);
      if FIn[i] then Pen.Color := clWhite else Pen.Color := clBlack;
      Ellipse(cx - r, cy - r, cx + r + 1, cy + r + 1);
    end;
    // kast van het voetgangerslicht: rood staand en groen stappend mannetje
    Brush.Color := $303030;
    Pen.Color := clBlack;
    RoundRect(VL_VX, VL_VY, VL_VX + VL_VW, VL_VY + VL_VH, 8, 8);
    for i := 0 to 1 do
    begin
      Brush.Color := clBlack;
      Pen.Color := clBlack;
      Rectangle(VL_VX + 4, VL_VY + 4 + i * 26, VL_VX + VL_VW - 4, VL_VY + 28 + i * 26);
      Mannetje(Rect(VL_VX + 4, VL_VY + 4 + i * 26, VL_VX + VL_VW - 4, VL_VY + 28 + i * 26),
        i = 1, Kleur(3 + i));
    end;
    // gevaar: groen voor auto's en voetgangers samen
    if Gevaar then
    begin
      Brush.Style := bsClear;
      Pen.Color := clRed;
      Pen.Width := 2;
      Rectangle(13, 1, BW - 2, BH - 1);
      Pen.Width := 1;
      Font.Name := 'Arial';
      Font.Size := 14;
      Font.Style := [fsBold];
      Font.Color := clRed;
      TextOut(VL_VX + 9, VL_VY + VL_VH + 6, '!');
    end;
    Brush.Style := bsClear;
    if FSelect or FSelected then
    begin
      if FSelected then Pen.Color := clRed else Pen.Color := clBlack;
      Pen.Style := psDot;
      Rectangle(0, 0, BW, BH);
      Pen.Style := psSolid;
    end;
    Brush.Style := bsSolid;
  end;
end;


// ============================================================
// TjanSimSlagboom: slagboom van een parking, ingang O = openen
// ============================================================

const
  SB_W = 150;           // breedte van het blok
  SB_H = 130;           // hoogte van het blok
  SB_PX = 40;           // draaipunt van de boom (op de paal)
  SB_PY = 100;
  SB_LEN = 96;          // lengte van de boom
  SB_STAP = 3;          // graden per tik (60 ms): 90 graden in 1,8 s

constructor TjanSimSlagboom.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := SB_W;
  Height := SB_H;
  FNaam := 'Slagboom';
  HelpKeyword := 'slagboom';
end;

// FPos is de hoek van de boom in graden: 0 = dicht, 90 = open
function TjanSimSlagboom.Range: Integer;
begin
  Result := 90;
end;

function TjanSimSlagboom.InputCount: Integer;
begin
  Result := 1;
end;

function TjanSimSlagboom.OutputName(I: Integer): string;
begin
  if I = 0 then
    Result := Tr(FTaal, 'Dicht', 'Closed', 'Fermée', 'Zu')
  else
    Result := Tr(FTaal, 'Open', 'Open', 'Ouverte', 'Auf');
end;

function TjanSimSlagboom.Direction: Integer;
begin
  if FIn[0] and (FPos < Range) then Result := 1
  else if not FIn[0] and (FPos > 0) then Result := -1
  else Result := 0;
end;

procedure TjanSimSlagboom.Tick;
var
  NewPos: Integer;
begin
  if Direction = 0 then
  begin
    FTimer.Enabled := False;   // helemaal open of dicht: timer mag stoppen
    Exit;
  end;
  NewPos := FPos + Direction * SB_STAP;
  if NewPos < 0 then NewPos := 0;
  if NewPos > Range then NewPos := Range;
  FPos := NewPos;
  Invalidate;
  MeldEindschakelaars;
  if FMouseOver then
    SendStatusToBar;
end;

function TjanSimSlagboom.StatusText: string;
begin
  case Direction of
    1: Result := Tr(FTaal, 'gaat open', 'opening', 's''ouvre', 'öffnet');
    -1: Result := Tr(FTaal, 'gaat dicht', 'closing', 'se ferme', 'schließt');
  else
    if FPos >= Range then
      Result := Tr(FTaal, 'open', 'open', 'ouverte', 'offen')
    else
      Result := Tr(FTaal, 'dicht', 'closed', 'fermée', 'zu');
  end;
  Result := Tr(FTaal, 'slagboom: ', 'barrier: ', 'barrière : ', 'Schranke: ') + Result +
    Format(' (%d°)', [FPos]);
end;

procedure TjanSimSlagboom.UpdateHintText;
begin
  Hint := BuildSimHint(FNaam, FTaal) + #13#10 +
    Tr(FTaal, 'ingang O: aan = boom gaat open, uit = boom gaat dicht' + #13#10 + 'eindschakelaars Dicht en Open (rechtsklik: Eindschakelaars plaatsen)',
              'input O: on = barrier opens, off = barrier closes' + #13#10 + 'limit switches Closed and Open (right-click: Place limit switches)',
              'entrée O : active = la barrière s''ouvre, inactive = elle se ferme' + #13#10 + 'fins de course Fermée et Ouverte (clic droit : Placer les fins de course)',
              'Eingang O: ein = Schranke öffnet, aus = Schranke schließt' + #13#10 + 'Endschalter Zu und Auf (Rechtsklick: Endschalter setzen)');
end;

procedure TjanSimSlagboom.Paint;
var
  BW, BH, i, y: Integer;
  a, c, s: Double;
  x1, y1, x2, y2: Integer;
begin
  BW := Self.Width;
  BH := Self.Height;
  with Canvas do
  begin
    Pen.Width := 1;
    // blok
    Brush.Style := bsSolid;
    Brush.Color := clCream;
    Pen.Color := clGray;
    Rectangle(12, 0, BW - 1, BH);
    // aansluiting O
    y := InPinY(0) + 3;
    Pen.Color := clBlack;
    Line(8, y, 12, y);
    Brush.Color := clLime;
    Pen.Color := clGray;
    Rectangle(1, InPinY(0), 8, InPinY(0) + 7);
    Font.Name := 'Arial';
    Font.Size := 7;
    Font.Style := [fsBold];
    Font.Color := clBlack;
    Brush.Style := bsClear;
    TextOut(15, y - 6, 'O');
    Brush.Style := bsSolid;
    // weg en steunpaaltje aan het einde van de boom
    Pen.Color := clGray;
    Brush.Color := clSilver;
    Rectangle(14, BH - 8, BW - 3, BH - 3);
    Brush.Color := clGray;
    Rectangle(SB_PX + SB_LEN - 3, SB_PY + 2, SB_PX + SB_LEN + 3, BH - 8);
    // de boom: rood-wit gestreept, draait om het draaipunt
    a := FPos * Pi / 180;
    c := Cos(a);
    s := Sin(a);
    Pen.Color := clBlack;
    Pen.Width := 8;
    Line(SB_PX - Round(10 * c), SB_PY + Round(10 * s),
         SB_PX + Round(SB_LEN * c), SB_PY - Round(SB_LEN * s));
    Pen.Width := 6;
    for i := 0 to 7 do
    begin
      x1 := SB_PX + Round(SB_LEN * i / 8 * c);
      y1 := SB_PY - Round(SB_LEN * i / 8 * s);
      x2 := SB_PX + Round(SB_LEN * (i + 1) / 8 * c);
      y2 := SB_PY - Round(SB_LEN * (i + 1) / 8 * s);
      if Odd(i) then Pen.Color := clWhite else Pen.Color := clRed;
      Line(x1, y1, x2, y2);
    end;
    // tegengewicht achter het draaipunt
    Pen.Color := clDkGray;
    Line(SB_PX, SB_PY, SB_PX - Round(10 * c), SB_PY + Round(10 * s));
    Pen.Width := 1;
    // paal (kast) met draaipunt
    Pen.Color := clBlack;
    Brush.Color := $00C0C0C0;
    Rectangle(SB_PX - 8, SB_PY - 4, SB_PX + 8, BH - 8);
    Brush.Color := clDkGray;
    Ellipse(SB_PX - 3, SB_PY - 3, SB_PX + 4, SB_PY + 4);
    // lampje op de kast: rood = dicht, oranje = beweegt, groen = open
    if Direction <> 0 then Brush.Color := $0080FF
    else if FPos >= Range then Brush.Color := clLime
    else Brush.Color := clRed;
    Ellipse(SB_PX - 4, SB_PY + 8, SB_PX + 5, SB_PY + 17);
    Brush.Style := bsClear;
    if FSelect or FSelected then
    begin
      if FSelected then Pen.Color := clRed else Pen.Color := clBlack;
      Pen.Style := psDot;
      Rectangle(0, 0, BW, BH);
      Pen.Style := psSolid;
    end;
    Brush.Style := bsSolid;
  end;
end;
