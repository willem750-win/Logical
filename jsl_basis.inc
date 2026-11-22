// janSimLogic.pas, deel: hulpcode, invoervenster, klok van de elektronen (ingevoegd met {$I jsl_basis.inc})
// magnetisch rechttrekken van draden bij het slepen (zie verderop)
procedure StraightenWires(AConnectors: TList; var ANewLeft, ANewTop: Integer); forward;
// staat er een + rail onder spanning (voedingskring, zie UpdateSupply)?
function SupplyOK(P: TWinControl): Boolean; forward;
// tekenwijze (Afbeelding/IEC/ANSI) van een onderdeel (zie verderop)
function SymOf(C: TComponent): TjanSymbolen; forward;

// veld N (vanaf 0) van een regel met ; als scheiding, '' als het ontbreekt
function VeldNr(const S: string; N: Integer): string;
var
  i, k, Start: Integer;
begin
  Result := '';
  k := 0;
  Start := 1;
  for i := 1 to Length(S) + 1 do
    if (i > Length(S)) or (S[i] = ';') then
    begin
      if k = N then
        Exit(Trim(Copy(S, Start, i - Start)));
      Inc(k);
      Start := i + 1;
    end;
end;

  var
    // nummer van de huidige simulatieronde (cpuOnTimer, alle draden één keer)
    SimRonde: Cardinal = 0;
    GlobalSimBox: TjanSimLogicBox;

CONST
 crDrukknop          = 1;
 crSchakelaar        = 2;
 crSensor            = 3;
 crWarm              = 4;
 crPuls              = 5;
 crDip               = 6;
 crAnd               = 7;
 crOr                = 8;
 crNot               = 9;
 crTeller            = 10;
 crGeheugen          = 11;
 crLamp              = 12;
 crRelais            = 13;
 crZoemer            = 14;
 crDisplay           = 15;
 crDraad             = 16;
 crMeter             = 17;

 function BuildSimHint(const ANaam, ABTaal: string): string;
 var
   s: string;
 begin
   if ABTaal = 'NL' then
     s := 'Rechter muisknop voor extra instellingen'
   else if ABTaal = 'ENG' then
     s := 'Right mouse button for extra settings'
   else if ABTaal = 'FR' then
     s := 'Bouton droit pour paramètres supplémentaires'
   else if ABTaal = 'DU' then
     s := 'Rechte Maustaste für zusätzliche Einstellungen'
   else
     s := 'Right mouse button for extra settings';
   Result := ANaam + #13#10 + s;
 end;



 function StatTaalToBTaal(T: TStatTaal): string;
 begin
   case T of
     stDutch:  Result := 'NL';
     stEnglish: Result := 'ENG';
     stFrench:  Result := 'FR';
     stGerman:  Result := 'DU';
   else
     Result := 'ENG';
   end;
 end;

function Tr(const BTaal, NL, ENG, FR, DU: string): string;
begin
  if BTaal = 'NL' then Result := NL
  else if BTaal = 'ENG' then Result := ENG
  else if BTaal = 'FR' then Result := FR
  else if BTaal = 'DU' then Result := DU
  else Result := ENG;
  // extra taal (lang\<code>.po): zie LangTrHook in chatgridpcodeSmall
  if Result = ENG then Result := LangTr(ENG);
end;

// Code van een poort in een paneelbestand (TjanLogic;H;Left;CODE;Top;W)
function LogicFuncCode(F: TjanLogicFunc): string;
begin
  case F of
    jlfAND:  Result := 'EN';
    jlfOR:   Result := 'OF';
    jlfNOT:  Result := 'NIET';
    jlfNAND: Result := 'NEN';
    jlfNOR:  Result := 'NOF';
  else
    Result := 'EXOF';
  end;
end;

