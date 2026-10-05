unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Buttons, Graphics, Dialogs, ComCtrls,
  Menus,StrHolder, SMNetGradient, ScreenCapture, chatgridpcodeSmall,
  janSimLogic,AdvancedPropertyGridComponent, wcimgcbo, IniFiles,LCLIntf,LCLType,
  TypInfo, LCLProc, ExtCtrls, UTF8Process,  uHelpManager, uAbout,
  // De ingebouwde CEF-browser bestaat enkel onder Windows; onder Linux
  // wordt de help in de standaardbrowser van het systeem geopend.
  {$IFDEF WINDOWS}uMiniBrowser,{$ENDIF}
  // Frames om in te laden
  FSettings;
const
  IniFileName = 'taal.ini';

type

  { TmainForm }

  TmainForm = class(TForm)
    BCapture2: TSpeedButton;
    Box: TjanSimLogicBox;
    BSettings2: TSpeedButton;
    btClearConnectors: TSpeedButton;
    btClose1: TSpeedButton;
    btDelCurObject: TSpeedButton;
    btGrid: TSpeedButton;
    btGridguidelines: TSpeedButton;
    btGridkaders: TSpeedButton;
    btGridPanelTitel: TSpeedButton;
    btSimulate: TSpeedButton;
    btInfo2: TSpeedButton;
    btnSavePanel1: TSpeedButton;
    Grid: TjanGridS;
    ImageList2: TImageList;
    LGPanels1: TSpeedButton;
    btOpenPaneel1: TSpeedButton;
    beslissen1: TStrHolder;
    DataGeheugenN: TStrHolder;
    DataTellerN: TStrHolder;
    Data_beslissen_en_tellerN: TStrHolder;
    beslissenN: TStrHolder;
    Panel1: TPanel;
    Panel2: TPanel;
    SpeedButton1: TSpeedButton;
    brButton: TSpeedButton;
    StatusBar1: TStatusBar;
    Taal: TImageComboBox;
    test: TStrHolder;
    StringHolderTranslations: TStrHolder;
    Flags: TImageList;
    ImageList1: TImageList;
    janScreenCapture1: TjanScreenCapture;
    PPanels: TPopupMenu;
    MBeslissen: TMenuItem;
    MGeheugenpaneel: TMenuItem;
    MNieuwStandaardpaneel: TMenuItem;
    MTeller: TMenuItem;
    TitelBar2: TNetGradient;
    FObject: TComponent;



    procedure BCapture2MouseEnter(Sender: TObject);
    procedure BCaptureClick(Sender: TObject);
    procedure brButtonClick(Sender: TObject);
    procedure brButtonMouseEnter(Sender: TObject);
    procedure BSettings2MouseEnter(Sender: TObject);

    procedure BSettingsClick(Sender: TObject);
    procedure btClearConnectorsClick(Sender: TObject);
    procedure btClearConnectorsMouseEnter(Sender: TObject);

    procedure btCloseClick(Sender: TObject);
    procedure btDelCurObjectClick(Sender: TObject);
    procedure btDelCurObjectMouseEnter(Sender: TObject);


    procedure btGridClick(Sender: TObject);
    procedure btGridguidelinesClick(Sender: TObject);
    procedure btGridguidelinesMouseEnter(Sender: TObject);
    procedure btGridkadersClick(Sender: TObject);
    procedure btGridkadersMouseEnter(Sender: TObject);
    procedure btGridMouseEnter(Sender: TObject);
    procedure btGridPanelTitelMouseEnter(Sender: TObject);
    procedure btInfo2ChangeBounds(Sender: TObject);
    procedure btInfo2Click(Sender: TObject);
    procedure btInfo2MouseEnter(Sender: TObject);
    procedure btnSimulateClick(Sender: TObject);
    procedure btnSavePanelClick(Sender: TObject);
    procedure btOpenPaneelClick(Sender: TObject);
    procedure btGridPanelTitelClick(Sender: TObject);
    procedure btSimulateMouseEnter(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure GridClick(Sender: TObject);

    procedure GridMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure GridMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure GridMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure GridTitleClick(Sender: TObject);

    procedure LGPanelsClick(Sender: TObject);//openen van PPanels: TPopupMenu;
     //akties van PPanels popup items
    procedure MBeslissenClick(Sender: TObject);
    procedure MGeheugenpaneelClick(Sender: TObject);
    procedure MNieuwStandaardpaneelClick(Sender: TObject);
    procedure MTellerClick(Sender: TObject);

    procedure RemoveSettingsFrame(Sender: TObject);
    procedure maaksettingsframe;

    procedure killframes;
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton1MouseEnter(Sender: TObject);
    procedure StatusBar1DrawPanel(StatusBar: TStatusBar; Panel: TStatusPanel;
      const Rect: TRect);
    procedure DrawPanelIconAndShift(var AR: TRect; AImageIndex: Integer);
    procedure StatusBar1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure TaalChange(Sender: TObject);
    procedure SaveLanguageSetting;
    procedure LoadLanguageSetting;
    function StrHolderToStream(StrHolder: TStrHolder): TMemoryStream;
    function GetStatusBarPanelHint(APanelIndex: Integer): string;


    function TranslateTab(const TabName: string; Lang: chatgridpcodeSmall.TLanguage): string;
  private
    FBrowserProc: TProcessUTF8;
    FSBIcon: array[0..3] of Integer;  // -1 = geen icoon
     FRunMode: Boolean;
     FPanel0KindColor: TColor;   // kleur-indicator voor panel 0  afhankelijk van object-soort
     FPanel0HasKind  : Boolean;  // of we hem moeten tekenen
     FLastHelpObject: TObject;
     function GetProjectHelpText(const AKeyword, ABTaal: string): string;
     procedure UpdateLastHelpObject(AObj: TObject);
     procedure OpenHelpInMiniBrowser(const FileName: string);
  //  procedure StartBrowser(const AUrl: string);
  //  procedure StopBrowser;

    procedure BoxSelected(Sender: TObject; SelectedObj: TObject);
    procedure UpdateDeleteButtonVisual;
    procedure FreeObjAsync(Data: PtrInt);

    procedure BoxObjectMove(Sender: TObject; Obj: TControl; X, Y: Integer);
    procedure StatusFromLogicBox(Sender: TObject; const AText: string; APanel: Integer);
    function GetSoortFromObj(AObj: TObject): string;//newtest
    function IsSimObj(AObj: TObject): Boolean;
  public
     procedure LaadGridsettings;
     procedure LaadBoxsettings;
   public
    SettingsFrame:TSettingsFrame;
    // allerlei variable
    fr_Settingsbestaat:Boolean;
    moduscurrent:String;
    FCurrentSender: TObject;// testnu
  end;

var
  mainForm: TmainForm;
  Beweeg:Boolean;
  temp:String;
  OpslagFileName:String;

implementation

function BuildSimulateHint(
  ALanguage: chatgridpcodeSmall.TLanguage;
  ARunMode: Boolean): string;
begin
  case ALanguage of

    chatgridpcodeSmall.lgDutch:
      if ARunMode then
        Result := 'Stop simulatie'
      else
        Result := 'Start simulatie';

    chatgridpcodeSmall.lgEnglish:
      if ARunMode then
        Result := 'Stop simulation'
      else
        Result := 'Start simulation';

    chatgridpcodeSmall.lgFrench:
      if ARunMode then
        Result := 'Arrêter la simulation'
      else
        Result := 'Démarrer la simulation';

    chatgridpcodeSmall.lgGerman:
      if ARunMode then
        Result := 'Simulation stoppen'
      else
        Result := 'Simulation starten';

  else
    if ARunMode then
      Result := 'Stop simulation'
    else
      Result := 'Start simulation';
  end;
end;

function LangToBTaal(L: chatgridpcodeSmall.TLanguage): string;
begin
  case L of
    chatgridpcodeSmall.lgDutch:   Result := 'NL';
    chatgridpcodeSmall.lgEnglish: Result := 'ENG';
    chatgridpcodeSmall.lgFrench:  Result := 'FR';
    chatgridpcodeSmall.lgGerman:  Result := 'DU';
  else
    Result := 'NL';
  end;
end;

function MyTr(const ABTaal, NL, ENG, FR, DU: string): string;
begin
  if ABTaal = 'NL' then
    Result := NL
  else if ABTaal = 'ENG' then
    Result := ENG
  else if ABTaal = 'FR' then
    Result := FR
  else if ABTaal = 'DU' then
    Result := DU
  else
    Result := ENG;
end;

{$R *.lfm}

{ TmainForm }

function TmainForm.GetProjectHelpText(const AKeyword, ABTaal: string): string;
begin
  if SameText(AKeyword, 'logicbox') then
  begin
    Result := TrHelp(ABTaal,
      'LogicBox'#13#10#13#10 +
      '- Centrale container voor simulatie-objecten.'#13#10 +
      '- Beheert selectie, events en statusmeldingen.'#13#10 +
      '- Kan child-objecten blokkeren in runmode.',
      'LogicBox'#13#10#13#10 +
      '- Central container for simulation objects.'#13#10 +
      '- Manages selection, events and status messages.'#13#10 +
      '- Can block child objects in run mode.',
      'LogicBox'#13#10#13#10 +
      '- Conteneur central pour les objets de simulation.'#13#10 +
      '- Gère la sélection, les événements et les messages d''état.'#13#10 +
      '- Peut bloquer les objets enfants en mode exécution.',
      'LogicBox'#13#10#13#10 +
      '- Zentraler Container für Simulationsobjekte.'#13#10 +
      '- Verwaltet Auswahl, Ereignisse und Statusmeldungen.'#13#10 +
      '- Kann Kindobjekte im Run-Modus sperren.');
    Exit;
  end;

  Result := '';
end;

procedure TmainForm.UpdateLastHelpObject(AObj: TObject);
begin
  if Assigned(AObj) then
    FLastHelpObject := AObj;
end;

function TMainForm.StrHolderToStream(StrHolder: TStrHolder): TMemoryStream;
 var
  StringStream: TStringStream;

begin
  Result := TMemoryStream.Create; // Maak een nieuwe geheugenstream
  try
    StringStream := TStringStream.Create(StrHolder.Strings.Text, TEncoding.UTF8);
    try
      StringStream.Position := 0;
      Result.CopyFrom(StringStream, StringStream.Size);
      Result.Position := 0; // Reset de stream naar het begin
    finally
      StringStream.Free;
    end;
  except
    Result.Free; // Voorkom geheugenlekken bij fouten
    raise;
  end;
end;

function TmainForm.GetStatusBarPanelHint(APanelIndex: Integer): string;
var
  BTaalCode: string;
begin
  BTaalCode := LangToBTaal(Grid.Language);

  case APanelIndex of
    0:
      Result := MyTr(BTaalCode,
        'Toont de naam of info van het actieve object',
        'Shows the name or info of the active object',
        'Affiche le nom ou les infos de l''objet actif',
        'Zeigt den Namen oder die Infos des aktiven Objekts');
    1:
      Result := MyTr(BTaalCode,
        'Toont de actuele status of functie',
        'Shows the current status or function',
        'Affiche l''état actuel ou la fonction',
        'Zeigt den aktuellen Status oder die Funktion');
    2:
      Result := MyTr(BTaalCode,
        'Toont de X- en Y-positie van het huidige object',
        'Displays the X and Y position of the current object',
        'Affiche la position X et Y de l'+'objet actuel',
        'ZZeigt die X- und Y-Position des aktuellen Objekts an');
    3:
      Result := MyTr(BTaalCode,
        'Toont het type van het object',
        'Shows the object type',
        'Affiche le type de l''objet',
        'Zeigt den Typ des Objekts');
    4:
      Result := MyTr(BTaalCode,
        'Toont extra debuginformatie',
        'Shows extra debug information',
        'Affiche des informations de débogage supplémentaires',
        'Zeigt zusätzliche Debug-Informationen');


  else
    Result := MyTr(BTaalCode,
        'Statusbalk',
        'Status bar',
        'Barre d''état',
        'Statusleiste');
  end;
end;

function TmainForm.TranslateTab(const TabName: string; Lang: chatgridpcodeSmall.TLanguage): string;
begin
  case Lang of
    chatgridpcodeSmall.lgDutch:
      begin
        if TabName = 'Algemeen' then Result := 'Algemeen'
        else if TabName = 'SchakelElementen' then Result := 'Schakelelementen'
        else if TabName = 'Hints' then Result := 'Hints';
      end;
    chatgridpcodeSmall.lgEnglish:
      begin
        if TabName = 'Algemeen' then Result := 'General'
        else if TabName = 'SchakelElementen' then Result := 'Switch Elements'
        else if TabName = 'Hints' then Result := 'Hints';
      end;
    chatgridpcodeSmall.lgFrench:
      begin
        if TabName = 'Algemeen' then Result := 'Général'
        else if TabName = 'SchakelElementen' then Result := 'Éléments de commutation'
        else if TabName = 'Hints' then Result := 'Conseils';
      end;
    chatgridpcodeSmall.lgGerman:
      begin
        if TabName = 'Algemeen' then Result := 'Allgemein'
        else if TabName = 'SchakelElementen' then Result := 'Schaltereinheiten'
        else if TabName = 'Hints' then Result := 'Hinweise';
      end;
  else
    Result := TabName; // Fallback
  end;
end;

procedure TmainForm.BoxObjectMove(Sender: TObject; Obj: TControl; X, Y: Integer);
begin
  // Naam van het object + positie tonen
  StatusBar1.Panels.Items[2].Text := Format('%s  X=%d  Y=%d', [Obj.ClassName, X, Y]);
end;


procedure TmainForm.StatusFromLogicBox(Sender: TObject; const AText: string; APanel: Integer);
var
  src    : TObject;
  soortN : string;
  isClear: Boolean;
begin
  UpdateLastHelpObject(Sender);
  if (StatusBar1 = nil) then Exit;

  isClear := (Trim(AText) = '');

  // -----------------------------
  // 0) bron bepalen (1x, voor alle panels)
  // -----------------------------
  src := nil;
  if Sender is TjanSimLogicBox then
    src := TjanSimLogicBox(Sender).LastStatusSender
  else
    src := Sender;

  // -----------------------------
  // 1) Altijd eerst: state resetten bij leegmaken
  // -----------------------------
  if isClear then
  begin
    // Kleurblok panel 0 uit (BELANGRIJK: anders blijft blokje staan)
    FPanel0HasKind := False;
    FPanel0KindColor := clNone;

    // Icons resetten (optioneel maar meestal gewenst)
    if (APanel >= Low(FSBIcon)) and (APanel <= High(FSBIcon)) then
      FSBIcon[APanel] := -1;

    // Panel 3 leeg bij clear
    if (StatusBar1.Panels.Count > 3) then
      StatusBar1.Panels[3].Text := '';
  end;

  // -----------------------------
  // 2) Tekst zetten
  // -----------------------------
  if StatusBar1.Panels.Count > 0 then
  begin
    if (APanel >= 0) and (APanel < StatusBar1.Panels.Count) then
      StatusBar1.Panels[APanel].Text := AText;
  end
  else
    StatusBar1.SimpleText := AText;

  // -----------------------------
  // 2b) Panel 3: altijd ClassName tonen (bij niet-clear)
  // -----------------------------
  if (StatusBar1.Panels.Count > 3) then
  begin
    if not isClear then
    begin
      if Assigned(src) then
        StatusBar1.Panels[3].Text := src.ClassName
      else
        StatusBar1.Panels[3].Text := '';
    end
    else
      StatusBar1.Panels[3].Text := '';
  end;

  // -----------------------------
  // 3) Panel 0: kleur bepalen (alleen als er iets te tonen is)
  // -----------------------------
  if (APanel = 0) and (not isClear) then
  begin
    FSBIcon[0] := -1;

    FPanel0HasKind := False;
    FPanel0KindColor := clNone;
    soortN := '';
    if src is TjanSimButton then
      soortN := Trim(TjanSimButton(src).Soort)
    else if src is TjanSimKnop then
      soortN := Trim(TjanSimKnop(src).Soort)
    else if src is TjanSimSensor then
      soortN := Trim(TjanSimSensor(src).Soort)
    else if src is TjanSimWarm then
      soortN := Trim(TjanSimWarm(src).Soort)
    else if src is TjanSimPuls then
      soortN := Trim(TjanSimPuls(src).Soort)
    else if src is TjanDipSwitsh then
      soortN := Trim(TjanDipSwitsh(src).Soort)
    else if src is TjanLogic then
      soortN := Trim(TjanLogic(src).Soort)
    else if src is TjanTeller then
      soortN := Trim(TjanTeller(src).Soort)
    else if src is TjanMemory then
      soortN := Trim(TjanMemory(src).Soort)
    else if src is TjanSimLight then
      soortN := Trim(TjanSimLight(src).Soort)
    else if src is TjanSimRelais then
      soortN := Trim(TjanSimRelais(src).Soort)
    else if src is TjanSimBuzzer then
      soortN := Trim(TjanSimBuzzer(src).Soort)
    else if src is TjanDisplay then
      soortN := Trim(TjanDisplay(src).Soort);
          // aanpassen uibreiden type



    if SameText(soortN, 'Invoer') then
    begin
      FPanel0KindColor := Grid.ColorInput;
      FPanel0HasKind := True;
    end
    else if SameText(soortN, 'Verwerking') then
    begin
      FPanel0KindColor := Grid.ColorProcessing;
      FPanel0HasKind := True;
    end
    else if SameText(soortN, 'Uitvoer') then
    begin
      FPanel0KindColor := Grid.ColorOutput;
      FPanel0HasKind := True;
    end;
  end;

  // -----------------------------
  // 4) Icons panel 1..3 (alleen als er iets te tonen is)
  // -----------------------------
  if not isClear then
  begin
    case APanel of
      1:
        begin
          if (Trim(AText) = '1') or (Pos('= 1', AText) > 0) then
            FSBIcon[1] := 47
          else
            FSBIcon[1] := 48;
        end;
      2: FSBIcon[2] := 1;
      3: FSBIcon[3] := -1;
    end;
  end;
  StatusBar1.Invalidate;
end;

function TmainForm.GetSoortFromObj(AObj: TObject): string;
begin
  Result := '';
  if AObj is TjanSimButton then Exit(Trim(TjanSimButton(AObj).Soort));
  if AObj is TjanSimKnop   then Exit(Trim(TjanSimKnop(AObj).Soort));
  if AObj is TjanSimSensor then Exit(Trim(TjanSimSensor(AObj).Soort));
  if AObj is TjanSimWarm   then Exit(Trim(TjanSimWarm(AObj).Soort));
  if AObj is TjanSimPuls  then Exit(Trim(TjanSimPuls(AObj).Soort));
  if AObj is TjanDipSwitsh  then Exit(Trim(TjanDipSwitsh(AObj).Soort));
  if AObj is TjanLogic  then Exit(Trim(TjanLogic(AObj).Soort));
  if AObj is TjanTeller  then Exit(Trim(TjanTeller(AObj).Soort));
  if AObj is TjanMemory  then Exit(Trim(TjanMemory(AObj).Soort));
  if AObj is TjanSimLight  then Exit(Trim(TjanSimLight(AObj).Soort));
  if AObj is TjanSimRelais  then Exit(Trim(TjanSimRelais(AObj).Soort));
  if AObj is TjanSimBuzzer  then Exit(Trim(TjanSimBuzzer(AObj).Soort));
  if AObj is TjanDisplay  then Exit(Trim(TjanDisplay(AObj).Soort));
  // aanpassen
end;

function TmainForm.IsSimObj(AObj: TObject): Boolean;
begin
  Result :=
    (AObj is TjanSimButton) or
    (AObj is TjanSimKnop) or
    (AObj is TjanSimSensor) or
    (AObj is TjanSimWarm)or
    (AObj is TjanSimPuls) or
    (AObj is TjanDipSwitsh) or
    (AObj is TjanLogic)or
    (AObj is TjanTeller)or
    (AObj is TjanMemory) or
    (AObj is TjanSimLight)or
    (AObj is TjanSimRelais)or
    (AObj is TjanSimBuzzer)or
    (AObj is TjanDisplay);
  // aanpassen voor ander type
end;


procedure TMainForm.RemoveSettingsFrame(Sender: TObject);
begin
  if Sender = SettingsFrame then
  begin
    FreeAndNil(SettingsFrame); // Zorgt ervoor dat het object correct wordt vrijgegeven
  end;
end;



procedure TmainForm.killframes;
begin
 if fr_Settingsbestaat = True then
  begin
    SettingsFrame.Parent := self;
    SettingsFrame.Free;
    SettingsFrame := nil;
    fr_Settingsbestaat := False;
    Grid.Repaint;
  end;

end;
procedure TmainForm.SpeedButton1Click(Sender: TObject);
var
  P: TProcessUTF8;
  ExePath: string;
begin
 // StartBrowser('https://chatgpt.com');
//  StartBrowser('http://localhost');
end;

procedure TmainForm.SpeedButton1MouseEnter(Sender: TObject);
begin
 UpdateLastHelpObject(Sender);

end;

procedure TmainForm.StatusBar1DrawPanel(StatusBar: TStatusBar;
  Panel: TStatusPanel; const Rect: TRect);
var
  idx : Integer;
  R, RTxt, CBox : TRect;
  s   : string;
begin
  idx := Panel.Index;
  R   := Rect;
  s   := Panel.Text;

  // achtergrond + font per panel
  case idx of
    0:
    begin
      StatusBar.Canvas.Brush.Color := clCream;
      StatusBar.Canvas.FillRect(R);
      StatusBar.Canvas.Font.Color := clNavy;
      StatusBar.Canvas.Font.Style := [fsBold];
    end;

    1:
    begin
      StatusBar.Canvas.Brush.Color := clCream;
      StatusBar.Canvas.FillRect(R);
      StatusBar.Canvas.Font.Color := clRed;
      StatusBar.Canvas.Font.Style := [fsBold];
    end;

    2:
    begin
      StatusBar.Canvas.Brush.Color := clCream;
      StatusBar.Canvas.FillRect(R);
      StatusBar.Canvas.Font.Color := clGreen;
      StatusBar.Canvas.Font.Style := [fsBold];
    end;

    3:
    begin
      StatusBar.Panels.Items[3].Alignment:=taCenter;
      StatusBar.Canvas.Brush.Color := clYellow;
      StatusBar.Canvas.FillRect(R);
      StatusBar.Canvas.Font.Color := clGreen;
      StatusBar.Canvas.Font.Style := [fsBold];
    end;
  end;

  RTxt := R;

  // Panel 0: kleurblokje tekenen
  if (idx = 0) and FPanel0HasKind and (Trim(Panel.Text) <> '') then
  begin
    CBox.Left   := R.Left + 6;
    CBox.Right  := CBox.Left + 14;
    CBox.Top    := R.Top + 4;
    CBox.Bottom := R.Bottom - 4;

    StatusBar.Canvas.Brush.Color := FPanel0KindColor;
    StatusBar.Canvas.Pen.Color := clBlack;
    StatusBar.Canvas.Rectangle(CBox);
    //reset default color
    StatusBar.Canvas.Brush.Color:=clYellow;
    RTxt.Left := CBox.Right + 8; // tekst na blokje
  end;

  // Icons alleen voor panel 1..3 (panel 0 is kleurblokje)
  if (idx <> 0) and (idx >= Low(FSBIcon)) and (idx <= High(FSBIcon)) then
    DrawPanelIconAndShift(RTxt, FSBIcon[idx]);

  // tekst tekenen
  if idx = 3 then
    DrawText(StatusBar.Canvas.Handle, PChar(s), Length(s), RTxt,
      DT_LEFT or DT_VCENTER or DT_WORDBREAK)
  else
    DrawText(StatusBar.Canvas.Handle, PChar(s), Length(s), RTxt,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE);

end;

 procedure TmainForm.DrawPanelIconAndShift(var AR: TRect; AImageIndex: Integer);
 var
   x, y: Integer;
 begin
   if (AImageIndex < 0) or (AImageIndex >= ImageList1.Count) then Exit;

   x := AR.Left + 4;
   y := AR.Top + ((AR.Bottom - AR.Top) - ImageList1.Height) div 2;

   ImageList1.Draw(StatusBar1.Canvas, x, y, AImageIndex);

   // schuif tekstgebied naar rechts
   Inc(AR.Left, ImageList1.Width + 8);
 end;



 procedure TmainForm.StatusBar1MouseMove(Sender: TObject; Shift: TShiftState; X,
   Y: Integer);
 var
   i, Accumulator: Integer;
 begin
   Accumulator := 0;

   for i := 0 to StatusBar1.Panels.Count - 1 do
   begin
     Accumulator := Accumulator + StatusBar1.Panels[i].Width;
     if X < Accumulator then
     begin
       StatusBar1.Hint := GetStatusBarPanelHint(i);
       Break;
     end;
   end;
 end;




procedure TmainForm.maaksettingsframe;
var
  centerleft: integer;
Begin
  SettingsFrame := TSettingsFrame.Create(nil);
  SettingsFrame.Hide;
  SettingsFrame.Height := 500;
  SettingsFrame.Width := 366;
  SettingsFrame.Parent := Grid;

  SettingsFrame.Left := (Grid.Width  - SettingsFrame.Width)  div 2;
  SettingsFrame.Top  := (Grid.Height - SettingsFrame.Height +80) div 2;

  // Stel de verwijdercallback in
  SettingsFrame.OnRemove := @RemoveSettingsFrame;

     SettingsFrame.LinkCloseButton(settingsFrame.PropB2.FCloseButton);
     SettingsFrame.LinkCloseButton(SettingsFrame.PropB22.FCloseButton);
     SettingsFrame.LinkCloseButton(SettingsFrame.PropB222.FCloseButton);


  //  PropB2.InfoTextHolder:=InfoTextHolder_DU;
    SettingsFrame.PropB2.Note:= SettingsFrame.Note;  // Belangrijk om een capture te doen van PropB2
    SettingsFrame.PropB2.DefaultPropHolder:=SettingsFrame.iniGrid;
    SettingsFrame.PropB2.TranslationHolder:= SettingsFrame.StringHolderTranslations;
    SettingsFrame.PropB2.AddRelevantProperties('Color,ColorInput,ColorOutput,ColorProcessing,GridX,GridY,'+
                                  'DotColor,Titel,SavePicFormat,ShowGrid,Capture');
    SettingsFrame.PropB2.ConnectObject := mainForm.Grid;
    SettingsFrame.PropB2.Cols[0];
    //__________________________________
 //   PropB22.InfoTextHolder:=InfoTextHolder_NL;
    SettingsFrame.PropB22.Note:= SettingsFrame.Note;  // Belangrijk om een capture te doen van PropB22
    SettingsFrame.PropB22.DefaultPropHolder:=SettingsFrame.iniBox_schakellelementen;
    SettingsFrame.PropB22.TranslationHolder:=SettingsFrame.StringHolderTranslations;
    SettingsFrame.PropB22.AddRelevantProperties('KColor,KBuzzer,KDipSwitsh,KDisplay,KDraad,KDrukknop,KLamp,'+
                                  'KLogicAnd,KLogicNot,KLogicOr,KMemory,KPuls,KRelais,KSchakelaar,'+
                                  'KSensor,KTeller,KWarm,KDraad');
    SettingsFrame.PropB22.ConnectObject :=mainForm.Box;
    SettingsFrame.PropB22.Cols[0];
    //__________________________________
 //  PropB222.InfoTextHolder:=InfoTextHolder_NL;
    SettingsFrame.PropB222.Note:= SettingsFrame.Note;  // Belangrijk om een capture te doen van PropB222
    SettingsFrame.PropB222.DefaultPropHolder:=SettingsFrame.iniBox_Hints;
    SettingsFrame.PropB222.TranslationHolder:= SettingsFrame.StringHolderTranslations;
    SettingsFrame.PropB222.AddRelevantProperties('HBuzzer,HDipSwitsh,HDisplay,HDraad,HDrukknop,HLamp,'+
                                  'HLogicAnd,HLogicNot,HLogicOr,HMemory,HPuls,HRelais,HSchakelaar,'+
                                  'HSensor,HTeller,HWarm,ShowHint');
    SettingsFrame.PropB222.ConnectObject := mainForm.Box;
    SettingsFrame.PropB222.Cols[0];
    SettingsFrame.Note.ActivePageIndex:=0;
    SettingsFrame.Note.Pages[0].Show;// Propertys van TJanGridS(Grid)

    moduscurrent:='Settings';
    mainform.StatusBar1.Panels.Items[2].Text:=moduscurrent;
    SettingsFrame.Note.ShowTabs:=true;
    fr_settingsbestaat := True;
    SettingsFrame.Show;


end;


procedure TmainForm.SaveLanguageSetting;
var
  Ini: TIniFile;
begin
  // Naast het programma, niet in de huidige map (onder Linux is dat vaak ~).
  Ini := TIniFile.Create(ExtractFilePath(ParamStr(0)) + IniFileName);
  try
    Ini.WriteInteger('Settings', 'Language', Taal.ItemIndex);//  ItemIndex);
  finally
    Ini.Free;
  end;
end;

procedure TmainForm.LaadBoxsettings;
var
  Ini: TIniFile;
  IniPath, FileName: string;
  i, RowCount: Integer;
  PropName, PropValue: string;
begin
  // Pad naar .\ini\defaultgrid.ini
  IniPath  := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'ini';
  FileName := IncludeTrailingPathDelimiter(IniPath) + 'defaultschakel.ini';
  if not FileExists(FileName) then
  begin
    ShowMessage('defaultschakel.ini niet gevonden: ' + FileName);
    Exit;
  end;
  Ini := TIniFile.Create(FileName);
  try
    // Aantal properties lezen
    RowCount := Ini.ReadInteger('Settings', 'RowCount', 0);
    for i := 1 to RowCount do
    begin
      // Naam van de property
      PropName := Ini.ReadString('Properties',
                                 'Row' + IntToStr(i) + '_Name',
                                 '');
      if PropName = '' then
        Continue;
      // Waarde van de property
      PropValue := Ini.ReadString('Properties', PropName, '');

      if PropValue = '' then
        Continue;

      try
        // Zet de property direct op je Grid
        SetPropValue(Box, PropName, PropValue);
      except
        // ongeldige property negeren
      end;
    end;
    // Box direct hertekenen
    Box.Invalidate;
  finally
    Ini.Free;
  end;
end;
{
procedure TmainForm.StartBrowser(const AUrl: string);
var
  ExePath: string;
begin
  ExePath := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName)) + 'browser.exe';

  if not FileExists(ExePath) then
  begin
    ShowMessage('browser.exe niet gevonden: ' + ExePath);
    Exit;
  end;

  // Als hij al draait: eventueel niets doen, of opnieuw starten.
  if Assigned(FBrowserProc) and FBrowserProc.Running then
    Exit;

  FreeAndNil(FBrowserProc);

  FBrowserProc := TProcessUTF8.Create(nil);
  FBrowserProc.Executable := ExePath;
  FBrowserProc.Parameters.Add('--url=' + AUrl);

  // poNoConsole alleen als het bestaat (optioneel)
  {$IFDEF Windows}
  {$IF DECLARED(poNoConsole)}
  FBrowserProc.Options := [poNoConsole];
  {$ENDIF}
  {$ENDIF}

  FBrowserProc.Execute;
