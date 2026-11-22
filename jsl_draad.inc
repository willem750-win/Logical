// janSimLogic.pas, deel: draad: tekenen, slepen, opruimen (ingevoegd met {$I jsl_draad.inc})


{ TjanConnector }

constructor TjanConnector.Create(AOwner: TComponent);
var
i:integer;
begin
   inherited Create(AOwner);
   width:=60;
   height:=8;
   mode:=jcmTL;
   shape:=jcsTLBR;
   conPos:=jcpTL;
   W_Conmode:='jcmTL';
   W_Conshape:='jcsTLBR';
   W_ConPos:='jcpTL';
   conSize:=8;
   Edge:=0.5;
   S_Edge:='0,5';
   FPower:=false;
   Ledd:=0;
   VAdres:=0;
   For i:= 0 to 15 do Tmemlist[i]:=0;
   TSchrijf:=false;
   FLock:=false;
   Hit:=false;
   select:=false;
  // FNaam:='Draad';
   //FTaal:='NL';
end;

destructor TjanConnector.Destroy;
begin
  // geen verwijzing laten staan naar een draad die weg is
  if (DraadBox <> nil) and (DraadBox.SelectedSender = Self) then
    DraadBox.ClearSelectedSender;
  if ElektronDraden <> nil then
  begin
    ElektronDraden.Remove(Self);
    if (ElektronDraden.Count = 0) and (ElektronTimer <> nil) then
      ElektronTimer.Enabled := False;
  end;
  inherited Destroy;
end;

procedure TjanConnector.SetStroomA(AI: Double);
var
  Aan, WasAan: Boolean;
begin
  WasAan := Abs(FStroomA) > ElektronMinA;
  FStroomA := AI;
  Aan := Abs(AI) > ElektronMinA;
  if Aan = WasAan then Exit;
  ElektronLijst(Self, Aan);
  Invalidate;
end;

// Elektronen langs de draad. De (conventionele) stroom gaat van het begin
// naar het einde; de elektronen schuiven de andere kant op, van - naar +.
// Hoe meer stroom, hoe sneller (100 mA: 40 pixels per seconde).
// de weg van de draad (4 punten, lokaal), van het begin (APi) naar het einde
procedure TjanConnector.ElektronWeg(out Pt: array of TPoint);
var
  d2, w2, xw, yh: Integer;
begin
  d2 := conSize div 2;
  w2 := Round(Edge * Width);
  xw := Width - 1;
  yh := Height - 1;
  case conPos of
    jcpTL: begin Pt[0] := Point(d2, d2); Pt[1] := Point(w2, d2); Pt[2] := Point(w2, yh - d2); Pt[3] := Point(xw - d2, yh - d2); end;
    jcpBR: begin Pt[0] := Point(xw - d2, yh - d2); Pt[1] := Point(xw - d2, d2); Pt[2] := Pt[1]; Pt[3] := Point(d2, d2); end;
    jcpTR: begin Pt[0] := Point(xw - d2, d2); Pt[1] := Point(xw - d2, yh - d2); Pt[2] := Pt[1]; Pt[3] := Point(d2, yh - d2); end;
  else     begin Pt[0] := Point(d2, yh - d2); Pt[1] := Point(w2, yh - d2); Pt[2] := Point(w2, d2); Pt[3] := Point(xw - d2, d2); end;
  end;
end;

procedure TjanConnector.InvalidateElektronen;
var
  Pt: array[0..3] of TPoint;
  k: Integer;
  R: TRect;
begin
  if (Parent = nil) or not Parent.HandleAllocated then Exit;
  ElektronWeg(Pt);
  for k := 0 to 2 do
  begin
    R.Left := Left + KleinsteI(Pt[k].X, Pt[k + 1].X) - 4;
    R.Right := Left + GrootsteI(Pt[k].X, Pt[k + 1].X) + 5;
    R.Top := Top + KleinsteI(Pt[k].Y, Pt[k + 1].Y) - 4;
    R.Bottom := Top + GrootsteI(Pt[k].Y, Pt[k + 1].Y) + 5;
    InvalidateRect(Parent.Handle, @R, False);
  end;
end;

procedure TjanConnector.PaintElektronen;
var
  k, j: Integer;
  Pt: array[0..3] of TPoint;
  Len: array[0..2] of Double;
  Tot, Ph, S, F: Double;
  X, Y: Integer;
begin
  if Abs(FStroomA) <= ElektronMinA then Exit;
  // zelfde weg als in Paint, van het begin (APi) naar het einde (APo)
  ElektronWeg(Pt);
  Tot := 0;
  for k := 0 to 2 do
  begin
    Len[k] := Abs(Pt[k + 1].X - Pt[k].X) + Abs(Pt[k + 1].Y - Pt[k].Y);
    Tot := Tot + Len[k];
  end;
  if Tot < 1 then Exit;
  // stroom van begin naar einde: elektronen van einde naar begin
  Ph := ElektronFase(FStroomA);
  with Canvas do
  begin
    Pen.Width := 1;
    Pen.Color := RGBToColor(31, 95, 191);
    Brush.Style := bsSolid;
    Brush.Color := RGBToColor(31, 95, 191);
    S := Ph;
    while S < Tot do
    begin
      F := S;
      j := 0;
      while (j < 2) and (F > Len[j]) do
      begin
        F := F - Len[j];
        Inc(j);
      end;
      if Len[j] > 0 then F := F / Len[j] else F := 0;
      if F > 1 then F := 1;
      X := Pt[j].X + Round((Pt[j + 1].X - Pt[j].X) * F);
      Y := Pt[j].Y + Round((Pt[j + 1].Y - Pt[j].Y) * F);
      Ellipse(X - 2, Y - 2, X + 3, Y + 3);
      S := S + ElektronAfstand;
    end;
  end;
end;

procedure TjanConnector.DoMouseDown(x,y:integer);
var p:Tpoint;
    Rtl,Rbr,Rtr,Rbl:TRect;
    d:integer;
begin
  doMove:=false;
  doEdge:=false;
  d:=conSize;
  oldp:=point(x,y);
  Rtl:=rect(0,0,d,d);
  Rbr:=rect(width-1-d,height-1-d,width-1,height-1);
  Rtr:=rect(width-1-d,0,width-1,d);
  Rbl:=rect(0,height-1-d,d,height-1);
  p:=point(x,y);
  if ptinrect(Rtl,p)and (shape=jcsTLBR) then
  begin
    //showMessage('jcsTLBR');
    mode:=jcmTL;S_Mode:= 'jcmTL';
    mdp:=point(x,y);
  end
  else if ptinrect(Rtr,p) and (shape=jcsTRBL) then
  begin
    //showMessage('jcsTRBL');
    mode:=jcmTR;S_mode:='jcmTR';
    mdp:=point(width-x,y);
  end
  else if ptinrect(Rbr,p) and (shape=jcsTLBR) then
  begin
    //showMessage('jcsBR');
    mode:=jcmBR; S_mode:='jcmBR';
    mdp:=point(width-x,height-y);
  end
  else if ptinrect(Rbl,p) and (shape=jcsTRBL) then
  begin
    //showMessage('jcsTRBL');
    mode:=jcmBL; S_mode:='jcmBL';
    mdp:=point(x,height-y);
  end
  else if (abs(x-round(Edge*width))<10) then
  begin
    doEdge:=true;
  end
  else
  begin
    doMove:=true;
    mdp:=point(x,y);
    SetFromLogic(nil);
    SetToLogic(nil);
  end;
  if not doEdge then
    DisConnect;
end;


