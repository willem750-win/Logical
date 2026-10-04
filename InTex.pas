
UNIT InTex;

{$mode ObjFPC}{$H+}

INTERFACE

USES

  LCLIntf, LCLType,// LMessages,
  SysUtils,Classes;

TYPE

  ENotFound = CLASS(Exception);

  TInTex = CLASS(TComponent)
  private
    fStrings: TStrings;
    fTemp: TStrings;
    PROCEDURE SetStrings(Value: TStrings);
  protected
  public
    CONSTRUCTOR Create(AOwner: TComponent); override;
    DESTRUCTOR Destroy; override;

    FUNCTION GetValue(Section, Naam: STRING): STRING;  //Get a single value if in name=value format
    FUNCTION GetSection(Section: STRING): TStrings;    //Get Section contents
    FUNCTION GetSectionNames(Section: STRING): TStrings; //Get Section names if in name=value format
    FUNCTION GetSectionValues(Section: STRING): TStrings;//Get Section values if in name=value format
    FUNCTION GetSectionHeadings: TStrings;               //Get all Section headings
  published
    PROPERTY Strings: TStrings read FStrings write SetStrings;
END;

PROCEDURE Register;

IMPLEMENTATION

PROCEDURE Register;
BEGIN
  RegisterComponents('JWLOGIC', [TInTex]);
END;

FUNCTION TInTex.GetValue(Section, Naam: STRING): STRING;
VAR
  I: integer;
BEGIN
  I := fStrings.IndexOf('[' + Section + ']');
  IF I >= 0 THEN
  BEGIN
    FOR I := I + 1 TO fStrings.Count - 1 DO
    BEGIN
      IF Pos('[', fStrings[I]) = 1 THEN Break;
      IF fStrings.Names[I] = Naam THEN
      BEGIN
        Result := fStrings.Values[Name];
        Break;
      END;
    END;
  END
  ELSE
  BEGIN
    RAISE ENotFound.Create('The Section "' + Section + '" was not found.');
    Exit;
  END;

  IF Result = '' THEN
    RAISE ENotFound.Create('The value for "' + Name + '" was not found.');
END;

FUNCTION TInTex.GetSectionNames(Section: STRING): TStrings;
VAR
  I: integer;
BEGIN
  fTemp.Clear;
  I := fStrings.IndexOf('[' + Section + ']');
  IF I >= 0 THEN
  BEGIN
    FOR I := I + 1 TO fStrings.Count - 1 DO
      IF Pos('[', fStrings[I]) = 1 THEN Break ELSE fTemp.Add(fStrings.Names[I]);
    Result := fTemp;
  END
  ELSE
    RAISE ENotFound.Create('The Section "' + Section + '" was not found.');

  IF Result.Count = 0 THEN
    RAISE ENotFound.Create('There are no names in section "' + Section + '".');
END;

FUNCTION TInTex.GetSectionValues(Section: STRING): TStrings;
VAR
  I: Integer;
BEGIN
  fTemp.Clear;
  I := fStrings.IndexOf('[' + Section + ']');
  IF I >= 0 THEN
  BEGIN
    FOR I := I + 1 TO fStrings.Count - 1 DO
      IF Pos('[', fStrings[I]) = 1 THEN Break ELSE fTemp.Add(fStrings.Values[fStrings.Names[I]]);
    Result := fTemp;
  END
  ELSE
    RAISE ENotFound.Create('The Section "' + Section + '" was not found.');

  IF Result.Count = 0 THEN
    RAISE ENotFound.Create('There are no values in section "' + Section + '".');
END;

FUNCTION TInTex.GetSection(Section: STRING): TStrings;
VAR
  I: Integer;
BEGIN
  fTemp.Clear;
  I := fStrings.IndexOf('[' + Section + ']');
  IF I >= 0 THEN
  BEGIN
    FOR I := I + 1 TO fStrings.Count - 1 DO
      IF Pos('[', fStrings[I]) = 1 THEN Break ELSE fTemp.Add(fStrings[I]);
    Result := fTemp;
  END
  ELSE
    RAISE ENotFound.Create('The Section "' + Section + '" was not found.');
END;

FUNCTION TInTex.GetSectionHeadings: TStrings;
VAR
  I: integer;
BEGIN
  fTemp.Clear;
  FOR I := 0 TO fStrings.Count - 1 DO
    IF Pos('[', fStrings[I]) = 1 THEN fTemp.Add(fStrings[I]);
  Result := fTemp;

  IF Result.Count = 0 THEN
    RAISE ENotFound.Create('No section headings were found.');
END;

PROCEDURE TInTex.SetStrings(Value: TStrings);
BEGIN
  IF fStrings <> value THEN
  BEGIN
    fStrings.BeginUpdate;
    fStrings.Assign(Value);
    fStrings.EndUpDate;
  END;
END;


CONSTRUCTOR TInTex.Create(AOwner: TComponent);
BEGIN
  INHERITED Create(AOwner);
  fStrings := TStringList.Create;
  fTemp := TStringList.Create;
END;

DESTRUCTOR TInTex.Destroy;
BEGIN
  fStrings.Free;
  fTemp.Free;
  INHERITED Destroy;
END;

END.

