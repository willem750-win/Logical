unit chatgridpcode;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  LCLIntf, LCLType,// LMessages,
  Graphics, Controls, Forms, Dialogs,
  ExtCtrls, ComCtrls, Clipbrd,
  janSimLogic;
  //StdCtrls,
type
  TSaveFormat = (sfBMP, sfJPG, sfPNG, sfClipbrd);

  TjanGrid = class(TPanel)
  private
    FToolBar: TToolBar;          // ToolBar for buttons
    FLogicBox: TjanSimLogicBox;
    FShowGrid: Boolean;
    FGridX, FGridY: NativeInt;
    FGridColor: TColor;
    FSnapToGrid: Boolean;
    FIsDrawing: Boolean;
    FRect: TRect;                // Current selection rectangle

    // External event handlers
    FOnMouseDown: TMouseEvent;
    FOnMouseMove: TMouseMoveEvent;
    FOnMouseUp: TMouseEvent;
    // Toevoeging colors TjanGrid
    FStatusBarHeight: NativeInt;
    FColorInput: TColor;
    FColorProcessing: TColor;
    FColorOutput: TColor;

    FStatus: TStatusBar;

    FInputText: string;
    FProcessingText: string;
    FOutputText: string;
    // Methods
    function SnapToGridValue(Value, GridSize: NativeInt): NativeInt;
   // procedure DrawSelection;
    procedure DrawStatusBar;
    function GetStatusBarRect: TRect;
   // procedure InitializeToolBar;
  //  procedure AddDefaultButtons;
    procedure DefaultButtonClick(Sender: TObject);
    procedure SettingsButtonClick(Sender: TObject);
    procedure ToolsButtonClick(Sender: TObject);
    procedure ExampleButtonClick(Sender: TObject);
   // procedure RemoveToolBar;
   // procedure CreateStatusBar;
    procedure DrawSelectionRectangle;
    procedure Resize;

  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Paint; override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure CaptureSelectedRegion(SaveFormat: TSaveFormat);
   // procedure InitializeGridPanel;
    //procedure AddButton(const ACaption: string; AClickEvent: TNotifyEvent = nil);
    procedure AddButtonWithImage(ToolBar: TToolBar; const ACaption: string; KnopName: String;
      ImageIndex: Integer; W: Integer; H: Integer; HintN: String; TagN: Integer; OnClickEvent: TNotifyEvent);
    procedure SetToolBarImages(Value: TImageList);
    function GetToolBarImages: TImageList;
     procedure AddSeparatorToToolBar(ToolBar: TToolBar;W:Integer);
    procedure AddButton(const ACaption: string; AClickEvent: TNotifyEvent = nil);
   // procedure AddButtonWithImage(ToolBar: TToolBar; const ACaption: string;KnopName:String ;
             // ImageIndex: Integer;W:Integer;H:Integer;HintN:String;TagN:Integer;OnClickEvent: TNotifyEvent);
   procedure AddConfigButton;
  published
    property ShowGrid: Boolean read FShowGrid write FShowGrid;
    property GridX: NativeInt read FGridX write FGridX;
    property GridY: NativeInt read FGridY write FGridY;
    property GridColor: TColor read FGridColor write FGridColor;
    property SnapToGrid: Boolean read FSnapToGrid write FSnapToGrid;
    // New properties for section colors statusbar
    property StatusBarHeight: NativeInt read FStatusBarHeight write FStatusBarHeight default 45;
    // New properties for section colors
    property ColorInput: TColor read FColorInput write FColorInput default clGreen;
    property ColorProcessing: TColor read FColorProcessing write FColorProcessing default clRed;
    property ColorOutput: TColor read FColorOutput write FColorOutput default clBlue;

    property InputText: string read FInputText write FInputText;
    property ProcessingText: string read FProcessingText write FProcessingText;
    property OutputText: string read FOutputText write FOutputText;
    // External events
    property OnMouseDown: TMouseEvent read FOnMouseDown write FOnMouseDown;
    property OnMouseMove: TMouseMoveEvent read FOnMouseMove write FOnMouseMove;
    property OnMouseUp: TMouseEvent read FOnMouseUp write FOnMouseUp;
    // koppel Imagelist aan ToolBar in Grid
    property ToolBarImages: TImageList read GetToolBarImages write SetToolBarImages;
  end;

implementation

