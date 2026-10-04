{$O+} // Optimization must be ON

unit SZCodeBaseX;

{$MODE Delphi}

/////////////////////////////
// Version 1.2.1
////////////////////////////

{

 The contents of this file are subject to the Mozilla Public License
 Version 1.1 (the "License"); you may not use this file except in compliance
 with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/

 Software distributed under the License is distributed on an "AS IS" basis,
 WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the
 specific language governing rights and limitations under the License.

 The original code is SZCodeBaseX.pas, released 15. July, 2004.

 The initial developer of the original code is
 Sasa Zeman (public@szutils.net, www.szutils.net)

 Copyright(C) 2004 Sasa Zeman. All Rights Reserved.
}

{--------------------------------------------------------------------

Encode/Decode algorithms for Base16, Base32 and Base64
Reference: RFC 3548

- Universal Encode/Decode algorithms for Base16, Base32 and Base64
- Standard Base16, Base32 and Base64 encoding/decoding functions
- Reference: RFC 3548, full compatibility
- Supported work with Memory, Stream, String and Files
- Optionally supported work with padding keys (required numbers 
  of '=' at the end of the encoded array)
- Very flexible work - you may easily create your own Encode/Decode functions
  based on your own specific codes, from Base2 up to Base128

Revision History:

Version 1.2.0, 19. November 2004
  - Added support for Memory, Stream and Files

Version 1.1.0, 21. August 2004
  - Optimized version, more than 35 times speed acceleration,
    one of the fastest and the simplest universal Base16/32/64 encoder/decoder

Version 1.0.0, 15. July 2004
  - Initial version

  Author   : Sasa Zeman
  E-mail   : public@szutils.net or sasaz72@mail.ru
  Web site : www.szutils.net
}

interface

uses LCLIntf, LCLType, LMessages, SysUtils, Types, Classes;

//////////////////////////////////////////////////////////////////
// Universal Encode/Decode algorithms for Base16, Base32 and Base64
// Actualy, you can create any variation you need, even by your own
// codes from Base2 to Base128
//////////////////////////////////////////////////////////////////

function SZEncodeBaseXMemory( pIN, pOUT: pByte; Size: integer; const Codes: String; BITS: integer; FullQuantum : integer = 0): integer;
function SZDecodeBaseXMemory( pIN, pOUT: pByte; Size: integer; const Codes: string; BITS: integer): integer;

function SZEncodeBaseXStream(sIN, sOUT: TStream; Size: integer; const Codes: String; BITS: integer; FullQuantum : integer = 0): integer;
function SZDecodeBaseXStream(sIN, sOUT: TStream; const Codes: String; BITS: integer): integer;

function SZEncodeBaseXString(const S: string; const Codes: string; BITS: integer; FullQuantum : integer = 0): string;
function SZDecodeBaseXString(const S: string; const Codes: string; BITS: integer): string;

function SZEncodeBaseXFile(const FileName: String; sOUT: TStream; const Codes: string; BITS: integer; FullQuantum : integer = 0): integer;
// Decoding entire file is not supported, as is not logical - file may
// contain any data, or more then one encoded data
// Use the stream realization for precise and logical decoding - even
// for a part of a stream (fully suppoted)

// Calculates full reqired memory for output
// based on input size, BITS and needs for padding keys
function SZCalcRequireOutputMemory(TotalIn: integer; BITS, FullQuantum: integer): integer;

// Calculates reqired ammoun of padding keys based on output size
function SZCalcRequiredPaddingKeys(Size, FullQuantum: integer):Integer;

//////////////////////////////////////////////////////////////////
// ATTENTION!!! Next two funtion are for testing purposes only.
// My be deleted in the future.
////////////////////////////////////////////////////////////////////
function SZFullEncodeOnlyBase64(const S: string): string;
function SZFullEncodeOnlyBase64_6(const S: string): string;

////////////////////////////////////////////////////////////////////
// Base 16
//////////////////////////////////////////////////////////////////
function SZEncodeBase16(pIN, pOUT: PByte; Size: integer): integer; overload;
function SZEncodeBase16(sIN, sOUT: TStream; Size: integer=-1): integer; overload;
function SZEncodeBase16(const S: string): string; overload;
function SZEncodeBase16(const FileName: String; sOUT: TStream): integer; overload;

function SZDecodeBase16(pIN, pOUT: PByte; Size: integer): integer; overload;
function SZDecodeBase16(sIN, sOUT: TStream): integer; overload;
function SZDecodeBase16(const S: string): string; overload;

//////////////////////////////////////////////////////////////////
// Base32, Full encoding mean adding padding keys
//////////////////////////////////////////////////////////////////

