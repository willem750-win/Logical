// janSimLogic.pas, deel: onderdelen van de voedingskring (bron ... scoop) (ingevoegd met {$I jsl_voedingsdelen.inc})

{ TjanVoedingsDeel }

constructor TjanVoedingsDeel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FConnectors := TList.Create;
  FTaal := 'NL';
  ShowHint := True;
  HelpKeyword := 'voeding';
end;

destructor TjanVoedingsDeel.Destroy;
begin
  FConnectors.Free;
  inherited Destroy;
end;

function TjanVoedingsDeel.PinCenter(I: Integer): TPoint;
var
  Q: TPoint;
begin
  Q := PinPos(I);
  Result := Point(Left + Q.X + 3, Top + Q.Y + 3);
end;

function TjanVoedingsDeel.PinAt(const P: TPoint): Integer;
var
  i: Integer;
  C: TPoint;
begin
  for i := 0 to PinCount - 1 do
  begin
    C := PinCenter(i);
    if (Abs(C.X - P.X) <= VoedingPinTol) and (Abs(C.Y - P.Y) <= VoedingPinTol) then
      Exit(i);
  end;
  Result := -1;
end;

procedure TjanVoedingsDeel.PaintPin(X, Y: Integer; AOn: Boolean);
begin
  with Canvas do
  begin
    Brush.Style := bsSolid;
    if AOn then Brush.Color := clLime else Brush.Color := clGreen;
    FillRect(Rect(X, Y, X + 7, Y + 7));
    Pen.Color := clBlack;
    Pen.Style := psSolid;
    Brush.Style := bsClear;
    Rectangle(Rect(X, Y, X + 7, Y + 7));
  end;
end;

procedure TjanVoedingsDeel.PaintSelection;
begin
  if not FSelected then Exit;
  with Canvas do
  begin
    Brush.Style := bsClear;
    Pen.Color := clRed; Pen.Style := psDot; Pen.Width := 1;
    Rectangle(ClientRect);
    Pen.Style := psSolid;
    Brush.Style := bsSolid;
  end;
end;

function TjanVoedingsDeel.KanDraaien: Boolean;
begin
  Result := False;
end;

function TjanVoedingsDeel.StdMaat: TPoint;
begin
  Result := Point(Width, Height);
end;

function TjanVoedingsDeel.ExtraBreedte: Integer;
begin
  Result := 0;
end;

function TjanVoedingsDeel.StdRechtop: Boolean;
begin
  Result := False;
end;

procedure TjanVoedingsDeel.PasMaatAan;
var
  M: TPoint;
begin
  if not KanDraaien then Exit;
  M := StdMaat;
  if FGedraaid then
  begin
    Width := M.Y + ExtraBreedte;
    Height := M.X;
  end
  else
  begin
    Width := M.X;
    Height := M.Y;
  end;
end;

function TjanVoedingsDeel.TP(X, Y: Integer): TPoint;
begin
  if FGedraaid then Result := Point(Y, X) else Result := Point(X, Y);
end;

function TjanVoedingsDeel.TRc(L, T, R, B: Integer): TRect;
begin
  if FGedraaid then Result := Rect(T, L, B, R) else Result := Rect(L, T, R, B);
end;

procedure TjanVoedingsDeel.TLijn(X1, Y1, X2, Y2: Integer);
begin
  Canvas.MoveTo(TP(X1, Y1));
  Canvas.LineTo(TP(X2, Y2));
end;

procedure TjanVoedingsDeel.SetGedraaid(const Value: Boolean);
begin
  if (Value = FGedraaid) or not KanDraaien then Exit;
  FGedraaid := Value;
  PasMaatAan;
  Invalidate;
end;

procedure TjanVoedingsDeel.DraaiClick(Sender: TObject);
begin
  Draai;
end;

procedure TjanVoedingsDeel.Draai;
var
  OudC: array of TPoint;
  Cons: TList;
  KBegin, KEinde: array of Integer;
  i, n, CX, CY: Integer;
  Con: TjanConnector;
  A, B: TPoint;

  function KlemBij(const P: TPoint): Integer;
  var
    j: Integer;
  begin
    for j := 0 to n - 1 do
      if (Abs(OudC[j].X - P.X) <= VoedingPinTol) and (Abs(OudC[j].Y - P.Y) <= VoedingPinTol) then
        Exit(j);
    Result := -1;
  end;

begin
  if not KanDraaien or (Parent = nil) then Exit;
  n := PinCount;
  SetLength(OudC, n);
  for i := 0 to n - 1 do
    OudC[i] := PinCenter(i);
  Cons := TList.Create;
  try
    // draden waarvan een uiteinde op een klem van dit onderdeel ligt
    for i := 0 to Parent.ControlCount - 1 do
      if Parent.Controls[i] is TjanConnector then
      begin
        Con := TjanConnector(Parent.Controls[i]);
        Con.EndCenters(A, B);
        if (KlemBij(A) >= 0) or (KlemBij(B) >= 0) then
        begin
          Cons.Add(Con);
          SetLength(KBegin, Cons.Count);
          SetLength(KEinde, Cons.Count);
          KBegin[Cons.Count - 1] := KlemBij(A);
          KEinde[Cons.Count - 1] := KlemBij(B);
        end;
      end;
    // draaien rond het midden
    CX := Left + Width div 2;
    CY := Top + Height div 2;
    FGedraaid := not FGedraaid;
    PasMaatAan;
    SetBounds(CX - Width div 2, CY - Height div 2, Width, Height);
    // de uiteinden naar de nieuwe plaats van hun klem
    for i := 0 to Cons.Count - 1 do
    begin
      Con := TjanConnector(Cons[i]);
      Con.EndCenters(A, B);
      if KBegin[i] >= 0 then A := PinCenter(KBegin[i]);
      if KEinde[i] >= 0 then B := PinCenter(KEinde[i]);
      Con.PlaceEnds(A, B);
    end;
  finally
    Cons.Free;
  end;
  Invalidate;
  if Assigned(GlobalSimBox) then
    GlobalSimBox.DoObjectMove(Self, Left, Top);
  UpdateSupply(Parent, True);
end;

procedure TjanVoedingsDeel.SetTaal(const Value: string);
begin
  FTaal := Value;
  UpdateHintText;
  Invalidate;
end;

procedure TjanVoedingsDeel.AddMenuItems(APop: TPopupMenu);
begin
end;

function TjanVoedingsDeel.HandleClick(X, Y: Integer): Boolean;
begin
  Result := False;
end;

procedure TjanVoedingsDeel.LockClick(Sender: TObject);
begin
  FLock := not FLock;
end;

procedure TjanVoedingsDeel.InfoClick(Sender: TObject);
begin
  ShowHint := not ShowHint;
end;

procedure TjanVoedingsDeel.SelectClick(Sender: TObject);
begin
  if Assigned(FBox) then
    FBox.SelectObject(Self);
end;

procedure TjanVoedingsDeel.AnchorConnectors;
var
  i: Integer;
  Con: TjanConnector;
  R: TRect;
begin
  FConnectors.Clear;
  if Parent = nil then Exit;
  R := BoundsRect;
  if FGedraaid <> StdRechtop then InflateRect(R, 0, 8) else InflateRect(R, 8, 0);
  for i := 0 to Parent.ControlCount - 1 do
    if Parent.Controls[i] is TjanConnector then
    begin
      Con := TjanConnector(Parent.Controls[i]);
      if Con.AnchorToRect(R, Point(Left, Top)) then
        FConnectors.Add(Con);
    end;
end;

procedure TjanVoedingsDeel.MoveConnectors;
var
  i: Integer;
begin
  for i := 0 to FConnectors.Count - 1 do
    TjanConnector(FConnectors[i]).MoveConnector(Point(FNewLeft, FNewTop));
end;

procedure TjanVoedingsDeel.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Pop: TPopupMenu;
  Mi: TMenuItem;
  Pt: TPoint;
  K: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  FDoMove := False;
  FMdp := Point(X, Y);
  if Button = mbRight then
  begin
    Pop := TPopupMenu.Create(Self);
    AddMenuItems(Pop);
    if KanDraaien then
    begin
      Mi := TMenuItem.Create(Pop);
      Mi.Caption := Tr(FTaal, 'Draaien', 'Rotate', 'Pivoter', 'Drehen');
      Mi.OnClick := DraaiClick;
      Mi.Enabled := not FLock;
      Pop.Items.Add(Mi);
    end;
    if Pop.Items.Count > 0 then
    begin
      Mi := TMenuItem.Create(Pop);
      Mi.Caption := '-';
      Pop.Items.Add(Mi);
    end;
    Mi := TMenuItem.Create(Pop);
    if FLock then
      Mi.Caption := Tr(FTaal, 'Ontgrendel', 'Unlock', 'Déverrouiller', 'Entsperren')
    else
      Mi.Caption := Tr(FTaal, 'Vergrendel', 'Lock', 'Verrouiller', 'Sperren');
    Mi.OnClick := LockClick;
    Pop.Items.Add(Mi);
    Mi := TMenuItem.Create(Pop);
    if ShowHint then
      Mi.Caption := Tr(FTaal, 'Info uit', 'Information off', 'Infos off', 'Infos aus')
    else
      Mi.Caption := Tr(FTaal, 'Info aan', 'Information on', 'Infos on', 'Infos an');
    Mi.OnClick := InfoClick;
    Pop.Items.Add(Mi);
    Mi := TMenuItem.Create(Pop);
    if FSelected then
      Mi.Caption := Tr(FTaal, 'Deselecteer object', 'Deselect object', 'Désélectionner l''objet', 'Objekt abwählen')
    else
      Mi.Caption := Tr(FTaal, 'Selecteer object', 'Select object', 'Sélectionner un objet', 'Objekt auswählen');
    Mi.OnClick := SelectClick;
    Pop.Items.Add(Mi);
    Pt := ClientToScreen(Point(0, Height));
    Pop.Popup(Pt.X, Pt.Y - 1);
    Exit;
  end;
  // met de knop Verbinding: een draad beginnen op een klem
  if (Button = mbLeft) and (Screen.Cursor = crDraad) and (Parent <> nil) then
  begin
    K := PinAt(Point(Left + X, Top + Y));
    if K >= 0 then
    begin
      Pt := PinCenter(K);
      Maakdraad(Pt.Y - 4, Pt.X - 4, Parent);
      movecursor;
      BringToFront;
      Exit;
    end;
  end;
  if Button <> mbLeft then Exit;
  // eigen bediening (schuifregelaar) werkt ook tijdens de simulatie
  if HandleClick(X, Y) then Exit;
  FDoMove := True;
  AnchorConnectors;
  if Parent is TjanGridS then
    TjanGridS(Parent).BeginGuideLines(Left + Width div 2, Top + Height div 2);
end;

procedure TjanVoedingsDeel.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  P, SnapP: TPoint;
  Grid: TjanGridS;
begin
  inherited MouseMove(Shift, X, Y);
  if FLock or (Parent = nil) or not FDoMove or not (ssLeft in Shift) then Exit;
  P := Parent.ScreenToClient(ClientToScreen(Point(X, Y)));
  FNewLeft := P.X - FMdp.X;
  FNewTop := P.Y - FMdp.Y;
  if Parent is TjanGridS then
  begin
    Grid := TjanGridS(Parent);
    SnapP := Grid.SnapPointToRuler(Point(FNewLeft + Width div 2, FNewTop + Height div 2),
      Grid.GetWorkAreaRect);
    FNewLeft := SnapP.X - Width div 2;
    FNewTop := SnapP.Y - Height div 2;
  end;
  StraightenWires(FConnectors, FNewLeft, FNewTop);
  Left := FNewLeft;
  Top := FNewTop;
  MoveConnectors;
  if Parent is TjanGridS then
    TjanGridS(Parent).UpdateGuideLines(Left + Width div 2, Top + Height div 2);
  if Assigned(GlobalSimBox) then
    GlobalSimBox.DoObjectMove(Self, Left, Top);
  SendStatusToBar;
end;

procedure TjanVoedingsDeel.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  FDoMove := False;
  if Parent is TjanGridS then
    TjanGridS(Parent).EndGuideLines;
  if Parent <> nil then
    UpdateSupply(Parent, True);
end;

procedure TjanVoedingsDeel.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
  UpdateHintText;
  SendStatusToBar;
end;

procedure TjanVoedingsDeel.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
  if Assigned(FOnStatus) then
  begin
    FOnStatus(Self, '', 0);
    FOnStatus(Self, '', 1);
    FOnStatus(Self, '', 2);
    FOnStatus(Self, '', 3);
  end;
end;

{ TjanBron }

constructor TjanBron.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := BronW;
  Height := BronH;
  FVolt := BronMaxVolt;
  FRiIdx := 1;            // 0,5 ohm
  FKlem := FVolt;
end;

function TjanBron.PinCount: Integer;
begin
  Result := 2;
end;

// klemmen onderaan: + links, - rechts
function TjanBron.PinPos(I: Integer): TPoint;
begin
  if I = 0 then Result := Point(4, BronH - 10) else Result := Point(BronW - 10, BronH - 10);
end;

function TjanBron.Ri: Double;
begin
  Result := BronRi[FRiIdx];
end;

function TjanBron.Emk: Double;
begin
  Result := FVolt;
end;

procedure TjanBron.SetVolt(const Value: Double);
var
  V: Double;
begin
  V := Round(Value * 2) / 2;           // stappen van 0,5 V
  if V < 0 then V := 0;
  if V > BronMaxVolt then V := BronMaxVolt;
  if Abs(V - FVolt) < 0.001 then Exit;
  FVolt := V;
  Invalidate;
  if Parent <> nil then
    UpdateSupply(Parent, True);
  SendStatusToBar;
end;

procedure TjanBron.SetRiIdx(const Value: Integer);
begin
  if (Value < Low(BronRi)) or (Value > High(BronRi)) or (Value = FRiIdx) then Exit;
  FRiIdx := Value;
  Invalidate;
  if Parent <> nil then
    UpdateSupply(Parent, True);
end;

function TjanBron.SliderRect: TRect;
begin
  Result := Rect(10, 54, 86, 60);
end;

procedure TjanBron.SlideTo(X: Integer);
var
  R: TRect;
begin
  R := SliderRect;
  Volt := (X - R.Left) / (R.Right - R.Left) * BronMaxVolt;
end;

function TjanBron.HandleClick(X, Y: Integer): Boolean;
var
  R: TRect;
begin
  R := SliderRect;
  InflateRect(R, 4, 6);
  Result := PtInRect(R, Point(X, Y));
  if Result then
  begin
    FSliding := True;
    SlideTo(X);
  end;
end;

procedure TjanBron.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  if FSliding then
  begin
    if ssLeft in Shift then SlideTo(X) else FSliding := False;
    Exit;
  end;
  inherited MouseMove(Shift, X, Y);
end;

procedure TjanBron.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FSliding := False;
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TjanBron.RiClick(Sender: TObject);
begin
  RiIdx := TMenuItem(Sender).Tag;
end;

procedure TjanBron.SetElektronen(const Value: Boolean);
begin
  if Value = FElektronen then Exit;
  FElektronen := Value;
  if Parent <> nil then
    UpdateSupply(Parent, True);
end;

procedure TjanBron.ElektronenClick(Sender: TObject);
begin
  Elektronen := not Elektronen;
end;

procedure TjanBron.AddMenuItems(APop: TPopupMenu);
var
  Mi, Sub: TMenuItem;
  i: Integer;
begin
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Inwendige weerstand', 'Internal resistance', 'Résistance interne', 'Innenwiderstand');
  APop.Items.Add(Mi);
  for i := Low(BronRi) to High(BronRi) do
  begin
    Sub := TMenuItem.Create(APop);
    Sub.Caption := FormatFloat('0.#', BronRi[i]) + ' Ω';
    Sub.Tag := i;
    Sub.RadioItem := True;
    Sub.Checked := i = FRiIdx;
    Sub.OnClick := RiClick;
    Mi.Add(Sub);
  end;
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Elektronen tonen', 'Show electrons', 'Montrer les électrons', 'Elektronen zeigen');
  Mi.Checked := FElektronen;
  Mi.OnClick := ElektronenClick;
  APop.Items.Add(Mi);
end;

procedure TjanBron.Paint;
var
  R: TRect;
  S: string;
  KX, TW: Integer;
begin
  with Canvas do
  begin
    // doorzichtig, met een streep-punt kader (zoals een kast in een schema)
    Brush.Style := bsClear;
    Pen.Color := clGray; Pen.Width := 1; Pen.Style := psDashDot;
    Rectangle(ClientRect);
    Pen.Style := psSolid;
    Brush.Style := bsSolid;
    // batterijsymbool (cellen in serie): lange plaat (+), korte plaat (-),
    // stippellijn, lange plaat, korte plaat
    Brush.Color := clBlack;
    FillRect(Rect(3, 18, 7, 20));      // aansluiting
    FillRect(Rect(7, 8, 9, 30));       // lange plaat
    FillRect(Rect(11, 13, 14, 25));    // korte plaat
    FillRect(Rect(16, 18, 18, 20));    // stippels
    FillRect(Rect(19, 18, 21, 20));
    FillRect(Rect(22, 18, 24, 20));
    FillRect(Rect(26, 8, 28, 30));     // lange plaat
    FillRect(Rect(30, 13, 33, 25));    // korte plaat
    FillRect(Rect(33, 18, 37, 20));    // aansluiting
    Font.Name := 'Arial';
    // display met de bronspanning
    Brush.Style := bsSolid;
    Brush.Color := RGBToColor(250, 250, 220);
    R := Rect(46, 6, 100, 28);
    FillRect(R);
    Frame3D(R, clBtnShadow, clBtnHighlight, 1);
    Brush.Style := bsClear;
    S := FormatFloat('0.0', FVolt) + ' V';
    Font.Size := 11; Font.Style := [fsBold];
    if FVolt > 0.001 then Font.Color := clRed else Font.Color := clGray;
    TW := TextWidth(S);
    TextOut(73 - TW div 2, 8, S);
    // inwendige weerstand
    Font.Size := 7; Font.Style := []; Font.Color := clNavy;
    TextOut(48, 36, 'Ri ' + FormatFloat('0.#', Ri) + ' Ω');
    // klemmen onderaan: + links, - rechts
    Font.Size := 8; Font.Style := [fsBold];
    Font.Color := clRed; TextOut(14, BronH - 15, '+');
    Font.Color := clBlue; TextOut(BronW - 20, BronH - 15, '-');
    PaintPin(PinPos(0).X, PinPos(0).Y, FKlem >= RailMinVolt);
    PaintPin(PinPos(1).X, PinPos(1).Y, False);
    // schuifregelaar 0 .. 12 V
    R := SliderRect;
    Brush.Style := bsSolid;
    Brush.Color := clGray;
    FillRect(Rect(R.Left, R.Top + 2, R.Right, R.Bottom - 2));
    KX := R.Left + Round((R.Right - R.Left) * FVolt / BronMaxVolt);
    Brush.Color := clNavy;
    FillRect(Rect(KX - 3, R.Top - 4, KX + 3, R.Bottom + 4));
    Brush.Style := bsClear;
    Font.Size := 6; Font.Style := []; Font.Color := clBlack;
    TextOut(R.Right + 4, R.Top - 3, '12V');
  end;
  PaintSelection;
end;

