unit chatgridpcodeSmall;

{$mode ObjFPC}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages,
  SysUtils, Classes, Controls, Forms, Dialogs, Buttons,
  ExtCtrls, StdCtrls, ComCtrls,
  Graphics, Clipbrd, FPImage, IntfGraphics, FPWritePNG, FPWriteJPEG;

type
  TSaveFormat = (sfBMP, sfJPG, sfPNG, sfClipbrd);
  TLanguage = (lgEnglish, lgFrench, lgDutch, lgGerman);

  TTitleClickEvent = procedure(Sender: TObject) of object;

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
  end;


implementation

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

constructor TjanGridS.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

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
  FRect := Rect(0, 0, 0, 0);

  // guide lines
  FShowGuideLines := True;
  FGuidePoint := Point(-1, -1);
  FHasGuidePoint := False;

  // mouse info
  FMousePos := Point(-1, -1);

  // uiterlijk
  Color := clInfoBk;

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

  // Magnetische Snap
  FMagneticSnap := True;
  FSnapTolerance := 4;
  FMajorSnapMultiplier := 5;

  // Hints Titel
   ShowHint := True;
  ParentShowHint := False;

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
  WorkR,TitleRect: TRect;
  x, y: Integer;
begin
  inherited Paint;
  DrawStatusBar;
  DrawRulers;

   TitleRect := GetTitleRect;   // <-- hier

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


  // guide lines
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


procedure TjanGridS.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  WorkR, TitleRect: TRect;
  P: TPoint;
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

  // buiten werkgebied → niets doen
  if not PtInRect(WorkR, Point(X, Y)) then
    Exit;

  if Button = mbLeft then
  begin
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
begin
  inherited MouseMove(Shift, X, Y);

  FMousePos := Point(X, Y);
  TitleRect := GetTitleRect;

  // =========================
  // 1. TITEL HOVER
  // =========================
  if PtInRect(TitleRect, Point(X, Y)) then
  begin
    Cursor := crHelp;

    if Hint <> BuildTitleHint(FLanguage) then
    begin
      Hint := BuildTitleHint(FLanguage);
      Application.CancelHint;
      Application.ActivateHint(ClientToScreen(Point(X + 16, Y + 16)));
    end;

    FHasGuidePoint := False;
    Invalidate;
    Exit;
  end;

  // =========================
  // 2. WERKGEBIED
  // =========================
  WorkR := GetWorkAreaRect;

  if not PtInRect(WorkR, Point(X, Y)) then
  begin
    Cursor := crDefault;

    if Hint <> '' then
    begin
      Hint := '';
      Application.CancelHint;
    end;

    if FHasGuidePoint then
    begin
      FHasGuidePoint := False;
      Invalidate;
    end;

    Exit;
  end;

  Cursor := crDefault;

  // clamp binnen werkgebied
  PX := X;
  PY := Y;

  if PX < WorkR.Left then PX := WorkR.Left;
  if PX > WorkR.Right then PX := WorkR.Right;
  if PY < WorkR.Top then PY := WorkR.Top;
  if PY > WorkR.Bottom then PY := WorkR.Bottom;

  // =========================
  // 3. GUIDE LINES (rulers)
  // =========================
  if (not FHasGuidePoint) or
     (FGuidePoint.X <> PX) or
     (FGuidePoint.Y <> PY) then
  begin
    FGuidePoint := Point(PX, PY);
    FHasGuidePoint := True;
    Invalidate;
  end;

  // =========================
  // 4. XY HINT
  // =========================
  RelX := PX - WorkR.Left;
  RelY := PY - WorkR.Top;

  S := Format('X=%d  Y=%d', [RelX, RelY]);

  if Hint <> S then
  begin
    Hint := S;
    Application.CancelHint;
    Application.ActivateHint(ClientToScreen(Point(X + 16, Y + 16)));
  end;

  // =========================
  // 5. SELECTIE TEKENEN
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
begin
  if Button = mbLeft then
  begin
    FIsDrawing := False;
    FShowSelectionDimensions := True;

    Invalidate;
    CaptureSelectedRegion;

    if Assigned(FOnMouseUp) then
      FOnMouseUp(Self, Button, Shift, X, Y);
  end;
end;



procedure TjanGridS.MouseLeave;
begin
  inherited MouseLeave;

  Cursor := crDefault;

  if Hint <> '' then
  begin
    Hint := '';
    Application.CancelHint;
  end;

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
begin
  inherited Destroy;
end;

end.