function SZFullEncodeBase32(pIN, pOUT: PByte; Size: integer): integer; overload;
function SZFullEncodeBase32(sIN, sOUT: TStream; Size: integer=-1): integer; overload;
function SZFullEncodeBase32(const S: string): string; overload;
function SZFullEncodeBase32(const FileName: String; sOUT: TStream): integer; overload;

function SZEncodeBase32(pIN, pOUT: PByte; Size: integer): integer; overload;
function SZEncodeBase32(sIN, sOUT: TStream; Size: integer=-1): integer; overload;
function SZEncodeBase32(const S: string): string; overload;
function SZEncodeBase32(const FileName: String; sOUT: TStream): integer; overload;

function SZDecodeBase32(pIN, pOUT: PByte; Size: integer): integer; overload;
function SZDecodeBase32(sIN, sOUT: TStream): integer; overload;
function SZDecodeBase32(const S: string): string; overload;

//////////////////////////////////////////////////////////////////
// Base 64, Full encoding mean adding padding keys
//////////////////////////////////////////////////////////////////

function SZFullEncodeBase64(pIN, pOUT: PByte; Size: integer): integer; overload;
function SZFullEncodeBase64(sIN, sOUT: TStream; Size: integer=-1): integer; overload;
function SZFullEncodeBase64(const S: string): string; overload;
function SZFullEncodeBase64(const FileName: String; sOUT: TStream): integer; overload;

function SZEncodeBase64(pIN, pOUT: PByte; Size: integer): integer; overload;
function SZEncodeBase64(sIN, sOUT: TStream; Size: integer=-1): integer; overload;
function SZEncodeBase64(const S: string): string; overload;
function SZEncodeBase64(const FileName: String; sOUT: TStream): integer; overload;

function SZDecodeBase64(pIN, pOUT: PByte; Size: integer): integer; overload;
function SZDecodeBase64(sIN, sOUT: TStream): integer; overload;
function SZDecodeBase64(const S: string): string; overload;

//////////////////////////////////////////////////////////////////
// Base64 URL
//////////////////////////////////////////////////////////////////
function SZFullEncodeBase64URL(pIN, pOUT: PByte; Size: integer): integer; overload;
function SZFullEncodeBase64URL(sIN, sOUT: TStream; Size: integer=-1): integer; overload;
function SZFullEncodeBase64URL(const S: string): string; overload;
function SZFullEncodeBase64URL(const FileName: String; sOUT: TStream): integer; overload;

function SZEncodeBase64URL(pIN, pOUT: PByte; Size: integer): integer; overload;
function SZEncodeBase64URL(sIN, sOUT: TStream; Size: integer=-1): integer; overload;
function SZEncodeBase64URL(const S: string): string; overload;
function SZEncodeBase64URL(const FileName: String; sOUT: TStream): integer; overload;

function SZDecodeBase64URL(pIN, pOUT: PByte; Size: integer): integer; overload;
function SZDecodeBase64URL(sIN, sOUT: TStream): integer; overload;
function SZDecodeBase64URL(const S: string): string; overload;

//////////////////////////////////////////////////////////////////
// Setting Buffer Size procedure
//////////////////////////////////////////////////////////////////
procedure SZCodeBaseXSetBufferSize(Size:integer);
procedure SZCodeBaseXSetOrigBufferSize;
//////////////////////////////////////////////////////////////////
                       
implementation

const

  // Basic size for buffer is 64KB
  SZORIGBUFFSIZE = 64*1024;

///////////////////////////////////////////
/// Base 64 definitioins
///////////////////////////////////////////

  SZCodes64    = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  SZCodes64URL = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
  SZBITS64 = 6;

  // Result number of chars must be integral multiple of
  // 24 input bits div 6 output group bits
  SZFullQuantum64 = 24 div 6;

  ///////////////////////////////////////////

///////////////////////////////////////////
/// Base 32 definitioins
///////////////////////////////////////////

  SZCodes32 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  SZBITS32 = 5;

  // Result number of chars must be integral multiple of
  // 40 input bits div 5 output group bits
  SZFullQuantum32 = 40 div 5;

///////////////////////////////////////////

///////////////////////////////////////////
/// Base 16 definitioins
///////////////////////////////////////////

  SZCodes16 = '0123456789ABCDEF';
  SZBITS16 = 4;

///////////////////////////////////////////

  codes64: array[0..63] of byte = (
    065, 066, 067, 068, 069, 070, 071, 072,
    073, 074, 075, 076, 077, 078, 079, 080,
    081, 082, 083, 084, 085, 086, 087, 088,
    089, 090, 097, 098, 099, 100, 101, 102,
    103, 104, 105, 106, 107, 108, 109, 110,
    111, 112, 113, 114, 115, 116, 117, 118,
    119, 120, 121, 122, 048, 049, 050, 051,
    052, 053, 054, 055, 056, 057, 043, 047);

