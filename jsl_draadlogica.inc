// janSimLogic.pas, deel: elektronen en het signaal door de draden (ingevoegd met {$I jsl_draadlogica.inc})

// ============================================================
// Uiteinde van een draad laten "springen" naar een ingang
// ============================================================

type
  TPinArray = array of TPoint;

// Ingangen van component C: linkerbovenhoek van het groene
// aansluitvierkantje (7x7), relatief t.o.v. het component. Opgemeten
// uit de getekende componenten; bij poort, teller en meter alleen de
// ingangen die actief zijn.
function InputPins(C: TControl): TPinArray;
  procedure Add(X, Y: Integer);
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := Point(X, Y);
  end;
var i: Integer;
begin
  Result := nil;
  if C is TjanVoedingsDeel then
  begin
    // bron, zekering, milliampèremeter: alle klemmen
    for i := 0 to TjanVoedingsDeel(C).PinCount - 1 do
      Add(TjanVoedingsDeel(C).PinPos(i).X, TjanVoedingsDeel(C).PinPos(i).Y);
  end
  else if C is TjanLogicRun then
  begin
    for i := 0 to 3 do
      Add(1, TjanLogicRun.InputPinY(i));
  end
  else if C is TjanSimMotor then
  begin
    Add(1, TjanSimMotor.InputPinY(0));
    Add(1, TjanSimMotor.InputPinY(1));
  end
  else if C is TjanSimFlipFlop then
  begin
    for i := 0 to TjanSimFlipFlop(C).InputCount - 1 do
      Add(1, TjanSimFlipFlop(C).InPinY(i));
  end
  else if C is TjanSimStappenteller then
  begin
    Add(1, TjanSimStappenteller.InputPinY(0));
    Add(1, TjanSimStappenteller.InputPinY(1));
  end
  else if C is TjanSimPersoon then
  begin
    // L en R (of V en A, of de 8 noten) zitten links
    for i := 0 to TjanSimPersoon(C).InputCount - 1 do
      Add(1, TjanSimPersoon(C).InPinY(i));
  end
  else if C is TjanLogic then
  begin
    for i := 0 to 2 do
      if TjanLogic(C).Gates[i].Active then
        Add(TjanLogic(C).Gates[i].pos.x + 1, TjanLogic(C).Gates[i].pos.y + 2);
  end
  else if C is TjanMeter then
  begin
    if TjanMeter(C).Gates[0].Active then Add(6, 36);    // + (links); de - zit op de massa
  end
  else if C is TjanTeller then
  begin
    if TjanTeller(C).Gates[0].Active then Add(1, 12);   // reset
    if TjanTeller(C).Gates[1].Active then Add(1, 52);   // telimpuls
  end
  else if C is TjanMemory then
  begin
    Add(58, 35); Add(82, 35); Add(107, 35); Add(132, 35); Add(157, 35); // adres
    Add(19, 123);                                                         // data
  end
  else if C is TjanSchakelRelais then
  begin
    Add(2, 9);     // R1 (contact)
    Add(37, 71);   // R+ (spoel)
  end
  else if C is TjanSimRelais then Add(1, 28)
  else if C is TjanSimLight then Add(1, 3)
  else if C is TjanSimBuzzer then Add(1, 18)
  else if C is TjanDisplay then Add(1, C.Height div 2 - 3)
  else if C is TjanDipSwitsh then Add(93, 17);
end;

// Midden van de ingang (het groene vierkantje) van een blok zonder klemmen
// waar Pt binnen KnoopTol van ligt; anders Pt zelf. Voor de knooppunten op
// een ingang in UpdateSupply (jsl_rails_kring.inc).
function IngangBij(P: TWinControl; const Pt: TPoint): TPoint;
var
  i, j, Dist, Best: Integer;
  C: TControl;
  Pins: TPinArray;
  M: TPoint;
begin
  Result := Pt;
  if P = nil then Exit;
  Best := KnoopTol + 1;
  for i := 0 to P.ControlCount - 1 do
  begin
    C := P.Controls[i];
    if (not C.Visible) or (C is TjanConnector) or (C is TjanRail) or
       (C is TjanVoedingsDeel) then Continue;
    // alleen blokken in de buurt (InputPins maakt telkens een lijst)
    if (Pt.X < C.Left - KnoopTol - 4) or (Pt.X > C.Left + C.Width + KnoopTol + 4) or
       (Pt.Y < C.Top - KnoopTol - 4) or (Pt.Y > C.Top + C.Height + KnoopTol + 4) then Continue;
    Pins := InputPins(C);
    for j := 0 to High(Pins) do
    begin
      M := Point(C.Left + Pins[j].X + 3, C.Top + Pins[j].Y + 3);
      Dist := Abs(M.X - Pt.X);
      if Abs(M.Y - Pt.Y) > Dist then Dist := Abs(M.Y - Pt.Y);
      if Dist < Best then
      begin
        Best := Dist;
        Result := M;
      end;
    end;
  end;
end;

// Elektronen langs de rails en door de signaaldraden naar de lampen e.d.
// op de rails. Elke verbruiker C neemt LoadAmps12(C) x U / 12 V: die stroom
// komt van de + rail via de invoer (bv. een drukknop) en de draad naar de
// ingang van C, en gaat via de stekker van C naar de - rail. In elk stuk
// rail is de stroom de som van wat er boven in- en uitgaat.
procedure ElektronenRails(P: TWinControl; AU: Double; AToon: Boolean);
var
  Rails: array of TjanRail;
  TapR, TapY: array of Integer;
  TapI: array of Double;
  NT, i, j, k, qi, ri, Tmp: Integer;
  C, Src: TControl;
  Con: TjanConnector;
  Pa, Pb, Pin, Q: TPoint;
  Pins: TPinArray;
  IC, T, IPin: Double;
  NAan: Integer;
  R: TjanRail;
  Ys: array of Integer;
  Is_: array of Double;
  Cum: Double;

  // krijgt ingang J van uitvoer AC stroom? (persoon, wagentje, muziekdoos,
  // verkeerslicht, slagboom en motor: alleen de ingangen die aan staan)
  function PinAan(AC: TControl; J: Integer): Boolean;
  begin
    if AC is TjanSimPersoon then Result := TjanSimPersoon(AC).Inputs[J]
    else if AC is TjanSimMotor then Result := TjanSimMotor(AC).Inputs[J]
    else Result := True;
  end;

  procedure Tap(AR: TjanRail; AY: Integer; AI: Double);
  var
    z: Integer;
  begin
    for z := 0 to High(Rails) do
      if Rails[z] = AR then
      begin
        SetLength(TapR, NT + 1); SetLength(TapY, NT + 1); SetLength(TapI, NT + 1);
        TapR[NT] := z; TapY[NT] := AY; TapI[NT] := AI;
        Inc(NT);
        Exit;
      end;
  end;

  function Bij(const A, B: TPoint): Boolean;
  begin
    Result := (Abs(A.X - B.X) <= 3) and (Abs(A.Y - B.Y) <= 3);
  end;