procedure TjanBron.UpdateHintText;
begin
  Hint := Tr(FTaal, 'Bron (accu)', 'Source (battery)', 'Source (batterie)', 'Quelle (Akku)') +
    ': E = ' + FormatFloat('0.0', FVolt) + ' V    Ri = ' + OhmText(Ri) + #13#10;
  // klemspanning met de wet van Ohm: U = E - I x Ri
  if FStroom > 0.00005 then
    Hint := Hint + StroomRegel(FStroom) + #13#10 +
      'U = E − I × Ri = ' + VoltText(FVolt) + ' − ' + AmpText(FStroom) + ' × ' +
        OhmText(Ri) + ' = ' + VoltText(FKlem) + #13#10 +
      VermogenRegel(FKlem, FStroom) + #13#10;
  Hint := Hint +
    Tr(FTaal,
      'Schuifregelaar: spanning 0 tot 12 V.' + #13#10 +
        '+ met een draad naar de + rail, - naar de - rail.' + #13#10 +
        'Rechtsklik: inwendige weerstand.',
      'Slider: voltage 0 to 12 V.' + #13#10 +
        '+ with a wire to the + rail, - to the - rail.' + #13#10 +
        'Right-click: internal resistance.',
      'Curseur : tension de 0 à 12 V.' + #13#10 +
        '+ avec un fil vers le rail +, - vers le rail -.' + #13#10 +
        'Clic droit : résistance interne.',
      'Schieberegler: Spannung 0 bis 12 V.' + #13#10 +
        '+ mit einem Draht an die + Schiene, - an die - Schiene.' + #13#10 +
        'Rechtsklick: Innenwiderstand.');
end;