type
  TFastDecodeTable=array[0..255] of byte;

var
  // Optimized buffer length for encoding files up to 64KB
  // Important for speed-up works with large streams

  SZBUFFSIZE: integer;

  SZFastDecodeTable: TFastDecodeTable;

////////////////////////////
// Basic Function
////////////////////////////

procedure SZUpdateFastDecodeTable(const Codes: string);
var
  i: integer;
begin
  FillChar(SZFastDecodeTable,256,#0);

  for i := 1 to length(Codes) do
    SZFastDecodeTable[ byte( Codes[i] ) ] := i;
end;

function SZCalcRequiredPaddingKeys(Size, FullQuantum: integer):Integer;
{
 Adding necessary padding keys to create a full
 RFC 3548 compatibility string
}
var
  IM: integer;
begin
  IM:=Size mod FullQuantum;

  if IM>0 then
    Result:=FullQuantum-IM
  else
    Result:=0
end;

function SZCalcRequireOutputMemory(TotalIn: integer; BITS, FullQuantum: integer): integer;
var
  TotalOut, IM: integer;
begin

  TotalOut := TotalIn shl 3; // * 8

  if TotalOut mod BITS > 0 then
    TotalOut:= TotalOut div BITS +1
  else
    TotalOut:= TotalOut div BITS;

  if FullQuantum>0 then
  begin
    IM:=TotalOut mod FullQuantum;

    if IM>0 then
      TotalOut:= TotalOut + FullQuantum-IM;
  end;

  result:=TotalOut;
end;

procedure GetRelevantData(TotalIn: integer; var TotalOut: integer;
        BITS, FullQuantum: integer; var IM: integer);
begin

  TotalOut := TotalIn shl 3; // * 8

  if TotalOut mod BITS > 0 then
    TotalOut:= TotalOut div BITS +1
  else
    TotalOut:= TotalOut div BITS;

  if FullQuantum>0 then
  begin
    IM:=TotalOut mod FullQuantum;

    if IM>0 then
      TotalOut:= TotalOut + FullQuantum-IM;
  end
  else
    IM:=0;
end;

////////////////////////////
// Memory
////////////////////////////

function SZEncodeBaseXMemoryUpdate(pIN: PByte; var pOUT: PByte; Size: integer; {Codes: pchar}const Codes: String; BITS: integer; var vB8, VI8: integer): integer;
{
 Universal Encode algorithm for Base16, Base32 and Base64
 Reference: RFC 3548
 RFC incompatibility: No padding keys
}

const Mask: array [0..16] of Word=
( 0, 1, 3, 7, 15, 31, 63,
  127,255,511,1023, 2047,
  4095,8191,16383,32767,65535
);

var
  i,B8, I8: integer;
//  pIN, pOUT: PByte;

  Count: integer;

begin
  Count:=0;

  B8 := vB8;
  I8 := vI8;

  for i := 1 to Size do
  begin
    B8 := B8 shl 8;
    B8 := B8 or pIN^;
    I8 := I8 + 8;

    while I8 >= BITS do
    begin

      I8 := (I8 - BITS);

      // Get first BITS of bits
      pchar(pOUT)^ := Codes[(B8 shr I8)+1];
      inc(pOUT);
      inc(Count);

      //Return position back for BITS bits
      //B8 := B8 - ((B8 shr I8) shl I8);

      // The same result as upper code, a bit faster
      B8 := B8 and MASK[I8];

    end;

    inc(pIN);

  end;

  vB8 := B8;
  vI8 := I8;

  result:=Count;
end;
                 
function SZEncodeBaseXMemoryFinalyze(var pOUT: PByte; const Codes: String; BITS: integer; B8, I8: integer): integer;
// Finalyzing encoding with last left bites (if any)
begin
  // If something left
  if I8 > 0 then
  begin
    pchar(pOUT)^ := Codes[ (B8 shl (BITS-I8)) + 1];
    inc(pOUT);
    result:=1;
  end else
    result:=0;
end;

function SZEncodeBaseXMemory(pIN, pOUT: pByte; Size: integer; const Codes: String; BITS: integer; FullQuantum : integer = 0): integer;
var
  B8,I8: integer;

//  TotalIn  : integer;
  TotalOut : integer;
  IM       : integer;

  ppIN, ppOUT: pByte;
begin
  B8:=0;
  I8:=0;

  ppIN  := pIN;
  ppOUT := pOut;

  TotalOut:=SZEncodeBaseXMemoryUpdate(ppIN, ppOUT, Size, Codes, BITS, B8, I8);

  // If something left
  if I8>0 then
    TotalOut:=TotalOut+
      SZEncodeBaseXMemoryFinalyze(ppOut, Codes, BITS, B8, I8);


  if FullQuantum>0 then
  begin

    // Calculate relevant data
    //GetRelevantData(TotalIn, TotalOut, BITS, FullQuantum, IM);

    // Get required padding keys
    IM:=SZCalcRequiredPaddingKeys(TotalOut, FullQuantum);

    if IM>0 then
    begin
      FillChar( ppOUT^, FullQuantum - IM ,'=');
      TotalOut:=TotalOut+IM
    end
  end;

  result:=TotalOut;
end;


function SZDecodeBaseXMemoryUpdate(pIN,pOUT: pByte; Size: integer; const FastDecodeTable: TFastDecodeTable; BITS: integer; var B8, I8 : integer): integer;
{
 Universal Decode algorithm for Base16, Base32 and Base64
 Reference: RFC 3548 - full compatibility
}

var
  i: Integer;
  TotalIN, Count: integer;

begin

  TotalIN  := Size;

  // Start decoding
  count := 0;
  for i := 1 to TotalIN do
  begin

    if SZFastDecodeTable[pIN^] > 0 then
    begin

      B8 := B8 shl BITS;
      B8 := B8 or (SZFastDecodeTable[pIN^]-1);

      I8 := I8 + BITS;

      while I8 >= 8 do
      begin
        I8 := I8 - 8;

        pOUT^ := B8 shr I8;
        inc( pOUT );

        inc(count)
      end;

      inc(pIN);
    end
    else
      break
  end;

  result:=Count;
end;

function SZDecodeBaseXMemory(pIN,pOUT: pByte; Size: integer; const Codes: string; BITS: integer): integer;
{
 Universal Decode algorithm for Base16, Base32 and Base64
 Reference: RFC 3548 - full compatibility
}

var
  B8, I8 : integer;
begin
  B8:=0;
  I8:=0;

  SZUpdateFastDecodeTable(Codes);

  result:=SZDecodeBaseXMemoryUpdate( pIN, pOUT, Size, SZFastDecodeTable, BITS, B8, I8);
end;

function SZDecodeBaseXString(const S: string; const Codes: String; BITS: integer): String;
var
  TotalIn  : integer;
  TotalOut : integer;

  pIN,pOUT: pByte;

begin

  TotalIn  := length(S);
  TotalOut := (TotalIn * BITS) div 8;

  Setlength(Result,TotalOut);

  pIN  := @S[1];
  pOUT := @Result[1];


  TotalOut:=SZDecodeBaseXMemory( pIN, pOUT, TotalIn, Codes, BITS);

  if length(Result)<> TotalOut then
    Setlength(Result,TotalOut);
end;

function SZEncodeBaseXString(const S: string; const Codes: string; BITS: integer; FullQuantum : integer = 0): string;
// Universal Encode algorithm for Base16, Base32 and Base64
var
  pIN, pOUT: pByte;

  TotalIn, TotalOut: integer;
  IM: integer;

  Count: integer;
begin

  TotalIn  := length(s);

  // Calculate relevant data
  GetRelevantData(TotalIn, TotalOut, BITS, FullQuantum, IM);

  SetLength(Result,TotalOut);

  pIN :=@S[1];
  pOUT:=@Result[1];

  Count:=SZEncodeBaseXMemory(pIn,pOut, TotalIn, Codes, BITS);

  // Adding Padding keys

  if IM>0 then
  begin
    pchar(pOut):=pchar(pOut)+count;
    FillChar( pOUT^, FullQuantum - IM ,'=');
  end;

end;

//////////////////////////
// Stream
//////////////////////////

function SZEncodeBaseXStreamUpdate(sIN, sOUT: TStream; Size: integer; const Codes: String; BITS: integer; var vB8, vI8: integer): integer;
var
  pBuffIn, pBuffOut: pByte;
  Res,BUFF : Integer;
  pIn,pOut: pByte;
  LOut,Count,TotalIn, TotalOut: integer;

begin

  BUFF := SZBUFFSIZE;

  TotalIn:=Size;

  if BUFF > TotalIn  then
    BUFF:=TotalIn+1;

  TotalOut := BUFF shl 3; // * 8

  if TotalOut mod BITS > 0 then
    TotalOut:= TotalOut div BITS +1
  else
    TotalOut:= TotalOut div BITS;

  // Get memory for it

  GetMem(pBuffIn,BUFF);
  GetMem(pBuffOut,TotalOut);

  Count:=0;

  repeat
    Res := sIn.Read(pBuffIn^, BUFF);

    pIn  := pBuffIn;
    pOut := pBuffOut;

    LOut:=SZEncodeBaseXMemoryUpdate(pIn,pOut, Res, Codes, BITS, vB8, vI8);
    sOut.Write(pBuffOut^,LOut);

    Count := Count + LOut;

  until (Res <> LongInt(BUFF));

  FreeMem(pBuffIn);
  FreeMem(pBuffOut);

  result:=Count;
end;

function SZEncodeBaseXStreamFinalyze(sOUT: TStream; const Codes: String; BITS: integer; var B8, I8: integer): integer;
var
  pOut: pByte;
  b: byte;
begin
  pOut:=@b;

  Result:=SZEncodeBaseXMemoryFinalyze(pOUT, Codes, BITS,B8,I8);

  if Result>0 then
    sOut.Write(b,Result);
end;

function SZEncodeBaseXStream(sIN, sOUT: TStream; Size: integer; const Codes: String; BITS: integer; FullQuantum : integer = 0): integer;
var
  B8,I8: integer;

  TotalIn  : integer;
  TotalOut : integer;
  IM       : integer;

begin

  if size=0 then
  begin
    result:=0;
    exit
  end;

  // This is important code if you encode just part of a stream
  if size<0 then
    TotalIn:= sIn.Size-sIn.Position
  else
    TotalIn:= Size;

  B8:=0;
  I8:=0;

  TotalOut:=SZEncodeBaseXStreamUpdate(sIN, sOUT, TotalIn, Codes, BITS, B8, I8);
  // If something left
  if I8>0 then
    TotalOut:=TotalOut+SZEncodeBaseXStreamFinalyze(sOUT, Codes, BITS, B8, I8);

  if FullQuantum>0 then
  begin

    // Calculate relevant data
    //GetRelevantData(TotalIn, TotalOut, BITS, FullQuantum, IM);

    // Get required padding keys
    IM:=SZCalcRequiredPaddingKeys(TotalOut, FullQuantum);

    if IM>0 then
    begin
      sOut.Write(pchar(StringOfChar('=',IM))^,IM);
      TotalOut:=TotalOut+IM
    end

  end;

  result:=TotalOut;
end;

function SZDecodeBaseXStream(sIN, sOUT: TStream;  const Codes: String; BITS: integer): integer;
var

  TotalIn  : integer;
  TotalOut : integer;

  pIn,pOut: pByte;

  pBuffIn, pBuffOut: pByte;
  Res,BUFF : Integer;
  LOut,Count: integer;

  B8, I8: integer;

begin

  BUFF := SZBUFFSIZE;

  // This is important code if you encode just a part of a stream
  TotalIn := sIn.Size - SIn.Position;

  if BUFF > TotalIn  then
    BUFF:=TotalIn+1;

  TotalOut := BUFF;

  // Get memory for it

  GetMem(pBuffIn,BUFF);
  GetMem(pBuffOut,TotalOut);

  Count:=0;

  B8:=0;
  I8:=0;

  SZUpdateFastDecodeTable(Codes);

  repeat
    Res := sIn.Read(pBuffIn^, BUFF);

    pIn  := pBuffIn;
    pOut := pBuffOut;

    Lout:=SZDecodeBaseXMemoryUpdate(pIN, pOUT, Res, SZFastDecodeTable, BITS, B8, I8);

    sOut.Write(pBuffOut^,LOut);

    Count := Count + LOut;

  until (Res <> LongInt(BUFF));

  FreeMem(pBuffIn);
  FreeMem(pBuffOut);

  result:=Count;

end;

function SZEncodeBaseXFile(const FileName: String; sOUT: TStream; const Codes: string; BITS: integer; FullQuantum : integer = 0): integer;
var
  sIn: TFileStream;
  Size: integer;
begin
  sIn := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);

  Size:= sIn.Size;

  try
    result:= SZEncodeBaseXStream(sIN, sOUT, Size, Codes, BITS, FullQuantum);
  finally
    sIn.Free;
  end;

