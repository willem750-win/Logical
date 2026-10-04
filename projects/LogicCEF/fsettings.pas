unit FSettings;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ComCtrls, Buttons, Dialogs,
  ExtCtrls, StrHolder, RxTextHolder, RTTIGrids, RTTICtrls,
  AdvancedPropertyGridComponent;

type

    TOnRemoveFrame = procedure(Sender: TObject) of object;

  { TSettingsFrame }

    TSettingsFrame = class(TFrame)
    InfoTextHolder_DU: TRxTextHolder;
    InfoTextHolder_EN: TRxTextHolder;
    InfoTextHolder_FR: TRxTextHolder;
    InfoTextHolder_NL: TRxTextHolder;
    iniBox: TStrHolder;
    iniBox_Hints: TStrHolder;
    iniBox_schakellelementen: TStrHolder;
    iniGrid: TStrHolder;
    Note: TPageControl;
    PropB2: TAdvancedPropertyGrid;
    PropB22: TAdvancedPropertyGrid;
    PropB222: TAdvancedPropertyGrid;
    StringHolderTranslations: TStrHolder;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;

  private
    FCloseButtons: TList;
    FOnRemove: TOnRemoveFrame;
    procedure CloseButtonClick(Sender: TObject);
  public
   constructor Create(TheOwner: TComponent); override;
   destructor Destroy; override;
   procedure LinkCloseButton(ACloseButton: TSpeedButton);
   property OnRemove: TOnRemoveFrame read FOnRemove write FOnRemove;
  end;

  var
    SettingsFrame: TSettingsFrame;

implementation

{$R *.lfm}

uses

  main;

{ TSettingsFrame }

Constructor TSettingsFrame.Create(TheOwner: TComponent);
begin
   inherited Create(TheOwner);
    Parent := TWinControl(TheOwner);
    FCloseButtons := TList.Create;
end;

destructor TSettingsFrame.Destroy;
begin
  FCloseButtons.Free;
  inherited Destroy;
end;

procedure TSettingsFrame.LinkCloseButton(ACloseButton: TSpeedButton);
begin
  if Assigned(ACloseButton) and (FCloseButtons.IndexOf(ACloseButton) = -1) then
  begin
    FCloseButtons.Add(Pointer(ACloseButton)); // Voeg toe als Pointer
    ACloseButton.OnClick := @CloseButtonClick;
  end;
end;

procedure TSettingsFrame.CloseButtonClick(Sender: TObject);
begin
  //showMessage('testklik '+ Sender.ClassName);
  mainForm.fr_settingsbestaat := false;
  if Assigned(FOnRemove) then
    FOnRemove(Self);

end;



end.

