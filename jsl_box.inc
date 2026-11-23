// janSimLogic.pas, deel: paneel: klok, waarheidstabel, laden en bewaren (ingevoegd met {$I jsl_box.inc})

{ TjanSimLogicBox }

procedure TjanSimLogicBox.cpuOnTimer(sender: TObject);
var wc:TWinControl;
    i:integer;
begin
  Inc(SimRonde);
  wc:=parent;
  // eerst de voedingskring: spanning op de rails, stroom in de meters.
  // Alleen de echte timer laat de tijd verder lopen (condensatoren); de
  // waarheidstabel roept dit ook aan, zonder tijd.
  if (sender = cpu) then
  begin
    if CondLaatste > 0 then
    begin
      CondDt := (GetTickCount64 - CondLaatste) / 1000;
      if CondDt < 0.01 then CondDt := 0.01;
      if CondDt > 0.2 then CondDt := 0.2;
    end;
    CondLaatste := GetTickCount64;
    SimTijd := SimTijd + CondDt;
    CondStap := True;
    try
      UpdateSupply(wc, True);
    finally
      CondStap := False;
    end;
  end
  else
    UpdateSupply(wc, True);
  for i:=0 to wc.ControlCount-1 do
    if (wc.controls[i] is TjanConnector) then
      TjanConnector(wc.controls[i]).connect;

end;

function TjanSimLogicBox.Waarheidstabel(Ins, Outs: TList; Rijen: TStrings;
  out Geheugen: Boolean; MaxIn: Integer): Integer;
var
  wc: TWinControl;
  c: TControl;
  i, k, r, NIn, Rondes, Draden: Integer;
  Oud: array of Boolean;
  S: string;

  // van boven naar onder, bij dezelfde hoogte van links naar rechts
  procedure Sorteer(L: TList);
  var a, b: Integer; t: Pointer;
  begin
    for a := 1 to L.Count - 1 do
    begin
      b := a;
      while (b > 0) and
        ((TControl(L[b - 1]).Top > TControl(L[b]).Top) or
         ((TControl(L[b - 1]).Top = TControl(L[b]).Top) and
          (TControl(L[b - 1]).Left > TControl(L[b]).Left))) do
      begin
        t := L[b - 1]; L[b - 1] := L[b]; L[b] := t;
        Dec(b);
      end;
    end;
  end;

  function IsDown(C: TControl): Boolean;
  begin
    Result := InvoerAan(C);
  end;

  procedure ZetDown(C: TControl; V: Boolean);
  begin
    ZetInvoer(C, V);
  end;

  // alle draden genoeg keer laten rekenen: per ronde gaat een signaal
  // minstens één draad verder
  procedure Reken;
  var j: Integer;
  begin
    for j := 1 to Rondes do cpuOnTimer(nil);
  end;

begin
  Ins.Clear; Outs.Clear; Rijen.Clear;
  Geheugen := False;
  wc := Parent;
  if wc = nil then Exit(1);
  Draden := 0;
  for i := 0 to wc.ControlCount - 1 do
  begin
    c := wc.Controls[i];
    if not c.Visible then Continue;
    if IsInvoer(c) then Ins.Add(c)
    else if IsUitvoer(c) then Outs.Add(c)
    else if c is TjanConnector then Inc(Draden)
    else if (c is TjanSimStappenteller) or (c is TjanTeller) or (c is TjanMemory) or
            (c is TjanSimPuls) or (c is TjanLogicRun) or (c is TjanSimStopwatch) then
      Geheugen := True;
  end;
  Sorteer(Ins);
  Sorteer(Outs);
  if Ins.Count = 0 then Exit(1);
  if Outs.Count = 0 then Exit(2);
  if Ins.Count > MaxIn then Exit(3);
  NIn := Ins.Count;
  Rondes := Draden + 5;
  if Rondes > 400 then Rondes := 400;
  SetLength(Oud, NIn);
  for i := 0 to NIn - 1 do Oud[i] := IsDown(TControl(Ins[i]));
  try
    for k := 0 to (1 shl NIn) - 1 do
    begin
      // A (de bovenste) is het hoogste bit: 00, 01, 10, 11 ...
      for i := 0 to NIn - 1 do
        ZetDown(TControl(Ins[i]), ((k shr (NIn - 1 - i)) and 1) = 1);
      Reken;
      S := '';
      for i := 0 to NIn - 1 do
        if ((k shr (NIn - 1 - i)) and 1) = 1 then S := S + '1' else S := S + '0';
      for r := 0 to Outs.Count - 1 do
        S := S + UitvoerTeken(TControl(Outs[r]));
      Rijen.Add(S);
    end;
  finally
    for i := 0 to NIn - 1 do ZetDown(TControl(Ins[i]), Oud[i]);
    Reken;
  end;
  Result := 0;
end;

function TjanSimLogicBox.TelPoort(const Code: string): Integer;
var
  i: Integer;
  wc: TWinControl;
  c: TControl;
begin
  Result := 0;
  wc := Parent;
  if wc = nil then Exit;
  for i := 0 to wc.ControlCount - 1 do
  begin
    c := wc.Controls[i];
    if c.Visible and (c is TjanLogic) and
       SameText(LogicFuncCode(TjanLogic(c).LogicFunc), Code) then
      Inc(Result);
  end;
end;

class function TjanSimLogicBox.PoortWoord(const Code, BTaal: string): string;
var
  F: TjanLogicFunc;
begin
  if LogicFuncFromCode(UpperCase(Code), F) then
    Result := LogicFuncWoord(F, BTaal)
  else
    Result := Code;
end;

class function TjanSimLogicBox.IsInvoer(C: TControl): Boolean;
begin
  Result := (C is TjanSimKnop) or (C is TjanSimButton) or (C is TjanDipSwitsh) or
    (C is TjanSimSensor) or (C is TjanSimWarm) or (C is TjanSchakelaar2);
end;

class function TjanSimLogicBox.IsUitvoer(C: TControl): Boolean;
begin
  Result := (C is TjanSimLight) or (C is TjanSimBuzzer) or (C is TjanSimRelais) or
    (C is TjanSimMotor) or (C is TjanDisplay);
end;

class function TjanSimLogicBox.InvoerAan(C: TControl): Boolean;
begin
  if C is TjanSimKnop then Result := TjanSimKnop(C).Down
  else if C is TjanSimButton then Result := TjanSimButton(C).Down
  else if C is TjanDipSwitsh then Result := TjanDipSwitsh(C).Down
  else if C is TjanSimSensor then Result := TjanSimSensor(C).Down
  else if C is TjanSimWarm then Result := TjanSimWarm(C).Down
  else if C is TjanSchakelaar2 then Result := TjanSchakelaar2(C).Aan
  else Result := False;
end;

class procedure TjanSimLogicBox.ZetInvoer(C: TControl; V: Boolean);
begin
  if C is TjanSimKnop then TjanSimKnop(C).Down := V
  else if C is TjanSimButton then TjanSimButton(C).Down := V
  else if C is TjanDipSwitsh then TjanDipSwitsh(C).Down := V
  else if C is TjanSimSensor then TjanSimSensor(C).Down := V
  else if C is TjanSimWarm then TjanSimWarm(C).Down := V
  else if C is TjanSchakelaar2 then TjanSchakelaar2(C).Aan := V;
end;

class function TjanSimLogicBox.UitvoerTeken(C: TControl): Char;
var
  B: Boolean;
begin
  Result := '0';
  if C is TjanSimMotor then
  begin
    if TjanSimMotor(C).Inputs[0] and not TjanSimMotor(C).Inputs[1] then Result := 'L'
    else if TjanSimMotor(C).Inputs[1] and not TjanSimMotor(C).Inputs[0] then Result := 'R';
    Exit;
  end;
  if C is TjanDisplay then
  begin
    Result := TjanDisplay(C).Digit;
    if Result = ' ' then Result := '-';   // zonder voeding: donker
    Exit;
  end;
  if C is TjanSimLight then B := TjanSimLight(C).Lit
  else if C is TjanSimBuzzer then B := TjanSimBuzzer(C).Lit
  else if C is TjanSimRelais then B := TjanSimRelais(C).Lit
  else B := False;
  if B then Result := '1';
end;

function TjanSimLogicBox.Paneelvorm: string;
var
  wc: TWinControl;
  c: TControl;
  i: Integer;
begin
  Result := IntToStr(FKillCount);
  wc := Parent;
  if wc = nil then Exit;
  for i := 0 to wc.ControlCount - 1 do
  begin
    c := wc.Controls[i];
    if (not c.Visible) or (c is TjanGroupSelect) or (c = Self) or
       (c is TjanSimPersoon) then Continue;   // persoon, wagentje ... bewegen zelf
    Result := Result + '|' + c.ClassName + ':' + IntToStr(c.Left) + ',' +
      IntToStr(c.Top) + ',' + IntToStr(c.Width) + ',' + IntToStr(c.Height);
    if c is TjanLogic then Result := Result + ':' + TjanLogic(c).L_Type;
  end;
end;

constructor TjanSimLogicBox.create(AOwner: Tcomponent);
begin
  inherited Create(AOwner);
  DraadBox := Self;
  // Init Hint verschijning bij knoppen
  ShowHint := True;
  ParentShowHint := False;
  FLastHintText := '';

  // InitTools;




   // ⬇️ Deze box als globale referentie onthouden
  GlobalSimBox := Self;

  if (Align=(alTop)) or (Align=(alBottom))then
  begin
  height:=45;
  FKnopLeft:=2;FKnopTop:=4;FSpatie:=2;
  end;
  if (Align=(alLeft)) or (Align=(alRight))then
    begin
    width:=35;
    FKnopLeft:=9;
    FKnopTop:=25;
    FSpatie:=2;
    end;
  FOpen:=true;
  FFirst:=false;
  FNew:=false;
  FDraden:=false;
  FImputColor:=clSilver;// clgreen;
  FOutputColor:=clSilver;//clBlue;
  FBoxTaal:= stDutch;
  FVerwerkingColor:=clSilver;//clRed;
  FFilterLijst:= TStringList.Create;
  FOefening := TStringList.Create;
  templijst:=TStringList.Create;
  tempFile:=TStringList.Create;
  // opladen van speciale cursors
  Screen.Cursors[crDrukknop]    := LoadCursor(hInstance,  'DRUKKNOP');
  Screen.Cursors[crSchakelaar]    := LoadCursor(hInstance,  'SCHAKELAAR');
  Screen.Cursors[crSensor]    := LoadCursor(hInstance,  'SENSOR');
  Screen.Cursors[crWarm]    := LoadCursor(hInstance,  'WARM');
  Screen.Cursors[crPuls]    := LoadCursor(hInstance,  'PULS');
  Screen.Cursors[crDip]    := LoadCursor(hInstance,  'DIP');
  Screen.Cursors[crAnd]    := LoadCursor(hInstance,  'AND');
  Screen.Cursors[crOr]    := LoadCursor(hInstance,  'OR');
  Screen.Cursors[crNot]    := LoadCursor(hInstance,  'NOT');
  Screen.Cursors[crTeller]    := LoadCursor(hInstance,  'TELLER');
  Screen.Cursors[crGeheugen]    := LoadCursor(hInstance,  'GEHEUGEN');
  Screen.Cursors[crLamp]    := LoadCursor(hInstance,  'LAMP');
  Screen.Cursors[crRelais]    := LoadCursor(hInstance,  'RELAIS');
  Screen.Cursors[crZoemer]    := LoadCursor(hInstance,  'ZOEMER');
  Screen.Cursors[crDisplay]    := LoadCursor(hInstance,  'DISPLAY');
  Screen.Cursors[crDraad]    := LoadCursor(hInstance,  'DRAAD');
  Screen.Cursors[crMeter]    := LoadCursor(hInstance,  'VOLT');

  //aanmaken bitmaps in het geheugen
  bmCon:=TBitmap.create;//bmCon2:=TBitmap.Create;
  bmLogicAnd:=TBitmap.create;bmLogicOr:=TBitmap.create;
  bmButton:=TBitmap.create;bmLogicNot:=TBitmap.create;
  bmLight:=TBitmap.create;bmRelais:=TBitmap.create;
  bmKnop:=TBitmap.Create; bmPuls:=TBitmap.Create;
  bmBuzzer:=TBitmap.Create;bmSensor:=TBitmap.Create;bmWarm:=TBitmap.Create;
  bmTeller:=TBitmap.Create;bmMemory:=TBitmap.Create;bmDisplay:=TBitmap.Create;
  bmDipSwitsh:=TBitmap.Create;bmMeter:=TBitmap.Create;


 { bmCon2.LoadFromResourceName(HInstance,'RCON2');
  bmCon2.Transparent := True;
  bmCon2.TransParentColor := bmCon2.canvas.pixels[0,0];}

  bmButton.LoadFromResourceName(HInstance,'RBUTTON');
  bmMeter.LoadFromResourceName(HInstance,'VOLT');


  bmKnop.LoadFromResourceName(HInstance,'RKNOP');
  bmPuls.LoadFromResourceName(HInstance,'RPULS');
  bmCon.LoadFromResourceName(HInstance,'RCON2');

  bmLogicAnd.LoadFromResourceName(HInstance,'L_AND');
  bmLogicAnd.Transparent := True;
  bmLogicAnd.TransParentColor := bmLogicAnd.canvas.pixels[0,0];

  bmLogicOr.LoadFromResourceName(HInstance,'L_OR');
  bmLogicOr.Transparent := True;
  bmLogicOr.TransParentColor := bmLogicAnd.canvas.pixels[0,0];

  bmLogicNot.LoadFromResourceName(HInstance,'L_NOT');
  bmLogicNot.Transparent := True;
  bmLogicNot.TransParentColor := bmLogicNot.canvas.pixels[0,0];

  bmLight.LoadFromResourceName(HInstance,'RLIGHT');
  bmRelais.LoadFromResourceName(HInstance,'RRELAIS');
  bmRelais.Transparent := True;
  bmRelais.TransParentColor := bmRelais.canvas.pixels[0,0];

  bmDipSwitsh.LoadFromResourceName(HInstance,'RDIPSW');
  bmDipSwitsh.Transparent := True;
  bmDipSwitsh.TransParentColor := bmDipSwitsh.canvas.pixels[0,0];

  bmTeller.LoadFromResourceName(HInstance,'RTELLER');
  bmTeller.Transparent := True;
  bmTeller.TransParentColor := bmTeller.canvas.pixels[0,0];

  bmMemory.LoadFromResourceName(HInstance,'RMEMORY');
  bmMemory.Transparent := True;
  bmMemory.TransParentColor := bmMemory.canvas.pixels[0,0];

  bmBuzzer.LoadFromResourceName(HInstance,'RBUZZER');
  bmBuzzer.Transparent := True;
  bmBuzzer.TransParentColor := bmBuzzer.canvas.pixels[0,0];

  bmSensor.LoadFromResourceName(HInstance,'RSENSOR');
  bmSensor.Transparent := True;
  bmSensor.TransParentColor := bmSensor.canvas.pixels[0,0];

  bmWarm.LoadFromResourceName(HInstance,'RWARM');
  bmWarm.Transparent := True;
  bmWarm.TransParentColor := bmWarm.canvas.pixels[0,0];

  bmDisplay.LoadFromResourceName(HInstance,'RDISPLAY');
  bmDisplay.Transparent := True;
  bmDisplay.TransParentColor := bmDisplay.canvas.pixels[0,0];
  // opzetten van knoppen (imputobjecten)
  FSymbolen:=IEC;
  FDrukknop:=True;FSchakelaar:=True;FPuls:=True;FSensor:=True;FWarm:=True;FTeller:=true;
  // aantal imputobjecten
  FImputAantal:=6;
  // opzetten van knoppen (Verwerkingsobjecten)
  FLogicAnd:=True;FMemory:=true;FTeller:=true;FLogicOr:=True;FLogicNot:=True;FLogicNand:=True;FLogicNor:=True;FLogicXor:=True;FStappen:=True;FFlipFlopK:=True;FStopwatch:=True;
  // aantal Verwerkingobjecten
  FVerwerkingAantal:=7;
  // opzetten van knoppen (Uitvoerobjecten)
  FLamp:=True;FRelais:=True;FSchakelRelais:=True;FBuzzer:=True;FMotor:=True;FPersoon:=True;FWagen:=True;FMuziek:=True;FVerkeer:=True;FSlagboom:=True;FDisplay:=true;
  FVoeding:=True;
  FBronK:=True;FZekeringK:=True;FAmpMeterK:=True;FWeerstandK:=True;FLamp2K:=True;FSchak2K:=True;FVolt2K:=True;FLed2K:=True;FCondK:=True;FWattMeterK:=True;FPotK:=True;FDiodeK:=True;FWisselK:=True;FScoopK:=True;FTransK:=True;FLdrK:=True;FNtcK:=True;FWschK:=True;FPuls2K:=True;FDip2K:=True;FMagK:=True;
  // hints van led en condensator: niet in main.lfm, dus hier de standaard (NL)
  FHLed2:='maak Led met 2 klemmen (met voorschakelweerstand)';
  FHCond:='maak Condensator (laden en ontladen)';
  FHWattMeter:='maak Wattmeter';
  FHPot:='maak Potentiometer (drie klemmen)';
  FHDiode:='maak Diode';
  FHWissel:='maak Wisselspanningsbron';
  FHScoop:='maak Oscilloscoop';
  FHTrans:='maak Transistor';
  FHWsch:='maak Wisselschakelaar';
  FHPuls2:='maak Impulsgenerator';
  FHDip2:='maak Dipschakelaar';
  FHMagneet:='maak Staafmagneet';
  FHKompas:='maak Kompas';
  FHVeldplaat:='maak Veldlijnenplaat';
  FHSpoel:='maak Spoel';
  FHIJzer:='maak Spijker (ijzer)';
  FHLdr:='maak LDR';
  FHNtc:='maak NTC';
  FOutputAantal:=5;

  FDraad:=True;FGrid:=true;//FSave:=true;

  //DReset:=false;
  DRelais:=false;DSchakel:=false;DBuzzer:=false;DMotor:=false;DPersoon:=false;DWagen:=false;DMuziek:=false;DVerkeer:=false;DSlagboom:=false;DSensor:=false;DWarm:=false;
  DCon:=false;DLogicAnd:=false;DLogicOr:=false;DLogicNot:=false;DLogicNand:=false;DLogicNor:=false;DLogicXor:=false;
  DButton:=false;DLight:=false;DKnop:=false;DPuls:=false;
  DTeller:=false;DStappen:=false;DFlipFlop:=false;DStopwatch:=false;DMemory:=false;DDisplay:=false;DGrid:=false;//DSave:=false;

  cpu:=TTimer.Create(self);
  cpu.Enabled:=false;
  cpu.OnTimer:=cpuOnTimer;
  cpu.Interval:=50;
  // voedingskring ook buiten de simulatie (schuifregelaar, nieuwe draden)
  FSupplyTimer := TTimer.Create(Self);
  FSupplyTimer.Interval := 200;
  FSupplyTimer.OnTimer := SupplyOnTimer;
  FSupplyTimer.Enabled := True;
  FBColor:=clSilver;
  Align:=(alTop);


