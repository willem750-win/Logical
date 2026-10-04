unit uHelpManager;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls, Forms, Dialogs;

type
  THelpDisplayMode = (hdmMessage, hdmHTML);
  THelpOpenFileEvent = procedure(const AFileName: string) of object;
  THelpTextEvent = function(const AKeyword, ABTaal: string): string of object;

  { TAppHelpManager }

  TAppHelpManager = class(TComponent)
  private
    FHelpPath: string;
    FDisplayMode: THelpDisplayMode;
    FBTaal: string;
    FOnGetHelpText: THelpTextEvent;
    FOnOpenHelpFile: THelpOpenFileEvent;

    function SafeLower(const S: string): string;
    function LangFolder: string;
    function HelpPageForKeyword(const AKeyword: string; out AAnchor: string): string;
    function BuildHelpPageFileName(const APage: string): string;
    function BuildHelpBaseFileName: string;
    function BuildHelpTarget(const AKeyword: string): string;
    function GetBuiltInHelpText(const AKeyword, ABTaal: string): string;
    function FindNearestHelpControl(AControl: TControl): TControl;
  public
    constructor Create(AOwner: TComponent); override;

    procedure ShowHelpForControl(AControl: TControl);
    procedure ShowHelpForObject(AObject: TObject);
    procedure ShowHelpForKeyword(const AKeyword: string);
    procedure ShowTableOfContents;

    procedure RegisterDefaultKeyword(AControl: TControl);
    procedure RegisterDefaultKeywords(AParent: TWinControl);

    property BTaal: string read FBTaal write FBTaal;
  published
    property HelpPath: string read FHelpPath write FHelpPath;
    property DisplayMode: THelpDisplayMode read FDisplayMode write FDisplayMode;
    property OnGetHelpText: THelpTextEvent read FOnGetHelpText write FOnGetHelpText;
    property OnOpenHelpFile: THelpOpenFileEvent read FOnOpenHelpFile write FOnOpenHelpFile;
  end;

function TrHelp(const ABTaal, NLText, ENText, FRText, DEText: string): string;
procedure AssignHelpRecursive(AParent: TWinControl);
procedure ShowAppHelpForControl(AControl: TControl);
procedure ShowAppHelpForObject(AObject: TObject);

var
  AppHelpManager: TAppHelpManager = nil;

implementation

function TrHelp(const ABTaal, NLText, ENText, FRText, DEText: string): string;
begin
  if SameText(ABTaal, 'NL') then
    Result := NLText
  else if SameText(ABTaal, 'ENG') then
    Result := ENText
  else if SameText(ABTaal, 'FR') then
    Result := FRText
  else if SameText(ABTaal, 'DU') then
    Result := DEText
  else
    Result := ENText;
end;

{ TAppHelpManager }

constructor TAppHelpManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FHelpPath := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)) + 'help');
  FDisplayMode := hdmHTML;
  FBTaal := 'NL';
end;

function TAppHelpManager.SafeLower(const S: string): string;
begin
  Result := LowerCase(Trim(S));
end;

// De help staat per taal in een eigen map: help\nl, help\en, help\fr, help\de.
function TAppHelpManager.LangFolder: string;
begin
  if SameText(FBTaal, 'ENG') then
    Result := 'en'
  else if SameText(FBTaal, 'FR') then
    Result := 'fr'
  else if SameText(FBTaal, 'DU') then
    Result := 'de'
  else
    Result := 'nl';

  // Valt terug op Nederlands als de vertaling (nog) ontbreekt.
  if not DirectoryExists(IncludeTrailingPathDelimiter(FHelpPath) + Result) then
    Result := 'nl';
end;

// Koppelt een HelpKeyword aan een helppagina en een anker op die pagina.
function TAppHelpManager.HelpPageForKeyword(const AKeyword: string;
  out AAnchor: string): string;
var
  K: string;
