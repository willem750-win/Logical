unit tiphtmln;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Classes, Graphics,
  Dialogs, ExtCtrls, ImgList, StdCtrls, Buttons, ColorBox, Math,
  Types, PropEdits, ObjectInspector, LResources, Controls, Forms, wcimgcbo;

type
  TBalloonTipPosition = (btpNone, btpTopLeft, btpTopRight, btpBottomLeft,
                         btpBottomRight, btpTopCenter, btpBottomCenter,
                         btpLeftCenter, btpRightCenter);
  TTextAlignment = (taLeft, taCenter, taRight);
  TIconClickEvent = procedure(Sender: TObject) of object;

  TjanTipHtml = class(TCustomControl)
  private
    FMouseX: Integer;
    FMouseY: Integer;
    IconRect: TRect;
    FIconX: Integer;
    FIconY: Integer;
    FRonding: Integer;
    FIcon: TPicture;
    FImageList: TCustomImageList;
    FImageListTXT: TImageList;
    FImageIndex: Integer;
    FDebugInfo: Boolean;
    FShowIcon: Boolean;
    FTextColor: TColor;
    FBrushColor: TColor;
    FBalloonTipColor: TColor;
    FBalloonTipPosition: TBalloonTipPosition;
    FTextAlignment: TTextAlignment;
    FStrings: TStringList;
    FWordWrap: Boolean;
    FOnIconClick: TIconClickEvent;
    FOnLinkClick: TNotifyEvent;
    FDefaultFontSize: Integer;
    FDefaultFontColor: TColor;
    FLinkRects: array of record
      Rect: TRect;
      URL: string;
    end;
    procedure SetStrings(const Value: TStringList);
    function GetStrings: TStringList;
    procedure SetFIconX(Value: Integer);
    procedure SetFIconY(Value: Integer);
    procedure SetIcon(Value: TPicture);
    procedure SetImageList(Value: TCustomImageList);
    procedure SetImageListTXT(Value: TImageList);
    procedure SetImageIndex(Value: Integer);
    procedure SetShowIcon(Value: Boolean);
    procedure SetWordWrap(Value: Boolean);
    procedure SetDebugInfo(Value: Boolean);
    procedure SetTextAlignment(Value: TTextAlignment);
    procedure SetBrushColor(Value: TColor);
    procedure SetBalloonTipPosition(Value: TBalloonTipPosition);
    procedure AdjustSize;
    procedure SetRonding(Value: Integer);

    function StripHTMLTags(const AText: string): string;
    procedure ParseAndDrawHTML(ACanvas: TCanvas; const ARect: TRect);
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure UpdateIconRect(AX, AY, AWidth, AHeight: Integer);
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure Click; override;
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure LoadFromFile(const AFileName: string);
    procedure SaveToFile(const AFileName: string);
  published
    property Align;
    property Icon: TPicture read FIcon write SetIcon;
    property ImageList: TCustomImageList read FImageList write SetImageList;
    property ImageIndex: Integer read FImageIndex write SetImageIndex;
    property ImageListText: TImageList read FImageListTXT write SetImageListTXT;
    property ShowIcon: Boolean read FShowIcon write SetShowIcon;
    property TextColor: TColor read FTextColor write FTextColor;
    property BrushColor: TColor read FBrushColor write SetBrushColor;
    property BalloonTipColor: TColor read FBalloonTipColor write FBalloonTipColor;
    property BalloonTipPosition: TBalloonTipPosition read FBalloonTipPosition write SetBalloonTipPosition;
    property TextAlignment: TTextAlignment read FTextAlignment write SetTextAlignment;
    property Strings: TStringList read GetStrings write SetStrings;
    property CornersRadius: Integer read FRonding write SetRonding default 20;
    property OnIconClick: TIconClickEvent read FOnIconClick write FOnIconClick;
    property OnLinkClick: TNotifyEvent read FOnLinkClick write FOnLinkClick;
    property IconLeft: Integer read FIconX write SetFIconX default 20;
    property IconTop: Integer read FIconY write SetFIconY default 20;
    property DefaultFontSize: Integer read FDefaultFontSize write FDefaultFontSize default 10;
    property DefaultFontColor: TColor read FDefaultFontColor write FDefaultFontColor;
    property WordWrap: Boolean read FWordWrap write SetWordWrap default False;
    property DebugInfo: Boolean read FDebugInfo write SetDebugInfo default False;
  end;

  { Property Editor }
  TjanTipHtmlStringsProperty = class(TClassPropertyEditor)
  private
    FEditor: TMemo;
    FForm: TForm;
    procedure ApplyFormatting(const Tag: string);
    procedure ChangeColor;
    procedure OnBoldClick(Sender: TObject);
    procedure OnItalicClick(Sender: TObject);
    procedure OnUnderlineClick(Sender: TObject);
    procedure OnColorClick(Sender: TObject);
    procedure OnOKClick(Sender: TObject);
    procedure OnCancelClick(Sender: TObject);
    procedure OnPicOnChange(Sender: TObject);
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
  end;