end;

procedure TjanSimLogicBox.Encode(tekst:TStringList);
var
  e,d: String;
  temp:TStringList;
  i: integer;
begin
  d:='';temp:=TStringlist.Create;
  for i:= 0 to tekst.count-1 do
    begin
    d:= tekst.Strings[i];
    e:=SZFullEncodeBase64(d);
    temp.Add(e)
    end;
    tekst.Clear;
    tekst.Assign(temp);
  temp.Free;
end;

procedure TjanSimLogicBox.decode(tekst:TStringList);
var
  e,d: string;
  i: integer;
  temp:TStringList;
begin
  d:='';temp:=TStringlist.Create;
  for i:= 0 to tekst.count-1 do
    Begin
    d:= tekst.Strings[i];
    e:=SZDecodeBase64(d);
    temp.Add(e)
    end;
    tekst.Clear;
    tekst.Assign(temp);
  temp.Free;
end;

destructor TjanSimLogicBox.Destroy;
begin
  if DraadBox = Self then DraadBox := nil;
  Application.RemoveAsyncCalls(Self);
 // FreeTools;
  cpu.free;
  bmBuzzer.Free;bmSensor.Free;bmWarm.Free;bmGrid.Free;bmCon.free;
  bmLogicAnd.free;bmLogicOr.free;bmLogicNot.free;
  bmButton.free;bmKnop.Free;bmPuls.Free;bmLight.free;bmRelais.Free;
  bmTeller.Free;bmMemory.Free;bmDisplay.Free;bmDipSwitsh.Free;bmMeter.Free;
  FFilterLijst.Free;templijst.Free;tempFile.Free;
  FOefening.Free;

  inherited Destroy;
end;

//nieuw voor save
FUNCTION TjanSimLogicBox.InFilterL (aCompClassName, aPropName: STRING): BOOLEAN;
// Returns TRUE, if a property is in the filterlist
VAR i: INTEGER;
BEGIN
 Result:= TRUE;
 IF FFilterLijst.Find (aPropName, i) then EXIT;
 IF FFilterLijst.Find (aCompClassName + '.' + aPropName, i) then EXIT;
 Result:= false;
END; // InfilterList

PROCEDURE TjanSimLogicBox.SetDefaultFilt;
// Initialize the filterlist
BEGIN
 WITH FFilterLijst DO
 BEGIN
  // properties that should be saved from ALL components
  Add ('Text');          // for TEdits, TCombos etc.
  Add ('Checked');       // for TCombos, TMenuItems etc.
  Add ('Position');      // for TRackBars
  Add ('InitialDir');    // for TOpENDialog, TSaveDialog etc
  Add ('FileName');      // for TOpENDialog, TSaveDialog etc
  Sort;
  Add ('TjanConnector.Left');
  Add ('TjanConnector.Top');
  Add ('TjanConnector.Width');
  Add ('TjanConnector.Height');
  Add ('TjanConnector.W_ConMode');
  Add ('TjanConnector.W_ConPos');
  Add ('TjanConnector.W_ConShape');
  Add ('TjanConnector.W_Edge');
   // *** NIEUW: logische poorten altijd volledig opslaan ***
    Add('TjanLogic.Left');
    Add('TjanLogic.Top');
    Add('TjanLogic.Width');
    Add('TjanLogic.Height');
    Add('TjanLogic.L_Type');   // => EN/OF/NIET
 END;
END; // SetDefaultFilter

procedure TjanSimLogicBox.SetPropFromStringe(obj: TObject; info: PPropInfo; const str: string);
var
  vFloat: Extended;
  fs: TFormatSettings;
  vInt: Integer;
begin
  // Veiligheid
  if (info = nil) or (info^.PropType = nil) then
    Exit;

  with info^ do
  begin
    case PropType^.Kind of

      // Enumeraties (inclusief Boolean)
      tkEnumeration:
        begin
          if SameText(str, 'True') then
            SetOrdProp(obj, info, 1)
          else if SameText(str, 'False') then
            SetOrdProp(obj, info, 0)
          else
          begin
            vInt := GetEnumValue(PropType, str);
            if vInt >= 0 then
              SetOrdProp(obj, info, vInt);
          end;
        end;

      // Integers
      tkInteger:
        begin
          if str <> '' then
            SetOrdProp(obj, info, StrToIntDef(str, 0));
        end;

      // >>> Belangrijk: Floats tolerant inlezen ("0,5" én "0.5") <<<
      tkFloat:
        begin
          fs := DefaultFormatSettings;

          // 1) proberen met huidige locale
          if not TryStrToFloat(str, vFloat, fs) then
          begin
            // 2) met punt als decimal
            fs.DecimalSeparator := '.';
            if not TryStrToFloat(str, vFloat, fs) then
            begin
              // 3) met komma als decimal
              fs.DecimalSeparator := ',';
              if not TryStrToFloat(str, vFloat, fs) then
                Exit; // totaal onleesbaar → niks zetten
            end;
          end;

          SetFloatProp(obj, info, vFloat);
        end;

      // Characters
      tkChar:
        begin
          if str <> '' then
            SetOrdProp(obj, info, Ord(str[1]));
        end;

      // Strings (Delphi én FPC-varianten)
      tkString,
      tkLString
      {$IFDEF FPC}
      , tkAString, tkWString, tkUString
      {$ENDIF}
      :
        begin
          SetStrProp(obj, info, str);
        end;

      // Andere types laten we gewoon met rust
    else
      ; // niets doen
    end;
  end;
end;


FUNCTION TjanSimLogicBox.GetPropAsStringe (obj: TObject; info: PPropInfo): STRING;
// Builds from the properties of a component a string
VAR i: LONGINT;
BEGIN
 Result:= '';
 IF info^.PropType^.Kind = tkUnknown THEN EXIT;
 WITH info^ DO BEGIN
  CASE PropType^.Kind OF
   tkEnumeration: IF PropType^.Name = 'Boolean' then BEGIN
                   IF LONGINT (GetOrdProp (obj, info)) = 0 THEN  Result:= 'FALSE'
                                                           ELSE  Result:= 'TRUE';
                   EXIT;
                  END;
   tkInteger:     BEGIN
                   i:= LONGINT (GetOrdProp(Obj,Info));
                   {IF (PropType^.Name = 'TColor') OR (PropType^.Name = 'TCursor') THEN
                    BEGIN
                    ColorToIdent (i, Result);
                    EXIT;
                    END;}
                   Result:= IntToStr (i);
                  END;
   {  WAS
   tkChar:        Result:= CHR (GetOrdProp (obj, info));
   tkString,
   tkLString:     Result:= GetStrProp (obj, info); }
   // NU
   tkChar:
     Result := Chr(GetOrdProp(obj, info));
   tkString,
   tkLString
   {$IFDEF FPC}
   , tkAString, tkWString, tkUString
   {$ENDIF}
   :
     Result := GetStrProp(obj, info);
  END; // case
 END; // WITH
END; // GetPropAsString


PROCEDURE TjanSimLogicBox.AddFilter (s: STRING);
// Adds a filter to the filterlist
BEGIN
 FFilterLijst.Add (s);
END; // AddFilter

procedure TjanSimLogicBox.SavePanel(waar: string; Paneel: TjanGridS; codec: Boolean);
var
  SFile: TStringList;
begin
  SFile := TStringList.Create;
  try
    SavePanelToList(SFile, Paneel);

    if codec then
      Decode(SFile); // of Encode, afhankelijk van jouw implementatie

    SFile.SaveToFile(waar);
  finally
    SFile.Free;
  end;
end;

function TjanSimLogicBox.PanelText(Paneel: TjanGridS): string;
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    SavePanelToList(L, Paneel);
    Result := L.Text;
  finally
    L.Free;
  end;
end;

procedure TjanSimLogicBox.LoadPanelText(const AText: string; Paneel: TjanGridS);
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    L.Text := AText;
    InternalLoadFromList(L, Paneel);
  finally
    L.Free;
  end;
end;

function TjanSimLogicBox.LayoutShift: TPoint;
begin
  case Align of
    alTop:    Result := Point(-20, Height);
    alBottom, alRight: Result := Point(-20, 0);
    alLeft:   Result := Point(Width - 20, 0);
  else
    Result := Point(0, 0);
  end;
end;

procedure TjanSimLogicBox.ShiftPanelObjects(DX, DY: Integer);
var
  i: Integer;
  c: TControl;
begin
  if (FParent = nil) or ((DX = 0) and (DY = 0)) then Exit;
  for i := 0 to FParent.ControlCount - 1 do
  begin
    c := FParent.Controls[i];
    // niet de knoppenbalk zelf en geen venster dat over het paneel ligt
    // (instellingen): dat zou bij elke momentopname mee verspringen
    if (c <> Self) and not (c is TCustomFrame) then
      c.SetBounds(c.Left + DX, c.Top + DY, c.Width, c.Height);
  end;
end;

procedure TjanSimLogicBox.SavePanelToList(SFile: TStrings; Paneel: TjanGridS);
var
  wc: TWinControl;
  i: Integer;
  c: TControl;
  lijn, modeStr, posStr, shapeStr, edgeStr, ltypeStr: string;
  Sh: TPoint;
begin
  wc := FParent;
  SFile.Clear;
  Sh := LayoutShift;
  ShiftPanelObjects(-Sh.X, -Sh.Y);   // plaatsen zoals bij de balk links
  try
    // Alle controls serialiseren
    for i := 0 to wc.ControlCount - 1 do
    begin
      c := wc.Controls[i];
      if Assigned(FSaveOnly) and (FSaveOnly.IndexOf(c) < 0) then
        Continue;

      // --- TjanConnector ---
      if c is TjanConnector then
      with TjanConnector(c) do
      begin
        case V_ConMode of
          jcmTL: modeStr := 'jcmTL';
          jcmTR: modeStr := 'jcmTR';
          jcmBL: modeStr := 'jcmBL';
          jcmBR: modeStr := 'jcmBR';
        end;

        case V_ConPos of
          jcpTL: posStr := 'jcpTL';
          jcpTR: posStr := 'jcpTR';
          jcpBL: posStr := 'jcpBL';
          jcpBR: posStr := 'jcpBR';
        end;

        case V_ConShape of
          jcsTLBR: shapeStr := 'jcsTLBR';
          jcsTRBL: shapeStr := 'jcsTRBL';
        end;

        // edge met komma in file (maar loader kan beide)
        edgeStr := FloatToStr(V_Edge);
        edgeStr := StringReplace(edgeStr, DecimalSeparator, ',', [rfReplaceAll]);

        lijn := Format(
          'TjanConnector;%d;%d;%d;%d;%s;%s;%s;%s;%d;',
          [Height, Left, Top, Width,
           modeStr, posStr, shapeStr, edgeStr, FObjectID]
        );
        SFile.Add(lijn);
      end
      else
      // --- TjanLogic ---
      if c is TjanLogic then
      with TjanLogic(c) do
      begin
        ltypeStr := LogicFuncCode(logicFunc);

        lijn := Format(
          'TjanLogic;%d;%d;%s;%d;%d;',
          [Height, Left, ltypeStr, Top, Width]
        );
        SFile.Add(lijn);
      end
      else
      // --- Alle overige (simpele) componenten ---
      if c is TjanTeller then
      begin
        with TjanTeller(c) do
          lijn := Format('TjanTeller;%d;%d;%d;%d;', [Height, Left, Top, Width]);
        SFile.Add(lijn);
      end
      else if c is TjanSimButton then
      begin
        with TjanSimButton(c) do
          lijn := Format('TjanSimButton;%d;%d;%d;%d;', [Height, Left, Top, Width]);
        SFile.Add(lijn);
      end
      else if c is TjanSimKnop then
      begin
        with TjanSimKnop(c) do
          lijn := Format('TjanSimKnop;%d;%d;%d;%d;', [Height, Left, Top, Width]);
        SFile.Add(lijn);
      end
      else if c is TjanSimSensor then
      begin
        with TjanSimSensor(c) do
          lijn := Format('TjanSimSensor;%d;%d;%d;%d;', [Height, Left, Top, Width]);
        SFile.Add(lijn);
      end
      else if c is TjanSimWarm then
      begin
        with TjanSimWarm(c) do
          lijn := Format('TjanSimWarm;%d;%d;%d;%d;', [Height, Left, Top, Width]);
        SFile.Add(lijn);
      end
      else if c is TjanSimPuls then
      begin
        with TjanSimPuls(c) do
          lijn := Format('TjanSimPuls;%d;%d;%d;%d;', [Height, Left, Top, Width]);
        // frequentie als extra veld, alleen als ze niet de standaard is
        if TjanSimPuls(c).PulsInterval <> PulsIntervalStandaard then
          lijn := lijn + IntToStr(TjanSimPuls(c).PulsInterval) + ';';
        SFile.Add(lijn);
      end
      else if c is TjanDipSwitsh then
      begin
        with TjanDipSwitsh(c) do
          lijn := Format('TjanDipSwitsh;%d;%d;%d;%d;', [Height, Left, Top, Width]);
        SFile.Add(lijn);
      end
      else if c is TjanMemory then
      begin
        with TjanMemory(c) do
          lijn := Format('TjanMemory;%d;%d;%d;%d;%s;', [Height, Left, Top, Width, InhoudTekst]);
        SFile.Add(lijn);
      end
      else if c is TjanSimLight then
      begin
        with TjanSimLight(c) do
          lijn := Format('TjanSimLight;%d;%d;%d;%d;', [Height, Left, Top, Width]);
        // led: de kleur als extra veld (een oudere Logic toont een lamp)
        if TjanSimLight(c).Kleur <> lkLamp then
          lijn := lijn + IntToStr(Ord(TjanSimLight(c).Kleur)) + ';';
        SFile.Add(lijn);
      end
      else if c is TjanSchakelRelais then
      begin
        with TjanSchakelRelais(c) do
          lijn := Format('TjanSchakelRelais;%d;%d;%d;%d;', [Height, Left, Top, Width]);
        SFile.Add(lijn);
      end
      else if c is TjanSimRelais then
      begin
        with TjanSimRelais(c) do
          lijn := Format('TjanSimRelais;%d;%d;%d;%d;', [Height, Left, Top, Width]);
        SFile.Add(lijn);
      end
      else if c is TjanSimBuzzer then
      begin
        with TjanSimBuzzer(c) do
          lijn := Format('TjanSimBuzzer;%d;%d;%d;%d;', [Height, Left, Top, Width]);
        SFile.Add(lijn);
      end
      else if c is TjanDisplay then
      begin
        with TjanDisplay(c) do
          lijn := Format('TjanDisplay;%d;%d;%d;%d;', [Height, Left, Top, Width]);
        SFile.Add(lijn);
      end
      else if c is TjanSimMotor then
        SFile.Add(Format('TjanSimMotor;%d;%d;%d;%d;', [c.Height, c.Left, c.Top, c.Width]))
      else if c is TjanSimPersoon then
        SFile.Add(Format('%s;%d;%d;%d;%d;', [c.ClassName, c.Height, c.Left, c.Top, c.Width]))
      else if c is TjanSimEindschakelaar then
        SFile.Add(Format('TjanSimEindschakelaar;%d;%d;%d;%d;%d;', [c.Height, c.Left, c.Top, c.Width, TjanSimEindschakelaar(c).Kanaal]))
      else if c is TjanSimStappenteller then
        SFile.Add(Format('%s;%d;%d;%d;%d;%d;%d;', [c.ClassName, c.Height, c.Left, c.Top, c.Width,
          TjanSimStappenteller(c).Eindwaarde, Ord(TjanSimStappenteller(c).Herhalen)]))
      else if c is TjanLogicRun then
        SFile.Add(Format('TjanLogicRun;%d;%d;%d;%d;', [c.Height, c.Left, c.Top, c.Width]) +
          TjanLogicRun(c).ProgramText + ';')
      else if c is TjanMeter then
        SFile.Add(Format('TjanMeter;%d;%d;%d;%d;', [c.Height, c.Left, c.Top, c.Width]))
      else if c is TjanRail then
        SFile.Add(RailFileLine(TjanRail(c)))
      else if c is TjanVoedingsDeel then
        SFile.Add(VoedingFileLine(c));
    end;

    // Paneel-instellingen achteraan (niet bij kopiëren)
    if not Assigned(FSaveOnly) then
    begin
    SFile.Add(Format('Paneelkleur;%d;', [Paneel.Color]));
    SFile.Add(Format('Dotkleur;%d;', [Paneel.DotColor]));
    SFile.Add('Voeding;1;');   // paneel met bron (geen bron bijzetten bij laden)
    if Paneel.ShowGrid then
      SFile.Add('Grid;True;')
    else
      SFile.Add('Grid;False;');
    // altijd bewaren: zonder regel volgt het paneel de instelling KStatusBalk
    SFile.Add('Statusbalk;' + BoolToStr(Paneel.ShowStatusBar, True) + ';');
    // een oefening blijft een oefening
    SFile.AddStrings(FOefening);
    end;
  finally
    ShiftPanelObjects(Sh.X, Sh.Y);
  end;
