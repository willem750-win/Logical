// janSimLogic.pas, deel: logische lamp, relais, schakelrelais, zoemer (ingevoegd met {$I jsl_uitvoer.inc})
// einde TjanSimWarm

procedure TjanSimLight.AnchorConnectors;
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

constructor TjanSimLight.Create(AOwner: TComponent);
var
XX, YY: Integer;
  PixelColor: TColor;
begin
  inherited Create(AOwner);
  Select:=false;
  FLock:=false;
  FLit:=false;
  width:=69;
  height:=23;
  connectors:=TList.create;

  lUit:=TBitmap.Create;
  lUit.LoadFromResourceName(HInstance,'L_UIT');
  for YY := 0 to lUit.Height - 1 do
      for XX := 0 to lUit.Width - 1 do
      begin
        PixelColor := lUit.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          lUit.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  lUit.Transparent := True;
  lUit.TransParentColor := lUit.canvas.pixels[0,0];

  lAan:=TBitmap.Create;
  lAan.LoadFromResourceName(HInstance,'L_AAN');
  for YY := 0 to lAan.Height - 1 do
      for XX := 0 to lAan.Width - 1 do
      begin
        PixelColor := lAan.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          lAan.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  lAan.Transparent := True;
  lAan.TransParentColor := lAan.canvas.pixels[0,0];


  FDown:=false; //xxx
  FInfo:= 'Lamp';//xxx
  FSoort:='Uitvoer';//xxx
  FNaam:='Lamp';//xxx
end;

destructor TjanSimLight.Destroy;
begin
  inherited;
  FDimBmp.Free;
  lUit.Free;
  lAan.Free;
  connectors.free;
end;

procedure TjanSimLight.SendStatusToBar;
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

 procedure TjanSimLight.SetNaam(const Value: String);
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

procedure TjanSimLight.SetTaal(const Value: String);
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

procedure TjanSimLight.SetDown(const Value: boolean);
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

procedure TjanSimLight.CMHitTest(var Message: TCMHitTest);
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



procedure TjanSimLight.CMMouseLeave(var Msg: TMessage);
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

procedure TjanSimLight.CMMouseEnter(var Msg: TMessage);
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





