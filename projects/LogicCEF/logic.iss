; Inno Setup-script voor Logic (Windows-installatieprogramma).
;
; Compileren (Inno Setup 6):
;   "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" /DMyAppVersion=1.0.1 projects\LogicCEF\logic.iss
; of via make-release.ps1, dat ook de zip maakt.
;
; Resultaat: C:\fpcupdeluxe\publish\release\Logic-<versie>-setup.exe
;
; Waarom per gebruiker installeren?
; Logic schrijft naast zijn eigen programmabestand (taal.ini, ini\, panels\,
; en de CEF-cache). In Program Files mag een gewone gebruiker dat niet.
; Daarom gaat Logic naar %LOCALAPPDATA%\Programs\Logic, zonder
; beheerdersrechten. Instellingen en eigen panelen blijven bij een update
; behouden; programma, CEF-runtime, help en html worden vervangen.

#ifndef MyAppVersion
  #define MyAppVersion "1.0.1"
#endif
#define MyAppName      "Logic"
#define MyAppPublisher "Willy Jansen"
#define MyAppURL       "https://github.com/willem750-win/Logical"
#define MyAppExeName   "logicCEF.exe"
#define Src            "Resultaat"

[Setup]
AppId={{6E0B2F4A-3C7D-4B8E-9A51-2D4F7C1E8B36}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}/releases
AppCopyright=© 2026 Willy Jansen
VersionInfoVersion={#MyAppVersion}
VersionInfoDescription={#MyAppName} {#MyAppVersion} Setup
PrivilegesRequired=lowest
DefaultDirName={localappdata}\Programs\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
LicenseFile=..\..\LICENSE
SetupIconFile=logic.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName} {#MyAppVersion}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=C:\fpcupdeluxe\publish\release
OutputBaseFilename=Logic-{#MyAppVersion}-setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes

[Languages]
Name: "dutch";   MessagesFile: "compiler:Languages\Dutch.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "french";  MessagesFile: "compiler:Languages\French.isl"
Name: "german";  MessagesFile: "compiler:Languages\German.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; Programma en CEF-runtime: altijd vervangen
Source: "{#Src}\{#MyAppExeName}";           DestDir: "{app}"; Flags: ignoreversion
Source: "{#Src}\libcef.dll";                DestDir: "{app}"; Flags: ignoreversion
Source: "{#Src}\chrome_elf.dll";            DestDir: "{app}"; Flags: ignoreversion
Source: "{#Src}\d3dcompiler_47.dll";        DestDir: "{app}"; Flags: ignoreversion
Source: "{#Src}\libEGL.dll";                DestDir: "{app}"; Flags: ignoreversion
Source: "{#Src}\libGLESv2.dll";             DestDir: "{app}"; Flags: ignoreversion
Source: "{#Src}\vk_swiftshader.dll";        DestDir: "{app}"; Flags: ignoreversion
Source: "{#Src}\vk_swiftshader_icd.json";   DestDir: "{app}"; Flags: ignoreversion
Source: "{#Src}\vulkan-1.dll";              DestDir: "{app}"; Flags: ignoreversion
Source: "{#Src}\icudtl.dat";                DestDir: "{app}"; Flags: ignoreversion
Source: "{#Src}\resources.pak";             DestDir: "{app}"; Flags: ignoreversion
Source: "{#Src}\chrome_100_percent.pak";    DestDir: "{app}"; Flags: ignoreversion
Source: "{#Src}\chrome_200_percent.pak";    DestDir: "{app}"; Flags: ignoreversion
Source: "{#Src}\snapshot_blob.bin";         DestDir: "{app}"; Flags: ignoreversion
Source: "{#Src}\v8_context_snapshot.bin";   DestDir: "{app}"; Flags: ignoreversion
Source: "{#Src}\locales\*";                 DestDir: "{app}\locales"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#Src}\help\*";                    DestDir: "{app}\help"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#Src}\html\*";                    DestDir: "{app}\html"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\..\LICENSE";                    DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\README.md";                  DestDir: "{app}"; Flags: ignoreversion

; Instellingen en panelen: alleen als ze nog niet bestaan (eigen werk blijft),
; en niet verwijderen bij het verwijderen van Logic
Source: "{#Src}\taal.ini";  DestDir: "{app}"; Flags: onlyifdoesntexist uninsneveruninstall
Source: "{#Src}\ini\*";     DestDir: "{app}\ini"; Excludes: "comboColor.ini"; Flags: onlyifdoesntexist uninsneveruninstall recursesubdirs createallsubdirs
Source: "{#Src}\panels\*";  DestDir: "{app}\panels"; Flags: onlyifdoesntexist uninsneveruninstall recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"
Name: "{autodesktop}\{#MyAppName}";  Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Door het programma aangemaakt
Type: filesandordirs; Name: "{app}\cache"
Type: files;          Name: "{app}\debug.log"
