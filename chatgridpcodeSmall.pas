unit chatgridpcodeSmall;

{$mode ObjFPC}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages,
  SysUtils, Classes, Controls, Forms, Dialogs, Buttons,
  ExtCtrls, StdCtrls, ComCtrls,Types, Menus,
  Graphics, Clipbrd, FPImage, IntfGraphics, FPWritePNG, FPWriteJPEG;
type
  TSaveFormat = (sfBMP, sfJPG, sfPNG, sfClipbrd);
  TLanguage = (lgEnglish, lgFrench, lgDutch, lgGerman);


  TTitleClickEvent = procedure(Sender: TObject) of object;

  // voor kaders tekenen
 type
  TGridMode = (gmNormal, gmFrameDraw, gmFrameEdit);
  TFrameHit = (fhNone, fhMove, fhTopLeft, fhTopRight, fhBottomLeft, fhBottomRight);

  TGridFrame = class(TPersistent)
  private
    FFrameRect: TRect;
    FCaption: string;
    FSelected: Boolean;
    FVisible: Boolean;
    FBorderColor: TColor;
    FInfo:String;
    procedure SetInfo(const Value: String);


  public
    constructor Create;
    function NormalizedRect: TRect;
    function HitTest(const P: TPoint): TFrameHit;
    function ContainsPoint(const P: TPoint): Boolean;
    procedure Draw(ACanvas: TCanvas);

    property FrameRect: TRect read FFrameRect write FFrameRect;
    property Caption: string read FCaption write FCaption;
    property Selected: Boolean read FSelected write FSelected;
    property Visible: Boolean read FVisible write FVisible;
    property BorderColor: TColor read FBorderColor write FBorderColor;
    property Info:String read FInfo write SetInfo; // xxxx

  end;

  TjanGridS = class(TPanel)
  private
     FOnTitleClick: TTitleClickEvent;
    // basis
    FCapture: Boolean;
    FSaveFormat: TSaveFormat;
    FShowGrid: Boolean;
    FGridX, FGridY: NativeInt;
    FGridColor: TColor;
    FSnapToGrid: Boolean;
    // selectie / tekenen
    FIsDrawing: Boolean;
    FRect: TRect;
    // guide lines (nieuw, vervangt snap kruis)
    FShowGuideLines: Boolean;
    FGuidePoint: TPoint;
    FHasGuidePoint: Boolean;
    // nodig om GuideLnes volledig al of niet te tonen
    // bij leeg panel
    FMouseMoveGuideLines:Boolean;
   // mouse info
    FMousePos: TPoint;
    // rulers
    FShowRulers: Boolean;
    FRulerTopHeight: Integer;
    FRulerRightWidth: Integer;
    FRulerColor: TColor;
    FRulerTextColor: TColor;
    FRulerTickColor: TColor;
    // external events
    FOnMouseDown: TMouseEvent;
    FOnMouseMove: TMouseMoveEvent;
    FOnMouseUp: TMouseEvent;
    // statusbar / titel
    FStatusBarHeight: NativeInt;
    FColorInput: TColor;
    FColorProcessing: TColor;
    FColorOutput: TColor;
    FShowSelectionDimensions: Boolean;
    // taal
    FLanguage: TLanguage;
    FInputText: string;
    FProcessingText: string;
    FOutputText: string;
    // layout
    FBox: Boolean;
    FTitel: string;
    FTitelColor: TColor;
    // Magnetische Snap
    FMagneticSnap: Boolean;
    FSnapTolerance: Integer;
    FMajorSnapMultiplier: Integer;
    //meerdere Kaders
    FGridMode: TGridMode;
    FFrames: TList;
    FActiveFrame: TGridFrame;
    FFrameDragging: Boolean;
    FFrameHit: TFrameHit;
    FFrameStartMouse: TPoint;
    FFrameStartRect: TRect;
    FFrameMinSize: Integer;

    // kaders popup
    FFramePopup: TPopupMenu;
    miFrameCaption: TMenuItem;
    miFrameVisible: TMenuItem;
    miFrameEditMode: TMenuItem;
    miFrameColorBlue: TMenuItem;
    miFrameColorRed: TMenuItem;
    miFrameColorGreen: TMenuItem;
    miFrameDelete: TMenuItem;
    procedure ClearFrameSelection;
    procedure BuildFramePopup;
    procedure UpdateFramePopupCaptions;
    procedure FrameCaptionClick(Sender: TObject);
    procedure FrameVisibleClick(Sender: TObject);
    procedure FrameEditModeClick(Sender: TObject);
    procedure FrameColorClick(Sender: TObject);
    procedure FrameDeleteClick(Sender: TObject);

    procedure ShowCustomHint(const S: string; X, Y: Integer);
    procedure HideCustomHint;
    procedure UpdateFrameHints;

    function NormalizeRect(const R: TRect): TRect;
    procedure DeselectAllFrames;
    function FrameBodyAtPoint(const P: TPoint): TGridFrame;
    function FrameAtPoint(const P: TPoint; out AHit: TFrameHit): TGridFrame;
    function AddFrame(const ARect: TRect; const ACaption: string = 'Kader'): TGridFrame;
    // helpers
    function GetTitleRect: TRect;
    function MagneticSnapValue(Value, Origin, StepSize, Tolerance: Integer): Integer;
    function SnapToGridValue(Value, GridSize: NativeInt): NativeInt;
    procedure DrawSelectionRectangle;
    procedure UpdateTextForLanguage;
    procedure SetLanguage(const Value: TLanguage);
    procedure SetBox(Value: Boolean);
    procedure SetTitel(const Value: string);
    procedure SetTitelColor(const Value: TColor);
    procedure SetInputText(const Value: string);
    procedure SetOutputText(const Value: string);
    procedure SetProcessingText(const Value: string);

    procedure DrawStatusBar;
    function GetStatusBarRect: TRect;

    // rulers helpers
    function GetTitleHeight: Integer;
    function GetGridLeftOffset: Integer;
    function GetTitleTop: Integer;
    function GetTopRulerRect: TRect;
    function GetRightRulerRect: TRect;
    function NormalizeSelectionRect(const R: TRect): TRect;
    procedure DrawRulers;

  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
    procedure PaintSelectionDimensions; virtual;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure CaptureSelectedRegion;
    procedure ClearFrames;// voor Kaders
    function GetWorkAreaRect: TRect;
    function SnapPointToRuler(const P: TPoint; const WorkR: TRect): TPoint;

    // guide lines API (BELANGRIJK)
    procedure BeginGuideLines(AX, AY: Integer);
    procedure UpdateGuideLines(AX, AY: Integer);
    procedure EndGuideLines;

  published
    property Capture: Boolean read FCapture write FCapture;
    property ShowGrid: Boolean read FShowGrid write FShowGrid;
    property GridX: NativeInt read FGridX write FGridX;
    property GridY: NativeInt read FGridY write FGridY;
    property DotColor: TColor read FGridColor write FGridColor;
    property SnapToGrid: Boolean read FSnapToGrid write FSnapToGrid;

    property StatusBarHeight: NativeInt read FStatusBarHeight write FStatusBarHeight default 25;
    property ColorInput: TColor read FColorInput write FColorInput default clGreen;
    property ColorProcessing: TColor read FColorProcessing write FColorProcessing default clRed;
    property ColorOutput: TColor read FColorOutput write FColorOutput default clBlue;

    property ShowRulers: Boolean read FShowRulers write FShowRulers default True;
    property RulerTopHeight: Integer read FRulerTopHeight write FRulerTopHeight default 20;
    property RulerRightWidth: Integer read FRulerRightWidth write FRulerRightWidth default 42;
    property RulerColor: TColor read FRulerColor write FRulerColor default clBtnFace;
    property RulerTextColor: TColor read FRulerTextColor write FRulerTextColor default clBlack;
    property RulerTickColor: TColor read FRulerTickColor write FRulerTickColor default clGray;
    property GuideLinesAll:Boolean read FMouseMoveGuideLines write FMouseMoveGuideLines default False;

    property ShowGuideLines: Boolean read FShowGuideLines write FShowGuideLines default True;

    property OnMouseDown: TMouseEvent read FOnMouseDown write FOnMouseDown;
    property OnMouseMove: TMouseMoveEvent read FOnMouseMove write FOnMouseMove;
    property OnMouseUp: TMouseEvent read FOnMouseUp write FOnMouseUp;

    property ShowSelectionDimensions: Boolean read FShowSelectionDimensions write FShowSelectionDimensions;

    property Language: TLanguage read FLanguage write SetLanguage;

    property InputText: string read FInputText write SetInputText;
    property OutputText: string read FOutputText write SetOutputText;
    property ProcessingText: string read FProcessingText write SetProcessingText;

    property Box: Boolean read FBox write SetBox default True;
    property Titel: string read FTitel write SetTitel;
    property TitelColor: TColor read FTitelColor write SetTitelColor;

    property SavePicFormat: TSaveFormat read FSaveFormat write FSaveFormat;

    property Enabled;

    property MagneticSnap: Boolean read FMagneticSnap write FMagneticSnap default True;
    property SnapTolerance: Integer read FSnapTolerance write FSnapTolerance default 4;
    property MajorSnapMultiplier: Integer read FMajorSnapMultiplier write FMajorSnapMultiplier default 5;

    property OnTitleClick: TTitleClickEvent read FOnTitleClick write FOnTitleClick;
     // voor kaders
     property GridMode: TGridMode read FGridMode write FGridMode default gmNormal;
  end;


