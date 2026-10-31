unit uHelpBrowserLinux;

// Ingebouwde helpbrowser onder Linux (GTK2), met CEF4Delphi.
// De CEF-runtime staat in de submap ceflib naast logicCEF (libcef.so,
// *.pak, icudtl.dat, locales/ ...). Ontbreekt die map, dan opent de help
// zoals vroeger in de systeembrowser (zie TmainForm.OpenHelpInMiniBrowser).
// Naar het voorbeeld Lazarus_Linux/SimpleBrowser2 van CEF4Delphi.

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SyncObjs, Forms, Controls, Graphics, ExtCtrls, StdCtrls,
  Buttons, LMessages, LCLIntf, URIParser,
  uCEFChromium, uCEFTypes, uCEFInterfaces, uCEFConstants,
  uCEFLinkedWindowParent;

type
  TOpenPanelEvent = procedure(const AFileName: string) of object;

  { THelpBrowserForm }

  THelpBrowserForm = class(TForm)
  private
    FBalk: TPanel;
    FTerug, FVooruit, FInhoud, FHerlaad: TSpeedButton;
    FTitel: TLabel;
    FStatus: TPanel;
    FBrowserParent: TCEFLinkedWindowParent;
    FChromium: TChromium;
    FStartTimer: TTimer;
    FCS: TCriticalSection;
    // door CEF-threads gezet, in de hoofdthread gelezen (onder FCS)
    FNieuweTitel: string;
    FKanTerug, FKanVooruit: Boolean;
    FPanelToOpen, FExternalURL: string;
    FInhoudURL: string;
    FAfsluiten: Boolean;   // Logic stopt: venster echt sluiten
    FGesloten: Boolean;    // OnBeforeClose ontvangen
    procedure MaakBrowser;
    procedure StartTimerTimer(Sender: TObject);
    procedure TerugClick(Sender: TObject);
    procedure VooruitClick(Sender: TObject);
    procedure InhoudClick(Sender: TObject);
    procedure HerlaadClick(Sender: TObject);
    procedure FormShowEvt(Sender: TObject);
    procedure FormCloseQueryEvt(Sender: TObject; var CanClose: Boolean);
    procedure ParentEnter(Sender: TObject);
    procedure ParentExit(Sender: TObject);
    // CEF-gebeurtenissen (andere thread)
    procedure ChromiumAfterCreated(Sender: TObject; const browser: ICefBrowser);
    procedure ChromiumClose(Sender: TObject; const browser: ICefBrowser;
      var aAction: TCefCloseBrowserAction);
    procedure ChromiumBeforeClose(Sender: TObject; const browser: ICefBrowser);
    procedure ChromiumGotFocus(Sender: TObject; const browser: ICefBrowser);
    procedure ChromiumTitleChange(Sender: TObject; const browser: ICefBrowser;
      const title: ustring);
    procedure ChromiumLoadingStateChange(Sender: TObject; const browser: ICefBrowser;
      isLoading, canGoBack, canGoForward: Boolean);
    procedure ChromiumBeforeBrowse(Sender: TObject; const browser: ICefBrowser;
      const frame: ICefFrame; const request: ICefRequest;
      user_gesture, isRedirect: Boolean; out Result: Boolean);
    procedure ChromiumBeforePopup(Sender: TObject; const browser: ICefBrowser;
      const frame: ICefFrame; const targetUrl, targetFrameName: ustring;
      targetDisposition: TCefWindowOpenDisposition; userGesture: Boolean;
      const popupFeatures: TCefPopupFeatures; var windowInfo: TCefWindowInfo;
      var client: ICefClient; var settings: TCefBrowserSettings;
      var extra_info: ICefDictionaryValue; var noJavascriptAccess: Boolean;
      var Result: Boolean);
    procedure ChromiumOpenUrlFromTab(Sender: TObject; const browser: ICefBrowser;
      const frame: ICefFrame; const targetUrl: ustring;
      targetDisposition: TCefWindowOpenDisposition; userGesture: Boolean;
      out Result: Boolean);
    // in de hoofdthread uitgevoerd (QueueAsyncCall)
    procedure KopBijwerken(Data: PtrInt);
    procedure FocusBrowser(Data: PtrInt);
    procedure OpenPanel(Data: PtrInt);
    procedure OpenExtern(Data: PtrInt);
    procedure Geblokkeerd(Data: PtrInt);
  protected
    procedure WMMove(var Message: TLMMove); message LM_MOVE;
    procedure WMSize(var Message: TLMSize); message LM_SIZE;
    procedure WMWindowPosChanged(var Message: TLMWindowPosChanged); message LM_WINDOWPOSCHANGED;
  public
    constructor CreateHelp(AOwner: TComponent);
    destructor Destroy; override;
    procedure ToonURL(const AURL, ABTaal: string);
    procedure SluitBrowser;
  end;

