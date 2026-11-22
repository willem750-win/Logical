// janSimLogic.pas, deel: oude voltmeter, knoppen, sensoren, impulsgenerator (ingevoegd met {$I jsl_oude_invoer.inc})

{TjanMeter}

constructor TjanMeter.Create(AOwner: TComponent);
var i:integer;
begin
  inherited Create(AOwner);
  Select:=false;
  width:=100;
  height:=51;
  // initialize Gates
  FGates[0].pos:=point(1,10);
  FGates[1].pos:=point(1,28);
  FGates[2].pos:=point(1,46);
  FGates[3].pos:=point(52,10);
  FGates[4].pos:=point(52,28);
  FGates[5].pos:=point(52,46);
  for i:=0 to 5 do
    FGates[i].State:=false;
  for i:=0 to 2 do
  begin
    FGates[i].style:=jgsDI;
    FGates[i+3].style:=jgsDO;
  end;
  FLogicAndFunc:=jlfEN;
  FGates[0].Active:=true;
  FGates[1].Active:=false;
  FGates[2].Active:=true;    // - aansluiting: zonder draad meet de meter tegen de massa, met een draad het verschil (bv. over een contact)
  FGates[3].Active:=false;
  FGates[4].Active:=true;
  FGates[5].Active:=false;
  connectors:=TList.create;
  lIn:=TBitmap.create;
  lIn.LoadFromResourceName(HInstance,'LOG');
  V0:=TBitmap.create;
  V0.LoadFromResourceName(HInstance,'V0');
  V5:=TBitmap.create;
  V5.LoadFromResourceName(HInstance,'V5');

  FInfo:= 'Meter';
  FTaal:='NL';
  FPlusVolt:=0; FMinVolt:=0;
  HelpKeyword:='meter';
  ShowHint:=true;
  FLock:=false;
  FPcolor:=rgb(250,250,220);
  Cursor := crMeter;
end;

function TjanMeter.GetGate(Index: Integer): TjanGate;
begin
   result:=FGates[index];
end;

procedure TjanMeter.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  p: TPoint;
  pop: TPopupMenu;
  ItemNew: TMenuItem;
begin
  inherited MouseDown(Button, Shift, X, Y);
  doMove := False;
  mdp := Point(X, Y);

  if Button = mbRight then
  begin
    // popupmenu: vergrendelen, info, selecteren (om te verwijderen)
    pop := TPopupMenu.Create(Self);
    ItemNew := TMenuItem.Create(pop);
    if FLock then
      ItemNew.Caption := Tr(FTaal, 'Ontgrendel', 'Unlock', 'Déverrouiller', 'Entsperren')
    else
      ItemNew.Caption := Tr(FTaal, 'Vergrendel', 'Lock', 'Verrouiller', 'Sperren');
    ItemNew.OnClick := MeterClick;
    pop.Items.Add(ItemNew);
    ItemNew := TMenuItem.Create(pop);
    if ShowHint then
      ItemNew.Caption := Tr(FTaal, 'Info uit', 'Information off', 'Infos off', 'Infos aus')
    else
      ItemNew.Caption := Tr(FTaal, 'Info aan', 'Information on', 'Infos on', 'Infos an');
    ItemNew.OnClick := MeterClick2;
    pop.Items.Add(ItemNew);
    ItemNew := TMenuItem.Create(pop);
    if FSelected then
      ItemNew.Caption := Tr(FTaal, 'Deselecteer object', 'Deselect object', 'Désélectionner l''objet', 'Objekt abwählen')
    else
      ItemNew.Caption := Tr(FTaal, 'Selecteer object', 'Select object', 'Sélectionner un objet', 'Objekt auswählen');
    ItemNew.OnClick := MeterSelectClick;
    pop.Items.Add(ItemNew);
    p := ClientToScreen(Point(0, Height));
    pop.Popup(p.X, p.Y - 1);
    Exit;
  end;

  if Button <> mbLeft then Exit;
  doMove := True;
  oldp := Point(X, Y);
  AnchorConnectors;
  if Parent is TjanGridS then
    TjanGridS(Parent).BeginGuideLines(Left + Width div 2, Top + Height div 2);
end;

procedure TjanMeter.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  p, SnapP: TPoint;
  Grid: TjanGridS;
begin
  inherited MouseMove(Shift, X, Y);
  if FLock or (Parent = nil) then Exit;
  if (ssLeft in Shift) and doMove then
  begin
    p := Parent.ScreenToClient(ClientToScreen(Point(X, Y)));
    newleft := p.x - mdp.x;
    newtop := p.y - mdp.y;
    if Parent is TjanGridS then
    begin
      // net als de andere componenten: midden op het raster laten springen
      Grid := TjanGridS(Parent);
      SnapP := Grid.SnapPointToRuler(Point(newleft + Width div 2, newtop + Height div 2),
        Grid.GetWorkAreaRect);
      newleft := SnapP.X - Width div 2;
      newtop := SnapP.Y - Height div 2;
    end;
    StraightenWires(connectors, newleft, newtop); SnapToRail(Self, newleft);
    left := newleft;
    top := newtop;
    MoveConnectors;
    if Parent is TjanGridS then
      TjanGridS(Parent).UpdateGuideLines(Left + Width div 2, Top + Height div 2);
    if Assigned(GlobalSimBox) then
      GlobalSimBox.DoObjectMove(Self, Left, Top);
    SendStatusToBar;
  end;
end;

procedure TjanMeter.AnchorConnectors;
var wc:TWincontrol;
    i:integer;
    con:TjanConnector;
    R:TRect;
    p:TPoint;
begin
  wc:=parent;
  connectors.Clear;
  R:=boundsrect;
  inflateRect(R,8,0);
  p:=point(left,top);
  for i:=0 to wc.ControlCount-1 do
    if (wc.controls[i] is TjanConnector) then
    begin
      con:=TjanConnector(wc.controls[i]);
      // alleen de echte uiteinden van de draad (zie TjanConnector.AnchorToRect)
      if con.AnchorToRect(R,p) then
        connectors.Add(con);
    end;
end;


procedure TjanMeter.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  doMove := False;
  if Parent is TjanGridS then
    TjanGridS(Parent).EndGuideLines;
  select:=false;Cursor := crDefault;repaint;
end;

procedure TjanMeter.PaintLed(index:integer);
begin
  if not Gates[index].Active then exit;
  // aansluitblokjes: + links, - rechts
  if index=0 then
    canvas.draw(5,35,lIn)
  else if index=2 then
    canvas.draw(85,35,lIn);
end;


procedure TjanMeter.Paint;
var i, TW: integer;
    R:TRect;
    U: Double;
    S: string;
begin
   U := Reading;
   with canvas do
   begin
     brush.color:=clSilver;
     R:=clientrect;
      Fillrect(R);
     Frame3D(R,clbtnhighlight,clbtnshadow,1);
     brush.color:=FPcolor;
     R:=rect(22,5,76,30);
     Fillrect(R);
     frame3D(R,clbtnshadow,clbtnhighlight,2);
     for i:=0 to 4 do
       PaintLed(i);
     brush.style:=bsclear;
     // gemeten spanning, bv. 3,3 (rood zodra er spanning is)
     S := FormatFloat('0.0', U);
     Font.Name := 'Arial'; Font.Size := 12; Font.Style := [fsBold];
     if U > 0.001 then Font.Color := clRed else Font.Color := clGray;
     TW := TextWidth(S);
     TextOut(62 - TW, 8, S);
     Font.Style := [];
     Font.Name:='Arial';Font.Size:=14;Font.Color:=clWhite;
     TextOut(4,10,'+');TextOut(84,2,'_');Font.Color:=clBlack;Font.Size:=12;  TextOut(64,9,'V');
     if FSelected then
     begin
       brush.style := bsClear;
       pen.color := clRed; pen.style := psDot; pen.width := 1;
       Rectangle(ClientRect);
       pen.style := psSolid;
     end;
   end;
end;



procedure TjanMeter.Resize;
begin
  width:=100;
  height:=51;
end;


destructor TjanMeter.Destroy;
begin
  lIn.Free;
  V0.Free;
  V5.Free;
  Connectors.Free;
  inherited;

end;

// U(+) - U(-). + en - komen elk van een rail (ingeplugd) of van een draad.
function TjanMeter.Reading: Double;
var
  R: TjanRail;
  UP, UM: Double;
  i: Integer;
begin
  UP := FPlusVolt;
  UM := FMinVolt;
  if Parent <> nil then
    for i := 0 to Parent.ControlCount - 1 do
      if (Parent.Controls[i] is TjanRail) and Parent.Controls[i].Visible then
      begin
        R := TjanRail(Parent.Controls[i]);
        if RailFits(R, Self, Left, Top) then
          if R.Plus then
            UP := R.Volt              // + ingeplugd op een + rail
          else
            UM := 0;                  // - ingeplugd op de massa
      end;
  if WiredRail(Self, False) <> nil then
    UM := 0;                          // - met een draad aan de massa
  // (zonder - aansluiting meet de meter ook tegen de massa)
  Result := UP - UM;
  if Result < 0 then Result := 0;     // omgekeerd aangesloten: 0 V
end;

// uitgang van de meter: hoog vanaf RailMinVolt (altijd actueel, ook als een
// rail van spanning verandert)
function TjanMeter.GetOutPut2: Boolean;
begin
  Result := Reading >= RailMinVolt - 0.001;
end;

procedure TjanMeter.SetPlusVolt(const Value: Double);
begin
  if Abs(Value - FPlusVolt) < 0.001 then Exit;
  FPlusVolt := Value;
  OutCalc;
  Invalidate;
end;

procedure TjanMeter.SetMinVolt(const Value: Double);
begin
  if Abs(Value - FMinVolt) < 0.001 then Exit;
  FMinVolt := Value;
  OutCalc;
  Invalidate;
end;

procedure TjanMeter.MeterSelectClick(Sender: TObject);
begin
  if Assigned(FBox) then
    FBox.SelectObject(Self);
end;

procedure TjanMeter.UpdateHintText;
begin
  // de meter meet altijd tegen de massa (0 V)
  Hint := Tr(FTaal,
    'Voltmeter (meet tegen de massa)' + #13#10 + '+ links: aansluiten met een draad of op een + rail inpluggen.' + #13#10 +
      '- rechts mag open blijven of op een - rail ingeplugd worden.',
    'Voltmeter (measures against ground)' + #13#10 + '+ left: connect a wire or plug onto a + rail.' + #13#10 +
      '- right may stay open or be plugged onto a - rail.',
    'Voltmètre (mesure par rapport à la masse)' + #13#10 + '+ à gauche : relier un fil ou brancher sur un rail +.' + #13#10 +
      '- à droite peut rester libre ou être branché sur un rail -.',
    'Voltmeter (misst gegen Masse)' + #13#10 + '+ links: Draht anschließen oder an eine + Schiene stecken.' + #13#10 +
      '- rechts darf offen bleiben oder an eine - Schiene gesteckt werden.');
end;