procedure TjanBron.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Tr(FTaal, 'Bron (accu)', 'Source (battery)', 'Source (batterie)', 'Quelle (Akku)') + ' > ', 0);
  FOnStatus(Self, 'E = ' + FormatFloat('0.0', FVolt) + ' V   U = ' + FormatFloat('0.00', FKlem) +
    ' V   I = ' + FormatFloat('0', FStroom * 1000) + ' mA', 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

function SimulatieTijd: Double;
begin
  Result := SimTijd;
end;

procedure ZetSimulatieTijd(T: Double);
begin
  SimTijd := T;
end;

procedure VoedingBijwerken(P: TWinControl);
begin
  UpdateSupply(P, True);
end;

procedure SimulatieStap(P: TWinControl; ADt: Double);
begin
  CondDt := ADt;
  SimTijd := SimTijd + ADt;
  CondStap := True;
  try
    UpdateSupply(P, True);
  finally
    CondStap := False;
  end;
end;

{ TjanWisselbron }

constructor TjanWisselbron.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFreqIdx := WisselStandaard;
  HelpKeyword := 'wisselbron';
end;

function TjanWisselbron.Hz: Double;
begin
  Result := WisselHz[FFreqIdx];
end;

function TjanWisselbron.Emk: Double;
begin
  Result := Volt * Sin(2 * Pi * Hz * SimTijd);
end;

procedure TjanWisselbron.SetFreqIdx(const Value: Integer);
begin
  if (Value < Low(WisselHz)) or (Value > High(WisselHz)) or (Value = FFreqIdx) then Exit;
  FFreqIdx := Value;
  UpdateHintText;
  Invalidate;
end;

procedure TjanWisselbron.FreqClick(Sender: TObject);
begin
  FreqIdx := TMenuItem(Sender).Tag;
end;

procedure TjanWisselbron.AddMenuItems(APop: TPopupMenu);
var
  Mi, Sub: TMenuItem;
  i: Integer;
begin
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Frequentie', 'Frequency', 'Fréquence', 'Frequenz');
  APop.Items.Add(Mi);
  for i := Low(WisselHz) to High(WisselHz) do
  begin
    Sub := TMenuItem.Create(APop);
    Sub.Caption := FormatFloat('0.#', WisselHz[i]) + ' Hz';
    Sub.Tag := i;
    Sub.RadioItem := True;
    Sub.Checked := i = FFreqIdx;
    Sub.OnClick := FreqClick;
    Mi.Add(Sub);
  end;
  inherited AddMenuItems(APop);   // inwendige weerstand, elektronen
end;

procedure TjanWisselbron.Paint;
var
  R: TRect;
  S: string;
  KX, TW, i, X, Y: Integer;
  E: Double;
begin
  E := Emk;
  if Abs(E) < 0.05 then E := 0;   // geen "-0,0 V" op het nulpunt
  with Canvas do
  begin
    Brush.Style := bsClear;
    Pen.Color := clGray; Pen.Width := 1; Pen.Style := psDashDot;
    Rectangle(ClientRect);
    Pen.Style := psSolid;
    // symbool: cirkel met een sinus
    Pen.Color := clBlack; Pen.Width := 1;
    Brush.Style := bsSolid; Brush.Color := clWhite;
    Ellipse(Rect(6, 4, 38, 36));
    Pen.Width := 2;
    for i := 0 to 22 do
    begin
      X := 11 + i;
      Y := 20 - Round(8 * Sin(2 * Pi * i / 22));
      if i = 0 then MoveTo(X, Y) else LineTo(X, Y);
    end;
    Pen.Width := 1;
    Font.Name := 'Arial';
    // display: de spanning van dit ogenblik, met teken
    Brush.Style := bsSolid;
    Brush.Color := RGBToColor(250, 250, 220);
    R := Rect(46, 6, 106, 28);
    FillRect(R);
    Frame3D(R, clBtnShadow, clBtnHighlight, 1);
    Brush.Style := bsClear;
    S := FormatFloat('+0.0;-0.0;0.0', E) + ' V';
    Font.Size := 11; Font.Style := [fsBold];
    if Abs(E) > 0.05 then Font.Color := clRed else Font.Color := clGray;
    TW := TextWidth(S);
    TextOut(76 - TW div 2, 8, S);
    // topwaarde, frequentie en inwendige weerstand
    Font.Size := 7; Font.Style := []; Font.Color := clNavy;
    TextOut(46, 31, Tr(FTaal, 'top', 'peak', 'crête', 'Spitze') + ' ' + FormatFloat('0.0', Volt) + ' V  ' +
      FormatFloat('0.#', Hz) + ' Hz');
    TextOut(46, 41, 'Ri ' + FormatFloat('0.#', Ri) + ' Ω');
    // klemmen onderaan: ~ aan beide kanten
    Font.Size := 8; Font.Style := [fsBold];
    Font.Color := clBlack; TextOut(14, BronH - 15, '~');
    TextOut(BronW - 22, BronH - 15, '~');
    PaintPin(PinPos(0).X, PinPos(0).Y, Abs(E) >= RailMinVolt);
    PaintPin(PinPos(1).X, PinPos(1).Y, False);
    // schuifregelaar voor de topwaarde 0 .. 12 V
    R := SliderRect;
    Brush.Style := bsSolid;
    Brush.Color := clGray;
    FillRect(Rect(R.Left, R.Top + 2, R.Right, R.Bottom - 2));
    KX := R.Left + Round((R.Right - R.Left) * Volt / BronMaxVolt);
    Brush.Color := clNavy;
    FillRect(Rect(KX - 3, R.Top - 4, KX + 3, R.Bottom + 4));
    Brush.Style := bsClear;
    Font.Size := 6; Font.Style := []; Font.Color := clBlack;
    TextOut(R.Right + 4, R.Top - 3, '12V');
  end;
  PaintSelection;
end;

procedure TjanWisselbron.UpdateHintText;
begin
  Hint := Tr(FTaal, 'Wisselspanningsbron', 'AC voltage source', 'Source de tension alternative', 'Wechselspannungsquelle') +
    ': ' + Tr(FTaal, 'top', 'peak', 'crête', 'Spitze') + ' ' + FormatFloat('0.0', Volt) + ' V, ' +
    FormatFloat('0.#', Hz) + ' Hz    Ri = ' + OhmText(Ri) + #13#10 +
    'e = ' + FormatFloat('0.0', Volt) + ' V × sin(2π × ' + FormatFloat('0.#', Hz) + ' Hz × t) = ' +
      FormatFloat('+0.00;-0.00;0.00', Emk) + ' V' + #13#10 +
    Tr(FTaal,
      'De spanning wisselt als een sinus van richting; de tijd loopt tijdens de simulatie.' + #13#10 +
        'Vertraagd: het lichtnet is 50 Hz, hier 0,5 tot 2 Hz zodat je het ziet.' + #13#10 +
        'Schuifregelaar: topwaarde 0 tot 12 V. Rechtsklik: frequentie, inwendige weerstand.',
      'The voltage changes direction like a sine; time runs during the simulation.' + #13#10 +
        'Slowed down: the mains is 50 Hz, here 0.5 to 2 Hz so that you can see it.' + #13#10 +
        'Slider: peak value 0 to 12 V. Right-click: frequency, internal resistance.',
      'La tension change de sens comme une sinusoïde ; le temps avance pendant la simulation.' + #13#10 +
        'Ralenti : le secteur est à 50 Hz, ici 0,5 à 2 Hz pour que vous le voyiez.' + #13#10 +
        'Curseur : valeur de crête de 0 à 12 V. Clic droit : fréquence, résistance interne.',
      'Die Spannung wechselt wie ein Sinus die Richtung; die Zeit läuft während der Simulation.' + #13#10 +
        'Verlangsamt: Das Netz hat 50 Hz, hier 0,5 bis 2 Hz, damit Sie es sehen.' + #13#10 +
        'Schieberegler: Spitzenwert 0 bis 12 V. Rechtsklick: Frequenz, Innenwiderstand.');
end;

procedure TjanWisselbron.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Tr(FTaal, 'Wisselspanningsbron', 'AC voltage source', 'Source de tension alternative', 'Wechselspannungsquelle') + ' > ', 0);
  FOnStatus(Self, Tr(FTaal, 'top', 'peak', 'crête', 'Spitze') + ' ' + FormatFloat('0.0', Volt) + ' V   ' +
    FormatFloat('0.#', Hz) + ' Hz   e = ' + FormatFloat('+0.0;-0.0;0.0', Emk) + ' V', 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

{ TjanZekering }

constructor TjanZekering.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := ZekeringW;
  Height := ZekeringH;
  FNomIdx := 2;           // 500 mA
end;

function TjanZekering.PinCount: Integer;
begin
  Result := 2;
end;

function TjanZekering.PinPos(I: Integer): TPoint;
begin
  if I = 0 then Result := TP(17, 1) else Result := TP(17, ZekeringH - 8);
end;

function TjanZekering.KanDraaien: Boolean;
begin
  Result := True;
end;

function TjanZekering.StdMaat: TPoint;
begin
  Result := Point(ZekeringW, ZekeringH);
end;

function TjanZekering.ExtraBreedte: Integer;
begin
  Result := 0;
end;

function TjanZekering.StdRechtop: Boolean;
begin
  Result := True;   // gewone stand: staand buisje, klemmen boven en onder
end;

function TjanZekering.NominaalA: Double;
begin
  Result := ZekeringMA[FNomIdx] / 1000;
end;

procedure TjanZekering.SetNomIdx(const Value: Integer);
begin
  if (Value < Low(ZekeringMA)) or (Value > High(ZekeringMA)) or (Value = FNomIdx) then Exit;
  FNomIdx := Value;
  UpdateHintText;
  Invalidate;
end;

procedure TjanZekering.SetDoorgebrand(const Value: Boolean);
begin
  if Value = FDoorgebrand then Exit;
  FDoorgebrand := Value;
  Invalidate;
  SendStatusToBar;
end;

procedure TjanZekering.NomClick(Sender: TObject);
begin
  NomIdx := TMenuItem(Sender).Tag;
end;

procedure TjanZekering.VervangClick(Sender: TObject);
begin
  Doorgebrand := False;
  if Parent <> nil then
    UpdateSupply(Parent, True);
end;

procedure TjanZekering.AddMenuItems(APop: TPopupMenu);
var
  Mi, Sub: TMenuItem;
  i: Integer;
begin
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Zekering vervangen', 'Replace fuse', 'Remplacer le fusible', 'Sicherung ersetzen');
  Mi.Enabled := FDoorgebrand;
  Mi.OnClick := VervangClick;
  APop.Items.Add(Mi);
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Nominale stroom', 'Rated current', 'Courant nominal', 'Nennstrom');
  APop.Items.Add(Mi);
  for i := Low(ZekeringMA) to High(ZekeringMA) do
  begin
    Sub := TMenuItem.Create(APop);
    if ZekeringMA[i] >= 1000 then
      Sub.Caption := IntToStr(ZekeringMA[i] div 1000) + ' A'
    else
      Sub.Caption := IntToStr(ZekeringMA[i]) + ' mA';
    Sub.Tag := i;
    Sub.RadioItem := True;
    Sub.Checked := i = FNomIdx;
    Sub.OnClick := NomClick;
    Mi.Add(Sub);
  end;
end;

procedure TjanZekering.Paint;
var
  R: TRect;
  S: string;
  CX, CY, TW: Integer;
begin
  // tekening in de gewone (staande) stand; TP/TRc spiegelen ze als hij gedraaid is
  CX := 17 + 3;
  CY := 24;
  with Canvas do
  begin
    // geen achtergrond: de zekering is doorzichtig, alleen het buisje is te zien
    Brush.Style := bsSolid;
    // staand glazen buisje met het smeltdraadje
    if FDoorgebrand then Brush.Color := RGBToColor(255, 210, 210)
    else Brush.Color := RGBToColor(235, 245, 255);
    R := TRc(CX - 6, 14, CX + 7, 34);
    FillRect(R);
    Pen.Color := clGray; Pen.Width := 1;
    Brush.Style := bsClear;
    Rectangle(R);
    Brush.Style := bsSolid; Brush.Color := clGray;
    FillRect(TRc(CX - 5, 10, CX + 6, 14));
    FillRect(TRc(CX - 5, 34, CX + 6, 38));
    Pen.Color := clBlack; Pen.Width := 2;
    if FDoorgebrand then
    begin
      // gesmolten: het draadje is onderbroken
      TLijn(CX, 8, CX, CY - 5);
      TLijn(CX, CY + 5, CX, 38);
      Pen.Color := clRed;
      TLijn(CX - 4, CY - 4, CX + 4, CY + 4);
      TLijn(CX + 4, CY - 4, CX - 4, CY + 4);
    end
    else
      TLijn(CX, 8, CX, 38);
    // liggend staat de tekst niet in de draad: die loopt dan door
    if FGedraaid then
    begin
      Pen.Color := clBlack;
      TLijn(CX, 38, CX, 48);
    end;
    Pen.Width := 1;
    PaintPin(PinPos(0).X, PinPos(0).Y, FInVolt >= RailMinVolt);
    PaintPin(PinPos(1).X, PinPos(1).Y, FUitVolt >= RailMinVolt);
    // nominale stroom onder het buisje
    if ZekeringMA[FNomIdx] >= 1000 then
      S := IntToStr(ZekeringMA[FNomIdx] div 1000) + ' A'
    else
      S := IntToStr(ZekeringMA[FNomIdx]) + ' mA';
    Brush.Style := bsClear;
    Font.Name := 'Arial'; Font.Size := 6; Font.Style := [fsBold];
    if FDoorgebrand then Font.Color := clRed else Font.Color := clNavy;
    TW := TextWidth(S);
    if FGedraaid then
      TextOut((ZekeringH - TW) div 2, CX + 9, S)    // onder het liggende buisje
    else
      TextOut((ZekeringW - TW) div 2, 38, S);
    // het draadje loopt door tot de onderste klem
    Pen.Color := clBlack; Pen.Width := 2;
    TLijn(CX, 48, CX, ZekeringH - 8);
    Pen.Width := 1;
  end;
  PaintSelection;
end;

procedure TjanZekering.UpdateHintText;
var
  S: string;
begin
  if ZekeringMA[FNomIdx] >= 1000 then
    S := IntToStr(ZekeringMA[FNomIdx] div 1000) + ' A'
  else
    S := IntToStr(ZekeringMA[FNomIdx]) + ' mA';
  Hint := Tr(FTaal, 'Zekering', 'Fuse', 'Fusible', 'Sicherung') + ': ' + S + #13#10 +
    Tr(FTaal,
      'In serie tussen de bron en de + rail.' + #13#10 +
        'Smelt bij te veel stroom: rechtsklik om te vervangen.',
      'In series between the source and the + rail.' + #13#10 +
        'Blows when the current is too high: right-click to replace.',
      'En série entre la source et le rail +.' + #13#10 +
        'Fond si le courant est trop fort : clic droit pour le remplacer.',
      'In Reihe zwischen Quelle und + Schiene.' + #13#10 +
        'Brennt bei zu hohem Strom durch: Rechtsklick zum Ersetzen.');
end;

procedure TjanZekering.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Tr(FTaal, 'Zekering', 'Fuse', 'Fusible', 'Sicherung') + ' > ', 0);
  if FDoorgebrand then
    FOnStatus(Self, Tr(FTaal, 'doorgebrand', 'blown', 'fondu', 'durchgebrannt'), 1)
  else
    FOnStatus(Self, Tr(FTaal, 'in orde', 'OK', 'en ordre', 'in Ordnung'), 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

{ TjanAmpMeter }

constructor TjanAmpMeter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := AmpMeterW;
  Height := AmpMeterH;
end;

function TjanAmpMeter.PinCount: Integer;
begin
  Result := 2;
end;

function TjanAmpMeter.PinPos(I: Integer): TPoint;
begin
  if I = 0 then Result := Point(1, 35) else Result := Point(AmpMeterW - 8, 35);
end;

procedure TjanAmpMeter.Paint;
var
  R: TRect;
  S: string;
  TW: Integer;
begin
  with Canvas do
  begin
    Brush.Style := bsSolid;
    Brush.Color := clSilver;
    R := ClientRect;
    FillRect(R);
    Frame3D(R, clBtnHighlight, clBtnShadow, 1);
    Brush.Color := RGBToColor(220, 240, 250);
    R := Rect(18, 5, 82, 30);
    FillRect(R);
    Frame3D(R, clBtnShadow, clBtnHighlight, 2);
    Brush.Style := bsClear;
    // onder 10 mA één decimaal (bv. 0,4 mA bij een led net boven de drempel)
    if FStroom < 0.00995 then
      S := FormatFloat('0.0', FStroom * 1000)
    else
      S := FormatFloat('0', FStroom * 1000);
    Font.Name := 'Arial'; Font.Size := 12; Font.Style := [fsBold];
    if FStroom > 0.00005 then Font.Color := clRed else Font.Color := clGray;
    TW := TextWidth(S);
    TextOut(60 - TW, 8, S);
    Font.Size := 9; Font.Color := clBlack; Font.Style := [];
    TextOut(62, 11, 'mA');
    PaintPin(PinPos(0).X, PinPos(0).Y, FInVolt >= RailMinVolt);
    PaintPin(PinPos(1).X, PinPos(1).Y, FUitVolt >= RailMinVolt);
    Brush.Style := bsClear;
    Font.Size := 8; Font.Style := [fsBold]; Font.Color := clNavy;
    TextOut(40, 34, 'A');
  end;
  PaintSelection;
end;

procedure TjanAmpMeter.UpdateHintText;
begin
  Hint := Tr(FTaal, 'Milliampèremeter', 'Milliammeter', 'Milliampèremètre', 'Milliamperemeter') +
    ': ' + StroomRegel(FStroom) + '    (1 A = 1000 mA)' + #13#10 +
    Tr(FTaal,
      'In serie tussen de bron en de + rail.' + #13#10 +
        'Toont de stroom die de schakeling verbruikt.',
      'In series between the source and the + rail.' + #13#10 +
        'Shows the current the circuit uses.',
      'En série entre la source et le rail +.' + #13#10 +
        'Affiche le courant consommé par le circuit.',
      'In Reihe zwischen Quelle und + Schiene.' + #13#10 +
        'Zeigt den Strom, den die Schaltung verbraucht.');
end;

procedure TjanAmpMeter.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Tr(FTaal, 'Milliampèremeter', 'Milliammeter', 'Milliampèremètre', 'Milliamperemeter') + ' > ', 0);
  FOnStatus(Self, 'I = ' + FormatFloat('0', FStroom * 1000) + ' mA', 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

{ TjanWattMeter }

constructor TjanWattMeter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  HelpKeyword := 'wattmeter';
end;

function TjanWattMeter.Spanning: Double;
begin
  // de kant waar de stroom naartoe gaat (FAmp: van klem 0 naar klem 1)
  if FAmp >= 0 then Result := FUitVolt else Result := FInVolt;
  if Result < 0 then Result := 0;
end;

function TjanWattMeter.Watt: Double;
begin
  Result := FStroom * Spanning;
  if Result < 0.00005 then Result := 0;
end;

procedure TjanWattMeter.Paint;
var
  R: TRect;
  S: string;
  TW: Integer;
  P: Double;
begin
  P := Watt;
  with Canvas do
  begin
    Brush.Style := bsSolid;
    Brush.Color := clSilver;
    R := ClientRect;
    FillRect(R);
    Frame3D(R, clBtnHighlight, clBtnShadow, 1);
    Brush.Color := RGBToColor(255, 245, 215);
    R := Rect(14, 5, 86, 30);
    FillRect(R);
    Frame3D(R, clBtnShadow, clBtnHighlight, 2);
    Brush.Style := bsClear;
    // het getal zonder eenheid (de W staat ernaast): 0,014 / 0,30 / 1,44 / 6,0
    if P >= 10 then S := FormatFloat('0.0', P)
    else if P >= 0.1 then S := FormatFloat('0.00', P)
    else S := FormatFloat('0.000', P);
    Font.Name := 'Arial'; Font.Size := 12; Font.Style := [fsBold];
    if P > 0 then Font.Color := clRed else Font.Color := clGray;
    TW := TextWidth(S);
    TextOut(68 - TW, 8, S);
    Font.Size := 9; Font.Color := clBlack; Font.Style := [];
    TextOut(71, 11, 'W');
    PaintPin(PinPos(0).X, PinPos(0).Y, FInVolt >= RailMinVolt);
    PaintPin(PinPos(1).X, PinPos(1).Y, FUitVolt >= RailMinVolt);
    Brush.Style := bsClear;
    Font.Size := 8; Font.Style := [fsBold]; Font.Color := clNavy;
    TextOut(40, 34, 'W');
  end;
  PaintSelection;
end;

procedure TjanWattMeter.UpdateHintText;
begin
  Hint := Tr(FTaal, 'Wattmeter', 'Wattmeter', 'Wattmètre', 'Wattmeter') +
    ': P = ' + WattText(Watt) + '   (U = ' + VoltText(Spanning) + '   ' + StroomRegel(FStroom) + ')' + #13#10 +
    Tr(FTaal,
      'In serie, zoals een milliampèremeter. Toont het vermogen P = U x I' + #13#10 +
        'van alles wat achter de meter hangt (tot aan de - van de bron).',
      'In series, like a milliammeter. Shows the power P = U x I' + #13#10 +
        'of everything after the meter (up to the - of the source).',
      'En série, comme un milliampèremètre. Affiche la puissance P = U x I' + #13#10 +
        'de tout ce qui est branché après le wattmètre (jusqu''au - de la source).',
      'In Reihe, wie ein Milliamperemeter. Zeigt die Leistung P = U x I' + #13#10 +
        'von allem, was hinter dem Messgerät hängt (bis zum - der Quelle).');
end;

procedure TjanWattMeter.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Tr(FTaal, 'Wattmeter', 'Wattmeter', 'Wattmètre', 'Wattmeter') + ' > ', 0);
  FOnStatus(Self, 'P = ' + WattText(Watt), 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

{ TjanWeerstand }

constructor TjanWeerstand.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := WeerstandW;
  Height := WeerstandH;
  FSoort := 2;            // slecht contact, 2 ohm
  HelpKeyword := 'weerstand';
end;

function TjanWeerstand.PinCount: Integer;
begin
  Result := 2;
end;

function TjanWeerstand.PinPos(I: Integer): TPoint;
begin
  if I = 0 then Result := TP(1, 11) else Result := TP(WeerstandW - 8, 11);
end;

function TjanWeerstand.KanDraaien: Boolean;
begin
  Result := True;
end;

function TjanWeerstand.StdMaat: TPoint;
begin
  Result := Point(WeerstandW, WeerstandH);
end;

function TjanWeerstand.ExtraBreedte: Integer;
begin
  Result := 74;   // waarde en soort rechts naast het blokje
end;

function TjanWeerstand.Ohm: Double;
begin
  Result := WeerstandOhm[FSoort];
end;

function TjanWeerstand.Vermogen: Double;
begin
  Result := FStroom * FStroom * Ohm;
end;

procedure TjanWeerstand.SetSoort(const Value: Integer);
begin
  if (Value < Low(WeerstandOhm)) or (Value > High(WeerstandOhm)) or (Value = FSoort) then Exit;
  FSoort := Value;
  UpdateHintText;
  Invalidate;
  if Parent <> nil then
    UpdateSupply(Parent, True);
end;

procedure TjanWeerstand.SoortClick(Sender: TObject);
begin
  Soort := TMenuItem(Sender).Tag;
end;

procedure TjanWeerstand.AddMenuItems(APop: TPopupMenu);
var
  Mi, Sub: TMenuItem;
  i: Integer;
begin
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Soort', 'Kind', 'Type', 'Art');
  APop.Items.Add(Mi);
  for i := Low(WeerstandOhm) to High(WeerstandOhm) do
  begin
    Sub := TMenuItem.Create(APop);
    Sub.Caption := WeerstandNaam(FTaal, i) + ' (' + OhmText(WeerstandOhm[i]) + ')';
    Sub.Tag := i;
    Sub.RadioItem := True;
    Sub.Checked := i = FSoort;
    Sub.OnClick := SoortClick;
    Mi.Add(Sub);
  end;
end;

function TjanWeerstand.Naam: string;
begin
  if FDeler and (FSoort >= 4) then
    Result := Tr(FTaal, 'spanningsdeler', 'voltage divider', 'diviseur de tension', 'Spannungsteiler')
  else
    Result := WeerstandNaam(FTaal, FSoort);
end;

procedure TjanWeerstand.SetDeler(const Value: Boolean);
begin
  if Value = FDeler then Exit;
  FDeler := Value;
  UpdateHintText;
  Invalidate;
end;

procedure TjanWeerstand.Paint;
var
  R: TRect;
  S: string;
  CY, TW, X, H, K: Integer;
  Heat: Double;
begin
  // tekening in liggende coördinaten; TP/TRc spiegelen ze als hij rechtop staat
  CY := 11 + 3;
  with Canvas do
  begin
    // doorzichtig: alleen de draadjes, het blokje en de tekst
    Pen.Color := clBlack; Pen.Width := 2;
    TLijn(8, CY, 26, CY);
    TLijn(WeerstandW - 26, CY, WeerstandW - 8, CY);
    Pen.Width := 1;
    // schemasymbool (rechthoek); kleurt rood als het warm wordt
    Heat := Vermogen / 0.5;
    if Heat > 1 then Heat := 1;
    Brush.Style := bsSolid;
    Brush.Color := RGBToColor(255, 255 - Round(140 * Heat), 255 - Round(255 * Heat));
    R := TRc(26, CY - 8, WeerstandW - 26, CY + 9);
    FillRect(R);
    Pen.Color := clBlack;
    Brush.Style := bsClear;
    Rectangle(R);
    if FSoort = 3 then
    begin
      // verbrand: zwarte vlekken aan de uiteinden (naast de waarde)
      Brush.Style := bsSolid; Brush.Color := RGBToColor(60, 40, 30);
      Pen.Color := RGBToColor(60, 40, 30);
      for X := 0 to 3 do
      begin
        H := 4 + (X mod 2) * 2;
        if X < 2 then K := 28 + X * 4 else K := WeerstandW - 36 + (X - 2) * 4;
        Ellipse(TRc(K, CY - 6 + (X mod 2) * 6, K + H, CY - 6 + (X mod 2) * 6 + H));
      end;
      Pen.Color := clBlack;
      Brush.Style := bsClear;
    end;
    PaintPin(PinPos(0).X, PinPos(0).Y, FInVolt >= RailMinVolt);
    PaintPin(PinPos(1).X, PinPos(1).Y, FUitVolt >= RailMinVolt);
    Font.Name := 'Arial'; Font.Size := 7; Font.Style := [fsBold]; Font.Color := clNavy;
    S := OhmText(Ohm);
    if FGedraaid then
    begin
      // rechtop: waarde en soort rechts naast het blokje, de soort op twee regels
      X := CY + 13;
      TextOut(X, WeerstandW div 2 - 16, S);
      Font.Size := 7; Font.Style := []; Font.Color := clBlack;
      if FSoort <= 3 then Font.Style := [fsBold];
      if FSoort = 3 then Font.Color := RGBToColor(150, 0, 0);
      S := Naam;
      K := Pos(' ', S);
      if (TextWidth(S) > Width - X) and (K > 0) then
      begin
        TextOut(X, WeerstandW div 2 - 2, Copy(S, 1, K - 1));
        TextOut(X, WeerstandW div 2 + 8, Copy(S, K + 1, MaxInt));
      end
      else
        TextOut(X, WeerstandW div 2 - 2, S);
      PaintSelection;
      Exit;
    end;
    // liggend: waarde in het blokje, soort eronder
    if FSoort = 3 then
    begin
      TW := TextWidth(S);
      Brush.Style := bsSolid; Brush.Color := clWhite;
      FillRect(Rect((WeerstandW - TW) div 2 - 1, CY - 6, (WeerstandW + TW) div 2 + 1, CY + 6));
      Brush.Style := bsClear;
    end;
    TW := TextWidth(S);
    TextOut((WeerstandW - TW) div 2, CY - 6, S);
    // de soort eronder, goed leesbaar: een contact vet (verbrand in donkerrood)
    if FSoort <= 3 then
    begin
      Font.Size := 8; Font.Style := [];
      if FSoort = 3 then Font.Color := RGBToColor(150, 0, 0) else Font.Color := clBlack;
    end
    else
    begin
      Font.Size := 7; Font.Style := []; Font.Color := clBlack;
    end;
    S := Naam;
    TW := TextWidth(S);
    TextOut((WeerstandW - TW) div 2, CY + 10, S);
  end;
  PaintSelection;
end;

procedure TjanWeerstand.UpdateHintText;
begin
  Hint := Tr(FTaal, 'Weerstand', 'Resistance', 'Résistance', 'Widerstand') + ': ' +
    Naam + ' (' + OhmText(Ohm) + ')' + #13#10 +
    StroomRegel(FStroom) + #13#10 +
    'U = I × R = ' + AmpText(FStroom) + ' × ' + OhmText(Ohm) + ' = ' +
      VoltText(FStroom * Ohm) + #13#10 +
    VermogenRegel(FStroom * Ohm, FStroom) + #13#10;
  if FDeler and (FSoort >= 4) then
    Hint := Hint + Tr(FTaal,
      'Samen met de LDR of NTC vormt deze weerstand een spanningsdeler: de spanning tussen' + #13#10 +
        'de twee verandert met het licht of de temperatuur, en die gaat naar de poort.' + #13#10 +
        'Met een andere weerstand schakelt de poort bij een ander licht of een andere temperatuur om.',
      'Together with the LDR or NTC this resistor forms a voltage divider: the voltage between' + #13#10 +
        'the two changes with the light or the temperature, and it goes to the gate.' + #13#10 +
        'With another resistance the gate switches at another light level or temperature.',
      'Avec la LDR ou la CTN, cette résistance forme un diviseur de tension : la tension entre' + #13#10 +
        'les deux varie avec la lumière ou la température, et elle va à la porte.' + #13#10 +
        'Avec une autre résistance, la porte bascule à une autre lumière ou une autre température.',
      'Zusammen mit dem LDR oder NTC bildet dieser Widerstand einen Spannungsteiler: Die Spannung zwischen' + #13#10 +
        'beiden ändert sich mit dem Licht oder der Temperatur und geht zum Gatter.' + #13#10 +
        'Mit einem anderen Widerstand schaltet das Gatter bei einem anderen Licht oder einer anderen Temperatur um.') + #13#10;
  Hint := Hint + Tr(FTaal,
      'In serie in de voedingsleiding: er gaat spanning verloren (U = I × R).' + #13#10 +
        'Meet ze met een voltmeter over de twee klemmen. Rechtsklik: soort kiezen.',
      'In series in the supply line: some voltage is lost (U = I × R).' + #13#10 +
        'Measure it with a voltmeter across both terminals. Right-click: choose the kind.',
      'En série dans la ligne d''alimentation : une partie de la tension est perdue (U = I × R).' + #13#10 +
        'Mesurez-la avec un voltmètre entre les deux bornes. Clic droit : choisir le type.',
      'In Reihe in der Versorgungsleitung: Es geht Spannung verloren (U = I × R).' + #13#10 +
        'Messen Sie sie mit einem Voltmeter über beide Klemmen. Rechtsklick: Art wählen.');
end;

procedure TjanWeerstand.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Tr(FTaal, 'Weerstand', 'Resistance', 'Résistance', 'Widerstand') + ' > ', 0);
  FOnStatus(Self, Naam + ' ' + OhmText(Ohm) + '   I = ' +
    FormatFloat('0', FStroom * 1000) + ' mA', 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

{ TjanPotmeter }

constructor TjanPotmeter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := PotW;
  Height := PotH;
  FSoort := PotStandaard;
  FProcent := 50;
  HelpKeyword := 'potmeter';
end;

function TjanPotmeter.PinCount: Integer;
begin
  Result := 3;
end;

// A links en B rechts op de hoogte van het symbool, de loper onderaan in het midden
function TjanPotmeter.PinPos(I: Integer): TPoint;
begin
  case I of
    0: Result := Point(1, 17);
    1: Result := Point(PotW - 8, 17);
  else
    Result := Point(PotW div 2 - 3, PotH - 8);
  end;
end;

function TjanPotmeter.Ohm: Double;
begin
  Result := PotOhm[FSoort];
end;

function TjanPotmeter.OhmAL: Double;
begin
  Result := Ohm * FProcent / 100;
end;

function TjanPotmeter.OhmLB: Double;
begin
  Result := Ohm * (100 - FProcent) / 100;
end;

procedure TjanPotmeter.SetSoort(const Value: Integer);
begin
  if (Value < Low(PotOhm)) or (Value > High(PotOhm)) or (Value = FSoort) then Exit;
  FSoort := Value;
  UpdateHintText;
  Invalidate;
  if Parent <> nil then
    UpdateSupply(Parent, True);
end;

procedure TjanPotmeter.SetProcent(const Value: Integer);
var
  V: Integer;
begin
  V := Value;
  if V < 0 then V := 0;
  if V > 100 then V := 100;
  if V = FProcent then Exit;
  FProcent := V;
  UpdateHintText;
  Invalidate;
  if Parent <> nil then
    UpdateSupply(Parent, True);
end;

procedure TjanPotmeter.SoortClick(Sender: TObject);
begin
  Soort := TMenuItem(Sender).Tag;
end;

procedure TjanPotmeter.AddMenuItems(APop: TPopupMenu);
var
  Mi, Sub: TMenuItem;
  i: Integer;
begin
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Waarde', 'Value', 'Valeur', 'Wert');
  APop.Items.Add(Mi);
  for i := Low(PotOhm) to High(PotOhm) do
  begin
    Sub := TMenuItem.Create(APop);
    Sub.Caption := OhmText(PotOhm[i]);
    Sub.Tag := i;
    Sub.RadioItem := True;
    Sub.Checked := i = FSoort;
    Sub.OnClick := SoortClick;
    Mi.Add(Sub);
  end;
end;

// de baan waarover de loper schuift (onder het symbool)
function TjanPotmeter.SliderRect: TRect;
begin
  Result := Rect(22, 30, PotW - 22, 44);
end;

procedure TjanPotmeter.SlideTo(X: Integer);
var
  R: TRect;
begin
  R := SliderRect;
  Procent := Round((X - R.Left) / (R.Right - R.Left) * 100);
end;

function TjanPotmeter.HandleClick(X, Y: Integer): Boolean;
var
  R: TRect;
begin
  R := SliderRect;
  InflateRect(R, 4, 2);
  Result := PtInRect(R, Point(X, Y));
  if Result then
  begin
    FSliding := True;
    SlideTo(X);
  end;
end;

procedure TjanPotmeter.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  if FSliding then
  begin
    if ssLeft in Shift then SlideTo(X) else FSliding := False;
    Exit;
  end;
  inherited MouseMove(Shift, X, Y);
end;

procedure TjanPotmeter.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FSliding := False;
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TjanPotmeter.Paint;
var
  R: TRect;
  S: string;
  CY, TW, XL, PX, YB: Integer;
begin
  CY := PinPos(0).Y + 3;
  R := SliderRect;
  XL := R.Left + Round((R.Right - R.Left) * FProcent / 100);   // x van de loper
  PX := PinPos(2).X + 3;                                         // x van de loperklem
  YB := 37;                                                      // hoogte van de schuifbaan
  with Canvas do
  begin
    // aansluitdraadjes naar A en B
    Pen.Color := clBlack; Pen.Width := 2;
    MoveTo(PinPos(0).X + 7, CY); LineTo(22, CY);
    MoveTo(PotW - 22, CY); LineTo(PinPos(1).X, CY);
    Pen.Width := 1;
    // het weerstandsblokje: A-L en L-B in een eigen tint
    Brush.Style := bsSolid;
    Brush.Color := RGBToColor(255, 200, 150);
    FillRect(Rect(22, CY - 7, XL, CY + 8));
    Brush.Color := RGBToColor(255, 228, 200);
    FillRect(Rect(XL, CY - 7, PotW - 22, CY + 8));
    Brush.Style := bsClear;
    Rectangle(Rect(22, CY - 7, PotW - 22, CY + 8));
    // waarde en stand bovenaan
    Font.Name := 'Arial'; Font.Size := 7; Font.Style := [fsBold]; Font.Color := clNavy;
    S := OhmText(Ohm) + '   ' + IntToStr(FProcent) + ' %';
    TW := TextWidth(S);
    TextOut((PotW - TW) div 2, 0, S);
    Font.Size := 6; Font.Style := [fsBold];
    TextOut(10, CY + 6, 'A');
    TextOut(PotW - 16, CY + 6, 'B');
    TextOut(PX + 6, PotH - 16, 'L');
    // schuifbaan (grijze gleuf) met de loper: een pijl die op het blokje drukt
    Brush.Style := bsSolid; Brush.Color := RGBToColor(200, 200, 200);
    Pen.Color := clGray;
    RoundRect(R.Left - 2, YB - 2, R.Right + 3, YB + 3, 4, 4);
    // de loperdraad: van de klem L naar de schuifknop
    Pen.Color := clBlack; Pen.Width := 2;
    MoveTo(PX, PinPos(2).Y + 1); LineTo(PX, YB + 9);
    LineTo(XL, YB + 9); LineTo(XL, YB + 5);
    // de pijl van de schuifknop naar het blokje
    MoveTo(XL, YB - 6); LineTo(XL, CY + 12);
    Pen.Width := 1;
    Brush.Color := clBlack;
    Polygon([Point(XL - 4, CY + 13), Point(XL + 4, CY + 13), Point(XL, CY + 8)]);
    // de schuifknop zelf
    Brush.Color := RGBToColor(40, 80, 160);
    Pen.Color := RGBToColor(20, 40, 90);
    Rectangle(Rect(XL - 5, YB - 5, XL + 6, YB + 6));
    Pen.Color := clBlack;
    Brush.Style := bsClear;
    PaintPin(PinPos(0).X, PinPos(0).Y, FPinV[0] >= RailMinVolt);
    PaintPin(PinPos(1).X, PinPos(1).Y, FPinV[1] >= RailMinVolt);
    PaintPin(PinPos(2).X, PinPos(2).Y, FPinV[2] >= RailMinVolt);
  end;
  PaintSelection;
end;

procedure TjanPotmeter.UpdateHintText;
begin
  Hint := Tr(FTaal, 'Potentiometer', 'Potentiometer', 'Potentiomètre', 'Potentiometer') + ': ' +
    OhmText(Ohm) + ', ' + Tr(FTaal, 'loper op', 'wiper at', 'curseur à', 'Schleifer bei') + ' ' +
    IntToStr(FProcent) + ' %' + #13#10 +
    'A-L: ' + OhmText(OhmAL) + '   U = ' + VoltText(FPinV[0] - FPinV[2]) + '   I = ' + MilliAmpText(Abs(FIa)) + #13#10 +
    'L-B: ' + OhmText(OhmLB) + '   U = ' + VoltText(FPinV[2] - FPinV[1]) + '   I = ' + MilliAmpText(Abs(FIb)) + #13#10 +
    Tr(FTaal,
      'Drie klemmen: de uiteinden A en B, en de loper L. Sleep de loper met de muis.' + #13#10 +
        'Rechtsklik: waarde kiezen.',
      'Three terminals: the ends A and B, and the wiper L. Drag the wiper with the mouse.' + #13#10 +
        'Right-click: choose the value.',
      'Trois bornes : les extrémités A et B, et le curseur L. Faites glisser le curseur avec la souris.' + #13#10 +
        'Clic droit : choisir la valeur.',
      'Drei Klemmen: die Enden A und B und der Schleifer L. Ziehen Sie den Schleifer mit der Maus.' + #13#10 +
        'Rechtsklick: Wert wählen.');
end;

procedure TjanPotmeter.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Tr(FTaal, 'Potentiometer', 'Potentiometer', 'Potentiomètre', 'Potentiometer') + ' > ', 0);
  FOnStatus(Self, OhmText(Ohm) + '   ' + IntToStr(FProcent) + ' %   A-L ' + OhmText(OhmAL) +
    '   L-B ' + OhmText(OhmLB), 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

{ TjanSensorR }

constructor TjanSensorR.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := SensW;
  Height := SensH;
  FStand := 50;
end;

function TjanSensorR.PinCount: Integer;
begin
  Result := 2;
end;

function TjanSensorR.PinPos(I: Integer): TPoint;
begin
  if I = 0 then Result := Point(1, 17) else Result := Point(SensW - 8, 17);
end;

procedure TjanSensorR.SetStand(const Value: Integer);
var
  V: Integer;
begin
  V := Value;
  if V < 0 then V := 0;
  if V > 100 then V := 100;
  if V = FStand then Exit;
  FStand := V;
  UpdateHintText;
  Invalidate;
  SendStatusToBar;
  if Parent <> nil then
    UpdateSupply(Parent, True);
end;

// de baan van de schuifregelaar (onder het blokje)
function TjanSensorR.SliderRect: TRect;
begin
  Result := Rect(22, 42, SensW - 22, 52);
end;

// slepen aan de knop: de stand verschuift evenveel als de muis, zonder te springen
procedure TjanSensorR.SlideTo(X: Integer);
var
  R: TRect;
begin
  R := SliderRect;
  Stand := FDragStand + Round((X - FDragX) / (R.Right - R.Left) * 100);
end;

function TjanSensorR.HandleClick(X, Y: Integer): Boolean;
var
  R: TRect;
  XK: Integer;
begin
  R := SliderRect;
  InflateRect(R, 4, 3);
  Result := PtInRect(R, Point(X, Y));
  if not Result then Exit;
  R := SliderRect;
  XK := R.Left + Round((R.Right - R.Left) * FStand / 100);
  if Abs(X - XK) <= 6 then
  begin
    // op de knop: verslepen
    FSliding := True;
    FDragX := X;
    FDragStand := FStand;
  end
  // naast de knop: een stap van 1 in die richting (fijn instellen)
  else if X < XK then
    Stand := FStand - 1
  else
    Stand := FStand + 1;
end;

procedure TjanSensorR.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  if FSliding then
  begin
    if ssLeft in Shift then SlideTo(X) else FSliding := False;
    Exit;
  end;
  inherited MouseMove(Shift, X, Y);
end;

procedure TjanSensorR.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FSliding := False;
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TjanSensorR.Paint;
var
  R, Rs: TRect;
  S: string;
  CY, TW, XK, YB: Integer;
begin
  CY := 17 + 3;
  Rs := SliderRect;
  YB := (Rs.Top + Rs.Bottom) div 2;
  XK := Rs.Left + Round((Rs.Right - Rs.Left) * FStand / 100);
  with Canvas do
  begin
    // aansluitdraadjes en het blokje (zoals een weerstand)
    Pen.Color := clBlack; Pen.Width := 2;
    MoveTo(8, CY); LineTo(30, CY);
    MoveTo(SensW - 30, CY); LineTo(SensW - 8, CY);
    Pen.Width := 1;
    R := Rect(30, CY - 7, SensW - 30, CY + 8);
    Brush.Style := bsSolid; Brush.Color := RGBToColor(255, 228, 200);
    FillRect(R);
    Brush.Style := bsClear;
    Rectangle(R);
    PaintSymbool(R);
    // de weerstand in het blokje, de naam en de stand erboven
    Brush.Style := bsClear;
    Font.Name := 'Arial'; Font.Size := 7; Font.Style := [fsBold]; Font.Color := clNavy;
    S := OhmText(Ohm);
    TW := TextWidth(S);
    TextOut((SensW - TW) div 2, CY - 6, S);
    // schermpje onderaan met de stand (het licht of de temperatuur), zoals bij een meter
    R := Rect(30, SensH - 27, SensW - 30, SensH - 2);
    Brush.Style := bsSolid; Brush.Color := RGBToColor(255, 250, 220);
    FillRect(R);
    Frame3D(R, clBtnShadow, clBtnHighlight, 2);
    Brush.Style := bsClear;
    Font.Size := 12; Font.Style := [fsBold]; Font.Color := clRed;
    S := IntToStr(FStand);
    Font.Size := 9; Font.Style := [];
    TW := TextWidth(' ' + Eenheid);
    Font.Size := 12; Font.Style := [fsBold];
    XK := (SensW + TextWidth(S) - TW) div 2;          // rechterkant van het getal
    TextOut(XK - TextWidth(S), R.Top + 3, S);
    Font.Size := 9; Font.Style := []; Font.Color := clBlack;
    TextOut(XK, R.Top + 6, ' ' + Eenheid);
    XK := Rs.Left + Round((Rs.Right - Rs.Left) * FStand / 100);
    // de naam linksboven
    Font.Size := 6; Font.Style := []; Font.Color := clBlack;
    TextOut(2, 0, Naam);
    // schuifregelaar
    Brush.Style := bsSolid; Brush.Color := RGBToColor(200, 200, 200);
    Pen.Color := clGray;
    RoundRect(Rs.Left - 2, YB - 2, Rs.Right + 3, YB + 3, 4, 4);
    Brush.Color := KnopKleur;
    Pen.Color := clBlack;
    Rectangle(Rect(XK - 5, YB - 5, XK + 6, YB + 6));
    Brush.Style := bsClear;
    PaintPin(PinPos(0).X, PinPos(0).Y, FPinV[0] >= RailMinVolt);
    PaintPin(PinPos(1).X, PinPos(1).Y, FPinV[1] >= RailMinVolt);
  end;
  PaintSelection;
end;

procedure TjanSensorR.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Naam + ' > ', 0);
  FOnStatus(Self, StandTekst + '   R = ' + OhmText(Ohm) + '   I = ' + MilliAmpText(Abs(FAmp)), 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

{ TjanLDR }

constructor TjanLDR.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  HelpKeyword := 'ldr';
end;

function TjanLDR.Ohm: Double;
begin
  // 1 Mohm bij 0 % licht, 100 ohm bij 100 %: elke 25 % tien keer kleiner
  Result := LdrDonker * Exp(-4 * FStand / 100 * Ln(10));
end;

function TjanLDR.StandTekst: string;
begin
  Result := Tr(FTaal, 'licht', 'light', 'lumière', 'Licht') + ' ' + IntToStr(FStand) + ' %';
end;

function TjanLDR.Eenheid: string;
begin
  Result := '%';
end;

function TjanLDR.Naam: string;
begin
  Result := 'LDR';
end;

function TjanLDR.KnopKleur: TColor;
var
  K: Integer;
begin
  // van donkergrijs (donker) naar geel (fel licht)
  K := Round(FStand * 2.55);
  Result := RGBToColor(60 + K * 195 div 255, 60 + K * 160 div 255, 60 - K * 60 div 255);
end;

procedure TjanLDR.PaintSymbool(const R: TRect);
var
  i, X: Integer;
begin
  // twee pijlen van linksboven naar het blokje: het licht
  with Canvas do
  begin
    Pen.Width := 1;
    if FStand > 10 then Pen.Color := RGBToColor(220, 160, 0) else Pen.Color := clGray;
    Brush.Style := bsSolid; Brush.Color := Pen.Color;
    for i := 0 to 1 do
    begin
      X := R.Left + 4 + i * 9;
      MoveTo(X, R.Top - 13); LineTo(X + 7, R.Top - 3);
      Polygon([Point(X + 8, R.Top - 1), Point(X + 3, R.Top - 4), Point(X + 7, R.Top - 7)]);
    end;
    Brush.Style := bsClear;
    Pen.Color := clBlack;
  end;
end;

procedure TjanLDR.UpdateHintText;
begin
  Hint := 'LDR: ' + StandTekst + '   R = ' + OhmText(Ohm) + #13#10 +
    'U = ' + VoltText(Abs(FPinV[0] - FPinV[1])) + '   I = ' + MilliAmpText(Abs(FAmp)) + #13#10 +
    Tr(FTaal,
      'Lichtgevoelige weerstand: hoe meer licht, hoe kleiner de weerstand' + #13#10 +
        '(1 MΩ in het donker, 100 Ω in fel licht). Sleep de knop om het licht te regelen.',
      'Light-dependent resistor: the more light, the lower the resistance' + #13#10 +
        '(1 MΩ in the dark, 100 Ω in bright light). Drag the knob to set the light.',
      'Photorésistance : plus il y a de lumière, plus la résistance est faible' + #13#10 +
        '(1 MΩ dans le noir, 100 Ω en pleine lumière). Faites glisser le bouton pour régler la lumière.',
      'Fotowiderstand: Je mehr Licht, desto kleiner der Widerstand' + #13#10 +
        '(1 MΩ im Dunkeln, 100 Ω bei hellem Licht). Ziehen Sie den Knopf, um das Licht einzustellen.') + #13#10 +
    Tr(FTaal, 'Klik naast de knop voor een stap van 1.', 'Click beside the knob for a step of 1.',
      'Cliquez à côté du bouton pour un pas de 1.', 'Neben den Knopf klicken für einen Schritt von 1.');
end;

{ TjanNTC }

constructor TjanNTC.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FStand := 25;
  HelpKeyword := 'ntc';
end;

function TjanNTC.Ohm: Double;
begin
  // R = R25 x e^(B x (1/T - 1/T25)), T in kelvin
  Result := NtcR25 * Exp(NtcB * (1 / (FStand + 273.15) - 1 / 298.15));
end;

function TjanNTC.StandTekst: string;
begin
  Result := IntToStr(FStand) + ' °C';
end;

function TjanNTC.Eenheid: string;
begin
  Result := '°C';
end;

function TjanNTC.Naam: string;
begin
  Result := 'NTC';
end;

function TjanNTC.KnopKleur: TColor;
var
  K: Integer;
begin
  // van blauw (koud) naar rood (warm)
  K := Round(FStand * 2.55);
  Result := RGBToColor(K, 60, 255 - K);
end;

procedure TjanNTC.PaintSymbool(const R: TRect);
begin
  // schuine streep door het blokje met een korte horizontale voet, en -t°
  with Canvas do
  begin
    Pen.Color := clBlack; Pen.Width := 1;
    MoveTo(R.Left - 4, R.Bottom + 3); LineTo(R.Left + 4, R.Bottom + 3);
    LineTo(R.Right - 4, R.Top - 4);
    Font.Name := 'Arial'; Font.Size := 6; Font.Style := []; Font.Color := clBlack;
    Brush.Style := bsClear;
    TextOut(R.Right - 16, R.Bottom + 1, '-t°');
  end;
end;

procedure TjanNTC.UpdateHintText;
begin
  Hint := 'NTC: ' + StandTekst + '   R = ' + OhmText(Ohm) + #13#10 +
    'U = ' + VoltText(Abs(FPinV[0] - FPinV[1])) + '   I = ' + MilliAmpText(Abs(FAmp)) + #13#10 +
    Tr(FTaal,
      'Temperatuurgevoelige weerstand: hoe warmer, hoe kleiner de weerstand' + #13#10 +
        '(10 kΩ bij 25 °C). Sleep de knop om de temperatuur te regelen.',
      'Temperature-dependent resistor: the warmer, the lower the resistance' + #13#10 +
        '(10 kΩ at 25 °C). Drag the knob to set the temperature.',
      'Thermistance : plus il fait chaud, plus la résistance est faible' + #13#10 +
        '(10 kΩ à 25 °C). Faites glisser le bouton pour régler la température.',
      'Heißleiter: Je wärmer, desto kleiner der Widerstand' + #13#10 +
        '(10 kΩ bei 25 °C). Ziehen Sie den Knopf, um die Temperatur einzustellen.') + #13#10 +
    Tr(FTaal, 'Klik naast de knop voor een stap van 1.', 'Click beside the knob for a step of 1.',
      'Cliquez à côté du bouton pour un pas de 1.', 'Neben den Knopf klicken für einen Schritt von 1.');
end;

{ TjanLamp2 }

constructor TjanLamp2.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := Lamp2W;
  Height := Lamp2H;
  FSoort := Lamp2Standaard;
  HelpKeyword := 'lamp2';
end;

function TjanLamp2.PinCount: Integer;
begin
  Result := 2;
end;

function TjanLamp2.PinPos(I: Integer): TPoint;
begin
  if I = 0 then Result := TP(1, 17) else Result := TP(Lamp2W - 8, 17);
end;

function TjanLamp2.KanDraaien: Boolean;
begin
  Result := True;
end;

function TjanLamp2.StdMaat: TPoint;
begin
  Result := Point(Lamp2W, Lamp2H);
end;

function TjanLamp2.ExtraBreedte: Integer;
begin
  Result := 28;   // de weerstand rechts naast de lamp
end;

function TjanLamp2.Ohm: Double;
begin
  Result := Lamp2Ohm[FSoort];
end;

function TjanLamp2.Is5V: Boolean;
begin
  Result := FSoort >= Lamp2Eerste5V;
end;

function TjanLamp2.Volt: Double;
begin
  if Is5V then Result := 5 else Result := BronMaxVolt;
end;

function TjanLamp2.Aan: Boolean;
begin
  Result := Vermogen >= 0.25 * Volt * Volt / Ohm;
end;

procedure TjanLamp2.VoltClick(Sender: TObject);
begin
  if TMenuItem(Sender).Tag = 5 then
  begin
    if not Is5V then Soort := Lamp2Standaard5V;
  end
  else if Is5V then
    Soort := Lamp2Standaard;
end;

procedure TjanLamp2.SetSoort(const Value: Integer);
begin
  if (Value < Low(Lamp2Ohm)) or (Value > High(Lamp2Ohm)) or (Value = FSoort) then Exit;
  FSoort := Value;
  UpdateHintText;
  Invalidate;
  if Parent <> nil then
    UpdateSupply(Parent, True);
end;

procedure TjanLamp2.SoortClick(Sender: TObject);
begin
  Soort := TMenuItem(Sender).Tag;
end;

procedure TjanLamp2.AddMenuItems(APop: TPopupMenu);
var
  Mi, Sub: TMenuItem;
  i: Integer;
begin
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Spanning van de lamp', 'Lamp voltage', 'Tension de la lampe', 'Spannung der Lampe');
  APop.Items.Add(Mi);
  for i := 0 to 1 do
  begin
    Sub := TMenuItem.Create(APop);
    if i = 0 then
    begin
      Sub.Caption := Tr(FTaal, 'Lamp voor 5 V (ook aan een poort)', 'Lamp for 5 V (also on a gate)',
        'Lampe pour 5 V (aussi sur une porte)', 'Lampe für 5 V (auch an einem Gatter)');
      Sub.Tag := 5;
      Sub.Checked := Is5V;
    end
    else
    begin
      Sub.Caption := Tr(FTaal, 'Lamp voor 12 V', 'Lamp for 12 V', 'Lampe pour 12 V', 'Lampe für 12 V');
      Sub.Tag := 12;
      Sub.Checked := not Is5V;
    end;
    Sub.RadioItem := True;
    Sub.OnClick := VoltClick;
    Mi.Add(Sub);
  end;
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Weerstand', 'Resistance', 'Résistance', 'Widerstand');
  APop.Items.Add(Mi);
  for i := Low(Lamp2Ohm) to High(Lamp2Ohm) do
  begin
    if (i >= Lamp2Eerste5V) <> Is5V then Continue;
    Sub := TMenuItem.Create(APop);
    Sub.Caption := OhmText(Lamp2Ohm[i]) + '  (' + FormatFloat('0', Volt) + ' V: ' + MilliAmpText(Volt / Lamp2Ohm[i]) +
      ', ' + WattText(Volt * Volt / Lamp2Ohm[i]) + ')';
    Sub.Tag := i;
    Sub.RadioItem := True;
    Sub.Checked := i = FSoort;
    Sub.OnClick := SoortClick;
    Mi.Add(Sub);
  end;
end;

function TjanLamp2.Spanning: Double;
begin
  Result := Abs(FAmp) * Ohm;
end;

function TjanLamp2.Vermogen: Double;
begin
  Result := FAmp * FAmp * Ohm;
end;

procedure TjanLamp2.Paint;
var
  CX, CY, Rr, TW: Integer;
  K: Double;
  S: string;
begin
  // tekening in de gewone stand; TP/TRc spiegelen ze als de lamp gedraaid is
  CX := Lamp2W div 2;
  CY := 17 + 3;
  Rr := 12;
  // helderheid volgt het vermogen: vol bij het vermogen van de lamp op haar
  // eigen spanning (5 of 12 V)
  K := Vermogen / (Volt * Volt / Ohm);
  if K > 1 then K := 1;
  with Canvas do
  begin
    Pen.Color := clBlack; Pen.Width := 2;
    TLijn(8, CY, CX - Rr, CY);
    TLijn(CX + Rr, CY, Lamp2W - 8, CY);
    // gloed rond de lamp
    if K > 0.02 then
    begin
      Pen.Style := psClear;
      Brush.Style := bsSolid;
      Brush.Color := RGBToColor(255, 240, Round(200 - 120 * K));
      Ellipse(TRc(CX - Rr - 5, CY - Rr - 5, CX + Rr + 6, CY + Rr + 6));
      Pen.Style := psSolid;
    end;
    Brush.Style := bsSolid;
    if K > 0.02 then
      Brush.Color := RGBToColor(255, 255 - Round(43 * K), 255 - Round(255 * K))
    else
      Brush.Color := clWhite;
    Pen.Width := 2;
    Ellipse(TRc(CX - Rr, CY - Rr, CX + Rr + 1, CY + Rr + 1));
    // kruis: het schemasymbool van een lamp
    TLijn(CX - 8, CY - 8, CX + 9, CY + 9);
    TLijn(CX + 8, CY - 8, CX - 9, CY + 9);
    Pen.Width := 1;
    PaintPin(PinPos(0).X, PinPos(0).Y, FPinV[0] >= RailMinVolt);
    PaintPin(PinPos(1).X, PinPos(1).Y, FPinV[1] >= RailMinVolt);
    Brush.Style := bsClear;
    Font.Name := 'Arial'; Font.Size := 7; Font.Style := []; Font.Color := clNavy;
    S := OhmText(Ohm);
    if Is5V then S := '5 V ' + S;
    TW := TextWidth(S);
    if FGedraaid then
      TextOut(CY + Rr + 6, CX - 6, S)          // rechts naast de lamp
    else
      TextOut(CX - TW div 2, CY + Rr + 4, S);
  end;
  PaintSelection;
end;

procedure TjanLamp2.UpdateHintText;
var
  I: Double;
begin
  I := Abs(FAmp);
  Hint := Format(Tr(FTaal, 'Lamp voor %s V (%s)', 'Lamp for %s V (%s)', 'Lampe pour %s V (%s)', 'Lampe für %s V (%s)'),
    [FormatFloat('0', Volt), OhmText(Ohm)]) + #13#10;
  if I > 0.00005 then
    Hint := Hint +
      'U = I × R = ' + AmpText(I) + ' × ' + OhmText(Ohm) + ' = ' + VoltText(Spanning) + #13#10 +
      'I = U / R = ' + VoltText(Spanning) + ' / ' + OhmText(Ohm) + ' = ' + AmpText(I) +
        ' = ' + MilliAmpText(I) + #13#10 +
      VermogenRegel(Spanning, I) + #13#10;
  Hint := Hint + Tr(FTaal,
      'Lamp met twee klemmen: zet ze in serie of parallel in de kring.',
      'Lamp with two terminals: put it in series or in parallel in the circuit.',
      'Lampe à deux bornes : placez-la en série ou en parallèle dans le circuit.',
      'Lampe mit zwei Klemmen: in Reihe oder parallel in den Stromkreis setzen.') + #13#10 +
    Format(Tr(FTaal,
      'Bij %s V: %s en %s. Hoe meer vermogen, hoe feller ze brandt.',
      'At %s V: %s and %s. The more power, the brighter it shines.',
      'À %s V : %s et %s. Plus la puissance est grande, plus elle brille.',
      'Bei %s V: %s und %s. Je mehr Leistung, desto heller leuchtet sie.'),
      [FormatFloat('0', Volt), MilliAmpText(Volt / Ohm), WattText(Volt * Volt / Ohm)]) + #13#10;
  if Is5V then
    Hint := Hint + Tr(FTaal,
      'Een lamp voor 5 V brandt ook aan de uitgang van een poort en telt mee in de waarheidstabel.',
      'A 5 V lamp also lights on the output of a gate and counts in the truth table.',
      'Une lampe de 5 V brille aussi à la sortie d''une porte et compte dans la table de vérité.',
      'Eine 5-V-Lampe leuchtet auch am Ausgang eines Gatters und zählt in der Wahrheitstabelle.') + #13#10;
  Hint := Hint + Tr(FTaal, 'Rechtsklik: spanning en weerstand kiezen.', 'Right-click: choose the voltage and the resistance.',
    'Clic droit : choisir la tension et la résistance.', 'Rechtsklick: Spannung und Widerstand wählen.');
end;

procedure TjanLamp2.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Tr(FTaal, 'Lamp', 'Lamp', 'Lampe', 'Lampe') + ' > ', 0);
  FOnStatus(Self, 'U = ' + VoltText(Spanning) + '   I = ' + MilliAmpText(Abs(FAmp)), 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

{ TjanLed2 }

constructor TjanLed2.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := Led2W;
  Height := Led2H;
  FKleur := 0;
  HelpKeyword := 'led2';
end;

function TjanLed2.PinCount: Integer;
begin
  Result := 2;
end;

function TjanLed2.PinPos(I: Integer): TPoint;
begin
  if I = 0 then Result := TP(1, 17) else Result := TP(Led2W - 8, 17);
end;

function TjanLed2.KanDraaien: Boolean;
begin
  Result := True;
end;

function TjanLed2.StdMaat: TPoint;
begin
  Result := Point(Led2W, Led2H);
end;

function TjanLed2.ExtraBreedte: Integer;
begin
  Result := 26;   // kleur en spanning rechts naast het symbool, op twee regels
end;

function TjanLed2.Drempel: Double;
begin
  Result := LedVolt[FKleur];
end;

function TjanLed2.Rd: Double;
begin
  Result := LedRd;
end;

function TjanLed2.MaxA: Double;
begin
  Result := LedMaxA;
end;

function TjanLed2.Spanning: Double;
begin
  Result := FPinV[0] - FPinV[1];
end;

procedure TjanLed2.SetKleur(const Value: Integer);
begin
  if (Value < Low(LedVolt)) or (Value > High(LedVolt)) or (Value = FKleur) then Exit;
  FKleur := Value;
  UpdateHintText;
  Invalidate;
  if Parent <> nil then
    UpdateSupply(Parent, True);
end;

procedure TjanLed2.SetDoorgebrand(const Value: Boolean);
begin
  if Value = FDoorgebrand then Exit;
  FDoorgebrand := Value;
  if Value then FGeleidt := False;
  Invalidate;
  SendStatusToBar;
end;

procedure TjanLed2.KleurClick(Sender: TObject);
begin
  Kleur := TMenuItem(Sender).Tag;
end;

procedure TjanLed2.VervangClick(Sender: TObject);
begin
  Doorgebrand := False;
  if Parent <> nil then
    UpdateSupply(Parent, True);
end;

procedure TjanLed2.AddMenuItems(APop: TPopupMenu);
var
  Mi, Sub: TMenuItem;
  i: Integer;
begin
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Led vervangen', 'Replace LED', 'Remplacer la LED', 'LED ersetzen');
  Mi.Enabled := FDoorgebrand;
  Mi.OnClick := VervangClick;
  APop.Items.Add(Mi);
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Kleur', 'Colour', 'Couleur', 'Farbe');
  APop.Items.Add(Mi);
  for i := Low(LedVolt) to High(LedVolt) do
  begin
    Sub := TMenuItem.Create(APop);
    Sub.Caption := LedKleurNaam(FTaal, i) + ' (' + VoltText(LedVolt[i]) + ')';
    Sub.Tag := i;
    Sub.RadioItem := True;
    Sub.Checked := i = FKleur;
    Sub.OnClick := KleurClick;
    Mi.Add(Sub);
  end;
end;

procedure TjanLed2.Paint;
var
  CX, CY, TW: Integer;
  K: Double;
  Col: TColor;
  S: string;

  function Meng(C: TColor; F: Double): TColor;
  begin
    // van wit (F = 0) naar kleur C (F = 1)
    Result := RGBToColor(255 - Round((255 - Red(C)) * F), 255 - Round((255 - Green(C)) * F),
      255 - Round((255 - Blue(C)) * F));
  end;

begin
  // tekening in de gewone stand; TP/TRc spiegelen ze als de led gedraaid is
  CX := Led2W div 2;
  CY := 17 + 3;
  K := Abs(FAmp) / LedVolA;
  if K > 1 then K := 1;
  if FDoorgebrand then K := 0;
  Col := LedRGB(FKleur);
  with Canvas do
  begin
    // gloed
    if K > 0.03 then
    begin
      Pen.Style := psClear;
      Brush.Style := bsSolid;
      Brush.Color := Meng(Col, 0.35 * K);
      Ellipse(TRc(CX - 15, CY - 15, CX + 14, CY + 14));
      Pen.Style := psSolid;
    end;
    Pen.Color := clBlack; Pen.Width := 2;
    TLijn(8, CY, CX - 8, CY);
    TLijn(CX + 7, CY, Led2W - 8, CY);
    // schemasymbool: driehoek (van + naar -) met een streep
    Pen.Width := 1;
    Brush.Style := bsSolid;
    if FDoorgebrand then Brush.Color := RGBToColor(90, 80, 70)
    else if K > 0.03 then Brush.Color := Meng(Col, 0.4 + 0.6 * K)
    else Brush.Color := Meng(Col, 0.25);
    Polygon([TP(CX - 8, CY - 8), TP(CX + 6, CY), TP(CX - 8, CY + 8)]);
    Pen.Width := 2;
    TLijn(CX + 6, CY - 8, CX + 6, CY + 9);
    // pijltjes: licht
    Pen.Width := 1;
    if K > 0.03 then Pen.Color := Col else Pen.Color := clGray;
    TLijn(CX, CY - 10, CX + 5, CY - 15); TLijn(CX + 5, CY - 15, CX + 2, CY - 15);
    TLijn(CX + 5, CY - 15, CX + 5, CY - 12);
    TLijn(CX + 5, CY - 9, CX + 10, CY - 14); TLijn(CX + 10, CY - 14, CX + 7, CY - 14);
    TLijn(CX + 10, CY - 14, CX + 10, CY - 11);
    Pen.Color := clBlack;
    if FDoorgebrand then
    begin
      Pen.Width := 2; Pen.Color := clRed;
      TLijn(CX - 10, CY - 10, CX + 10, CY + 10);
      TLijn(CX + 10, CY - 10, CX - 10, CY + 10);
      Pen.Width := 1; Pen.Color := clBlack;
    end;
    PaintPin(PinPos(0).X, PinPos(0).Y, FPinV[0] >= RailMinVolt);
    PaintPin(PinPos(1).X, PinPos(1).Y, FPinV[1] >= RailMinVolt);
    Brush.Style := bsClear;
    Font.Name := 'Arial'; Font.Size := 7; Font.Style := [fsBold]; Font.Color := clNavy;
    with TP(9, CY - 15) do TextOut(X, Y, '+');
    Font.Style := [];
    Font.Size := 6;
    if FGedraaid then
    begin
      // rechts naast het symbool: kleur en spanning op twee regels
      if FDoorgebrand then
        TextOut(CY + 17, CX - 5, Tr(FTaal, 'kapot', 'broken', 'grillée', 'kaputt'))
      else
      begin
        TextOut(CY + 17, CX - 10, LedKleurNaam(FTaal, FKleur));
        TextOut(CY + 17, CX, FormatFloat('0.0', Drempel) + ' V');
      end;
    end
    else
    begin
      if FDoorgebrand then
        S := Tr(FTaal, 'kapot', 'broken', 'grillée', 'kaputt')
      else
        S := LedKleurNaam(FTaal, FKleur) + ' ' + FormatFloat('0.0', Drempel) + ' V';
      TW := TextWidth(S);
      TextOut(CX - TW div 2, CY + 11, S);
    end;
  end;
  PaintSelection;
end;

procedure TjanLed2.UpdateHintText;
var
  I, Rv: Double;
begin
  I := Abs(FAmp);
  Hint := Tr(FTaal, 'Led', 'LED', 'LED', 'LED') + ' (' + LedKleurNaam(FTaal, FKleur) + ', ' +
    VoltText(Drempel) + ')' + #13#10;
  if FDoorgebrand then
    Hint := Hint + Tr(FTaal, 'Kapot: er ging meer dan 30 mA door. Rechtsklik: led vervangen.',
      'Broken: more than 30 mA went through it. Right-click: replace LED.',
      'Grillée : plus de 30 mA l''ont traversée. Clic droit : remplacer la LED.',
      'Kaputt: Es floss mehr als 30 mA. Rechtsklick: LED ersetzen.') + #13#10
  else if I > 0.00005 then
    Hint := Hint + 'U = ' + VoltText(Spanning) + '   ' + StroomRegel(I) + #13#10;
  // voorschakelweerstand voor 20 mA bij 12 V
  Rv := (BronMaxVolt - Drempel) / LedVolA;
  Hint := Hint + Format(Tr(FTaal,
      'Led met twee klemmen: + (anode) links, - (kathode) rechts. Ze geleidt maar in één richting,' + #13#10 +
        'en pas boven %s. Vol licht bij 20 mA, kapot boven 30 mA.' + #13#10 +
        'Zet er een voorschakelweerstand in serie mee: R = (U - Ud) / I = (12 V - %s) / 0,02 A = %s. Rechtsklik: kleur kiezen.',
      'LED with two terminals: + (anode) on the left, - (cathode) on the right. It conducts in one direction only,' + #13#10 +
        'and only above %s. Full light at 20 mA, broken above 30 mA.' + #13#10 +
        'Put a series resistor with it: R = (U - Ud) / I = (12 V - %s) / 0.02 A = %s. Right-click: choose the colour.',
      'LED à deux bornes : + (anode) à gauche, - (cathode) à droite. Elle ne conduit que dans un sens,' + #13#10 +
        'et seulement au-dessus de %s. Pleine lumière à 20 mA, grillée au-dessus de 30 mA.' + #13#10 +
        'Mettez une résistance série avec elle : R = (U - Ud) / I = (12 V - %s) / 0,02 A = %s. Clic droit : choisir la couleur.',
      'LED mit zwei Klemmen: + (Anode) links, - (Kathode) rechts. Sie leitet nur in eine Richtung,' + #13#10 +
        'und erst über %s. Volles Licht bei 20 mA, kaputt über 30 mA.' + #13#10 +
        'Setzen Sie einen Vorwiderstand in Reihe: R = (U - Ud) / I = (12 V - %s) / 0,02 A = %s. Rechtsklick: Farbe wählen.'),
      [VoltText(Drempel), VoltText(Drempel), OhmText(Rv)]);
end;

procedure TjanLed2.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Tr(FTaal, 'Led', 'LED', 'LED', 'LED') + ' > ', 0);
  if FDoorgebrand then
    FOnStatus(Self, Tr(FTaal, 'kapot', 'broken', 'grillée', 'kaputt'), 1)
  else
    FOnStatus(Self, 'U = ' + VoltText(Spanning) + '   I = ' + MilliAmpText(Abs(FAmp)), 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

{ TjanDiode }

constructor TjanDiode.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  HelpKeyword := 'diode';
end;

function TjanDiode.Drempel: Double;
begin
  Result := DiodeVolt;
end;

function TjanDiode.Rd: Double;
begin
  Result := DiodeRd;
end;

function TjanDiode.MaxA: Double;
begin
  Result := DiodeMaxA;
end;

procedure TjanDiode.VervangDiodeClick(Sender: TObject);
begin
  Doorgebrand := False;
  if Parent <> nil then
    UpdateSupply(Parent, True);
end;

// omgedraaid: de anode (pin 0) rechts en de kathode (pin 1) links. De draden
// blijven liggen, dus ze zitten nu aan de andere klem.
function TjanDiode.PinPos(I: Integer): TPoint;
begin
  if (I = 0) <> FOmgekeerd then Result := TP(1, 17) else Result := TP(Led2W - 8, 17);
end;

procedure TjanDiode.SetOmgekeerd(const Value: Boolean);
begin
  if Value = FOmgekeerd then Exit;
  FOmgekeerd := Value;
  UpdateHintText;
  Invalidate;
  if Parent <> nil then
    UpdateSupply(Parent, True);
end;

procedure TjanDiode.OmdraaiClick(Sender: TObject);
begin
  Omgekeerd := not Omgekeerd;
end;

procedure TjanDiode.AddMenuItems(APop: TPopupMenu);
var
  Mi: TMenuItem;
begin
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Omdraaien', 'Turn round', 'Retourner', 'Umdrehen');
  Mi.OnClick := OmdraaiClick;
  APop.Items.Add(Mi);
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Diode vervangen', 'Replace diode', 'Remplacer la diode', 'Diode ersetzen');
  Mi.Enabled := FDoorgebrand;
  Mi.OnClick := VervangDiodeClick;
  APop.Items.Add(Mi);
end;

procedure TjanDiode.Paint;
var
  CX, CY, TW, R: Integer;
  S: string;
  Aan: Boolean;
begin
  // tekening in de gewone stand; TP/TRc spiegelen ze als de diode gedraaid is
  CX := Led2W div 2;
  CY := 17 + 3;
  // R = 1: de driehoek wijst naar rechts (anode links); -1: omgedraaid
  if FOmgekeerd then R := -1 else R := 1;
  Aan := (Abs(FAmp) > 0.0005) and not FDoorgebrand;
  with Canvas do
  begin
    Pen.Color := clBlack; Pen.Width := 2;
    TLijn(8, CY, CX - 8, CY);
    TLijn(CX + 7, CY, Led2W - 8, CY);
    // schemasymbool: driehoek in de doorlaatrichting met een streep (kathode)
    Pen.Width := 1;
    Brush.Style := bsSolid;
    if FDoorgebrand then Brush.Color := RGBToColor(90, 80, 70)
    else if Aan then Brush.Color := RGBToColor(255, 150, 120)   // geleidt
    else Brush.Color := RGBToColor(200, 200, 200);              // spert
    Polygon([TP(CX - 8 * R, CY - 8), TP(CX + 6 * R, CY), TP(CX - 8 * R, CY + 8)]);
    Pen.Width := 2;
    TLijn(CX + 6 * R, CY - 8, CX + 6 * R, CY + 9);
    Pen.Width := 1;
    if FDoorgebrand then
    begin
      Pen.Width := 2; Pen.Color := clRed;
      TLijn(CX - 10, CY - 10, CX + 10, CY + 10);
      TLijn(CX + 10, CY - 10, CX - 10, CY + 10);
      Pen.Width := 1; Pen.Color := clBlack;
    end;
    PaintPin(PinPos(0).X, PinPos(0).Y, FPinV[0] >= RailMinVolt);
    PaintPin(PinPos(1).X, PinPos(1).Y, FPinV[1] >= RailMinVolt);
    Brush.Style := bsClear;
    Font.Name := 'Arial'; Font.Size := 6; Font.Style := [fsBold]; Font.Color := clNavy;
    if FOmgekeerd then S := 'K' else S := 'A';
    with TP(9, CY - 15) do TextOut(X, Y, S);
    if FOmgekeerd then S := 'A' else S := 'K';
    with TP(Led2W - 14, CY - 15) do TextOut(X, Y, S);
    Font.Style := [];
    if FGedraaid then
    begin
      // rechts naast het symbool, op twee regels
      if FDoorgebrand then
        TextOut(CY + 17, CX - 5, Tr(FTaal, 'kapot', 'broken', 'grillée', 'kaputt'))
      else
      begin
        TextOut(CY + 17, CX - 10, Tr(FTaal, 'diode', 'diode', 'diode', 'Diode'));
        TextOut(CY + 17, CX, FormatFloat('0.0', Drempel) + ' V');
      end;
    end
    else
    begin
      if FDoorgebrand then
        S := Tr(FTaal, 'kapot', 'broken', 'grillée', 'kaputt')
      else
        S := Tr(FTaal, 'diode', 'diode', 'diode', 'Diode') + ' ' + FormatFloat('0.0', Drempel) + ' V';
      TW := TextWidth(S);
      TextOut(CX - TW div 2, CY + 11, S);
    end;
  end;
  PaintSelection;
end;

procedure TjanDiode.UpdateHintText;
var
  I: Double;
begin
  I := Abs(FAmp);
  Hint := Tr(FTaal, 'Diode', 'Diode', 'Diode', 'Diode') + ' (' + VoltText(Drempel) + ')' + #13#10;
  if FDoorgebrand then
    Hint := Hint + Tr(FTaal, 'Kapot: er ging meer dan 1 A door. Rechtsklik: diode vervangen.',
      'Broken: more than 1 A went through it. Right-click: replace diode.',
      'Grillée : plus de 1 A l''a traversée. Clic droit : remplacer la diode.',
      'Kaputt: Es floss mehr als 1 A. Rechtsklick: Diode ersetzen.') + #13#10
  else if I > 0.00005 then
    Hint := Hint + 'U = ' + VoltText(Spanning) + '   ' + StroomRegel(I) + #13#10
  else
    Hint := Hint + 'U = ' + VoltText(Spanning) + '   ' +
      Tr(FTaal, 'spert: geen stroom', 'blocking: no current', 'bloque : pas de courant', 'sperrt: kein Strom') + #13#10;
  Hint := Hint + Tr(FTaal,
      'Diode: A (anode) links, K (kathode) rechts, bij de streep. Ze laat stroom alleen door' + #13#10 +
        'van A naar K, en pas boven 0,7 V. Kapot boven 1 A.',
      'Diode: A (anode) on the left, K (cathode) on the right, at the bar. It only lets current through' + #13#10 +
        'from A to K, and only above 0.7 V. Broken above 1 A.',
      'Diode : A (anode) à gauche, K (cathode) à droite, côté barre. Elle ne laisse passer le courant' + #13#10 +
        'que de A vers K, et seulement au-dessus de 0,7 V. Grillée au-dessus de 1 A.',
      'Diode: A (Anode) links, K (Kathode) rechts, beim Strich. Sie lässt Strom nur' + #13#10 +
        'von A nach K durch, und erst über 0,7 V. Kaputt über 1 A.') + #13#10 +
    Tr(FTaal, 'Rechtsklik: omdraaien.', 'Right-click: turn round.', 'Clic droit : retourner.',
      'Rechtsklick: umdrehen.');
end;

procedure TjanDiode.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Tr(FTaal, 'Diode', 'Diode', 'Diode', 'Diode') + ' > ', 0);
  if FDoorgebrand then
    FOnStatus(Self, Tr(FTaal, 'kapot', 'broken', 'grillée', 'kaputt'), 1)
  else
    FOnStatus(Self, 'U = ' + VoltText(Spanning) + '   I = ' + MilliAmpText(Abs(FAmp)), 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

// stroom in mA: twee decimalen onder 1 mA, een onder 10 mA (basisstroom van een transistor)
function MaKort(I: Double): string;
begin
  if Abs(I) < 0.001 then Result := FormatFloat('0.00', I * 1000) + ' mA'
  else if Abs(I) < 0.01 then Result := FormatFloat('0.0', I * 1000) + ' mA'
  else Result := FormatFloat('0', I * 1000) + ' mA';
end;

{ TjanTransistor }

constructor TjanTransistor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := TrW;
  Height := TrH;
  FBetaIdx := TrBetaStd;
  HelpKeyword := 'transistor';
end;

function TjanTransistor.PinCount: Integer;
begin
  Result := 3;
end;

function TjanTransistor.PinPos(I: Integer): TPoint;
begin
  case I of
    0: Result := Point(45, 1);          // collector, boven
    1: Result := Point(1, 45);          // basis, links
  else
    Result := Point(45, TrH - 8);       // emitter, onder
  end;
end;

function TjanTransistor.Beta: Double;
begin
  Result := TrBeta[FBetaIdx];
end;

procedure TjanTransistor.SetPNP(const Value: Boolean);
begin
  if Value = FPNP then Exit;
  FPNP := Value;
  FBeAan := False;
  FVerzadigd := False;
  UpdateHintText;
  Invalidate;
  if Parent <> nil then
    UpdateSupply(Parent, True);
end;

procedure TjanTransistor.SetBetaIdx(const Value: Integer);
begin
  if (Value < Low(TrBeta)) or (Value > High(TrBeta)) or (Value = FBetaIdx) then Exit;
  FBetaIdx := Value;
  UpdateHintText;
  Invalidate;
  if Parent <> nil then
    UpdateSupply(Parent, True);
end;

procedure TjanTransistor.SetDoorgebrand(const Value: Boolean);
begin
  if Value = FDoorgebrand then Exit;
  FDoorgebrand := Value;
  FBeAan := False;
  FVerzadigd := False;
  Invalidate;
  SendStatusToBar;
end;

procedure TjanTransistor.SoortClick(Sender: TObject);
begin
  PNP := TMenuItem(Sender).Tag = 1;
end;

procedure TjanTransistor.BetaClick(Sender: TObject);
begin
  BetaIdx := TMenuItem(Sender).Tag;
end;

procedure TjanTransistor.VervangClick(Sender: TObject);
begin
  Doorgebrand := False;
  if Parent <> nil then
    UpdateSupply(Parent, True);
end;

procedure TjanTransistor.AddMenuItems(APop: TPopupMenu);
var
  Mi, Sub: TMenuItem;
  i: Integer;
begin
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Soort', 'Kind', 'Type', 'Art');
  APop.Items.Add(Mi);
  for i := 0 to 1 do
  begin
    Sub := TMenuItem.Create(APop);
    if i = 0 then Sub.Caption := 'NPN' else Sub.Caption := 'PNP';
    Sub.Tag := i;
    Sub.RadioItem := True;
    Sub.Checked := (i = 1) = FPNP;
    Sub.OnClick := SoortClick;
    Mi.Add(Sub);
  end;
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Versterking', 'Gain', 'Gain', 'Verstärkung');
  APop.Items.Add(Mi);
  for i := Low(TrBeta) to High(TrBeta) do
  begin
    Sub := TMenuItem.Create(APop);
    Sub.Caption := 'β = ' + IntToStr(TrBeta[i]);
    Sub.Tag := i;
    Sub.RadioItem := True;
    Sub.Checked := i = FBetaIdx;
    Sub.OnClick := BetaClick;
    Mi.Add(Sub);
  end;
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Transistor vervangen', 'Replace transistor', 'Remplacer le transistor', 'Transistor ersetzen');
  Mi.Enabled := FDoorgebrand;
  Mi.OnClick := VervangClick;
  APop.Items.Add(Mi);
end;

function TjanTransistor.ToestandTekst: string;
begin
  if FDoorgebrand then Result := Tr(FTaal, 'kapot', 'broken', 'grillé', 'kaputt')
  else if not FBeAan then Result := Tr(FTaal, 'spert', 'off', 'bloqué', 'sperrt')
  else if FVerzadigd then Result := Tr(FTaal, 'verzadigd', 'saturated', 'saturé', 'gesättigt')
  else Result := Tr(FTaal, 'versterkt', 'amplifying', 'amplifie', 'verstärkt');
end;

procedure TjanTransistor.Paint;
const
  CX = 40; CY = 48; Rr = 22;   // de cirkel
  XB = 32;                     // de basisbalk
  XL = 48;                     // de lijn van C en E
var
  Tip, Rug: TPoint;
  Dx, Dy: Double;
  S: string;
  Y: Integer;
begin
  with Canvas do
  begin
    // cirkel: lichtblauw als er collectorstroom loopt
    Pen.Color := clBlack; Pen.Width := 1;
    Brush.Style := bsSolid;
    if FDoorgebrand then Brush.Color := RGBToColor(90, 80, 70)
    else if FIc > 0.0005 then Brush.Color := RGBToColor(200, 225, 255)
    else Brush.Color := clWhite;
    Ellipse(Rect(CX - Rr, CY - Rr, CX + Rr + 1, CY + Rr + 1));
    // basis: draad en balk
    Pen.Width := 2;
    MoveTo(8, CY); LineTo(XB, CY);
    Pen.Width := 3;
    MoveTo(XB, CY - 12); LineTo(XB, CY + 13);
    // collector en emitter: schuin van de balk, dan recht naar de klem
    Pen.Width := 2;
    MoveTo(XB, CY - 6); LineTo(XL, CY - 18); LineTo(XL, 8);
    MoveTo(XB, CY + 6); LineTo(XL, CY + 18); LineTo(XL, TrH - 8);
    // pijl in de emitter: NPN naar buiten, PNP naar de balk
    Pen.Width := 1;
    Dx := 0.8; Dy := 0.6;
    if FPNP then
    begin
      Tip := Point(XB + 4, CY + 9);
      Dx := -Dx; Dy := -Dy;
    end
    else
      Tip := Point(XL - 2, CY + 16);
    Rug := Point(Round(Tip.X - 8 * Dx), Round(Tip.Y - 8 * Dy));
    Brush.Style := bsSolid; Brush.Color := clBlack;
    Polygon([Tip, Point(Round(Rug.X - 4 * Dy), Round(Rug.Y + 4 * Dx)),
      Point(Round(Rug.X + 4 * Dy), Round(Rug.Y - 4 * Dx))]);
    if FDoorgebrand then
    begin
      Pen.Width := 2; Pen.Color := clRed;
      MoveTo(CX - 12, CY - 12); LineTo(CX + 12, CY + 12);
      MoveTo(CX + 12, CY - 12); LineTo(CX - 12, CY + 12);
      Pen.Width := 1; Pen.Color := clBlack;
    end;
    PaintPin(PinPos(0).X, PinPos(0).Y, FPinV[0] >= RailMinVolt);
    PaintPin(PinPos(1).X, PinPos(1).Y, FPinV[1] >= RailMinVolt);
    PaintPin(PinPos(2).X, PinPos(2).Y, FPinV[2] >= RailMinVolt);
    // namen van de klemmen
    Brush.Style := bsClear;
    Font.Name := 'Arial'; Font.Size := 6; Font.Style := [fsBold]; Font.Color := clNavy;
    TextOut(XL + 5, 4, 'C');
    TextOut(10, CY - 14, 'B');
    TextOut(XL + 5, TrH - 18, 'E');
    // soort, versterking, toestand en stromen rechts
    Y := 22;
    Font.Size := 7;
    if FPNP then S := 'PNP' else S := 'NPN';
    TextOut(70, Y, S);
    Font.Style := [];
    TextOut(70, Y + 11, 'β = ' + IntToStr(TrBeta[FBetaIdx]));
    Font.Style := [fsBold];
    if FDoorgebrand then Font.Color := clRed
    else if not FBeAan then Font.Color := clGray
    else if FVerzadigd then Font.Color := RGBToColor(0, 130, 0)
    else Font.Color := RGBToColor(210, 110, 0);
    TextOut(70, Y + 24, ToestandTekst);
    Font.Style := []; Font.Size := 6; Font.Color := clBlack;
    TextOut(70, Y + 37, 'Ib ' + MaKort(FIb));
    TextOut(70, Y + 47, 'Ic ' + MaKort(FIc));
  end;
  PaintSelection;
end;

procedure TjanTransistor.UpdateHintText;
var
  S: string;
begin
  if FPNP then S := 'PNP' else S := 'NPN';
  Hint := Tr(FTaal, 'Transistor', 'Transistor', 'Transistor', 'Transistor') + ' ' + S +
    ' (β = ' + IntToStr(TrBeta[FBetaIdx]) + '): ' + ToestandTekst + #13#10;
  if FDoorgebrand then
    Hint := Hint + Tr(FTaal,
      'Kapot: er ging te veel stroom door de basis of de collector. Rechtsklik: transistor vervangen.',
      'Broken: too much current went through the base or the collector. Right-click: replace transistor.',
      'Grillé : trop de courant a traversé la base ou le collecteur. Clic droit : remplacer le transistor.',
      'Kaputt: Durch die Basis oder den Kollektor floss zu viel Strom. Rechtsklick: Transistor ersetzen.') + #13#10
  else
  begin
    Hint := Hint + 'Ib = ' + MaKort(FIb) + '   Ic = ' + MaKort(FIc) + #13#10;
    if FBeAan and not FVerzadigd then
      Hint := Hint + 'Ic = β × Ib = ' + IntToStr(TrBeta[FBetaIdx]) + ' × ' + MaKort(FIb) + ' = ' +
        MaKort(FIc) + #13#10
    else if FVerzadigd then
      Hint := Hint + Tr(FTaal,
        'Verzadigd: de rest van de kring laat minder door dan β × Ib; tussen C en E staat maar 0,2 V.',
        'Saturated: the rest of the circuit lets less through than β × Ib; only 0.2 V across C and E.',
        'Saturé : le reste du circuit laisse passer moins que β × Ib ; seulement 0,2 V entre C et E.',
        'Gesättigt: Der Rest des Stromkreises lässt weniger als β × Ib durch; zwischen C und E nur 0,2 V.') + #13#10;
  end;
  if FPNP then
    Hint := Hint + Tr(FTaal,
      'Een kleine stroom uit de basis (B) stuurt een grote stroom van de emitter (E) naar de collector (C).',
      'A small current out of the base (B) controls a large current from the emitter (E) to the collector (C).',
      'Un petit courant sortant de la base (B) commande un grand courant de l''émetteur (E) vers le collecteur (C).',
      'Ein kleiner Strom aus der Basis (B) steuert einen großen Strom vom Emitter (E) zum Kollektor (C).')
  else
    Hint := Hint + Tr(FTaal,
      'Een kleine stroom in de basis (B) stuurt een grote stroom van de collector (C) naar de emitter (E).',
      'A small current into the base (B) controls a large current from the collector (C) to the emitter (E).',
      'Un petit courant entrant dans la base (B) commande un grand courant du collecteur (C) vers l''émetteur (E).',
      'Ein kleiner Strom in die Basis (B) steuert einen großen Strom vom Kollektor (C) zum Emitter (E).');
  Hint := Hint + #13#10 + Tr(FTaal,
    'Zet altijd een weerstand voor de basis. Rechtsklik: soort en versterking kiezen.',
    'Always put a resistor before the base. Right-click: choose the kind and the gain.',
    'Mettez toujours une résistance avant la base. Clic droit : choisir le type et le gain.',
    'Setzen Sie immer einen Widerstand vor die Basis. Rechtsklick: Art und Verstärkung wählen.');