procedure TjanConnector.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  p: TPoint;
  T: string;
  mi: TMenuItem;
begin
  // rechtsklik: menu om de draad te selecteren (dan verwijdert de knop
  // Verwijderen alleen deze draad) of meteen te verwijderen
  if Button = mbRight then
  begin
    if FLock then Exit;
    if DraadBox <> nil then T := StatTaalToBTaal(DraadBox.Language) else T := 'NL';
    if FPopup = nil then FPopup := TPopupMenu.Create(Self);
    FPopup.Items.Clear;
    mi := TMenuItem.Create(FPopup);
    if FSelected then
      mi.Caption := Tr(T, 'Draad deselecteren', 'Deselect wire', 'Désélectionner le fil', 'Draht abwählen')
    else
      mi.Caption := Tr(T, 'Draad selecteren', 'Select wire', 'Sélectionner le fil', 'Draht auswählen');
    mi.OnClick := DraadSelectClick;
    FPopup.Items.Add(mi);
    mi := TMenuItem.Create(FPopup);
    mi.Caption := Tr(T, 'Draad verwijderen', 'Delete wire', 'Supprimer le fil', 'Draht löschen');
    mi.OnClick := DraadVerwijderClick;
    FPopup.Items.Add(mi);
    p := ClientToScreen(Point(X, Y));
    FPopup.Popup(p.X, p.Y);
    Exit;
  end;
  // klik op een horizontaal stuk van de draad: draad (de)selecteren, niet
  // verslepen (slepen blijft aan de uiteinden en aan de knik)
  if (Button = mbLeft) and (Screen.Cursor <> crDraad) and InLijnStrook(X, Y) then
  begin
    FKlikSelect := True;
    DraadSelectClick(Self);
    Exit;
  end;
  // met de knop Verbinding op een blokje dat op een klem van de voedingskring
  // ligt: een NIEUWE draad op die klem beginnen (zo kan je meerdere draden
  // op dezelfde klem zetten) in plaats van deze draad te verslepen
  if (Button = mbLeft) and (Screen.Cursor = crDraad) and (Parent <> nil) then
    if StartWireOnPin(Point(Left + X, Top + Y)) then
      Exit;
  DoMouseDown(x,y);


end;

procedure TjanConnector.SetSelected(const Value: Boolean);
begin
  if FSelected = Value then Exit;
  FSelected := Value;
  Invalidate;
end;

procedure TjanConnector.DraadSelectClick(Sender: TObject);
begin
  // zelfde werking als bij de onderdelen: nog eens kiezen = deselecteren
  if DraadBox <> nil then DraadBox.SelectObject(Self);
end;

procedure DraadVrijgeven(Data: PtrInt);
begin
  TObject(Data).Free;
end;

type
  TDraadOpruimer = class
    procedure Vrij(Data: PtrInt);
  end;

procedure TDraadOpruimer.Vrij(Data: PtrInt);
begin
  DraadVrijgeven(Data);
end;

var
  DraadOpruimer: TDraadOpruimer = nil;

procedure TjanConnector.DraadVerwijderClick(Sender: TObject);
begin
  if (DraadBox <> nil) and (DraadBox.SelectedSender = Self) then
    DraadBox.SelectObject(Self);      // selectie eraf (knop Verwijderen uit)
  Losmaken;
  Visible := False;
  // pas vrijgeven na het menu (niet binnen de eigen klik)
  if DraadOpruimer = nil then DraadOpruimer := TDraadOpruimer.Create;
  Application.QueueAsyncCall(DraadOpruimer.Vrij, PtrInt(Self));
end;

procedure TjanConnector.Losmaken;
var W: TWinControl;
begin
  W := Parent;
  if W = nil then Exit;
  // zoekt de ingang aan het einde van de draad en zet die uit
  DisConnect;
  DisConnectFinal;
  W.Invalidate;
end;

function TjanConnector.StartWireOnPin(const P: TPoint): Boolean;
var
  i, K: Integer;
  D: TjanVoedingsDeel;
  Pt: TPoint;
begin
  Result := False;
  for i := Parent.ControlCount - 1 downto 0 do
    if (Parent.Controls[i] is TjanVoedingsDeel) and Parent.Controls[i].Visible then
    begin
      D := TjanVoedingsDeel(Parent.Controls[i]);
      K := D.PinAt(P);
      if K < 0 then continue;
      Pt := D.PinCenter(K);
      Maakdraad(Pt.Y - 4, Pt.X - 4, Parent);
      movecursor;
      Exit(True);
    end;
end;


procedure TjanConnector.DoMouseMove(dx,dy:integer);
var
    p:Tpoint;
    d,d2,nw,nh:integer;
    x,y:integer;
begin
   x:=dx+oldp.x;
   y:=dy+oldp.y;
   oldp:=point(x,y);
   p:=clienttoscreen(point(x,y));
   p:=parent.ScreenToClient(p);
   d:=conSize;
   d2:= d div 2;
   if doEdge then
   begin
     Edge := x / width;S_Edge :=Format('%.2n', [Edge]);
     invalidate;
   end
   else if doMove then
   begin
     left:=p.x-mdp.x;
     top:=p.y-mdp.y;
   end
   else
   begin
      case mode of
      jcmTL:
      begin
        left:=p.x-mdp.x;
        top:=p.y-mdp.y;
        nw:=width+(mdp.x-X);
        if nw<d2 then
        begin
          left:=left+nw-d;
          width:=-nw+d+d;
          mode:=jcmTR;S_mode:='jcmTR';
          shape:=jcsTRBL; S_shape:='jcsTRBL';
          case conPos of
            jcpTL: begin conPos:=jcpTR;S_Pos:='jcpTR';end;
            jcpBR: begin conPos:=jcpBL;S_Pos:='jcpBL';end;
          end;
          Edge:=1-Edge;S_Edge :=Format('%.2n', [Edge]);
        end
        else
          width:=nw;
        nh:=height+(mdp.y-Y);
        if nh<d2 then
        begin
          top:=top+nh-d;
          height:=-nh+d+d;
          mode:=jcmBL;  S_mode:='jcmBL';
          shape:=jcsTRBL;S_shape:='jcsTRBL';
          case conPos of
            jcpTL: begin conPos:=jcpBL;S_Pos:='jcpBL'; end;
            jcpBR: begin conPos:=jcpTR;S_Pos:='jcpTR'; end;
          end;
        end
        else
         height:=nh;
      end;
      jcmTR:
      begin
        top:=p.y-mdp.y;
        nw:=X+mdp.x;
        if nw<d2 then
        begin
          left:=left+nw-d;
          width:=-nw+d+d;
          mode:=jcmTL; S_mode:='jcmTL';
          shape:=jcsTLBR;S_shape:='jcsTLBR';
          case conPos of
            jcpTR: begin conPos:=jcpTL;S_Pos:='jcpTL';end;
            jcpBL: begin conPos:=jcpBR;S_Pos:='jcpBR';end;
          end;
          Edge:=1-Edge;S_Edge :=Format('%.2n', [Edge]);
        end
        else
         width:=nw;
        nh:=height+(mdp.y-Y);
        if nh<d2 then
        begin
          top:=top+nh-d;
          height:=-nh+d+d;
          mode:=jcmBR;S_mode:='jcmBR';
          shape:=jcsTLBR;S_shape:='jcsTLBR';
          case conPos of
            jcpTR: begin conPos:=jcpBR;S_Pos:='jcpBR';end;
            jcpBL: begin conPos:=jcpTL;S_Pos:='jcpTL';end;
          end;
        end
        else
          height:=nh;
      end;
      jcmBR:
      begin
        nw:=X+mdp.x;
        if nw<d2 then
        begin
          left:=left+nw-d;
          width:=-nw+d+d;
          mode:=jcmBL;S_mode:='jcmBL';
          shape:=jcsTRBL;S_shape:='jcsTRBL';
          case conPos of
            jcpBR: begin conPos:=jcpBL; S_Pos:='jcpBL'; end;
            jcpTL: begin conPos:=jcpTR; S_Pos:='jcpTR'; end;
          end;
          Edge:=1-Edge;S_Edge :=Format('%.2n', [Edge]);
        end
        else
         width:=nw;
        nh:=Y+mdp.y;
        if nh<d2 then
        begin
          top:=top+nh-d;
          height:=-nh+d+d;
          mode:=jcmTR; S_mode:='jcmTR';
          shape:=jcsTRBL;S_shape:='jcsTRBL';
          case conPos of
            jcpBR: begin conPos:=jcpTR;S_Pos:='jcpTR';end;
            jcpTL: begin conPos:=jcpBL;S_Pos:='jcpBL';end;
          end;
        end
        else
          height:=nh;
      end;
      jcmBL:
      begin
        left:=p.x-mdp.x;
        nw:=width+(mdp.x-x);
        if nw<d2 then
        begin
          left:=left+nw-d;
          width:=-nw+d+d;
          mode:=jcmBR;S_mode:='jcmBR';
          shape:=jcsTLBR;S_shape:='jcsTLBR';
          case conPos of
            jcpBL: begin conPos:=jcpBR;S_Pos:='jcpBR';end;
            jcpTR: begin conPos:=jcpTL;S_Pos:='jcpTL';end;
          end;
          Edge:=1-Edge;S_Edge :=Format('%.2n', [Edge]);
        end
        else
          width:=nw;
        nh:=Y+mdp.y;
        if nh<d2 then
        begin
          top:=top+nh-d;
          height:=-nh+d+d;
          mode:=jcmTL; S_mode:='jcmTL';
          shape:=jcsTLBR; S_shape:='jcsTLBR';
          case conPos of
             jcpBL: begin conPos:=jcpTL; S_Pos:='jcpTL';end;
             jcpTR: begin conPos:=jcpBR; S_Pos:='jcpBR';end;
          end;
        end
        else
          height:=nh;
      end;
      end;
   end;