var
  OnHelpOpenPanel: TOpenPanelEvent = nil;

// Is de ingebouwde browser beschikbaar (ceflib gevonden en CEF gestart)?
function HelpBrowserAvailable: Boolean;
procedure ShowHelpBrowser(const AURL, ABTaal: string; AParent: TForm);
procedure HideHelpBrowser;
// Bij het afsluiten van Logic: de browser netjes sluiten.
procedure CloseHelpBrowser;

implementation

uses
  uCefGtk2Widgetset, uHelpManager;

var
  HelpForm: THelpBrowserForm = nil;

function IsWebURL(const aURL: string): Boolean;
var
  U: string;
begin
  U := LowerCase(Trim(aURL));
  Result := (Pos('http://', U) = 1) or (Pos('https://', U) = 1);
end;

// Alleen lokale pagina's in het helpvenster (zoals onder Windows)
function IsAllowedURL(const aURL: string): Boolean;
var
  U: string;
begin
  U := LowerCase(Trim(aURL));
  Result := (U = '') or
            (Pos('file:', U) = 1) or
            (Pos('about:', U) = 1) or
            (Pos('data:', U) = 1) or
            (Pos('blob:', U) = 1) or
            (Pos('chrome-error:', U) = 1);
end;

// CEF start in uCefGtk2Widgetset, vóór GTK
function HelpBrowserAvailable: Boolean;
begin
  Result := uCefGtk2Widgetset.HelpBrowserAvailable;
end;

procedure ShowHelpBrowser(const AURL, ABTaal: string; AParent: TForm);
begin
  if HelpForm = nil then
  begin
    HelpForm := THelpBrowserForm.CreateHelp(Application);
    // help blijft vóór het hoofdvenster (niet boven andere programma's)
    HelpForm.PopupMode := pmExplicit;
    HelpForm.PopupParent := AParent;
  end;
  HelpForm.ToonURL(AURL, ABTaal);
end;

procedure HideHelpBrowser;
begin
  if HelpForm <> nil then
    HelpForm.Hide;
end;

procedure CloseHelpBrowser;
begin
  if HelpForm <> nil then
    HelpForm.SluitBrowser;
end;

{ THelpBrowserForm }

constructor THelpBrowserForm.CreateHelp(AOwner: TComponent);

  function Knop(const ACaption: string; AEvent: TNotifyEvent): TSpeedButton;
  begin
    Result := TSpeedButton.Create(Self);
    Result.Parent := FBalk;
    Result.Align := alLeft;
    Result.Width := 34;
    Result.Caption := ACaption;
    Result.Flat := True;
    Result.Font.Size := 12;
    Result.ShowHint := True;
    Result.OnClick := AEvent;
  end;