begin
  SetLength(Rails, 0);
  for i := 0 to P.ControlCount - 1 do
    if (P.Controls[i] is TjanRail) and P.Controls[i].Visible then
    begin
      SetLength(Rails, Length(Rails) + 1);
      Rails[High(Rails)] := TjanRail(P.Controls[i]);
    end;
  NT := 0;
  if AToon then
  begin
    // voedingsdraden die op een rail eindigen (al berekend in het netwerk)
    for i := 0 to P.ControlCount - 1 do
      if (P.Controls[i] is TjanConnector) and P.Controls[i].Visible then
      begin
        Con := TjanConnector(P.Controls[i]);
        if Abs(Con.FStroomNieuw) <= ElektronMinA then Continue;
        Con.EndCenters(Pa, Pb);
        R := RailAtPoint(P, Pb);
        if R <> nil then Tap(R, Pb.Y, Con.FStroomNieuw);
        R := RailAtPoint(P, Pa);
        if R <> nil then Tap(R, Pa.Y, -Con.FStroomNieuw);
        // logische uitgang die een klem voedt: haar (niet getekende) voeding
        // hangt aan de - rail, ter hoogte van de uitgang; een relaiscontact
        // neemt zijn stroom uit de rail van R1
        if Con.FLogicBron then
        begin
          if VoedingsKlemOp(P, Pa) then Pa := Pb;
          Src := RelaisContactOp(P, Pa);
          if Src <> nil then
          begin
            R := SchakelPlusRail(Src);
            if R <> nil then Tap(R, Pa.Y, -Abs(Con.FStroomNieuw));
          end
          else
            for k := 0 to High(Rails) do
              if not Rails[k].Plus then
              begin
                if Con.Power then Tap(Rails[k], Pa.Y, -Abs(Con.FStroomNieuw))
                else Tap(Rails[k], Pa.Y, Abs(Con.FStroomNieuw));
                Break;
              end;
        end;
      end;
    // verbruikers op de rails
    for i := 0 to P.ControlCount - 1 do
    begin
      C := P.Controls[i];
      if not (C.Visible and IsRailOutput(C)) then Continue;
      IC := LoadAmps12(C) * AU / BronMaxVolt;
      if IC <= ElektronMinA then Continue;
      // via de stekker naar de - rail
      R := RailOf(C);
      if R <> nil then
      begin
        Tap(R, PowerDot(C, False).Y, IC);
        // met een min-draad (niet ingeplugd): de stroom loopt door die draad
        // van het voedingsbolletje naar de - rail
        if not RailFits(R, C, C.Left, C.Top) then
          for k := 0 to P.ControlCount - 1 do
            if (P.Controls[k] is TjanConnector) and P.Controls[k].Visible then
            begin
              Con := TjanConnector(P.Controls[k]);
              Con.EndCenters(Pa, Pb);
              if OnPowerDot(C, False, Pa) and (RailAtPoint(P, Pb) = R) then
              begin
                Con.FStroomNieuw := IC;
                Break;
              end
              else if OnPowerDot(C, False, Pb) and (RailAtPoint(P, Pa) = R) then
              begin
                Con.FStroomNieuw := -IC;
                Break;
              end;
            end;
      end;
      // door de draad naar de ingang
      Pins := InputPins(C);
      NAan := 0;
      for j := 0 to High(Pins) do
        if PinAan(C, j) then Inc(NAan);
      if NAan = 0 then NAan := 1;
      IPin := IC / NAan;
      for j := 0 to High(Pins) do
      begin
        if not PinAan(C, j) then Continue;
        Pin := Point(C.Left + Pins[j].X + 3, C.Top + Pins[j].Y + 3);
        for k := 0 to P.ControlCount - 1 do
          if (P.Controls[k] is TjanConnector) and P.Controls[k].Visible then
          begin
            Con := TjanConnector(P.Controls[k]);
            Con.EndCenters(Pa, Pb);
            if Bij(Pb, Pin) then
            begin
              Con.FStroomNieuw := IPin;
              Q := Pa;
            end
            else if Bij(Pa, Pin) then
            begin
              Con.FStroomNieuw := -IPin;
              Q := Pb;
            end
            else
              Continue;
            // waar komt de draad vandaan: een rail, of een ingeplugde invoer
            R := RailAtPoint(P, Q);
            if R <> nil then
              Tap(R, Q.Y, -IPin)
            else
              for qi := 0 to P.ControlCount - 1 do
              begin
                Src := P.Controls[qi];
                if Src.Visible and IsRailInput(Src) and
                   (Q.X >= Src.Left - 4) and (Q.X <= Src.Left + Src.Width + 4) and
                   (Q.Y >= Src.Top - 4) and (Q.Y <= Src.Top + Src.Height + 4) then
                begin
                  R := RailOf(Src);
                  if R <> nil then Tap(R, PowerDot(Src, True).Y, -IPin);
                  Break;
                end;
              end;
            Break;   // één draad per ingang
          end;
      end;
    end;
  end;
  // per rail: punten sorteren en de stroom per stuk optellen
  for ri := 0 to High(Rails) do
  begin
    SetLength(Ys, 0); SetLength(Is_, 0);
    for i := 0 to NT - 1 do
      if TapR[i] = ri then
      begin
        SetLength(Ys, Length(Ys) + 1); SetLength(Is_, Length(Is_) + 1);
        Ys[High(Ys)] := TapY[i]; Is_[High(Is_)] := TapI[i];
      end;
    for i := 1 to High(Ys) do
      for j := i downto 1 do
        if Ys[j] < Ys[j - 1] then
        begin
          Tmp := Ys[j]; Ys[j] := Ys[j - 1]; Ys[j - 1] := Tmp;
          T := Is_[j]; Is_[j] := Is_[j - 1]; Is_[j - 1] := T;
        end;
    // Is_[k] wordt de stroom naar beneden tussen Ys[k] en Ys[k+1]
    Cum := 0;
    for i := 0 to High(Is_) do
    begin
      Cum := Cum + Is_[i];
      Is_[i] := Cum;
    end;
    if Length(Is_) > 0 then SetLength(Is_, Length(Is_) - 1);
    Rails[ri].SetElektronen(Ys, Is_);
  end;
  // de nieuwe stromen in één keer toepassen: een draad wordt alleen hertekend
  // als hij aan of uit gaat (de klok van de elektronen doet de rest)
  for i := 0 to P.ControlCount - 1 do
    if P.Controls[i] is TjanConnector then
    begin
      Con := TjanConnector(P.Controls[i]);
      if not AToon then Con.FStroomNieuw := 0;
      Con.SetStroomA(Con.FStroomNieuw);
    end;
end;

// Middelpunt van het blokje aan het begin (APi, de bron, kant van conPos)
// en aan het einde (APo) van de draad, in coördinaten van het paneel.
// Zelfde berekening als in Connect/DisConnect.
procedure TjanConnector.EndCenters(out APi, APo: TPoint);
var d2,xw,yh:integer;
begin
  d2:=conSize div 2;
  xw:=Width-1;
  yh:=Height-1;
  case conPos of
    jcpTL: begin APi:=point(d2,d2);       APo:=point(xw-d2,yh-d2); end;
    jcpTR: begin APi:=point(xw-d2,d2);    APo:=point(d2,yh-d2);    end;
    jcpBR: begin APi:=point(xw-d2,yh-d2); APo:=point(d2,d2);       end;
  else     begin APi:=point(d2,yh-d2);    APo:=point(xw-d2,d2);    end;
  end;
  APi:=point(Left+APi.x,Top+APi.y);
  APo:=point(Left+APo.x,Top+APo.y);
end;

// Bouwt de draad opnieuw op met het begin op APi en het einde op APo
// (middelpunten van de blokjes). Gebruikt MoveConnector, zodat vorm,
// conPos en het rechte/omgeklapte geval op de gewone manier geregeld
// worden.
procedure TjanConnector.PlaceEnds(const APi, APo: TPoint);
var lo,hi,k:integer;
    m:TjanConMode;
    GotPi,GotPo:TPoint;
