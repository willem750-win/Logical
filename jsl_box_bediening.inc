// janSimLogic.pas, deel: paneel: muis en eigenschappen (ingevoegd met {$I jsl_box_bediening.inc})

procedure TjanSimLogicBox.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var p:TPoint;
begin
  p:=point(x,y);
  DSquare:=false;
  DCon:=false;DLogicAnd:=false;DLogicOr:=false;DLogicNot:=false;DLogicNand:=false;DLogicNor:=false;DLogicXor:=false;
  DButton:=false;DLight:=false;DKnop:=false;DPuls:=false;
  DBuzzer:=false;DMotor:=false;DPersoon:=false;DWagen:=false;DMuziek:=false;DVerkeer:=false;DSlagboom:=false;DSensor:=false;DTeller:=false;DStappen:=false;DFlipFlop:=false;DStopwatch:=false;DMemory:=false;DDisplay:=false;
  DDipSwitsh:=false;DGrid:=false;DRailPlus:=false;DRailMin:=false;
  DBron:=false;DZekering:=false;DAmpMeter:=false;DWattMeter:=false;DWeerstand:=false;
  DLamp2:=false;DSchak2:=false;DVolt2:=false;DLed2:=false;DCond:=false;DPot:=false;DDiode:=false;DWissel:=false;DScoop:=false;DTrans:=false;DLdr:=false;DNtc:=false;DWsch:=false;DPuls2:=false;DDip2:=false;DMagneet:=false;DKompas:=false;DVeldplaat:=false;DSpoel:=false;DIJzer:=false;DRelaisM:=false;DSchommel:=false;DMotorM:=false;DNulmeter:=false;DDraaiM:=false;DTrafo:=false;DZoemer2:=false;DRelais2:=false;DBoardIn:=false;DBoardUit:=false;DStapM:=false;DServo:=false;DVent:=false;DK8055In:=false;DK8055Uit:=false;DK8055Ana:=false;
  DMeter:=false;DRelais:=false;DSchakel:=false;DWarm:=false;

  if PtInRect(RSquare, P) then DSquare := True
  else if ptinrect(RCon,p) and KDraad then Dcon:=true
  else if ptinrect(RLogicAnd,p)and (KLogicAnd=true) then DLogicAnd:=true
  else if ptinrect(RLogicOr,p)and (KLogicOr=true) then DLogicOr:=true
  else if ptinrect(RLogicNot,p)and (KLogicNot=true) then DLogicNot:=true
  else if PtInRect(RLogicNand,p) and KLogicNand then DLogicNand:=true
  else if PtInRect(RLogicNor,p) and KLogicNor then DLogicNor:=true
  else if PtInRect(RLogicXor,p) and KLogicXor then DLogicXor:=true
  else if ptinrect(RButton,p) and (KDrukknop=true) then DButton:=true
  else if ptinrect(RLight,p) and (KLamp=true) then DLight:=true
  else if ptinrect(RRelais,p) and (KRelais=true) then DRelais:=true
  else if ptinrect(RSchakel,p) and (KSchakelRelais=true) then DSchakel:=true
  else if ptinrect(RBuzzer,p) and (KBuzzer=true) then DBuzzer:=true
  else if ptinrect(RMotor,p) and (KMotor=true) then DMotor:=true
  else if ptinrect(RSensor,p) and (KSensor=true) then DSensor:=true
  else if ptinrect(RWarm,p) and (KWarm=true) then DWarm:=true
  else if ptinrect(RKnop,p) and (KSchakelaar=true) then DKnop:=true
  else if ptinrect(RPuls,p) and (KPuls=true) then DPuls:=true
  else if ptinrect(RDisplay,p) and (KDisplay=true)then DDisplay:=true
  else if ptinrect(RTeller,p) and (KTeller=true)then DTeller:=true
  else if ptinrect(RStappen,p) and (KStappen=true)then DStappen:=true
  else if PtInRect(RFlipFlop,p) and KFlipFlop then DFlipFlop:=true
  else if ptinrect(RStopwatch,p) and (KStopwatch=true)then DStopwatch:=true
  else if ptinrect(RMemory,p) and (KMemory=true)then DMemory:=true
  else if ptinrect(RDipSwitsh,p) and (KDipSwitsh=true)then DDipSwitsh:=true
  else if ptinrect(RMeter,p) and (KMeter=true)then DMeter:=true
  else if ptinrect(RPersoon,p) and (KPersoon=true) then DPersoon:=true
  else if ptinrect(RWagen,p) and (KWagen=true) then DWagen:=true
  else if ptinrect(RMuziek,p) and (KMuziek=true) then DMuziek:=true
  else if ptinrect(RVerkeer,p) and (KVerkeer=true) then DVerkeer:=true
  else if ptinrect(RSlagboom,p) and (KSlagboom=true) then DSlagboom:=true
  else if PtInRect(RRailPlus, P) then DRailPlus := True
  else if PtInRect(RRailMin, P) then DRailMin := True
  else if PtInRect(RBron, P) then DBron := True
  else if PtInRect(RZekering, P) then DZekering := True
  else if PtInRect(RAmpMeter, P) then DAmpMeter := True
  else if PtInRect(RWattMeter, P) then DWattMeter := True
  else if PtInRect(RWeerstand, P) then DWeerstand := True
  else if PtInRect(RLamp2, P) then DLamp2 := True
  else if PtInRect(RSchak2, P) then DSchak2 := True
  else if PtInRect(RWsch, P) then DWsch := True
  else if PtInRect(RPuls2, P) then DPuls2 := True
  else if PtInRect(RDip2, P) then DDip2 := True
  else if PtInRect(RMagneet, P) then DMagneet := True
  else if PtInRect(RKompas, P) then DKompas := True
  else if PtInRect(RVeldplaat, P) then DVeldplaat := True
  else if PtInRect(RSpoel, P) then DSpoel := True
  else if PtInRect(RIJzer, P) then DIJzer := True
  else if PtInRect(RRelaisM, P) then DRelaisM := True
  else if PtInRect(RSchommel, P) then DSchommel := True
  else if PtInRect(RMotorM, P) then DMotorM := True
  else if PtInRect(RNulmeter, P) then DNulmeter := True
  else if PtInRect(RDraaiM, P) then DDraaiM := True
  else if PtInRect(RTrafo, P) then DTrafo := True
  else if PtInRect(RZoemer2, P) then DZoemer2 := True
  else if PtInRect(RRelais2, P) then DRelais2 := True
  else if PtInRect(RBoardIn, P) then DBoardIn := True
  else if PtInRect(RBoardUit, P) then DBoardUit := True
  else if PtInRect(RStapM, P) then DStapM := True
  else if PtInRect(RServo, P) then DServo := True
  else if PtInRect(RVent, P) then DVent := True
  else if PtInRect(RK8055In, P) then DK8055In := True
  else if PtInRect(RK8055Uit, P) then DK8055Uit := True
  else if PtInRect(RK8055Ana, P) then DK8055Ana := True
  else if PtInRect(RVolt2, P) then DVolt2 := True
  else if PtInRect(RLed2, P) then DLed2 := True
  else if PtInRect(RCond, P) then DCond := True
  else if PtInRect(RPot, P) then DPot := True
  else if PtInRect(RDiode, P) then DDiode := True
  else if PtInRect(RWissel, P) then DWissel := True
  else if PtInRect(RScoop, P) then DScoop := True
  else if PtInRect(RTrans, P) then DTrans := True
  else if PtInRect(RLdr, P) then DLdr := True
  else if PtInRect(RNtc, P) then DNtc := True
  else if ptinrect(RGrid,p) and (KGrid=true) then DGrid:=true;
  invalidate;
end;

procedure TjanSimLogicBox.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
  NewHint: string;
begin
  inherited;

  P := Point(X, Y);
