unit uBoard;

{ Een echt Arduino-board (Uno, Nano) via USB, met het Firmata-protocol
  (StandardFirmata, 57600 baud). Op het paneel staan de onderdelen
  TjanBoardIn (een echte drukknop op een pin, met interne pull-up) en
  TjanBoardUit (een lamp van 5 V die een echte pin hoog of laag zet).

  TBoard: de seriële poort (Windows en Linux, zonder extra pakketten), het
  Firmata-protocol en een timer die het board leest en de pinnen instelt.
  TBoardForm: het venster om een poort te kiezen en te verbinden. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Graphics,
  {$IFDEF WINDOWS}Windows, Registry,{$ELSE}BaseUnix, termio,{$ENDIF}
  janSimLogic, uLangPo;

type

  { TBoard }

  TBoard = class(TComponent)
  private
    FPaneel: TWinControl;          // waar de onderdelen op staan (Grid)
    {$IFDEF WINDOWS}
    FHandle: THandle;
    {$ELSE}
    FFd: cint;
    {$ENDIF}
    FOpen: Boolean;
    FPoort: string;
    FTimer: TTimer;
    FStart: QWord;                 // moment van openen (het board herstart)
    FKlaar: Boolean;               // na het herstarten: pinnen ingesteld
    FVersie: string;               // Firmata-versie die het board meldt
    FUitPort: array[0..2] of Byte; // laatst gestuurde waarden per poort (8 pinnen)
    FInPort: array[0..2] of Integer;  // gelezen waarden per poort, -1 = nog niet
    FModus: array[0..19] of Integer;  // ingestelde modus per pin, -1 = niet
    // ontvangen bytes ontleden
    FCmd: Byte;
    FData: array[0..1] of Byte;
    FNData, FNodig: Integer;
    FInSysex: Boolean;
    FFout: Boolean;                // schrijven mislukt: de timer verbreekt
    FTel: Integer;                 // tikken van de timer
    FOnStatus: TNotifyEvent;
    procedure Stuur(const B: array of Byte);
    function Lees(var Buf; N: Integer): Integer;
    procedure TimerTick(Sender: TObject);
    procedure Ontvang(B: Byte);
    procedure Bericht;
    procedure PinnenInstellen;
    procedure IngangenBijwerken;
    procedure Melden;
  public
    constructor Create(AOwner: TComponent; APaneel: TWinControl); reintroduce;
    destructor Destroy; override;
    class procedure Poorten(L: TStrings);
    function Verbind(const APoort: string): Boolean;
    procedure Verbreek;
    procedure Schrijf(APin: Integer; AHoog: Boolean);
    // pin in servomodus zetten en de hoek (0..180 graden) sturen
    procedure SchrijfServo(APin, AHoek: Integer);
    property Open: Boolean read FOpen;
    property Klaar: Boolean read FKlaar;
    property Poort: string read FPoort;
    property Versie: string read FVersie;
    property OnStatus: TNotifyEvent read FOnStatus write FOnStatus;
  end;

  { TBoardForm }

  TBoardForm = class(TForm)
  private
    FBoard: TBoard;
    FTaal: string;
    FUitleg, FPoortLabel, FStatus: TLabel;
    FPoorten: TComboBox;
    FVernieuw, FVerbind: TButton;
    function T(const NL, EN, FR, DE: string): string;
    procedure VernieuwClick(Sender: TObject);
    procedure VerbindClick(Sender: TObject);
    procedure BoardStatus(Sender: TObject);
  public
    constructor CreateVoor(AOwner: TComponent; ABoard: TBoard); reintroduce;
    procedure SetTaal(const ATaal: string);
    procedure ToonStatus;
  end;

function MaakBoardGlyph: Graphics.TBitmap;

implementation

const
  Baud = 57600;
  ModusIn = 0;
  ModusUit = 1;
  ModusPullUp = $0B;
  ModusServo = 4;

{ TBoard }

constructor TBoard.Create(AOwner: TComponent; APaneel: TWinControl);
var
  i: Integer;
begin
  inherited Create(AOwner);
  FPaneel := APaneel;
  {$IFDEF WINDOWS}
  FHandle := INVALID_HANDLE_VALUE;
  {$ELSE}
  FFd := -1;
  {$ENDIF}
  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.Interval := 15;
  FTimer.OnTimer := @TimerTick;
  for i := 0 to 19 do FModus[i] := -1;
end;

destructor TBoard.Destroy;
begin
  Verbreek;
  inherited Destroy;
end;

// de seriële poorten van de computer (COM3, /dev/ttyACM0 ...)
class procedure TBoard.Poorten(L: TStrings);
{$IFDEF WINDOWS}
var
  R: TRegistry;
  Namen: TStringList;
  i: Integer;
begin
  L.Clear;
  R := TRegistry.Create(KEY_READ);
  Namen := TStringList.Create;
  try
    R.RootKey := HKEY_LOCAL_MACHINE;
    if R.OpenKeyReadOnly('HARDWARE\DEVICEMAP\SERIALCOMM') then
    begin
      R.GetValueNames(Namen);
      for i := 0 to Namen.Count - 1 do
        L.Add(R.ReadString(Namen[i]));
    end;
  finally
    Namen.Free;
    R.Free;
  end;
end;
{$ELSE}
var
  Sr: TSearchRec;
  Patroon: string;
begin
  L.Clear;
  for Patroon in ['/dev/ttyACM*', '/dev/ttyUSB*'] do
    if FindFirst(Patroon, faAnyFile, Sr) = 0 then
    begin
      repeat
        L.Add('/dev/' + Sr.Name);
      until FindNext(Sr) <> 0;
      FindClose(Sr);
    end;
end;
{$ENDIF}

function TBoard.Verbind(const APoort: string): Boolean;
var
  i: Integer;
  {$IFDEF WINDOWS}
  Dcb: TDCB;
  Tm: TCommTimeouts;
  {$ELSE}
  Tio: Termios;
  {$ENDIF}
begin
  Verbreek;
  Result := False;
  {$IFDEF WINDOWS}
  FHandle := CreateFileW(PWideChar(UnicodeString('\\.\' + APoort)), GENERIC_READ or GENERIC_WRITE,
    0, nil, OPEN_EXISTING, 0, 0);
  if FHandle = INVALID_HANDLE_VALUE then Exit;
  FillChar(Dcb, SizeOf(Dcb), 0);
  Dcb.DCBlength := SizeOf(Dcb);
  GetCommState(FHandle, Dcb);
  Dcb.BaudRate := Baud;
  Dcb.ByteSize := 8;
  Dcb.Parity := NOPARITY;
  Dcb.StopBits := ONESTOPBIT;
  Dcb.Flags := $11;            // fBinary, DTR aan (het board herstart)
  if not SetCommState(FHandle, Dcb) then
  begin
    CloseHandle(FHandle);
    FHandle := INVALID_HANDLE_VALUE;
    Exit;
  end;
  // lezen geeft meteen terug wat er is (niet wachten)
  FillChar(Tm, SizeOf(Tm), 0);
  Tm.ReadIntervalTimeout := MAXDWORD;
  Tm.WriteTotalTimeoutConstant := 200;
  SetCommTimeouts(FHandle, Tm);
  {$ELSE}
  FFd := FpOpen(APoort, O_RDWR or O_NOCTTY or O_NONBLOCK);
  if FFd < 0 then Exit;
  if TCGetAttr(FFd, Tio) <> 0 then
  begin
    FpClose(FFd);
    FFd := -1;
    Exit;
  end;
  CFMakeRaw(Tio);
  CFSetISpeed(Tio, B57600);
  CFSetOSpeed(Tio, B57600);
  Tio.c_cflag := Tio.c_cflag or CLOCAL or CREAD;
  TCSetAttr(FFd, TCSANOW, Tio);
  {$ENDIF}
  FOpen := True;
  FPoort := APoort;
  FFout := False;
  FTel := 0;
  FStart := GetTickCount64;
  FKlaar := False;
  FVersie := '';
  FNData := 0; FNodig := 0; FInSysex := False; FCmd := 0;
  for i := 0 to 2 do
  begin
    FUitPort[i] := 0;
    FInPort[i] := -1;
  end;
  for i := 0 to 19 do FModus[i] := -1;
  FTimer.Enabled := True;
  Result := True;
  Melden;
end;

procedure TBoard.Verbreek;
var
  i: Integer;
begin
  FTimer.Enabled := False;
  if FOpen and FKlaar then
  begin
    // alle uitgangen laag, zodat er niets blijft branden
    for i := 0 to 2 do
      if FUitPort[i] <> 0 then
      begin
        FUitPort[i] := 0;
        Stuur([$90 or i, 0, 0]);
      end;
  end;
  {$IFDEF WINDOWS}
  if FHandle <> INVALID_HANDLE_VALUE then CloseHandle(FHandle);
  FHandle := INVALID_HANDLE_VALUE;
  {$ELSE}
  if FFd >= 0 then FpClose(FFd);
  FFd := -1;
  {$ENDIF}
  FOpen := False;
  FKlaar := False;
  if BoardVerbonden then
  begin
    BoardVerbonden := False;
    BoardSchrijf := nil;
    BoardServo := nil;
    if FPaneel <> nil then
      for i := 0 to FPaneel.ControlCount - 1 do
        if (FPaneel.Controls[i] is TjanBoardIn) or (FPaneel.Controls[i] is TjanBoardUit) then
        begin
          TjanVoedingsDeel(FPaneel.Controls[i]).UpdateHintText;
          FPaneel.Controls[i].Invalidate;
        end;
  end;
  Melden;
end;

procedure TBoard.Stuur(const B: array of Byte);
var
  {$IFDEF WINDOWS}
  N: DWORD;
  {$ENDIF}
  Buf: array[0..15] of Byte;
  i: Integer;
begin
  if not FOpen then Exit;
  for i := 0 to High(B) do Buf[i] := B[i];
  {$IFDEF WINDOWS}
  if not WriteFile(FHandle, Buf, Length(B), N, nil) then FFout := True;
  {$ELSE}
  if FpWrite(FFd, Buf, Length(B)) < 0 then
    if FpGetErrno <> ESysEAGAIN then FFout := True;
  {$ENDIF}
end;

function TBoard.Lees(var Buf; N: Integer): Integer;
{$IFDEF WINDOWS}
var
  Got: DWORD;
begin
  Result := 0;
  if not FOpen then Exit;
  if ReadFile(FHandle, Buf, N, Got, nil) then
    Result := Got
  else
  begin
    Result := -1;   // het board is losgekoppeld
  end;
end;
{$ELSE}
begin
  Result := 0;
  if not FOpen then Exit;
  Result := FpRead(FFd, Buf, N);
  if Result < 0 then
    if FpGetErrno = ESysEAGAIN then Result := 0;
end;
{$ENDIF}

procedure TBoard.Schrijf(APin: Integer; AHoog: Boolean);
var
  P: Integer;
  Oud: Byte;
begin
  if not (FOpen and FKlaar) or (APin < 0) or (APin > 19) then Exit;
  if FModus[APin] <> ModusUit then
  begin
    Stuur([$F4, APin, ModusUit]);
    FModus[APin] := ModusUit;
  end;
  P := APin div 8;
  Oud := FUitPort[P];
  if AHoog then
    FUitPort[P] := FUitPort[P] or (1 shl (APin mod 8))
  else
    FUitPort[P] := FUitPort[P] and not (1 shl (APin mod 8));
  if FUitPort[P] <> Oud then
    Stuur([$90 or P, FUitPort[P] and $7F, FUitPort[P] shr 7]);
end;

procedure TBoard.SchrijfServo(APin, AHoek: Integer);
begin
  if not (FOpen and FKlaar) or (APin < 2) or (APin > 13) then Exit;
  if AHoek < 0 then AHoek := 0;
  if AHoek > 180 then AHoek := 180;
  if FModus[APin] <> ModusServo then
  begin
    Stuur([$F4, APin, ModusServo]);
    FModus[APin] := ModusServo;
  end;
  // analoog bericht: E0 + pin, 7 lage bits, 7 hoge bits
  Stuur([$E0 or APin, AHoek and $7F, AHoek shr 7]);
end;

procedure TBoard.TimerTick(Sender: TObject);
var
  Buf: array[0..255] of Byte;
  N, i: Integer;
begin
  if not FOpen then Exit;
  N := Lees(Buf, SizeOf(Buf));
  if (N < 0) or FFout then
  begin
    Verbreek;
    Exit;
  end;
  for i := 0 to N - 1 do Ontvang(Buf[i]);
  if not FKlaar then
  begin
    // het board herstart bij het openen van de poort: even wachten
    if GetTickCount64 - FStart < 2200 then Exit;
    FKlaar := True;
    Stuur([$F9]);        // versie vragen
    BoardSchrijf := @Schrijf;
    BoardServo := @SchrijfServo;
    BoardVerbonden := True;
    PinnenInstellen;
    // alle uitgangen meteen sturen, de hints bijwerken
    if FPaneel <> nil then
      for i := 0 to FPaneel.ControlCount - 1 do
        if FPaneel.Controls[i] is TjanBoardUit then
          TjanBoardUit(FPaneel.Controls[i]).Stuur(True);
    IngangenBijwerken;
    Melden;
    Exit;
  end;
  // af en toe: zijn er onderdelen bijgekomen of van pin veranderd?
  Inc(FTel);
  if FTel mod 30 = 0 then PinnenInstellen;
end;

// de pinnen van de onderdelen op het paneel instellen (ingang met pull-up of
// uitgang) en de poorten met ingangen laten melden
procedure TBoard.PinnenInstellen;
var
  i, P: Integer;
  MeldPoort: array[0..2] of Boolean;
begin
  if not (FOpen and FKlaar) or (FPaneel = nil) then Exit;
  for i := 0 to 2 do MeldPoort[i] := False;
  for i := 0 to FPaneel.ControlCount - 1 do
    if FPaneel.Controls[i] is TjanBoardIn then
    begin
      P := TjanBoardIn(FPaneel.Controls[i]).Pin;
      if FModus[P] <> ModusPullUp then
      begin
        Stuur([$F4, P, ModusPullUp]);
        FModus[P] := ModusPullUp;
        MeldPoort[P div 8] := True;
      end;
    end
    else if FPaneel.Controls[i] is TjanBoardUit then
    begin
      P := TjanBoardUit(FPaneel.Controls[i]).Pin;
      if FModus[P] <> ModusUit then
      begin
        Stuur([$F4, P, ModusUit]);
        FModus[P] := ModusUit;
        TjanBoardUit(FPaneel.Controls[i]).Stuur(True);
      end;
    end;
  for i := 0 to 2 do
    if MeldPoort[i] then
      Stuur([$D0 or i, 1]);    // deze poort melden bij elke verandering
end;

procedure TBoard.Ontvang(B: Byte);
begin
  if FInSysex then
  begin
    if B = $F7 then FInSysex := False;
    Exit;
  end;
  if B >= $80 then
  begin
    FCmd := B;
    FNData := 0;
    if B = $F0 then
    begin
      FInSysex := True;
      FNodig := 0;
    end
    else if (B and $F0 = $90) or (B and $F0 = $E0) or (B = $F9) then
      FNodig := 2
    else
      FNodig := 0;
    Exit;
  end;
  if FNodig = 0 then Exit;
  FData[FNData] := B;
  Inc(FNData);
  if FNData >= FNodig then
  begin
    Bericht;
    FNData := 0;   // "running status": dezelfde opdracht kan herhaald worden
  end;
end;

procedure TBoard.Bericht;
var
  P: Integer;
begin
  if FCmd = $F9 then
  begin
    FVersie := Format('%d.%d', [FData[0], FData[1]]);
    Melden;
  end
  else if FCmd and $F0 = $90 then
  begin
    P := FCmd and $0F;
    if P <= 2 then
    begin
      FInPort[P] := FData[0] or (FData[1] shl 7);
      IngangenBijwerken;
    end;
  end;
end;

// de onderdelen TjanBoardIn volgen de gelezen pinnen; ingedrukt = laag (pull-up)
procedure TBoard.IngangenBijwerken;
var
  i, P: Integer;
  Laag: Boolean;
begin
  if FPaneel = nil then Exit;
  for i := 0 to FPaneel.ControlCount - 1 do
    if FPaneel.Controls[i] is TjanBoardIn then
    begin
      P := TjanBoardIn(FPaneel.Controls[i]).Pin;
      if FInPort[P div 8] < 0 then Continue;
      Laag := (FInPort[P div 8] shr (P mod 8)) and 1 = 0;
      if TjanBoardIn(FPaneel.Controls[i]).Aan <> Laag then
        TjanBoardIn(FPaneel.Controls[i]).Aan := Laag;
      TjanBoardIn(FPaneel.Controls[i]).UpdateHintText;
      FPaneel.Controls[i].Invalidate;
    end;
end;

procedure TBoard.Melden;
begin
  if Assigned(FOnStatus) then FOnStatus(Self);
end;

{ TBoardForm }

constructor TBoardForm.CreateVoor(AOwner: TComponent; ABoard: TBoard);
begin
  inherited CreateNew(AOwner);
  FBoard := ABoard;
  FBoard.OnStatus := @BoardStatus;
  FTaal := 'NL';
  BorderStyle := bsToolWindow;
  FormStyle := fsStayOnTop;
  Position := poMainFormCenter;
  Width := 420;
  Height := 250;

  FUitleg := TLabel.Create(Self);
  FUitleg.Parent := Self;
  FUitleg.WordWrap := True;
  FUitleg.AutoSize := False;
  FUitleg.SetBounds(12, 10, 396, 92);

  FPoortLabel := TLabel.Create(Self);
  FPoortLabel.Parent := Self;
  FPoortLabel.SetBounds(12, 112, 80, 20);

  FPoorten := TComboBox.Create(Self);
  FPoorten.Parent := Self;
  FPoorten.Style := csDropDownList;
  FPoorten.SetBounds(100, 108, 170, 24);

  FVernieuw := TButton.Create(Self);
  FVernieuw.Parent := Self;
  FVernieuw.SetBounds(278, 107, 130, 26);
  FVernieuw.OnClick := @VernieuwClick;

  FVerbind := TButton.Create(Self);
  FVerbind.Parent := Self;
  FVerbind.SetBounds(100, 142, 170, 30);
  FVerbind.Font.Style := [fsBold];
  FVerbind.OnClick := @VerbindClick;

  FStatus := TLabel.Create(Self);
  FStatus.Parent := Self;
  FStatus.WordWrap := True;
  FStatus.AutoSize := False;
  FStatus.SetBounds(12, 182, 396, 56);

  VernieuwClick(nil);
  SetTaal('NL');
end;

function TBoardForm.T(const NL, EN, FR, DE: string): string;
begin
  if FTaal = 'ENG' then Result := PoTr(EN)
  else if FTaal = 'FR' then Result := FR
  else if FTaal = 'DU' then Result := DE
  else Result := NL;
end;

procedure TBoardForm.SetTaal(const ATaal: string);
begin
  FTaal := ATaal;
  Caption := T('Arduino-board', 'Arduino board', 'Carte Arduino', 'Arduino-Board');
  FUitleg.Caption := T(
    'Verbind een Arduino Uno of Nano met de USB-kabel. Zet er eerst één keer StandardFirmata op (Arduino IDE: Bestand > Voorbeelden > Firmata > StandardFirmata, en Uploaden). Plaats dan een Arduino-ingang of -uitgang uit de groep Voeding op het paneel.',
    'Connect an Arduino Uno or Nano with the USB cable. First put StandardFirmata on it once (Arduino IDE: File > Examples > Firmata > StandardFirmata, then Upload). Then place an Arduino input or output from the Power group on the panel.',
    'Branchez une Arduino Uno ou Nano avec le câble USB. Chargez-y d''abord une fois StandardFirmata (Arduino IDE : Fichier > Exemples > Firmata > StandardFirmata, puis Téléverser). Placez ensuite une entrée ou une sortie Arduino du groupe Alimentation sur le panneau.',
    'Verbinden Sie einen Arduino Uno oder Nano mit dem USB-Kabel. Spielen Sie zuerst einmal StandardFirmata auf (Arduino IDE: Datei > Beispiele > Firmata > StandardFirmata, dann Hochladen). Setzen Sie dann einen Arduino-Eingang oder -Ausgang aus der Gruppe Versorgung auf das Panel.');
  FPoortLabel.Caption := T('Poort:', 'Port:', 'Port :', 'Port:');
  FVernieuw.Caption := T('Zoek poorten', 'Find ports', 'Chercher les ports', 'Ports suchen');
  ToonStatus;
end;

procedure TBoardForm.ToonStatus;
begin
  if FBoard.Open then
    FVerbind.Caption := T('Verbreken', 'Disconnect', 'Déconnecter', 'Trennen')
  else
    FVerbind.Caption := T('Verbinden', 'Connect', 'Connecter', 'Verbinden');
  FPoorten.Enabled := not FBoard.Open;
  FVernieuw.Enabled := not FBoard.Open;
  if not FBoard.Open then
  begin
    if FPoorten.Items.Count = 0 then
      FStatus.Caption := T('Geen poort gevonden. Steek het board in en klik op Zoek poorten.',
        'No port found. Plug in the board and click Find ports.',
        'Aucun port trouvé. Branchez la carte et cliquez sur Chercher les ports.',
        'Kein Port gefunden. Stecken Sie das Board ein und klicken Sie auf Ports suchen.')
    else
      FStatus.Caption := T('Niet verbonden.', 'Not connected.', 'Non connecté.', 'Nicht verbunden.');
  end
  else if not FBoard.Klaar then
    FStatus.Caption := Format(T('Verbinden met %s... (het board herstart even)',
      'Connecting to %s... (the board restarts for a moment)',
      'Connexion à %s... (la carte redémarre un instant)',
      'Verbinden mit %s... (das Board startet kurz neu)'), [FBoard.Poort])
  else if FBoard.Versie <> '' then
    FStatus.Caption := Format(T('Verbonden met %s (Firmata %s). De onderdelen op het paneel volgen nu het board.',
      'Connected to %s (Firmata %s). The components on the panel now follow the board.',
      'Connecté à %s (Firmata %s). Les composants du panneau suivent maintenant la carte.',
      'Verbunden mit %s (Firmata %s). Die Bauteile auf dem Panel folgen jetzt dem Board.'), [FBoard.Poort, FBoard.Versie])
  else
    FStatus.Caption := Format(T('Poort %s is open, maar het board antwoordt niet. Staat StandardFirmata erop?',
      'Port %s is open, but the board does not answer. Is StandardFirmata on it?',
      'Le port %s est ouvert, mais la carte ne répond pas. StandardFirmata est-il chargé ?',
      'Port %s ist offen, aber das Board antwortet nicht. Ist StandardFirmata aufgespielt?'), [FBoard.Poort]);
end;

procedure TBoardForm.VernieuwClick(Sender: TObject);
var
  Oud: string;
begin
  Oud := FPoorten.Text;
  TBoard.Poorten(FPoorten.Items);
  if FPoorten.Items.IndexOf(Oud) >= 0 then
    FPoorten.ItemIndex := FPoorten.Items.IndexOf(Oud)
  else if FPoorten.Items.Count > 0 then
    FPoorten.ItemIndex := FPoorten.Items.Count - 1;   // meestal het laatst ingestoken board
  if Sender <> nil then ToonStatus;
end;

procedure TBoardForm.VerbindClick(Sender: TObject);
begin
  if FBoard.Open then
    FBoard.Verbreek
  else if FPoorten.ItemIndex >= 0 then
  begin
    if not FBoard.Verbind(FPoorten.Items[FPoorten.ItemIndex]) then
    begin
      FStatus.Caption := Format(T('Kan poort %s niet openen. Is ze in gebruik (bv. door de Arduino IDE)?',
        'Cannot open port %s. Is it in use (e.g. by the Arduino IDE)?',
        'Impossible d''ouvrir le port %s. Est-il utilisé (p. ex. par l''Arduino IDE) ?',
        'Port %s kann nicht geöffnet werden. Wird er benutzt (z. B. von der Arduino IDE)?'),
        [FPoorten.Items[FPoorten.ItemIndex]]);
      Exit;
    end;
  end;
  ToonStatus;
end;

procedure TBoardForm.BoardStatus(Sender: TObject);
begin
  ToonStatus;
end;

// knop in de bovenste balk: een blauwgroen board met een usb-stekker
function MaakBoardGlyph: Graphics.TBitmap;
begin
  Result := Graphics.TBitmap.Create;
  Result.SetSize(16, 16);
  with Result.Canvas do
  begin
    Brush.Color := clFuchsia;
    FillRect(0, 0, 16, 16);
    Brush.Color := RGBToColor(0, 130, 140);
    Pen.Color := RGBToColor(0, 80, 90);
    Rectangle(3, 2, 16, 15);
    Pen.Color := clWhite;
    MoveTo(6, 6); LineTo(14, 6);
    MoveTo(6, 9); LineTo(14, 9);
    MoveTo(6, 12); LineTo(12, 12);
    Brush.Color := clSilver;
    Pen.Color := clGray;
    Rectangle(0, 4, 5, 9);
  end;
  Result.TransparentColor := clFuchsia;
  Result.Transparent := True;
end;

end.
