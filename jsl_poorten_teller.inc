// janSimLogic.pas, deel: poorten en teller (ingevoegd met {$I jsl_poorten_teller.inc})


{ TjanLogic }

constructor TjanLogic.Create(AOwner: TComponent);
var i:integer;
begin
  inherited Create(AOwner);
  Select:=false;
  FStatPoort := stPoortStop;
  FType:='EN';
  width:=100;
  height:=LogicPoortH;
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
  FLogicAndFunc:=jlfAND;
  FGates[0].Active:=true;
  FGates[1].Active:=false;
  FGates[2].Active:=true;
  FGates[3].Active:=false;
  FGates[4].Active:=true;
  FGates[5].Active:=false;
  connectors:=TList.create;
  lIn:=TBitmap.create;
  lIn.LoadFromResourceName(HInstance,'LOG_IN');
  lIn.Transparent := True;
  lIn.TransParentColor := lIn.canvas.pixels[0,0];
  lUit:=TBitmap.Create;
  lUit.LoadFromResourceName(HInstance,'LOG_UIT');
  lUit.Transparent := True;
  lUit.TransParentColor := lUit.canvas.pixels[0,0];

  FTaal:='NL';
  FInfo:= 'Logische poort';
  FSoort:= 'Verwerking';
  FNaam:= 'Logische Poort';
  FDown:=False;
  ShowHint:=true;
  FLock:=false;
  FPcolor:=rgb(250,250,150);
end;

function TjanLogic.GetGate(Index: Integer): TjanGate;
begin
   result:=FGates[index];
end;

procedure TjanLogic.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  R, R2: TRect;
  p: TPoint;
  L, T: Integer;
  wc: TWinControl;
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

  doMove := False;
  doStyle := False;
  StyleDown := False;
  mdp := Point(X, Y);

  R := Rect(90,25,100,40);

  // maken van aansluitdraad
  if PtInRect(R, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + Width - 9;
    T := Top + 31;
    Maakdraad(T, L, wc);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;

  Screen.Cursor := crDefault;

  // einde van het maken van een aansluiting
  R2 := Rect(22,20,65,45);
  doStyle := PtInRect(R2, mdp);
  doMove := not doStyle;
  oldp := Point(X, Y);

  if doMove then
  begin
    AnchorConnectors;

    if (Button = mbLeft) and (Parent is TjanGridS) then
      TjanGridS(Parent).BeginGuideLines(Left + Width div 2, Top + Height div 2);
  end;

  if doStyle then
  begin
    StyleDown := True;
    Invalidate;
  end;

  UpdateHintText;
end;

procedure TjanLogic.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  p: TPoint;
  Grid: TjanGridS;
  SnapP: TPoint;
  WorkR: TRect;
begin
  inherited;

  if FLock = True then Exit;
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
      UpdateHintText;
    end;
  end;
end;

procedure TjanLogic.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;

  if Parent is TjanGridS then
    TjanGridS(Parent).EndGuideLines;

  FDepressed := False;
  Select := False;
  Invalidate;

  if FLock = True then Exit;

  StyleDown := False;
  FMouseOver := True;
  SendStatusToBar;
end;


procedure TjanLogic.AnchorConnectors;
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

procedure TjanLogic.CMMouseLeave(var Msg: TMessage);
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

procedure TjanLogic.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
  UpdateHintText;
  // ✅ statusbar meteen vullen
  FMouseOver := True;
  SendStatusToBar;  // vult panel 0/1/2

  BringToFront;
  if not FLock then
  begin
    Select := True;
    Invalidate;
  end;
  exit;
  //If FOutPut2=true then Hint:= FInfo  + #13#10  +'Status = 1'; //test
  //If FOutPut2=false then Hint:= FInfo + #13#10  +'Status = 0';

end;



procedure TjanLogic.BuildPopup;
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



procedure TjanLogic.UpdatePopupCaptions;
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


// Tekent een poort als IEC- of ANSI-symbool binnen R. Bij de NIET-poort komt
// het bolletje (omkering) rechts in R. InY1/InY2: hoogte van de ingangen; bij
// de ANSI OF-poort lopen die tot aan de holle achterkant (-1 = geen).
procedure DrawGateSymbol(C: TCanvas; R: TRect; F: TjanLogicFunc; S: TjanSymbolen;
  Fill: TColor; InY1, InY2: Integer);
const N = 16;
var Pts: array of TPoint;
    W, H, D, Mid, L, BR, Bk, i, k, n2: Integer;
    t: Double;
    Txt: string;
    OldBrush, OldPen: TColor;
    OldBrushStyle: TBrushStyle;
    OldFont: TFont;

  // x van de holle achterkant van de OF-poort op hoogte y
  function BackX(y: Integer): Integer;
  begin
    Result := L + Round(Bk * Sin(Pi * (R.Bottom - 1 - y) / (H - 1)));
  end;

  // EX-OF: de extra holle lijn helemaal achteraan
  function BackX2(y: Integer): Integer;
  begin
    Result := R.Left + Round(Bk * Sin(Pi * (R.Bottom - 1 - y) / (H - 1)));
  end;

begin
  W := R.Right - R.Left;
  H := R.Bottom - R.Top;
  if (W < 6) or (H < 6) then Exit;
  Mid := R.Top + H div 2;
  L := R.Left;
  D := 0;
  if F in [jlfNOT, jlfNAND, jlfNOR] then
  begin
    D := H div 6;
    if D < 4 then D := 4;
  end;
  BR := R.Right - D;            // rechterkant van het lichaam
  // ANSI EX-OF: het lichaam van de OF-poort schuift wat op, achteraan komt
  // een tweede holle lijn
  if (S <> IEC) and (F = jlfXOR) then
  begin
    k := (BR - R.Left) div 8;
    if k < 3 then k := 3;
    L := R.Left + k;
  end;
  Bk := (BR - L) div 5;
  if Bk < 2 then Bk := 2;

  OldBrush := C.Brush.Color;
  OldBrushStyle := C.Brush.Style;
  OldPen := C.Pen.Color;
  OldFont := TFont.Create;
  try
    OldFont.Assign(C.Font);
    C.Pen.Color := clBlack;
    C.Pen.Style := psSolid;
    C.Pen.Width := 1;
    C.Brush.Style := bsSolid;
    C.Brush.Color := Fill;

    if S = IEC then
    begin
      C.Rectangle(L, R.Top, BR, R.Bottom);
      case F of
        jlfAND, jlfNAND: Txt := '&';
        jlfOR, jlfNOR  : Txt := #$E2#$89#$A5'1';   // >=1 (UTF-8)
        jlfXOR         : Txt := '=1';
      else
        Txt := '1';
      end;
      C.Font.Name := 'Arial';
      C.Font.Style := [fsBold];
      C.Font.Color := clBlack;
      k := H * 2 div 7;
      if k < 8 then k := 8;
      if k > 16 then k := 16;
      C.Font.Height := -k;
      C.Brush.Style := bsClear;
      k := H div 12;
      if k < 1 then k := 1;
      C.TextOut((L + BR - C.TextWidth(Txt)) div 2, R.Top + k, Txt);
    end
    else
    begin
      case F of
        jlfAND, jlfNAND:
          begin
            // recht achteraan, halve ellips vooraan
            k := L + (BR - L) div 3;
            SetLength(Pts, N + 3);
            Pts[0] := Point(L, R.Top);
            for i := 0 to N do
            begin
              t := -Pi / 2 + Pi * i / N;
              Pts[i + 1] := Point(k + Round((BR - 1 - k) * Cos(t)),
                                  Mid + Round(((H - 1) / 2) * Sin(t)));
            end;
            Pts[N + 2] := Point(L, R.Bottom - 1);
          end;
        jlfOR, jlfNOR, jlfXOR:
          begin
            // gebogen zijkanten naar een punt, holle achterkant
            n2 := 2 * N + 1;
            SetLength(Pts, n2 + N - 1);
            for i := 0 to N do
            begin
              t := i / N;
              Pts[i] := Point(L + Round((BR - 1 - L) * t), R.Top + Round((Mid - R.Top) * t * t));
            end;
            for i := N - 1 downto 0 do
            begin
              t := i / N;
              Pts[N + (N - i)] := Point(L + Round((BR - 1 - L) * t),
                                        R.Bottom - 1 - Round((R.Bottom - 1 - Mid) * t * t));
            end;
            for i := 1 to N - 1 do
            begin
              k := R.Bottom - 1 - Round((H - 1) * i / N);
              Pts[n2 + i - 1] := Point(BackX(k), k);
            end;
          end;
      else
        begin
          // NIET: driehoek
          SetLength(Pts, 3);
          Pts[0] := Point(L, R.Top);
          Pts[1] := Point(BR - 1, Mid);
          Pts[2] := Point(L, R.Bottom - 1);
        end;
      end;
      C.Polygon(Pts);
      if F in [jlfOR, jlfNOR] then
      begin
        if InY1 >= 0 then C.Line(L, InY1, BackX(InY1) + 1, InY1);
        if InY2 >= 0 then C.Line(L, InY2, BackX(InY2) + 1, InY2);
      end
      else if F = jlfXOR then
      begin
        // tweede holle lijn achteraan; de ingangen lopen tot daar
        SetLength(Pts, N + 1);
        for i := 0 to N do
        begin
          k := R.Bottom - 1 - Round((H - 1) * i / N);
          Pts[i] := Point(BackX2(k), k);
        end;
        C.Polyline(Pts);
        if InY1 >= 0 then C.Line(R.Left, InY1, BackX2(InY1) + 1, InY1);
        if InY2 >= 0 then C.Line(R.Left, InY2, BackX2(InY2) + 1, InY2);
      end;
    end;

    if D > 0 then
    begin
      // bolletje = omkering
      C.Brush.Style := bsSolid;
      C.Brush.Color := clWhite;
      C.Ellipse(BR - 1, Mid - D div 2, BR + D, Mid - D div 2 + D + 1);
    end;
  finally
    C.Font.Assign(OldFont);
    OldFont.Free;
    C.Pen.Color := OldPen;
    C.Brush.Color := OldBrush;
    C.Brush.Style := OldBrushStyle;
  end;
end;

// ---------------------------------------------------------------------------
// Schemasymbolen voor invoer- en uitvoeronderdelen (KSymbolen = IEC of ANSI)
// ---------------------------------------------------------------------------

// gekozen tekenwijze voor een onderdeel dat door de Box gemaakt is
function SymOf(C: TComponent): TjanSymbolen;
begin
  Result := IEC;
  if (C <> nil) and (C.Owner is TjanSimLogicBox) then
    Result := TjanSimLogicBox(C.Owner).KSymbolen;
end;

// achtergrond van de knoppen in de balk bij schemasymbolen
const SymKnopKleur = $00F8F8F8;

// waar je op de drukknop klikt om hem te bedienen: het knopje van het plaatje,
// of bij schemasymbolen de beugel en het contact
function ButtonPushZone(C: TControl): TRect;
begin
  if SymOf(C) = Afbeelding then
    Result := Rect(1, 1, 16, 15)
  else
    Result := Rect(0, 9, 19, 31);
end;

// Alleen het deel R van een plaatje tekenen (draad, pijl en aansluitblokje
// blijven zo precies zoals in de afbeelding, met hun kleur aan/uit).
procedure DrawBitmapPart(C: TCanvas; Bm: TBitmap; const R: TRect);
var S: Integer;
begin
  S := SaveDC(C.Handle);
  try
    IntersectClipRect(C.Handle, R.Left, R.Top, R.Right, R.Bottom);
    C.Draw(0, 0, Bm);
  finally
    RestoreDC(C.Handle, S);
  end;
end;

// zelfde, met het plaatje op (X,Y); R in dezelfde coordinaten als het canvas
procedure DrawBitmapPartAt(C: TCanvas; Bm: TBitmap; X, Y: Integer; const R: TRect);
var S: Integer;
begin
  S := SaveDC(C.Handle);
  try
    IntersectClipRect(C.Handle, R.Left, R.Top, R.Right, R.Bottom);
    C.Draw(X, Y, Bm);
  finally
    RestoreDC(C.Handle, S);
  end;
end;

procedure SymPen(C: TCanvas; Col: TColor);
begin
  C.Pen.Color := Col;
  C.Pen.Style := psSolid;
  C.Pen.Width := 1;
end;

// pijlpunt aan het einde (X2,Y2) van de lijn van (X1,Y1)
procedure SymArrowHead(C: TCanvas; X1, Y1, X2, Y2, Size: Integer);
var a: Double;
begin
  if X2 = X1 then
  begin
    if Y2 > Y1 then a := Pi / 2 else a := -Pi / 2;
  end
  else
  begin
    a := ArcTan((Y2 - Y1) / (X2 - X1));
    if X2 < X1 then a := a + Pi;
  end;
  C.Line(X2, Y2, X2 - Round(Size * Cos(a - 0.5)), Y2 - Round(Size * Sin(a - 0.5)));
  C.Line(X2, Y2, X2 - Round(Size * Cos(a + 0.5)), Y2 - Round(Size * Sin(a + 0.5)));
end;

// Maakcontact verticaal op x = X, van YBot (ingang, vanaf InL links) naar YTop; vanaf YTop loopt
// de uitgang naar rechts tot R. Bediening links (tot ActL) met een stippellijn
// naar het mes: Push = drukknop (beugel), anders handbediening (hendel).
// Gesloten: mes recht en rood.
procedure DrawContactSymbol(C: TCanvas; X, YTop, YBot, ActL, R, InL: Integer; Closed, Push: Boolean);
var L, yb, yt, dx, xm, ym, h, i: Integer;
    Col: TColor;
begin
  L := YBot - YTop;
  yb := YBot - L div 4;                // scharnier van het mes
  yt := YTop + L div 5;                // vast contact
  if Closed then begin dx := 0; Col := clRed; end
  else begin dx := (yb - yt) div 2 + 1; Col := clBlack; end;
  SymPen(C, Col);
  if InL < X then C.Line(InL, YBot, X, YBot);   // ingang van links (rail)
  C.Line(X, YBot, X, yb);              // ingang
  C.Line(X, yt, X, YTop);              // naar de uitgang
  C.Line(X, YTop, R + 1, YTop);
  SymPen(C, clBlack);
  C.Line(X, yt, X - 3, yt);            // vast contact
  SymPen(C, Col);
  if Closed then
  begin
    C.Line(X, yb, X, yt);              // mes
    C.Line(X + 1, yb, X + 1, yt);
  end
  else
    C.Line(X, yb, X - dx, yt - 3);
  // bediening: stippellijn van het midden van het mes naar links
  xm := X - dx div 2 - 1;
  ym := (yb + yt) div 2 - 1;
  for i := ActL + 2 to xm do
    if ((xm - i) mod 3) <> 2 then C.Pixels[i, ym] := clBlack;
  SymPen(C, clBlack);
  h := L div 3;
  if h < 4 then h := 4;
  if ym - h < YTop then h := ym - YTop;
  C.Line(ActL, ym - h, ActL, ym + h + 1);
  C.Line(ActL + 1, ym - h, ActL + 1, ym + h + 1);
  if Push then
  begin
    // drukknop: beugel open naar het contact
    C.Line(ActL, ym - h, ActL + 5, ym - h);
    C.Line(ActL, ym + h, ActL + 5, ym + h);
  end;
end;

// weerstand (rechthoek) op de lijn Y tussen L en R; geeft de rechthoek terug
function DrawResistorBody(C: TCanvas; L, R, Y, HalfH: Integer; Fill: TColor): TRect;
begin
  Result := Rect(L + 3, Y - HalfH, R - 2, Y + HalfH + 1);
  SymPen(C, clBlack);
  C.Line(L, Y, Result.Left, Y);
  C.Line(Result.Right - 1, Y, R + 1, Y);
  C.Brush.Style := bsSolid;
  C.Brush.Color := Fill;
  C.Rectangle(Result);
end;

// LDR: weerstand met twee lichtpijlen; geel als er licht is
procedure DrawLDRSymbol(C: TCanvas; L, R, Y: Integer; Lit: Boolean);
var B: TRect;
    x, i: Integer;
begin
  if Lit then B := DrawResistorBody(C, L, R, Y, 3, clYellow)
  else B := DrawResistorBody(C, L, R, Y, 3, clWhite);
  if Lit then SymPen(C, $0080FF) else SymPen(C, clBlack);
  for i := 0 to 1 do
  begin
    x := B.Left + 1 + i * 6;
    C.Line(x - 5, Y - 11, x, Y - 5);
    SymArrowHead(C, x - 5, Y - 11, x, Y - 5, 3);
  end;
  SymPen(C, clBlack);
end;

// NTC (temperatuur): weerstand met schuine streep en voetje; rood als warm
procedure DrawNTCSymbol(C: TCanvas; L, R, Y: Integer; Warm: Boolean);
var B: TRect;
begin
  if Warm then B := DrawResistorBody(C, L, R, Y, 3, $8080FF)
  else B := DrawResistorBody(C, L, R, Y, 3, clWhite);
  SymPen(C, clBlack);
  C.Line(B.Left - 2, Y + 5, B.Right + 2, Y - 6);
  C.Line(B.Left - 5, Y + 5, B.Left - 1, Y + 5);
end;

// pulsgenerator: cirkel met blokgolf, lijn naar R
procedure DrawPulsSymbol(C: TCanvas; L, R, Y: Integer; On: Boolean);
var d, x0, x1, h: Integer;
begin
  d := R - L - 3;
  if d > 16 then d := 16;
  SymPen(C, clBlack);
  C.Brush.Style := bsSolid;
  if On then C.Brush.Color := clYellow else C.Brush.Color := clWhite;
  C.Ellipse(L, Y - d div 2, L + d + 1, Y - d div 2 + d + 1);
  C.Line(L + d, Y, R + 1, Y);
  if On then SymPen(C, clRed) else SymPen(C, clBlue);
  x0 := L + d div 4; x1 := L + d - d div 4; h := d div 5;
  C.MoveTo(x0, Y + h);
  C.LineTo((x0 + x1) div 2 - 1, Y + h);
  C.LineTo((x0 + x1) div 2 - 1, Y - h);
  C.LineTo(x1, Y - h);
  C.LineTo(x1, Y + h + 1);
  SymPen(C, clBlack);
end;

// --- Tekenwijze Afbeelding voor de invoer: half-realistische tekeningen links,
// draad, pijl en aansluitblokje rechts blijven uit het oude plaatje komen.

procedure HalfFill(C: TCanvas; Fill, Border: TColor);
begin
  C.Pen.Style := psSolid;
  C.Pen.Width := 1;
  C.Pen.Color := Border;
  C.Brush.Style := bsSolid;
  C.Brush.Color := Fill;
end;

procedure HalfGlans(C: TCanvas; L, T, Size: Integer);
begin
  HalfFill(C, clWhite, clWhite);
  C.Ellipse(L, T, L + Size, T + Size);
end;

// Drukknop op (X,Y): metalen ring met een ronde knop; groen los, rood
// ingedrukt (de knop zakt een beetje in en verliest zijn glans).
procedure DrawButtonAt(C: TCanvas; X, Y: Integer; Down: Boolean);
begin
  SymPen(C, clBlack);
  C.Line(X + 18, Y + 10, X + 22, Y + 10);
  HalfFill(C, RGBToColor(92, 99, 108), RGBToColor(47, 52, 58));
  C.Ellipse(X, Y + 1, X + 20, Y + 21);
  HalfFill(C, RGBToColor(140, 147, 156), RGBToColor(70, 76, 84));
  C.Ellipse(X + 2, Y + 3, X + 18, Y + 19);
  if Down then
  begin
    HalfFill(C, RGBToColor(230, 60, 47), RGBToColor(150, 30, 20));
    C.Ellipse(X + 5, Y + 6, X + 15, Y + 16);
  end
  else
  begin
    HalfFill(C, RGBToColor(60, 200, 90), RGBToColor(30, 120, 50));
    C.Ellipse(X + 4, Y + 5, X + 16, Y + 17);
    HalfGlans(C, X + 6, Y + 7, 3);
  end;
  SymPen(C, clBlack);
end;

procedure DrawButtonPicture(C: TCanvas; Down: Boolean);
begin
  DrawButtonAt(C, 0, 0, Down);
end;

// Kleine schuifschakelaar (dipschakelaar, A16 van het geheugen) in de
// rechthoek R: donker kastje, aan = bovenkant rood, uit = onderkant groen.
procedure DrawDipPicture(C: TCanvas; const R: TRect; On: Boolean);
var M: Integer;
begin
  HalfFill(C, RGBToColor(59, 64, 72), RGBToColor(34, 38, 43));
  C.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 4, 4);
  HalfFill(C, RGBToColor(201, 205, 210), RGBToColor(47, 52, 58));
  C.Rectangle(R.Left + 3, R.Top + 3, R.Right - 3, R.Bottom - 3);
  M := (R.Top + R.Bottom) div 2;
  if On then
  begin
    HalfFill(C, RGBToColor(229, 69, 58), RGBToColor(150, 30, 20));
    C.Rectangle(R.Left + 3, R.Top + 3, R.Right - 3, M + 1);
  end
  else
  begin
    HalfFill(C, RGBToColor(60, 200, 90), RGBToColor(30, 120, 50));
    C.Rectangle(R.Left + 3, M, R.Right - 3, R.Bottom - 3);
  end;
  SymPen(C, clBlack);