procedure TjanMeter.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, 'Voltmeter > ', 0);
  FOnStatus(Self, 'U = ' + FormatFloat('0.0', Reading) + ' V', 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

procedure TjanMeter.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
  UpdateHintText;
  SendStatusToBar;
end;

procedure TjanMeter.CMMouseLeave(var Msg: TMessage);
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

procedure TjanMeter.MoveConnectors;
var i:integer;
    con:TjanConnector;
begin
  select:=true;
  if connectors.Count=0 then exit;
  for i:=0 to connectors.count-1 do
  begin
    con:=TjanConnector(connectors[i]);
    con.MoveConnector(point(newleft,newtop));
  end;
end;

procedure TjanMeter.OutCalc;
begin
  {case FLogicAndFunc of
  jlfEN: OutPut2:= Input1 and Input3;
 { end; }
  // Voltmeter (parallel aangesloten): toont het spanningsverschil
  // U(+) - U(-) in volt (zie Reading). Input1 = + (links), Input3 = - (rechts).
  // De uitgang is hoog vanaf RailMinVolt (2 V), zoals een logische ingang.
  output2 := Reading >= RailMinVolt - 0.001;
end;

procedure TjanMeter.SetInput1(const Value: boolean);
begin
  if value<>FInput1 then
  begin
    FInput1 := Value;
    invalidate;
    OutCalc;
  end;
end;



procedure TjanMeter.MeterClick(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanMeter.MeterClick1(sender:TObject);
var
i:integer;
con:TjanConnector;
Begin
Output2:=false;
for i:=0 to connectors.count-1 do
    begin
    con:=TjanConnector(connectors[i]);
    con.connect;
    con.free;
    end;
free;
end;

procedure TjanMeter.MeterClick2(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;


procedure TjanMeter.SetInfo(const Value: String);
begin
  if value<>FInfo then
  begin
    FInfo := Value;
 end;
end;

procedure TjanMeter.SetLock(const Value: boolean);
begin
  if value<>FLock then
  begin
    FLock := Value;
 end;
end;

procedure TjanMeter.SetInput3(const Value: boolean);
begin
  if value<>FInput3 then
  begin
    FInput3 := Value;
    invalidate;
    OutCalc;
  end;
end;



procedure TjanMeter.SetOutPut2(const Value: boolean);
begin
  if value<>FOutput2 then
  begin
    FOutPut2 := Value;
    invalidate;
  end;

end;

procedure TjanMeter.SetPColor(const Value: TColor);
begin
  if value<>FPcolor then
  begin
    FPcolor := Value;
    invalidate;
  end;

end;

procedure TjanMeter.SetLogicFunc(const Value: TjanMeterFunc);
begin
  if value<>FLogicAndFunc then
  begin
    FLogicAndFunc := Value;
    case FLogicAndFunc of
    jlfEN:
      begin
        FGates[0].Active:=true;
        FGates[1].Active:=false;
        FGates[2].Active:=false;
        FGates[3].Active:=false;
        FGates[4].Active:=true;
        FGates[5].Active:=false;
      end;

    end;
    invalidate;
    OutCalc;
  end;
end;


{ TjanSimButton }

procedure TjanSimButton.BuildPopup;
var
  miLock, miName, miInfo, miSelect: TMenuItem;
begin
  if not Assigned(PopupMenu) then
    PopupMenu := TPopupMenu.Create(Self)
  else
    PopupMenu.Items.Clear;

  // --- Lock / Unlock
  miLock := TMenuItem.Create(PopupMenu);
  miLock.Name := 'miLock';
  miLock.OnClick := ButtonClick1;     // Delphi-mode: geen @
  PopupMenu.Items.Add(miLock);

  // --- Naam wijzigen
  miName := TMenuItem.Create(PopupMenu);
  miName.Name := 'miName';
  miName.OnClick := ButtonNClick;     // Delphi-mode: geen @
  PopupMenu.Items.Add(miName);

  // --- Info aan/uit
  miInfo := TMenuItem.Create(PopupMenu);
  miInfo.Name := 'miInfo';
  miInfo.OnClick := ButtonClick3;     // Delphi-mode: geen @
  PopupMenu.Items.Add(miInfo);

  // --- Selecteer voor verwijdering
  miSelect := TMenuItem.Create(PopupMenu);
  miSelect.Name := 'miSelect';
  miSelect.OnClick := ButtonClick4;     // Delphi-mode: geen @
  PopupMenu.Items.Add(miSelect);
end;

procedure TjanSimButton.UpdatePopupCaptions;
var
  miLock, miName, miInfo, miSelect: TMenuItem;
  s: string;
begin
  if not Assigned(PopupMenu) then Exit;

  miLock   := TMenuItem(PopupMenu.FindComponent('miLock'));
  miName   := TMenuItem(PopupMenu.FindComponent('miName'));
  miInfo   := TMenuItem(PopupMenu.FindComponent('miInfo'));
  miSelect := TMenuItem(PopupMenu.FindComponent('miSelect'));

  // --- Lock / Unlock
  if Assigned(miLock) then
  begin
    if BTaal = 'NL' then
    begin
      if FLock then s := 'Ontgrendel' else s := 'Vergrendel';
    end
    else if BTaal = 'FR' then
    begin
      if FLock then s := 'Déverrouiller' else s := 'Verrouiller';
    end
    else if BTaal = 'DU' then
    begin
      if FLock then s := 'Entsperren' else s := 'Sperren';
    end
    else
    begin
      if FLock then s := 'Unlock' else s := 'lock';
    end;
    miLock.Caption := LangTr(s);
  end;

  // --- Naam wijzigen
  if Assigned(miName) then
  begin
    if BTaal = 'NL' then s := 'Wijzig Naam'
    else if BTaal = 'FR' then s := 'Changer le nom'
    else if BTaal = 'DU' then s := 'Namen ändern'
    else s := 'Change name';
    miName.Caption := LangTr(s);
  end;

  // --- Select / Deselect (TOGGLE)
  if Assigned(miSelect) then
  begin
    if not Selected then
    begin
      if BTaal = 'NL' then s := 'Selecteer object'
      else if BTaal = 'FR' then s := 'Sélectionner un objet'
      else if BTaal = 'DU' then s := 'Objekt auswählen'
      else s := 'Select object';
    end
    else
    begin
      if BTaal = 'NL' then s := 'Deselecteer object'
      else if BTaal = 'FR' then s := 'Désélectionner l''objet'
      else if BTaal = 'DU' then s := 'Objekt abwählen'
      else s := 'Deselect object';
    end;
    miSelect.Caption := LangTr(s);
  end;

  // --- Info aan/uit
  if Assigned(miInfo) then
  begin
    if ShowHint then
    begin
      if BTaal = 'NL' then s := 'Info uit'
      else if BTaal = 'FR' then s := 'Infos off'
      else if BTaal = 'DU' then s := 'Infos aus'
      else s := 'Information off';
    end
    else
    begin
      if BTaal = 'NL' then s := 'Info aan'
      else if BTaal = 'FR' then s := 'Infos on'
      else if BTaal = 'DU' then s := 'Infos an'
      else s := 'Information on';
    end;
    miInfo.Caption := LangTr(s);
  end;
end;



procedure TjanSimButton.AnchorConnectors;
var wc:TWincontrol;
    i:integer;
    con:TjanConnector;
    R:TRect;
    p:TPoint;
begin
  wc:=parent;
  connectors.Clear;
  R:=boundsrect;
  inflateRect(R,8,8);
  p:=point(left,top);
  for i:=0 to wc.ControlCount-1 do
    if (wc.controls[i] is TjanConnector) then
    begin
      con:=TjanConnector(wc.controls[i]);
      // alleen de echte uiteinden van de draad (zie TjanConnector.AnchorToRect)
      if con.AnchorToRect(R,p) then
        connectors.Add(con);
    end;
end;

constructor TjanSimButton.Create(AOwner: TComponent);
var
XX, YY: Integer;
PixelColor: TColor;
MI:TMenuItem;
begin
  inherited Create(AOwner);
  HelpKeyword := 'button';
  Select:=false;
  FStatButton := stButtonStop;
  draad:=true;
  FDown:=false;
  width:=58;
  height:=32;
  connectors:=TList.create;

  KnopUp:=TBitmap.Create;
  KnopUp.LoadFromResourceName(HInstance,'DRUK_UIT');
  for YY := 0 to KnopUp.Height - 1 do
      for XX := 0 to KnopUp.Width - 1 do
      begin
        PixelColor := KnopUp.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          KnopUp.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  KnopUp.Transparent := True;
  KnopUp.TransParentColor:= clFuchsia;

  KnopDown:=TBitmap.Create;
  KnopDown.LoadFromResourceName(HInstance,'DRUK__IN');
  for YY := 0 to KnopDown.Height - 1 do
      for XX := 0 to KnopDown.Width - 1 do
      begin
        PixelColor := KnopDown.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          KnopDown.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  KnopDown.Transparent := True;
  KnopDown.TransParentColor:= clFuchsia;;//KnopUp.canvas.pixels[0,0];

  ControlStyle := ControlStyle + [csCaptureMouse,csDoubleClicks,csClickEvents];
  FTaal:='NL';
  FNaam:='Drukknop';
  FSoort:='Invoer';
  FInfo:=  FNaam;//Druknop';
  ShowHint:=True;

  FModusSquare:=false;
end;

destructor TjanSimButton.Destroy;
begin
  knopUp.Free;
  knopDown.Free;
  connectors.free;
  inherited;
end;

procedure TjanSimButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  R, R2, R3: TRect;
  p: TPoint;
  L, T: Integer;
  wc: TWinControl;
begin
  inherited;

  // =========================================================
  // 1) RECHTSKLIK: popup tonen en meteen stoppen
  // =========================================================
  if (Button = mbRight) and (FLock = False) then
  begin
    BuildPopup;
    UpdatePopupCaptions;

    p := Point(0, Height);
    p := ClientToScreen(p);
    PopupMenu.Popup(p.X, p.Y - 1);
    Exit;
  end;

  puls := 1;
  mdp := Point(X, Y);

  R  := Rect(49, 6, 57, 14);  // klik-zone voor draadaansluiting
  R2 := ButtonPushZone(Self);   // klik-zone om button te bedienen
  R3 := ClientRect;           // zone voor square button

  // =========================================================
  // 2) SQUARE MODUS
  // =========================================================
  if FModusSquare = True then
  begin
    if PtInRect(R3, mdp) then
    begin
      FDepressed := True;
      doMove := False;
      Down := True;

      with Canvas do
      begin
        Lock;
        try
          Pen.Color := clRed;
          RoundRect(3, 3, 47, 47, 8, 8);
          DrawFocusRect(ClientRect);
        finally
          Unlock;
        end;
      end;

      Invalidate;
      Exit;
    end;
  end;

  // =========================================================
  // 3) NIET-SQUARE MODUS
  // =========================================================
  if FModusSquare = False then
  begin
    // maken van aansluitdraad
    if PtInRect(R, mdp) and (Screen.Cursor = crDraad) then
    begin
      wc := Parent;
      L := Left + Width - 8;
      T := Top + 7;

      Maakdraad(T, L, wc);

      doMove := False;
      movecursor;
      BringToFront;
      Exit;
    end;

    Screen.Cursor := crDefault;

    // drag of click?
    doMove := not PtInRect(R2, mdp);
    FDepressed := not doMove;
    oldp := Point(X, Y);

    if doMove then
    begin
      AnchorConnectors;

      if (Button = mbLeft) and (Parent is TjanGridS) then
        TjanGridS(Parent).BeginGuideLines(Left + Width div 2, Top + Height div 2);
    end
    else
    begin
      Canvas.Lock;
      try
        Canvas.Draw(0, 0, knopDown);
      finally
        Canvas.Unlock;
      end;

      Down := True;
      Invalidate;
    end;
  end;
end;

procedure TjanSimButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  R2, R3: TRect;
  p: TPoint;
begin
  inherited;

  if Parent is TjanGridS then
    TjanGridS(Parent).EndGuideLines;

  Select := False;
  Repaint;
  FDepressed := False;

  p := Point(X, Y);
  R2 := ButtonPushZone(Self);
  R3 := ClientRect;

  if PtInRect(R3, p) and (FModusSquare = True) then
  begin
    Down := False;
    with Canvas do
    begin
      Lock;
      try
        Pen.Color := clNavy;
        RoundRect(3,3,47,47,8,8);
        DrawFocusRect(ClientRect);
        Font.Style := [fsBold];
        TextOut(20,17,FText);
      finally
        Unlock;
      end;
    end;
    Exit;
  end;

  if PtInRect(R2, p) and (FModusSquare = False) then
  begin
    Down := False;
    Canvas.Lock;
    try
      Canvas.Draw(0,0,knopUp);
    finally
      Canvas.Unlock;
    end;
  end;
end;

procedure TjanSimButton.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  p, md: TPoint;
  R2: TRect;
  Grid: TjanGridS;
  SnapP: TPoint;
  WorkR: TRect;
begin
  inherited;

  R2 := ButtonPushZone(Self);
  md := Point(X, Y);

  if not PtInRect(R2, md) then
    Down := False;

  if FLock = True then Exit;
  if FDepressed then Exit;
  if Parent = nil then Exit;

  p := ClientToScreen(Point(X, Y));
  p := Parent.ScreenToClient(p);

  if (ssLeft in Shift) then
  begin
    if doMove then
    begin
      NewLeft := p.X - mdp.X;
      NewTop := p.Y - mdp.Y;

      if Parent is TjanGridS then
      begin
        Grid := TjanGridS(Parent);
        WorkR := Grid.GetWorkAreaRect;

        // neem middenpunt van het object
        SnapP := Point(NewLeft + Width div 2, NewTop + Height div 2);

        // magnetisch snappen aan ruler/grid
        SnapP := Grid.SnapPointToRuler(SnapP, WorkR);

        // terug omzetten naar Left/Top
        NewLeft := SnapP.X - Width div 2;
        NewTop := SnapP.Y - Height div 2;
      end;

      StraightenWires(connectors,newleft,newtop); SnapToRail(Self,newleft);
      Left := NewLeft;
      Top := NewTop;
      MoveConnectors;

      if Parent is TjanGridS then
        TjanGridS(Parent).UpdateGuideLines(Left + Width div 2, Top + Height div 2);

      FMouseOver := True;
      SendXYmoveToBar;
    end;
  end;
end;
{
procedure TjanSimButton.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  p, md: TPoint;
  R2: TRect;
begin
  inherited;

  R2 := ButtonPushZone(Self);
  md := Point(X, Y);

  if not PtInRect(R2, md) then
    Down := False;

  if FLock = True then Exit;
  if FDepressed then Exit;
  if Parent = nil then Exit;

  p := ClientToScreen(Point(X, Y));
  p := Parent.ScreenToClient(p);

  if (ssLeft in Shift) then
  begin
    if doMove then
    begin
      NewLeft := p.X - mdp.X;
      NewTop := p.Y - mdp.Y;

      StraightenWires(connectors,newleft,newtop); SnapToRail(Self,newleft);
      Left := NewLeft;
      Top := NewTop;
      MoveConnectors;

      if Parent is TjanGridS then
        TjanGridS(Parent).UpdateGuideLines(Left + Width div 2, Top + Height div 2);

      FMouseOver := True;
      SendXYmoveToBar;
    end;
  end;
end;}




procedure TjanSimButton.MoveConnectors;
var i:integer;
    con:TjanConnector;
begin
  select:=true;
  if connectors.Count=0 then exit;
  for i:=0 to connectors.count-1 do
  begin
    con:=TjanConnector(connectors[i]);
    con.MoveConnector(point(newleft,newtop));
  end;
end;

procedure TjanSimButton.Paint;
var p:Tpoint;
R:TRect;
begin
If FModusSquare=true then
 begin
  with canvas do
   begin
   Lock;
   brush.style:=bssolid;
   if FDepressed or FDown then
     begin
     R:=ClientRect;
     pen.Color:=clred;
     canvas.RoundRect(3,3,47,47,8,8);
     DrawFocusRect(R);

     end
     else
     begin
     pen.Color:=clNavy;
     canvas.RoundRect(3,3,47,47,8,8);
     end;
   Font.Style:= [fsBold];
   Font.Color:=clNavy;
   TextOut(20,17,FText);
   Unlock;
   end;
 end
 else
 Begin
 knopUp.Transparent:=true;
 knopDown.Transparent:=true;
 with canvas do
   begin
   Lock;
     if FDepressed or FDown then
      begin
       PaintInputSymbol(Self,Canvas,knopDown,0,True);
       brush.style:=bsclear;
       Font.Name:='Arial';Font.Size:=9;
       Font.Style:= [fsBold];Font.Color:=clRed;
       TextOut(50,14,'1');
      end
     else
      begin
       PaintInputSymbol(Self,Canvas,knopUp,0,False);
       brush.style:=bsclear;
       Font.Name:='Arial';Font.Size:=9;
       Font.Style:= [fsBold];Font.Color:=clNavy;
       TextOut(50,14,'0');
      end;
    Unlock;
   end;
   // tekenen van selectie kader
   if select=true then
     begin
     with canvas do
      begin
      R:=ClientRect;
      pen.Color:=clblack;
      pen.style:=psDot;
      Lock;rectangle(R);Unlock;
      pen.Color:=clSilver;pen.style:=psSolid;
      end;
     end;
    // tekenen van rode kader na selectie via popupmenu
     if FSelected then
  begin
    R := ClientRect;
   // InflateRect(R, -1, -1);         // binnen de rand tekenen

    Canvas.Brush.Style := bsClear;
    Canvas.Pen.Color := clRed;
    Canvas.pen.style:=psDot;
    Canvas.Pen.Width := 1;
    Canvas.Rectangle(R);

    // restore (netjes)
     Canvas.Pen.Width := 1;
     Canvas.pen.style:=psSolid;
     Canvas.Brush.Style := bsSolid;
  end;
 end;
end;

procedure TjanSimButton.PaintLed(pt:TPoint;lit:boolean);
var surfcol,litcol:Tcolor;
    x,y:integer;
begin
  x:=pt.x;
  y:=pt.y- 5;
  if lit then
  begin
    surfcol:=clred;
    litcol:=clwhite
  end
  else
  begin
    surfcol:=clmaroon;
    litcol:=clred;
  end;
  with Canvas do begin
    lock;
    brush.style:=bsclear;
    fillrect(rect(x,y,x+12,y+13));
    brush.style:=bsclear;
    pen.color:=clgray;
    ellipse(x,y,x+12,y+13);
    pen.color:=clblack;
    brush.color:=surfcol;
    ellipse(x+1,y+1,x+11,y+12);
    pen.color:=clwhite;
    arc(x+1,y+1,x+11,y+12,x+0,y+12,x+12,y+0);
    pen.color:=litcol;
    arc(x+3,y+3,x+8,y+9,x+5,y+0,x+0,y+8);
    unlock;
   end;
end;

procedure TjanSimButton.Resize;
begin
If FModusSquare=true then
     begin
     width:=50;height:=50;
     end
     else
     Begin
     width:=58;height:=32;
     end;
end;

procedure TjanSimButton.SetDown(const Value: Boolean);
begin
  if Value = FDown then Exit;   // ✅ alleen bij echte verandering

  FDown := Value;
  FDepressed := Value;

  if FDown then
    FStatButton := stButtonStop
  else
    FStatButton := stButtonStart;

  Invalidate;

  // ✅ Onmiddellijke refresh als muis erboven staat
  if FMouseOver then
    SendStatusToBar;

  // ✅ event alleen bij echte wijziging
  if Assigned(FOnStatButtonChange) then
    FOnStatButtonChange(Self, FStatButton);
end;


{
procedure TjanSimButton.SetDown(const Value: boolean);
begin
  if value<>FDown then
  begin
    FDown := Value;
    FDepressed:=value;
    // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
    If FDown=true then FStatButton := stButtonStop else FStatButton := stButtonStart;
  invalidate;
  end;
if Assigned(OnButtonChange) then OnButtonChange(Self, StatButton);
end;}

procedure TjanSimButton.SetModus(const Value: boolean);
begin
  if value<>FModus then
  begin
    FModus := Value;
    If FModus=true then
     begin
     KnopUp.LoadFromResourceName(HInstance,'DRUK_UITS');
     KnopDown.LoadFromResourceName(HInstance,'DRUK_INS');
     end
     else
     Begin
     KnopUp.LoadFromResourceName(HInstance,'DRUK_UIT');
     KnopDown.LoadFromResourceName(HInstance,'DRUK__IN');
     end;
  invalidate;
  end;
end;

procedure TjanSimButton.SetModusSquare(const Value: boolean);
begin
  if value<>FModusSquare then
  begin
    FModusSquare := Value;
    If FModusSquare=true then
     begin
     width:=50;height:=50;
     end
     else
     Begin
     width:=58;height:=32;

     end;
  invalidate;
  end;
end;

procedure TjanSimButton.SetActiv(const Value: boolean);
begin
  if value<>FActiv then
  begin
    FActiv := Value;
  end;
invalidate;
end;

procedure TjanSimButton.SetRuntime(const Value: boolean);
begin
  if value<>FRuntime then
  begin
    FRuntime := Value;
  end;
invalidate;
end;

procedure TjanSimButton.SetConnectie(const Value: boolean);
var
WC:TWinControl;
L,T:integer;
begin
  if value<>FConnectie then
  begin
    FConnectie := Value;
  end;
  if Value=true then
  begin
   wc:=parent;
   L:=left + width -8;T:=top+7;
   Maakdraad(T,L,wc);
  end;
invalidate;
end;

procedure TjanSimButton.SetAction(aktie: TAction);
begin
  if aktie<>FAction then
  begin
    FAction := aktie;
  end;
//invalidate;
end;

procedure TjanSimButton.CMMouseLeave(var Msg: TMessage);
begin
   inherited;
  FMouseOver := False;
  if Assigned(FOnStatus) then
    Begin
    FOnStatus(Self, '', 0);
    FOnStatus(Self, '', 1);
    FOnStatus(Self, '', 2);
    FOnStatus(Self, '', 3);
    end;
    invalidate;
   if not FLock then
   begin
    select:=false;
    invalidate;
   end;
end;


procedure TjanSimButton.CMMouseEnter(var Msg: TMessage);
var
 s:string;
begin
  inherited;
   UpdateHintText;
   // laat status en x,y van object verschijnen in Main StatusBar Panel 1
   FMouseOver := True;
   SendStatusToBar;

  if Assigned(FOnEnter) then
    FOnEnter(Self);

  BringToFront;

  if not FLock then
  begin
    Select := True;
    Invalidate;
  end;
end;


procedure TjanSimButton.ButtonClick1(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanSimButton.ButtonClick3(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;

procedure TjanSimButton.ButtonClick4(Sender: TObject);
begin
  if Assigned(FBox) then
    FBox.SelectObject(Self);
end;

procedure TjanSimButton.ButtonNClick(Sender: TObject);
var
  dlg: TInputBoxForm;
  s: string;
begin
  dlg := TInputBoxForm.Create(nil);
  try
    if dlg.Execute('Naam wijzigen', 'Geef een naam:', Naam, s) then
      Naam := s;  // setter -> Invalidate
  finally
    dlg.Free;
  end;
  UpdateHintText;
end;

procedure TjanSimButton.SetLock(const Value: boolean);
begin
  if value<>FLock then
  begin
    FLock := Value;
 end;
end;

procedure TjanSimButton.SetPuls(const Value: Integer);
begin
  if value<>FPuls then
  begin
    FPuls:= Value;
 end;
end;

procedure TjanSimButton.SendXYmoveToBar;
var
LB: TjanSimLogicBox;
  C: TComponent;
s:string;
begin
// Zoek LogicBox via Owner-keten (werkt ook als Owner niet direct de box is)
  LB := nil;
  C := Owner;
  while (C <> nil) and (LB = nil) do
  begin
    if C is TjanSimLogicBox then
      LB := TjanSimLogicBox(C)
    else
      C := C.Owner;
  end;
  if LB = nil then Exit;
 s:= Format('X=%d Y=%d', [Left, Top]);
 LB.PushStatus(Self, s, 2);
end;

procedure TjanSimButton.SendStatusToBar;
var
  s, ss: string;
  wInput, wStatus,
  wT1,wT0: string;
  LB: TjanSimLogicBox;
  C: TComponent;
begin
  // Zoek LogicBox via Owner-keten (werkt ook als Owner niet direct de box is)
  LB := nil;
  C := Owner;
  while (C <> nil) and (LB = nil) do
  begin
    if C is TjanSimLogicBox then
      LB := TjanSimLogicBox(C)
    else
      C := C.Owner;
  end;

  if LB = nil then Exit;

  wInput  := Tr(BTaal,'Invoer','Input','Entrée','Eingang');

  wStatus := Tr(BTaal,'Drukknop','Push button','Bouton poussoir','Druckknopf');

  wT1:=Tr(BTaal,'Omlaag','Down','Vers le bas','Runter');

  wT0:=Tr(BTaal,'Omhoog','Upwards','Vers le haut','Nach oben');


  LB.PushStatus(Self, FNaam , 0);

  if FDown then
    s := wStatus + ' = ' + wT1
  else
    s := wStatus + ' = ' + wT0;

  LB.PushStatus(Self, s, 1);

  ss := Format('X=%d Y=%d', [Left, Top]);

  LB.PushStatus(Self, ss, 2);
end;

procedure TjanSimButton.UpdateHintText;
begin
  Hint := BuildSimHint(FNaam, BTaal);
end;

procedure TjanSimButton.SetTaal(const Value: String);
begin
  if value<>FTaal then
  begin
    FTaal:= Value;
 end;
 if value='NL' then FInfo:=FNaam
 else if value='ENG' then FInfo:='Push button'
 else if value='FR' then FInfo:= 'Poussoir'
 else if value='DU' then FInfo:= 'Druckknopf';
invalidate;
end;

procedure TjanSimButton.SetText(const Value: String);
begin
  if value<>FText then
  begin
    FText := Value;
    invalidate;
 end;
end;
procedure TjanSimButton.SetInfo(const Value: String);
begin
  if value<>FInfo then
  begin
    FInfo := Value;
 end;
end;
procedure TjanSimButton.Setdraad(const Value: boolean);
begin
  if value<>FDraad then
  begin
    Fdraad := Value;
 end;
end;

procedure TjanSimButton.SetNaam(const Value: String);
begin
   if FNaam <> Value then
  begin
    FNaam := Value;
    Invalidate;
  end;
end;


{ TjanSimKnop }


procedure TjanSimKnop.AnchorConnectors;
var wc:TWincontrol;
    i:integer;
    con:TjanConnector;
    R:TRect;
    p:TPoint;
begin
  wc:=parent;
  connectors.Clear;
  R:=boundsrect;
  inflateRect(R,8,8);
  p:=point(left,top);
  for i:=0 to wc.ControlCount-1 do
    if (wc.controls[i] is TjanConnector) then
    begin
      con:=TjanConnector(wc.controls[i]);
      // alleen de echte uiteinden van de draad (zie TjanConnector.AnchorToRect)
      if con.AnchorToRect(R,p) then
        connectors.Add(con);
    end;
end;

procedure TjanSimKnop.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
   FMouseOver := False;

   if Assigned(FOnStatus) then
   begin
     FOnStatus(Self, '', 0);
     FOnStatus(Self, '', 1);
     FOnStatus(Self, '', 2);
     FOnStatus(Self, '', 3);
   end;

    if Assigned(FOnExit) then
    FOnExit(Self);

   if Flock=false then begin select:=false;invalidate;end;
end;

procedure TjanSimKnop.CMMouseEnter(var Msg: TMessage);
var
 s:String;
begin
  inherited;
  UpdateHintText;

  if Assigned(FOnEnter) then
  FOnEnter(Self);

   // laat status en x,y van object verschijnen in Main StatusBar Panel 1

   FMouseOver := True;
   SendStatusToBar;

   if Assigned(FOnEnter) then
    FOnEnter(Self);


  BringToFront;
  if not FLock then
  begin
    Select := True;
    Invalidate;
  end;
end;


constructor TjanSimKnop.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  HelpKeyword := 'schakelaar';
  Select:=false;
  FDown:=false;
  width:=51;
  height:=50;
  connectors:=TList.create;
  KnopUp:=TBitmap.Create;
  KnopUp.LoadFromResourceName(HInstance,'SCHAK_UIT');
  KnopUp.Transparent := True;
  KnopUp.TransParentColor := KnopUp.canvas.pixels[0,0];
  KnopDown:=TBitmap.Create;
  KnopDown.LoadFromResourceName(HInstance,'SCHAK__IN');
  KnopDown.Transparent := True;
  KnopDown.TransParentColor := KnopDown.canvas.pixels[0,0];
 // FTaal:='NL';
  FInfo:= 'Schakelaar';
  ShowHint:=true;
  FSoort:='Invoer';
  FNaam:='Schakelaar';
end;

destructor TjanSimKnop.Destroy;
begin
  knopUp.Free;
  knopDown.Free;
  connectors.free;
  inherited;
end;

procedure TjanSimKnop.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  R, R2: TRect;
  p: TPoint;
  wc: TWinControl;
  L, T: Integer;
begin
  inherited;

  // Rechtsklik: popup tonen en stoppen
  if (Button = mbRight) and (FLock = False) then
  begin
    BuildPopup;
    UpdatePopupCaptions;

    p := Point(0, Height);
    p := ClientToScreen(p);
    PopupMenu.Popup(p.X, p.Y - 1);
    Exit;
  end;

  mdp := Point(X, Y);
  R := Rect(42,20,51,50);

  // maken van aansluitdraad
  if PtInRect(R, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + Width - 8;
    T := Top + 21;
    Maakdraad(T, L, wc);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;

  Screen.Cursor := crDefault;

  // einde van het maken van een aansluiting
  R2 := Rect(2,12,14,37);
  doMove := not PtInRect(R2, mdp);
  FDepressed := not doMove;
  oldp := Point(X, Y);

  if doMove then
  begin
    AnchorConnectors;

    // GuideLines enkel starten bij echt bewegen
    if (Button = mbLeft) and (Parent is TjanGridS) then
      TjanGridS(Parent).BeginGuideLines(Left + Width div 2, Top + Height div 2);
  end
  else
    Invalidate;
end;

procedure TjanSimKnop.BuildPopup;
        var
        miLock, miName, miInfo, miSelect: TMenuItem;
       begin
         if not Assigned(PopupMenu) then
           PopupMenu := TPopupMenu.Create(Self)
         else
           PopupMenu.Items.Clear;
         // --- Lock / Unlock
          miLock := TMenuItem.Create(PopupMenu);
          miLock.Name := 'miLock';
          miLock.OnClick := ButtonClick1;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miLock);

         // --- Naam wijzigen
          miName := TMenuItem.Create(PopupMenu);
          miName.Name := 'miName';
          miName.OnClick := ButtonNClick;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miName);

         // --- Info aan/uit
          miInfo := TMenuItem.Create(PopupMenu);
          miInfo.Name := 'miInfo';
          miInfo.OnClick := ButtonClick3;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miInfo);

          // --- Selecteer voor verwijdering
          miSelect := TMenuItem.Create(PopupMenu);
          miSelect.Name := 'miSelect';
          miSelect.OnClick := ButtonClick4;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miSelect);

       end;

       procedure TjanSimKnop.UpdatePopupCaptions;
       var
         miLock, miName, miInfo, miSelect: TMenuItem;
         s: string;
       begin
         if not Assigned(PopupMenu) then Exit;

         miLock   := TMenuItem(PopupMenu.FindComponent('miLock'));
         miName   := TMenuItem(PopupMenu.FindComponent('miName'));
         miInfo   := TMenuItem(PopupMenu.FindComponent('miInfo'));
         miSelect := TMenuItem(PopupMenu.FindComponent('miSelect'));

         // --- Lock / Unlock
         if Assigned(miLock) then
         begin
           if BTaal = 'NL' then
           begin
             if FLock then s := 'Ontgrendel' else s := 'Vergrendel';
           end
           else if BTaal = 'FR' then
           begin
             if FLock then s := 'Déverrouiller' else s := 'Verrouiller';
           end
           else if BTaal = 'DU' then
           begin
             if FLock then s := 'Entsperren' else s := 'Sperren';
           end
           else
           begin
             if FLock then s := 'UnLock' else s := 'Lock';
           end;
           miLock.Caption := LangTr(s);
         end;

         // --- Naam wijzigen
         if Assigned(miName) then
         begin
           if BTaal = 'NL' then s := 'Wijzig Naam'
           else if BTaal = 'FR' then s := 'Changer le nom'
           else if BTaal = 'DU' then s := 'Namen ändern'
           else s := 'Change name';
           miName.Caption := LangTr(s);
         end;

         // --- Select / Deselect (TOGGLE)
         if Assigned(miSelect) then
         begin
           if not Selected then
           begin
             if BTaal = 'NL' then s := 'Selecteer object'
             else if BTaal = 'FR' then s := 'Sélectionner un objet'
             else if BTaal = 'DU' then s := 'Objekt auswählen'
             else s := 'Select object';
           end
           else
           begin
             if BTaal = 'NL' then s := 'Deselecteer object'
             else if BTaal = 'FR' then s := 'Désélectionner l''objet'
             else if BTaal = 'DU' then s := 'Objekt abwählen'
             else s := 'Deselect object';
           end;
           miSelect.Caption := LangTr(s);
         end;

         // --- Info aan/uit
         if Assigned(miInfo) then
         begin
           if ShowHint then
           begin
             if BTaal = 'NL' then s := 'Info uit'
             else if BTaal = 'FR' then s := 'Infos off'
             else if BTaal = 'DU' then s := 'Infos aus'
             else s := 'Information off';
           end
           else
           begin
             if BTaal = 'NL' then s := 'Info aan'
             else if BTaal = 'FR' then s := 'Infos on'
             else if BTaal = 'DU' then s := 'Infos an'
             else s := 'Information on';
           end;
           miInfo.Caption := LangTr(s);
         end;
       end;


       procedure TjanSimKnop.MouseUp(Button: TMouseButton; Shift: TShiftState;
         X, Y: Integer);
       var
         R: TRect;
         p: TPoint;
       begin
         inherited;

         if Parent is TjanGridS then
           TjanGridS(Parent).EndGuideLines;

         Select := False;
         Repaint;
         FDepressed := False;

         p := Point(X, Y);
         R := Rect(2,12,14,37);

         if PtInRect(R, p) then
           Down := not Down;

         FMouseOver := True;
         SendStatusToBar;
       end;


procedure TjanSimKnop.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  p: TPoint;
  Grid: TjanGridS;
  SnapP: TPoint;
  WorkR: TRect;
begin
  inherited;

  if FLock = True then Exit;
  if FDepressed then Exit;
  if Parent = nil then Exit;

  p := ClientToScreen(Point(X, Y));
  p := Parent.ScreenToClient(p);

  if (ssLeft in Shift) then
  begin
    if doMove then
    begin
      NewLeft := p.X - mdp.X;
      NewTop := p.Y - mdp.Y;

      if Parent is TjanGridS then
      begin
        Grid := TjanGridS(Parent);
        WorkR := Grid.GetWorkAreaRect;

        // middenpunt van het object nemen
        SnapP := Point(NewLeft + Width div 2, NewTop + Height div 2);

        // magnetisch snappen op ruler/grid
        SnapP := Grid.SnapPointToRuler(SnapP, WorkR);

        // terug omzetten naar linkerbovenhoek
        NewLeft := SnapP.X - Width div 2;
        NewTop := SnapP.Y - Height div 2;
      end;

      StraightenWires(connectors,newleft,newtop); SnapToRail(Self,newleft);
      Left := NewLeft;
      Top := NewTop;

      MoveConnectors;

      if Parent is TjanGridS then
        TjanGridS(Parent).UpdateGuideLines(Left + Width div 2, Top + Height div 2);

      FMouseOver := True;
      SendXYmoveToBar;
    end;
  end;
end;



procedure TjanSimKnop.MoveConnectors;
var i:integer;
    con:TjanConnector;
begin
  Select:=true;
  if connectors.Count=0 then exit;
  for i:=0 to connectors.count-1 do
  begin
    con:=TjanConnector(connectors[i]);
    con.MoveConnector(point(newleft,newtop));
  end;
end;

procedure TjanSimKnop.Paint;
var p:Tpoint;
    R:TRect;
begin
   with canvas do
   begin
    Lock;
    R:=ClientRect;
    inflaterect(R,-3,-5);
    knopDown.Transparent:=true;
    knopUp.Transparent:=true;;
     if FDepressed or FDown then
       begin
            PaintInputSymbol(Self,Canvas,knopDown,1,True);
            brush.style:=bsclear;
            Font.Name:='Arial';Font.Size:=9;Font.Style:= [fsBold];
            Font.Color:=clRed;
            TextOut(42,29,'1');
       end
       else
       begin
            PaintInputSymbol(Self,Canvas,knopUp,1,False);
            brush.style:=bsclear;
            Font.Name:='Arial';Font.Size:=9;Font.Style:= [fsBold];
            Font.Color:=clNavy;
            TextOut(42,29,'0');
       end;

   unlock;
   end;
   if select=true then
     begin
       with canvas do
        begin
         R:=ClientRect;
         pen.Color:=clblack;
         pen.style:=psDot;
         Lock;rectangle(R);Unlock;
         pen.Color:=clSilver;pen.style:=psSolid;
        end;
     end;
   // tekenen van rode kader na selectie via popupmenu in paint onderaan
   if FSelected then
     begin
       R := ClientRect;
     // InflateRect(R, -1, -1);         // binnen de rand tekenen
      Canvas.Brush.Style := bsClear;
      Canvas.Pen.Color := clRed;
      Canvas.pen.style:=psDot;
      Canvas.Pen.Width := 1;
      Canvas.Rectangle(R);
      // restore (netjes)
      Canvas.Pen.Width := 1;
      Canvas.pen.style:=psSolid;
      Canvas.Brush.Style := bsSolid;
     end;
end;

procedure TjanSimKnop.PaintLed(pt:TPoint;lit:boolean);
var surfcol,litcol:Tcolor;
    x,y:integer;
begin
  x:=pt.x;
  y:=pt.y;
  if lit then
  begin
    surfcol:=clred;
    litcol:=clwhite;
  end
  else
  begin
    surfcol:=clmaroon;
    litcol:=clred;
  end;
  with Canvas do begin
    Lock;
    brush.style:=bsclear;
    fillrect(rect(x,y,x+12,y+13));
    brush.style:=bsclear;
    pen.color:=clgray;
    ellipse(x,y,x+12,y+13);
    pen.color:=clblack;
    brush.color:=surfcol;
    ellipse(x+1,y+1,x+11,y+12);
    pen.color:=clwhite;
    arc(x+1,y+1,x+11,y+12,x+0,y+12,x+12,y+0);
    pen.color:=litcol;
    arc(x+3,y+3,x+8,y+9,x+5,y+0,x+0,y+8);
    Unlock;
   end;
end;

procedure TjanSimKnop.Resize;
begin
  width:=51;
  height:=50;
end;

//new
procedure TjanSimKnop.ButtonClick1(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanSimKnop.ButtonClick3(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;

procedure TjanSimKnop.ButtonNClick(Sender: TObject);
var
  dlg: TInputBoxForm;
  s: string;
begin
  dlg := TInputBoxForm.Create(nil);
  try
    if dlg.Execute('Naam wijzigen', 'Geef een naam:', Naam, s) then
      Naam := s;  // setter -> Invalidate
  finally
    dlg.Free;
  end;
  UpdateHintText;
end;

procedure TjanSimKnop.ButtonClick4(sender:TObject); // selecteer object
begin
   if Assigned(FBox) then
    FBox.SelectObject(Self);
end;



procedure TjanSimKnop.SetDown(const Value: boolean);
begin
  if value<>FDown then
  begin
   FDown := Value;
   FDepressed:=value;
   puls:=1;
   invalidate;

    // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
  end;
end;
procedure TjanSimKnop.SetInfo(const Value: String);
begin
  if value<>FInfo then
  begin
    FInfo := Value;
 end;
end;


procedure TjanSimKnop.SetLock(const Value: boolean);
begin
  if value<>FLock then
  begin
    FLock := Value;
 end;
end;

procedure TjanSimKnop.SetPuls(const Value: Integer);
begin
  if value<>FPuls then
  begin
    FPuls:= Value;
 end;
end;

procedure TjanSimKnop.SendXYmoveToBar;
var
LB: TjanSimLogicBox;
  C: TComponent;
s:string;
begin
// Zoek LogicBox via Owner-keten (werkt ook als Owner niet direct de box is)
  LB := nil;
  C := Owner;
  while (C <> nil) and (LB = nil) do
  begin
    if C is TjanSimLogicBox then
      LB := TjanSimLogicBox(C)
    else
      C := C.Owner;
  end;
  if LB = nil then Exit;
 s:= Format('X=%d Y=%d', [Left, Top]);
 LB.PushStatus(Self, s, 2);
end;


procedure TjanSimKnop.SendStatusToBar;
var
  s, ss: string;
  wInput, wStatus: string;
begin
  if not Assigned(FOnStatus) then Exit;

  wInput  := Tr(BTaal,'Invoer','Input','Entrée','Eingang');
  wStatus := Tr(BTaal,'Status','Status','Statut','Status');

  // Panel 0
 FOnStatus(Self, FNaam + ' > ', 0);

  // Panel 1
  if FDown then
    s := wStatus + ' = 1'
  else
    s := wStatus + ' = 0';
  FOnStatus(Self, s, 1);

  // Panel 2
  ss := Format('X=%d Y=%d', [Left, Top]);
  FOnStatus(Self, ss, 2);
end;


procedure TjanSimKnop.UpdateHintText;
begin
  Hint := BuildSimHint(FNaam, BTaal);
end;

procedure TjanSimKnop.SetNaam(const Value: String);
begin
   if FNaam <> Value then
  begin
    FNaam := Value;
    Invalidate;
  end;
end;

procedure TjanSimKnop.SetTaal(const Value: String);
begin
  if value<>FTaal then
  begin
    FTaal:= Value;
 end;
 if value='NL' then FInfo:='schakelaar'
 else if value='ENG' then FInfo:='switch'
 else if value='DU' then FInfo:='Schalter'
 else if value='FR' then FInfo:= 'l´interrupteur';
invalidate;
end;

{ TjanDipSwitsh }

procedure TjanDipSwitsh.SendStatusToBar;
 var
   s, ss: string;
   wInput, wStatus: string;
 begin
   if not Assigned(FOnStatus) then Exit;

   wInput  := Tr(BTaal,'Invoer','Input','Entrée','Eingang');
   wStatus := Tr(BTaal,'Status','Status','Statut','Status');

   // Panel 0
  FOnStatus(Self, FNaam + ' > ', 0);

   // Panel 1
   if FDown then
     s := wStatus + ' = 1'
   else
     s := wStatus + ' = 0';
   FOnStatus(Self, s, 1);

   // Panel 2
   ss := Format('X=%d Y=%d', [Left, Top]);
   FOnStatus(Self, ss, 2);
 end;

 procedure TjanDipSwitsh.UpdateHintText;
 begin
   Hint := BuildSimHint(FNaam, BTaal);
 end;

procedure TjanDipSwitsh.SetNaam(const Value: String);
begin
   if FNaam <> Value then
  begin
    FNaam := Value;
    Invalidate;
    // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
  end;
end;

procedure TjanDipSwitsh.SetTaal(const Value: String);
begin
  if value<>FTaal then
  begin
    FTaal:= Value;
 end;
 if value='NL' then FInfo:='Dipschakelaar'
 else if value='ENG' then FInfo:='DipSwitsh'
 else if value='FR' then FInfo:= 'Commutateur DIP'
 else if value='DU' then FInfo:= 'DipSwitch';

 invalidate;

// ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
end;

procedure TjanDipSwitsh.SetInfo(const Value: String);
begin
   if value<>FInfo then
  begin
    FInfo := Value;
 end;
end;

procedure TjanDipSwitsh.CMMouseLeave(var Msg: TMessage);
begin
   inherited;
  if not FMouseOver then Exit;     // kleine guard
     FMouseOver := False;

 // ✅ statusbar leegmaken (zoals bij TjanSimButton)
 if Assigned(FOnStatus) then
 begin
   FOnStatus(Self, '', 0);
   FOnStatus(Self, '', 1);
   FOnStatus(Self, '', 2);
   FOnStatus(Self, '', 3);
 end;
 if Flock=false then begin select:=false;invalidate;end;
end;



procedure TjanDipSwitsh.CMMouseEnter(var Msg: TMessage);
var
s:String;
begin
  inherited;
   UpdateHintText;
   // ✅ statusbar meteen vullen
  FMouseOver := True;
  SendStatusToBar;  // vult panel 0/1/2
  if Assigned(FOnEnter) then
    FOnEnter(Self);
  BringToFront;
  if not FLock then
  begin
    Select := True;
    Invalidate;
  end;
 end;

procedure TjanDipSwitsh.CMHitTest(var Message: TCMHitTest);
 begin
 inherited;
   {Message.Result := 0;
   if Canvas.Pixels[Message.XPos, Message.YPos] = clLime then
    begin
    Message.Result := 1;SendToBack;exit;
    end;
   if Canvas.Pixels[Message.XPos, Message.YPos] <> clLime then
    begin
    Message.Result := 1;BringToFront;exit;
    end;}
end;

procedure TjanDipSwitsh.AnchorConnectors;
var wc:TWincontrol;
    i:integer;
    con:TjanConnector;
    R:TRect;
    p:TPoint;
begin
  wc:=parent;
  connectors.Clear;
  R:=boundsrect;
  inflateRect(R,8,8);
  p:=point(left,top);
  for i:=0 to wc.ControlCount-1 do
    if (wc.controls[i] is TjanConnector) then
    begin
      con:=TjanConnector(wc.controls[i]);
      // alleen de echte uiteinden van de draad (zie TjanConnector.AnchorToRect)
      if con.AnchorToRect(R,p) then
        connectors.Add(con);
    end;
end;

constructor TjanDipSwitsh.Create(AOwner: TComponent);
var
 XX, YY: Integer;
 PixelColor: TColor;
begin
  inherited Create(AOwner);
  Select:=false;
  // initialize (imputs)
  FGates[0].pos:=point(120,64); FGates[0].Active:=true;    // reset
  FStatDip := stDipStop;
  FDown8:=false;FDown4:=false;FDown2:=false;FDown1:=false;
  FStart := false;
  width:=130;height:=80;
  connectors:=TList.create;

  KnopUp:=TBitmap.Create;
  KnopUp.LoadFromResourceName(HInstance,'DI_UIT');
  for YY := 0 to KnopUp.Height - 1 do
      for XX := 0 to KnopUp.Width - 1 do
      begin
        PixelColor := KnopUp.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          KnopUp.Canvas.Pixels[XX, YY] := clFuchsia;
        end;
      end;
  KnopUp.Transparent := True;
  KnopUp.TransParentColor := clFuchsia;

  KnopDown:=TBitmap.Create;
  KnopDown.LoadFromResourceName(HInstance,'DI_AAN');
  for YY := 0 to KnopDown.Height - 1 do
      for XX := 0 to KnopUp.Width - 1 do
      begin
        PixelColor := KnopDown.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          KnopDown.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  KnopDown.Transparent := True;
  KnopDown.TransParentColor := clFuchsia;//:= KnopDown.canvas.pixels[0,0];

  DrukUp:=TBitmap.Create;
  DrukUp.LoadFromResourceName(HInstance,'DRUKUP');
  for YY := 0 to DrukUp.Height - 1 do
      for XX := 0 to KnopUp.Width - 1 do
      begin
        PixelColor := DrukUp.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          DrukUp.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  DrukUp.Transparent := True;
  DrukUp.TransParentColor:= clFuchsia;// := DrukUp.canvas.pixels[0,0];

  DrukDown:=TBitmap.Create;
  DrukDown.LoadFromResourceName(HInstance,'DRUKDOWN');
  for YY := 0 to DrukDown.Height - 1 do
      for XX := 0 to KnopUp.Width - 1 do
      begin
        PixelColor := DrukDown.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          DrukDown.Canvas.Pixels[XX, YY] := clFuchsia;
        end;
      end;
  DrukDown.Transparent := True;
  DrukDown.TransParentColor := clFuchsia;//:= DrukDown.canvas.pixels[0,0];

  Ingang:=TBitmap.Create;
  Ingang.LoadFromResourceName(HInstance,'IN');
  for YY := 0 to Ingang.Height - 1 do
      for XX := 0 to Ingang.Width - 1 do
      begin
        PixelColor := Ingang.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          Ingang.Canvas.Pixels[XX, YY] := clFuchsia;
        end;
      end;
  Ingang.Transparent := True;
  Ingang.TransParentColor := clFuchsia;

  Connectoren:=TBitmap.Create;
  Connectoren.LoadFromResourceName(HInstance,'UIT');
  for YY := 0 to Connectoren.Height - 1 do
      for XX := 0 to Connectoren.Width - 1 do
      begin
        PixelColor := Connectoren.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          Connectoren.Canvas.Pixels[XX, YY] := clFuchsia;
        end;
      end;
  Connectoren.Transparent := True;
  Connectoren.TransParentColor := clFuchsia;
  FConnector:=true;

 // FTaal:='NL';
  FInfo:= 'DipSwitsh';
  ShowHint:=True;
  FSoort:='Invoer';
  FNaam:='DipSwitsh';
  FSelected:=false;
end;

destructor TjanDipSwitsh.Destroy;
begin
  knopUp.Free; knopDown.Free;drukup.Free;drukdown.Free;Ingang.Free;
  connectors.free;
  connectoren.Free;
  inherited;
end;

procedure TjanDipSwitsh.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  R, R8, R4, R2, R1, Rp, RD: TRect;
  p: TPoint;
  wc: TWinControl;
  L, T: Integer;
begin
  inherited;

  if (Button = mbRight) and (FLock = False) then
  begin
    BuildPopup;
    UpdatePopupCaptions;
    p := Point(0, Height);
    p := ClientToScreen(p);
    PopupMenu.Popup(p.X, p.Y - 1);
    Exit;
  end;

  mdp := Point(X, Y);

  RD := Rect(0,12,60,38);
  if PtInRect(RD, mdp) then
    Screen.Cursor := crDefault;

  R := Rect(120,64,128,72);
  if PtInRect(R, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + 122;
    T := Top + 66;
    Maakdraad(T, L, wc);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;

  Screen.Cursor := crDefault;

  Rp := Rect(87,58,109,80);
  R8 := Rect(0,12,15,37);
  R4 := Rect(16,12,30,37);
  R2 := Rect(31,12,45,37);
  R1 := Rect(46,12,60,37);

  // doMove alleen True als er NIET op een bedieningszone geklikt is
  doMove := not (
    PtInRect(Rp, mdp) or
    PtInRect(R8, mdp) or
    PtInRect(R4, mdp) or
    PtInRect(R2, mdp) or
    PtInRect(R1, mdp)
  );

  FDepressed  := PtInRect(Rp, mdp);
  FDepressed8 := PtInRect(R8, mdp);
  FDepressed4 := PtInRect(R4, mdp);
  FDepressed2 := PtInRect(R2, mdp);
  FDepressed1 := PtInRect(R1, mdp);

  if (FDepressed or FDown) then
    Down := True;

  oldp := Point(X, Y);

  if doMove then
  begin
    AnchorConnectors;

    if (Button = mbLeft) and (Parent is TjanGridS) then
      TjanGridS(Parent).BeginGuideLines(Left + Width div 2, Top + Height div 2);
  end
  else
  begin
    Screen.Cursor := crDefault;
    Invalidate;
  end;
end;

procedure TjanDipSwitsh.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  p: TPoint;
  Grid: TjanGridS;
  SnapP: TPoint;
  WorkR: TRect;
begin
  inherited;

  if FLock = True then Exit;

  if FDepressed8 or FDepressed4 or FDepressed2 or FDepressed1 or FDepressed then
  begin
    Screen.Cursor := crDefault;
    Exit;
  end;

  if Parent = nil then Exit;

  p := ClientToScreen(Point(X, Y));
  p := Parent.ScreenToClient(p);

  if (ssLeft in Shift) then
  begin
    if doMove then
    begin
      NewLeft := p.X - mdp.X;
      NewTop := p.Y - mdp.Y;

      if Parent is TjanGridS then
      begin
        Grid := TjanGridS(Parent);
        WorkR := Grid.GetWorkAreaRect;

        // snappen op het midden van het object
        SnapP := Point(NewLeft + Width div 2, NewTop + Height div 2);
        SnapP := Grid.SnapPointToRuler(SnapP, WorkR);

        NewLeft := SnapP.X - Width div 2;
        NewTop := SnapP.Y - Height div 2;
      end;

      StraightenWires(connectors,newleft,newtop); SnapToRail(Self,newleft);
      Left := NewLeft;
      Top := NewTop;
      MoveConnectors;

      if Parent is TjanGridS then
        TjanGridS(Parent).UpdateGuideLines(Left + Width div 2, Top + Height div 2);

      FMouseOver := True;
      SendStatusToBar;
    end;
  end;
end;

procedure TjanDipSwitsh.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  R8, R4, R2, R1, R: TRect;
  p: TPoint;
begin
  inherited;

  if Parent is TjanGridS then
    TjanGridS(Parent).EndGuideLines;

  Select := False;
  Repaint;

  FDepressed8 := False;
  FDepressed4 := False;
  FDepressed2 := False;
  FDepressed1 := False;
  FDepressed := False;

  p := Point(X, Y);

  R8 := Rect(1,12,15,37);
  if PtInRect(R8, p) then Down8 := not FDown8;

  R4 := Rect(16,12,30,37);
  if PtInRect(R4, p) then Down4 := not FDown4;

  R2 := Rect(31,12,45,37);
  if PtInRect(R2, p) then Down2 := not FDown2;

  R1 := Rect(46,12,60,37);
  if PtInRect(R1, p) then Down1 := not FDown1;

  R := Rect(87,58,109,80);
  if PtInRect(R, p) then
    Down := not FDown;

  if PtInRect(R, p) then
    FDown := False;

  FMouseOver := True;
  SendStatusToBar;
end;

{
procedure TjanDipSwitsh.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var R,R8,R4,R2,R1,Rp,RD:TRect;
p : TPoint;
pop:TPopupMenu;
ItemNew,ItemNew1,ItemNew2:TMenuItem;
S:String;
wc:TWinControl;
L,T:integer;
begin
  if (Button = mbRight) and (FLock = False) then
  begin
    BuildPopup;              // maakt PopupMenu 1x (als nog niet bestaat)
    UpdatePopupCaptions;     // past captions aan volgens taal/lock/showhint
    p := Point(0, Height);
    p := ClientToScreen(p);
    PopupMenu.Popup(p.X, p.Y - 1);
    Exit;
  end;

  mdp:=point(x,y);
  RD:=Rect(0,12,60,38);
   if (ptinrect(RD,mdp)) then screen.Cursor:=crDefault;
  R:=Rect(120,64,128,72);
  if (ptinrect(R,mdp)) and (screen.Cursor=crDraad) then
  begin
   wc:=parent;L:=left+ 122;T:=top + 66;
   Maakdraad(T,L,wc);doMove:=false;movecursor;BringToFront;exit;
  end;
  screen.Cursor:=crDefault;
  Rp:=Rect(87,58,109,80);
  doMove:= not (ptinrect(Rp,mdp));
  FDepressed:=not doMove;
  if (FDepressed or FDown) then Down:=true;

  R8:=Rect(0,12,15,37);
  doMove:= not (ptinrect(R8,mdp));
  FDepressed8:=not doMove;

  R4:=Rect(16,12,30,37);
  doMove:= not (ptinrect(R4,mdp));
  FDepressed4:=not doMove;

  R2:=Rect(31,12,45,37);
  doMove:= not (ptinrect(R2,mdp));
  FDepressed2:=not doMove;

  R1:=Rect(46,12,60,37);
  doMove:= not (ptinrect(R1,mdp));
  FDepressed1:=not doMove;

  oldp:=point(x,y);
  if doMove then
    begin

    AnchorConnectors;
    end
  else
    begin
    screen.cursor:=crDefault;
    invalidate;
    end;

  inherited MouseDown(Button, Shift, X, Y);
end;

procedure TjanDipSwitsh.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var R8,R4,R2,R1,R:TRect;
    p:Tpoint;
begin
  select:=false;repaint;
  FDepressed8:=false;FDepressed4:=false;FDepressed2:=false;
  FDepressed1:=false;FDepressed:=false;
  p:=point(x,y);
  R8:=Rect(1,12,15,37);if ptinrect(R8,p) then Down8:=not FDown8;
  R4:=Rect(16,12,30,37);if ptinrect(R4,p) then Down4:=not FDown4;
  R2:=Rect(31,12,45,37);if ptinrect(R2,p) then Down2:=not FDown2;
  R1:=Rect(46,12,60,37);if ptinrect(R1,p) then Down1:=not FDown1;
  R:=Rect(87,58,109,80);if ptinrect(R,p) then Down:=not FDown;



  if ptinrect(R,p) then FDown:=false;



    FMouseOver := True;
    SendStatusToBar;
end;

procedure TjanDipSwitsh.MouseMove(Shift: TShiftState; X, Y: Integer);
var p:TPoint;
begin
   if FLock=true then exit;
   if FDepressed8 or FDepressed4 or FDepressed2 or FDepressed1 or FDepressed then
      begin
       screen.cursor:=crDefault;exit;
      end;
   p:=clienttoscreen(point(x,y));
   p:=parent.ScreenToClient(p);
   if (ssleft in shift) then
   begin
     if doMove then
     begin
     newleft:=p.x-mdp.x;
     newtop:=p.y-mdp.y;
     MoveConnectors;
     StraightenWires(connectors,newleft,newtop); SnapToRail(Self,newleft);
     left:=newleft;
     top:=newtop;

     FMouseOver := True;
     SendStatusToBar;
     end
   end;
end;
 }



procedure TjanDipSwitsh.MoveConnectors;
var i:integer;
    con:TjanConnector;
begin
  select:=true;
  if connectors.Count=0 then exit;
  for i:=0 to connectors.count-1 do
  begin
    con:=TjanConnector(connectors[i]);
    con.MoveConnector(point(newleft,newtop));
  end;
end;

procedure TjanDipSwitsh.Paint;
var p:Tpoint;
    R:TRect;
begin
knopDown.Transparent:=true;
knopUp.Transparent:=true;
Connectoren.Transparent:=true;
DrukUp.Transparent:=true;
DrukDown.Transparent:=True;
Ingang.Transparent:=true;
   with canvas do
   begin
    Lock;
    R:=ClientRect;
    inflaterect(R,-3,-5);
     if FDepressed8 or FDown8 then begin draw(0,0,knopDown) end else Begin draw(0,0,knopUp);end;
     if FDepressed4 or FDown4 then begin draw(15,0,knopDown)end else Begin draw(15,0,knopUp);end;
     if FDepressed2 or FDown2 then begin draw(30,0,knopDown)end else Begin draw(30,0,knopUp);end;
     if FDepressed1 or FDown1 then begin draw(45,0,knopDown)end else Begin draw(45,0,knopUp);end;
     // de schakelaartjes zelf getekend (half-realistisch), de cijfers en
     // pijlen eronder blijven uit het plaatje
     DrawDipPicture(Canvas, Rect(0, 11, 15, 40), FDepressed8 or FDown8);
     DrawDipPicture(Canvas, Rect(15, 11, 30, 40), FDepressed4 or FDown4);
     DrawDipPicture(Canvas, Rect(30, 11, 45, 40), FDepressed2 or FDown2);
     DrawDipPicture(Canvas, Rect(45, 11, 60, 40), FDepressed1 or FDown1);
     moveto(9,height-20);lineto(70,height-20);moveto(70,20);lineto(113,20);
     moveto(70,20);lineto(70,68);moveto(113,20);lineto(113,68);moveto(70,68);lineto(width,68);
     moveto(8,60);lineto(70,60);
     if FConnector then
       begin draw(120,64,Connectoren);end;
     if (FDepressed or FDown) then
       draw(87,58,DrukDown)else draw(87,58,DrukUp);
     DrawButtonAt(Canvas, 87, 58, FDepressed or FDown);
     pen.Color:=clBlack;
     draw(91,15,Ingang);
     p:=point((width div 2),(height div 2)-7);
     brush.style:=bsclear;
     Font.Name:='Arial';Font.Size:=9;Font.Style:= [];Font.Color:=clNavy;
     TextOut(4,-3,'8');TextOut(19,-3,'4');TextOut(36,-3,'2');TextOut(51,-3,'1');
     TextOut(89,35,'Sc');
   if select=true then
     begin
     with canvas do
      begin
      R:=ClientRect;
      pen.Color:=clblack;
      pen.style:=psDot;
      Lock;rectangle(R);Unlock;
      pen.Color:=clBlack;pen.style:=psSolid;
      end;
     end;
   if FSelected then
   Begin
    R := ClientRect;
   // InflateRect(R, -1, -1);         // binnen de rand tekenen
    Brush.Style := bsClear;
    Pen.Color := clRed;
    pen.style:=psDot;
    Pen.Width := 1;
    Rectangle(R);
    // restore (netjes)
     Pen.Width := 1;
     pen.style:=psSolid;
     Brush.Style := bsSolid;
  end;
  Unlock;
  end;
end;



procedure TjanDipSwitsh.Resize;
begin
  width:=130;
  height:=80;
end;

procedure TjanDipSwitsh.BuildPopup;
        var
        miLock, miName, miInfo, miPuls, miSelect: TMenuItem;
       begin
         if not Assigned(PopupMenu) then
           PopupMenu := TPopupMenu.Create(Self)
         else
           PopupMenu.Items.Clear;
         // --- Lock / Unlock
          miLock := TMenuItem.Create(PopupMenu);
          miLock.Name := 'miLock';
          miLock.OnClick := ButtonClick1;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miLock);

         // --- Naam wijzigen
          miName := TMenuItem.Create(PopupMenu);
          miName.Name := 'miName';
          miName.OnClick := ButtonNClick;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miName);

         // --- Info aan/uit
          miInfo := TMenuItem.Create(PopupMenu);
          miInfo.Name := 'miInfo';
          miInfo.OnClick := ButtonClick3;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miInfo);

          // --- Selecteer voor verwijdering
          miSelect := TMenuItem.Create(PopupMenu);
          miSelect.Name := 'miSelect';
          miSelect.OnClick := ButtonClick4;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miSelect);
       end;

procedure TjanDipSwitsh.UpdatePopupCaptions;
       var
         miLock, miName, miInfo, miSelect: TMenuItem;
         s: string;
       begin
         if not Assigned(PopupMenu) then Exit;

         miLock   := TMenuItem(PopupMenu.FindComponent('miLock'));
         miName   := TMenuItem(PopupMenu.FindComponent('miName'));
         miInfo   := TMenuItem(PopupMenu.FindComponent('miInfo'));
         miSelect := TMenuItem(PopupMenu.FindComponent('miSelect'));

         // --- Lock / Unlock
         if Assigned(miLock) then
         begin
           if BTaal = 'NL' then
           begin
             if FLock then s := 'Ontgrendel' else s := 'Vergrendel';
           end
           else if BTaal = 'FR' then
           begin
             if FLock then s := 'Déverrouiller' else s := 'Verrouiller';
           end
           else if BTaal = 'DU' then
           begin
             if FLock then s := 'Entsperren' else s := 'Sperren';
           end
           else
           begin
             if FLock then s := 'Unlock' else s := 'lock';
           end;
           miLock.Caption := LangTr(s);
         end;

         // --- Naam wijzigen
         if Assigned(miName) then
         begin
           if BTaal = 'NL' then s := 'Wijzig Naam'
           else if BTaal = 'FR' then s := 'Changer le nom'
           else if BTaal = 'DU' then s := 'Namen ändern'
           else s := 'Change name';
           miName.Caption := LangTr(s);
         end;

         // --- Select / Deselect (TOGGLE)
         if Assigned(miSelect) then
         begin
           if not Selected then
           begin
             if BTaal = 'NL' then s := 'Selecteer object'
             else if BTaal = 'FR' then s := 'Sélectionner un objet'
             else if BTaal = 'DU' then s := 'Objekt auswählen'
             else s := 'Select object';
           end
           else
           begin
             if BTaal = 'NL' then s := 'Deselecteer object'
             else if BTaal = 'FR' then s := 'Désélectionner l''objet'
             else if BTaal = 'DU' then s := 'Objekt abwählen'
             else s := 'Deselect object';
           end;
           miSelect.Caption := LangTr(s);
         end;

         // --- Info aan/uit
         if Assigned(miInfo) then
         begin
           if ShowHint then
           begin
             if BTaal = 'NL' then s := 'Info uit'
             else if BTaal = 'FR' then s := 'Infos off'
             else if BTaal = 'DU' then s := 'Infos aus'
             else s := 'Information off';
           end
           else
           begin
             if BTaal = 'NL' then s := 'Info aan'
             else if BTaal = 'FR' then s := 'Infos on'
             else if BTaal = 'DU' then s := 'Infos an'
             else s := 'Information on';
           end;
           miInfo.Caption := LangTr(s);
         end;
       end;


procedure TjanDipSwitsh.Knop1Click(sender:TObject);
Begin
If (FDown8=true) then
      begin setdown8(false)end else setdown8(true);
invalidate;
end;

procedure TjanDipSwitsh.Knop1Click2(sender:TObject);
var
i:integer;
con:TjanConnector;
Begin
FDown8:=false;
for i:=0 to connectors.count-1 do
    begin
    con:=TjanConnector(connectors[i]);
    con.connect;
    con.free;
    end;
free;
end;

//new
procedure TjanDipSwitsh.ButtonClick1(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanDipSwitsh.ButtonClick3(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;

procedure TjanDipSwitsh.ButtonNClick(Sender: TObject);
var
  dlg: TInputBoxForm;
  s: string;
begin
  dlg := TInputBoxForm.Create(nil);
  try
    if dlg.Execute('Naam wijzigen', 'Geef een naam:', Naam, s) then
      Naam := s;  // setter -> Invalidate
  finally
    dlg.Free;
  end;
  UpdateHintText;
end;

procedure TjanDipSwitsh.ButtonClick4(sender:TObject); //selecteer
begin
 if Assigned(FBox) then
    FBox.SelectObject(Self);
end;

procedure TjanDipSwitsh.SetDown8(const Value: boolean);
begin
  if value<>FDown8 then
  begin
   FDown8 := Value;
   FDepressed8:=value;
   If Value=true then Fpuls8:=8 else FPuls8:=0;
   FPuls:=FPuls8+FPuls4+FPuls2+FPuls1;
   invalidate;
  end;
end;
procedure TjanDipSwitsh.SetDown4(const Value: boolean);
begin
  if value<>FDown4 then
  begin
   FDown4 := Value;
   FDepressed4:=value;
   If Value=true then Fpuls4:=4 else FPuls4:=0;
   FPuls:=FPuls8+FPuls4+FPuls2+FPuls1;
   invalidate;
  end;
end;
procedure TjanDipSwitsh.SetDown2(const Value: boolean);
begin
  if value<>FDown2 then
  begin
   FDown2 := Value;
   FDepressed2:=value;
   If Value=true then Fpuls2:=2 else FPuls2:=0;
   FPuls:=FPuls8+FPuls4+FPuls2+FPuls1;
   invalidate;
  end;
end;
procedure TjanDipSwitsh.SetDown1(const Value: boolean);
begin
  if value<>FDown1 then
  begin
   FDown1 := Value;
   FDepressed1:=value;
   If Value=true then Fpuls1:=1 else FPuls1:=0;
   FPuls:=FPuls8+FPuls4+FPuls2+FPuls1;
   invalidate;
  end;
end;
procedure TjanDipSwitsh.SetDown(const Value: boolean);
begin
  if value <> FDown then
  begin
   FDown := Value;
   FDepressed:=value;
   If Value=true then FPuls:=FPuls8+FPuls4+FPuls2+FPuls1;
   If FDown=true then FStatDip := stDipStart else FStatDip := stDipStop;
   invalidate;
  end;
    // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
if Assigned(OnDipChange) then OnDipChange(Self, StatDip,FPuls);
end;

procedure TjanDipSwitsh.SetConnector(const Value: boolean);
begin
  if value<>FConnector then
  begin
   FConnector := Value;
   invalidate;
  end;
end;

procedure TjanDipSwitsh.SetStart(const Value: boolean);
begin
  if value <> FStart then
  begin
   FStart := Value;
   //FDepressed:=value;
   If Value=true then FPuls:=FPuls8+FPuls4+FPuls2+FPuls1;
   If FStart=true then FStatDip := stDipStart else FStatDip := stDipStop;
   invalidate;
  end;
if Assigned(OnDipChange) then OnDipChange(Self, StatDip, FPuls);
end;

procedure TjanDipSwitsh.SetLock(const Value: boolean);
begin
  if value<>FLock then
  begin
    FLock := Value;
 end;
end;

{ TjanSimPuls }
procedure TjanSimPuls.CMMouseLeave(var Msg: TMessage);
begin
    inherited;
   if not FMouseOver then Exit;     // kleine guard
      FMouseOver := False;

  // ✅ statusbar leegmaken (zoals bij TjanSimButton)
  if Assigned(FOnStatus) then
  begin
    FOnStatus(Self, '', 0);
    FOnStatus(Self, '', 1);
    FOnStatus(Self, '', 2);
    FOnStatus(Self, '', 3);
  end;
  if Flock=false then begin select:=false;invalidate;end;
end;

procedure TjanSimPuls.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
   if FMouseOver then Exit;         // kleine guard
  // ✅ statusbar meteen vullen
  FMouseOver := True;
  SendStatusToBar;  // vult panel 0/1/2
  BringToFront;
  if not FLock then
  begin
    Select := True;
    Invalidate;
  end;
   UpdateHintText;
 end;

 procedure TjanSimPuls.SendStatusToBar;
 var
   s, ss: string;
   wInput, wStatus: string;
 begin
   if not Assigned(FOnStatus) then Exit;

   wInput  := Tr(BTaal,'Invoer','Input','Entrée','Eingang');
   wStatus := Tr(BTaal,'Status','Status','Statut','Status');

   // Panel 0
  FOnStatus(Self, FNaam + ' > ', 0);

   // Panel 1
   if FDown then
     s := wStatus + ' = 1'
   else
     s := wStatus + ' = 0';
   FOnStatus(Self, s, 1);

   // Panel 2
   ss := Format('X=%d Y=%d', [Left, Top]);
   FOnStatus(Self, ss, 2);
 end;

 procedure TjanSimPuls.UpdateHintText;
 begin
   Hint := BuildSimHint(FNaam, BTaal);
 end;

procedure TjanSimPuls.SetNaam(const Value: String);
begin
   if FNaam <> Value then
  begin
    FNaam := Value;
    Invalidate;
    // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
  end;
end;

procedure TjanSimPuls.SetTaal(const Value: String);
begin
  if value<>FTaal then
  begin
    FTaal:= Value;
 end;
 if value='NL' then FInfo:='Temperatuursensor'
 else if value='ENG' then FInfo:='emperature sensor'
 else if value='FR' then FInfo:= 'Le capteur de température'
 else if value='DU' then FInfo:= 'Schalter';
invalidate;

// ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
end;

procedure TjanSimPuls.AnchorConnectors;
var wc:TWincontrol;
    i:integer;
    con:TjanConnector;
    R:TRect;
    p:TPoint;
begin
  wc:=parent;
  connectors.Clear;
  R:=boundsrect;
  inflateRect(R,8,8);
  p:=point(left,top);
  for i:=0 to wc.ControlCount-1 do
    if (wc.controls[i] is TjanConnector) then
    begin
      con:=TjanConnector(wc.controls[i]);
      // alleen de echte uiteinden van de draad (zie TjanConnector.AnchorToRect)
      if con.AnchorToRect(R,p) then
        connectors.Add(con);
    end;
end;

constructor TjanSimPuls.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FState := stStopped;
  FPulsinterval:=300;
  FDown:=false;
  width:=50;
  height:=80;
  connectors:=TList.create;
  KnopUp:=TBitmap.Create;
  KnopUp.LoadFromResourceName(HInstance,'PULS_UIT');
  KnopUp.Transparent := True;
  KnopUp.TransParentColor := KnopUp.canvas.pixels[0,0];
  KnopDown:=TBitmap.Create;
  KnopDown.LoadFromResourceName(HInstance,'PULS_AAN');
  KnopDown.Transparent := True;
  KnopDown.TransParentColor := KnopDown.canvas.pixels[0,0];
  FPuls:=false;
  puls:=TTimer.Create(self);
  with puls do
    begin
     OnTimer := mTimer;
     enabled:=false;
    end;
     {FSlider:=TSlideSmall.Create(self);
      With FSlider do
      Begin
        parent:=self;
        FSlider.OnChange:= Inter;
        visible:=true;

     end;
     FSlider.Visible:=false;}
 // FTaal:='NL';
  FInfo:= 'Impulsgenerator';
  ShowHint:=true;
  FSoort:='Invoer';
  FNaam:='Impulsgenerator';
end;

destructor TjanSimPuls.Destroy;
begin
  knopUp.Free;
  knopDown.Free;
  connectors.free;
  puls.Free;
  //FSlider.Free;

  inherited;
end;

procedure TjanSimPuls.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  R, R2: TRect;
  p: TPoint;
  wc: TWinControl;
  L, T: Integer;
begin
  inherited;

  if (Button = mbRight) and (FLock = False) then
  begin
    BuildPopup;
    UpdatePopupCaptions;

    p := Point(0, Height);
    p := ClientToScreen(p);
    PopupMenu.Popup(p.X, p.Y - 1);
    Exit;
  end;

  mdp := Point(X, Y);
  R := Rect(Width - 9, 21, Width, 30);

  // maken van aansluitdraad
  if PtInRect(R, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + Width - 8;
    T := Top + 21;
    Maakdraad(T, L, wc);
    doMove := False;
    BringToFront;
    Exit;
  end;

  Screen.Cursor := crDefault;

  R2 := Rect(13,66,37,75);
  doMove := not PtInRect(R2, mdp);
  FDepressed := not doMove;
  oldp := Point(X, Y);

  if doMove then
  begin
    AnchorConnectors;

    if (Button = mbLeft) and (Parent is TjanGridS) then
      TjanGridS(Parent).BeginGuideLines(Left + Width div 2, Top + Height div 2);
  end
  else
    Invalidate;
end;

procedure TjanSimPuls.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  R: TRect;
  p: TPoint;
begin
  inherited;

  if Parent is TjanGridS then
    TjanGridS(Parent).EndGuideLines;

  movecursor;
  FDepressed := False;

  p := Point(X, Y);
  R := Rect(13,66,37,75);

  if PtInRect(R, p) then
    Starten := not FDown;

  FMouseOver := True;
  SendStatusToBar;
end;

procedure TjanSimPuls.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  p: TPoint;
  Grid: TjanGridS;
  SnapP: TPoint;
  WorkR: TRect;
begin
  inherited;

  if FLock = True then Exit;
  if FDepressed then Exit;
  if Parent = nil then Exit;

  p := ClientToScreen(Point(X, Y));
  p := Parent.ScreenToClient(p);

  if (ssLeft in Shift) then
  begin
    if doMove then
    begin
      NewLeft := p.X - mdp.X;
      NewTop := p.Y - mdp.Y;

      if Parent is TjanGridS then
      begin
        Grid := TjanGridS(Parent);
        WorkR := Grid.GetWorkAreaRect;

        // snappen op het midden van het object
        SnapP := Point(NewLeft + Width div 2, NewTop + Height div 2);
        SnapP := Grid.SnapPointToRuler(SnapP, WorkR);

        NewLeft := SnapP.X - Width div 2;
        NewTop := SnapP.Y - Height div 2;
      end;

      StraightenWires(connectors,newleft,newtop); SnapToRail(Self,newleft);
      Left := NewLeft;
      Top := NewTop;
      MoveConnectors;

      if Parent is TjanGridS then
        TjanGridS(Parent).UpdateGuideLines(Left + Width div 2, Top + Height div 2);

      FMouseOver := True;
      SendStatusToBar;
    end;
  end;
end;

procedure TjanSimPuls.BuildPopup;
        var
        miLock, miName, miInfo, miPuls, miSelect, mi: TMenuItem;
        i: Integer;
       begin
         if not Assigned(PopupMenu) then
           PopupMenu := TPopupMenu.Create(Self)
         else
           PopupMenu.Items.Clear;
         // --- Lock / Unlock
          miLock := TMenuItem.Create(PopupMenu);
          miLock.Name := 'miLock';
          miLock.OnClick := ButtonClick1;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miLock);

         // --- Naam wijzigen
          miName := TMenuItem.Create(PopupMenu);
          miName.Name := 'miName';
          miName.OnClick := ButtonNClick;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miName);

         // --- Info aan/uit
          miInfo := TMenuItem.Create(PopupMenu);
          miInfo.Name := 'miInfo';
          miInfo.OnClick := ButtonClick3;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miInfo);

           // --- Selecteer voor verwijdering
           miSelect := TMenuItem.Create(PopupMenu);
           miSelect.Name := 'miSelect';
           miSelect.OnClick := ButtonClick4;     // Delphi-mode: geen @
           popupMenu.Items.Add(miSelect);

           // --- Frequentie: hoe snel de pulsen komen
           miPuls := TMenuItem.Create(PopupMenu);
           miPuls.Caption := Tr(BTaal, 'Frequentie', 'Frequency', 'Fréquence', 'Frequenz');
           PopupMenu.Items.Add(miPuls);
           for i := Low(PulsIntervallen) to High(PulsIntervallen) do
           begin
             mi := TMenuItem.Create(PopupMenu);
             mi.Caption := PulsFrequentieText(PulsIntervallen[i]) + '  (' +
               Tr(BTaal, 'elke ', 'every ', 'toutes les ', 'alle ') +
               FormatFloat('0.##', 2 * PulsIntervallen[i] / 1000) + ' s)';
             if PulsIntervallen[i] = PulsIntervalStandaard then
               mi.Caption := mi.Caption + ' - ' + Tr(BTaal, 'standaard', 'default', 'par défaut', 'Standard');
             mi.Tag := PulsIntervallen[i];
             mi.RadioItem := True;
             mi.Checked := PulsIntervallen[i] = FPulsinterval;
             mi.OnClick := FrequentieClick;
             miPuls.Add(mi);
           end;
       end;

       procedure TjanSimPuls.FrequentieClick(Sender: TObject);
       begin
         PulsInterval := TMenuItem(Sender).Tag;
       end;

       procedure TjanSimPuls.UpdatePopupCaptions;
       var
         miLock, miName, miInfo, miSelect: TMenuItem;
         s: string;
       begin
         if not Assigned(PopupMenu) then Exit;

         miLock   := TMenuItem(PopupMenu.FindComponent('miLock'));
         miName   := TMenuItem(PopupMenu.FindComponent('miName'));
         miInfo   := TMenuItem(PopupMenu.FindComponent('miInfo'));
         miSelect := TMenuItem(PopupMenu.FindComponent('miSelect'));

         // --- Lock / Unlock
         if Assigned(miLock) then
         begin
           if BTaal = 'NL' then
           begin
             if FLock then s := 'Ontgrendel' else s := 'Vergrendel';
           end
           else if BTaal = 'FR' then
           begin
             if FLock then s := 'Déverrouiller' else s := 'Verrouiller';
           end
           else if BTaal = 'DU' then
           begin
             if FLock then s := 'Entsperren' else s := 'Sperren';
           end
           else
           begin
             if FLock then s := 'Unlock' else s := 'lock';
           end;
           miLock.Caption := LangTr(s);
         end;

         // --- Naam wijzigen
         if Assigned(miName) then
         begin
           if BTaal = 'NL' then s := 'Wijzig Naam'
           else if BTaal = 'FR' then s := 'Changer le nom'
           else if BTaal = 'DU' then s := 'Namen ändern'
           else s := 'Change name';
           miName.Caption := LangTr(s);
         end;

         // --- Select / Deselect (TOGGLE)
         if Assigned(miSelect) then
         begin
           if not Selected then
           begin
             if BTaal = 'NL' then s := 'Selecteer object'
             else if BTaal = 'FR' then s := 'Sélectionner un objet'
             else if BTaal = 'DU' then s := 'Objekt auswählen'
             else s := 'Select object';
           end
           else
           begin
             if BTaal = 'NL' then s := 'Deselecteer object'
             else if BTaal = 'FR' then s := 'Désélectionner l''objet'
             else if BTaal = 'DU' then s := 'Objekt abwählen'
             else s := 'Deselect object';
           end;
           miSelect.Caption := LangTr(s);
         end;

         // --- Info aan/uit
         if Assigned(miInfo) then
         begin
           if ShowHint then
           begin
             if BTaal = 'NL' then s := 'Info uit'
             else if BTaal = 'FR' then s := 'Infos off'
             else if BTaal = 'DU' then s := 'Infos aus'
             else s := 'Information off';
           end
           else
           begin
             if BTaal = 'NL' then s := 'Info aan'
             else if BTaal = 'FR' then s := 'Infos on'
             else if BTaal = 'DU' then s := 'Infos an'
             else s := 'Information on';
           end;
           miInfo.Caption := LangTr(s);
         end;
       end;




procedure TjanSimPuls.MoveConnectors;
var i:integer;
    con:TjanConnector;
begin

  if connectors.Count=0 then exit;
  for i:=0 to connectors.count-1 do
  begin
    con:=TjanConnector(connectors[i]);
    con.MoveConnector(point(newleft,newtop));
  end;
end;

procedure TjanSimPuls.Paint;
var p:Tpoint;
    R:TRect;
    Pu:string;
begin
   with canvas do
   begin
    Lock;
    R:=ClientRect;
    inflaterect(R,-3,-5);
    knopDown.Transparent:=true;
    knopUp.Transparent:=true;
     if FDepressed or FDown then
        Begin
        PaintInputSymbol(Self,Canvas,knopDown,4,True);

        end
        else
        Begin
        PaintInputSymbol(Self,Canvas,knopUp,4,False);

        end;

      // Tekenen van Led
        p:=point((self.width div 2),18);
     if starten=false then
       PaintLed(p,false)
       else
       PaintLed(p,FPuls);

     // de frequentie klein onder de pulstekst
     Pu:=PulsFrequentieText(FPulsinterval);
     brush.style:=bsClear;
     Font.Name:='Arial';Font.Size:=7;Font.Style:=[];
     Font.Color:=clNavy;
     TextOut((Self.Width - TextWidth(Pu)) div 2, 53, Pu);

    Unlock;
    end;
    if select=true then
     begin
     with canvas do
      begin
      R:=ClientRect;
      Brush.Style:=bsClear;
      pen.Color:=clblack;
      pen.style:=psDot;
      Lock;rectangle(R);Unlock;
      pen.Color:=clSilver;pen.style:=psSolid;
      end;
     end;
      if FSelected then
       begin
       R := ClientRect;
      // InflateRect(R, -2, -2);         // binnen de rand tekenen

       Canvas.Brush.Style := bsClear;
       Canvas.Pen.Color := clRed;
       Canvas.pen.style:=psDot;
       Canvas.Pen.Width := 1;
       Canvas.Rectangle(R);

    // restore (netjes)
     Canvas.Pen.Width := 1;
     Canvas.pen.style:=psSolid;
     Canvas.Brush.Style := bsSolid;
  end;

end;

procedure TjanSimPuls.PaintLed(pt:TPoint;lit:boolean);
var surfcol,litcol:Tcolor;
    x,y:integer;
begin
  x:=pt.x;
  y:=pt.y;
  if lit then
  begin
    surfcol:=clred;
    litcol:=clwhite;

        canvas.brush.style:=bsclear;
        canvas.Font.Name:='Arial';canvas.Font.Size:=9;canvas.Font.Style:= [fsBold];
        canvas.Font.Color:=clRed;
        canvas.TextOut(4,40,'puls = 1');
  end
  else
  begin
    surfcol:=clmaroon;
    litcol:=clred;
        canvas.brush.style:=bsclear;
        canvas.Font.Name:='Arial';canvas.Font.Size:=9;canvas.Font.Style:= [fsBold];
        canvas.Font.Color:=clNavy;
        canvas.TextOut(4,40,'puls = 0');
  end;

  with Canvas do begin
    Lock;
    brush.style:=bsclear;
    brush.color:=clsilver;
    fillrect(rect(x,y,x+12,y+13));
    brush.style:=bsclear;
    pen.color:=clgray;
    ellipse(x,y,x+12,y+13);

    brush.color:=surfcol;
    ellipse(x+1,y+1,x+11,y+12);
    pen.color:=clwhite;
    arc(x+1,y+1,x+11,y+12,x+0,y+12,x+12,y+0);
    pen.color:=litcol;
    arc(x+3,y+3,x+8,y+9,x+5,y+0,x+0,y+8);

    Unlock;
   end;
end;

procedure TjanSimPuls.Resize;
begin
  width:=50;
  height:=80;
end;

procedure TjanSimPuls.mTimer(sender: TObject);
begin
   If FPuls=true then
       Begin
       FPuls:=false;
       FState := stStopped;
       pulser:=0;
       end
       else
       begin
       FPuls:=true;
       FState := stStarted;

       pulser:=1;

       end;

       if Assigned(OnPulsChange) then OnPulsChange(Self, State);
invalidate;
end;

procedure TjanSimPuls.Inter(sender: TObject);
begin
FPulsinterval:=3 * 100;
If starten=false then exit else
 Begin
 If starten=true then Begin starten:=false;starten:=true end;

 end;
end;

procedure TjanSimPuls.SetInfo(const Value: String);
begin
   if value<>FInfo then
  begin
    FInfo := Value;
 end;
end;

//new
procedure TjanSimPuls.ButtonClick1(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanSimPuls.ButtonClick3(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;

procedure TjanSimPuls.ButtonNClick(Sender: TObject);
var
  dlg: TInputBoxForm;
  s: string;
begin
  dlg := TInputBoxForm.Create(nil);
  try
    if dlg.Execute('Naam wijzigen', 'Geef een naam:', Naam, s) then
      Naam := s;  // setter -> Invalidate
  finally
    dlg.Free;
  end;
  UpdateHintText;
end;

procedure TjanSimPuls.ButtonClick4(sender:TObject);
begin
  if Assigned(FBox) then
    FBox.SelectObject(Self);
end;

procedure TjanSimPuls.SetDown(const Value: boolean);
begin
  if value<>FDown then
  begin
    FDown := Value;
    FDepressed:=value;
    puls.interval := FPulsinterval;
    puls.enabled := Value;

     // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;

   // if (starten=true) then FSlider.Visible:=true else FSlider.Visible:=false;
  end;



  invalidate;
end;

procedure TjanSimPuls.SetLock(const Value: boolean);
begin
  if value<>FLock then
  begin
    FLock := Value;
 end;
end;

procedure TjanSimPuls.SetPuls(const Value: boolean);
begin
  if value<>FPuls then
  begin
    FPuls := Value;
  end;
  if value=true then
invalidate;
end;

procedure TjanSimPuls.SetPulsen(const Value: Integer);
begin
  if value<>FPulsen then
  begin
    FPulsen:= Value;
  end;
end;

procedure TjanSimPuls.SetPulsinterval(const Value: integer);
begin
  if value<>FPulsinterval then
  begin
    FPulsinterval := Value;
    puls.Interval := Value;   // loopt hij al, dan meteen het nieuwe tempo
 end;
invalidate;
end;

{ TjanSimSensor }
procedure TjanSimSensor.AnchorConnectors;
var wc:TWincontrol;
    i:integer;
    con:TjanConnector;
    R:TRect;
    p:TPoint;
begin
  wc:=parent;
  connectors.Clear;
  R:=boundsrect;
  inflateRect(R,8,8);
  p:=point(left,top);
  for i:=0 to wc.ControlCount-1 do
    if (wc.controls[i] is TjanConnector) then
    begin
      con:=TjanConnector(wc.controls[i]);
      // alleen de echte uiteinden van de draad (zie TjanConnector.AnchorToRect)
      if con.AnchorToRect(R,p) then
        connectors.Add(con);
    end;
end;

procedure TjanSimSensor.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
   FMouseOver := False;
   if Assigned(FOnStatus) then
   begin
    FOnStatus(Self, '', 1);   // Panel leeg
    FOnStatus(Self, '', 0);   // Panel leeg
    FOnStatus(Self, '', 2);   // Panel leeg
    FOnStatus(Self, '', 3);   // Panel leeg
   end;
   if Assigned (FonExit) then
   FonExit(Self);
   if Flock=false then begin select:=false;invalidate;end;
end;

procedure TjanSimSensor.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
  UpdateHintText;


  // laat Naam van object verschijnen in Main statusBar Panel 0
     FOnStatus(Self, Fnaam +'>>', 0);
   // laat status en x,y van object verschijnen in Main StatusBar Panel 1
  FMouseOver := True;
  SendStatusToBar;

  if Assigned(FOnEnter) then
    FOnEnter(Self);
  BringToFront;
  if not FLock then
  begin
    Select := True;
    Invalidate;
  end;
end;

constructor TjanSimSensor.Create(AOwner: TComponent);
var
  XX, YY: Integer;
  PixelColor: TColor;
begin
  inherited Create(AOwner);
  Select:=false;
  FStatlicht := stLichtStop;
  FDown:=false;
  width:=58;
  height:=32;
  connectors:=TList.create;

  KnopUp:=TBitmap.Create;
  KnopUp.LoadFromResourceName(HInstance,'LSENS_UIT');
  for YY := 0 to KnopUp.Height - 1 do
      for XX := 0 to KnopUp.Width - 1 do
      begin
        PixelColor := KnopUp.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          KnopUp.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  KnopUp.Transparent := True;
  KnopUp.TransParentColor := clFuchsia;//:= KnopUp.canvas.pixels[0,0];

  KnopDown:=TBitmap.Create;
  KnopDown.LoadFromResourceName(HInstance,'LSENS_IN');
  for YY := 0 to KnopUp.Height - 1 do
      for XX := 0 to KnopDown.Width - 1 do
      begin
        PixelColor := KnopDown.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          KnopDown.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  KnopDown.Transparent := True;
  KnopDown.TransParentColor := clFuchsia;//:= KnopDown.canvas.pixels[0,0];
  FTaal:='NL';
  FInfo:= 'Lichtsensor';
  ShowHint:=true;
  FNaam:='Lichtsensor';
  FSoort:='Invoer';
  HelpKeyword:='lichtsensor';
end;

destructor TjanSimSensor.Destroy;
begin
  knopUp.Free;
  knopDown.Free;
  connectors.free;
  inherited;
end;


procedure TjanSimSensor.BuildPopup;
        var
        miLock, miName, miInfo, miSelect: TMenuItem;
       begin
         if not Assigned(PopupMenu) then
           PopupMenu := TPopupMenu.Create(Self)
         else
           PopupMenu.Items.Clear;
         // --- Lock / Unlock
          miLock := TMenuItem.Create(PopupMenu);
          miLock.Name := 'miLock';
          miLock.OnClick := ButtonClick1;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miLock);

         // --- Naam wijzigen
          miName := TMenuItem.Create(PopupMenu);
          miName.Name := 'miName';
          miName.OnClick := ButtonNClick;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miName);

         // --- Info aan/uit
          miInfo := TMenuItem.Create(PopupMenu);
          miInfo.Name := 'miInfo';
          miInfo.OnClick := ButtonClick3;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miInfo);

          // --- Selecteer voor verwijdering
          miSelect := TMenuItem.Create(PopupMenu);
          miSelect.Name := 'miSelect';
          miSelect.OnClick := ButtonClick4;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miSelect);
       end;