end;


procedure TjanSimLogicBox.SaveSelectionToList(SFile: TStrings; Paneel: TjanGridS; Only: TList);
begin
  FSaveOnly := Only;
  try
    SavePanelToList(SFile, Paneel);
  finally
    FSaveOnly := nil;
  end;
end;

procedure TjanSimLogicBox.AddFromList(AList: TStrings; Paneel: TjanGridS; DX, DY: Integer; Nieuw: TList;
  AtPos: Boolean);
var
  Oud: TList;
  i, MinL, MinT: Integer;
  c, Ref: TControl;
  wc: TWinControl;
  Sh, PA, PB, P0, Doel, C0, Snapped: TPoint;
  WorkR: TRect;
  Con: TjanConnector;
  Rc: TRect;
  MA, MB: TjanConMode;
  InA, InB: Boolean;

  // ligt P op een van de geplakte objecten (geen draad)?
  function OpNieuw(const P: TPoint): Boolean;
  var
    k: Integer;
    R: TRect;
  begin
    Result := False;
    for k := 0 to Nieuw.Count - 1 do
      if not (TObject(Nieuw[k]) is TjanConnector) then
      begin
        R := TControl(Nieuw[k]).BoundsRect;
        InflateRect(R, 8, 8);
        if PtInRect(R, P) then
          Exit(True);
      end;
  end;

  // het losse uiteinde P van een geplakte draad: waar moet het komen?
  // Lag het origineel (P - DX,DY) op een rail, dan schuift het langs die
  // rail mee (binnen de rail); op een bron of elders blijft het staan.
  function LosDoel(const P: TPoint): TPoint;
  var
    k: Integer;
    R: TRect;
    o: TControl;
  begin
    P0 := Point(P.X - DX, P.Y - DY);
    Result := P0;
    for k := 0 to Oud.Count - 1 do
    begin
      o := TControl(Oud[k]);
      if not (o is TjanRail) or not o.Visible then Continue;
      R := o.BoundsRect;
      InflateRect(R, 8, 8);
      if not PtInRect(R, P0) then Continue;
      R := o.BoundsRect;
      if o.Height >= o.Width then
      begin
        Result.Y := P.Y;
        if Result.Y > R.Bottom - 4 then Result.Y := R.Bottom - 4;
        if Result.Y < R.Top + 4 then Result.Y := R.Top + 4;
      end
      else
      begin
        Result.X := P.X;
        if Result.X > R.Right - 4 then Result.X := R.Right - 4;
        if Result.X < R.Left + 4 then Result.X := R.Left + 4;
      end;
      Exit;
    end;
  end;

begin
  Nieuw.Clear;
  wc := FParent;
  if wc = nil then Exit;
  Oud := TList.Create;
  try
    for i := 0 to wc.ControlCount - 1 do
      Oud.Add(wc.Controls[i]);
    FAppend := True;
    try
      InternalLoadFromList(AList, Paneel);
    finally
      FAppend := False;
    end;
    // bewaard zoals bij de balk links: terugschuiven naar de balk van nu
    Sh := LayoutShift;
    for i := 0 to wc.ControlCount - 1 do
    begin
      c := wc.Controls[i];
      if Oud.IndexOf(c) >= 0 then Continue;
      Nieuw.Add(c);
      c.SetBounds(c.Left + Sh.X, c.Top + Sh.Y, c.Width, c.Height);
    end;
    // plakken aan de muis: linksboven van het stuk op DX,DY, en net als
    // bij slepen het eerste object op de liniaal laten springen
    if AtPos then
    begin
      MinL := MaxInt; MinT := MaxInt; Ref := nil;
      for i := 0 to Nieuw.Count - 1 do
      begin
        c := TControl(Nieuw[i]);
        if c.Left < MinL then MinL := c.Left;
        if c.Top < MinT then MinT := c.Top;
        if (Ref = nil) and not (c is TjanConnector) then Ref := c;
      end;
      if MinL = MaxInt then
      begin
        DX := 0; DY := 0;
      end
      else
      begin
        Doel := Point(DX, DY);
        if Assigned(Paneel) then
        begin
          WorkR := Paneel.GetWorkAreaRect;
          if Doel.X < WorkR.Left then Doel.X := WorkR.Left;
          if Doel.Y < WorkR.Top then Doel.Y := WorkR.Top;
        end;
        DX := Doel.X - MinL;
        DY := Doel.Y - MinT;
        if Assigned(Paneel) and Assigned(Ref) then
        begin
          C0 := Point(Ref.Left + Ref.Width div 2 + DX, Ref.Top + Ref.Height div 2 + DY);
          Snapped := Paneel.SnapPointToRuler(C0, WorkR);
          DX := DX + (Snapped.X - C0.X);
          DY := DY + (Snapped.Y - C0.Y);
        end;
      end;
    end;
    for i := 0 to Nieuw.Count - 1 do
    begin
      c := TControl(Nieuw[i]);
      c.SetBounds(c.Left + DX, c.Top + DY, c.Width, c.Height);
    end;
    // een draad naar een rail of bron die niet mee gekopieerd is: dat
    // uiteinde weer op de rail (of de bron) leggen
    if (DX <> 0) or (DY <> 0) then
      for i := 0 to Nieuw.Count - 1 do
        if TObject(Nieuw[i]) is TjanConnector then
        begin
          Con := TjanConnector(Nieuw[i]);
          Rc := Con.BoundsRect;
          if Con.V_ConShape = jcsTLBR then
          begin
            PA := Point(Rc.Left, Rc.Top);     MA := jcmTL;
            PB := Point(Rc.Right, Rc.Bottom); MB := jcmBR;
          end
          else
          begin
            PA := Point(Rc.Right, Rc.Top);    MA := jcmTR;
            PB := Point(Rc.Left, Rc.Bottom);  MB := jcmBL;
          end;
          InA := OpNieuw(PA);
          InB := OpNieuw(PB);
          if InA <> InB then
          begin
            if InA then
            begin
              Doel := LosDoel(PB);
              Con.AnchorCorner(Point(0, 0), MB);
              Con.MoveConnector(Point(Doel.X - PB.X, Doel.Y - PB.Y));
            end
            else
            begin
              Doel := LosDoel(PA);
              Con.AnchorCorner(Point(0, 0), MA);
              Con.MoveConnector(Point(Doel.X - PA.X, Doel.Y - PA.Y));
            end;
          end;
        end;
  finally
    Oud.Free;
  end;
  BlokkeerObjecten(False);
  UpdateSupply(wc, True);
  wc.Invalidate;
end;

function TjanSimLogicBox.PanelSignature(Paneel: TjanGridS): string;
var
  wc: TWinControl;
  i: Integer;
  c: TControl;
  L, P: TStringList;
  s: string;
  Sh: TPoint;
begin
  Result := '';
  wc := FParent;
  if wc = nil then Exit;
  Sh := LayoutShift;
  L := TStringList.Create;
  P := TStringList.Create;
  P.Delimiter := ';';
  P.StrictDelimiter := True;
  try
    for i := 0 to wc.ControlCount - 1 do
    begin
      c := wc.Controls[i];
      // alleen wat in een paneelbestand terechtkomt (geen selectiekader e.d.)
      if not ((c is TjanConnector) or (c is TjanLogic) or (c is TjanTeller) or
              (c is TjanMemory) or (c is TjanMeter) or (c is TjanSimButton) or
              (c is TjanSimKnop) or (c is TjanDipSwitsh) or (c is TjanSimPuls) or
              (c is TjanSimSensor) or (c is TjanSimWarm) or (c is TjanSimLight) or
              (c is TjanSimRelais) or (c is TjanSimBuzzer) or (c is TjanDisplay) or
              (c is TjanRail) or (c is TjanLogicRun) or (c is TjanSimMotor) or
              (c is TjanSimPersoon) or (c is TjanSimEindschakelaar) or
              (c is TjanSimStappenteller) or (c is TjanVoedingsDeel)) then
        Continue;
      // plaats ten opzichte van de knoppenbalk: een tweede rij knoppen
      // schuift alles op, maar dat is geen wijziging van het paneel
      s := Format('%s;%d;%d;%d;%d', [c.ClassName, c.Left - Sh.X, c.Top - Sh.Y, c.Width, c.Height]);
      if (c is TjanRail) or (c is TjanVoedingsDeel) then
      begin
        if c is TjanRail then s := RailFileLine(TjanRail(c))
        else s := VoedingFileLine(c);
        // Type;Height;Left;Top;... : Left en Top relatief maken
        P.DelimitedText := s;
        if P.Count > 3 then
        begin
          P[2] := IntToStr(c.Left - Sh.X);
          P[3] := IntToStr(c.Top - Sh.Y);
          s := P.DelimitedText;
        end;
      end
      else if c is TjanConnector then
        with TjanConnector(c) do
          s := s + Format(';%d;%d;%.3f', [Ord(V_ConPos), Ord(V_ConShape), V_Edge])
      else if c is TjanLogic then
        s := s + Format(';%d', [Ord(TjanLogic(c).LogicFunc)])
      else if c is TjanLogicRun then
        s := s + ';' + TjanLogicRun(c).ProgramText
      else if c is TjanSimLight then
        s := s + Format(';%d', [Ord(TjanSimLight(c).Kleur)])
      else if c is TjanSimStappenteller then
        s := s + Format(';%d;%d', [TjanSimStappenteller(c).Eindwaarde, Ord(TjanSimStappenteller(c).Herhalen)])
      else if c is TjanSimPuls then
        s := s + Format(';%d', [TjanSimPuls(c).PulsInterval]);
      L.Add(s);
    end;
    // volgorde doet er niet toe (BringToFront bij de simulatie verandert ze)
    L.Sort;
    if Assigned(Paneel) then
      L.Add(Format('paneel;%d;%d;%s;%s', [Paneel.Color, Paneel.DotColor, BoolToStr(Paneel.ShowGrid, True),
        BoolToStr(Paneel.ShowStatusBar, True)]));
    Result := L.Text;
  finally
    P.Free;
    L.Free;
  end;
end;

procedure TjanSimLogicBox.SavePanelTemp(Paneel: TjanGridS);
var
  wc: TWinControl;
  i: Integer;
  c: TControl;
  lijn, modeStr, posStr, shapeStr, edgeStr, ltypeStr: string;
  Sh: TPoint;
begin
  wc := FParent;
  TempFile.Clear;
  Sh := LayoutShift;
  ShiftPanelObjects(-Sh.X, -Sh.Y);   // plaatsen zoals bij de balk links
  try

  // Alle controls serialiseren
  for i := 0 to wc.ControlCount - 1 do
  begin
    c := wc.Controls[i];

    // --- TjanConnector ---
    if c is TjanConnector then
    with TjanConnector(c) do
    begin
      case V_ConMode of
        jcmTL: modeStr := 'jcmTL';
        jcmTR: modeStr := 'jcmTR';
        jcmBL: modeStr := 'jcmBL';
        jcmBR: modeStr := 'jcmBR';
      end;

      case V_ConPos of
        jcpTL: posStr := 'jcpTL';
        jcpTR: posStr := 'jcpTR';
        jcpBL: posStr := 'jcpBL';
        jcpBR: posStr := 'jcpBR';
      end;

      case V_ConShape of
        jcsTLBR: shapeStr := 'jcsTLBR';
        jcsTRBL: shapeStr := 'jcsTRBL';
      end;

      edgeStr := FloatToStr(V_Edge);
      edgeStr := StringReplace(edgeStr, DecimalSeparator, ',', [rfReplaceAll]);

      lijn := Format(
        'TjanConnector;%d;%d;%d;%d;%s;%s;%s;%s;%d;',
        [Height, Left, Top, Width,
         modeStr, posStr, shapeStr, edgeStr, FObjectID]
      );
      TempFile.Add(lijn);
    end
    else
    // --- TjanLogic ---
    if c is TjanLogic then
    with TjanLogic(c) do
    begin
      ltypeStr := LogicFuncCode(logicFunc);

      lijn := Format(
        'TjanLogic;%d;%d;%s;%d;%d;',
        [Height, Left, ltypeStr, Top, Width]
      );
      TempFile.Add(lijn);
    end
    else
    // --- overige ---
    if c is TjanTeller then
    begin
      with TjanTeller(c) do
        lijn := Format('TjanTeller;%d;%d;%d;%d;', [Height, Left, Top, Width]);
      TempFile.Add(lijn);
    end
    else if c is TjanSimButton then
    begin
      with TjanSimButton(c) do
        lijn := Format('TjanSimButton;%d;%d;%d;%d;', [Height, Left, Top, Width]);
      TempFile.Add(lijn);
    end
    else if c is TjanSimKnop then
    begin
      with TjanSimKnop(c) do
        lijn := Format('TjanSimKnop;%d;%d;%d;%d;', [Height, Left, Top, Width]);
      TempFile.Add(lijn);
    end
    else if c is TjanSimSensor then
    begin
      with TjanSimSensor(c) do
        lijn := Format('TjanSimSensor;%d;%d;%d;%d;', [Height, Left, Top, Width]);
      TempFile.Add(lijn);
    end
    else if c is TjanSimWarm then
    begin
      with TjanSimWarm(c) do
        lijn := Format('TjanSimWarm;%d;%d;%d;%d;', [Height, Left, Top, Width]);
      TempFile.Add(lijn);
    end
    else if c is TjanSimPuls then
    begin
      with TjanSimPuls(c) do
        lijn := Format('TjanSimPuls;%d;%d;%d;%d;', [Height, Left, Top, Width]);
      // frequentie als extra veld, alleen als ze niet de standaard is
      if TjanSimPuls(c).PulsInterval <> PulsIntervalStandaard then
        lijn := lijn + IntToStr(TjanSimPuls(c).PulsInterval) + ';';
      TempFile.Add(lijn);
    end
    else if c is TjanDipSwitsh then
    begin
      with TjanDipSwitsh(c) do
        lijn := Format('TjanDipSwitsh;%d;%d;%d;%d;', [Height, Left, Top, Width]);
      TempFile.Add(lijn);
    end
    else if c is TjanMemory then
    begin
      with TjanMemory(c) do
        lijn := Format('TjanMemory;%d;%d;%d;%d;%s;', [Height, Left, Top, Width, InhoudTekst]);
      TempFile.Add(lijn);
    end
    else if c is TjanSimLight then
    begin
      with TjanSimLight(c) do
        lijn := Format('TjanSimLight;%d;%d;%d;%d;', [Height, Left, Top, Width]);
      if TjanSimLight(c).Kleur <> lkLamp then
        lijn := lijn + IntToStr(Ord(TjanSimLight(c).Kleur)) + ';';
      TempFile.Add(lijn);
    end
    else if c is TjanSchakelRelais then
    begin
      with TjanSchakelRelais(c) do
        lijn := Format('TjanSchakelRelais;%d;%d;%d;%d;', [Height, Left, Top, Width]);
      TempFile.Add(lijn);
    end
    else if c is TjanSimRelais then
    begin
      with TjanSimRelais(c) do
        lijn := Format('TjanSimRelais;%d;%d;%d;%d;', [Height, Left, Top, Width]);
      TempFile.Add(lijn);
    end
    else if c is TjanSimBuzzer then
    begin
      with TjanSimBuzzer(c) do
        lijn := Format('TjanSimBuzzer;%d;%d;%d;%d;', [Height, Left, Top, Width]);
      TempFile.Add(lijn);
    end
    else if c is TjanDisplay then
    begin
      with TjanDisplay(c) do
        lijn := Format('TjanDisplay;%d;%d;%d;%d;', [Height, Left, Top, Width]);
      TempFile.Add(lijn);
    end
    else if c is TjanSimMotor then
      TempFile.Add(Format('TjanSimMotor;%d;%d;%d;%d;', [c.Height, c.Left, c.Top, c.Width]))
    else if c is TjanSimPersoon then
      TempFile.Add(Format('%s;%d;%d;%d;%d;', [c.ClassName, c.Height, c.Left, c.Top, c.Width]))
    else if c is TjanSimEindschakelaar then
      TempFile.Add(Format('TjanSimEindschakelaar;%d;%d;%d;%d;%d;', [c.Height, c.Left, c.Top, c.Width, TjanSimEindschakelaar(c).Kanaal]))
    else if c is TjanSimStappenteller then
      TempFile.Add(Format('%s;%d;%d;%d;%d;%d;%d;', [c.ClassName, c.Height, c.Left, c.Top, c.Width,
        TjanSimStappenteller(c).Eindwaarde, Ord(TjanSimStappenteller(c).Herhalen)]))
    else if c is TjanLogicRun then
      TempFile.Add(Format('TjanLogicRun;%d;%d;%d;%d;', [c.Height, c.Left, c.Top, c.Width]) +
        TjanLogicRun(c).ProgramText + ';')
    else if c is TjanMeter then
      TempFile.Add(Format('TjanMeter;%d;%d;%d;%d;', [c.Height, c.Left, c.Top, c.Width]))
    else if c is TjanRail then
      TempFile.Add(RailFileLine(TjanRail(c)))
    else if c is TjanVoedingsDeel then
      TempFile.Add(VoedingFileLine(c));
  end;

  // Paneel-instellingen
  TempFile.Add(Format('Paneelkleur;%d;', [Paneel.Color]));
  TempFile.Add(Format('Dotkleur;%d;', [Paneel.DotColor]));
  TempFile.Add('Voeding;1;');
  if Paneel.ShowGrid then
    TempFile.Add('Grid;True;')
  else
    TempFile.Add('Grid;False;');
  TempFile.Add('Statusbalk;' + BoolToStr(Paneel.ShowStatusBar, True) + ';');
  finally
    ShiftPanelObjects(Sh.X, Sh.Y);
  end;