procedure Register;

implementation

{ TjanTipHtml }

constructor TjanTipHtml.Create(AOwner: TComponent);
var
  DefaultBitmap: TBitmap;
begin
  inherited Create(AOwner);
  FIcon := TPicture.Create;
  FStrings := TStringList.Create;
  FTextColor := clBlack;
  FBrushColor := clWhite;
  FBalloonTipColor := clYellow;
  FBalloonTipPosition := btpNone;
  FTextAlignment := taCenter;
  Width := 200;
  Height := 100;
  FRonding := 20;
  FIconY := 15;
  FIconX := 15;
  FDefaultFontSize := 10;
  FWordWrap := False;

  FImageList := TImageList.Create(Self);
  FImageList.Width := 16;
  FImageList.Height := 16;

  DefaultBitmap := TBitmap.Create;
  try
    DefaultBitmap.Width := FImageList.Width;
    DefaultBitmap.Height := FImageList.Height;
    DefaultBitmap.Canvas.Brush.Color := clRed;
    DefaultBitmap.Canvas.FillRect(Types.Rect(0, 0, DefaultBitmap.Width, DefaultBitmap.Height));
    FImageList.Add(DefaultBitmap, nil);
    FImageIndex := 0;
  finally
    DefaultBitmap.Free;
  end;
  ShowIcon := True;
end;

destructor TjanTipHtml.Destroy;
begin
  FIcon.Free;
  FStrings.Free;
  inherited Destroy;
end;

procedure TjanTipHtml.SetWordWrap(Value: Boolean);
begin
  if FWordWrap <> Value then
  begin
    FWordWrap := Value;
    Invalidate;
  end;
end;

procedure TjanTipHtml.SetDebugInfo(Value: Boolean);
begin
  if FDebugInfo <> Value then
  begin
    FDebugInfo := Value;
    Invalidate;
  end;
end;

procedure TjanTipHtml.UpdateIconRect(AX, AY, AWidth, AHeight: Integer);
var
  IconWidth, IconHeight: Integer;
begin
  if Assigned(FImageList) and (FImageIndex >= 0) and (FImageIndex < FImageList.Count) then
  begin
    IconWidth := FImageList.Width;
    IconHeight := FImageList.Height;
  end
  else if Assigned(FIcon.Graphic) and not FIcon.Graphic.Empty then
  begin
    IconWidth := FIcon.Width;
    IconHeight := FIcon.Height;
  end
  else
    Exit;

  IconRect := Types.Rect(FIconX, FIconY, FIconX + IconWidth, FIconY + IconHeight);
end;

procedure TjanTipHtml.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  FMouseX := X;
  FMouseY := Y;
end;