implementation

function TxtFrameCaption(ALanguage: TLanguage): string;
begin
  case ALanguage of
    lgDutch:   Result := 'Caption wijzigen';
    lgEnglish: Result := 'Change caption';
    lgFrench:  Result := 'Modifier la légende';
    lgGerman:  Result := 'Beschriftung ändern';
  else
    Result := 'Change caption';
  end;
end;
{
function TxtFrameVisible(ALanguage: TLanguage): string;
begin
  case ALanguage of
    lgDutch:   Result := 'Visible aan/uit';
    lgEnglish: Result := 'Toggle visible';
    lgFrench:  Result := 'Visible oui/non';
    lgGerman:  Result := 'Sichtbar ein/aus';
  else
    Result := 'Toggle visible';
  end;
end; }
{
function TxtFrameEditMode(ALanguage: TLanguage): string;
begin
  case ALanguage of
    lgDutch:   Result := 'Mode = Edit';
    lgEnglish: Result := 'Mode = Edit';
    lgFrench:  Result := 'Mode = Édition';
    lgGerman:  Result := 'Modus = Bearbeiten';
  else
    Result := 'Mode = Edit';
  end;
end;}

function TxtFrameColorBlue(ALanguage: TLanguage): string;
begin
  case ALanguage of
    lgDutch:   Result := 'Kleur blauw';
    lgEnglish: Result := 'Color blue';
    lgFrench:  Result := 'Couleur bleue';
    lgGerman:  Result := 'Farbe blau';
  else
    Result := 'Color blue';
  end;
end;

function TxtFrameColorRed(ALanguage: TLanguage): string;
begin
  case ALanguage of
    lgDutch:   Result := 'Kleur rood';
    lgEnglish: Result := 'Color red';
    lgFrench:  Result := 'Couleur rouge';
    lgGerman:  Result := 'Farbe rot';
  else
    Result := 'Color red';
  end;
end;

function TxtFrameColorGreen(ALanguage: TLanguage): string;
begin
  case ALanguage of
    lgDutch:   Result := 'Kleur groen';
    lgEnglish: Result := 'Color green';
    lgFrench:  Result := 'Couleur verte';
    lgGerman:  Result := 'Farbe grün';
  else
    Result := 'Color green';
  end;
end;

function TxtFrameDelete(ALanguage: TLanguage): string;
begin
  case ALanguage of
    lgDutch:   Result := 'Kader verwijderen';
    lgEnglish: Result := 'Delete frame';
    lgFrench:  Result := 'Supprimer le cadre';
    lgGerman:  Result := 'Rahmen löschen';
  else
    Result := 'Delete frame';
  end;
end;

function BuildTitleHint(ALanguage: TLanguage): string;
begin
  case ALanguage of
    lgDutch:
      Result := 'Klik hier om de titel te wijzigen';
    lgEnglish:
      Result := 'Click here to change the title';
    lgFrench:
      Result := 'Cliquez ici pour modifier le titre';
    lgGerman:
      Result := 'Klicken Sie hier, um den Titel zu ändern';
  else
      Result := 'Click here to change the title';
  end;
end;

function BuildFrameInfoHint(ALanguage: TLanguage): string;
begin
  case ALanguage of
    lgDutch:
      Result := 'Rechter muisknop voor extra instellingen';
    lgEnglish:
      Result := 'Right mouse button for extra settings';
    lgFrench:
      Result := 'Bouton droit pour paramètres supplémentaires';
    lgGerman:
      Result := 'Rechte Maustaste für zusätzliche Einstellungen';
  else
    Result := 'Right mouse button for extra settings';
  end;
end;

constructor TGridFrame.Create;
begin
  inherited Create;
  FFrameRect := Types.Rect(0, 0, 0, 0);
  FCaption := 'Kader';
  FSelected := False;
  FVisible := True;
  FBorderColor := clBlue;
 // Info:='Rechter muisknop voor extra instellingen';
end;

procedure TGridFrame.SetInfo(const Value: String);
begin
  if value<>FInfo then
  begin
    FInfo := Value;
 end;
end;



function TGridFrame.NormalizedRect: TRect;
begin
  Result := FFrameRect;

  if Result.Left > Result.Right then
  begin
    Result.Left := FFrameRect.Right;
    Result.Right := FFrameRect.Left;
  end;

  if Result.Top > Result.Bottom then
  begin
    Result.Top := FFrameRect.Bottom;
    Result.Bottom := FFrameRect.Top;
  end;
end;

function TGridFrame.HitTest(const P: TPoint): TFrameHit;
const
  GripSize = 4;
  MoveRadius = 6;
var
  R, G: TRect;
  CX, CY: Integer;
begin
  Result := fhNone;
  if not FVisible then Exit;

  R := NormalizedRect;

  // hoekgrepen
  G := Types.Rect(R.Left - GripSize, R.Top - GripSize,
                  R.Left + GripSize, R.Top + GripSize);
  if PtInRect(G, P) then Exit(fhTopLeft);

  G := Types.Rect(R.Right - GripSize, R.Top - GripSize,
                  R.Right + GripSize, R.Top + GripSize);
  if PtInRect(G, P) then Exit(fhTopRight);

  G := Types.Rect(R.Left - GripSize, R.Bottom - GripSize,
                  R.Left + GripSize, R.Bottom + GripSize);
  if PtInRect(G, P) then Exit(fhBottomLeft);

  G := Types.Rect(R.Right - GripSize, R.Bottom - GripSize,
                  R.Right + GripSize, R.Bottom + GripSize);
  if PtInRect(G, P) then Exit(fhBottomRight);

  // centrale move-greep (cirkel, benaderd met een vierkant hitgebied)
  CX := (R.Left + R.Right) div 2;
  CY := (R.Top + R.Bottom) div 2;

  G := Types.Rect(CX - MoveRadius, CY - MoveRadius,
                  CX + MoveRadius, CY + MoveRadius);
  if PtInRect(G, P) then Exit(fhMove);
