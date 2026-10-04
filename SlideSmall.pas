unit SlideSmall;

{$mode objfpc}{$H+}

interface



uses

  LCLIntf, LCLType,
  SysUtils, Classes, Graphics,Controls,Forms, Dialogs,extctrls,
  menus,LResources; //
type
  TBarStyle    = (bsLowered,bsRaised);
  TOrientation = (orVertical,orHorizontal);
  TThumbStyle  = (tsBar1,tsBar2,tsBar3,tsBar4,tsCircle1,tsSquare1,
                  tsDiamond1,tsDiamond2,tsDiamond3,tsDiamond4);
  TSlideSmall = class(TCustomControl)
  private
    FMax,FMin,FPosition      : Integer;
    FOrientation             : TOrientation;
    FStyle                   : TBarStyle;
    FThickness               : Byte;
    FThumbStyle              : TThumbStyle;
    FTicks                   : Boolean;
    FOnChange                : TNotifyEvent;
    ThumbBmp,MaskBmp,BkgdBmp : TBitmap;
    DragVal,HalfTW,HalfTH    : Integer;
    ThumbRect                : TRect;
  //  TempDC                   : HDC;
    DraggingN                 : Boolean;
    procedure SetMax(A: Integer);
    procedure SetMin(A: Integer);
    procedure SetOrientation(A: TOrientation);
    procedure SetPosition(A: Integer);
    procedure SetStyle(A: TBarStyle);
    procedure SetThickness(A: Byte);
    procedure SetThumbStyle(A: TThumbStyle);
    procedure SetTicks(A: Boolean);
 protected
    procedure Paint; override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    function  NewPosition(WhereX,WhereY: Integer): Integer;
    function  IsVert: Boolean;
    procedure RemoveThumbBar;
    procedure DrawThumbBar;
    procedure DrawTrench;
    procedure SaveBackground;
    procedure WhereIsBar;
    procedure SetTLColor;
    procedure SetBRColor;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Enabled;
   // property Dragging;
    property Max: Integer read FMax write SetMax default 10;
    property Min: Integer read FMin write SetMin default 1;
    property Orientation: TOrientation read FOrientation
                          write SetOrientation default orHorizontal;
    property Position: Integer read FPosition write SetPosition default 1;
    property Style: TBarStyle read FStyle write SetStyle default bsLowered;
    property Thickness: Byte read FThickness write SetThickness default 1;
    property ThumbStyle: TThumbStyle read FThumbStyle
                         write SetThumbStyle default tsCircle1;
    property Ticks: Boolean read FTicks write SetTicks default True;
    property Visible;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

procedure Register;

implementation

function MinInt(A,B: Integer): Integer;
begin
  If A > B Then MinInt := B Else MinInt := A;
end;

function MaxInt(A,B: Integer): Integer;
begin
  If A > B Then MaxInt := A Else MaxInt := B;
end;

procedure Register;
begin
  {$I SlideBarn.lrs}
  RegisterComponents('JWLOGIC', [TSlideSmall]);
end;

constructor TSlideSmall.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Height := 15;
  Width := 48;
  ThumbBmp := TBitmap.Create;
  MaskBmp := TBitmap.Create;
  BkgdBmp := TBitmap.Create;
  FMin := 0;
  FMax := 4;
  FOrientation := orHorizontal;
  FPosition := 2;
  FStyle := bsLowered;
  FThickness := 3;
  FTicks := true;
  DraggingN := False;
  DragVal := 0;
  ThumbStyle := tsDiamond4;
  Top:=50;Left:=1;
  visible:=true;

end;

destructor TSlideSmall.Destroy;
begin
  ThumbBmp.Free;
  MaskBmp.Free;
  BkgdBmp.Free;
  inherited Destroy;
end;

function TSlideSmall.IsVert: Boolean;
begin
  IsVert := (Orientation = orVertical);
end;