procedure TjanTipHtml.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);

  if FShowIcon and PtInRect(IconRect, Point(FMouseX, FMouseY)) then
  begin
    // ShowMessage('Icon clicked mouseUp');
    if Assigned(FOnIconClick) then
      FOnIconClick(Self);
  end;
end;

function TjanTipHtml.GetStrings: TStringList;
begin
  Result := FStrings;
end;

procedure TjanTipHtml.Resize;
begin
  inherited Resize;
  Invalidate;
end;

procedure TjanTipHtml.LoadFromFile(const AFileName: string);
begin
  FStrings.LoadFromFile(AFileName);
  Invalidate;
end;

procedure TjanTipHtml.SaveToFile(const AFileName: string);
begin
  FStrings.SaveToFile(AFileName);
end;

procedure TjanTipHtml.SetFIconX(Value: Integer);
var
  IconWidth, IconHeight: Integer;
begin
  if FIconX <> Value then
  begin
    FIconX := Value;

    if Assigned(FImageList) and (FImageIndex >= 0) and (FImageIndex < FImageList.Count) then
    begin
      IconWidth := FImageList.Width;
      IconHeight := FImageList.Height;
    end
    else if Assigned(FIcon.Graphic) and not FIcon.Graphic.Empty then
    begin
      IconWidth := FIcon.Width;
      IconHeight := FIcon.Height;
    end
    else
    begin
      IconWidth := 0;
      IconHeight := 0;
    end;

    UpdateIconRect(FIconX, FIconY, IconWidth, IconHeight);
    Invalidate;
  end;
end;

procedure TjanTipHtml.SetFIconY(Value: Integer);
var
  IconWidth, IconHeight: Integer;
begin
  if FIconY <> Value then
  begin
    FIconY := Value;

    if Assigned(FImageList) and (FImageIndex >= 0) and (FImageIndex < FImageList.Count) then
    begin
      IconWidth := FImageList.Width;
      IconHeight := FImageList.Height;
    end
    else if Assigned(FIcon.Graphic) and not FIcon.Graphic.Empty then
    begin
      IconWidth := FIcon.Width;
      IconHeight := FIcon.Height;
    end
    else
    begin
      IconWidth := 0;
      IconHeight := 0;
    end;

    UpdateIconRect(FIconX, FIconY, IconWidth, IconHeight);
    Invalidate;
  end;
end;

procedure TjanTipHtml.SetRonding(Value: Integer);
begin
  if FRonding <> Value then
  begin
    FRonding := Value;
    Invalidate;
  end;
end;

procedure TjanTipHtml.SetIcon(Value: TPicture);
begin
  FIcon.Assign(Value);
  Invalidate;
end;

procedure TjanTipHtml.SetImageList(Value: TCustomImageList);
begin
  FImageList := Value;
  Invalidate;
end;

procedure TjanTipHtml.SetImageListTXT(Value: TImageList);
begin
  FImageListTXT := Value;
  Invalidate;
end;

procedure TjanTipHtml.SetImageIndex(Value: Integer);
begin
  if FImageIndex <> Value then
  begin
    FImageIndex := Value;
    Invalidate;
  end;
end;

procedure TjanTipHtml.SetShowIcon(Value: Boolean);
var
  IconWidth, IconHeight: Integer;
begin
  if FShowIcon <> Value then
  begin
    FShowIcon := Value;

    if Assigned(FImageList) and (FImageIndex >= 0) and (FImageIndex < FImageList.Count) then
    begin
      IconWidth := FImageList.Width;
      IconHeight := FImageList.Height;
    end
    else if Assigned(FIcon.Graphic) and not FIcon.Graphic.Empty then
    begin
      IconWidth := FIcon.Width;
      IconHeight := FIcon.Height;
    end
    else
    begin
      IconWidth := 0;
      IconHeight := 0;
    end;

    UpdateIconRect(FIconX, FIconY, IconWidth, IconHeight);

    Invalidate;
    Update;
  end;
