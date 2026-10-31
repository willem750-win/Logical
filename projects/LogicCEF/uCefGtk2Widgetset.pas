unit uCefGtk2Widgetset;

// Vervangt de LCL-unit Interfaces onder Linux (GTK2), voor de ingebouwde
// help met CEF4Delphi (zie uMiniBrowserLinux). CEF moet starten vóór GTK:
// in de initialization start eerst CEF (als de map ceflib er is) en pas
// daarna de widgetset, net zoals Interfaces dat doet.
// Naar het voorbeeld Lazarus_Linux/SimpleBrowser2 van CEF4Delphi.

{$mode objfpc}{$H+}

interface

{$IFDEF UNIX}{$IFNDEF DisableCWString}uses cwstring;{$ENDIF}{$ENDIF}

// Is de ingebouwde browser beschikbaar (ceflib gevonden en CEF gestart)?
function HelpBrowserAvailable: Boolean;

implementation

uses
  SysUtils, gtk2DisableLibOverlay, Gtk2Int, InterfaceBase, Forms, xlib,
  uCEFApplication, uCEFConstants, uCEFTypes;

var
  CefGestart: Boolean = False;
  EigenWidgetset: Boolean = False;

function HelpBrowserAvailable: Boolean;
begin
  Result := CefGestart;
end;

// Start CEF als ceflib naast het programma staat.
// False = dit is een CEF-subproces (renderer, GPU ...) dat klaar is.
function StartHelpCEF: Boolean;
var
  AppDir, CefDir, DataDir: string;
  I: Integer;
  SubProces: Boolean;
begin
  Result := True;
  AppDir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  CefDir := AppDir + 'ceflib';
  if not FileExists(CefDir + PathDelim + 'libcef.so') then Exit;

  SubProces := False;
  for I := 1 to ParamCount do
    if Pos('--type=', ParamStr(I)) = 1 then SubProces := True;

  // cache en log in de gebruikersmap: de programmamap kan alleen-lezen zijn
  DataDir := IncludeTrailingPathDelimiter(GetUserDir + '.cache') + 'logic-help';
  ForceDirectories(DataDir);

  GlobalCEFApp                  := TCefApplication.Create;
  GlobalCEFApp.FrameworkDirPath := CefDir;
  GlobalCEFApp.ResourcesDirPath := CefDir;
  GlobalCEFApp.LocalesDirPath   := CefDir + PathDelim + 'locales';
  GlobalCEFApp.cache            := DataDir + PathDelim + 'cache';
  GlobalCEFApp.LogFile          := DataDir + PathDelim + 'debug.log';
  GlobalCEFApp.LogSeverity      := LOGSEVERITY_ERROR;
  GlobalCEFApp.ShowMessageDlg   := False;
  // Logic (GTK2) draait onder X11, ook in een Wayland-sessie (Xwayland).
  // Zonder dit kiest Chromium daar zelf Wayland: de pagina komt dan in een
  // los venster linksboven en de ingebedde browser blijft zwart.
  GlobalCEFApp.OzonePlatform    := ozpX11;

  if GlobalCEFApp.StartMainProcess then
  begin
    CefGestart := True;
    Exit;
  end;

  DestroyGlobalCEFApp;
  // in het hoofdproces zonder werkende CEF: help in de systeembrowser
  Result := not SubProces;
end;

// CEF en GTK delen de X-verbinding; X-fouten van de browser mogen Logic
// niet afsluiten.
function CustomX11ErrorHandler(Display: PDisplay; ErrorEv: PXErrorEvent): longint; cdecl;
begin
  Result := 0;
end;

function CustomXIOErrorHandler(Display: PDisplay): longint; cdecl;
begin
  Result := 0;
end;

initialization
  // Een programma dat ook de LCL-unit Interfaces gebruikt (bv. een testprogramma)
  // heeft de widgetset al: dan geen CEF, de help gaat naar de systeembrowser.
  if WidgetSet = nil then
  begin
    EigenWidgetset := True;
    if not StartHelpCEF then
      Halt(0);
    CreateWidgetset(TGtk2WidgetSet);
    if CefGestart then
    begin
      XSetErrorHandler(@CustomX11ErrorHandler);
      XSetIOErrorHandler(@CustomXIOErrorHandler);
    end;
  end;

finalization
  if EigenWidgetset then
    FreeWidgetSet;
  if GlobalCEFApp <> nil then
    DestroyGlobalCEFApp;

end.