end;}
{
procedure TmainForm.StopBrowser;
begin
  if Assigned(FBrowserProc) then
  begin
    try
      if FBrowserProc.Running then
        FBrowserProc.Terminate(0); // forceert beëindigen van browser.exe
    except
      // negeren: afsluiten hoofdapp moet doorlopen
    end;

    FreeAndNil(FBrowserProc);
  end;
end;}
procedure TmainForm.LaadGridsettings;
var
  Ini: TIniFile;
  IniPath, FileName: string;
  i, RowCount: Integer;
  PropName, PropValue: string;
begin
  // Pad naar .\ini\defaultgrid.ini
  IniPath  := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'ini';
  FileName := IncludeTrailingPathDelimiter(IniPath) + 'defaultgrid.ini';

  if not FileExists(FileName) then
  begin
    ShowMessage('defaultgrid.ini niet gevonden: ' + FileName);
    Exit;
  end;

  Ini := TIniFile.Create(FileName);
  try
    // Aantal properties lezen
    RowCount := Ini.ReadInteger('Settings', 'RowCount', 0);

    for i := 1 to RowCount do
    begin
      // Naam van de property
      PropName := Ini.ReadString('Properties',
                                 'Row' + IntToStr(i) + '_Name',
                                 '');
      if PropName = '' then
        Continue;

      // Waarde van de property
      PropValue := Ini.ReadString('Properties', PropName, '');

      if PropValue = '' then
        Continue;

      try
        // Zet de property direct op je Grid
        SetPropValue(Grid, PropName, PropValue);
      except
        // ongeldige property negeren
      end;
    end;

    // Grid direct hertekenen
    Grid.Invalidate;
  finally
    Ini.Free;
  end;