end;

procedure TjanTransistor.SendStatusToBar;
var
  S: string;
begin
  if not Assigned(FOnStatus) then Exit;
  if FPNP then S := 'PNP' else S := 'NPN';
  FOnStatus(Self, Tr(FTaal, 'Transistor', 'Transistor', 'Transistor', 'Transistor') + ' ' + S + ' > ', 0);
  FOnStatus(Self, ToestandTekst + '   Ib = ' + MaKort(FIb) + '   Ic = ' + MaKort(FIc), 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

{ TjanCondensator }

constructor TjanCondensator.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := CondW;
  Height := CondH;
  FSoort := CondStandaard;
  HelpKeyword := 'condensator';
end;

function TjanCondensator.PinCount: Integer;
begin
  Result := 2;
end;

function TjanCondensator.PinPos(I: Integer): TPoint;
begin
  if I = 0 then Result := TP(1, 17) else Result := TP(CondW - 8, 17);
end;

function TjanCondensator.KanDraaien: Boolean;
begin
  Result := True;
end;

function TjanCondensator.StdMaat: TPoint;
begin
  Result := Point(CondW, CondH);
end;

function TjanCondensator.ExtraBreedte: Integer;
begin
  Result := 14;   // capaciteit en spanning rechts naast het symbool
end;

function TjanCondensator.Farad: Double;
begin
  Result := CondUF[FSoort] / 1000000;
end;

procedure TjanCondensator.SetSoort(const Value: Integer);
begin
  if (Value < Low(CondUF)) or (Value > High(CondUF)) or (Value = FSoort) then Exit;
  FSoort := Value;
  UpdateHintText;
  Invalidate;
  if Parent <> nil then
    UpdateSupply(Parent, True);
end;

procedure TjanCondensator.SoortClick(Sender: TObject);
begin
  Soort := TMenuItem(Sender).Tag;
end;

procedure TjanCondensator.OntlaadClick(Sender: TObject);
begin
  FU := 0;
  Invalidate;
  if Parent <> nil then
    UpdateSupply(Parent, True);
end;

procedure TjanCondensator.AddMenuItems(APop: TPopupMenu);
var
  Mi, Sub: TMenuItem;
  i: Integer;
begin
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Ontladen', 'Discharge', 'Décharger', 'Entladen');
  Mi.OnClick := OntlaadClick;
  APop.Items.Add(Mi);
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Capaciteit', 'Capacitance', 'Capacité', 'Kapazität');
  APop.Items.Add(Mi);
  for i := Low(CondUF) to High(CondUF) do
  begin
    Sub := TMenuItem.Create(APop);
    Sub.Caption := UFText(CondUF[i]);
    Sub.Tag := i;
    Sub.RadioItem := True;
    Sub.Checked := i = FSoort;
    Sub.OnClick := SoortClick;
    Mi.Add(Sub);
  end;
end;

procedure TjanCondensator.Paint;
var
  CX, CY, TW, Hh: Integer;
  K: Double;
  S: string;
begin
  // tekening in de gewone stand; TP/TRc spiegelen ze als hij gedraaid is
  CX := CondW div 2;
  CY := 17 + 3;
  // lading: hoe vol (tot 12 V)
  K := Abs(FU) / BronMaxVolt;
  if K > 1 then K := 1;
  with Canvas do
  begin
    Pen.Color := clBlack; Pen.Width := 2;
    TLijn(8, CY, CX - 4, CY);
    TLijn(CX + 4, CY, CondW - 8, CY);
    // de lading tussen de platen (blauw, hoe hoger hoe voller); gedraaid
    // vult ze van links naar rechts
    Hh := Round(24 * K);
    if Hh > 0 then
    begin
      Brush.Style := bsSolid;
      Brush.Color := RGBToColor(120, 170, 255);
      if FGedraaid then
        FillRect(Rect(CY - 12, CX - 3, CY - 12 + Hh, CX + 4))
      else
        FillRect(Rect(CX - 3, CY + 12 - Hh, CX + 4, CY + 12));
    end;
    // schemasymbool: twee platen, de - plaat dik (elco)
    Pen.Width := 2;
    TLijn(CX - 4, CY - 12, CX - 4, CY + 13);
    Brush.Style := bsSolid; Brush.Color := clBlack;
    FillRect(TRc(CX + 3, CY - 12, CX + 7, CY + 13));
    Pen.Width := 1;
    PaintPin(PinPos(0).X, PinPos(0).Y, FPinV[0] >= RailMinVolt);
    PaintPin(PinPos(1).X, PinPos(1).Y, FPinV[1] >= RailMinVolt);
    Brush.Style := bsClear;
    Font.Name := 'Arial'; Font.Size := 7; Font.Style := [fsBold]; Font.Color := clNavy;
    with TP(CX - 12, CY - 15) do TextOut(X, Y, '+');
    Font.Style := [];
    // capaciteit en spanning op twee regels (anders te breed)
    Font.Size := 6;
    if FGedraaid then
    begin
      TextOut(CY + 16, CX - 10, UFText(CondUF[FSoort]));
      TextOut(CY + 16, CX, FormatFloat('0.0', FU) + ' V');
    end
    else
    begin
      S := UFText(CondUF[FSoort]);
      TW := TextWidth(S);
      TextOut(CX - TW div 2, CY + 14, S);
      S := FormatFloat('0.0', FU) + ' V';
      TW := TextWidth(S);
      TextOut(CX - TW div 2, CY + 24, S);
    end;
  end;
  PaintSelection;
end;

procedure TjanCondensator.UpdateHintText;
var
  Q: Double;
begin
  Q := Farad * Abs(FU);
  Hint := Tr(FTaal, 'Condensator', 'Capacitor', 'Condensateur', 'Kondensator') + ' (' +
    UFText(CondUF[FSoort]) + ')' + #13#10 +
    'U = ' + VoltText(FU) + '   I = ' + MilliAmpText(Abs(FAmp)) + #13#10 +
    'Q = C × U = ' + FormatFloat('0.####', Farad) + ' F × ' + VoltText(Abs(FU)) + ' = ' +
      FormatFloat('0.####', Q) + ' C' + #13#10 +
    Tr(FTaal,
      'Condensator met twee klemmen: + links. Hij laadt op als er spanning op staat en geeft' + #13#10 +
        'die lading weer af. Hoe lang dat duurt: tijdconstante tau = R × C (bv. 1000 ohm × 1000 µF = 1 s).' + #13#10 +
        'Rechtsklik: capaciteit kiezen of ontladen.',
      'Capacitor with two terminals: + on the left. It charges when there is a voltage on it and gives' + #13#10 +
        'that charge back. How long that takes: time constant tau = R × C (e.g. 1000 ohm × 1000 µF = 1 s).' + #13#10 +
        'Right-click: choose the capacitance or discharge.',
      'Condensateur à deux bornes : + à gauche. Il se charge quand il est sous tension et rend' + #13#10 +
        'ensuite cette charge. Combien de temps : constante de temps tau = R × C (p. ex. 1000 ohms × 1000 µF = 1 s).' + #13#10 +
        'Clic droit : choisir la capacité ou décharger.',
      'Kondensator mit zwei Klemmen: + links. Er lädt sich auf, wenn Spannung anliegt, und gibt' + #13#10 +
        'die Ladung wieder ab. Wie lange das dauert: Zeitkonstante tau = R × C (z. B. 1000 Ohm × 1000 µF = 1 s).' + #13#10 +
        'Rechtsklick: Kapazität wählen oder entladen.');
end;

procedure TjanCondensator.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Tr(FTaal, 'Condensator', 'Capacitor', 'Condensateur', 'Kondensator') + ' > ', 0);
  FOnStatus(Self, UFText(CondUF[FSoort]) + '   U = ' + VoltText(FU) + '   I = ' + MilliAmpText(Abs(FAmp)), 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

{ TjanSchakelaar2 }

constructor TjanSchakelaar2.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := Schakelaar2W;
  Height := Schakelaar2H;
  HelpKeyword := 'schakelaar2';
end;

function TjanSchakelaar2.PinCount: Integer;
begin
  if FSoort = 2 then Result := 3 else Result := 2;
end;

// klem 0 links, klem 1 rechts; wisselschakelaar: klem 0 = A, klem 1 = B en
// klem 2 = het midden (onderaan), waar de hendel draait
function TjanSchakelaar2.PinPos(I: Integer): TPoint;
begin
  case I of
    0: Result := TP(1, 21);
    1: Result := TP(Schakelaar2W - 8, 21);
  else
    Result := TP(Schakelaar2W div 2 - 4, Schakelaar2H - 8);
  end;
end;

function TjanSchakelaar2.KanDraaien: Boolean;
begin
  Result := True;
end;

function TjanSchakelaar2.StdMaat: TPoint;
begin
  Result := Point(Schakelaar2W, Schakelaar2H);
end;

function TjanSchakelaar2.ExtraBreedte: Integer;
begin
  Result := 24;   // dicht/open rechts naast de hendel
end;

function TjanSchakelaar2.GetDruk: Boolean;
begin
  Result := FSoort = 1;
end;

function TjanSchakelaar2.GetWissel: Boolean;
begin
  Result := FSoort = 2;
end;

procedure TjanSchakelaar2.SetDruk(const Value: Boolean);
begin
  if Value then Soort := 1 else if FSoort = 1 then Soort := 0;
end;

procedure TjanSchakelaar2.SetAan(const Value: Boolean);
begin
  if Value = FAan then Exit;
  FAan := Value;
  UpdateHintText;
  Invalidate;
  if Parent <> nil then
    UpdateSupply(Parent, True);
end;

function TjanSchakelaar2.HandleClick(X, Y: Integer): Boolean;
begin
  // de hendel (tussen de twee contacten); gedraaid: x en y gespiegeld
  with TP(X, Y) do
    Result := (X >= 12) and (X <= Schakelaar2W - 12) and (Y >= 4) and (Y <= 30);
  if not Result then Exit;
  if FSoort = 1 then Aan := True else Aan := not Aan;
end;

// drukknop: muisknop los = weer open
procedure TjanSchakelaar2.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if (FSoort = 1) and FAan then Aan := False;
end;

procedure TjanSchakelaar2.SetSoort(const Value: Integer);
begin
  // de wisselschakelaar is een eigen onderdeel (TjanWissel2): niet omzetten
  if (Self is TjanWissel2) or (Value < 0) or (Value > 1) or (Value = FSoort) then Exit;
  FSoort := Value;
  if FSoort = 1 then FAan := False;
  UpdateHintText;
  Invalidate;
  if Parent <> nil then
    UpdateSupply(Parent, True);
end;

procedure TjanSchakelaar2.SoortClick(Sender: TObject);
begin
  Soort := TMenuItem(Sender).Tag;
end;

procedure TjanSchakelaar2.AddMenuItems(APop: TPopupMenu);
var
  Mi, Sub: TMenuItem;
  i: Integer;
begin
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Soort', 'Type', 'Type', 'Art');
  APop.Items.Add(Mi);
  for i := 0 to 1 do
  begin
    Sub := TMenuItem.Create(APop);
    if i = 0 then
      Sub.Caption := Tr(FTaal, 'Schakelaar (blijft staan)', 'Switch (stays put)',
        'Interrupteur (reste en place)', 'Schalter (bleibt stehen)')
    else
      Sub.Caption := Tr(FTaal, 'Drukknop (alleen zolang je drukt)', 'Push button (only while pressed)',
        'Bouton-poussoir (seulement en appuyant)', 'Taster (nur solange gedrückt)');
    Sub.Tag := i;
    Sub.RadioItem := True;
    Sub.Checked := i = FSoort;
    Sub.Enabled := not FLock;
    Sub.OnClick := SoortClick;
    Mi.Add(Sub);
  end;
end;

procedure TjanSchakelaar2.Paint;
var
  CY, XL, XR, TW, MX, MY: Integer;
  S: string;
begin
  // tekening in de gewone stand; TP/TRc spiegelen ze als hij gedraaid is
  CY := 21 + 3;
  XL := 16;
  XR := Schakelaar2W - 16;
  with Canvas do
  begin
    Pen.Color := clBlack; Pen.Width := 2;
    TLijn(8, CY, XL, CY);
    TLijn(XR, CY, Schakelaar2W - 8, CY);
    if FSoort = 2 then
    begin
      // wisselschakelaar: de hendel draait in het midden onderaan en wijst
      // naar contact A (links) of B (rechts); hij maakt altijd contact
      MX := Schakelaar2W div 2;
      MY := Schakelaar2H - 9;
      TW := 12;            // hoogte van de contacten A en B
      TLijn(XL, CY, XL, TW);
      TLijn(XR, CY, XR, TW);
      Pen.Color := clRed; Pen.Width := 3;
      if FAan then TLijn(MX, MY, XR - 1, TW + 1) else TLijn(MX, MY, XL + 1, TW + 1);
      Pen.Width := 1; Pen.Color := clBlack;
      Brush.Style := bsSolid; Brush.Color := clWhite;
      Ellipse(TRc(XL - 3, TW - 3, XL + 4, TW + 4));
      Ellipse(TRc(XR - 3, TW - 3, XR + 4, TW + 4));
      Brush.Color := clBlack;
      Ellipse(TRc(MX - 3, MY - 3, MX + 4, MY + 4));
      PaintPin(PinPos(0).X, PinPos(0).Y, FPinV[0] >= RailMinVolt);
      PaintPin(PinPos(1).X, PinPos(1).Y, FPinV[1] >= RailMinVolt);
      PaintPin(PinPos(2).X, PinPos(2).Y, FPinV[2] >= RailMinVolt);
      Brush.Style := bsClear;
      Font.Name := 'Arial'; Font.Size := 7; Font.Style := [fsBold]; Font.Color := clNavy;
      // de letters binnen naast de contacten (de draden komen van buiten)
      with TP(XL + 5, 1) do TextOut(X, Y, 'A');
      with TP(XR - 11, 1) do TextOut(X, Y, 'B');
      PaintSelection;
      Exit;
    end;
    if FAan then Pen.Color := clRed else Pen.Color := clBlack;
    Pen.Width := 3;
    if FSoort = 1 then
    begin
      // drukknop: een brug boven de contacten met een steeltje erop;
      // ingedrukt ligt de brug op de contacten
      if FAan then TW := CY - 2 else TW := CY - 9;
      TLijn(XL - 2, TW, XR + 2, TW);
      Pen.Width := 2;
      TLijn((XL + XR) div 2, TW, (XL + XR) div 2, TW - 10);
      TLijn((XL + XR) div 2 - 5, TW - 10, (XL + XR) div 2 + 6, TW - 10);
    end
    // hendel: dicht = recht naar het andere contact, open = schuin omhoog
    // (gedraaid: schuin naar links)
    else if FAan then TLijn(XL, CY, XR - 1, CY) else TLijn(XL, CY, XR - 4, CY - 13);
    Pen.Width := 1; Pen.Color := clBlack;
    Brush.Style := bsSolid; Brush.Color := clBlack;
    Ellipse(TRc(XL - 3, CY - 3, XL + 4, CY + 4));
    Brush.Color := clWhite;
    Ellipse(TRc(XR - 3, CY - 3, XR + 4, CY + 4));
    PaintPin(PinPos(0).X, PinPos(0).Y, FPinV[0] >= RailMinVolt);
    PaintPin(PinPos(1).X, PinPos(1).Y, FPinV[1] >= RailMinVolt);
    Brush.Style := bsClear;
    Font.Name := 'Arial'; Font.Size := 7; Font.Style := []; Font.Color := clNavy;
    if FSoort = 1 then
    begin
      if FAan then S := Tr(FTaal, 'ingedrukt', 'pressed', 'appuyé', 'gedrückt')
      else S := Tr(FTaal, 'los', 'released', 'relâché', 'los');
    end
    else if FAan then S := Tr(FTaal, 'dicht', 'closed', 'fermé', 'zu')
    else S := Tr(FTaal, 'open', 'open', 'ouvert', 'offen');
    TW := TextWidth(S);
    if FGedraaid then
      TextOut(CY + 8, (Schakelaar2W - TextHeight(S)) div 2, S)
    else
      TextOut((Schakelaar2W - TW) div 2, CY + 6, S);
  end;
  PaintSelection;
end;

procedure TjanSchakelaar2.UpdateHintText;
var
  S2: string;
begin
  if FSoort = 2 then
  begin
    Hint := Tr(FTaal, 'Wisselschakelaar', 'Changeover switch', 'Commutateur va-et-vient', 'Wechselschalter') + ': ';
    if FAan then S2 := 'B' else S2 := 'A';
    Hint := Hint + Tr(FTaal, 'het midden is verbonden met ', 'the middle is connected to ',
      'le milieu est relié à ', 'die Mitte ist verbunden mit ') + S2 + '   ' + StroomRegel(Abs(FAmp));
    Hint := Hint + #13#10 + Tr(FTaal,
      'Wisselschakelaar met drie klemmen: het midden (onderaan) is verbonden met A of met B. Klik om om te wisselen. ' +
      'Twee wisselschakelaars maken de schakeling van een trap: je zet het licht aan en uit vanaf twee plaatsen.',
      'Changeover switch with three terminals: the middle (bottom) is connected to A or to B. Click to change over. ' +
      'Two changeover switches make a staircase circuit: you switch the light on and off from two places.',
      'Commutateur à trois bornes : le milieu (en bas) est relié à A ou à B. Cliquez pour basculer. ' +
      'Deux commutateurs font un va-et-vient d''escalier : vous allumez et éteignez depuis deux endroits.',
      'Wechselschalter mit drei Klemmen: die Mitte (unten) ist mit A oder B verbunden. Klicken zum Umschalten. ' +
      'Zwei Wechselschalter ergeben eine Treppenhausschaltung: Licht ein und aus von zwei Stellen.');
    Exit;
  end;
  if FSoort = 1 then
  begin
    Hint := Tr(FTaal, 'Drukknop', 'Push button', 'Bouton-poussoir', 'Taster') + ': ';
    if FAan then
      Hint := Hint + Tr(FTaal, 'ingedrukt', 'pressed', 'appuyé', 'gedrückt') + '   ' + StroomRegel(Abs(FAmp))
    else
      Hint := Hint + Tr(FTaal, 'los: er loopt geen stroom', 'released: no current flows',
        'relâché : aucun courant ne passe', 'los: es fließt kein Strom');
    Hint := Hint + #13#10 + Tr(FTaal,
      'Drukknop met twee klemmen in de kring. Hij is alleen dicht zolang je erop drukt (muisknop ingedrukt houden).',
      'Push button with two terminals in the circuit. It is only closed while you press it (hold the mouse button).',
      'Bouton-poussoir à deux bornes dans le circuit. Il n''est fermé que tant que vous appuyez (gardez le bouton de la souris enfoncé).',
      'Taster mit zwei Klemmen im Stromkreis. Er ist nur geschlossen, solange Sie drücken (Maustaste gedrückt halten).');
    Exit;
  end;
  Hint := Tr(FTaal, 'Schakelaar', 'Switch', 'Interrupteur', 'Schalter') + ': ';
  if FAan then
    Hint := Hint + Tr(FTaal, 'dicht', 'closed', 'fermé', 'geschlossen') + '   ' + StroomRegel(Abs(FAmp))
  else
    Hint := Hint + Tr(FTaal, 'open: er loopt geen stroom', 'open: no current flows',
      'ouvert : aucun courant ne passe', 'offen: es fließt kein Strom');
  Hint := Hint + #13#10 + Tr(FTaal,
      'Schakelaar met twee klemmen in de kring. Klik op de hendel om hem te openen of te sluiten.',
      'Switch with two terminals in the circuit. Click the lever to open or close it.',
      'Interrupteur à deux bornes dans le circuit. Cliquez sur le levier pour l''ouvrir ou le fermer.',
      'Schalter mit zwei Klemmen im Stromkreis. Klicken Sie auf den Hebel, um ihn zu öffnen oder zu schließen.');
