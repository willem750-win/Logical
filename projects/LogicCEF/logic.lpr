program logic;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  // Onder Linux (GTK2) start uCefGtk2Widgetset eerst CEF (ingebouwde help,
  // zie uMiniBrowserLinux) en maakt pas daarna de widgetset aan.
  {$IF DEFINED(LINUX) AND DEFINED(LCLGTK2)}
  uCefGtk2Widgetset,
  {$ELSE}
  Interfaces, // this includes the LCL widgetset
  {$ENDIF}
  Forms, main, FSettings, rx,
  // De ingebouwde CEF-browser onder Windows (MiniBrowser)
  {$IFDEF WINDOWS}
  uMiniBrowser, uPreferences, uSimpleTextViewer, uCEFApplication,
  {$ENDIF}
  uHelpManager
  { you can add units after this };

{$R *.res}

begin
  {$IFDEF WINDOWS}
  CreateGlobalCEFApp;

  // HEEL BELANGRIJK: dit scheidt main-process van subprocess. Een subprocess
  // slaat het programma over, maar ruimt GlobalCEFApp wel op (hieronder).
  if GlobalCEFApp.StartMainProcess then
  {$ENDIF}
  begin
    RequireDerivedFormResource:=True;

  Application.Scaled:=True;
    Application.Initialize;
    Application.CreateForm(TmainForm, mainForm);
    Application.Run;
  end;

  {$IFDEF WINDOWS}
  // GlobalCEFApp vrijgeven, zoals in de voorbeelden van CEF4Delphi (onder
  // Linux doet uCefGtk2Widgetset dit)
  DestroyGlobalCEFApp;
  {$ENDIF}
end.