end;

procedure TjanTipHtml.SetStrings(const Value: TStringList);
begin
  FStrings.Assign(Value);
  Invalidate;
end;

procedure TjanTipHtml.SetTextAlignment(Value: TTextAlignment);
begin
  if FTextAlignment <> Value then
  begin
    FTextAlignment := Value;
    Invalidate;
  end;
end;

procedure TjanTipHtml.SetBrushColor(Value: TColor);
begin
  if FBrushColor <> Value then
  begin
    FBrushColor := Value;
    Invalidate;
  end;
end;

procedure TjanTipHtml.SetBalloonTipPosition(Value: TBalloonTipPosition);
begin
  if FBalloonTipPosition <> Value then
  begin
    FBalloonTipPosition := Value;
    Invalidate;
  end;
end;

function TjanTipHtml.StripHTMLTags(const AText: string): string;
var
  i: Integer;
  InTag: Boolean;
begin
  Result := '';
  InTag := False;
  for i := 1 to Length(AText) do
  begin
    if AText[i] = '<' then
      InTag := True
    else if AText[i] = '>' then
      InTag := False
    else if not InTag then
      Result := Result + AText[i];
  end;
end;

procedure TjanTipHtml.AdjustSize;
var
  MaxWidth, TotalHeight, LineHeight, I: Integer;
  Padding: Integer;
  PlainText: string;
begin
  Canvas.Font := Self.Font;
  LineHeight := Canvas.TextHeight('Wg');
  Padding := 15;

  MaxWidth := 0;
  TotalHeight := Padding;

  for I := 0 to FStrings.Count - 1 do
  begin
    PlainText := StripHTMLTags(FStrings[I]);
    MaxWidth := Max(MaxWidth, Canvas.TextWidth(PlainText));
    Inc(TotalHeight, LineHeight);
  end;

  Width := MaxWidth + (FIconX * 2) + Padding * 2;
  Height := TotalHeight + Padding;
end;

procedure TjanTipHtml.Loaded;
begin
  inherited Loaded;
  Invalidate;
  Update;
end;

procedure TjanTipHtml.Paint;
var
  TipPoints: array[0..2] of TPoint;
  ARect: TRect;
  BalloonRect: TRect;
  maat: String;