begin
  lo:=conSize div 2;       // van middelpunt naar hoek links/boven
  hi:=conSize-lo+1;        // van middelpunt naar hoek rechts/onder (xw = Width-1)
  // het einde ligt in de hoek tegenover conPos
  case conPos of
    jcpTL: m:=jcmBR;
    jcpTR: m:=jcmBL;
    jcpBR: m:=jcmTL;
  else     m:=jcmTR;
  end;
  ConMode:=m;
  ConHot:=conPos;
  case m of
    jcmTL: begin ConOffset:=point(APo.x-lo,APo.y-lo); ConAnchor:=point(APi.x+hi,APi.y+hi); end;
    jcmTR: begin ConOffset:=point(APo.x+hi,APo.y-lo); ConAnchor:=point(APi.x-lo,APi.y+hi); end;
    jcmBR: begin ConOffset:=point(APo.x+hi,APo.y+hi); ConAnchor:=point(APi.x-lo,APi.y-lo); end;
  else     begin ConOffset:=point(APo.x-lo,APo.y+hi); ConAnchor:=point(APi.x+hi,APi.y-lo); end;
  end;
  MoveConnector(point(0,0));

  // Bij een (bijna) rechte of omgeklapte draad wisselt een blokje van een
  // rechter-/onderhoek naar een linker-/bovenhoek; die worden 1 pixel
  // verschillend getekend (Width-1). Daarom nameten en bijsturen.
  for k:=1 to 3 do
  begin
    EndCenters(GotPi,GotPo);
    if (GotPi.x=APi.x) and (GotPi.y=APi.y) and (GotPo.x=APo.x) and (GotPo.y=APo.y) then
      break;
    ConAnchor:=point(ConAnchor.x+APi.x-GotPi.x,ConAnchor.y+APi.y-GotPi.y);
    ConOffset:=point(ConOffset.x+APo.x-GotPo.x,ConOffset.y+APo.y-GotPo.y);
    MoveConnector(point(0,0));
  end;
end;

const
  InputSnapTol = 12;   // pixels rond een ingang waarbinnen het einde springt

procedure TjanConnector.SnapEndToInput;
var PiC,PoC,Best,P:TPoint;
    BestDist,Dist,i,j:integer;
    C:TControl;
    Pins:TPinArray;
    EndMode:TjanConMode;
    FromRail:TjanRail;
    HasDot:Boolean;
    FromVoeding:Boolean;
    Rl:TjanRail;
begin
  if Parent=nil then exit;
  // alleen als het EINDE van de draad versleept werd (niet het begin)
  case conPos of
    jcpTL: EndMode:=jcmBR;
    jcpTR: EndMode:=jcmBL;
    jcpBR: EndMode:=jcmTL;
  else     EndMode:=jcmTR;
  end;
  if Mode<>EndMode then exit;

  EndCenters(PiC,PoC);
  // begint de draad op een voedingsrail, dan ook naar de voedingsbolletjes
  FromRail:=RailAtPoint(Parent,PiC);
  BestDist:=InputSnapTol+1;
  Best:=PoC;
  for i:=0 to Parent.ControlCount-1 do
  begin
    C:=Parent.Controls[i];
    if (C=Self) or (C is TjanConnector) or not C.Visible then continue;
    if FromRail<>nil then
    begin
      HasDot:=False;
      if FromRail.Plus and IsRailInput(C) then
      begin
        P:=PowerDot(C,True); HasDot:=True;
      end
      else if (not FromRail.Plus) and (IsRailOutput(C) or (C is TjanMeter)) then
      begin
        P:=PowerDot(C,False); HasDot:=True;
      end;
      if HasDot then
      begin
        Dist:=Abs(P.x-PoC.x);
        if Abs(P.y-PoC.y)>Dist then Dist:=Abs(P.y-PoC.y);
        if Dist<BestDist then
        begin
          BestDist:=Dist;
          Best:=P;
        end;
      end;
    end;
    Pins:=InputPins(C);
    for j:=0 to High(Pins) do
    begin
      // middelpunt van het 7x7-vierkantje
      P:=point(C.Left+Pins[j].x+3,C.Top+Pins[j].y+3);
      Dist:=Abs(P.x-PoC.x);
      if Abs(P.y-PoC.y)>Dist then Dist:=Abs(P.y-PoC.y);
      if Dist<BestDist then
      begin
        BestDist:=Dist;
        Best:=P;
      end;
    end;
  end;
  // begint de draad op een klem van de voedingskring (bron, zekering,
  // meter), dan mag het einde ook op de lijn van een rail springen
  FromVoeding:=False;
  for i:=0 to Parent.ControlCount-1 do
    if (Parent.Controls[i] is TjanVoedingsDeel) and Parent.Controls[i].Visible and
       (TjanVoedingsDeel(Parent.Controls[i]).PinAt(PiC)>=0) then
      FromVoeding:=True;
  if FromVoeding then
    for i:=0 to Parent.ControlCount-1 do
      if (Parent.Controls[i] is TjanRail) and Parent.Controls[i].Visible then
      begin
        Rl:=TjanRail(Parent.Controls[i]);
        if (PoC.y<Rl.SpanTop+2) or (PoC.y>Rl.SpanBottom-2) then continue;
        Dist:=Abs(Rl.LineX-PoC.x);
        if Dist<BestDist then
        begin
          BestDist:=Dist;
          Best:=point(Rl.LineX,PoC.y);
        end;
      end;
  if (BestDist<=InputSnapTol) and ((Best.x<>PoC.x) or (Best.y<>PoC.y)) then
    PlaceEnds(PiC,Best);
end;

procedure TjanConnector.MoveConnector(logTL: TPoint);
var nw,nh:integer;
    d,dd,d2:integer;
    nc:Tpoint;
begin
   d:=conSize;
   d2:= d div 2;
   nc:=point(LogTL.x+ConOffset.x,logTL.y+ConOffset.y);
  case conMode of
  jcmTL:
    begin
    nw:=conAnchor.x-nc.x;
    if nw<d then
    begin
      left:=conAnchor.x-d;
      width:=-nw+d+d;
    end
    else begin
      left:=nc.x;
      width:=ConAnchor.x-left;
    end;
    nh:=ConAnchor.y-nc.y;

// adjust new hot position
    if (nw<d) and (not (nh<d)) then
    begin
      case conHot of
        jcpTL: conPos:=jcpTR;
        jcpBR: conPos:=jcpBL;
      end;
      shape:=jcsTRBL;
    end
    else if (nw<d) and (nh<d) then
    begin
      case conHot of
        jcpTL: conPos:=jcpBR;
        jcpBR: conPos:=jcpTL;
      end;
      shape:=jcsTLBR;
    end
    else if (not nw<d) and (nh<d) then
    begin
      case conHot of
        jcpTL: conPos:=jcpBL;
        jcpBR: conPos:=jcpTR;
      end;
      shape:=jcsTRBL;
    end
    else begin
      case conHot of
        jcpTL: conPos:=jcpTL;
        jcpBR: conPos:=jcpBR;
      end;
      shape:=jcsTLBR;
    end;
// end of adjust TL new hot
    if nh<d then
    begin
      top:=ConAnchor.y-d;
      height:=-nh+d+d;
    end
    else begin
      top:=nc.y;
      height:=ConAnchor.y-Top;
    end;
    end;
  jcmTR:
    begin
    nw:=nc.x-ConAnchor.x;
    if nw<=0 then
    begin
      left:=conAnchor.x+nw-d;
      width:=-nw+d+d;
    end
    else if nw<=d then
    begin
      left:=nc.x-d;
      width:=-nw+d+d;
    end
    else begin
      // left altijd opnieuw vanaf het vaste punt: was de draad in deze
      // sleepbeweging al eens omgeklapt (tak hierboven), dan staat left
      // nog verkeerd en schuift het vaste uiteinde anders mee.
      left:=ConAnchor.x;
      width:=nw;
    end;
    nh:=ConAnchor.y-nc.y;
// adjust TR new hot position
    if (nw<d) and (not (nh<d)) then
    begin
      case conHot of
        jcpTR: conPos:=jcpTL;
        jcpBL: conPos:=jcpBR;
      end;
      shape:=jcsTLBR;
    end
    else if (nw<d) and (nh<d) then
    begin
      case conHot of
        jcpTR: conPos:=jcpBL;
        jcpBL: conPos:=jcpTR;
      end;
      shape:=jcsTRBL;
    end
    else if (not nw<d) and (nh<d) then
    begin
      case conHot of
        jcpTR: conPos:=jcpBR;
        jcpBL: conPos:=jcpTL;
      end;
      shape:=jcsTLBR;
    end
    else begin
      case conHot of
        jcpTR: conPos:=jcpTR;
        jcpBL: conPos:=jcpBL;
      end;
      shape:=jcsTRBL;
    end;