begin
  K := SafeLower(AKeyword);
  AAnchor := K;

  case K of
    'raster', 'grid':
      begin Result := 'paneel'; AAnchor := 'raster'; end;
    'richtlijnen', 'kader', 'titel', 'paneelkeuze', 'opslaan':
      Result := 'paneel';
    'openen':
      begin Result := 'paneel'; AAnchor := 'opslaan'; end;
    'schermkopie', 'info', 'afsluiten', 'browser', 'draden', 'sbutton1':
      Result := 'knoppen';
    'logicbox':
      Result := 'onderdelenbalk';
    'button', 'drukknop':
      begin Result := 'invoer'; AAnchor := 'drukknop'; end;
    'schakelaar', 'dipswitch', 'puls', 'sensor', 'warm':
      Result := 'invoer';
    'logic':
      begin Result := 'verwerking'; AAnchor := 'poorten'; end;
    'teller', 'geheugen':
      Result := 'verwerking';
    'lamp', 'relais', 'zoemer', 'display', 'meter':
      Result := 'uitvoer';
    'connector':
      Result := 'verbindingen';
    'delete_selected':
      begin Result := 'objecten'; AAnchor := 'verwijderen'; end;
    'simulate':
      Result := 'simulatie';
    'settings', 'taal':
      Result := 'instellingen';
  else
    begin Result := 'index'; AAnchor := ''; end;
  end;
end;

function TAppHelpManager.BuildHelpPageFileName(const APage: string): string;
begin
  Result := IncludeTrailingPathDelimiter(FHelpPath) + LangFolder + PathDelim +
    APage + '.html';
end;

function TAppHelpManager.BuildHelpBaseFileName: string;
begin
  Result := BuildHelpPageFileName('index');
end;

function TAppHelpManager.BuildHelpTarget(const AKeyword: string): string;
var
  Anchor: string;
begin
  Result := BuildHelpPageFileName(HelpPageForKeyword(AKeyword, Anchor));
  if Anchor <> '' then
    Result := Result + '#' + Anchor;
end;

function TAppHelpManager.FindNearestHelpControl(AControl: TControl): TControl;
begin
  Result := AControl;
  while Assigned(Result) do
  begin
    if Trim(Result.HelpKeyword) <> '' then
      Exit;
    Result := Result.Parent;
  end;
end;

