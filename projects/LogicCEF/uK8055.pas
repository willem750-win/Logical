unit uK8055;

{ Velleman K8055 (USB-experimenteerbord) voor Logic.

  Het bordje is een HID-toestel (VID 10CF, PID 5500..5503 voor kaart 0..3),
  zonder eigen driver of DLL. Logic zoekt het zelf zodra er een K8055-ingang
  of -uitgang op het paneel staat, en verbindt automatisch.

  Berichten van 8 bytes (op Windows met een rapportnummer 0 ervoor):
  - schrijven: 5, uitgangen (bit 0 = OUT1), analoog 1, analoog 2, 0, 0, 0, 0
  - lezen (ongeveer elke 8 ms): ingangen (vreemde bitvolgorde, zie
    K8055Ingang), kaartnummer, analoog 1, analoog 2, tellers ...

  Een eigen draad leest de berichten; een timer op de hoofddraad zet de
  ingangen op het paneel (TjanK8055In) en houdt de verbinding in de gaten.
  Onder Linux: /dev/hidrawN (de gebruiker moet er mogen lezen en schrijven,
  zie de help). }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, ExtCtrls, janSimLogic
  {$IFDEF WINDOWS}, Windows{$ENDIF}
  {$IFDEF UNIX}, BaseUnix{$ENDIF};

type
  TK8055Leser = class(TThread)
  private
    FHandle: THandle;
  protected
    procedure Execute; override;
  public
    Data: array[0..7] of Byte;   // laatst gelezen bericht
    Teller: LongInt;             // aantal gelezen berichten
    Fout: Boolean;               // lezen mislukt (bordje weg)
    constructor Create(AHandle: THandle);
  end;

  TK8055 = class(TComponent)
  private
    FPaneel: TWinControl;
    FTimer: TTimer;
    FHandle: THandle;
    FOpen: Boolean;
    FLeser: TK8055Leser;
    FTel: Integer;
    FLaatsteIn: Integer;         // laatst toegepaste ingangen, -1 = nog niets
    FOnStatus: TNotifyEvent;
    procedure Tik(Sender: TObject);
    function ZoekPad: string;
    function Open: Boolean;
    procedure Sluit;
    procedure Schrijf(AMasker: Byte);
    procedure IngangenBijwerken(AData: Byte);
    procedure HintsBijwerken(AInval: Boolean);
    procedure AnaloogBijwerken(A1, A2: Byte);
    function OnderdelenOpPaneel: Boolean;
  public
    constructor Create(AOwner: TComponent; APaneel: TWinControl); reintroduce;
    destructor Destroy; override;
    property Verbonden: Boolean read FOpen;
    property OnStatus: TNotifyEvent read FOnStatus write FOnStatus;
  end;

implementation

const
  HidGuid: TGUID = '{4D1E55B2-F16F-11CF-88CB-001111000030}';

{$IFDEF WINDOWS}
const
  DIGCF_PRESENT = $2;
  DIGCF_DEVICEINTERFACE = $10;

type
  TSpDevIntData = record
    cbSize: DWORD;
    InterfaceClassGuid: TGUID;
    Flags: DWORD;
    Reserved: ULONG_PTR;
  end;

function SetupDiGetClassDevsW(ClassGuid: PGUID; Enumerator: PWideChar; hwndParent: HWND;
  Flags: DWORD): THandle; stdcall; external 'setupapi.dll';
function SetupDiEnumDeviceInterfaces(DevInfo: THandle; DevInfoData: Pointer; const Guid: TGUID;
  Index: DWORD; var Data: TSpDevIntData): BOOL; stdcall; external 'setupapi.dll';
function SetupDiGetDeviceInterfaceDetailW(DevInfo: THandle; var Data: TSpDevIntData; Detail: Pointer;
  Size: DWORD; var Req: DWORD; DevInfoData: Pointer): BOOL; stdcall; external 'setupapi.dll';
function SetupDiDestroyDeviceInfoList(DevInfo: THandle): BOOL; stdcall; external 'setupapi.dll';
{$ENDIF}

{ TK8055Leser }

constructor TK8055Leser.Create(AHandle: THandle);
begin
  FHandle := AHandle;
  FreeOnTerminate := False;
  inherited Create(False);
end;

procedure TK8055Leser.Execute;
var
  Buf: array[0..63] of Byte;
  N, Off, i: Integer;
  {$IFDEF UNIX}
  Pfd: TPollFd;
  {$ENDIF}