//  Fx := X;
//  Fy := Y;
  NewHint := '';

  if PtInRect(RCon, P) then NewHint := FHDraad
  else if PtInRect(RLogicAnd, P) then NewHint := FHLogicAnd
  else if PtInRect(RLogicOr, P) then NewHint := FHLogicOr
  else if PtInRect(RLogicNot, P) then NewHint := FHLogicNot
  else if PtInRect(RLogicNand, P) then NewHint := FHLogicNand
  else if PtInRect(RLogicNor, P) then NewHint := FHLogicNor
  else if PtInRect(RLogicXor, P) then NewHint := FHLogicXor
  else if PtInRect(RButton, P) then NewHint := FHDrukknop
  else if PtInRect(RLight, P) then NewHint := FHLamp
  else if PtInRect(RRelais, P) then NewHint := FHRelais
  else if PtInRect(RSchakel, P) then NewHint := FHSchakel
  else if PtInRect(RBuzzer, P) then NewHint := FHBuzzer
  else if PtInRect(RMotor, P) then NewHint := FHMotor
  else if PtInRect(RSensor, P) then NewHint := FHSensor
  else if PtInRect(RWarm, P) then NewHint := FHWarm
  else if PtInRect(RKnop, P) then NewHint := FHSchakelaar
  else if PtInRect(RPuls, P) then NewHint := FHPuls
  else if PtInRect(RDisplay, P) then NewHint := FHDisplay
  else if PtInRect(RTeller, P) then NewHint := FHTeller
  else if PtInRect(RStappen, P) then NewHint := FHStappen
  else if PtInRect(RFlipFlop, P) then NewHint := FHFlipFlop
  else if PtInRect(RStopwatch, P) then NewHint := FHStopwatch
  else if PtInRect(RMemory, P) then NewHint := FHMemory
  else if PtInRect(RDipSwitsh, P) then NewHint := FHDipSwitsh
  else if PtInRect(RMeter, P) then NewHint := FHMeter
  else if PtInRect(RPersoon, P) then NewHint := FHPersoon
  else if PtInRect(RWagen, P) then NewHint := FHWagen
  else if PtInRect(RMuziek, P) then NewHint := FHMuziek
  else if PtInRect(RVerkeer, P) then NewHint := FHVerkeer
  else if PtInRect(RSlagboom, P) then NewHint := FHSlagboom
  else if PtInRect(RRailPlus, P) then NewHint := FHRailPlus
  else if PtInRect(RRailMin, P) then NewHint := FHRailMin
  else if PtInRect(RBron, P) then NewHint := FHBron
  else if PtInRect(RZekering, P) then NewHint := FHZekering
  else if PtInRect(RAmpMeter, P) then NewHint := FHAmpMeter
  else if PtInRect(RWattMeter, P) then NewHint := FHWattMeter
  else if PtInRect(RWeerstand, P) then NewHint := FHWeerstand
  else if PtInRect(RLamp2, P) then NewHint := FHLamp2
  else if PtInRect(RSchak2, P) then NewHint := FHSchak2
  else if PtInRect(RVolt2, P) then NewHint := FHVolt2
  else if PtInRect(RLed2, P) then NewHint := FHLed2
  else if PtInRect(RCond, P) then NewHint := FHCond
  else if PtInRect(RPot, P) then NewHint := FHPot
  else if PtInRect(RDiode, P) then NewHint := FHDiode
  else if PtInRect(RWissel, P) then NewHint := FHWissel
  else if PtInRect(RScoop, P) then NewHint := FHScoop
  else if PtInRect(RTrans, P) then NewHint := FHTrans
  else if PtInRect(RWsch, P) then NewHint := FHWsch
  else if PtInRect(RPuls2, P) then NewHint := FHPuls2
  else if PtInRect(RDip2, P) then NewHint := FHDip2
  else if PtInRect(RMagneet, P) then NewHint := FHMagneet
  else if PtInRect(RKompas, P) then NewHint := FHKompas
  else if PtInRect(RVeldplaat, P) then NewHint := FHVeldplaat
  else if PtInRect(RSpoel, P) then NewHint := FHSpoel
  else if PtInRect(RIJzer, P) then NewHint := FHIJzer
  else if PtInRect(RRelaisM, P) then NewHint := FHRelaisM
  else if PtInRect(RSchommel, P) then NewHint := FHSchommel
  else if PtInRect(RMotorM, P) then NewHint := FHMotorM
  else if PtInRect(RNulmeter, P) then NewHint := FHNulmeter
  else if PtInRect(RDraaiM, P) then NewHint := FHDraaiM
  else if PtInRect(RTrafo, P) then NewHint := FHTrafo
  else if PtInRect(RZoemer2, P) then NewHint := FHBuzzer
  else if PtInRect(RRelais2, P) then NewHint := FHRelais
  else if PtInRect(RBoardIn, P) then NewHint := FHBoardIn
  else if PtInRect(RBoardUit, P) then NewHint := FHBoardUit
  else if PtInRect(RStapM, P) then NewHint := FHStapM
  else if PtInRect(RServo, P) then NewHint := FHServo
  else if PtInRect(RVent, P) then NewHint := FHVent
  else if PtInRect(RK8055In, P) then NewHint := FHK8055In
  else if PtInRect(RK8055Uit, P) then NewHint := FHK8055Uit
  else if PtInRect(RK8055Ana, P) then NewHint := FHK8055Ana
  else if PtInRect(RLdr, P) then NewHint := FHLdr
  else if PtInRect(RNtc, P) then NewHint := FHNtc
  else if PtInRect(RGrid, P) then NewHint := FHGrid;

  if FLastHintText <> NewHint then
  begin
    FLastHintText := NewHint;
    Hint := NewHint;
    Application.CancelHint;

    if NewHint <> '' then
      Application.ActivateHint(ClientToScreen(Point(X, Y)));
  end;
end;

procedure TjanSimLogicBox.maakpanel;
var
wc:TWinControl;
Y,X1,X2,X3:integer;
begin
  Y:= 0;
  X1:= 140;
  X2:= 380;
  X3:= 620;
  wc:=parent;
 // INVOER
  with TjanSimButton.create(self) do  //xxxx
  Begin
    parent:=wc;left:=X1;top:=80 + y;
    FLock:=true;tag:= wc.ControlCount;Hint:='Invoer --> Drukknop';
      OnStatus := StatusFromChild;
  end;
  with TjanSimKnop.create(self) do
  Begin
    parent:=wc;left:=X1+5;top:=140+ y;
    FLock:=true;tag:= wc.ControlCount;
      OnStatus := StatusFromChild;
  end;
  with TjanSimSensor.create(self) do
  begin
    parent:=wc;left:=X1;top:=220+ y;
    FLock:=true;tag:= wc.ControlCount;
     OnStatus := StatusFromChild;
  end;
  with TjanSimWarm.create(self) do
  Begin
    parent:=wc;left:=X1;top:=290 + y;
    FLock:=true;tag:= wc.ControlCount;
     OnStatus := StatusFromChild;
  end;
 // VERWERKING
  with TjanLogic.create(self) do
  begin
    parent:=wc;
    left:=X2;top:=65 + y;LogicFunc:=(jlfAnd);
    tag:= wc.ControlCount;FLock:=true;
  end;
  with TjanLogic.create(self) do
  begin
    parent:=wc;
    left:=X2;top:=165 + y;LogicFunc:=(jlfOR);
    tag:= wc.ControlCount;FLock:=true;
  end;
  with TjanLogic.create(self) do
  begin
    parent:=wc;
    left:=X2;top:=265 + y;LogicFunc:=(jlfNOT);
    tag:= wc.ControlCount;FLock:=true;
  end;
 // UITVOER
  with TjanSimBuzzer.create(self) do
  begin
    parent:=wc;
    left:=X3; top:=90 + y;
    FLock:=true;tag:= wc.ControlCount;
  end;
  with TjanSimRelais.create(self) do
  begin
    parent:=wc;
    left:=X3;top:=169 + y;
    FLock:=true;tag:= wc.ControlCount;
  end;
  with TjanSimLight.create(self) do
  begin
    parent:=wc;
    left:=X3;top:=284 + y;
    FLock:=true;tag:= wc.ControlCount;
    Info:='Uitvoer --> Lamp';
  end;
end;

Procedure TjanSimLogicBox.kontrolconnectors;
var
wc:TWinControl;
i:integer;
begin
wc:=Fparent;
 for i := wc.ControlCount - 1 downto 0 do
  if (wc.controls[i] is TjanConnector) then
   begin
       FDraden:=true;
   end;
end;

PROCEDURE TjanSimLogicBox.BlokkeerObjecten(blokkeer:Boolean);
var
wc:TWinControl;
i:integer;
begin
   wc:=Fparent;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanRail) then
        TjanRail(wc.Controls[i]).Lock := blokkeer;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanLogicRun) then
        TjanLogicRun(wc.Controls[i]).Lock := blokkeer;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimMotor) then
        TjanSimMotor(wc.Controls[i]).Lock := blokkeer;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimPersoon) then
        TjanSimPersoon(wc.Controls[i]).Lock := blokkeer;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimEindschakelaar) then
        TjanSimEindschakelaar(wc.Controls[i]).Lock := blokkeer;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimStappenteller) then
        TjanSimStappenteller(wc.Controls[i]).Lock := blokkeer;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanVoedingsDeel) then
        TjanVoedingsDeel(wc.Controls[i]).Lock := blokkeer;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanMeter) then
        TjanMeter(wc.Controls[i]).Lock := blokkeer;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimLight) then
       begin
       (wc.Controls[i] as TjanSimLight).Lock:=blokkeer;
       (wc.Controls[i] as TjanSimLight).BringToFront;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimRelais) then
       begin
       (wc.Controls[i] as TjanSimRelais).Lock:=blokkeer;
       (wc.Controls[i] as TjanSimRelais).BringToFront;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanConnector) then
       begin
       (wc.Controls[i] as TjanConnector).Lock := blokkeer;
       (wc.Controls[i] as TjanConnector).BringToFront;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanLogic) then
       begin
       (wc.Controls[i] as TjanLogic).Lock:=blokkeer;
       (wc.Controls[i] as TjanLogic).BringToFront;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimButton) then
       begin
       (wc.Controls[i] as TjanSimButton).Lock:=blokkeer;
       (wc.Controls[i] as TjanSimButton).BringToFront;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimKnop) then
       begin
       (wc.Controls[i] as TjanSimKnop).Lock:=blokkeer;
       (wc.Controls[i] as TjanSimKnop).BringToFront;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimPuls) then
       begin
       (wc.Controls[i] as TjanSimPuls).Lock:=blokkeer;
       (wc.Controls[i] as TjanSimPuls).BringToFront;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanTeller) then
       begin
       (wc.Controls[i] as TjanTeller).Lock:=blokkeer;
       (wc.Controls[i] as TjanTeller).BringToFront;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanDisplay) then
      begin
      (wc.Controls[i] as Tjandisplay).Lock:=blokkeer;
      (wc.Controls[i] as Tjandisplay).BringToFront;
      end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimBuzzer) then
       begin
       (wc.Controls[i] as TjanSimBuzzer).Lock:=blokkeer;
       (wc.Controls[i] as TjanSimBuzzer).BringToFront;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimSensor) then
      begin
      (wc.Controls[i] as TjanSimSensor).Lock:=blokkeer;
      (wc.Controls[i] as TjanSimSensor).BringToFront;
      end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimWarm) then
       begin
       (wc.Controls[i] as TjanSimWarm).Lock:=blokkeer;
       (wc.Controls[i] as TjanSimWarm).BringToFront;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanDipSwitsh) then
       begin
       (wc.Controls[i] as TjanDipSwitsh).Lock:=blokkeer;
       (wc.Controls[i] as TjanDipSwitsh).BringToFront;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanMemory) then
       begin
       (wc.Controls[i] as TjanMemory).Lock:=blokkeer;
       (wc.Controls[i] as TjanMemory).BringToFront;
       end;
end;

procedure TjanSimLogicBox.Killpanel;
var
wc:TWinControl;
i:integer;
begin
   Inc(FKillCount);   // zie KillCount (ongedaan maken begint opnieuw)
   FOefening.Clear;   // een ander paneel is geen oefening meer
   wc:=Fparent;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanLogicRun) then
        wc.Controls[i].Free;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimMotor) then
        wc.Controls[i].Free;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimPersoon) then
        wc.Controls[i].Free;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimEindschakelaar) then
        wc.Controls[i].Free;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimStappenteller) then
        wc.Controls[i].Free;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanVoedingsDeel) then
        wc.Controls[i].Free;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanRail) then
        wc.Controls[i].Free;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimLight) then
       begin
       (wc.Controls[i] as TjanSimLight).Free;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimRelais) then
       begin
       (wc.Controls[i] as TjanSimRelais).Free;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanLogic) then
       begin
       (wc.Controls[i] as TjanLogic).Free;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanConnector) then
       begin
       (wc.Controls[i] as TjanConnector).Free;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimButton) then
       begin
       (wc.Controls[i] as TjanSimButton).Free;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimKnop) then
       begin
       (wc.Controls[i] as TjanSimKnop).Free;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimPuls) then
       begin
       (wc.Controls[i] as TjanSimPuls).Free;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanTeller) then
       begin
       (wc.Controls[i] as TjanTeller).Free;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanDisplay) then
       begin
       (wc.Controls[i] as Tjandisplay).Free;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimBuzzer) then
       begin
       (wc.Controls[i] as TjanSimBuzzer).Free;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimSensor) then
       begin
       (wc.Controls[i] as TjanSimSensor).Free;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanSimWarm) then
       begin
       (wc.Controls[i] as TjanSimWarm).Free;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanDipSwitsh) then
       begin
       (wc.Controls[i] as TjanDipSwitsh).Free;
       end;
   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanMemory) then
       begin
       (wc.Controls[i] as TjanMemory).Free;
       end;

   for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanMeter) then
       begin
       (wc.Controls[i] as TjanMeter).Free;
       end;
