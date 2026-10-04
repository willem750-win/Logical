unit JanSimScope;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Graphics, Controls, Forms, ExtCtrls;

const
  JvScopeDefaultCapacity = 128;
  JvMinimumScopeWidth = 20;
  JvMinimumScopeHeight = 20;


type
  TJanWSimScope = class;

  TJanWScopeLineUnit = (jluPercent, jluAbsolute);

  TValues = array of Integer;

  TJanWScopeLineValues = class
  private
    FValues: TValues;
    FCount: Integer;
    FZeroIndex: Integer;

    procedure SetCapacity(const Value: Integer);
    function GetCapacity: Integer;
    function GetItem(Index: Integer): Integer;
  public
    procedure Assign(Source: TJanWScopeLineValues);
    procedure Add(Value: Integer);
    procedure Clear;

    property Capacity: Integer read GetCapacity write SetCapacity;
    property Count: Integer read FCount;
    property Items[Index: Integer]: Integer read GetItem; default;
  end;

  TJanWScopeLine = class(TCollectionItem)
  private
    FPosition: Integer;
    FColor: TColor;
    FName: string;
    FPositionUnit: TJanWScopeLineUnit;
    FValues: TJanWScopeLineValues;
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(ACollection: Classes.TCollection); override;
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;
    procedure Clear;
    property Values: TJanWScopeLineValues read FValues;
  published
    property Name: string read FName write FName;
    property Color: TColor read FColor write FColor default clLime;
    property Position: Integer read FPosition write FPosition default 50;
    property PositionUnit: TJanWScopeLineUnit read FPositionUnit write FPositionUnit default jluPercent;
  end;

  TJanWScopeLines = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TJanWScopeLine;
    procedure SetItem(Index: Integer; const Value: TJanWScopeLine);
  protected
    function GetOwner: TJanWSimScope; reintroduce;
    procedure Notify(Item: TCollectionItem; Action: TCollectionNotification); override;
  public
    constructor Create(AOwner: TJanWSimScope);
    procedure Assign(Source: TPersistent); override;
    procedure ClearValues;

    function Add: TJanWScopeLine;
    function IndexOfName(const AName: string): Integer;
    property Lines[Index: Integer]: TJanWScopeLine read GetItem write SetItem; default;
  end;

  TJanWSimScopeDisplayUnit = (jduPixels, jduLogical);

  TJanWSimScope = class(TGraphicControl)
  private
    FAllowed: Boolean;
    FOnUpdate: TNotifyEvent;
    FDrawBuffer: TBitmap;
    FDrawTimer: TTimer;
    FActive: Boolean;
    FBaseColor: TColor;
    FGridColor: TColor;
    FBaseLine: Integer;
    FInterval: Integer;
    FLines: TJanWScopeLines;
    FHorizontalGridSize: Integer;
    FVerticalGridSize: Integer;
    FDisplayUnits: TJanWSimScopeDisplayUnit;
    FMaximum: Integer;
    FMinimum: Integer;
    FBaseLineUnit: TJanWScopeLineUnit;
    FTotalTimeSteps: Integer;
    FUpdateTimeSteps: Integer;

    procedure SetActive(Value: Boolean);
    procedure SetGridSize(Value: Integer);
    procedure SetBaseLine(Value: Integer);
    procedure SetInterval(Value: Integer);
    procedure SetLines(const Value: TJanWScopeLines);
    procedure UpdateDisplay(ClearFirst: Boolean);
    procedure SetHorizontalGridSize(const Value: Integer);
    procedure SetVerticalGridSize(const Value: Integer);
    function GetGridSize: Integer;
    procedure SetDisplayUnits(const Value: TJanWSimScopeDisplayUnit);
    procedure SetMaximum(const Value: Integer);
    procedure SetMinimum(const Value: Integer);
    procedure UpdateComputedValues;
    procedure SetBaseLineUnit(const Value: TJanWScopeLineUnit);
    procedure SetTotalTimeSteps(const Value: Integer);
    procedure SetUpdateTimeSteps(const Value: Integer);
  protected
    FCalcBase: Integer;
    FStepPixelWidth: Double;
    FCounter: Double;
    procedure DrawTimerTimer(Sender: TObject);
    function GetLinePixelPosition(Line: TJanWScopeLine; Position: Integer): Integer;
    procedure Loaded; override;
    procedure Resize; override;
  public
    procedure Paint; override;
    constructor Create(AOwner: TComponent); override;
    procedure UpdateScope;
    destructor Destroy; override;
    procedure Clear;
    procedure ClearValues;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
  published
    property Active: Boolean read FActive write SetActive;
    property BaseColor: TColor read FBaseColor write FBaseColor default clRed;
    property BaseLine: Integer read FBaseLine write SetBaseLine default 50;
    property BaseLineUnit: TJanWScopeLineUnit read FBaseLineUnit write SetBaseLineUnit default jluPercent;
    property Color default clBlack;
    property DisplayUnits: TJanWSimScopeDisplayUnit read FDisplayUnits write SetDisplayUnits default jduPixels;
    property GridColor: TColor read FGridColor write FGridColor default clGreen;
    property GridSize: Integer read GetGridSize write SetGridSize stored False default 16;
    property HorizontalGridSize: Integer read FHorizontalGridSize write SetHorizontalGridSize default 16;
    property Height default 120;
    property Interval: Integer read FInterval write SetInterval default 50;
    property Lines: TJanWScopeLines read FLines write SetLines;
    property Minimum: Integer read FMinimum write SetMinimum;
    property Maximum: Integer read FMaximum write SetMaximum default 120;
    property TotalTimeSteps: Integer read FTotalTimeSteps write SetTotalTimeSteps default 208;
    property UpdateTimeSteps: Integer read FUpdateTimeSteps write SetUpdateTimeSteps default 2;
    property VerticalGridSize: Integer read FVerticalGridSize write SetVerticalGridSize default 16;
    property Width default 208;

    property OnUpdate: TNotifyEvent read FOnUpdate write FOnUpdate;

    property Align;
    property Anchors;
    property BorderSpacing;
    property ParentShowHint;
    property ShowHint;
    property Visible;