begin
  inherited Paint;
  ARect := ClientRect;
  Canvas.Font.Color := FTextColor;
  Canvas.Font.Size := FDefaultFontSize;

  if FBalloonTipPosition in [btpTopLeft, btpTopRight, btpTopCenter] then
    BalloonRect := Types.Rect(0, 10, Width, Height)
  else if FBalloonTipPosition in [btpBottomLeft, btpBottomRight, btpBottomCenter] then
    BalloonRect := Types.Rect(0, 0, Width, Height - 10)
  else if FBalloonTipPosition in [btpLeftCenter, btpRightCenter] then
    BalloonRect := Types.Rect(10, 0, Width - 10, Height)
  else
    BalloonRect := Types.Rect(0, 0, Width, Height);

  Canvas.Pen.Color := clBlack;
  Canvas.Brush.Color := FBrushColor;
  Canvas.RoundRect(BalloonRect.Left, BalloonRect.Top, BalloonRect.Right, BalloonRect.Bottom, FRonding, FRonding);

  if FShowIcon and Assigned(FImageList) and (FImageIndex >= 0) and (FImageIndex < FImageList.Count) then
  begin
    UpdateIconRect(FIconX, FIconY, FImageList.Width, FImageList.Height);
    FImageList.Draw(Canvas, FIconX, FIconY, FImageIndex);
  end
  else if FShowIcon and Assigned(FIcon.Graphic) and not FIcon.Graphic.Empty then
  begin
    UpdateIconRect(FIconX, FIconY, FIcon.Width, FIcon.Height);
    Canvas.Draw(FIconX, FIconY, FIcon.Graphic);
  end;

  if FDebugInfo then
  begin
    maat := Format('IconRect - X: %d, Y: %d, W: %d, H: %d',
      [IconRect.Left, IconRect.Top, IconRect.Right - IconRect.Left, IconRect.Bottom - IconRect.Top]);
    Canvas.TextOut(20, Height - 30, maat);
  end;

  if FBalloonTipPosition <> btpNone then
  begin
    case FBalloonTipPosition of
      btpTopLeft:
        begin
          TipPoints[0] := Point(10, 10);
          TipPoints[1] := Point(20, 0);
          TipPoints[2] := Point(30, 10);
        end;
      btpTopRight:
        begin
          TipPoints[0] := Point(Width - 30, 10);
          TipPoints[1] := Point(Width - 20, 0);
          TipPoints[2] := Point(Width - 10, 10);
        end;
      btpBottomLeft:
        begin
          TipPoints[0] := Point(10, Height - 10);
          TipPoints[1] := Point(20, Height);
          TipPoints[2] := Point(30, Height - 10);
        end;
      btpBottomRight:
        begin
          TipPoints[0] := Point(Width - 30, Height - 10);
          TipPoints[1] := Point(Width - 20, Height);
          TipPoints[2] := Point(Width - 10, Height - 10);
        end;
      btpTopCenter:
        begin
          TipPoints[0] := Point(Width div 2 - 10, 10);
          TipPoints[1] := Point(Width div 2, 0);
          TipPoints[2] := Point(Width div 2 + 10, 10);
        end;
      btpBottomCenter:
        begin
          TipPoints[0] := Point(Width div 2 - 10, Height - 10);
          TipPoints[1] := Point(Width div 2, Height);
          TipPoints[2] := Point(Width div 2 + 10, Height - 10);
        end;
      btpLeftCenter:
        begin
          TipPoints[0] := Point(10, Height div 2 - 10);
          TipPoints[1] := Point(0, Height div 2);
          TipPoints[2] := Point(10, Height div 2 + 10);
        end;
      btpRightCenter:
        begin
          TipPoints[0] := Point(Width - 10, Height div 2 - 10);
          TipPoints[1] := Point(Width, Height div 2);
          TipPoints[2] := Point(Width - 10, Height div 2 + 10);
        end;
    end;

    Canvas.Brush.Color := FBalloonTipColor;
    Canvas.Polygon(TipPoints);
    ParseAndDrawHTML(Canvas, BalloonRect);
  end
  else
  begin
    ParseAndDrawHTML(Canvas, ARect);
  end;
end;

procedure TjanTipHtml.ParseAndDrawHTML(ACanvas: TCanvas; const ARect: TRect);
var
  i, X, Y: Integer;
  Line, Segment, ColorHex: string;
  Bold, Italic, Underline: Boolean;
  CurrentColor: TColor;
  TextWidth, StartX: Integer;
  NextTagPos: Integer;
