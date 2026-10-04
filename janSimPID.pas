unit janSimPID;

{$mode ObjFPC}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs;

type
  TjvSymFunc=(sfPid,sfAdd,sfCompare,sfRamp,sfMul);

  TjanWSimPID = class(TGraphicControl)
  private
//    fSymFunc:TjvSymFunc;
    FMV:extended;
    FMVColor:tcolor;
    FSP: extended;
    FSPColor: tcolor;
    FCV: extended;
    FCVColor: tcolor;
    FKD: extended;
    FKP: extended;
    FKI: extended;
    FI:extended;
    FD: extended;
    FDirect: boolean;
    FManual: boolean;
    FSource: TjanWSimPID;
    FActive: boolean;
    FSymFunc: TjvSymFunc;
    procedure SetMV(value:extended);
    procedure SetMVColor(value:tcolor);
    procedure SetSP(const Value: extended);
    procedure SetSPColor(const Value: tcolor);
    procedure SetCV(const Value: extended);
    procedure SetCVColor(const Value: tcolor);
    procedure SetKD(const Value: extended);
    procedure SetKI(const Value: extended);
    procedure SetKP(const Value: extended);
    procedure CalcOut;
    procedure SetDirect(const Value: boolean);
    procedure SetManual(const Value: boolean);
    procedure SetSource(const Value: TjanWSimPID);
    procedure SetActive(const Value: boolean);
    procedure SetSymFunc(const Value: TjvSymFunc);
    { Private declarations }

  protected
    Procedure Paint; Override;
    { Protected declarations }

  public
    Constructor Create(Aowner:TComponent); override;
    procedure Execute;
    { Public declarations }

  published
    property SymFunc:TjvSymFunc read FSymFunc write SetSymFunc;
    property Source:TjanWSimPID read FSource write SetSource;
    property MV:extended read FMV write SetMV ;
    property MVColor:tcolor read FMVColor write SetMVColor;
    property SP:extended read FSP write SetSP;
    property SPColor:tcolor read FSPColor write SetSPColor;
    property CV:extended read FCV write SetCV;
    property CVColor:tcolor read FCVColor write SetCVColor;
    property KP:extended read FKP write SetKP;
    property KI:extended read FKI write SetKI;
    property KD:extended read FKD write SetKD;
    property Direct:boolean read FDirect write SetDirect;
    property Manual:boolean read FManual write SetManual;
    property Active:boolean read FActive write SetActive;
    property Color;
    property Align;
    property Visible;
    property ShowHint;
    property Popupmenu;
    property onMouseDown;
    property onMouseMove;
    property onMouseUp;
    property onClick;
    property onDblClick;
    { Published declarations }

  end;

//procedure Register;

implementation

var drawrect:trect;

Procedure TjanWSimPID.SetMV(value:extended);
var MVold:extended;
begin
     MVold:=FMV;
     if value<>FMV then
        Begin
          if Value>100 then MV:=100
          else
          if Value<0 then MV:=0
          else
          FMV:=value;
        End;
     FI:=FI+KI*(FMV-FSP);
     if FI>50 then FI:=50;
     if FI<-50 then FI:=-50;
     FD:=KD*(FMV-MVold);
     if FD>50 then FD:=50;
     if FD<-50 then FD:=-50;
     CalcOut;
end;

Procedure TjanWSimPID.SetMVColor(value:tcolor);
begin
     if value<>FMVColor then
        Begin
          FMVColor:=value;
          invalidate;
        End;
end;

Procedure TjanWSimPID.Paint;
var buff,bw:integer;
    R:trect;
begin
     Drawrect:=Clientrect;
     with Canvas,drawrect do
     begin
          Pen.color:=clgray;
          Pen.width:=1;
          Rectangle(left,top,right,bottom);
          inflaterect(Drawrect,-1,-1);
          R:=DrawRect;
          bw:=(R.right-R.left) div 3;