{
type
TSaveFormat = (sfBMP, sfJPG, sfPNG, sfClipbrd);

  TjanGrid = class(TPanel)
  private
    FToolBar: TToolBar;// ToolBar for buttons
    FLogicBox: TjanSimLogicBox;
    FShowGrid: Boolean;
    FGridX, FGridY: NativeInt;
    FGridColor: TColor;
    FSnapToGrid: Boolean;
    FIsDrawing: Boolean;
    FRect: TRect;                // Current selection rectangle

     // External event handlers
    FOnMouseDown: TMouseEvent;
    FOnMouseMove: TMouseMoveEvent;
    FOnMouseUp: TMouseEvent;
    // Toevoeging colors TjanGrid
    FStatusBarHeight: NativeInt;
    FColorInput: TColor;
    FColorProcessing: TColor;
    FColorOutput: TColor;

    FStatus:TStatusBar;

    FInputText: string;
    FProcessingText: string;
    FOutputText: string;
    // Methods
    function SnapToGridValue(Value, GridSize: NativeInt): NativeInt;
    procedure DrawSelectionRectangle;
    // Toevoeging colors statusbar
    procedure DrawStatusBar;
    function GetStatusBarRect: TRect;
    procedure DefaultButtonClick(Sender: TObject);

   // procedure ShowConfigForm(Sender: TObject);
    procedure AddConfigButton;

  protected

    procedure Paint; override;
    procedure Resize; override;   // Toevoeging colors statusbar

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure CaptureSelectedRegion(SaveFormat: TSaveFormat);
    // Example method for button click
    procedure ExampleButtonClick(Sender: TObject);
    procedure ToolsButtonClick(Sender: TObject);
    procedure SettingsButtonClick(Sender: TObject);
     // Access the toolbar for customization
    property ToolBar: TToolBar read FToolBar;
    property LogicBox:TjanSimLogicBox read FLogicBox;
    procedure AddSeparatorToToolBar(ToolBar: TToolBar;W:Integer);
    procedure AddButton(const ACaption: string; AClickEvent: TNotifyEvent = nil);
    procedure AddButtonWithImage(ToolBar: TToolBar; const ACaption: string;KnopName:String ;
              ImageIndex: Integer;W:Integer;H:Integer;Hint:String;Tag:Integer;OnClickEvent: TNotifyEvent);

    procedure SetToolBarImages(Value: TImageList);
    function GetToolBarImages: TImageList;

  published
    property ShowGrid: Boolean read FShowGrid write FShowGrid;
    property GridX: NativeInt read FGridX write FGridX;
    property GridY: NativeInt read FGridY write FGridY;
    property GridColor: TColor read FGridColor write FGridColor;
    property SnapToGrid: Boolean read FSnapToGrid write FSnapToGrid;
    // New properties for section colors statusbar
    property StatusBarHeight: NativeInt read FStatusBarHeight write FStatusBarHeight default 45;
     // New properties for section colors
    property ColorInput: TColor read FColorInput write FColorInput default clGreen;
    property ColorProcessing: TColor read FColorProcessing write FColorProcessing default clRed;
    property ColorOutput: TColor read FColorOutput write FColorOutput default clBlue;

     property InputText: string read FInputText write FInputText;
     property ProcessingText: string read FProcessingText write FProcessingText;
     property OutputText: string read FOutputText write FOutputText;
     // External events
     property OnMouseDown: TMouseEvent read FOnMouseDown write FOnMouseDown;
     property OnMouseMove: TMouseMoveEvent read FOnMouseMove write FOnMouseMove;
     property OnMouseUp: TMouseEvent read FOnMouseUp write FOnMouseUp;
     // koppel Imagelist aan ToolBar in Grid
     property ToolBarImages: TImageList read GetToolBarImages write SetToolBarImages;

end;



implementation }

procedure TjanGrid.DefaultButtonClick(Sender: TObject);
begin
  ShowMessage('Knop in TjanGrid geklikt!');
end;

procedure TjanGrid.AddButton(const ACaption: string; AClickEvent: TNotifyEvent);
var
  Button: TToolButton;
begin
  // Dynamisch een knop toevoegen aan de toolbar
  if not Assigned(FToolBar) then Exit;
  Button := TToolButton.Create(FToolBar);
  Button.Parent := FToolBar;
  Button.Caption := ACaption;
  Button.Style := tbsButton;

  // Koppel een klik-event
  if Assigned(AClickEvent) then
    Button.OnClick := AClickEvent
  else
  Button.OnClick := @DefaultButtonClick; // Standaard klik-handler
