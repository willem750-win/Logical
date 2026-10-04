unit jwlogicreg;

{$mode objfpc}{$H+}

interface
uses
  Classes, SysUtils,LResources,janLed, janSimIndicator, janToggle, janSimPID,
  janSimPIDLinker,chatgridpcodeSmall, janSimLogic;

procedure Register;

implementation



procedure Register;
begin
  RegisterComponents('JWLOGIC',[TjanGridS,TjanWLed, TjanWSimIndicator, TjanWToggle, TjanWSimPID,TjanWSimPIDLinker]);
end;
 initialization

    {$I jwlogic.lrs}
end.