end;

function TGridFrame.ContainsPoint(const P: TPoint): Boolean;
begin
  Result := FVisible and PtInRect(NormalizedRect, P);
end;

procedure TGridFrame.Draw(ACanvas: TCanvas);
const
  GripSize = 4;
var
  R: TRect;
  TW,TH,TX,TY:Integer;
begin
  if not FVisible then Exit;

  R := NormalizedRect;

  ACanvas.Brush.Style := bsClear;
  ACanvas.Pen.Color := FBorderColor;
  ACanvas.Pen.Width := 1;
  ACanvas.Pen.Style := psSolid;
  ACanvas.RoundRect(R,20,20);     // Rectangle(R);

  if Trim(FCaption) <> '' then
  begin
    ACanvas.Font.Color := clNavy;
    ACanvas.Font.Style := [fsBold];

    // bereken tekst grootte
    TW := ACanvas.TextWidth(FCaption);
    TH := ACanvas.TextHeight(FCaption);

    // horizontaal centreren
    TX := R.Left + ((R.Right - R.Left) div 2) - (TW div 2);

    // boven het kader (zoals je had)
       // TY := R.Top - TH - 2;
    // in kader gecentreerd
    TY:= R.top +3;
    ACanvas.TextOut(TX, TY, FCaption);
  end;
 if FSelected then
begin
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := clWhite;
  ACanvas.Pen.Color := clBlack;

  // hoekgrepen
  ACanvas.Rectangle(R.Left - GripSize,  R.Top - GripSize,    R.Left + GripSize,  R.Top + GripSize);
  ACanvas.Rectangle(R.Right - GripSize, R.Top - GripSize,    R.Right + GripSize, R.Top + GripSize);
  ACanvas.Rectangle(R.Left - GripSize,  R.Bottom - GripSize, R.Left + GripSize,  R.Bottom + GripSize);
  ACanvas.Rectangle(R.Right - GripSize, R.Bottom - GripSize, R.Right + GripSize, R.Bottom + GripSize);

  // centrale move-greep
  ACanvas.Brush.Color := clYellow;
  ACanvas.Ellipse(
    ((R.Left + R.Right) div 2) - 6,
    ((R.Top + R.Bottom) div 2) - 6,
    ((R.Left + R.Right) div 2) + 6,
    ((R.Top + R.Bottom) div 2) + 6
  );
end;

  ACanvas.Brush.Style := bsSolid;
end;

procedure TjanGridS.ClearFrameSelection;
var
  i: Integer;
begin
  for i := 0 to FFrames.Count - 1 do
    TGridFrame(FFrames[i]).Selected := False;

  FActiveFrame := nil;
end;

// voor kaders popup

procedure TjanGridS.BuildFramePopup;
begin
  if Assigned(FFramePopup) then Exit;

  FFramePopup := TPopupMenu.Create(Self);

  miFrameCaption := TMenuItem.Create(FFramePopup);
  miFrameCaption.Caption := TxtFrameCaption(FLanguage);
  miFrameCaption.OnClick := @FrameCaptionClick;
  FFramePopup.Items.Add(miFrameCaption);

  FFramePopup.Items.Add(TMenuItem.Create(FFramePopup));
  FFramePopup.Items[FFramePopup.Items.Count - 1].Caption := '-';

  miFrameColorBlue := TMenuItem.Create(FFramePopup);
  miFrameColorBlue.Caption := TxtFrameColorBlue(FLanguage);
  miFrameColorBlue.Tag := clBlue;
  miFrameColorBlue.OnClick := @FrameColorClick;
  FFramePopup.Items.Add(miFrameColorBlue);

  miFrameColorRed := TMenuItem.Create(FFramePopup);
  miFrameColorRed.Caption := TxtFrameColorRed(FLanguage);
  miFrameColorRed.Tag := clRed;
  miFrameColorRed.OnClick := @FrameColorClick;
  FFramePopup.Items.Add(miFrameColorRed);

  miFrameColorGreen := TMenuItem.Create(FFramePopup);
  miFrameColorGreen.Caption := TxtFrameColorGreen(FLanguage);
  miFrameColorGreen.Tag := clGreen;
  miFrameColorGreen.OnClick := @FrameColorClick;
  FFramePopup.Items.Add(miFrameColorGreen);

  FFramePopup.Items.Add(TMenuItem.Create(FFramePopup));
  FFramePopup.Items[FFramePopup.Items.Count - 1].Caption := '-';

  miFrameDelete := TMenuItem.Create(FFramePopup);
  miFrameDelete.Caption := TxtFrameDelete(FLanguage);
  miFrameDelete.OnClick := @FrameDeleteClick;
  FFramePopup.Items.Add(miFrameDelete);
end;

procedure TjanGridS.UpdateFramePopupCaptions;
begin
  if not Assigned(FFramePopup) then Exit;

  if Assigned(miFrameCaption) then
    miFrameCaption.Caption := TxtFrameCaption(FLanguage);

  if Assigned(miFrameColorBlue) then
    miFrameColorBlue.Caption := TxtFrameColorBlue(FLanguage);

  if Assigned(miFrameColorRed) then
    miFrameColorRed.Caption := TxtFrameColorRed(FLanguage);

  if Assigned(miFrameColorGreen) then
    miFrameColorGreen.Caption := TxtFrameColorGreen(FLanguage);

  if Assigned(miFrameDelete) then
    miFrameDelete.Caption := TxtFrameDelete(FLanguage);
end;

// caption wijzigen
procedure TjanGridS.FrameCaptionClick(Sender: TObject);
var
  S: string;
begin
  if not Assigned(FActiveFrame) then Exit;

  S := InputBox('Caption wijzigen', 'Nieuwe caption:', FActiveFrame.Caption);
  FActiveFrame.Caption := S;
  FActiveFrame.FSelected:=false;
  Invalidate;
end;
// Visible toggle
procedure TjanGridS.FrameVisibleClick(Sender: TObject);
begin
  if not Assigned(FActiveFrame) then Exit;

  FActiveFrame.Visible := not FActiveFrame.Visible;
  Invalidate;
end;

// mode edit
procedure TjanGridS.FrameEditModeClick(Sender: TObject);
begin
  FGridMode := gmFrameEdit;
  Invalidate;
end;

// Kleur wijeigen
procedure TjanGridS.FrameColorClick(Sender: TObject);
begin
  if not Assigned(FActiveFrame) then Exit;
  if Sender is TMenuItem then
  begin
    FActiveFrame.BorderColor := TMenuItem(Sender).Tag;
    FActiveFrame.FSelected:=false;
    Invalidate;

  end;
end;
// verwijderen
procedure TjanGridS.FrameDeleteClick(Sender: TObject);
begin
  if not Assigned(FActiveFrame) then Exit;

  FFrames.Remove(FActiveFrame);
  FActiveFrame.Free;
  FActiveFrame := nil;
  Invalidate;
end;

procedure TjanGridS.ShowCustomHint(const S: string; X, Y: Integer);
begin
  if Trim(S) = '' then Exit;

  if Hint <> S then
  begin
    Hint := S;
    Application.CancelHint;
    Application.ActivateHint(ClientToScreen(Point(X + 16, Y + 16)));
  end;

end;


procedure TjanGridS.HideCustomHint;
begin
  if Hint <> '' then
  begin
    Hint := '';
    Application.CancelHint;
  end;
end;

procedure TjanGridS.UpdateFrameHints;
var
  i: Integer;
begin
  for i := 0 to FFrames.Count - 1 do
    TGridFrame(FFrames[i]).Info := BuildFrameInfoHint(FLanguage);
end;