// Omgekeerd: code uit een paneelbestand naar soort; False = onbekend
function LogicFuncFromCode(const S: string; out F: TjanLogicFunc): Boolean;
begin
  Result := True;
  if S = 'EN' then F := jlfAND
  else if S = 'OF' then F := jlfOR
  else if S = 'NIET' then F := jlfNOT
  else if S = 'NEN' then F := jlfNAND
  else if S = 'NOF' then F := jlfNOR
  else if S = 'EXOF' then F := jlfXOR
  else Result := False;
end;

// Woord op de poort (Afbeelding) en in de knop, in de taal BTaal
function LogicFuncWoord(F: TjanLogicFunc; const BTaal: string): string;
begin
  case F of
    jlfAND:  Result := Tr(BTaal, 'EN', 'AND', 'ET', 'UND');
    jlfOR:   Result := Tr(BTaal, 'OF', 'OR', 'OU', 'ODER');
    jlfNOT:  Result := Tr(BTaal, 'NIET', 'NOT', 'PAS', 'NICHT');
    jlfNAND: Result := Tr(BTaal, 'NEN', 'NAND', 'NON-ET', 'NAND');
    jlfNOR:  Result := Tr(BTaal, 'NOF', 'NOR', 'NON-OU', 'NOR');
  else
    Result := Tr(BTaal, 'EX-OF', 'XOR', 'OU-X', 'XOR');
  end;
end;


constructor TInputBoxForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  BorderStyle := bsDialog;
  Position := poScreenCenter;
  Width := 300;
  Height := 130;

  Caption := 'Input';

  FLabel := TLabel.Create(Self);
  FLabel.Parent := Self;
  FLabel.Left := 8;
  FLabel.Top := 8;

  FEdit := TEdit.Create(Self);
  FEdit.Parent := Self;
  FEdit.Left := 8;
  FEdit.Top := 28;
  FEdit.Width := ClientWidth - 16;

  FOkButton := TButton.Create(Self);
  FOkButton.Parent := Self;
  FOkButton.Caption := 'OK';
  FOkButton.ModalResult := mrOk;
  FOkButton.Left := ClientWidth - 170;
  FOkButton.Top := 65;
  FOkButton.Width := 75;

  FCancelButton := TButton.Create(Self);
  FCancelButton.Parent := Self;
  FCancelButton.Caption := LangTr('Cancel');
  FCancelButton.ModalResult := mrCancel;
  FCancelButton.Left := ClientWidth - 85;
  FCancelButton.Top := 65;
  FCancelButton.Width := 75;

  ActiveControl := FEdit;
end;


function TInputBoxForm.Execute(
  const ACaption, APrompt, ADefault: string;
  out AResult: string): Boolean;
begin
  Caption := ACaption;
  FLabel.Caption := APrompt;
  FEdit.Text := ADefault;

  Result := ShowModal = mrOk;
  if Result then
    AResult := FEdit.Text;
end;




procedure Register;
begin
  RegisterComponents('JWLOGIC', [TjanMeter,TjanDisplay,TjanConnector,TjanLogic,TjanTeller,TjanSimButton,TjanSimKnop,
                                 TjanSimPuls,TjanSimLight, TjanSimRelais,TjanSimBuzzer,TjanSimSensor,TjanSimWarm,
                                 TjanSimLogicBox,TjanMemory,TjanDipSwitsh]);
end;

procedure movecursor;
var
pt:TPoint;
begin
if (screen.cursor=crDraad) then
   begin
    Application.ProcessMessages;
    GetCursorPos(pt);
    SetCursorPos(pt.x + 35 - 10, pt.y+15);
    //screen.cursor:=crDefault;
   end;
end;

// ============================================================
// Elektronen in de draden van de voedingskring: bolletjes die met de
// stroom meeschuiven (aan te zetten bij de bron: Elektronen tonen)
// ============================================================
const
  ElektronMinA = 0.0005;   // minder stroom: geen elektronen
  ElektronAfstand = 14;    // pixels tussen twee elektronen
type
  TElektronKlok = class
    procedure Tik(Sender: TObject);
  end;
