unit uLangPo;

{ Extra talen via .po-bestanden (gettext, te bewerken met bv. Poedit).

  Nederlands, Engels, Frans en Duits zitten in de code zelf. Voor een andere
  taal legt men een bestand <code>.po in de map lang naast het programma
  (bv. lang\it.po). De sleutel (msgid) is altijd de Engelse tekst.

  Werking: bij zo'n taal draait Logic intern in het Engels, en
  - de vertaalfuncties (Tr, MyTr, T, TrHelp) geven PoTr(<Engelse tekst>);
  - PoTranslateScreen vertaalt wat er op de vensters staat (Caption van
    knoppen, labels, tabbladen en vensters, menu's, keuzelijsten en de
    kolom met namen van de instellingen); dat gebeurt telkens als Logic
    niets te doen heeft (hoogstens om de 300 ms);
  - hints worden vertaald vlak voor ze verschijnen (Application.OnShowHint).
  Ontbreekt een vertaling, dan blijft de Engelse tekst staan. Een tekst met
  meerdere regels wordt zo nodig regel per regel vertaald.

  Met het argument --po-collect (of LOGIC_PO_COLLECT=1) schrijft Logic bij
  het afsluiten de Engelse teksten die het niet kon vertalen naar
  lang\missing-<code>.pot. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Menus, Grids,
  ComCtrls, TypInfo, Generics.Collections;

// map lang naast het programma (met afsluitende \ of /)
function PoLangDir: string;
// gevonden talen: ACodes = 'it', 'es' ...; ANames = 'Italiano', 'Español' ...
procedure PoListLanguages(ACodes, ANames: TStrings);
// laadt lang\<ACode>.po; False als het bestand ontbreekt of leeg is
function PoLoad(const ACode: string): Boolean;
procedure PoUnload;
function PoActive: Boolean;
function PoCode: string;
// vertaling van de Engelse tekst S (zonder actieve taal: S zelf)
function PoTr(const S: string): string;
// vertaalt Caption, menu's, keuzelijsten ... van AComp en alles eronder
procedure PoTranslateComponent(AComp: TComponent);
// alle zichtbare vensters
procedure PoTranslateScreen;

implementation

type
  TStrDict = specialize TDictionary<string, string>;

var
  FDict: TStrDict = nil;          // Engels -> vertaling
  FOut: TStrDict = nil;           // vertalingen (worden niet opnieuw vertaald)
  FMissing: TStringList = nil;    // alleen met --po-collect
  FCode: string = '';
  FCollect: Boolean = False;
  FLastSweep: QWord = 0;

type
  TIdleSweeper = class
    procedure AppIdle(Sender: TObject; var Done: Boolean);
  end;

var
  FSweeper: TIdleSweeper = nil;

function PoLangDir: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)) + 'lang');
end;

// naam van de taal in die taal zelf; anders de code in hoofdletters
function NativeName(const ACode: string): string;
const
  Codes: array[0..19] of string = ('it', 'es', 'pt', 'pl', 'cs', 'sk', 'hu',
    'ro', 'sv', 'da', 'no', 'fi', 'tr', 'ru', 'uk', 'ja', 'zh', 'id', 'el', 'ca');
  Names: array[0..19] of string = ('Italiano', 'Español', 'Português', 'Polski',
    'Čeština', 'Slovenčina', 'Magyar', 'Română', 'Svenska', 'Dansk', 'Norsk',
    'Suomi', 'Türkçe', 'Русский', 'Українська', '日本語', '中文', 'Bahasa Indonesia',
    'Ελληνικά', 'Català');
var
  I: Integer;
begin
  for I := Low(Codes) to High(Codes) do
    if SameText(Codes[I], ACode) then Exit(Names[I]);
  Result := UpperCase(ACode);
end;

function Unescape(const S: string): string;
var
  I: Integer;