//    property OnCanResize;   -- wp: removed
    property OnClick;
    property OnConstrainedResize;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
  end;


implementation

//=== { TJanWScopeLineValues } =================================================

procedure TJanWScopeLineValues.Add(Value: Integer);
begin
  Assert(Assigned(Self));
  if Length(FValues)=Count then // auto-growby JvScopeDefaultCapacity
      SetCapacity( GetCapacity+JvScopeDefaultCapacity);

  if Count < Capacity then
  begin
    FValues[FCount] := Value;
    Inc(FCount);
  end
  else
  begin
    FValues[FZeroIndex] := Value;
    FZeroIndex := (FZeroIndex + 1) mod FCount;
  end;
end;

procedure TJanWScopeLineValues.Assign(Source: TJanWScopeLineValues);
var
  I: Integer;
begin
  if (not Assigned(Source)) then
      raise Exception.Create('TJanWScopeLineValues.Assign:Source not assigned');
  FCount := Source.FCount;
  FZeroIndex := Source.FZeroIndex;
  Capacity := Source.Capacity;
  for I := 0 to Source.Capacity - 1 do
    FValues[I] := Source.FValues[I];
end;

procedure TJanWScopeLineValues.Clear;
begin
  FCount := 0;
  FZeroIndex := 0;

  // Always need to have two values in the queue
  Add(0);
  Add(0);
end;

function TJanWScopeLineValues.GetCapacity: Integer;
begin
  if Assigned(FValues) then
    Result := Length(FValues)
  else
    Result := 0;
end;

function TJanWScopeLineValues.GetItem(Index: Integer): Integer;
begin
  if FCount = 0 then
    Result := FValues[0]
  else
    Result := FValues[(Index + FZeroIndex) mod FCount];
end;

procedure TJanWScopeLineValues.SetCapacity(const Value: Integer);
begin
  if Value <> Capacity then
  begin
    SetLength(FValues, Value);
  end;
end;

//=== { TJanWScopeLine } =======================================================

procedure TJanWScopeLine.Clear;
begin
  FValues.Clear;