end;

// Schakelaar: tuimelschakelaar in een donker kastje. Aan: bovenkant rood
// ingedrukt (I), uit: onderkant groen ingedrukt (O).
procedure DrawSwitchPicture(C: TCanvas; On: Boolean);
begin
  SymPen(C, clBlack);
  C.Line(14, 24, 24, 24);
  HalfFill(C, RGBToColor(59, 64, 72), RGBToColor(34, 38, 43));
  C.RoundRect(0, 9, 15, 40, 5, 5);
  HalfFill(C, RGBToColor(201, 205, 210), RGBToColor(47, 52, 58));
  C.Rectangle(3, 12, 12, 37);
  if On then
  begin
    HalfFill(C, RGBToColor(229, 69, 58), RGBToColor(150, 30, 20));
    C.Rectangle(3, 12, 12, 25);
    SymPen(C, clWhite);
    C.Line(7, 15, 7, 22);
  end
  else
  begin
    HalfFill(C, RGBToColor(60, 200, 90), RGBToColor(30, 120, 50));
    C.Rectangle(3, 24, 12, 37);
    SymPen(C, clWhite);
    C.Brush.Style := bsClear;
    C.Ellipse(5, 28, 10, 34);
  end;
  SymPen(C, clBlack);
end;

// Lichtsensor (LDR): rond schijfje met een kronkelend spoor; in het licht
// wordt het schijfje lichtgeel en het spoor oranje.
procedure DrawLDRPicture(C: TCanvas; Lit: Boolean);
var i, y: Integer;
begin
  SymPen(C, clBlack);
  C.Line(19, 16, 22, 16);
  if Lit then HalfFill(C, RGBToColor(255, 240, 150), RGBToColor(150, 120, 40))
  else HalfFill(C, RGBToColor(232, 227, 214), RGBToColor(110, 100, 75));
  C.Ellipse(0, 5, 21, 26);
  if Lit then SymPen(C, RGBToColor(216, 106, 0))
  else SymPen(C, RGBToColor(150, 75, 40));
  for i := 0 to 4 do
  begin
    y := 9 + i * 3;
    C.Line(4, y, 17, y);
    if i < 4 then
      if Odd(i) then C.Line(4, y, 4, y + 3)
      else C.Line(16, y, 16, y + 3);
  end;
  SymPen(C, clBlack);
end;

// Warmtesensor (NTC): druppel met twee pootjes; koud blauwgrijs, warm
// oranjerood.
procedure DrawNTCPicture(C: TCanvas; Warm: Boolean);
begin
  SymPen(C, RGBToColor(90, 96, 104));
  C.Line(2, 17, 8, 17);
  C.Line(8, 17, 9, 13);
  C.Line(14, 13, 15, 17);
  SymPen(C, clBlack);
  C.Line(15, 17, 23, 17);
  if Warm then HalfFill(C, RGBToColor(224, 86, 43), RGBToColor(150, 40, 15))
  else HalfFill(C, RGBToColor(91, 127, 166), RGBToColor(45, 70, 100));
  C.Ellipse(3, 0, 21, 15);
  HalfGlans(C, 7, 3, 3);
  SymPen(C, clBlack);
end;

// Impulsgenerator: klein donker schermpje (X,Y, 17 breed) met een groene
// blokgolf als hij loopt, grijs als hij stilstaat.
procedure DrawPulsPicture(C: TCanvas; X, Y: Integer; On: Boolean);
begin
  HalfFill(C, RGBToColor(35, 40, 46), RGBToColor(20, 22, 26));
  C.RoundRect(X, Y, X + 18, Y + 18, 4, 4);
  if On then SymPen(C, RGBToColor(60, 230, 90))
  else SymPen(C, RGBToColor(120, 130, 140));
  C.Line(X + 2, Y + 13, X + 4, Y + 13);
  C.Line(X + 4, Y + 13, X + 4, Y + 4);
  C.Line(X + 4, Y + 4, X + 8, Y + 4);
  C.Line(X + 8, Y + 4, X + 8, Y + 13);
  C.Line(X + 8, Y + 13, X + 12, Y + 13);
  C.Line(X + 12, Y + 13, X + 12, Y + 4);
  C.Line(X + 12, Y + 4, X + 16, Y + 4);
  SymPen(C, clBlack);
end;

// Icoontje (24 x 24 op X,Y) in de knoppenbalk bij Afbeelding.
// Kind: 0 drukknop, 1 schakelaar, 2 lichtsensor, 3 warmtesensor, 4 puls.
procedure DrawInputPictureIcon(C: TCanvas; Kind, X, Y: Integer);
var i, yy: Integer;
begin
  case Kind of
    0: begin
         HalfFill(C, RGBToColor(92, 99, 108), RGBToColor(47, 52, 58));
         C.Ellipse(X + 2, Y + 2, X + 22, Y + 22);
         HalfFill(C, RGBToColor(140, 147, 156), RGBToColor(70, 76, 84));
         C.Ellipse(X + 4, Y + 4, X + 20, Y + 20);
         HalfFill(C, RGBToColor(60, 200, 90), RGBToColor(30, 120, 50));
         C.Ellipse(X + 6, Y + 6, X + 18, Y + 18);
         HalfGlans(C, X + 8, Y + 8, 3);
       end;
    1: begin
         HalfFill(C, RGBToColor(59, 64, 72), RGBToColor(34, 38, 43));
         C.RoundRect(X + 5, Y + 1, X + 19, Y + 23, 5, 5);
         HalfFill(C, RGBToColor(201, 205, 210), RGBToColor(47, 52, 58));
         C.Rectangle(X + 8, Y + 4, X + 16, Y + 20);
         HalfFill(C, RGBToColor(60, 200, 90), RGBToColor(30, 120, 50));
         C.Rectangle(X + 8, Y + 12, X + 16, Y + 20);
       end;
    2: begin
         HalfFill(C, RGBToColor(232, 227, 214), RGBToColor(110, 100, 75));
         C.Ellipse(X + 2, Y + 2, X + 22, Y + 22);
         SymPen(C, RGBToColor(150, 75, 40));
         for i := 0 to 4 do
         begin
           yy := Y + 6 + i * 3;
           C.Line(X + 6, yy, X + 18, yy);
           if i < 4 then
             if Odd(i) then C.Line(X + 6, yy, X + 6, yy + 3)
             else C.Line(X + 17, yy, X + 17, yy + 3);
         end;
       end;
    3: begin
         SymPen(C, RGBToColor(90, 96, 104));
         C.Line(X + 9, Y + 15, X + 8, Y + 23);
         C.Line(X + 15, Y + 15, X + 16, Y + 23);
         HalfFill(C, RGBToColor(91, 127, 166), RGBToColor(45, 70, 100));
         C.Ellipse(X + 3, Y + 1, X + 21, Y + 17);
         HalfGlans(C, X + 7, Y + 4, 3);
       end;
    4: DrawPulsPicture(C, X + 3, Y + 3, True);
  end;
  SymPen(C, clBlack);
end;

// Invoeronderdeel tekenen: het plaatje Bm bij Afbeelding, anders het
// schemasymbool links en van het plaatje alleen draad en aansluitblokje.
// Kind: 0 drukknop, 1 schakelaar, 2 lichtsensor, 3 warmtesensor, 4 puls.
procedure PaintInputSymbol(Ctl: TControl; C: TCanvas; Bm: TBitmap; Kind: Integer; On: Boolean);
var W, H: Integer;
    OldBrush: TColor;
    OldStyle: TBrushStyle;
begin
  W := Ctl.Width; H := Ctl.Height;
  if SymOf(Ctl) = Afbeelding then
  begin
    OldBrush := C.Brush.Color; OldStyle := C.Brush.Style;
    case Kind of
      0: begin
           DrawBitmapPart(C, Bm, Rect(21, 0, W, H));
           DrawButtonPicture(C, On);
         end;
      1: begin
           DrawBitmapPart(C, Bm, Rect(23, 0, W, H));
           DrawSwitchPicture(C, On);
         end;
      2: begin
           DrawBitmapPart(C, Bm, Rect(21, 0, W, H));
           DrawLDRPicture(C, On);
         end;
      3: begin
           DrawBitmapPart(C, Bm, Rect(22, 0, W, H));
           DrawNTCPicture(C, On);
         end;
      4: begin
           C.Draw(0, 0, Bm);
           DrawPulsPicture(C, 0, 13, On);
         end;
    else
      C.Draw(0, 0, Bm);
    end;
    C.Brush.Color := OldBrush; C.Brush.Style := OldStyle;
    Exit;
  end;
  OldBrush := C.Brush.Color; OldStyle := C.Brush.Style;
  case Kind of
    0: begin
         DrawBitmapPart(C, Bm, Rect(21, 0, W, H));
         DrawContactSymbol(C, 15, 10, 29, 2, 21, 0, On, True);
       end;
    1: begin
         DrawBitmapPart(C, Bm, Rect(23, 0, W, H));
         DrawContactSymbol(C, 17, 24, 47, 3, 23, 0, On, False);
       end;
    2: begin
         DrawBitmapPart(C, Bm, Rect(21, 0, W, H));
         DrawLDRSymbol(C, 1, 21, 16, On);
       end;
    3: begin
         DrawBitmapPart(C, Bm, Rect(22, 0, W, H));
         DrawNTCSymbol(C, 2, 22, 17, On);
       end;
    4: begin
         DrawBitmapPart(C, Bm, Rect(17, 0, W, H));
         DrawBitmapPart(C, Bm, Rect(0, 40, 17, H));
         DrawPulsSymbol(C, 0, 17, 24, On);
       end;
  end;
  C.Brush.Color := OldBrush; C.Brush.Style := OldStyle;
end;

// Lamp op de lijn Y van L tot R, cirkel met diameter D: IEC een kruis erin,
// ANSI een gloeidraad (lusje). Geel als hij brandt.
procedure DrawLampSymbol(C: TCanvas; L, R, Y, D: Integer; Lit: Boolean; S: TjanSymbolen);
var cx, x0, x1, y0, y1, k: Integer;
begin
  x0 := L + 3; x1 := x0 + D; y0 := Y - D div 2; y1 := y0 + D;
  cx := (x0 + x1) div 2;
  SymPen(C, clBlack);
  C.Line(L, Y, x0, Y);
  C.Line(x1, Y, R + 1, Y);
  C.Brush.Style := bsSolid;
  if Lit then C.Brush.Color := clYellow else C.Brush.Color := clWhite;
  C.Ellipse(x0, y0, x1 + 1, y1 + 1);
  if Lit then SymPen(C, clRed);
  if S = ANSI then
  begin
    // gloeidraad: van links en rechts naar een lusje in het midden
    k := D div 4;
    C.Line(x0, Y, cx - k, Y);
    C.Line(cx + k, Y, x1, Y);
    C.Brush.Style := bsClear;
    C.Ellipse(cx - k, Y - 2 * k, cx + k + 1, Y + 1);
  end
  else
  begin
    // kruis onder 45 graden
    k := Round(D * 0.35);
    C.Line(cx - k, Y - k, cx + k + 1, Y + k + 1);
    C.Line(cx - k, Y + k, cx + k + 1, Y - k - 1);
  end;
  SymPen(C, clBlack);
end;