end;

procedure TjanSimLogicBox.ZetTaal;
var
  wc: TWinControl;
  i: Integer;
begin
  wc := FParent;
  if not Assigned(wc) then Exit;

  case Language of
    stDutch  : Taal := 'NL';
    stEnglish: Taal := 'ENG';
    stFrench : Taal := 'FR';
    stGerman : Taal := 'DU';
  else
    Taal := 'NL';
  end;

  case Language of
    stDutch  : FHSchakelaar := 'maak Schakelaar';
    stEnglish: FHSchakelaar := LangTr('create Switch');
    stFrench : FHSchakelaar := 'créer interrupteur';
    stGerman : FHSchakelaar := 'Schalter erstellen';
  end;

  for i := wc.ControlCount - 1 downto 0 do
    ApplyLanguageToSimObj(wc.Controls[i]);

  RefreshStatusBarLanguage;
end;


procedure TjanSimLogicBox.KillConnectors;
var
wc:TWinControl;
i:integer;
begin
 wc:=Fparent;
  for i := wc.ControlCount - 1 downto 0 do
      if (wc.controls[i] is TjanConnector) then
       begin
       (wc.Controls[i] as TjanConnector).Free;
       end;
end;

procedure TjanSimLogicBox.MoveObjekten(hoeveel:Integer);
var
wc:TWinControl;
i:integer;
templeft:integer;
begin
  wc:=Fparent;
  for i := wc.ControlCount - 1 downto 0 do
       begin
       templeft:=wc.Controls[i].Left;
       if (Fopen=true) then
          begin
          wc.Controls[i].Left:= (templeft + hoeveel);
          end
          else
          begin
          wc.Controls[i].Left:= (templeft - hoeveel);
          end;
       end;
end;
 procedure TjanSimLogicBox.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  wc: TWinControl;
  a: Integer;
  s: string;

  procedure AddF(const PropName: string);
  begin
    AddFilter(PropName);
  end;

  procedure ResetDownStates;
  begin
    Dgrid := False;
    DButton := False; DKnop := False; DPuls := False; DWarm := False; DSensor := False;
    DCon := False;
    DLogicAnd := False; DLogicOr := False; DLogicNot := False; DLogicNand := False; DLogicNor := False; DLogicXor := False; DTeller := False; DStappen := False; DFlipFlop := False; DStopwatch := False; DMemory := False; DDipSwitsh := False;
    DLight := False; DRelais := False; DSchakel := False; DBuzzer := False; DMotor := False; DPersoon := False; DWagen := False; DMuziek := False; DVerkeer := False; DSlagboom := False; DDisplay := False;
    DRailPlus := False; DRailMin := False; DMeter := False;
    DBron := False; DZekering := False; DAmpMeter := False; DWattMeter := False; DWeerstand := False;
    DLamp2 := False; DSchak2 := False; DVolt2 := False; DLed2 := False; DCond := False; DPot := False; DDiode := False; DWissel := False; DScoop := False; DTrans := False; DLdr := False; DNtc := False; DWsch := False; DPuls2 := False; DDip2 := False; DMagneet := False; DKompas := False; DVeldplaat := False; DSpoel := False; DIJzer := False; DRelaisM := False; DSchommel := False; DMotorM := False; DNulmeter := False; DDraaiM := False; DTrafo := False; DZoemer2 := False; DRelais2 := False; DBoardIn := False; DBoardUit := False; DStapM := False; DServo := False; DVent := False; DK8055In := False; DK8055Uit := False; DK8055Ana := False;

    // nieuw
    DSquare := False;
  end;