end;


procedure TmainForm.LoadLanguageSetting;
var
  Ini: TIniFile;
  LanguageIndex: Integer;
begin
  Ini := TIniFile.Create(ExtractFilePath(ParamStr(0)) + IniFileName);
  try
    LanguageIndex := Ini.ReadInteger('Settings', 'Language', 0);
    if (LanguageIndex >= 0) and (LanguageIndex <= 3) then
      Taal.ItemIndex := LanguageIndex
    else
      Taal.ItemIndex := 0;
    // Roep direct de change event aan zodat alles wordt bijgewerkt
    TaalChange(Taal);
  finally
    Ini.Free;
  end;
end;

function ConvertTLanguage(lang: chatgridpcodeSmall.TLanguage): advancedPropertyGridComponent.TLanguage;
begin
  case lang of
    chatgridpcodeSmall.lgDutch:  Result := advancedPropertyGridComponent.lgDutch;
    chatgridpcodeSmall.lgEnglish: Result := advancedPropertyGridComponent.lgEnglish;
    chatgridpcodeSmall.lgFrench:  Result := advancedPropertyGridComponent.lgFrench;
    chatgridpcodeSmall.lgGerman:  Result := advancedPropertyGridComponent.lgGerman;
  else
    Result := advancedPropertyGridComponent.lgEnglish; // Standaardwaarde als failsafe
  end;
