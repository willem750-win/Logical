unit versionInfo;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
{$IFnDEF FPC}
  Windows,
{$ELSE}
  LCLIntf, LCLType, LMessages,
{$ENDIF}
  Messages, SysUtils, Classes, LResources, Graphics, Controls, Forms, Dialogs;

type
  TLangAndCP = record
    wLanguage : word;
    wCodePage : word;
    end;
  PLangAndCP = ^TLangAndCP;

  TCEVersionInfo = class(TComponent)
  private
    { Private declarations }
    FCompanyName      : string;
    FFileDescription  : string;
    FFileVersion      : string;
    FInternalname     : string;
    FLegalCopyright   : string;
    FLegalTradeMarks  : string;
    FOriginalFilename : string;
    FProductName      : string;
    FProductVersion   : string;
    FComments         : string;
    FMajorVersion     : string;
    FMinorVersion     : string;
    FRelease          : string;
    FBuild            : string;
  protected
    { Protected declarations }
  public
    { Public declarations }
    constructor Create(AOwner : TComponent); override;
    destructor  Destroy; override;
  published
    { Published declarations }
    property CompanyName      : string read FCompanyName write FCompanyName stored False;
    property FileDescription  : string read FFileDescription write FFileDescription stored False;
    property FileVersion      : string read FFileVersion write FFileVersion stored False;
    property Internalname     : string read FInternalname write FInternalname stored False;
    property LegalCopyright   : string read FLegalCopyright write FLegalCopyright stored False;
    property LegalTradeMarks  : string read FLegalTradeMarks write FLegalTradeMarks stored False;
    property OriginalFilename : string read FOriginalFilename write FOriginalFilename stored False;
    property ProductName      : string read FProductName write FProductName stored False;
    property ProductVersion   : string read FProductVersion write FProductVersion stored False;
    property Comments         : string read FComments write FComments stored False;
    property MajorVersion     : string read FMajorVersion write FMajorVersion stored False;
    property MinorVersion     : string read FMinorVersion write FMinorVersion stored False;
    property Release          : string read FRelease write FRelease stored False;
    property Build            : string read FBuild write FBuild stored False;

    procedure GetInfo(FName : string);
  end;

const
  InfoNum = 10;
  InfoStr : array [1..InfoNum] of String = ('CompanyName', 'FileDescription',
  'FileVersion', 'InternalName', 'LegalCopyright', 'LegalTradeMarks',
  'OriginalFilename', 'ProductName', 'ProductVersion', 'Comments');




implementation


 // {$I ceversioninfo_icon.lrs}

constructor TCEVersionInfo.Create(AOwner : TComponent);
begin
  inherited Create(AOwner);
  GetInfo(ParamStr(0));
end;

destructor TCEVersionInfo.Destroy;
begin
  inherited Destroy;
end;

procedure TCEVersionInfo.GetInfo(FName: string);
var
  N         : integer;
  ZValue    : cardinal;
  Buf       : PChar;
  Lang      : PLangAndCP;
  LangLen   : cardinal;
  SubBlock  : string;
  Value     : PChar;
  Len       : cardinal;
  S         : string;
  PointPos  : integer;