end;

procedure TjanSimLogicBox.InternalLoadFromList(AList: TStrings; Paneel: TjanGridS);
var
  i, positie: Integer;
  LF: TjanLogicFunc;
  LR: TjanLogicRun;
  StT: TjanSimStappenteller;
  S: string;
  obj: array[1..10] of string;
  wc: TWinControl;
  EdgeFS: TFormatSettings;
  EdgeVal: Double;
  PersoonKlasse: TjanSimPersoonClass;
  VoedingMark: Boolean;   // regel Voeding;1; (paneel met bron)
  VD: TjanVoedingsDeel;

  procedure AddCommonSimProps(const AClassName: string);
  var
    s: string;
  begin
    s := AClassName + '.Left';   AddFilter(s);
    s := AClassName + '.Top';    AddFilter(s);
    s := AClassName + '.width';  AddFilter(s);
    s := AClassName + '.Height'; AddFilter(s);
  end;

begin
  if not FAppend then
    KillPanel;
  // Geen nieuw object meer "aan de muis": koos je in de balk een component
  // maar plaatste je het niet, dan zou anders na het laden een object van
  // het paneel de muis volgen (zie GridMouseMove in main.pas).
  VoedingMark := False;
  FNew := False;
  wc := FParent;
  if not FAppend then
  begin
    FFilterLijst.Clear;
    if Assigned(Paneel) then
      Paneel.ShowStatusBar := Paneel.KStatusBalk;
  end;   // panelen zonder regel 'Statusbalk' volgen de instelling

  for i := 0 to AList.Count - 1 do
  begin
    S := Trim(AList.Strings[i]);
    if S = '' then
      Continue;

    // eerste token: soort (TjanTeller, TjanConnector, Paneelkleur, ...)
    positie := Pos(';', S);
    if positie = 0 then
      Continue;

    obj[1] := Copy(S, 1, positie - 1);
    Delete(S, 1, positie);
    {
    // ---------- Paneel-instellingen ----------
    if obj[1] = 'Paneelkleur' then
    begin
      positie := Pos(';', S);
      if positie = 0 then Continue;
      obj[2] := Copy(S, 1, positie - 1);           // kleur
      Paneel.Color := StrToInt(Trim(obj[2]));
      Continue;
    end;

    if obj[1] = 'Dotkleur' then
    begin
      positie := Pos(';', S);
      if positie = 0 then Continue;
      obj[2] := Copy(S, 1, positie - 1);           // dotkleur
      Paneel.DotColor := StrToInt(Trim(obj[2]));
      Continue;
    end;

    if obj[1] = 'Grid' then
    begin
      positie := Pos(';', S);
      if positie = 0 then Continue;
      obj[2] := Copy(S, 1, positie - 1);           // True / False
      Paneel.ShowGrid := (Trim(obj[2]) = 'True');
      Continue;
    end;}
    if obj[1] = 'Paneelkleur' then
      begin
      positie := Pos(';', S);
      if positie = 0 then Continue;
      obj[2] := Copy(S, 1, positie - 1);           // kleur
      if Assigned(Paneel) then
      Paneel.Color := StrToInt(Trim(obj[2]));
      Continue;
      end;

    if obj[1] = 'Dotkleur' then
      begin
      positie := Pos(';', S);
      if positie = 0 then Continue;
      obj[2] := Copy(S, 1, positie - 1);           // dotkleur
      if Assigned(Paneel) then
       Paneel.DotColor := StrToInt(Trim(obj[2]));
      Continue;
      end;

    if obj[1] = 'Grid' then
      begin
      positie := Pos(';', S);
      if positie = 0 then Continue;
      obj[2] := Copy(S, 1, positie - 1);           // True / False
      if Assigned(Paneel) then
         Paneel.ShowGrid := (Trim(obj[2]) = 'True');
      Continue;
    end;

    // oefening (zie Oefening): de regels onthouden, niet bij plakken
    if (obj[1] = 'Titel') or (obj[1] = 'Opdracht') or (obj[1] = 'Verwacht') or
       (obj[1] = 'Verboden') then
    begin
      if not FAppend then
        FOefening.Add(Trim(AList.Strings[i]));
      Continue;
    end;

    // Voeding;1;  (paneel uit een versie met bron: geen bron bijzetten)
    if obj[1] = 'Voeding' then
    begin
      VoedingMark := True;
      Continue;
    end;

    // TjanBron;h;l;t;w;spanning x10;Ri;elektronen;  TjanZekering;h;l;t;w;stroom;
    // TjanAmpMeter;h;l;t;w;
    // TjanLamp2;h;l;t;w;soort;  TjanSchakelaar2;h;l;t;w;aan;  TjanVoltmeter2;h;l;t;w;
    // TjanWeerstand;h;l;t;w;soort;
    if (obj[1] = 'TjanBron') or (obj[1] = 'TjanZekering') or (obj[1] = 'TjanAmpMeter') or
       (obj[1] = 'TjanWeerstand') or
       (obj[1] = 'TjanLamp2') or (obj[1] = 'TjanSchakelaar2') or (obj[1] = 'TjanVoltmeter2') or
       (obj[1] = 'TjanLed2') or (obj[1] = 'TjanCondensator') or (obj[1] = 'TjanWattMeter') or (obj[1] = 'TjanPotmeter') or (obj[1] = 'TjanDiode') or (obj[1] = 'TjanWisselbron') or (obj[1] = 'TjanScoop') or (obj[1] = 'TjanTransistor') or (obj[1] = 'TjanLDR') or (obj[1] = 'TjanNTC') or (obj[1] = 'TjanWissel2') or (obj[1] = 'TjanPuls2') or (obj[1] = 'TjanDip2') or (obj[1] = 'TjanMagneet') or (obj[1] = 'TjanKompas') or (obj[1] = 'TjanVeldplaat') or (obj[1] = 'TjanSpoel') or (obj[1] = 'TjanIJzer') then
    begin
      with TStringList.Create do
      try
        Delimiter := ';';
        StrictDelimiter := True;
        DelimitedText := S;
        if Count >= 3 then
        begin
          if obj[1] = 'TjanBron' then VD := TjanBron.Create(Self)
          else if obj[1] = 'TjanZekering' then VD := TjanZekering.Create(Self)
          else if obj[1] = 'TjanWeerstand' then VD := TjanWeerstand.Create(Self)
          else if obj[1] = 'TjanLamp2' then VD := TjanLamp2.Create(Self)
          else if obj[1] = 'TjanSchakelaar2' then VD := TjanSchakelaar2.Create(Self)
          else if obj[1] = 'TjanWissel2' then VD := TjanWissel2.Create(Self)
          else if obj[1] = 'TjanPuls2' then VD := TjanPuls2.Create(Self)
          else if obj[1] = 'TjanDip2' then VD := TjanDip2.Create(Self)
          else if obj[1] = 'TjanMagneet' then VD := TjanMagneet.Create(Self)
          else if obj[1] = 'TjanKompas' then VD := TjanKompas.Create(Self)
          else if obj[1] = 'TjanVeldplaat' then VD := TjanVeldplaat.Create(Self)
          else if obj[1] = 'TjanSpoel' then VD := TjanSpoel.Create(Self)
          else if obj[1] = 'TjanIJzer' then VD := TjanIJzer.Create(Self)
          else if obj[1] = 'TjanVoltmeter2' then VD := TjanVoltmeter2.Create(Self)
          else if obj[1] = 'TjanLed2' then VD := TjanLed2.Create(Self)
          else if obj[1] = 'TjanCondensator' then VD := TjanCondensator.Create(Self)
          else if obj[1] = 'TjanWattMeter' then VD := TjanWattMeter.Create(Self)
          else if obj[1] = 'TjanPotmeter' then VD := TjanPotmeter.Create(Self)
          else if obj[1] = 'TjanDiode' then VD := TjanDiode.Create(Self)
          else if obj[1] = 'TjanWisselbron' then VD := TjanWisselbron.Create(Self)
          else if obj[1] = 'TjanScoop' then VD := TjanScoop.Create(Self)
          else if obj[1] = 'TjanTransistor' then VD := TjanTransistor.Create(Self)
          else if obj[1] = 'TjanLDR' then VD := TjanLDR.Create(Self)
          else if obj[1] = 'TjanNTC' then VD := TjanNTC.Create(Self)
          else VD := TjanAmpMeter.Create(Self);
          VD.Parent := wc;
          VD.Tag := wc.ControlCount;
          SetupVoedingsDeel(VD);
          // rechtop gezet: veld V achteraan
          if (Trim(Strings[Count - 1]) = 'V') or ((Count >= 2) and (Trim(Strings[Count - 2]) = 'V')) then
            VD.Gedraaid := True;
          VD.SetBounds(StrToIntDef(Trim(Strings[1]), 0), StrToIntDef(Trim(Strings[2]), 0),
            VD.Width, VD.Height);
          if (VD is TjanBron) and (Count >= 6) then
          begin
            TjanBron(VD).RiIdx := StrToIntDef(Trim(Strings[5]), 1);
            TjanBron(VD).Volt := StrToIntDef(Trim(Strings[4]), 120) / 10;
            if Count >= 7 then
              TjanBron(VD).Elektronen := Trim(Strings[6]) = '1';
            if (VD is TjanWisselbron) and (Count >= 8) then
              TjanWisselbron(VD).FreqIdx := StrToIntDef(Trim(Strings[7]), WisselStandaard);
          end
          else if (VD is TjanZekering) and (Count >= 5) then
            TjanZekering(VD).NomIdx := StrToIntDef(Trim(Strings[4]), 2)
          else if VD is TjanSpoel then
          begin
            // TjanSpoel;h;l;t;w;windingen;kern;omgekeerd;
            if Count >= 5 then TjanSpoel(VD).WindIdx := StrToIntDef(Trim(Strings[4]), 1);
            if Count >= 6 then TjanSpoel(VD).Kern := Trim(Strings[5]) = '1';
            if Count >= 7 then TjanSpoel(VD).Omgekeerd := Trim(Strings[6]) = '1';
          end
          else if (VD is TjanWeerstand) and (Count >= 5) then
            TjanWeerstand(VD).Soort := StrToIntDef(Trim(Strings[4]), 2)
          else if (VD is TjanLamp2) and (Count >= 5) then
            TjanLamp2(VD).Soort := StrToIntDef(Trim(Strings[4]), Lamp2Standaard)
          else if (VD is TjanPuls2) and (Count >= 5) then
          begin
            TjanPuls2(VD).Interval := StrToIntDef(Trim(Strings[4]), 300);
            if Count >= 6 then
              TjanPuls2(VD).Loopt := Trim(Strings[5]) = '1';
          end
          else if (VD is TjanDip2) and (Count >= 5) then
            TjanDip2(VD).Waarde := StrToIntDef(Trim(Strings[4]), 0)
          else if (VD is TjanMagneet) and (Count >= 5) then
            TjanMagneet(VD).Omgekeerd := Trim(Strings[4]) = '1'
          else if (VD is TjanVeldplaat) then
          begin
            if Count >= 5 then
              TjanVeldplaat(VD).Maat := StrToIntDef(Trim(Strings[4]), 1);
            VD.SendToBack;   // de plaat ligt onder de magneten
          end
          else if (VD is TjanSchakelaar2) and (Count >= 5) then
          begin
            TjanSchakelaar2(VD).Aan := Trim(Strings[4]) = '1';
            if Count >= 6 then
              TjanSchakelaar2(VD).Soort := StrToIntDef(Trim(Strings[5]), 0);
          end
          else if (VD is TjanLed2) and (Count >= 5) then
          begin
            TjanLed2(VD).Kleur := StrToIntDef(Trim(Strings[4]), 0);
            if Count >= 6 then
              TjanLed2(VD).Doorgebrand := Trim(Strings[5]) = '1';
            if (VD is TjanDiode) and (Count >= 7) then
              TjanDiode(VD).Omgekeerd := Trim(Strings[6]) = '1';
          end
          else if (VD is TjanCondensator) and (Count >= 5) then
            TjanCondensator(VD).Soort := StrToIntDef(Trim(Strings[4]), CondStandaard)
          else if (VD is TjanScoop) and (Count >= 5) then
          begin
            TjanScoop(VD).BereikIdx := StrToIntDef(Trim(Strings[4]), 1);
            if Count >= 6 then
              TjanScoop(VD).TijdIdx := StrToIntDef(Trim(Strings[5]), 1);
          end
          else if (VD is TjanSensorR) and (Count >= 5) then
            TjanSensorR(VD).Stand := StrToIntDef(Trim(Strings[4]), TjanSensorR(VD).Stand)
          else if (VD is TjanTransistor) and (Count >= 5) then
          begin
            // TjanTransistor;h;l;t;w;pnp;beta;kapot;
            TjanTransistor(VD).PNP := Trim(Strings[4]) = '1';
            if Count >= 6 then
              TjanTransistor(VD).BetaIdx := StrToIntDef(Trim(Strings[5]), TrBetaStd);
            if Count >= 7 then
              TjanTransistor(VD).Doorgebrand := Trim(Strings[6]) = '1';
          end
          else if (VD is TjanPotmeter) and (Count >= 5) then
          begin
            TjanPotmeter(VD).Soort := StrToIntDef(Trim(Strings[4]), PotStandaard);
            if Count >= 6 then
              TjanPotmeter(VD).Procent := StrToIntDef(Trim(Strings[5]), 50);
          end;
        end;
      finally
        Free;
      end;
      Continue;
    end;

    // Statusbalk;False;  (balk Invoer / Verwerken / Uitvoer verborgen)
    if obj[1] = 'Statusbalk' then
    begin
      if Assigned(Paneel) then
        Paneel.ShowStatusBar := not SameText(Trim(Copy(S, 1, Pos(';', S + ';') - 1)), 'False');
      Continue;
    end;

    // TjanMeter;height;left;top;width;  (voltmeter)
    if obj[1] = 'TjanMeter' then
    begin
      with TStringList.Create do
      try
        Delimiter := ';';
        StrictDelimiter := True;
        DelimitedText := S;
        if Count >= 3 then
          with TjanMeter.Create(Self) do
          begin
            Parent := wc;
            Tag := wc.ControlCount;
            SetBounds(StrToIntDef(Trim(Strings[1]), 0), StrToIntDef(Trim(Strings[2]), 0), 100, 51);
            Box := Self;
            BTaal := StatTaalToBTaal(Language);
            OnStatus := StatusFromChild;
          end;
      finally
        Free;
      end;
      Continue;
    end;

    // TjanRail;height;left;top;width;+ of -;spanning x10;
    if obj[1] = 'TjanRail' then
    begin
      with TStringList.Create do
      try
        Delimiter := ';';
        StrictDelimiter := True;
        DelimitedText := S;
        if Count >= 6 then
          AddRail(StrToIntDef(Trim(Strings[1]), 0), StrToIntDef(Trim(Strings[2]), 0),
            StrToIntDef(Trim(Strings[0]), 200), Trim(Strings[4]) = '+',
            StrToIntDef(Trim(Strings[5]), 50) / 10);
      finally
        Free;
      end;
      Continue;
    end;

    // Voeding;True;plusX;minX;plusBoven;plusOnder;minBoven;minOnder;
    // (vaste paneelrails uit een testversie): omzetten naar twee rails
    if obj[1] = 'Voeding' then
    begin
      with TStringList.Create do
      try
        Delimiter := ';';
        StrictDelimiter := True;
        DelimitedText := S;
        if (Count >= 7) and (Trim(Strings[0]) = 'True') then
        begin
          AddRail(StrToIntDef(Strings[1], 0) - RailLineOfs, StrToIntDef(Strings[3], 0) - RailLabelH,
            StrToIntDef(Strings[4], 0) - StrToIntDef(Strings[3], 0) + 1 + RailLabelH, True, RailMaxVolt);
          AddRail(StrToIntDef(Strings[2], 0) - RailLineOfs, StrToIntDef(Strings[5], 0) - RailLabelH,
            StrToIntDef(Strings[6], 0) - StrToIntDef(Strings[5], 0) + 1 + RailLabelH + RailFootH, False, 0);
        end;
      finally
        Free;
      end;
      Continue;
    end;

    // ---------- TjanConnector ----------
    // Formaat:
    // TjanConnector;height;left;top;width;mode;pos;shape;edge;ID;
    if obj[1] = 'TjanConnector' then
    begin
      // height
      positie := Pos(';', S); if positie = 0 then Continue;
      obj[2] := Copy(S, 1, positie - 1); Delete(S, 1, positie);

      // left
      positie := Pos(';', S); if positie = 0 then Continue;
      obj[3] := Copy(S, 1, positie - 1); Delete(S, 1, positie);

      // top
      positie := Pos(';', S); if positie = 0 then Continue;
      obj[4] := Copy(S, 1, positie - 1); Delete(S, 1, positie);

      // width
      positie := Pos(';', S); if positie = 0 then Continue;
      obj[5] := Copy(S, 1, positie - 1); Delete(S, 1, positie);

      // mode
      positie := Pos(';', S); if positie = 0 then Continue;
      obj[6] := Copy(S, 1, positie - 1); Delete(S, 1, positie);

      // pos
      positie := Pos(';', S); if positie = 0 then Continue;
      obj[7] := Copy(S, 1, positie - 1); Delete(S, 1, positie);

      // shape
      positie := Pos(';', S); if positie = 0 then Continue;
      obj[8] := Copy(S, 1, positie - 1); Delete(S, 1, positie);

      // edge
      positie := Pos(';', S); if positie = 0 then Continue;
      obj[9] := Copy(S, 1, positie - 1); Delete(S, 1, positie);

      // ID (optioneel, nu nog niet gebruikt)
      if Pos(';', S) > 0 then
      begin
        positie := Pos(';', S);
        obj[10] := Copy(S, 1, positie - 1);
      end
      else
        obj[10] := S;

      with TjanConnector.Create(self) do
      begin
        Parent := wc;
        Tag    := wc.ControlCount;

        Left   := StrToInt(Trim(obj[3]));
        Top    := StrToInt(Trim(obj[4]));
        Height := StrToInt(Trim(obj[2]));
        Width  := StrToInt(Trim(obj[5]));  // **echte** width uit file

        // mode
        if obj[6] = 'jcmTL' then V_ConMode := jcmTL else
        if obj[6] = 'jcmTR' then V_ConMode := jcmTR else
        if obj[6] = 'jcmBL' then V_ConMode := jcmBL else
        if obj[6] = 'jcmBR' then V_ConMode := jcmBR;

        // pos
        if obj[7] = 'jcpTL' then V_ConPos := jcpTL else
        if obj[7] = 'jcpTR' then V_ConPos := jcpTR else
        if obj[7] = 'jcpBL' then V_ConPos := jcpBL else
        if obj[7] = 'jcpBR' then V_ConPos := jcpBR;

        // shape
        if obj[8] = 'jcsTLBR' then V_ConShape := jcsTLBR else
        if obj[8] = 'jcsTRBL' then V_ConShape := jcsTRBL;

        // edge: waar de middenlijn staat (0..1), met komma of punt bewaard
        EdgeFS := DefaultFormatSettings;
        EdgeFS.DecimalSeparator := '.';
        if TryStrToFloat(StringReplace(Trim(obj[9]), ',', '.', []), EdgeVal, EdgeFS) and
           (EdgeVal >= 0) and (EdgeVal <= 1) then
          V_Edge := EdgeVal;

        FObjectID := wc.ControlCount;

        AddFilter('TjanConnector.Left');
        AddFilter('TjanConnector.Top');
        AddFilter('TjanConnector.width');
        AddFilter('TjanConnector.Height');
        AddFilter('TjanConnector.W_ConMode');
        AddFilter('TjanConnector.W_ConPos');
        AddFilter('TjanConnector.W_ConShape');
        AddFilter('TjanConnector.W_Edge');
      end;

      Continue;
    end;

    // ---------- TjanLogic ----------
    // Formaat: TjanLogic;height;left;L_Type;top;width;
    if obj[1] = 'TjanLogic' then
    begin
      // height
      positie := Pos(';', S); if positie = 0 then Continue;
      obj[2] := Copy(S, 1, positie - 1); Delete(S, 1, positie);

      // left
      positie := Pos(';', S); if positie = 0 then Continue;
      obj[3] := Copy(S, 1, positie - 1); Delete(S, 1, positie);

      // L_Type (NIET/EN/OF)
      positie := Pos(';', S); if positie = 0 then Continue;
      obj[4] := Copy(S, 1, positie - 1); Delete(S, 1, positie);

      // top
      positie := Pos(';', S); if positie = 0 then Continue;
      obj[5] := Copy(S, 1, positie - 1); Delete(S, 1, positie);

      // width
      positie := Pos(';', S);
      if positie > 0 then
        obj[6] := Copy(S, 1, positie - 1)
      else
        obj[6] := S;

      with TjanLogic.Create(self) do
      begin
        Parent := wc;
        Tag    := wc.ControlCount;

        Left   := StrToInt(Trim(obj[3]));
        Top    := StrToInt(Trim(obj[5]));
        // oude panelen: 68 hoog; nu met de naam onder het symbool
        Height := StrToInt(Trim(obj[2]));
        if Height < LogicPoortH then Height := LogicPoortH;
        Width  := StrToInt(Trim(obj[6]));

        FObjectID := wc.ControlCount;
        Lock      := True;

        if LogicFuncFromCode(obj[4], LF) then logicFunc := LF;

        AddFilter('TjanLogic.Left');
        AddFilter('TjanLogic.Top');
        AddFilter('TjanLogic.width');
        AddFilter('TjanLogic.Height');
        AddFilter('TjanLogic.L_Type');
      end;

      Continue;
    end;

    // ---------- Overige componenten ----------
    // Formaat: Type;height;left;top;width;
    if (obj[1] <> 'TjanLogic') and (obj[1] <> 'TjanConnector') then
    begin
      // height
      positie := Pos(';', S); if positie = 0 then Continue;
      obj[2] := Copy(S, 1, positie - 1); Delete(S, 1, positie);

      // left
      positie := Pos(';', S); if positie = 0 then Continue;
      obj[3] := Copy(S, 1, positie - 1); Delete(S, 1, positie);

      // top
      positie := Pos(';', S); if positie = 0 then Continue;
      obj[4] := Copy(S, 1, positie - 1); Delete(S, 1, positie);

      // width
      positie := Pos(';', S);
      if positie > 0 then
        obj[5] := Copy(S, 1, positie - 1)
      else
        obj[5] := S;

      // ---- TjanTeller ----
      if obj[1] = 'TjanTeller' then
      begin
        with TjanTeller.Create(self) do
        begin
          Parent := wc; Tag := wc.ControlCount;
          Left   := StrToInt(Trim(obj[3]));
          Top    := StrToInt(Trim(obj[4]));
          Height := StrToInt(Trim(obj[2]));
          Width  := StrToInt(Trim(obj[5]));
          FObjectID := wc.ControlCount; Lock := True;
          if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';

          AddCommonSimProps('TjanTeller');
        end;
        Continue;
      end;

      // ---- TjanSimButton ----
      if obj[1] = 'TjanSimButton' then
      begin
        with TjanSimButton.Create(self) do   //xxxx
        begin
          Parent := wc;
          Tag := wc.ControlCount;
          Left   := StrToInt(Trim(obj[3]));
          Top    := StrToInt(Trim(obj[4]));
          Height := StrToInt(Trim(obj[2]));
          Width  := StrToInt(Trim(obj[5]));
          FObjectID := wc.ControlCount;

          Lock := True;

          if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';
          // DIT
          // ✅ Koppeling naar statusbar-route via de box
          OnEnter := ChildMouseEnter;  // Delphi-mode: GEEN @
          OnExit  := ChildMouseExit;


          OnStatus := StatusFromChild;

          AddCommonSimProps('TjanSimButton');
        end;
        Continue;
      end;

      // ---- TjanSimKnop ----
      if obj[1] = 'TjanSimKnop' then
      begin
        with TjanSimKnop.Create(self) do
        begin
          Parent := wc;
          Tag := wc.ControlCount;
          Left   := StrToInt(Trim(obj[3]));
          Top    := StrToInt(Trim(obj[4]));
          Height := StrToInt(Trim(obj[2]));
          Width  := StrToInt(Trim(obj[5]));
          FObjectID := wc.ControlCount; Lock := True;

          if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';
          // DIT
          // ✅ Koppeling naar statusbar-route via de box
          OnEnter := ChildMouseEnter;  // Delphi-mode: GEEN @
          OnExit  := ChildMouseExit;


          OnStatus := StatusFromChild;

          AddCommonSimProps('TjanSimKnop');
        end;
        Continue;
      end;

      // ---- TjanSimSensor ----
      if obj[1] = 'TjanSimSensor' then
      begin
        with TjanSimSensor.Create(self) do
        begin
          Parent := wc; Tag := wc.ControlCount;
          Left   := StrToInt(Trim(obj[3]));
          Top    := StrToInt(Trim(obj[4]));
          Height := StrToInt(Trim(obj[2]));
          Width  := StrToInt(Trim(obj[5]));
          FObjectID := wc.ControlCount; Lock := True;

          if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';
          // DIT
          // ✅ Koppeling naar statusbar-route via de box
          OnEnter := ChildMouseEnter;  // Delphi-mode: GEEN @
          OnExit  := ChildMouseExit;


          OnStatus := StatusFromChild;
          AddCommonSimProps('TjanSimSensor');
        end;
        Continue;
      end;

      // ---- TjanSimWarm ----
      if obj[1] = 'TjanSimWarm' then
      begin
        with TjanSimWarm.Create(self) do
        begin
          Parent := wc; Tag := wc.ControlCount;
          Left   := StrToInt(Trim(obj[3]));
          Top    := StrToInt(Trim(obj[4]));
          Height := StrToInt(Trim(obj[2]));
          Width  := StrToInt(Trim(obj[5]));
          FObjectID := wc.ControlCount; Lock := True;

          if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';
          // DIT
          // ✅ Koppeling naar statusbar-route via de box
          OnEnter := ChildMouseEnter;  // Delphi-mode: GEEN @
          OnExit  := ChildMouseExit;

          OnStatus := StatusFromChild;
          AddCommonSimProps('TjanSimWarm');
        end;
        Continue;
      end;

      // ---- TjanSimPuls ----
      if obj[1] = 'TjanSimPuls' then
      begin
        with TjanSimPuls.Create(self) do
        begin
          Parent := wc; Tag := wc.ControlCount;
          Left   := StrToInt(Trim(obj[3]));
          Top    := StrToInt(Trim(obj[4]));
          Height := StrToInt(Trim(obj[2]));
          Width  := StrToInt(Trim(obj[5]));
          PulsInterval := PulsIntervalUitRest(S);   // frequentie na de breedte
          FObjectID := wc.ControlCount; Lock := True;

          if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';
          // DIT
          // ✅ Koppeling naar statusbar-route via de box
          OnEnter := ChildMouseEnter;  // Delphi-mode: GEEN @
          OnExit  := ChildMouseExit;

          OnStatus := StatusFromChild;
          AddCommonSimProps('TjanSimPuls');
        end;
        Continue;
      end;

      // ---- TjanDipSwitsh ----
      if obj[1] = 'TjanDipSwitsh' then
      begin
        with TjanDipSwitsh.Create(self) do
        begin
          Parent := wc; Tag := wc.ControlCount;
          Left   := StrToInt(Trim(obj[3]));
          Top    := StrToInt(Trim(obj[4]));
          Height := StrToInt(Trim(obj[2]));
          Width  := StrToInt(Trim(obj[5]));
          FObjectID := wc.ControlCount; Lock := True;
          if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';
          // DIT
          // ✅ Koppeling naar statusbar-route via de box
          OnEnter := ChildMouseEnter;  // Delphi-mode: GEEN @
          OnExit  := ChildMouseExit;

          OnStatus := StatusFromChild;

          AddCommonSimProps('TjanDipSwitsh');
        end;
        Continue;
      end;

      // ---- TjanMemory ----
      if obj[1] = 'TjanMemory' then
      begin
        with TjanMemory.Create(self) do
        begin
          Parent := wc; Tag := wc.ControlCount;
          Left   := StrToInt(Trim(obj[3]));
          Top    := StrToInt(Trim(obj[4]));
          Height := StrToInt(Trim(obj[2]));
          Width  := StrToInt(Trim(obj[5]));
          FObjectID := wc.ControlCount; Lock := True;

          if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';
          // DIT
          // ✅ Koppeling naar statusbar-route via de box
          OnEnter := ChildMouseEnter;  // Delphi-mode: GEEN @
          OnExit  := ChildMouseExit;

          OnStatus := StatusFromChild;
          AddCommonSimProps('TjanMemory');
          // inhoud van de laatjes (nieuwere panelen)
          ZetInhoudUitRest(S);
        end;
        Continue;
      end;

      // ---- TjanSimLight ----
      if obj[1] = 'TjanSimLight' then
      begin
        with TjanSimLight.Create(self) do
        begin
          Parent := wc; Tag := wc.ControlCount;
          Left   := StrToInt(Trim(obj[3]));
          Top    := StrToInt(Trim(obj[4]));
          Height := StrToInt(Trim(obj[2]));
          Width  := StrToInt(Trim(obj[5]));
          Kleur  := LampKleurUitRest(S);   // led: kleur na de breedte
          FObjectID := wc.ControlCount; Lock := True;

          if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';
          // DIT
          // ✅ Koppeling naar statusbar-route via de box
          OnEnter := ChildMouseEnter;  // Delphi-mode: GEEN @
          OnExit  := ChildMouseExit;

          OnStatus := StatusFromChild;
          AddCommonSimProps('TjanSimLight');
        end;
        Continue;
      end;

      // ---- TjanSchakelRelais ----
      if obj[1] = 'TjanSchakelRelais' then
      begin
        with TjanSchakelRelais.Create(self) do
        begin
          Parent := wc; Tag := wc.ControlCount;
          Left   := StrToInt(Trim(obj[3]));
          Top    := StrToInt(Trim(obj[4]));
          FObjectID := wc.ControlCount; Lock := True;

          if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';
          OnEnter := ChildMouseEnter;  // Delphi-mode: GEEN @
          OnExit  := ChildMouseExit;
          OnStatus := StatusFromChild;

          AddCommonSimProps('TjanSchakelRelais');
        end;
        Continue;
      end;

      // ---- TjanSimRelais ----
      if obj[1] = 'TjanSimRelais' then
      begin
        with TjanSimRelais.Create(self) do
        begin
          Parent := wc; Tag := wc.ControlCount;
          Left   := StrToInt(Trim(obj[3]));
          Top    := StrToInt(Trim(obj[4]));
          Height := StrToInt(Trim(obj[2]));
          Width  := StrToInt(Trim(obj[5]));
          FObjectID := wc.ControlCount; Lock := True;

          if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';
          // DIT
          // ✅ Koppeling naar statusbar-route via de box
          OnEnter := ChildMouseEnter;  // Delphi-mode: GEEN @
          OnExit  := ChildMouseExit;

          OnStatus := StatusFromChild;

          AddCommonSimProps('TjanSimRelais');
        end;
        Continue;
      end;

      // ---- TjanSimBuzzer ----
      if obj[1] = 'TjanSimBuzzer' then
      begin
        with TjanSimBuzzer.Create(self) do
        begin
          Parent := wc; Tag := wc.ControlCount;
          Left   := StrToInt(Trim(obj[3]));
          Top    := StrToInt(Trim(obj[4]));
          Height := StrToInt(Trim(obj[2]));
          Width  := StrToInt(Trim(obj[5]));
          FObjectID := wc.ControlCount; Lock := True;
            //aanpassen
          if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';
          // DIT
          // ✅ Koppeling naar statusbar-route via de box
          OnEnter := ChildMouseEnter;  // Delphi-mode: GEEN @
          OnExit  := ChildMouseExit;

          OnStatus := StatusFromChild;
          AddCommonSimProps('TjanSimBuzzer');
        end;
        Continue;
      end;

      // ---- TjanSimMotor ----
      if obj[1] = 'TjanSimMotor' then
      begin
        with TjanSimMotor.Create(self) do
        begin
          Parent := wc; Tag := wc.ControlCount;
          Left := StrToInt(Trim(obj[3]));
          Top  := StrToInt(Trim(obj[4]));
          FObjectID := wc.ControlCount; Lock := True;
          BTaal := StatTaalToBTaal(Language);
        end;
        Continue;
      end;

      // ---- TjanSimPersoon (begint altijd links, bij S1) en TjanSimWagen
      // (begint altijd aan de start) ----
      if (obj[1] = 'TjanSimPersoon') or (obj[1] = 'TjanSimWagen') or (obj[1] = 'TjanSimMuziek') or
         (obj[1] = 'TjanSimVerkeerslicht') or (obj[1] = 'TjanSimSlagboom') then
      begin
        if obj[1] = 'TjanSimWagen' then
          PersoonKlasse := TjanSimWagen
        else if obj[1] = 'TjanSimMuziek' then
          PersoonKlasse := TjanSimMuziek
        else if obj[1] = 'TjanSimVerkeerslicht' then
          PersoonKlasse := TjanSimVerkeerslicht
        else if obj[1] = 'TjanSimSlagboom' then
          PersoonKlasse := TjanSimSlagboom
        else
          PersoonKlasse := TjanSimPersoon;
        with PersoonKlasse.Create(self) do
        begin
          Parent := wc; Tag := wc.ControlCount;
          Left := StrToInt(Trim(obj[3]));
          Top  := StrToInt(Trim(obj[4]));
          FObjectID := wc.ControlCount; Lock := True;
          BTaal := StatTaalToBTaal(Language);
        end;
        Continue;
      end;

      // ---- TjanSimEindschakelaar;height;left;top;width;kanaal ----
      if obj[1] = 'TjanSimEindschakelaar' then
      begin
        with TjanSimEindschakelaar.Create(self) do
        begin
          Parent := wc; Tag := wc.ControlCount;
          Left := StrToInt(Trim(obj[3]));
          Top  := StrToInt(Trim(obj[4]));
          // kanaal: het veld na de breedte (S begint nog bij de breedte)
          positie := Pos(';', S);
          if positie > 0 then
            Kanaal := StrToIntDef(Trim(Copy(S, positie + 1,
              Pos(';', Copy(S, positie + 1, MaxInt)) - 1)), 0);
          FObjectID := wc.ControlCount; Lock := True;
          BTaal := StatTaalToBTaal(Language);
        end;
        Continue;
      end;

      // ---- TjanSimStappenteller (of TjanSimStopwatch);height;left;top;width;eindwaarde;herhalen ----
      // bij de stopwatch is de eindwaarde de eindtijd in seconden
      if (obj[1] = 'TjanSimStappenteller') or (obj[1] = 'TjanSimStopwatch') or (obj[1] = 'TjanSimFlipFlop') then
      begin
        if obj[1] = 'TjanSimFlipFlop' then
          StT := TjanSimFlipFlop.Create(self)
        else if obj[1] = 'TjanSimStopwatch' then
          StT := TjanSimStopwatch.Create(self)
        else
          StT := TjanSimStappenteller.Create(self);
        with StT do
        begin
          Parent := wc; Tag := wc.ControlCount;
          Left := StrToInt(Trim(obj[3]));
          Top  := StrToInt(Trim(obj[4]));
          // S begint nog bij de breedte
          Eindwaarde := StrToIntDef(VeldNr(S, 1), 1000);
          Herhalen := VeldNr(S, 2) = '1';
          FObjectID := wc.ControlCount; Lock := True;
          BTaal := StatTaalToBTaal(Language);
        end;
        Continue;
      end;

      // ---- TjanLogicRun;height;left;top;width;programma ----
      if obj[1] = 'TjanLogicRun' then
      begin
        // hoogte, links, boven en breedte staan al in obj[2..5]; de rest
        // van de regel na de breedte is het programma
        positie := Pos(';', S);
        Delete(S, 1, positie);
        // er is er hoogstens één op een paneel
        if (positie > 0) and (FindLogicRun(wc) = nil) then
        begin
          LR := TjanLogicRun.Create(Self);
          LR.Parent := wc;
          LR.Tag := wc.ControlCount;
          LR.Left := StrToIntDef(Trim(obj[3]), 0);
          LR.Top := StrToIntDef(Trim(obj[4]), 0);
          LR.SetProgramText(S);
          LR.BTaal := StatTaalToBTaal(Language);
          LR.Lock := True;
        end;
        Continue;
      end;

      // ---- TjanDisplay ----
      if obj[1] = 'TjanDisplay' then
      begin
        with TjanDisplay.Create(self) do
        begin
          Parent := wc; Tag := wc.ControlCount;
          Left   := StrToInt(Trim(obj[3]));
          Top    := StrToInt(Trim(obj[4]));
          Height := StrToInt(Trim(obj[2]));
          Width  := StrToInt(Trim(obj[5]));
          FObjectID := wc.ControlCount; Lock := True;
            //aanpassen
          if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';
          // DIT
          // ✅ Koppeling naar statusbar-route via de box
          OnEnter := ChildMouseEnter;  // Delphi-mode: GEEN @
          OnExit  := ChildMouseExit;

          OnStatus := StatusFromChild;
          AddCommonSimProps('TjanDisplay');
        end;
        Continue;
      end;

      // Onbekend type → negeren
    end;
  end;
  // Hierboven schrijft "FObjectID := wc.ControlCount" (binnen de with-
  // blokken) in het ObjectID van de BOX: dat wees daarna naar het laatst
  // ingelezen object. ObjectID hoort alleen bij een nieuw geplaatst object.
  FNew := False;
  FObjectID := -1;
  if FAppend then Exit;   // plakken: AddFromList doet de rest
  // bewaard met de balk links: bij de balk boven of onder opschuiven
  ShiftPanelObjects(LayoutShift.X, LayoutShift.Y);
  BlokkeerObjecten(False);
  // paneel bewaard met een andere tekenwijze: voedingsdraden bijstellen
  RealignPowerWires(wc);
  // oud paneel (zonder bron): een bron met draden naar de rails bijzetten
  if not VoedingMark then
    EnsureBron;
  UpdateSupply(wc, True);