begin
  Y := ARect.Top + 10;
  CurrentColor := FTextColor;
  ACanvas.Brush.Style := bsClear;

  for i := 0 to FStrings.Count - 1 do
  begin
    Line := FStrings[i];
    Bold := False;
    Italic := False;
    Underline := False;

    TextWidth := ACanvas.TextWidth(StripHTMLTags(Line));

    case FTextAlignment of
      taLeft:
        StartX := ARect.Left + 5;
      taCenter:
        StartX := ARect.Left + ((ARect.Right - ARect.Left) - TextWidth) div 2;
      taRight:
        StartX := ARect.Right - TextWidth - 5;
    end;

    X := StartX;

    while Line <> '' do
    begin
      if Pos('<b>', Line) = 1 then
      begin
        Bold := True;
        Delete(Line, 1, 3);
        Continue;
      end
      else if Pos('</b>', Line) = 1 then
      begin
        Bold := False;
        Delete(Line, 1, 4);
        Continue;
      end
      else if Pos('<i>', Line) = 1 then
      begin
        Italic := True;
        Delete(Line, 1, 3);
        Continue;
      end
      else if Pos('</i>', Line) = 1 then
      begin
        Italic := False;
        Delete(Line, 1, 4);
        Continue;
      end
      else if Pos('<u>', Line) = 1 then
      begin
        Underline := True;
        Delete(Line, 1, 3);
        Continue;
      end
      else if Pos('</u>', Line) = 1 then
      begin
        Underline := False;
        Delete(Line, 1, 4);
        Continue;
      end
      else if Pos('<color=#', LowerCase(Line)) = 1 then
      begin
        ColorHex := Copy(Line, 9, 6);
        try
          CurrentColor := StringToColor('$' + ColorHex);
        except
          CurrentColor := FTextColor;
        end;
        Delete(Line, 1, 15);
        Continue;
      end
      else if Pos('</color>', LowerCase(Line)) = 1 then
      begin
        CurrentColor := FTextColor;
        Delete(Line, 1, 8);
        Continue;
      end;

      NextTagPos := Pos('<', Line);
      if NextTagPos = 0 then
      begin
        Segment := Line;
        Line := '';
      end
      else if NextTagPos = 1 then
      begin
        Segment := '';
      end
      else
      begin
        Segment := Copy(Line, 1, NextTagPos - 1);
        Delete(Line, 1, NextTagPos - 1);
      end;

      if Segment <> '' then
      begin
        ACanvas.Font.Style := [];
        if Bold then
          ACanvas.Font.Style := ACanvas.Font.Style + [fsBold];
        if Italic then
          ACanvas.Font.Style := ACanvas.Font.Style + [fsItalic];
        if Underline then
          ACanvas.Font.Style := ACanvas.Font.Style + [fsUnderline];

        ACanvas.Font.Color := CurrentColor;
        ACanvas.TextOut(X, Y, Segment);
        Inc(X, ACanvas.TextWidth(Segment));
      end;
    end;

    Inc(Y, ACanvas.TextHeight('Wg'));
    X := ARect.Left;
  end;

  ACanvas.Font.Style := [];
end;

procedure TjanTipHtml.Click;
begin
  inherited Click;
end;

{ TjanTipHtmlStringsProperty }

procedure TjanTipHtmlStringsProperty.Edit;
var
  Toolbar: TPanel;
  BtnBold, BtnItalic, BtnUnderline, BtnColor, BtnOK, BtnCancel: TButton;
  BtnWidth: Integer;
  Spatie: Integer;
  PicBox: TImageComboBox;
  I: Integer;