//Helpers voor kaders
function TjanGridS.NormalizeRect(const R: TRect): TRect;
begin
  Result := R;

  if Result.Left > Result.Right then
  begin
    Result.Left := R.Right;
    Result.Right := R.Left;
  end;

  if Result.Top > Result.Bottom then
  begin
    Result.Top := R.Bottom;
    Result.Bottom := R.Top;
  end;
end;
{
procedure TjanGridS.DeselectAllFrames;
var
  i: Integer;
begin
  for i := 0 to FFrames.Count - 1 do
    TGridFrame(FFrames[i]).Selected := False;
end;
}
procedure TjanGridS.DeselectAllFrames;
var
  i: Integer;
begin
  for i := 0 to FFrames.Count - 1 do
    TGridFrame(FFrames[i]).Selected := False;

  FActiveFrame := nil;
end;

function TjanGridS.FrameBodyAtPoint(const P: TPoint): TGridFrame;
var
  i: Integer;
  R: TRect;
begin
  Result := nil;
  for i := FFrames.Count - 1 downto 0 do
  begin
    R := TGridFrame(FFrames[i]).NormalizedRect;
    if PtInRect(R, P) then
      Exit(TGridFrame(FFrames[i]));
  end;
end;

function TjanGridS.FrameAtPoint(const P: TPoint; out AHit: TFrameHit): TGridFrame;
var
  i: Integer;
  F: TGridFrame;
begin
  Result := nil;
  AHit := fhNone;

  for i := FFrames.Count - 1 downto 0 do
  begin
    F := TGridFrame(FFrames[i]);
    AHit := F.HitTest(P);
    if AHit <> fhNone then
    begin
      Result := F;
      Exit;
    end;
  end;
end;

function TjanGridS.AddFrame(const ARect: TRect; const ACaption: string = 'Kader'): TGridFrame;
begin
  Result := TGridFrame.Create;
  Result.FrameRect := ARect;
  Result.Caption := ACaption;
  Result.Visible := True;
  Result.Selected := False;// was true
  Result.BorderColor := clBlack;
  Result.Info := BuildFrameInfoHint(FLanguage);
  FFrames.Add(Result);
  FActiveFrame := Result;
  Invalidate;
end;

procedure TjanGridS.ClearFrames;
var
  i: Integer;
begin
  for i := 0 to FFrames.Count - 1 do
    TObject(FFrames[i]).Free;

  FFrames.Clear;
  FActiveFrame := nil;
  FFrameDragging := False;
  FFrameHit := fhNone;
  Invalidate;
end;

constructor TjanGridS.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFramePopup := nil;
  miFrameCaption := nil;
  miFrameVisible := nil;
  miFrameEditMode := nil;
  miFrameColorBlue := nil;
  miFrameColorRed := nil;
  miFrameColorGreen := nil;
  miFrameDelete := nil;
  // basis
  FCapture := False;
  FSaveFormat := sfBMP;
  FShowGrid := True;
  FGridX := 10;
  FGridY := 10;
  FGridColor := clGray;
  FSnapToGrid := True;

  // selectie / tekenen
  FIsDrawing := False;
  FRect := Types.Rect(0, 0, 0, 0);

  // guide lines
  FShowGuideLines := True;
  FGuidePoint := Point(-1, -1);
  FHasGuidePoint := False;

  // mouse info
  FMousePos := Point(-1, -1);

  // uiterlijk
  Color := $00E1FFFF; // vast lichtgeel: clInfoBk is onder Linux-thema's vaak zwart

  // statusbar / titel
  FStatusBarHeight := 25;
  FColorInput := clGreen;
  FColorProcessing := clRed;
  FColorOutput := clBlue;
  FShowSelectionDimensions := True;

  // taal
  FLanguage := lgDutch;
  FInputText := 'INVOER';
  FProcessingText := 'VERWERKING';
  FOutputText := 'UITVOER';

  // layout
  FBox := True;
  FTitel := '';
  FTitelColor := clNavy;

  // rulers
  FShowRulers := True;
  FRulerTopHeight := 20;
  FRulerRightWidth := 42;
  FRulerColor := clBtnFace;
  FRulerTextColor := clBlack;
  FRulerTickColor := clGray;

  // magnetische snap
  FMagneticSnap := True;
  FSnapTolerance := 4;
  FMajorSnapMultiplier := 5;

  // hints titel
  ShowHint := True;
  ParentShowHint := False;

  // kaders
  FGridMode := gmNormal;
  FFrames := TList.Create;
  FActiveFrame := nil;
  FFrameDragging := False;
  FFrameHit := fhNone;
  FFrameStartMouse := Point(0, 0);
  FFrameStartRect := Types.Rect(0, 0, 0, 0);
  FFrameMinSize := 20;

  FHasGuidePoint:=False;

  UpdateTextForLanguage;

  ControlStyle := ControlStyle + [csOpaque, csAcceptsControls];
end;

function TjanGridS.GetTitleHeight: Integer;
begin
  if Trim(FTitel) <> '' then
    Result := Canvas.TextHeight('Ag') + 4
  else
    Result := 0;
end;


function TjanGridS.GetGridLeftOffset: Integer;
begin
  if FBox then
    Result := 48
  else
    Result := 3;
end;

function TjanGridS.GetTitleTop: Integer;
begin
  Result := FStatusBarHeight + 3;
end;

function TjanGridS.GetTopRulerRect: TRect;
var
  L, TopY, RightEdge: Integer;
begin
  L := GetGridLeftOffset;
  TopY := GetTitleTop + GetTitleHeight;

  RightEdge := Width - 3;
  if FShowRulers then
    Dec(RightEdge, FRulerRightWidth);

  Result := Rect(L, TopY, RightEdge, TopY + FRulerTopHeight);
end;



function TjanGridS.GetRightRulerRect: TRect;
var
  TopY: Integer;
begin
  TopY := GetTopRulerRect.Bottom;
  Result := Rect(Width - 3 - FRulerRightWidth, TopY, Width - 3, Height - 3);
end;

function TjanGridS.GetWorkAreaRect: TRect;
var
  L, T, R: Integer;
begin
  L := GetGridLeftOffset;
  T := GetTitleTop + GetTitleHeight;

  if FShowRulers then
    Inc(T, FRulerTopHeight);

  R := Width - 3;
  if FShowRulers then
    Dec(R, FRulerRightWidth);

  Result := Rect(L, T, R, Height - 3);
end;


function TjanGridS.NormalizeSelectionRect(const R: TRect): TRect;
begin
  Result := NormalizeRect(R);
end;


procedure TjanGridS.SetTitel(const Value: string);
begin
  if FTitel <> Value then
  begin
    FTitel := Value;
    Invalidate;
  end;
end;

procedure TjanGridS.SetTitelColor(const Value: TColor);
begin
  if FTitelColor <> Value then
  begin
    FTitelColor := Value;
    Invalidate;
  end;
end;

procedure TjanGridS.SetInputText(const Value: string);
begin
  if FInputText <> Value then
  begin
    FInputText := Value;
    Invalidate;
  end;
end;

procedure TjanGridS.SetOutputText(const Value: string);
begin
  if FOutputText <> Value then
  begin
    FOutputText := Value;
    Invalidate;
  end;
end;

procedure TjanGridS.SetProcessingText(const Value: string);
begin
  if FProcessingText <> Value then
  begin
    FProcessingText := Value;
    Invalidate;
  end;
end;

procedure TjanGridS.SetBox(Value: Boolean);
var
  i: NativeInt;
  NoteBook: TNoteBook;
  BaseLeft: Integer;
begin
  if Value = FBox then
    Exit;

  FBox := Value;

  for i := 0 to ControlCount - 1 do
  begin
    if Controls[i] is TNoteBook then
    begin
      NoteBook := TNoteBook(Controls[i]);

      BaseLeft := (ClientWidth - NoteBook.Width) div 2;

      if FBox then
        NoteBook.Left := BaseLeft + 23
      else
        NoteBook.Left := BaseLeft;

      Break;
    end;
  end;

  Invalidate;