end;

procedure TjanConnector.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
   if (ssleft in shift) and not FKlikSelect then
   begin

     doMouseMove(x-oldp.x,y-oldp.y);
   end;
end;


procedure TjanConnector.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
// rechtsklik opent alleen het menu, een klik op de draad selecteert alleen:
// de draad is niet versleept
if Button = mbRight then Exit;
if FKlikSelect then
begin
  FKlikSelect := False;
  Exit;
end;
// uiteinde losgelaten vlak bij een ingang: exact op die ingang zetten
if (not doEdge) and (not doMove) then
    SnapEndToInput;
if not doEdge then
    DisConnectFinal;
    //SendToBack;
    select:=false;invalidate;
// voedingsbolletjes bijwerken (een voedingsdraad kan aan- of losgekoppeld zijn)
if Parent<>nil then
  Parent.Invalidate;
end;

procedure TjanConnector.DisConnectFinal;
begin
  if DisCon=nil then exit;
  if (DisCon is TjanLogicRun) then
  begin
    TjanLogicRun(DisCon).SetInput(DisConI-1, false);
  end
  else if (DisCon is TjanSimMotor) then
  begin
    TjanSimMotor(DisCon).SetInput(DisConI-1, false);
  end
  else if (DisCon is TjanSimStappenteller) then
  begin
    TjanSimStappenteller(DisCon).SetInput(DisConI-1, false);
  end
  else if (DisCon is TjanSimPersoon) then
  begin
    TjanSimPersoon(DisCon).SetInput(DisConI-1, false);
  end
  else if (Discon is TjanSimLight) then
  begin
    TjanSimLight(Discon).lit:=false;
  end
  else if (Discon is TjanDipSwitsh) then
  begin
    TjanDipSwitsh(Discon).Down:=false;
  end
  else if (Discon is TjanDisplay) then
  begin
    TjanDisplay(Discon).digit:='0';
  end
  else if (Discon is TjanSimRelais) then
  begin
    TjanSimRelais(Discon).lit:=false;
  end
  else if (Discon is TjanSimBuzzer) then
  begin
    TjanSimBuzzer(Discon).lit:=false;
  end
  else if (Discon is TjanMeter) then
  begin
    if DisConI=1 then
      begin TjanMeter(DisCon).input1:=false; TjanMeter(DisCon).PlusVolt:=0; end
    else if DisConI=3 then
      begin TjanMeter(DisCon).input3:=false; TjanMeter(DisCon).MinVolt:=0; end
  end
  else if (DisCon is TjanTeller) then
  begin
    if DisConI=1 then
      TjanTeller(DisCon).reset:=true
    else if DisConI=3 then
      TjanTeller(DisCon).reset:=true
  end
  else if (DisCon is TjanMemory) then
  begin
    if DisConI=1 then
      TjanMemory(DisCon).reset:=true
    else if DisConI=3 then
      TjanMemory(DisCon).reset:=true
  end
  else if (DisCon is TjanLogic) then
  begin
    if DisConI=1 then
      TjanLogic(DisCon).input1:=false
    else if DisConI=2 then
      TjanLogic(DisCon).input2:=false
    else if DisConI=3 then
      TjanLogic(DisCon).input3:=false
  end;
end;

procedure TjanConnector.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  if (operation=opremove) and (AComponent=FFromLogic) then
    SetFromLogic(nil);
  if (operation=opremove) and (AComponent=FToLogic) then
    SetToLogic(nil);
end;

procedure TjanConnector.draadClick(sender:TObject);
Begin
  disconnectFinal;
  free;
end;

procedure TjanConnector.Paint;
var
  d, d2, w2, xw, yh: Integer;
  R: TRect;
  EndA, EndB: TPoint;
  MinWire: Boolean;
  Dik: array[0..3] of TPoint;