begin
  inherited;

  if (Screen.Cursor = crHandPoint) then Exit;

  wc := FParent;
  if not Assigned(wc) then
  begin
    ResetDownStates;
    Exit;
  end;

  // Staat er nog een nieuw onderdeel klaar dat nog niet op het paneel
  // geplaatst is (nog onzichtbaar), dan dat weghalen: anders bleef het
  // achter op het paneel als je intussen een andere knop koos.
  if FNew then
    for a := wc.ControlCount - 1 downto 0 do
      if (wc.Controls[a] <> Self) and (wc.Controls[a].Tag = FObjectID) and
         not wc.Controls[a].Visible then
      begin
        wc.Controls[a].Free;
        FNew := False;
        Screen.Cursor := crDefault;
        Break;
      end;

  // ------------------------------------------------------------
  // Connector mode toggle + Z-order
  // ------------------------------------------------------------
  if Dcon then
  begin
    // eerst logic naar voren
    for a := wc.ControlCount - 1 downto 0 do
      if (wc.Controls[a] is TjanLogic) then
        (wc.Controls[a] as TjanLogic).BringToFront;

    // dan connectors naar voren
    for a := wc.ControlCount - 1 downto 0 do
      if (wc.Controls[a] is TjanConnector) then
        (wc.Controls[a] as TjanConnector).BringToFront;

    if Screen.Cursor = crDefault then
      Screen.Cursor := crDraad
    else
      Screen.Cursor := crDefault;
  end
  // ------------------------------------------------------------
  // Grid toggle (Kill connectors)
  // ------------------------------------------------------------
  else if DGrid then
  begin
    KillConnectors;
    Draden := False;
  end

  // ------------------------------------------------------------
  // Verwerking: Logic blocks
  // ------------------------------------------------------------
  else if DLogicAnd then
  with TjanLogic.Create(self) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount; LogicFunc := jlfAND;
    FObjectID := wc.ControlCount; Visible := False; Left := -100; Screen.Cursor := crAnd;

    if Language = stDutch then BTaal := 'NL'
    else if Language = stEnglish then BTaal := 'ENG'
    else if Language = stFrench then BTaal := 'FR';

    AddF('TjanLogic.Left');   AddF('TjanLogic.Top');
    AddF('TjanLogic.Width');  AddF('TjanLogic.Height');
    AddF('TjanLogic.L_Type');
  end
  else if DLogicOr then
  with TjanLogic.Create(self) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount; LogicFunc := jlfOR;
    FObjectID := wc.ControlCount; Visible := False; Left := -100; Screen.Cursor := crOr;

    if Language = stDutch then BTaal := 'NL'
    else if Language = stEnglish then BTaal := 'ENG'
    else if Language = stFrench then BTaal := 'FR';

    AddF('TjanLogic.Left');   AddF('TjanLogic.Top');
    AddF('TjanLogic.Width');  AddF('TjanLogic.Height');
    AddF('TjanLogic.L_Type');
  end
  else if DLogicNot then
  with TjanLogic.Create(self) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount; LogicFunc := jlfNOT;
    FObjectID := wc.ControlCount; Visible := False; Left := -100; Screen.Cursor := crNot;

    if Language = stDutch then BTaal := 'NL'
    else if Language = stEnglish then BTaal := 'ENG'
    else if Language = stFrench then BTaal := 'FR';

    AddF('TjanLogic.Left');   AddF('TjanLogic.Top');
    AddF('TjanLogic.Width');  AddF('TjanLogic.Height');
    AddF('TjanLogic.L_Type');
  end
  else if DLogicNand or DLogicNor or DLogicXor then
  with TjanLogic.Create(self) do
  begin
    // NEN, NOF en EX-OF: twee ingangen, zoals EN en OF
    Parent := wc; FNew := True; Tag := wc.ControlCount;
    if DLogicNand then LogicFunc := jlfNAND
    else if DLogicNor then LogicFunc := jlfNOR
    else LogicFunc := jlfXOR;
    FObjectID := wc.ControlCount; Visible := False; Left := -100;
    if DLogicNand then Screen.Cursor := crAnd else Screen.Cursor := crOr;
    BTaal := StatTaalToBTaal(Language);

    AddF('TjanLogic.Left');   AddF('TjanLogic.Top');
    AddF('TjanLogic.Width');  AddF('TjanLogic.Height');
    AddF('TjanLogic.L_Type');
  end
  else if DStopwatch then
  with TjanSimStopwatch.Create(self) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount;
    FObjectID := wc.ControlCount; Visible := False; Left := -200; Screen.Cursor := crCross;
    BTaal := StatTaalToBTaal(Language);
  end
  else if DFlipFlop then
  with TjanSimFlipFlop.Create(self) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount;
    FObjectID := wc.ControlCount; Visible := False; Left := -200; Screen.Cursor := crCross;
    BTaal := StatTaalToBTaal(Language);
  end
  else if DStappen then
  with TjanSimStappenteller.Create(self) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount;
    FObjectID := wc.ControlCount; Visible := False; Left := -200; Screen.Cursor := crCross;
    BTaal := StatTaalToBTaal(Language);
  end
  else if DTeller then
  with TjanTeller.Create(self) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount;
    FObjectID := wc.ControlCount; Visible := False; Screen.Cursor := crTeller;

    AddF('TjanTeller.Left');  AddF('TjanTeller.Top');
    AddF('TjanTeller.Width'); AddF('TjanTeller.Height');
  end
  else if DMemory then
  with TjanMemory.Create(self) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount;
    FObjectID := wc.ControlCount; Visible := False; Screen.Cursor := crGeheugen;

    AddF('TjanMemory.Left');  AddF('TjanMemory.Top');
    AddF('TjanMemory.Width'); AddF('TjanMemory.Height');
    AddF('TjanMemory.LogicFunc');
  end
  else if DDipSwitsh then
  with TjanDipSwitsh.Create(self) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount;
    FObjectID := wc.ControlCount; Visible := False; Screen.Cursor := crDip;

    AddF('TjanDipSwitsh.Left');  AddF('TjanDipSwitsh.Top');
    AddF('TjanDipSwitsh.Width'); AddF('TjanDipSwitsh.Height');
  end

  // ------------------------------------------------------------
  // Invoer: Buttons/Knoppen/Sensoren
  // ------------------------------------------------------------
  else if DButton then
  with TjanSimButton.Create(self) do   //xxxx
  begin
    OnStatus := StatusFromChild;
    Parent := wc; FNew := True;
    Tag := wc.ControlCount;
    Left := -100;
    FObjectID := wc.ControlCount; Visible := False;
    Screen.Cursor := crDrukknop;

    if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';

          OnStatus := StatusFromChild;

    AddF('TjanSimButton.Left');  AddF('TjanSimButton.Top');
    AddF('TjanSimButton.Width'); AddF('TjanSimButton.Height');

  end
  else if DKnop then
  with TjanSimKnop.Create(self) do
  begin

    Parent := wc; FNew := True; Tag := wc.ControlCount;
    FObjectID := wc.ControlCount; Visible := False; Screen.Cursor := crSchakelaar;

    if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';

      OnStatus := StatusFromChild;

    AddF('TjanSimKnop.Left');  AddF('TjanSimKnop.Top');
    AddF('TjanSimKnop.Width'); AddF('TjanSimKnop.Height');
  end
  else if DPuls then
  with TjanSimPuls.Create(self) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount;
    FObjectID := wc.ControlCount; Visible := False; Screen.Cursor := crPuls;

    AddF('TjanSimPuls.Left');  AddF('TjanSimPuls.Top');
    AddF('TjanSimPuls.Width'); AddF('TjanSimPuls.Height');
  end
  else if DLight then
  with TjanSimLight.Create(self) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount;
    FObjectID := wc.ControlCount; Visible := False; Screen.Cursor := crLamp;

    AddF('TjanSimLight.Left');  AddF('TjanSimLight.Top');
    AddF('TjanSimLight.Width'); AddF('TjanSimLight.Height');
  end
  else if DDisplay then
  with TjanDisplay.Create(self) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount;
    FObjectID := wc.ControlCount; Visible := False; Screen.Cursor := crDisplay;

    AddF('TjanDisplay.Left');  AddF('TjanDisplay.Top');
    AddF('TjanDisplay.Width'); AddF('TjanDisplay.Height');
  end
  else if DRailPlus then
    NewRail(True)
  else if DRailMin then
    NewRail(False)
  else if DBron then
    NewVoedingsDeel(0)
  else if DZekering then
    NewVoedingsDeel(1)
  else if DAmpMeter then
    NewVoedingsDeel(2)
  else if DWattMeter then
    NewVoedingsDeel(9)
  else if DWeerstand then
    NewVoedingsDeel(3)
  else if DLamp2 then
    NewVoedingsDeel(4)
  else if DSchak2 then
    NewVoedingsDeel(5)
  else if DWsch then
    NewVoedingsDeel(17)
  else if DPuls2 then
    NewVoedingsDeel(18)
  else if DDip2 then
    NewVoedingsDeel(19)
  else if DMagneet then
    NewVoedingsDeel(20)
  else if DKompas then
    NewVoedingsDeel(21)
  else if DVeldplaat then
    NewVoedingsDeel(22)
  else if DSpoel then
    NewVoedingsDeel(23)
  else if DIJzer then
    NewVoedingsDeel(24)
  else if DRelaisM then
    NewVoedingsDeel(25)
  else if DSchommel then
    NewVoedingsDeel(26)
  else if DMotorM then
    NewVoedingsDeel(27)
  else if DNulmeter then
    NewVoedingsDeel(28)
  else if DDraaiM then
    NewVoedingsDeel(29)
  else if DTrafo then
    NewVoedingsDeel(30)
  else if DZoemer2 then
    NewVoedingsDeel(31)
  else if DRelais2 then
    NewVoedingsDeel(32)
  else if DBoardIn then
    NewVoedingsDeel(33)
  else if DBoardUit then
    NewVoedingsDeel(34)
  else if DStapM then
    NewVoedingsDeel(35)
  else if DServo then
    NewVoedingsDeel(36)
  else if DVent then
    NewVoedingsDeel(37)
  else if DK8055In then
    NewVoedingsDeel(38)
  else if DK8055Uit then
    NewVoedingsDeel(39)
  else if DK8055Ana then
    NewVoedingsDeel(40)
  else if DVolt2 then
    NewVoedingsDeel(6)
  else if DLed2 then
    NewVoedingsDeel(7)
  else if DCond then
    NewVoedingsDeel(8)
  else if DPot then
    NewVoedingsDeel(10)
  else if DDiode then
    NewVoedingsDeel(11)
  else if DWissel then
    NewVoedingsDeel(12)
  else if DScoop then
    NewVoedingsDeel(13)
  else if DTrans then
    NewVoedingsDeel(14)
  else if DLdr then
    NewVoedingsDeel(15)
  else if DNtc then
    NewVoedingsDeel(16)
  else if DMeter then
  with TjanMeter.Create(wc) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount;
    FObjectID := wc.ControlCount; Visible := False; Screen.Cursor := crMeter;

    AddF('TjanMeter.Left');  AddF('TjanMeter.Top');
    AddF('TjanMeter.Width'); AddF('TjanMeter.Height');
    Box := Self; BTaal := StatTaalToBTaal(Language); OnStatus := StatusFromChild;
  end
  else if DBuzzer then
  with TjanSimBuzzer.Create(self) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount;
    FObjectID := wc.ControlCount; Visible := False; Screen.Cursor := crZoemer;

    AddF('TjanSimBuzzer.Left');  AddF('TjanSimBuzzer.Top');
    AddF('TjanSimBuzzer.Width'); AddF('TjanSimBuzzer.Height');
  end
  else if DWagen then
    NewWagen
  else if DMuziek then
    NewMuziek
  else if DVerkeer then
    NewPersoonVan(TjanSimVerkeerslicht)
  else if DSlagboom then
    NewPersoonVan(TjanSimSlagboom)
  else if DPersoon then
    NewPersoon
  else if DMotor then
  with TjanSimMotor.Create(self) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount;
    FObjectID := wc.ControlCount; Visible := False; Left := -100; Screen.Cursor := crCross;
    BTaal := StatTaalToBTaal(Language);
  end
  else if DSensor then
  with TjanSimSensor.Create(self) do
  begin

    Parent := wc; FNew := True; Tag := wc.ControlCount;
    FObjectID := wc.ControlCount; Visible := False; Screen.Cursor := crSensor;
      if Language = stDutch then BTaal := 'NL'
    else if Language = stEnglish then BTaal := 'ENG'
    else if Language = stFrench then BTaal := 'FR'
    else if Language = stGerman then BTaal := 'DU';
      OnStatus := StatusFromChild;
    AddF('TjanSimSensor.Left');  AddF('TjanSimSensor.Top');
    AddF('TjanSimSensor.Width'); AddF('TjanSimSensor.Height');

  end
  else if DWarm then
  with TjanSimWarm.Create(self) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount;
    FObjectID := wc.ControlCount; Visible := False; Screen.Cursor := crWarm;

    if Language = stDutch then BTaal := 'NL'
    else if Language = stEnglish then BTaal := 'ENG'
    else if Language = stFrench then BTaal := 'FR'
    else if Language = stGerman then BTaal := 'DU';
      OnStatus := StatusFromChild;
    AddF('TjanSimWarm.Left');  AddF('TjanSimWarm.Top');
    AddF('TjanSimWarm.Width'); AddF('TjanSimWarm.Height');
  end
  else if DRelais then
  with TjanSimRelais.Create(self) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount;
    FObjectID := wc.ControlCount; Visible := False; Screen.Cursor := crRelais;

    AddF('TjanSimRelais.Left');  AddF('TjanSimRelais.Top');
    AddF('TjanSimRelais.Width'); AddF('TjanSimRelais.Height');
  end
  else if DSchakel then
  with TjanSchakelRelais.Create(self) do
  begin
    Parent := wc; FNew := True; Tag := wc.ControlCount;
    FObjectID := wc.ControlCount; Visible := False; Screen.Cursor := crRelais;

    AddF('TjanSchakelRelais.Left');  AddF('TjanSchakelRelais.Top');
    AddF('TjanSchakelRelais.Width'); AddF('TjanSchakelRelais.Height');
  end;

  ResetDownStates;
  Invalidate;
end;



{LogicBox}

procedure TjanSimLogicBox.SetHDrukknop(const Value: String);
begin
  if value<>FHDrukknop then FHDrukknop := Value;
end;
procedure TjanSimLogicBox.SetHBuzzer(const Value: String);
begin
  if value<>FHBuzzer then FHBuzzer := Value;
end;
procedure TjanSimLogicBox.SetHMotor(const Value: String);
begin
  if value<>FHMotor then FHMotor := Value;
end;
procedure TjanSimLogicBox.SetHDipSwitsh(const Value: String);
begin
  if value<>FHDipSwitsh then FHDipSwitsh := Value;
end;
procedure TjanSimLogicBox.SetHSensor(const Value: String);
begin
  if value<>FHSensor then FHSensor := Value;
end;
procedure TjanSimLogicBox.SetHWarm(const Value: String);
begin
  if value<>FHWarm then FHWarm := Value;
end;
procedure TjanSimLogicBox.SetHDisplay(const Value: String);
begin
  if value<>FHDisplay then FHDisplay := Value;
end;
procedure TjanSimLogicBox.SetHDraad(const Value: String);
begin
  if value<>FHDraad then FHDraad := Value;
end;
procedure TjanSimLogicBox.SetHLamp(const Value: String);
begin
  if value<>FHLamp then FHLamp := Value;
end;
procedure TjanSimLogicBox.SetHGrid(const Value: String);
begin
  if value<>FHGrid then FHGrid := Value;
end;

procedure TjanSimLogicBox.SetHMeter(const Value: String);
begin
  if value<>FHMeter then FHMeter := Value;
end;

procedure TjanSimLogicBox.SetHLock(const Value: String);
begin
  if value<>FHLock then FHLock := Value;
end;
procedure TjanSimLogicBox.SetHLogicAnd(const Value: String);
begin
  if value<>FHLogicAnd then FHLogicAnd := Value;
end;
procedure TjanSimLogicBox.SetHLogicNot(const Value: String);
begin
  if value<>FHLogicNot then FHLogicNot := Value;
end;
procedure TjanSimLogicBox.SetHLogicOr(const Value: String);
begin
  if value<>FHLogicOr then FHLogicOr := Value;
end;
procedure TjanSimLogicBox.SetHTeller(const Value: String);
begin
  if value<>FHTeller then FHTeller := Value;
end;
procedure TjanSimLogicBox.SetHMemory(const Value: String);
begin
  if value<>FHMemory then FHMemory := Value;
end;
procedure TjanSimLogicBox.SetHRelais(const Value: String);
begin
  if value<>FHRelais then FHRelais := Value;
end;

procedure TjanSimLogicBox.SetHSchakelaar(const Value: String);
begin
  if value<>FHSchakelaar then FHSchakelaar := Value;
end;