// Zoemer: koepel (straal Rad) op een platte voet, met twee pootjes eronder.
// De ingang komt op hoogte Y van links en gaat naar het linkerpootje; het
// rechterpootje loopt naar R (op de hoogte BuzzerLegY). Als hij zoemt: geel
// met geluidsboogjes.
function BuzzerLegY(Y, Rad: Integer): Integer;
begin
  Result := Y + Rad div 2 + 5;
end;

procedure DrawBuzzerSymbol(C: TCanvas; L, R, Y, Rad: Integer; On: Boolean);
var cx, yb, yl, xl, xr, i, a: Integer;
begin
  cx := L + 5 + Rad;
  yb := Y + Rad div 2;               // voet
  yl := BuzzerLegY(Y, Rad);          // onderkant van de pootjes
  xl := cx - Rad div 2;
  xr := cx + Rad div 2;
  SymPen(C, clBlack);
  // ingang: van links naar beneden en onder het linkerpootje
  C.Line(L, Y, L + 2, Y);
  C.Line(L + 2, Y, L + 2, yl);
  C.Line(L + 2, yl, xl, yl);
  C.Line(xl, yl, xl, yb);
  // uitgang: rechterpootje naar rechts
  C.Line(xr, yb, xr, yl);
  C.Line(xr, yl, R + 1, yl);
  // koepel
  C.Brush.Style := bsSolid;
  if On then C.Brush.Color := clYellow else C.Brush.Color := clWhite;
  C.Pie(cx - Rad, yb - Rad, cx + Rad + 1, yb + Rad + 1, cx + Rad, yb, cx - Rad, yb);
  C.Line(cx - Rad, yb, cx + Rad + 1, yb);
  if On and (cx + Rad + 10 < R) then
  begin
    SymPen(C, clRed);
    C.Brush.Style := bsClear;
    for i := 1 to 2 do
    begin
      a := Rad + 2 + 4 * i;
      C.Arc(cx - a, yb - a, cx + a + 1, yb + a + 1,
            cx + a, yb - a div 4, cx + a div 2, yb - a);
    end;
    SymPen(C, clBlack);
  end;
end;

// Relais: spoel (rechthoek CoilL..CoilR rond Y), stippellijn naar een
// verticaal maakcontact op x = CX tussen YTop en YBot. Aan: spoel groen,
// contact gesloten en rood.
procedure DrawRelaySymbol(C: TCanvas; CoilL, CoilR, Y, CoilH, CX, YTop, YBot: Integer; On: Boolean);
var yt, yb, dx, xm, i: Integer;
    Col: TColor;
begin
  SymPen(C, clBlack);
  C.Brush.Style := bsSolid;
  if On then C.Brush.Color := $80FF80 else C.Brush.Color := clWhite;
  C.Rectangle(CoilL, Y - CoilH div 2, CoilR + 1, Y - CoilH div 2 + CoilH + 1);
  yt := YTop + (YBot - YTop) div 5;
  yb := YBot - (YBot - YTop) div 4;
  if On then begin dx := 0; Col := clRed; end
  else begin dx := (yb - yt) div 2 + 1; Col := clBlack; end;
  SymPen(C, Col);
  C.Line(CX, YTop, CX, yt + 1);
  C.Line(CX, yb, CX, YBot + 1);
  SymPen(C, clBlack);
  C.Line(CX, yt, CX - 3, yt);           // vast contact
  SymPen(C, Col);
  if On then
  begin
    C.Line(CX, yb, CX, yt);
    C.Line(CX + 1, yb, CX + 1, yt);
  end
  else
    C.Line(CX, yb, CX - dx, yt - 3);
  // mechanische koppeling: stippellijn van de spoel naar het mes
  xm := CX - dx * (yb - Y) div (yb - yt + 3) - 1;
  if xm > CX - 1 then xm := CX - 1;
  for i := CoilR + 2 to xm do
    if ((i - CoilR) mod 3) <> 0 then C.Pixels[i, Y] := clBlack;
  SymPen(C, clBlack);
end;

// --- Tekenwijze Afbeelding: half-realistische tekeningen (effen kleuren met
// een rand en een klein glansje). Het aansluitblokje en de pijl links blijven
// uit het oude plaatje komen, zodat de aansluitingen niet verschuiven.

// Gloeilamp liggend op de draad Y (vanaf X = L): metalen fitting met
// schroefdraad en een glazen bol met gloeidraad; geel als hij brandt.
var
  // helderheid van een brandende lamp bij Afbeelding (1 = vol, kleiner =
  // gedimd: de kleuren schuiven naar die van een lamp die uit is)
  LampPictureDim: Double = 1;

function DimKleur(R1, G1, B1, R0, G0, B0: Integer): TColor;
var F: Double;
begin
  F := LampPictureDim;
  if F > 1 then F := 1;
  if F < 0 then F := 0;
  Result := RGBToColor(Round(R0 + (R1 - R0) * F), Round(G0 + (G1 - G0) * F),
    Round(B0 + (B1 - B0) * F));
end;

procedure DrawLampPicture(C: TCanvas; L, Y: Integer; Lit: Boolean);
var i, x0, bx0, bx1, by0, by1, cx: Integer;
begin
  SymPen(C, clBlack);
  C.Line(L - 2, Y, L + 2, Y);
  // fitting: ringen van de schroefdraad
  x0 := L + 2;
  C.Pen.Style := psClear;
  C.Brush.Style := bsSolid;
  for i := 0 to 3 do
  begin
    if Odd(i) then C.Brush.Color := RGBToColor(150, 158, 168)
    else C.Brush.Color := RGBToColor(198, 204, 212);
    C.Rectangle(x0 + i * 2, Y - 5, x0 + i * 2 + 3, Y + 7);
  end;
  C.Brush.Color := RGBToColor(118, 126, 136);
  C.Rectangle(x0 + 8, Y - 4, x0 + 11, Y + 6);
  C.Pen.Style := psSolid;
  // glazen bol
  bx0 := x0 + 9; bx1 := bx0 + 21; by0 := Y - 6; by1 := Y + 9;
  cx := (bx0 + bx1) div 2;
  C.Brush.Style := bsSolid;
  if Lit then
  begin
    C.Brush.Color := DimKleur(255, 225, 77, 244, 247, 250);
    C.Pen.Color := DimKleur(200, 140, 0, 130, 140, 150);
  end
  else
  begin
    C.Brush.Color := RGBToColor(244, 247, 250);
    C.Pen.Color := RGBToColor(130, 140, 150);
  end;
  C.Ellipse(bx0, by0, bx1, by1);
  // gloeidraad: twee steuntjes en een zigzag
  if Lit then C.Pen.Color := DimKleur(200, 80, 0, 110, 118, 128)
  else C.Pen.Color := RGBToColor(110, 118, 128);
  C.Line(bx0 + 1, Y + 1, cx - 4, Y + 1);
  C.Line(cx - 4, Y + 1, cx - 3, Y - 2);
  C.Line(cx - 3, Y - 2, cx - 1, Y + 4);
  C.Line(cx - 1, Y + 4, cx + 1, Y - 2);
  C.Line(cx + 1, Y - 2, cx + 3, Y + 4);
  C.Line(cx + 3, Y + 4, cx + 4, Y + 1);
  // glansje
  C.Pen.Color := clWhite;
  C.Brush.Color := clWhite;
  C.Ellipse(cx + 3, by0 + 2, cx + 6, by0 + 5);
  SymPen(C, clBlack);
end;

// Zoemer: rond zwart huis met middelpunt (CX,CY) en straal Rad, aangesloten
// met de draad Y vanaf X = L. Als hij zoemt: gele rand en geluidsgolfjes.
procedure DrawBuzzerPicture(C: TCanvas; L, Y, CX, CY, Rad: Integer; On: Boolean);
var i, a: Integer;
begin
  SymPen(C, clBlack);
  C.Line(L, Y, CX - Rad + 1, Y);
  C.Brush.Style := bsSolid;
  C.Brush.Color := RGBToColor(43, 47, 54);
  if On then
  begin
    C.Pen.Color := RGBToColor(240, 180, 0);
    C.Pen.Width := 2;
  end
  else
    C.Pen.Color := RGBToColor(21, 24, 28);
  C.Ellipse(CX - Rad, CY - Rad, CX + Rad + 1, CY + Rad + 1);
  C.Pen.Width := 1;
  // binnenring en gaatje
  C.Pen.Color := RGBToColor(80, 88, 99);
  C.Brush.Color := RGBToColor(58, 64, 73);
  a := Rad * 2 div 3;
  C.Ellipse(CX - a, CY - a, CX + a + 1, CY + a + 1);
  if On then C.Brush.Color := RGBToColor(255, 212, 0)
  else C.Brush.Color := RGBToColor(15, 15, 15);
  C.Pen.Color := C.Brush.Color;
  C.Ellipse(CX - 3, CY - 3, CX + 4, CY + 4);
  // glansje bovenaan links
  C.Pen.Color := RGBToColor(120, 128, 138);
  C.Brush.Style := bsClear;
  C.Arc(CX - Rad + 3, CY - Rad + 3, CX + Rad - 2, CY + Rad - 2,
        CX - Rad, CY, CX, CY - Rad);
  if On then
  begin
    // geluidsgolfjes in het huis, rond het gaatje
    C.Pen.Color := RGBToColor(255, 212, 0);
    for i := 1 to 2 do
    begin
      a := 3 + 4 * i;
      C.Arc(CX - a, CY - a, CX + a + 1, CY + a + 1, CX + a, CY + a div 2, CX + a, CY - a div 2);
      C.Arc(CX - a, CY - a, CX + a + 1, CY + a + 1, CX - a, CY - a div 2, CX - a, CY + a div 2);
    end;
  end;
  SymPen(C, clBlack);
end;

// Relais: grijs kastje met een koperen spoel op een ijzeren kern en rechts
// het contact op x = CX tussen YTop en YBot (de aansluitingen R1 en R2).
// Aan: de spoel trekt, het contact is dicht en rood.
procedure DrawRelayPicture(C: TCanvas; L, Y, CX, YTop, YBot: Integer; On: Boolean);
var i, yt, yb, xm: Integer;
    Col: TColor;
begin
  SymPen(C, clBlack);
  C.Line(L - 2, Y, L + 2, Y);
  // kastje
  C.Brush.Style := bsSolid;
  C.Brush.Color := RGBToColor(242, 243, 245);
  C.Pen.Color := RGBToColor(89, 96, 106);
  C.RoundRect(L + 1, YTop + 13, CX + 10, YBot - 12, 6, 6);
  // kern en wikkelingen
  C.Brush.Color := RGBToColor(154, 163, 173);
  C.Pen.Color := RGBToColor(110, 118, 128);
  C.Rectangle(L + 3, Y - 4, L + 22, Y + 5);
  C.Pen.Style := psClear;
  for i := 0 to 4 do
  begin
    if On then C.Brush.Color := RGBToColor(224, 138, 46)
    else C.Brush.Color := RGBToColor(184, 115, 51);
    C.Rectangle(L + 5 + i * 3, Y - 8, L + 7 + i * 3, Y + 9);
  end;
  C.Pen.Style := psSolid;
  // contact
  yt := YTop + (YBot - YTop) div 3;
  yb := YBot - (YBot - YTop) div 3;
  if On then Col := clRed else Col := RGBToColor(60, 64, 70);
  SymPen(C, RGBToColor(60, 64, 70));
  C.Line(CX, YTop, CX, yt + 1);
  C.Line(CX - 2, yt, CX + 3, yt);
  SymPen(C, Col);
  C.Line(CX, yb, CX, YBot + 1);
  if On then
  begin
    C.Line(CX, yb, CX, yt);
    C.Line(CX + 1, yb, CX + 1, yt);
    xm := CX - 1;
  end
  else
  begin
    C.Line(CX, yb, CX - 5, yt + 1);
    xm := CX - 4;
  end;
  // koppeling van de spoel naar het contact
  for i := L + 23 to xm do
    if ((i - L) mod 3) <> 0 then C.Pixels[i, Y] := RGBToColor(89, 96, 106);
  SymPen(C, clBlack);
end;

// Knop van de voltmeter (S = 'V') of milliampèremeter (S = 'mA') bij
// Afbeelding: een licht lcd-schermpje met donkergroene letters.
procedure DrawMeterIcon(C: TCanvas; Bm: TBitmap; X, Y: Integer; const S: string);
begin
  // het oude zwarte plaatje niet meer; de balk eronder blijft zichtbaar
  HalfFill(C, RGBToColor(214, 230, 206), RGBToColor(89, 96, 106));
  C.RoundRect(X + 1, Y + 2, X + Bm.Width - 1, Y + Bm.Height - 2, 5, 5);
  C.Brush.Style := bsClear;
  C.Font.Name := 'Arial';
  if Length(S) > 1 then C.Font.Size := 8 else C.Font.Size := 10;
  C.Font.Style := [fsBold];
  C.Font.Color := RGBToColor(25, 90, 40);
  C.TextOut(X + Bm.Width div 2 - C.TextWidth(S) div 2,
            Y + Bm.Height div 2 - C.TextHeight(S) div 2, S);
  SymPen(C, clBlack);
end;

// Icoontje (24 x 24 op X,Y) in de knoppenbalk bij Afbeelding, in dezelfde
// stijl als de tekeningen hierboven. Kind: 0 lamp, 1 relais, 2 zoemer.
procedure DrawPictureIcon(C: TCanvas; Kind, X, Y: Integer);
var i: Integer;
begin
  C.Pen.Width := 1;
  C.Pen.Style := psSolid;
  C.Brush.Style := bsSolid;
  case Kind of
    0: begin
         // rechtopstaande gloeilamp: bol boven, fitting onder
         C.Brush.Color := RGBToColor(244, 247, 250);
         C.Pen.Color := RGBToColor(110, 118, 128);
         C.Ellipse(X + 5, Y + 2, X + 19, Y + 16);
         C.Pen.Color := RGBToColor(110, 118, 128);
         C.Line(X + 9, Y + 15, X + 9, Y + 10);
         C.Line(X + 15, Y + 15, X + 15, Y + 10);
         C.Line(X + 9, Y + 10, X + 10, Y + 7);
         C.Line(X + 10, Y + 7, X + 11, Y + 10);
         C.Line(X + 11, Y + 10, X + 12, Y + 7);
         C.Line(X + 12, Y + 7, X + 13, Y + 10);
         C.Line(X + 13, Y + 10, X + 14, Y + 7);
         C.Line(X + 14, Y + 7, X + 15, Y + 10);
         C.Pen.Style := psClear;
         for i := 0 to 2 do
         begin
           if Odd(i) then C.Brush.Color := RGBToColor(150, 158, 168)
           else C.Brush.Color := RGBToColor(198, 204, 212);
           C.Rectangle(X + 8, Y + 15 + i * 2, X + 17, Y + 18 + i * 2);
         end;
         C.Brush.Color := RGBToColor(80, 86, 94);
         C.Rectangle(X + 10, Y + 21, X + 15, Y + 24);
         C.Pen.Style := psSolid;
         C.Pen.Color := clWhite;
         C.Brush.Color := clWhite;
         C.Ellipse(X + 8, Y + 5, X + 11, Y + 8);
       end;
    1: begin
         // relais: kastje met koperen spoel en een contact erboven
         C.Brush.Color := RGBToColor(242, 243, 245);
         C.Pen.Color := RGBToColor(89, 96, 106);
         C.RoundRect(X + 2, Y + 8, X + 22, Y + 22, 4, 4);
         C.Brush.Color := RGBToColor(154, 163, 173);
         C.Pen.Color := RGBToColor(110, 118, 128);
         C.Rectangle(X + 4, Y + 13, X + 16, Y + 18);
         C.Pen.Style := psClear;
         C.Brush.Color := RGBToColor(184, 115, 51);
         for i := 0 to 3 do
           C.Rectangle(X + 5 + i * 3, Y + 11, X + 7 + i * 3, Y + 21);
         C.Pen.Style := psSolid;
         SymPen(C, RGBToColor(60, 64, 70));
         C.Line(X + 1, Y + 4, X + 7, Y + 4);
         C.Line(X + 7, Y + 4, X + 16, Y + 1);
         C.Line(X + 17, Y + 4, X + 23, Y + 4);
         C.Line(X + 17, Y + 4, X + 17, Y + 2);
         C.Pixels[X + 12, Y + 5] := RGBToColor(89, 96, 106);
         C.Pixels[X + 12, Y + 7] := RGBToColor(89, 96, 106);
       end;
    2: begin
         // zoemer: rond zwart huis met binnenring en gaatje
         C.Brush.Color := RGBToColor(43, 47, 54);
         C.Pen.Color := RGBToColor(21, 24, 28);
         C.Ellipse(X + 2, Y + 2, X + 22, Y + 22);
         C.Pen.Color := RGBToColor(80, 88, 99);
         C.Brush.Color := RGBToColor(58, 64, 73);
         C.Ellipse(X + 6, Y + 6, X + 18, Y + 18);
         C.Brush.Color := RGBToColor(15, 15, 15);
         C.Pen.Color := C.Brush.Color;
         C.Ellipse(X + 10, Y + 10, X + 14, Y + 14);
         C.Pen.Color := RGBToColor(120, 128, 138);
         C.Brush.Style := bsClear;
         C.Arc(X + 4, Y + 4, X + 20, Y + 20, X + 2, Y + 12, X + 12, Y + 2);
       end;
  end;
  SymPen(C, clBlack);