begin
  d  := conSize;
  d2 := d div 2;
  w2 := Round(Edge * Width);
  xw := Width - 1;
  yh := Height - 1;

  // voedingsdraad naar de - rail: blauw, zoals de rail
  MinWire := False;
  if Parent <> nil then
  begin
    EndCenters(EndA, EndB);
    MinWire := ((RailAtPoint(Parent, EndA) <> nil) and not RailAtPoint(Parent, EndA).Plus) or
               ((RailAtPoint(Parent, EndB) <> nil) and not RailAtPoint(Parent, EndB).Plus);
  end;

  with Canvas do
  begin
    Lock;
    try
      Brush.Color := clLime;
      if FPower = True then
        Pen.Color := clRed
      else if MinWire then
        Pen.Color := clBlue
      else
        Pen.Color := clBlack;
      // de draad dikker tekenen, in zijn eigen kleur: 3 pixels als de muis
      // erop staat, 5 pixels als hij geselecteerd is
      if Select or FSelected then
      begin
        ElektronWeg(Dik);
        Pen.Style := psSolid;
        if FSelected then Pen.Width := 5 else Pen.Width := 3;
        Polyline(Dik);
        Pen.Width := 1;
      end;
      case Shape of
        jcsTLBR:
          begin
            case conPos of
              jcpTL:
                begin
                  MoveTo(d, d2);
                  LineTo(w2, d2);
                  LineTo(w2, yh - d2);
                  LineTo(xw - d, yh - d2);

                  if (FLock = False) and (yh > 20) and (xw > 20) and (hit = True) then
                  begin
                    Brush.Style := bsSolid;
                    Brush.Color := clWhite;
                    Ellipse(w2 - 4, (yh div 2) - 4, w2 + 4, (yh div 2) + 4);
                  end;

                  Brush.Style := bsClear;
                  Rectangle(0, 0, d, d);

                  Brush.Style := bsSolid;
                  Brush.Color := clLime;
                  Rectangle(xw - d, yh - d, xw, yh);
                end;

              jcpBR:
                begin
                  MoveTo(d, d2);
                  LineTo(xw - d2, d2);
                  LineTo(xw - d2, yh - d);

                  Brush.Color := clLime;
                  Rectangle(0, 0, d, d);

                  Brush.Style := bsClear;
                  Rectangle(xw - d, yh - d, xw, yh);

                  Brush.Style := bsSolid;
                end;
            end;
          end;

        jcsTRBL:
          begin
            case conPos of
              jcpTR:
                begin
                  MoveTo(xw - d2, d);
                  LineTo(xw - d2, yh - d2);
                  LineTo(d, yh - d2);

                  Brush.Style := bsClear;
                  Rectangle(xw - d, 0, xw, d);

                  Brush.Style := bsSolid;
                  Brush.Color := clLime;
                  Rectangle(0, yh - d, d, yh);
                end;

              jcpBL:
                begin
                  MoveTo(xw - d, d2);
                  LineTo(w2, d2);
                  LineTo(w2, yh - d2);
                  LineTo(d - 1, yh - d2);

                  if (FLock = False) and (yh > 20) and (xw > 20) and (hit = True) then
                  begin
                    Brush.Style := bsSolid;
                    Brush.Color := clWhite;
                    Ellipse(w2 - 4, (yh div 2) - 4, w2 + 4, (yh div 2) + 4);
                  end;

                  Brush.Color := clLime;
                  Rectangle(xw - d, 0, xw, d);

                  Brush.Style := bsClear;
                  Rectangle(0, yh - d, d, yh);

                  Brush.Style := bsSolid;
                end;
            end;
          end;
      end; // case Shape

      PaintElektronen;

      // -----------------------------
      // Selectiekader ALS LAATSTE
      // -----------------------------
      // (muis erop of geselecteerd: de draad is bovenaan dikker getekend)

    finally
      Unlock;
    end;
  end;
end;


{
procedure TjanConnector.paint;
var
    d,d2,w2,xw,yh:integer;
    R:TRect;
begin
  d:=conSize;
  d2:=d div 2;
  w2:=round(Edge * width);
  xw:=width-1;
  yh:=height-1;
  with canvas do
  begin
  Lock;
  brush.color:=cllime;
  if FPower=true then Pen.Color:=clred else Pen.Color:=clblack;
  case shape of
  jcsTLBR:
    begin
      case conPos of
        jcpTL: // draw regular connector
        begin
          moveto(d,d2);
          lineto(w2,d2);
          lineto(w2,yh-d2);
          lineto(xw-d,yh-d2);
          if (FLock=false)  and (yh > 20) and (xw > 20) and (hit=true) then
           begin
           brush.Style:=bsSolid;
           brush.color:=clWhite;
           Ellipse(w2-4,(yh div 2)-4,w2+4,(yh div 2)+4);
           end;
          brush.Style:=bsClear;
          rectangle(0,0,d,d);
          brush.Style:=bsSolid;
          brush.color:=clLime;
          rectangle(xw-d,yh-d,xw,yh);
        end;
        jcpBR:
        begin
          moveto(d,d2);
          lineto(xw-d2,d2);
          lineto(xw-d2,yh-d);
          brush.color:=clLime;
          rectangle(0,0,d,d);
          brush.Style:=bsClear;
          rectangle(xw-d,yh-d,xw,yh);
          brush.Style:=bsSolid;
        end;
      end;
    end;
  jcsTRBL:
    begin
      case conPos of
        jcpTR: // draw reverted connector
        begin
          moveto(xw-d2,d);
          lineto(xw-d2,yh-d2);
          lineto(d,yh-d2);
          brush.Style:=bsClear;
          rectangle(xw-d,0,xw,d);
          brush.Style:=bsSolid;
          brush.color:=clLime;
          rectangle(0,yh-d,d,yh);
        end;
        jcpBL: // draw regular connector
        begin
          moveto(xw-d,d2);
          lineto(w2,d2);
          lineto(w2,yh-d2);
          lineto(d-1,yh-d2);
          if (FLock=false) and (yh > 20) and (xw > 20)and( hit=true) then
           begin
           brush.Style:=bsSolid;
           brush.color:=clWhite;
           Ellipse(w2-4,(yh div 2)-4,w2+4,(yh div 2)+4);
           end;
          brush.color:=clLime;
          rectangle(xw-d,0,xw,d);
          brush.Style:=bsClear;
          rectangle(0,yh-d,d,yh);
          brush.Style:=bsSolid;
        end;
      end;
    end;
  end; // case
  unlock;

end; //canvas
end;}

procedure TjanConnector.SetFromGate(const Value: integer);
begin
  FFromGate := Value;
end;

procedure TjanConnector.SetFromLogic(const Value: TjanLogic);
begin
  FFromLogic := Value;
end;

procedure TjanConnector.SetToGate(const Value: integer);
begin
  FToGate := Value;
end;

procedure TjanConnector.SetPower(const Value: Boolean);
begin
  if power <> value then invalidate;
  Fpower := Value;
end;

procedure TjanConnector.SetLock(const Value: boolean);
begin
  if value<>FLock then
  begin
    FLock := Value;
    // vergrendeld (simulatie): geen achtergebleven markering van de muis
    if FLock and Select then
    begin
      Select := False;
      Invalidate;
    end;
  end;
end;

procedure TjanConnector.SetS_mode(Value: string);
begin
  S_mode := Value;
  invalidate;
end;
procedure TjanConnector.SetS_Edge(Value: string);
begin
  S_Edge := Value;
invalidate;
end;
procedure TjanConnector.SetS_Pos(Value: string);
begin
  S_Pos := Value;
  invalidate;
end;
procedure TjanConnector.SetS_Shape(Value: string);
begin
  S_Shape := Value;
  invalidate;
end;


procedure TjanConnector.Setjanconmode(Value: TjanConMode);
begin
  mode := Value;
  case Mode of
        jcmTL:
        begin S_Mode:='jcmTL'end;
        jcmBR:
        begin S_Mode:='jcmBR'end;
        jcmBL:
        begin S_Mode:='jcmBL'end;
        jcmTR:
        begin S_Mode:='jcmTR'end;
      end;
  invalidate;
end;
procedure TjanConnector.Setjanconpos(Value: TjanConpos);
begin
  ConPos := Value;
  case ConPos of
        jcpTL:
        begin S_Pos:='jcpTL'end;
        jcpBR:
        begin S_Pos:='jcpBR'end;
        jcpBL:
        begin S_Pos:='jcpBL'end;
        jcpTR:
        begin S_Pos:='jcpTR'end;
      end;
  invalidate;
end;
procedure TjanConnector.SetjanconShape(Value: TjanConShape);
begin
  shape := Value;
  case Shape of
        jcsTLBR:
        begin S_Shape:='jcsTLBR'end;
        jcsTRBL:
        begin S_Shape:='jcsTRBL'end;
      end;
  invalidate;
end;