end;

procedure TjanGridS.SetLanguage(const Value: TLanguage);
begin
  if FLanguage <> Value then
  begin
    FLanguage := Value;

    UpdateTextForLanguage;
     UpdateFrameHints;
     UpdateFramePopupCaptions;
     invalidate;
  end;
end;

procedure TjanGridS.UpdateTextForLanguage;
begin
  case FLanguage of
    lgEnglish:
      begin
        FInputText := 'Input';
        FProcessingText := 'Processing';
        FOutputText := 'Output';
        FTitel := 'Logic Panel';
      end;
    lgFrench:
      begin
        FInputText := 'Entrée';
        FProcessingText := 'Traitement';
        FOutputText := 'Sortie';
        FTitel := 'Panneau logique';
      end;
    lgDutch:
      begin
        FInputText := 'Invoer';
        FProcessingText := 'Verwerken';
        FOutputText := 'Uitvoer';
        FTitel := 'Logisch Paneel';
      end;
    lgGerman:
      begin
        FInputText := 'Import';
        FProcessingText := 'Verfahren';
        FOutputText := 'Export';
        FTitel := 'Logikpanel';
      end;
  end;
  Invalidate;
end;

procedure TjanGridS.PaintSelectionDimensions;
var
  Tekst: string;
  TextWidth, TextHeight: Integer;
  TextX, TextY: Integer;
  NR: TRect;
begin
  if FIsDrawing and FShowSelectionDimensions then
  begin
    NR := NormalizeSelectionRect(FRect);
    Tekst := Format('W: %d H: %d', [Abs(NR.Right - NR.Left), Abs(NR.Bottom - NR.Top)]);
    TextWidth := Canvas.TextWidth(Tekst);
    TextHeight := Canvas.TextHeight(Tekst);

    Canvas.Font.Color := clNavy;
    Canvas.Brush.Style := bsClear;

    TextX := (NR.Left + NR.Right) div 2 - (TextWidth div 2);
    TextY := NR.Top - TextHeight - 4;
    if TextY < 0 then
      TextY := 0;

    Canvas.TextOut(TextX, TextY, Tekst);
    Canvas.Brush.Style := bsSolid;
  end;
end;

function TjanGridS.GetStatusBarRect: TRect;
begin
  if Box then
    Result := Rect(48, 2, Width - 3, FStatusBarHeight)
  else
    Result := Rect(3, 2, Width - 3, FStatusBarHeight);
end;

procedure TjanGridS.DrawStatusBar;
var
  StatusBarRect: TRect;
  SectionWidth, TextWidth, TextHeight, CenterX, CenterY: NativeInt;
  TextX, TextY: NativeInt;
  RectT: TRect;
begin
  StatusBarRect := GetStatusBarRect;
  SectionWidth := StatusBarRect.Width div 3;

  // Input-sectie
  Canvas.Brush.Color := FColorInput;
  Canvas.FillRect(Rect(StatusBarRect.Left, StatusBarRect.Top,
    StatusBarRect.Left + SectionWidth, StatusBarRect.Bottom));
  Canvas.Font.Color := clWhite;
  Canvas.Font.Style := [fsBold];
  TextWidth := Canvas.TextWidth(FInputText);
  TextHeight := Canvas.TextHeight(FInputText);
  CenterX := (StatusBarRect.Left + (StatusBarRect.Left + SectionWidth) - TextWidth) div 2;
  CenterY := (StatusBarRect.Top + StatusBarRect.Bottom - TextHeight) div 2;
  Canvas.TextOut(CenterX, CenterY, FInputText);

  // Processing-sectie
  Canvas.Brush.Color := FColorProcessing;
  Canvas.FillRect(Rect(StatusBarRect.Left + SectionWidth, StatusBarRect.Top,
    StatusBarRect.Left + 2 * SectionWidth, StatusBarRect.Bottom));
  TextWidth := Canvas.TextWidth(FProcessingText);
  TextHeight := Canvas.TextHeight(FProcessingText);
  CenterX := (StatusBarRect.Left + SectionWidth +
             (StatusBarRect.Left + 2 * SectionWidth) - TextWidth) div 2;
  CenterY := (StatusBarRect.Top + StatusBarRect.Bottom - TextHeight) div 2;
  Canvas.TextOut(CenterX, CenterY, FProcessingText);

  // Output-sectie
  Canvas.Brush.Color := FColorOutput;
  Canvas.FillRect(Rect(StatusBarRect.Left + 2 * SectionWidth, StatusBarRect.Top,
    StatusBarRect.Right, StatusBarRect.Bottom));
  TextWidth := Canvas.TextWidth(FOutputText);
  TextHeight := Canvas.TextHeight(FOutputText);
  CenterX := (StatusBarRect.Left + 2 * SectionWidth + StatusBarRect.Right - TextWidth) div 2;
  CenterY := (StatusBarRect.Top + StatusBarRect.Bottom - TextHeight) div 2;
  Canvas.TextOut(CenterX, CenterY, FOutputText);

  // Titel alleen tekenen als die niet leeg is
  if Trim(FTitel) <> '' then
  begin
    Canvas.Font.Size := 8;
    Canvas.Font.Style := [fsBold];
    Canvas.Font.Color := FTitelColor;

    TextWidth := Canvas.TextWidth(FTitel);
    TextHeight := Canvas.TextHeight(FTitel);

    if not FBox then
      TextX := (Width - TextWidth) div 2
    else
      TextX := ((Width - TextWidth) div 2) + 23;

    TextY := FStatusBarHeight + 5;
    RectT := Rect(TextX, TextY, TextX + TextWidth, TextY + TextHeight);
    Canvas.TextRect(RectT, TextX, TextY, FTitel);
  end;
end;


procedure TjanGridS.DrawRulers;
var
  RTop, RRight, WorkR: TRect;
  x, y, Offset: Integer;
  Txt: string;
  TxtH: Integer;
begin
  if not FShowRulers then
    Exit;

  WorkR := GetWorkAreaRect;
  RTop := GetTopRulerRect;
  RRight := GetRightRulerRect;

  Canvas.Brush.Color := FRulerColor;
  Canvas.FillRect(RTop);
  Canvas.FillRect(RRight);

  Canvas.Pen.Color := FRulerTickColor;
  Canvas.Font.Color := FRulerTextColor;
  Canvas.Font.Style := [];
  Canvas.Brush.Style := bsClear;
  TxtH := Canvas.TextHeight('0');

  // horizontale ruler
  x := WorkR.Left;
  while x <= WorkR.Right do
  begin
    Offset := x - WorkR.Left;

    if (FGridX > 0) and ((Offset mod (FGridX * 5)) = 0) then
    begin
      Canvas.MoveTo(x, RTop.Bottom);
      Canvas.LineTo(x, RTop.Top + 3);
      Txt := IntToStr(Offset);
      Canvas.TextOut(x + 2, RTop.Top + 2, Txt);
    end
    else if (FGridX > 0) and ((Offset mod FGridX) = 0) then
    begin
      Canvas.MoveTo(x, RTop.Bottom);
      Canvas.LineTo(x, RTop.Bottom - 6);
    end;

    Inc(x);
  end;

  // verticale ruler
  y := WorkR.Top;
  while y <= WorkR.Bottom do
  begin
    Offset := y - WorkR.Top;

    if (FGridY > 0) and ((Offset mod (FGridY * 5)) = 0) then
    begin
      Canvas.MoveTo(RRight.Left, y);
      Canvas.LineTo(RRight.Left + 10, y);
      Txt := IntToStr(Offset);
      Canvas.TextOut(RRight.Left + 12, y - (TxtH div 2), Txt);
    end
    else if (FGridY > 0) and ((Offset mod FGridY) = 0) then
    begin
      Canvas.MoveTo(RRight.Left, y);
      Canvas.LineTo(RRight.Left + 6, y);
    end;

    Inc(y);
  end;

  // rand rond rulers
  Canvas.Pen.Color := clSilver;
  Canvas.Rectangle(RTop);
  Canvas.Rectangle(RRight);

  // markeringen op rulers alleen als guide lines zichtbaar mogen zijn
  if FShowGuideLines and FHasGuidePoint then
  begin
    Canvas.Pen.Color := clRed;

    if (FGuidePoint.X >= WorkR.Left) and (FGuidePoint.X <= WorkR.Right) then
    begin
      Canvas.MoveTo(FGuidePoint.X, RTop.Top);
      Canvas.LineTo(FGuidePoint.X, RTop.Bottom);
    end;

    if (FGuidePoint.Y >= WorkR.Top) and (FGuidePoint.Y <= WorkR.Bottom) then
    begin
      Canvas.MoveTo(RRight.Left, FGuidePoint.Y);
      Canvas.LineTo(RRight.Right, FGuidePoint.Y);
    end;
  end;

  Canvas.Brush.Style := bsSolid;
