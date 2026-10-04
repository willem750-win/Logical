program logic;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, smnetgradientlaz, main, FSettings, rx, Pinfo,
  // De ingebouwde CEF-browser (MiniBrowser) wordt enkel onder Windows
  // gebruikt; onder Linux opent de help in de systeembrowser.
  {$IFDEF WINDOWS}
  uMiniBrowser, uPreferences, uSimpleTextViewer, uCEFApplication,
  {$ENDIF}
  uHelpManager
  { you can add units after this };

{$R *.res}

begin
  {$IFDEF WINDOWS}
  CreateGlobalCEFApp;

  // HEEL BELANGRIJK: dit scheidt main-process van subprocess
  if not GlobalCEFApp.StartMainProcess then
    Exit;
  {$ENDIF}

  RequireDerivedFormResource:=True;

  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TmainForm, mainForm);
  Application.Run;
end.

