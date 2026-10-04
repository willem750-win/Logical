unit janLed;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  LCLIntf, LCLType, LMessages,
  Graphics, Controls;

type
  // Zelfde namen houden als vroeger (red, green, ...)
  TLedColor = (red, green, yellow, blue, purple);

  TjanWLed = class(TGraphicControl)
  private
    FLit: Boolean;
    FLedColor: TLedColor;
    procedure SetLit(AValue: Boolean);
    procedure SetLedColor(AValue: TLedColor);
  protected
    procedure Paint; override;
    procedure Resize; override; // houdt de LED mooi vierkant
  public
    constructor Create(AOwner: TComponent); override;
  published
    // Eigen properties
    property Lit: Boolean read FLit write SetLit default False;
    property LedColor: TLedColor read FLedColor write SetLedColor default red;

    // Standaard Lazarus properties
    property Align;
    property Anchors;
    property Enabled;
    property Visible;
    property PopupMenu;
    property ShowHint;
    property ParentShowHint;
    property OnClick;
    property OnMouseDown;
    property OnMouseUp;
    property OnMouseMove;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('JWLOGIC', [TjanWLed]);
end;

{ TjanWLed }

constructor TjanWLed.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width  := 16;
  Height := 16;
  FLit := False;
  FLedColor := red;
end;

procedure TjanWLed.Resize;
var
  S: Integer;
begin
  inherited Resize;
  // LED vierkant houden: neem de kleinste zijde
  if Width <> Height then
  begin
    if Width < Height then
      S := Width
    else
      S := Height;
    inherited SetBounds(Left, Top, S, S);
  end;
end;

procedure TjanWLed.SetLit(AValue: Boolean);
begin
  if FLit = AValue then Exit;
  FLit := AValue;
  Invalidate; // hertekenen
end;

procedure TjanWLed.SetLedColor(AValue: TLedColor);
begin
  if FLedColor = AValue then Exit;
  FLedColor := AValue;
  Invalidate;
end;

procedure TjanWLed.Paint;
var
  R: TRect;
  BaseColor, DarkColor: TColor;
begin
  inherited Paint;

  R := ClientRect;

  // Achtergrond: teken met Parent.Color
  if Parent <> nil then
    Canvas.Brush.Color := Parent.Color
  else
    Canvas.Brush.Color := clBtnFace;
  Canvas.Brush.Style := bsSolid;
  Canvas.FillRect(R);

  InflateRect(R, -1, -1);

  // Basis LED-kleur kiezen
  case FLedColor of
    red:    BaseColor := RGBToColor(255, 0, 0);
    green:  BaseColor := RGBToColor(0, 200, 0);
    yellow: BaseColor := RGBToColor(255, 255, 0);
    blue:   BaseColor := RGBToColor(0, 0, 255);
    purple: BaseColor := RGBToColor(180, 0, 180);
  else
    BaseColor := clRed;
  end;

  if FLit then
  begin
    // "Aan": heldere kleur, lichte rand
    Canvas.Pen.Color := clWhite;
    Canvas.Brush.Color := BaseColor;
  end
  else
  begin
    // "Uit": gedimde kleur, grijze rand
    DarkColor := ColorToRGB(BaseColor) and $7F7F7F; // simpele dimming
    Canvas.Pen.Color := clGray;
    Canvas.Brush.Color := DarkColor;
  end;

  Canvas.Ellipse(R);
end;

end.

{unit janLed;

//{$MODE Delphi}

{$mode ObjFPC}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages,SysUtils, Classes, Graphics, Controls, Forms, Dialogs,buttons;

 //LCLIntf, LCLType, LMessages,
// SysUtils, Classes, Graphics, Controls;

type
  TLedColor=(red,green,yellow,blue,purple);
  TjanWLed = class(TGraphicControl)
  private
    { Private declarations }
    FLit: boolean;
    FLedColor: TLedColor;

    procedure SetLit(const Value: boolean);
    procedure SetLedColor(const Value: TLedColor);
    procedure keepsize(Sender: TObject; var NewWidth, NewHeight: Integer; var AllowResize: Boolean);
  protected
    { Protected declarations }
   procedure Paint; override;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

  published
    { Published declarations }
    property Lit:boolean read FLit write SetLit;
    property LedColor:TLedColor read FLedColor write SetLedColor;
  end;


implementation

{ TjanLed }


constructor TjanWLed.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csReplicatable];
  Width := 12;
  Height := 13;
  FLit:=false;
  FLedColor:=red;
 // oncanresize:=keepsize;
end;


destructor TjanWLed.Destroy;
begin
 //mycode
  inherited Destroy;
end;



procedure TjanWLed.Paint;
var
  surfcol,litcol:Tcolor;
begin
 if Flit then begin
  case FLedColor of
   red: begin surfcol:=clred;litcol:=clwhite end;
   green: begin surfcol:=cllime;litcol:=clwhite end;
   yellow: begin surfcol:=clyellow;litcol:=clwhite end;
   blue: begin surfcol:=claqua;litcol:=clwhite end;
   purple: begin surfcol:=clfuchsia;litcol:=clwhite end;
   end;
  end
  else
    begin
      case FLedColor of
    red: begin
          surfcol:=clmaroon;
          litcol:=clred
         end;
    green: begin surfcol:=clgreen;litcol:=cllime end;
    yellow: begin surfcol:=clolive;litcol:=clyellow end;
    blue: begin surfcol:=clnavy;litcol:=claqua end;
    purple: begin surfcol:=clpurple;litcol:=clfuchsia end;
   end;

  end;
 with Canvas do
   begin
   brush.color:=clsilver;
   fillrect(rect(0,0,12,13));
   brush.style:=bsclear;
   pen.color:=clgray;
   ellipse(0,0,12,13);
   pen.color:=clblack;
   brush.color:=surfcol;
   ellipse(1,1,11,12);
   pen.color:=clwhite;
   arc(1,1,11,12,0,12,12,0);
   pen.color:=litcol;
   arc(3,3,8,9,5,0,0,8);
   end;

end;
procedure TjanWLed.keepsize(Sender: TObject; var NewWidth, NewHeight: Integer; var AllowResize: Boolean);
//procedure TjanWLed.keepsize(Sender: TObject; var NewWidth,
  //NewHeight: Integer; var Resize: Boolean);
begin
 AllowResize:=true;
 newwidth:=width;
 newheight:=height;
end;


procedure TjanWLed.SetLit(const Value: boolean);
begin
  if value<>FLit then begin
   FLit:= Value;
   refresh;
   end;
end;

procedure TjanWLed.SetLedColor(const Value: TLedColor);
begin
  if value<>FLedColor then begin
   FLedColor:= Value;
   refresh;
   end;
end;

end.}