end;

procedure TjanSchakelaar2.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  case FSoort of
    1: FOnStatus(Self, Tr(FTaal, 'Drukknop', 'Push button', 'Bouton-poussoir', 'Taster') + ' > ', 0);
    2: FOnStatus(Self, Tr(FTaal, 'Wisselschakelaar', 'Changeover switch', 'Commutateur va-et-vient', 'Wechselschalter') + ' > ', 0);
  else
    FOnStatus(Self, Tr(FTaal, 'Schakelaar', 'Switch', 'Interrupteur', 'Schalter') + ' > ', 0);
  end;
  if FSoort = 2 then
  begin
    if FAan then FOnStatus(Self, 'B', 1) else FOnStatus(Self, 'A', 1);
  end
  else if FAan then
    FOnStatus(Self, Tr(FTaal, 'dicht', 'closed', 'fermé', 'geschlossen'), 1)
  else
    FOnStatus(Self, Tr(FTaal, 'open', 'open', 'ouvert', 'offen'), 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

{ TjanWissel2 }

constructor TjanWissel2.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSoort := 2;
  HelpKeyword := 'wisselschakelaar';
end;

// geen keuze van de soort: drie klemmen blijven drie klemmen
procedure TjanWissel2.AddMenuItems(APop: TPopupMenu);
begin
end;

{ TjanPuls2 }

const
  Puls2W = 88; Puls2H = 40;
  Puls2Intervallen: array[0..4] of Integer = (1000, 500, 300, 200, 100);
  Dip2W = 96; Dip2H = 92;
  Dip2Rij0 = 12;      // y van de bovenste uitgang (8)
  Dip2RijAfst = 20;   // afstand tussen de uitgangen

function Puls2FreqText(AInterval: Integer): string;
begin
  if AInterval <= 0 then AInterval := 300;
  Result := FormatFloat('0.#', 1000 / (2 * AInterval)) + ' Hz';
end;

constructor TjanPuls2.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := Puls2W;
  Height := Puls2H;
  HelpKeyword := 'puls2';
  FInterval := 300;
  FKlok := TTimer.Create(Self);
  FKlok.Interval := FInterval;
  FKlok.OnTimer := Tik;
  FKlok.Enabled := False;   // pas na een klik op het kastje
end;

procedure TjanPuls2.SetLoopt(const Value: Boolean);
begin
  if Value = FLoopt then Exit;
  FLoopt := Value;
  FKlok.Enabled := Value;
  if not Value then FAan := False;   // gestopt: het contact staat open
  UpdateHintText;
  Invalidate;
  if Parent <> nil then
    UpdateSupply(Parent, True);
end;

// klik op het kastje: aan- of uitzetten (ook tijdens de simulatie)
function TjanPuls2.HandleClick(X, Y: Integer): Boolean;
begin
  Result := (X >= 12) and (X <= Puls2W - 12) and (Y >= 6) and (Y <= 38);
  if Result then Loopt := not FLoopt;
end;

function TjanPuls2.PinCount: Integer;
begin
  Result := 2;
end;

function TjanPuls2.PinPos(I: Integer): TPoint;
begin
  if I = 0 then Result := Point(1, 21) else Result := Point(Puls2W - 8, 21);
end;

procedure TjanPuls2.Tik(Sender: TObject);
begin
  if Parent = nil then Exit;
  FAan := not FAan;
  Invalidate;
  UpdateSupply(Parent, True);
end;

procedure TjanPuls2.SetInterval(const Value: Integer);
begin
  if (Value <= 0) or (Value = FInterval) then Exit;
  FInterval := Value;
  FKlok.Interval := Value;
  UpdateHintText;
  Invalidate;
end;

procedure TjanPuls2.FreqClick(Sender: TObject);
begin
  Interval := TMenuItem(Sender).Tag;
end;

procedure TjanPuls2.AddMenuItems(APop: TPopupMenu);
var
  Mi, Sub: TMenuItem;
  i: Integer;
begin
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Frequentie', 'Frequency', 'Fréquence', 'Frequenz');
  APop.Items.Add(Mi);
  for i := Low(Puls2Intervallen) to High(Puls2Intervallen) do
  begin
    Sub := TMenuItem.Create(APop);
    Sub.Caption := Puls2FreqText(Puls2Intervallen[i]);
    Sub.Tag := Puls2Intervallen[i];
    Sub.RadioItem := True;
    Sub.Checked := Puls2Intervallen[i] = FInterval;
    Sub.OnClick := FreqClick;
    Mi.Add(Sub);
  end;
end;

procedure TjanPuls2.Paint;
var
  CY, X0, Y0, Y1, S: Integer;
begin
  CY := 24;
  with Canvas do
  begin
    Pen.Color := clBlack; Pen.Width := 2;
    MoveTo(8, CY); LineTo(12, CY);
    MoveTo(Puls2W - 12, CY); LineTo(Puls2W - 8, CY);
    // kastje met een blokgolf en een contact dat open en dicht gaat
    Pen.Width := 1;
    Brush.Style := bsSolid; Brush.Color := clWhite;
    Rectangle(12, 6, Puls2W - 12, 38);
    if FLoopt then Pen.Color := clNavy else Pen.Color := clSilver;
    Pen.Width := 2;
    X0 := 18; Y0 := 14; Y1 := 24; S := 6;
    MoveTo(X0, Y1); LineTo(X0 + S, Y1); LineTo(X0 + S, Y0); LineTo(X0 + 2 * S, Y0);
    LineTo(X0 + 2 * S, Y1); LineTo(X0 + 3 * S, Y1); LineTo(X0 + 3 * S, Y0); LineTo(X0 + 4 * S, Y0);
    // het contact rechts in het kastje: dicht = rood
    if FAan then Pen.Color := clRed else Pen.Color := clBlack;
    Pen.Width := 3;
    if FAan then
    begin
      MoveTo(48, CY); LineTo(Puls2W - 18, CY);
    end
    else
    begin
      MoveTo(48, CY); LineTo(Puls2W - 20, CY - 9);
    end;
    Pen.Width := 1; Pen.Color := clBlack;
    MoveTo(Puls2W - 18, CY); LineTo(Puls2W - 12, CY);
    MoveTo(12, CY); LineTo(48, CY);
    Brush.Style := bsClear;
    Font.Name := 'Arial'; Font.Size := 7; Font.Style := []; Font.Color := clNavy;
    TextOut(16, 27, Puls2FreqText(FInterval));
    if FLoopt then
    begin
      Font.Color := clGreen; Font.Style := [fsBold];
      TextOut(52, 27, Tr(FTaal, 'aan', 'on', 'on', 'an'));
    end
    else
    begin
      Font.Color := clGray; Font.Style := [fsBold];
      TextOut(52, 27, Tr(FTaal, 'uit', 'off', 'off', 'aus'));
    end;
    PaintPin(PinPos(0).X, PinPos(0).Y, FPinV[0] >= RailMinVolt);
    PaintPin(PinPos(1).X, PinPos(1).Y, FPinV[1] >= RailMinVolt);
  end;
  PaintSelection;
end;

procedure TjanPuls2.UpdateHintText;
begin
  Hint := Tr(FTaal, 'Impulsgenerator', 'Pulse generator', 'Générateur d''impulsions', 'Impulsgenerator') +
    ' ' + Puls2FreqText(FInterval) + #13#10 + Tr(FTaal,
    'Een schakelaar die vanzelf opent en sluit. Tussen de + rail en een ingang geeft hij pulsen. Klik op het kastje: aan of uit. Rechtsklik: frequentie.',
    'A switch that opens and closes by itself. Between the + rail and an input it gives pulses. Click the box: on or off. Right-click: frequency.',
    'Un interrupteur qui s''ouvre et se ferme tout seul. Entre le rail + et une entrée, il donne des impulsions. Clic sur le boîtier : marche ou arrêt. Clic droit : fréquence.',
    'Ein Schalter, der sich von selbst öffnet und schließt. Zwischen der + Schiene und einem Eingang gibt er Impulse. Klick auf das Kästchen: an oder aus. Rechtsklick: Frequenz.');
