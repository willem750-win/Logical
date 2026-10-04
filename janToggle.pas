unit janToggle;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  LCLIntf, LCLType, LMessages,
  Graphics, Controls;

type
  TonToggleChange = procedure (Sender: TObject; AState: Boolean) of object;
  TToggleColor   = (red, green, yellow, blue, purple);
  TToggleStyle   = (vertical, horizontal);
  TButtonStyle   = (bssquare, bsround);

  TjanWToggle = class(TGraphicControl)
  private
    { Private declarations }
    FonTogglechange: TonToggleChange;
    FToggleState: Boolean;
    FIn, FOut: TRect;
    FInColor: TToggleColor;
    FOutColor: TToggleColor;
    FBackLit: Boolean;
    FMarking: Boolean;
    FToggleStyle: TToggleStyle;
    FInCap: string;
    FOutCap: string;
    FButtonstyle: TbuttonStyle;
    procedure DoToggleChange;
    procedure SetToggleState(const Value: Boolean);
    procedure keepsize(Sender: TObject);
    procedure SetonToggleChange(const Value: TonToggleChange);
    procedure SetIncolor(const Value: TToggleColor);
    procedure SetOutColor(const Value: TToggleColor);
    procedure SetBackLit(const Value: Boolean);
    procedure SetMarking(const Value: Boolean);
    procedure SetToggleStyle(const Value: TToggleStyle);
    procedure SetInCap(const Value: string);
    procedure SetOutCap(const Value: string);
    procedure SetButtonstyle(const Value: TbuttonStyle);
  protected
    procedure ToggleMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    function FXcolor(Acolor: TToggleColor; bright: Boolean): TColor;
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure makestyle;
  published
    { Published declarations }
    property ToggleState: Boolean read FToggleState write SetToggleState;
    property ToggleStyle: TToggleStyle read FToggleStyle write SetToggleStyle;
    property Buttonstyle: TbuttonStyle read FButtonstyle write SetButtonstyle;
    property BackLit: Boolean read FBackLit write SetBackLit;
    property Marking: Boolean read FMarking write SetMarking;
    property onToggleChange: TonToggleChange read FonToggleChange write SetonToggleChange;
    property InColor: TToggleColor read FInColor write SetInColor;
    property InCap: string read FInCap write SetInCap;
    property OutColor: TToggleColor read FOutColor write SetOutColor;
    property OutCap: string read FOutCap write SetOutCap;

    // Standaard Lazarus visual properties
    property Align;
    property Anchors;
    property Enabled;
    property Visible;
    property ParentShowHint;
    property ShowHint;
    property PopupMenu;
    property OnClick;
    property OnMouseDown;
    property OnMouseUp;
    property OnMouseMove;
  end;


implementation


{ TjanWToggle }

constructor TjanWToggle.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csReplicatable];
  FButtonStyle := bssquare;
  makestyle;
  OnMouseDown := @ToggleMousedown;
  OnResize := @keepsize;
  FInColor := red;
  FOutColor := green;
  FBackLit := False;
  FMarking := True;
  FInCap := 'I';
  FOutCap := 'O';
end;

destructor TjanWToggle.Destroy;
begin
  // mycode (indien nodig)
  inherited Destroy;
end;

procedure TjanWToggle.makestyle;
begin
  case FToggleStyle of
    vertical:
      begin
        Width := 24;
        Height := 48;
        FIn := Rect(1, 1, Width - 1, Width - 2);
        FOut := Rect(1, Width, Width - 2, Height - 2);
      end;
    horizontal:
      begin
        Width := 48;
        Height := 24;
        FIn := Rect(1, 1, Height - 2, Height - 2);
        FOut := Rect(Height, 1, Width - 2, Height - 2);
      end;
  end;
  Invalidate;
end;

procedure TjanWToggle.DoToggleChange;
begin
  if Assigned(FonToggleChange) then
    FonToggleChange(Self, FToggleState);
