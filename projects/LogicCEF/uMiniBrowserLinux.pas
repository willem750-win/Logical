unit uMiniBrowserLinux;

// MiniBrowser voor de help onder Linux (GTK2), naar het voorbeeld
// demos/Lazarus_Linux_GTK2/MiniBrowser van CEF4Delphi. Werkt zoals
// uMiniBrowser onder Windows: alleen lokale pagina's, internetlinks openen
// in de gewone browser en een link naar een .lpl-paneel opent dat in Logic.
// CEF zelf start in uCefGtk2Widgetset (vóór de widgetset).

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Menus, ComCtrls, SyncObjs, LMessages,
  uCEFChromium, uCEFInterfaces, uCEFTypes, uCEFConstants, uCEFChromiumEvents,
  uCEFLinkedWindowParent;

const
  // alleen lokale pagina's (de help), geen internet
  MINIBROWSER_LOCALONLY = True;

type
  TOpenPanelEvent = procedure(const AFileName: string) of object;

  { TMiniBrowserFrm }
  TMiniBrowserFrm = class(TForm)
    CEFLinkedWindowParent1: TCEFLinkedWindowParent;
    Chromium1: TChromium;
    NavControlPnl: TPanel;
    NavButtonPnl: TPanel;
    URLEditPnl: TPanel;
    ConfigPnl: TPanel;
    BackBtn: TButton;
    ForwardBtn: TButton;
    ReloadBtn: TButton;
    StopBtn: TButton;
    ConfigBtn: TButton;
    URLCbx: TComboBox;
    StatusBar1: TStatusBar;
    PopupMenu1: TPopupMenu;
    PrintinPDF1: TMenuItem;
    N3: TMenuItem;
    Zoom1: TMenuItem;
    Inczoom1: TMenuItem;
    Deczoom1: TMenuItem;
    Resetzoom1: TMenuItem;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    SaveDialog1: TSaveDialog;
    Timer1: TTimer;

    procedure Chromium1AfterCreated(Sender: TObject; const browser: ICefBrowser);
    procedure Chromium1ChromeCommand(Sender: TObject; const browser: ICefBrowser; command_id: integer; disposition: TCefWindowOpenDisposition; var aResult: boolean);
    procedure Chromium1Close(Sender: TObject; const browser: ICefBrowser; var aAction : TCefCloseBrowserAction);
    procedure Chromium1BeforeClose(Sender: TObject; const browser: ICefBrowser);
    procedure Chromium1BeforeBrowse(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; const request: ICefRequest; user_gesture, isRedirect: Boolean; out Result: Boolean);
    procedure Chromium1BeforePopup(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; popup_id: Integer; const targetUrl, targetFrameName: ustring; targetDisposition: TCefWindowOpenDisposition; userGesture: Boolean; const popupFeatures: TCefPopupFeatures; var windowInfo: TCefWindowInfo; var client: ICefClient; var settings: TCefBrowserSettings; var extra_info: ICefDictionaryValue; var noJavascriptAccess: Boolean; var Result: Boolean);
    procedure Chromium1OpenUrlFromTab(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; const targetUrl: ustring; targetDisposition: TCefWindowOpenDisposition; userGesture: Boolean; out Result: Boolean);
    procedure Chromium1BeforeContextMenu(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; const params: ICefContextMenuParams; const model: ICefMenuModel);
    procedure Chromium1GotFocus(Sender: TObject; const browser: ICefBrowser);
    procedure Chromium1LoadingStateChange(Sender: TObject; const browser: ICefBrowser; isLoading, canGoBack, canGoForward: Boolean);
    procedure Chromium1TitleChange(Sender: TObject; const browser: ICefBrowser; const title: ustring);
    procedure Chromium1AddressChange(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; const url: ustring);
    procedure Chromium1StatusMessage(Sender: TObject; const browser: ICefBrowser; const value: ustring);
    procedure Chromium1PdfPrintFinished(Sender: TObject; aResultOK: Boolean);

    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);

    procedure CEFLinkedWindowParent1Enter(Sender: TObject);
    procedure CEFLinkedWindowParent1Exit(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);

    procedure BackBtnClick(Sender: TObject);
    procedure ForwardBtnClick(Sender: TObject);
    procedure ReloadBtnClick(Sender: TObject);
    procedure StopBtnClick(Sender: TObject);
    procedure ConfigBtnClick(Sender: TObject);
    procedure PrintinPDF1Click(Sender: TObject);
    procedure Inczoom1Click(Sender: TObject);
    procedure Deczoom1Click(Sender: TObject);
    procedure Resetzoom1Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);

  protected
    FClosing  : boolean;  // Logic sluit af: venster echt sluiten (CloseMiniBrowser)
    FGesloten : boolean;  // TChromium.OnBeforeClose is gebeurd

    FBrowserCS            : TCriticalSection;
    FBrowserAddress       : string;
    FBrowserIsLoading     : boolean;
    FBrowserCanGoBack     : boolean;
    FBrowserCanGoForward  : boolean;
    FBrowserStatusText    : string;
    FBrowserTitle         : string;
    FPanelToOpen          : string;   // link naar een .lpl-paneel
    FExternalURL          : string;   // internetlink: in de gewone browser openen

    // CEF needs to handle these messages to call TChromium.NotifyMoveOrResizeStarted
    procedure WMMove(var Message: TLMMove); message LM_MOVE;
    procedure WMSize(var Message: TLMSize); message LM_SIZE;
    procedure WMWindowPosChanged(var Message: TLMWindowPosChanged); message LM_WINDOWPOSCHANGED;

    procedure CreateBrowserNow;
    procedure ShowStatusText(const aText: string);

    // in de hoofdthread (Application.QueueAsyncCall)
    procedure BrowserCreatedMsg(Data: PtrInt);
    procedure BrowserUpdateAddressMsg(Data: PtrInt);
    procedure BrowserUpdateLoadingStateMsg(Data: PtrInt);
    procedure BrowserUpdateStatusTextMsg(Data: PtrInt);
    procedure BrowserUpdateTitleMsg(Data: PtrInt);
    procedure BrowserPrintPDFEndMsg(Data: PtrInt);
    procedure BrowserSetFocusMsg(Data: PtrInt);
    procedure BlockedMsg(Data: PtrInt);
    procedure OpenPanelMsg(Data: PtrInt);
    procedure OpenExternalMsg(Data: PtrInt);
  public
    procedure LoadURLString(const AURL: string);
  end;

