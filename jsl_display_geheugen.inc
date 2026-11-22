// janSimLogic.pas, deel: display en geheugen (ingevoegd met {$I jsl_display_geheugen.inc})



{ TjanDisplay }
const
  SegState: array[0..127] of word =   { all ASCII chars, display '-' if unknown }
              ($0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002,
               $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002,
               $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002,
               $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002,
               $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002,
               $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002,
               $007d, $0050, $0037, $0057, $005a, $004f, $006f, $0051,   { 0 1 2 3 4 5 6 7 }
               $007f, $005f, $0002, $0002, $0002, $0002, $0002, $0002,   { 8 9             }
               $0002, $007b, $006e, $002d, $0076, $002f, $002b, $0002,   { A B C D E F G   }
               $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002,
               $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002,
               $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002,
               $0002, $007b, $006e, $002d, $0076, $002f, $002b, $0002,   { a b c d e f g   }
               $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002,
               $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002,
               $0002, $0002, $0002, $0002, $0002, $0002, $0002, $0002);


constructor TjanDisplay.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Select:=false;
  Width := 74;
  Height := 90;
  FOnColor := clBlue;
  FOffColor :=clCream;
  //willem
  FBackColor := clSilver;
  FPenOnColor := clAqua;
  FPenOffColor:= clgray;
  FSegWidth := 3;
  FMargin := 25;
  FDigit:='0';
  FBits:=0;
  OldWidth := Width;
  OldHeight := Height;
  SetMeasures;

  connectors:=TList.create;

  FInfo:= 'Display';
  FDown:=false; //xxx
  FSoort:='Uitvoer';//xxx
  FNaam:='Display';//xxx
  ShowHint:=true;
end;

destructor TjanDisplay.Destroy;
begin
  inherited;
  connectors.free;
end;

procedure TjanDisplay.SendStatusToBar;
var
   s, ss: string;
   wInput, wStatus: string;
 begin
   if not Assigned(FOnStatus) then Exit;

   wInput  := Tr(BTaal,'Uitvoer','Export','Exporter','Export');
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

 procedure TjanDisplay.SetNaam(const Value: String);
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

procedure TjanDisplay.SetTaal(const Value: String);
begin
if value<>FTaal then
 begin
   FTaal:= Value;
end;
// ✅ Onmiddellijke refresh als muis erboven staat
   if FMouseOver then
     SendStatusToBar;
   UpdateHintText;
   invalidate;
end;

procedure TjanDisplay.SetDown(const Value: boolean);
begin
  if value<>FDown then
  begin
   FDown := Value;
   FDepressed:=value;

   invalidate;

    // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
  end;
end;

procedure TjanDisplay.BuildPopup;
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

 procedure TjanDisplay.UpdatePopupCaptions;
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

procedure TjanDisplay.UpdateHintText;
begin
  Hint := BuildSimHint(FNaam, BTaal);
end;


procedure TjanDisplay.AnchorConnectors;
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

procedure TjanDisplay.MoveConnectors;
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