end;

procedure TjanGrid.SetToolBarImages(Value: TImageList);
begin
  if Assigned(FToolBar) then
    FToolBar.Images := Value;
end;

function TjanGrid.GetToolBarImages: TImageList;
begin
  if Assigned(FToolBar) and (FToolBar.Images is TImageList) then
    Result := TImageList(FToolBar.Images)  // Typecast naar TImageList
  else
    Result := nil;
end;



{ TjanGrid }

constructor TjanGrid.Create(AOwner: TComponent);
var
  PanelWidth,i:NativeInt;
  Panel: TStatusPanel;
begin
  inherited Create(AOwner);
  FShowGrid := True;
  FGridX := 10;
  FGridY := 10;
  FGridColor := clGray;
  FSnapToGrid := True;
  FIsDrawing := False;
  FRect := Rect(0, 0, 0, 0);
  // Default height of the status bar
  FStatusBarHeight := 25; // Default height of the status bar
  // Default colors for the status bar sections
  FColorInput := clGreen;
  FColorProcessing := clRed;
  FColorOutput := clBlue;
  // Create the toolbar and Ensure the toolbar has valid settings
  FToolBar := TToolBar.Create(Self);
  FToolBar.Parent := Self;
  FToolBar.Align := alTop;
  FToolBar.SetButtonSize(100,23);
  FToolBar.ShowCaptions := True; // Show captions on buttons
  FToolBar.List:=True;
   // AddSeparator
  AddSeparatorToToolBar(FToolBar,45);
  AddButtonWithImage(FToolBar,'Grid uit','KNOP1',0,100,25,'TEST1',10,@ExampleButtonClick);
  AddSeparatorToToolBar(FToolBar,15);
   AddButtonWithImage(FToolBar,'GRID','KNOP2',0,100,25,'Grid Ja/Nee',11,@ToolsButtonClick);
  AddSeparatorToToolBar(FToolBar,15);
   AddButtonWithImage(FToolBar,'Box','KNOP3',0,100,25,'Instellingen',12,@settingsButtonClick);
  FInputText := 'INVOER';
  FProcessingText := 'VERWERKING';
  FOutputText := 'UITVOER';
end;

procedure TjanGrid.AddConfigButton;
begin
  // Voeg een knop toe die het configuratiescherm opent
//  AddButton('Instellingen', ShowConfigForm);
end;
procedure TjanGrid.AddSeparatorToToolBar(ToolBar: TToolBar;W:Integer);
var
  Separator: TToolButton;
begin
  // Maak een nieuw ToolButton-object
  Separator := TToolButton.Create(ToolBar);
  Separator.Parent := ToolBar; // Stel de ToolBar in als ouder
  Separator.Style := tbsSeparator; // Stel de stijl in als separator
  Separator.Width := W; // Stel een breedte in voor de separator (optioneel)
end;

procedure TjanGrid.AddButtonWithImage(ToolBar: TToolBar; const ACaption: string;KnopName:String ;ImageIndex: Integer; W:Integer;H:Integer;HintN:String;TagN:Integer;OnClickEvent: TNotifyEvent);
var
  Button: TToolButton;
begin
  // Maak een nieuwe ToolButton
  Button := TToolButton.Create(ToolBar);
  Button.Parent := ToolBar;
  // Stel de stijl in
  Button.Style := tbsButton;
  // Stel de tekst en de afbeelding in
  Button.Caption := ACaption;
  Button.Wrap:=false;
  Button.ImageIndex :=ImageIndex;
  Button.Width:=W;
  Button.Height:=H;
  Button.Hint:= HintN;
  Button.ShowHint:=True;
  Button.Tag:= TagN;
  Button.Name:=KnopName;
  // Stel een klik-event in
  Button.OnClick := OnClickEvent;
end;
//
procedure TjanGrid.SettingsButtonClick(Sender: TObject);
var
  Btn:  TToolButton; // Veronderstel dat de klik wordt uitgevoerd door een TButton
  BoxSetting:TjanSimLogicBox;
begin
  if Sender is  TToolButton then
  begin

  end;