begin
  Spatie := 4;
  BtnWidth := 60;

  FForm := TForm.Create(nil);
  try
    FForm.Caption := 'Edit Strings';
    FForm.Width := 500;
    FForm.Height := 400;
    FForm.Position := poScreenCenter;

    Toolbar := TPanel.Create(FForm);
    Toolbar.Parent := FForm;
    Toolbar.Align := alTop;
    Toolbar.Height := 40;

    BtnBold := TButton.Create(Toolbar);
    BtnBold.Parent := Toolbar;
    BtnBold.Caption := 'Bold';
    BtnBold.Left := Spatie;
    BtnBold.Top := 5;
    BtnBold.Width := BtnWidth;
    BtnBold.OnClick := @OnBoldClick;

    BtnItalic := TButton.Create(Toolbar);
    BtnItalic.Parent := Toolbar;
    BtnItalic.Caption := 'Italic';
    BtnItalic.Left := Spatie + BtnWidth;
    BtnItalic.Top := 5;
    BtnItalic.Width := BtnWidth;
    BtnItalic.OnClick := @OnItalicClick;

    BtnUnderline := TButton.Create(Toolbar);
    BtnUnderline.Parent := Toolbar;
    BtnUnderline.Caption := 'Underline';
    BtnUnderline.Left := Spatie + BtnWidth + Spatie + BtnWidth;
    BtnUnderline.Top := 5;
    BtnUnderline.Width := BtnWidth;
    BtnUnderline.OnClick := @OnUnderlineClick;

    BtnColor := TButton.Create(Toolbar);
    BtnColor.Parent := Toolbar;
    BtnColor.Caption := 'Color';
    BtnColor.Left := Spatie + BtnWidth + Spatie + BtnWidth + Spatie + BtnWidth;
    BtnColor.Top := 5;
    BtnColor.Width := BtnWidth;
    BtnColor.OnClick := @OnColorClick;

    PicBox := TImageComboBox.Create(FForm);
    PicBox.Parent := Toolbar;
    PicBox.Left := Spatie + BtnWidth + Spatie + BtnWidth + Spatie + BtnWidth + Spatie + BtnWidth;
    PicBox.Width := 60;
    PicBox.Top := 5;

    if GetComponent(0) is TjanTipHtml then
      PicBox.Images := TjanTipHtml(GetComponent(0)).FImageListTXT;

    if Assigned(PicBox.Images) then
    begin
      for I := 0 to PicBox.Images.Count - 1 do
        PicBox.Items.Add(IntToStr(I));
    end;
    PicBox.OnChange := @OnPicOnChange;

    BtnOK := TButton.Create(FForm);
    BtnOK.Parent := Toolbar;
    BtnOK.Caption := 'OK';
    BtnOK.Left := 340;
    BtnOK.Top := 5;
    BtnOK.Width := BtnWidth;
    BtnOK.OnClick := @OnOKClick;

    BtnCancel := TButton.Create(FForm);
    BtnCancel.Parent := Toolbar;
    BtnCancel.Caption := 'Cancel';
    BtnCancel.Left := 420;
    BtnCancel.Top := 5;
    BtnCancel.Width := BtnWidth;
    BtnCancel.OnClick := @OnCancelClick;

    FEditor := TMemo.Create(FForm);
    FEditor.Parent := FForm;
    FEditor.Align := alClient;

    if GetComponent(0) is TjanTipHtml then
      FEditor.Lines.Assign(TjanTipHtml(GetComponent(0)).Strings);

    if FForm.ShowModal = mrOk then
      SetValue(FEditor.Text);
  finally
    FForm.Free;
  end;
end;

procedure TjanTipHtmlStringsProperty.OnOKClick(Sender: TObject);
const
  ColorMap: array[0..15] of record
    Name: string;
    Hex: string;
  end = (
    (Name: 'clBlack';   Hex: '#000000'),
    (Name: 'clMaroon';  Hex: '#800000'),
    (Name: 'clGreen';   Hex: '#008000'),
    (Name: 'clOlive';   Hex: '#808000'),
    (Name: 'clNavy';    Hex: '#000080'),
    (Name: 'clPurple';  Hex: '#800080'),
    (Name: 'clTeal';    Hex: '#008080'),
    (Name: 'clGray';    Hex: '#808080'),
    (Name: 'clSilver';  Hex: '#C0C0C0'),
    (Name: 'clRed';     Hex: '#FF0000'),
    (Name: 'clLime';    Hex: '#00FF00'),
    (Name: 'clYellow';  Hex: '#FFFF00'),
    (Name: 'clBlue';    Hex: '#0000FF'),
    (Name: 'clFuchsia'; Hex: '#FF00FF'),
    (Name: 'clAqua';    Hex: '#00FFFF'),
    (Name: 'clWhite';   Hex: '#FFFFFF')
  );
var
  i, j: Integer;
  Line: string;
