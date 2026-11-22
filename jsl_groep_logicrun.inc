// janSimLogic.pas, deel: selectie (groep) en LogicRun (ingevoegd met {$I jsl_groep_logicrun.inc})

constructor TjanGroupSelect.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TList.Create;
  FBTaal := 'NL';
  Visible := False;
  ShowHint := True;
  SetBounds(0, 0, 1, 1);
end;

destructor TjanGroupSelect.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

function TjanGroupSelect.IsGroupable(C: TControl): Boolean;
begin
  Result := (C <> Self) and C.Visible and
    ((C is TjanLogic) or (C is TjanTeller) or (C is TjanMemory) or
     (C is TjanSimButton) or (C is TjanSimKnop) or (C is TjanSimSensor) or
     (C is TjanSimWarm) or (C is TjanSimPuls) or (C is TjanDipSwitsh) or
     (C is TjanSimLight) or (C is TjanSimRelais) or (C is TjanSimBuzzer) or
     (C is TjanDisplay) or (C is TjanMeter) or (C is TjanRail) or (C is TjanLogicRun) or
     (C is TjanSimMotor) or (C is TjanSimPersoon) or (C is TjanSimEindschakelaar) or
     (C is TjanSimStappenteller) or (C is TjanVoedingsDeel));
  // vergrendelde objecten blijven staan
  if Result and IsPublishedProp(C, 'Lock') then
    Result := GetOrdProp(C, 'Lock') = 0;
end;

function TjanGroupSelect.EndInGroup(const P: TPoint): Boolean;
var
  k: Integer;
  R: TRect;
begin
  Result := False;
  for k := 0 to FItems.Count - 1 do
  begin
    R := TControl(FItems[k]).BoundsRect;
    InflateRect(R, 8, 8);   // zelfde marge als PrepareDrag
    if PtInRect(R, P) then
      Exit(True);
  end;
end;

procedure TjanGroupSelect.GetItems(L: TList);
var
  i: Integer;
begin
  for i := 0 to FItems.Count - 1 do
    L.Add(FItems[i]);
end;

procedure TjanGroupSelect.GetWires(L: TList; Beide: Boolean);
var
  j: Integer;
  C: TControl;
  Rc: TRect;
  InA, InB: Boolean;
begin
  if (Parent = nil) or (FItems.Count = 0) then Exit;
  for j := 0 to Parent.ControlCount - 1 do
  begin
    C := Parent.Controls[j];
    if not (C is TjanConnector) or not C.Visible then Continue;
    Rc := C.BoundsRect;
    if TjanConnector(C).Shape = jcsTLBR then
    begin
      InA := EndInGroup(Point(Rc.Left, Rc.Top));
      InB := EndInGroup(Point(Rc.Right, Rc.Bottom));
    end
    else
    begin
      InA := EndInGroup(Point(Rc.Right, Rc.Top));
      InB := EndInGroup(Point(Rc.Left, Rc.Bottom));
    end;
    if (Beide and InA and InB) or ((not Beide) and (InA or InB)) then
      L.Add(C);
  end;
end;

// ligt P op een rail of een bron? (ook als die niet geselecteerd is: de
// rails lopen meestal over het hele paneel en vallen dan buiten het kader)
function TjanGroupSelect.EndOnVoeding(const P: TPoint): Boolean;
var
  k: Integer;
  C: TControl;
  R: TRect;
begin
  Result := False;
  if Parent = nil then Exit;
  for k := 0 to Parent.ControlCount - 1 do
  begin
    C := Parent.Controls[k];
    if not C.Visible or not ((C is TjanRail) or (C is TjanBron)) then Continue;
    R := C.BoundsRect;
    InflateRect(R, 8, 8);
    if PtInRect(R, P) then
      Exit(True);
  end;
end;

procedure TjanGroupSelect.GetCopyWires(L: TList);
var
  j: Integer;
  C: TControl;
  Rc: TRect;
  PA, PB: TPoint;
  InA, InB: Boolean;
begin
  if (Parent = nil) or (FItems.Count = 0) then Exit;
  for j := 0 to Parent.ControlCount - 1 do
  begin
    C := Parent.Controls[j];
    if not (C is TjanConnector) or not C.Visible then Continue;
    Rc := C.BoundsRect;
    if TjanConnector(C).Shape = jcsTLBR then
    begin
      PA := Point(Rc.Left, Rc.Top);
      PB := Point(Rc.Right, Rc.Bottom);
    end
    else
    begin
      PA := Point(Rc.Right, Rc.Top);
      PB := Point(Rc.Left, Rc.Bottom);
    end;
    InA := EndInGroup(PA);
    InB := EndInGroup(PB);
    if (InA and InB) or (InA and EndOnVoeding(PB)) or (InB and EndOnVoeding(PA)) then
      L.Add(C);
  end;
end;

procedure TjanGroupSelect.SelectList(L: TList);
var
  i: Integer;
begin
  Clear;
  for i := 0 to L.Count - 1 do
    if IsGroupable(TControl(L[i])) then
    begin
      FItems.Add(L[i]);
      TComponent(L[i]).FreeNotification(Self);
    end;
  UpdateFrame;