begin
  Result := '';
  I := 1;
  while I <= Length(S) do
  begin
    if (S[I] = '\') and (I < Length(S)) then
    begin
      Inc(I);
      case S[I] of
        'n': Result := Result + #10;
        't': Result := Result + #9;
        'r': Result := Result + #13;
      else
        Result := Result + S[I];   // \" en \\
      end;
    end
    else
      Result := Result + S[I];
    Inc(I);
  end;
end;

function Escape(const S: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(S) do
    case S[I] of
      '"':  Result := Result + '\"';
      '\':  Result := Result + '\\';
      #10:  Result := Result + '\n';
      #13:  ;
      #9:   Result := Result + '\t';
    else
      Result := Result + S[I];
    end;
end;

// "tekst" -> tekst
function Quoted(const L: string): string;
var
  A, B: Integer;
begin
  Result := '';
  A := Pos('"', L);
  B := Length(L);
  while (B > A) and (L[B] <> '"') do Dec(B);
  if (A > 0) and (B > A) then
    Result := Unescape(Copy(L, A + 1, B - A - 1));
end;

// leest een .po-bestand; AHeader krijgt de kopregels (msgid "")
procedure ReadPo(const AFile: string; ADict: TStrDict; AHeader: TStrings);
var
  Lines: TStringList;
  I: Integer;
  L, Id, Str, Part: string;
  Fuzzy: Boolean;

  procedure Flush;
  begin
    if (Part <> '') then
    begin
      if Id = '' then
      begin
        if Assigned(AHeader) then AHeader.Text := StringReplace(Str, '\n', LineEnding, [rfReplaceAll]);
      end
      else if (Str <> '') and not Fuzzy and Assigned(ADict) then
        ADict.AddOrSetValue(Id, Str);
    end;
    Id := ''; Str := ''; Part := ''; Fuzzy := False;
  end;

begin
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(AFile);
    Id := ''; Str := ''; Part := ''; Fuzzy := False;
    for I := 0 to Lines.Count - 1 do
    begin
      L := Trim(Lines[I]);
      if (I = 0) and (Copy(L, 1, 3) = #$EF#$BB#$BF) then Delete(L, 1, 3);
      if L = '' then Continue;
      if L[1] = '#' then
      begin
        // een nieuw item begint met opmerkingen
        if Part = 'str' then Flush;
        if (Copy(L, 1, 2) = '#,') and (Pos('fuzzy', L) > 0) then Fuzzy := True;
        Continue;
      end;
      if Copy(L, 1, 7) = 'msgctxt' then
      begin
        if Part = 'str' then Flush;
        Part := 'ctxt';
      end
      else if Copy(L, 1, 5) = 'msgid' then
      begin
        if Part = 'str' then Flush;
        Part := 'id';
        Id := Quoted(L);
      end
      else if Copy(L, 1, 6) = 'msgstr' then
      begin
        Part := 'str';
        Str := Quoted(L);
      end
      else if L[1] = '"' then
      begin
        if Part = 'id' then Id := Id + Quoted(L)
        else if Part = 'str' then Str := Str + Quoted(L);
      end;
    end;
    if Part = 'str' then Flush;
  finally
    Lines.Free;
  end;
end;

procedure PoListLanguages(ACodes, ANames: TStrings);
var
  SR: TSearchRec;
  Code, Name: string;
  Header: TStringList;
begin
  ACodes.Clear;
  ANames.Clear;
  if FindFirst(PoLangDir + '*.po', faAnyFile, SR) = 0 then
  try
    repeat
      Code := LowerCase(ChangeFileExt(SR.Name, ''));
      // de vier talen in de code zelf worden niet nog eens aangeboden
      if (Code = 'nl') or (Code = 'en') or (Code = 'fr') or (Code = 'de') then Continue;
      Name := NativeName(Code);
      Header := TStringList.Create;
      try
        try
          ReadPo(PoLangDir + SR.Name, nil, Header);
        except
        end;
        Header.NameValueSeparator := ':';
        if Trim(Header.Values['X-Language-Name']) <> '' then
          Name := Trim(Header.Values['X-Language-Name']);
      finally
        Header.Free;
      end;
      ACodes.Add(Code);
      ANames.Add(Name);
    until FindNext(SR) <> 0;
  finally
    FindClose(SR);
  end;
end;

function PoLoad(const ACode: string): Boolean;
var
  F: string;
begin
  // al geladen (Logic kiest de taal opnieuw bij elke activering van het venster)
  if Assigned(FDict) and SameText(FCode, ACode) then Exit(True);
  PoUnload;
  Result := False;
  F := PoLangDir + LowerCase(ACode) + '.po';
  if not FileExists(F) then Exit;
  FDict := TStrDict.Create;
  FOut := TStrDict.Create;
  try
    ReadPo(F, FDict, nil);
  except
    FreeAndNil(FDict);
    FreeAndNil(FOut);
    Exit;
  end;
  if FDict.Count = 0 then
  begin
    FreeAndNil(FDict);
    FreeAndNil(FOut);
    Exit;
  end;
  FCode := LowerCase(ACode);
  Result := True;
  if not Assigned(FSweeper) then
  begin
    FSweeper := TIdleSweeper.Create;
    Application.AddOnIdleHandler(@FSweeper.AppIdle);
  end;
end;

procedure PoUnload;
begin
  FreeAndNil(FDict);
  FreeAndNil(FOut);
  FCode := '';
end;

function PoActive: Boolean;
begin
  Result := Assigned(FDict);
end;

function PoCode: string;
begin
  Result := FCode;
end;

// lijkt S op een tekst (een woord van minstens 3 letters, geen kleurnaam
// als clRed of klassenaam als TjanSimKnop)? Alleen voor --po-collect.
function HasLetter(const S: string): Boolean;
var
  I, Run: Integer;
begin
  Result := False;
  if (Pos(' ', S) = 0) and (Length(S) > 2) and
     (((S[1] = 'c') and (S[2] = 'l') and (S[3] in ['A'..'Z', '3'])) or
      ((S[1] = 'T') and (S[2] in ['A'..'Z', 'j']))) then Exit;
  Run := 0;
  for I := 1 to Length(S) do
    if S[I] in ['A'..'Z', 'a'..'z'] then
    begin
      Inc(Run);
      if Run >= 3 then Exit(True);
    end
    else
      Run := 0;
end;

procedure NoteMissing(const S: string);
begin
  if not FCollect or not HasLetter(S) or FOut.ContainsKey(S) then Exit;
  if not Assigned(FMissing) then
  begin
    FMissing := TStringList.Create;
    FMissing.Sorted := True;
    FMissing.Duplicates := dupIgnore;
  end;
  FMissing.Add(S);
end;

function Lookup(const S: string; out R: string): Boolean;
var
  T, Lead, Trail: string;
  A, B: Integer;
begin
  Result := FDict.TryGetValue(S, R);
  if Result then Exit;
  // zelfde tekst met spaties ervoor of erachter
  A := 1;
  while (A <= Length(S)) and (S[A] in [' ', #9]) do Inc(A);
  B := Length(S);
  while (B >= A) and (S[B] in [' ', #9]) do Dec(B);
  if (A > 1) or (B < Length(S)) then
  begin
    T := Copy(S, A, B - A + 1);
    Lead := Copy(S, 1, A - 1);
    Trail := Copy(S, B + 1, MaxInt);
    if FDict.TryGetValue(T, R) then
    begin
      R := Lead + R + Trail;
      Exit(True);
    end;
  end;
end;

function PoTr(const S: string): string;
var
  Parts: TStringList;
  I: Integer;
  Changed: Boolean;
  R, Sep: string;
begin
  Result := S;
  if not Assigned(FDict) or (S = '') then Exit;
  if FOut.ContainsKey(S) then Exit;
  if Lookup(S, R) then
  begin
    FOut.AddOrSetValue(R, '');
    Exit(R);
  end;
  if Pos(#10, S) = 0 then
  begin
    NoteMissing(S);
    Exit;
  end;
  // regel per regel
  if Pos(#13#10, S) > 0 then Sep := #13#10 else Sep := #10;
  Parts := TStringList.Create;
  try
    Parts.StrictDelimiter := True;
    Parts.LineBreak := Sep;
    Parts.Text := S;
    Changed := False;
    for I := 0 to Parts.Count - 1 do
      if Lookup(Parts[I], R) then
      begin
        Parts[I] := R;
        FOut.AddOrSetValue(R, '');
        Changed := True;
      end
      else
        NoteMissing(Parts[I]);
    if Changed then
    begin
      R := Parts[0];
      for I := 1 to Parts.Count - 1 do R := R + Sep + Parts[I];
      Result := R;
      FOut.AddOrSetValue(R, '');
    end;
  finally
    Parts.Free;
  end;
end;

// onderdelen van het paneel zelf (schakelaars, lampen ...): hun opschrift is
// inhoud van het paneel en wordt bewaard, dus niet vertalen
function IsPanelContent(AComp: TComponent): Boolean;
var
  U: string;
begin
  U := LowerCase(AComp.UnitName);
  Result := (Copy(U, 1, 3) = 'jan') or (U = 'chatgridpcodesmall');
end;

procedure TranslateStrProp(AComp: TComponent; const AProp: string);
var
  PI: PPropInfo;
  S, R: string;
begin
  PI := GetPropInfo(AComp, AProp);
  if (PI = nil) or not (PI^.PropType^.Kind in [tkAString, tkUString, tkSString, tkLString]) then Exit;
  if PI^.SetProc = nil then Exit;
  S := GetStrProp(AComp, PI);
  if S = '' then Exit;
  R := PoTr(S);
  if R <> S then SetStrProp(AComp, PI, R);
end;

procedure TranslateItems(AItems: TStrings);
var
  I: Integer;
  S, R: string;
begin
  for I := 0 to AItems.Count - 1 do
  begin
    S := AItems[I];
    R := PoTr(S);
    if R <> S then AItems[I] := R;
  end;
end;

procedure TranslateOne(AComp: TComponent);
var
  I, Idx: Integer;
  G: TStringGrid;
  S, R: string;
begin
  if AComp is TMenuItem then
  begin
    TranslateStrProp(AComp, 'Caption');
    Exit;
  end;
  if IsPanelContent(AComp) then Exit;
  // invoervelden: de tekst is van de gebruiker
  if (AComp is TCustomEdit) then Exit;
  if AComp is TCustomComboBox then
  begin
    if TCustomComboBox(AComp).Style in [csDropDownList, csOwnerDrawFixed, csOwnerDrawVariable] then
    begin
      Idx := TCustomComboBox(AComp).ItemIndex;
      TranslateItems(TCustomComboBox(AComp).Items);
      if TCustomComboBox(AComp).ItemIndex <> Idx then TCustomComboBox(AComp).ItemIndex := Idx;
    end;
    Exit;
  end;
  if AComp is TCustomRadioGroup then
  begin
    Idx := TCustomRadioGroup(AComp).ItemIndex;
    TranslateItems(TCustomRadioGroup(AComp).Items);
    if TCustomRadioGroup(AComp).ItemIndex <> Idx then TCustomRadioGroup(AComp).ItemIndex := Idx;
  end
  else if AComp is TCustomCheckGroup then
    TranslateItems(TCustomCheckGroup(AComp).Items);
  // instellingen: kolom 3 bevat de (vertaalde) naam, rij 0 de kolomkoppen
  if (AComp is TStringGrid) and (AComp.ClassName = 'TAdvancedPropertyGrid') then
  begin
    G := TStringGrid(AComp);
    for I := 0 to G.ColCount - 1 do
    begin
      S := G.Cells[I, 0];
      R := PoTr(S);
      if R <> S then G.Cells[I, 0] := R;
    end;
    if G.ColCount > 3 then
      for I := 1 to G.RowCount - 1 do
      begin
        S := G.Cells[3, I];
        R := PoTr(S);
        if R <> S then G.Cells[3, I] := R;
      end;
    Exit;
  end;
  if AComp is TStatusBar then
  begin
    for I := 0 to TStatusBar(AComp).Panels.Count - 1 do
    begin
      S := TStatusBar(AComp).Panels[I].Text;
      R := PoTr(S);
      if R <> S then TStatusBar(AComp).Panels[I].Text := R;
    end;
    TranslateStrProp(AComp, 'SimpleText');
    Exit;
  end;
  if AComp is TControl then
    TranslateStrProp(AComp, 'Caption');
end;

procedure PoTranslateComponent(AComp: TComponent);
var
  I: Integer;
begin
  if not Assigned(FDict) or (AComp = nil) then Exit;
  TranslateOne(AComp);
  for I := 0 to AComp.ComponentCount - 1 do
    PoTranslateComponent(AComp.Components[I]);
  // ook wat in een ander onderdeel ligt dan zijn eigenaar (bv. het venster
  // met de instellingen, zonder eigenaar op het paneel)
  if AComp is TWinControl then
    for I := 0 to TWinControl(AComp).ControlCount - 1 do
      if TWinControl(AComp).Controls[I].Owner <> AComp then
        PoTranslateComponent(TWinControl(AComp).Controls[I]);
end;

procedure PoTranslateScreen;
var
  I: Integer;
begin
  if not Assigned(FDict) then Exit;
  for I := 0 to Screen.CustomFormCount - 1 do
    if Screen.CustomForms[I].Visible then
      PoTranslateComponent(Screen.CustomForms[I]);
  FLastSweep := GetTickCount64;
end;

procedure TIdleSweeper.AppIdle(Sender: TObject; var Done: Boolean);
begin
  if Assigned(FDict) and (GetTickCount64 - FLastSweep >= 300) then
    PoTranslateScreen;
end;

procedure SaveMissing;
var
  L: TStringList;
  I: Integer;
begin
  if not Assigned(FMissing) or (FMissing.Count = 0) or (FCode = '') then Exit;
  L := TStringList.Create;
  try
    for I := 0 to FMissing.Count - 1 do
    begin
      L.Add('msgid "' + Escape(FMissing[I]) + '"');
      L.Add('msgstr ""');
      L.Add('');
    end;
    try
      ForceDirectories(PoLangDir);
      L.SaveToFile(PoLangDir + 'missing-' + FCode + '.pot');
    except
    end;
  finally
    L.Free;
  end;
end;

var
  I: Integer;

initialization
  FCollect := GetEnvironmentVariable('LOGIC_PO_COLLECT') = '1';
  for I := 1 to ParamCount do
    if ParamStr(I) = '--po-collect' then FCollect := True;

finalization
  SaveMissing;
  FreeAndNil(FMissing);
  PoUnload;
  FreeAndNil(FSweeper);
end.
