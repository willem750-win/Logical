// janSimLogic.pas, deel: stappenteller, stopwatch, flipflop, eindschakelaar (ingevoegd met {$I jsl_stappen_flipflop.inc})
// ============================================================
// TjanSimEindschakelaar: eindschakelaar in de invoer, volgt de persoon of
// het wagentje zonder draad
// ============================================================

const
  ES_W = 60;            // breedte van het blok
  ES_H = 36;            // hoogte van het blok

constructor TjanSimEindschakelaar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := ES_W;
  Height := ES_H;
  Connectors := TList.Create;
  FTimer := TTimer.Create(Self);
  FTimer.Interval := 100;
  FTimer.OnTimer := TimerTick;
  FTaal := 'NL';
  FNaam := 'Eindschakelaar';
  FGezien := -1;
  HelpKeyword := 'eindschakelaar';
  ShowHint := True;
end;

destructor TjanSimEindschakelaar.Destroy;
begin
  FTimer.Enabled := False;
  Connectors.Free;
  inherited;
end;

class function TjanSimEindschakelaar.PinY: Integer;
begin
  Result := 18;
end;

function TjanSimEindschakelaar.OutputPinAt(const P: TPoint): Boolean;
begin
  Result := (P.X >= Left + Width - 18) and (P.X <= Left + Width + 8) and
            (Abs(P.Y - (Top + PinY + 3)) <= 6);
end;

function TjanSimEindschakelaar.Bron: TjanSimPersoon;
var
  i: Integer;
begin
  Result := nil;
  if Parent = nil then Exit;
  for i := 0 to Parent.ControlCount - 1 do
    if (Parent.Controls[i] is TjanSimPersoon) and (TjanSimPersoon(Parent.Controls[i]).OutputCount > 0) then
      Exit(TjanSimPersoon(Parent.Controls[i]));
end;

function TjanSimEindschakelaar.KanaalNaam: string;
var
  B: TjanSimPersoon;
begin
  B := Bron;
  if B <> nil then
    Result := B.OutputName(FKanaal)
  else
    Result := 'S' + IntToStr(FKanaal + 1);
end;

function TjanSimEindschakelaar.Aan: Boolean;
var
  B: TjanSimPersoon;
begin
  B := Bron;
  Result := (B <> nil) and (FKanaal < B.OutputCount) and B.Outputs[FKanaal];
end;

function TjanSimEindschakelaar.SimUitgang: Boolean;
var
  B: TjanSimPersoon;
  T: Integer;
begin
  B := Bron;
  if B = nil then Exit(False);
  T := B.PulsTeller(FKanaal);
  if T < 0 then Exit(Aan);          // gewone stand (S1, S2, Start, Finish)
  if FRonde = SimRonde then Exit(FUit);   // al bepaald in deze ronde
  FRonde := SimRonde;
  if (FGezien < 0) or (FGezien > T) then FGezien := T;
  if FUit then
  begin
    if not Aan then FUit := False;   // na minstens een ronde aan: weer uit
  end
  else if FGezien < T then
  begin
    FUit := True;                    // een (eventueel gemiste) puls doorgeven
    Inc(FGezien);
  end;
  Result := FUit;
end;

procedure TjanSimEindschakelaar.SetKanaal(Value: Integer);
begin
  if Value < 0 then Value := 0;
  if Value > 4 then Value := 4;
  FKanaal := Value;
  Invalidate;
end;

procedure TjanSimEindschakelaar.SetTaal(const Value: string);
begin
  FTaal := Value;
  UpdateHintText;
  if FMouseOver then
    SendStatusToBar;
end;

// de persoon of het wagentje beweegt op zijn eigen timer: alleen opnieuw
// tekenen als de stand verandert
procedure TjanSimEindschakelaar.TimerTick(Sender: TObject);
begin
  if Aan <> FGetekend then
  begin
    Invalidate;
    if FMouseOver then
      SendStatusToBar;
  end;
end;

procedure TjanSimEindschakelaar.Paint;
var
  BW, BH, Y: Integer;
  Dicht: Boolean;
begin
  BW := Self.Width;
  BH := Self.Height;
  Dicht := Aan;
  FGetekend := Dicht;
  Y := PinY + 3;   // hoogte van de schakelaar en van de uitgang
  with Canvas do
  begin
    Font.Name := 'Arial';
    Font.Size := 7;
    Font.Style := [fsBold];
    Pen.Width := 1;
    // twee aansluitpunten; rechts naar de uitgang
    if Dicht then Pen.Color := clRed else Pen.Color := clGray;
    Line(4, Y, 9, Y);
    Line(36, Y, BW - 8, Y);
    Brush.Style := bsSolid;
    Brush.Color := clWhite;
    Pen.Color := clBlack;
    Ellipse(8, Y - 2, 13, Y + 3);
    Ellipse(33, Y - 2, 38, Y + 3);
    // hefboom met rolletje: dicht (ingedrukt) of open
    Pen.Width := 2;
    if Dicht then
    begin
      Pen.Color := clRed;
      Line(11, Y - 2, 35, Y - 2);
      Pen.Width := 1;
      Brush.Color := clRed;
      Ellipse(31, Y - 10, 39, Y - 2);
    end
    else
    begin
      Pen.Color := clNavy;
      Line(11, Y - 1, 33, Y - 11);
      Pen.Width := 1;
      Brush.Color := clSilver;
      Ellipse(30, Y - 18, 38, Y - 10);
    end;
    // uitgang
    Pen.Width := 1;
    Pen.Color := clGray;
    Brush.Color := clLime;
    Rectangle(BW - 8, PinY, BW - 1, PinY + 7);
    // naam van de stand (S1, Start...) onderaan; ? als er geen bron is
    Brush.Style := bsClear;
    if Bron = nil then
    begin
      Font.Color := clRed;
      TextOut(14, Y + 3, '?');
    end
    else
    begin
      if Dicht then Font.Color := clRed else Font.Color := clNavy;
      TextOut(14, Y + 3, KanaalNaam);
    end;
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

function TjanSimEindschakelaar.StatusText: string;
begin
  if Bron = nil then
    Result := Tr(FTaal, 'geen persoon of wagentje op het paneel', 'no person or cart on the panel',
                        'pas de personne ni de chariot sur le panneau', 'keine Person und kein Wagen auf dem Panel')
  else if Aan then
    Result := KanaalNaam + Tr(FTaal, ': aan', ': on', ' : actif', ': ein')
  else
    Result := KanaalNaam + Tr(FTaal, ': uit', ': off', ' : inactif', ': aus');
