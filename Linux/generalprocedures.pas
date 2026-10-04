unit GeneralProcedures;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrHolder, TypInfo, IniFiles, Dialogs, DCPrijndael, DCPsha256;

  procedure LoadObjectPropertiesRelevantFromStrHolder(TargetObject: TObject;Relevant:String ;StrHolder: TStrHolder);
  procedure SaveObjectPropertiesRelevantToIni(TargetObject: TObject; Relevant: String; const FileName: string; Encrypt: Boolean);
  // tools
  procedure ShowMemIniFileContent(Ini: TMemIniFile);
  // einde tools
implementation

procedure SaveObjectPropertiesRelevantToIni(TargetObject: TObject; Relevant: String; const FileName: string; Encrypt: Boolean);
var
  PropList: PPropList;
  PropCount, i: Integer;
  Ini: TStringList;RelevantProps: TStringList;
  PropName, PropValue, EncryptedContent: string;
  Cipher: TDCP_rijndael;
  Key: array[0..31] of Byte;

begin
  Ini := TStringList.Create;
  RelevantProps := TStringList.Create;
  Cipher := TDCP_rijndael.Create(nil);
  try
    // Voeg hier je relevante properties toe
    RelevantProps.CommaText := Relevant;
    PropCount := GetPropList(TargetObject.ClassInfo, tkProperties, nil);
    GetMem(PropList, PropCount * SizeOf(PPropInfo));
    try
      GetPropList(TargetObject.ClassInfo, tkProperties, PropList);
      for i := 0 to PropCount - 1 do
      begin
        PropName := PropList^[i]^.Name;
        // Controleer of de eigenschap relevant is en schrijfbaar is
        if (PropList^[i]^.SetProc <> nil) and (RelevantProps.IndexOf(PropName) <> -1) then
        begin
          PropValue := GetPropValue(TargetObject, PropName, True);
          Ini.Add(PropName + '=' + PropValue);
        end;
      end;
    finally
      FreeMem(PropList);
    end;
    if Encrypt then
    begin
      // Stel een versleutelingssleutel in
      FillChar(Key, SizeOf(Key), 0);
      Move(PAnsiChar(AnsiString('MijnSterkeSleutel'))^, Key, Length('MijnSterkeSleutel'));
      Cipher.Init(Key, SizeOf(Key) * 8, nil);
      try
        // Converteer de INI-inhoud naar een versleutelde string
        //  var EncryptedContent: string;
        EncryptedContent := Cipher.EncryptString(Ini.Text);
        // Schrijf de versleutelde inhoud naar een bestand
        with TFileStream.Create(FileName, fmCreate) do
        try
          Write(Pointer(EncryptedContent)^, Length(EncryptedContent));
        finally
          Free;
        end;
      finally
        Cipher.Burn;
      end;
    end
    else
    begin
      // Schrijf de niet-versleutelde inhoud naar het bestand
      Ini.SaveToFile(FileName);
    end;
  finally
    RelevantProps.Free;
    Ini.Free;
    Cipher.Free;
  end;
end;
// debug tools
procedure ShowMemIniFileContent(Ini: TMemIniFile);
var
  Sections, Keys: TStringList;
  Section, Key, Value: string;
  i, j: Integer;
  Output: string;
begin
  Output := 'Inhoud van TMemIniFile:' + sLineBreak;
  Sections := TStringList.Create;
  Keys := TStringList.Create;
  try
    // Lees alle secties uit de TMemIniFile
    Ini.ReadSections(Sections);
    for i := 0 to Sections.Count - 1 do
    begin
      Section := Sections[i];
      Output := Output + '[' + Section + ']' + sLineBreak;

      // Lees alle sleutels in de huidige sectie
      Ini.ReadSection(Section, Keys);
      for j := 0 to Keys.Count - 1 do
      begin
        Key := Keys[j];
        Value := Ini.ReadString(Section, Key, '');
        Output := Output + Key + '=' + Value + sLineBreak;
      end;
      Output := Output + sLineBreak; // Voeg lege regel toe tussen secties
    end;

    // Toon het resultaat in een ShowMessage
    ShowMessage(Output);
  finally
    Sections.Free;
    Keys.Free;
  end;
end;
// einde debug tools


procedure LoadObjectPropertiesRelevantFromStrHolder(TargetObject: TObject;Relevant:String ;StrHolder: TStrHolder);
var
  PropList: PPropList;
  PropCount, i: Integer;
  Ini: TMemIniFile;
  StringStream: TStringStream;
  PropValue: string;
  RelevantProps: TStringList;
  PropName: string;
begin
 // ShowMessage('Start opladen');
  // Maak een TStringStream aan en laad de inhoud van TStrHolder
  StringStream := TStringStream.Create('');
  try
    StringStream.WriteString(StrHolder.Strings.Text); // StrHolder naar stream
    StringStream.Position := 0;
   // showMessage( StrHolder.Strings.Text);
    // Laad de stream in een TMemIniFile
    Ini := TMemIniFile.Create(StringStream);
     // test
        // ShowMemIniFileContent(Ini);
     // einde test
    try
      RelevantProps := TStringList.Create;
      try
        // Voeg hier je relevante properties toe
        RelevantProps.CommaText := Relevant;
        // Haal de properties op uit TargetObject
        PropCount := GetPropList(TargetObject.ClassInfo, tkProperties, nil);
          //showMessage('AanTal propertys = '+ inttostr(PropCount));
        GetMem(PropList, PropCount * SizeOf(PPropInfo));
        try
         // ShowMessage('TargetObject ClassName: ' + TargetObject.ClassName);
          GetPropList(TargetObject.ClassInfo, tkProperties, PropList);
          for i := 0 to PropCount - 1 do
          begin
            PropName := PropList^[i]^.Name;
            // Controleer of de eigenschap relevant en schrijfbaar is
            if (PropList^[i]^.SetProc <> nil) and (RelevantProps.IndexOf(PropName) <> -1) then
            begin
              PropValue := Ini.ReadString('Properties', PropName, '');
              //showMessage(PropName + ' = '+PropValue);
              if PropValue <> '' then
                SetPropValue(TargetObject, PropName, PropValue);
            end;
          end;
        finally
          FreeMem(PropList);
        end;
      finally
        RelevantProps.Free;
      end;
    finally
      Ini.Free;
    end;
  finally
    StringStream.Free;
  end;
 // ShowMessage('Einde opladen');
end;


end.