end;

procedure TjanGridS.Paint;
var
  WorkR: TRect;
  x, y: Integer;
  i: Integer;
begin
  inherited Paint;

  DrawStatusBar;
  DrawRulers;

  WorkR := GetWorkAreaRect;

  if FShowGrid and (FGridX > 0) and (FGridY > 0) then
  begin
    Canvas.Lock;
    try
      x := WorkR.Left;
      while x < WorkR.Right do
      begin
        y := WorkR.Top;
        while y < WorkR.Bottom do
        begin
          Canvas.Pixels[x, y] := FGridColor;
          Inc(y, FGridY);
        end;
        Inc(x, FGridX);
      end;
    finally
      Canvas.Unlock;
    end;
  end;

  if FShowGuideLines and FHasGuidePoint then
  begin
    Canvas.Pen.Color := clRed;
    Canvas.Pen.Style := psDot;
    Canvas.Pen.Width := 1;

    Canvas.MoveTo(FGuidePoint.X, WorkR.Top);
    Canvas.LineTo(FGuidePoint.X, WorkR.Bottom);

    Canvas.MoveTo(WorkR.Left, FGuidePoint.Y);
    Canvas.LineTo(WorkR.Right, FGuidePoint.Y);

    Canvas.Pen.Style := psSolid;
  end;

  PaintSelectionDimensions;
  DrawSelectionRectangle;

  for i := 0 to FFrames.Count - 1 do
    TGridFrame(FFrames[i]).Draw(Canvas);
end;


procedure TjanGridS.Resize;
begin
  inherited Resize;
  Invalidate;
end;

procedure TjanGridS.DrawSelectionRectangle;
var
  NR: TRect;
begin
  if FIsDrawing then
  begin
    NR := NormalizeSelectionRect(FRect);
    Canvas.Pen.Style := psSolid;
    Canvas.Pen.Color := clRed;
    Canvas.Brush.Style := bsClear;
    Canvas.Rectangle(NR);
    Canvas.Brush.Style := bsSolid;
  end;
end;

function TjanGridS.GetTitleRect: TRect;
var
  TxtWidth, TxtHeight, TextX, TextY: Integer;
begin
  Canvas.Font.Size := 8;
  Canvas.Font.Style := [fsBold];

  TxtWidth  := Canvas.TextWidth(FTitel);
  TxtHeight := Canvas.TextHeight(FTitel);

  if not FBox then
    TextX := (Width - TxtWidth) div 2
  else
    TextX := ((Width - TxtWidth) div 2) + 23;

  TextY := FStatusBarHeight + 5;

  Result := Rect(TextX, TextY, TextX + TxtWidth, TextY + TxtHeight);
end;

function TjanGridS.MagneticSnapValue(Value, Origin, StepSize, Tolerance: Integer): Integer;
var
  RelativeValue: Integer;
  SnapValue: Integer;
begin
  if StepSize <= 0 then
    Exit(Value);

  RelativeValue := Value - Origin;
  SnapValue := (RelativeValue div StepSize) * StepSize;

  if Abs(RelativeValue - SnapValue) <= Tolerance then
    Result := Origin + SnapValue
  else if Abs(RelativeValue - (SnapValue + StepSize)) <= Tolerance then
    Result := Origin + SnapValue + StepSize
  else
    Result := Value;
end;

function TjanGridS.SnapPointToRuler(const P: TPoint; const WorkR: TRect): TPoint;
var
  MajorX, MajorY: Integer;
begin
  Result := P;

  if not FMagneticSnap then
    Exit;

  MajorX := FGridX * FMajorSnapMultiplier;
  MajorY := FGridY * FMajorSnapMultiplier;

  if MajorX > 0 then
    Result.X := MagneticSnapValue(Result.X, WorkR.Left, MajorX, FSnapTolerance);

  if MajorY > 0 then
    Result.Y := MagneticSnapValue(Result.Y, WorkR.Top, MajorY, FSnapTolerance);

  if FGridX > 0 then
    Result.X := MagneticSnapValue(Result.X, WorkR.Left, FGridX, FSnapTolerance);

  if FGridY > 0 then
    Result.Y := MagneticSnapValue(Result.Y, WorkR.Top, FGridY, FSnapTolerance);
end;


function TjanGridS.SnapToGridValue(Value, GridSize: NativeInt): NativeInt;
begin
  if GridSize <= 0 then
    Result := Value
  else
    Result := (Value div GridSize) * GridSize;
end;

{
procedure TjanGridS.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  WorkR, TitleRect: TRect;
  P: TPoint;
  Hit: TFrameHit;
  PScreen: TPoint;
begin
  FMousePos := Point(X, Y);
  TitleRect := GetTitleRect;

  // klik op titel
  if (Button = mbLeft) and PtInRect(TitleRect, Point(X, Y)) then
  begin
    if Assigned(FOnTitleClick) then
      FOnTitleClick(Self);
    Exit;
  end;

  WorkR := GetWorkAreaRect;
  if not PtInRect(WorkR, Point(X, Y)) then
    Exit;

  // RECHTERKLIK = popup op kader
  if Button = mbRight then
  begin
    FActiveFrame := FrameAtPoint(Point(X, Y), Hit);

    if not Assigned(FActiveFrame) then
    begin
      Hit := fhNone;
      FActiveFrame := FrameBodyAtPoint(Point(X, Y));
    end;

    DeselectAllFrames;

    if Assigned(FActiveFrame) then
    begin
      FActiveFrame.Selected := True;
      FFrameHit := Hit;
      BuildFramePopup;

      PScreen := ClientToScreen(Point(X, Y));
      FFramePopup.PopUp(PScreen.X, PScreen.Y);

      Invalidate;
      Exit;
    end;
  end;

  // LINKERKLIK
  if Button = mbLeft then
  begin
    case FGridMode of
      gmFrameDraw:
        begin
          DeselectAllFrames;

          if FSnapToGrid then
            P := SnapPointToRuler(Point(X, Y), WorkR)
          else
            P := Point(X, Y);

          FActiveFrame := AddFrame(Types.Rect(P.X, P.Y, P.X, P.Y), 'Kader');
          FFrameDragging := True;
          FFrameHit := fhBottomRight;
          FFrameStartMouse := P;
          FFrameStartRect := FActiveFrame.FrameRect;

          Invalidate;
          Exit;
        end;

      gmFrameEdit:
        begin
          // eerst zoeken op grips / move-cirkel
          FActiveFrame := FrameAtPoint(Point(X, Y), Hit);

          // als niets geraakt: kijken of we in het kaderlichaam zitten
          if not Assigned(FActiveFrame) then
          begin
            Hit := fhNone;
            FActiveFrame := FrameBodyAtPoint(Point(X, Y));
          end;

          DeselectAllFrames;

          if Assigned(FActiveFrame) then
          begin
            FActiveFrame.Selected := True;
            FFrameHit := Hit;

            // alleen slepen als echt op grip of move-cirkel geklikt werd
            if Hit <> fhNone then
            begin
              FFrameDragging := True;
              FFrameStartMouse := Point(X, Y);
              FFrameStartRect := FActiveFrame.FrameRect;
            end
            else
              FFrameDragging := False;

            Invalidate;
            Exit;
          end
          else
          begin
            // klik op leeg gebied = alles deselecteren
            FFrameDragging := False;
            Invalidate;
          end;
        end;
    end;

    // gewone capture-logica
    FIsDrawing := FCapture;

    if FSnapToGrid then
    begin
      P := SnapPointToRuler(Point(X, Y), WorkR);
      FRect.TopLeft := P;
    end
    else
      FRect.TopLeft := Point(X, Y);

    FRect.BottomRight := FRect.TopLeft;

    if Assigned(FOnMouseDown) then
      FOnMouseDown(Self, Button, Shift, X, Y);
  end;
end;
}
procedure TjanGridS.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  WorkR, TitleRect: TRect;
  P: TPoint;
  Hit: TFrameHit;
  PScreen: TPoint;
  ClickedFrame: TGridFrame;