end;


///////////////////////////////////////////////////
// File to stream
///////////////////////////////////////////////////

function SZFullEncodeBase64(const FileName: String; sOUT: TStream): integer; overload;
begin
  result:=SZEncodeBaseXFile(FileName, sOUT, SZCodes64, SZBITS64, SZFullQuantum64);
end;

function SZFullEncodeBase64URL(const FileName: String; sOUT: TStream): integer; overload;
begin
  result:=SZEncodeBaseXFile(FileName, sOUT, SZCodes64URL, SZBITS64, SZFullQuantum64);
end;

function SZEncodeBase64(const FileName: String; sOUT: TStream): integer; overload;
begin
  result:=SZEncodeBaseXFile(FileName, sOUT, SZCodes64, SZBITS64);
end;

function SZEncodeBase64URL(const FileName: String; sOUT: TStream): integer; overload;
begin
  result:=SZEncodeBaseXFile(FileName, sOUT, SZCodes64URL, SZBITS64);
end;

function SZFullEncodeBase32(const FileName: String; sOUT: TStream): integer; overload;
begin
  result:=SZEncodeBaseXFile(FileName, sOUT, SZCodes32, SZBITS32, SZFullQuantum32);
end;

function SZEncodeBase32(const FileName: String; sOUT: TStream): integer; overload;
begin
  result:=SZEncodeBaseXFile(FileName, sOUT, SZCodes32, SZBITS32);