begin
  inherited CreateNew(AOwner);
  FCS := TCriticalSection.Create;
  Caption := 'Logic - Help';
  Width := 1000;
  Height := 720;
  Position := poMainFormCenter;
  OnShow := @FormShowEvt;
  OnCloseQuery := @FormCloseQueryEvt;

  FBalk := TPanel.Create(Self);
  FBalk.Parent := Self;
  FBalk.Align := alTop;
  FBalk.Height := 30;
  FBalk.BevelOuter := bvNone;
  // alLeft legt de knoppen in de volgorde van Left neer
  FTerug := Knop(#$E2#$97#$80, @TerugClick);        // ◀
  FVooruit := Knop(#$E2#$96#$B6, @VooruitClick);    // ▶
  FVooruit.Left := FTerug.Left + FTerug.Width;
  FInhoud := Knop(#$E2#$8C#$82, @InhoudClick);      // ⌂
  FInhoud.Left := FVooruit.Left + FVooruit.Width;
  FHerlaad := Knop(#$E2#$9F#$B3, @HerlaadClick);    // ⟳
  FHerlaad.Left := FInhoud.Left + FInhoud.Width;
  FTerug.Enabled := False;
  FVooruit.Enabled := False;

  FTitel := TLabel.Create(Self);
  FTitel.Parent := FBalk;
  FTitel.Align := alClient;
  FTitel.Layout := tlCenter;
  FTitel.BorderSpacing.Left := 10;
  FTitel.Font.Style := [fsBold];
  FTitel.ShowAccelChar := False;

  FStatus := TPanel.Create(Self);
  FStatus.Parent := Self;
  FStatus.Align := alBottom;
  FStatus.Height := 22;
  FStatus.BevelOuter := bvNone;
  FStatus.Alignment := taLeftJustify;
  FStatus.Visible := False;

  FChromium := TChromium.Create(Self);
  FChromium.OnAfterCreated := @ChromiumAfterCreated;
  FChromium.OnClose := @ChromiumClose;
  FChromium.OnBeforeClose := @ChromiumBeforeClose;
  FChromium.OnGotFocus := @ChromiumGotFocus;
  FChromium.OnTitleChange := @ChromiumTitleChange;
  FChromium.OnLoadingStateChange := @ChromiumLoadingStateChange;
  FChromium.OnBeforeBrowse := @ChromiumBeforeBrowse;
  FChromium.OnBeforePopup := @ChromiumBeforePopup;
  FChromium.OnOpenUrlFromTab := @ChromiumOpenUrlFromTab;

  FBrowserParent := TCEFLinkedWindowParent.Create(Self);
  FBrowserParent.Parent := Self;
  FBrowserParent.Align := alClient;
  FBrowserParent.TabStop := True;
  FBrowserParent.Chromium := FChromium;
  FBrowserParent.OnEnter := @ParentEnter;
  FBrowserParent.OnExit := @ParentExit;

  FStartTimer := TTimer.Create(Self);
  FStartTimer.Enabled := False;
  FStartTimer.Interval := 250;
  FStartTimer.OnTimer := @StartTimerTimer;
end;

destructor THelpBrowserForm.Destroy;
begin
  Application.RemoveAsyncCalls(Self);
  if HelpForm = Self then HelpForm := nil;
  FCS.Free;
  inherited Destroy;
end;

procedure THelpBrowserForm.ToonURL(const AURL, ABTaal: string);
var
  P: Integer;
begin
  FTerug.Hint := TrHelp(ABTaal, 'Terug', 'Back', 'Retour', 'Zurück');
  FVooruit.Hint := TrHelp(ABTaal, 'Vooruit', 'Forward', 'Avancer', 'Vorwärts');
  FInhoud.Hint := TrHelp(ABTaal, 'Inhoud', 'Contents', 'Sommaire', 'Inhalt');
  FHerlaad.Hint := TrHelp(ABTaal, 'Opnieuw laden', 'Reload', 'Recharger', 'Neu laden');
  FStatus.Caption := '  ' + TrHelp(ABTaal,
    'Internet is uitgeschakeld in de help', 'Internet is disabled in the help',
    'Internet est désactivé dans l''aide', 'Internet ist in der Hilfe deaktiviert');

  // inhoud: index.html in dezelfde taalmap als de gevraagde pagina
  FInhoudURL := AURL;
  P := Pos('#', FInhoudURL);
  if P > 0 then SetLength(FInhoudURL, P - 1);
  FInhoudURL := Copy(FInhoudURL, 1, LastDelimiter('/', FInhoudURL)) + 'index.html';

  if FChromium.Initialized then
    FChromium.LoadURL(UTF8Decode(AURL))
  else
    FChromium.DefaultURL := UTF8Decode(AURL);
  Show;
  BringToFront;
end;

procedure THelpBrowserForm.MaakBrowser;
begin
  if not FChromium.Initialized and
     not FChromium.CreateBrowser(FBrowserParent.Handle, FBrowserParent.BoundsRect) then
    FStartTimer.Enabled := True;
end;

procedure THelpBrowserForm.StartTimerTimer(Sender: TObject);
begin
  FStartTimer.Enabled := False;
  MaakBrowser;
end;

procedure THelpBrowserForm.FormShowEvt(Sender: TObject);
begin
  // pas aanmaken als GTK het venster getoond heeft (zoals OnActivate in
  // het voorbeeld); anders komt de browser in een onzichtbaar venster
  FStartTimer.Enabled := True;
end;

procedure THelpBrowserForm.FormCloseQueryEvt(Sender: TObject; var CanClose: Boolean);
begin
  // Sluiten verbergt het venster; de browser blijft klaar voor de volgende vraag.
  CanClose := FAfsluiten;
  if not FAfsluiten then Hide;
end;

procedure THelpBrowserForm.SluitBrowser;
var
  Tot: QWord;
begin
  FAfsluiten := True;
  Hide;
  if FChromium.Initialized then
  begin
    FChromium.CloseBrowser(True);
    // wachten op OnBeforeClose, anders blijft CEF bij het afsluiten hangen
    Tot := GetTickCount64 + 3000;
    while not FGesloten and (GetTickCount64 < Tot) do
    begin
      Application.ProcessMessages;
      Sleep(10);
    end;
  end;
end;

procedure THelpBrowserForm.TerugClick(Sender: TObject);
begin
  FChromium.GoBack;
end;

procedure THelpBrowserForm.VooruitClick(Sender: TObject);
begin
  FChromium.GoForward;
end;

procedure THelpBrowserForm.InhoudClick(Sender: TObject);
begin
  if FInhoudURL <> '' then
    FChromium.LoadURL(UTF8Decode(FInhoudURL));
end;

procedure THelpBrowserForm.HerlaadClick(Sender: TObject);
begin
  FChromium.Reload;
end;

procedure THelpBrowserForm.ParentEnter(Sender: TObject);
begin
  if FChromium.Initialized and not FChromium.FrameIsFocused then
    FChromium.SendFocusEvent(True);
end;

procedure THelpBrowserForm.ParentExit(Sender: TObject);
begin
  FChromium.SendCaptureLostEvent;
end;

procedure THelpBrowserForm.WMMove(var Message: TLMMove);
begin
  inherited;
  if FChromium <> nil then FChromium.NotifyMoveOrResizeStarted;
end;

procedure THelpBrowserForm.WMSize(var Message: TLMSize);
begin
  inherited;
  if FChromium <> nil then FChromium.NotifyMoveOrResizeStarted;
end;

procedure THelpBrowserForm.WMWindowPosChanged(var Message: TLMWindowPosChanged);
begin
  inherited;
  if FChromium <> nil then FChromium.NotifyMoveOrResizeStarted;
end;

{ CEF-gebeurtenissen }

procedure THelpBrowserForm.ChromiumAfterCreated(Sender: TObject; const browser: ICefBrowser);
begin
  Application.QueueAsyncCall(@KopBijwerken, 0);
end;

procedure THelpBrowserForm.ChromiumClose(Sender: TObject; const browser: ICefBrowser;
  var aAction: TCefCloseBrowserAction);
begin
  aAction := cbaClose;
end;

procedure THelpBrowserForm.ChromiumBeforeClose(Sender: TObject; const browser: ICefBrowser);
begin
  FGesloten := True;
end;

procedure THelpBrowserForm.ChromiumGotFocus(Sender: TObject; const browser: ICefBrowser);
begin
  Application.QueueAsyncCall(@FocusBrowser, 0);
end;

procedure THelpBrowserForm.ChromiumTitleChange(Sender: TObject; const browser: ICefBrowser;
  const title: ustring);
begin
  FCS.Acquire;
  FNieuweTitel := UTF8Encode(title);
  FCS.Release;
  Application.QueueAsyncCall(@KopBijwerken, 0);
end;

procedure THelpBrowserForm.ChromiumLoadingStateChange(Sender: TObject; const browser: ICefBrowser;
  isLoading, canGoBack, canGoForward: Boolean);
begin
  FCS.Acquire;
  FKanTerug := canGoBack;
  FKanVooruit := canGoForward;
  FCS.Release;
  Application.QueueAsyncCall(@KopBijwerken, 0);
end;

procedure THelpBrowserForm.ChromiumBeforeBrowse(Sender: TObject; const browser: ICefBrowser;
  const frame: ICefFrame; const request: ICefRequest;
  user_gesture, isRedirect: Boolean; out Result: Boolean);
var
  U, FN: string;
begin
  Result := False;
  if request = nil then Exit;
  U := UTF8Encode(request.Url);

  // Link naar een paneelbestand (.lpl), bv. een voorbeeld uit het leerpad:
  // niet tonen, maar het paneel in Logic openen.
  if (Pos('file:', LowerCase(U)) = 1) and SameText(ExtractFileExt(U), '.lpl') and
     URIToFilename(U, FN) then
  begin
    FCS.Acquire;
    FPanelToOpen := FN;
    FCS.Release;
    Application.QueueAsyncCall(@OpenPanel, 0);
    Result := True;
    Exit;
  end;

  // Zelf aangeklikte internetlink: in de gewone browser openen
  if user_gesture and IsWebURL(U) then
  begin
    FCS.Acquire;
    FExternalURL := U;
    FCS.Release;
    Application.QueueAsyncCall(@OpenExtern, 0);
    Result := True;
    Exit;
  end;

  // Result = True: navigatie annuleren
  Result := not IsAllowedURL(U);
  if Result then
    Application.QueueAsyncCall(@Geblokkeerd, 0);
end;

procedure THelpBrowserForm.ChromiumBeforePopup(Sender: TObject; const browser: ICefBrowser;
  const frame: ICefFrame; const targetUrl, targetFrameName: ustring;
  targetDisposition: TCefWindowOpenDisposition; userGesture: Boolean;
  const popupFeatures: TCefPopupFeatures; var windowInfo: TCefWindowInfo;
  var client: ICefClient; var settings: TCefBrowserSettings;
  var extra_info: ICefDictionaryValue; var noJavascriptAccess: Boolean;
  var Result: Boolean);
begin
  // geen nieuwe vensters; internetlinks gaan naar de gewone browser
  Result := True;
  if userGesture and IsWebURL(UTF8Encode(targetUrl)) then
  begin
    FCS.Acquire;
    FExternalURL := UTF8Encode(targetUrl);
    FCS.Release;
    Application.QueueAsyncCall(@OpenExtern, 0);
  end;
end;

procedure THelpBrowserForm.ChromiumOpenUrlFromTab(Sender: TObject; const browser: ICefBrowser;
  const frame: ICefFrame; const targetUrl: ustring;
  targetDisposition: TCefWindowOpenDisposition; userGesture: Boolean;
  out Result: Boolean);
begin
  Result := True;
end;

{ hoofdthread }

procedure THelpBrowserForm.KopBijwerken(Data: PtrInt);
var
  T: string;
begin
  FCS.Acquire;
  T := FNieuweTitel;
  FTerug.Enabled := FKanTerug;
  FVooruit.Enabled := FKanVooruit;
  FCS.Release;
  if T <> '' then
  begin
    FTitel.Caption := T;
    Caption := T;
  end;
  FStatus.Visible := False;
end;

procedure THelpBrowserForm.FocusBrowser(Data: PtrInt);
begin
  if FBrowserParent.CanFocus then
    FBrowserParent.SetFocus;
end;

procedure THelpBrowserForm.OpenPanel(Data: PtrInt);
var
  FN: string;
begin
  FCS.Acquire;
  FN := FPanelToOpen;
  FPanelToOpen := '';
  FCS.Release;
  if (FN <> '') and Assigned(OnHelpOpenPanel) then
    OnHelpOpenPanel(FN);
end;

procedure THelpBrowserForm.OpenExtern(Data: PtrInt);
var
  U: string;
begin
  FCS.Acquire;
  U := FExternalURL;
  FExternalURL := '';
  FCS.Release;
  if U <> '' then
    OpenURL(U);
end;

procedure THelpBrowserForm.Geblokkeerd(Data: PtrInt);
begin
  FStatus.Visible := True;
end;

end.