end;

function TjanSimLogicBox.AddRail(ALeft, ATop, AHeight: Integer; APlus: Boolean;
  AVolt: Double): TjanRail;
begin
  Result := TjanRail.Create(Self);
  Result.Parent := FParent;
  Result.Plus := APlus;
  Result.Volt := AVolt;
  if AHeight < RailLabelH + RailMinLen + RailFootH then
    AHeight := RailLabelH + RailMinLen + RailFootH;
  Result.SetBounds(ALeft, ATop, RailWidth, AHeight);
  Result.Box := Self;
  Result.BTaal := StatTaalToBTaal(Language);
  Result.OnStatus := StatusFromChild;
end;

procedure TjanSimLogicBox.NewLogicRun;
var
  LR: TjanLogicRun;
begin
  if (FParent = nil) or (FindLogicRun(FParent) <> nil) then Exit;
  LR := TjanLogicRun.Create(Self);
  LR.Parent := FParent;
  LR.BTaal := StatTaalToBTaal(Language);
  // zoals een nieuw component uit de balk: volgt de muis tot de klik
  // (zie GridMouseMove/GridMouseDown/GridMouseUp in main.pas)
  LR.Visible := False;
  LR.Left := -200;
  LR.Tag := FParent.ControlCount;
  FObjectID := LR.Tag;
  FNew := True;
  Screen.Cursor := crCross;
