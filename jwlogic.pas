{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit jwlogic;

{$warn 5023 off : no warning about unused units}
interface

uses
  janLed, janSimIndicator, janSimLogic, janSimPID, janSimPIDLinker, janToggle, 
  jwlogicreg, InTex, tiphtmln, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('janSimLogic', @janSimLogic.Register);
  RegisterUnit('jwlogicreg', @jwlogicreg.Register);
  RegisterUnit('InTex', @InTex.Register);
  RegisterUnit('tiphtmln', @tiphtmln.Register);
end;

initialization
  RegisterPackage('jwlogic', @Register);
end.