var
  MiniBrowserFrm : TMiniBrowserFrm;
  // ingevuld door het hoofdvenster: opent een paneel uit een link in de help
  OnHelpOpenPanel : TOpenPanelEvent = nil;

// Is de ingebouwde browser beschikbaar (ceflib gevonden en CEF gestart)?
function HelpBrowserAvailable: Boolean;
// Bij het afsluiten van Logic: de browser netjes sluiten.
procedure CloseMiniBrowser;

implementation

{$R *.lfm}

uses
  LCLIntf, URIParser, uCEFApplication, uCefGtk2Widgetset;

function HelpBrowserAvailable: Boolean;
begin
  Result := uCefGtk2Widgetset.HelpBrowserAvailable;
end;

procedure CloseMiniBrowser;
var
  Tot: QWord;
begin
  if MiniBrowserFrm = nil then Exit;
  with MiniBrowserFrm do
  begin
    FClosing := True;
    Hide;
    if Chromium1.Initialized then
    begin
      Chromium1.CloseAllBrowsers;
      // wachten op OnBeforeClose, anders blijft CEF bij het afsluiten hangen
      Tot := GetTickCount64 + 3000;
      while not FGesloten and (GetTickCount64 < Tot) do
      begin
        Application.ProcessMessages;
        Sleep(10);
      end;
    end;
  end;
end;

// Mag dit adres geopend worden? Met MINIBROWSER_LOCALONLY alleen lokale
// bestanden (de help) en interne pagina's van de browser, geen internet.
function IsAllowedURL(const aURL: string): Boolean;
var
  U: string;
begin
  if not MINIBROWSER_LOCALONLY then Exit(True);
  U := LowerCase(Trim(aURL));
  Result := (U = '') or
            (Pos('file:', U) = 1) or
            (Pos('about:', U) = 1) or
            (Pos('data:', U) = 1) or
            (Pos('blob:', U) = 1) or
            (Pos('chrome-error:', U) = 1);