procedure TjanConnector.SetjanEdge(Value: extended);
begin
  Edge := Value;
  S_Edge:=Format('%.2n', [Edge]);
  invalidate;
end;
procedure TjanConnector.SetToLogic(const Value: TjanLogic);
begin
  FToLogic := Value;
end;

procedure TjanConnector.SetToTeller(const Value: TjanTeller);
begin
  FToTeller := Value;
end;
procedure TjanConnector.SetFromPoint(const Value: TPoint);
begin
  FFromPoint := Value;
end;

procedure TjanConnector.SetToPoint(const Value: TPoint);
begin
  FToPoint := Value;
end;
{
procedure TjanConnector.CMHitTest(var Msg: TCMHitTest);
var
RegLB,RegLO,RegRO,RegRB,RegM:HRGN;
w2 : Integer;
begin
   //if FLock=true then exit;
   w2:=round(Edge * width);
   RegLB:=CreateRectRgn(1,1,9,9);
   RegLO:=CreateRectRgn(1,height-9,9,height-1);
   RegM:=CreateRectRgn(w2- 2,0,w2 + 2,height);
   RegRO:=CreateRectRgn(width - 9,height-1,width-1,height - 9);
   RegRB:=CreateRectRgn(width - 9,1,width-1,9);
   Msg.Result := HTNOWHERE;
 with Msg do
    Begin
    if Canvas.Pixels[XPos,YPos] = clWhite then Result := HTCLIENT;
    if PtInRegion(RegLB, XPos, YPos) then Result := HTCLIENT;
    if PtInRegion(RegLO, XPos, YPos) then Result := HTCLIENT ;
    if PtInRegion(RegM, XPos, YPos) then
      begin
       Hit := TRUE ;
       Result := HTCLIENT;
       invalidate;
       end
       else
       begin
       hit:=false;
       Result := HTCLIENT;
       invalidate;
       Result := HTNOWHERE;
       end;
    if PtInRegion(RegRo, XPos, YPos) then Result := HTCLIENT ;
    if PtInRegion(RegRB, XPos, YPos) then Result := HTCLIENT ;
    end;
   DeleteObject(RegLB);
   DeleteObject(RegLO);
   DeleteObject(RegM);
   DeleteObject(RegRO);
   DeleteObject(RegRB);
end;}
{
procedure TjanConnector.CMHitTest(var Msg: TCMHitTest);
begin
  Msg.Result := HTCLIENT;
end;}

procedure TjanConnector.CMHitTest(var Msg: TCMHitTest);
var
  RegLB, RegLO, RegRO, RegRB, RegM: HRGN;
  w2, d: Integer;
begin
  // if FLock then Exit;  // indien nodig

  d  := conSize;                // grootte van de hoek-blokjes (meestal 8)
  w2 := Round(Edge * Width);    // positie van de midden-lijn

  // Regio's voor de 4 hoeken + midden-strook
  RegLB := CreateRectRgn(0, 0, d, d);                       // links-boven
  RegLO := CreateRectRgn(0, Height - d, d, Height);         // links-onder
  RegRB := CreateRectRgn(Width - d, 0, Width, d);           // rechts-boven
  RegRO := CreateRectRgn(Width - d, Height - d, Width, Height); // rechts-onder (lime)
  RegM  := CreateRectRgn(w2 - 5, 0, w2 + 6, Height);        // middenlijn (11 breed)

  Msg.Result := HTNOWHERE;

  with Msg do
  begin
    // 1) Witte cirkel in het midden (clWhite) mag ook hit zijn
    if Canvas.Pixels[XPos, YPos] = clWhite then
      Result := HTCLIENT;
    // 2) Hoeken: als je in een van de hoek-regio's zit → HTCLIENT
    if PtInRegion(RegLB, XPos, YPos) or  // links-boven
       PtInRegion(RegLO, XPos, YPos) or  // links-onder
       PtInRegion(RegRB, XPos, YPos) or  // rechts-boven
       PtInRegion(RegRO, XPos, YPos)     // rechts-onder (lime)
    then
      Result := HTCLIENT;

    // 3) Middenlijn (hit = true/false)
    if PtInRegion(RegM, XPos, YPos) then
    begin
      Hit := True;
      Result := HTCLIENT;

      Invalidate;
    end
    else
    begin
      Hit := False;

      Invalidate;
      // BELANGRIJK: Result hier NIET terug op HTNOWHERE zetten,
      // anders gooi je de hoek-hits weer weg.
    end;
  end;

  DeleteObject(RegLB);
  DeleteObject(RegLO);
  DeleteObject(RegRB);
  DeleteObject(RegRO);
  DeleteObject(RegM);
  // ook de horizontale stukken van de draad zijn te raken (om te selecteren)
  if (Msg.Result = HTNOWHERE) and InLijnStrook(Msg.XPos, Msg.YPos) then
    Msg.Result := HTCLIENT;
end;

// Ligt (X,Y) op een horizontaal stuk van de draad (tot 6 pixels ernaast),
// buiten de blokjes aan de uiteinden en buiten het verticale middenstuk?
function TjanConnector.InLijnStrook(X, Y: Integer): Boolean;
const T = 6;
var d, k: Integer;
    Pt: array[0..3] of TPoint;
    A, B: TPoint;
begin
  Result := False;
  d := conSize;
  // de knik (slepen) en de blokjes aan de uiteinden (slepen) niet
  if Abs(X - Round(Edge * Width)) < 10 then Exit;
  ElektronWeg(Pt);
  if (Abs(X - Pt[0].X) <= d) and (Abs(Y - Pt[0].Y) <= d) then Exit;
  if (Abs(X - Pt[3].X) <= d) and (Abs(Y - Pt[3].Y) <= d) then Exit;
  // langs elk stuk van de draad (zoals hij getekend wordt)
  for k := 0 to 2 do
  begin
    A := Pt[k]; B := Pt[k + 1];
    if (A.X = B.X) and (A.Y = B.Y) then Continue;
    if A.Y = B.Y then
    begin
      if (Abs(Y - A.Y) <= T) and (X >= KleinsteI(A.X, B.X)) and (X <= GrootsteI(A.X, B.X)) then
        Exit(True);
    end
    else if A.X = B.X then
    begin
      if (Abs(X - A.X) <= T) and (Y >= KleinsteI(A.Y, B.Y)) and (Y <= GrootsteI(A.Y, B.Y)) then
        Exit(True);
    end;
  end;
end;


procedure TjanConnector.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
   if Assigned (FonExit) then FonExit(Self);
   // de markering altijd wegnemen, ook als de draad intussen vergrendeld is
   if Select then
   begin
    select:=false;
    invalidate;
   end;
end;

procedure TjanConnector.CMMouseEnter(var Msg: TMessage);
var T: string;
begin
  // hint: hoe je een draad selecteert, verwijdert en versleept
  if DraadBox <> nil then T := StatTaalToBTaal(DraadBox.Language) else T := 'NL';
  Hint := Tr(T,
    'Draad' + #13#10 + 'Klik: selecteren (dikker), nog eens klikken: deselecteren' + #13#10 +
      'Rechtsklik: menu om te selecteren of te verwijderen' + #13#10 +
      'Sleep aan een uiteinde of aan de knik om te verplaatsen',
    'Wire' + #13#10 + 'Click: select (thicker), click again: deselect' + #13#10 +
      'Right-click: menu to select or delete' + #13#10 +
      'Drag an end or the bend to move it',
    'Fil' + #13#10 + 'Clic : sélectionner (plus épais), cliquer encore : désélectionner' + #13#10 +
      'Clic droit : menu pour sélectionner ou supprimer' + #13#10 +
      'Faites glisser une extrémité ou le coude pour le déplacer',
    'Draht' + #13#10 + 'Klick: auswählen (dicker), noch einmal klicken: abwählen' + #13#10 +
      'Rechtsklick: Menü zum Auswählen oder Löschen' + #13#10 +
      'Ein Ende oder den Knick ziehen, um ihn zu verschieben');
  ShowHint := True;
  inherited;

  if Assigned (FOnEnter) then FOnEnter(Self);
  // alleen bij het bouwen dikker tekenen; tijdens de simulatie (de balk met
  // onderdelen is dan verborgen) blijft de draad zoals hij is
  if not FLock and not ((DraadBox <> nil) and not DraadBox.Visible) then
  begin
    Select := True;
    Invalidate;
  end;