end;

procedure TjanSimEindschakelaar.UpdateHintText;
begin
  Hint := BuildSimHint(FNaam, FTaal) + #13#10 +
    Tr(FTaal, 'Volgt de persoon of het wagentje (zonder draad).' + #13#10 + 'Rechtsklik: S1, S2 of Start, Tel, Finish kiezen',
              'Follows the person or the cart (without a wire).' + #13#10 + 'Right-click: choose S1, S2 or Start, Tel, Finish',
              'Suit la personne ou le chariot (sans fil).' + #13#10 + 'Clic droit : choisir S1, S2 ou Start, Tel, Finish',
              'Folgt der Person oder dem Wagen (ohne Draht).' + #13#10 + 'Rechtsklick: S1, S2 oder Start, Tel, Finish wählen');
end;

procedure TjanSimEindschakelaar.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, FNaam + ' > ', 0);
  FOnStatus(Self, StatusText, 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

procedure TjanSimEindschakelaar.CMMouseEnter(var Msg: TMessage);
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

procedure TjanSimEindschakelaar.CMMouseLeave(var Msg: TMessage);
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

procedure TjanSimEindschakelaar.BuildPopup;
var
  Mi: TMenuItem;
  B: TjanSimPersoon;
  i, n: Integer;
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
  Mi.Caption := '-';
  PopupMenu.Items.Add(Mi);
  // welke stand: S1/S2 bij de persoon, Start/Tel/Finish bij het wagentje
  B := Bron;
  if B <> nil then n := B.OutputCount else n := 2;
  for i := 0 to n - 1 do
  begin
    Mi := TMenuItem.Create(PopupMenu);
    if B <> nil then Mi.Caption := B.OutputName(i) else Mi.Caption := 'S' + IntToStr(i + 1);
    Mi.Tag := i;
    Mi.RadioItem := True;
    Mi.Checked := i = FKanaal;
    Mi.OnClick := KanaalClick;
    PopupMenu.Items.Add(Mi);
  end;
end;

procedure TjanSimEindschakelaar.LockClick(Sender: TObject);
begin
  FLock := not FLock;
  Invalidate;
end;

procedure TjanSimEindschakelaar.SelectClick(Sender: TObject);
begin
  if Assigned(FBox) then
    FBox.SelectObject(Self);
end;

procedure TjanSimEindschakelaar.KanaalClick(Sender: TObject);
begin
  Kanaal := TMenuItem(Sender).Tag;
  if FMouseOver then
    SendStatusToBar;
end;

procedure TjanSimEindschakelaar.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
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

  // met de knop Verbinding: een draad beginnen op de uitgang
  if (Button = mbLeft) and (Screen.Cursor = crDraad) and (Parent <> nil) and
     OutputPinAt(Point(Left + X, Top + Y)) then
  begin
    Maakdraad(Top + PinY + 3 - 4, Left + Width - 5 - 4, Parent);
    movecursor;
    BringToFront;
    Exit;
  end;

  Screen.Cursor := crDefault;
  if Button <> mbLeft then Exit;
  doMove := True;
  AnchorConnectors;
  if Parent is TjanGridS then
    TjanGridS(Parent).BeginGuideLines(Left + Width div 2, Top + Height div 2);
end;

procedure TjanSimEindschakelaar.MouseMove(Shift: TShiftState; X, Y: Integer);
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

procedure TjanSimEindschakelaar.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Parent is TjanGridS then
    TjanGridS(Parent).EndGuideLines;
  doMove := False;
  if Assigned(Parent) then
    Parent.Invalidate;   // stekker en bolletje van de voedingsrail
end;

procedure TjanSimEindschakelaar.AnchorConnectors;
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

procedure TjanSimEindschakelaar.MoveConnectors;
var
  i: Integer;
begin
  for i := 0 to Connectors.Count - 1 do
    TjanConnector(Connectors[i]).MoveConnector(Point(NewLeft, NewTop));
end;


// ============================================================
// TjanSimStappenteller: decimale teller met display (0 tot 9999)
// ============================================================

const
  ST_W = 140;           // breedte van het blok
  ST_H = 64;            // hoogte van het blok
  ST_DX = 24;           // display: links, boven, breedte van een cijfer
  ST_DY = 8;
  ST_CW = 23;
  ST_SW = 16;           // segmentcijfer: breedte, hoogte, dikte (zoals het display)
  ST_SH = 28;
  ST_ST = 4;
  // segmenten a..g (bit 0 = a) van de cijfers 0 tot 9
  ST_SEG: array[0..9] of Byte = ($3F, $06, $5B, $4F, $66, $6D, $7D, $07, $7F, $6F);

constructor TjanSimStappenteller.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := ST_W;
  Height := ST_H;
  Connectors := TList.Create;
  FEind := 1000;
  FTaal := 'NL';
  FNaam := 'Stappenteller';
  HelpKeyword := 'stappenteller';
  ShowHint := True;
end;

destructor TjanSimStappenteller.Destroy;
begin
  Connectors.Free;
  inherited;
end;

class function TjanSimStappenteller.InputPinY(I: Integer): Integer;
begin
  if I = 0 then Result := 10 else Result := 46;
end;

class function TjanSimStappenteller.OutputPinY: Integer;
begin
  Result := 28;
end;

function TjanSimStappenteller.InputPinAt(const P: TPoint): Integer;
var
  i: Integer;
begin
  Result := -1;
  if (P.X < Left - 8) or (P.X > Left + 18) then Exit;
  for i := 0 to 1 do
    if Abs(P.Y - (Top + InputPinY(i) + 3)) <= 10 then
      Exit(i);
end;

function TjanSimStappenteller.OutputPinAt(const P: TPoint): Boolean;
begin
  Result := (P.X >= Left + Width - 18) and (P.X <= Left + Width + 8) and
            (Abs(P.Y - (Top + OutputPinY + 3)) <= 10);
end;

function TjanSimStappenteller.OutValueAt(const P: TPoint; out V: Boolean): Boolean;
begin
  Result := OutputPinAt(P);
  V := Result and Bereikt;
end;

function TjanSimStappenteller.OutPinYAt(const P: TPoint): Integer;
begin
  if OutputPinAt(P) then Result := OutputPinY else Result := -1;
end;

function TjanSimStappenteller.Bereikt: Boolean;
begin
  Result := FStand >= FEind;
end;

procedure TjanSimStappenteller.SetInput(I: Integer; Value: Boolean);
begin
  if (I < 0) or (I > 1) or (FIn[I] = Value) then Exit;
  FIn[I] := Value;
  if Value then
  begin
    if I = 1 then
    begin
      FResetRonde := SimRonde;
      FStand := 0;
    end
    // reset gaat voor: een telpuls terwijl R aan is (of in dezelfde ronde) telt niet
    else if not FIn[1] and not ((SimRonde <> 0) and (FResetRonde = SimRonde)) then
    begin
      if FStand < FEind then
        Inc(FStand)
      else if FHerhalen then
        FStand := 1;
    end;
  end;
  Invalidate;
  if FMouseOver then
    SendStatusToBar;
end;

procedure TjanSimStappenteller.SetEind(Value: Integer);
begin
  if Value < 1 then Value := 1;
  if Value > 9999 then Value := 9999;
  FEind := Value;
  if FStand > FEind then FStand := FEind;
  UpdateHintText;
  Invalidate;
end;

procedure TjanSimStappenteller.SetHerhalen(Value: Boolean);
begin
  FHerhalen := Value;
  UpdateHintText;
  Invalidate;
end;

procedure TjanSimStappenteller.SetTaal(const Value: string);
begin
  FTaal := Value;
  UpdateHintText;
  if FMouseOver then
    SendStatusToBar;
end;

procedure TjanSimStappenteller.Paint;
var
  BW, BH, i, y, d, n, x0, y0, h2, sh, HorLen, VerLen: Integer;
  Seg: Byte;
  Body: TRect;
  S: string;

  // zeshoekig segment zoals bij TjanDisplay: blauw aan, crème met grijze rand uit
  procedure Segment(Nr, x, y, w, h: Integer);
  begin
    if Seg and (1 shl Nr) <> 0 then
    begin
      Canvas.Brush.Color := clBlue;
      Canvas.Pen.Color := clAqua;
    end
    else
    begin
      Canvas.Brush.Color := clCream;
      Canvas.Pen.Color := clGray;
    end;
    if h > w then   // verticaal
      Canvas.Polygon([Point(x, y + sh), Point(x + sh, y), Point(x + w, y + sh),
                      Point(x + w, y + h - sh), Point(x + sh, y + h), Point(x, y + h - sh)])
    else            // horizontaal
      Canvas.Polygon([Point(x, y + sh), Point(x + sh, y), Point(x + w - sh, y),
                      Point(x + w, y + sh), Point(x + w - sh, y + h), Point(x + sh, y + h)]);
  end;

begin
  BW := Self.Width;
  BH := Self.Height;
  with Canvas do
  begin
    Pen.Width := 1;
    // aansluitdraden naar het blok
    Pen.Color := clBlack;
    for i := 0 to 1 do
    begin
      y := InputPinY(i) + 3;
      Line(8, y, 12, y);
    end;
    y := OutputPinY + 3;
    Line(BW - 12, y, BW - 8, y);
    // blok
    Body := Rect(12, 0, BW - 12, BH);
    Brush.Style := bsSolid;
    Brush.Color := clCream;
    Pen.Color := clGray;
    Rectangle(Body);
    // display: 4 cijfers zoals het display; voorloopnullen gedoofd
    n := FStand;
    h2 := ST_SH div 2;
    sh := ST_ST div 2;
    HorLen := ST_SW - ST_ST;
    VerLen := h2 - ST_ST - sh;
    for d := 3 downto 0 do
    begin
      if (n > 0) or (d = 3) then Seg := ST_SEG[n mod 10] else Seg := 0;
      n := n div 10;
      x0 := ST_DX + d * ST_CW + 2;
      y0 := ST_DY;
      Segment(0, x0 + sh, y0, HorLen, ST_ST);                              // a boven
      Segment(1, x0 + ST_SW - ST_ST, y0 + ST_ST, ST_ST, VerLen);           // b rechtsboven
      Segment(2, x0 + ST_SW - ST_ST, y0 + h2 + sh, ST_ST, VerLen);         // c rechtsonder
      Segment(3, x0 + sh, y0 + ST_SH - ST_ST, HorLen, ST_ST);              // d onder
      Segment(4, x0, y0 + h2 + sh, ST_ST, VerLen);                         // e linksonder
      Segment(5, x0, y0 + ST_ST, ST_ST, VerLen);                           // f linksboven
      Segment(6, x0 + sh, y0 + h2 - sh, HorLen, ST_ST);                    // g midden
    end;
    // aansluitingen
    Brush.Color := clLime;
    Pen.Color := clGray;
    for i := 0 to 1 do
      Rectangle(1, InputPinY(i), 8, InputPinY(i) + 7);
    Rectangle(BW - 8, OutputPinY, BW - 1, OutputPinY + 7);
    // letters en de eindwaarde onderaan
    Brush.Style := bsClear;
    Font.Name := 'Arial';
    Font.Size := 7;
    Font.Style := [fsBold];
    if FIn[0] then Font.Color := clRed else Font.Color := clNavy;
    TextOut(14, InputPinY(0) - 2, 'T');
    if FIn[1] then Font.Color := clRed else Font.Color := clNavy;
    TextOut(14, InputPinY(1) - 2, 'R');
    if Bereikt then Font.Color := clRed else Font.Color := clNavy;
    TextOut(BW - 22, OutputPinY - 2, 'Q');
    Font.Style := [];
    Font.Color := clBlack;
    if FHerhalen then
      S := '1..' + IntToStr(FEind) + '  ' + Tr(FTaal, 'herhalen', 'repeat', 'répéter', 'wiederh.')
    else
      S := Tr(FTaal, 'tot ', 'to ', 'jusqu''à ', 'bis ') + IntToStr(FEind);
    TextOut(ST_DX + 4, ST_DY + ST_SH + 8, S);   // rechts van de letter R
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

function TjanSimStappenteller.StatusText: string;
begin
  Result := Tr(FTaal, 'stand ', 'count ', 'valeur ', 'Stand ') + IntToStr(FStand) +
            Tr(FTaal, ' van ', ' of ', ' sur ', ' von ') + IntToStr(FEind);
  if Bereikt then
    Result := Result + Tr(FTaal, ': bereikt (Q aan)', ': reached (Q on)',
                                 ' : atteinte (Q actif)', ': erreicht (Q ein)');
end;

procedure TjanSimStappenteller.UpdateHintText;
begin
  Hint := BuildSimHint(FNaam, FTaal) + #13#10 +
    Tr(FTaal, 'T: +1 per puls, R: terug naar 0' + #13#10 + 'Q: aan als de eindwaarde bereikt is' + #13#10 + 'Rechtsklik: eindwaarde kiezen',
              'T: +1 per pulse, R: back to 0' + #13#10 + 'Q: on when the end value is reached' + #13#10 + 'Right-click: choose the end value',
              'T : +1 par impulsion, R : retour à 0' + #13#10 + 'Q : actif quand la valeur finale est atteinte' + #13#10 + 'Clic droit : choisir la valeur finale',
              'T: +1 pro Impuls, R: zurück auf 0' + #13#10 + 'Q: ein, wenn der Endwert erreicht ist' + #13#10 + 'Rechtsklick: Endwert wählen');
end;

procedure TjanSimStappenteller.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, FNaam + ' > ', 0);
  FOnStatus(Self, StatusText, 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

procedure TjanSimStappenteller.CMMouseEnter(var Msg: TMessage);
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

procedure TjanSimStappenteller.CMMouseLeave(var Msg: TMessage);
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

procedure TjanSimStappenteller.BuildPopup;
const
  Waarden: array[0..3] of Integer = (10, 100, 1000, 9999);
var
  Mi: TMenuItem;
  i: Integer;
  Vast: Boolean;
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
  Mi.Caption := '-';
  PopupMenu.Items.Add(Mi);
  // eindwaarde: vaste keuzes of zelf ingeven
  Vast := False;
  for i := 0 to High(Waarden) do
  begin
    Mi := TMenuItem.Create(PopupMenu);
    Mi.Caption := Tr(FTaal, 'Tot ', 'To ', 'Jusqu''à ', 'Bis ') + IntToStr(Waarden[i]);
    Mi.Tag := Waarden[i];
    Mi.RadioItem := True;
    Mi.Checked := FEind = Waarden[i];
    Vast := Vast or Mi.Checked;
    Mi.OnClick := EindClick;
    PopupMenu.Items.Add(Mi);
  end;
  Mi := TMenuItem.Create(PopupMenu);
  Mi.Caption := Tr(FTaal, 'Andere eindwaarde...', 'Other end value...', 'Autre valeur finale...', 'Anderer Endwert...');
  Mi.RadioItem := True;
  Mi.Checked := not Vast;
  Mi.OnClick := EindAnderClick;
  PopupMenu.Items.Add(Mi);
  Mi := TMenuItem.Create(PopupMenu);
  Mi.Caption := '-';
  PopupMenu.Items.Add(Mi);
  Mi := TMenuItem.Create(PopupMenu);
  Mi.Caption := Tr(FTaal, 'Herhalen (na de eindwaarde weer bij 1)', 'Repeat (start again at 1 after the end value)',
                          'Répéter (recommencer à 1 après la valeur finale)', 'Wiederholen (nach dem Endwert wieder bei 1)');
  Mi.Checked := FHerhalen;
  Mi.OnClick := HerhalenClick;
  PopupMenu.Items.Add(Mi);
  Mi := TMenuItem.Create(PopupMenu);
  Mi.Caption := Tr(FTaal, 'Op 0 zetten', 'Set to 0', 'Mettre à 0', 'Auf 0 setzen');
  Mi.OnClick := NulClick;
  PopupMenu.Items.Add(Mi);
end;

procedure TjanSimStappenteller.LockClick(Sender: TObject);
begin
  FLock := not FLock;
  Invalidate;
end;

procedure TjanSimStappenteller.SelectClick(Sender: TObject);
begin
  if Assigned(FBox) then
    FBox.SelectObject(Self);
end;

procedure TjanSimStappenteller.EindClick(Sender: TObject);
begin
  Eindwaarde := TMenuItem(Sender).Tag;
  if FMouseOver then
    SendStatusToBar;
end;

procedure TjanSimStappenteller.EindAnderClick(Sender: TObject);
var
  dlg: TInputBoxForm;
  s: string;
  v: Integer;
begin
  dlg := TInputBoxForm.Create(nil);
  try
    if dlg.Execute(Tr(FTaal, 'Eindwaarde', 'End value', 'Valeur finale', 'Endwert'),
                   Tr(FTaal, 'Tot hoeveel tellen (1 tot 9999)?', 'Count up to (1 to 9999)?',
                             'Compter jusqu''à (1 à 9999) ?', 'Bis wie viel zählen (1 bis 9999)?'),
                   IntToStr(FEind), s) then
      if TryStrToInt(Trim(s), v) then
        Eindwaarde := v;
  finally
    dlg.Free;
  end;
end;

procedure TjanSimStappenteller.HerhalenClick(Sender: TObject);
begin
  Herhalen := not FHerhalen;
end;

procedure TjanSimStappenteller.NulClick(Sender: TObject);
begin
  FStand := 0;
  Invalidate;
  if FMouseOver then
    SendStatusToBar;
end;

procedure TjanSimStappenteller.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
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

  // met de knop Verbinding: een draad beginnen op de uitgang Q
  if (Button = mbLeft) and (Screen.Cursor = crDraad) and (Parent <> nil) and
     (OutPinYAt(Point(Left + X, Top + Y)) >= 0) then
  begin
    Maakdraad(Top + OutPinYAt(Point(Left + X, Top + Y)) + 3 - 4, Left + Width - 5 - 4, Parent);
    movecursor;
    BringToFront;
    Exit;
  end;

  Screen.Cursor := crDefault;
  if Button <> mbLeft then Exit;
  doMove := True;
  AnchorConnectors;
  if Parent is TjanGridS then
    TjanGridS(Parent).BeginGuideLines(Left + Width div 2, Top + Height div 2);
end;

procedure TjanSimStappenteller.MouseMove(Shift: TShiftState; X, Y: Integer);
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
  Left := NewLeft;
  Top := NewTop;
  MoveConnectors;
  if Parent is TjanGridS then
    TjanGridS(Parent).UpdateGuideLines(Left + Width div 2, Top + Height div 2);
  FMouseOver := True;
  SendStatusToBar;
end;

procedure TjanSimStappenteller.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Parent is TjanGridS then
    TjanGridS(Parent).EndGuideLines;
  doMove := False;
end;

procedure TjanSimStappenteller.AnchorConnectors;
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

procedure TjanSimStappenteller.MoveConnectors;
var
  i: Integer;
begin
  for i := 0 to Connectors.Count - 1 do
    TjanConnector(Connectors[i]).MoveConnector(Point(NewLeft, NewTop));
end;


// ============================================================
// TjanSimStopwatch: stopwatch met display MM:SS (tot 99:59)
// ============================================================

const
  SW_MAX = 5999;        // 99:59
  SW_KOLOM = 8;         // ruimte voor de dubbelpunt tussen minuten en seconden

// seconden als MM:SS
function MinSec(Sec: Integer): string;
begin
  Result := Format('%.2d:%.2d', [Sec div 60, Sec mod 60]);
end;

constructor TjanSimStopwatch.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FEind := 30;
  FNaam := 'Stopwatch';
  HelpKeyword := 'stopwatch';
  FLaatst := GetTickCount64;
  FTimer := TTimer.Create(Self);
  FTimer.Interval := 100;
  FTimer.OnTimer := TimerTick;
  FTimer.Enabled := not (csDesigning in ComponentState);
end;

procedure TjanSimStopwatch.TimerTick(Sender: TObject);
var
  Nu: QWord;
  D: Int64;
  OudeStand, OudeFase: Integer;
begin
  Nu := GetTickCount64;
  D := Nu - FLaatst;
  FLaatst := Nu;
  if D > 1000 then D := 1000;       // na een pauze van het programma
  // de tijd loopt zolang S aan is (en R uit)
  if not FIn[0] or FIn[1] then Exit;
  if (FStand >= FEind) and not FHerhalen then Exit;
  OudeStand := FStand;
  OudeFase := (FMs div 500) mod 2;
  Inc(FMs, D);
  if FHerhalen then
  begin
    // na de eindtijd (Q een seconde aan) weer bij 00:01
    if FMs >= Int64(FEind + 1) * 1000 then
      Dec(FMs, Int64(FEind) * 1000);
  end
  else if FMs > Int64(FEind) * 1000 then
    FMs := Int64(FEind) * 1000;
  FStand := FMs div 1000;
  if (FStand <> OudeStand) or ((FMs div 500) mod 2 <> OudeFase) then
  begin
    Invalidate;
    if FMouseOver and (FStand <> OudeStand) then
      SendStatusToBar;
  end;
end;

procedure TjanSimStopwatch.SetInput(I: Integer; Value: Boolean);
begin
  if (I < 0) or (I > 1) or (FIn[I] = Value) then Exit;
  FIn[I] := Value;
  FLaatst := GetTickCount64;
  if (I = 1) and Value then
  begin
    FMs := 0;
    FStand := 0;
  end;
  Invalidate;
  if FMouseOver then
    SendStatusToBar;
end;

procedure TjanSimStopwatch.Paint;
var
  BW, BH, i, y, d, x0, y0, h2, sh, HorLen, VerLen, Kx: Integer;
  Seg: Byte;
  Body: TRect;
  S: string;
  Cijfer: array[0..3] of Integer;
  Loopt: Boolean;

  // zeshoekig segment zoals bij de stappenteller
  procedure Segment(Nr, x, y, w, h: Integer);
  begin
    if Seg and (1 shl Nr) <> 0 then
    begin
      Canvas.Brush.Color := clBlue;
      Canvas.Pen.Color := clAqua;
    end
    else
    begin
      Canvas.Brush.Color := clCream;
      Canvas.Pen.Color := clGray;
    end;
    if h > w then   // verticaal
      Canvas.Polygon([Point(x, y + sh), Point(x + sh, y), Point(x + w, y + sh),
                      Point(x + w, y + h - sh), Point(x + sh, y + h), Point(x, y + h - sh)])
    else            // horizontaal
      Canvas.Polygon([Point(x, y + sh), Point(x + sh, y), Point(x + w - sh, y),
                      Point(x + w, y + sh), Point(x + w - sh, y + h), Point(x + sh, y + h)]);
  end;

begin
  BW := Self.Width;
  BH := Self.Height;
  Loopt := FIn[0] and not FIn[1] and ((FStand < FEind) or FHerhalen);
  with Canvas do
  begin
    Pen.Width := 1;
    // aansluitdraden naar het blok
    Pen.Color := clBlack;
    for i := 0 to 1 do
    begin
      y := InputPinY(i) + 3;
      Line(8, y, 12, y);
    end;
    y := OutputPinY + 3;
    Line(BW - 12, y, BW - 8, y);
    // blok
    Body := Rect(12, 0, BW - 12, BH);
    Brush.Style := bsSolid;
    Brush.Color := clCream;
    Pen.Color := clGray;
    Rectangle(Body);
    // display MM:SS
    Cijfer[0] := (FStand div 60) div 10;
    Cijfer[1] := (FStand div 60) mod 10;
    Cijfer[2] := (FStand mod 60) div 10;
    Cijfer[3] := (FStand mod 60) mod 10;
    h2 := ST_SH div 2;
    sh := ST_ST div 2;
    HorLen := ST_SW - ST_ST;
    VerLen := h2 - ST_ST - sh;
    for d := 0 to 3 do
    begin
      Seg := ST_SEG[Cijfer[d]];
      x0 := ST_DX + d * ST_CW + 2;
      if d >= 2 then Inc(x0, SW_KOLOM);
      y0 := ST_DY;
      Segment(0, x0 + sh, y0, HorLen, ST_ST);                              // a boven
      Segment(1, x0 + ST_SW - ST_ST, y0 + ST_ST, ST_ST, VerLen);           // b rechtsboven
      Segment(2, x0 + ST_SW - ST_ST, y0 + h2 + sh, ST_ST, VerLen);         // c rechtsonder
      Segment(3, x0 + sh, y0 + ST_SH - ST_ST, HorLen, ST_ST);              // d onder
      Segment(4, x0, y0 + h2 + sh, ST_ST, VerLen);                         // e linksonder
      Segment(5, x0, y0 + ST_ST, ST_ST, VerLen);                           // f linksboven
      Segment(6, x0 + sh, y0 + h2 - sh, HorLen, ST_ST);                    // g midden
    end;
    // dubbelpunt: knippert zolang de tijd loopt
    Kx := ST_DX + 2 * ST_CW + 2 - 3;
    if Loopt and ((FMs div 500) mod 2 = 1) then
    begin
      Brush.Color := clCream;
      Pen.Color := clGray;
    end
    else
    begin
      Brush.Color := clBlue;
      Pen.Color := clAqua;
    end;
    Rectangle(Kx, ST_DY + 7, Kx + 4, ST_DY + 11);
    Rectangle(Kx, ST_DY + ST_SH - 11, Kx + 4, ST_DY + ST_SH - 7);
    // aansluitingen
    Brush.Color := clLime;
    Pen.Color := clGray;
    for i := 0 to 1 do
      Rectangle(1, InputPinY(i), 8, InputPinY(i) + 7);
    Rectangle(BW - 8, OutputPinY, BW - 1, OutputPinY + 7);
    // letters en de eindtijd onderaan
    Brush.Style := bsClear;
    Font.Name := 'Arial';
    Font.Size := 7;
    Font.Style := [fsBold];
    if FIn[0] then Font.Color := clRed else Font.Color := clNavy;
    TextOut(14, InputPinY(0) - 2, 'S');
    if FIn[1] then Font.Color := clRed else Font.Color := clNavy;
    TextOut(14, InputPinY(1) - 2, 'R');
    if Bereikt then Font.Color := clRed else Font.Color := clNavy;
    TextOut(BW - 22, OutputPinY - 2, 'Q');
    Font.Style := [];
    Font.Color := clBlack;
    if FHerhalen then
      S := MinSec(1) + '..' + MinSec(FEind) + ' ' + Tr(FTaal, 'herhalen', 'repeat', 'répéter', 'wiederh.')
    else
      S := Tr(FTaal, 'tot ', 'to ', 'jusqu''à ', 'bis ') + MinSec(FEind);
    TextOut(ST_DX + 4, ST_DY + ST_SH + 8, S);   // rechts van de letter R
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

function TjanSimStopwatch.StatusText: string;
begin
  Result := Tr(FTaal, 'tijd ', 'time ', 'temps ', 'Zeit ') + MinSec(FStand) +
            Tr(FTaal, ' van ', ' of ', ' sur ', ' von ') + MinSec(FEind);
  if Bereikt then
    Result := Result + Tr(FTaal, ': bereikt (Q aan)', ': reached (Q on)',
                                 ' : atteint (Q actif)', ': erreicht (Q ein)');
end;

procedure TjanSimStopwatch.UpdateHintText;
begin
  Hint := BuildSimHint(FNaam, FTaal) + #13#10 +
    Tr(FTaal, 'S: de tijd loopt zolang S aan is, R: terug naar 00:00' + #13#10 + 'Q: aan als de eindtijd bereikt is' + #13#10 + 'Rechtsklik: eindtijd kiezen',
              'S: time runs while S is on, R: back to 00:00' + #13#10 + 'Q: on when the end time is reached' + #13#10 + 'Right-click: choose the end time',
              'S : le temps court tant que S est actif, R : retour à 00:00' + #13#10 + 'Q : actif quand l''heure de fin est atteinte' + #13#10 + 'Clic droit : choisir l''heure de fin',
              'S: die Zeit läuft, solange S ein ist, R: zurück auf 00:00' + #13#10 + 'Q: ein, wenn die Endzeit erreicht ist' + #13#10 + 'Rechtsklick: Endzeit wählen');
end;

procedure TjanSimStopwatch.BuildPopup;
const
  Waarden: array[0..4] of Integer = (10, 30, 60, 300, 600);
var
  Mi: TMenuItem;
  i: Integer;
  Vast: Boolean;
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
  Mi.Caption := '-';
  PopupMenu.Items.Add(Mi);
  // eindtijd: vaste keuzes of zelf ingeven
  Vast := False;
  for i := 0 to High(Waarden) do
  begin
    Mi := TMenuItem.Create(PopupMenu);
    Mi.Caption := Tr(FTaal, 'Tot ', 'To ', 'Jusqu''à ', 'Bis ') + MinSec(Waarden[i]);
    Mi.Tag := Waarden[i];
    Mi.RadioItem := True;
    Mi.Checked := FEind = Waarden[i];
    Vast := Vast or Mi.Checked;
    Mi.OnClick := EindTijdClick;
    PopupMenu.Items.Add(Mi);
  end;
  Mi := TMenuItem.Create(PopupMenu);
  Mi.Caption := Tr(FTaal, 'Andere eindtijd...', 'Other end time...', 'Autre heure de fin...', 'Andere Endzeit...');
  Mi.RadioItem := True;
  Mi.Checked := not Vast;
  Mi.OnClick := EindTijdAnderClick;
  PopupMenu.Items.Add(Mi);
  Mi := TMenuItem.Create(PopupMenu);
  Mi.Caption := '-';
  PopupMenu.Items.Add(Mi);
  Mi := TMenuItem.Create(PopupMenu);
  Mi.Caption := Tr(FTaal, 'Herhalen (na de eindtijd weer bij 00:01)', 'Repeat (start again at 00:01 after the end time)',
                          'Répéter (recommencer à 00:01 après l''heure de fin)', 'Wiederholen (nach der Endzeit wieder bei 00:01)');
  Mi.Checked := FHerhalen;
  Mi.OnClick := HerhalenClick;
  PopupMenu.Items.Add(Mi);
  Mi := TMenuItem.Create(PopupMenu);
  Mi.Caption := Tr(FTaal, 'Op 00:00 zetten', 'Set to 00:00', 'Mettre à 00:00', 'Auf 00:00 setzen');
  Mi.OnClick := NulTijdClick;
  PopupMenu.Items.Add(Mi);
end;

procedure TjanSimStopwatch.EindTijdClick(Sender: TObject);
begin
  Eindwaarde := TMenuItem(Sender).Tag;
  if FMouseOver then
    SendStatusToBar;
end;

procedure TjanSimStopwatch.EindTijdAnderClick(Sender: TObject);
var
  dlg: TInputBoxForm;
  s: string;
  p, m, sec: Integer;
begin
  dlg := TInputBoxForm.Create(nil);
  try
    if dlg.Execute(Tr(FTaal, 'Eindtijd', 'End time', 'Heure de fin', 'Endzeit'),
                   Tr(FTaal, 'Eindtijd als mm:ss (00:01 tot 99:59)?', 'End time as mm:ss (00:01 to 99:59)?',
                             'Heure de fin en mm:ss (00:01 à 99:59) ?', 'Endzeit als mm:ss (00:01 bis 99:59)?'),
                   MinSec(FEind), s) then
    begin
      s := Trim(s);
      p := Pos(':', s);
      if p > 0 then
      begin
        // mm:ss
        if TryStrToInt(Trim(Copy(s, 1, p - 1)), m) and TryStrToInt(Trim(Copy(s, p + 1, MaxInt)), sec) then
          sec := m * 60 + sec
        else
          Exit;
      end
      else if not TryStrToInt(s, sec) then   // alleen seconden
        Exit;
      if sec > SW_MAX then sec := SW_MAX;
      Eindwaarde := sec;
    end;
  finally
    dlg.Free;
  end;
end;

procedure TjanSimStopwatch.NulTijdClick(Sender: TObject);
begin
  FMs := 0;
  FStand := 0;
  Invalidate;
  if FMouseOver then
    SendStatusToBar;
end;


// ============================================================
// TjanSimFlipFlop: SR-, D-, JK- of T-flipflop
// ============================================================

const
  FF_W = 100;           // breedte van het blok
  FF_H = 64;            // hoogte van het blok

constructor TjanSimFlipFlop.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := FF_W;
  Height := FF_H;
  FEind := 1;           // soort SR
  FStartRonde := SimRonde;
  FNaam := 'Flipflop';
  HelpKeyword := 'flipflop';
end;

function TjanSimFlipFlop.GetSoort: TjanFlipFlopSoort;
begin
  case FEind of
    2: Result := ffD;
    3: Result := ffJK;
    4: Result := ffT;
  else
    Result := ffSR;
  end;
end;

procedure TjanSimFlipFlop.SetSoort(Value: TjanFlipFlopSoort);
begin
  FEind := Ord(Value) + 1;
  FIn3[0] := False; FIn3[1] := False; FIn3[2] := False;
  UpdateHintText;
  Invalidate;
end;

function TjanSimFlipFlop.InputCount: Integer;
begin
  case Soort of
    ffJK: Result := 3;
    ffT:  Result := 1;
  else
    Result := 2;
  end;
end;

function TjanSimFlipFlop.InPinY(I: Integer): Integer;
begin
  case InputCount of
    1: Result := 28;
    3: case I of 0: Result := 8; 1: Result := 28; else Result := 48; end;
  else
    if I = 0 then Result := 10 else Result := 46;
  end;
end;

function TjanSimFlipFlop.InLabel(I: Integer): string;
begin
  case Soort of
    ffSR: if I = 0 then Result := 'S' else Result := 'R';
    ffD:  if I = 0 then Result := 'D' else Result := 'C';
    ffJK: case I of 0: Result := 'J'; 1: Result := 'C'; else Result := 'K'; end;
  else
    Result := 'T';
  end;
end;

class function TjanSimFlipFlop.QPinY(I: Integer): Integer;
begin
  if I = 0 then Result := 10 else Result := 46;
end;

function TjanSimFlipFlop.InputPinAt(const P: TPoint): Integer;
var
  i: Integer;
begin
  Result := -1;
  if (P.X < Left - 8) or (P.X > Left + 18) then Exit;
  for i := 0 to InputCount - 1 do
    if Abs(P.Y - (Top + InPinY(i) + 3)) <= 8 then
      Exit(i);
end;

function TjanSimFlipFlop.OutPinYAt(const P: TPoint): Integer;
var
  i: Integer;
begin
  Result := -1;
  if (P.X < Left + Width - 18) or (P.X > Left + Width + 8) then Exit;
  for i := 0 to 1 do
    if Abs(P.Y - (Top + QPinY(i) + 3)) <= 10 then
      Exit(QPinY(i));
end;

function TjanSimFlipFlop.OutputPinAt(const P: TPoint): Boolean;
begin
  Result := OutPinYAt(P) >= 0;
end;

function TjanSimFlipFlop.OutValueAt(const P: TPoint; out V: Boolean): Boolean;
var
  Y: Integer;
begin
  Y := OutPinYAt(P);
  Result := Y >= 0;
  if Y = QPinY(0) then V := FQ else V := not FQ;
end;

function TjanSimFlipFlop.Bereikt: Boolean;
begin
  Result := FQ;
end;

procedure TjanSimFlipFlop.SetInput(I: Integer; Value: Boolean);
begin
  if (I < 0) or (I >= InputCount) or (FIn3[I] = Value) then Exit;
  FIn3[I] := Value;
  // de eerste rondes na het maken of laden komen de beginwaarden binnen
  // (bv. niet-Q = 1 van een andere flipflop): dat is geen klokflank
  if (SimRonde <= FStartRonde + 3) and (Soort <> ffSR) then
  begin
    Invalidate;
    Exit;
  end;
  case Soort of
    ffSR:
      // R gaat voor (ook als S en R samen aan zijn: verboden toestand)
      if FIn3[1] then FQ := False
      else if FIn3[0] then FQ := True;
    ffD:
      if (I = 1) and Value then FQ := FIn3[0];
    ffJK:
      if (I = 1) and Value then
      begin
        if FIn3[0] and FIn3[2] then FQ := not FQ
        else if FIn3[0] then FQ := True
        else if FIn3[2] then FQ := False;
      end;
    ffT:
      if Value then FQ := not FQ;
  end;
  Invalidate;
  if FMouseOver then
    SendStatusToBar;
end;

procedure TjanSimFlipFlop.Paint;
var
  BW, BH, i, y, x: Integer;
  S: string;
begin
  BW := Self.Width;
  BH := Self.Height;
  with Canvas do
  begin
    Pen.Width := 1;
    Pen.Color := clBlack;
    // aansluitdraden naar het blok
    for i := 0 to InputCount - 1 do
    begin
      y := InPinY(i) + 3;
      Line(8, y, 12, y);
    end;
    for i := 0 to 1 do
    begin
      y := QPinY(i) + 3;
      Line(BW - 12, y, BW - 8, y);
    end;
    // blok
    Brush.Style := bsSolid;
    Brush.Color := clCream;
    Pen.Color := clGray;
    RoundRect(12, 0, BW - 12, BH, 8, 8);
    // soort in het midden, met de stand van Q eronder
    case Soort of
      ffSR: S := 'SR';
      ffD:  S := 'D';
      ffJK: S := 'JK';
    else
      S := 'T';
    end;
    Brush.Style := bsClear;
    Font.Name := 'Arial';
    Font.Size := 11;
    Font.Style := [fsBold];
    Font.Color := clNavy;
    TextOut((BW - TextWidth(S)) div 2, 12, S);
    Font.Size := 7;
    Font.Style := [];
    Font.Color := clBlack;
    S := 'FF';
    TextOut((BW - TextWidth(S)) div 2, 32, S);
    // klokingang: driehoekje aan de binnenkant van het blok
    for i := 0 to InputCount - 1 do
      if InLabel(i) = 'C' then
      begin
        y := InPinY(i) + 3;
        Pen.Color := clBlack;
        Line(12, y - 4, 18, y);
        Line(18, y, 12, y + 4);
      end;
    // aansluitingen
    Brush.Style := bsSolid;
    Brush.Color := clLime;
    Pen.Color := clGray;
    for i := 0 to InputCount - 1 do
      Rectangle(1, InPinY(i), 8, InPinY(i) + 7);
    for i := 0 to 1 do
    begin
      if (i = 0) = FQ then Brush.Color := clRed else Brush.Color := clLime;
      Rectangle(BW - 8, QPinY(i), BW - 1, QPinY(i) + 7);
    end;
    // letters
    Brush.Style := bsClear;
    Font.Size := 7;
    Font.Style := [fsBold];
    for i := 0 to InputCount - 1 do
    begin
      if FIn3[i] then Font.Color := clRed else Font.Color := clNavy;
      if InLabel(i) = 'C' then x := 20 else x := 15;
      TextOut(x, InPinY(i) - 2, InLabel(i));
    end;
    if FQ then Font.Color := clRed else Font.Color := clNavy;
    TextOut(BW - 23, QPinY(0) - 2, 'Q');
    if FQ then Font.Color := clNavy else Font.Color := clRed;
    TextOut(BW - 23, QPinY(1) - 2, 'Q');
    // streep boven de tweede Q: niet-Q
    Pen.Color := Font.Color;
    x := BW - 23;
    Line(x, QPinY(1) - 2, x + TextWidth('Q'), QPinY(1) - 2);
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

function TjanSimFlipFlop.StatusText: string;
const
  Namen: array[TjanFlipFlopSoort] of string = ('SR', 'D', 'JK', 'T');
begin
  Result := Namen[Soort] + '-flipflop: Q = ' + IntToStr(Ord(FQ));
end;

procedure TjanSimFlipFlop.UpdateHintText;
var
  S: string;
begin
  case Soort of
    ffSR: S := Tr(FTaal, 'SR: S zet Q op 1, R zet Q op 0 (R gaat voor)', 'SR: S sets Q to 1, R resets Q to 0 (R wins)',
                 'SR : S met Q à 1, R remet Q à 0 (R l''emporte)', 'SR: S setzt Q auf 1, R setzt Q auf 0 (R hat Vorrang)');
    ffD:  S := Tr(FTaal, 'D: bij het aangaan van C neemt Q de waarde van D over', 'D: when C turns on, Q takes the value of D',
                 'D : quand C s''allume, Q prend la valeur de D', 'D: wenn C einschaltet, übernimmt Q den Wert von D');
    ffJK: S := Tr(FTaal, 'JK: bij het aangaan van C: J zet, K wist, J en K samen wisselen', 'JK: when C turns on: J sets, K resets, J and K together toggle',
                 'JK : quand C s''allume : J met à 1, K remet à 0, J et K ensemble basculent', 'JK: wenn C einschaltet: J setzt, K löscht, J und K zusammen wechseln');
  else
    S := Tr(FTaal, 'T: elke keer dat T aangaat, wisselt Q', 'T: every time T turns on, Q toggles',
           'T : à chaque fois que T s''allume, Q bascule', 'T: jedes Mal, wenn T einschaltet, wechselt Q');
  end;
  Hint := BuildSimHint(FNaam, FTaal) + #13#10 + S + #13#10 +
    Tr(FTaal, 'Rechtsklik: soort kiezen (SR, D, JK, T)', 'Right-click: choose the type (SR, D, JK, T)',
              'Clic droit : choisir le type (SR, D, JK, T)', 'Rechtsklick: Art wählen (SR, D, JK, T)');
end;

procedure TjanSimFlipFlop.BuildPopup;
const
  Namen: array[TjanFlipFlopSoort] of string = ('SR', 'D', 'JK', 'T');
var
  Mi: TMenuItem;
  k: TjanFlipFlopSoort;
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
  Mi.Caption := '-';
  PopupMenu.Items.Add(Mi);
  for k := Low(TjanFlipFlopSoort) to High(TjanFlipFlopSoort) do
  begin
    Mi := TMenuItem.Create(PopupMenu);
    Mi.Caption := Namen[k] + '-flipflop';
    Mi.Tag := Ord(k);
    Mi.RadioItem := True;
    Mi.Checked := Soort = k;
    Mi.OnClick := SoortClick;
    PopupMenu.Items.Add(Mi);
  end;
  Mi := TMenuItem.Create(PopupMenu);
  Mi.Caption := '-';
  PopupMenu.Items.Add(Mi);
  Mi := TMenuItem.Create(PopupMenu);
  Mi.Caption := Tr(FTaal, 'Q op 0 zetten', 'Set Q to 0', 'Mettre Q à 0', 'Q auf 0 setzen');
  Mi.OnClick := NulQClick;
  PopupMenu.Items.Add(Mi);
end;

procedure TjanSimFlipFlop.SoortClick(Sender: TObject);
begin
  Soort := TjanFlipFlopSoort(TMenuItem(Sender).Tag);
  if FMouseOver then
    SendStatusToBar;
end;

procedure TjanSimFlipFlop.NulQClick(Sender: TObject);
begin
  FQ := False;
  Invalidate;
  if FMouseOver then
    SendStatusToBar;
end;