end;

// Een internetadres (http of https)?
function IsWebURL(const aURL: string): Boolean;
var
  U: string;
begin
  U := LowerCase(Trim(aURL));
  Result := (Pos('http://', U) = 1) or (Pos('https://', U) = 1);
end;

{Button events}
{%Region}
procedure TMiniBrowserFrm.BackBtnClick(Sender: TObject);
begin
  Chromium1.GoBack;
end;

procedure TMiniBrowserFrm.ForwardBtnClick(Sender: TObject);
begin
  Chromium1.GoForward;
end;

procedure TMiniBrowserFrm.ReloadBtnClick(Sender: TObject);
begin
  Chromium1.Reload;
end;

procedure TMiniBrowserFrm.StopBtnClick(Sender: TObject);
begin
  Chromium1.StopLoad;
end;

procedure TMiniBrowserFrm.ConfigBtnClick(Sender: TObject);
var
  TempPoint : TPoint;
begin
  TempPoint.x := ConfigBtn.left;
  TempPoint.y := ConfigBtn.top + ConfigBtn.Height;
  TempPoint   := ConfigPnl.ClientToScreen(TempPoint);

  PopupMenu1.Popup(TempPoint.x, TempPoint.y);
end;
{%Endregion}

{Config menu events}
{%Region}
procedure TMiniBrowserFrm.Inczoom1Click(Sender: TObject);
begin
  Chromium1.IncZoomStep;
end;

procedure TMiniBrowserFrm.Deczoom1Click(Sender: TObject);
begin
  Chromium1.DecZoomStep;
end;

procedure TMiniBrowserFrm.Resetzoom1Click(Sender: TObject);
begin
  Chromium1.ResetZoomLevel;
end;

procedure TMiniBrowserFrm.PrintinPDF1Click(Sender: TObject);
begin
  SaveDialog1.DefaultExt := 'pdf';
  SaveDialog1.Filter     := 'PDF files (*.pdf)|*.pdf';

  if SaveDialog1.Execute and (length(SaveDialog1.FileName) > 0) then
    Chromium1.PrintToPDF(UTF8Decode(SaveDialog1.FileName));
end;

procedure TMiniBrowserFrm.MenuItem2Click(Sender: TObject);
var
  TempInfo : string;
begin
  TempInfo := 'CEF : '                + CRLF + GlobalCEFApp.LibCefVersion    + CRLF + CRLF +
              'Chromium : '           + CRLF + GlobalCEFApp.ChromeVersion    + CRLF + CRLF +
              'Platform API hash : '  + CRLF + GlobalCEFApp.ApiHashPlatform  + CRLF + CRLF +
              'Commit API hash : '    + CRLF + GlobalCEFApp.ApiHashCommit;

  showmessage(TempInfo);
end;
{%Endregion}

{Form events}
{%Region}
procedure TMiniBrowserFrm.CreateBrowserNow;
begin
  // GlobalCEFApp.GlobalContextInitialized has to be TRUE before creating any browser
  // If it's not initialized yet, we use a simple timer to create the browser later.
  if not(Chromium1.Initialized) and
     not(Chromium1.CreateBrowser(CEFLinkedWindowParent1.Handle, CEFLinkedWindowParent1.BoundsRect)) then
    Timer1.Enabled := True;
end;

procedure TMiniBrowserFrm.FormActivate(Sender: TObject);
begin
  // Linux needs a visible form to create a browser so we need to use the
  // TForm.OnActivate event instead of the TForm.OnShow event
  CreateBrowserNow;
end;

procedure TMiniBrowserFrm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  // Sluiten verbergt het venster; de browser blijft klaar voor de volgende vraag.
  // Pas bij het afsluiten van Logic (CloseMiniBrowser) echt sluiten.
  CanClose := FClosing;
  if not FClosing then Hide;
end;