{procedure TjanSimLogicBox.SetHKader(const Value: String);
begin
  if value<>FHKader then FHKader := Value;
end;}

procedure TjanSimLogicBox.SetHPuls(const Value: String);
begin
  if value<>FHPuls then FHPuls := Value;
end;
procedure TjanSimLogicBox.SetDrukknop(const Value: Boolean);
begin
  if value<>FDrukknop then
  begin
    FDrukknop := Value;
    if Value=true then FImputAantal:= FImputAantal+1 else FImputAantal:= FImputAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetKnopLeft(const Value: Integer);
begin
  if value<>FKnopLeft then
  begin
    FKnopLeft := Value;
  end;
  invalidate;
end;





procedure TjanSimLogicBox.SetGrid(const Value: Boolean);
begin
  if value <> FGrid then
  begin
    FGrid := Value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetFx(const Value: integer);
begin
  if value <> Fx then
  begin
    Fx := Value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetFy(const Value: integer);
begin
  if value <> Fy then
  begin
    Fy := Value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetDraden (const Value: Boolean);
begin
  if value <> FDraden then
  begin
    Fdraden:=value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetImputAantal(const Value: Integer);
begin
  if value<>FImputAantal then
  begin
    FImputAantal := Value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetImputColor(const Value: TColor);
begin
  if value<>FImputColor then
  begin
    FImputColor := Value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetOutputColor(const Value: TColor);
begin
  if value<>FOutputColor then
  begin
    FOutputColor := Value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetVerwerkingColor(const Value: TColor);
begin
  if value<>FVerwerkingColor then
  begin
    FVerwerkingColor := Value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetOutputAantal(const Value: Integer);
begin
  if value<>FOutputAantal then
  begin
    FOutputAantal := Value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetVerwerkingAantal(const Value: Integer);
begin
  if value<>FVerwerkingAantal then
  begin
    FVerwerkingAantal := Value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetKnopSpatie(const Value: Integer);
begin
  if value<>FSpatie then
  begin
    FSpatie := Value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetKnopTop(const Value: Integer);
begin
  if value<>FKnopTop then
  begin
    FKnopTop := Value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetDraad(const Value: Boolean);
begin
  if value<>FDraad then
  begin
    FDraad:= Value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetMotor(const Value: Boolean);
begin
  if value<>FMotor then
  begin
    FMotor:= Value;
    if Value=true then FOutputAantal:= FOutputAantal+1 else FOutputAantal:= FOutputAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetBuzzer(const Value: Boolean);
begin
  if value<>FBuzzer then
  begin
    FBuzzer:= Value;
    if Value=true then FOutputAantal:= FOutputAantal+1 else FOutputAantal:= FOutputAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetBColor(const Value: TColor);
begin
  if value<>FBColor then
  begin
    FBColor:= Value;
    invalidate;
  end;
end;




procedure TjanSimLogicBox.DoStatusText(const AText: string; APanel: Integer);
begin
  if Assigned(FOnStatusText) then
    FOnStatusText(Self, AText, APanel);
end;

procedure TjanSimLogicBox.PushStatus(ASource: TObject;const AText: string; APanel: Integer);
begin
  // oude event blijft werken
  if Assigned(FOnStatusText) then
    FOnStatusText(Self, AText, APanel);

  // nieuwe event met bronobject
  if Assigned(FOnStatusEx) then
    FOnStatusEx(Self, ASource, AText, APanel);
end;


procedure TjanSimLogicBox.RefreshStatusBarLanguage; // xxxx
begin
  if not Assigned(FLastStatusSender) then Exit;

  if FLastStatusSender is TjanSimButton then
    TjanSimButton(FLastStatusSender).SendStatusToBar
  else if FLastStatusSender is TjanSimKnop then
    TjanSimKnop(FLastStatusSender).SendStatusToBar
  else if FLastStatusSender is TjanSimSensor then
    TjanSimSensor(FLastStatusSender).SendStatusToBar
  else if FLastStatusSender is TjanSimWarm then
    TjanSimWarm(FLastStatusSender).SendStatusToBar
  else if FLastStatusSender is TjanSimPuls then
    TjanSimPuls(FLastStatusSender).SendStatusToBar
  else if FLastStatusSender is TjanDipSwitsh then
    TjanDipSwitsh(FLastStatusSender).SendStatusToBar
  else if FLastStatusSender is TjanLogic then
    TjanLogic(FLastStatusSender).SendStatusToBar
  else if FLastStatusSender is TjanTeller then
    TjanTeller(FLastStatusSender).SendStatusToBar
  else if FLastStatusSender is TjanMemory then
    TjanMemory(FLastStatusSender).SendStatusToBar
  else if FLastStatusSender is TjanSimLight then
    TjanSimLight(FLastStatusSender).SendStatusToBar
  else if FLastStatusSender is TjanSimRelais then
    TjanSimRelais(FLastStatusSender).SendStatusToBar
  else if FLastStatusSender is TjanSimBuzzer then
    TjanSimBuzzer(FLastStatusSender).SendStatusToBar
  else if FLastStatusSender is TjanDisplay then
    TjanDisplay(FLastStatusSender).SendStatusToBar;
    // aanpassen voor volgend object
    //voeg hier je andere sim-types toe
end;

procedure TjanSimLogicBox.SelectObject(AObj: TObject);


  procedure SetSelectedFlag(Obj: TObject; AValue: Boolean);
  begin

    if Obj is TjanSimButton then TjanSimButton(Obj).Selected := AValue
    else if Obj is TjanSimKnop then TjanSimKnop(Obj).Selected := AValue
    else if Obj is TjanSimSensor then TjanSimSensor(Obj).Selected := AValue
    else if Obj is TjanSimWarm then TjanSimWarm(Obj).Selected := AValue
    else if Obj is TjanSimPuls then TjanSimPuls(Obj).Selected := AValue
    else if Obj is TjanDipSwitsh then TjanDipSwitsh(Obj).Selected := AValue
    else if Obj is TjanLogic then TjanLogic(Obj).Selected := AValue
    else if Obj is TjanTeller then TjanTeller(Obj).Selected := AValue
    else if Obj is TjanMemory then TjanMemory(Obj).Selected := AValue
    else if Obj is TjanSimLight then TjanSimLight(Obj).Selected := AValue
    else if Obj is TjanSimRelais then TjanSimRelais(Obj).Selected := AValue
    else if Obj is TjanSimBuzzer then TjanSimBuzzer(Obj).Selected := AValue
    else if Obj is TjanDisplay then TjanDisplay(Obj).Selected := AValue
    else if Obj is TjanRail then TjanRail(Obj).Selected := AValue
    else if Obj is TjanMeter then TjanMeter(Obj).Selected := AValue
    else if Obj is TjanLogicRun then TjanLogicRun(Obj).Selected := AValue
    else if Obj is TjanSimMotor then TjanSimMotor(Obj).Selected := AValue
    else if Obj is TjanSimPersoon then TjanSimPersoon(Obj).Selected := AValue
    else if Obj is TjanSimEindschakelaar then TjanSimEindschakelaar(Obj).Selected := AValue
    else if Obj is TjanSimStappenteller then TjanSimStappenteller(Obj).Selected := AValue
    else if Obj is TjanVoedingsDeel then TjanVoedingsDeel(Obj).Selected := AValue
    else if Obj is TjanConnector then TjanConnector(Obj).Selected := AValue;
    // aanpassen voor volgend object
  end;

  procedure InvalidateIfControl(Obj: TObject);
  begin
    if Obj is TControl then
      TControl(Obj).Invalidate;
  end;
begin

  // --- TOGGLE: zelfde object opnieuw => deselect ---
  if Assigned(FSelectedSender) and (FSelectedSender = AObj) then
  begin
    SetSelectedFlag(FSelectedSender, False);
    InvalidateIfControl(FSelectedSender);

    FSelectedSender := nil;

    if Assigned(FOnSelected) then
      FOnSelected(Self, nil);

    Exit;
  end;

  // 1) vorige selectie uit
  if Assigned(FSelectedSender) then
  begin
    SetSelectedFlag(FSelectedSender, False);
    InvalidateIfControl(FSelectedSender);
  end;

  // 2) nieuwe selectie zetten
  FSelectedSender := AObj;

  if Assigned(FSelectedSender) then
  begin
    SetSelectedFlag(FSelectedSender, True);
    InvalidateIfControl(FSelectedSender);
  end;

  // 3) event naar mainform (btDelCurObject enable + hint)
  if Assigned(FOnSelected) then
    FOnSelected(Self, FSelectedSender);
end;

procedure TjanSimLogicBox.ApplyLanguageToGridChildren(const NewBTaal: TStatTaal; AGrid: TWinControl);
var
  i: Integer;
  c: TControl;
  s: string;
begin
  if not Assigned(AGrid) then Exit;

  s := StatTaalToBTaal(NewBTaal);

  for i := 0 to AGrid.ControlCount - 1 do
  begin
    c := AGrid.Controls[i];

    if c is TjanSimButton then
      TjanSimButton(c).BTaal := s
    else if c is TjanSimKnop then
      TjanSimKnop(c).BTaal := s
    else if c is TjanSimSensor then
      TjanSimSensor(c).BTaal := s
    else if c is TjanSimWarm then
      TjanSimWarm(c).BTaal := s
    else if c is TjanSimPuls then
      TjanSimPuls(c).BTaal := s
    else if c is TjanMeter then
      TjanMeter(c).BTaal := s
    else if c is TjanLogicRun then
      TjanLogicRun(c).BTaal := s
    else if c is TjanSimMotor then
      TjanSimMotor(c).BTaal := s
    else if c is TjanSimPersoon then
      TjanSimPersoon(c).BTaal := s
    else if c is TjanSimEindschakelaar then
      TjanSimEindschakelaar(c).BTaal := s
    else if c is TjanSimStappenteller then
      TjanSimStappenteller(c).BTaal := s
    else if c is TjanVoedingsDeel then
      TjanVoedingsDeel(c).BTaal := s
    else if c is TjanRail then
      TjanRail(c).BTaal := s
    else if c is TjanDipSwitsh then
      TjanDipSwitsh(c).BTaal := s
    else if c is TjanLogic then
      TjanLogic(c).BTaal := s
    else if c is TjanTeller then
      TjanTeller(c).BTaal := s
    else if c is TjanMemory then
      TjanMemory(c).BTaal := s
    else if c is TjanSimLight then
      TjanSimLight(c).BTaal := s
    else if c is TjanSimRelais then
      TjanSimRelais(c).BTaal := s
    else if c is TjanSimBuzzer then
      TjanSimBuzzer(c).BTaal := s
    else if c is TjanDisplay then
      TjanDisplay(c).BTaal := s;
    // voeg hier je andere sim-types toe  aanpassen
  end;
