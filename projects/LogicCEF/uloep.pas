unit uloep;
{ Loep: een klein venster dat het stukje scherm rond de muis vergroot toont
  (1,5, 2 of 3 keer). Het venster staat altijd naast het vergrote stukje, nooit
  onder de muis: je blijft gewoon op het paneel klikken, ook tijdens de
  simulatie. Aan en uit met de knop Loep bovenaan of met F7. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, Forms, Controls, Graphics, ExtCtrls, LCLIntf, LCLType;

type

  { TLoep }

  TLoep = class(TForm)
  private
    FBmp: Graphics.TBitmap;
    FTimer: TTimer;
    FDoel: TControl;        // alleen boven dit onderdeel (het paneel) vergroten
    FZoom: Integer;         // vergroting in procent: 150, 200 of 300
    FMuis: TPoint;          // plaats van de muis in de loep (voor het kruisje)
    FZichtbaar: Boolean;
    FMidden: TPoint;        // midden van het vergrote stukje (volgt de muis niet bij elk trillinkje)
    procedure Tik(Sender: TObject);
    procedure SetZoom(AValue: Integer);
    procedure Toon(AAan: Boolean);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent; ADoel: TControl); reintroduce;
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    property Zoom: Integer read FZoom write SetZoom;
  end;

implementation

{$IFDEF WINDOWS}
uses Windows;
{$ENDIF}

// 150 -> '1,5 x', 200 -> '2 x'
function ZoomTekst(AProcent: Integer): string;
begin
  if AProcent mod 100 = 0 then
    Result := IntToStr(AProcent div 100) + ' x'
  else
    Result := IntToStr(AProcent div 100) + ',' + IntToStr(AProcent mod 100 div 10) + ' x';
end;

const
  LoepB = 270;     // grootte van het loepvenster
  LoepH = 180;
  LoepAfstand = 16;
  LoepRust = 3;    // trillingen tot zoveel pixels verschuiven het beeld niet
  LoepVer = 420;   // staat de muis verder van het venster, dan komt het dichterbij

constructor TLoep.Create(AOwner: TComponent; ADoel: TControl);
begin
  inherited CreateNew(AOwner);
  FDoel := ADoel;
  FZoom := 150;
  BorderStyle := bsNone;
  FormStyle := fsStayOnTop;
  ShowInTaskBar := stNever;
  SetBounds(0, 0, LoepB, LoepH);
  Color := clBlack;
  FBmp := Graphics.TBitmap.Create;
  FBmp.SetSize(LoepB, LoepH);
  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.Interval := 40;
  FTimer.OnTimer := @Tik;
end;

destructor TLoep.Destroy;
begin
  FTimer.Enabled := False;
  FBmp.Free;
  inherited Destroy;
end;

procedure TLoep.SetZoom(AValue: Integer);
begin
  if AValue < 150 then AValue := 150;
  if AValue > 300 then AValue := 300;
  FZoom := AValue;
end;

procedure TLoep.Start;
begin
  FTimer.Enabled := True;
  Tik(nil);
end;

procedure TLoep.Stop;
begin
  FTimer.Enabled := False;
  Toon(False);
end;

// tonen zonder het actieve venster af te pakken
procedure TLoep.Toon(AAan: Boolean);
begin
  if AAan = FZichtbaar then Exit;
  FZichtbaar := AAan;
  {$IFDEF WINDOWS}
  if AAan then
  begin
    if not HandleAllocated then HandleNeeded;
    SetWindowPos(Handle, HWND_TOPMOST, Left, Top, Width, Height,
      SWP_NOACTIVATE or SWP_SHOWWINDOW);
    Visible := True;
  end
  else
  begin
    ShowWindow(Handle, SW_HIDE);
    Visible := False;
  end;
  {$ELSE}
  Visible := AAan;
  {$ENDIF}
end;

procedure TLoep.Tik(Sender: TObject);
var
  P, DoelLB: TPoint;
  R, Werk, Hier, Stuk, Dummy: TRect;
  W, H, X, Y, NL, NT: Integer;
  DC: HDC;
  F: TCustomForm;