begin
  while not Terminated do
  begin
    {$IFDEF UNIX}
    // niet eindeloos blijven wachten: zo kan de draad stoppen
    Pfd.fd := FHandle;
    Pfd.events := POLLIN;
    Pfd.revents := 0;
    if fpPoll(@Pfd, 1, 200) <= 0 then Continue;
    {$ENDIF}
    N := FileRead(FHandle, Buf, 9);
    if N <= 0 then
    begin
      Fout := True;
      Break;
    end;
    // Windows geeft het rapportnummer (0) mee, Linux (hidraw) niet
    if N >= 9 then Off := 1 else Off := 0;
    for i := 0 to 7 do
      if Off + i < N then Data[i] := Buf[Off + i];
    InterLockedIncrement(Teller);
  end;
end;

{ TK8055 }

constructor TK8055.Create(AOwner: TComponent; APaneel: TWinControl);
begin
  inherited Create(AOwner);
  FPaneel := APaneel;
  FHandle := THandle(-1);
  FLaatsteIn := -1;
  FTimer := TTimer.Create(Self);
  FTimer.Interval := 40;
  FTimer.OnTimer := @Tik;
  FTimer.Enabled := True;
end;

destructor TK8055.Destroy;
begin
  FTimer.Enabled := False;
  Sluit;
  inherited Destroy;
end;

function TK8055.OnderdelenOpPaneel: Boolean;
var
  i: Integer;
begin
  Result := False;
  if FPaneel = nil then Exit;
  for i := 0 to FPaneel.ControlCount - 1 do
    if (FPaneel.Controls[i] is TjanK8055In) or (FPaneel.Controls[i] is TjanK8055Uit) or
      (FPaneel.Controls[i] is TjanK8055Ana) then
      Exit(True);
end;

{$IFDEF WINDOWS}
function TK8055.ZoekPad: string;
var
  Info: THandle;
  Data: TSpDevIntData;
  Detail: array of Byte;
  Req: DWORD;
  i: Integer;
  Pad: string;
begin
  Result := '';
  Info := SetupDiGetClassDevsW(@HidGuid, nil, 0, DIGCF_PRESENT or DIGCF_DEVICEINTERFACE);
  if Info = THandle(-1) then Exit;
  try
    i := 0;
    FillChar(Data, SizeOf(Data), 0);
    Data.cbSize := SizeOf(Data);
    while SetupDiEnumDeviceInterfaces(Info, nil, HidGuid, i, Data) do
    begin
      Inc(i);
      Req := 0;
      SetupDiGetDeviceInterfaceDetailW(Info, Data, nil, 0, Req, nil);
      if Req = 0 then Continue;
      SetLength(Detail, Req + 4);
      FillChar(Detail[0], Length(Detail), 0);
      // cbSize van SP_DEVICE_INTERFACE_DETAIL_DATA_W: 8 op 64 bit, 6 op 32 bit
      if SizeOf(Pointer) = 8 then PDWORD(@Detail[0])^ := 8 else PDWORD(@Detail[0])^ := 6;
      if not SetupDiGetDeviceInterfaceDetailW(Info, Data, @Detail[0], Req, Req, nil) then Continue;
      Pad := UTF8Encode(WideString(PWideChar(@Detail[4])));
      if Pos('vid_10cf&pid_550', LowerCase(Pad)) > 0 then
        Exit(Pad);
    end;
  finally
    SetupDiDestroyDeviceInfoList(Info);
  end;
end;
{$ENDIF}

{$IFDEF UNIX}
function TK8055.ZoekPad: string;
var
  SR: TSearchRec;
  L: TStringList;
  i: Integer;
begin
  Result := '';
  if FindFirst('/sys/class/hidraw/hidraw*', faAnyFile, SR) = 0 then
  try
    repeat
      L := TStringList.Create;
      try
        try
          L.LoadFromFile('/sys/class/hidraw/' + SR.Name + '/device/uevent');
        except
          Continue;
        end;
        for i := 0 to L.Count - 1 do
          if Pos('HID_ID=', UpperCase(L[i])) = 1 then
            if Pos(':000010CF:0000550', UpperCase(L[i])) > 0 then
              Exit('/dev/' + SR.Name);
      finally
        L.Free;
      end;
    until FindNext(SR) <> 0;
  finally
    FindClose(SR);
  end;
end;
{$ENDIF}

function TK8055.Open: Boolean;
var
  Pad: string;
