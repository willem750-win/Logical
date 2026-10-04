unit janSimIndicator;


{$mode ObjFPC}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  extCtrls;
 //LCLIntf, LCLType, LMessages,
// SysUtils, Classes, Graphics, Controls;

type
  TjanWSimIndicator = class(TGraphicControl)
  private
    Fvalue: integer;
    Fmaximum: integer;
    Fminimum: integer;
    FBarColor: TColor;
    FColor: TColor;
    FBackColor: TColor;
    procedure SetBarColor(const Value: TColor);
    procedure Setmaximum(const Value: integer);
    procedure Setminimum(const Value: integer);
    procedure Setvalue(const Value: integer);
    procedure SetBackColor(const Value: TColor);
    { Private declarations }
  protected
    { Protected declarations }
  public
    { Public declarations }
    constructor create(AOwner:Tcomponent); override;
    destructor  destroy; override;
    procedure   paint; override;
  published
    { Published declarations }
    property value:integer read Fvalue write Setvalue;
    property minimum:integer read Fminimum write Setminimum;
    property maximum:integer read Fmaximum write Setmaximum;
    property BarColor:TColor read FColor write SetBarColor;
    property BackColor:TColor read FBackColor write SetBackColor;
  end;


implementation


constructor TjanWSimIndicator.create(AOwner: Tcomponent);
begin
  inherited;
  width:=25;
  height:=100;
  FMinimum:=0;
  FMaximum:=100;
  FValue:=50;
  FBarColor:=cllime;
  FBackColor:=clSilver;
end;

destructor TjanWSimIndicator.destroy;
begin
  inherited;

end;

procedure TjanWSimIndicator.paint;
var R,Ri:TRect;
    i,n:integer;
    h,dh:integer;
begin
   R:=ClientRect;
   canvas.brush.color:=clsilver;
   canvas.fillrect(R);
   Frame3D(canvas,R,clbtnhighlight,clbtnshadow,1);
   inflaterect(R,-3,-3);
   Frame3D(canvas,R,clbtnshadow,clbtnhighlight,1);
   canvas.brush.color:=FBackColor;
   inflaterect(R,-1,-1);
   canvas.fillrect(R);
   inc(R.right,-1);
   h:=R.bottom-R.top;
   dh:=h div 20;
   n:=round(h*(FValue-FMinimum)/(FMaximum-FMinimum)/dh);
   canvas.brush.color:=FBarColor;
   Ri:=rect(R.left+1,R.bottom-dh+1,R.right-1,R.bottom);
   if n>0 then
   for i:=1 to n do
   begin
    canvas.fillrect(Ri);
    inc(Ri.top,-dh);
    inc(Ri.bottom,-dh);
   end;
end;

procedure TjanWSimIndicator.SetBackColor(const Value: TColor);
begin
  FBackColor := Value;
  invalidate;
end;

procedure TjanWSimIndicator.SetBarColor(const Value: TColor);
begin
  FBarColor := Value;
  invalidate;
end;

procedure TjanWSimIndicator.Setmaximum(const Value: integer);
begin
  Fmaximum := Value;
  invalidate;
end;

procedure TjanWSimIndicator.Setminimum(const Value: integer);
begin
  Fminimum := Value;
  invalidate;
end;

procedure TjanWSimIndicator.Setvalue(const Value: integer);
begin
  Fvalue := Value;
  invalidate;
end;

end.