end;
// Example method for button click
procedure TjanGrid.ExampleButtonClick(Sender: TObject);
var
  Btn:  TToolButton; // Veronderstel dat de klik wordt uitgevoerd door een TButton
begin
  if Sender is  TToolButton then
  begin
    Btn :=  TToolButton(Sender);
    // Toon de naam van de knop
    ShowMessage('Knop geklikt: ' + Btn.Name);
    // Toon de tag van de knop (indien ingesteld)
    ShowMessage('Knop tag: ' + IntToStr(Btn.Tag));
  end
  else
    ShowMessage('Onbekend object geklikt');
end;

procedure TjanGrid.ToolsButtonClick(Sender: TObject);
var
  i: Integer;
  MainForm: TForm;
begin
  MainForm := Application.MainForm;
  // Zoek naar een TStatusBar op het hoofdformulier
 { for i := 0 to MainForm.ComponentCount - 1 do
  begin
    if MainForm.Components[i] is TStatusBar then
    begin
      TStatusBar(MainForm.Components[i]).SimpleText := 'Tools Knop geklikt!';
      Exit; // Stop na de eerste gevonden TStatusBar
    end;
  end;}
  for i := 0 to MainForm.ComponentCount - 1 do
  begin
    if MainForm.Components[i] is TjanGrid then
    begin
       If TjanGrid(MainForm.Components[i]).ShowGrid= True then
          TjanGrid(MainForm.Components[i]).ShowGrid:=False
          else
          TjanGrid(MainForm.Components[i]).ShowGrid:=True;

      invalidate;
      Exit; // Stop na de eerste gevonden TStatusBar
    end;
  end;
end;
  //ShowMessage('Tools Knop geklikt!');
//  parent.StatustatusBar.Simpl
//end;

// Paint method for drawing grid and rectangle
procedure TjanGrid.Paint;
var
  StartY,idxX,idxY : NativeInt;
begin
  inherited Paint;
   // Bereken de beginpositie van het grid (onder toolbar en statusbalk)
  StartY := FToolBar.Height + FStatusBarHeight;
  ControlStyle:=ControlStyle + [csOpaque] + [csAcceptsControls];
  // Draw grid if enabled
  if FShowGrid then
     begin
         with Canvas do
          begin
               Lock;
               idxX:=1;
               while idxX < Width do
               begin
                    idxY:=1;
                    while idxY < height do
                    begin
                         Pixels[idxX,idxY]:=FGridColor;
                         inc(idxY,FGridY);
                    end;
                    inc(idxX,FGridX);
               end;
               Unlock;
          end;
     end;
  // Draw the status bar
    DrawStatusBar;
  // Draw the selection rectangle wordt door procedure DrawSelectionRectangle
  // uitgevoerd indien FIsDrawing true is ( wordt in de procedure gekontroleerd
    DrawSelectionRectangle;
end;

procedure TjanGrid.DrawStatusBar;
var
  StatusBarRect: TRect;
  SectionWidth, TextWidth, TextHeight, CenterX, CenterY: NativeInt;
begin
  StatusBarRect := GetStatusBarRect;
  SectionWidth := StatusBarRect.Width div 3;

  // Input sectie
  Canvas.Brush.Color := FColorInput;
  Canvas.FillRect(Rect(StatusBarRect.Left, StatusBarRect.Top, StatusBarRect.Left + SectionWidth, StatusBarRect.Bottom));
  Canvas.Font.Color := clWhite;
  Canvas.Font.Style := [fsBold];
  TextWidth := Canvas.TextWidth(FInputText);
  TextHeight := Canvas.TextHeight(FInputText);
  CenterX := (StatusBarRect.Left + (StatusBarRect.Left + SectionWidth) - TextWidth) div 2;
  CenterY := (StatusBarRect.Top + StatusBarRect.Bottom - TextHeight) div 2;
  Canvas.TextOut(CenterX,CenterY, FInputText);

  // Verwerking sectie
  Canvas.Brush.Color := FColorProcessing;
  Canvas.FillRect(Rect(StatusBarRect.Left + SectionWidth, StatusBarRect.Top, StatusBarRect.Left + 2 * SectionWidth, StatusBarRect.Bottom));
  TextWidth := Canvas.TextWidth(FProcessingText);
  TextHeight := Canvas.TextHeight(FProcessingText);
  CenterX := (StatusBarRect.Left + SectionWidth + (StatusBarRect.Left + 2 * SectionWidth) - TextWidth) div 2;
  CenterY := (StatusBarRect.Top + StatusBarRect.Bottom - TextHeight) div 2;
  Canvas.TextOut(CenterX,CenterY, FProcessingText);

  // Output sectie
  Canvas.Brush.Color := FColorOutput;
  Canvas.FillRect(Rect(StatusBarRect.Left + 2 * SectionWidth, StatusBarRect.Top, StatusBarRect.Right, StatusBarRect.Bottom));
  TextWidth := Canvas.TextWidth(FOutputText);
  TextHeight := Canvas.TextHeight(FOutputText);
  CenterX := (StatusBarRect.Left + 2 * SectionWidth + (StatusBarRect.Right) - TextWidth) div 2;
  CenterY := (StatusBarRect.Top + StatusBarRect.Bottom - TextHeight) div 2;
  Canvas.TextOut(CenterX,CenterY, FOutputText);