end;

procedure TjanSimLogicBox.NewPersoon;
begin
  NewPersoonVan(TjanSimPersoon);
end;

procedure TjanSimLogicBox.NewWagen;
begin
  NewPersoonVan(TjanSimWagen);
end;

procedure TjanSimLogicBox.NewMuziek;
begin
  NewPersoonVan(TjanSimMuziek);
end;

// persoon of wagentje maken (zelfde soort blok)
procedure TjanSimLogicBox.NewPersoonVan(AKlasse: TComponentClass);
var
  P: TjanSimPersoon;
begin
  if FParent = nil then Exit;
  P := TjanSimPersoon(AKlasse.Create(Self));
  P.Parent := FParent;
  P.BTaal := StatTaalToBTaal(Language);
  // zoals een nieuw component uit de balk: volgt de muis tot de klik
  P.Visible := False;
  P.Left := -300;
  P.Tag := FParent.ControlCount;
  FObjectID := P.Tag;
  FNew := True;
  Screen.Cursor := crCross;
end;

procedure TjanSimLogicBox.NewRail(APlus: Boolean);
var
  R: TjanRail;
begin
  if FParent = nil then Exit;
  if APlus then
    R := AddRail(-100, 0, 200, True, RailMaxVolt)
  else
    R := AddRail(-100, 0, 200, False, 0);
  // zoals een nieuw component uit de balk: volgt de muis tot de klik
  // (zie GridMouseMove/GridMouseDown/GridMouseUp in main.pas)
  R.Visible := False;
  R.Tag := FParent.ControlCount;
  FObjectID := R.Tag;
  FNew := True;
  Screen.Cursor := crCross;
end;

procedure TjanSimLogicBox.SetupVoedingsDeel(D: TjanVoedingsDeel);
begin
  D.Box := Self;
  D.BTaal := StatTaalToBTaal(Language);
  D.OnStatus := StatusFromChild;
end;

// 0 = bron (accu), 1 = zekering, 2 = milliampèremeter, 3 = weerstand,
// 4 = lamp, 5 = schakelaar, 6 = voltmeter (met twee klemmen)
procedure TjanSimLogicBox.NewVoedingsDeel(AKind: Integer);
var
  D: TjanVoedingsDeel;
begin
  if FParent = nil then Exit;
  case AKind of
    0: D := TjanBron.Create(Self);
    1: D := TjanZekering.Create(Self);
    3: D := TjanWeerstand.Create(Self);
    4: D := TjanLamp2.Create(Self);
    5: D := TjanSchakelaar2.Create(Self);
    6: D := TjanVoltmeter2.Create(Self);
    7: D := TjanLed2.Create(Self);
    8: D := TjanCondensator.Create(Self);
    9: D := TjanWattMeter.Create(Self);
    10: D := TjanPotmeter.Create(Self);
    11: D := TjanDiode.Create(Self);
    12: D := TjanWisselbron.Create(Self);
    13: D := TjanScoop.Create(Self);
    14: D := TjanTransistor.Create(Self);
    15: D := TjanLDR.Create(Self);
    16: D := TjanNTC.Create(Self);
    17: D := TjanWissel2.Create(Self);
    18: D := TjanPuls2.Create(Self);
    19: D := TjanDip2.Create(Self);
    20: D := TjanMagneet.Create(Self);
    21: D := TjanKompas.Create(Self);
    22: D := TjanVeldplaat.Create(Self);
    23: D := TjanSpoel.Create(Self);
    24: D := TjanIJzer.Create(Self);
  else
    D := TjanAmpMeter.Create(Self);
  end;
  D.Parent := FParent;
  SetupVoedingsDeel(D);
  // zoals een nieuw component uit de balk: volgt de muis tot de klik
  D.Visible := False;
  D.Left := -200;
  D.Tag := FParent.ControlCount;
  FObjectID := D.Tag;
  FNew := True;
  Screen.Cursor := crCross;
end;

// Een paneel van vóór de bron (versie 1.10 en ouder) heeft rails met een
// eigen spanning. Zonder bron zou alles op 0 V staan: zet daarom boven
// elke + rail een bron met die spanning (zonder inwendige weerstand, zodat
// het paneel werkt zoals vroeger) en verbind ze met de rails.
procedure TjanSimLogicBox.EnsureBron;
const
  BronGap = 18;   // ruimte tussen de bronklemmen en het hoogste onderdeel
var
  wc: TWinControl;
  i, k, X, Y, Y1, Y2, MinTop, BronTop: Integer;
  RP, RM: TjanRail;
  B: TjanBron;
  A, E: TPoint;
  WA: TRect;

  function Clamp(V, Lo, Hi: Integer): Integer;
  begin
    Result := V;
    if Result < Lo then Result := Lo;
    if Result > Hi then Result := Hi;
  end;

  procedure AddWire(const AFrom, ATo: TPoint; AEdge: Double);
  var
    Con: TjanConnector;
  begin
    Con := TjanConnector.Create(Self);
    Con.Parent := wc;
    Con.Tag := wc.ControlCount;
    if ATo.X >= AFrom.X then
    begin
      if ATo.Y >= AFrom.Y then Con.V_ConPos := jcpTL else Con.V_ConPos := jcpBL;
    end
    else if ATo.Y >= AFrom.Y then Con.V_ConPos := jcpTR
    else Con.V_ConPos := jcpBR;
    Con.PlaceEnds(AFrom, ATo);
    // waar de knik in de draad zit (0..1); -1: meteen aan het begin, zodat
    // de draad eerst recht naar beneden gaat en dan opzij
    if AEdge < 0 then
    begin
      if Con.Width > 0 then Con.V_Edge := 4 / Con.Width;
    end
    else
      Con.V_Edge := AEdge;
    Con.Visible := True;
  end;

begin
  wc := FParent;
  if wc = nil then Exit;
  for i := 0 to wc.ControlCount - 1 do
    if wc.Controls[i] is TjanBron then Exit;
  if wc is TjanGridS then
    WA := TjanGridS(wc).GetWorkAreaRect
  else
    WA := wc.ClientRect;
  // De bron komt boven de + rail, boven alle onderdelen: de - draad loopt
  // dan bovenlangs naar de - rail en kruist niets. Is er bovenaan te weinig
  // plaats, dan schuift eerst het hele paneel wat naar beneden.
  MinTop := MaxInt;
  for i := 0 to wc.ControlCount - 1 do
    if (wc.Controls[i] <> Self) and wc.Controls[i].Visible and
       not (wc.Controls[i] is TCustomFrame) then
      if wc.Controls[i].Top < MinTop then MinTop := wc.Controls[i].Top;
  if MinTop = MaxInt then Exit;
  BronTop := MinTop - BronGap - (BronH - 7);   // - draad BronGap-6 boven alles
  if BronTop < WA.Top + 4 then
  begin
    ShiftPanelObjects(0, WA.Top + 4 - BronTop);
    BronTop := WA.Top + 4;
  end;
  for i := wc.ControlCount - 1 downto 0 do
  begin
    if not ((wc.Controls[i] is TjanRail) and TjanRail(wc.Controls[i]).Plus and
            wc.Controls[i].Visible) then Continue;
    RP := TjanRail(wc.Controls[i]);
    // de dichtste - rail
    RM := nil;
    for k := 0 to wc.ControlCount - 1 do
      if (wc.Controls[k] is TjanRail) and wc.Controls[k].Visible and
         not TjanRail(wc.Controls[k]).Plus then
        if (RM = nil) or (Abs(TjanRail(wc.Controls[k]).LineX - RP.LineX) <
                          Abs(RM.LineX - RP.LineX)) then
          RM := TjanRail(wc.Controls[k]);
    B := TjanBron.Create(Self);
    B.Parent := wc;
    SetupVoedingsDeel(B);
    B.RiIdx := 0;
    B.Volt := RP.SavedVolt;
    // De klemmen zitten onderaan (+ links, - rechts). De + klem staat net
    // links van de + rail: + gaat recht naar beneden en dan naar rechts tot
    // bovenaan de + rail; - gaat iets naar beneden en dan bovenlangs naar
    // de - rail (die zo nodig naar boven verlengd wordt).
    X := RP.LineX - 25;                      // + klem 18 links van de rail
    if X < WA.Left + 4 then X := WA.Left + 4;
    B.SetBounds(X, BronTop, BronW, BronH);
    B.Tag := wc.ControlCount;
    // + van de bron naar de + rail
    A := B.PinCenter(0);
    Y1 := Clamp(RP.SpanTop + 6, A.Y + 6, RP.SpanBottom - 2);
    E := Point(RP.LineX, Y1);
    AddWire(A, E, -1);
    // - van de bron naar de - rail, boven de onderdelen
    if RM <> nil then
    begin
      A := B.PinCenter(1);
      Y2 := A.Y + 9;
      // de - rail zo nodig naar boven verlengen tot boven die draad
      if RM.SpanTop > Y2 - 4 then
      begin
        Y := RM.Top - (RM.SpanTop - (Y2 - 4));
        RM.SetBounds(RM.Left, Y, RM.Width, RM.Height + RM.Top - Y);
      end;
      // en naar beneden als de draad er toch onder ligt
      if RM.SpanBottom < Y2 + 4 then
        RM.Height := Y2 + 4 + RailFootH - RM.Top + 1;
      E := Point(RM.LineX, Y2);
      AddWire(A, E, -1);
    end;
  end;
  UpdateSupply(wc, True);
end;

procedure TjanSimLogicBox.SupplyOnTimer(Sender: TObject);
begin
  // tijdens de simulatie doet cpuOnTimer dit
  if (FParent <> nil) and not cpu.Enabled then
    UpdateSupply(FParent, True);
end;

// knoppen van de voedingskring: 0 = bron, 1 = zekering, 2 = mA-meter
procedure TjanSimLogicBox.DrawVoedingButton(const R: TRect; AKind: Integer; ADown: Boolean);
var
  Rb: TRect;
  CX, CY, K: Integer;