end;

// Uitvoeronderdeel tekenen: links uit het plaatje alleen aansluitblokje, pijl
// (en ledje), rechts de tekening (Afbeelding) of het schemasymbool.
// Kind: 0 lamp, 1 relais, 2 zoemer.
procedure PaintOutputSymbol(Ctl: TControl; C: TCanvas; Bm: TBitmap; Kind: Integer; On: Boolean);
var W, H: Integer;
    OldBrush: TColor;
    OldStyle: TBrushStyle;
    S: TjanSymbolen;
begin
  S := SymOf(Ctl);
  W := Ctl.Width; H := Ctl.Height;
  if S = Afbeelding then
  begin
    OldBrush := C.Brush.Color; OldStyle := C.Brush.Style;
    case Kind of
      0: begin
           DrawBitmapPart(C, Bm, Rect(0, 0, 37, H));
           DrawLampPicture(C, 37, 6, On);
         end;
      1: begin
           DrawBitmapPart(C, Bm, Rect(0, 0, 36, H));
           DrawBitmapPart(C, Bm, Rect(62, 0, W, 9));      // R1
           DrawBitmapPart(C, Bm, Rect(62, 53, W, H));     // R2
           DrawRelayPicture(C, 36, 31, 69, 8, 53, On);
         end;
      2: begin
           DrawBitmapPart(C, Bm, Rect(0, 0, 35, H));
           DrawBuzzerPicture(C, 35, 21, 58, 22, 20, On);
         end;
    else
      C.Draw(0, 0, Bm);
    end;
    C.Brush.Color := OldBrush; C.Brush.Style := OldStyle;
    Exit;
  end;
  OldBrush := C.Brush.Color; OldStyle := C.Brush.Style;
  case Kind of
    0: begin
         DrawBitmapPart(C, Bm, Rect(0, 0, 37, H));
         DrawLampSymbol(C, 37, W - 1, 6, 12, On, S);
       end;
    1: begin
         DrawBitmapPart(C, Bm, Rect(0, 0, 36, H));
         DrawBitmapPart(C, Bm, Rect(62, 0, W, 15));     // R1
         DrawBitmapPart(C, Bm, Rect(62, 47, W, H));     // R2
         SymPen(C, clBlack);
         C.Line(34, 31, 39, 31);
         DrawRelaySymbol(C, 39, 52, 31, 18, 71, 15, 46, On);
       end;
    2: begin
         DrawBitmapPart(C, Bm, Rect(0, 0, 35, H));
         DrawBuzzerSymbol(C, 35, W - 1, 21, 13, On);
       end;
  end;
  C.Brush.Color := OldBrush; C.Brush.Style := OldStyle;
end;

// impulsgenerator: halve periode in ms (zo lang is de puls hoog en ook laag)
const
  PulsIntervalStandaard = 300;
  PulsIntervallen: array[0..4] of Integer = (1000, 500, 300, 200, 100);

function PulsFrequentieText(AInterval: Integer): string;
begin
  if AInterval <= 0 then AInterval := PulsIntervalStandaard;
  Result := FormatFloat('0.#', 1000 / (2 * AInterval)) + ' Hz';
end;

// halve periode van een impulsgenerator uit de rest van de regel
// (S = 'breedte;interval;', zonder interval de standaard)
function PulsIntervalUitRest(const S: string): Integer;
var p: Integer;
    Rest: string;
begin
  Result := PulsIntervalStandaard;
  p := Pos(';', S);
  if p = 0 then Exit;
  Rest := Copy(S, p + 1, MaxInt);
  p := Pos(';', Rest);
  if p > 0 then Rest := Copy(Rest, 1, p - 1);
  Result := StrToIntDef(Trim(Rest), PulsIntervalStandaard);
  if (Result < 20) or (Result > 10000) then Result := PulsIntervalStandaard;
end;

// kleur van een lamp uit de rest van de regel in het paneelbestand
// (S = 'breedte;kleur;', zonder kleur een gewone lamp)
function LampKleurUitRest(const S: string): TLampKleur;
var p, v: Integer;
    Rest: string;
begin
  Result := lkLamp;
  p := Pos(';', S);
  if p = 0 then Exit;
  Rest := Copy(S, p + 1, MaxInt);
  p := Pos(';', Rest);
  if p > 0 then Rest := Copy(Rest, 1, p - 1);
  v := StrToIntDef(Trim(Rest), 0);
  if (v >= Ord(Low(TLampKleur))) and (v <= Ord(High(TLampKleur))) then
    Result := TLampKleur(v);
end;

// Kleur van een led (lkRood/lkGroen/lkOranje): fel als hij brandt, een lichte
// tint van dezelfde kleur als hij uit is (zo zie je welke kleur hij heeft)
function LedColor(K: TLampKleur; On: Boolean): TColor;
begin
  case K of
    lkRood:   if On then Result := RGBToColor(255, 30, 30) else Result := RGBToColor(205, 140, 140);
    lkGroen:  if On then Result := RGBToColor(40, 220, 40) else Result := RGBToColor(140, 195, 140);
    lkOranje: if On then Result := RGBToColor(255, 150, 0) else Result := RGBToColor(230, 190, 130);
  else
    if On then Result := clYellow else Result := clWhite;
  end;
end;

// Led op de plaats van het lampsymbool (rechts van X = L, tot R). Bij
// Afbeelding een gekleurd bolletje met een glans als hij brandt; bij
// schemasymbolen een diode (driehoek en streep) op de lijn Y met twee
// pijltjes voor het licht.
procedure DrawLedSymbol(C: TCanvas; L, R, Y: Integer; K: TLampKleur; On: Boolean; S: TjanSymbolen);
var x0, x1, cx, cy, i: Integer;
    Col: TColor;
begin
  Col := LedColor(K, On);
  if S = Afbeelding then
  begin
    cx := L + 15; cy := 11;
    SymPen(C, clGray);
    C.Line(L, Y, cx - 6, cy - 3);
    C.Line(cx + 8, cy, R + 1, cy);
    if On then
    begin
      // gloed rond de led
      C.Brush.Style := bsClear;
      C.Pen.Color := LedColor(K, True);
      C.Ellipse(cx - 10, cy - 10, cx + 11, cy + 11);
    end;
    C.Brush.Style := bsSolid;
    C.Brush.Color := Col;
    C.Pen.Color := clBlack;
    C.Ellipse(cx - 8, cy - 8, cx + 9, cy + 9);
    if On then
    begin
      C.Brush.Color := clWhite;
      C.Pen.Color := clWhite;
      C.Ellipse(cx - 5, cy - 5, cx - 1, cy - 1);
    end;
    SymPen(C, clBlack);
    Exit;
  end;
  x0 := L + 4; x1 := x0 + 10;
  SymPen(C, clBlack);
  C.Line(L, Y, x0, Y);
  C.Line(x1, Y, R + 1, Y);
  C.Brush.Style := bsSolid;
  C.Brush.Color := Col;
  C.Polygon([Point(x0, Y - 5), Point(x0, Y + 5), Point(x1, Y)]);
  C.Line(x1, Y - 5, x1, Y + 6);
  // twee pijltjes naar rechtsonder: het licht
  if On then SymPen(C, Col) else SymPen(C, clBlack);
  for i := 0 to 1 do
  begin
    cx := x0 + 2 + i * 5;
    C.Line(cx, Y + 7, cx + 5, Y + 12);
    C.Line(cx + 5, Y + 12, cx + 2, Y + 12);
    C.Line(cx + 5, Y + 12, cx + 5, Y + 9);
  end;
  SymPen(C, clBlack);
end;

// Motor: cirkel met middelpunt (CX,CY) en straal Rad. Bij Afbeelding een
// metalen schijf met een rotor van drie spaken op hoek Angle (graden); bij
// schemasymbolen een cirkel met M en een rondlopend puntje. Dir: -1 linksom,
// 1 rechtsom, 0 stil; als hij draait een gebogen pijl bovenaan in de
// draairichting. Fault: rode rand (L en R samen aan).
procedure DrawMotorSymbol(C: TCanvas; CX, CY, Rad, Angle, Dir: Integer; Fault: Boolean; S: TjanSymbolen);

  function P(R: Integer; ADeg: Double): TPoint;
  begin
    Result := Point(CX + Round(R * Cos(ADeg * Pi / 180)), CY - Round(R * Sin(ADeg * Pi / 180)));
  end;

var
  k, R2: Integer;
  A, Ux, Uy: Double;
  Tip, Q: TPoint;
begin
  C.Pen.Width := 1;
  C.Pen.Style := psSolid;
  C.Brush.Style := bsSolid;
  if S = Afbeelding then
    C.Brush.Color := RGBToColor(205, 210, 220)
  else
    C.Brush.Color := clWhite;
  if Fault then
  begin
    C.Pen.Color := clRed;
    C.Pen.Width := 2;
  end
  else
    C.Pen.Color := clBlack;
  C.Ellipse(CX - Rad, CY - Rad, CX + Rad + 1, CY + Rad + 1);
  C.Pen.Width := 1;
  if S = Afbeelding then
  begin
    // rotor: drie spaken en een naaf (dunner op het kleine knopicoon)
    C.Pen.Color := clNavy;
    if Rad >= 14 then C.Pen.Width := 3 else C.Pen.Width := 2;
    for k := 0 to 2 do
    begin
      if Rad >= 14 then Q := P(Rad - 4, Angle + k * 120) else Q := P(Rad - 2, Angle + k * 120);
      C.Line(CX, CY, Q.X, Q.Y);
    end;
    C.Pen.Width := 1;
    C.Brush.Color := clNavy;
    if Rad >= 14 then C.Ellipse(CX - 3, CY - 3, CX + 4, CY + 4);
  end
  else
  begin
    C.Brush.Style := bsClear;
    C.Font.Name := 'Arial';
    C.Font.Size := 10;
    C.Font.Style := [fsBold];
    C.Font.Color := clBlack;
    C.TextOut(CX - C.TextWidth('M') div 2, CY - C.TextHeight('M') div 2, 'M');
    if Dir <> 0 then
    begin
      // rondlopend puntje op de rand
      Q := P(Rad - 3, Angle);
      C.Brush.Style := bsSolid;
      C.Brush.Color := clRed;
      C.Pen.Color := clRed;
      C.Ellipse(Q.X - 2, Q.Y - 2, Q.X + 3, Q.Y + 3);
    end;
  end;
  if Dir <> 0 then
  begin
    // gebogen pijl bovenaan, van 130 naar 50 graden (rechtsom) of omgekeerd
    R2 := Rad + 4;
    C.Pen.Color := clGreen;
    C.Pen.Width := 2;
    Q := P(R2, 130);
    C.MoveTo(Q.X, Q.Y);
    A := 130;
    while A > 50 do
    begin
      A := A - 10;
      Q := P(R2, A);
      C.LineTo(Q.X, Q.Y);
    end;
    C.Pen.Width := 1;
    // pijlpunt aan het einde in de draairichting
    if Dir > 0 then
    begin
      A := 50; Ux := Sin(A * Pi / 180); Uy := Cos(A * Pi / 180);
    end
    else
    begin
      A := 130; Ux := -Sin(A * Pi / 180); Uy := -Cos(A * Pi / 180);
    end;
    Q := P(R2, A);
    Tip := Point(Q.X + Round(5 * Ux), Q.Y + Round(5 * Uy));
    C.Brush.Style := bsSolid;
    C.Brush.Color := clGreen;
    C.Polygon([Tip, Point(Q.X - Round(4 * Uy), Q.Y + Round(4 * Ux)),
                    Point(Q.X + Round(4 * Uy), Q.Y - Round(4 * Ux))]);
  end;
  C.Pen.Color := clBlack;
  C.Pen.Width := 1;
  C.Brush.Style := bsSolid;
end;

// Lichaam van een blok (teller, geheugen): bij Afbeelding een vlak met 3D-rand,
// bij schemasymbolen een rechthoek met zwarte rand en de IEC-aanduiding
// Qual (bv. CTR4) op (QX,QY).
procedure DrawBlockBody(C: TCanvas; const R: TRect; Fill: TColor; S: TjanSymbolen;
  const Qual: string; QX, QY: Integer);
begin
  C.Brush.Style := bsSolid;
  C.Brush.Color := Fill;
  if S = Afbeelding then
  begin
    // afgerond blok met een rand (half-realistisch)
    C.Pen.Style := psSolid;
    C.Pen.Width := 1;
    C.Pen.Color := RGBToColor(89, 96, 106);
    C.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 8, 8);
    C.Pen.Color := clBlack;
    Exit;
  end;
  SymPen(C, clBlack);
  C.Rectangle(R);
  C.Brush.Style := bsClear;
  C.Font.Name := 'Arial';
  C.Font.Size := 8;
  C.Font.Style := [fsBold];
  C.Font.Color := clBlack;
  C.TextOut(QX, QY, Qual);
  C.Brush.Style := bsSolid;
  C.Brush.Color := Fill;
end;

procedure TjanLogic.PaintLed(index:integer);
var surfcol,litcol:Tcolor;
    p:Tpoint;
    x,y:integer;
    lit:boolean;
begin
  if not Gates[index].Active then exit;
  p:=Gates[index].pos;
  x:=(p.x)+23; //23 bijgevoegd om de leds naar rechts te verschuiven
  y:=(p.y);
  if index=0 then
    lit:=FInput1
  else if index=1 then
    lit:=Finput2
  else if index=2 then
    lit:=Finput3
  else if index=3 then
    lit:=Foutput1
  else if index=4 then
    lit:=Foutput2     // deze output is de normale uit
  else if index=5 then
    lit:=Foutput3;
  if lit then
  begin
    if Gates[index].Style=jgsDI then
      surfcol:=cllime
    else
      surfcol:=clred;
    litcol:=clwhite
  end
  else
  begin
    if Gates[index].Style=jgsDI then
    begin
      surfcol:=clgreen;
      litcol:=cllime;  //led uit
    end
    else begin
      surfcol:=clmaroon;
      litcol:=clred; // led aan
    end;
  end;
  with Canvas do begin
    Lock;
    brush.style:=bsclear;
    pen.color:=clgray;
    // tekenen van de aansluitingen
    If index=4 then
       begin
       lUit.Transparent := True;
       draw(x-10,y+1,lUit);
       ellipse(x,y,x+12,y+13);
       pen.color:=clblack;
       brush.color:=surfcol;
       ellipse(x+1,y+1,x+11,y+12);
       pen.color:=clwhite;
       arc(x+1,y+1,x+11,y+12,x+0,y+12,x+12,y+0);
       pen.color:=litcol;
       arc(x+3,y+3,x+8,y+9,x+5,y+0,x+0,y+8);
       end
       else
       begin
       lIn.Transparent := True;
       draw(x-23,y,lIn);
       end;

     UnLock;
   end;
end;


procedure TjanLogic.Paint;
var i:integer;
    p:Tpoint;
    lit:boolean;
    R:TRect;
    s:string;
    Sym:TjanSymbolen;