// end of adjust TR new hot
    if nh<d then
    begin
      top:=ConAnchor.y-d;
      height:=-nh+d+d;
    end
    else begin
      top:=ConAnchor.y-nh;
      height:=nh;
    end;
    end;
  jcmBR:
    begin
    nw:=nc.x-ConAnchor.x;
    if nw<=0 then
    begin
      left:=nc.x-d;
      width:=-nw+d+d;
    end
    else if nw<=d then
    begin
      left:=nc.x-d;
      width:=-nw+d+d;
    end
    else begin
      left:=ConAnchor.x;   // zie jcmTR: vaste uiteinde niet laten meeschuiven
      width:=nw;
    end;
    nh:=nc.y-ConAnchor.y;
// adjust BR new hot position
    if (nw<d) and (not (nh<d)) then
    begin
      case conHot of
        jcpBR: conPos:=jcpBL;
        jcpTL: conPos:=jcpTR;
      end;
      shape:=jcsTRBL;
    end
    else if (nw<d) and (nh<d) then
    begin
      case conHot of
        jcpBR: conPos:=jcpTL;
        jcpTL: conPos:=jcpBR;
      end;
      shape:=jcsTLBR;
    end
    else if (not nw<d) and (nh<d) then
    begin
      case conHot of
        jcpBR: conPos:=jcpTR;
        jcpTL: conPos:=jcpBL;
      end;
      shape:=jcsTRBL;
    end
    else begin
      case conHot of
        jcpBR: conPos:=jcpBR;
        jcpTL: conPos:=jcpTL;
      end;
      shape:=jcsTLBR;
    end;
// end of adjust BR new hot
    if nh<d then
    begin
      top:=ConAnchor.y+nh-d;
      height:=-nh+d+d;
    end
    else begin
       top:=ConAnchor.y;   // zie jcmTR: vaste uiteinde niet laten meeschuiven
       height:=nh;
    end;
    end;
  jcmBL:
    begin
    nw:=conAnchor.x-nc.x;
    if nw<d then
    begin
      left:=conAnchor.x-d;
      width:=-nw+d+d;
    end
    else begin
      left:=ConAnchor.x-nw;
      width:=nw;
    end;
    nh:=nc.y-ConAnchor.y;
// adjust BL new hot position
    if (nw<d) and (not (nh<d)) then
    begin
      case conHot of
        jcpBL: conPos:=jcpBR;
        jcpTR: conPos:=jcpTL;
      end;
      shape:=jcsTLBR;
    end
    else if (nw<d) and (nh<d) then
    begin
      case conHot of
        jcpBL: conPos:=jcpTR;
        jcpTR: conPos:=jcpBL;
      end;
      shape:=jcsTRBL;
    end
    else if (not nw<d) and (nh<d) then
    begin
      case conHot of
        jcpBL: conPos:=jcpTL;
        jcpTR: conPos:=jcpBR;
      end;
      shape:=jcsTLBR;
    end
    else begin
      case conHot of
        jcpBL: conPos:=jcpBL;
        jcpTR: conPos:=jcpTR;
      end;
      shape:=jcsTRBL;
    end;
// end of adjust BL new hot
    if nh<d then
    begin
       top:=ConAnchor.y+nh-d;
       height:=-nh+d+d;
    end
    else begin
      top:=ConAnchor.y;   // zie jcmTR: vaste uiteinde niet laten meeschuiven
      height:=nh;
    end;
    end;
  end;
end;