procedure TjanDisplay.Click1(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanDisplay.Click2(sender:TObject);
Begin
free;
end;

procedure TjanDisplay.Click3(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;

procedure TjanDisplay.ButtonClick1(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanDisplay.ButtonClick3(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;

procedure TjanDisplay.ButtonNClick(Sender: TObject);
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

procedure TjanDisplay.ButtonClick4(sender:TObject); //selecteer
begin
 if Assigned(FBox) then
    FBox.SelectObject(Self);
end;


procedure TjanDisplay.SetInfo(const Value: String);
begin
  if value<>FInfo then
  begin
    FInfo := Value;
 end;
end;

procedure TjanDisplay.SetLock(const Value: boolean);
begin
  if value<>FLock then
  begin
    FLock := Value;
 end;
end;

procedure TjanDisplay.CMMouseLeave(var Msg: TMessage);
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

procedure TjanDisplay.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
 UpdateHintText;
if Assigned(FOnEnter) then
   FOnEnter(Self);


// ✅ statusbar meteen vullen
 FMouseOver := True;
 SendStatusToBar;  // vult panel 0/1/2


 BringToFront;
 if not FLock then
 begin
   Select := True;
   Invalidate;
 end;
end;

procedure TjanDisplay.CMHitTest(var Message: TCMHitTest);
 begin
 inherited;
   Message.Result := 0;
   if Canvas.Pixels[Message.XPos, Message.YPos] = clLime then
    begin
    Message.Result := 1;SendToBack;exit;
    end;
   if Canvas.Pixels[Message.XPos, Message.YPos] <> clLime then
    begin
    Message.Result := 1;BringToFront;exit;
    end;
end;


procedure TjanDisplay.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
p : TPoint;
S:String;
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
  mdp:=point(x,y);
  doMove:= true;
  oldp:=point(x,y);
  AnchorConnectors;
    // GuideLines enkel starten bij echt bewegen
    if (Button = mbLeft) and (Parent is TjanGridS) then
      TjanGridS(Parent).BeginGuideLines(Left + Width div 2, Top + Height div 2);
end;

procedure TjanDisplay.MouseMove(Shift: TShiftState; X, Y: Integer);
var
p:TPoint;
Grid: TjanGridS;
SnapP: TPoint;
WorkR: TRect;
begin
   if FLock=true then exit;
   if FDepressed then exit;
   if Parent = nil then Exit;

   p:=clienttoscreen(point(x,y));
   p:=parent.ScreenToClient(p);


   if (ssleft in shift) then
   begin
     if doMove then
     begin
     newleft:=p.x-mdp.x;
     newtop:=p.y-mdp.y;

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
     Left:=newleft;
     Top:=newtop;

     MoveConnectors;

     if Parent is TjanGridS then
        TjanGridS(Parent).UpdateGuideLines(Left + Width div 2, Top + Height div 2);

      FMouseOver := True;
  SendStatusToBar;
     end
   end;

end;

procedure TjanDisplay.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var R:TRect;
      p:Tpoint;
  begin
   inherited;
    if Parent is TjanGridS then
           TjanGridS(Parent).EndGuideLines;
    movecursor;
    FDepressed:=false;
    p:=point(x,y);
    R:=Rect(13,66,37,75);

    if ptinrect(R,p) then Down:=not FDown;

    FMouseOver := True;
    SendStatusToBar;
  end;

procedure TjanDisplay.SetBits(const Value:Integer);

begin
  if value <> FBits then
  begin
     FBits := Value;
     If FBits=0 then FDigit:='0';
     If FBits=1 then FDigit:='1';
     If FBits=2 then FDigit:='2';
     If FBits=3 then FDigit:='3';
     If FBits=4 then FDigit:='4';
     If FBits=5 then FDigit:='5';
     If FBits=6 then FDigit:='6';
     If FBits=7 then FDigit:='7';
     If FBits=8 then FDigit:='8';
     If FBits=9 then FDigit:='9';
     If FBits=10 then FDigit:='A';
     If FBits=11 then FDigit:='B';
     If FBits=12 then FDigit:='C';
     If FBits=13 then FDigit:='D';
     If FBits=14 then FDigit:='E';
     If FBits=15 then FDigit:='F';
  invalidate;
  end;
end;



procedure TjanDisplay.SetDigit(WhatDigit: char);
begin
  if WhatDigit <> FDigit then
  begin
    FDigit := WhatDigit;
    if FDigit='0' then FBits:=0;
    if FDigit='1' then FBits:=1;
    if FDigit='2' then FBits:=2;
    if FDigit='3' then FBits:=3;
    if FDigit='4' then FBits:=4;
    if FDigit='5' then FBits:=5;
    if FDigit='6' then FBits:=6;
    if FDigit='7' then FBits:=7;
    if FDigit='8' then FBits:=8;
    if FDigit='9' then FBits:=9;
    if FDigit='A' then FBits:=10;
    if FDigit='B' then FBits:=11;
    if FDigit='C' then FBits:=12;
    if FDigit='D' then FBits:=13;
    if FDigit='E' then FBits:=14;
    if FDigit='F' then FBits:=15;
  invalidate;
  end;
end;

procedure TjanDisplay.SetOnColor(WhatColor: TColor);
begin
  if WhatColor <> FOnColor then
  begin
    FOnColor := WhatColor;
    Refresh;
  end;
end;

procedure TjanDisplay.SetPenOnColor(WhatColor: TColor);
begin
  if WhatColor <> FPenOnColor then
  begin
    FPenOnColor := WhatColor;
    Refresh;
  end;
end;

procedure TjanDisplay.SetOffColor(WhatColor: TColor);
begin
  if WhatColor <> FOffColor then
  begin
    FOffColor := WhatColor;
    Refresh;
  end;
end;

procedure TjanDisplay.SetPenOffColor(WhatColor: TColor);
begin
  if WhatColor <> FPenOffColor then
  begin
    FPenOffColor := WhatColor;
    Refresh;
  end;
end;

procedure TjanDisplay.SetBackColor(WhatColor: TColor);
begin
  if WhatColor <> FBackColor then
  begin
    FBackColor := WhatColor;
    Refresh;
  end;
end;

procedure TjanDisplay.SetSegWidth(WhatWidth: integer);
begin
  if WhatWidth <> FSegWidth then
  begin
    FSegWidth := WhatWidth;
    SetMeasures;
    Refresh;
  end;
end;

procedure TjanDisplay.SetMargin(WhatWidth: integer);
begin
  if WhatWidth <> FMargin then
  begin
    FMargin := WhatWidth;
    SetMeasures;
    Refresh;
  end;
end;



procedure TjanDisplay.Hexagon(WhereTo: TBitmap; x, y, w, h: integer; OnOff: boolean);
begin
  if OnOff then
  begin
    WhereTo.Canvas.Brush.Color := FOnColor;
    WhereTo.Canvas.Pen.Color := FPenOnColor;
  end
  else
  begin
    WhereTo.Canvas.Brush.Color := FOffColor;
    WhereTo.Canvas.Pen.Color := FPenOffColor;
  end;
  if h > w then { vertical, w is SegWidth }
    WhereTo.Canvas.Polygon([Point(x, y + SegHalf), Point(x + SegHalf, y),
                            Point(x + w, y + SegHalf), Point(x + w, y + h - SegHalf),
                            Point(x + SegHalf, y + h), Point(x, y + h - SegHalf)])
  else          { horizontal, h is SegWidth }
    WhereTo.Canvas.Polygon([Point(x, y + SegHalf), Point(x + SegHalf, y),
                            Point(x + w - SegHalf, y), Point(x + w, y + SegHalf),
                            Point(x + w - SegHalf, y + h), Point(x + SegHalf, y + h)]);
end;

procedure TjanDisplay.DrawDot(WhereTo: TBitmap; x, y: integer; OnOff: boolean);
begin
  if OnOff then
  begin
    WhereTo.Canvas.Brush.Color := FOnColor;
    WhereTo.Canvas.Pen.Color := FPenOnColor;
  end
  else
  begin
    WhereTo.Canvas.Brush.Color := FOffColor;
    WhereTo.Canvas.Pen.Color := FPenOffColor;
  end;
  WhereTo.Canvas.Rectangle(x, y, x + FSegWidth, y + FSegWidth);
end;

procedure TjanDisplay.DrawBulb(WhereTo: TBitmap; x, y: integer; OnOff: boolean);
begin
  if OnOff then
  begin
    WhereTo.Canvas.Brush.Color := FOnColor;
    WhereTo.Canvas.Pen.Color := FPenOnColor;
  end
  else
  begin
    WhereTo.Canvas.Brush.Color := FOffColor;
    WhereTo.Canvas.Pen.Color := FPenOffColor;
  end;
  WhereTo.Canvas.Ellipse(x, y, x + FSegWidth, y + FSegWidth);
end;

procedure TjanDisplay.DrawTopSegment(WhereTo: TBitmap; x, y, w, h: integer; OnOff: boolean);
begin
  if OnOff then
  begin
    WhereTo.Canvas.Brush.Color := FOnColor;
    WhereTo.Canvas.Pen.Color := FPenOnColor;
  end
  else
  begin
    WhereTo.Canvas.Brush.Color := FOffColor;
    WhereTo.Canvas.Pen.Color := FPenOffColor;
  end;
  WhereTo.Canvas.Polygon([Point(x, y), Point(x + FSegWidth, y + h),
                          Point(x + w - FSegWidth, y + h), Point(x + w, y)]);
end;

procedure TjanDisplay.DrawBottomSegment(WhereTo: TBitmap; x, y, w, h: integer; OnOff: boolean);
begin
  if OnOff then
  begin
    WhereTo.Canvas.Brush.Color := FOnColor;
    WhereTo.Canvas.Pen.Color := FPenOnColor;
  end
  else
  begin
    WhereTo.Canvas.Brush.Color := FOffColor;
    WhereTo.Canvas.Pen.Color := FPenOffColor;
  end;
  WhereTo.Canvas.Polygon([Point(x, y + h), Point(x + FSegWidth, y),
                          Point(x + w - FSegWidth, y), Point(x + w, y + h)]);
end;

procedure TjanDisplay.DrawLeftSegment(WhereTo: TBitmap; x, y, w, h: integer; OnOff: boolean);
begin
  if OnOff then
  begin
    WhereTo.Canvas.Brush.Color := FOnColor;
    WhereTo.Canvas.Pen.Color := FPenOnColor;
  end
  else
  begin
    WhereTo.Canvas.Brush.Color := FOffColor;
    WhereTo.Canvas.Pen.Color := FPenOffColor;
  end;
  WhereTo.Canvas.Polygon([Point(x, y), Point(x + w, y + FSegWidth),
                          Point(x + w, y + h - FSegWidth), Point(x, y + h)]);
end;

procedure TjanDisplay.DrawRightSegment(WhereTo: TBitmap; x, y, w, h: integer; OnOff: boolean);
begin
  if OnOff then
  begin
    WhereTo.Canvas.Brush.Color := FOnColor;
    WhereTo.Canvas.Pen.Color := FPenOnColor;
  end
  else
  begin
    WhereTo.Canvas.Brush.Color := FOffColor;
    WhereTo.Canvas.Pen.Color := FPenOffColor;
  end;
  WhereTo.Canvas.Polygon([Point(x + w, y), Point(x, y + FSegWidth),
                          Point(x, y + h - FSegWidth), Point(x + w, y + h)]);
end;

procedure TjanDisplay.DrawNorthWest(WhereTo: TBitmap; x1, y1, x2, y2: integer; OnOff: boolean);
begin
  if OnOff then
  begin
    WhereTo.Canvas.Brush.Color := FOnColor;
    WhereTo.Canvas.Pen.Color := FPenOnColor;
  end
  else
  begin
    WhereTo.Canvas.Brush.Color := FOffColor;
    WhereTo.Canvas.Pen.Color := FPenOffColor;
  end;
  WhereTo.Canvas.Polygon([Point(x1, y1), Point(x1 + SegHalf, y1),
                          Point(x2, y2 - FSegWidth), Point(x2, y2),
                          Point(x2 - SegHalf, y2), Point(x1, y1 + FSegWidth)]);
end;

procedure TjanDisplay.DrawNorthEast(WhereTo: TBitmap; x1, y1, x2, y2: integer; OnOff: boolean);
begin
  if OnOff then
  begin
    WhereTo.Canvas.Brush.Color := FOnColor;
    WhereTo.Canvas.Pen.Color := FPenOnColor;
  end
  else
  begin
    WhereTo.Canvas.Brush.Color := FOffColor;
    WhereTo.Canvas.Pen.Color := FPenOffColor;
  end;
  WhereTo.Canvas.Polygon([Point(x1, y1), Point(x1, y1 - FSegWidth),
                          Point(x2 - SegHalf, y2), Point(x2, y2),
                          Point(x2, y2 + FSegWidth), Point(x1 + SegHalf, y1)]);
end;

procedure TjanDisplay.SetMeasures;
begin
 SegHalf := FSegWidth div 2;
 SegHorLen := Width - FMargin * 2 - FSegWidth;
 SegVerLen := Height div 2 - FSegWidth - SegHalf - FMargin;
 UpLeft[0] := Point(FMargin + SegHalf, FMargin);                         { 3 hor }
 UpLeft[1] := Point(FMargin + SegHalf, Height div 2 - SegHalf);
 UpLeft[2] := Point(FMargin + SegHalf, Height - FMargin - FSegWidth);
 UpLeft[3] := Point(FMargin, FMargin + FSegWidth);                       { 4 ver }
 UpLeft[4] := Point(Width - FMargin - FSegWidth, FMargin + FSegWidth);
 UpLeft[5] := Point(FMargin, Height div 2 + SegHalf);
 UpLeft[6] := Point(Width - FMargin - FSegWidth, Height div 2 + SegHalf);
end;

procedure TjanDisplay.DrawDigit(WhereTo: TBitmap);
var
  i : integer;
  S : word;
begin
   with WhereTo.Canvas do
        begin
          Lock;
          i := ord(FDigit) and $7F;
          S := SegState[i];
          if FDigit = ' ' then S := 0;   // spatie = alle segmenten uit (geen voeding)
          Hexagon(WhereTo, UpLeft[0].x, UpLeft[0].y, SegHorLen, FSegWidth, S and $0001 <> 0);
          Hexagon(WhereTo, UpLeft[1].x, UpLeft[1].y, SegHorLen, FSegWidth, S and $0002 <> 0);
          Hexagon(WhereTo, UpLeft[2].x, UpLeft[2].y, SegHorLen, FSegWidth, S and $0004 <> 0);
          Hexagon(WhereTo, UpLeft[3].x, UpLeft[3].y, FSegWidth, SegVerLen, S and $0008 <> 0);
          Hexagon(WhereTo, UpLeft[4].x, UpLeft[4].y, FSegWidth, SegVerLen, S and $0010 <> 0);
          Hexagon(WhereTo, UpLeft[5].x, UpLeft[5].y, FSegWidth, SegVerLen, S and $0020 <> 0);
          Hexagon(WhereTo, UpLeft[6].x, UpLeft[6].y, FSegWidth, SegVerLen, S and $0040 <> 0);
          Unlock;
        end;
end;

const
  // display: ingangen 1, 2, 4, 8 van boven naar onder (zoals bij een decoder);
  // zo kruisen de draden niet vanaf de uitgangen 8-4-2-1 onderaan een teller
  DispBcdY: array[0..3] of Integer = (12, 28, 62, 78);
  DispBcdW: array[0..3] of Integer = (1, 2, 4, 8);
  MemDataW: array[0..3] of Integer = (8, 4, 2, 1);   // geheugen: D8, D4, D2, D1
  MemDataY: array[0..4] of Integer = (96, 110, 124, 138, 150);  // 8, 4, 2, 1 en S

function HexTeken(AWaarde: Integer): Char;
begin
  if AWaarde < 10 then Result := Chr(Ord('0') + AWaarde)
  else Result := Chr(Ord('A') + AWaarde - 10);
end;

function TjanDisplay.BcdIndexAt(const P: TPoint): Integer;
var
  i: Integer;
begin
  Result := -1;
  if (P.X < Left - 6) or (P.X > Left + 9) then Exit;
  for i := 0 to 3 do
    if Abs(P.Y - (Top + DispBcdY[i])) <= 6 then Exit(i);
end;

// een van de ingangen 8-4-2-1 verandert: het cijfer is de som van wat aan staat
procedure TjanDisplay.ZetBcd(AIndex: Integer; AAan: Boolean);
var
  i, S: Integer;
begin
  if (AIndex < 0) or (AIndex > 3) then Exit;
  if (FBcd[AIndex] = AAan) and FBcdGebruikt then Exit;
  FBcd[AIndex] := AAan;
  FBcdGebruikt := True;
  S := 0;
  for i := 0 to 3 do
    if FBcd[i] then S := S + DispBcdW[i];
  Digit := HexTeken(S);
  Invalidate;
end;

function TjanMemory.DataIndexAt(const P: TPoint): Integer;
var
  i: Integer;
begin
  Result := -1;
  if (P.X < Left - 6) or (P.X > Left + 9) then Exit;
  for i := 0 to 4 do
    if Abs(P.Y - (Top + MemDataY[i])) <= 5 then Exit(i);
end;

function TjanMemory.InhoudTekst: string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to 31 do
    Result := Result + HexTeken(StrToIntDef(Lijst.Strings[i], 0) and 15);
end;

// ARest = 'breedte;inhoud;...' uit het paneelbestand; zonder inhoud blijft alles 0
procedure TjanMemory.ZetInhoudUitRest(const ARest: string);
var
  S: string;
  p, i, V: Integer;
begin
  S := ARest;
  p := Pos(';', S);
  if p = 0 then Exit;
  Delete(S, 1, p);
  p := Pos(';', S);
  if p > 0 then S := Copy(S, 1, p - 1);
  S := Trim(S);
  if Length(S) <> 32 then Exit;
  for i := 0 to 31 do
  begin
    V := StrToIntDef('$' + S[i + 1], 0);
    Lijst.Strings[i] := IntToStr(V);
  end;
  schrijf := False;
  FBits := -1;   // zeker opnieuw tonen
  Bits := StrToInt(Lijst.Strings[FAdress]);
end;

// data-ingang 8-4-2-1 of schrijfingang S: bij de stijgende flank van S komt
// het getal van de data-ingangen in het gekozen adres
procedure TjanMemory.ZetData(AIndex: Integer; AAan: Boolean);
var
  i, S: Integer;
begin
  if (AIndex >= 0) and (AIndex <= 3) then
  begin
    if FDin[AIndex] <> AAan then
    begin
      FDin[AIndex] := AAan;
      Invalidate;
    end;
    Exit;
  end;
  if AIndex <> 4 then Exit;
  if AAan and not FSchrijfIn then
  begin
    S := 0;
    for i := 0 to 3 do
      if FDin[i] then S := S + MemDataW[i];
    if S <> FBits then
    begin
      schrijf := True;
      Bits := S;        // SetBits bewaart het in het gekozen adres
    end;
  end;
  if FSchrijfIn <> AAan then
  begin
    FSchrijfIn := AAan;
    Invalidate;
  end;
end;

procedure TjanDisplay.Paint;
var
  R: TRect;
  PaintBMP, lIn: TBitmap;
  XX, YY: Integer;
  PixelColor: TColor;
begin
  inherited;

  if (OldHeight <> Height) or (OldWidth <> Width) then
  begin
    SetMeasures;
    OldHeight := Height;
    OldWidth  := Width;
  end;

  Canvas.Lock;
  try
    // Achtergrond component
    Canvas.Brush.Color := FBackColor;
    Canvas.Brush.Style := bsSolid;
    Canvas.Pen.Style   := psDot;
    Canvas.Rectangle(22, 10, Width - 10, Height - 10);

    // Digit bitmap
    PaintBMP := TBitmap.Create;
    try
      PaintBMP.Height := Height - 2;
      PaintBMP.Width  := Width - 2;

      with PaintBMP.Canvas do
      begin
        Lock;
        try
          Brush.Color := clCream;
          R := Rect(0, 0, PaintBMP.Width, PaintBMP.Height);
          FillRect(R);
        finally
          Unlock;
        end;
      end;

      DrawDigit(PaintBMP);

      Canvas.CopyMode := cmSrcCopy;
      PaintBMP.Transparent := True;
      PaintBMP.TransparentColor := clFuchsia;
      Canvas.Draw(0, 0, PaintBMP);
    finally
      PaintBMP.Free;
    end;

    // LOG_IN bitmap
    lIn := TBitmap.Create;
    try
      lIn.LoadFromResourceName(HInstance, 'LOG_IN');
      lIn.Transparent := True;

      for YY := 0 to lIn.Height - 1 do
        for XX := 0 to lIn.Width - 1 do
        begin
          PixelColor := lIn.Canvas.Pixels[XX, YY];
          if (Red(PixelColor) > 200) and
             (Green(PixelColor) > 200) and
             (Blue(PixelColor) > 200) then
            lIn.Canvas.Pixels[XX, YY] := clFuchsia;
        end;

      lIn.TransparentColor := clFuchsia;
      lIn.Transparent := True;
      Canvas.Draw(0, (Height div 2) - (lIn.Height div 2), lIn);
    finally
      lIn.Free;
    end;

    // de ingangen 8, 4, 2 en 1 links (groen = 1)
    Canvas.Pen.Style := psSolid; Canvas.Pen.Color := clBlack; Canvas.Pen.Width := 1;
    Canvas.Font.Name := 'Arial'; Canvas.Font.Size := 6; Canvas.Font.Style := [fsBold];
    for XX := 0 to 3 do
    begin
      YY := DispBcdY[XX];
      Canvas.MoveTo(7, YY); Canvas.LineTo(22, YY);
      Canvas.Brush.Style := bsSolid;
      if FBcd[XX] then Canvas.Brush.Color := clLime else Canvas.Brush.Color := clSilver;
      Canvas.Rectangle(1, YY - 3, 8, YY + 4);
      Canvas.Brush.Style := bsClear; Canvas.Font.Color := clNavy;
      Canvas.TextOut(10, YY - 11, IntToStr(DispBcdW[XX]));
    end;

    // Selectiekader ALS LAATSTE tekenen
    if Select then
    begin
      R := ClientRect;
      InflateRect(R, -1, -1);   // 1 pixel naar binnen

      Canvas.Brush.Style := bsClear;
      Canvas.Pen.Color   := clBlack;
      Canvas.Pen.Style   := psDot;
      Canvas.Rectangle(R);

      Canvas.Pen.Style   := psSolid;
    end;
    // tekenen van rode kader na selectie via popupmenu in paint onderaan
   if Selected then
     begin
     R := ClientRect;
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

  finally
    Canvas.Unlock;
  end;
end;