end;


 procedure TmainForm.TaalChange(Sender: TObject);
 var
   NieuweTaalChat: chatgridpcodeSmall.TLanguage;
   NieuweTaalPropGrid: AdvancedPropertyGridComponent.TLanguage;
   NieuweTaalStat: TStatTaal;
 begin
   // Converteer ComboBox selectie naar `TLanguage`
   case Taal.ItemIndex of
     0: NieuweTaalChat := chatgridpcodeSmall.lgDutch;
     1: NieuweTaalChat := chatgridpcodeSmall.lgEnglish;
     2: NieuweTaalChat := chatgridpcodeSmall.lgFrench;
     3: NieuweTaalChat := chatgridpcodeSmall.lgGerman;
   else
     NieuweTaalChat := chatgridpcodeSmall.lgDutch;
   end;

   // Zet de taal van Grid (WCIMGCBO.TLanguage)
   Grid.Language := NieuweTaalChat;

   // Wijs InfoTextHolder toe
   If fr_Settingsbestaat then
   Begin
     case NieuweTaalChat of
       chatgridpcodeSmall.lgDutch:
         begin
           SettingsFrame.PropB2.InfoTextHolder   := SettingsFrame.InfoTextHolder_NL;
           SettingsFrame.PropB22.InfoTextHolder  := SettingsFrame.InfoTextHolder_NL;
           SettingsFrame.PropB222.InfoTextHolder := SettingsFrame.InfoTextHolder_NL;
         end;
       chatgridpcodeSmall.lgEnglish:
         begin
           SettingsFrame.PropB2.InfoTextHolder   := SettingsFrame.InfoTextHolder_EN;
           SettingsFrame.PropB22.InfoTextHolder  := SettingsFrame.InfoTextHolder_EN;
           SettingsFrame.PropB222.InfoTextHolder := SettingsFrame.InfoTextHolder_EN;
         end;
       chatgridpcodeSmall.lgFrench:
         begin
           SettingsFrame.PropB2.InfoTextHolder   := SettingsFrame.InfoTextHolder_FR;
           SettingsFrame.PropB22.InfoTextHolder  := SettingsFrame.InfoTextHolder_FR;
           SettingsFrame.PropB222.InfoTextHolder := SettingsFrame.InfoTextHolder_FR;
         end;
       chatgridpcodeSmall.lgGerman:
         begin
           SettingsFrame.PropB2.InfoTextHolder   := SettingsFrame.InfoTextHolder_DU;
           SettingsFrame.PropB22.InfoTextHolder  := SettingsFrame.InfoTextHolder_DU;
           SettingsFrame.PropB222.InfoTextHolder := SettingsFrame.InfoTextHolder_DU;
         end;
     end;
   end;

   // Zet de taal van Box (TStatTaal)
   case NieuweTaalChat of
     chatgridpcodeSmall.lgDutch:   NieuweTaalStat := stDutch;
     chatgridpcodeSmall.lgEnglish: NieuweTaalStat := stEnglish;
     chatgridpcodeSmall.lgFrench:  NieuweTaalStat := stFrench;
     chatgridpcodeSmall.lgGerman:  NieuweTaalStat := stGerman;
   end;

   Box.SetBoxTaal(NieuweTaalStat);
   Box.ZetTaal;
     //  Box.RefreshStatusBarLanguage;
     Box.ApplyLanguageToGridChildren(NieuweTaalStat, Grid);
   // Converteer naar `TAdvancedPropertyGrid.TLanguage`
   NieuweTaalPropGrid := ConvertTLanguage(NieuweTaalChat);

   If fr_Settingsbestaat then
   Begin
     SettingsFrame.PropB2.SetLanguage(NieuweTaalPropGrid);
     SettingsFrame.PropB22.SetLanguage(NieuweTaalPropGrid);
     SettingsFrame.PropB222.SetLanguage(NieuweTaalPropGrid);

     if Assigned(SettingsFrame.PropB2) then SettingsFrame.PropB2.UpdateLanguageSelection(Taal.Text);
     if Assigned(SettingsFrame.PropB22) then SettingsFrame.PropB22.UpdateLanguageSelection(Taal.Text);
     if Assigned(SettingsFrame.PropB222) then SettingsFrame.PropB222.UpdateLanguageSelection(Taal.Text);

     SettingsFrame.Note.Pages[0].Caption := TranslateTab('Algemeen', NieuweTaalChat);
     SettingsFrame.Note.Pages[1].Caption := TranslateTab('SchakelElementen', NieuweTaalChat);
     SettingsFrame.Note.Pages[2].Caption := TranslateTab('Hints', NieuweTaalChat);
   end;

   // ... rest van je hints/captions:
  case NieuweTaalChat of
  chatgridpcodeSmall.lgDutch:
  begin
    Taal.Hint:='Kies taal...';
    BCapture2.Hint  := 'Schermkopie van paneel op het klembord...';
    btGrid.Hint    := 'Raster Ja/Nee'+ #13#10 +'Ga naar instellingen voor extra mogelijkheden...';
    btGridguidelines.Hint:= 'Richtlijnen op raster Ja/Nee...';
    btGridkaders.hint := 'Teken kader op raster...';
    btGridPanelTitel.hint:= 'Titel van paneel wijzigen...';
    BSettings2.Hint := 'Instellingen openen';
    btClose1.Hint   := 'Programma afsluiten';
    btInfo2.Hint    := 'Informatie...';
    btOpenPaneel1.Hint:='Open bewaard paneel...';
    btnSavePanel1.hint:= 'Bewaar paneel...';
    LGPanels1.Hint:='Klik hier voor paneel keuze...';
    btClearConnectors.Hint:= 'Verwijder verbindingen...';
    btDelCurObject.Hint:= 'Verwijder geselecteerd object...';
    btSimulate.Hint:='Start simulatie';

  end;

  chatgridpcodeSmall.lgEnglish:
  begin
    Taal.Hint:='Choose language...';
    BCapture2.Hint  := 'Copy the panel to the clipboard...';

    btGrid.Hint    := 'Grid Yes/No'+ #13#10 +'Go to open settings for additional options...';
    btGridguidelines.Hint:= 'Guidelines on grid YES/NO...';
    btGridkaders.hint := 'Draw frame on grid...';
    btGridPanelTitel.hint:= 'Change panel title...';

    BSettings2.Hint := 'Open settings';
    btClose1.Hint   := 'Close application';
    btInfo2.Hint    := 'Information...';
    btOpenPaneel1.Hint:='Open saved panel...';
    btnSavePanel1.hint:= 'Save panel...';
    LGPanels1.Hint:='Click here to select the panel...';
    btClearConnectors.Hint:= 'Remove connections...';
    btDelCurObject.Hint:= 'Delete selected object...';
    btSimulate.Hint:='Start simulation';
  end;

  chatgridpcodeSmall.lgFrench:
  begin
    Taal.Hint:='Choisissez la langue...';
    BCapture2.Hint  := 'Copiez le panneau dans le presse-papiers...';

    btGrid.Hint    := 'Grille Oui/Non'+ #13#10 +'Accéder aux paramètres pour plus options...';
    btGridguidelines.Hint:= 'Lignes directrices sur la grille OUI/NON...';
    btGridkaders.hint := 'Tracer un cadre sur la grille...';
    btGridPanelTitel.hint:= 'Changer le titre du panneau...';

    BSettings2.Hint := 'Ouvrir les paramètres';
    btClose1.Hint   := 'Fermer l''application';
    btInfo2.Hint    := 'Information...';
    btOpenPaneel1.Hint:='Ouvrir le panneau enregistré...';
    btnSavePanel1.hint:= 'Panneau conservé....';
    LGPanels1.Hint:='Cliquez ici pour sélectionner le panneau...';
    btClearConnectors.Hint:= 'Supprimer les connexions...';
    btDelCurObject.Hint:= 'Ausgewähltes Objekt löschen...';
    btSimulate.Hint:='Démarrer la simulation';
  end;

  chatgridpcodeSmall.lgGerman:
  begin
    Taal.Hint:='Sprache wählen...';
    BCapture2.Hint  := 'Kopieren Sie das Bedienfeld in die Zwischenablage...';

    btGrid.Hint    := 'Raster Ja/Nein'+ #13#10 +'Gehen Sie zu den Einstellungen, um weitere Optionen zu erhalten...';
    btGridguidelines.Hint:= 'Richtlinien zum Raster JA/NEIN...';
    btGridkaders.hint := 'Zeichne einen Rahmen auf das Raster...';
    btGridPanelTitel.hint:= 'Paneltitel ändern...';

    BSettings2.Hint := 'Einstellungen öffnen...';
    btClose1.Hint   := 'Anwendung schließen...';
    btInfo2.Hint    := 'Information...';
    btOpenPaneel1.Hint:='Gespeichertes Panel öffnen...';
    btnSavePanel1.hint:= 'Konserviertes Panel...';
    LGPanels1.Hint:='Klicken Sie hier, um das Bedienfeld auszuwählen...';
    btClearConnectors.Hint:= 'Verbindungen entfernen...';
    btDelCurObject.Hint:= 'Ausgewähltes Objekt löschen...';
    btSimulate.Hint:='Simulation starten';
  end;