procedure TjanSimSensor.UpdatePopupCaptions;
   var
  miLock, miName, miInfo, miSelect: TMenuItem;
  s: string;
begin
  if not Assigned(PopupMenu) then Exit;

  miLock   := TMenuItem(PopupMenu.FindComponent('miLock'));
  miName   := TMenuItem(PopupMenu.FindComponent('miName'));
  miInfo   := TMenuItem(PopupMenu.FindComponent('miInfo'));
  miSelect := TMenuItem(PopupMenu.FindComponent('miSelect'));

  // --- Lock / Unlock
  if Assigned(miLock) then
  begin
    if BTaal = 'NL' then
    begin
      if FLock then s := 'Ontgrendel' else s := 'Vergrendel';
    end
    else if BTaal = 'FR' then
    begin
      if FLock then s := 'Déverrouiller' else s := 'Verrouiller';
    end
    else if BTaal = 'DU' then
    begin
      if FLock then s := 'Entsperren' else s := 'Sperren';
    end
    else
    begin
      if FLock then s := 'Unlock' else s := 'lock';
    end;
    miLock.Caption := LangTr(s);
  end;

  // --- Naam wijzigen
  if Assigned(miName) then
  begin
    if BTaal = 'NL' then s := 'Wijzig Naam'
    else if BTaal = 'FR' then s := 'Changer le nom'
    else if BTaal = 'DU' then s := 'Namen ändern'
    else s := 'Change name';
    miName.Caption := LangTr(s);
  end;

  // --- Select / Deselect (TOGGLE)
  if Assigned(miSelect) then
  begin
    if not Selected then
    begin
      if BTaal = 'NL' then s := 'Selecteer object'
      else if BTaal = 'FR' then s := 'Sélectionner un objet'
      else if BTaal = 'DU' then s := 'Objekt auswählen'
      else s := 'Select object';
    end
    else
    begin
      if BTaal = 'NL' then s := 'Deselecteer object'
      else if BTaal = 'FR' then s := 'Désélectionner l''objet'
      else if BTaal = 'DU' then s := 'Objekt abwählen'
      else s := 'Deselect object';
    end;
    miSelect.Caption := LangTr(s);
  end;

  // --- Info aan/uit
  if Assigned(miInfo) then
  begin
    if ShowHint then
    begin
      if BTaal = 'NL' then s := 'Info uit'
      else if BTaal = 'FR' then s := 'Infos off'
      else if BTaal = 'DU' then s := 'Infos aus'
      else s := 'Information off';
    end
    else
    begin
      if BTaal = 'NL' then s := 'Info aan'
      else if BTaal = 'FR' then s := 'Infos on'
      else if BTaal = 'DU' then s := 'Infos an'
      else s := 'Information on';
    end;
    miInfo.Caption := LangTr(s);
  end;