end;

function SZEncodeBase16(const FileName: String; sOUT: TStream): integer; overload;
begin
  result:=SZEncodeBaseXFile(FileName, sOUT, SZCodes16, SZBITS16);
end;

////////////////////////////////////////////////////////////
///    Base16
////////////////////////////////////////////////////////////

function SZFullEncodeBase16(const S: string): string;  overload;
begin
  Result:=SZEncodeBaseXString(S, SZCodes16, SZBITS16)
end;

function SZEncodeBase16(pIN, pOUT: PByte; Size: integer): integer; overload;
begin
  result:= SZEncodeBaseXMemory(pIN,pOUT, Size, SZCodes16, SZBITS16);
end;

function SZEncodeBase16(sIN, sOUT: TStream; Size: integer): integer; overload;
begin
  result:=SZEncodeBaseXStream(sIN, sOUT, Size, SZCodes16, SZBITS16);
end;

function SZEncodeBase16(const S: string): string; overload;
begin
  Result:=SZEncodeBaseXString(S, SZCodes16, SZBITS16)
end;

function SZDecodeBase16(pIN, pOUT: PByte; Size: integer): integer; overload;
begin
  result:= SZDecodeBaseXMemory(pIN,pOUT, Size, SZCodes16, SZBITS16);
end;