procedure TjanConnector.Connect;
var Pi,Po:TPoint;
    R:Trect;
    i,g,d,d2,xw,yh,puls,puls1,getal:integer;
    kb:integer;        // ingang 8-4-2-1 van display of geheugen
    wc:TWinControl;
    Vi,aktief:boolean;
    SrcVolt:Double;   // spanning van de bron in volt (-1 = nog niet bepaald)
    Adres:Integer;
    Ledw:char;
    sBut:TjanSimButton;
    SDipSwitsh:TjanDipSwitsh;
    sKnop:TjanSimKnop;
    sPuls:TjanSimPuls;
    sSensor:TjanSimSensor;
    sWarm:TjanSimWarm;
    sLog:TjanLogic;
    sTeller:TjanTeller;
    sMemory:TjanMemory;
    sMeter:TjanMeter;
    sLight:TjanSimLight;
    sDisplay:TjanDisplay;
    sSchakel:TjanSchakelRelais;
    sRelais:TjanSimRelais;
    sBuzzer:TjanSimBuzzer;
    pl:TPoint;
    RailSrc:TjanRail;   // de draad begint op deze voedingsrail (of nil)

  // convert a corner point to a parent point
  function pp(x,y:integer):TPoint;
  var p:Tpoint;
  begin
    p:=point(x,y);
    p:=clienttoscreen(p);
    result:=wc.ScreenToClient(p);
  end;

  function getvi:boolean;
  var p:Tpoint;
      ii,Q:integer;
  begin
    result:=true;
    SrcVolt:=-1;
    // draad vanaf een rail naar een ingang: de rail is de bron
    if RailSrc<>nil then
    begin
      vi:=RailSrc.Powered;
      if RailSrc.Plus then SrcVolt:=RailSrc.Volt else SrcVolt:=0;
      exit;
    end;
    for ii:=0 to wc.ControlCount-1 do
    begin
      // voedingskring: een draad die op een klem van de bron, zekering of
      // milliampèremeter begint, krijgt de spanning van die klem
      if (wc.controls[ii] is TjanVoedingsDeel) then
      begin
        Q:=TjanVoedingsDeel(wc.controls[ii]).PinAt(Pi);
        if Q>=0 then
        begin
          SrcVolt:=VoedingsPinVolt(TjanVoedingsDeel(wc.controls[ii]),Q);
          vi:=SrcVolt>=RailMinVolt-0.001;
          exit;
        end;
        continue;
      end;
      // LogicRun: een draad die op een uitgang begint
      if (wc.controls[ii] is TjanLogicRun) then
      begin
        Q:=TjanLogicRun(wc.controls[ii]).OutputPinAt(Pi);
        if Q>=8 then
        begin  // T1/T2: cijfer voor een display
          vi:=true;LedW:=TjanLogicRun(wc.controls[ii]).DisplayChar(Q-8);
          exit;
        end;
        if Q>=0 then
        begin
          vi:=TjanLogicRun(wc.controls[ii]).Outputs[Q];
          exit;
        end;
        continue;
      end;
      // stappenteller: uitgang Q (eindwaarde bereikt)
      if (wc.controls[ii] is TjanSimStappenteller) then
      begin
        // (ook stopwatch en flipflop: die heeft twee uitgangen, Q en niet-Q)
        if TjanSimStappenteller(wc.controls[ii]).OutValueAt(Pi, Vi) then
          exit;
        continue;
      end;
      // eindschakelaar: een draad die op zijn uitgang begint (de stand van
      // de persoon of het wagentje; met rails alleen als hij aan de + rail hangt)
      if (wc.controls[ii] is TjanSimEindschakelaar) then
      begin
        if TjanSimEindschakelaar(wc.controls[ii]).OutputPinAt(Pi) then
        begin
          vi:=TjanSimEindschakelaar(wc.controls[ii]).SimUitgang;
          SrcVolt:=SignalVolt(wc.controls[ii], vi);
          vi:=vi and RailOK(wc.controls[ii]);
          exit;
        end;
        continue;
      end;
      // schakelrelais: een draad die bij R2 begint, krijgt het contact als bron
      if (wc.controls[ii] is TjanSchakelRelais) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Pi) then
        begin
          sSchakel:=TjanSchakelRelais(wc.controls[ii]);
          vi:=sSchakel.ContactOut;
          SrcVolt:=sSchakel.ContactVolt;
          exit;
        end;
      end
      else if (wc.controls[ii] is TjanSimButton) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Pi) then
        begin
          sBut:=TjanSimButton(wc.controls[ii]);
          puls:=sBut.Puls;
          Vi:=sBut.Down and RailOK(sBut);
          SrcVolt:=SignalVolt(sBut, sBut.Down);
          sBut.Puls:=0;
          exit;
        end;
      end
      else if (wc.controls[ii] is TjanDipSwitsh) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Pi)   then
        begin
          sDipSwitsh:=TjanDipSwitsh(wc.controls[ii]);
          if  (sDipSwitsh.Down=true) or (sDipSwitsh.Start=true) then vi:=RailOK(sDipSwitsh) else vi:=false;
          SrcVolt:=SignalVolt(sDipSwitsh, sDipSwitsh.Down or sDipSwitsh.Start);
          if vi=true then
          begin
             TSchrijf:=true;
             Ledd:=sDipSwitsh.Bits;
          end;
          exit;
        end;
      end
      else if (wc.controls[ii] is TjanSimKnop) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Pi) then
        begin
          sKnop:=TjanSimKnop(wc.controls[ii]);
          puls:=sKnop.Puls;
          Vi:=sKnop.Down and RailOK(sKnop);
          SrcVolt:=SignalVolt(sKnop, sKnop.Down);
          sKnop.Puls:=0;
          exit;
        end;
      end
      else if (wc.controls[ii] is TjanSimPuls) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Pi) then
        begin
          sPuls:=TjanSimPuls(wc.controls[ii]);
          puls:=sPuls.Pulser;
          Vi:=sPuls.Pulsen and RailOK(sPuls);
          SrcVolt:=SignalVolt(sPuls, sPuls.Pulsen);
          sPuls.Pulser:=0;
          exit;
        end;
      end
      else if (wc.controls[ii] is TjanSimSensor) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Pi) then
        begin
          sSensor:=TjanSimSensor(wc.controls[ii]);
          puls:=sSensor.Puls;
          Vi:=sSensor.Down and RailOK(sSensor);
          SrcVolt:=SignalVolt(sSensor, sSensor.Down);
          sSensor.Puls:=0;
          exit;
        end;
      end

      else if (wc.controls[ii] is TjanSimWarm) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Pi) then
        begin
          sWarm:=TjanSimWarm(wc.controls[ii]);
          puls:=sWarm.Puls;
          Vi:=sWarm.Down and RailOK(sWarm);
          SrcVolt:=SignalVolt(sWarm, sWarm.Down);
          sWarm.Puls:=0;
          exit;
        end;
      end
      //
      else if (wc.controls[ii] is TjanMeter) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Pi) then
        begin
          sMeter:=TjanMeter(wc.controls[ii]);
          R:=rect(sMeter.left+33,sMeter.top+23,sMeter.left+sMeter.Width+ConSize,smeter.Top+44);
          if ptinrect(R,Pi) and SMeter.Gates[4].Active then
          begin  // output is gate 4
            SrcVolt:=SMeter.Reading;
            vi:=SrcVolt >= RailMinVolt - 0.001;
            exit;
          end;
        end;
      end
      else if (wc.controls[ii] is TjanTeller) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Pi) then
        begin
          sTeller:=TjanTeller(wc.controls[ii]);
          R:=rect(sTeller.left+33,sTeller.top+40,sTeller.left+ sTeller.Width+ConSize,sTeller.Top+48);
          if ptinrect(R,Pi) and STeller.Gates[4].Active then
          begin  // output is op aansluiting naar display
            vi:=STeller.OutPutDisplay;LedW:=STeller.FBitsChar;exit;
          end;
          R:=rect(sTeller.left+30,sTeller.top + 75,sTeller.left+30+ConSize,sTeller.top+ 83);
          if ptinrect(R,Pi) and STeller.Gates[2].Active then
          begin  // output is op aansluiting bit8
            vi:=STeller.OutPutBit8;exit;
          end;
          R:=rect(sTeller.left + 55,sTeller.top + 75,sTeller.left + 55 + ConSize,sTeller.top+83);
          if ptinrect(R,Pi) and STeller.Gates[3].Active then
          begin  // output is op aansluiting bit4
            vi:=STeller.OutPutBit4;exit;
          end;
          R:=rect(sTeller.left+80,sTeller.top+ 75,sTeller.left+80+ConSize,sTeller.top+ 83);
          if ptinrect(R,Pi) and STeller.Gates[5].Active then
          begin  // output is op aansluiting bit2
            vi:=STeller.OutPutBit2;exit;
          end;
          R:=rect(sTeller.left+105,sTeller.top+ 75,sTeller.left+105+ConSize,sTeller.top+ 83);
          if ptinrect(R,Pi) and STeller.Gates[6].Active then
          begin  // output is op aansluiting bit1
            vi:=STeller.OutPutBit1;exit;
          end;
        end;
      end
      else if (wc.controls[ii] is TjanMemory) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Pi) then
        begin
          sMemory:=TjanMemory(wc.controls[ii]);
          R:=rect(sMemory.left+ 192,sMemory.top + 90,sMemory.left+ 200,sMemory.Top+98);
          if ptinrect(R,Pi) and SMemory.Gates[4].Active then
          begin  // output is op aansluiting naar display
            vi:=SMemory.OutPutDisplay;LedW:=SMemory.FBitsChar;exit;
          end;
          //nieuw 28 december
          //draw(81,138,Uit);
          R:=rect(sMemory.left+81,sMemory.top + 138,sMemory.left+81+ConSize,sMemory.top+ 138+ConSize);
          if ptinrect(R,Pi) and sMemory.Gates[2].Active then
          begin  // output is op aansluiting bit8
            vi:=sMemory.OutPutBitMem8;exit;
          end;
          //draw(106,138,Uit);
          R:=rect(sMemory.left + 106,sMemory.top + 138,sMemory.left + 106 + ConSize,sMemory.top+138+ConSize);
          if ptinrect(R,Pi) and sMemory.Gates[3].Active then
          begin  // output is op aansluiting bit4
            vi:=sMemory.OutPutBitMem4;exit;
          end;
          //draw(134,138,Uit);
          R:=rect(sMemory.left+134,sMemory.top+ 138,sMemory.left+134+ConSize,sMemory.top+ 138+ConSize);
          if ptinrect(R,Pi) and sMemory.Gates[5].Active then
          begin  // output is op aansluiting bit2
            vi:=sMemory.OutPutBitMem2;exit;
          end;
          //draw(156,138,Uit);
          R:=rect(sMemory.left+156,sMemory.top + 138,sMemory.left+156+ConSize,sMemory.top+ 138+ConSize);
          if ptinrect(R,Pi) and sMemory.Gates[6].Active then
          begin  // output is op aansluiting bit1
            vi:=sMemory.OutPutBitmem1;exit;
          end;
          // einde nieuw 28 december
        end;
      end
      else if (wc.controls[ii] is TjanLogic) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Pi) then
        begin
          sLog:=TjanLogic(wc.controls[ii]);
          // now check if p is in one of the 3 output area's
          R:=rect(sLog.left+33,sLog.top,sLog.left+slog.Width+ConSize,sLog.Top+22);
          if ptinrect(R,Pi) and SLog.Gates[3].Active then
          begin  // output is gate 3
            vi:=SLog.OutPut1;
            exit;
          end;
          R:=rect(sLog.left+33,sLog.top+23,sLog.left+slog.Width+ConSize,sLog.Top+44);
          if ptinrect(R,Pi) and SLog.Gates[4].Active then
          begin  // output is gate 4
            vi:=SLog.OutPut2;
            //If SLog.OutPut2=true then puls:=1 else puls:=0;
            exit;
          end;
          R:=rect(sLog.left+33,sLog.top+45,sLog.left+slog.Width+ConSize,sLog.Top+64);
          if ptinrect(R,Pi) and SLog.Gates[5].Active then
          begin  // output is gate 5
            vi:=SLog.OutPut3;
            exit;
          end;
        end;
      end;
    end;
    result:=false;
  end;

  procedure setVo;  // deze procedure kontroleert of er op een imput van een
  var p:Tpoint;     // object een aansluiting is gemaakt van een ander object
      ii,Q:integer; // doormiddel van Tjanconnector en veranderd een status in
  begin             // het object doormiddel van de variable vi dat op true/false
    getal:=0;       // wordt gezet in de procedure getvi hierboven
    if vi=true then setpower(true) else setpower(false);
    for ii:=0 to wc.ControlCount-1 do
    begin
      // LogicRun: een draad die op een ingang eindigt
      if (wc.controls[ii] is TjanLogicRun) then
      begin
        Q:=TjanLogicRun(wc.controls[ii]).InputPinAt(Po);
        if Q>=0 then
        begin
          TjanLogicRun(wc.controls[ii]).SetInput(Q, vi);
          exit;
        end;
        continue;
      end;
      // motor: L of R, alleen met voeding (zoals een lamp)
      if (wc.controls[ii] is TjanSimMotor) then
      begin
        Q:=TjanSimMotor(wc.controls[ii]).InputPinAt(Po);
        if Q>=0 then
        begin
          TjanSimMotor(wc.controls[ii]).SetInput(Q, vi and RailOK(TjanSimMotor(wc.controls[ii])));
          exit;
        end;
        continue;
      end;
      // stappenteller: T of R (verwerking, geen voeding nodig)
      if (wc.controls[ii] is TjanSimStappenteller) then
      begin
        Q:=TjanSimStappenteller(wc.controls[ii]).InputPinAt(Po);
        if Q>=0 then
        begin
          TjanSimStappenteller(wc.controls[ii]).SetInput(Q, vi);
          exit;
        end;
        continue;
      end;
      // persoon: L of R (geen voeding nodig, zoals LogicRun)
      if (wc.controls[ii] is TjanSimPersoon) then
      begin
        Q:=TjanSimPersoon(wc.controls[ii]).InputPinAt(Po);
        if Q>=0 then
        begin
          // uitvoer: met rails alleen als hij aan de - rail hangt (zoals de motor)
          TjanSimPersoon(wc.controls[ii]).SetInput(Q, vi and RailOK(TjanSimPersoon(wc.controls[ii])));
          exit;
        end;
        continue;
      end;
      if (wc.controls[ii] is TjanSimLight) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sLight:=TjanSimLight(wc.controls[ii]);
          If SLight.Lit <> (Vi and RailOK(SLight)) then SLight.Lit:=Vi and RailOK(SLight);
          exit;
        end;
      end
      else if(wc.controls[ii] is TjanDipSwitsh) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
        sDipSwitsh:=TjanDipSwitsh(wc.controls[ii]);
        //draw(91,15,Ingang);
        R:=rect(sDipSwitsh.left + 91,sDipSwitsh.top + 15,sDipSwitsh.left + 100,sDipSwitsh.Top + 30);
          if ptinrect(R,Po)  then
          begin  // input is op schrijfingang vanuit externe aansluiting
           if SDipSwitsh.start <> Vi then  SDipSwitsh.start:=vi;
           puls1:=1;
           exit;
          end;
        end;
      end
      else if(wc.controls[ii] is TjanDisplay) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sDisplay:=TjanDisplay(wc.controls[ii]);
          // een van de vier ingangen 8-4-2-1
          kb:=sDisplay.BcdIndexAt(Po);
          if kb>=0 then
          begin
            sDisplay.ZetBcd(kb, vi and RailOK(sDisplay));
            exit;
          end;
          if LedW=#0 then // gewone aan/uit-bron (drukknop, schakelaar, poort...)
            if vi then LedW:='1' else LedW:='0';
          if not RailOK(SDisplay) then LedW:=' ';  // zonder voeding: donker
          If SDisplay.Digit <> LedW then  SDisplay.digit:=LedW;
          exit;
        end;
      end
      else if(wc.controls[ii] is TjanSchakelRelais) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sSchakel:=TjanSchakelRelais(wc.controls[ii]);
          if sSchakel.IsContactInput(Po) then
            sSchakel.SetContact(Vi, SrcVolt)                          // R1: contact
          else if sSchakel.Lit <> (Vi and RailOK(sSchakel)) then
            sSchakel.Lit:=Vi and RailOK(sSchakel);                   // R+: spoel
          exit;
        end;
      end
      else if(wc.controls[ii] is TjanSimRelais) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sRelais:=TjanSimRelais(wc.controls[ii]);
          If Srelais.Lit <> (Vi and RailOK(Srelais)) then Srelais.Lit:=Vi and RailOK(Srelais);
          exit;
        end;
      end

      else if(wc.controls[ii] is TjanSimBuzzer) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sBuzzer:=TjanSimBuzzer(wc.controls[ii]);
          if SBuzzer.Lit <> (Vi and RailOK(SBuzzer)) then SBuzzer.Lit:=Vi and RailOK(SBuzzer);
          exit;
        end;
      end
      //
      else if (wc.controls[ii] is TjanMeter) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sMeter:=TjanMeter(wc.controls[ii]);
          // nu wordt gekontroleer of p is in een van de 2 input area's
          R:=rect(sMeter.left+5,sMeter.top+ 35,sMeter.left+13,sMeter.Top+43);
         // in input gate 0
         if ptinrect(R,Po) and SMeter.Gates[0].Active then
          begin
            SMeter.Input1:=vi; SMeter.PlusVolt:=SrcVolt; exit;
          end;
          R:=rect(sMeter.left+ 85,sMeter.top+ 35,sMeter.left+ 93,sMeter.Top+ 43);
          // in input gate 2
          if ptinrect(R,Po) and SMeter.Gates[2].Active then
          begin
            SMeter.Input3:=vi; SMeter.MinVolt:=SrcVolt; exit;
          end;
        end;
      end
      else if (wc.controls[ii] is TjanTeller) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sTeller:=TjanTeller(wc.controls[ii]);
          // now check if p is in one of the 2 input area's
          R:=rect(sTeller.left-d,sTeller.top,sTeller.left+32,sTeller.Top+22);
          if ptinrect(R,Po) and sTeller.Gates[0].Active then
          begin  // input is op Re (reset)
             if sTeller.reset <> vi then sTeller.reset:=vi;
            exit;
          end;
          R:=rect(sTeller.left-d,sTeller.top+45,sTeller.left+32,sTeller.Top+64);
          if ptinrect(R,Po) and sTeller.Gates[1].Active then
          begin  // input is op Te (teller)
            //if puls <> 0  then
            if sTeller.telop <> vi then sTeller.telop:=vi;
            //puls:=0;
            exit;
          end;
        end;
      end
      else if (wc.controls[ii] is TjanMemory) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        // now check if p is in one of the imput area's ( Gates[0] )
        if ptinrect(R,Po) then
        begin
          sMemory:=TjanMemory(wc.controls[ii]);
          // data-ingang 8-4-2-1 of schrijfingang S
          kb:=sMemory.DataIndexAt(Po);
          if kb>=0 then
          begin
            sMemory.ZetData(kb, vi);
            exit;
          end;
            R:=rect(sMemory.left + 17 ,sMemory.top + 120,sMemory.left + 30,sMemory.Top + 130);
          if ptinrect(R,Po) and sMemory.Gates[0].Active then
            begin  // input is op schrijfingang vanuit DipSwitsh
              if not sMemory.Connector then sMemory.Connector:=true;
              sMemory.schrijf:=TSchrijf;
              If TSchrijf=true then sMemory.Bits:=Ledd;
              TSchrijf:=false;
              //sMemory.telop:=vi;
              exit;
            end;
          R:=rect(sMemory.left + 55 ,sMemory.top + 33,sMemory.left + 65,sMemory.Top + 42);
          // input is op adresingang A16 (bovenste helft van het geheugen)
          if ptinrect(R,Po) then
          begin if sMemory.ButtonDown <> vi then sMemory.ButtonDown:=vi; end;
          R:=rect(sMemory.left + 80 ,sMemory.top + 33,sMemory.left + 90,sMemory.Top + 42);
          // input is op adressingang A8
          if ptinrect(R,Po) and sMemory.Gates[1].Active then
          Begin sMemory.A8:=vi;end;
          R:=rect(sMemory.left + 105 ,sMemory.top + 33,sMemory.left + 115,sMemory.Top + 42);
          // input is op adressingang A4
          if ptinrect(R,Po) and sMemory.Gates[7].Active then
          begin sMemory.A4:=vi;end;
          R:=rect(sMemory.left + 130 ,sMemory.top + 33,sMemory.left + 140,sMemory.Top + 42);
          // input is op adressingang A2
          if ptinrect(R,Po) and sMemory.Gates[8].Active then
          begin sMemory.A2:=vi;end;
          R:=rect(sMemory.left + 155 ,sMemory.top + 33,sMemory.left + 165,sMemory.Top + 42);
          // input is op adressingang A1
          if ptinrect(R,Po) and sMemory.Gates[9].Active then
            begin sMemory.A1:=vi;end;
          sMemory.Invalidate;
        end;
      end
      else if (wc.controls[ii] is TjanLogic) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sLog:=TjanLogic(wc.controls[ii]);
          // now check if p is in one of the 3 input area's
          R:=rect(sLog.left-d,sLog.top,sLog.left+32,sLog.Top+22);
          if ptinrect(R,Po) and SLog.Gates[0].Active then
          begin  // input is gate 0
            if SLog.Input1 <> vi then SLog.Input1:=vi;
            exit;
          end;
          R:=rect(sLog.left-d,sLog.top+23,sLog.left+32,sLog.Top+44);
          if ptinrect(R,Po) and SLog.Gates[1].Active then
          begin  // input is gate 1
           if SLog.Input2 <> Vi then SLog.input2:=vi;
            exit;
          end;
          R:=rect(sLog.left-d,sLog.top+45,sLog.left+32,sLog.Top+64);
          if ptinrect(R,Po) and SLog.Gates[2].Active then
          begin  // input is gate 2
            if SLog.Input3 <> Vi then SLog.Input3:=vi;
            exit;
          end;
        end;
      end;
    end;
  end;

  // mag het eind APt als logische uitgang een klem van de voedingskring
  // voeden? getvi herkent het schakelrelais aan heel zijn vlak: alleen het
  // contact R2 (rechtsboven) is een uitgang, R+ (de spoel) is een ingang;
  // een voltmeter meet alleen
  function LogicUitgangOp(const APt: TPoint): Boolean;
  var
    q: Integer;
    Rr: TRect;
  begin
    Result := True;
    for q := 0 to wc.ControlCount - 1 do
      if (wc.Controls[q] is TjanMeter) or (wc.Controls[q] is TjanSchakelRelais) then
      begin
        Rr := wc.Controls[q].BoundsRect;
        InflateRect(Rr, ConSize, 0);
        if not PtInRect(Rr, APt) then Continue;
        if wc.Controls[q] is TjanMeter then Exit(False);
        Exit((APt.X >= wc.Controls[q].Left + wc.Controls[q].Width div 2) and
             (APt.Y <= wc.Controls[q].Top + 25));
      end;
  end;

