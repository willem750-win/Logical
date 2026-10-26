unit uUpdate;

{ Zoeken naar een nieuwe versie van Logic.

  Logic leest een klein tekstbestand (latest.txt in de GitHub-repo):
      version=1.7.0
      url=https://github.com/willem750-win/Logical/releases/latest
  Er wordt niets doorgestuurd; het is een gewone download van dat bestand.

  - automatisch: bij het starten, op de achtergrond, hoogstens 1 keer per dag;
    lukt het niet (geen internet, geblokkeerd), dan wordt er niets gemeld.
    Is er een nieuwere versie, dan verschijnt een gele balk bovenaan.
  - met de hand: knop in het venster "Over Logic"; dan krijg je altijd antwoord.

  Instellingen in taal.ini, sectie [Update]: Auto, LaatsteKeer, Overslaan.
  Windows gebruikt WinINet (proxy-instellingen van het systeem, geen extra
  DLL's), Linux de HTTP-client van FPC met OpenSSL. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, StdCtrls, ExtCtrls, Dialogs,
  IniFiles, LCLIntf, chatgridpcodeSmall;

const
  UpdateDefaultDownloadUrl = 'https://github.com/willem750-win/Logical/releases/latest';

var
  // waar latest.txt staat (een var, zodat een test hem kan omleiden)
  UpdateInfoUrl: string = 'https://raw.githubusercontent.com/willem750-win/Logical/main/latest.txt';

// Bij het starten: zoekt op de achtergrond (als Auto aan staat en er vandaag
// nog niet gezocht is) en toont zo nodig de balk boven ABelow in AHost.
procedure StartAutoUpdateCheck(AHost: TWinControl; ABelow: TControl; ALang: TLanguage);
// Knop "Zoeken naar updates": zoekt meteen en meldt altijd het resultaat.
procedure ManualUpdateCheck(ALang: TLanguage);
// De gele balk 'er is een nieuwe versie' tonen.
procedure ShowUpdateBar(AHost: TWinControl; ABelow: TControl; ALang: TLanguage;
  const AVersion, AUrl: string);

function GetAutoUpdate: Boolean;
procedure SetAutoUpdate(AValue: Boolean);

// hulpfuncties (ook voor de test)
function CompareVersions(const A, B: string): Integer;
function ParseUpdateInfo(const AText: string; out AVersion, AUrl: string): Boolean;
function HttpGetText(const AUrl: string; out AText: string): Boolean;

implementation

uses
  {$IFDEF WINDOWS} Windows, WinINet, {$ELSE} fphttpclient, opensslsockets, openssl, {$ENDIF}
  uAbout;

const
  SectieUpdate = 'Update';
  TimeoutMs = 6000;

function Tr(ALang: TLanguage; const NL, EN, FR, DE: string): string;
begin
  case ALang of
    lgEnglish: Result := EN;
    lgFrench:  Result := FR;
    lgGerman:  Result := DE;
  else
    Result := NL;
  end;
end;

function IniPad: string;
begin
  Result := ExtractFilePath(ParamStr(0)) + 'taal.ini';
end;

function LeesIni(const AKey, ADefault: string): string;
var Ini: TIniFile;
begin
  Result := ADefault;
  try
    Ini := TIniFile.Create(IniPad);
    try
      Result := Ini.ReadString(SectieUpdate, AKey, ADefault);
    finally
      Ini.Free;
    end;
  except
    // geen schrijf- of leesrechten: standaardwaarde
  end;
end;

procedure SchrijfIni(const AKey, AValue: string);
var Ini: TIniFile;
begin
  try
    Ini := TIniFile.Create(IniPad);
    try
      Ini.WriteString(SectieUpdate, AKey, AValue);
    finally
      Ini.Free;
    end;
  except
  end;
end;

function GetAutoUpdate: Boolean;
begin
  Result := LeesIni('Auto', '1') <> '0';
end;

procedure SetAutoUpdate(AValue: Boolean);
begin
  if AValue then SchrijfIni('Auto', '1') else SchrijfIni('Auto', '0');
end;

// -1 als A ouder is dan B, 0 gelijk, 1 nieuwer ('1.10.0' > '1.9.2')
function CompareVersions(const A, B: string): Integer;
var
  PA, PB: TStringArray;
  i, NA, NB: Integer;
begin
  PA := Trim(A).Split(['.']);
  PB := Trim(B).Split(['.']);
  for i := 0 to 3 do
  begin
    if i < Length(PA) then NA := StrToIntDef(PA[i], 0) else NA := 0;
    if i < Length(PB) then NB := StrToIntDef(PB[i], 0) else NB := 0;
    if NA < NB then Exit(-1);
    if NA > NB then Exit(1);
  end;
  Result := 0;
end;

function ParseUpdateInfo(const AText: string; out AVersion, AUrl: string): Boolean;
var
  SL: TStringList;
  i, p: Integer;
  K, V: string;
begin
  AVersion := '';
  AUrl := UpdateDefaultDownloadUrl;
  SL := TStringList.Create;
  try
    SL.Text := AText;
    for i := 0 to SL.Count - 1 do
    begin
      p := Pos('=', SL[i]);
      if p = 0 then Continue;
      K := LowerCase(Trim(Copy(SL[i], 1, p - 1)));
      V := Trim(Copy(SL[i], p + 1, MaxInt));
      if K = 'version' then AVersion := V
      else if (K = 'url') and ((Pos('https://', V) = 1) or (Pos('http://', V) = 1)) then AUrl := V;
    end;
  finally
    SL.Free;
  end;
  // alleen cijfers en punten: zo weten we zeker dat het een versienummer is
  Result := (AVersion <> '') and (Length(AVersion) <= 20);
  for i := 1 to Length(AVersion) do
    if not (AVersion[i] in ['0'..'9', '.']) then Result := False;
end;

{$IFDEF WINDOWS}
function HttpGetText(const AUrl: string; out AText: string): Boolean;
var
  hNet, hUrl: HINTERNET;
  Buf: array[0..1023] of Char;
  N, Status, Len, Idx, T: DWORD;
  Part: string;
begin
  Result := False;
  AText := '';
  hNet := InternetOpen('Logic', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if hNet = nil then Exit;
  try
    T := TimeoutMs;
    InternetSetOption(hNet, INTERNET_OPTION_CONNECT_TIMEOUT, @T, SizeOf(T));
    InternetSetOption(hNet, INTERNET_OPTION_RECEIVE_TIMEOUT, @T, SizeOf(T));
    InternetSetOption(hNet, INTERNET_OPTION_SEND_TIMEOUT, @T, SizeOf(T));
    hUrl := InternetOpenUrl(hNet, PChar(AUrl), nil, 0,
      INTERNET_FLAG_RELOAD or INTERNET_FLAG_NO_CACHE_WRITE or INTERNET_FLAG_NO_UI, 0);
    if hUrl = nil then Exit;
    try
      Status := 0; Len := SizeOf(Status); Idx := 0;
      if not HttpQueryInfo(hUrl, HTTP_QUERY_STATUS_CODE or HTTP_QUERY_FLAG_NUMBER,
        @Status, Len, Idx) or (Status <> 200) then Exit;
      repeat
        N := 0;
        if not InternetReadFile(hUrl, @Buf, SizeOf(Buf), N) then Exit;
        if N > 0 then
        begin
          SetString(Part, PChar(@Buf[0]), N);
          AText := AText + Part;
        end;
      until (N = 0) or (Length(AText) > 4096);
      Result := True;
    finally
      InternetCloseHandle(hUrl);
    end;
  finally
    InternetCloseHandle(hNet);
  end;
end;
{$ELSE}
function HttpGetText(const AUrl: string; out AText: string): Boolean;
var C: TFPHTTPClient;
begin
  Result := False;
  AText := '';
  C := TFPHTTPClient.Create(nil);
  try
    try
      C.ConnectTimeout := TimeoutMs;
      C.IOTimeout := TimeoutMs;
      C.AllowRedirect := True;
      C.AddHeader('User-Agent', 'Logic');
      AText := C.Get(AUrl);
      Result := C.ResponseStatusCode = 200;
    except
      Result := False;
    end;
  finally
    C.Free;
  end;
end;
{$ENDIF}

{ ---------- de gele balk ---------- }

type
  TUpdateBar = class(TPanel)
  private
    FVersion, FUrl: string;
    procedure DownloadClick(Sender: TObject);
    procedure LaterClick(Sender: TObject);
    procedure OverslaanClick(Sender: TObject);
  public
    constructor CreateBar(AHost: TWinControl; ABelow: TControl; ALang: TLanguage;
      const AVersion, AUrl: string);
  end;

var
  Bar: TUpdateBar = nil;

constructor TUpdateBar.CreateBar(AHost: TWinControl; ABelow: TControl;
  ALang: TLanguage; const AVersion, AUrl: string);

  function Knop(const ACaption: string; AClick: TNotifyEvent): TButton;
  begin
    Result := TButton.Create(Self);
    Result.Parent := Self;
    Result.Caption := ACaption;
    Result.AutoSize := True;
    Result.Align := alRight;
    Result.Left := 0;   // elke nieuwe knop links van de vorige
    Result.BorderSpacing.Around := 4;
    Result.OnClick := AClick;
  end;

var L: TLabel;
begin
  inherited Create(AHost);
  FVersion := AVersion;
  FUrl := AUrl;
  BevelOuter := bvNone;
  ParentBackground := False;
  Color := $00B9F5FF;   // zacht geel
  Height := 34;
  Align := alTop;
  if ABelow <> nil then Top := ABelow.Top + ABelow.Height else Top := 0;
  Parent := AHost;

  L := TLabel.Create(Self);
  L.Parent := Self;
  L.Align := alClient;
  L.Layout := tlCenter;
  L.BorderSpacing.Left := 10;
  L.Font.Color := clBlack;
  L.Caption := Format(Tr(ALang,
    'Er is een nieuwe versie van Logic: %s (je hebt %s).',
    'A new version of Logic is available: %s (you have %s).',
    'Une nouvelle version de Logic est disponible : %s (vous avez %s).',
    'Eine neue Version von Logic ist verfügbar: %s (Sie haben %s).'), [AVersion, AppVersion]);

  Knop(Tr(ALang, 'Deze versie overslaan', 'Skip this version', 'Ignorer cette version', 'Diese Version überspringen'), @OverslaanClick);
  Knop(Tr(ALang, 'Later', 'Later', 'Plus tard', 'Später'), @LaterClick);
  Knop(Tr(ALang, 'Downloaden', 'Download', 'Télécharger', 'Herunterladen'), @DownloadClick);
end;

procedure TUpdateBar.DownloadClick(Sender: TObject);
begin
  OpenURL(FUrl);
  Hide;
end;

procedure TUpdateBar.LaterClick(Sender: TObject);
begin
  Hide;   // morgen opnieuw
end;

procedure TUpdateBar.OverslaanClick(Sender: TObject);
begin
  SchrijfIni('Overslaan', FVersion);
  Hide;
end;

procedure ShowUpdateBar(AHost: TWinControl; ABelow: TControl; ALang: TLanguage;
  const AVersion, AUrl: string);
begin
  if Bar = nil then
    Bar := TUpdateBar.CreateBar(AHost, ABelow, ALang, AVersion, AUrl);
end;

{ ---------- automatisch zoeken op de achtergrond ---------- }

type
  TUpdateThread = class(TThread)
  private
    FHost: TWinControl;
    FBelow: TControl;
    FLang: TLanguage;
    FOk: Boolean;
    FText: string;
    procedure Klaar;
  protected
    procedure Execute; override;
  end;

procedure TUpdateThread.Execute;
begin
  FOk := HttpGetText(UpdateInfoUrl, FText);
  if not Terminated then Synchronize(@Klaar);
end;

procedure TUpdateThread.Klaar;
var V, U: string;
begin
  if Application.Terminated then Exit;
  if not FOk or not ParseUpdateInfo(FText, V, U) then Exit;   // stil
  SchrijfIni('LaatsteKeer', FormatDateTime('yyyy-mm-dd', Date));
  if CompareVersions(V, AppVersion) <= 0 then Exit;
  if V = LeesIni('Overslaan', '') then Exit;
  ShowUpdateBar(FHost, FBelow, FLang, V, U);
end;

procedure StartAutoUpdateCheck(AHost: TWinControl; ABelow: TControl; ALang: TLanguage);
var T: TUpdateThread;
begin
  if not GetAutoUpdate then Exit;
  if LeesIni('LaatsteKeer', '') = FormatDateTime('yyyy-mm-dd', Date) then Exit;
  T := TUpdateThread.Create(True);
  T.FHost := AHost;
  T.FBelow := ABelow;
  T.FLang := ALang;
  T.FreeOnTerminate := True;
  T.Start;
end;

{ ---------- met de hand ---------- }

procedure ManualUpdateCheck(ALang: TLanguage);
var
  S, V, U: string;
  Ok: Boolean;
begin
  Screen.Cursor := crHourGlass;
  try
    Ok := HttpGetText(UpdateInfoUrl, S) and ParseUpdateInfo(S, V, U);
  finally
    Screen.Cursor := crDefault;
  end;
  if not Ok then
    MessageDlg(Tr(ALang,
      'Logic kon niet nagaan of er een nieuwe versie is. Misschien is er geen internet, of wordt de website geblokkeerd.',
      'Logic could not check for a new version. Maybe there is no internet connection, or the website is blocked.',
      'Logic n''a pas pu vérifier s''il existe une nouvelle version. Il n''y a peut-être pas d''internet, ou le site est bloqué.',
      'Logic konnte nicht prüfen, ob es eine neue Version gibt. Vielleicht gibt es kein Internet, oder die Website ist gesperrt.'),
      mtWarning, [mbOK], 0)
  else
  begin
    SchrijfIni('LaatsteKeer', FormatDateTime('yyyy-mm-dd', Date));
    if CompareVersions(V, AppVersion) > 0 then
    begin
      if MessageDlg(Format(Tr(ALang,
        'Er is een nieuwe versie van Logic: %s (je hebt %s).'#13#13'Wil je de downloadpagina openen?',
        'A new version of Logic is available: %s (you have %s).'#13#13'Do you want to open the download page?',
        'Une nouvelle version de Logic est disponible : %s (vous avez %s).'#13#13'Voulez-vous ouvrir la page de téléchargement ?',
        'Eine neue Version von Logic ist verfügbar: %s (Sie haben %s).'#13#13'Möchten Sie die Download-Seite öffnen?'),
        [V, AppVersion]), mtInformation, [mbYes, mbNo], 0) = mrYes then
        OpenURL(U);
    end
    else
      MessageDlg(Format(Tr(ALang,
        'Je hebt de nieuwste versie van Logic (%s).',
        'You have the latest version of Logic (%s).',
        'Vous avez la dernière version de Logic (%s).',
        'Sie haben die neueste Version von Logic (%s).'), [AppVersion]),
        mtInformation, [mbOK], 0);
  end;
end;


{$IFNDEF WINDOWS}
procedure OpenSSL3Erbij;
var i: Integer;
begin
  // FPC 3.2.2 zoekt geen libssl.so.3 (OpenSSL 3, o.a. Debian 12): voeg die
  // versie toe op de plaats van de oudste (0.9.1)
  for i := Low(DLLVersions) to High(DLLVersions) do
    if DLLVersions[i] = '.3' then Exit;
  DLLVersions[High(DLLVersions)] := '.3';
end;

initialization
  OpenSSL3Erbij;
{$ENDIF}

end.