// first draw the Measured Value
          Brush.Color:=MVColor;
          Buff:=DrawRect.Top;
          Drawrect.top:=Drawrect.top+round((100-MV)*(bottom-top)/100);
          DrawRect.left:=R.left+bw;
          DrawRect.right:=R.right-bw;
          FillRect(Drawrect);
          Drawrect.bottom:=Drawrect.top;
          Drawrect.top:=Buff;
          Brush.color:=color;
          Fillrect(Drawrect);
// and now the SetPoint
          DrawRect:=R;
          Brush.Color:=SPColor;
          Buff:=DrawRect.Top;
          Drawrect.top:=Drawrect.top+round((100-SP)*(bottom-top)/100);
          Drawrect.right:=R.left+bw;
          FillRect(Drawrect);
          Drawrect.bottom:=Drawrect.top;
          Drawrect.top:=Buff;
          Brush.color:=color;
          Fillrect(Drawrect);
// draw the Corrective Value (CV)
          DrawRect:=R;
          Brush.Color:=CVColor;
          Buff:=DrawRect.Top;
          Drawrect.top:=Drawrect.top+round((100-CV)*(bottom-top)/100);
          Drawrect.left:=R.right-bw;
          FillRect(Drawrect);
          Drawrect.bottom:=Drawrect.top;
          Drawrect.top:=Buff;
          Brush.color:=color;
          Fillrect(Drawrect);
     end;
end;

constructor TjanWSimPID.Create(Aowner:tcomponent);
begin
     inherited Create(Aowner);
     color:=clwhite;
     MVcolor:=clRed;
     SPColor:=clLime;
     CVcolor:=clyellow;
     Direct:=false;
     Manual:=false;
     Active:=false;
     FMV:=50;
     FSP:=50;
     FCV:=50;
     FKP:=0.5;
     FKI:=0;
     FKD:=0;
     Width:=20;
     Height:=100;
end;

procedure TjanWSimPID.SetSP(const Value: extended);
begin
     if value<>FSP then
        Begin
          if Value>100 then SP:=100
          else
          if Value<0 then SP:=0
          else
          FSP:=value;
          CalcOut;
        End;
end;

procedure TjanWSimPID.SetSPColor(const Value: tcolor);
begin
     if value<>FSPColor then
        Begin
          FSPColor:=value;
          invalidate;
        End;

end;

procedure TjanWSimPID.SetCV(const Value: extended);
begin
     if value<>FCV then
        Begin
          if Value>100 then CV:=100
          else
          if Value<0 then CV:=0
          else
          FCV:=value;
          End;
invalidate;;
end;

procedure TjanWSimPID.SetCVColor(const Value: tcolor);
begin
     if value<>FCVColor then
        Begin
          FCVColor:=value;
          invalidate;
          End;

end;

procedure TjanWSimPID.SetKD(const Value: extended);
begin
  FKD := Value;
end;

procedure TjanWSimPID.SetKI(const Value: extended);
begin
  FKI := Value;
  if FKI=0 then FI:=0;
end;

procedure TjanWSimPID.SetKP(const Value: extended);
begin
  FKP := Value;
end;

procedure TjanWSimPID.CalcOut;
var output:extended;
begin
if Fmanual then exit;
if FDirect then
  output:=50+KP*(FMV-FSP)+FI+FD
  else
  output:=50-(KP*(FMV-FSP)+FI+FD);
 SetCV(output);
 end;

procedure TjanWSimPID.SetDirect(const Value: boolean);
begin
  FDirect := Value;
end;

procedure TjanWSimPID.SetManual(const Value: boolean);
begin
  FManual := Value;
end;


procedure TjanWSimPID.SetSource(const Value: TjanWSimPID);
begin
  FSource := Value;
end;

procedure TjanWSimPID.Execute;
var value:extended;
begin
if not FActive then exit;
if assigned(source) then begin
  value:=source.CV ;
  setMV(value);
  end;
end;

procedure TjanWSimPID.SetActive(const Value: boolean);
begin
  FActive := Value;
end;


procedure TjanWSimPID.SetSymFunc(const Value: TjvSymFunc);
begin
  FSymFunc := Value;
end;

end.