end;

procedure TjanSimSensor.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  R, R2: TRect;
  p: TPoint;
  wc: TWinControl;
  L, T: Integer;
begin
  inherited;

  if (Button = mbRight) and (FLock = False) then
  begin
    BuildPopup;
    UpdatePopupCaptions;

    p := Point(0, Height);
    p := ClientToScreen(p);
    PopupMenu.Popup(p.X, p.Y - 1);
    Exit;
  end;

  mdp := Point(X, Y);
  R := Rect(49,12,57,20);

  // maken van aansluitdraad
  if PtInRect(R, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + Width - 8;
    T := Top + 13;
    Maakdraad(T, L, wc);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;

  Screen.Cursor := crDefault;

  // einde van het maken van een aansluiting
  R2 := Rect(2,6,20,26);
  doMove := not PtInRect(R2, mdp);
  FDepressed := not doMove;
  oldp := Point(X, Y);

  if doMove then
  begin
    AnchorConnectors;

    if (Button = mbLeft) and (Parent is TjanGridS) then
      TjanGridS(Parent).BeginGuideLines(Left + Width div 2, Top + Height div 2);
  end
  else
    Invalidate;
end;


procedure TjanSimSensor.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  R: TRect;
  p: TPoint;
begin
  inherited;

  if Parent is TjanGridS then
    TjanGridS(Parent).EndGuideLines;

  Select := False;
  Invalidate;
  FDepressed := False;

  p := Point(X, Y);
  R := Rect(2,6,20,26);

  if PtInRect(R, p) then
    Down := not Down;

  FMouseOver := True;
  SendStatusToBar;
end;

procedure TjanSimSensor.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  p: TPoint;
  Grid: TjanGridS;
  SnapP: TPoint;
  WorkR: TRect;
begin
  inherited;

  if FLock = True then Exit;
  if FDepressed then Exit;
  if Parent = nil then Exit;

  p := ClientToScreen(Point(X, Y));
  p := Parent.ScreenToClient(p);

  if (ssLeft in Shift) then
  begin
    if doMove then
    begin
      NewLeft := p.X - mdp.X;
      NewTop := p.Y - mdp.Y;

      if Parent is TjanGridS then
      begin
        Grid := TjanGridS(Parent);
        WorkR := Grid.GetWorkAreaRect;

        // snappen op het midden van het object
        SnapP := Point(NewLeft + Width div 2, NewTop + Height div 2);
        SnapP := Grid.SnapPointToRuler(SnapP, WorkR);

        NewLeft := SnapP.X - Width div 2;
        NewTop := SnapP.Y - Height div 2;
      end;

      StraightenWires(connectors,newleft,newtop); SnapToRail(Self,newleft);
      Left := NewLeft;
      Top := NewTop;
      MoveConnectors;

      if Parent is TjanGridS then
        TjanGridS(Parent).UpdateGuideLines(Left + Width div 2, Top + Height div 2);

      FMouseOver := True;
      SendXYmoveToBar;
    end;
  end;
end;




procedure TjanSimSensor.MoveConnectors;
var i:integer;
    con:TjanConnector;
begin
  select:=true;
  if connectors.Count=0 then exit;
  for i:=0 to connectors.count-1 do
  begin
    con:=TjanConnector(connectors[i]);
    con.MoveConnector(point(newleft,newtop));
  end;
end;

procedure TjanSimSensor.Paint;
var
    R:TRect;
begin
knopDown.Transparent:=true;
knopUp.Transparent:=true;
   with canvas do
   begin
   Lock;
     R:=ClientRect;
     if FDepressed or FDown then
      begin
       PaintInputSymbol(Self,Canvas,knopDown,2,True);
       brush.style:=bsclear;
       Font.Name:='Arial'; Font.Size:=9;Font.Style:= [fsBold];
       Font.Color:=clRed;
       TextOut(50,19,'1');
      end
      else
      begin
       PaintInputSymbol(Self,Canvas,knopUp,2,False);
       brush.style:=bsclear;
       Font.Name:='Arial'; Font.Size:=9;Font.Style:= [fsBold];
       Font.Color:=clNavy;
       TextOut(50,19,'0');
      end;
   Unlock;
   end;
  if select=true then
     begin
     R:=ClientRect;
      canvas.pen.Color:=clblack;
      canvas.pen.style:=psDot;canvas.Brush.Style:=bsClear;
      canvas.Lock;canvas.rectangle(R);canvas.Unlock;
      canvas.pen.Color:=clBlack;canvas.pen.style:=psSolid;
     end;
end;

procedure TjanSimSensor.PaintLed(pt:TPoint;lit:boolean);
var surfcol,litcol:Tcolor;
    x,y:integer;
begin
  x:=pt.x;
  y:=pt.y;
  if lit then
  begin
    surfcol:=clred;
    litcol:=clwhite;
  end
  else
  begin
    surfcol:=clmaroon;
    litcol:=clred;
  end;
  with Canvas do begin
    lock;
    brush.color:=clsilver;
    fillrect(rect(x,y,x+12,y+13));
    brush.style:=bsclear;
    pen.color:=clgray;
    ellipse(x,y,x+12,y+13);
    pen.color:=clblack;
    brush.color:=surfcol;
    ellipse(x+1,y+1,x+11,y+12);
    pen.color:=clwhite;
    arc(x+1,y+1,x+11,y+12,x+0,y+12,x+12,y+0);
    pen.color:=litcol;
    arc(x+3,y+3,x+8,y+9,x+5,y+0,x+0,y+8);
    unlock;
   end;
end;

procedure TjanSimSensor.Resize;
begin
  width:=58;
  height:=32;
end;



//new
procedure TjanSimSensor.ButtonClick1(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanSimSensor.ButtonClick3(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;

procedure TjanSimSensor.ButtonNClick(Sender: TObject);
var
  dlg: TInputBoxForm;
  s: string;
begin
  dlg := TInputBoxForm.Create(nil);
  try
    if dlg.Execute('Naam wijzigen', 'Geef een naam:', Naam, s) then
      Naam := s;  // setter -> Invalidate
  finally
    dlg.Free;
  end;
  UpdateHintText;
end;

procedure TjanSimSensor.ButtonClick4(Sender: TObject);
begin
  if Assigned(FBox) then
    FBox.SelectObject(Self);
end;

procedure TjanSimSensor.SetDown(const Value: boolean);
begin
  if value<>FDown then
  begin
    FDown := Value;
    FDepressed:=value;
    puls:=1;
  //  if FDown=true then FStatLicht := stLichtStart
  //  else FStatLicht := stLichtStop;
    invalidate;

     // ✅ Onmiddellijke refresh als muis erboven staat
     if FMouseOver then
      SendStatusToBar;
  end;
// if Assigned(OnLichtChange) then OnLichtChange(Self, StatLicht);
end;

procedure TjanSimSensor.SetInfo(const Value: String);
begin
  if value<>FInfo then
  begin
    FInfo := Value;
 end;
end;

procedure TjanSimSensor.SetLock(const Value: boolean);
begin
  if value<>FLock then
  begin
    FLock := Value;
 end;
end;

procedure TjanSimSensor.SetPuls(const Value: Integer);
begin
  if value<>FPuls then
    FPuls:= Value;
end;

procedure TjanSimSensor.SendXYmoveToBar;
var
LB: TjanSimLogicBox;
 C: TComponent;
s:string;
begin
// Zoek LogicBox via Owner-keten (werkt ook als Owner niet direct de box is)
 LB := nil;
 C := Owner;
 while (C <> nil) and (LB = nil) do
 begin
   if C is TjanSimLogicBox then
     LB := TjanSimLogicBox(C)
   else
     C := C.Owner;
 end;
 if LB = nil then Exit;
s:= Format('X=%d Y=%d', [Left, Top]);
LB.PushStatus(Self, s, 2);
end;

procedure TjanSimSensor.SendStatusToBar;
var
  s, ss: string;
  wInput, wStatus: string;
begin
  if not Assigned(FOnStatus) then Exit;

  wInput  := Tr(BTaal,'Invoer','Input','Entrée','Eingang');
  wStatus := Tr(BTaal,'Status','Status','Statut','Status');

  // Panel 0
 FOnStatus(Self, FNaam + ' > ', 0);

  // Panel 1
  if FDown then
    s := wStatus + ' = 1'
  else
    s := wStatus + ' = 0';
  FOnStatus(Self, s, 1);

  // Panel 2
  ss := Format('X=%d Y=%d', [Left, Top]);
  FOnStatus(Self, ss, 2);
end;

procedure TjanSimSensor.UpdateHintText;
begin
  Hint := BuildSimHint(FNaam, BTaal);
end;

procedure TjanSimSensor.SetNaam(const Value: String);
begin
    if FNaam <> Value then
  begin
    FNaam := Value;
    Invalidate;
  end;
end;

procedure TjanSimSensor.SetTaal(const Value: String);
begin
  if value<>FTaal then
  begin
    FTaal:= Value;
 end;
 if value='NL' then FInfo:='schakelaar'
 else if value='ENG' then FInfo:='switch'
 else if value='FR' then FInfo:= 'l´interrupteur'
 else if value='DU' then FInfo:= 'Schalter';
invalidate;
end;


// einde TjanSimsensor


{ TjanSimWarm }
procedure TjanSimWarm.AnchorConnectors;
var wc:TWincontrol;
    i:integer;
    con:TjanConnector;
    R:TRect;
    p:TPoint;
begin
  wc:=parent;
  connectors.Clear;
  R:=boundsrect;
  inflateRect(R,8,8);
  p:=point(left,top);
  for i:=0 to wc.ControlCount-1 do
    if (wc.controls[i] is TjanConnector) then
    begin
      con:=TjanConnector(wc.controls[i]);
      // alleen de echte uiteinden van de draad (zie TjanConnector.AnchorToRect)
      if con.AnchorToRect(R,p) then
        connectors.Add(con);
    end;
end;

procedure TjanSimWarm.CMMouseLeave(var Msg: TMessage);
begin
   inherited;
   FMouseOver := False;
   if Assigned(FOnStatus) then
   begin
     FOnStatus(Self, '', 0);
     FOnStatus(Self, '', 1);
     FOnStatus(Self, '', 2);
     FOnStatus(Self, '', 3);
   end;

    if Assigned(FOnExit) then
    FOnExit(Self);

   if not FLock then
   begin
     select:=false;
     invalidate;
   end;
end;

procedure TjanSimWarm.CMMouseEnter(var Msg: TMessage);
var
 s:String;
begin
  inherited;
   UpdateHintText;


  // laat Naam van object verschijnen in Main statusBar Panel 0
     FOnStatus(Self, Fnaam +'>>', 0);
  // laat status en x,y van object verschijnen in Main StatusBar Panel 1
  FMouseOver := True;
  SendStatusToBar;

  if Assigned(FOnEnter) then
    FOnEnter(Self);
  BringToFront;
  if not FLock then
  begin
    Select := True;
    Invalidate;

  end;
end;

constructor TjanSimWarm.Create(AOwner: TComponent);
var
  XX, YY: Integer;
  PixelColor: TColor;
begin
  inherited Create(AOwner);
  Select:=false;
  FStatTemp := stTempStop;
  FDown:=false;
  width:=58;
  height:=32;
  connectors:=TList.create;
  KnopUp:=TBitmap.Create;
  KnopUp.LoadFromResourceName(HInstance,'WSENS_UIT');
   for YY := 0 to KnopUp.Height - 1 do
      for XX := 0 to KnopUp.Width - 1 do
      begin
        PixelColor := KnopUp.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          KnopUp.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  KnopUp.Transparent := True;
  KnopUp.TransParentColor := clFuchsia;//:= KnopUp.canvas.pixels[0,0];

  KnopDown:=TBitmap.Create;
  KnopDown.LoadFromResourceName(HInstance,'WSENS_IN');
  for YY := 0 to KnopDown.Height - 1 do
      for XX := 0 to KnopDown.Width - 1 do
      begin
        PixelColor := KnopDown.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          KnopDown.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  KnopDown.Transparent := True;
  KnopDown.TransParentColor := clFuchsia;//:= KnopDown.canvas.pixels[0,0];
  FTaal:='NL';
  FNaam:='Temperatuursensor';
  FInfo:= 'Temperatuursensor';
  ShowHint:=true;
  FSoort:='Invoer';
end;

destructor TjanSimWarm.Destroy;
begin
  knopUp.Free;
  knopDown.Free;
  connectors.free;
  inherited;
end;

procedure TjanSimWarm.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  R, R2: TRect;
  p: TPoint;
  wc: TWinControl;
  L, T: Integer;
begin
  inherited;

  // Rechtsklik: popup tonen
  if (Button = mbRight) and (FLock = False) then
  begin
    BuildPopup;
    UpdatePopupCaptions;

    p := Point(0, Height);
    p := ClientToScreen(p);
    PopupMenu.Popup(p.X, p.Y - 1);
    Exit;
  end;

  mdp := Point(X, Y);
  R := Rect(49,13,57,21);

  // maken van aansluitdraad
  if PtInRect(R, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + Width - 8;
    T := Top + 14;
    Maakdraad(T, L, wc);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;

  Screen.Cursor := crDefault;

  // einde van het maken van een aansluiting
  R2 := Rect(1,1,21,14);
  doMove := not PtInRect(R2, mdp);
  FDepressed := not doMove;
  oldp := Point(X, Y);

  if doMove then
  begin
    AnchorConnectors;

    if (Button = mbLeft) and (Parent is TjanGridS) then
      TjanGridS(Parent).BeginGuideLines(Left + Width div 2, Top + Height div 2);
  end
  else
    Invalidate;
end;

procedure TjanSimWarm.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  R: TRect;
  p: TPoint;
begin
  inherited;

  if Parent is TjanGridS then
    TjanGridS(Parent).EndGuideLines;

  Select := False;
  Repaint;
  FDepressed := False;

  p := Point(X, Y);
  R := Rect(1,1,21,14);

  if PtInRect(R, p) then
    Down := not Down;

  FMouseOver := True;
  SendStatusToBar;
end;

procedure TjanSimWarm.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  p: TPoint;
  Grid: TjanGridS;
  SnapP: TPoint;
  WorkR: TRect;
begin
  inherited;

  if FLock = True then Exit;
  if FDepressed then Exit;
  if Parent = nil then Exit;

  p := ClientToScreen(Point(X, Y));
  p := Parent.ScreenToClient(p);

  if (ssLeft in Shift) then
  begin
    if doMove then
    begin
      NewLeft := p.X - mdp.X;
      NewTop := p.Y - mdp.Y;

      if Parent is TjanGridS then
      begin
        Grid := TjanGridS(Parent);
        WorkR := Grid.GetWorkAreaRect;

        // snappen op het midden van het object
        SnapP := Point(NewLeft + Width div 2, NewTop + Height div 2);
        SnapP := Grid.SnapPointToRuler(SnapP, WorkR);

        NewLeft := SnapP.X - Width div 2;
        NewTop := SnapP.Y - Height div 2;
      end;

      StraightenWires(connectors,newleft,newtop); SnapToRail(Self,newleft);
      Left := NewLeft;
      Top := NewTop;
      MoveConnectors;

      if Parent is TjanGridS then
        TjanGridS(Parent).UpdateGuideLines(Left + Width div 2, Top + Height div 2);

      FMouseOver := True;
      SendStatusToBar;
    end;
  end;
end;

procedure TjanSimWarm.BuildPopup;
        var
        miLock, miName, miInfo, miSelect: TMenuItem;
       begin
         if not Assigned(PopupMenu) then
           PopupMenu := TPopupMenu.Create(Self)
         else
           PopupMenu.Items.Clear;
         // --- Lock / Unlock
          miLock := TMenuItem.Create(PopupMenu);
          miLock.Name := 'miLock';
          miLock.OnClick := ButtonClick1;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miLock);

         // --- Naam wijzigen
          miName := TMenuItem.Create(PopupMenu);
          miName.Name := 'miName';
          miName.OnClick := ButtonNClick;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miName);

         // --- Info aan/uit
          miInfo := TMenuItem.Create(PopupMenu);
          miInfo.Name := 'miInfo';
          miInfo.OnClick := ButtonClick3;     // Delphi-mode: geen @
          PopupMenu.Items.Add(miInfo);


          // --- Selecteer voor verwijdering
           miSelect := TMenuItem.Create(PopupMenu);
           miSelect.Name := 'miSelect';
           miSelect.OnClick := ButtonClick4;     // Delphi-mode: geen @
           PopupMenu.Items.Add(miSelect);
       end;

procedure TjanSimWarm.UpdatePopupCaptions;
       var
        miLock, miName, miInfo, miSelect: TMenuItem;
        s: string;
       begin
        if not Assigned(PopupMenu) then Exit;

        miLock := TMenuItem(PopupMenu.FindComponent('miLock'));
        miName := TMenuItem(PopupMenu.FindComponent('miName'));
        miInfo := TMenuItem(PopupMenu.FindComponent('miInfo'));
        miSelect := TMenuItem(PopupMenu.FindComponent('miSelect'));

        if Assigned(miLock) then
         begin
          if BTaal = 'NL' then
          begin
           if FLock then s := 'Ontgrendel' else s := 'Vergrendel';
          end
          else if BTaal = 'FR' then
          begin
           if FLock then s := 'Déverrouiller' else s := 'Verrouiller';
          end
		  else if BTaal = 'DU' then
          begin
           if FLock then s := 'Déverrouiller' else s := 'Sperren';
          end
          else
          begin
           if FLock then s := 'Unbolt' else s := 'Bolt';
         end;
         miLock.Caption := LangTr(s);
        end;

        if Assigned(miName) then
         begin
          if BTaal = 'NL' then s := 'Wijzig Naam'
          else if BTaal = 'FR' then s := 'Changer le nom'
		   else if BTaal = 'DU' then s := 'Namen ändern'
          else s := 'Change name';
          miName.Caption := LangTr(s);
         end;

         // --- Select / Deselect (TOGGLE)
        if Assigned(miSelect) then
         begin
          if not Selected then
           begin
            if BTaal = 'NL' then s := 'Selecteer object'
            else if BTaal = 'FR' then s := 'Sélectionner un objet'
            else if BTaal = 'DU' then s := 'Objekt auswählen'
            else s := 'Select object';
           end
          else
          begin
           if BTaal = 'NL' then s := 'Deselecteer object'
           else if BTaal = 'FR' then s := 'Désélectionner l''objet'
           else if BTaal = 'DU' then s := 'Objekt abwählen'
           else s := 'Deselect object';
          end;
          miSelect.Caption := LangTr(s);
         end;

        if Assigned(miInfo) then
         begin
          if ShowHint then
           begin
            if BTaal = 'NL' then s := 'Info uit'
            else if BTaal = 'FR' then s := 'Infos off'
			else if BTaal = 'DU' then s := 'Infos raus'
            else s := 'Information off';
           end
           else
         begin
          if BTaal = 'NL' then s := 'Info aan'
          else if BTaal = 'FR' then s := 'Infos on'
		  else if BTaal = 'DU' then s := 'Infos zu'
          else s := 'Information on';
         end;
    miInfo.Caption := LangTr(s);
  end;
end;



procedure TjanSimWarm.MoveConnectors;
var i:integer;
    con:TjanConnector;
begin
  select:=true;
  if connectors.Count=0 then exit;
  for i:=0 to connectors.count-1 do
  begin
    con:=TjanConnector(connectors[i]);
    con.MoveConnector(point(newleft,newtop));
  end;
end;

procedure TjanSimWarm.Paint;
var p:Tpoint;
    R:TRect;
begin
 knopDown.Transparent:=true;
 knopUp.Transparent:=true;
 with canvas do
   begin
     Lock;
     R:=ClientRect;
     if FDepressed or FDown then
       Begin
        PaintInputSymbol(Self,Canvas,knopDown,3,True);
        brush.style:=bsclear;
        Font.Name:='Arial';Font.Size:=9;Font.Style:= [fsBold];
        Font.Color:=clRed;
        TextOut(50,20,'1');
       end
       else
       begin
        PaintInputSymbol(Self,Canvas,knopUp,3,False);
        brush.style:=bsclear;
        Font.Name:='Arial';Font.Size:=9;Font.Style:= [fsBold];
        Font.Color:=clNavy;
        TextOut(50,20,'0');
       end;
     brush.style:=bsclear;
     Font.Style:= [];Font.Color:=clBlack;
     If BTaal='NL' then begin If Down=false then TextOut(1,20,'koud') else TextOut(1,20,'warm');end;
     If BTaal='ENG' then begin If Down=false then TextOut(1,20,'cold') else TextOut(1,20,'hot');end;
     If BTaal='FR' then begin If Down=false then TextOut(1,20,'froid') else TextOut(1,20,'chauffer');end;
     If BTaal='DU' then begin If Down=false then TextOut(1,20,'kalt') else TextOut(1,20,'heiß');end;
     Unlock;
  end;
  if select=true then
     begin
     R:=ClientRect;
      canvas.pen.Color:=clblack;
      canvas.pen.style:=psDot;canvas.Brush.Style:=bsClear;
      canvas.Lock;canvas.rectangle(R);canvas.Unlock;
      canvas.pen.Color:=clBlack;canvas.pen.style:=psSolid;
     end;
    if Selected then   //kader voor selectie delete
     begin
      R := ClientRect;
      // InflateRect(R, -1, -1);         // binnen de rand tekenen
      Canvas.Brush.Style := bsClear;
      Canvas.Pen.Color := clRed;
      Canvas.pen.style:=psDot;
      Canvas.Pen.Width := 1;
      Canvas.Rectangle(R);
      // restore (netjes)
      Canvas.Pen.Width := 1;
      Canvas.pen.style:=psSolid;
      Canvas.Brush.Style := bsSolid;
     end;

end;

procedure TjanSimWarm.PaintLed(pt:TPoint;lit:boolean);
var surfcol,litcol:Tcolor;
    x,y:integer;
begin
  x:=pt.x;
  y:=pt.y;
  if lit then
  begin
    surfcol:=clred;
    litcol:=clwhite
  end
  else
  begin
    surfcol:=clmaroon;
    litcol:=clred;
  end;
  with Canvas do
   begin
    lock;
    brush.color:=clsilver;
    fillrect(rect(x,y,x+12,y+13));
    brush.style:=bsclear;
    pen.color:=clgray;
    ellipse(x,y,x+12,y+13);
    pen.color:=clblack;
    brush.color:=surfcol;
    ellipse(x+1,y+1,x+11,y+12);
    pen.color:=clwhite;
    arc(x+1,y+1,x+11,y+12,x+0,y+12,x+12,y+0);
    pen.color:=litcol;
    arc(x+3,y+3,x+8,y+9,x+5,y+0,x+0,y+8);
    unlock;
   end;
end;

procedure TjanSimWarm.Resize;
begin
  width:=58;
  height:=32;
end;



//nieuwe POPUPMENU event
procedure TjanSimWarm.ButtonClick1(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

//nieuwe POPUPMENU event
procedure TjanSimWarm.ButtonClick3(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;
//nieuwe POPUPMENU event
procedure TjanSimWarm.ButtonNClick(Sender: TObject);
var
  dlg: TInputBoxForm;
  s: string;
begin
  dlg := TInputBoxForm.Create(nil);
  try
    if dlg.Execute('Naam wijzigen', 'Geef een naam:', Naam, s) then
      Naam := s;  // setter -> Invalidate
  finally
    dlg.Free;
  end;
end;

procedure TjanSimWarm.ButtonClick4(Sender: TObject);
begin
  if Assigned(FBox) then
    FBox.SelectObject(Self);
end;

procedure TjanSimWarm.SetDown(const Value: boolean);
begin
  if value<>FDown then
  begin
    FDown := Value;
    FDepressed:=value;
    puls:=1;
    if FDown=true then FStatTemp := stTempStart else FStatTemp := stTempStop;
    invalidate;

    // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
  end;
  if Assigned(OnTempChange) then OnTempChange(Self, StatTemp);
end;

procedure TjanSimWarm.SetInfo(const Value: String);
begin
  if value<>FInfo then
  begin
    FInfo := Value;
 end;
end;
procedure TjanSimWarm.SetLock(const Value: boolean);
begin
  if value<>FLock then
  begin
    FLock := Value;
 end;
end;

procedure TjanSimWarm.SetPuls(const Value: Integer);
begin
  if value<>FPuls then
  begin
    FPuls:= Value;
 end;
end;

//nieuwe TOEGEVOEGD event
procedure TjanSimWarm.SendStatusToBar;
var
  s, ss: string;
  wInput, wStatus: string;
begin
  if not Assigned(FOnStatus) then Exit;

  wInput  := Tr(BTaal,'Invoer','Input','Entrée','Eingang');
  wStatus := Tr(BTaal,'Status','Status','Statut','Status');

  // Panel 0
 FOnStatus(Self, FNaam + ' > ', 0);

  // Panel 1
  if FDown then
    s := wStatus + ' = 1'
  else
    s := wStatus + ' = 0';
  FOnStatus(Self, s, 1);

  // Panel 2
  ss := Format('X=%d Y=%d', [Left, Top]);
  FOnStatus(Self, ss, 2);
end;

procedure TjanSimWarm.UpdateHintText;
begin
  Hint := BuildSimHint(FNaam, BTaal);
end;

// NIEUW Setnaam
procedure TjanSimWarm.SetNaam(const Value: String);
begin
   if FNaam <> Value then
  begin
    FNaam := Value;
    Invalidate;
    // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
  end;
end;

procedure TjanSimWarm.SetTaal(const Value: String);
begin
  if value<>FTaal then
  begin
    FTaal:= Value;
 end;
 if value='NL' then FInfo:='Temperatuursensor'
 else if value='ENG' then FInfo:='Temperature sensor'
 else if value='FR' then FInfo:= 'Le capteur de température'
 else if value='DU' then FInfo:= 'Schalter';
invalidate;

// ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
end;