begin
   Sym:=IEC;
   if Owner is TjanSimLogicBox then
     Sym:=TjanSimLogicBox(Owner).KSymbolen;
   with canvas do
   begin
     Lock;
     if Sym=Afbeelding then
     begin
       // poort als afgerond blok met een rand (half-realistisch)
       brush.color:=FPcolor;
       brush.style:=bsSolid;
       pen.color:=RGBToColor(89,96,106);
       pen.width:=1;
       R:=rect(22,5,65,63);//ClientRect;
       RoundRect(R.Left,R.Top,R.Right,R.Bottom,8,8);
       pen.color:=clBlack;
     end;
     brush.color:=clred;
     for i:=0 to 5 do
       PaintLed(i);
     R:=ClientRect;
     inflaterect(R,0,0);
     s:='';
     if Sym<>Afbeelding then
     begin
       // symbool na de aansluitingen, zodat het de korte draadjes afdekt
       if FLogicAndFunc=jlfNOT then
         DrawGateSymbol(Canvas,rect(22,5,72,63),FLogicAndFunc,Sym,FPcolor,-1,-1)
       else if FLogicAndFunc in [jlfNAND,jlfNOR] then
         // met bolletje (omkering): iets breder, zoals NIET
         DrawGateSymbol(Canvas,rect(22,5,72,63),FLogicAndFunc,Sym,FPcolor,
           FGates[0].pos.y+6,FGates[2].pos.y+6)
       else
         DrawGateSymbol(Canvas,rect(22,5,68,63),FLogicAndFunc,Sym,FPcolor,
           FGates[0].pos.y+6,FGates[2].pos.y+6);
     end
     else
       // draw caption
       s:=LogicFuncWoord(FLogicAndFunc, BTaal);
     R:=rect(0,0,85,65);//ClientRect;
     brush.style:=bsclear;
     drawtext(canvas.handle,pchar(s),-1,R,DT_SINGLELINE or DT_CENTER or DT_VCENTER);
     if Sym<>Afbeelding then
     begin
       // de naam van de poort onder het symbool (EN, OF, NIET, ...)
       s:=LogicFuncWoord(FLogicAndFunc, BTaal);
       Font.Name:='Arial'; Font.Size:=8; Font.Style:=[fsBold]; Font.Color:=clNavy;
       TextOut(47 - TextWidth(s) div 2, 66, s);
       s:='';
     end;

     brush.style:=bsclear;
     Font.Name:='Arial';
     Font.Size:=9;
     Font.Style:= [];
     Font.Color:=clNavy;
     If FLogicAndFunc=(jlfAND) then
     Begin
     TextOut(1,20,'A1');
     TextOut(90,38,'A');
     TextOut(1,56,'A2');
     end;
     If FLogicAndFunc=(jlfOR) then
     Begin
     TextOut(1,20,'O1');
     TextOut(90,38,'O');
     TextOut(1,56,'O2');
     end;
     If FLogicAndFunc=(jlfNOT) then
     Begin
     TextOut(1,38,'N1');
     TextOut(90,38,'N');
     end;
     If FLogicAndFunc in [jlfNAND,jlfNOR,jlfXOR] then
     Begin
     case FLogicAndFunc of
       jlfNAND: s:='A';
       jlfNOR : s:='O';
     else
       s:='X';
     end;
     TextOut(1,20,s+'1');
     TextOut(90,38,s);
     TextOut(1,56,s+'2');
     end;
     Unlock;
     if select=true then
     begin
     R:=ClientRect;
      canvas.pen.Color:=clblack;
      canvas.pen.style:=psDot;canvas.Brush.Style:=bsClear;
      canvas.Lock;canvas.rectangle(R);canvas.Unlock;
      canvas.pen.Color:=clBlack;canvas.pen.style:=psSolid;
     end;
     if FSelected then
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
end;



procedure TjanLogic.Resize;
begin
  width:=100;
  height:=LogicPoortH;
end;



destructor TjanLogic.Destroy;
begin
  lIn.Free;
  lUit.Free;
  Connectors.Free;
  inherited;

end;
procedure TjanLogic.MoveConnectors;
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

procedure TjanLogic.OutCalc;
begin
  case FLogicAndFunc of
  jlfAND : OutPut2:=Input1 and Input3;
  jlfOR  : OutPut2:=Input1 or Input3;
  jlfNOT : OutPut2:=not Input2;
  jlfNAND: OutPut2:=not (Input1 and Input3);
  jlfNOR : OutPut2:=not (Input1 or Input3);
  jlfXOR : OutPut2:=Input1 xor Input3;
  end;

end;

procedure TjanLogic.SetInput1(const Value: boolean);
begin
  if value<>FInput1 then
  begin
    FInput1 := Value;
    invalidate;
    OutCalc;
  end;
end;

procedure TjanLogic.SetInput2(const Value: boolean);
begin
  if value<>FInput2 then
  begin
    FInput2 := Value;
    invalidate;
    OutCalc;
  end;

end;


procedure TjanLogic.SetDown(const Value: boolean);
begin
  if value<>FDown then
  begin
    FDown := Value;
    FDepressed:=value;
     // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
  end;
  invalidate;
end;