function SZDecodeBase16(sIN, sOUT: TStream): integer; overload;
begin
  result:= SZDecodeBaseXStream(sIN,sOUT, SZCodes16, SZBITS16);
end;

function SZDecodeBase16(const S: string): string; overload;
begin
  Result:=SZDecodeBaseXString(S, SZCodes16, SZBITS16)
end;


////////////////////////////////////////////////////////////
/// Base32
////////////////////////////////////////////////////////////

function SZFullEncodeBase32(pIN, pOUT: PByte; Size: integer): integer;  overload;
begin
  result:=SZEncodeBaseXMemory(pIN,pOUT, Size, SZCodes32, SZBITS32, SZFullQuantum32);
end;

function SZFullEncodeBase32(sIN, sOUT: TStream; Size: integer=-1): integer; overload;
begin
  result:=SZEncodeBaseXStream(sIN,sOUT, Size, SZCodes32, SZBITS32, SZFullQuantum32);
end;

function SZFullEncodeBase32(const S: string): string; overload;
begin
  Result:=SZEncodeBaseXString(S, SZCodes32, SZBITS32, SZFullQuantum32);
end;

function SZEncodeBase32(pIN, pOUT: PByte; Size: integer): integer; overload;
begin
  result:=SZEncodeBaseXMemory(pIN,pOUT, Size, SZCodes32, SZBITS32);
end;

function SZEncodeBase32(sIN, sOUT: TStream; Size: integer=-1): integer; overload;
begin
  result:=SZEncodeBaseXStream(sIN,sOUT, Size, SZCodes32, SZBITS32);
end;

function SZEncodeBase32(const S: string): string; overload;
begin
  Result:=SZEncodeBaseXString(S, SZCodes32, SZBITS32)
end;

function SZDecodeBase32(pIN, pOUT: PByte; Size: integer): integer; overload;
begin
  result:= SZDecodeBaseXMemory(pIN,pOUT, Size, SZCodes32, SZBITS32);
end;

function SZDecodeBase32(sIN, sOUT: TStream): integer; overload;
begin
  result:=SZDecodeBaseXStream(sIN,sOUT, SZCodes32, SZBITS32);
end;

function SZDecodeBase32(const S: string): string; overload;
begin
  Result:=SZDecodeBaseXString(S, SZCodes32, SZBITS32)
end;

////////////////////////////////////////////////////////////
///    Base64
////////////////////////////////////////////////////////////
function SZFullEncodeBase64(pIN, pOUT: PByte; Size: integer): integer;  overload;
begin
  result:=SZEncodeBaseXMemory(pIN,pOUT, Size, SZCodes64, SZBITS64, SZFullQuantum64);