procedure TSlideSmall.SetMin(A: Integer);
begin
  FMin := A;
  Refresh;
end;

procedure TSlideSmall.SetMax(A: Integer);
begin
  FMax := A;
  Refresh;
end;

procedure TSlideSmall.SetOrientation(A: TOrientation);
begin
  FOrientation := A;
  Refresh;
end;

procedure TSlideSmall.SetPosition(A: Integer);
begin
  if csDesigning in ComponentState then
    begin
      if (A >= Min) and (A <= Max) Then FPosition := A;
      Refresh;
    end
  else
    begin
      RemoveThumbBar;
      if (A >= Min) and (A <= Max) Then FPosition := A;
      WhereIsBar;
      SaveBackground;
      DrawThumbBar;
      if Assigned(FOnChange) then FOnChange(Self);
    end;
end;

procedure TSlideSmall.SetStyle(A: TBarStyle);
begin
  FStyle := A;
  Refresh;
end;

procedure TSlideSmall.SetThickness(A: Byte);
begin
  If (A > 0) and (A < 6) then
    begin FThickness := A; Refresh; end;
end;

procedure TSlideSmall.SetThumbStyle(A: TThumbStyle);
begin
  if FThumbStyle <> A then
  begin
    FThumbStyle := A;

    case FThumbStyle of
      tsBar1     : ThumbBmp.LoadFromLazarusResource('BAR1');
      tsBar2     : ThumbBmp.LoadFromLazarusResource('BAR2');
      tsBar3     : ThumbBmp.LoadFromLazarusResource('BAR3');
      tsBar4     : ThumbBmp.LoadFromLazarusResource('BAR4');
      tsCircle1  : ThumbBmp.LoadFromLazarusResource('CIRCLE1');
      tsSquare1  : ThumbBmp.LoadFromLazarusResource('SQUARE1');
      tsDiamond1 : ThumbBmp.LoadFromLazarusResource('DIAMOND1');
      tsDiamond2 : ThumbBmp.LoadFromLazarusResource('DIAMOND2');
      tsDiamond3 : ThumbBmp.LoadFromLazarusResource('DIAMOND3');
      tsDiamond4 : ThumbBmp.LoadFromLazarusResource('DIAMOND4');
    end;

    case FThumbStyle of
      tsBar1     : MaskBmp.LoadFromLazarusResource('BAR1MASK');
      tsBar2     : MaskBmp.LoadFromLazarusResource('BAR2MASK');
      tsBar3     : MaskBmp.LoadFromLazarusResource('BAR3MASK');
      tsBar4     : MaskBmp.LoadFromLazarusResource('BAR4MASK');
      tsCircle1  : MaskBmp.LoadFromLazarusResource('CIRCLE1MASK');
      tsSquare1  : MaskBmp.LoadFromLazarusResource('SQUARE1MASK');
      tsDiamond1 : MaskBmp.LoadFromLazarusResource('DIAMOND1MASK');
      tsDiamond2 : MaskBmp.LoadFromLazarusResource('DIAMOND2MASK');
      tsDiamond3 : MaskBmp.LoadFromLazarusResource('DIAMOND3MASK');
      tsDiamond4 : MaskBmp.LoadFromLazarusResource('DIAMOND4MASK');
    end;

    HalfTH := ThumbBmp.Height div 2;
    HalfTW := ThumbBmp.Width  div 2;
    Refresh;
  end;
end;

procedure TSlideSmall.SetTicks(A: Boolean);
begin
  FTicks := A;
  Refresh;
end;



function TSlideSmall.NewPosition(WhereX,WhereY: Integer): Integer;
var
  H1,W1 : Integer;
begin
  {Calculate the nearest position to where the mouse is located}
  H1 := Height-HalfTH;
  W1 := Width-HalfTW;
  if IsVert then
    Result := Round(((H1-WhereY)/H1)*(Max-Min)+Min)
  else
    Result := Round((WhereX/W1)*(Max-Min)+Min);
  Result := MinInt(MaxInt(Result,Min),Max);