end;

procedure TjanPuls2.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Tr(FTaal, 'Impulsgenerator', 'Pulse generator', 'Générateur d''impulsions', 'Impulsgenerator') + ' > ', 0);
  FOnStatus(Self, Puls2FreqText(FInterval), 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

{ TjanDip2 }

constructor TjanDip2.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := Dip2W;
  Height := Dip2H;
  HelpKeyword := 'dip2';
end;

function TjanDip2.PinCount: Integer;
begin
  Result := 5;
end;

// klem 0 links in het midden, klemmen 1..4 rechts (8, 4, 2, 1)
function TjanDip2.PinPos(I: Integer): TPoint;
begin
  if I = 0 then
    Result := Point(1, Dip2Rij0 + Dip2RijAfst * 3 div 2 - 3)
  else
    Result := Point(Dip2W - 8, Dip2Rij0 + Dip2RijAfst * (I - 1) - 3);
end;

function TjanDip2.BitAan(APin: Integer): Boolean;
begin
  Result := (FWaarde and (1 shl (4 - APin))) <> 0;
end;

procedure TjanDip2.SetWaarde(const Value: Integer);
begin
  if (Value < 0) or (Value > 15) or (Value = FWaarde) then Exit;
  FWaarde := Value;
  UpdateHintText;
  Invalidate;
  if Parent <> nil then
    UpdateSupply(Parent, True);
end;

function TjanDip2.HandleClick(X, Y: Integer): Boolean;
var
  i, Ry: Integer;
begin
  Result := False;
  if (X < 26) or (X > 66) then Exit;
  for i := 1 to 4 do
  begin
    Ry := Dip2Rij0 + Dip2RijAfst * (i - 1);
    if Abs(Y - Ry) <= Dip2RijAfst div 2 then
    begin
      Waarde := FWaarde xor (1 shl (4 - i));
      Exit(True);
    end;
  end;
end;

procedure TjanDip2.Paint;
const
  Gewicht: array[1..4] of string = ('8', '4', '2', '1');
var
  i, Ry, CY0, XB: Integer;
begin
  CY0 := PinPos(0).Y + 3;
  XB := 18;     // de gemeenschappelijke lijn
  with Canvas do
  begin
    Brush.Style := bsSolid; Brush.Color := RGBToColor(235, 240, 250);
    Pen.Color := clGray; Pen.Width := 1;
    Rectangle(12, 2, Dip2W - 12, Dip2H - 14);
    Pen.Color := clBlack; Pen.Width := 2;
    MoveTo(8, CY0); LineTo(XB, CY0);
    MoveTo(XB, Dip2Rij0); LineTo(XB, Dip2Rij0 + Dip2RijAfst * 3);
    Font.Name := 'Arial'; Font.Size := 7;
    for i := 1 to 4 do
    begin
      Ry := Dip2Rij0 + Dip2RijAfst * (i - 1);
      Pen.Color := clBlack; Pen.Width := 2;
      MoveTo(XB, Ry); LineTo(30, Ry);
      MoveTo(56, Ry); LineTo(Dip2W - 8, Ry);
      // het schuifje: dicht = rood en recht, open = schuin
      Pen.Width := 3;
      if BitAan(i) then
      begin
        Pen.Color := clRed; MoveTo(30, Ry); LineTo(55, Ry);
      end
      else
      begin
        Pen.Color := clBlack; MoveTo(30, Ry); LineTo(52, Ry - 8);
      end;
      Pen.Width := 1; Pen.Color := clBlack;
      Brush.Style := bsSolid; Brush.Color := clBlack;
      Ellipse(27, Ry - 3, 34, Ry + 4);
      Brush.Color := clWhite;
      Ellipse(53, Ry - 3, 60, Ry + 4);
      Brush.Style := bsClear;
      Font.Style := [fsBold]; Font.Color := clNavy;
      TextOut(Dip2W - 24, Ry - 13, Gewicht[i]);
      PaintPin(PinPos(i).X, PinPos(i).Y, FPinV[i] >= RailMinVolt);
    end;
    PaintPin(PinPos(0).X, PinPos(0).Y, FPinV[0] >= RailMinVolt);
    Brush.Style := bsClear;
    Font.Style := [fsBold]; Font.Color := clRed; Font.Size := 8;
    TextOut((Dip2W - TextWidth('= ' + IntToStr(FWaarde))) div 2, Dip2H - 13, '= ' + IntToStr(FWaarde));
  end;
  PaintSelection;
end;

procedure TjanDip2.UpdateHintText;
begin
  Hint := Tr(FTaal, 'Dipschakelaar', 'DIP switch', 'Interrupteur DIP', 'DIP-Schalter') + ' = ' + IntToStr(FWaarde) +
    #13#10 + Tr(FTaal,
    'Vier schakelaartjes: links de gemeenschappelijke klem (naar de + rail), rechts de uitgangen 8, 4, 2 en 1. Klik op een schuifje om het om te zetten.',
    'Four small switches: on the left the common terminal (to the + rail), on the right the outputs 8, 4, 2 and 1. Click a slider to change it.',
    'Quatre petits interrupteurs : à gauche la borne commune (vers le rail +), à droite les sorties 8, 4, 2 et 1. Cliquez sur un curseur pour le changer.',
    'Vier kleine Schalter: links die gemeinsame Klemme (zur + Schiene), rechts die Ausgänge 8, 4, 2 und 1. Klicken Sie auf einen Schieber, um ihn umzuschalten.');