procedure TjanSimLight.MouseDown(Button: TMouseButton; Shift: TShiftState;
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

procedure TjanSimLight.MouseMove(Shift: TShiftState; X, Y: Integer);
var
p:TPoint;
Grid: TjanGridS;
SnapP: TPoint;
WorkR: TRect;
begin
inherited;
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

procedure TjanSimLight.MouseUp(Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
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

  procedure TjanSimLight.BuildPopup;
  var
    miLock, miName, miInfo, miSelect, miKleur, mi: TMenuItem;
    k: TLampKleur;
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

    // --- Kleur: lamp of led (rood, groen, oranje)
    miKleur := TMenuItem.Create(PopupMenu);
    miKleur.Caption := Tr(BTaal, 'Kleur', 'Colour', 'Couleur', 'Farbe');
    PopupMenu.Items.Add(miKleur);
    for k := Low(TLampKleur) to High(TLampKleur) do
    begin
      mi := TMenuItem.Create(PopupMenu);
      case k of
        lkLamp:   mi.Caption := Tr(BTaal, 'Lamp', 'Lamp', 'Lampe', 'Lampe');
        lkRood:   mi.Caption := Tr(BTaal, 'Rode led', 'Red LED', 'LED rouge', 'Rote LED');
        lkGroen:  mi.Caption := Tr(BTaal, 'Groene led', 'Green LED', 'LED verte', 'Grüne LED');
        lkOranje: mi.Caption := Tr(BTaal, 'Oranje led', 'Orange LED', 'LED orange', 'Orange LED');
      end;
      mi.Tag := Ord(k);
      mi.RadioItem := True;
      mi.Checked := k = FKleur;
      mi.OnClick := KleurClick;
      miKleur.Add(mi);
    end;
  end;

  procedure TjanSimLight.KleurClick(Sender: TObject);
  begin
    Kleur := TLampKleur(TMenuItem(Sender).Tag);
  end;

  procedure TjanSimLight.SetKleur(const Value: TLampKleur);
  begin
    if Value = FKleur then Exit;
    FKleur := Value;
    Invalidate;
  end;

  procedure TjanSimLight.UpdatePopupCaptions;
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

procedure TjanSimLight.UpdateHintText;
var
  U, R, I: Double;
begin
   Hint := BuildSimHint(FNaam, BTaal) + #13#10 +
     Tr(BTaal, 'Logische lamp: werkt op 5 V, zoals de uitgang van een poort.',
               'Logic lamp: works on 5 V, like the output of a gate.',
               'Lampe logique : fonctionne sur 5 V, comme la sortie d''une porte.',
               'Logische Lampe: arbeitet mit 5 V, wie der Ausgang eines Gatters.');
   // met een voeding: de berekening met de wet van Ohm bij hoogstens 5 V
   // (lamp 100 mA en led 20 mA, zie LoadAmps12)
   if (Parent <> nil) and PanelHasRails(Parent) and (LoadAmps12(Self) > 0) then
   begin
     U := MaxRailVolt(Parent);
     if U <= 0 then Exit;
     if U > LogicLampVolt then U := LogicLampVolt;
     R := LogicLampVolt / LoadAmps12(Self);
     I := U / R;
     Hint := Hint + #13#10 + 'U = ' + VoltText(U) + '    R = ' + OhmText(R) + #13#10 +
       'I = U / R = ' + VoltText(U) + ' / ' + OhmText(R) + ' = ' + AmpText(I) +
         ' = ' + MilliAmpText(I) + #13#10 +
       VermogenRegel(U, I);
   end;
end;

procedure TjanSimLight.MoveConnectors;
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

procedure TjanSimLight.Paint;
var
R:TRect;
Dim:Double;
BOn,BOff:TBitmap;
x,y:Integer;
COn,COff,Bg:TColor;
Key:string;

  procedure DrawLamp(ACanvas:TCanvas; ALit:Boolean);
  begin
    if FKleur<>lkLamp then
    begin
      // led: links het aansluitblokje met pijl van het lampje, rechts de led
      if ALit then
        DrawBitmapPart(ACanvas,lAan,Rect(0,0,37,Self.Height))
      else
        DrawBitmapPart(ACanvas,lUit,Rect(0,0,37,Self.Height));
      DrawLedSymbol(ACanvas,37,Self.Width-1,6,FKleur,ALit,SymOf(Self));
    end
    else if ALit then
      PaintOutputSymbol(Self,ACanvas,lAan,0,True)
    else
      PaintOutputSymbol(Self,ACanvas,lUit,0,False);
  end;

  function Mix(A,B:TColor; F:Double):TColor;
  begin
    A:=ColorToRGB(A); B:=ColorToRGB(B);
    Result:=RGBToColor(Round(Red(A)*F+Red(B)*(1-F)),Round(Green(A)*F+Green(B)*(1-F)),
      Round(Blue(A)*F+Blue(B)*(1-F)));
  end;

begin
 With canvas do
 begin
   Lock;
   lUit.Transparent:=true; lAan.Transparent:=true;
   // helderheid volgens de spanning van de voeding (12 V = vol); de pixels
   // die aan en uit verschillen worden gemengd
   Dim:=LampHelderheid(Self);
   if FLit and (Dim<0.97) and (FKleur=lkLamp) and (SymOf(Self)=Afbeelding) then
   begin
     // Afbeelding: de lamp is met code getekend; gedimd = de kleuren mengen,
     // rechtstreeks op het scherm (geen bitmap met doorzichtige kleur)
     LampPictureDim:=Dim;
     try
       DrawLamp(Canvas,True);
     finally
       LampPictureDim:=1;
     end;
   end
   else if FLit and (Dim<0.97) then
   begin
     // het gemengde beeld bewaren; alleen opnieuw mengen als de helderheid,
     // de grootte, de soort of de tekenwijze verandert
     if Parent<>nil then Bg:=ColorToRGB(Parent.Color) else Bg:=ColorToRGB(clBtnFace);
     Key:=Format('%d,%d,%d,%d,%d,%d',[Round(Dim*100),Self.Width,Self.Height,Ord(FKleur),Ord(SymOf(Self)),Bg]);
     if (FDimBmp=nil) or (FDimKey<>Key) then
     begin
     if FDimBmp=nil then FDimBmp:=TBitmap.Create;
     BOn:=TBitmap.Create; BOff:=TBitmap.Create;
     try
       BOn.SetSize(Self.Width,Self.Height); BOff.SetSize(Self.Width,Self.Height);
       BOn.Canvas.Brush.Color:=clFuchsia; BOn.Canvas.FillRect(Rect(0,0,Self.Width,Self.Height));
       BOff.Canvas.Brush.Color:=clFuchsia; BOff.Canvas.FillRect(Rect(0,0,Self.Width,Self.Height));
       DrawLamp(BOn.Canvas,True);
       DrawLamp(BOff.Canvas,False);
       // alleen het stuk waar aan en uit verschillen (de lamp zelf) mengen,
       // zonder doorzichtige kleur: die werkt niet overal (fuchsia rand)
       R:=Rect(Self.Width,Self.Height,-1,-1);
       for y:=0 to Self.Height-1 do
         for x:=0 to Self.Width-1 do
         begin
           COn:=BOn.Canvas.Pixels[x,y];
           if (COn<>BOff.Canvas.Pixels[x,y]) and (COn<>clFuchsia) then
           begin
             if x<R.Left then R.Left:=x; if x>R.Right then R.Right:=x;
             if y<R.Top then R.Top:=y; if y>R.Bottom then R.Bottom:=y;
           end;
         end;
       if R.Right<R.Left then R:=Rect(0,0,0,0);
       FDimPos:=Point(R.Left,R.Top);
       FDimBmp.SetSize(R.Right-R.Left+1,R.Bottom-R.Top+1);
       for y:=R.Top to R.Bottom do
         for x:=R.Left to R.Right do
         begin
           COn:=BOn.Canvas.Pixels[x,y];
           COff:=BOff.Canvas.Pixels[x,y];
           if COff=clFuchsia then COff:=Bg;
           if COn=clFuchsia then COn:=Bg;
           if COn<>COff then
             FDimBmp.Canvas.Pixels[x-R.Left,y-R.Top]:=Mix(COn,COff,Dim)
           else
             FDimBmp.Canvas.Pixels[x-R.Left,y-R.Top]:=COff;
         end;
     finally
       BOn.Free; BOff.Free;
     end;
     FDimKey:=Key;
     end;
     DrawLamp(Canvas,False);
     Canvas.Draw(FDimPos.X,FDimPos.Y,FDimBmp);
   end
   else
     DrawLamp(Canvas,FLit);
     brush.style:=bsclear;
     Font.Name:='Arial';
     Font.Size:=9;
     Font.Style:= [];
     Font.Color:=clNavy;
     if FKleur<>lkLamp then TextOut(1,11,'Led') else TextOut(1,11,'La');
   UnLock;
 end;
 if select=true then
     begin
     R:=ClientRect;
      canvas.pen.Color:=clblack;
      canvas.pen.style:=psDot;canvas.Brush.Style:=bsClear;
      canvas.Lock;canvas.rectangle(R);canvas.Unlock;
      canvas.pen.Color:=clBlack;canvas.pen.style:=psSolid;
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
end;

procedure TjanSimLight.Resize;
begin
  width:=69;
  height:=23;
end;

//old
{
procedure TjanSimLight.LampClick(sender:TObject);
Begin
If FLit=true then
     FLit:=false else FLit:=true;
invalidate;
end;

procedure TjanSimLight.LampClick1(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanSimLight.LampClick2(sender:TObject);
Begin
free;
end;

procedure TjanSimLight.LampClick3(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;
}
// einde old

procedure TjanSimLight.ButtonClick1(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanSimLight.ButtonClick3(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;

procedure TjanSimLight.ButtonNClick(Sender: TObject);
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

procedure TjanSimLight.ButtonClick4(sender:TObject); //selecteer
begin
 if Assigned(FBox) then
    FBox.SelectObject(Self);
end;

procedure TjanSimLight.SetLock(const Value: boolean);
begin
  if value<>FLock then
  begin
    FLock := Value;
 end;
end;

procedure TjanSimLight.SetInfo(const Value: String);
begin
  if value<>FInfo then
  begin
    FInfo := Value;
 end;
end;

procedure TjanSimLight.SetLit(const Value: boolean);
begin
 if value<>FLit then
  begin
    FLit := Value;
    invalidate;
  end;
end;

{TjanSimRelais}

procedure TjanSimRelais.SendStatusToBar;//xxxx
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

procedure TjanSimRelais.SetNaam(const Value: String);
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

 procedure TjanSimRelais.SetTaal(const Value: String);
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

 procedure TjanSimRelais.SetDown(const Value: boolean);
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

procedure TjanSimRelais.AnchorConnectors;
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

constructor TjanSimRelais.Create(AOwner: TComponent);
 var
  XX, YY: Integer;
  PixelColor: TColor;
begin
  inherited Create(AOwner);
  Select:=false;
  FLock:=false;
  FLit:=false;
  width:=80;
  height:=62;
  connectors:=TList.create;

  lUit:=TBitmap.Create;
  lUit.LoadFromResourceName(HInstance,'R_UIT');
   for YY := 0 to lUit.Height - 1 do
      for XX := 0 to lUit.Width - 1 do
      begin
        PixelColor := lUit.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          lUit.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  lUit.Transparent := True;
  lUit.TransParentColor := clFuchsia;// lUit.canvas.pixels[0,0];

  lAan:=TBitmap.Create;
  lAan.LoadFromResourceName(HInstance,'R_AAN');
  for YY := 0 to lAan.Height - 1 do
      for XX := 0 to lAan.Width - 1 do
      begin
        PixelColor := lAan.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          lUit.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  lAan.Transparent := True;
  lAan.TransParentColor := clFuchsia;// lAan.canvas.pixels[0,0];

  FDown:=false; //xxxx
  FNaam:='Relais'; //xxxx
  FSoort:='Uitvoer';  //xxxx
  FInfo:= 'Relais';  //xxxx
  ShowHint:=true;
end;

destructor TjanSimRelais.Destroy;
begin
  inherited;
  lUit.Free;
  lAan.Free;

  connectors.free;
end;

procedure TjanSimRelais.CMMouseLeave(var Msg: TMessage); //xxxx
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

procedure TjanSimRelais.CMMouseEnter(var Msg: TMessage);//xxxx
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

procedure TjanSimRelais.CMHitTest(var Message: TCMHitTest);
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

procedure TjanSimRelais.MouseDown(Button: TMouseButton; Shift: TShiftState;X, Y: Integer);//xxxx
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

procedure TjanSimRelais.MouseMove(Shift: TShiftState; X, Y: Integer);
var
p:TPoint;
Grid: TjanGridS;
SnapP: TPoint;
WorkR: TRect;
begin
   if FLock then exit;
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

procedure TjanSimRelais.MouseUp(Button: TMouseButton; Shift: TShiftState; X,Y: Integer);

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

 procedure TjanSimRelais.BuildPopup;
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

  procedure TjanSimRelais.UpdatePopupCaptions;
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

procedure TjanSimRelais.UpdateHintText;
begin
   Hint := BuildSimHint(FNaam, BTaal);
end;


procedure TjanSimRelais.MoveConnectors;
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

procedure TjanSimRelais.Paint;
var
R:TRect;
begin
lAan.Transparent:=true;
lUit.Transparent:=true;
with canvas do
 begin
   Lock;
   If FLit=false then
     PaintOutputSymbol(Self,Canvas,lUit,1,False)
     else PaintOutputSymbol(Self,Canvas,lAan,1,True);
     brush.style:=bsclear;
     Font.Name:='Arial';
     Font.Size:=9;
     Font.Style:= [];
     Font.Color:=clNavy;
     TextOut(1,35,'R');
     TextOut(48,-2,'R1');
     TextOut(48,50,'R2');
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

end;

procedure TjanSimRelais.Resize;
begin
  width:=80;
  height:=62;
end;



procedure TjanSimRelais.SetLock(const Value: boolean);
begin
  if value<>FLock then
  begin
    FLock := Value;
 end;
end;

procedure TjanSimRelais.SetInfo(const Value: String);
begin
  if value<>FInfo then
  begin
    FInfo := Value;
 end;
end;



procedure TjanSimRelais.ButtonClick1(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanSimRelais.ButtonClick3(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;

procedure TjanSimRelais.ButtonNClick(Sender: TObject);
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

procedure TjanSimRelais.ButtonClick4(sender:TObject); //selecteer
begin
 if Assigned(FBox) then
    FBox.SelectObject(Self);
end;



procedure TjanSimRelais.SetLit(const Value: boolean);
begin
  if value<>FLit then
  begin
    FLit := Value;
    invalidate;
  end;
end;

{ TjanSchakelRelais }

// Plaatsen (in het onderdeel, 90 x 80):
//   R1  ingang contact   blokje (1,8)    contactlijn op y = 12
//   R2  uitgang contact  blokje (80,8)
//   R+  ingang spoel     blokje (36,70), pijl omhoog naar ledje en spoel
//   R-  spoel naar de - rail, rechts op y = 38
const
  SR_W = 90; SR_H = 80;
  SR_CY = 12;                 // hoogte van de contactlijn
  SR_COIL: TRect = (Left: 33; Top: 28; Right: 48; Bottom: 49);
  SR_RMIN_Y = 38;             // hoogte van R- (railbolletje)

constructor TjanSchakelRelais.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := SR_W;
  Height := SR_H;
  FContactIn := False;
  FContactVolt := 0;
  Naam := 'Schakelrelais';
  Info := 'Schakelrelais';
end;

procedure TjanSchakelRelais.Resize;
begin
  Width := SR_W;
  Height := SR_H;
end;

procedure TjanSchakelRelais.SetContactIn(const Value: Boolean);
begin
  SetContact(Value, FContactVolt);
end;

procedure TjanSchakelRelais.SetContact(AOn: Boolean; AVolt: Double);
begin
  if not AOn then AVolt := 0;
  if (AOn <> FContactIn) or (AVolt <> FContactVolt) then
  begin
    FContactIn := AOn;
    FContactVolt := AVolt;
    Invalidate;
  end;
end;

function TjanSchakelRelais.EffIn(out AVolt: Double): Boolean;
var R: TjanRail;
begin
  AVolt := 0;
  Result := FContactIn;
  if Result then
  begin
    AVolt := FContactVolt;
    Exit;
  end;
  R := SchakelPlusRail(Self);
  if (R <> nil) and R.Powered then
  begin
    Result := True;
    AVolt := R.Volt;
  end;
end;

function TjanSchakelRelais.ContactOut: Boolean;
var V: Double;
begin
  Result := EffIn(V) and Lit;
end;

function TjanSchakelRelais.ContactVolt: Double;
var V: Double;
begin
  if EffIn(V) and Lit then Result := V else Result := 0;
end;

function TjanSchakelRelais.IsContactInput(const P: TPoint): Boolean;
begin
  // bovenste strook = contact (R1); de rest = spoel (R+)
  Result := (P.Y - Top) < 25;
end;

procedure TjanSchakelRelais.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  // draad maken vanaf de uitgang R2: ook vanaf het stukje draad en de pijl ervoor,
  // want op het blokje zelf ligt vaak al het begin van een bestaande draad
  if (Button = mbLeft) and (Screen.Cursor = crDraad) and
     PtInRect(Rect(57, 3, SR_W, 21), Point(X, Y)) and (Parent <> nil) then
  begin
    Maakdraad(Top + SR_CY - 3, Left + 81, Parent);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;
  inherited MouseDown(Button, Shift, X, Y);
end;

procedure TjanSchakelRelais.Paint;
var
  S: TjanSymbolen;
  V: Double;
  Closed, OutOn: Boolean;
  cx, xm, ym, i: Integer;
  ColIn, ColOut: TColor;
  R: TRect;

  procedure Pin(X, Y: Integer; Fill: TColor);
  begin
    Canvas.Pen.Color := clGray;
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := Fill;
    Canvas.Rectangle(X, Y, X + 9, Y + 9);
  end;

  procedure ArrowRight(X, Y: Integer; Col: TColor);
  begin
    Canvas.Pen.Color := Col;
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := Col;
    Canvas.Polygon([Point(X, Y - 3), Point(X + 5, Y), Point(X, Y + 3)]);
  end;

  procedure ArrowUp(X, Y: Integer; Col: TColor);
  begin
    Canvas.Pen.Color := Col;
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := Col;
    Canvas.Polygon([Point(X - 3, Y), Point(X, Y - 5), Point(X + 3, Y)]);
  end;

  procedure Lbl(X, Y: Integer; const T: string);
  begin
    Canvas.Brush.Style := bsClear;
    Canvas.Font.Name := 'Arial';
    Canvas.Font.Size := 7;
    Canvas.Font.Style := [];
    Canvas.Font.Color := clNavy;
    Canvas.TextOut(X, Y, T);
  end;

begin
  S := SymOf(Self);
  Closed := Lit;
  OutOn := ContactOut;
  if EffIn(V) then ColIn := clRed else ColIn := clBlack;
  if OutOn then ColOut := clRed else ColOut := clBlack;
  cx := (SR_COIL.Left + SR_COIL.Right) div 2;
  with Canvas do
  begin
    Lock;
    try
      Pen.Width := 1;
      Pen.Style := psSolid;

      // behuizing (alleen bij Afbeelding)
      if S = Afbeelding then
      begin
        Brush.Style := bsSolid;
        Brush.Color := RGBToColor(242, 243, 245);
        Pen.Color := RGBToColor(89, 96, 106);
        RoundRect(22, 1, 62, 54, 6, 6);
      end;

      // ---- contact bovenaan ----
      Pin(1, SR_CY - 4, clLime);                       // R1
      Pen.Color := ColIn;
      Line(10, SR_CY, 18, SR_CY);
      ArrowRight(18, SR_CY, ColIn);
      Pen.Color := ColIn;
      Line(23, SR_CY, 27, SR_CY);
      Pen.Color := clBlack;
      Line(54, SR_CY, 54, SR_CY - 5);                  // vast contact
      if Closed then
      begin
        Pen.Color := ColIn;
        Line(27, SR_CY, 55, SR_CY);
        Line(27, SR_CY - 1, 55, SR_CY - 1);
        ym := SR_CY;
      end
      else
      begin
        Pen.Color := ColIn;
        Line(27, SR_CY, 52, SR_CY - 9);
        ym := SR_CY - 5;
      end;
      Pen.Color := ColOut;
      Line(54, SR_CY, 72, SR_CY);
      ArrowRight(72, SR_CY, ColOut);
      if OutOn then Pin(80, SR_CY - 4, clRed) else Pin(80, SR_CY - 4, clLime);  // R2

      // ---- mechanische koppeling: stippellijn van het mes naar de spoel ----
      xm := cx;
      for i := ym + 2 to SR_COIL.Top - 1 do
        if ((i - ym) mod 3) <> 0 then Pixels[xm, i] := clBlack;

      // ---- spoel ----
      Pen.Color := clBlack;
      Brush.Style := bsSolid;
      if S = Afbeelding then
      begin
        // ijzeren kern met koperen wikkelingen
        Brush.Color := RGBToColor(154, 163, 173);
        Pen.Color := RGBToColor(110, 118, 128);
        Rectangle(SR_COIL.Left + 2, SR_COIL.Top, SR_COIL.Right - 2, SR_COIL.Bottom);
        Pen.Style := psClear;
        if Closed then Brush.Color := RGBToColor(224, 138, 46)
        else Brush.Color := RGBToColor(184, 115, 51);
        i := SR_COIL.Top + 2;
        while i + 2 <= SR_COIL.Bottom - 1 do
        begin
          Rectangle(SR_COIL.Left, i, SR_COIL.Right + 1, i + 3);
          Inc(i, 4);
        end;
        Pen.Style := psSolid;
        Pen.Color := clBlack;
      end
      else
      begin
        if Closed then Brush.Color := $80FF80 else Brush.Color := clWhite;
        Rectangle(SR_COIL);
      end;

      // R- : spoel naar de - rail (rechts)
      Pen.Color := clBlue;
      Line(SR_COIL.Right, SR_RMIN_Y, SR_W, SR_RMIN_Y);

      // ---- spoel naar ledje en R+ onderaan ----
      Pen.Color := clBlack;
      Line(cx, SR_COIL.Bottom, cx, 52);
      R := Rect(cx - 6, 52, cx + 7, 64);               // ledje
      Pen.Color := clGray;
      if Closed then Brush.Color := clRed else Brush.Color := clGreen;
      Ellipse(R);
      Pen.Color := clBlack;
      Line(cx, 64, cx, 70);
      ArrowUp(cx, 70, clBlack);
      Pin(cx - 4, 70, clLime);                         // R+

      Lbl(1, SR_CY + 6, 'R1');
      Lbl(76, SR_CY + 6, 'R2');
      Lbl(cx - 20, 70, 'R+');
      Lbl(70, SR_RMIN_Y + 2, 'R-');
    finally
      Unlock;
    end;
  end;

  // selectiekaders zoals bij het gewone relais
  if Select then
  begin
    R := ClientRect;
    Canvas.Pen.Color := clBlack;
    Canvas.Pen.Style := psDot;
    Canvas.Brush.Style := bsClear;
    Canvas.Rectangle(R);
    Canvas.Pen.Style := psSolid;
  end;
  if Selected then
  begin
    R := ClientRect;
    Canvas.Brush.Style := bsClear;
    Canvas.Pen.Color := clRed;
    Canvas.Pen.Style := psDot;
    Canvas.Rectangle(R);
    Canvas.Pen.Style := psSolid;
    Canvas.Brush.Style := bsSolid;
  end;
end;


{TjanSimBuzzer}

procedure TjanSimBuzzer.SendStatusToBar;
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

 procedure TjanSimBuzzer.SetNaam(const Value: String);
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

procedure TjanSimBuzzer.SetTaal(const Value: String);
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

procedure TjanSimBuzzer.SetDown(const Value: boolean);
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

procedure TjanSimBuzzer.UpdateHintText;
begin
   Hint := BuildSimHint(FNaam, BTaal);
end;

procedure TjanSimBuzzer.BuildPopup;
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

  procedure TjanSimBuzzer.UpdatePopupCaptions;
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

procedure TjanSimBuzzer.AnchorConnectors;
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

constructor TjanSimBuzzer.Create(AOwner: TComponent);
  var
  XX, YY: Integer;
  PixelColor: TColor;
begin
  inherited Create(AOwner);
  Select:=false;
  FLock:=false;
  FLit:=false;
  width:=80;
  height:=44;
  connectors:=TList.create;

  lAan:=TBitmap.Create;
  lAan.LoadFromResourceName(HInstance,'BA');
  for YY := 0 to lAan.Height - 1 do
      for XX := 0 to lAan.Width - 1 do
      begin
        PixelColor := lAan.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          lAan.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  lAan.Transparent := True;
  lAan.TransParentColor := clFuchsia;//lAan.canvas.pixels[0,0];
  lUit:=TBitmap.Create;
  lUit.LoadFromResourceName(HInstance,'BU');
  for YY := 0 to lUit.Height - 1 do
      for XX := 0 to lAan.Width - 1 do
      begin
        PixelColor := lUit.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          lUit.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  lUit.Transparent := True;
  lUit.TransParentColor := clFuchsia;//:= lUit.canvas.pixels[0,0];

  FDown:=false; //xxx
  FInfo:= 'Zoemer';//xxx
  FSoort:='Uitvoer';//xxx
  FNaam:='Zoemer';//xxx
  ShowHint:=true;
end;

destructor TjanSimBuzzer.Destroy;
begin
  inherited;
  lUit.Free;
  lAan.Free;
  connectors.free;
end;

procedure TjanSimBuzzer.CMMouseLeave(var Msg: TMessage);
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

procedure TjanSimBuzzer.CMMouseEnter(var Msg: TMessage);
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


procedure TjanSimBuzzer.CMHitTest(var Message: TCMHitTest);
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

procedure TjanSimBuzzer.MouseDown(Button: TMouseButton; Shift: TShiftState;
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

procedure TjanSimBuzzer.MouseMove(Shift: TShiftState; X, Y: Integer);
var
p:TPoint;
Grid: TjanGridS;
SnapP: TPoint;
WorkR: TRect;
begin
   if FLock then exit;
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


procedure TjanSimBuzzer.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
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

procedure TjanSimBuzzer.MoveConnectors;
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

procedure TjanSimBuzzer.Paint;
var
R:TRect;

begin
lAan.Transparent:=true;
lUit.Transparent:=true;
  With canvas do
  begin
   Lock;
   If FLit=false then
     PaintOutputSymbol(Self,Canvas,lUit,2,False)
     else PaintOutputSymbol(Self,Canvas,lAan,2,True);
     brush.style:=bsclear;
     Font.Name:='Arial';
     Font.Size:=9;
     Font.Style:= [];
     Font.Color:=clNavy;
     TextOut(1,25,'Z');
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
end;

procedure TjanSimBuzzer.Resize;
begin
  width:=80;
  height:=44;
end;


procedure TjanSimBuzzer.ButtonClick1(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanSimBuzzer.ButtonClick3(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;

procedure TjanSimBuzzer.ButtonNClick(Sender: TObject);
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

procedure TjanSimBuzzer.ButtonClick4(sender:TObject); //selecteer
begin
 if Assigned(FBox) then
    FBox.SelectObject(Self);
end;



procedure TjanSimBuzzer.SetLock(const Value: boolean);
begin
  if value<>FLock then
  begin
    FLock := Value;
 end;
end;

procedure TjanSimBuzzer.SetInfo(const Value: String);
begin
  if value<>FInfo then
  begin
    FInfo := Value;
 end;
end;

procedure TjanSimBuzzer.SetLit(const Value: boolean);
begin
  if value<>FLit then
  begin
    FLit := Value;
    invalidate;
  end;
end;