procedure TjanLogic.ButtonClick1(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanLogic.ButtonClick3(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;

procedure TjanLogic.ButtonClick4(Sender: TObject);
begin
  if Assigned(FBox) then
    FBox.SelectObject(Self);
end;

procedure TjanLogic.ButtonNClick(Sender: TObject);
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

procedure TjanLogic.SetInfo(const Value: String);
begin
  if value<>FInfo then
  begin
    FInfo := Value;
 end;
end;

procedure TjanLogic.SetLock(const Value: boolean);
begin
  if value<>FLock then
  begin
    FLock := Value;
 end;
end;

procedure TjanLogic.SetInput3(const Value: boolean);
begin
  if value<>FInput3 then
  begin
    FInput3 := Value;
    invalidate;
    OutCalc;
  end;
end;

procedure TjanLogic.SetOutPut1(const Value: boolean);
begin
  if value<>FOutput1 then
  begin
    FOutPut1 := Value;
    invalidate;
  end;
end;

procedure TjanLogic.SetOutPut2(const Value: boolean);
begin
  if value<>FOutput2 then
  begin
    FOutPut2 := Value;
    if FOutPut2=true then FStatPoort := stPoortStart else FStatPoort := stPoortStop;
    invalidate;

  end;
  if Assigned(OnPoortOutChange) then OnPoortOutChange(Self, StatPoort);
end;

procedure TjanLogic.SetOutPut3(const Value: boolean);
begin
  if value<>FOutput3 then
  begin
    FOutPut3 := Value;
    invalidate;
  end;

end;
procedure TjanLogic.SetPColor(const Value: TColor);
begin
  if value<>FPcolor then
  begin
    FPcolor := Value;
    invalidate;
  end;
end;

procedure TjanLogic.UpdateHintText;
begin
  Hint := BuildSimHint(FNaam, BTaal) + #13#10 +
    Tr(BTaal, 'Een poort werkt op 5 V: haar uitgang geeft hoogstens 5 V.',
              'A gate works on 5 V: its output gives at most 5 V.',
              'Une porte fonctionne sur 5 V : sa sortie donne au plus 5 V.',
              'Ein Gatter arbeitet mit 5 V: Sein Ausgang liefert höchstens 5 V.');
end;

procedure TjanLogic.SetNaam(const Value: String);
Begin
  if FNaam <> Value then
  begin
    FNaam := Value;
    Invalidate;
  end;
end;

function TjanLogic.GetLogicFuncText: string;
begin
  case LogicFunc of
    jlfAND:
      Result := Tr(BTaal,'EN','AND','ET','UND');

    jlfOR:
      Result := Tr(BTaal,'OF','OR','OU','ODER');

    jlfNOT:
      Result := Tr(BTaal,'NIET','NOT','NON','NICHT');

  else
    Result := LogicFuncWoord(LogicFunc, BTaal);
  end;
end;


procedure TjanLogic.SendStatusToBar;
var
   s, ss: string;
  // wInput:String;
   wStatus: string;

 begin
   if not Assigned(FOnStatus) then Exit;
//   wInput  := Tr(BTaal,'Verwerking','Processing','Traitement','Verarbeitung');
   wStatus := Tr(BTaal,'Status','Status','Statut','Status');

   // Panel 0  gebruikt function TjanLogic.GetLogicFuncText: string;
    if LogicFunc =jlfAND then
      FOnStatus(Self, FNaam + '(EN-AND) > ', 0);
    if LogicFunc =jlfOR then
      FOnStatus(Self, FNaam + '(OF-OR) > ', 0);
    if LogicFunc =jlfNOT then
      FOnStatus(Self, FNaam + '(NIET-NOT) > ', 0);
    if LogicFunc =jlfNAND then
      FOnStatus(Self, FNaam + '(NEN-NAND) > ', 0);
    if LogicFunc =jlfNOR then
      FOnStatus(Self, FNaam + '(NOF-NOR) > ', 0);
    if LogicFunc =jlfXOR then
      FOnStatus(Self, FNaam + '(EX-OF-XOR) > ', 0);
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


procedure TjanLogic.SetTaal(const Value: String);
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

procedure TjanLogic.SetType(const Value: String);
begin
  if value<>FType then
  begin
    FType := Value;
  invalidate;
  end;

end;

procedure TjanLogic.SetLogicFunc(const Value: TjanLogicFunc);
begin
  if value<>FLogicAndFunc then
  begin
    FLogicAndFunc := Value;
    case FLogicAndFunc of
    jlfAND:
      begin
        FGates[0].Active:=true;
        FGates[1].Active:=false;
        FGates[2].Active:=true;
        FGates[3].Active:=false;
        FGates[4].Active:=true;
        FGates[5].Active:=false;
        FType:='EN';
      end;
    jlfOR:
      begin
        FGates[0].Active:=true;
        FGates[1].Active:=false;
        FGates[2].Active:=true;
        FGates[3].Active:=false;
        FGates[4].Active:=true;
        FGates[5].Active:=false;
        FType:='OF';
      end;
    jlfNOT:
      begin
        FGates[0].Active:=false;
        FGates[1].Active:=true;
        FGates[2].Active:=false;
        FGates[3].Active:=false;
        FGates[4].Active:=true;
        FGates[5].Active:=false;
        FType:='NIET';
      end;
    jlfNAND, jlfNOR, jlfXOR:
      begin
        // twee ingangen, zoals EN en OF
        FGates[0].Active:=true;
        FGates[1].Active:=false;
        FGates[2].Active:=true;
        FGates[3].Active:=false;
        FGates[4].Active:=true;
        FGates[5].Active:=false;
        FType:=LogicFuncCode(FLogicAndFunc);
      end;
    end;
    invalidate;
    OutCalc;
  end;
end;


{ TjanTeller }

constructor TjanTeller.Create(AOwner: TComponent);
var
i:integer;
XX, YY: Integer;
PixelColor: TColor;
begin
  inherited Create(AOwner);
  Select:=false;
  FStat1 := stBit1Stop;
  FStat2 := stBit2Stop;
  FStat4 := stBit4Stop;
  FStat8 := stBit8Stop;
  width:=150;  height:=84;
  // initialize (imputs)
  FGates[0].pos:=point(1,10); FGates[0].Active:=true;    // reset
  FGates[1].pos:=point(1,46); FGates[1].Active:=true;    // telimpuls
  // initialize (outputs)
  FGates[2].pos:=point(30,80);  FGates[2].Active:=true;  // Bit8
  FGates[3].pos:=point(55,80);  FGates[3].Active:=true;  // Bit4
  FGates[5].pos:=point(80,80);  FGates[5].Active:=true;  // Bit2
  FGates[6].pos:=point(105,80); FGates[6].Active:=true;  // Bit1

  FGates[4].pos:=point(52,28);  FGates[4].Active:=true;  // naar display

  connectors:=TList.create;

  Uit:=TBitmap.create;
  Uit.LoadFromResourceName(HInstance,'UIT');

  lIn:=TBitmap.create;
  lIn.LoadFromResourceName(HInstance,'LOG_IN');

  for YY := 0 to lIn.Height - 1 do
      for XX := 0 to lIn.Width - 1 do
      begin
        PixelColor := lIn.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          lIn.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  lIn.Transparent := True;
  lIn.TransParentColor := clFuchsia;//:= lIn.canvas.pixels[0,0];

  lUit:=TBitmap.Create;
  lUit.LoadFromResourceName(HInstance,'T_UIT');
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
  lUit.TransParentColor := clFuchsia;//:= lUit.canvas.pixels[0,0];

  lBitUit:=TBitmap.Create;
  lBitUit.LoadFromResourceName(HInstance,'TBITUIT');
  for YY := 0 to lBitUit.Height - 1 do
      for XX := 0 to lBitUit.Width - 1 do
      begin
        PixelColor := lBitUit.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          lBitUit.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  lBitUit.Transparent := True;
  lUit.TransParentColor := clFuchsia;//:= lBitUit.canvas.pixels[0,0];

  FLock:=false;
  FPcolor:=rgb(250,250,150);
  FBits:=0;FBitsChar:='0';
  FLedColUit:=clMaroon;
  FLedColAan:=clred;

 // FTaal:='NL';
  FInfo:= 'TellerBlok';
  ShowHint:=true;
  FSoort:='Verwerking';
  FNaam:='TellerBlok';
end;

function TjanTeller.GetGate(Index: Integer): TjanGate;
begin
   result:=FGates[index];
end;

procedure TjanTeller.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  R, R2, Rb8, Rb4, Rb2, Rb1: TRect;
  p: TPoint;
  L, T: Integer;
  wc: TWinControl;
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

  doMove := False;
  StyleDown := False;
  mdp := Point(X, Y);

  Rb8 := Rect(30,75,40,84); // aansluitplaats Bit8
  if PtInRect(Rb8, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + 33;
    T := Top + 76;
    Maakdraad(T, L, wc);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;

  Rb4 := Rect(55,75,65,84); // aansluitplaats Bit4
  if PtInRect(Rb4, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + 58;
    T := Top + 76;
    Maakdraad(T, L, wc);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;

  Rb2 := Rect(80,75,105,84); // aansluitplaats Bit2
  if PtInRect(Rb2, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + 83;
    T := Top + 76;
    Maakdraad(T, L, wc);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;

  Rb1 := Rect(105,75,130,84); // aansluitplaats Bit1
  if PtInRect(Rb1, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + 108;
    T := Top + 76;
    Maakdraad(T, L, wc);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;

  R := Rect(135,40,150,50); // aansluitplaats display
  if PtInRect(R, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + Width - 8;
    T := Top + 41;
    Maakdraad(T, L, wc);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;

  // einde van het maken van een aansluiting
  Screen.Cursor := crDefault;

  R2 := Rect(22,20,65,45);
  doStyle := PtInRect(R2, mdp);
  doMove := not doStyle;
  oldp := Point(X, Y);

  if doMove then
  begin
    AnchorConnectors;

    if (Button = mbLeft) and (Parent is TjanGridS) then
      TjanGridS(Parent).BeginGuideLines(Left + Width div 2, Top + Height div 2);
  end;

  if doStyle then
  begin
    StyleDown := True;
    Invalidate;
  end;
end;

procedure TjanTeller.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  p: TPoint;
  Grid: TjanGridS;
  SnapP: TPoint;
  WorkR: TRect;
begin
  inherited;

  if FLock = True then Exit;
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

procedure TjanTeller.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;

  if Parent is TjanGridS then
    TjanGridS(Parent).EndGuideLines;

  Select := False;
  Invalidate;

  if FLock = True then Exit;

  StyleDown := False;
  FMouseOver := True;
  SendStatusToBar;
end;



procedure TjanTeller.BuildPopup;
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

  procedure TjanTeller.UpdatePopupCaptions;
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

procedure TjanTeller.UpdateHintText;
begin
    Hint := BuildSimHint(FNaam, BTaal);
end;

procedure TjanTeller.SendStatusToBar;//xxx
  var
   s, ss: string;
   wInput, wStatus: string;
 begin
   if not Assigned(FOnStatus) then Exit;

   wInput  := Tr(BTaal,'Invoer','Input','Entrée','Eingang');
   wStatus := Tr(BTaal,'Status','Status','Statut','Status');

   // Panel 0
  //FOnStatus(Self, FNaam + ' > ', 0);
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

procedure TjanTeller.SetNaam(const Value: String);//xxxx
Begin
  if FNaam <> Value then
  begin
    FNaam := Value;
    Invalidate;
    // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
  end;
end;

procedure TjanTeller.SetTaal(const Value: String);
begin
   if Value <> FTaal then
    FTaal := Value;

  if Value = 'NL' then FInfo := 'Verwerking --> Tellerblok'
  else if Value = 'ENG' then FInfo := 'Processing --> Counter block'
  else if Value = 'FR' then FInfo := 'Traitement --> Bloc compteur'
  else if Value = 'DU' then FInfo := 'Verarbeitung --> Zählerblock';

  UpdateHintText;
  Invalidate;

  if FMouseOver then
    SendStatusToBar;
end;

procedure TjanTeller.CMMouseLeave(var Msg: TMessage);
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

procedure TjanTeller.CMMouseEnter(var Msg: TMessage);
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


procedure TjanTeller.CMHitTest(var Message: TCMHitTest);
 begin
 inherited;
  { //if Flock=true then exit;
   Message.Result := 0;
   if Canvas.Pixels[Message.XPos, Message.YPos] = clLime then
    begin
    Message.Result := 1;SendToBack;exit;
    end;
   if Canvas.Pixels[Message.XPos, Message.YPos] <> clLime then
    begin
    Message.Result := 1;BringToFront;exit;
    end;}
end;

procedure TjanTeller.AnchorConnectors;
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




procedure TjanTeller.PaintLed8(status:Integer);
var
x,y:Integer;
Begin
x:=30;y:=43;
  with Canvas do
  begin
  Lock;
       brush.style:=bsclear;
       // led bit 8
       pen.color:=clgray;
       ellipse(x,y,x+12,y+13);
       pen.color:=clblack;
       If Status=1 then
          Begin brush.color:=FLedColAan;FStat8 := stBit8Start;  end
          else
          begin brush.color:=FLedColUit;FStat8 := stBit8Stop; end;
       ellipse(x+1,y+1,x+11,y+12);pen.color:=clwhite;
       arc(x+1,y+1,x+11,y+12,x+0,y+12,x+12,y+0);pen.color:=clwhite;
       arc(x+3,y+3,x+8,y+9,x+5,y+0,x+0,y+8);
  UnLock;
  end;
  if Assigned(OnBit8Change) then OnBit8Change(Self, Stat8);
end;

procedure TjanTeller.PaintLed4(status:Integer);
var
litcol:TColor;
x,y:Integer;
Begin
x:=55;y:=43;
litcol:=clwhite;
  with Canvas do
  begin
  Lock;
       brush.style:=bsclear;
      // led bit 4
       pen.color:=clgray;
       ellipse(x,y,x+12,y+13);
       pen.color:=clblack;
       If Status=1 then
          Begin brush.color:=FLedColAan;FStat4 := stBit4Start; end
          else
          begin brush.color:=FLedColUit;FStat4 := stBit4Stop; end;
       ellipse(x+1,y+1,x+11,y+12);pen.color:=clwhite;
       arc(x+1,y+1,x+11,y+12,x+0,y+12,x+12,y+0);pen.color:=litcol;
       arc(x+3,y+3,x+8,y+9,x+5,y+0,x+0,y+8);
   Unlock;
   end;
  if Assigned(OnBit4Change) then OnBit4Change(Self, Stat4);
end;

procedure TjanTeller.PaintLed2(status:Integer);
var
litcol:TColor;
x,y:Integer;
Begin
x:=80;y:=43;
litcol:=clwhite;
  with Canvas do
  begin
  Lock;
       brush.style:=bsclear;
      // led bit 2
       pen.color:=clgray;
       ellipse(x,y,x+12,y+13);
       pen.color:=clblack;
       If Status=1 then
          Begin brush.color:=FLedColAan;FStat2 := stBit2Start;end
          else
          begin brush.color:=FLedColUit;FStat2 := stBit2Stop;end;
       ellipse(x+1,y+1,x+11,y+12);pen.color:=clwhite;
       arc(x+1,y+1,x+11,y+12,x+0,y+12,x+12,y+0);pen.color:=litcol;
       arc(x+3,y+3,x+8,y+9,x+5,y+0,x+0,y+8);
   UnLock;
   end;
  if Assigned(OnBit2Change) then OnBit2Change(Self, Stat2);
end;

procedure TjanTeller.PaintLed1(status:Integer);
var
litcol:TColor;
x,y:Integer;
Begin
x:=105;y:=43;
litcol:=clwhite;
  with Canvas do
  begin
  Lock;
       brush.style:=bsclear;
       // led bit 1
       pen.color:=clgray;
       ellipse(x,y,x+12,y+13);
       pen.color:=clblack;
       If Status=1 then
          Begin brush.color:=FLedColAan;FStat1 := stBit1Start; end
          else
          begin brush.color:=FLedColUit;FStat1 := stBit1Stop; end;
       ellipse(x+1,y+1,x+11,y+12);pen.color:=clwhite;
       arc(x+1,y+1,x+11,y+12,x+0,y+12,x+12,y+0);pen.color:=litcol;
       arc(x+3,y+3,x+8,y+9,x+5,y+0,x+0,y+8);
   Unlock;
   end;
if Assigned(OnBit1Change) then OnBit1Change(Self, Stat1);
end;


procedure TjanTeller.PaintLeds(bit:Integer);
begin
 PaintLed1(0);PaintLed2(0);PaintLed4(0);PaintLed8(0);
 if bit=0 then begin end;
 If bit=1 then begin PaintLed1(1);exit;end;
 If bit=2 then begin PaintLed2(1);exit;end;
 If bit=3 then begin PaintLed1(1);PaintLed2(1);exit;end;
 If bit=4 then begin PaintLed4(1);exit;end;
 If bit=5 then begin PaintLed1(1);PaintLed4(1);exit;end;
 If bit=6 then begin PaintLed2(1);PaintLed4(1);exit;end;
 If bit=7 then begin PaintLed1(1);PaintLed2(1);PaintLed4(1);exit;end;
 If bit=8 then begin PaintLed8(1);exit;end;
 If bit=9 then begin PaintLed1(1);PaintLed8(1);exit;end;
 If bit=10 then begin PaintLed2(1);PaintLed8(1);exit;end;
 If bit=11 then begin PaintLed2(1);PaintLed1(1);PaintLed8(1);exit;end;
 If bit=12 then begin PaintLed4(1);PaintLed8(1);exit;end;
 If bit=13 then begin PaintLed4(1);PaintLed1(1);PaintLed8(1);exit;end;
 If bit=14 then begin PaintLed2(1);PaintLed4(1);PaintLed8(1);exit;end;
 If bit=15 then begin PaintLed2(1);PaintLed1(1);PaintLed8(1);PaintLed4(1);exit;end;
end;


procedure TjanTeller.Paint;
var
i:integer;
R:TRect;
begin
 lIn.Transparent:=true;
 lUit.Transparent:=true;
 lBitUit.Transparent:=true;
 Uit.Transparent:=true;
   with canvas do
   begin
   Lock;
     brush.color:=FPcolor;
     R:=rect(22,15,125,65);
     DrawBlockBody(Canvas, R, FPcolor, SymOf(Self), 'CTR4', 24, 0);
     PaintLeds(FBits);
     brush.style:=bsclear;
     Font.Name:='Arial';
     Font.Size:=8;
     Font.Style:= [];
     Font.Color:=clNavy;
     TextOut(1,20,'Re');TextOut(1,68,'Te');
     TextOut(31,16,'T');TextOut(55,16,'T');TextOut(79,16,'T');TextOut(103,16,'T');
     Font.Size:=7;
     TextOut(39,19,'8');TextOut(63,19,'4');TextOut(87,18,'2');TextOut(111,18,'1');
     pen.Color:=clSilver;
     MoveTo(48,15);LineTo(48,height-20);MoveTo(72,15);LineTo(72,height-20);MoveTo(96,15);LineTo(96,height-20);
     lUit.Transparent := True;
     draw(126,40,lUit);
     draw(0,10,lIn);
     draw(0,50,lIn);
     draw(0,height-30,lIn);
     draw(31,74,Uit);draw(56,74,Uit);draw(81,74,Uit);draw(106,74,Uit);
     draw(31,50,lBitUit);draw(56,50,lBitUit);draw(81,50,lBitUit);draw(106,50,lBitUit);
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
   if Selected then
   Begin
     R := ClientRect;
   // InflateRect(R, -1, -1);         // binnen de rand tekenen
     canvas.Brush.Style := bsClear;
     canvas.Pen.Color := clRed;
     canvas.pen.style:=psDot;
     canvas.Pen.Width := 1;
     canvas.Rectangle(R);
    // restore (netjes)
     canvas.Pen.Width := 1;
     canvas.pen.style:=psSolid;
     canvas.Brush.Style := bsSolid;
  end;
end;



procedure TjanTeller.Resize;
begin
  width:=150;
  height:=84;
end;

destructor TjanTeller.Destroy;
begin
  uit.Free;
  lIn.Free;
  lUit.Free;
  lBitUit.Free;
  Connectors.Free;
  inherited;

end;

procedure TjanTeller.MoveConnectors;
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



procedure TjanTeller.SetInput1(const Value: boolean);
begin
  if value=true then
  begin
    FResetRonde := SimRonde;
    FBits := 0;FBitsChar:='0';
    FOutPutBit1:=false;FOutPutBit2:=false;FOutPutBit4:=false;FOutPutBit8:=false;
    invalidate;
 end;
FInput1:=false;
end;

procedure TjanTeller.SetLoop(const Value: boolean);
begin
  FLoop := value;
  // reset gaat voor: een telpuls in dezelfde ronde als Re hoog telt niet
  if value and (SimRonde <> 0) and (FResetRonde = SimRonde) then
    Exit;
  if value=true then
  begin
     inc(FBits);
     If FBits > 15 then FBits:=0;
     If FBits=0 then
        begin FBitsChar:='0';
        FOutPutBit1:=false;FOutPutBit2:=false;FOutPutBit4:=false;FOutPutBit8:=false;
        invalidate;exit;end;
     If FBits=1 then
        begin FBitsChar:='1';
        FOutPutBit1:=true;FOutPutBit2:=false;FOutPutBit4:=false;FOutPutBit8:=false;
        invalidate;exit;end;
     If FBits=2 then
        begin FBitsChar:='2';
        FOutPutBit1:=false;FOutPutBit2:=true;FOutPutBit4:=false;FOutPutBit8:=false;
        invalidate;exit;end;
     If FBits=3 then
        begin FBitsChar:='3';
        FOutPutBit1:=true;FOutPutBit2:=true;FOutPutBit4:=false;FOutPutBit8:=false;
        invalidate;exit;end;
     If FBits=4 then
        begin FBitsChar:='4';
        FOutPutBit1:=false;FOutPutBit2:=false;FOutPutBit4:=true;FOutPutBit8:=false;
        invalidate;exit;end;
     If FBits=5 then
        begin FBitsChar:='5';
        FOutPutBit1:=true;FOutPutBit2:=false;FOutPutBit4:=true;FOutPutBit8:=false;
        invalidate;exit;end;
     If FBits=6 then
        begin FBitsChar:='6';
        FOutPutBit1:=false;FOutPutBit2:=true;FOutPutBit4:=true;FOutPutBit8:=false;
        invalidate;exit;end;
     If FBits=7 then
        begin FBitsChar:='7';
        FOutPutBit1:=true;FOutPutBit2:=true;FOutPutBit4:=true;FOutPutBit8:=false;
        invalidate;exit;end;
     If FBits=8 then
        begin FBitsChar:='8';
        FOutPutBit1:=false;FOutPutBit2:=false;FOutPutBit4:=false;FOutPutBit8:=true;
        invalidate;exit;end;
     If FBits=9 then
        begin FBitsChar:='9';
        FOutPutBit1:=true;FOutPutBit2:=false;FOutPutBit4:=false;FOutPutBit8:=true;
        invalidate;exit;end;
     If FBits=10 then
        begin FBitsChar:='A';
        FOutPutBit1:=false;FOutPutBit2:=true;FOutPutBit4:=false;FOutPutBit8:=true;
        invalidate;exit;end;
     If FBits=11 then
        begin FBitsChar:='B';
        FOutPutBit1:=true;FOutPutBit2:=true;FOutPutBit4:=false;FOutPutBit8:=true;
        invalidate;exit;end;
     If FBits=12 then
        begin FBitsChar:='C';
        FOutPutBit1:=false;FOutPutBit2:=false;FOutPutBit4:=true;FOutPutBit8:=true;
        invalidate;exit;end;
     If FBits=13 then
        begin FBitsChar:='D';
        FOutPutBit1:=true;FOutPutBit2:=false;FOutPutBit4:=true;FOutPutBit8:=true;
        invalidate;exit;end;
     If FBits=14 then
        begin FBitsChar:='E';
        FOutPutBit1:=false;FOutPutBit2:=true;FOutPutBit4:=true;FOutPutBit8:=true;
        invalidate;exit;end;
     If FBits=15 then
        begin FBitsChar:='F';
        FOutPutBit1:=true;FOutPutBit2:=true;FOutPutBit4:=true;FOutPutBit8:=true;
        invalidate;exit;end;
  end;
end;
{
procedure TjanTeller.tellerClick(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanTeller.tellerClick2(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;}

//new
procedure TjanTeller.ButtonClick1(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanTeller.ButtonClick3(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;

procedure TjanTeller.ButtonNClick(Sender: TObject);
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

procedure TjanTeller.ButtonClick4(sender:TObject); //selecteer
begin
 if Assigned(FBox) then
    FBox.SelectObject(Self);
end;



procedure TjanTeller.SetInfo(const Value: String);
begin
  if value<>FInfo then
  begin
    FInfo := Value;
 end;
end;

procedure TjanTeller.SetBits(const Value:Integer);
begin
  if value <> FBits then
  begin
     FBits := Value;
     If FBits=0 then FBitsChar:='0';
     If FBits=1 then FBitsChar:='1';
     If FBits=2 then FBitsChar:='2';
     If FBits=3 then FBitsChar:='3';
     If FBits=4 then FBitsChar:='4';
     If FBits=5 then FBitsChar:='5';
     If FBits=6 then FBitsChar:='6';
     If FBits=7 then FBitsChar:='7';
     If FBits=8 then FBitsChar:='8';
     If FBits=9 then FBitsChar:='9';
     If FBits=10 then FBitsChar:='A';
     If FBits=11 then FBitsChar:='B';
     If FBits=12 then FBitsChar:='C';
     If FBits=13 then FBitsChar:='D';
     If FBits=14 then FBitsChar:='E';
     If FBits=15 then FBitsChar:='F';
  end;
  invalidate;
end;

procedure TjanTeller.SetBitsChar(const Value:Char);
begin
  if value <> FBitsChar then
  begin
    FBitsChar := Value;
  end;
  invalidate;
end;

procedure TjanTeller.SetLock(const Value: boolean);
begin
  if value<>FLock then
  begin
    FLock := Value;
 end;
end;

procedure TjanTeller.SetInput3(const Value: boolean);
begin
  if value<>FInput3 then
  begin
    FInput3 := Value;
    invalidate;
  end;
end;



procedure TjanTeller.SetOutPutDisplay(const Value: boolean);
begin
  if value <> FOutputDisplay then
  begin
    FOutPutDisplay := Value;
  end;
invalidate;
end;
procedure TjanTeller.SetOutPutBit1(const Value: boolean);
begin
  if value <> FOutputBit1 then
  begin
    FOutPutBit1 := Value;
  end;

end;
procedure TjanTeller.SetOutPutBit2(const Value: boolean);
begin
  if value <> FOutputBit2 then
  begin
    FOutPutBit2 := Value;
  end;

end;
procedure TjanTeller.SetOutPutBit4(const Value: boolean);
begin
  if value <> FOutputBit4 then
  begin
    FOutPutBit4 := Value;
  end;

end;
procedure TjanTeller.SetOutPutBit8(const Value: boolean);
begin
  if value <> FOutputBit8 then
  begin
    FOutPutBit8 := Value;
  end;
end;
procedure TjanTeller.SetOutPutBits(const Value: boolean);
begin

end;

procedure TjanTeller.SetPColor(const Value: TColor);
begin
  if value<>FPcolor then
  begin
    FPcolor := Value;
    invalidate;
  end;
end;
procedure TjanTeller.SetLedColUit(const Value: TColor);
begin
  if value<>FLedColUit then
  begin
    FLedColUit := Value;
    invalidate;
  end;
end;

procedure TjanTeller.SetLedColAan(const Value: TColor);
begin
  if value<>FLedColAan then
  begin
    FLedColAan := Value;
    invalidate;
  end;
end;

procedure TjanTeller.SetDown(const Value: boolean);
begin
  if value<>FDown then
  begin
   FDown := Value;
   FDepressed:=value;
  // puls:=1;
   invalidate;

    // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
  end;
 end;

//-----TjanMemory
constructor TjanMemory.Create(AOwner: TComponent);
var
    i,YY,XX:integer;
    PixelColor: TColor;
begin
  inherited Create(AOwner);
  Select:=false;
  schrijf:=false;
  lijst:=TStringList.Create;
  //for i:= 0 to 15 do  lijst.Add('0');
  for i:= 0 to 31 do  lijst.Add('0');
  FStatMem1 := stBitMem1Stop;FStatMem2 := stBitMem2Stop;FStatMem4 := stBitMem4Stop;
  FStatMem8 := stBitMem8Stop;FStatMemB := stMemButtonStop;
  width:=200;height:=155;
  // initialize (imputs)
  FGates[0].pos:=point(120,64); FGates[0].Active:=true;   // imput vanuit dipswitsh
  FGates[1].pos:=point(80,33); FGates[1].Active:=true;    // imput adress bit8
  FGates[7].pos:=point(105,33); FGates[7].Active:=true;   // imput adress bit4
  FGates[8].pos:=point(130,33); FGates[8].Active:=true;   // imput adress bit2
  FGates[9].pos:=point(155,33); FGates[9].Active:=true;   // imput adress bit1
   // initialize (outputs)

  FGates[2].pos:=point(81,138);   FGates[2].Active:=true;  // Bit8
  FGates[3].pos:=point(106,138);  FGates[3].Active:=true;  // Bit4
  FGates[4].pos:=point(191,90);  FGates[4].Active:=true;  // naar display
  FGates[5].pos:=point(134,138);  FGates[5].Active:=true;  // Bit2
  FGates[6].pos:=point(156,138);  FGates[6].Active:=true;  // Bit1
  connectors:=TList.create;

///--------
  lAcoo:=TBitmap.create;
   lAcoo.LoadFromResourceName(HInstance,'ACO0');
      // Loop door alle pixels van de afbeelding
    for YY := 0 to lAcoo.Height - 1 do
      for XX := 0 to lAcoo.Width - 1 do
      begin
        PixelColor := lAcoo.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          lAcoo.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
   lAcoo.Transparent := True;
   lAcoo.TransParentColor := clFuchsia; //lAco.canvas.pixels[0,0];
///--------
  Bin:=TBitmap.create;
  Bin.LoadFromResourceName(HInstance,'BINUIT');
   // Loop door alle pixels van de afbeelding
    for YY := 0 to Bin.Height - 1 do
      for XX := 0 to Bin.Width - 1 do
      begin
        PixelColor := Bin.Canvas.Pixels[XX, YY];
        // Als de pixelkleur in de buurt van wit is, maak deze dan transparant
        if (Red(PixelColor) > 200) and (Green(PixelColor) > 200) and (Blue(PixelColor) > 200) then
        begin
          Bin.Canvas.Pixels[XX, YY] := clFuchsia;  // Zet pixelkleur naar een transparante kleur
        end;
      end;
  Bin.Transparent := True;
  Bin.TransParentColor := clFuchsia;//Bin.canvas.pixels[0,0];
///--------
  BinAan:=TBitmap.create;
  BinAan.LoadFromResourceName(HInstance,'BINAAN');
  BinAan.Transparent := True;
  BinAan.TransParentColor := BinAan.canvas.pixels[0,0];
  Uit:=TBitmap.create;
  Uit.LoadFromResourceName(HInstance,'UIT');
  Inv:=TBitmap.create;
  Inv.LoadFromResourceName(HInstance,'IN');

  lIn:=TBitmap.create;
  lIn.LoadFromResourceName(HInstance,'LOG_IN');
  lIn.Transparent := True;
  lIn.TransParentColor := lIn.canvas.pixels[0,0];
  lUit:=TBitmap.Create;
  lUit.LoadFromResourceName(HInstance,'T_UIT');
  lUit.Transparent := True;
  lUit.TransParentColor := lUit.canvas.pixels[0,0];

  lBitUit:=TBitmap.Create;
  lBitUit.LoadFromResourceName(HInstance,'MUIT');
  lBitUit.Transparent := True;
  lBitUit.TransParentColor := lBitUit.canvas.pixels[0,0];

  lBitUit1:=TBitmap.Create;
  lBitUit1.LoadFromResourceName(HInstance,'MUIT1');
  lBitUit1.Transparent := True;
  lBitUit1.TransParentColor := lBitUit1.canvas.pixels[0,3];

  // de oude data-aansluiting (getal over een draad) alleen tonen als er een
  // draad op zit; nieuw zijn de ingangen D8..D1 en S links
  FConnector:=false;
  FLock:=false;
  FPcolor:=rgb(250,250,150);
  FBits:=0;FBitsChar:='0';
  FLedColUit:=clMaroon;
  FLedColAan:=clred;
  FDown:=false;
  FInfo:= 'Geheugenblok';
  ShowHint:=true;
 // FTaal:='NL';
  FSoort:='Verwerking';
  FNaam:='Geheugenblok';
end;

function TjanMemory.GetGate(Index: Integer): TjanGate;
begin
   result:=FGates[index];
end;

procedure TjanMemory.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  R, Rb8, Rb4, Rb2, Rb1, Rb: TRect;
  p: TPoint;
  L, T: Integer;
  wc: TWinControl;
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

  doMove := False;
  mdp := Point(X, Y);

  // A16 is een gewone ingang (draad), geen ingebouwd schakelaartje meer
  doMove := True;
  FDepressed := False;
  oldp := Point(X, Y);

  if doMove then
  begin
    AnchorConnectors;

    if (Button = mbLeft) and (Parent is TjanGridS) then
      TjanGridS(Parent).BeginGuideLines(Left + Width div 2, Top + Height div 2);
  end
  else
    Invalidate;

  Rb8 := Rect(81,138,90,148); // aansluitplaats Bit8
  if PtInRect(Rb8, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + 82;
    T := Top + 85 + 55;
    Maakdraad(T, L, wc);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;

  Rb4 := Rect(106,138,116,148); // aansluitplaats Bit4
  if PtInRect(Rb4, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + 107;
    T := Top + 85 + 55;
    Maakdraad(T, L, wc);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;

  Rb2 := Rect(134,138,144,148); // aansluitplaats Bit2
  if PtInRect(Rb2, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + 132;
    T := Top + 85 + 55;
    Maakdraad(T, L, wc);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;

  Rb1 := Rect(156,138,166,148); // aansluitplaats Bit1
  if PtInRect(Rb1, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + 157;
    T := Top + 85 + 55;
    Maakdraad(T, L, wc);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;

  R := Rect(191,90,199,100); // aansluitplaats display
  if PtInRect(R, mdp) and (Screen.Cursor = crDraad) then
  begin
    wc := Parent;
    L := Left + 192;
    T := Top + 91;
    Maakdraad(T, L, wc);
    doMove := False;
    movecursor;
    BringToFront;
    Exit;
  end;

  Screen.Cursor := crDefault;
end;

procedure TjanMemory.MouseMove(Shift: TShiftState; X, Y: Integer);
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

procedure TjanMemory.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
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
  SendStatusToBar;

end;


procedure TjanMemory.CMMouseLeave(var Msg: TMessage);
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

procedure TjanMemory.CMMouseEnter(var Msg: TMessage);
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

procedure TjanMemory.CMHitTest(var Message: TCMHitTest);
 begin
 inherited;
   //if Flock=true then exit;
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

procedure TjanMemory.AnchorConnectors;
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



procedure TjanMemory.BuildPopup;
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

 procedure TjanMemory.UpdatePopupCaptions;
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

procedure TjanMemory.UpdateHintText;
begin
   Hint := BuildSimHint(FNaam, BTaal);
end;

procedure TjanMemory.PaintLed8(status:Integer);
var
x,y:Integer;
Begin
x:=80;y:=47+50-4;
  with Canvas do
  begin
  Lock;
       brush.style:=bsclear;
       // led bit 8
       pen.color:=clgray;
       ellipse(x,y,x+12,y+13);
       pen.color:=clblack;
       If Status=1 then
          Begin brush.color:=FLedColAan;FStatMem8 := stBitMem8Start;  end
          else
          begin brush.color:=FLedColUit;FStatMem8 := stBitMem8Stop; end;
       ellipse(x+1,y+1,x+11,y+12);pen.color:=clwhite;
       arc(x+1,y+1,x+11,y+12,x+0,y+12,x+12,y+0);pen.color:=clwhite;
       arc(x+3,y+3,x+8,y+9,x+5,y+0,x+0,y+8);
   Unlock;
   end;
  if Assigned(OnBitMem8Change) then OnBitMem8Change(Self, StatMem8);
end;

procedure TjanMemory.PaintLed4(status:Integer);
var
litcol:TColor;
x,y:Integer;
Begin
x:=105;y:=47+50-4;
litcol:=clwhite;
  with Canvas do
  begin
  Lock;
       brush.style:=bsclear;
      // led bit 4
       pen.color:=clgray;
       ellipse(x,y,x+12,y+13);
       pen.color:=clblack;
       If Status=1 then
          Begin brush.color:=FLedColAan;FStatMem4 := stBitMem4Start; end
          else
          begin brush.color:=FLedColUit;FStatMem4 := stBitMem4Stop; end;
       ellipse(x+1,y+1,x+11,y+12);pen.color:=clwhite;
       arc(x+1,y+1,x+11,y+12,x+0,y+12,x+12,y+0);pen.color:=litcol;
       arc(x+3,y+3,x+8,y+9,x+5,y+0,x+0,y+8);
  Unlock;
  end;
  if Assigned(OnBitMem4Change) then OnBitMem4Change(Self, StatMem4);
end;

procedure TjanMemory.PaintLed2(status:Integer);
var
litcol:TColor;
x,y:Integer;
Begin
x:=130;y:=47+50-4;
litcol:=clwhite;
  with Canvas do
  begin
  Lock;
       brush.style:=bsclear;
      // led bit 2
       pen.color:=clgray;
       ellipse(x,y,x+12,y+13);
       pen.color:=clblack;
       If Status=1 then
          Begin brush.color:=FLedColAan;FStatMem2 := stBitMem2Start;end
          else
          begin brush.color:=FLedColUit;FStatMem2 := stBitMem2Stop;end;
       ellipse(x+1,y+1,x+11,y+12);pen.color:=clwhite;
       arc(x+1,y+1,x+11,y+12,x+0,y+12,x+12,y+0);pen.color:=litcol;
       arc(x+3,y+3,x+8,y+9,x+5,y+0,x+0,y+8);
  Unlock;
  end;
  if Assigned(OnBitMem2Change) then OnBitMem2Change(Self, StatMem2);
end;

procedure TjanMemory.PaintLed1(status:Integer);
var
litcol:TColor;
x,y:Integer;
Begin
x:=155;y:=47+50-4;
litcol:=clwhite;
  with Canvas do
  begin
  Lock;
       brush.style:=bsclear;
       // led bit 1
       pen.color:=clgray;
       ellipse(x,y,x+12,y+13);
       pen.color:=clblack;
       If Status=1 then
          Begin brush.color:=FLedColAan;FStatMem1 := stBitMem1Start; end
          else
          begin brush.color:=FLedColUit;FStatMem1 := stBitMem1Stop; end;
       ellipse(x+1,y+1,x+11,y+12);pen.color:=clwhite;
       arc(x+1,y+1,x+11,y+12,x+0,y+12,x+12,y+0);pen.color:=litcol;
       arc(x+3,y+3,x+8,y+9,x+5,y+0,x+0,y+8);
   Unlock;
   end;
if Assigned(OnBitMem1Change) then OnBitMem1Change(Self, StatMem1);
end;


procedure TjanMemory.PaintLeds(bit:Integer);
begin
 PaintLed1(0);PaintLed2(0);PaintLed4(0);PaintLed8(0);
 If bit=1 then begin PaintLed1(1);exit;end;
 If bit=2 then begin PaintLed2(1);exit;end;
 If bit=3 then begin PaintLed1(1);PaintLed2(1);exit;end;
 If bit=4 then begin PaintLed4(1);exit;end;
 If bit=5 then begin PaintLed1(1);PaintLed4(1);exit;end;
 If bit=6 then begin PaintLed2(1);PaintLed4(1);exit;end;
 If bit=7 then begin PaintLed1(1);PaintLed2(1);PaintLed4(1);exit;end;
 If bit=8 then begin PaintLed8(1);exit;end;
 If bit=9 then begin PaintLed1(1);PaintLed8(1);exit;end;
 If bit=10 then begin PaintLed2(1);PaintLed8(1);exit;end;
 If bit=11 then begin PaintLed2(1);PaintLed1(1);PaintLed8(1);exit;end;
 If bit=12 then begin PaintLed4(1);PaintLed8(1);exit;end;
 If bit=13 then begin PaintLed4(1);PaintLed1(1);PaintLed8(1);exit;end;
 If bit=14 then begin PaintLed2(1);PaintLed4(1);PaintLed8(1);exit;end;
 If bit=15 then begin PaintLed2(1);PaintLed1(1);PaintLed8(1);PaintLed4(1);exit;end;
end;


procedure TjanMemory.Paint;
var
i:integer;
R:TRect;
Y,x:integer;
begin
   with canvas do
   begin
     Lock;
     y:=50;x:=50;
     brush.color:=FPcolor;
     R:=rect(22+x,0+y+15,125+x,65+y);
     DrawBlockBody(Canvas, R, FPcolor, SymOf(Self), 'RAM 32x4', 8, 64);
     PaintLeds(FBits);
     brush.style:=bsclear;
     Font.Name:='Arial';Font.Size:=8;Font.Style:= [];Font.Color:=clNavy;
     TextOut(31+x,2+y+15,'G');TextOut(55+x,2+y+15,'G');TextOut(79+x,2+y+15,'G');TextOut(103+x,2+y+15,'G');
     Font.Size:=7;
     TextOut(40+x,5+y+15,'8');TextOut(64+x,5+y+15,'4');TextOut(88+x,5+y+15,'2');TextOut(112+x,5+y+15,'1');
     pen.Color:=clSilver;
     MoveTo(48+x,0+y + 15);LineTo(48+x,115);
     MoveTo(72+x,0+y + 15);LineTo(72+x,115);
     MoveTo(96+x,0+y + 15);LineTo(96+x,115);

     lUit.Transparent:=true;
     draw(126+x,25+y+15,lUit);
     // tekenen van de uitvoerpunten Bit8,Bit4,Bit2,Bit1
     Uit.Transparent:=true;
     draw(31+x,25+y+9+54,Uit);draw(56+x,25+y+9+54,Uit);draw(81+x,25+y+9+54,Uit);draw(106+x,25+y+9+54,Uit);
     // tekenen van de uitvoerpunten Bit8,Bit4,Bit2,Bit1 -- pijlen naar boven
     lBitUit.Transparent:=true;
     draw(23+x,63+y,lBitUit);draw(48+x,63+y,lBitUit);draw(73+x,63+y,lBitUit);draw(98+x,63+y,lBitUit);
     // tekenen van de uitvoerpunten Bit8,Bit4,Bit2,Bit1 -- pijlen naar onder
     lBitUit1.Transparent:=true;
     draw(23+x,63+y+13,lBitUit1);draw(48+x,63+y+13,lBitUit1);draw(73+x,63+y+13,lBitUit1);draw(98+x,63+y+13,lBitUit1);

     Font.Size:=7;
     TextOut(5+x,2+y-9,'A');TextOut(28+x,2+y-9,'A');TextOut(53+x,2+y-9,'A');TextOut(79+x,2+y-9,'A');TextOut(104+x,2+y-9,'A');
     Font.Size:=7;
     TextOut(13+x,5+y-10,'16');TextOut(38+x,5+y-10,'8');TextOut(64+x,5+y-10,'4');TextOut(88+x,5+y-10,'2');TextOut(112+x,5+y-10,'1');
     // tekenen van de invoerpunten Bit8,Bit4,Bit2,Bit1
     Inv.Transparent:=true;
     draw(56,25+8,Inv);   //imput adress 16
     draw(30+x,25+8,Inv); //imput adress 8   x:=50
     draw(55+x,25+8,Inv); //imput adress 4
     draw(80+x,25+8,Inv); //imput adress 2
     draw(105+x,25+8,Inv);//imput adress 1
     If FConnector=true then
       begin
       Inv.Transparent:=true;
       draw(17,71+y,Inv);
       end;
     //test voor adress  -adresregel  en adresinhoud
     //if schrijf=false then
        //TextOut(17,80,inttoStr(adress)+ ' ... ' + lijst.Strings[adress]+'   0');
     //if schrijf=true then
        //TextOut(17,80,inttoStr(adress)+ ' ... ' + lijst.Strings[adress] +'   1');

     Font.Size:=7;
     TextOut(10,80,'ADRES = '+inttoStr(adress));
     // data-ingangen 8, 4, 2, 1 en schrijfingang S links (groen = 1)
     pen.Style:=psSolid; pen.Color:=clBlack;
     Font.Size:=6; Font.Style:=[fsBold];
     for i:=0 to 4 do
     begin
       brush.style:=bsSolid;
       if ((i<4) and FDin[i]) or ((i=4) and FSchrijfIn) then brush.color:=clLime else brush.color:=clSilver;
       Rectangle(1, MemDataY[i]-3, 8, MemDataY[i]+4);
       brush.style:=bsclear;
       if i<4 then TextOut(10, MemDataY[i]-5, 'D'+IntToStr(MemDataW[i]))
       else TextOut(10, MemDataY[i]-5, 'S');
     end;
     Font.Style:=[]; Font.Size:=7;
     pen.Color:=clBlack;pen.Style:=psdot;

     lAcoo.Transparent:=true;
     draw(6+x,50,lAcoo); //

     // A16 is een gewone ingang, net als A8..A1 (ADRES toont het resultaat)
     pen.Style:=psSolid;
     If FConnector=true then
       begin
       MoveTo(27, 76+y);LineTo(30+x, 76+y)
       end
       else
       MoveTo(0+x, 76+y);LineTo(30+x, 76+y);
     pen.Color:=clSilver;
     MoveTo(112+x, 76+y);LineTo(124+x, 76+y);
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



procedure TjanMemory.Resize;
begin
  width:=200;
  height:=155;//88
end;



destructor TjanMemory.Destroy;
begin
  lAcoo.Free;
  uit.Free;
  lIn.Free;
  Inv.Free;
  lUit.Free;
  lBitUit.Free;
  lBitUit1.Free;
  Bin.Free;
  BinAan.Free;
  Connectors.Free;
  lijst.Free;
  inherited;
end;

procedure TjanMemory.getadress;
var
a,b,c,d:integer;
begin
if A1=true then a:=1 else a:=0;
if A2=true then b:=2 else b:=0;
if A4=true then c:=4 else c:=0;
if A8=true then d:=8 else d:=0;

adress:=a+b+c+d;

end;

procedure TjanMemory.MoveConnectors;
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



procedure TjanMemory.SetInputMem1(const Value: boolean);
begin
  if value=true then
  begin
    FBits := 0;FBitsChar:='0';
    FOutPutBitMem1:=false;FOutPutBitMem2:=false;FOutPutBitMem4:=false;FOutPutBitMem8:=false;
    invalidate;
 end;
FInputMem1:=false;
end;
{
procedure TjanMemory.SetLoop(const Value: boolean);
begin
  FLoop := value;
  if value=true then
  begin
     inc(FBits);
     If FBits > 15 then FBits:=0;
     If FBits=0 then
        begin FBitsChar:='0';
        FOutPutBitMem1:=false;FOutPutBitMem2:=false;FOutPutBitMem4:=false;FOutPutBitMem8:=false;
        invalidate;exit;end;
     If FBits=1 then
        begin FBitsChar:='1';
        FOutPutBitMem1:=true;FOutPutBitMem2:=false;FOutPutBitMem4:=false;FOutPutBitMem8:=false;
        invalidate;exit;end;
     If FBits=2 then
        begin FBitsChar:='2';
        FOutPutBitMem1:=false;FOutPutBitMem2:=true;FOutPutBitMem4:=false;FOutPutBitMem8:=false;
        invalidate;exit;end;
     If FBits=3 then
        begin FBitsChar:='3';
        FOutPutBitMem1:=true;FOutPutBitMem2:=true;FOutPutBitMem4:=false;FOutPutBitMem8:=false;
        invalidate;exit;end;
     If FBits=4 then
        begin FBitsChar:='4';
        FOutPutBitMem1:=false;FOutPutBitMem2:=false;FOutPutBitMem4:=true;FOutPutBitMem8:=false;
        invalidate;exit;end;
     If FBits=5 then
        begin FBitsChar:='5';
        FOutPutBitMem1:=true;FOutPutBitMem2:=false;FOutPutBitMem4:=true;FOutPutBitMem8:=false;
        invalidate;exit;end;
     If FBits=6 then
        begin FBitsChar:='6';
        FOutPutBitMem1:=false;FOutPutBitMem2:=true;FOutPutBitMem4:=true;FOutPutBitMem8:=false;
        invalidate;exit;end;
     If FBits=7 then
        begin FBitsChar:='7';
        FOutPutBitMem1:=true;FOutPutBitMem2:=true;FOutPutBitMem4:=true;FOutPutBitMem8:=false;
        invalidate;exit;end;
     If FBits=8 then
        begin FBitsChar:='8';
        FOutPutBitMem1:=false;FOutPutBitMem2:=false;FOutPutBitMem4:=false;FOutPutBitMem8:=true;
        invalidate;exit;end;
     If FBits=9 then
        begin FBitsChar:='9';
        FOutPutBitMem1:=true;FOutPutBitMem2:=false;FOutPutBitMem4:=false;FOutPutBitMem8:=true;
        invalidate;exit;end;
     If FBits=10 then
        begin FBitsChar:='A';
        FOutPutBitMem1:=false;FOutPutBitMem2:=true;FOutPutBitMem4:=false;FOutPutBitMem8:=true;
        invalidate;exit;end;
     If FBits=11 then
        begin FBitsChar:='B';
        FOutPutBitMem1:=true;FOutPutBitMem2:=true;FOutPutBitMem4:=false;FOutPutBitMem8:=true;
        invalidate;exit;end;
     If FBits=12 then
        begin FBitsChar:='C';
        FOutPutBitMem1:=false;FOutPutBitMem2:=false;FOutPutBitMem4:=true;FOutPutBitMem8:=true;
        invalidate;exit;end;
     If FBits=13 then
        begin FBitsChar:='D';
        FOutPutBitMem1:=true;FOutPutBitMem2:=false;FOutPutBitMem4:=true;FOutPutBitMem8:=true;
        invalidate;exit;end;
     If FBits=14 then
        begin FBitsChar:='E';
        FOutPutBitMem1:=false;FOutPutBitMem2:=true;FOutPutBitMem4:=true;FOutPutBitMem8:=true;
        invalidate;exit;end;
     If FBits=15 then
        begin FBitsChar:='F';
        FOutPutBitMem1:=true;FOutPutBitMem2:=true;FOutPutBitMem4:=true;FOutPutBitMem8:=true;
        invalidate;exit;end;
  end;
end;}


procedure TjanMemory.ButtonClick1(sender:TObject);
Begin
If FLock=true then
     FLock:=false else FLock:=true;
invalidate;
end;

procedure TjanMemory.ButtonClick3(sender:TObject);
Begin
If ShowHint=true then showHint:=false else showHint:=true;
end;

procedure TjanMemory.ButtonNClick(Sender: TObject);
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

procedure TjanMemory.ButtonClick4(sender:TObject); //selecteer
begin
 if Assigned(FBox) then
    FBox.SelectObject(Self);
end;



procedure TjanMemory.SetInfo(const Value: String);
begin
  if value<>FInfo then
  begin
    FInfo := Value;
 end;
end;

procedure TjanMemory.SetBits(const Value:Integer);
begin
  if value <> FBits then
  begin
     FBits := Value;
     If FBits=0 then
        begin FBitsChar:='0';FOutPutBitMem1:=false;FOutPutBitMem2:=false;FOutPutBitMem4:=false;FOutPutBitMem8:=false;end;
     If FBits=1 then
        begin FBitsChar:='1';FOutPutBitMem1:=true;FOutPutBitMem2:=false;FOutPutBitMem4:=false;FOutPutBitMem8:=false;end;
     If FBits=2 then
        begin FBitsChar:='2';FOutPutBitMem1:=false;FOutPutBitMem2:=true;FOutPutBitMem4:=false;FOutPutBitMem8:=false;end;
     If FBits=3 then
        begin FBitsChar:='3';FOutPutBitMem1:=true;FOutPutBitMem2:=true;FOutPutBitMem4:=false;FOutPutBitMem8:=false;end;
     If FBits=4 then
        begin FBitsChar:='4';FOutPutBitMem1:=false;FOutPutBitMem2:=false;FOutPutBitMem4:=true;FOutPutBitMem8:=false;end;
     If FBits=5 then
        begin FBitsChar:='5';FOutPutBitMem1:=true;FOutPutBitMem2:=false;FOutPutBitMem4:=true;FOutPutBitMem8:=false;end;
     If FBits=6 then
        begin FBitsChar:='6';FOutPutBitMem1:=false;FOutPutBitMem2:=true;FOutPutBitMem4:=true;FOutPutBitMem8:=false;end;
     If FBits=7 then
        begin FBitsChar:='7';FOutPutBitMem1:=true;FOutPutBitMem2:=true;FOutPutBitMem4:=true;FOutPutBitMem8:=false;end;
     If FBits=8 then
        begin FBitsChar:='8';FOutPutBitMem1:=false;FOutPutBitMem2:=false;FOutPutBitMem4:=false;FOutPutBitMem8:=true;end;
     If FBits=9 then
        begin FBitsChar:='9';FOutPutBitMem1:=true;FOutPutBitMem2:=false;FOutPutBitMem4:=false;FOutPutBitMem8:=true;end;
     If FBits=10 then
        begin FBitsChar:='A';FOutPutBitMem1:=false;FOutPutBitMem2:=true;FOutPutBitMem4:=false;FOutPutBitMem8:=true;end;
     If FBits=11 then
        begin FBitsChar:='B';FOutPutBitMem1:=true;FOutPutBitMem2:=true;FOutPutBitMem4:=false;FOutPutBitMem8:=true;end;
     If FBits=12 then
        begin FBitsChar:='C';FOutPutBitMem1:=false;FOutPutBitMem2:=false;FOutPutBitMem4:=true;FOutPutBitMem8:=true;end;
     If FBits=13 then
        begin FBitsChar:='D';FOutPutBitMem1:=true;FOutPutBitMem2:=false;FOutPutBitMem4:=true;FOutPutBitMem8:=true;end;
     If FBits=14 then
        begin FBitsChar:='E';FOutPutBitMem1:=false;FOutPutBitMem2:=true;FOutPutBitMem4:=true;FOutPutBitMem8:=true;end;
     If FBits=15 then
        begin FBitsChar:='F';FOutPutBitMem1:=true;FOutPutBitMem2:=true;FOutPutBitMem4:=true;FOutPutBitMem8:=true;end;
     if schrijf=true then
      begin
       schrijf:=false;
       Lijst.Strings[Adress]:=IntToStr(Value);
      end;
     If (schrijf=false) then FBits:= StrToInt(Lijst.Strings[FAdress]);
  end;
invalidate;
end;

procedure TjanMemory.SetAdress(const Value:Integer);
begin
// Value is het adres van A1..A8 (0..15); met A16 aan komt er 16 bij
FAdress := Value mod 16;
if FDown=true then FAdress:=FAdress + 16;
If (schrijf=false) then Bits:= StrToInt(Lijst.Strings[FAdress]);
invalidate;
end;

procedure TjanMemory.SetBitsChar(const Value:Char);
begin
  if value <> FBitsChar then
  begin
    FBitsChar := Value;
 end;
invalidate;
end;




procedure TjanMemory.SendStatusToBar;//xxx
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

procedure TjanMemory.SetNaam(const Value: String);//xxxx
Begin
  if FNaam <> Value then
  begin
    FNaam := Value;
    Invalidate;
    // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
  end;
end;

procedure TjanMemory.SetTaal(const Value: String);
begin
  if value<>FTaal then
  begin
    FTaal:= Value;
 end;
 if value='NL' then FInfo:='Geheugenblok'
 else if value='ENG' then FInfo:='Memory block'
 else if value='FR' then FInfo:= 'Bloc mémoire'
 else if value='DU' then FInfo:= 'Speicherblock';
invalidate;
// ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
end;

procedure TjanMemory.SetDown(const Value: boolean);
var
a1,a2,a4,a8:integer;
begin
  if value<>FDown then
  begin
   FDown := Value;
   FDepressed:=value;

   // A16: bovenste helft (16..31) of onderste helft (0..15) van het geheugen;
   // daarna meteen de inhoud van het nieuwe adres tonen
   if FDown then FAdress := (FAdress mod 16) + 16
   else FAdress := FAdress mod 16;
   if (schrijf=false) then Bits := StrToInt(Lijst.Strings[FAdress]);

   If FDown=true then FStatMemB := stMemButtonStop else FStatMemB := stMemButtonStart;
   invalidate;
  end;

 if Assigned(OnMemButtonChange) then OnMemButtonChange(Self, StatMemB);
  // ✅ Onmiddellijke refresh als muis erboven staat
    if FMouseOver then
      SendStatusToBar;
end;
procedure TjanMemory.SetA1(const Value: boolean);
begin
   If value=true then FA1 := true else FA1:=false;
   getadress;
   invalidate;
end;
procedure TjanMemory.SetA2(const Value: boolean);
begin
  If value=true then FA2 := true else FA2:=false;
  getadress;
   invalidate;
end;
procedure TjanMemory.SetA4(const Value: boolean);
begin
  If value=true then FA4 := true else FA4:=false;
   getadress;
   invalidate;
end;
procedure TjanMemory.SetA8(const Value: boolean);
begin
  If value=true then FA8 := true else FA8:=false;
   getadress;
   invalidate;
end;
procedure TjanMemory.SetConnector(const Value: boolean);
begin
  if value<>FConnector then
  begin
   FConnector := Value;
   invalidate;
  end;
end;

procedure TjanMemory.SetLock(const Value: boolean);
begin
  if value<>FLock then
  begin
    FLock := Value;
 end;
end;

{Procedure TjanMemory.SetLijst(const Value: TStrings);
begin
  if lijst <> value
  then
  begin
  lijst:=value;
  invalidate;
  end;
end;}

procedure TjanMemory.SetInputMem3(const Value: boolean);
begin
  if value<>FInputMem3 then
  begin
    FInputMem3 := Value;
    invalidate;
  end;
end;



procedure TjanMemory.SetOutPutMemDisplay(const Value: boolean);
begin
  if value <> FOutputDisplay then
  begin
    FOutPutDisplay := Value;
  end;
invalidate;
end;
procedure TjanMemory.SetOutPutMemBit1(const Value: boolean);
begin
  if value <> FOutputBitMem1 then
  begin
    FOutPutBitMem1 := Value;
  end;

end;
procedure TjanMemory.SetOutPutMemBit2(const Value: boolean);
begin
  if value <> FOutputBitMem2 then
  begin
    FOutPutBitMem2 := Value;
  end;

end;
procedure TjanMemory.SetOutPutMemBit4(const Value: boolean);
begin
  if value <> FOutputBitMem4 then
  begin
    FOutPutBitMem4 := Value;
  end;

end;
procedure TjanMemory.SetOutPutMemBit8(const Value: boolean);
begin
  if value <> FOutputBitMem8 then
  begin
    FOutPutBitMem8 := Value;
  end;
end;


procedure TjanMemory.SetPColor(const Value: TColor);
begin
  if value<>FPcolor then
  begin
    FPcolor := Value;
    invalidate;
  end;
end;
procedure TjanMemory.SetLedColUit(const Value: TColor);
begin
  if value<>FLedColUit then
  begin
    FLedColUit := Value;
    invalidate;
  end;
end;

procedure TjanMemory.SetLedColAan(const Value: TColor);
begin
  if value<>FLedColAan then
  begin
    FLedColAan := Value;
    invalidate;
  end;
end;