end;

procedure TjanDip2.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Tr(FTaal, 'Dipschakelaar', 'DIP switch', 'Interrupteur DIP', 'DIP-Schalter') + ' > ', 0);
  FOnStatus(Self, '= ' + IntToStr(FWaarde), 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

{ TjanVoltmeter2 }

constructor TjanVoltmeter2.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := Voltmeter2W;
  Height := Voltmeter2H;
  HelpKeyword := 'voltmeter2';
end;

function TjanVoltmeter2.PinCount: Integer;
begin
  Result := 2;
end;

function TjanVoltmeter2.PinPos(I: Integer): TPoint;
begin
  if I = 0 then Result := Point(1, 35) else Result := Point(Voltmeter2W - 8, 35);
end;

function TjanVoltmeter2.Spanning: Double;
begin
  Result := FPinV[0] - FPinV[1];
  if Abs(Result) < 0.005 then Result := 0;
end;

procedure TjanVoltmeter2.Paint;
var
  R: TRect;
  S: string;
  TW: Integer;
begin
  with Canvas do
  begin
    Brush.Style := bsSolid;
    Brush.Color := clSilver;
    R := ClientRect;
    FillRect(R);
    Frame3D(R, clBtnHighlight, clBtnShadow, 1);
    Brush.Color := RGBToColor(255, 250, 220);
    R := Rect(18, 5, 82, 30);
    FillRect(R);
    Frame3D(R, clBtnShadow, clBtnHighlight, 2);
    Brush.Style := bsClear;
    S := FormatFloat('0.0', Spanning);
    Font.Name := 'Arial'; Font.Size := 12; Font.Style := [fsBold];
    if Abs(Spanning) >= 0.05 then Font.Color := clRed else Font.Color := clGray;
    TW := TextWidth(S);
    TextOut(66 - TW, 8, S);
    Font.Size := 9; Font.Color := clBlack; Font.Style := [];
    TextOut(68, 11, 'V');
    PaintPin(PinPos(0).X, PinPos(0).Y, FPinV[0] >= RailMinVolt);
    PaintPin(PinPos(1).X, PinPos(1).Y, FPinV[1] >= RailMinVolt);
    Brush.Style := bsClear;
    Font.Size := 9; Font.Style := [fsBold];
    Font.Color := clRed;  TextOut(11, 32, '+');
    Font.Color := clNavy; TextOut(Voltmeter2W - 17, 31, '−');
    Font.Size := 8; TextOut(46, 34, 'V');
  end;
  PaintSelection;
end;

procedure TjanVoltmeter2.UpdateHintText;
begin
  Hint := Tr(FTaal, 'Voltmeter', 'Voltmeter', 'Voltmètre', 'Voltmeter') + ': U = ' +
    VoltText(Spanning) + #13#10 + Tr(FTaal,
      'Zet de + klem (links) en de − klem (rechts) met een draad op de twee kanten' + #13#10 +
        'van een lamp, contact of bron. De meter neemt geen stroom.',
      'Connect the + terminal (left) and the − terminal (right) with a wire to both sides' + #13#10 +
        'of a lamp, contact or source. The meter draws no current.',
      'Reliez la borne + (à gauche) et la borne − (à droite) par un fil aux deux côtés' + #13#10 +
        'd''une lampe, d''un contact ou d''une source. Le voltmètre ne consomme pas de courant.',
      'Verbinden Sie die + Klemme (links) und die − Klemme (rechts) mit einem Draht mit beiden Seiten' + #13#10 +
        'einer Lampe, eines Kontakts oder einer Quelle. Das Messgerät nimmt keinen Strom auf.');