end;

procedure TjanConnector.AnchorCorner(logTL: TPoint; ACorner: TjanConMode);
var Rc:TRect;
begin
  ConMode:=ACorner;
  Rc:=boundsrect;
  ConHot:=ConPos;
  case Acorner of
  jcmTL:
    begin
      ConOffset:=point(Rc.left-logTL.x,Rc.top-logTL.y);
      ConAnchor:=parent.ScreenToClient(clienttoscreen(point(width,height)));
    end;
  jcmTR:
    begin
      ConOffset:=point(Rc.Right-logTL.x,Rc.top-logTL.y);
      ConAnchor:=parent.ScreenToClient(clienttoscreen(point(0,height)));
    end;
  jcmBR:
    begin
      ConOffset:=point(Rc.Right-logTL.x,Rc.bottom-logTL.y);
      ConAnchor:=parent.ScreenToClient(clienttoscreen(point(0,0)));
    end;
  jcmBL:
    begin
      ConOffset:=point(Rc.left-logTL.x,Rc.bottom-logTL.y);
      ConAnchor:=parent.ScreenToClient(clienttoscreen(point(width,0)));
    end;
  end;
end;

// Koppelt deze draad aan een component met (vergrote) rechthoek R als
// een van de twee UITEINDEN van de draad in R ligt. De uiteinden hangen
// af van de vorm: jcsTLBR = linksboven/rechtsonder, jcsTRBL =
// rechtsboven/linksonder. De andere twee hoeken zijn geen uiteinde en
// worden bewust niet getest: bij een (bijna) rechte draad liggen die ook
// binnen R, en wie daarop ankert verschuift de koppeling en krijgt een
// conPos die niet bij de vorm past (de draad wordt dan niet getekend).
function TjanConnector.AnchorToRect(const R: TRect; logTL: TPoint): Boolean;
var Rc:TRect;
begin
  Result:=True;
  Rc:=BoundsRect;
  if Shape=jcsTLBR then
  begin
    if PtInRect(R,Point(Rc.Left,Rc.Top)) then AnchorCorner(logTL,jcmTL)
    else if PtInRect(R,Point(Rc.Right,Rc.Bottom)) then AnchorCorner(logTL,jcmBR)
    else Result:=False;
  end
  else
  begin
    if PtInRect(R,Point(Rc.Right,Rc.Top)) then AnchorCorner(logTL,jcmTR)
    else if PtInRect(R,Point(Rc.Left,Rc.Bottom)) then AnchorCorner(logTL,jcmBL)
    else Result:=False;
  end;
end;

// Hoeveel moet het gesleepte component (linkerbovenhoek logTL) nog
// verschuiven zodat deze draad exact recht ligt? Vergelijkt het
// aansluitblokje aan het bewegende uiteinde met dat aan het vaste
// uiteinde. Geeft True met dY (liggende draad) of dX (staande draad);
// de andere waarde is 0. Alleen geldig na AnchorCorner.
function TjanConnector.StraightenDelta(logTL: TPoint; out dX, dY: Integer): Boolean;
var d:integer;
    nc,M,S:TPoint;
begin
  d:=conSize;
  nc:=point(logTL.x+ConOffset.x,logTL.y+ConOffset.y);
  // linkerbovenhoek van het blokje aan het bewegende uiteinde (M) en aan
  // het vaste uiteinde (S), afhankelijk van welke hoek vastgemaakt werd
  case conMode of
    jcmTL: begin M:=nc;                        S:=point(ConAnchor.x-d,ConAnchor.y-d); end;
    jcmTR: begin M:=point(nc.x-d,nc.y);        S:=point(ConAnchor.x,ConAnchor.y-d);   end;
    jcmBR: begin M:=point(nc.x-d,nc.y-d);      S:=ConAnchor;                          end;
  else     begin M:=point(nc.x,nc.y-d);        S:=point(ConAnchor.x-d,ConAnchor.y);   end;
  end;
  dX:=0; dY:=0;
  if Abs(S.x-M.x)>=Abs(S.y-M.y) then dY:=S.y-M.y   // liggende draad
  else dX:=S.x-M.x;                                // staande draad
  Result:=(dX<>0) or (dY<>0);
end;

// Magnetisch rechttrekken: ligt een draad aan het gesleepte component
// binnen WireStraightenTol pixels van recht, dan schuift het component
// dat laatste stukje bij. De kleinste correctie per richting wint.
const
  WireStraightenTol = 6;

procedure StraightenWires(AConnectors: TList; var ANewLeft, ANewTop: Integer);
var i,dX,dY,BestX,BestY:integer;
begin
  if (AConnectors=nil) or (AConnectors.Count=0) then exit;
  BestX:=WireStraightenTol+1;
  BestY:=WireStraightenTol+1;
  for i:=0 to AConnectors.Count-1 do
    if TjanConnector(AConnectors[i]).StraightenDelta(point(ANewLeft,ANewTop),dX,dY) then
    begin
      if (dY<>0) and (Abs(dY)<Abs(BestY)) then BestY:=dY;
      if (dX<>0) and (Abs(dX)<Abs(BestX)) then BestX:=dX;
    end;
  if Abs(BestY)<=WireStraightenTol then Inc(ANewTop,BestY);
  if Abs(BestX)<=WireStraightenTol then Inc(ANewLeft,BestX);
end;

// ============================================================
// Voedingsrails
// ============================================================

function IsRailInput(C: TControl): Boolean;
begin
  Result := (C is TjanSimButton) or (C is TjanSimKnop) or (C is TjanSimSensor) or
            (C is TjanSimWarm) or (C is TjanSimPuls) or (C is TjanDipSwitsh) or
            (C is TjanSimEindschakelaar);
end;

function IsRailOutput(C: TControl): Boolean;
begin
  Result := (C is TjanSimLight) or (C is TjanSimRelais) or
            (C is TjanSimBuzzer) or (C is TjanDisplay) or (C is TjanSimMotor) or
            (C is TjanSimPersoon);
end;

function PanelHasRails(P: TWinControl): Boolean;
var
  i: Integer;
begin
  Result := False;
  if P = nil then Exit;
  for i := 0 to P.ControlCount - 1 do
    if (P.Controls[i] is TjanRail) and P.Controls[i].Visible then
      Exit(True);
end;

// ------------------------------------------------------------
// Voedingsdraden: een gewone draad (TjanConnector) van de lijn van een
// rail naar het voedingsbolletje van een component werkt als inpluggen.
// ------------------------------------------------------------
const
  RailWireTol = 3;   // zo dicht bij de raillijn / het bolletje telt een draadeinde

// midden van het voedingsbolletje van C: links (+ kant, invoer en R1 van het
// schakelrelais) of rechts (- kant, uitvoer), op de hoogte van de
// ingangs- of uitgangsdraad
function PowerDotSym(C: TControl; APlusSide: Boolean; S: TjanSymbolen): TPoint;
var
  Y: Integer;