end;

procedure TjanSimLogicBox.SetBoxTaal(const Value:TStatTaal);
begin
  if value<>FBoxTaal then
  begin
    FBoxTaal := Value;
  end;
if FBoxTaal=stDutch then
 Begin
  Taal:='NL';
  HBuzzer:='maak Zoemer (twee klemmen)';
  HMotor:='maak Motor';
  HDipSwitsh:='maak DipSwitsh';
  HDisplay:='maak 7 segmentdisplay';
  HDraad:='maak Verbinding';
  HDrukknop:='maak Drukknop';
  HLamp:='maak logische lamp (5 V)';
  HLogicAnd:='maak EN-poort';
  HLogicNot:='maak Niet-poort';
  HLogicOr:='maak OF-poort';
  HLogicNand:='maak NEN-poort (niet-en)';
  HLogicNor:='maak NOF-poort (niet-of)';
  HLogicXor:='maak EX-OF-poort (exclusieve of)';
  HMemory:='maak Geheugenblok';
  HPuls:='maak Impulsgenerator';
  HRelais:='maak Relais (spoel met twee klemmen, wisselcontact)';
  HSchakelRelais:='maak Schakelrelais (relais met contact)';
  HSchakelaar:='maak Schakelaar';
  HSensor:='maak Lichtsensor';
  HTeller:='maak Tellerblok';
  HStappen:='maak Stappenteller (telt tot 9999)';
  HFlipFlop:='maak Flipflop (SR, D, JK of T)';
  HStopwatch:='maak Stopwatch (tijd met eindtijd)';
  HWarm:='maak WarmteSensor';
  HMeter:='maak Voltmeter';
  HPersoon:='maak Persoon (met eindschakelaars)';
  HWagen:='maak Wagentje (parcours met paaltjes)';
  HMuziek:='maak Muziekdoos (8 pianotoetsen)';
  HVerkeer:='maak Verkeerslicht (met voetgangerslicht)';
  HSlagboom:='maak Slagboom (parking)';
  HRailPlus:='maak + rail (voeding)';
  HRailMin:='maak - rail (massa)';
  HBron:='maak Bron (accu, 0 tot 12 V)';
  HZekering:='maak Zekering';
  HAmpMeter:='maak Milliampèremeter';
  HWattMeter:='maak Wattmeter';
  HWeerstand:='maak Weerstand (contact, lange draad)';
  HLamp2:='maak Lamp met 2 klemmen, voor 12 V of 5 V (serie en parallel)';
  HSchakelaar2:='maak Schakelaar met 2 klemmen';
  HWisselschakelaar:='maak Wisselschakelaar';
  HPuls2:='maak Impulsgenerator';
  HDip2:='maak Dipschakelaar';
  HMagneet:='maak Staafmagneet';
  HKompas:='maak Kompas';
  HVeldplaat:='maak Veldlijnenplaat';
  HSpoel:='maak Spoel';
  HIJzer:='maak Spijker (ijzer)';
  HRelaisModel:='maak Relais (open model)';
  HSchommel:='maak Stroomschommel';
  HElektromotor:='maak Elektromotor (model)';
  HNulmeter:='maak Nulpuntmeter (galvanometer)';
  HDraaimagneet:='maak Draaiende magneet (dynamo)';
  HTransformator:='maak Transformator';
  HBoardIn:='maak Arduino-ingang (echte drukknop)';
  HBoardUit:='maak Arduino-uitgang (echte pin)';
  HK8055In:='maak K8055-ingang (echte drukknop)';
  HK8055Uit:='maak K8055-uitgang (echte uitgang)';
  HK8055Ana:='maak K8055-analoge ingang (draaiknop, 0 tot 5 V)';
  HStappenmotor:='maak Stappenmotor';
  HServo:='maak Servomotor';
  HVentilator:='maak Ventilator';
  HVoltmeter2:='maak Voltmeter met 2 klemmen';
  HLed2:='maak Led met 2 klemmen (met voorschakelweerstand)';
  HCondensator:='maak Condensator (laden en ontladen)';
  HPotmeter:='maak Potentiometer (drie klemmen)';
  HDiode:='maak Diode';
  HWisselbron:='maak Wisselspanningsbron';
  HScoop:='maak Oscilloscoop';
  HTransistor:='maak Transistor';
  HLDR:='maak LDR';
  HNTC:='maak NTC';
 end;

if FBoxTaal=stEnglish then
 Begin
  // LangTr: ook voor een extra taal (lang\<code>.po)
  Taal:='ENG';
  HBuzzer:=LangTr('create buzzer (two terminals)');
  HMotor:=LangTr('create Motor');
  HDipSwitsh:=LangTr('create DipSwitsh');
  HDisplay:=LangTr('create 7 segment display');
  HDraad:=LangTr('create Connection');
  HDrukknop:=LangTr('create Push button');
  HLamp:=LangTr('create logic lamp (5 V)');
  HLogicAnd:=LangTr('create AND-Logic gate');
  HLogicNot:=LangTr('create NOT-Logic gate');
  HLogicOr:=LangTr('create OR-Logic gate');
  HLogicNand:=LangTr('create NAND-Logic gate (not-and)');
  HLogicNor:=LangTr('create NOR-Logic gate (not-or)');
  HLogicXor:=LangTr('create XOR-Logic gate (exclusive or)');
  HMemory:=LangTr('create Memory block');
  HPuls:=LangTr('create Impuls generator');
  HRelais:=LangTr('create relay (two-terminal coil, changeover contact)');
  HSchakelRelais:=LangTr('create Switching relay (relay with contact)');
  HSchakelaar:=LangTr('create Switsh');
  HSensor:=LangTr('create Light sensor');
  HTeller:=LangTr('create Counter block');
  HStappen:=LangTr('create Step counter (counts up to 9999)');
  HFlipFlop:=LangTr('create Flip-flop (SR, D, JK or T)');
  HStopwatch:=LangTr('create Stopwatch (time with end time)');
  HWarm:=LangTr('create HeatSensor');
  HMeter:=LangTr('create Voltmeter');
  HPersoon:=LangTr('create Person (with limit switches)');
  HWagen:=LangTr('create Cart (road with posts)');
  HMuziek:=LangTr('create Music box (8 piano keys)');
  HVerkeer:=LangTr('create Traffic light (with pedestrian light)');
  HSlagboom:=LangTr('create Barrier gate (car park)');
  HRailPlus:=LangTr('create + rail (supply)');
  HRailMin:=LangTr('create - rail (ground)');
  HBron:=LangTr('create Source (battery, 0 to 12 V)');
  HZekering:=LangTr('create Fuse');
  HAmpMeter:=LangTr('create Milliammeter');
  HWattMeter:=LangTr('create Wattmeter');
  HWeerstand:=LangTr('create Resistance (contact, long wire)');
  HLamp2:=LangTr('create Lamp with 2 terminals, for 12 V or 5 V (series and parallel)');
  HSchakelaar2:=LangTr('create Switch with 2 terminals');
  HWisselschakelaar:=LangTr('create Changeover switch');
  HPuls2:=LangTr('create Pulse generator');
  HDip2:=LangTr('create DIP switch');
  HMagneet:=LangTr('create bar magnet');
  HKompas:=LangTr('create compass');
  HVeldplaat:=LangTr('create field line sheet');
  HSpoel:=LangTr('create coil');
  HIJzer:=LangTr('create nail (iron)');
  HRelaisModel:=LangTr('create relay (open model)');
  HSchommel:=LangTr('create current swing');
  HElektromotor:=LangTr('create electric motor (model)');
  HNulmeter:=LangTr('create centre-zero meter (galvanometer)');
  HDraaimagneet:=LangTr('create rotating magnet (dynamo)');
  HTransformator:=LangTr('create transformer');
  HBoardIn:=LangTr('create Arduino input (real push button)');
  HBoardUit:=LangTr('create Arduino output (real pin)');
  HK8055In:=LangTr('create K8055 input (real push button)');
  HK8055Uit:=LangTr('create K8055 output (real output)');
  HK8055Ana:=LangTr('create K8055 analog input (knob, 0 to 5 V)');
  HStappenmotor:=LangTr('create stepper motor');
  HServo:=LangTr('create servo motor');
  HVentilator:=LangTr('create fan');
  HVoltmeter2:=LangTr('create Voltmeter with 2 terminals');
  HLed2:=LangTr('create LED with 2 terminals (with series resistor)');
  HCondensator:=LangTr('create Capacitor (charging and discharging)');
  HPotmeter:=LangTr('create Potentiometer (three terminals)');
  HDiode:=LangTr('create Diode');
  HWisselbron:=LangTr('create AC voltage source');
  HScoop:=LangTr('create Oscilloscope');
  HTransistor:=LangTr('create Transistor');
  HLDR:=LangTr('create LDR');
  HNTC:=LangTr('create NTC');
  end ;