end;

function SZFullEncodeBase64(sIN, sOUT: TStream; Size: integer=-1): integer; overload;
begin
  result:=SZEncodeBaseXStream(sIN,sOUT, Size, SZCodes64, SZBITS64, SZFullQuantum64);
end;

function SZFullEncodeBase64(const S: string): string;  overload;
begin
  Result:=SZEncodeBaseXString(S, SZCodes64, SZBITS64, SZFullQuantum64)
end;

function SZEncodeBase64(pIN, pOUT: PByte; Size: integer): integer; overload;
begin
  result:=SZEncodeBaseXMemory(pIN,pOUT, Size, SZCodes64, SZBITS64);
end;

function SZEncodeBase64(sIN, sOUT: TStream; Size: integer=-1): integer; overload;
begin
  result:=SZEncodeBaseXStream(sIN,sOUT, Size, SZCodes64, SZBITS64);
end;

function SZEncodeBase64(const S: string): string; overload;
begin
  Result:=SZEncodeBaseXString(S, SZCodes64, SZBITS64)
end;

function SZDecodeBase64(pIN, pOUT: PByte; Size: integer): integer; overload;
begin
  result:= SZDecodeBaseXMemory(pIN,pOUT, Size, SZCodes64, SZBITS64);
end;

function SZDecodeBase64(sIN, sOUT: TStream): integer; overload;
begin
  result:=SZDecodeBaseXStream(sIN,sOUT, SZCodes64, SZBITS64);
end;

function SZDecodeBase64(const S: string): string; overload;
begin
  Result:=SZDecodeBaseXString(S, SZCodes64, SZBITS64)
end;

////////////////////////////////////////////////////////////
///  Base64 URL table
////////////////////////////////////////////////////////////

function SZFullEncodeBase64URL(pIN, pOUT: PByte; Size: integer): integer; overload;
begin
  result:=SZEncodeBaseXMemory(pIN, pOUT, Size, SZCodes64URL, SZBITS64, SZFullQuantum64);
end;

function SZFullEncodeBase64URL(sIN, sOUT: TStream; Size: integer=-1): integer; overload;
begin
  result:=SZEncodeBaseXStream(sIN,sOUT, Size, SZCodes64URL, SZBITS64, SZFullQuantum64);
end;

function SZFullEncodeBase64URL(const S: string): string; overload;
begin
  Result:=SZEncodeBaseXString(S, SZCodes64URL, SZBITS64, SZFullQuantum64)
end;

function SZEncodeBase64URL(pIN, pOUT: PByte; Size: integer): integer; overload;
begin
  result:=SZEncodeBaseXMemory(pIN, pOUT, Size, SZCodes64URL, SZBITS64);
end;

function SZEncodeBase64URL(const S: string): string; overload;
begin
  Result:=SZEncodeBaseXString(S, SZCodes64URL, SZBITS64)
end;

function SZEncodeBase64URL(sIN, sOUT: TStream; Size: integer=-1): integer; overload;
begin
  result:=SZEncodeBaseXStream(sIN,sOUT, Size, SZCodes64URL, SZBITS64);
end;

function SZDecodeBase64URL(pIN, pOUT: PByte; Size: integer): integer; overload;
begin
  result:= SZDecodeBaseXMemory(pIN,pOUT, Size, SZCodes64URL, SZBITS64);
end;

function SZDecodeBase64URL(sIN, sOUT: TStream): integer; overload;
begin
  result:=SZDecodeBaseXStream(sIN,sOUT, SZCodes64URL, SZBITS64);
end;

function SZDecodeBase64URL(const S: string): string; overload;
begin
  Result:=SZDecodeBaseXString(S, SZCodes64URL, SZBITS64)
end;

//////////////////////////////////////////////////////////////


procedure SZCodeBaseXSetBufferSize(Size:integer);
begin
  // Do not allow Buffers size less than original
  // to avoid drastic performace decresing with streams

  if size > SZORIGBUFFSIZE then
    SZBUFFSIZE := Size
  else
    SZBUFFSIZE := SZORIGBUFFSIZE;
end;

procedure SZCodeBaseXSetOrigBufferSize;
begin
  SZCodeBaseXSetBufferSize(SZORIGBUFFSIZE);
end;

////////////////////
///      End     ///
////////////////////


//////////////////////////////////////////////////////////////
//Additional codes, may be deleted in the future
//////////////////////////////////////////////////////////////