end;

  if Assigned(AppHelpManager) then
  AppHelpManager.BTaal := LangToBTaal(Grid.Language);

   SaveLanguageSetting;
 end;



procedure TmainForm.BSettingsClick(Sender: TObject);
begin
  // zeker zijn: geen nieuw object meer in slep-modus
  Box.NewObject := False;
  killframes;
  maaksettingsframe;
  TaalChange(self);
end;

procedure TmainForm.btClearConnectorsClick(Sender: TObject);
begin
  Box.KillConnectors;
end;

procedure TmainForm.btClearConnectorsMouseEnter(Sender: TObject);
begin
  UpdateLastHelpObject(Sender);
end;

procedure TmainForm.btCloseClick(Sender: TObject);
begin
  close;
end;


procedure TmainForm.UpdateDeleteButtonVisual;
begin
  if btDelCurObject.Enabled then
  begin
    btDelCurObject.Color := clRed;
    btDelCurObject.Font.Color := clWhite;
  end
  else
  begin
    btDelCurObject.Color := clGradientActiveCaption;
    btDelCurObject.Font.Color := clBlack;
  end;
end;

procedure TmainForm.BoxSelected(Sender: TObject; SelectedObj: TObject);
var
  s: string;
begin
   UpdateLastHelpObject(SelectedObj);
  btDelCurObject.Enabled := Assigned(SelectedObj);

  if not Assigned(SelectedObj) then
  begin
    btDelCurObject.Hint := '';
    UpdateDeleteButtonVisual;
    Exit;
  end;

  s := '';

  if SelectedObj is TjanSimButton then
    s := TjanSimButton(SelectedObj).Naam
  else if SelectedObj is TjanSimKnop then
    s := TjanSimKnop(SelectedObj).Naam
  else if SelectedObj is TjanSimSensor then
    s := TjanSimSensor(SelectedObj).Naam
  else if SelectedObj is TjanSimWarm then
    s := TjanSimWarm(SelectedObj).Naam
  else if SelectedObj is TjanSimPuls then
    s := TjanSimPuls(SelectedObj).Naam
  else if SelectedObj is TjanDipSwitsh then
    s := TjanDipSwitsh(SelectedObj).Naam
 else if SelectedObj is TjanLogic then
    s := TjanLogic(SelectedObj).Naam
  else if SelectedObj is TjanTeller then
    s := TjanTeller(SelectedObj).Naam
  else if SelectedObj is TjanMemory then
    s := TjanMemory(SelectedObj).Naam
  else if SelectedObj is TjanSimLight then
    s := TjanSimLight(SelectedObj).Naam
  else if SelectedObj is TjanSimRelais then
    s := TjanSimRelais(SelectedObj).Naam
  else if SelectedObj is TjanSimBuzzer then
    s := TjanSimBuzzer(SelectedObj).Naam
  else if SelectedObj is TjanDisplay then
    s := TjanDisplay(SelectedObj).Naam;
  btDelCurObject.Hint := 'Verwijder geselecteerd: ' + s;
        // aanpassen / uitbreiden

  UpdateDeleteButtonVisual;
