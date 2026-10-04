unit main;

{$mode objfpc}{$H+}

interface

uses
  {
  Windows, Classes, SysUtils, Forms, Controls, Graphics, IntfGraphics, FPImage,
  Dialogs, chatgridpcodeSmall, janSimLogic, InTex, VersionInfo,
  ComCtrls, ExtCtrls, IniFiles, LCLType, Buttons,
  LResources, StdCtrls, Menus, StrHolder, RxTextHolder, RTTIGrids, RTTICtrls,
  TypInfo, PropEdits, base64, ObjectInspector, GeneralProcedures, HtmlView,
  ScreenCapture,wcimgcbo, SMNetGradient, Tips, advancedPropertyGridComponent, }



  Classes, SysUtils, Forms, Controls, Graphics, IntfGraphics, FPImage,
  Dialogs, ComCtrls, Buttons,StrHolder, janSimLogic, chatgridpcodeSmall, InTex, SMNetGradient,
  ScreenCapture, wcimgcbo, SliderBars, AdvancedPropertyGridComponent, RxTextHolder, RTTIGrids, RTTICtrls,
  CEVersionInfo;//GeneralProcedures,
  // Frames om in te laden
//  FSettings;  //Keuze,
const
  IniFileName = 'taal.ini';

type

  { TmainForm }

  TmainForm = class(TForm)
    beslissen1: TStrHolder;
    BSettings: TSpeedButton;
    ColorBar1: TColorBar;
    DataGeheugenN: TStrHolder;
    DataTellerN: TStrHolder;
    Data_beslissen_en_tellerN: TStrHolder;
    Flags: TImageList;
    ImageList1: TImageList;
    InfoTextHolder_EN: TRxTextHolder;
    InfoTextHolder_NL: TRxTextHolder;
    InTex1: TInTex;
    Grid: TjanGridS;
    janScreenCapture1: TjanScreenCapture;
    Box: TjanSimLogicBox;
    janSimPuls1: TjanSimPuls;
    NetGradient2: TNetGradient;
    btClose: TSpeedButton;
    Status: TStatusBar;
    StringHolderTranslations: TStrHolder;
    Taal: TImageComboBox;
    VersionInfo: TCEVersionInfo;
    procedure BSettingsClick(Sender: TObject);
    procedure ColorBar1Change(Sender: TObject);
    procedure GridMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure GridMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure GridMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure btCloseClick(Sender: TObject);
    procedure TaalChange(Sender: TObject);

    function TranslateTab(const TabName: string; Lang: chatgridpcodeSmall.TLanguage): string;
    {
    procedure maaksettingsframe;
    procedure RemoveSettingsFrame(Sender: TObject);
    procedure killframes; }
  private
     temp:String;
  public
    constructor Create(AOwner: TComponent); override;
  public
      //KeuzeFrame:TKeuzeFrame;
  //  SettingsFrame:TSettingsFrame;

    // allerlei variable
   // fr_keuzebestaat:Boolean;
   // fr_Settingsbestaat:Boolean;
    moduscurrent:String;
  end;

var
  mainForm: TmainForm;
  Beweeg:Boolean;
  temp:String;

implementation

{$R *.lfm}

constructor TmainForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  //fr_keuzebestaat:=false;
  //fr_Settingsbestaat:=false;
  moduscurrent:='';

  // Form instellingen
  //BorderStyle := bsNone;
  Width := 825;
  Height := 600;
 // LoadLanguageSetting;

  // Koppel de Grid-muis events
 // Grid.OnMouseDown := @GridMouseDown;
 // Grid.OnMouseMove := @GridMouseMove;
 // Grid.OnMouseUp := @GridMouseUp;
end;
 //TALEN BEGIN
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


{ TmainForm }
{
procedure TmainForm.maaksettingsframe;
var
  centerleft: integer;
Begin
  SettingsFrame := TSettingsFrame.Create(nil);
  SettingsFrame.Hide;
  SettingsFrame.Height := 500;
  SettingsFrame.Width := 366;
  centerLeft := ((Grid.Width) div 2) - (SettingsFrame.Width div 2);
  SettingsFrame.Parent := Grid;
  SettingsFrame.SetBounds(centerLeft,Grid.Top + 8, SettingsFrame.Width,SettingsFrame.Height);

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
    mainform.Status.Panels.Items[0].Text:=moduscurrent;
    SettingsFrame.Note.ShowTabs:=true;
    fr_settingsbestaat := True;
    SettingsFrame.Show;
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
 {if fr_keuzebestaat = True then
  begin
    KeuzeFrame.Parent := self;
    KeuzeFrame.Free;
    KeuzeFrame := nil;
    fr_keuzebestaat := False;
    Grid.Repaint;
  end;}
 if fr_Settingsbestaat = True then
  begin
    SettingsFrame.Parent := self;
    SettingsFrame.Free;
    SettingsFrame := nil;
    fr_Settingsbestaat := False;
    Grid.Repaint;
  end;

 // Remise.Panel1.Caption := '';
 // Remise.Panel1.Repaint;
 // panel5.Visible := False;
end;}

//test van ColorBar1
procedure TmainForm.ColorBar1Change(Sender: TObject);
begin
  janSimPuls1.PulsInterval:=ColorBar1.Value;
  janSimPuls1.Starten:=False;
  janSimPuls1.Starten:=True;
end;
// einde test van ColorBar1

procedure TmainForm.BSettingsClick(Sender: TObject);
begin
 // killframes;
 // maaksettingsframe;
// TaalChange(self);
end;

procedure TmainForm.GridMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
wc:TWinControl;
Child:TControl;
a,b:integer;
beweeg:Boolean;
begin
//if fr_Settingsbestaat or fr_keuzebestaat then exit;
Status.Panels.Items[1].Text:=(Format('MouseDown van uit form at: X=%d, Y=%d', [X, Y]));
Application.HintPause:=50;
wc:=Box.Eigenaar;
b:= wc.ControlCount;
beweeg:= Box.NewObject;//  NewObject;
 if (b > 0) and (beweeg=true) then
  begin
    for a := wc.ControlCount - 1 downto 0 do
    begin
    Child := wc.controls[a];
    if Child.Tag= Box.ObjectID then
      begin
      Child.Left:= X +2;Child.top:=Y+2;
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
 // showMessage('vanuit GridMouseMove procedure');
//Timer1.Enabled:=false;Application.HintPause:=50;
temp:='';
wc:=box.Eigenaar;
b:= wc.ControlCount;
beweeg:=box.NewObject;
 if (b > 0) and (beweeg=true) then
  begin
    for a := wc.ControlCount - 1 downto 0 do
    begin
    Child := wc.controls[a];
    if Child.Tag= box.ObjectID then
      begin
      Child.Left:=x+2;Child.top:=Y+2;
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

procedure TmainForm.btCloseClick(Sender: TObject);
begin
  close;
end;

procedure TmainForm.TaalChange(Sender: TObject);
begin

end;



end.