end;

procedure TjanWToggle.SetToggleState(const Value: Boolean);
begin
  if Value <> FToggleState then
  begin
    FToggleState := Value;
    Invalidate;
    DoToggleChange;
  end;
end;

procedure TjanWToggle.SetonToggleChange(const Value: TonToggleChange);
begin
  FonToggleChange := Value;
end;

procedure TjanWToggle.SetIncolor(const Value: TToggleColor);
begin
  if Value <> FInColor then
  begin
    FInColor := Value;
    Invalidate;
  end;
end;

procedure TjanWToggle.SetOutColor(const Value: TToggleColor);
begin
  if Value <> FOutColor then
  begin
    FOutColor := Value;
    Invalidate;
  end;
end;

procedure TjanWToggle.SetBackLit(const Value: Boolean);
begin
  if Value <> FBackLit then
  begin
    FBackLit := Value;
    Invalidate;
  end;
end;

procedure TjanWToggle.SetMarking(const Value: Boolean);
begin
  if Value <> FMarking then
  begin
    FMarking := Value;
    Invalidate;
  end;
end;

procedure TjanWToggle.keepsize(Sender: TObject);
begin
  makestyle;
end;

procedure TjanWToggle.SetToggleStyle(const Value: TToggleStyle);
begin
  if Value <> FToggleStyle then
  begin
    FToggleStyle := Value;
    makestyle;
  end;
end;

procedure TjanWToggle.SetInCap(const Value: string);
begin
  if Value <> FInCap then
  begin
    if Value = '' then
      FInCap := ''
    else
      FInCap := UpperCase(Value[1]);
    Invalidate;
  end;
end;

procedure TjanWToggle.SetOutCap(const Value: string);
begin
  if Value <> FOutCap then
  begin
    if Value = '' then
      FOutCap := ''
    else
      FOutCap := UpperCase(Value[1]);
    Invalidate;
  end;
end;

procedure TjanWToggle.SetButtonstyle(const Value: TbuttonStyle);
begin
  if Value <> FButtonStyle then
  begin
    FButtonstyle := Value;
    Invalidate;
  end;
end;

function TjanWToggle.FXcolor(Acolor: TToggleColor; bright: Boolean): TColor;
var
  base: TColor;
begin
  case Acolor of
    red:    base := clRed;
    green:  base := clLime;
    yellow: base := clYellow;
    blue:   base := clBlue;
    purple: base := clFuchsia;
  else
    base := clBtnFace;
  end;

  if bright then
    Result := base
  else
    Result := ColorToRGB(base) and $7F7F7F; // simpele dimming
end;

procedure TjanWToggle.ToggleMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);

  function InRectXY(x, y: Integer; const ARect: TRect): Boolean;
  begin
    Result :=
      (x > ARect.Left) and (x < ARect.Right) and
      (y > ARect.Top) and (y < ARect.Bottom);
  end;

var
  hit, astate: Boolean;
begin
  hit := False;
  if InRectXY(X, Y, FIn) then
  begin
    hit := True;
    astate := True;
  end
  else if InRectXY(X, Y, FOut) then
  begin
    hit := True;
    astate := False;
  end;

  if hit then
    ToggleState := astate;
end;