procedure TMiniBrowserFrm.FormCreate(Sender: TObject);
begin
  FClosing             := False;
  FGesloten            := False;

  FBrowserAddress      := '';
  FBrowserIsLoading    := False;
  FBrowserCanGoBack    := False;
  FBrowserCanGoForward := False;
  FBrowserStatusText   := '';
  FBrowserTitle        := '';

  FBrowserCS           := TCriticalSection.Create;

  Chromium1.MultiBrowserMode := True;
  Chromium1.DefaultURL       := '';
  Chromium1.RuntimeStyle     := CEF_RUNTIME_STYLE_ALLOY;

  // WebRTC's IP leaking can lowered/avoided by setting these preferences
  Chromium1.WebRTCIPHandlingPolicy := hpDisableNonProxiedUDP;
  Chromium1.WebRTCMultipleRoutes   := STATE_DISABLED;
  Chromium1.WebRTCNonproxiedUDP    := STATE_DISABLED;

  if MINIBROWSER_LOCALONLY then
  begin
    // adresbalk alleen tonen, niet zelf een adres intikken
    URLCbx.Enabled := False;
  end;
end;

procedure TMiniBrowserFrm.FormDestroy(Sender: TObject);
begin
  Application.RemoveAsyncCalls(Self);
  if MiniBrowserFrm = Self then MiniBrowserFrm := nil;
  FBrowserCS.Free;
end;

procedure TMiniBrowserFrm.LoadURLString(const AURL: string);
begin
  if Chromium1.Initialized then
    Chromium1.LoadURL(UTF8Decode(AURL))
  else
    Chromium1.DefaultURL := UTF8Decode(AURL);

  if not Visible then
    Show;

  BringToFront;
end;

procedure TMiniBrowserFrm.ShowStatusText(const aText: string);
begin
  StatusBar1.Panels[0].Text := aText;
end;
{%Endregion}

{Lazarus form messages}
{%Region}
procedure TMiniBrowserFrm.WMMove(var Message: TLMMove);
begin
  inherited;
  Chromium1.NotifyMoveOrResizeStarted;
end;

procedure TMiniBrowserFrm.WMSize(var Message: TLMSize);
begin
  inherited;
  Chromium1.NotifyMoveOrResizeStarted;
end;

procedure TMiniBrowserFrm.WMWindowPosChanged(var Message: TLMWindowPosChanged);
begin
  inherited;
  Chromium1.NotifyMoveOrResizeStarted;
end;
{%Endregion}

{TCEFLinkedWindowParent events}
{%Region}
procedure TMiniBrowserFrm.CEFLinkedWindowParent1Exit(Sender: TObject);
begin
  if not(csDesigning in ComponentState) then
    Chromium1.SendCaptureLostEvent;
end;

procedure TMiniBrowserFrm.CEFLinkedWindowParent1Enter(Sender: TObject);
begin
  if not(csDesigning in ComponentState) and
     Chromium1.Initialized and
     not(Chromium1.FrameIsFocused) then
    Chromium1.SetFocus(True);
end;
{%Endregion}

procedure TMiniBrowserFrm.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := False;
  CreateBrowserNow;
end;

{Chromium events (in een CEF-thread: de GUI bijwerken via QueueAsyncCall)}
{%Region}
procedure TMiniBrowserFrm.Chromium1AddressChange(Sender: TObject;
  const browser: ICefBrowser; const frame: ICefFrame; const url: ustring);
begin
  if Chromium1.IsSameBrowser(browser) then
    begin
      FBrowserCS.Acquire;
      FBrowserAddress := UTF8Encode(url);
      FBrowserCS.Release;
      Application.QueueAsyncCall(@BrowserUpdateAddressMsg, 0);
    end;
end;

procedure TMiniBrowserFrm.Chromium1AfterCreated(Sender: TObject; const browser: ICefBrowser);
begin
  if Chromium1.IsSameBrowser(browser) then
    Application.QueueAsyncCall(@BrowserCreatedMsg, 0);
end;

procedure TMiniBrowserFrm.Chromium1ChromeCommand(Sender: TObject;
  const browser: ICefBrowser; command_id: integer;
  disposition: TCefWindowOpenDisposition; var aResult: boolean);
begin
  aResult := (command_id = IDC_HELP_PAGE_VIA_KEYBOARD) or // Block the new Chromium window created when the user presses F1 for help.
             (command_id = IDC_FULLSCREEN);               // Block the "switch to full screen" command when the user presses F11.
end;