begin
  // alleen als Logic het actieve programma is en de muis boven het paneel staat
  F := GetParentForm(FDoel);
  if (FDoel = nil) or not FDoel.IsVisible or (F = nil) or not Application.Active then
  begin
    Toon(False);
    Exit;
  end;
  P := Mouse.CursorPos;
  DoelLB := FDoel.ClientToScreen(Types.Point(0, 0));
  R := Types.Rect(DoelLB.X, DoelLB.Y, DoelLB.X + FDoel.Width, DoelLB.Y + FDoel.Height);
  if not PtInRect(R, P) then
  begin
    Toon(False);
    Exit;
  end;

  // het stukje dat vergroot wordt: rond de muis, binnen het paneel. Kleine
  // trillingen van de hand (een paar pixels) verschuiven het beeld niet.
  if not FZichtbaar or (Abs(P.X - FMidden.X) > LoepRust) or (Abs(P.Y - FMidden.Y) > LoepRust) then
    FMidden := P;
  W := LoepB * 100 div FZoom;
  H := LoepH * 100 div FZoom;
  X := FMidden.X - W div 2;
  Y := FMidden.Y - H div 2;
  if X + W > R.Right then X := R.Right - W;
  if Y + H > R.Bottom then Y := R.Bottom - H;
  if X < R.Left then X := R.Left;
  if Y < R.Top then Y := R.Top;
  FMuis := Types.Point((P.X - X) * FZoom div 100, (P.Y - Y) * FZoom div 100);

  // de loep naast dat stukje: rechtsonder, anders links of boven. Het venster
  // blijft staan zolang het niet over het stukje schuift en niet te ver weg
  // staat: zo springt het niet bij elke beweging mee.
  Hier := Types.Rect(Left, Top, Left + LoepB, Top + LoepH);
  Stuk := Types.Rect(X - LoepAfstand div 2, Y - LoepAfstand div 2,
    X + W + LoepAfstand div 2, Y + H + LoepAfstand div 2);
  if not FZichtbaar or IntersectRect(Dummy, Hier, Stuk) or
     (Abs(P.X - (Left + LoepB div 2)) > LoepVer) or (Abs(P.Y - (Top + LoepH div 2)) > LoepVer) then
  begin
    Werk := Screen.MonitorFromPoint(P).WorkareaRect;
    NL := X + W + LoepAfstand;
    if NL + LoepB > Werk.Right then NL := X - LoepAfstand - LoepB;
    NT := Y + H + LoepAfstand;
    if NT + LoepH > Werk.Bottom then NT := Y - LoepAfstand - LoepH;
    if NL < Werk.Left then NL := Werk.Left;
    if NT < Werk.Top then NT := Werk.Top;
    SetBounds(NL, NT, LoepB, LoepH);
  end;

  // het scherm overnemen en vergroten (pixels blijven scherp)
  DC := GetDC(0);
  try
    StretchBlt(FBmp.Canvas.Handle, 0, 0, LoepB, LoepH, DC, X, Y, W, H, SRCCOPY);
  finally
    ReleaseDC(0, DC);
  end;
  Toon(True);
  Invalidate;
end;

procedure TLoep.Paint;
var
  S: string;
begin
  Canvas.Draw(0, 0, FBmp);
  // kruisje waar de muis staat
  Canvas.Pen.Color := clRed;
  Canvas.Pen.Width := 1;
  Canvas.Line(FMuis.X - 8, FMuis.Y, FMuis.X + 9, FMuis.Y);
  Canvas.Line(FMuis.X, FMuis.Y - 8, FMuis.X, FMuis.Y + 9);
  // rand en vergroting
  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Color := clNavy;
  Canvas.Pen.Width := 3;
  Canvas.Rectangle(1, 1, LoepB, LoepH);
  S := ZoomTekst(FZoom);
  Canvas.Font.Name := 'Arial';
  Canvas.Font.Size := 9;
  Canvas.Font.Style := [fsBold];
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := clNavy;
  Canvas.Font.Color := clWhite;
  Canvas.TextOut(LoepB - Canvas.TextWidth(S) - 8, 4, ' ' + S + ' ');
end;

end.