end;

procedure TjanVoltmeter2.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Tr(FTaal, 'Voltmeter', 'Voltmeter', 'Voltmètre', 'Voltmeter') + ' > ', 0);
  FOnStatus(Self, 'U = ' + VoltText(Spanning), 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

{ TjanScoop }

constructor TjanScoop.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := ScoopW;
  Height := ScoopH;
  SetLength(FT, ScoopMax);
  SetLength(FU, ScoopMax);
  FBereikIdx := 1;   // +/- 12 V
  FTijdIdx := 1;     // 4 s
  HelpKeyword := 'scoop';
end;

// klemmen onderaan: + links, - rechts
function TjanScoop.PinPos(I: Integer): TPoint;
begin
  if I = 0 then Result := Point(1, ScoopH - 15) else Result := Point(ScoopW - 8, ScoopH - 15);
end;

procedure TjanScoop.Wis;
begin
  FN := 0;
  FKop := 0;
  Invalidate;
end;

procedure TjanScoop.Meet(AU: Double);
var
  Laatste: Integer;
begin
  if FN > 0 then
  begin
    Laatste := (FKop - 1 + ScoopMax) mod ScoopMax;
    // de tijd sprong terug (nieuw paneel, andere start): opnieuw beginnen
    if SimTijd < FT[Laatste] - 0.0001 then
    begin
      FN := 0;
      FKop := 0;
    end
    // nog dezelfde tijd: alleen de laatste meting bijwerken
    else if SimTijd - FT[Laatste] < 0.0005 then
    begin
      FU[Laatste] := AU;
      Exit;
    end;
  end;
  FT[FKop] := SimTijd;
  FU[FKop] := AU;
  FKop := (FKop + 1) mod ScoopMax;
  if FN < ScoopMax then Inc(FN);
  Invalidate;
end;

function TjanScoop.MaxLaatste(ASec: Double): Double;
var
  i, j: Integer;
  TNu: Double;
begin
  Result := 0;
  if FN = 0 then Exit;
  TNu := FT[(FKop - 1 + ScoopMax) mod ScoopMax];
  Result := -1E9;
  for i := 0 to FN - 1 do
  begin
    j := (FKop - 1 - i + 2 * ScoopMax) mod ScoopMax;
    if FT[j] < TNu - ASec then Break;
    if FU[j] > Result then Result := FU[j];
  end;
end;

function TjanScoop.MinLaatste(ASec: Double): Double;
var
  i, j: Integer;
  TNu: Double;
begin
  Result := 0;
  if FN = 0 then Exit;
  TNu := FT[(FKop - 1 + ScoopMax) mod ScoopMax];
  Result := 1E9;
  for i := 0 to FN - 1 do
  begin
    j := (FKop - 1 - i + 2 * ScoopMax) mod ScoopMax;
    if FT[j] < TNu - ASec then Break;
    if FU[j] < Result then Result := FU[j];
  end;
end;

procedure TjanScoop.SetBereikIdx(const Value: Integer);
begin
  if (Value < Low(ScoopBereik)) or (Value > High(ScoopBereik)) or (Value = FBereikIdx) then Exit;
  FBereikIdx := Value;
  Invalidate;
end;

procedure TjanScoop.SetTijdIdx(const Value: Integer);
begin
  if (Value < Low(ScoopTijd)) or (Value > High(ScoopTijd)) or (Value = FTijdIdx) then Exit;
  FTijdIdx := Value;
  Invalidate;
end;

procedure TjanScoop.BereikClick(Sender: TObject);
begin
  BereikIdx := TMenuItem(Sender).Tag;
end;

procedure TjanScoop.TijdClick(Sender: TObject);
begin
  TijdIdx := TMenuItem(Sender).Tag;
end;

procedure TjanScoop.WisClick(Sender: TObject);
begin
  Wis;
end;

procedure TjanScoop.AddMenuItems(APop: TPopupMenu);
var
  Mi, Sub: TMenuItem;
  i: Integer;
begin
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Bereik', 'Range', 'Calibre', 'Messbereich');
  APop.Items.Add(Mi);
  for i := Low(ScoopBereik) to High(ScoopBereik) do
  begin
    Sub := TMenuItem.Create(APop);
    Sub.Caption := '± ' + FormatFloat('0', ScoopBereik[i]) + ' V';
    Sub.Tag := i;
    Sub.RadioItem := True;
    Sub.Checked := i = FBereikIdx;
    Sub.OnClick := BereikClick;
    Mi.Add(Sub);
  end;
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Tijdbasis', 'Time base', 'Base de temps', 'Zeitbasis');
  APop.Items.Add(Mi);
  for i := Low(ScoopTijd) to High(ScoopTijd) do
  begin
    Sub := TMenuItem.Create(APop);
    Sub.Caption := FormatFloat('0', ScoopTijd[i]) + ' s';
    Sub.Tag := i;
    Sub.RadioItem := True;
    Sub.Checked := i = FTijdIdx;
    Sub.OnClick := TijdClick;
    Mi.Add(Sub);
  end;
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Scherm wissen', 'Clear screen', 'Effacer l''écran', 'Bildschirm löschen');
  Mi.OnClick := WisClick;
  APop.Items.Add(Mi);
end;

procedure TjanScoop.Paint;
var
  R: TRect;
  S: string;
  i, j, X, Y, CY, H2, TW: Integer;
  Venster, T0, TNu, Ber: Double;
  Eerste: Boolean;
begin
  Venster := ScoopTijd[FTijdIdx];
  Ber := ScoopBereik[FBereikIdx];
  with Canvas do
  begin
    // kast
    Brush.Style := bsSolid;
    Brush.Color := RGBToColor(70, 75, 85);
    R := ClientRect;
    FillRect(R);
    Frame3D(R, clBtnHighlight, clBtnShadow, 1);
    // scherm met raster: 8 vakken breed, 6 hoog
    R := Rect(8, 6, ScoopW - 8, ScoopH - 30);
    Brush.Color := RGBToColor(10, 30, 15);
    FillRect(R);
    Pen.Width := 1;
    Pen.Color := RGBToColor(35, 75, 45);
    for i := 1 to 7 do
    begin
      X := R.Left + (R.Right - R.Left) * i div 8;
      MoveTo(X, R.Top); LineTo(X, R.Bottom);
    end;
    for i := 1 to 5 do
    begin
      Y := R.Top + (R.Bottom - R.Top) * i div 6;
      MoveTo(R.Left, Y); LineTo(R.Right, Y);
    end;
    CY := (R.Top + R.Bottom) div 2;
    H2 := (R.Bottom - R.Top) div 2;
    Pen.Color := RGBToColor(70, 130, 80);
    MoveTo(R.Left, CY); LineTo(R.Right, CY);   // nullijn
    // het spoor: van de oudste naar de nieuwste meting, de nieuwste rechts
    if FN > 0 then
    begin
      TNu := FT[(FKop - 1 + ScoopMax) mod ScoopMax];
      T0 := TNu - Venster;
      Pen.Color := RGBToColor(80, 255, 110);
      Pen.Width := 2;
      Eerste := True;
      for i := FN - 1 downto 0 do
      begin
        j := (FKop - 1 - i + 2 * ScoopMax) mod ScoopMax;
        if FT[j] < T0 then Continue;
        X := R.Left + Round((FT[j] - T0) / Venster * (R.Right - R.Left));
        Y := CY - Round(FU[j] / Ber * H2);
        if Y < R.Top then Y := R.Top;
        if Y > R.Bottom then Y := R.Bottom;
        if Eerste then MoveTo(X, Y) else LineTo(X, Y);
        Eerste := False;
      end;
      Pen.Width := 1;
    end;
    // schaal en de spanning van nu
    Brush.Style := bsClear;
    Font.Name := 'Arial'; Font.Size := 6; Font.Style := []; Font.Color := RGBToColor(150, 220, 160);
    TextOut(R.Left + 2, R.Top + 1, '+' + FormatFloat('0', Ber) + ' V');
    TextOut(R.Left + 2, R.Bottom - 10, '−' + FormatFloat('0', Ber) + ' V');
    S := FormatFloat('0', Venster) + ' s';
    TextOut(R.Right - TextWidth(S) - 2, R.Bottom - 10, S);
    Font.Size := 8; Font.Style := [fsBold]; Font.Color := clWhite;
    S := 'U = ' + FormatFloat('+0.0;-0.0;0.0', Spanning) + ' V';
    TW := TextWidth(S);
    TextOut((ScoopW - TW) div 2, ScoopH - 21, S);
    PaintPin(PinPos(0).X, PinPos(0).Y, FPinV[0] >= RailMinVolt);
    PaintPin(PinPos(1).X, PinPos(1).Y, FPinV[1] >= RailMinVolt);
    Font.Size := 9;
    Font.Color := RGBToColor(255, 110, 110); TextOut(11, ScoopH - 22, '+');
    Font.Color := RGBToColor(140, 170, 255); TextOut(ScoopW - 17, ScoopH - 23, '−');
  end;
  PaintSelection;
end;

procedure TjanScoop.UpdateHintText;
begin
  Hint := Tr(FTaal, 'Oscilloscoop', 'Oscilloscope', 'Oscilloscope', 'Oszilloskop') + ': U = ' +
    VoltText(Spanning) + '   (± ' + FormatFloat('0', ScoopBereik[FBereikIdx]) + ' V, ' +
    FormatFloat('0', ScoopTijd[FTijdIdx]) + ' s)' + #13#10 + Tr(FTaal,
      'Tekent de spanning tussen + en − in de tijd, zoals een voltmeter die schrijft.' + #13#10 +
        'Hij meet tijdens de simulatie en neemt geen stroom. Rechtsklik: bereik, tijdbasis, wissen.',
      'Draws the voltage between + and − over time, like a voltmeter that writes.' + #13#10 +
        'It measures during the simulation and draws no current. Right-click: range, time base, clear.',
      'Trace la tension entre + et − dans le temps, comme un voltmètre qui écrit.' + #13#10 +
        'Il mesure pendant la simulation et ne consomme pas de courant. Clic droit : calibre, base de temps, effacer.',
      'Zeichnet die Spannung zwischen + und − über die Zeit, wie ein Voltmeter, das schreibt.' + #13#10 +
        'Es misst während der Simulation und nimmt keinen Strom auf. Rechtsklick: Messbereich, Zeitbasis, löschen.');
end;

procedure TjanScoop.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Tr(FTaal, 'Oscilloscoop', 'Oscilloscope', 'Oscilloscope', 'Oszilloskop') + ' > ', 0);
  FOnStatus(Self, 'U = ' + VoltText(Spanning), 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;