begin
  Result := False;
  Pad := ZoekPad;
  if Pad = '' then Exit;
  {$IFDEF WINDOWS}
  FHandle := CreateFileW(PWideChar(UTF8Decode(Pad)), GENERIC_READ or GENERIC_WRITE,
    FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
  {$ENDIF}
  {$IFDEF UNIX}
  FHandle := fpOpen(Pad, O_RDWR);
  {$ENDIF}
  if (FHandle = THandle(-1)) or (FHandle = 0) then
  begin
    FHandle := THandle(-1);
    Exit;
  end;
  FOpen := True;
  FLaatsteIn := -1;
  FLeser := TK8055Leser.Create(FHandle);
  K8055Schrijf := @Schrijf;
  K8055Verbonden := True;
  K8055Bijwerken(FPaneel, True);
  HintsBijwerken(True);
  if Assigned(FOnStatus) then FOnStatus(Self);
  Result := True;
end;

procedure TK8055.Sluit;
var
  T: QWord;
begin
  if FOpen then
  begin
    // alle uitgangen uit
    try
      Schrijf(0);
    except
    end;
  end;
  K8055Verbonden := False;
  K8055Schrijf := nil;
  if Assigned(FLeser) then
  begin
    FLeser.Terminate;
    // de draad leest elke 8 ms een bericht: hij stopt snel
    T := GetTickCount64;
    while not FLeser.Finished and (GetTickCount64 - T < 1000) do Sleep(10);
    if FLeser.Finished then FLeser.Free;
    FLeser := nil;
  end;
  if FHandle <> THandle(-1) then
  begin
    FileClose(FHandle);
    FHandle := THandle(-1);
  end;
  if FOpen then
  begin
    FOpen := False;
    HintsBijwerken(True);
    VoedingBijwerken(FPaneel);
    if Assigned(FOnStatus) then FOnStatus(Self);
  end;
end;

procedure TK8055.Schrijf(AMasker: Byte);
var
  B: array[0..8] of Byte;
begin
  if not FOpen then Exit;
  FillChar(B, SizeOf(B), 0);
  B[0] := 0;          // rapportnummer
  B[1] := 5;          // opdracht: uitgangen en analoge uitgangen zetten
  B[2] := AMasker;
  if FileWrite(FHandle, B, 9) <> 9 then
    if FLeser <> nil then FLeser.Fout := True;
end;

procedure TK8055.IngangenBijwerken(AData: Byte);
var
  i: Integer;
  K: TjanK8055In;
  Aan: Boolean;
begin
  if (FPaneel = nil) or (AData = FLaatsteIn) then Exit;
  FLaatsteIn := AData;
  for i := 0 to FPaneel.ControlCount - 1 do
    if FPaneel.Controls[i] is TjanK8055In then
    begin
      K := TjanK8055In(FPaneel.Controls[i]);
      Aan := K8055Ingang(AData, K.Nr);
      if K.Aan <> Aan then
      begin
        K.Aan := Aan;
        K.Invalidate;
      end;
    end;
end;

// de analoge ingangen A1 en A2: bij een verandering van minstens 2 (ruis) de
// kring opnieuw berekenen en de onderdelen TjanK8055Ana opnieuw tekenen
procedure TK8055.AnaloogBijwerken(A1, A2: Byte);
var
  i: Integer;
begin
  if (Abs(A1 - K8055Analoog[1]) < 2) and (Abs(A2 - K8055Analoog[2]) < 2) then Exit;
  K8055Analoog[1] := A1;
  K8055Analoog[2] := A2;
  if FPaneel = nil then Exit;
  for i := 0 to FPaneel.ControlCount - 1 do
    if FPaneel.Controls[i] is TjanK8055Ana then FPaneel.Controls[i].Invalidate;
  VoedingBijwerken(FPaneel);
end;

procedure TK8055.HintsBijwerken(AInval: Boolean);
var
  i: Integer;
begin
  if FPaneel = nil then Exit;
  for i := 0 to FPaneel.ControlCount - 1 do
    if (FPaneel.Controls[i] is TjanK8055In) or (FPaneel.Controls[i] is TjanK8055Uit) or
      (FPaneel.Controls[i] is TjanK8055Ana) then
    begin
      TjanVoedingsDeel(FPaneel.Controls[i]).UpdateHintText;
      if AInval then FPaneel.Controls[i].Invalidate;
    end;
end;

procedure TK8055.Tik(Sender: TObject);
begin
  Inc(FTel);
  if not FOpen then
  begin
    // om de 2 seconden zoeken, maar alleen als er K8055-onderdelen zijn
    if (FTel mod 50 = 1) and OnderdelenOpPaneel then Open;
    Exit;
  end;
  if FLeser.Fout then
  begin
    Sluit;
    Exit;
  end;
  if FLeser.Teller > 0 then
  begin
    IngangenBijwerken(FLeser.Data[0]);
    AnaloogBijwerken(FLeser.Data[2], FLeser.Data[3]);
  end;
  // nieuwe K8055-onderdelen (bv. net geladen paneel): hints en uitgangen bijwerken
  if FTel mod 25 = 0 then
  begin
    HintsBijwerken(False);
    K8055Bijwerken(FPaneel, False);
  end;
end;

end.