begin
  // connect input and output using the conPos
  d2:=conSize div 2;
  d:=conSize;
  xw:=width-1;
  yh:=height-1;
  wc:=parent;
  case conPos of
    jcpTL:
      begin
        Pi:=pp(d2,d2);
        Po:=pp(xw-d2,yh-d2);
      end;
    jcpTR:
      begin
        Pi:=pp(xw-d2,d2);
        Po:=pp(d2,yh-d2);
      end;
    jcpBR:
      begin
        Pi:=pp(xw-d2,yh-d2);
        Po:=pp(d2,d2);
      end;
    jcpBL:
      begin
        Pi:=pp(d2,yh-d2);
        Po:=pp(xw-d2,d2);
      end;
  end;
  // draad vanaf een voedingsrail (eventueel achterstevoren gelegd)
  FLogicBron:=False;
  RailSrc:=RailAtPoint(wc,Pi);
  if RailSrc=nil then
  begin
    RailSrc:=RailAtPoint(wc,Po);
    if RailSrc<>nil then
    begin
      pl:=Pi; Pi:=Po; Po:=pl;
    end
    // draad tussen een klem in de voedingskring en iets anders: is dat andere
    // eind een logische uitgang (poort, flipflop, teller, LogicRun ...), dan
    // is die de bron en voedt ze de klem met 5 V; anders is de klem de bron
    // (een schakelaar, sensor ... naar een ingang), ook achterstevoren getekend
    else if VoedingsKlemOp(wc,Pi) <> VoedingsKlemOp(wc,Po) then
    begin
      if VoedingsKlemOp(wc,Pi) then
      begin
        pl:=Pi; Pi:=Po; Po:=pl;     // het andere eind eerst als bron proberen
      end;
      FLogicBron:=LogicUitgangOp(Pi) and getvi;
      if not FLogicBron then
      begin
        pl:=Pi; Pi:=Po; Po:=pl;     // geen logische uitgang: de klem is de bron
      end;
    end;
  end;
  // voedingsdraad (rail -> voedingsbolletje): geen signaal, RailOf regelt
  // de voeding van het component
  if (RailSrc<>nil) and (PowerDotAt(wc,Po) or (RailAtPoint(wc,Po)<>nil)) then
  begin
    SetPower(RailSrc.Powered);
    exit;
  end;
  LedW:=#0; // enkel teller/geheugen vullen dit in; anders toont het display 0/1
  if getvi then
  Begin
  // bronnen zonder eigen spanning (poorten, teller, ...): hoog = 5 V
  if SrcVolt < 0 then
    if Vi then SrcVolt := RailMaxVolt else SrcVolt := 0;
  setvo;
  end;