procedure TjanWToggle.Paint;

  procedure doLit(Arect: TRect; Acolor: TToggleColor; bright: Boolean);
  var
    glass: TColor;
    mr: Integer;
    x1, y1, x2, y2: Integer;
  begin
    x1 := Arect.Left;
    y1 := Arect.Top;
    x2 := Arect.Right;
    y2 := Arect.Bottom;
    glass := FXColor(Acolor, bright);
    mr := 1;
    with Canvas do
    begin
      Pen.Style := psClear;
      Brush.Color := glass;
      case FButtonstyle of
        bssquare: Rectangle(x1 + mr, y1 + mr, x2, y2);
        bsround:  Ellipse(x1 + 2, y1 + 2, x2 - 2, y2 - 2);
      end;
      Pen.Style := psSolid;
      if bright then
        Pen.Color := clWhite
      else
        Pen.Color := FXColor(Acolor, True);
      Arc(Arect.Left + 3, Arect.Top + 3, Arect.Right - 3, Arect.Bottom - 3,
        Arect.Left + 12, Arect.Top + 0, Arect.Left + 0, Arect.Top + 16);
      Pen.Color := clBlack;
    end;
  end;

  procedure btncap(R: TRect; s: string; AColor: TToggleColor; bright: Boolean);
  var
    x, y, w, h: Integer;
  begin
    with Canvas do
    begin
      w := TextWidth(s);
      h := TextHeight(s);
      x := (R.Right - R.Left - w + 1) div 2;
      y := (R.Bottom - R.Top - h) div 2;
      Font.Style := Font.Style + [fsBold];
      Pen.Color := clBlack;
      Brush.Style := bsClear;
      if FBacklit then
        Font.Color := clBlack
      else
        Font.Color := FXcolor(AColor, bright);
      TextOut(R.Left + x, R.Top + y, s);
    end;
  end;

  procedure drawbtn(Arect: TRect; AColor: TToggleColor; active: Boolean; s: string);
  var
    x1, y1, x2, y2: Integer;
  begin
    x1 := Arect.Left;
    y1 := Arect.Top;
    x2 := Arect.Right;
    y2 := Arect.Bottom;
    with Canvas do
    begin
      case FButtonStyle of
        bssquare:
          begin
            Brush.Color := $E0E0E0;
            FillRect(Arect);
            Pen.Color := clBlack;
            MoveTo(x1, y2);
            LineTo(x1, y1);
            LineTo(x2, y1);
            Pen.Color := clWhite;
            LineTo(x2, y2);
            LineTo(x1, y2);
          end;
        bsround:
          begin
            Brush.Color := $E0E0E0;
            Pen.Color := clGray;
            Ellipse(x1, y1, x2, y2);
            Pen.Color := clBlack;
            Ellipse(x1 + 1, y1 + 1, x2 - 1, y2 - 1);
            Pen.Color := clWhite;
            Arc(x1 + 1, y1 + 1, x2 - 1, y2 - 1, x1, y2, x2, y1);
          end;
      end;

      if active then
      begin
        case FButtonStyle of
          bssquare:
            begin
              Brush.Color := clSilver;
              FillRect(Arect);
              Pen.Color := clWhite;
              MoveTo(Arect.Left, Arect.Bottom);
              LineTo(Arect.Left, Arect.Top);
              LineTo(Arect.Right, Arect.Top);
              Pen.Color := clBlack;
              LineTo(Arect.Right, Arect.Bottom);
              LineTo(Arect.Left, Arect.Bottom);
            end;
          bsround:
            begin
              Brush.Color := clSilver;
              Pen.Color := clGray;
              Ellipse(x1, y1, x2, y2);
              Pen.Color := clBlack;
              Ellipse(x1 + 1, y1 + 1, x2 - 1, y2 - 1);
              Pen.Color := clWhite;
              Arc(x1 + 1, y1 + 1, x2 - 1, y2 - 1, x2, y1, x1, y2);
            end;
        end;
      end;

      if FBackLit then
        doLit(Arect, Acolor, False);
      if FMarking then
        btncap(Arect, s, Acolor, active);
    end;
  end;

begin
  with Canvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(ClientRect);
  end;

  if FToggleState then
  begin
    drawbtn(FIn, FInColor, True, FInCap);
    drawbtn(FOut, FOutColor, False, FOutCap);
  end
  else
  begin
    drawbtn(FIn, FInColor, False, FInCap);
    drawbtn(FOut, FOutColor, True, FOutCap);
  end;
end;

end.