begin
  if GetComponent(0) is TjanTipHtml then
  begin
    for i := 0 to FEditor.Lines.Count - 1 do
    begin
      Line := FEditor.Lines[i];
      for j := Low(ColorMap) to High(ColorMap) do
      begin
        Line := StringReplace(Line, Format('<font color="%s">', [ColorMap[j].Name]),
          Format('<color=%s>', [ColorMap[j].Hex]), [rfReplaceAll, rfIgnoreCase]);
        Line := StringReplace(Line, Format('</font color="%s">', [ColorMap[j].Name]),
          '</color>', [rfReplaceAll, rfIgnoreCase]);
      end;
      FEditor.Lines[i] := Line;
    end;
    TjanTipHtml(GetComponent(0)).Strings.Assign(FEditor.Lines);
    TjanTipHtml(GetComponent(0)).Invalidate;
  end;
  if FForm <> nil then
    FForm.ModalResult := mrOk;
end;

procedure TjanTipHtmlStringsProperty.OnCancelClick(Sender: TObject);
begin
  if Assigned(FForm) then
    FForm.ModalResult := mrCancel;
end;

procedure TjanTipHtmlStringsProperty.OnPicOnChange(Sender: TObject);
var
  PicBox: TImageComboBox;
begin
  if (Sender is TImageComboBox) and Assigned(FEditor) then
  begin
    PicBox := TImageComboBox(Sender);
    ShowMessage('Gekozen Item = ' + IntToStr(PicBox.ItemIndex));
    FEditor.SelText := '<IMG=' + IntToStr(PicBox.ItemIndex) + '>';
  end;
end;

procedure TjanTipHtmlStringsProperty.ApplyFormatting(const Tag: string);
var
  SelStart, SelLength: Integer;
begin
  SelStart := FEditor.SelStart;
  SelLength := FEditor.SelLength;
  if SelLength > 0 then
    FEditor.SelText := Format('<%s>%s</%s>', [Tag, FEditor.SelText, Tag])
  else
    ShowMessage('Please select text to format.');
end;

procedure TjanTipHtmlStringsProperty.ChangeColor;
var
  Form: TForm;
  ColorBox: TColorBox;
  BtnOK: TButton;
  BtnCancel: TButton;
begin
  Form := TForm.Create(nil);
  try
    Form.Caption := 'Select Color';
    Form.Width := 300;
    Form.Height := 150;
    Form.Position := poScreenCenter;

    ColorBox := TColorBox.Create(Form);
    ColorBox.Parent := Form;
    ColorBox.Style := [cbStandardColors];
    ColorBox.Left := 20;
    ColorBox.Top := 20;
    ColorBox.Width := 200;

    BtnOK := TButton.Create(Form);
    BtnOK.Parent := Form;
    BtnOK.Caption := 'OK';
    BtnOK.ModalResult := mrOk;
    BtnOK.Left := 50;
    BtnOK.Top := 80;

    BtnCancel := TButton.Create(Form);
    BtnCancel.Parent := Form;
    BtnCancel.Caption := 'Cancel';
    BtnCancel.ModalResult := mrCancel;
    BtnCancel.Left := 150;
    BtnCancel.Top := 80;

    if Form.ShowModal = mrOk then
      ApplyFormatting(Format('font color="%s"', [ColorToString(ColorBox.Selected)]));
  finally
    Form.Free;
  end;
end;

procedure TjanTipHtmlStringsProperty.OnBoldClick(Sender: TObject);
begin
  ApplyFormatting('b');
end;

procedure TjanTipHtmlStringsProperty.OnItalicClick(Sender: TObject);
begin
  ApplyFormatting('i');
end;

procedure TjanTipHtmlStringsProperty.OnUnderlineClick(Sender: TObject);
begin
  ApplyFormatting('u');
end;

procedure TjanTipHtmlStringsProperty.OnColorClick(Sender: TObject);
begin
  ChangeColor;
end;

function TjanTipHtmlStringsProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paReadOnly];
end;

procedure Register;
begin
  RegisterComponents('JWHA', [TjanTipHtml]);
  RegisterPropertyEditor(TypeInfo(TStringList), TjanTipHtml, 'Strings', TjanTipHtmlStringsProperty);
end;

end.