end;

procedure TmainForm.FreeObjAsync(Data: PtrInt);
begin
  TObject(Data).Free;
end;

procedure TmainForm.btDelCurObjectClick(Sender: TObject);
var
  Obj: TObject;
  C  : TControl;
begin
  Obj := Box.SelectedSender;
  if not Assigned(Obj) then Exit;

  if not (Obj is TControl) then Exit;
  C := TControl(Obj);

  // alleen jouw reeks toestaan
  if not ((C is TjanSimButton) or (C is TjanSimKnop) or (C is TjanSimSensor) or
         (C is TjanSimWarm)  or (C is TjanSimPuls) or (C is TjanDipSwitsh) or
         (C is TjanDipSwitsh) or (C is TjanLogic) or (C is TjanTeller) or
         (C is TjanMemory) or (C is TjanSimLight) or (C is TjanSimRelais) or
         (C is TjanSimBuzzer) or (C is TjanDisplay))  then
    Exit;
    // aanpassen om object te kunnen verwijderen

  // selection + current wissen
  Box.ClearSelectedSender;
  BoxSelected(Box, nil);
  FCurrentSender := nil;
  UpdateDeleteButtonVisual;
  // statusbar leeg
  StatusFromLogicBox(Self, '', 0);
  StatusFromLogicBox(Self, '', 1);
  StatusFromLogicBox(Self, '', 2);
  StatusFromLogicBox(Self, '', 3);

  // veilig verwijderen (geen event-recursie/AV)
  Application.QueueAsyncCall(@FreeObjAsync, PtrInt(C));
end;

procedure TmainForm.btDelCurObjectMouseEnter(Sender: TObject);
begin
  UpdateLastHelpObject(Sender);
end;



procedure TmainForm.btGridClick(Sender: TObject);
begin
   if (Grid.ShowGrid=True) then
     Grid.ShowGrid:=false
   else
     Grid.ShowGrid:=True;
   Grid.Refresh;
end;

procedure TmainForm.btGridguidelinesClick(Sender: TObject);
begin
  If Grid.GuideLinesAll then  Grid.GuideLinesAll:=false else Grid.GuideLinesAll:=true;Invalidate;
end;

procedure TmainForm.btGridguidelinesMouseEnter(Sender: TObject);
begin
  UpdateLastHelpObject(Sender);
end;

procedure TmainForm.btGridkadersClick(Sender: TObject);
begin
   Grid.GridMode := gmFrameDraw;