end;


// Calculate the rectangle for the status bar
function TjanGrid.GetStatusBarRect: TRect;
begin
  Result := Rect(45, FToolBar.Height, Width, FToolBar.Height + FStatusBarHeight);

end;

// Adjust layout on resize
procedure TjanGrid.Resize;
begin
  inherited Resize;
  Invalidate; // Trigger repaint
end;


// Draw the selection rectangle dynamically
procedure TjanGrid.DrawSelectionRectangle;
begin
  if FIsDrawing then
  begin
    Canvas.Pen.Style := psSolid;
    Canvas.Pen.Color:=clRed;
    Canvas.Brush.Style := bsClear;
    Canvas.Rectangle(FRect);
  end;
end;

// Snap a value to the nearest grid point
function TjanGrid.SnapToGridValue(Value, GridSize: NativeInt): NativeInt;
begin
  Result := (Value div GridSize) * GridSize;
end;

// Mouse event handlers
procedure TjanGrid.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y:Integer);
begin
  if Button = mbLeft then
  begin
    FIsDrawing := True;
    FRect.Left := SnapToGridValue(X, FGridX);
    FRect.Top := SnapToGridValue(Y, FGridY);
    FRect.Right := FRect.Left;
    FRect.Bottom := FRect.Top;
    //  Invalidate; // Trigger repaint
    //showMessage('MouseDown in gridpanel');
    // Call external handler if assigned
  if Assigned(FOnMouseDown) then
    FOnMouseDown(Self, Button, Shift, X, Y);

  end;
end;

procedure TjanGrid.MouseMove(Shift: TShiftState; X, Y: integer);
begin
  if FIsDrawing then
  begin
    FRect.Right := SnapToGridValue(X, FGridX);
    FRect.Bottom := SnapToGridValue(Y, FGridY);
    Invalidate; // Trigger repaint
    // Call external handler if assigned
  if Assigned(FOnMouseMove) then
    FOnMouseMove(Self, Shift, X, Y);

  end;
end;

procedure TjanGrid.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    FIsDrawing := False;
    Invalidate; // Trigger repaint
    CaptureSelectedRegion(sfClipbrd);

     // Call external handler if assigned
  if Assigned(FOnMouseUp) then
    FOnMouseUp(Self, Button, Shift, X, Y);

  end;
end;

// Capture the selected region
procedure TjanGrid.CaptureSelectedRegion(SaveFormat: TSaveFormat);
var
  Bitmap: TBitmap;
  SelectionWidth, SelectionHeight: NativeInt;
begin
  SelectionWidth := FRect.Right - FRect.Left;
  SelectionHeight := FRect.Bottom - FRect.Top;

  if (SelectionWidth <= 0) or (SelectionHeight <= 0) then Exit;

  Bitmap := TBitmap.Create;
  try
    Bitmap.Width := SelectionWidth;
    Bitmap.Height := SelectionHeight;
    Bitmap.Canvas.CopyRect(Rect(0, 0, SelectionWidth, SelectionHeight), Canvas, FRect);
    case SaveFormat of
      sfBMP: Bitmap.SaveToFile('SelectedRegion.bmp');
      sfClipbrd: Clipboard.Assign(Bitmap);
      // Add more formats as needed
    end;
  finally
    Bitmap.Free;
  end;
end;

destructor TjanGrid.Destroy;
begin
  inherited Destroy;
end;

end.