begin
  Y := C.Top + C.Height div 2;
  // schemasymbolen: het bolletje op de hoogte van de ingangsdraad
  if APlusSide and (S <> Afbeelding) then
  begin
    if C is TjanSimButton then Y := C.Top + 29
    else if C is TjanSimKnop then Y := C.Top + 47
    else if C is TjanSimWarm then Y := C.Top + 17;
  end;
  // en bij de uitvoer op de hoogte van de uitgangsdraad naar de - rail
  if (not APlusSide) and (S <> Afbeelding) then
  begin
    if C is TjanSimLight then Y := C.Top + 6
    else if C is TjanSimBuzzer then Y := C.Top + 32;   // BuzzerLegY(21, 13)
  end;
  // schakelrelais: R- zit altijd rechts op hoogte 38, R1 links op 12
  if (not APlusSide) and (C is TjanSchakelRelais) then Y := C.Top + 38;
  if APlusSide and (C is TjanSchakelRelais) then Y := C.Top + 12;
  if APlusSide then
    Result := Point(C.Left - 4, Y)
  else
    Result := Point(C.Left + C.Width + 4, Y);
end;

function PowerDot(C: TControl; APlusSide: Boolean): TPoint;
begin
  Result := PowerDotSym(C, APlusSide, SymOf(C));
end;

function VoedingsKlemOp(P: TWinControl; const Pt: TPoint): Boolean;
var
  i: Integer;
begin
  Result := False;
  if P = nil then Exit;
  for i := 0 to P.ControlCount - 1 do
    if (P.Controls[i] is TjanVoedingsDeel) and
       (TjanVoedingsDeel(P.Controls[i]).PinAt(Pt) >= 0) then
      Exit(True);
end;

// de rail waarvan de lijn door Pt loopt (binnen RailWireTol), anders nil
function RailAtPoint(P: TWinControl; const Pt: TPoint): TjanRail;
var
  i: Integer;
  R: TjanRail;
begin
  Result := nil;
  if P = nil then Exit;
  for i := 0 to P.ControlCount - 1 do
    if (P.Controls[i] is TjanRail) and P.Controls[i].Visible then
    begin
      R := TjanRail(P.Controls[i]);
      if (Abs(Pt.X - R.LineX) <= RailWireTol) and
         (Pt.Y >= R.SpanTop) and (Pt.Y <= R.SpanBottom) then
        Exit(R);
    end;
end;

function NearPoint(const A, B: TPoint): Boolean;
begin
  Result := (Abs(A.X - B.X) <= RailWireTol) and (Abs(A.Y - B.Y) <= RailWireTol);
end;

// ligt Pt op het voedingsbolletje van C, bij welke tekenwijze ook? (een
// paneel kan bewaard zijn met Afbeelding en geopend met IEC, of omgekeerd)
function OnPowerDot(C: TControl; APlusSide: Boolean; const Pt: TPoint): Boolean;
var
  S: TjanSymbolen;
begin
  for S := Low(TjanSymbolen) to High(TjanSymbolen) do
    if NearPoint(Pt, PowerDotSym(C, APlusSide, S)) then
      Exit(True);
  Result := False;
end;

// de rail (+ of -) die met een draad op het voedingsbolletje van C zit
function WiredRail(C: TControl; APlusSide: Boolean): TjanRail;
var
  i: Integer;
  A, B, Dot: TPoint;
  P: TWinControl;
  R: TjanRail;
begin
  Result := nil;
  P := C.Parent;
  if P = nil then Exit;
  for i := 0 to P.ControlCount - 1 do
    if (P.Controls[i] is TjanConnector) and P.Controls[i].Visible then
    begin
      TjanConnector(P.Controls[i]).EndCenters(A, B);
      R := nil;
      if OnPowerDot(C, APlusSide, B) then
        R := RailAtPoint(P, A)
      else if OnPowerDot(C, APlusSide, A) then
        R := RailAtPoint(P, B);
      if (R <> nil) and (R.Plus = APlusSide) then
        Exit(R);
    end;
end;

// ligt Pt op het voedingsbolletje van een component?
function PowerDotAt(P: TWinControl; const Pt: TPoint): Boolean;
var
  i: Integer;
  C: TControl;
begin
  Result := False;
  if P = nil then Exit;
  for i := 0 to P.ControlCount - 1 do
  begin
    C := P.Controls[i];
    if not C.Visible then Continue;
    // (R1 van het schakelrelais niet: een draad van de + rail naar R1 is
    // een gewone ingangsdraad met de spanning van de rail)
    if IsRailInput(C) and OnPowerDot(C, True, Pt) then
      Exit(True);
    if (IsRailOutput(C) or (C is TjanMeter)) and OnPowerDot(C, False, Pt) then
      Exit(True);
  end;
end;

// Voedingsdraden laten eindigen op het bolletje van de huidige tekenwijze
// (na omschakelen Afbeelding <-> IEC/ANSI, en na het laden van een paneel)
procedure RealignPowerWires(P: TWinControl);
var
  i, k: Integer;
  Con: TjanConnector;
  A, B, Dot: TPoint;
  R: TjanRail;
  C: TControl;
  RailAtStart: Boolean;
begin
  if P = nil then Exit;
  for i := 0 to P.ControlCount - 1 do
  begin
    if not (P.Controls[i] is TjanConnector) then Continue;
    Con := TjanConnector(P.Controls[i]);
    Con.EndCenters(A, B);
    R := RailAtPoint(P, A);
    RailAtStart := R <> nil;
    if not RailAtStart then
      R := RailAtPoint(P, B);
    if R = nil then Continue;
    for k := 0 to P.ControlCount - 1 do
    begin
      C := P.Controls[k];
      if not C.Visible then Continue;
      if not ((R.Plus and IsRailInput(C)) or
              ((not R.Plus) and (IsRailOutput(C) or (C is TjanMeter)))) then Continue;
      Dot := PowerDot(C, R.Plus);
      if RailAtStart then
      begin
        if OnPowerDot(C, R.Plus, B) then
        begin
          if not NearPoint(B, Dot) then Con.PlaceEnds(A, Dot);
          Break;
        end;
      end
      else if OnPowerDot(C, R.Plus, A) then
      begin
        if not NearPoint(A, Dot) then Con.PlaceEnds(Dot, B);
        Break;
      end;
    end;
  end;
end;

// zou C met linkerkant ALeft en bovenkant ATop op rail R ingeplugd zijn?
// Invoer zit rechts van een + rail, uitvoer links van een - rail. De
// voltmeter kan beide: + (links) op een + rail, - (rechts) op een - rail.
function RailFits(R: TjanRail; C: TControl; ALeft, ATop: Integer): Boolean;
var
  Y: Integer;
  OnPlus, OnMin: Boolean;
begin
  Result := False;
  Y := ATop + C.Height div 2;
  if (Y < R.SpanTop) or (Y > R.SpanBottom) then Exit;
  OnPlus := ALeft = R.LineX + RailGap;
  OnMin := ALeft + C.Width + RailGap = R.LineX;
  if C is TjanSchakelRelais then
    // links een + rail (R1, contact), rechts een - rail (R-, spoel)
    Result := (R.Plus and OnPlus) or ((not R.Plus) and OnMin)
  else   if IsRailInput(C) then
    Result := R.Plus and OnPlus
  else if IsRailOutput(C) then
    Result := (not R.Plus) and OnMin
  else if C is TjanMeter then
    Result := (R.Plus and OnPlus) or ((not R.Plus) and OnMin);