var
  ElektronDraden: TList = nil;      // draden waar stroom door gaat
  // de box van het programma (er is er een): de draden selecteren daarmee
  DraadBox: TjanSimLogicBox = nil;
  ElektronTimer: TTimer = nil;
  ElektronKlok: TElektronKlok = nil;
  // tijd van de animatie (s). Loopt per tik hoogstens ElektronMaxStap op:
  // bij weinig beelden per seconde (Linux) zou de snelste stroom anders per
  // beeld bijna een hele afstand opschuiven, en dan lijken de elektronen
  // stil te staan of achteruit te gaan (stroboscoop)
  ElektronTijd: Double = 0;
  ElektronLaatste: QWord = 0;
const
  ElektronMaxSnel = 120;   // pixels per seconde (bij 300 mA en meer)
  ElektronMaxStap = 0.35 * ElektronAfstand / ElektronMaxSnel;

procedure TElektronKlok.Tik(Sender: TObject);
var
  i: Integer;
  Nu: QWord;
  Dt: Double;
begin
  if ElektronDraden = nil then Exit;
  Nu := GetTickCount64;
  if ElektronLaatste > 0 then
  begin
    Dt := (Nu - ElektronLaatste) / 1000;
    if Dt > ElektronMaxStap then Dt := ElektronMaxStap;
    ElektronTijd := ElektronTijd + Dt;
  end;
  ElektronLaatste := Nu;
  for i := 0 to ElektronDraden.Count - 1 do
    if TObject(ElektronDraden[i]) is TjanConnector then
      TjanConnector(ElektronDraden[i]).InvalidateElektronen
    else if TObject(ElektronDraden[i]) is TjanRail then
      TjanRail(ElektronDraden[i]).InvalidateElektronen
    else
      TControl(ElektronDraden[i]).Invalidate;
end;

// C (draad of rail) in of uit de lijst van de klok
procedure ElektronLijst(C: TControl; AAan: Boolean);
begin
  if ElektronDraden = nil then ElektronDraden := TList.Create;
  if AAan then
  begin
    if ElektronDraden.IndexOf(C) < 0 then ElektronDraden.Add(C);
    if ElektronTimer = nil then
    begin
      ElektronKlok := TElektronKlok.Create;
      ElektronTimer := TTimer.Create(nil);
      ElektronTimer.Interval := 40;
      ElektronTimer.OnTimer := ElektronKlok.Tik;
    end;
    ElektronTimer.Enabled := True;
  end
  else
  begin
    ElektronDraden.Remove(C);
    if (ElektronDraden.Count = 0) and (ElektronTimer <> nil) then
      ElektronTimer.Enabled := False;
  end;
end;

// fase (0..ElektronAfstand) van de elektronen bij stroom AI; AI > 0: de
// (conventionele) stroom gaat in de richting van de weg, de elektronen
// schuiven terug
function KleinsteI(A, B: Integer): Integer;
begin
  if A < B then Result := A else Result := B;
end;

function GrootsteI(A, B: Integer): Integer;
begin
  if A > B then Result := A else Result := B;
end;

function ElektronFase(AI: Double): Double;
var
  Snel: Double;
begin
  Snel := 400 * Abs(AI);
  if Snel < 8 then Snel := 8;
  if Snel > ElektronMaxSnel then Snel := ElektronMaxSnel;
  Result := Frac(ElektronTijd * Snel / ElektronAfstand) * ElektronAfstand;
  if AI > 0 then Result := ElektronAfstand - Result;
end;

procedure Maakdraad(T,L:integer;wc:TWincontrol);
begin
with TjanConnector.create(wc) do   //wc
 begin
 parent:=wc;
 left:=L;top:=T;height:=25;width:=35;visible:=true;
 tag:= wc.ControlCount;
end;
end;

procedure Maakconnector(T,L,R,B:integer;wc:TWincontrol);
begin
with TjanConnector.create(wc) do
 begin
 parent:=wc;
 left:=L;top:=T;
 height:=B;width:=R;
 visible:=true;
 tag:= wc.ControlCount;
 BringToFront;
 end;
end;