begin
  N:=GetFileVersionInfoSize(PChar(FName),ZValue);
  if N>0 then begin
    Buf:=AllocMem(N);
    GetFileVersionInfo(PChar(FName),0,N,Buf);
    VerQueryValue(Buf,PChar('\\VarFileInfo\\Translation'),Pointer(Lang),LangLen);

    SubBlock:=Format('\\StringFileInfo\\%.4x%.4x\\'+InfoStr[1],[Lang^.wLanguage,Lang^.wCodePage]);
    VerQueryValue(Buf,PChar(SubBlock),Pointer(Value),Len);
    FCompanyName:=string(Value);

    SubBlock:=Format('\\StringFileInfo\\%.4x%.4x\\'+InfoStr[2],[Lang^.wLanguage,Lang^.wCodePage]);
    VerQueryValue(Buf,PChar(SubBlock),Pointer(Value),Len);
    FFileDescription:=Value;

    SubBlock:=Format('\\StringFileInfo\\%.4x%.4x\\'+InfoStr[3],[Lang^.wLanguage,Lang^.wCodePage]);
    VerQueryValue(Buf,PChar(SubBlock),Pointer(Value),Len);
    FFileVersion:=Value;

    SubBlock:=Format('\\StringFileInfo\\%.4x%.4x\\'+InfoStr[4],[Lang^.wLanguage,Lang^.wCodePage]);
    VerQueryValue(Buf,PChar(SubBlock),Pointer(Value),Len);
    FInternalName:=Value;

    SubBlock:=Format('\\StringFileInfo\\%.4x%.4x\\'+InfoStr[5],[Lang^.wLanguage,Lang^.wCodePage]);
    VerQueryValue(Buf,PChar(SubBlock),Pointer(Value),Len);
    FLegalCopyright:=Value;

    SubBlock:=Format('\\StringFileInfo\\%.4x%.4x\\'+InfoStr[6],[Lang^.wLanguage,Lang^.wCodePage]);
    VerQueryValue(Buf,PChar(SubBlock),Pointer(Value),Len);
    FLegalTradeMarks:=Value;

    SubBlock:=Format('\\StringFileInfo\\%.4x%.4x\\'+InfoStr[7],[Lang^.wLanguage,Lang^.wCodePage]);
    VerQueryValue(Buf,PChar(SubBlock),Pointer(Value),Len);
    FOriginalFilename:=Value;

    SubBlock:=Format('\\StringFileInfo\\%.4x%.4x\\'+InfoStr[8],[Lang^.wLanguage,Lang^.wCodePage]);
    VerQueryValue(Buf,PChar(SubBlock),Pointer(Value),Len);
    FProductName:=Value;

    SubBlock:=Format('\\StringFileInfo\\%.4x%.4x\\'+InfoStr[9],[Lang^.wLanguage,Lang^.wCodePage]);
    VerQueryValue(Buf,PChar(SubBlock),Pointer(Value),Len);
    FProductVersion:=Value;

    SubBlock:=Format('\\StringFileInfo\\%.4x%.4x\\'+InfoStr[10],[Lang^.wLanguage,Lang^.wCodePage]);
    VerQueryValue(Buf,PChar(SubBlock),Pointer(Value),Len);
    FComments:=Value;

    if FFileVersion<>'' then begin
      PointPos:=Pos('.',FFileVersion);
      if PointPos<>0 then begin
        FMajorVersion:=Copy(FFileVersion,1,PointPos-1);
        S:=Copy(FileVersion,PointPos+1,Length(FFileVersion)-PointPos);
        PointPos:=Pos('.',S);
        FMinorVersion:=Copy(S,1,PointPos-1);
        S:=Copy(S,PointPos+1,Length(S)-PointPos);
        PointPos:=Pos('.',S);
        FRelease:=Copy(S,1,PointPos-1);
        FBuild:=Copy(S,PointPos+1,Length(S)-PointPos);
      end
      else begin
        PointPos:=Pos(',',FFileVersion);
        if PointPos<>0 then begin
          FMajorVersion:=Copy(FFileVersion,1,PointPos-1);
          S:=Copy(FileVersion,PointPos+1,Length(FFileVersion)-PointPos);
          PointPos:=Pos(',',S);
          FMinorVersion:=Copy(S,1,PointPos-1);
          S:=Copy(S,PointPos+1,Length(S)-PointPos);
          PointPos:=Pos(',',S);
          FRelease:=Copy(S,1,PointPos-1);
          FBuild:=Copy(S,PointPos+1,Length(S)-PointPos);
        end
        else begin
          FMajorVersion :='<info not available>';
          FMinorVersion :='<info not available>';
          FRelease      :='<info not available>';
          FBuild        :='<info not available>';
        end;
      end;
    end
    else begin
      FMajorVersion :='<info not available>';
      FMinorVersion :='<info not available>';
      FRelease      :='<info not available>';
      FBuild        :='<info not available>';
    end;

    FreeMem(Buf,N);
  end
  else begin
    FCompanyname      :='<info not available>';
    FFileDescription  :='<info not available>';
    FFileVersion      :='<info not available>';
    FInternalname     :='<info not available>';
    FLegalCopyright   :='<info not available>';
    FLegalTradeMarks  :='<info not available>';
    FOriginalFilename :='<info not available>';
    FProductName      :='<info not available>';
    FProductVersion   :='<info not available>';
    FComments         :='<info not available>';
    FMajorVersion     :='<info not available>';
    FMinorVersion     :='<info not available>';
    FRelease          :='<info not available>';
    FBuild            :='<info not available>';
  end;
end;


end.
