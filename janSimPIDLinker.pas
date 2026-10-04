unit janSimPIDLinker;

{$mode ObjFPC}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,janSimPID;

type
  TjanWSimPIDLinker = class(TComponent)
  private
    FIn1: TjanWSimPID;
    FOut1: TjanWSimPID;
    FOut7: TjanWSimPID;
    FOut6: TjanWSimPID;
    FOut4: TjanWSimPID;
    FIn2: TjanWSimPID;
    FIn4: TjanWSimPID;
    FOut2: TjanWSimPID;
    FIn8: TjanWSimPID;
    FOut8: TjanWSimPID;
    FIn5: TjanWSimPID;
    FOut3: TjanWSimPID;
    FIn3: TjanWSimPID;
    FIn7: TjanWSimPID;
    FOut5: TjanWSimPID;
    FIn6: TjanWSimPID;
    procedure SetIn1(const Value: TjanWSimPID);
    procedure SetOut1(const Value: TjanWSimPID);
    procedure SetIn2(const Value: TjanWSimPID);
    procedure SetIn3(const Value: TjanWSimPID);
    procedure SetIn4(const Value: TjanWSimPID);
    procedure SetIn5(const Value: TjanWSimPID);
    procedure SetIn6(const Value: TjanWSimPID);
    procedure SetIn7(const Value: TjanWSimPID);
    procedure SetIn8(const Value: TjanWSimPID);
    procedure SetOut2(const Value: TjanWSimPID);
    procedure SetOut3(const Value: TjanWSimPID);
    procedure SetOut4(const Value: TjanWSimPID);
    procedure SetOut5(const Value: TjanWSimPID);
    procedure SetOut6(const Value: TjanWSimPID);
    procedure SetOut7(const Value: TjanWSimPID);
    procedure SetOut8(const Value: TjanWSimPID);
    { Private declarations }
  protected
    { Protected declarations }
  public
    { Public declarations }
    procedure Execute;
  published
    { Published declarations }
    property In1:TjanWSimPID read FIn1 write SetIn1;
    property Out1:TjanWSimPID read FOut1 write SetOut1;
    property In2:TjanWSimPID read FIn2 write SetIn2;
    property Out2:TjanWSimPID read FOut2 write SetOut2;
    property In3:TjanWSimPID read FIn3 write SetIn3;
    property Out3:TjanWSimPID read FOut3 write SetOut3;
    property In4:TjanWSimPID read FIn4 write SetIn4;
    property Out4:TjanWSimPID read FOut4 write SetOut4;
    property In5:TjanWSimPID read FIn5 write SetIn5;
    property Out5:TjanWSimPID read FOut5 write SetOut5;
    property In6:TjanWSimPID read FIn6 write SetIn6;
    property Out6:TjanWSimPID read FOut6 write SetOut6;
    property In7:TjanWSimPID read FIn7 write SetIn7;
    property Out7:TjanWSimPID read FOut7 write SetOut7;
    property In8:TjanWSimPID read FIn8 write SetIn8;
    property Out8:TjanWSimPID read FOut8 write SetOut8;


  end;

//procedure Register;

implementation
{
procedure Register;
begin
  RegisterComponents('Logic', [TjanWSimPIDLinker]);
end;}

{ TjanWSimPIDLinker }

procedure TjanWSimPIDLinker.Execute;
var value:extended;
begin
if assigned(FIn1) then value:=Fin1.CV ;
if assigned(FOut1) then FOut1.MV :=value;
if assigned(FIn2) then value:=Fin2.CV ;
if assigned(FOut2) then FOut2.MV :=value;
if assigned(FIn3) then value:=Fin3.CV ;
if assigned(FOut3) then FOut3.MV :=value;
if assigned(FIn4) then value:=Fin4.CV ;
if assigned(FOut4) then FOut4.MV :=value;
if assigned(FIn5) then value:=Fin5.CV ;
if assigned(FOut5) then FOut5.MV :=value;
if assigned(FIn6) then value:=Fin6.CV ;
if assigned(FOut6) then FOut6.MV :=value;
if assigned(FIn7) then value:=Fin7.CV ;
if assigned(FOut7) then FOut7.MV :=value;
if assigned(FIn8) then value:=Fin8.CV ;
if assigned(FOut8) then FOut8.MV :=value;

end;

procedure TjanWSimPIDLinker.SetIn1(const Value: TjanWSimPID);
begin
  FIn1 := Value;
end;

procedure TjanWSimPIDLinker.SetIn2(const Value: TjanWSimPID);
begin
  FIn2 := Value;
end;

procedure TjanWSimPIDLinker.SetIn3(const Value: TjanWSimPID);
begin
  FIn3 := Value;
end;

procedure TjanWSimPIDLinker.SetIn4(const Value: TjanWSimPID);
begin
  FIn4 := Value;
end;

procedure TjanWSimPIDLinker.SetIn5(const Value: TjanWSimPID);
begin
  FIn5 := Value;
end;

procedure TjanWSimPIDLinker.SetIn6(const Value: TjanWSimPID);
begin
  FIn6 := Value;
end;

procedure TjanWSimPIDLinker.SetIn7(const Value: TjanWSimPID);
begin
  FIn7 := Value;
end;

procedure TjanWSimPIDLinker.SetIn8(const Value: TjanWSimPID);
begin
  FIn8 := Value;
end;

procedure TjanWSimPIDLinker.SetOut1(const Value: TjanWSimPID);
begin
  FOut1 := Value;
end;

procedure TjanWSimPIDLinker.SetOut2(const Value: TjanWSimPID);
begin
  FOut2 := Value;
end;

procedure TjanWSimPIDLinker.SetOut3(const Value: TjanWSimPID);
begin
  FOut3 := Value;
end;

procedure TjanWSimPIDLinker.SetOut4(const Value: TjanWSimPID);
begin
  FOut4 := Value;
end;

procedure TjanWSimPIDLinker.SetOut5(const Value: TjanWSimPID);
begin
  FOut5 := Value;
end;

procedure TjanWSimPIDLinker.SetOut6(const Value: TjanWSimPID);
begin
  FOut6 := Value;
end;

procedure TjanWSimPIDLinker.SetOut7(const Value: TjanWSimPID);
begin
  FOut7 := Value;
end;

procedure TjanWSimPIDLinker.SetOut8(const Value: TjanWSimPID);
begin
  FOut8 := Value;
end;

end.
 