begin
  Rb := R;
  with Canvas do
  begin
    Brush.Style := bsSolid;
    Brush.Color := clSilver;
    if FSymbolen <> Afbeelding then Brush.Color := SymKnopKleur;
    if not ADown then
      Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
    else
      Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
    FillRect(Rb);
    CX := (R.Left + R.Right) div 2;
    CY := (R.Top + R.Bottom) div 2;
    Pen.Color := clBlack;
    Pen.Width := 1;
    case AKind of
      0:
        begin
          // accu (batterij van cellen): lange en korte platen met
          // stippellijn ertussen, zoals het schemasymbool
          K := R.Left + (R.Right - R.Left - 16) div 2;
          Brush.Color := clBlack;
          FillRect(Rect(K, CY, K + 2, CY + 1));            // aansluiting links
          FillRect(Rect(K + 1, CY - 5, K + 2, CY + 6));    // lange plaat
          FillRect(Rect(K + 3, CY - 2, K + 4, CY + 3));    // korte plaat
          FillRect(Rect(K + 5, CY, K + 6, CY + 1));        // stippels
          FillRect(Rect(K + 7, CY, K + 8, CY + 1));
          FillRect(Rect(K + 9, CY, K + 10, CY + 1));
          FillRect(Rect(K + 11, CY - 5, K + 12, CY + 6));  // lange plaat
          FillRect(Rect(K + 13, CY - 2, K + 14, CY + 3));  // korte plaat
          FillRect(Rect(K + 13, CY, K + 16, CY + 1));      // aansluiting rechts
        end;
      1:
        begin
          // zekering: buisje met draadje
          Brush.Style := bsClear;
          Rectangle(Rect(CX - 7, CY - 4, CX + 8, CY + 5));
          MoveTo(R.Left + 3, CY); LineTo(R.Right - 3, CY);
        end;
      3:
        begin
          // weerstand: schemasymbool (rechthoek met aansluitdraadjes)
          Brush.Style := bsSolid;
          Brush.Color := RGBToColor(255, 200, 150);
          FillRect(Rect(CX - 5, CY - 3, CX + 6, CY + 4));
          Brush.Style := bsClear;
          Rectangle(Rect(CX - 5, CY - 3, CX + 6, CY + 4));
          MoveTo(R.Left + 2, CY); LineTo(CX - 5, CY);
          MoveTo(CX + 6, CY); LineTo(R.Right - 2, CY);
        end;
      4:
        begin
          // lamp met 2 klemmen: cirkel met kruis en aansluitdraadjes
          MoveTo(R.Left + 2, CY); LineTo(CX - 5, CY);
          MoveTo(CX + 6, CY); LineTo(R.Right - 2, CY);
          Brush.Style := bsSolid; Brush.Color := RGBToColor(255, 230, 120);
          Ellipse(Rect(CX - 5, CY - 5, CX + 6, CY + 6));
          MoveTo(CX - 3, CY - 3); LineTo(CX + 4, CY + 4);
          MoveTo(CX + 3, CY - 3); LineTo(CX - 4, CY + 4);
        end;
      18:
        begin
          // impulsgenerator: blokgolf
          MoveTo(R.Left + 3, CY + 4); LineTo(CX - 5, CY + 4); LineTo(CX - 5, CY - 4);
          LineTo(CX, CY - 4); LineTo(CX, CY + 4); LineTo(CX + 5, CY + 4);
          LineTo(CX + 5, CY - 4); LineTo(R.Right - 3, CY - 4);
        end;
      19:
        begin
          // dipschakelaar: vier schuifjes in een kastje
          Brush.Style := bsSolid; Brush.Color := clWhite;
          Rectangle(Rect(CX - 9, CY - 7, CX + 10, CY + 8));
          for K := 0 to 3 do
          begin
            Brush.Color := clGray;
            FillRect(Rect(CX - 7 + K * 4, CY - 5, CX - 5 + K * 4, CY + 6));
            Brush.Color := clRed;
            if K in [1, 3] then FillRect(Rect(CX - 7 + K * 4, CY - 5, CX - 5 + K * 4, CY - 1))
            else FillRect(Rect(CX - 7 + K * 4, CY + 2, CX - 5 + K * 4, CY + 6));
          end;
        end;
      17:
        begin
          // wisselschakelaar: het midden onderaan, contacten A en B bovenaan,
          // de hendel wijst naar A
          MoveTo(CX, R.Bottom - 2); LineTo(CX, CY + 4);
          MoveTo(R.Left + 2, CY - 4); LineTo(CX - 8, CY - 4);
          MoveTo(CX + 8, CY - 4); LineTo(R.Right - 2, CY - 4);
          Pen.Width := 2;
          MoveTo(CX, CY + 4); LineTo(CX - 5, CY - 2);
          Pen.Width := 1;
          Brush.Style := bsSolid; Brush.Color := clWhite;
          Ellipse(Rect(CX - 9, CY - 6, CX - 3, CY));
          Ellipse(Rect(CX + 3, CY - 6, CX + 9, CY));
          Brush.Color := clBlack;
          Ellipse(Rect(CX - 1, CY + 3, CX + 3, CY + 7));
        end;
      5:
        begin
          // schakelaar: twee contacten en een open hendel
          MoveTo(R.Left + 2, CY + 2); LineTo(CX - 4, CY + 2);
          LineTo(CX + 4, CY - 4);
          MoveTo(CX + 4, CY + 2); LineTo(R.Right - 2, CY + 2);
        end;
      7:
        begin
          // led: driehoek met streep en twee pijltjes
          MoveTo(R.Left + 2, CY); LineTo(CX - 4, CY);
          MoveTo(CX + 4, CY); LineTo(R.Right - 2, CY);
          Brush.Style := bsSolid; Brush.Color := RGBToColor(255, 80, 80);
          Polygon([Point(CX - 4, CY - 5), Point(CX + 3, CY), Point(CX - 4, CY + 5)]);
          MoveTo(CX + 3, CY - 5); LineTo(CX + 3, CY + 6);
          Pen.Color := clRed;
          MoveTo(CX, CY - 6); LineTo(CX + 4, CY - 10);
          MoveTo(CX + 3, CY - 5); LineTo(CX + 7, CY - 9);
          Pen.Color := clBlack;
        end;
      8:
        begin
          // condensator: twee platen
          MoveTo(R.Left + 2, CY); LineTo(CX - 2, CY);
          MoveTo(CX + 3, CY); LineTo(R.Right - 2, CY);
          Brush.Style := bsSolid; Brush.Color := clBlack;
          FillRect(Rect(CX - 3, CY - 6, CX - 1, CY + 7));
          FillRect(Rect(CX + 2, CY - 6, CX + 4, CY + 7));
        end;
      13:
        begin
          // oscilloscoop: donker schermpje met een groene sinus
          Brush.Style := bsSolid; Brush.Color := RGBToColor(10, 30, 15);
          FillRect(Rect(CX - 9, CY - 7, CX + 10, CY + 8));
          Pen.Color := RGBToColor(80, 255, 110);
          MoveTo(CX - 8, CY);
          for K := 1 to 16 do
            LineTo(CX - 8 + K, CY - Round(5 * Sin(2 * Pi * K / 16)));
          Pen.Color := clBlack;
        end;
      12:
        begin
          // wisselbron: cirkel met een sinus
          Brush.Style := bsSolid; Brush.Color := clWhite;
          Ellipse(Rect(CX - 7, CY - 7, CX + 8, CY + 8));
          MoveTo(CX - 5, CY);
          for K := 1 to 10 do
            LineTo(CX - 5 + K, CY - Round(4 * Sin(2 * Pi * K / 10)));
        end;
      11:
        begin
          // diode: grijze driehoek met een streep
          MoveTo(R.Left + 2, CY); LineTo(CX - 4, CY);
          MoveTo(CX + 4, CY); LineTo(R.Right - 2, CY);
          Brush.Style := bsSolid; Brush.Color := RGBToColor(160, 160, 160);
          Polygon([Point(CX - 4, CY - 5), Point(CX + 3, CY), Point(CX - 4, CY + 5)]);
          MoveTo(CX + 3, CY - 5); LineTo(CX + 3, CY + 6);
        end;
      10:
        begin
          // potentiometer: weerstand met een pijl (de loper) van onderen
          Brush.Style := bsSolid;
          Brush.Color := RGBToColor(255, 200, 150);
          FillRect(Rect(CX - 6, CY - 5, CX + 7, CY + 1));
          Brush.Style := bsClear;
          Rectangle(Rect(CX - 6, CY - 5, CX + 7, CY + 1));
          MoveTo(R.Left + 2, CY - 2); LineTo(CX - 6, CY - 2);
          MoveTo(CX + 7, CY - 2); LineTo(R.Right - 2, CY - 2);
          MoveTo(CX, CY + 7); LineTo(CX, CY + 2);
          Brush.Style := bsSolid; Brush.Color := clBlack;
          Polygon([Point(CX - 2, CY + 4), Point(CX + 3, CY + 4), Point(CX, CY + 1)]);
        end;
      15, 16:
        begin
          // LDR: weerstand met twee pijlen (licht); NTC: weerstand met een schuine streep
          MoveTo(R.Left + 2, CY + 2); LineTo(CX - 6, CY + 2);
          MoveTo(CX + 7, CY + 2); LineTo(R.Right - 2, CY + 2);
          Brush.Style := bsSolid;
          Brush.Color := RGBToColor(255, 228, 200);
          FillRect(Rect(CX - 6, CY - 1, CX + 7, CY + 6));
          Brush.Style := bsClear;
          Rectangle(Rect(CX - 6, CY - 1, CX + 7, CY + 6));
          if AKind = 15 then
          begin
            Pen.Color := RGBToColor(200, 140, 0);
            MoveTo(CX - 6, CY - 8); LineTo(CX - 2, CY - 3);
            MoveTo(CX - 1, CY - 8); LineTo(CX + 3, CY - 3);
            Pen.Color := clBlack;
          end
          else
          begin
            MoveTo(CX - 9, CY + 9); LineTo(CX - 5, CY + 9); LineTo(CX + 8, CY - 6);
          end;
        end;
      14:
        begin
          // transistor (NPN): cirkel, basis links, collector en emitter rechts
          Brush.Style := bsClear;
          Ellipse(Rect(CX - 7, CY - 7, CX + 8, CY + 8));
          MoveTo(R.Left + 2, CY); LineTo(CX - 2, CY);
          MoveTo(CX - 2, CY - 4); LineTo(CX - 2, CY + 5);
          MoveTo(CX - 2, CY - 2); LineTo(CX + 4, CY - 6); LineTo(CX + 4, R.Top + 2);
          MoveTo(CX - 2, CY + 2); LineTo(CX + 4, CY + 6); LineTo(CX + 4, R.Bottom - 2);
          Brush.Style := bsSolid; Brush.Color := clBlack;
          Polygon([Point(CX + 4, CY + 6), Point(CX + 1, CY + 6), Point(CX + 3, CY + 3)]);
        end;
      20:
        begin
          // staafmagneet: blauwe zuidpool links, rode noordpool rechts
          Brush.Style := bsSolid;
          Brush.Color := RGBToColor(40, 90, 200);
          FillRect(Rect(CX - 10, CY - 4, CX, CY + 5));
          Brush.Color := RGBToColor(215, 40, 40);
          FillRect(Rect(CX, CY - 4, CX + 10, CY + 5));
          Brush.Style := bsClear;
          Rectangle(Rect(CX - 10, CY - 4, CX + 10, CY + 5));
        end;
      21:
        begin
          // kompas: cirkel met een naald, rood naar boven
          Brush.Style := bsSolid;
          Brush.Color := clWhite;
          Ellipse(Rect(CX - 8, CY - 8, CX + 9, CY + 9));
          Brush.Color := RGBToColor(215, 30, 30);
          Polygon([Point(CX, CY - 6), Point(CX - 2, CY), Point(CX + 2, CY)]);
          Brush.Color := RGBToColor(160, 160, 160);
          Polygon([Point(CX, CY + 6), Point(CX - 2, CY), Point(CX + 2, CY)]);
        end;
      22:
        begin
          // veldlijnenplaat: blad met veldlijnen rond een magneetje
          Brush.Style := bsSolid;
          Brush.Color := RGBToColor(250, 247, 232);
          FillRect(Rect(R.Left + 3, R.Top + 3, R.Right - 3, R.Bottom - 3));
          Brush.Style := bsClear;
          Pen.Color := RGBToColor(120, 110, 90);
          Rectangle(Rect(R.Left + 3, R.Top + 3, R.Right - 3, R.Bottom - 3));
          Pen.Color := RGBToColor(90, 90, 90);
          Ellipse(Rect(CX - 8, CY - 6, CX + 9, CY + 7));
          Ellipse(Rect(CX - 6, CY - 3, CX + 7, CY + 4));
          Brush.Style := bsSolid;
          Brush.Color := RGBToColor(40, 90, 200);
          FillRect(Rect(CX - 4, CY - 1, CX, CY + 2));
          Brush.Color := RGBToColor(215, 40, 40);
          FillRect(Rect(CX, CY - 1, CX + 4, CY + 2));
          Pen.Color := clBlack;
        end;
      23:
        begin
          // spoel: koperen windingen met aansluitdraadjes
          MoveTo(R.Left + 2, CY); LineTo(CX - 8, CY);
          MoveTo(CX + 8, CY); LineTo(R.Right - 2, CY);
          Brush.Style := bsClear;
          Pen.Color := RGBToColor(184, 100, 30);
          for K := 0 to 4 do
            Ellipse(Rect(CX - 9 + K * 4, CY - 6, CX - 5 + K * 4, CY + 7));
          Pen.Color := clBlack;
        end;
      24:
        begin
          // spijker: kop, schacht en punt
          Brush.Style := bsSolid;
          Brush.Color := RGBToColor(100, 100, 110);
          FillRect(Rect(CX - 10, CY - 4, CX - 7, CY + 5));
          Brush.Color := RGBToColor(150, 150, 160);
          FillRect(Rect(CX - 7, CY - 1, CX + 6, CY + 2));
          Pen.Color := RGBToColor(150, 150, 160);
          Polygon([Point(CX + 6, CY - 2), Point(CX + 10, CY), Point(CX + 6, CY + 2)]);
          Pen.Color := clBlack;
        end;
      6:
        begin
          // voltmeter: cirkel met V
          MoveTo(R.Left + 2, CY); LineTo(CX - 6, CY);
          MoveTo(CX + 7, CY); LineTo(R.Right - 2, CY);
          Brush.Style := bsClear;
          Ellipse(Rect(CX - 6, CY - 6, CX + 7, CY + 7));
          MoveTo(CX - 3, CY - 3); LineTo(CX, CY + 4); LineTo(CX + 4, CY - 4);
        end;
    else
      begin
        // milliampèremeter: cirkel met A
        Brush.Style := bsClear;
        K := (R.Right - R.Left) div 2 - 3;
        if K > 9 then K := 9;
        Ellipse(Rect(CX - K, CY - K, CX + K + 1, CY + K + 1));
        Font.Name := 'Arial'; Font.Size := 8; Font.Style := [fsBold]; Font.Color := clNavy;
        TextOut(CX - TextWidth('A') div 2 + 1, CY - TextHeight('A') div 2, 'A');
      end;
    end;
    Brush.Style := bsSolid;
    Brush.Color := clSilver;
  end;
end;

procedure TjanSimLogicBox.LoadPanel(welke: string; Paneel: TjanGridS; codec: Boolean);
begin
  templijst.Clear;
  templijst.LoadFromFile(welke);
  if codec then
    Decode(templijst);
  InternalLoadFromList(templijst, Paneel);
end;

procedure TjanSimLogicBox.LoadPanelTemp(Paneel: TjanGridS);
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    L.Assign(TempFile);
    InternalLoadFromList(L, Paneel);
  finally
    L.Free;
  end;
end;

procedure TjanSimLogicBox.LoadStreamNew(welke: TStream; Paneel: TjanGridS; Inf: Boolean);
var
  L: TStringList;
  i: Integer;
  c: TControl;
begin
  // Zelfde start als LoadPanel / LoadPanelTemp
  KillPanel;
  FFilterLijst.Clear;
  if Assigned(Paneel) then
    Paneel.ShowStatusBar := Paneel.KStatusBalk;   // panelen zonder regel 'Statusbalk' volgen de instelling
  L := TStringList.Create;
  try
    // hele stream als tekst inlezen
    L.LoadFromStream(welke);

    // nieuwe parser gebruiken (zelfde formaat als SavePanel)
    InternalLoadFromList(L, Paneel);



    // Optioneel: Inf gebruiken zoals je oude LoadStream deed
    // (bijvoorbeeld hints activeren op connectors)
    if Inf then
    begin
      for i := 0 to FParent.ControlCount - 1 do
      begin
        c := FParent.Controls[i];
        if c is TjanConnector then
          TjanConnector(c).ShowHint := True;
      end;
    end;
  finally
    L.Free;
  end;
end;