end;

procedure TjanConnector.DisConnect;
var Pi,Po:TPoint;
    R:Trect;
    i,g,d,d2,xw,yh:integer;
    wc:TWinControl;
    Vi:boolean;
    sKnop:TjanSimKnop;
    sPuls:TjanSimPuls;
    sSensor:TjanSimSensor;
    sWarm:TjanSimWarm;
    sBut:TjanSimButton;
    SDipSwitsh:TjanDipSwitsh;
    sLog:TjanLogic;
    sTeller:TjanTeller;
    sMemory:TjanMemory;
    sMeter:TjanMeter;
    sLight:TjanSimLight;
    sDisplay:TjanDisplay;
    sSchakel:TjanSchakelRelais;
    sRelais:TjanSimRelais;
    sBuzzer:TjanSimBuzzer;
  // convert a corner point to a parent point
  function pp(x,y:integer):TPoint;
  var p:Tpoint;
  begin
    p:=point(x,y);
    p:=clienttoscreen(p);
    result:=wc.ScreenToClient(p);
  end;

  procedure setVo;
  var p:Tpoint;
      ii,Q:integer;
  begin
    if vi=true then setpower(true) else setpower(false);
    for ii:=0 to wc.ControlCount-1 do
    begin
      // LogicRun: ingang wordt na het loskoppelen uitgezet (DisConnectFinal)
      if (wc.controls[ii] is TjanLogicRun) then
      begin
        Q:=TjanLogicRun(wc.controls[ii]).InputPinAt(Po);
        if Q>=0 then
        begin
          DisCon:=TjanLogicRun(wc.controls[ii]);
          DisConI:=Q+1;
          exit;
        end;
        continue;
      end;
      if (wc.controls[ii] is TjanSimMotor) then
      begin
        Q:=TjanSimMotor(wc.controls[ii]).InputPinAt(Po);
        if Q>=0 then
        begin
          DisCon:=TjanSimMotor(wc.controls[ii]);
          DisConI:=Q+1;
          exit;
        end;
        continue;
      end;
      if (wc.controls[ii] is TjanSimStappenteller) then
      begin
        Q:=TjanSimStappenteller(wc.controls[ii]).InputPinAt(Po);
        if Q>=0 then
        begin
          DisCon:=TjanSimStappenteller(wc.controls[ii]);
          DisConI:=Q+1;
          exit;
        end;
        continue;
      end;
      if (wc.controls[ii] is TjanSimPersoon) then
      begin
        Q:=TjanSimPersoon(wc.controls[ii]).InputPinAt(Po);
        if Q>=0 then
        begin
          DisCon:=TjanSimPersoon(wc.controls[ii]);
          DisConI:=Q+1;
          exit;
        end;
        continue;
      end;
      if (wc.controls[ii] is TjanSimLight) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sLight:=TjanSimLight(wc.controls[ii]);
          SLight.Lit:=false;
          DisCon:=sLight;
          exit;
        end;
      end
      else if (wc.controls[ii] is TjanDipSwitsh) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sDipSwitsh:=TjanDipSwitsh(wc.controls[ii]);
          sDipSwitsh.Down:=false;
          DisCon:=sDipSwitsh;
          exit;
        end;
      end
      else if (wc.controls[ii] is TjanDisplay) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sDisplay:=TjanDisplay(wc.controls[ii]);
          if sDisplay.BcdIndexAt(Po)>=0 then
            sDisplay.ZetBcd(sDisplay.BcdIndexAt(Po), False)
          else
            SDisplay.digit:='0';
          DisCon:=sDisplay;
          exit;
        end;
      end
      else if (wc.controls[ii] is TjanSchakelRelais) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sSchakel:=TjanSchakelRelais(wc.controls[ii]);
          if sSchakel.IsContactInput(Po) then
            sSchakel.SetContact(False, 0)                             // R1 los
          else
          begin
            sSchakel.Lit:=false;                                      // spoel los
            DisCon:=sSchakel;
          end;
          exit;
        end;
      end
      else if (wc.controls[ii] is TjanSimRelais) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sRelais:=TjanSimRelais(wc.controls[ii]);
          SRelais.Lit:=false;
          DisCon:=sRelais;
          exit;
        end;
      end
      else if (wc.controls[ii] is TjanSimBuzzer) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sBuzzer:=TjanSimBuzzer(wc.controls[ii]);
          SBuzzer.Lit:=false;
          DisCon:=sBuzzer;
          exit;
        end;
      end
      //
      else if (wc.controls[ii] is TjanMeter) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sMeter:=TjanMeter(wc.controls[ii]);
          // now check if p is in one of the 3 input area's
          // zelfde aansluitingen als in Connect: + links (5,35), - rechts (85,35)
          R:=rect(sMeter.left+1,sMeter.top+31,sMeter.left+17,sMeter.Top+47);
          if ptinrect(R,Po) and sMeter.Gates[0].Active then
          begin  // input is gate 0
          DisCon:=sMeter;
          DisConI:=1;