//Returns 64-bit count of CPU clock cycles.
{function RDTSC: Int64;
asm
  dw $310F  // opcode for RDTSC
end;

function ROR(value: LongWord;dummy: integer; count: LongWord): LongWord;
asm
   ROR EAX, CL
end;

function ROL(value: LongWord;dummy: integer; count: LongWord): LongWord;
asm
   ROL EAX, CL
end;

function BSWAP(value: LongWord): LongWord;
asm
   BSWAP EAX
end; }

function SZFullEncodeOnlyBase64(const S: string): string;
{
 Encode algorithm for Base64
 Reference: RFC 3548 - full compatibility
}

type
  TBI3= packed array [0..2] of byte;
  pBI3= ^TBI3;

  TBO4= packed array [0..3] of byte;
  pBO4= ^TBO4;
var
  i: integer;

  pIN: pBI3;
  pOUT: pBO4;

  TotalIn, TotalOut, TotalInRest: integer;
  B32: longword;

begin

  TotalIn  := length(s);
  TotalOut := (TotalIn + 2) div 3 * 4 ;
  TotalINRest:= TotalIn - TotalIN div 3 * 3;

  SetLength(Result, TotalOut);

  pIN  := @S[1];
  pOUT := @Result[1];

  // Start coding
  for i := 1 to TotalIn Div 3 do
  begin

    // Set new DWORD value in format
    // 00000000 11111111 22222222 33333333

    B32 := (pIN[0] shl 16) or (pIN[1] shl 8) or (pIn[2]);
    inc(pIN);

    pOUT[3] := Codes64[ B32  and $3F ]; B32:=B32 shr 6;
    pOUT[2] := Codes64[ B32  and $3F ]; B32:=B32 shr 6;
    pOUT[1] := Codes64[ B32  and $3F ]; B32:=B32 shr 6;
    pOUT[0] := Codes64[ B32          ];

    inc(pOUT);

  end;

  if TotalINRest = 1 then
  begin
    B32:= (pIn[0] shl 4) ;

    pOUT[1] := Codes64[ B32 and $3F ]; B32:= B32 shr 6;
    pOUT[0] := Codes64[ B32         ];

    pOUT[3] := byte('=');
    pOUT[2] := byte('=');
  end
  else
  if TotalINRest = 2
  then
  begin
    B32:= ((pIn[0] shl 8) or pIn[1]) shl 2 ;

    pOUT[2] := Codes64[ B32 and $3F ]; B32:= B32 shr 6;
    pOUT[1] := Codes64[ B32 and $3F ]; B32:= B32 shr 6;
    pOUT[0] := Codes64[ B32         ];

    pOUT[3] := byte('=');

  end

end;


function SZFullEncodeOnlyBase64_6(const S: string): string;
{
 Encode algorithm for Base64
 Reference: RFC 3548 - full compatibility
}

type

  TBI3= packed array [0..2] of byte;
  pBI3= ^TBI3;

  TBO4= packed array [0..3] of byte;
  pBO4= ^TBO4;

var
  i: integer;

  pIN: pBI3;
  pOUT: pBO4;

  TotalIn, TotalOut, TotalINRest: integer;
  B32: longword;

begin

  TotalIn  := length(s);
  TotalOut := (TotalIn + 2) div 3 * 4 ;
  TotalINRest:= TotalIn - TotalIN div 3 * 3;

  SetLength(Result, TotalOut);

  pIN  := @S[1];
  pOUT := @Result[1];

  // This variation encode directly form input DWORD

  // Start coding
  for i := 1 to TotalIn Div 3 do
  begin

    B32:=pLongWord(pIN)^;
    inc(pIN);

    pOUT[0] := Codes64[((B32 shr  2) and $3F)];
    pOUT[1] := Codes64[((B32 shl  4) and $3F) or ((B32 shr 12) and $0F)];
    pOUT[2] := Codes64[((B32 shr  6) and $3C) or ((B32 shr 22) and $03)];
    pOUT[3] := Codes64[((B32 shr 16) and $3F)];

    inc(pOUT);

  end;

  if TotalINRest = 1 then
  begin
    B32:= (pIn[0] shl 4) ;

    pOUT[1] := Codes64[ B32 and $3F ]; B32:= B32 shr 6;
    pOUT[0] := Codes64[ B32         ];

    pOUT[3] := byte('=');
    pOUT[2] := byte('=');
  end
  else
  if TotalINRest = 2
  then
  begin
    B32:= ((pIn[0] shl 8) or pIn[1]) shl 2 ;

    pOUT[2] := Codes64[ B32 and $3F ]; B32:= B32 shr 6;
    pOUT[1] := Codes64[ B32 and $3F ]; B32:= B32 shr 6;
    pOUT[0] := Codes64[ B32         ];

    pOUT[3] := byte('=');
  end

end;


Initialization
  SZCodeBaseXSetOrigBufferSize

end.