PROCEDURE TjanSimLogicBox.LoadStream(welke:TStream;Inf:Boolean); //xxxx
VAR
i,positie:integer;
LF: TjanLogicFunc;
S:string;
templijst:TStringlist;
obj:array[1..10] of string;
wc:TWinControl;
BEGIN
killpanel;
wc:=FParent;
FFilterLijst.Clear;
templijst:=TStringList.Create;
templijst.LoadFromStream(welke);
 for i:= 0 to templijst.Count -1 do
  begin
   S:=Templijst.Strings[i];
   // uitlezen van welk component we gaan genereren
   positie:= Pos(';',S);obj[1]:=copy(S,1,positie-1);delete(S,1,positie);
   If obj[1] = 'TjanConnector' then
        begin
        //
        positie:= Pos(';',S);obj[2]:=copy(S,1,positie-1);delete(S,1,positie);  // height
        positie:= Pos(';',S);obj[3]:=copy(S,1,positie-1);delete(S,1,positie);  // Left
        positie:= Pos(';',S);obj[4]:=copy(S,1,positie-1);delete(S,1,positie);  // top
        positie:= Pos(';',S);obj[5]:=copy(S,1,positie-1);delete(S,1,positie); // width
        //
        positie:= Pos(';',S);obj[6]:=copy(S,1,positie-1);delete(S,1,positie); // mode
        positie:= Pos(';',S);obj[7]:=copy(S,1,positie-1);delete(S,1,positie); // pos
        positie:= Pos(';',S);obj[8]:=copy(S,1,positie-1); // shape
          with TjanConnector.create(self) do
            begin
             parent:=wc;tag:= wc.ControlCount;
             left:=StrToInt(obj[3]);top:=StrToInt(obj[4]);
             Height:=StrToInt(obj[2]);width:=StrToInt(obj[5]);
             if (Inf=true) then showhint:=true else showhint:=false;
             if obj[6]='jcmTL' then V_ConMode:=jcmTL;
             if obj[6]='jcmTR' then V_ConMode:=jcmTR;
             if obj[6]='jcmBL' then V_ConMode:=jcmBL;
             if obj[6]='jcmBR' then V_ConMode:=jcmBR;

             if obj[7]='jcpTL' then V_ConPos:=jcpTL;
             if obj[7]='jcpTR' then V_ConPos:=jcpTR;
             if obj[7]='jcpBL' then V_ConPos:=jcpBL;
             if obj[7]='jcpBR' then V_ConPos:=jcpBR;

             if obj[8]='jcsTLBR' then V_ConShape:=jcsTLBR;
             if obj[8]='jcsTRBL' then V_ConShape:=jcsTRBL;

             FObjectID:= wc.ControlCount;
             s:='TjanConnector.Left';AddFilter (s);s:='TjanConnector.Top';AddFilter (s);
             s:='TjanConnector.width';AddFilter (s);s:='TjanConnector.Height';AddFilter (s);
             s:='TjanConnector.W_ConMode';AddFilter (s);s:='TjanConnector.W_ConPos';AddFilter (s);
             s:='TjanConnector.W_ConShape';AddFilter (s);
            end;
        end;
   If obj[1] <> 'TjanLogic' then
     begin
     positie:= Pos(';',S);obj[2]:=copy(S,1,positie-1);delete(S,1,positie);  // height
     positie:= Pos(';',S);obj[3]:=copy(S,1,positie-1);delete(S,1,positie);  // Left
     positie:= Pos(';',S);obj[4]:=copy(S,1,positie-1);delete(S,1,positie);  // top
     positie:= Pos(';',S);obj[5]:=copy(S,1,positie-1); // width
     If obj[1] = 'TjanSimButton' then
        begin
          with TjanSimButton.create(self) do  ///xxxx
            begin
             parent:=wc;tag:= wc.ControlCount;
             left:=StrToInt(obj[3]);top:=StrToInt(obj[4]);
             Height:=StrToInt(obj[2]);width:=StrToInt(obj[5]);
             FObjectID:= wc.ControlCount;Lock:=true;


             if Language = stDutch   then BTaal := 'NL'  else
             if Language = stEnglish then BTaal := 'ENG' else
             if Language = stFrench  then BTaal := 'FR' else
             if Language = stGerman  then BTaal := 'DU';


             OnStatus := StatusFromChild;

             if (Inf=true) then showhint:=true else showhint:=false;
             s:='TjanSimButton.Left';AddFilter (s);s:='TjanSimButton.Top';AddFilter (s);
             s:='TjanSimButton.width';AddFilter (s);s:='TjanSimButton.Height';AddFilter (s);
            end;
        end;
     If obj[1] = 'TjanSimKnop' then
        begin
          with TjanSimKnop.create(self) do
            begin
             parent:=wc;tag:= wc.ControlCount;
             left:=StrToInt(obj[3]);top:=StrToInt(obj[4]);
             Height:=StrToInt(obj[2]);width:=StrToInt(obj[5]);
             FObjectID:= wc.ControlCount;Lock:=true;
             if Language = stDutch   then BTaal := 'NL'  else
             if Language = stEnglish then BTaal := 'ENG' else
             if Language = stFrench  then BTaal := 'FR' else
             if Language = stGerman  then BTaal := 'DU';


             OnStatus := StatusFromChild;
             if (Inf=true) then showhint:=true else showhint:=false;
             s:='TjanSimKnop.Left';AddFilter (s);s:='TjanSimKnop.Top';AddFilter (s);
             s:='TjanSimKnop.width';AddFilter (s);s:='TjanSimKnop.Height';AddFilter (s);
            end;
        end;
     If obj[1] = 'TjanSimSensor' then
        begin
          with TjanSimSensor.create(self) do
            begin
             parent:=wc;tag:= wc.ControlCount;
             left:=StrToInt(obj[3]);top:=StrToInt(obj[4]);
             Height:=StrToInt(obj[2]);width:=StrToInt(obj[5]);
             FObjectID:= wc.ControlCount;Lock:=true;
             if Language = stDutch   then BTaal := 'NL'  else
             if Language = stEnglish then BTaal := 'ENG' else
             if Language = stFrench  then BTaal := 'FR' else
             if Language = stGerman  then BTaal := 'DU';

               OnStatus := StatusFromChild;
             if (Inf=true) then showhint:=true else showhint:=false;
             s:='TjanSimSensor.Left';AddFilter (s);s:='TjanSimSensor.Top';AddFilter (s);
             s:='TjanSimSensor.width';AddFilter (s);s:='TjanSimSensor.Height';AddFilter (s);
            end;
        end;
     If obj[1] = 'TjanSimWarm' then
        begin
          with TjanSimWarm.create(self) do
            begin
             parent:=wc;tag:= wc.ControlCount;
             left:=StrToInt(obj[3]);top:=StrToInt(obj[4]);
             Height:=StrToInt(obj[2]);width:=StrToInt(obj[5]);
             FObjectID:= wc.ControlCount;Lock:=true;
             if Language = stDutch   then BTaal := 'NL'  else
             if Language = stEnglish then BTaal := 'ENG' else
             if Language = stFrench  then BTaal := 'FR' else
             if Language = stGerman  then BTaal := 'DU';


             OnStatus := StatusFromChild;


             if (Inf=true) then showhint:=true else showhint:=false;
             s:='TjanSimWarm.Left';AddFilter (s);s:='TjanSimWarm.Top';AddFilter (s);
             s:='TjanSimWarm.width';AddFilter (s);s:='TjanSimWarm.Height';AddFilter (s);
            end;
        end;
     If obj[1] = 'TjanSimPuls' then
        begin
          with TjanSimPuls.create(self) do
            begin
             parent:=wc;tag:= wc.ControlCount;
             left:=StrToInt(obj[3]);top:=StrToInt(obj[4]);
             Height:=StrToInt(obj[2]);width:=StrToInt(obj[5]);
             FObjectID:= wc.ControlCount;Lock:=true;
                if Language = stDutch   then BTaal := 'NL'  else
             if Language = stEnglish then BTaal := 'ENG' else
             if Language = stFrench  then BTaal := 'FR' else
             if Language = stGerman  then BTaal := 'DU';

               OnStatus := StatusFromChild;
             if (Inf=true) then showhint:=true else showhint:=false;
             s:='TjanSimPuls.Left';AddFilter (s);s:='TjanSimPuls.Top';AddFilter (s);
             s:='TjanSimPuls.width';AddFilter (s);s:='TjanSimPuls.Height';AddFilter (s);
            end;
        end;
     If obj[1] = 'TjanDipSwitsh' then
        begin
          with TjanDipSwitsh.create(self) do
            begin
             parent:=wc;tag:= wc.ControlCount;
             left:=StrToInt(obj[3]);top:=StrToInt(obj[4]);
             Height:=StrToInt(obj[2]);width:=StrToInt(obj[5]);
             FObjectID:= wc.ControlCount;Lock:=true;

          if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';
          // DIT
          // ✅ Koppeling naar statusbar-route via de box
          OnEnter := ChildMouseEnter;  // Delphi-mode: GEEN @
          OnExit  := ChildMouseExit;

          OnStatus := StatusFromChild;

             if (Inf=true) then showhint:=true else showhint:=false;
             s:='TjanDipSwitsh.Left';AddFilter (s);s:='TjanDipSwitsh.Top';AddFilter (s);
             s:='TjanDipSwitsh.width';AddFilter (s);s:='TjanDipSwitsh.Height';AddFilter (s);
            end;
        end;
     If obj[1] = 'TjanTeller' then
        begin
          with TjanTeller.create(self) do
            begin
             parent:=wc;tag:= wc.ControlCount;
             left:=StrToInt(obj[3]);top:=StrToInt(obj[4]);
             Height:=StrToInt(obj[2]);width:=StrToInt(obj[5]);
             FObjectID:= wc.ControlCount;Lock:=true;
             if Language = stDutch   then BTaal := 'NL'  else
          if Language = stEnglish then BTaal := 'ENG' else
          if Language = stFrench  then BTaal := 'FR' else
          if Language = stGerman  then BTaal := 'DU';
           // DIT
          // ✅ Koppeling naar statusbar-route via de box
          OnEnter := ChildMouseEnter;  // Delphi-mode: GEEN @
          OnExit  := ChildMouseExit;
            OnStatus := StatusFromChild;
             if (Inf=true) then showhint:=true else showhint:=false;
             s:='TjanTeller.Left';AddFilter (s);s:='TjanTeller.Top';AddFilter (s);
             s:='TjanTeller.width';AddFilter (s);s:='TjanTeller.Height';AddFilter (s);
            end;
        end;
     If obj[1] = 'TjanMemory' then
        begin
          with TjanMemory.create(self) do
            begin
             parent:=wc;tag:= wc.ControlCount;
             left:=StrToInt(obj[3]);top:=StrToInt(obj[4]);
             Height:=StrToInt(obj[2]);width:=StrToInt(obj[5]);
             FObjectID:= wc.ControlCount;Lock:=true;
               if Language = stDutch   then BTaal := 'NL'  else
             if Language = stEnglish then BTaal := 'ENG' else
             if Language = stFrench  then BTaal := 'FR' else
             if Language = stGerman  then BTaal := 'DU';

               OnStatus := StatusFromChild;
             if (Inf=true) then showhint:=true else showhint:=false;
             s:='TjanMemory.Left';AddFilter (s);s:='TjanMemory.Top';AddFilter (s);
             s:='TjanMemory.width';AddFilter (s);s:='TjanMemory.Height';AddFilter (s);

            end;
        end;
     If obj[1] = 'TjanSimLight' then
        begin
          with TjanSimLight.create(self) do
            begin
             parent:=wc;tag:= wc.ControlCount;
             left:=StrToInt(obj[3]);top:=StrToInt(obj[4]);
             Height:=StrToInt(obj[2]);width:=StrToInt(obj[5]);
             FObjectID:= wc.ControlCount;Lock:=true;
               if Language = stDutch   then BTaal := 'NL'  else
             if Language = stEnglish then BTaal := 'ENG' else
             if Language = stFrench  then BTaal := 'FR' else
             if Language = stGerman  then BTaal := 'DU';

               OnStatus := StatusFromChild;
             if (Inf=true) then showhint:=true else showhint:=false;
             s:='TjanSimLight.Left';AddFilter (s);s:='TjanSimLight.Top';AddFilter (s);
             s:='TjanSimLight.width';AddFilter (s);s:='TjanSimLight.Height';AddFilter (s);
            end;
        end;
     If obj[1] = 'TjanSchakelRelais' then
        begin
          with TjanSchakelRelais.create(self) do
            begin
             parent:=wc;tag:= wc.ControlCount;
             left:=StrToInt(obj[3]);top:=StrToInt(obj[4]);
             FObjectID:= wc.ControlCount;Lock:=true;
             if Language = stDutch   then BTaal := 'NL'  else
             if Language = stEnglish then BTaal := 'ENG' else
             if Language = stFrench  then BTaal := 'FR' else
             if Language = stGerman  then BTaal := 'DU';
             OnStatus := StatusFromChild;
             if (Inf=true) then showhint:=true else showhint:=false;
             s:='TjanSchakelRelais.Left';AddFilter (s);s:='TjanSchakelRelais.Top';AddFilter (s);
             s:='TjanSchakelRelais.width';AddFilter (s);s:='TjanSchakelRelais.Height';AddFilter (s);
            end;
        end;
     If obj[1] = 'TjanSimRelais' then
        begin
          with TjanSimRelais.create(self) do
            begin
             parent:=wc;tag:= wc.ControlCount;
             left:=StrToInt(obj[3]);top:=StrToInt(obj[4]);
             Height:=StrToInt(obj[2]);width:=StrToInt(obj[5]);
             FObjectID:= wc.ControlCount;Lock:=true;
               if Language = stDutch   then BTaal := 'NL'  else
             if Language = stEnglish then BTaal := 'ENG' else
             if Language = stFrench  then BTaal := 'FR' else
             if Language = stGerman  then BTaal := 'DU';

               OnStatus := StatusFromChild;

               //aanpassen
             if (Inf=true) then showhint:=true else showhint:=false;
             s:='TjanSimRelais.Left';AddFilter (s);s:='TjanSimRelais.Top';AddFilter (s);
             s:='TjanSimRelais.width';AddFilter (s);s:='TjanSimRelais.Height';AddFilter (s);
            end;
        end;
     If obj[1] = 'TjanSimBuzzer' then
        begin
          with TjanSimBuzzer.create(self) do
            begin
             parent:=wc;tag:= wc.ControlCount;
             left:=StrToInt(obj[3]);top:=StrToInt(obj[4]);
             Height:=StrToInt(obj[2]);width:=StrToInt(obj[5]);
             FObjectID:= wc.ControlCount;Lock:=true;
               if Language = stDutch   then BTaal := 'NL'  else
             if Language = stEnglish then BTaal := 'ENG' else
             if Language = stFrench  then BTaal := 'FR' else
             if Language = stGerman  then BTaal := 'DU';

               OnStatus := StatusFromChild;
               // aanpassen
             if (Inf=true) then showhint:=true else showhint:=false;
             s:='TjanSimBuzzer.Left';AddFilter (s);s:='TjanSimBuzzer.Top';AddFilter (s);
             s:='TjanSimBuzzer.width';AddFilter (s);s:='TjanSimBuzzer.Height';AddFilter (s);
            end;
        end;
     If obj[1] = 'TjanDisplay' then
        begin
          with TjanDisplay.create(self) do
            begin
             parent:=wc;tag:= wc.ControlCount;
             left:=StrToInt(obj[3]);top:=StrToInt(obj[4]);
             Height:=StrToInt(obj[2]);width:=StrToInt(obj[5]);
             FObjectID:= wc.ControlCount;Lock:=true;
               FObjectID:= wc.ControlCount;Lock:=true;
               if Language = stDutch   then BTaal := 'NL'  else
             if Language = stEnglish then BTaal := 'ENG' else
             if Language = stFrench  then BTaal := 'FR' else
             if Language = stGerman  then BTaal := 'DU';

               OnStatus := StatusFromChild;
               // aanpassen
             if (Inf=true) then showhint:=true else showhint:=false;
             s:='TjanDisplay.Left';AddFilter (s);s:='TjanDisplay.Top';AddFilter (s);
             s:='TjanDisplay.width';AddFilter (s);s:='TjanDisplay.Height';AddFilter (s);
            end;
        end;
     end;

     If obj[1] = 'TjanLogic' then
     begin
     positie:= Pos(';',S);obj[2]:=copy(S,1,positie-1);delete(S,1,positie);  // height
     positie:= Pos(';',S);obj[3]:=copy(S,1,positie-1);delete(S,1,positie);  // Left
     positie:= Pos(';',S);obj[4]:=copy(S,1,positie-1);delete(S,1,positie);  // L_Type(string)
     positie:= Pos(';',S);obj[5]:=copy(S,1,positie-1);delete(S,1,positie); // Top
     positie:= Pos(';',S);obj[6]:=copy(S,1,positie-1); // Width
      with TjanLogic.create(self) do
            begin
             parent:=wc;
             tag:= wc.ControlCount;
             left:=StrToInt(obj[3]);
             top:=StrToInt(obj[5]);
             Height:=StrToInt(obj[2]);
             width:=StrToInt(obj[6]);
             FObjectID:= wc.ControlCount;Lock:=true;
             if LogicFuncFromCode(obj[4], LF) then logicFunc:=LF;
              FObjectID:= wc.ControlCount;Lock:=true;
               if Language = stDutch   then BTaal := 'NL'  else
             if Language = stEnglish then BTaal := 'ENG' else
             if Language = stFrench  then BTaal := 'FR' else
             if Language = stGerman  then BTaal := 'DU';

               OnStatus := StatusFromChild;


             if (Inf=true) then showhint:=true else showhint:=false;
             s:='TjanLogic.Left';AddFilter (s);s:='TjanLogic.Top';AddFilter (s);
             s:='TjanLogic.width';AddFilter (s);s:='TjanLogic.Height';AddFilter (s);
             s:='TjanLogic.L_Type';AddFilter (s);
            end;
      end;
  end;
templijst.Free;
END;

procedure TjanSimLogicBox.CMMouseEnter(var Msg:TMessage);
 var
 p:TPoint;
begin
  inherited;
  if Assigned (FOnEnter) then FOnEnter(Self);
end;

procedure TjanSimLogicBox.CMMouseLeave(var Msg:TMessage);
begin
  inherited;
  if Assigned (FOnLeave) then FOnLeave(Self);
  DoStatusText('',0);
end;

procedure TjanSimLogicBox.StartKlok;
begin
  cpu.Enabled := True;
end;

procedure TjanSimLogicBox.Loaded;
begin
  inherited;
  cpu.Enabled:=true;
end;