function TAppHelpManager.GetBuiltInHelpText(const AKeyword, ABTaal: string): string;
begin
  case SafeLower(AKeyword) of
    'button':
      Result := TrHelp(ABTaal,
        'Knop / Schakelaar'#13#10#13#10 +
        '- Simuleert een binaire invoer of uitgang.'#13#10 +
        '- Linkermuisknop wijzigt meestal de status.'#13#10 +
        '- Rechtermuisknop opent extra instellingen.'#13#10 +
        '- Naam en status kunnen in de statusbalk getoond worden.',
        'Button / Switch'#13#10#13#10 +
        '- Simulates a binary input or output.'#13#10 +
        '- Left mouse click usually changes the state.'#13#10 +
        '- Right mouse click opens extra settings.'#13#10 +
        '- Name and state can be shown in the status bar.',
        'Bouton / Interrupteur'#13#10#13#10 +
        '- Simule une entrée ou sortie binaire.'#13#10 +
        '- Le clic gauche change généralement l''état.'#13#10 +
        '- Le clic droit ouvre des réglages supplémentaires.'#13#10 +
        '- Le nom et l''état peuvent être affichés dans la barre d''état.',
        'Schalter / Taster'#13#10#13#10 +
        '- Simuliert einen binären Ein- oder Ausgang.'#13#10 +
        '- Linksklick ändert normalerweise den Zustand.'#13#10 +
        '- Rechtsklick öffnet zusätzliche Einstellungen.'#13#10 +
        '- Name und Zustand können in der Statusleiste angezeigt werden.');

    'schakelaar':
      Result := TrHelp(ABTaal,
        'Schakelaar'#13#10#13#10 +
        '- Simuleert een aan/uit schakelaar.'#13#10 +
        '- Kan geselecteerd en bediend worden.'#13#10 +
        '- Naam en status kunnen in de statusbalk getoond worden.',
        'Switch'#13#10#13#10 +
        '- Simulates an on/off switch.'#13#10 +
        '- Can be selected and operated.'#13#10 +
        '- Name and state can be shown in the status bar.',
        'Interrupteur'#13#10#13#10 +
        '- Simule un interrupteur marche/arrêt.'#13#10 +
        '- Peut être sélectionné et commandé.'#13#10 +
        '- Le nom et l''état peuvent être affichés dans la barre d''état.',
        'Schalter'#13#10#13#10 +
        '- Simuliert einen Ein/Aus-Schalter.'#13#10 +
        '- Kann ausgewählt und bedient werden.'#13#10 +
        '- Name und Zustand können in der Statusleiste angezeigt werden.');

    'logic':
      Result := TrHelp(ABTaal,
        'Logica-blok'#13#10#13#10 +
        '- Verwerkt ingangen volgens een logische functie.'#13#10 +
        '- Ondersteunde functies zijn bijvoorbeeld AND, OR en NOT.'#13#10 +
        '- De gekozen functie kan in statusbalk of hint getoond worden.',
        'Logic block'#13#10#13#10 +
        '- Processes inputs according to a logic function.'#13#10 +
        '- Supported functions may include AND, OR and NOT.'#13#10 +
        '- The selected function can be shown in the status bar or hint.',
        'Bloc logique'#13#10#13#10 +
        '- Traite les entrées selon une fonction logique.'#13#10 +
        '- Les fonctions prises en charge incluent par exemple AND, OR et NOT.'#13#10 +
        '- La fonction choisie peut être affichée dans la barre d''état ou l''info-bulle.',
        'Logikblock'#13#10#13#10 +
        '- Verarbeitet Eingänge entsprechend einer logischen Funktion.'#13#10 +
        '- Unterstützte Funktionen sind z. B. AND, OR und NOT.'#13#10 +
        '- Die gewählte Funktion kann in Statusleiste oder Hinweis angezeigt werden.');

    'connector':
      Result := TrHelp(ABTaal,
        'Connector / Draad'#13#10#13#10 +
        '- Verbindt objecten met elkaar.'#13#10 +
        '- Kan geselecteerd worden voor bewerking of verwijderen.'#13#10 +
        '- Popupmenu kan extra acties bevatten.',
        'Connector / Wire'#13#10#13#10 +
        '- Connects objects together.'#13#10 +
        '- Can be selected for editing or deleting.'#13#10 +
        '- Popup menu may contain extra actions.',
        'Connecteur / Fil'#13#10#13#10 +
        '- Relie des objets entre eux.'#13#10 +
        '- Peut être sélectionné pour modification ou suppression.'#13#10 +
        '- Le menu contextuel peut contenir des actions supplémentaires.',
        'Verbinder / Draht'#13#10#13#10 +
        '- Verbindet Objekte miteinander.'#13#10 +
        '- Kann zum Bearbeiten oder Löschen ausgewählt werden.'#13#10 +
        '- Das Kontextmenü kann zusätzliche Aktionen enthalten.');

    'sensor':
      Result := TrHelp(ABTaal,
        'Sensor'#13#10#13#10 +
        '- Stelt een detectie- of invoercomponent voor.'#13#10 +
        '- Geeft meestal een binaire toestand door.',
        'Sensor'#13#10#13#10 +
        '- Represents a detection or input component.'#13#10 +
        '- Usually provides a binary state.',
        'Capteur'#13#10#13#10 +
        '- Représente un composant de détection ou d''entrée.'#13#10 +
        '- Fournit généralement un état binaire.',
        'Sensor'#13#10#13#10 +
        '- Stellt eine Erkennungs- oder Eingabekomponente dar.'#13#10 +
        '- Liefert normalerweise einen binären Zustand.');

    'warm':
      Result := TrHelp(ABTaal,
        'Verwarming / Warm-element'#13#10#13#10 +
        '- Stelt een warmte-uitgang of warmtesymbool voor.',
        'Heating / Warm element'#13#10#13#10 +
        '- Represents a heating output or warm symbol.',
        'Chauffage / Élément chaud'#13#10#13#10 +
        '- Représente une sortie de chauffage ou un symbole thermique.',
        'Heizung / Wärmeelement'#13#10#13#10 +
        '- Stellt einen Heizausgang oder ein Wärmesymbol dar.');

    'puls':
      Result := TrHelp(ABTaal,
        'Puls'#13#10#13#10 +
        '- Genereert of toont een tijdelijke puls.'#13#10 +
        '- Handig voor triggers of testsignalen.',
        'Pulse'#13#10#13#10 +
        '- Generates or shows a temporary pulse.'#13#10 +
        '- Useful for triggers or test signals.',
        'Impulsion'#13#10#13#10 +
        '- Génère ou affiche une impulsion temporaire.'#13#10 +
        '- Utile pour les déclencheurs ou signaux de test.',
        'Impuls'#13#10#13#10 +
        '- Erzeugt oder zeigt einen temporären Impuls.'#13#10 +
        '- Nützlich für Trigger oder Testsignale.');

    'dipswitch':
      Result := TrHelp(ABTaal,
        'DIP-switch'#13#10#13#10 +
        '- Laat meerdere vaste binaire instellingen toe.',
        'DIP switch'#13#10#13#10 +
        '- Allows multiple fixed binary settings.',
        'Commutateur DIP'#13#10#13#10 +
        '- Permet plusieurs réglages binaires fixes.',
        'DIP-Schalter'#13#10#13#10 +
        '- Ermöglicht mehrere feste binäre Einstellungen.');

    'grid':
      Result := TrHelp(ABTaal,
        'Raster / Grid'#13#10#13#10 +
        '- Ondersteunt objectplaatsing, selectie en kadertekenen.'#13#10 +
        '- Kan SnapToGrid, hulplijnen en rulers gebruiken.'#13#10 +
        '- Titel en werkgebied kunnen apart behandeld worden.',
        'Grid'#13#10#13#10 +
        '- Supports object placement, selection and frame drawing.'#13#10 +
        '- Can use SnapToGrid, guide lines and rulers.'#13#10 +
        '- Title and work area can be handled separately.',
        'Grille'#13#10#13#10 +
        '- Prend en charge le placement d''objets, la sélection et le dessin de cadre.'#13#10 +
        '- Peut utiliser SnapToGrid, des guides et des règles.'#13#10 +
        '- Le titre et la zone de travail peuvent être gérés séparément.',
        'Raster'#13#10#13#10 +
        '- Unterstützt Objektplatzierung, Auswahl und Rahmenzeichnen.'#13#10 +
        '- Kann SnapToGrid, Hilfslinien und Lineale verwenden.'#13#10 +
        '- Titel und Arbeitsbereich können getrennt behandelt werden.');
  else
    Result := TrHelp(ABTaal,
      'Geen specifieke help gevonden voor keyword: ' + AKeyword + #13#10#13#10 +
      'Verwachte helppagina:'#13#10 + BuildHelpTarget(AKeyword),
      'No specific help found for keyword: ' + AKeyword + #13#10#13#10 +
      'Expected help page:'#13#10 + BuildHelpTarget(AKeyword),
      'Aucune aide spécifique trouvée pour le mot-clé : ' + AKeyword + #13#10#13#10 +
      'Page d''aide attendue :'#13#10 + BuildHelpTarget(AKeyword),
      'Keine spezifische Hilfe für Schlüsselwort gefunden: ' + AKeyword + #13#10#13#10 +
      'Erwartete Hilfeseite:'#13#10 + BuildHelpTarget(AKeyword));
  end;
end;

procedure TAppHelpManager.ShowHelpForKeyword(const AKeyword: string);
var
  FN, S: string;
begin
  if Trim(AKeyword) = '' then
  begin
    MessageDlg('Help',
      TrHelp(FBTaal,
        'Geen HelpKeyword ingesteld.',
        'No HelpKeyword assigned.',
        'Aucun HelpKeyword défini.',
        'Kein HelpKeyword gesetzt.'),
      mtInformation, [mbOK], 0);
    Exit;
  end;

  FN := BuildHelpPageFileName(HelpPageForKeyword(AKeyword, S));

  if (FDisplayMode = hdmHTML) and FileExists(FN) then
  begin
    if Assigned(FOnOpenHelpFile) then
      FOnOpenHelpFile(BuildHelpTarget(AKeyword))
    else
      MessageDlg('Help',
        TrHelp(FBTaal,
          'Geen interne help-handler gekoppeld.'#13#10 + BuildHelpTarget(AKeyword),
          'No internal help handler assigned.'#13#10 + BuildHelpTarget(AKeyword),
          'Aucun gestionnaire d''aide interne défini.'#13#10 + BuildHelpTarget(AKeyword),
          'Kein interner Hilfe-Handler zugewiesen.'#13#10 + BuildHelpTarget(AKeyword)),
        mtInformation, [mbOK], 0);
    Exit;
  end;

  if Assigned(FOnGetHelpText) then
    S := FOnGetHelpText(AKeyword, FBTaal)
  else
    S := '';

  if Trim(S) = '' then
    S := GetBuiltInHelpText(AKeyword, FBTaal);

  MessageDlg('Help: ' + AKeyword, S, mtInformation, [mbOK], 0);
end;

procedure TAppHelpManager.ShowHelpForControl(AControl: TControl);
var
  C: TControl;
begin
  if not Assigned(AControl) then
  begin
    ShowTableOfContents;
    Exit;
  end;

  // Onderdelen worden pas tijdens het werken op het paneel gezet en hebben
  // dan nog geen HelpKeyword: die eerst toekennen.
  RegisterDefaultKeyword(AControl);

  C := FindNearestHelpControl(AControl);

  if Assigned(C) and (Trim(C.HelpKeyword) <> '') then
    ShowHelpForKeyword(C.HelpKeyword)
  else
    ShowTableOfContents;
end;

procedure TAppHelpManager.ShowHelpForObject(AObject: TObject);
begin
  if not Assigned(AObject) then
  begin
    ShowTableOfContents;
    Exit;
  end;

  if AObject is TControl then
    ShowHelpForControl(TControl(AObject))
  else
    ShowTableOfContents;
end;

procedure TAppHelpManager.ShowTableOfContents;
var
  FN: string;
begin
  FN := BuildHelpBaseFileName;

  if (FDisplayMode = hdmHTML) and FileExists(FN) then
  begin
    if Assigned(FOnOpenHelpFile) then
      FOnOpenHelpFile(FN)
    else
      MessageDlg('Help',
        TrHelp(FBTaal,
          'Geen interne help-handler gekoppeld.'#13#10 + FN,
          'No internal help handler assigned.'#13#10 + FN,
          'Aucun gestionnaire d''aide interne défini.'#13#10 + FN,
          'Kein interner Hilfe-Handler zugewiesen.'#13#10 + FN),
        mtInformation, [mbOK], 0);
  end
  else
    MessageDlg('Help',
      TrHelp(FBTaal,
        'Inhoudsopgave niet gevonden.'#13#10 + FN,
        'Table of contents not found.'#13#10 + FN,
        'Table des matières introuvable.'#13#10 + FN,
        'Inhaltsverzeichnis nicht gefunden.'#13#10 + FN),
      mtInformation, [mbOK], 0);
end;

procedure TAppHelpManager.RegisterDefaultKeyword(AControl: TControl);
var
  CN: string;
begin
  if not Assigned(AControl) then Exit;
  if Trim(AControl.HelpKeyword) <> '' then Exit;

  CN := LowerCase(AControl.ClassName);

  case CN of
    'tjansimbutton':    AControl.HelpKeyword := 'button';
    'tjansimknop':      AControl.HelpKeyword := 'schakelaar';
    'tjandipswitsh':    AControl.HelpKeyword := 'dipswitch';
    'tjansimpuls':      AControl.HelpKeyword := 'puls';
    'tjansimsensor':    AControl.HelpKeyword := 'sensor';
    'tjansimwarm':      AControl.HelpKeyword := 'warm';
    'tjanlogic':        AControl.HelpKeyword := 'logic';
    'tjanteller':       AControl.HelpKeyword := 'teller';
    'tjanmemory':       AControl.HelpKeyword := 'geheugen';
    'tjansimlight':     AControl.HelpKeyword := 'lamp';
    'tjansimrelais':    AControl.HelpKeyword := 'relais';
    'tjansimbuzzer':    AControl.HelpKeyword := 'zoemer';
    'tjandisplay':      AControl.HelpKeyword := 'display';
    'tjanmeter':        AControl.HelpKeyword := 'meter';
    'tjanconnector':    AControl.HelpKeyword := 'connector';
    'tjansimlogicbox':  AControl.HelpKeyword := 'logicbox';
    'tjangrids':        AControl.HelpKeyword := 'grid';
  end;
end;

procedure TAppHelpManager.RegisterDefaultKeywords(AParent: TWinControl);
var
  i: Integer;
  C: TControl;
begin
  if not Assigned(AParent) then Exit;

  for i := 0 to AParent.ControlCount - 1 do
  begin
    C := AParent.Controls[i];
    RegisterDefaultKeyword(C);

    if C is TWinControl then
      RegisterDefaultKeywords(TWinControl(C));
  end;
end;

procedure AssignHelpRecursive(AParent: TWinControl);
begin
  if Assigned(AppHelpManager) then
    AppHelpManager.RegisterDefaultKeywords(AParent);
end;

procedure ShowAppHelpForControl(AControl: TControl);
begin
  if Assigned(AppHelpManager) then
    AppHelpManager.ShowHelpForControl(AControl);
end;

procedure ShowAppHelpForObject(AObject: TObject);
begin
  if Assigned(AppHelpManager) then
    AppHelpManager.ShowHelpForObject(AObject);
end;

end.