end;

constructor TJanWScopeLine.Create(ACollection: Classes.TCollection);
begin
  // MUST be created before, inherited create will call Notify...
  FValues := TJanWScopeLineValues.Create;
  inherited Create(ACollection);
  FPosition := 50;
  FColor := clLime;
end;

destructor TJanWScopeLine.Destroy;
begin
  FValues.Free;
  inherited Destroy;
end;

procedure TJanWScopeLine.Assign(Source: TPersistent);
begin
  if Source is TJanWScopeLine then
  begin
    Name := TJanWScopeLine(Source).Name;
    Color := TJanWScopeLine(Source).Color;
    Position := TJanWScopeLine(Source).Position;
    FValues.Assign(TJanWScopeLine(Source).FValues);
  end
  else
    inherited Assign(Source);
end;

function TJanWScopeLine.GetDisplayName: string;
begin
  if Name = '' then
    Result := inherited GetDisplayName
  else
    Result := Name;
end;

//=== { TJanWScopeLines } ======================================================

procedure TJanWScopeLines.ClearValues;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    Lines[I].Clear;
  end;
end;

constructor TJanWScopeLines.Create(AOwner: TJanWSimScope);
begin
  inherited Create(AOwner, TJanWScopeLine);
end;

function TJanWScopeLines.Add: TJanWScopeLine;
begin
  Result := TJanWScopeLine(inherited Add);
end;

procedure TJanWScopeLines.Assign(Source: TPersistent);
var
  I: Integer;
begin
  if Source is TJanWScopeLines then
  begin
    Clear;
    for I := 0 to TJanWScopeLines(Source).Count - 1 do
      Add.Assign(TJanWScopeLines(Source)[I]);
  end
  else
    inherited Assign(Source);
end;

function TJanWScopeLines.GetItem(Index: Integer): TJanWScopeLine;
begin
  Result := TJanWScopeLine(inherited Items[Index]);
end;

function TJanWScopeLines.GetOwner: TJanWSimScope;
begin
  Result := inherited GetOwner as TJanWSimScope;
end;