if FBoxTaal=stFrench then
 Begin
  Taal:='FR' ;
  HBuzzer:='faire Buzzer (deux bornes)';
  HMotor:='faire Moteur';
  HDipSwitsh:='faire DipSwitsh';
  HDisplay:='faire Affichage à 7 segments';
  HDraad:='faire Connexion';
  HDrukknop:='faire Bouton poussoir';
  HLamp:='faire lampe logique (5 V)';
  HLogicAnd:='faire ET-La porte logique';
  HLogicNot:='faire Pas-La porte logique';
  HLogicOr:='faire OU-La porte logique';
  HLogicNand:='faire NON-ET-La porte logique';
  HLogicNor:='faire NON-OU-La porte logique';
  HLogicXor:='faire OU-X-La porte logique (ou exclusif)';
  HMemory:='faire Bloc mémoire';
  HPuls:='faire Générateur d"impulsions';
  HRelais:='faire Relais (bobine à deux bornes, contact inverseur)';
  HSchakelRelais:='faire Relais avec contact';
  HSchakelaar:='faire un changement';
  HSensor:='faire Capteur de lumière';
  HTeller:='faire Bloc compteur';
  HFlipFlop:='faire Bascule (SR, D, JK ou T)';
  HStappen:='faire Compteur de pas (compte jusqu''à 9999)';
  HStopwatch:='faire Chronomètre (temps avec heure de fin)';
  HWarm:='faire Capteur de chaleur';
  HMeter:='faire Voltmètre';
  HPersoon:='faire Personne (avec fins de course)';
  HWagen:='faire Chariot (parcours avec poteaux)';
  HMuziek:='faire Boîte à musique (8 touches de piano)';
  HVerkeer:='faire Feu tricolore (avec feu piétons)';
  HSlagboom:='faire Barrière (parking)';
  HRailPlus:='faire Rail + (alimentation)';
  HRailMin:='faire Rail - (masse)';
  HBron:='faire Source (batterie, 0 à 12 V)';
  HZekering:='faire Fusible';
  HAmpMeter:='faire Milliampèremètre';
  HWattMeter:='faire Wattmètre';
  HWeerstand:='faire Résistance (contact, long fil)';
  HLamp2:='faire Lampe à 2 bornes, pour 12 V ou 5 V (série et parallèle)';
  HSchakelaar2:='faire Interrupteur à 2 bornes';
  HWisselschakelaar:='faire Commutateur va-et-vient';
  HPuls2:='faire Générateur d''impulsions';
  HDip2:='faire Interrupteur DIP';
  HMagneet:='faire Aimant droit';
  HKompas:='faire Boussole';
  HVeldplaat:='faire Plaque de lignes de champ';
  HSpoel:='faire Bobine';
  HIJzer:='faire Clou (fer)';
  HRelaisModel:='faire Relais (modèle ouvert)';
  HSchommel:='faire Balançoire électrique';
  HElektromotor:='faire Moteur électrique (modèle)';
  HNulmeter:='faire Galvanomètre à zéro central';
  HDraaimagneet:='faire Aimant tournant (dynamo)';
  HTransformator:='faire Transformateur';
  HBoardIn:='faire Entrée Arduino (vrai bouton-poussoir)';
  HBoardUit:='faire Sortie Arduino (vraie broche)';
  HK8055In:='faire Entrée K8055 (vrai bouton)';
  HK8055Uit:='faire Sortie K8055 (vraie sortie)';
  HK8055Ana:='faire Entrée analogique K8055 (bouton, 0 à 5 V)';
  HStappenmotor:='faire Moteur pas à pas';
  HServo:='faire Servomoteur';
  HVentilator:='faire Ventilateur';
  HVoltmeter2:='faire Voltmètre à 2 bornes';
  HLed2:='faire LED à 2 bornes (avec résistance série)';
  HCondensator:='faire Condensateur (charge et décharge)';
  HPotmeter:='faire Potentiomètre (trois bornes)';
  HDiode:='faire Diode';
  HWisselbron:='faire Source de tension alternative';
  HScoop:='faire Oscilloscope';
  HTransistor:='faire Transistor';
  HLDR:='faire LDR';
  HNTC:='faire NTC';
 end;

 if FBoxTaal=stGerman then
  Begin
  Taal:='DU';
  HBuzzer:='Summer (zwei Klemmen) erstellen';
  HMotor:='Motor erstellen';
  HDipSwitsh:='DipSwitsh erstellen';
  HDisplay:='Erstellen Sie eine 7-Segment-Anzeige';
  HDraad:='Verbindung herstellen';
  HDrukknop:='Erstellen Sie einen Druckknopf';
  HLamp:='logische Lampe herstellen (5 V)';
  HLogicAnd:='UND-Gatter erstellen';
  HLogicNot:='Erstellen Sie keinen Port';
  HLogicOr:='ODER-Gatter erstellen';
  HLogicNand:='NAND-Gatter erstellen (nicht-und)';
  HLogicNor:='NOR-Gatter erstellen (nicht-oder)';
  HLogicXor:='XOR-Gatter erstellen (exklusives oder)';
  HMemory:='Speicherblock erstellen';
  HPuls:='Impulsgenerator herstellen';
  HRelais:='Relais (Spule mit zwei Klemmen, Wechsler) erstellen';
  HSchakelRelais:='Schaltrelais (Relais mit Kontakt) erstellen';
  HSchakelaar:='Schalter machen';
  HSensor:='Lichtsensor herstellen';
  HTeller:='Gegenblock erstellen';
  HFlipFlop:='Flipflop erstellen (SR, D, JK oder T)';
  HStappen:='Stappenteller erstellen (zählt bis 9999)';
  HStopwatch:='Stoppuhr erstellen (Zeit mit Endzeit)';
  HWarm:='HeatSensor erstellen';
  HMeter:='Voltmeter erstellen';
  HPersoon:='Person erstellen (mit Endschaltern)';
  HWagen:='Wagen erstellen (Strecke mit Pfosten)';
  HMuziek:='Spieldose erstellen (8 Klaviertasten)';
  HVerkeer:='Ampel erstellen (mit Fußgängerampel)';
  HSlagboom:='Schranke erstellen (Parkplatz)';
  HRailPlus:='+ Schiene (Versorgung) erstellen';
  HRailMin:='- Schiene (Masse) erstellen';
  HBron:='Quelle erstellen (Akku, 0 bis 12 V)';
  HZekering:='Sicherung erstellen';
  HAmpMeter:='Milliamperemeter erstellen';
  HWattMeter:='Wattmeter erstellen';
  HWeerstand:='Widerstand erstellen (Kontakt, langer Draht)';
  HLamp2:='Lampe mit 2 Klemmen für 12 V oder 5 V erstellen (Reihe und parallel)';
  HSchakelaar2:='Schalter mit 2 Klemmen erstellen';
  HWisselschakelaar:='Wechselschalter erstellen';
  HPuls2:='Impulsgenerator erstellen';
  HDip2:='DIP-Schalter erstellen';
  HMagneet:='Stabmagnet erstellen';
  HKompas:='Kompass erstellen';
  HVeldplaat:='Feldlinienplatte erstellen';
  HSpoel:='Spule erstellen';
  HIJzer:='Nagel (Eisen) erstellen';
  HRelaisModel:='Relais (offenes Modell) erstellen';
  HSchommel:='Leiterschaukel erstellen';
  HElektromotor:='Elektromotor (Modell) erstellen';
  HNulmeter:='Nullpunktmessgerät (Galvanometer) erstellen';
  HDraaimagneet:='Drehenden Magneten (Dynamo) erstellen';
  HTransformator:='Transformator erstellen';
  HBoardIn:='Arduino-Eingang (echter Taster) erstellen';
  HBoardUit:='Arduino-Ausgang (echter Pin) erstellen';
  HK8055In:='K8055-Eingang (echter Taster) erstellen';
  HK8055Uit:='K8055-Ausgang (echter Ausgang) erstellen';
  HK8055Ana:='Analogen K8055-Eingang (Drehknopf, 0 bis 5 V) erstellen';
  HStappenmotor:='Schrittmotor erstellen';
  HServo:='Servomotor erstellen';
  HVentilator:='Ventilator erstellen';
  HVoltmeter2:='Voltmeter mit 2 Klemmen erstellen';
  HLed2:='LED mit 2 Klemmen erstellen (mit Vorwiderstand)';
  HCondensator:='Kondensator erstellen (Laden und Entladen)';
  HPotmeter:='Potentiometer erstellen (drei Klemmen)';
  HDiode:='Diode erstellen';
  HWisselbron:='Wechselspannungsquelle erstellen';
  HScoop:='Oszilloskop erstellen';
  HTransistor:='Transistor erstellen';
  HLDR:='LDR erstellen';
  HNTC:='NTC erstellen';
  end;
  invalidate;
 // willy
end;


procedure TjanSimLogicBox.SetLamp(const Value: Boolean);
begin
  if value<>FLamp then
  begin
    FLamp := Value;
  if Value=true then FOutputAantal:= FOutputAantal + 1 else FOutputAantal:= FOutputAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetLijst(Value:TstringList);
begin
  if value<>templijst then
  begin
    templijst := Value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetDisplay(const Value: Boolean);
begin
  if value<>FDisplay then
  begin
    FDisplay := Value;
  if Value=true then FOutputAantal:= FOutputAantal+1 else FOutputAantal:= FOutputAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetVoeding(const Value: Boolean);
begin
  if Value = FVoeding then Exit;
  FVoeding := Value;
  invalidate;
end;

procedure TjanSimLogicBox.SetVoedingKnop(var F: Boolean; const Value: Boolean);
begin
  if Value = F then Exit;
  F := Value;
  Invalidate;
end;

procedure TjanSimLogicBox.SetKBron(const Value: Boolean);
begin SetVoedingKnop(FBronK, Value); end;

procedure TjanSimLogicBox.SetKZekering(const Value: Boolean);
begin SetVoedingKnop(FZekeringK, Value); end;

procedure TjanSimLogicBox.SetKAmpMeter(const Value: Boolean);
begin SetVoedingKnop(FAmpMeterK, Value); end;

procedure TjanSimLogicBox.SetKWattMeter(const Value: Boolean);
begin SetVoedingKnop(FWattMeterK, Value); end;

procedure TjanSimLogicBox.SetKWeerstand(const Value: Boolean);
begin SetVoedingKnop(FWeerstandK, Value); end;

procedure TjanSimLogicBox.SetKLamp2(const Value: Boolean);
begin SetVoedingKnop(FLamp2K, Value); end;

procedure TjanSimLogicBox.SetKSchakelaar2(const Value: Boolean);
begin SetVoedingKnop(FSchak2K, Value); end;

procedure TjanSimLogicBox.SetKWisselschakelaar(const Value: Boolean);
begin SetVoedingKnop(FWschK, Value); end;

procedure TjanSimLogicBox.SetKPuls2(const Value: Boolean);
begin SetVoedingKnop(FPuls2K, Value); end;

procedure TjanSimLogicBox.SetKDip2(const Value: Boolean);
begin SetVoedingKnop(FDip2K, Value); end;

procedure TjanSimLogicBox.SetKMagnetisme(const Value: Boolean);
begin SetVoedingKnop(FMagK, Value); end;

procedure TjanSimLogicBox.SetKBoard(const Value: Boolean);
begin SetVoedingKnop(FBoardK, Value); end;

procedure TjanSimLogicBox.SetKMotoren(const Value: Boolean);
begin SetVoedingKnop(FMotorenK, Value); end;

procedure TjanSimLogicBox.SetKVoltmeter2(const Value: Boolean);
begin SetVoedingKnop(FVolt2K, Value); end;

procedure TjanSimLogicBox.SetKLed2(const Value: Boolean);
begin SetVoedingKnop(FLed2K, Value); end;

procedure TjanSimLogicBox.SetKCondensator(const Value: Boolean);
begin SetVoedingKnop(FCondK, Value); end;

procedure TjanSimLogicBox.SetKPotmeter(const Value: Boolean);
begin SetVoedingKnop(FPotK, Value); end;

procedure TjanSimLogicBox.SetKDiode(const Value: Boolean);
begin SetVoedingKnop(FDiodeK, Value); end;

procedure TjanSimLogicBox.SetKWisselbron(const Value: Boolean);
begin SetVoedingKnop(FWisselK, Value); end;