begin
  inherited MouseDown(Button, Shift, X, Y);

  FMousePos := Point(X, Y);
  TitleRect := GetTitleRect;

  // klik op titel
  if (Button = mbLeft) and PtInRect(TitleRect, Point(X, Y)) then
  begin
    if Assigned(FOnTitleClick) then
      FOnTitleClick(Self);
    Exit;
  end;

  WorkR := GetWorkAreaRect;
  if not PtInRect(WorkR, Point(X, Y)) then
    Exit;

  // =========================
  // RECHTERKLIK = popup op kader
  // =========================
  if Button = mbRight then
  begin
    ClickedFrame := FrameAtPoint(Point(X, Y), Hit);

    if not Assigned(ClickedFrame) then
    begin
      Hit := fhNone;
      ClickedFrame := FrameBodyAtPoint(Point(X, Y));
    end;

    if Assigned(ClickedFrame) then
    begin
      DeselectAllFrames;

      FActiveFrame := ClickedFrame;
      FActiveFrame.Selected := True;
      FFrameHit := Hit;

      BuildFramePopup;

      PScreen := ClientToScreen(Point(X, Y));
      FFramePopup.PopUp(PScreen.X, PScreen.Y);

      Invalidate;
      Exit;
    end
    else
    begin
      DeselectAllFrames;
      FActiveFrame := nil;
      Invalidate;
      Exit;
    end;
  end;

  // =========================
  // LINKERKLIK
  // =========================
  if Button = mbLeft then
  begin
    case FGridMode of
      gmFrameDraw:
        begin
          DeselectAllFrames;

          if FSnapToGrid then
            P := SnapPointToRuler(Point(X, Y), WorkR)
          else
            P := Point(X, Y);

          FActiveFrame := AddFrame(Types.Rect(P.X, P.Y, P.X, P.Y), 'Kader');
          if Assigned(FActiveFrame) then
            FActiveFrame.Selected := True;

          FFrameDragging := True;
          FFrameHit := fhBottomRight;
          FFrameStartMouse := P;
          FFrameStartRect := FActiveFrame.FrameRect;

          Invalidate;
          Exit;
        end;

      gmFrameEdit:
        begin
          // eerst zoeken op grips / move-cirkel
          ClickedFrame := FrameAtPoint(Point(X, Y), Hit);

          // als niets geraakt: kijken of we in het kaderlichaam zitten
          if not Assigned(ClickedFrame) then
          begin
            Hit := fhNone;
            ClickedFrame := FrameBodyAtPoint(Point(X, Y));
          end;

          if Assigned(ClickedFrame) then
          begin
            DeselectAllFrames;

            FActiveFrame := ClickedFrame;
            FActiveFrame.Selected := True;
            FFrameHit := Hit;

            // alleen slepen/resizen als echt op grip of move-greep geklikt werd
            if Hit <> fhNone then
            begin
              FFrameDragging := True;
              FFrameStartMouse := Point(X, Y);
              FFrameStartRect := FActiveFrame.FrameRect;
            end
            else
              FFrameDragging := False;

            Invalidate;
            Exit;
          end
          else
          begin
            // klik op leeg gebied = deselecteren
            DeselectAllFrames;
            FActiveFrame := nil;
            FFrameDragging := False;
            Invalidate;
            Exit;
          end;
        end;
    end;

    // gewone capture-logica
    FIsDrawing := FCapture;

    if FSnapToGrid then
    begin
      P := SnapPointToRuler(Point(X, Y), WorkR);
      FRect.TopLeft := P;
    end
    else
      FRect.TopLeft := Point(X, Y);

    FRect.BottomRight := FRect.TopLeft;

    if Assigned(FOnMouseDown) then
      FOnMouseDown(Self, Button, Shift, X, Y);
  end;
end;

procedure TjanGridS.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  WorkR, TitleRect: TRect;
  PX, PY: Integer;
  P: TPoint;
  RelX, RelY: Integer;
  S: string;
  DX, DY: Integer;
  R2: TRect;
  Hit: TFrameHit;
  HoverFrame: TGridFrame;      // voor cursor / resize / move
  HoverBodyFrame: TGridFrame;  // voor hint over volledig kader