end;



procedure TSlideSmall.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  A,B,C,D,E : Integer;
begin
  if Button <> mbLeft then exit;
  C := Position-1;
  D := Position;
  E := Position+1;
  {B is the center of the ThumbBar}
  if IsVert then B := ThumbRect.Top+HalfTH else B := ThumbRect.Left+HalfTW;
  if DraggingN then
    A := NewPosition(X,Y)
  else
    if IsVert then
      if Y < B then A := E else if Y > B then A := C else A := D
    else
      if X < B then A := C else if X > B then A := E else A := D;
  A := MinInt(MaxInt(A,Min),Max);
  DraggingN := False;
  Position := A;
end;

procedure TSlideSmall.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
   DraggingN:= PtInRect(ThumbRect,Point(X,Y));
  If IsVert then DragVal := Y else DragVal := X;
end;

procedure TSlideSmall.MouseMove(Shift: TShiftState; X, Y: Integer);
Var
  LastDragVal : Integer;
begin
  if (ssLeft in Shift) and DraggingN then
    begin
      LastDragVal := DragVal;
      if IsVert then DragVal := Y else DragVal := X;
      {This test eliminates unneccesary repaints}
      if DragVal <> LastDragVal then Position := NewPosition(X,Y);
    end;
end;

procedure TSlideSmall.RemoveThumbBar;
begin
   Canvas.Draw(ThumbRect.Left,ThumbRect.Top,BkgdBmp);
end;

procedure TSlideSmall.DrawThumbBar;
var
  TmpBmp  : TBitMap;
  Rect1: TRect;
begin
  try
   {Define a rectangle to mark the dimensions of the thumbbar}
    Rect1 := Rect(0,0,ThumbBmp.Width,ThumbBmp.Height);
    {Create a working bitmap}
    TmpBmp := TBitmap.Create;
    TmpBmp.Height := ThumbBmp.Height;
    TmpBmp.Width := ThumbBmp.Width;
    {Copy the background area onto the working bitmap}
    TmpBmp.Canvas.CopyMode := cmSrcCopy;
    TmpBmp.Canvas.CopyRect(Rect1,BkgdBmp.Canvas,Rect1);
    {Copy the mask onto the working bitmap with SRCAND}
    TmpBmp.Canvas.CopyMode := cmSrcAnd;
    TmpBmp.Canvas.CopyRect(Rect1,MaskBmp.Canvas,Rect1);
    {Copy the thumbbar onto the working bitmap with SRCPAINT}
    TmpBmp.Canvas.CopyMode := cmSrcPaint;
    TmpBmp.Canvas.CopyRect(Rect1,ThumbBmp.Canvas,Rect1);
    {Now draw the thumb bar}
    Canvas.CopyRect(ThumbRect,TmpBmp.Canvas,Rect1);
  finally
    TmpBmp.Free;
  end;
end;

procedure TSlideSmall.WhereIsBar;
var
  Each          : Real;
  ThumbX,ThumbY : Integer;
begin
  {Calculate where to paint the thumb bar - store in ThumbRect}
  if IsVert then
    begin
      Each := (Height-ThumbBmp.Height)/(Max-Min);
      If DraggingN then
        ThumbY := DragVal-HalfTH
      else
        ThumbY := Height-Round(Each*(Position-Min))-ThumbBmp.Height;
      ThumbY := MaxInt(0,MinInt(Height-ThumbBmp.Height,ThumbY));
      ThumbX := (Width-ThumbBmp.Width) div 2;
    end
  else
    begin
      Each := (Width-ThumbBmp.Width)/(Max-Min);
      if DraggingN then
        ThumbX := DragVal-HalfTW
      else
        ThumbX := Round(Each*(Position-Min));
      ThumbX := MaxInt(0,MinInt(Width-ThumbBmp.Width,ThumbX));
      ThumbY := (Height-ThumbBmp.Height) div 2;
    end;
  ThumbRect := Rect(ThumbX,ThumbY,ThumbX+ThumbBmp.Width,ThumbY+ThumbBmp.Height);