procedure TjanSimLogicBox.SetKScoop(const Value: Boolean);
begin SetVoedingKnop(FScoopK, Value); end;

procedure TjanSimLogicBox.SetKTransistor(const Value: Boolean);
begin SetVoedingKnop(FTransK, Value); end;

procedure TjanSimLogicBox.SetKLDR(const Value: Boolean);
begin SetVoedingKnop(FLdrK, Value); end;

procedure TjanSimLogicBox.SetKNTC(const Value: Boolean);
begin SetVoedingKnop(FNtcK, Value); end;

// De halve knoppen van de voeding (rails, bron, zekering, weerstand, lamp,
// schakelaar en voltmeter met 2 klemmen): alleen de aangevinkte, zonder gaten.
// Vertikaal (balk links): twee per rij vanaf (LK, TOP); anders naast elkaar.
// Naast elkaar zijn de rails en de voltmeter halve knoppen (17 breed), de
// andere even breed als de gewone knoppen (26). Met MaxX > 0 gaat een knop
// die niet meer past naar een nieuwe rij vanaf StartX; FVoedingBottom geeft
// de onderkant van de laatste rij.
procedure TjanSimLogicBox.PlaatsVoeding(LK, TOP, H, SPATIE: Integer; Vertikaal: Boolean;
  MaxX: Integer; StartX: Integer);
var
  N, X, Y: Integer;

  procedure Knop(var R: TRect; Soort: Integer; ADown: Boolean);
  var W: Integer;
  begin
    if (Soort = -2) or (Soort = -1) or (Soort = 6) then W := 17 else W := 26;
    if Vertikaal then
    begin
      // MaxX en StartX zijn hier de onderkant en de bovenkant van een kolom
      if (MaxX > 0) and (Y + H > MaxX) and (Y > StartX) then
      begin
        Y := StartX;
        LK := LK + 26 + 4;
      end;
      R := Rect(LK, Y, LK + W, Y + H);
      Y := Y + H + 2;
      if LK + W > FVoedingRight then FVoedingRight := LK + W;
    end
    else
    begin
      if (MaxX > 0) and (X + W > MaxX) and (X > StartX) then
      begin
        X := StartX;
        TOP := TOP + H + 4;
        FVoedingBottom := TOP + H;
      end;
      R := Rect(X, TOP, X + W, TOP + H);
      X := X + W + 2;
    end;
    if Soort = -1 then DrawRailButton(R, True, ADown)
    else if Soort = -2 then DrawRailButton(R, False, ADown)
    else DrawVoedingButton(R, Soort, ADown);
    Inc(N);
  end;

begin
  RRailPlus := Rect(0, 0, 0, 0);
  RRailMin := Rect(0, 0, 0, 0);
  RBron := Rect(0, 0, 0, 0);
  RZekering := Rect(0, 0, 0, 0);
  RWeerstand := Rect(0, 0, 0, 0);
  RLamp2 := Rect(0, 0, 0, 0);
  RSchak2 := Rect(0, 0, 0, 0);
  RVolt2 := Rect(0, 0, 0, 0);
  RLed2 := Rect(0, 0, 0, 0);
  RCond := Rect(0, 0, 0, 0);
  RPot := Rect(0, 0, 0, 0);
  RDiode := Rect(0, 0, 0, 0);
  RWissel := Rect(0, 0, 0, 0);
  RScoop := Rect(0, 0, 0, 0);
  RTrans := Rect(0, 0, 0, 0);
  RLdr := Rect(0, 0, 0, 0);
  RNtc := Rect(0, 0, 0, 0);
  RWsch := Rect(0, 0, 0, 0);
  RPuls2 := Rect(0, 0, 0, 0);
  RDip2 := Rect(0, 0, 0, 0);
  RMagneet := Rect(0, 0, 0, 0);
  RKompas := Rect(0, 0, 0, 0);
  RVeldplaat := Rect(0, 0, 0, 0);
  RSpoel := Rect(0, 0, 0, 0);
  RIJzer := Rect(0, 0, 0, 0);
  RRelaisM := Rect(0, 0, 0, 0);
  RSchommel := Rect(0, 0, 0, 0);
  RMotorM := Rect(0, 0, 0, 0);
  RNulmeter := Rect(0, 0, 0, 0);
  RDraaiM := Rect(0, 0, 0, 0);
  RTrafo := Rect(0, 0, 0, 0);
  RZoemer2 := Rect(0, 0, 0, 0);
  RRelais2 := Rect(0, 0, 0, 0);
  RBoardIn := Rect(0, 0, 0, 0);
  RBoardUit := Rect(0, 0, 0, 0);
  RStapM := Rect(0, 0, 0, 0);
  RServo := Rect(0, 0, 0, 0);
  RVent := Rect(0, 0, 0, 0);
  RK8055In := Rect(0, 0, 0, 0);
  RK8055Uit := Rect(0, 0, 0, 0);
  RK8055Ana := Rect(0, 0, 0, 0);
  N := 0;
  X := LK;
  Y := TOP;
  FVoedingBottom := TOP + H;
  FVoedingRight := 0;
  if FVoeding then
  begin
    Knop(RRailPlus, -1, DRailPlus);
    Knop(RRailMin, -2, DRailMin);
  end;
  if FBronK then Knop(RBron, 0, DBron);
  if FWisselK then Knop(RWissel, 12, DWissel);
  if FZekeringK then Knop(RZekering, 1, DZekering);
  if FWeerstandK then Knop(RWeerstand, 3, DWeerstand);
  if FPotK then Knop(RPot, 10, DPot);
  if FLdrK then Knop(RLdr, 15, DLdr);
  if FNtcK then Knop(RNtc, 16, DNtc);
  if FLamp2K then Knop(RLamp2, 4, DLamp2);
  if FBuzzer then Knop(RZoemer2, 31, DZoemer2);
  if FRelais then Knop(RRelais2, 32, DRelais2);
  if FLed2K then Knop(RLed2, 7, DLed2);
  if FDiodeK then Knop(RDiode, 11, DDiode);
  if FCondK then Knop(RCond, 8, DCond);
  if FSchak2K then Knop(RSchak2, 5, DSchak2);
  if FWschK then Knop(RWsch, 17, DWsch);
  if FPuls2K then Knop(RPuls2, 18, DPuls2);
  if FDip2K then Knop(RDip2, 19, DDip2);
  if FVolt2K then Knop(RVolt2, 6, DVolt2);
  if FScoopK then Knop(RScoop, 13, DScoop);
  if FTransK then Knop(RTrans, 14, DTrans);
  // motoren: stappenmotor, servomotor, ventilator
  if FMotorenK then
  begin
    Knop(RStapM, 35, DStapM);
    Knop(RServo, 36, DServo);
    Knop(RVent, 37, DVent);
  end;
  if FMagK then
  begin
    Knop(RMagneet, 20, DMagneet);
    Knop(RKompas, 21, DKompas);
    Knop(RVeldplaat, 22, DVeldplaat);
    Knop(RSpoel, 23, DSpoel);
    Knop(RIJzer, 24, DIJzer);
    Knop(RRelaisM, 25, DRelaisM);
    Knop(RSchommel, 26, DSchommel);
    Knop(RMotorM, 27, DMotorM);
    Knop(RNulmeter, 28, DNulmeter);
    Knop(RDraaiM, 29, DDraaiM);
    Knop(RTrafo, 30, DTrafo);
  end;
  // een echt Arduino-board (via USB): ingang en uitgang
  if FBoardK then
  begin
    Knop(RBoardIn, 33, DBoardIn);
    Knop(RBoardUit, 34, DBoardUit);
    Knop(RK8055In, 38, DK8055In);
    Knop(RK8055Uit, 39, DK8055Uit);
    Knop(RK8055Ana, 40, DK8055Ana);
  end;
end;

procedure TjanSimLogicBox.SetSymbolen(const Value: TjanSymbolen);
var i: Integer;
    V: TjanSymbolen;
begin
  // de plaatjes (Afbeelding) zijn weg: alleen nog schemasymbolen IEC of ANSI
  V := Value;
  if V = Afbeelding then V := IEC;
  if V = FSymbolen then Exit;
  FSymbolen := V;
  // het voedingsbolletje verhuist mee met de tekenwijze
  RealignPowerWires(FParent);
  invalidate;
  for i := 0 to ComponentCount - 1 do
    if Components[i] is TControl then
      TControl(Components[i]).Invalidate;
end;

// Knop van een invoeronderdeel in de balk: het vaste plaatje bij Afbeelding,
// anders het schemasymbool (Kind zoals bij PaintInputSymbol).
procedure TjanSimLogicBox.DrawInputIcon(Kind: Integer; Bm: TBitmap; X, Y: Integer);
var OldBrush: TColor;
    OldStyle: TBrushStyle;
    OldPen: TColor;
begin
  if FSymbolen = Afbeelding then
  begin
    Canvas.Draw(X, Y, Bm);
    if Kind in [0..4] then
    begin
      // de knop van het plaatje houden, binnenin de nieuwe tekening
      OldBrush := Canvas.Brush.Color; OldStyle := Canvas.Brush.Style; OldPen := Canvas.Pen.Color;
      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := Bm.Canvas.Pixels[2, 2];
      Canvas.FillRect(Rect(X + 1, Y + 1, X + Bm.Width - 1, Y + Bm.Height - 1));
      DrawInputPictureIcon(Canvas, Kind, X, Y);
      Canvas.Brush.Color := OldBrush; Canvas.Brush.Style := OldStyle; Canvas.Pen.Color := OldPen;
    end;
    Exit;
  end;
  OldBrush := Canvas.Brush.Color; OldStyle := Canvas.Brush.Style; OldPen := Canvas.Pen.Color;
  // lichte achtergrond: de zwarte symbolen zijn zo beter zichtbaar
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := SymKnopKleur;
  Canvas.FillRect(Rect(X, Y - 1, X + 24, Y + 23));
  case Kind of
    0: DrawContactSymbol(Canvas, X + 15, Y + 3, Y + 22, X + 2, X + 21, X + 15, False, True);
    1: DrawContactSymbol(Canvas, X + 15, Y + 3, Y + 22, X + 2, X + 21, X + 15, False, False);
    2: DrawLDRSymbol(Canvas, X + 1, X + 21, Y + 15, False);
    3: DrawNTCSymbol(Canvas, X + 3, X + 21, Y + 12, False);
    4: DrawPulsSymbol(Canvas, X + 2, X + 21, Y + 12, False);
  end;
  Canvas.Brush.Color := OldBrush; Canvas.Brush.Style := OldStyle; Canvas.Pen.Color := OldPen;
end;