procedure TMiniBrowserFrm.Chromium1BeforeClose(Sender: TObject; const browser: ICefBrowser);
begin
  // The main browser is being destroyed
  if (Chromium1.BrowserId = 0) then
    FGesloten := True;
end;

procedure TMiniBrowserFrm.Chromium1Close(Sender: TObject; const browser: ICefBrowser; var aAction : TCefCloseBrowserAction);
begin
  if (browser <> nil) and
     (Chromium1.BrowserId = browser.Identifier) then
    aAction := cbaClose;
end;

procedure TMiniBrowserFrm.Chromium1BeforeBrowse(Sender: TObject; const browser: ICefBrowser;
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
    FBrowserCS.Acquire;
    FPanelToOpen := FN;
    FBrowserCS.Release;
    Application.QueueAsyncCall(@OpenPanelMsg, 0);
    Result := True;
    Exit;
  end;

  // Zelf aangeklikte internetlink: in de gewone browser openen
  if MINIBROWSER_LOCALONLY and user_gesture and IsWebURL(U) then
  begin
    FBrowserCS.Acquire;
    FExternalURL := U;
    FBrowserCS.Release;
    Application.QueueAsyncCall(@OpenExternalMsg, 0);
    Result := True;
    Exit;
  end;

  // Result = True: navigatie annuleren
  Result := not IsAllowedURL(U);
  if Result then
    Application.QueueAsyncCall(@BlockedMsg, 0);
end;

procedure TMiniBrowserFrm.Chromium1BeforePopup(Sender: TObject; const browser: ICefBrowser;
  const frame: ICefFrame; popup_id: Integer; const targetUrl, targetFrameName: ustring;
  targetDisposition: TCefWindowOpenDisposition; userGesture: Boolean;
  const popupFeatures: TCefPopupFeatures; var windowInfo: TCefWindowInfo;
  var client: ICefClient; var settings: TCefBrowserSettings;
  var extra_info: ICefDictionaryValue; var noJavascriptAccess: Boolean;
  var Result: Boolean);
begin
  // Result = True: geen nieuw venster; internetlinks gaan naar de gewone browser
  Result := True;
  if userGesture and IsWebURL(UTF8Encode(targetUrl)) then
  begin
    FBrowserCS.Acquire;
    FExternalURL := UTF8Encode(targetUrl);
    FBrowserCS.Release;
    Application.QueueAsyncCall(@OpenExternalMsg, 0);
  end
  else if not IsAllowedURL(UTF8Encode(targetUrl)) then
    Application.QueueAsyncCall(@BlockedMsg, 0);
end;

procedure TMiniBrowserFrm.Chromium1OpenUrlFromTab(Sender: TObject; const browser: ICefBrowser;
  const frame: ICefFrame; const targetUrl: ustring;
  targetDisposition: TCefWindowOpenDisposition; userGesture: Boolean;
  out Result: Boolean);
begin
  // geen nieuwe tabbladen of vensters
  Result := True;
end;

procedure TMiniBrowserFrm.Chromium1BeforeContextMenu(Sender: TObject;
  const browser: ICefBrowser; const frame: ICefFrame;
  const params: ICefContextMenuParams; const model: ICefMenuModel);
begin
  // geen ontwikkelaarstools; het standaardmenu van CEF volstaat
end;

procedure TMiniBrowserFrm.Chromium1LoadingStateChange(Sender: TObject;
  const browser: ICefBrowser; isLoading, canGoBack, canGoForward: Boolean);
begin
  if not(Chromium1.IsSameBrowser(browser)) or FClosing then exit;

  FBrowserCS.Acquire;
  FBrowserIsLoading    := isLoading;
  FBrowserCanGoBack    := canGoBack;
  FBrowserCanGoForward := canGoForward;
  FBrowserCS.Release;

  Application.QueueAsyncCall(@BrowserUpdateLoadingStateMsg, 0);
end;

procedure TMiniBrowserFrm.Chromium1PdfPrintFinished(Sender: TObject; aResultOK: Boolean);
begin
  Application.QueueAsyncCall(@BrowserPrintPDFEndMsg, PtrInt(ord(aResultOK)));
end;

procedure TMiniBrowserFrm.Chromium1StatusMessage(Sender: TObject;
  const browser: ICefBrowser; const value: ustring);
begin
  if Chromium1.IsSameBrowser(browser) then
    begin
      FBrowserCS.Acquire;
      FBrowserStatusText := UTF8Encode(value);
      FBrowserCS.Release;
      Application.QueueAsyncCall(@BrowserUpdateStatusTextMsg, 0);
    end;
end;

procedure TMiniBrowserFrm.Chromium1TitleChange(Sender: TObject;
  const browser: ICefBrowser; const title: ustring);
begin
  if not(Chromium1.IsSameBrowser(browser)) then exit;

  FBrowserCS.Acquire;
  if (length(title) > 0) then
    FBrowserTitle := 'Browser LogicNew - ' + UTF8Encode(title)
   else
    FBrowserTitle := 'Browser LogicNew';
  FBrowserCS.Release;

  Application.QueueAsyncCall(@BrowserUpdateTitleMsg, 0);
end;

procedure TMiniBrowserFrm.Chromium1GotFocus(Sender: TObject;
  const browser: ICefBrowser);
begin
  Application.QueueAsyncCall(@BrowserSetFocusMsg, 0);
end;
{%Endregion}

{Custom form messages}
{%Region}
procedure TMiniBrowserFrm.BrowserCreatedMsg(Data: PtrInt);
begin
  NavControlPnl.Enabled := True;
  CEFLinkedWindowParent1.UpdateSize;
end;

procedure TMiniBrowserFrm.BrowserPrintPDFEndMsg(Data: PtrInt);
begin
  if (Data <> 0) then
    showmessage('The PDF file was generated successfully')
   else
    showmessage('There was a problem generating the PDF file.');
end;

procedure TMiniBrowserFrm.BrowserUpdateAddressMsg(Data: PtrInt);
var
  TempURL : string;
begin
  FBrowserCS.Acquire;
  TempURL := FBrowserAddress;
  FBrowserCS.Release;

  if (URLCbx.Items.IndexOf(TempURL) < 0) then
     URLCbx.Items.Add(TempURL);

  URLCbx.Text := TempURL;
end;

procedure TMiniBrowserFrm.BrowserUpdateLoadingStateMsg(Data: PtrInt);
var
  TempLoading : boolean;
begin
  FBrowserCS.Acquire;
  BackBtn.Enabled    := FBrowserCanGoBack;
  ForwardBtn.Enabled := FBrowserCanGoForward;
  TempLoading        := FBrowserIsLoading;
  FBrowserCS.Release;

  ReloadBtn.Enabled := not TempLoading;
  StopBtn.Enabled   := TempLoading;
  if not TempLoading then
    ShowStatusText('Finished');
end;

procedure TMiniBrowserFrm.BrowserUpdateStatusTextMsg(Data: PtrInt);
begin
  FBrowserCS.Acquire;
  ShowStatusText(FBrowserStatusText);
  FBrowserCS.Release;
end;

procedure TMiniBrowserFrm.BrowserUpdateTitleMsg(Data: PtrInt);
begin
  FBrowserCS.Acquire;
  Caption := FBrowserTitle;
  FBrowserCS.Release;
end;

procedure TMiniBrowserFrm.BrowserSetFocusMsg(Data: PtrInt);
begin
  if CEFLinkedWindowParent1.CanFocus then
    CEFLinkedWindowParent1.SetFocus;
end;

procedure TMiniBrowserFrm.BlockedMsg(Data: PtrInt);
begin
  ShowStatusText('Internet is uitgeschakeld in de help / Internet is disabled in the help');
end;

procedure TMiniBrowserFrm.OpenPanelMsg(Data: PtrInt);
var
  FN: string;
begin
  FBrowserCS.Acquire;
  FN := FPanelToOpen;
  FPanelToOpen := '';
  FBrowserCS.Release;
  if (FN <> '') and Assigned(OnHelpOpenPanel) then
    OnHelpOpenPanel(FN);
end;

procedure TMiniBrowserFrm.OpenExternalMsg(Data: PtrInt);
var
  U: string;
begin
  FBrowserCS.Acquire;
  U := FExternalURL;
  FExternalURL := '';
  FBrowserCS.Release;
  if U <> '' then
    OpenURL(U);
end;
{%Endregion}

end.