//            SLog.Input1:=false;
            exit;
          end;

          //R:=rect(sMeter.left-d,sMeter.top+45,sMeter.left+32,sMeter.Top+64);
          R:=rect(sMeter.left+81,sMeter.top+31,sMeter.left+97,sMeter.Top+47);

          if ptinrect(R,Po) and sMeter.Gates[2].Active then
          begin  // input is gate 2
          DisCon:=sMeter;
          DisConI:=3;
          exit;
          end;
        end;
      end

      else if (wc.controls[ii] is TjanTeller) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sTeller:=TjanTeller(wc.controls[ii]);
          // now check if p is in one of the 3 input area's
          R:=rect(sTeller.left-d,sTeller.top,sTeller.left+32,sTeller.Top+22);
          if ptinrect(R,Po) and sTeller.Gates[0].Active then
          begin  // input is gate 0
          DisCon:=sTeller;
          DisConI:=1;
          exit;
          end;
          R:=rect(sTeller.left-d,sTeller.top+45,sTeller.left+32,sTeller.Top+64);
          if ptinrect(R,Po) and sTeller.Gates[2].Active then
          begin  // input is gate 2
          DisCon:=sTeller;
          DisConI:=3;
            exit;
          end;
        end;
      end

      //kontroleren
      {
      FGates[0].pos:=point(120,64); FGates[0].Active:=true;   // imput vanuit dipswitsh
      FGates[1].pos:=point(80,33); FGates[1].Active:=true;    // imput adress bit8
      FGates[7].pos:=point(105,33); FGates[7].Active:=true;   // imput adress bit4
      FGates[8].pos:=point(130,33); FGates[8].Active:=true;   // imput adress bit2
      FGates[9].pos:=point(155,33); FGates[9].Active:=true;   // imput adress bit1
      }
      else if (wc.controls[ii] is TjanMemory) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sMemory:=TjanMemory(wc.controls[ii]);
          // draad van een data- of schrijfingang los: die ingang wordt 0
          if sMemory.DataIndexAt(Po)>=0 then
          begin
            sMemory.ZetData(sMemory.DataIndexAt(Po), False);
            exit;
          end;
          // draad van A16 los: terug naar de onderste helft
          if ptinrect(rect(sMemory.left + 55, sMemory.top + 33, sMemory.left + 65, sMemory.top + 42), Po) then
          begin
            sMemory.ButtonDown:=False;
            exit;
          end;
          // now check if p is in one of the 3 input area's
          R:=rect(sMemory.left-d,sMemory.top+64,sMemory.left+120,sMemory.Top+72);
          if ptinrect(R,Po) and sMemory.Gates[0].Active then
          begin  // input is gate 0
          DisCon:=sMemory;
          DisConI:=1;
          exit;
          end;
          R:=rect(sMemory.left-d,sMemory.top+33,sMemory.left+32,sMemory.Top+41);
          if ptinrect(R,Po) and sMemory.Gates[1].Active then
          begin  // input is gate 2
          DisCon:=sMemory;
          DisConI:=3;
            exit;
          end;
        end;
      end

      else if (wc.controls[ii] is TjanLogic) then
      begin
        R:=wc.Controls[ii].BoundsRect;
        inflaterect(R,d,0);
        if ptinrect(R,Po) then
        begin
          sLog:=TjanLogic(wc.controls[ii]);
          // now check if p is in one of the 3 input area's
          R:=rect(sLog.left-d,sLog.top,sLog.left+32,sLog.Top+22);
          if ptinrect(R,Po) and SLog.Gates[0].Active then
          begin  // input is gate 0
          DisCon:=sLog;
          DisConI:=1;
//            SLog.Input1:=false;
            exit;
          end;
          R:=rect(sLog.left-d,sLog.top+23,sLog.left+32,sLog.Top+44);
          if ptinrect(R,Po) and SLog.Gates[1].Active then
          begin  // input is gate 1
          DisCon:=sLog;
          DisConI:=2;
//            SLog.input2:=false;
            exit;
          end;
          R:=rect(sLog.left-d,sLog.top+45,sLog.left+32,sLog.Top+64);
          if ptinrect(R,Po) and SLog.Gates[2].Active then
          begin  // input is gate 2
          DisCon:=sLog;
          DisConI:=3;
//            SLog.Input3:=false;
            exit;
          end;
        end;
      end;
    end;
  end;



begin
  // connect input and output using the conPos
  DisCon:=nil;
  disConI:=0;
  d2:=conSize div 2;
  d:=conSize;
  xw:=width-1;
  yh:=height-1;
  wc:=parent;
  case conPos of
    jcpTL:
      begin
        Pi:=pp(d2,d2);
        Po:=pp(xw-d2,yh-d2);
      end;
    jcpTR:
      begin
        Pi:=pp(xw-d2,d2);
        Po:=pp(d2,yh-d2);
      end;
    jcpBR:
      begin
        Pi:=pp(xw-d2,yh-d2);
        Po:=pp(d2,d2);
      end;
    jcpBL:
      begin
        Pi:=pp(d2,yh-d2);
        Po:=pp(xw-d2,d2);
      end;
  end;
  // clear logic inputs and lights
  setvo;
end;