end;

function RailOf(C: TControl): TjanRail;
var
  i: Integer;
  P: TWinControl;
begin
  Result := nil;
  if (C = nil) or not (IsRailInput(C) or IsRailOutput(C)) then Exit;
  P := C.Parent;
  if P = nil then Exit;
  for i := 0 to P.ControlCount - 1 do
    if (P.Controls[i] is TjanRail) and P.Controls[i].Visible and
       RailFits(TjanRail(P.Controls[i]), C, C.Left, C.Top) and
       (not ((C is TjanSchakelRelais) and TjanRail(P.Controls[i]).Plus)) then
      Exit(TjanRail(P.Controls[i]));
  // niet ingeplugd: misschien met een voedingsdraad aangesloten
  Result := WiredRail(C, IsRailInput(C));
end;

// schakelrelais: de + rail links, waarop R1 (het contact) is ingeplugd
function SchakelPlusRail(C: TControl): TjanRail;
var
  i: Integer;
  P: TWinControl;
begin
  Result := nil;
  P := C.Parent;
  if P = nil then Exit;
  for i := 0 to P.ControlCount - 1 do
    if (P.Controls[i] is TjanRail) and P.Controls[i].Visible and
       TjanRail(P.Controls[i]).Plus and
       RailFits(TjanRail(P.Controls[i]), C, C.Left, C.Top) then
      Exit(TjanRail(P.Controls[i]));
  Result := WiredRail(C, True);
end;

function RailPlugged(C: TControl): Boolean;
begin
  Result := RailOf(C) <> nil;
end;

function RailOK(C: TControl): Boolean;
var
  R: TjanRail;
begin
  Result := True;
  if not (IsRailInput(C) or IsRailOutput(C)) then Exit;
  if not PanelHasRails(C.Parent) then Exit;
  R := RailOf(C);
  if R = nil then
    Result := False
  else if IsRailInput(C) then
    Result := R.Powered
  else
    // uitvoer: alleen als de bron de + rail(s) voedt
    Result := SupplyOK(C.Parent);
end;

// spanning (volt) die invoer C op zijn draad zet: zonder rails 5 V als hij
// aan staat, met rails de spanning van zijn + rail (0 V als hij los staat)
function SignalVolt(C: TControl; Raw: Boolean): Double;
var
  R: TjanRail;
begin
  Result := 0;
  if not Raw then Exit;
  if not PanelHasRails(C.Parent) then Exit(RailMaxVolt);
  R := RailOf(C);
  if (R <> nil) and R.Plus then
    Result := R.Volt;
end;

procedure SnapToRail(C: TControl; var NewLeft: Integer; Tol: Integer);
var
  i, Want, D, Best, BestWant, Y: Integer;
  P: TWinControl;
  R: TjanRail;
  CanPlus, CanMin: Boolean;
begin
  CanPlus := IsRailInput(C) or (C is TjanMeter) or (C is TjanSchakelRelais);
  CanMin := IsRailOutput(C) or (C is TjanMeter);
  if not (CanPlus or CanMin) then Exit;
  P := C.Parent;
  if not PanelHasRails(P) then Exit;
  Best := Tol + 1;
  BestWant := NewLeft;
  Y := C.Top + C.Height div 2;
  for i := 0 to P.ControlCount - 1 do
  begin
    if not (P.Controls[i] is TjanRail) then Continue;
    R := TjanRail(P.Controls[i]);
    if not R.Visible then Continue;
    if (R.Plus and not CanPlus) or ((not R.Plus) and not CanMin) then Continue;
    if (Y < R.SpanTop) or (Y > R.SpanBottom) then Continue;  // boven of onder de rail
    if R.Plus then
      Want := R.LineX + RailGap
    else
      Want := R.LineX - RailGap - C.Width;
    D := Abs(NewLeft - Want);
    if D < Best then
    begin
      Best := D;
      BestWant := Want;
    end;
  end;
  if Best <= Tol then
    NewLeft := BestWant;
  P.Invalidate;   // stekkers en bolletjes bijwerken
end;

// Per ingeplugd component: een stekker (1 px) van de rail naar het
// component met een bolletje (7 px) tegen het component. Niet ingeplugde
// invoer en uitvoer krijgen een grijs bolletje: zij werken niet.
procedure DrawRailOverlay(Grid: TjanGridS);

  procedure Plug(R: TjanRail; C: TControl; APlusSide: Boolean);
  var
    Y, DotX: Integer;
    Dot: TPoint;
  begin
    Dot := PowerDot(C, APlusSide);
    DotX := Dot.X;
    Y := Dot.Y;
    if R <> nil then
    begin
      Grid.Canvas.Pen.Color := R.RailColor;
      // stekker alleen als het component echt ingeplugd is (met een
      // voedingsdraad loopt de draad al naar het bolletje)
      if RailFits(R, C, C.Left, C.Top) then
      begin
        if APlusSide then
          Grid.Canvas.MoveTo(R.LineX + 2, Y)
        else
          Grid.Canvas.MoveTo(R.LineX - 1, Y);
        Grid.Canvas.LineTo(DotX, Y);
      end;
      Grid.Canvas.Brush.Color := R.RailColor;
    end
    else
    begin
      Grid.Canvas.Pen.Color := clGray;
      Grid.Canvas.Brush.Color := clSilver;
    end;
    Grid.Canvas.Ellipse(DotX - 3, Y - 3, DotX + 4, Y + 4);
  end;

var
  i, k: Integer;
  C: TControl;
  MinPlugged: Boolean;
begin
  if not PanelHasRails(Grid) then Exit;
  Grid.Canvas.Pen.Width := 1;
  Grid.Canvas.Pen.Style := psSolid;
  Grid.Canvas.Brush.Style := bsSolid;
  for i := 0 to Grid.ControlCount - 1 do
  begin
    C := Grid.Controls[i];
    if not C.Visible then Continue;
    if C is TjanSchakelRelais then
    begin
      Plug(RailOf(C), C, False);                         // R- (spoel)
      if SchakelPlusRail(C) <> nil then
        Plug(SchakelPlusRail(C), C, True);               // R1 (contact)
    end
    else     if IsRailInput(C) then
      Plug(RailOf(C), C, True)
    else if IsRailOutput(C) then
      Plug(RailOf(C), C, False)
    else if C is TjanMeter then
    begin
      // voltmeter: de kanten die echt op een rail zitten
      MinPlugged := False;
      for k := 0 to Grid.ControlCount - 1 do
        if (Grid.Controls[k] is TjanRail) and Grid.Controls[k].Visible and
           RailFits(TjanRail(Grid.Controls[k]), C, C.Left, C.Top) then
        begin
          Plug(TjanRail(Grid.Controls[k]), C, TjanRail(Grid.Controls[k]).Plus);
          if not TjanRail(Grid.Controls[k]).Plus then
            MinPlugged := True;
        end;
      // de - kant: met een draad aan een - rail (blauw), anders grijs
      if not MinPlugged then
        Plug(WiredRail(C, False), C, False);
    end;
  end;
end;

// regel in het paneelbestand: TjanRail;height;left;top;width;+ of -;spanning x10;
function RailFileLine(R: TjanRail): string;
var
  Sign: string;
begin
  if R.Plus then Sign := '+' else Sign := '-';
  Result := Format('TjanRail;%d;%d;%d;%d;%s;%d;',
    [R.Height, R.Left, R.Top, R.Width, Sign, Round(R.SavedVolt * 10)]);
end;