function TJanWScopeLines.IndexOfName(const AName: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to Count - 1 do
    if AnsiSameStr(Lines[Result].Name, AName) then
    begin
      Result := I;
      Break;
    end;
end;

procedure TJanWScopeLines.Notify(Item: TCollectionItem;
  Action: TCollectionNotification);
begin
  inherited Notify(Item, Action);

  if Action = cnAdded then
  begin
    TJanWScopeLine(Item).FValues.Capacity := GetOwner.TotalTimeSteps;
  end;
end;

procedure TJanWScopeLines.SetItem(Index: Integer; const Value: TJanWScopeLine);
begin
  inherited Items[Index] := Value;
end;

//=== { TJanWSimScope } ========================================================

procedure TJanWSimScope.ClearValues;
begin
  FLines.ClearValues;
end;

constructor TJanWSimScope.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAllowed := False;
  FDrawBuffer := TBitmap.Create;
  FDrawBuffer.Canvas.Brush.Style := bsSolid;
  FDrawBuffer.Canvas.Pen.Width := 1;
  FDrawBuffer.Canvas.Pen.Style := psSolid;

  FDrawTimer := TTimer.Create(Self);
  FDrawTimer.Enabled := False;
  FDrawTimer.OnTimer := @DrawTimerTimer;
  FDrawTimer.Interval := 500;

  FDisplayUnits := jduPixels;
  FUpdateTimeSteps := 2;

  Height := 120;  { property default }
  Width := 208;   { property default }

  Color := clBlack;
  FGridColor := clGreen;
  FBaseColor := clRed;

  BaseLine := 50;
  GridSize := 16;

  FLines := TJanWScopeLines.Create(Self);
  Interval := 50;
  FCounter := 1;

  ControlStyle := [csFramed, csOpaque];
  FAllowed := True;
end;

destructor TJanWSimScope.Destroy;
begin
  FDrawTimer.Free;
  FDrawBuffer.Free;
  FLines.Free;
  inherited Destroy;
end;

procedure TJanWSimScope.DrawTimerTimer(Sender: TObject);
begin
  UpdateScope;
end;

function TJanWSimScope.GetGridSize: Integer;
begin
  Result := -1;
  if HorizontalGridSize = VerticalGridSize then
    Result := HorizontalGridSize;
end;

function TJanWSimScope.GetLinePixelPosition(Line: TJanWScopeLine;
  Position: Integer): Integer;
begin
  Result := 0;
  case Line.PositionUnit of
    jluPercent:
      Result := Height - Round(Height * Position / 100);
    jluAbsolute:
      Result := Height - Round(Height * (Position - Minimum) / (Maximum - Minimum));
  end;
end;

procedure TJanWSimScope.Loaded;
begin
  inherited Loaded;

  // To force having enough values in the scope.
  ClearValues;

  FAllowed := True;
end;

procedure TJanWSimScope.Resize;
begin
  inherited;
  SetBounds(Left, Top, Width, Height);
end;

procedure TJanWSimScope.Clear;
var
  A: Double;
  I: Integer;
  J: Integer;
  Position: Double;
begin
  if not FAllowed then
    Exit;
  UpdateComputedValues;
  with FDrawBuffer.Canvas do
  begin
    Brush.Color := Color;
    Pen.Style := psClear;
    Rectangle(0, 0, Width + 1, Height + 1);
    Pen.Style := psSolid;
    Pen.Color := GridColor;
    Pen.Width := 1;
    { Vertical lines }
    A := Width;
    while A > 0 do
    begin
      MoveTo(Round(A - 1), 0);
      LineTo(Round(A - 1), Height);
      A := A - VerticalGridSize * FStepPixelWidth;
    end;
    { Horizontal lines - below BaseLine }
    A := FCalcBase;
    while A < Height do
    begin
      A := A + HorizontalGridSize * Height / (Maximum - Minimum);
      MoveTo(0, Round(A));
      LineTo(Width, Round(A));
    end;
    { Horizontal lines - above BaseLine }
    A := FCalcBase;
    while A > 0 do
    begin
      A := A - HorizontalGridSize * Height / (Maximum - Minimum);
      MoveTo(0, Round(A));
      LineTo(Width, Round(A));
    end;
    { BaseLine }
    Pen.Color := BaseColor;
    MoveTo(0, FCalcBase);
    LineTo(Width, FCalcBase);

    // Redraw old values to keep history of values
    for I := 0 to FLines.Count - 1 do
    begin
      Pen.Color := FLines[I].Color;

      if FLines[I].FValues.Count > 0 then
      begin
        Position := (TotalTimeSteps - FLines[I].FValues.Count) * FStepPixelWidth;

        MoveTo(Round(Position), GetLinePixelPosition(FLines[I], FLines[I].FValues[0]));
        J := UpdateTimeSteps - 1;
        while J < FLines[I].FValues.Count - 1 do
        begin
          Position := Position + UpdateTimeSteps * FStepPixelWidth;
          LineTo(Round(Position), GetLinePixelPosition(FLines[I], FLines[I].FValues[J]));
          Inc(J, UpdateTimeSteps);
        end;

      end
      else
      begin
        FLines[I].FValues.Clear;
      end;
    end;

    FCounter := 1;
  end;
end;

procedure TJanWSimScope.SetBaseLine(Value: Integer);
begin
  FBaseLine := Value;
  UpdateComputedValues;
  UpdateDisplay(True);
end;

procedure TJanWSimScope.SetBaseLineUnit(const Value: TJanWScopeLineUnit);
begin
  if FBaseLineUnit <> Value then
  begin
    FBaseLineUnit := Value;
    UpdateDisplay(True);
  end;
end;

procedure TJanWSimScope.SetInterval(Value: Integer);
begin
  if FInterval <> Value then
  begin
    FDrawTimer.Enabled := False;
    UpdateComputedValues;
    FDrawTimer.Interval := Value * 10;
    FInterval := Value;
    FDrawTimer.Enabled := FActive;
  end;
end;

procedure TJanWSimScope.SetGridSize(Value: Integer);
begin
  if ((Value <> FHorizontalGridSize) or (Value <> FVerticalGridSize)) and (Value > 0) then
  begin
    FHorizontalGridSize := Value;
    FVerticalGridSize := Value;
    UpdateDisplay(True);
  end;
end;

procedure TJanWSimScope.SetHorizontalGridSize(const Value: Integer);
begin
  if (FHorizontalGridSize <> Value) and (Value > 0) then
  begin
    FHorizontalGridSize := Value;
    UpdateDisplay(True);
  end;
end;

procedure TJanWSimScope.SetActive(Value: Boolean);
begin
  if FActive <> Value then
  begin
    UpdateComputedValues;
    FDrawTimer.Interval := Interval * 10;
    FDrawTimer.Enabled := Value;
    FActive := Value;
  end;
end;

{ All drawings is performed on in the FDrawBuffer to speed up
  proceedings and eliminate flicker. The Paint procedure merely
  copies the contents of the FDrawBuffer. }

procedure TJanWSimScope.UpdateScope;
var
  A: Double;
  I: Integer;
  Dest, Src: TRect;
  UpdateWidth: Integer;
  J: Integer;
  PosMinusOne: Double;
  PosMinusTwo: Double;
begin
  with FDrawBuffer.Canvas do
  begin
    Pen.Color := FGridColor;

    UpdateWidth := Round(UpdateTimeSteps * FStepPixelWidth);

    Dest.Top := 0;
    Dest.Left := 0;
    Dest.Right := Round(Width - UpdateWidth);
    Dest.Bottom := Height;

    Src.Top := 0;
    Src.Left := Round(UpdateTimeSteps * FStepPixelWidth);
    Src.Right := Width;
    Src.Bottom := Height;
    { Copy bitmap leftwards }
    CopyRect(Dest, FDrawBuffer.Canvas, Src);

    { Draw new area }
    Pen.Color := Color;
    Brush.Color := Color;
    BRush.Style := bsSolid;
    Dest.Top := 0;
    Dest.Left := Width - UpdateWidth;
    Dest.Right := Width;
    Dest.Bottom := Height;
    FilLRect(Dest);
(*    Pen.Width := UpdateWidth;
    MoveTo(Width - Round(UpdateWidth / 2), 0);
    LineTo(Width - Round(UpdateWidth / 2), Height);   *)


    Pen.Color := GridColor;
    Pen.Width := 1;
    { Draw vertical line if needed }
    if FCounter >= Round(VerticalGridSize * FStepPixelWidth / UpdateWidth) then
    begin
      MoveTo(Width - 1, 0);
      LineTo(Width - 1, Height);
      FCounter := 0;
    end;
    FCounter := FCounter + 1;
    { Horizontal lines - below BaseLine }
    A := FCalcBase;
    while A < Height do
    begin
      A := A + HorizontalGridSize * Height / (Maximum - Minimum);
      MoveTo(Width - UpdateWidth, Round(A));
      LineTo(Width, Round(A));
    end;
    { Horizontal lines - above BaseLine }
    A := FCalcBase;
    while A > 0 do
    begin
      A := A - HorizontalGridSize * Height / (Maximum - Minimum);
      MoveTo(Width - UpdateWidth, Round(A));
      LineTo(Width, Round(A));
    end;
    { BaseLine }
    Pen.Color := BaseColor;
    MoveTo(Width - UpdateWidth, FCalcBase);
    LineTo(Width, FCalcBase);
    { Draw position for lines}
    for I := 0 to FLines.Count - 1 do
    begin
      Pen.Color := FLines[I].Color;

      A := GetLinePixelPosition(FLines[I], FLines[I].Position);
      PosMinusOne := GetLinePixelPosition(FLines[I], FLines[I].FValues[FLines[I].FValues.Count - 1 * UpdateTimeSteps]);
      PosMinusTwo := GetLinePixelPosition(FLines[I], FLines[I].FValues[FLines[I].FValues.Count - 2 * UpdateTimeSteps]);

      MoveTo(Width - UpdateWidth * 2, Round(PosMinusTwo));
      LineTo(Width - UpdateWidth, Round(PosMinusOne));
      LineTo(Width - 0, Round(A));
      for J := 0 to UpdateTimeSteps - 1 do
        FLines[I].FValues.Add(FLines[I].Position);
    end;
  end;
  {$IFDEF LCLQt}
  Invalidate;
  Application.ProcessMessages;
  {$ELSE}
  Repaint;
  {$IFEND}
  if Assigned(FOnUpdate) then
    FOnUpdate(Self);
end;

{ Called by timer to show updates }

procedure TJanWSimScope.Paint;
var
  Rect: TRect;
begin
  //  inherited Paint;
  FDrawBuffer.Height := Height;
  FDrawBuffer.Width := Width;
  Rect.Top := 0;
  Rect.Left := 0;
  Rect.Right := Width;
  Rect.Bottom := Height;
  Canvas.CopyRect(Rect, FDrawBuffer.Canvas, Rect);
  FAllowed := True;
end;

{ Recalulate control after move and/or resize }

procedure TJanWSimScope.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  { BUGFIX/Workaround:JAN 2009 - ACCESS VIOLATIONS AND ODD BEHAVIOUR - SIZE/WIDTH BEING ZAPPED TO ZERO.}
  if AWidth < JvMinimumScopeWidth then
      AWidth := JvMinimumScopeWidth;
  if AHeight < JvMinimumScopeHeight then
      AHeight := JvMinimumScopeHeight;


  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
  FDrawBuffer.Height := Height;
  FDrawBuffer.Width := Width;
  if DisplayUnits = jduPixels then
  begin
    FMinimum := 0;
    FMaximum := AHeight;
    FTotalTimeSteps := AWidth;
  end;
  Clear;
end;

procedure TJanWSimScope.UpdateComputedValues;
begin
  case FBaseLineUnit of
    jluPercent:
      FCalcBase := Height - Round(Height * FBaseLine / 100);
    jluAbsolute:
      FCalcBase := Height - Round(Height * (FBaseLine - Minimum) / (Maximum - Minimum));
  end;
  FStepPixelWidth := Width / TotalTimeSteps;
  if FUpdateTimeSteps * FStepPixelWidth < 2 then
    UpdateTimeSteps := 2;
end;

procedure TJanWSimScope.SetDisplayUnits(const Value: TJanWSimScopeDisplayUnit);
begin
  if FDisplayUnits <> Value then
  begin
    FDisplayUnits := Value;
    if FDisplayUnits = jduPixels then
    begin
      FMinimum := 0;
      FMaximum := Height;
    end;
    UpdateDisplay(True);
  end;
end;

procedure TJanWSimScope.SetLines(const Value: TJanWScopeLines);
begin
  FLines.Assign(Value);
  Clear;
end;

procedure TJanWSimScope.SetMaximum(const Value: Integer);
begin
  if (FDisplayUnits <> jduPixels) and (FMaximum <> Value) then
  begin
    FMaximum := Value;
    UpdateDisplay(True);
  end;
end;

procedure TJanWSimScope.SetMinimum(const Value: Integer);
begin
  if (FDisplayUnits <> jduPixels) and (FMinimum <> Value) then
  begin
    FMinimum := Value;
    UpdateDisplay(True);
  end;
end;

procedure TJanWSimScope.SetTotalTimeSteps(const Value: Integer);
begin
  if (FDisplayUnits <> jduPixels) and (FTotalTimeSteps <> Value) then
  begin
    FTotalTimeSteps := Value;
    UpdateDisplay(True);
  end;
end;

procedure TJanWSimScope.SetUpdateTimeSteps(const Value: Integer);
begin
  if (FUpdateTimeSteps <> Value) and (Value > 0) then
  begin
    FUpdateTimeSteps := Value;
  end;
end;

procedure TJanWSimScope.SetVerticalGridSize(const Value: Integer);
begin
  if (FVerticalGridSize <> Value) and (Value > 0) then
  begin
    FVerticalGridSize := Value;
    UpdateDisplay(True);
  end;
end;

procedure TJanWSimScope.UpdateDisplay(ClearFirst: Boolean);
begin
  if Parent <> nil then
  begin
    if ClearFirst then
      Clear;
    Repaint;
  end;
end;


end.