end;

procedure TmainForm.btGridkadersMouseEnter(Sender: TObject);
begin
  UpdateLastHelpObject(Sender);
end;

procedure TmainForm.btGridMouseEnter(Sender: TObject);
begin
  UpdateLastHelpObject(Sender);
end;

procedure TmainForm.btGridPanelTitelMouseEnter(Sender: TObject);
begin
  UpdateLastHelpObject(Sender);
end;

procedure TmainForm.btInfo2ChangeBounds(Sender: TObject);
begin

end;

procedure TmainForm.btInfo2Click(Sender: TObject);
begin
  ShowAbout(Grid.Language);
end;

procedure TmainForm.btInfo2MouseEnter(Sender: TObject);
begin
  UpdateLastHelpObject(Sender);
end;

procedure TmainForm.btnSimulateClick(Sender: TObject);
var
  huidigeGuidelines:Boolean;

begin
 huidigeGuideLines:= Grid.GuideLinesAll;
  FRunMode := btSimulate.Down;

  if Assigned(Box) then
    Box.BlokkeerObjecten(FRunMode);

  if FRunMode then
  begin
    btSimulate.ImageIndex:=1;
    btSimulate.Color:=clRed;
    btSimulate.Hint := BuildSimulateHint(Grid.Language, True);
    Grid.Box := False;
    Grid.GuideLinesAll := False;
    Box.Visible := False;
    Panel1.Visible:=false;
    Grid.ShowRulers:=false;
    Panel2.Visible:=false;
    {btDelCurObject.Visible:=False;
    btClearConnectors.Visible:=False;
    btGrid.Visible:=False;
    btGridguidelines.Visible:=False;
    btGridkaders.Visible:=False;
    btGridPanelTitel.Visible:=False;
    BSettings2.Visible:=False;}
  end
  else
  begin
    btSimulate.ImageIndex:=0;
    btSimulate.Color:=clGreen;
    btSimulate.Hint := BuildSimulateHint(Grid.Language, False);
    Grid.Box := True;
    Grid.GuideLinesAll := huidigeGuidelines;//True;
    Box.Visible := True;
    Panel1.Visible:=True;
    Grid.ShowRulers:=True;

    Panel2.Visible:=True;
  {  btDelCurObject.Visible:=True;
    btClearConnectors.Visible:=True;
    btGrid.Visible:=True;
    btGridguidelines.Visible:=True;
    btGridkaders.Visible:=True;
    btGridPanelTitel.Visible:=True;
    BSettings2.Visible:=True;}

  end;
end;

procedure TmainForm.btnSavePanelClick(Sender: TObject);
var
  saveDialog : TSaveDialog;    // Save dialog variable
  baseDir,panelsDir: string;
begin
  baseDir   := ExtractFilePath(ParamStr(0));
  panelsDir := IncludeTrailingPathDelimiter(baseDir) + 'panels';
  saveDialog := TSaveDialog.Create(self);
  saveDialog.Title := 'Opslaan Panel';
  saveDialog.InitialDir := panelsDir;
  saveDialog.Filter := '*.lpl';
  saveDialog.DefaultExt := 'lpl';
  saveDialog.FilterIndex := 1;
  savedialog.FileName:=OpslagFileName;
  saveDialog.Options:=[ofOverwritePrompt];
  if saveDialog.Execute then
    box.SavePanel(saveDialog.FileName,Grid,false);

  saveDialog.Free;
end;

procedure TmainForm.btOpenPaneelClick(Sender: TObject);
var
  OpenDialog : TOpenDialog;
  baseDir,panelsDir: string;
begin
  baseDir   := ExtractFilePath(ParamStr(0));
  panelsDir := IncludeTrailingPathDelimiter(baseDir) + 'panels';

  OpenDialog := TOpenDialog.Create(self);
  OpenDialog.Title := 'Open Panel';
  OpenDialog.InitialDir := panelsDir;
  OpenDialog.Filter := '*.lpl';
  OpenDialog.DefaultExt := 'lpl';
  OpenDialog.FilterIndex := 1;
  if OpenDialog.Execute then
       begin
       Box.LoadPanel(OpenDialog.FileName,Grid,false) ;
       end;
 // OpslagFile:=ExtractFileName(OpenDialog.FileName);
 OpslagFileName:= OpenDialog.FileName;

end;

procedure TmainForm.btGridPanelTitelClick(Sender: TObject);
begin
  GridTitleClick(Grid);
end;

procedure TmainForm.btSimulateMouseEnter(Sender: TObject);
begin
  UpdateLastHelpObject(Sender);
end;

procedure TmainForm.FormActivate(Sender: TObject);
begin
   LoadLanguageSetting;
   TitelBar2.Caption:='';
end;

procedure TmainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  { SaveLanguageSetting;
  if Assigned(MiniBrowserFrm) then
    Begin

    MiniBrowserFrm.Close;
    end;}
   SaveLanguageSetting;

  {$IFDEF WINDOWS}
  if Assigned(MiniBrowserFrm) then
    MiniBrowserFrm.Hide;
  {$ENDIF}
end;

procedure TmainForm.FormCreate(Sender: TObject);
begin
  Box.OnStatusText := @StatusFromLogicBox;
  Box.OnObjectMove := @BoxObjectMove;
  Box.OnSelected := @BoxSelected;

  Grid.OnMouseMove := @GridMouseMove;

  Application.HintColor := clYellow;
  // Zwarte hinttekst. Zolang HintFont gelijk is aan het systeemfont tekent
  // de LCL de tekst in de themakleur van tooltips; onder Linux (GTK2) is
  // die vaak wit, wat op de gele achtergrond onleesbaar is.
  Screen.HintFont.Color := clBlack;
  Application.HintPause := 0;
  Application.HintHidePause := 5000;

  FSBIcon[0] := -1;
  FSBIcon[1] := -1;
  FSBIcon[2] := -1;
  FSBIcon[3] := -1;

  FPanel0KindColor := clNone;
  FPanel0HasKind := False;

  btDelCurObject.Enabled := False;
  btDelCurObject.ShowHint := True;

  FRunMode := False;
  btSimulate.GroupIndex := 1;
  btSimulate.AllowAllUp := True;
  btSimulate.NumGlyphs := 2;
  btSimulate.Down := False;

  AppHelpManager := TAppHelpManager.Create(Self);
  AppHelpManager.HelpPath := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)) + 'help');
  AppHelpManager.DisplayMode := hdmHTML;
  AppHelpManager.BTaal := 'NL';
  AppHelpManager.OnGetHelpText := @GetProjectHelpText;
  AppHelpManager.OnOpenHelpFile := @OpenHelpInMiniBrowser;

  KeyPreview := True;
  AssignHelpRecursive(Self);

  //  HelpKeyword
  Grid.HelpKeyword := 'raster';
  Box.HelpKeyword := 'logicbox';
  SpeedButton1.HelpKeyword := 'sbutton1';
  btSimulate.HelpKeyword := 'simulate';
  btDelCurObject.HelpKeyword := 'delete_selected';
  btGrid.HelpKeyword := 'grid';
  BSettings2.HelpKeyword := 'settings';
  brButton.HelpKeyword := 'browser';
  // Overige knoppen: zie TAppHelpManager.HelpPageForKeyword voor de koppeling
  // met de helppagina's.
  btOpenPaneel1.HelpKeyword := 'openen';
  btnSavePanel1.HelpKeyword := 'opslaan';
  BCapture2.HelpKeyword := 'schermkopie';
  LGPanels1.HelpKeyword := 'paneelkeuze';
  btInfo2.HelpKeyword := 'info';
  btClose1.HelpKeyword := 'afsluiten';
  btClearConnectors.HelpKeyword := 'draden';
  btGridguidelines.HelpKeyword := 'richtlijnen';
  btGridkaders.HelpKeyword := 'kader';
  btGridPanelTitel.HelpKeyword := 'titel';
  Taal.HelpKeyword := 'taal';
end;