end;

function TjanGroupSelect.Count: Integer;
begin
  Result := FItems.Count;
end;

procedure TjanGroupSelect.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and Assigned(FItems) and (FItems.IndexOf(AComponent) >= 0) then
  begin
    FItems.Remove(AComponent);
    if not FBanding then
      UpdateFrame;
  end;
end;

procedure TjanGroupSelect.Clear;
var
  i: Integer;
begin
  for i := 0 to FItems.Count - 1 do
    TComponent(FItems[i]).RemoveFreeNotification(Self);
  FItems.Clear;
  FBanding := False;
  FDragging := False;
  Visible := False;
end;

procedure TjanGroupSelect.UpdateFrame;
var
  i: Integer;
  R, U: TRect;
begin
  if FItems.Count = 0 then
  begin
    Visible := False;
    Exit;
  end;
  U := TControl(FItems[0]).BoundsRect;
  for i := 1 to FItems.Count - 1 do
  begin
    R := TControl(FItems[i]).BoundsRect;
    UnionRect(U, U, R);
  end;
  InflateRect(U, 6, 6);
  BoundsRect := U;
  // eerst vertalen, dan invullen: anders vindt LangTr (extra talen) de tekst niet
  Hint := Format(Tr(FBTaal,
    '%d objecten geselecteerd'#13#10'Sleep om ze samen te verplaatsen; Delete = verwijderen, Ctrl+C = kopiëren, Ctrl+V = plakken, Ctrl+D = dupliceren; Esc of klik ernaast om te deselecteren',
    '%d objects selected'#13#10'Drag to move them together; Delete = remove, Ctrl+C = copy, Ctrl+V = paste, Ctrl+D = duplicate; Esc or click outside to deselect',
    '%d objets sélectionnés'#13#10'Faites glisser pour les déplacer ensemble ; Suppr = supprimer, Ctrl+C = copier, Ctrl+V = coller, Ctrl+D = dupliquer ; Échap ou clic à côté pour désélectionner',
    '%d Objekte ausgewählt'#13#10'Ziehen, um sie gemeinsam zu verschieben; Entf = löschen, Strg+C = kopieren, Strg+V = einfügen, Strg+D = duplizieren; Esc oder daneben klicken zum Abwählen'), [FItems.Count]);
  Visible := True;
  BringToFront;
  Invalidate;
end;

procedure TjanGroupSelect.SelectRect(R: TRect);
var
  i: Integer;
  C: TControl;
  RC: TRect;
begin
  Clear;
  if Parent = nil then Exit;
  R := GroupNormRect(R);
  for i := 0 to Parent.ControlCount - 1 do
  begin
    C := Parent.Controls[i];
    if not IsGroupable(C) then Continue;
    RC := C.BoundsRect;
    // object moet volledig binnen de rechthoek liggen
    if (RC.Left >= R.Left) and (RC.Top >= R.Top) and
       (RC.Right <= R.Right) and (RC.Bottom <= R.Bottom) then
    begin
      FItems.Add(C);
      C.FreeNotification(Self);
    end;
  end;
  UpdateFrame;
end;

procedure TjanGroupSelect.SelectAll;
begin
  SelectRect(Rect(-MaxInt div 2, -MaxInt div 2, MaxInt div 2, MaxInt div 2));
end;

procedure TjanGroupSelect.BeginBand(X, Y: Integer);
begin
  Clear;
  FBanding := True;
  FBandStart := Point(X, Y);
  SetBounds(X, Y, 1, 1);
  Visible := True;
  BringToFront;
end;

procedure TjanGroupSelect.MoveBand(X, Y: Integer);
begin
  if not FBanding then Exit;
  BoundsRect := GroupNormRect(Rect(FBandStart.X, FBandStart.Y, X, Y));
  Invalidate;
end;

procedure TjanGroupSelect.EndBand(X, Y: Integer);
var
  R: TRect;
begin
  if not FBanding then Exit;
  FBanding := False;
  R := GroupNormRect(Rect(FBandStart.X, FBandStart.Y, X, Y));
  // gewoon klikken (geen echte rechthoek) = alleen deselecteren
  if (R.Right - R.Left < 4) and (R.Bottom - R.Top < 4) then
    Clear
  else
    SelectRect(R);
end;

procedure TjanGroupSelect.Paint;
begin
  // Alleen de rand tekenen: de objecten eronder blijven zichtbaar.
  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Width := 1;
  Canvas.Pen.Style := psDash;
  if FBanding then
    Canvas.Pen.Color := clGray
  else
    Canvas.Pen.Color := clBlue;
  Canvas.Rectangle(0, 0, Width, Height);
end;

procedure TjanGroupSelect.PrepareDrag;
var
  i, j, n: Integer;
  C: TControl;
  Con: TjanConnector;
  Rc: TRect;
  EndA, EndB: TPoint;
  ModeA, ModeB: TjanConMode;
  InA, InB: Boolean;

  function InGroup(const P: TPoint): Boolean;
  var
    k: Integer;
    R: TRect;
  begin
    Result := False;
    for k := 0 to FItems.Count - 1 do
    begin
      R := TControl(FItems[k]).BoundsRect;
      InflateRect(R, 8, 8);   // zelfde marge als AnchorConnectors
      if PtInRect(R, P) then
        Exit(True);
    end;
  end;

begin
  SetLength(FItemStart, FItems.Count);
  for i := 0 to FItems.Count - 1 do
    FItemStart[i] := Point(TControl(FItems[i]).Left, TControl(FItems[i]).Top);
  FFrameStart := Point(Left, Top);

  // draden: welke uiteinden liggen op een geselecteerd object?
  SetLength(FCons, 0);
  SetLength(FConMove, 0);
  SetLength(FConStart, 0);
  n := 0;
  for j := 0 to Parent.ControlCount - 1 do
  begin
    C := Parent.Controls[j];
    if not (C is TjanConnector) then Continue;
    Con := TjanConnector(C);
    Rc := Con.BoundsRect;
    if Con.Shape = jcsTLBR then
    begin
      EndA := Point(Rc.Left, Rc.Top);      ModeA := jcmTL;
      EndB := Point(Rc.Right, Rc.Bottom);  ModeB := jcmBR;
    end
    else
    begin
      EndA := Point(Rc.Right, Rc.Top);     ModeA := jcmTR;
      EndB := Point(Rc.Left, Rc.Bottom);   ModeB := jcmBL;
    end;
    InA := InGroup(EndA);
    InB := InGroup(EndB);
    if not (InA or InB) then Continue;

    SetLength(FCons, n + 1);
    SetLength(FConMove, n + 1);
    SetLength(FConStart, n + 1);
    FCons[n] := Con;
    FConStart[n] := Point(Con.Left, Con.Top);
    if InA and InB then
      FConMove[n] := 1                 // beide uiteinden mee: draad verschuiven
    else
    begin
      FConMove[n] := 2;                // één uiteinde mee: draad uitrekken
      // ankerpunt (0,0): MoveConnector(delta) verplaatst dan dat uiteinde
      if InA then
        Con.AnchorCorner(Point(0, 0), ModeA)
      else
        Con.AnchorCorner(Point(0, 0), ModeB);
    end;
    Inc(n);
  end;
end;

procedure TjanGroupSelect.Nudge(DX, DY: Integer);
var
  WorkR: TRect;
begin
  if (FItems.Count = 0) or FDragging or FBanding then Exit;
  PrepareDrag;
  // net als bij slepen: niet links of boven het werkgebied uit
  if Parent is TjanGridS then
  begin
    WorkR := TjanGridS(Parent).GetWorkAreaRect;
    if FFrameStart.X + DX < WorkR.Left then DX := WorkR.Left - FFrameStart.X;
    if FFrameStart.Y + DY < WorkR.Top then DY := WorkR.Top - FFrameStart.Y;
  end;
  if (DX = 0) and (DY = 0) then Exit;
  ApplyDelta(DX, DY);
  Parent.Invalidate;
end;

procedure TjanGroupSelect.BeginRailMove(ARail: TControl);
var
  i: Integer;
  C: TControl;
begin
  Clear;
  if Parent = nil then Exit;
  // de rail zelf ook: dan schuiven de draden die op de rail beginnen
  // (voedingsdraden) mee
  FItems.Add(ARail);
  ARail.FreeNotification(Self);
  for i := 0 to Parent.ControlCount - 1 do
  begin
    C := Parent.Controls[i];
    if C.Visible and (ARail is TjanRail) and RailFits(TjanRail(ARail), C, C.Left, C.Top) then
    begin
      FItems.Add(C);
      C.FreeNotification(Self);
    end;
  end;
  FRailMoving := FItems.Count > 0;
  if FRailMoving then
    PrepareDrag;   // het kader zelf blijft onzichtbaar
end;

procedure TjanGroupSelect.RailMove(DX, DY: Integer);
begin
  if FRailMoving then
    ApplyDelta(DX, DY);   // DX/DY t.o.v. het begin van het slepen
end;

procedure TjanGroupSelect.EndRailMove;
begin
  FRailMoving := False;
  Clear;
end;

procedure TjanGroupSelect.ApplyDelta(DX, DY: Integer);
var
  i: Integer;
begin
  for i := 0 to FItems.Count - 1 do
    if i <= High(FItemStart) then
      TControl(FItems[i]).SetBounds(FItemStart[i].X + DX, FItemStart[i].Y + DY,
        TControl(FItems[i]).Width, TControl(FItems[i]).Height);
  for i := 0 to High(FCons) do
    if FConMove[i] = 1 then
      FCons[i].SetBounds(FConStart[i].X + DX, FConStart[i].Y + DY,
        FCons[i].Width, FCons[i].Height)
    else
      FCons[i].MoveConnector(Point(DX, DY));
  SetBounds(FFrameStart.X + DX, FFrameStart.Y + DY, Width, Height);
end;

procedure TjanGroupSelect.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if FBanding then Exit;
  if Button = mbRight then
  begin
    Clear;
    Exit;
  end;
  if (Button = mbLeft) and (FItems.Count > 0) then
  begin
    FDragStart := Parent.ScreenToClient(ClientToScreen(Point(X, Y)));
    PrepareDrag;
    FDragging := True;
  end;
end;

procedure TjanGroupSelect.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  P, C0, Snapped: TPoint;
  DX, DY, i, NL: Integer;
  WorkR: TRect;
  Ref: TControl;
begin
  inherited MouseMove(Shift, X, Y);
  if not (FDragging and (ssLeft in Shift)) then Exit;
  P := Parent.ScreenToClient(ClientToScreen(Point(X, Y)));
  DX := P.X - FDragStart.X;
  DY := P.Y - FDragStart.Y;

  if Parent is TjanGridS then
  begin
    WorkR := TjanGridS(Parent).GetWorkAreaRect;
    // groep binnen het werkgebied houden
    if FFrameStart.X + DX < WorkR.Left then DX := WorkR.Left - FFrameStart.X;
    if FFrameStart.Y + DY < WorkR.Top then DY := WorkR.Top - FFrameStart.Y;
    // snappen zoals bij één object: op het midden van het eerste object
    Ref := TControl(FItems[0]);
    C0 := Point(FItemStart[0].X + Ref.Width div 2 + DX,
                FItemStart[0].Y + Ref.Height div 2 + DY);
    Snapped := TjanGridS(Parent).SnapPointToRuler(C0, WorkR);
    DX := DX + (Snapped.X - C0.X);
    DY := DY + (Snapped.Y - C0.Y);
  end;

  // voedingsrails: komt een invoer of uitvoer van de groep dicht bij zijn
  // rail, dan springt de hele groep zodat die erop zit (eerste treffer wint)
  for i := 0 to FItems.Count - 1 do
  begin
    NL := FItemStart[i].X + DX;
    SnapToRail(TControl(FItems[i]), NL);
    if NL <> FItemStart[i].X + DX then
    begin
      DX := NL - FItemStart[i].X;
      Break;
    end;
  end;

  ApplyDelta(DX, DY);
end;

procedure TjanGroupSelect.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  FDragging := False;
  if Assigned(Parent) then
    Parent.Invalidate;
end;


// ============================================================
// TjanLogicRun: programmeermodule (stappenprogramma)
// ============================================================

const
  LR_W = 120;           // breedte van het blok
  LR_H = 184;           // hoogte van het blok (met T1/T2 onder UIT7)
  LR_MaxSteps = 64;

function FindLogicRun(P: TWinControl): TjanLogicRun;
var
  i: Integer;
begin
  Result := nil;
  if P = nil then Exit;
  for i := 0 to P.ControlCount - 1 do
    if P.Controls[i] is TjanLogicRun then
      Exit(TjanLogicRun(P.Controls[i]));
end;

function LogicRunDinText(D: TLogicRunDin; const ATaal: string): string;
begin
  case D of
    lrdStartStop: Result := Tr(ATaal, 'start/stop', 'start/stop', 'marche/arrêt', 'Start/Stopp');
    lrdReset:     Result := Tr(ATaal, 'reset', 'reset', 'remise à 0', 'Reset');
    lrdStap:      Result := '+1';
    lrdAanUit:    Result := Tr(ATaal, 'aan/uit', 'on/off', 'actif/inactif', 'Ein/Aus');
  else
    Result := '';
  end;
end;

constructor TjanLogicRun.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := LR_W;
  Height := LR_H;
  Connectors := TList.Create;
  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.OnTimer := TimerTick;
  FStapDuur := 500;
  FTimer.Interval := FStapDuur;
  FHerhalen := True;
  FDin[0] := lrdStartStop;
  FDin[1] := lrdReset;
  FDin[2] := lrdStap;
  FDin[3] := lrdGeen;
  FStep := -1;
  AddStep(0, 1);
  FTaal := 'NL';
  FNaam := 'LogicRun';
  HelpKeyword := 'logicrun';
  ShowHint := True;
end;

destructor TjanLogicRun.Destroy;
begin
  FTimer.Enabled := False;
  Connectors.Free;
  inherited;
end;

class function TjanLogicRun.InputPinY(I: Integer): Integer;
begin
  Result := 28 + I * 24;
end;

class function TjanLogicRun.OutputPinY(I: Integer): Integer;
begin
  if I < 8 then
    Result := 22 + I * 14
  else
    Result := 140 + (I - 8) * 16;   // T1 en T2, iets lager dan UIT7
end;

function TjanLogicRun.DisplayChar(I: Integer): Char;
const
  Hex: array[0..15] of Char = '0123456789ABCDEF';
var
  B: Byte;
begin
  if (FStep < 0) or (FStep >= Length(FSteps)) then B := 0
  else B := FSteps[FStep].Bits;
  Result := Hex[(B shr (4 * I)) and $0F];
end;

function TjanLogicRun.OutputPinAt(const P: TPoint): Integer;
var
  i: Integer;
begin
  Result := -1;
  if (P.X < Left + Width - 18) or (P.X > Left + Width + 8) then Exit;
  for i := 0 to 9 do
    if Abs(P.Y - (Top + OutputPinY(i) + 3)) <= 6 then
      Exit(i);
end;

function TjanLogicRun.InputPinAt(const P: TPoint): Integer;
var
  i: Integer;
begin
  Result := -1;
  if (P.X < Left - 8) or (P.X > Left + 18) then Exit;
  for i := 0 to 3 do
    if Abs(P.Y - (Top + InputPinY(i) + 3)) <= 10 then
      Exit(i);
end;

function TjanLogicRun.GetStepCount: Integer;
begin
  Result := Length(FSteps);
end;

function TjanLogicRun.GetStep(I: Integer): TLogicRunStep;
begin
  Result := FSteps[I];
end;

procedure TjanLogicRun.SetStep(I: Integer; const Value: TLogicRunStep);
begin
  FSteps[I] := Value;
  if FSteps[I].Tijd < 1 then FSteps[I].Tijd := 1;
  if (FSteps[I].WachtDin < 0) or (FSteps[I].WachtDin > 3) then FSteps[I].WachtDin := 0;
  if FSteps[I].WachtN < 1 then FSteps[I].WachtN := 1;
  if FSteps[I].WachtN > 999 then FSteps[I].WachtN := 999;
  Changed;
end;

function TjanLogicRun.GetDin(I: Integer): TLogicRunDin;
begin
  Result := FDin[I];
end;

procedure TjanLogicRun.SetDin(I: Integer; Value: TLogicRunDin);
begin
  FDin[I] := Value;
  Changed;
end;

function TjanLogicRun.GetInput(I: Integer): Boolean;
begin
  Result := FIn[I];
end;

function TjanLogicRun.GetOutput(I: Integer): Boolean;
begin
  Result := (FStep >= 0) and (FStep < Length(FSteps)) and
            ((FSteps[FStep].Bits and (1 shl I)) <> 0);
end;

procedure TjanLogicRun.SetStapDuur(Value: Integer);
begin
  if Value < 50 then Value := 50;
  if Value > 10000 then Value := 10000;
  FStapDuur := Value;
  FTimer.Interval := Value;
  Changed;
end;

procedure TjanLogicRun.SetHerhalen(Value: Boolean);
begin
  FHerhalen := Value;
  Changed;
end;

procedure TjanLogicRun.SetTaal(const Value: string);
begin
  FTaal := Value;
  UpdateHintText;
  if FMouseOver then
    SendStatusToBar;
  Invalidate;
end;

procedure TjanLogicRun.Changed;
begin
  if FStep >= Length(FSteps) then
    FStep := Length(FSteps) - 1;
  Invalidate;
  if FMouseOver then
    SendStatusToBar;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TjanLogicRun.ClearSteps;
begin
  SetLength(FSteps, 0);
  FStep := -1;
  FCount := 0;
  Changed;
end;

procedure TjanLogicRun.AddStep(ABits: Byte; ATijd: Integer);
begin
  InsertStep(Length(FSteps), ABits, ATijd);
end;

procedure TjanLogicRun.InsertStep(AIndex: Integer; ABits: Byte; ATijd: Integer);
var
  i: Integer;
begin
  if Length(FSteps) >= LR_MaxSteps then Exit;
  if AIndex < 0 then AIndex := 0;
  if AIndex > Length(FSteps) then AIndex := Length(FSteps);
  SetLength(FSteps, Length(FSteps) + 1);
  for i := High(FSteps) downto AIndex + 1 do
    FSteps[i] := FSteps[i - 1];
  FSteps[AIndex].Bits := ABits;
  if ATijd < 1 then ATijd := 1;
  FSteps[AIndex].Tijd := ATijd;
  FSteps[AIndex].Wacht := lrwGeen;
  FSteps[AIndex].WachtDin := 0;
  FSteps[AIndex].WachtN := 1;
  Changed;
end;

procedure TjanLogicRun.DeleteStep(AIndex: Integer);
var
  i: Integer;
begin
  // er blijft altijd minstens één stap
  if (AIndex < 0) or (AIndex > High(FSteps)) or (Length(FSteps) <= 1) then Exit;
  for i := AIndex to High(FSteps) - 1 do
    FSteps[i] := FSteps[i + 1];
  SetLength(FSteps, Length(FSteps) - 1);
  Changed;
end;

// stapduur;herhalen;din1;din2;din3;din4;bits:tijd,bits:tijd,...
// (een stap met een voorwaarde: bits:tijd:wacht:din:n)
function TjanLogicRun.ProgramText: string;
var
  i: Integer;
  S: string;
begin
  S := '';
  for i := 0 to High(FSteps) do
  begin
    if i > 0 then S := S + ',';
    S := S + Format('%d:%d', [FSteps[i].Bits, FSteps[i].Tijd]);
    if FSteps[i].Wacht <> lrwGeen then
      S := S + Format(':%d:%d:%d', [Ord(FSteps[i].Wacht), FSteps[i].WachtDin, FSteps[i].WachtN]);
  end;
  Result := Format('%d;%d;%d;%d;%d;%d;%s',
    [FStapDuur, Ord(FHerhalen), Ord(FDin[0]), Ord(FDin[1]), Ord(FDin[2]), Ord(FDin[3]), S]);
end;

procedure TjanLogicRun.SetProgramText(const S: string);
var
  Parts, StepList, Fields: TStringList;
  i, p, D: Integer;
  Item: string;
begin
  Parts := TStringList.Create;
  StepList := TStringList.Create;
  Fields := TStringList.Create;
  try
    Parts.Delimiter := ';';
    Parts.StrictDelimiter := True;
    Parts.DelimitedText := S;
    if Parts.Count < 7 then Exit;
    FStapDuur := StrToIntDef(Parts[0], 500);
    if FStapDuur < 50 then FStapDuur := 50;
    FTimer.Interval := FStapDuur;
    FHerhalen := StrToIntDef(Parts[1], 1) <> 0;
    for i := 0 to 3 do
    begin
      D := StrToIntDef(Parts[2 + i], 0);
      if (D < Ord(Low(TLogicRunDin))) or (D > Ord(High(TLogicRunDin))) then D := 0;
      FDin[i] := TLogicRunDin(D);
    end;
    StepList.Delimiter := ',';
    StepList.StrictDelimiter := True;
    StepList.DelimitedText := Parts[6];
    SetLength(FSteps, 0);
    for i := 0 to StepList.Count - 1 do
    begin
      Item := Trim(StepList[i]);
      p := Pos(':', Item);
      if p = 0 then Continue;
      if Length(FSteps) >= LR_MaxSteps then Break;
      Fields.Delimiter := ':';
      Fields.StrictDelimiter := True;
      Fields.DelimitedText := Item;
      SetLength(FSteps, Length(FSteps) + 1);
      with FSteps[High(FSteps)] do
      begin
        Bits := Byte(StrToIntDef(Fields[0], 0));
        Tijd := StrToIntDef(Fields[1], 1);
        if Tijd < 1 then Tijd := 1;
        Wacht := lrwGeen;
        WachtDin := 0;
        WachtN := 1;
        if Fields.Count >= 5 then
        begin
          D := StrToIntDef(Fields[2], 0);
          if (D >= Ord(Low(TLogicRunWacht))) and (D <= Ord(High(TLogicRunWacht))) then
            Wacht := TLogicRunWacht(D);
          WachtDin := StrToIntDef(Fields[3], 0);
          if (WachtDin < 0) or (WachtDin > 3) then WachtDin := 0;
          WachtN := StrToIntDef(Fields[4], 1);
          if WachtN < 1 then WachtN := 1;
        end;
      end;
    end;
    if Length(FSteps) = 0 then
    begin
      SetLength(FSteps, 1);
      FSteps[0].Bits := 0;
      FSteps[0].Tijd := 1;
    end;
  finally
    Fields.Free;
    StepList.Free;
    Parts.Free;
  end;
  FPulses := 0;
  FStep := -1;
  FCount := 0;
  Changed;
end;

procedure TjanLogicRun.Start;
begin
  if Length(FSteps) = 0 then Exit;
  if (FStep < 0) or (FStep > High(FSteps)) then
  begin
    FStep := 0;
    FCount := 0;
    FPulses := 0;
  end;
  FRunning := True;
  FTimer.Interval := FStapDuur;
  FTimer.Enabled := True;
  Changed;
end;

procedure TjanLogicRun.Pause;
begin
  FRunning := False;
  FTimer.Enabled := False;
  Changed;
end;

procedure TjanLogicRun.StopRun;
begin
  FPulses := 0;
  FRunning := False;
  FTimer.Enabled := False;
  FStep := -1;
  FCount := 0;
  Changed;
end;

procedure TjanLogicRun.StepOnce;
begin
  FPulses := 0;
  if Length(FSteps) = 0 then Exit;
  FCount := 0;
  if (FStep < 0) or (FStep >= High(FSteps)) then
    FStep := 0
  else
    Inc(FStep);
  Changed;
end;

procedure TjanLogicRun.ResetRun;
begin
  FPulses := 0;
  if Length(FSteps) = 0 then Exit;
  FStep := 0;
  FCount := 0;
  Changed;
end;

// is de voorwaarde van de huidige stap vervuld?
function TjanLogicRun.ConditionMet: Boolean;
begin
  Result := False;
  if (FStep < 0) or (FStep > High(FSteps)) then Exit;
  with FSteps[FStep] do
    case Wacht of
      lrwAan:    Result := FIn[WachtDin];
      lrwUit:    Result := not FIn[WachtDin];
      // pas verder als de laatste puls voorbij is: zo krijgen andere
      // onderdelen op dezelfde ingang (bv. een teller) die puls nog mee
      lrwPulsen: Result := (FPulses >= WachtN) and not FIn[WachtDin];
    else
      Result := True;
    end;
end;

// naar de volgende stap (of opnieuw beginnen, of stoppen na de laatste)
procedure TjanLogicRun.NextStep;
begin
  FCount := 0;
  FPulses := 0;
  if FStep < High(FSteps) then
    Inc(FStep)
  else if FHerhalen then
    FStep := 0
  else
  begin
    // laatste stap blijft staan
    FRunning := False;
    FTimer.Enabled := False;
  end;
  Changed;
end;

procedure TjanLogicRun.TimerTick(Sender: TObject);
begin
  if (not FRunning) or (Length(FSteps) = 0) then Exit;
  if (FStep < 0) or (FStep > High(FSteps)) then
    FStep := 0;
  // een stap met een voorwaarde wacht daarop, niet op de tijd
  if FSteps[FStep].Wacht <> lrwGeen then
  begin
    if ConditionMet then NextStep;
    Exit;
  end;
  Inc(FCount);
  if FCount < FSteps[FStep].Tijd then Exit;
  NextStep;
end;

procedure TjanLogicRun.SetInput(I: Integer; Value: Boolean);
begin
  if (I < 0) or (I > 3) or (FIn[I] = Value) then Exit;
  FIn[I] := Value;
  if Value then
    case FDin[I] of
      lrdStartStop: if FRunning then Pause else Start;
      lrdReset: ResetRun;
      lrdStap: StepOnce;
      lrdAanUit: Start;
    end
  else if FDin[I] = lrdAanUit then
    StopRun;   // schakelaar uit: stoppen, uitgangen uit
  // voorwaarde van de huidige stap: puls tellen en meteen nakijken
  if FRunning and (FStep >= 0) and (FStep <= High(FSteps)) and
     (FSteps[FStep].Wacht <> lrwGeen) then
  begin
    if Value and (FSteps[FStep].Wacht = lrwPulsen) and (FSteps[FStep].WachtDin = I) then
      Inc(FPulses);
    if ConditionMet then
      NextStep;
  end;
  Invalidate;
end;

procedure TjanLogicRun.Paint;
var
  i, y, w: Integer;
  BW, BH: Integer;   // maten van het blok (in 'with Canvas' zijn Width/Height die van het canvas)
  S: string;
  Body: TRect;
begin
  BW := Self.Width;
  BH := Self.Height;
  with Canvas do
  begin
    // behuizing
    Body := Rect(4, 0, BW - 4, BH);
    Brush.Style := bsSolid;
    Brush.Color := RGBToColor(250, 250, 150);
    Pen.Color := clBlack;
    if FSelect then Pen.Width := 2 else Pen.Width := 1;
    Rectangle(Body);
    Pen.Width := 1;
    Font.Name := 'Arial';
    Font.Style := [fsBold];
    Font.Size := 9;
    Font.Color := clNavy;
    Brush.Style := bsClear;
    S := 'LogicRun';
    TextOut((BW - TextWidth(S)) div 2, 2, S);
    MoveTo(5, 17);
    LineTo(BW - 5, 17);

    // ingangen links: aansluiting, naam en functie
    Font.Size := 7;
    for i := 0 to 3 do
    begin
      y := InputPinY(i);
      Brush.Style := bsSolid;
      Brush.Color := clLime;
      Pen.Color := clGray;
      Rectangle(1, y, 8, y + 7);
      Brush.Style := bsClear;
      Font.Style := [fsBold];
      if FIn[i] then Font.Color := clRed else Font.Color := clNavy;
      TextOut(11, y - 3, 'DIN' + IntToStr(i + 1));
      Font.Style := [];
      Font.Color := clGray;
      TextOut(11, y + 7, LogicRunDinText(FDin[i], FTaal));
    end;

    // uitgangen rechts: lampje, naam en aansluiting
    for i := 0 to 7 do
    begin
      y := OutputPinY(i);
      Brush.Style := bsSolid;
      if Outputs[i] then Brush.Color := clRed else Brush.Color := clWhite;
      Pen.Color := clGray;
      Ellipse(BW - 20, y, BW - 12, y + 8);
      Brush.Color := clLime;
      Rectangle(BW - 8, y, BW - 1, y + 7);
      Brush.Style := bsClear;
      Font.Style := [fsBold];
      if Outputs[i] then Font.Color := clRed else Font.Color := clNavy;
      S := 'UIT' + IntToStr(i);
      w := TextWidth(S);
      TextOut(BW - 23 - w, y - 2, S);
    end;

    // display-uitgangen: T1 = UIT0..3, T2 = UIT4..7, met het cijfer erbij
    MoveTo(BW - 60, OutputPinY(8) - 6);
    LineTo(BW - 5, OutputPinY(8) - 6);
    for i := 0 to 1 do
    begin
      y := OutputPinY(8 + i);
      Brush.Style := bsSolid;
      Brush.Color := clBlack;
      Pen.Color := clGray;
      Rectangle(BW - 22, y - 3, BW - 10, y + 11);
      Brush.Color := clLime;
      Rectangle(BW - 8, y, BW - 1, y + 7);
      Brush.Style := bsClear;
      Font.Style := [fsBold];
      Font.Color := clRed;
      S := DisplayChar(i);
      TextOut(BW - 16 - TextWidth(S) div 2, y - 2, S);
      Font.Color := clNavy;
      S := 'T' + IntToStr(i + 1);
      TextOut(BW - 25 - TextWidth(S), y - 2, S);
    end;

    // onderaan: stap of gestopt
    Font.Style := [];
    Font.Size := 7;
    Font.Color := clBlack;
    if FStep < 0 then
      S := Tr(FTaal, 'gestopt', 'stopped', 'arrêté', 'gestoppt')
    else
    begin
      S := Format('%s %d/%d', [Tr(FTaal, 'stap', 'step', 'pas', 'Schritt'), FStep + 1, Length(FSteps)]);
      if FRunning then S := '> ' + S else S := '|| ' + S;
      if FSteps[FStep].Wacht = lrwPulsen then
        S := S + Format('  DIN%d %d/%d', [FSteps[FStep].WachtDin + 1, FPulses, FSteps[FStep].WachtN])
      else if FSteps[FStep].Wacht in [lrwAan, lrwUit] then
        S := S + Format('  DIN%d?', [FSteps[FStep].WachtDin + 1]);
    end;
    TextOut(11, BH - 14, S);
  end;
end;

procedure TjanLogicRun.UpdateHintText;
begin
  Hint := BuildSimHint(FNaam, FTaal) + #13#10 +
    Tr(FTaal, 'Dubbelklik: programma bewerken', 'Double-click: edit program',
              'Double-clic : modifier le programme', 'Doppelklick: Programm bearbeiten');
end;

procedure TjanLogicRun.SendStatusToBar;
var
  S: string;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, FNaam + ' > ', 0);
  if FStep < 0 then
    S := Tr(FTaal, 'gestopt', 'stopped', 'arrêté', 'gestoppt')
  else
    S := Format('%s %d/%d', [Tr(FTaal, 'stap', 'step', 'pas', 'Schritt'), FStep + 1, Length(FSteps)]);
  FOnStatus(Self, S, 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

procedure TjanLogicRun.CMMouseEnter(var Msg: TMessage);
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

procedure TjanLogicRun.CMMouseLeave(var Msg: TMessage);
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

procedure TjanLogicRun.BuildPopup;
var
  Mi: TMenuItem;
begin
  if not Assigned(PopupMenu) then
    PopupMenu := TPopupMenu.Create(Self)
  else
    PopupMenu.Items.Clear;
  Mi := TMenuItem.Create(PopupMenu);
  Mi.Caption := Tr(FTaal, 'Programma bewerken...', 'Edit program...',
                          'Modifier le programme...', 'Programm bearbeiten...');
  Mi.OnClick := EditClick;
  PopupMenu.Items.Add(Mi);
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

procedure TjanLogicRun.EditClick(Sender: TObject);
begin
  if Assigned(LogicRunEditHook) then
    LogicRunEditHook(Self);
end;

procedure TjanLogicRun.LockClick(Sender: TObject);
begin
  FLock := not FLock;
  Invalidate;
end;

procedure TjanLogicRun.SelectClick(Sender: TObject);
begin
  if Assigned(FBox) then
    FBox.SelectObject(Self);
end;

procedure TjanLogicRun.DblClick;
begin
  inherited;
  doMove := False;
  if Assigned(LogicRunEditHook) then
    LogicRunEditHook(Self);
end;

procedure TjanLogicRun.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
  k: Integer;
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

  // met de knop Verbinding: een draad beginnen op een uitgang
  if (Button = mbLeft) and (Screen.Cursor = crDraad) and (Parent <> nil) then
  begin
    k := OutputPinAt(Point(Left + X, Top + Y));
    if k >= 0 then
    begin
      // begin van de draad (midden van het blokje) op het midden van de aansluiting
      Maakdraad(Top + OutputPinY(k) + 3 - 4, Left + Width - 5 - 4, Parent);
      movecursor;
      BringToFront;
      Exit;
    end;
  end;

  Screen.Cursor := crDefault;
  if Button <> mbLeft then Exit;
  doMove := True;
  AnchorConnectors;
  if Parent is TjanGridS then
    TjanGridS(Parent).BeginGuideLines(Left + Width div 2, Top + Height div 2);
end;

procedure TjanLogicRun.MouseMove(Shift: TShiftState; X, Y: Integer);
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

procedure TjanLogicRun.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Parent is TjanGridS then
    TjanGridS(Parent).EndGuideLines;
  doMove := False;
  Invalidate;
end;

procedure TjanLogicRun.AnchorConnectors;
var
  i: Integer;
  Con: TjanConnector;
  R: TRect;
begin
  Connectors.Clear;
  if Parent = nil then Exit;
  R := BoundsRect;
  InflateRect(R, 8, 0);
  for i := 0 to Parent.ControlCount - 1 do
    if Parent.Controls[i] is TjanConnector then
    begin
      Con := TjanConnector(Parent.Controls[i]);
      // alleen de echte uiteinden van de draad (zie TjanConnector.AnchorToRect)
      if Con.AnchorToRect(R, Point(Left, Top)) then
        Connectors.Add(Con);
    end;
end;

procedure TjanLogicRun.MoveConnectors;
var
  i: Integer;
begin
  for i := 0 to Connectors.Count - 1 do
    TjanConnector(Connectors[i]).MoveConnector(Point(NewLeft, NewTop));
end;