begin
  inherited MouseMove(Shift, X, Y);

  FMousePos := Point(X, Y);
  TitleRect := GetTitleRect;

  // =========================
  // HOVER OP TITEL
  // =========================
  if PtInRect(TitleRect, Point(X, Y)) then
  begin
    Cursor := crHelp;
    ShowCustomHint(BuildTitleHint(FLanguage), X, Y);

    if FHasGuidePoint then
    begin
      FHasGuidePoint := False;
      Invalidate;
    end;

    Exit;
  end;

  WorkR := GetWorkAreaRect;

  // =========================
  // FRAME DRAG / RESIZE
  // =========================
  if FFrameDragging and (ssLeft in Shift) and Assigned(FActiveFrame) then
  begin
    DX := X - FFrameStartMouse.X;
    DY := Y - FFrameStartMouse.Y;
    R2 := FFrameStartRect;

    case FFrameHit of
      fhMove:
        OffsetRect(R2, DX, DY);

      fhTopLeft:
        begin
          R2.Left := R2.Left + DX;
          R2.Top := R2.Top + DY;
        end;

      fhTopRight:
        begin
          R2.Right := R2.Right + DX;
          R2.Top := R2.Top + DY;
        end;

      fhBottomLeft:
        begin
          R2.Left := R2.Left + DX;
          R2.Bottom := R2.Bottom + DY;
        end;

      fhBottomRight:
        begin
          R2.Right := R2.Right + DX;
          R2.Bottom := R2.Bottom + DY;
        end;
    end;

    // minimum grootte
    if Abs(R2.Right - R2.Left) < FFrameMinSize then
      if FFrameHit in [fhTopLeft, fhBottomLeft] then
        R2.Left := R2.Right - FFrameMinSize
      else
        R2.Right := R2.Left + FFrameMinSize;

    if Abs(R2.Bottom - R2.Top) < FFrameMinSize then
      if FFrameHit in [fhTopLeft, fhTopRight] then
        R2.Top := R2.Bottom - FFrameMinSize
      else
        R2.Bottom := R2.Top + FFrameMinSize;

    // binnen werkgebied houden
    if R2.Left < WorkR.Left then
      OffsetRect(R2, WorkR.Left - R2.Left, 0);
    if R2.Top < WorkR.Top then
      OffsetRect(R2, 0, WorkR.Top - R2.Top);
    if R2.Right > WorkR.Right then
      OffsetRect(R2, WorkR.Right - R2.Right, 0);
    if R2.Bottom > WorkR.Bottom then
      OffsetRect(R2, 0, WorkR.Bottom - R2.Bottom);

    FActiveFrame.FrameRect := R2;
    Invalidate;
    Exit;
  end;

  // =========================
  // CURSOR + FRAME HINT
  // =========================
  HoverFrame := nil;
  HoverBodyFrame := nil;

  if FGridMode = gmFrameEdit then
  begin
    // voor move/resize cursor
    HoverFrame := FrameAtPoint(Point(X, Y), Hit);

    // voor hint over volledig kader
    HoverBodyFrame := FrameBodyAtPoint(Point(X, Y));

    case Hit of
      fhMove: Cursor := crHandPoint;
      fhTopLeft, fhBottomRight: Cursor := crSizeNWSE;
      fhTopRight, fhBottomLeft: Cursor := crSizeNESW;
    else
      Cursor := crDefault;
    end;

    if Assigned(HoverBodyFrame) and (Trim(HoverBodyFrame.Info) <> '') then
      ShowCustomHint(HoverBodyFrame.Info, X, Y)
    else
      HideCustomHint;
  end
  else
    Cursor := crDefault;

  // =========================
  // BUITEN WERKGEBIED
  // =========================
  if not PtInRect(WorkR, Point(X, Y)) then
  begin
    HideCustomHint;

    if FHasGuidePoint then
    begin
      FHasGuidePoint := False;
      Invalidate;
    end;

    Exit;
  end;

  PX := X;
  PY := Y;

  if PX < WorkR.Left then PX := WorkR.Left;
  if PX > WorkR.Right then PX := WorkR.Right;
  if PY < WorkR.Top then PY := WorkR.Top;
  if PY > WorkR.Bottom then PY := WorkR.Bottom;

  // =========================
  // GUIDE LINES
  // =========================
  if FIsDrawing or FFrameDragging or FMouseMoveGuideLines then
  begin
    if (not FHasGuidePoint) or
       (FGuidePoint.X <> PX) or
       (FGuidePoint.Y <> PY) then
    begin
      FGuidePoint := Point(PX, PY);
      FHasGuidePoint := True;
      Invalidate;
    end;
  end
  else
  begin
    if FHasGuidePoint then
    begin
      FHasGuidePoint := False;
      Invalidate;
    end;
  end;

  // =========================
  // XY HINT
  // =========================
  if not (Assigned(HoverBodyFrame) and (Trim(HoverBodyFrame.Info) <> '')) then
  begin
    RelX := PX - WorkR.Left;
    RelY := PY - WorkR.Top;
    S := Format('X=%d  Y=%d', [RelX, RelY]);
    ShowCustomHint(S, X, Y);

  end;

  // Hint

  // =========================
  // GEWONE CAPTURE-SELECTIE
  // =========================
  if FIsDrawing then
  begin
    if FSnapToGrid then
    begin
      P := SnapPointToRuler(Point(PX, PY), WorkR);
      FRect.BottomRight := P;
    end
    else
      FRect.BottomRight := Point(PX, PY);
  end;

  if Assigned(FOnMouseMove) then
    FOnMouseMove(Self, Shift, X, Y);
end;


procedure TjanGridS.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  R: TRect;
begin
  if Button = mbLeft then
  begin
    // stop frame drag / resize
    FFrameDragging := False;
    FFrameHit := fhNone;

    // na kader tekenen automatisch naar edit-modus
    if FGridMode = gmFrameDraw then
    begin
      if Assigned(FActiveFrame) then
      begin
        R := NormalizeRect(FActiveFrame.FrameRect);

        // te klein kader verwijderen
        if ((R.Right - R.Left) < FFrameMinSize) or
           ((R.Bottom - R.Top) < FFrameMinSize) then
        begin
          FFrames.Remove(FActiveFrame);
          FActiveFrame.Free;
          FActiveFrame := nil;
        end;
      end;

      FGridMode := gmFrameEdit;
    end;

    // gewone capture-selectie
    if FIsDrawing then
    begin
      FIsDrawing := False;
      FShowSelectionDimensions := True;
      Invalidate;
      CaptureSelectedRegion;
    end
    else
      Invalidate;

    if Assigned(FOnMouseUp) then
      FOnMouseUp(Self, Button, Shift, X, Y);
  end;
end;


procedure TjanGridS.MouseLeave;
begin
  inherited MouseLeave;

  Cursor := crDefault;

  HideCustomHint;

  if FHasGuidePoint then
  begin
    FHasGuidePoint := False;
    Invalidate;
  end;
end;

procedure TjanGridS.CaptureSelectedRegion;
var
  Bitmap: TBitmap;
  SelectionWidth, SelectionHeight: NativeInt;
  Img: TLazIntfImage;
  Writer: TFPCustomImageWriter;
  NR: TRect;
begin
  NR := NormalizeSelectionRect(FRect);
  SelectionWidth := NR.Right - NR.Left;
  SelectionHeight := NR.Bottom - NR.Top;
  if (SelectionWidth <= 0) or (SelectionHeight <= 0) then
    Exit;

  Bitmap := TBitmap.Create;
  try
    Bitmap.Width := SelectionWidth;
    Bitmap.Height := SelectionHeight;
    Bitmap.Canvas.CopyRect(Rect(0, 0, SelectionWidth, SelectionHeight), Canvas, NR);

    case FSaveFormat of
      sfBMP:
        Bitmap.SaveToFile('SelectedRegion.bmp');
      sfClipbrd:
        Clipboard.Assign(Bitmap);
      sfJPG:
        begin
          Writer := TFPWriterJPEG.Create;
          try
            Img := Bitmap.CreateIntfImage;
            try
              Img.SaveToFile('SelectedRegion.jpg', Writer);
            finally
              Img.Free;
            end;
          finally
            Writer.Free;
          end;
        end;
      sfPNG:
        begin
          Writer := TFPWriterPNG.Create;
          try
            Img := Bitmap.CreateIntfImage;
            try
              Img.SaveToFile('SelectedRegion.png', Writer);
            finally
              Img.Free;
            end;
          finally
            Writer.Free;
          end;
        end;
    end;
  finally
    Bitmap.Free;
  end;
end;

procedure TjanGridS.BeginGuideLines(AX, AY: Integer);
begin
  UpdateGuideLines(AX, AY);
end;


procedure TjanGridS.UpdateGuideLines(AX, AY: Integer);
var
  WorkR: TRect;
  PX, PY: Integer;
begin
  WorkR := GetWorkAreaRect;

  PX := AX;
  PY := AY;

  if PX < WorkR.Left then PX := WorkR.Left;
  if PX > WorkR.Right then PX := WorkR.Right;
  if PY < WorkR.Top then PY := WorkR.Top;
  if PY > WorkR.Bottom then PY := WorkR.Bottom;

  FGuidePoint := Point(PX, PY);
  FHasGuidePoint := True;

  Invalidate;
end;

procedure TjanGridS.EndGuideLines;
begin
  FHasGuidePoint := False;
  Invalidate;
end;


destructor TjanGridS.Destroy;
var
  i: Integer;
begin
  for i := 0 to FFrames.Count - 1 do
    TObject(FFrames[i]).Free;

  FFrames.Free;
  inherited Destroy;
end;


end.