procedure TmainForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  HelpCtrl: TControl;
begin
  if Key = VK_F1 then
  begin
    Key := 0;

    // Eerst het onderdeel of de knop recht onder de muis.
    HelpCtrl := FindControlAtPosition(Mouse.CursorPos, True);
    if Assigned(HelpCtrl) and (HelpCtrl <> Self) then
      ShowAppHelpForControl(HelpCtrl)
    else if Assigned(Box) and Assigned(Box.LastStatusSender) then
      ShowAppHelpForObject(Box.LastStatusSender)
    else if Assigned(FLastHelpObject) then
      ShowAppHelpForObject(FLastHelpObject)
    else if Assigned(ActiveControl) then
      ShowAppHelpForControl(ActiveControl)
    else
      AppHelpManager.ShowTableOfContents;
  end;
end;

procedure TmainForm.FormShow(Sender: TObject);
begin
 LaadGridsettings;
 LaadBoxsettings;

end;

procedure TmainForm.GridClick(Sender: TObject);
begin

end;



procedure TmainForm.BCaptureClick(Sender: TObject);
begin
  janScreenCapture1.CaptureToClipboard;
end;

procedure TmainForm.BCapture2MouseEnter(Sender: TObject);
begin
  UpdateLastHelpObject(Sender);
end;

procedure TmainForm.brButtonClick(Sender: TObject);
begin
  // Help-startpagina in de gekozen taal openen: onder Windows in de
  // ingebouwde browser, onder Linux in de systeembrowser
  // (via OpenHelpInMiniBrowser).
  if Assigned(AppHelpManager) then
    AppHelpManager.ShowTableOfContents;
end;

procedure TmainForm.brButtonMouseEnter(Sender: TObject);
begin
  UpdateLastHelpObject(Sender);
end;

procedure TmainForm.BSettings2MouseEnter(Sender: TObject);
begin
  UpdateLastHelpObject(Sender);
end;


procedure TmainForm.OpenHelpInMiniBrowser(const FileName: string);
var
  URL: string;
begin
  {$IFDEF WINDOWS}
  if not Assigned(MiniBrowserFrm) then
    MiniBrowserFrm := TMiniBrowserFrm.Create(Application);

  URL := 'file:///' + StringReplace(FileName, '\', '/', [rfReplaceAll]);
  MiniBrowserFrm.LoadURLString(URL);
  {$ELSE}
  // FileName is een absoluut pad (/home/...), eventueel met #anker.
  URL := 'file://' + FileName;
  if not OpenURL(URL) then
    ShowMessage('Kan de help niet openen:' + LineEnding + FileName);
  {$ENDIF}
end;

procedure TmainForm.GridMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
wc:TWinControl;
Child:TControl;
a,b:integer;
beweeg:Boolean;
begin
if fr_Settingsbestaat then exit;
wc:=box.Eigenaar;
b:= wc.ControlCount;
beweeg:= Box.NewObject;//  NewObject;
 if (b > 0) and (beweeg=true) then
  begin
    for a := wc.ControlCount - 1 downto 0 do
    begin
    Child := wc.controls[a];
    if Child.Tag= Box.ObjectID then
      begin
      Child.Left:= X + 2;Child.top:=Y+2;
      end;
    end;
   end;

end;

procedure TmainForm.GridMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
  wc:TWinControl;
  Child:TControl;
  a,b:integer;
begin
  temp := '';
  wc := box.Eigenaar;
  b  := wc.ControlCount;
  beweeg := box.NewObject;
  if (b > 0) and (beweeg = True) then
  begin
    for a := wc.ControlCount - 1 downto 0 do
    begin
      Child := wc.Controls[a];
      if Child.Tag = box.ObjectID then
      begin
        Child.Left := X + 2;
        Child.Top  := Y + 2;
      end;
    end;
  end;

end;



procedure TmainForm.GridMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
wc:TWinControl;
a,b:integer;
Child:TControl;
begin
wc:=Box.Eigenaar;
b:= wc.ControlCount;
Box.NewObject:=false;
 if b > 0 then
  begin
     for a := wc.ControlCount - 1 downto 0 do
     begin
       Child := wc.controls[a];Child.visible:=true;screen.cursor:=crDefault;
     end;
  end;
if Grid.Capture then   Grid.CaptureSelectedRegion;

end;


procedure TmainForm.GridTitleClick(Sender: TObject);
var
  S, CapTxt, PromptTxt: string;
  G: TjanGridS;
begin
  if not (Sender is TjanGridS) then
    Exit;

  G := TjanGridS(Sender);

  case G.Language of
    chatgridpcodeSmall.lgDutch:
      begin
        CapTxt := 'Titel wijzigen';
        PromptTxt := 'Geef nieuwe titel:';
      end;

    chatgridpcodeSmall.lgEnglish:
      begin
        CapTxt := 'Change title';
        PromptTxt := 'Enter new title:';
      end;

    chatgridpcodeSmall.lgFrench:
      begin
        CapTxt := 'Modifier le titre';
        PromptTxt := 'Entrez le nouveau titre :';
      end;

    chatgridpcodeSmall.lgGerman:
      begin
        CapTxt := 'Titel ändern';
        PromptTxt := 'Neuen Titel eingeben:';
      end;
  else
    begin
      CapTxt := 'Change title';
      PromptTxt := 'Enter new title:';
    end;
  end;

  S := InputBox(CapTxt, PromptTxt, G.Titel);
  if Trim(S) = '' then
  G.Titel := ''
else
  G.Titel := Trim(S);
end;


procedure TmainForm.LGPanelsClick(Sender: TObject);
var
  P: TPoint;
begin
  // Linker-onderhoek van de button bepalen
  P := Point(LGPanels1.Left, LGPanels1.Top + LGPanels1.Height+25);
  // Omzetten naar schermcoördinaten
  P := LGPanels1.Parent.ClientToScreen(P);
  // PopupMenu openen op locatie P
  PPanels.PopUp(P.X, P.Y);

end;

procedure TmainForm.MBeslissenClick(Sender: TObject);
 var
  FStream: TMemoryStream;
begin
  Box.Killpanel; Box.KillConnectors;
  // zeker zijn: geen nieuw object meer in slep-modus
  Box.NewObject := False;
//  LGPanels1.Caption:=''; LGPanels1.Caption:='Beslissingspaneel';LGPanels1.Refresh;
  // Box.maakpanel; wordt intern inTjanSimLogic gemaakt via procedure
 FStream := StrHolderToStream(beslissenN);
  try
  //  Box.LoadStream(FStream, False);
     Box.LoadStreamNew(FStream, Grid,False);
  finally
    FStream.Free;
  end;
  Grid.Titel:='';Grid.Titel:='Beslissingspaneel';
end;

procedure TmainForm.MGeheugenpaneelClick(Sender: TObject);
var
  FStream: TMemoryStream;
begin
  Box.Killpanel; Box.KillConnectors;
  // zeker zijn: geen nieuw object meer in slep-modus
  Box.NewObject := False;
 // LGPanels1.Caption:=''; LGPanels1.Caption:='Geheugenpaneel';LGPanels1.Refresh;
  FStream := StrHolderToStream(DataGeheugenN);
  try
    //Box.LoadStream(FStream, False);
    Box.LoadStreamNew(FStream, Grid,False);
  finally
    FStream.Free;
  end;
  Grid.Titel:='';Grid.Titel:='Geheugenpaneel';
end;

procedure TmainForm.MNieuwStandaardpaneelClick(Sender: TObject);
begin
  Box.Killpanel; Box.KillConnectors;
  // zeker zijn: geen nieuw object meer in slep-modus
  Box.NewObject := False;
  box.open:=true;box.Enabled:=true;
//  LGPanels1.Caption:=''; LGPanels1.Caption:='Nieuw Standaardpaneel';LGPanels1.Refresh;
  Grid.Titel:='';Grid.Titel:='Nieuw Standaardpaneel';
end;

procedure TmainForm.MTellerClick(Sender: TObject);
var
  FStream: TMemoryStream;
begin
  Box.Killpanel; Box.KillConnectors;
  // zeker zijn: geen nieuw object meer in slep-modus
  Box.NewObject := False;
  FStream := StrHolderToStream(DataTellerN);
  try
    //Box.LoadStream(FStream, False);
    Box.LoadStreamNew(FStream,Grid,False);
  finally
    FStream.Free;
  end;
 // LGPanels1.Caption:=''; LGPanels1.Caption:='Tellerpaneel';LGPanels1.Refresh;
  Grid.Titel:='';Grid.Titel:='Tellerpaneel';
end;



end.