end;

procedure TSlideSmall.SetTLColor;
begin
  {Set the Top/Left color for the trench. Controls raised or lowered styles}
  With Canvas do
    if Style = bsLowered then Pen.Color := clGray else Pen.Color := clRed;
end;

procedure TSlideSmall.SetBRColor;
begin
  {Set the Bottom/Right color for the trench. Controls raised or lowered styles}
  With Canvas do
    if Style = bsRaised then Pen.Color := clGray else Pen.Color := clRed;
end;

procedure TSlideSmall.DrawTrench;
var
  X1,Y1,X2,Y2 : Integer;
  Each        : Real;
  Tmp,TickPos : Integer;
begin
  {This procedure simply draws the slot that the thumb bar will travel through}
  {including the tick-marks. The bar itself is not drawn.}
  with Canvas do begin
    {Calculate the corners of the trench dependant on orientation}
    if IsVert then
      begin
        X1 := (Width div 2) - (Thickness div 2) - 1;
        X2 := X1 + Thickness + 1;
        Y1 := HalfTH;
        Y2 := Height-ThumbBmp.Height+Y1;
      end
    else
      begin
        X1 := HalfTW;
        X2 := Width-ThumbBmp.Width+X1;
        Y1 := (Height div 2) - (Thickness div 2) - 1;
        Y2 := Y1 + Thickness + 1;
      end;
    Pen.Style := psSolid;
    {Set the color for the Top & Left edges}
    SetTLColor;
    MoveTo(X2,Y1);
    LineTo(X1,Y1);
    LineTo(X1,Y2);
    {Set the color for the Bottom & Right edges}
    SetBRColor;
    LineTo(X2,Y2);
    LineTo(X2,Y1-1);
    {Now do a filled black rectangle in the center if the control has focus}
    Pen.Style := psClear;
    {Draw the focus highlight}
    Rectangle(X1+1,Y1+1,X2+1,Y2+1);
    Pen.Style := psSolid;
    {Calculate spacing of tick marks}
    Each := 0;
    if Ticks then
      if (Max-Min) > 0 then
        if IsVert then
          Each := (Height-ThumbBmp.Height)/(Max-Min)
        else
          Each := (Width-ThumbBmp.Width)/(Max-Min);
    {Now draw the tick marks}
    if Ticks then
      for Tmp := Min to Max do
        if IsVert then
          begin
            TickPos := Y2-Trunc(Each*(Tmp-Min))-1;
            if Tmp = Max then TickPos := Y1;
            SetTLColor; MoveTo(X1,TickPos);   LineTo(X1-2,TickPos);
            SetBRColor; MoveTo(X1,TickPos+1); LineTo(X1-2,TickPos+1);
          end
        else
          begin
            TickPos := X1+Trunc(Each*(Tmp-Min));
            if Tmp = Max then TickPos := X2-1;
            SetTLColor; MoveTo(TickPos,Y1);   LineTo(TickPos,Y1-2);
            SetBRColor; MoveTo(TickPos+1,Y1); LineTo(TickPos+1,Y1-2);
          end;
      end;
end;

procedure TSlideSmall.SaveBackground;
begin
  {This saves the background image so it can be restored later}
  BkgdBmp.Width := ThumbBmp.Width;
  BkgdBmp.Height := ThumbBmp.Height;
  BkgdBmp.Canvas.CopyRect(Rect(0,0,ThumbBmp.Width,ThumbBmp.Height),Canvas,ThumbRect);
end;

procedure TSlideSmall.Paint;
begin
  DrawTrench;
  WhereIsBar;
  SaveBackground;
  DrawThumbBar;
end;

//implementation
     //{$I SlideBarn.lrs}
end.
