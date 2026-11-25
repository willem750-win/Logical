// janSimLogic.pas, deel: knoppenbalk tekenen (ingevoegd met {$I jsl_balk.inc})

// Knop van een uitvoeronderdeel in de balk (Kind zoals bij PaintOutputSymbol;
// 3 = voltmeter)
procedure TjanSimLogicBox.DrawOutputIcon(Kind: Integer; Bm: TBitmap; X, Y: Integer);
var OldBrush, OldPen: TColor;
    OldStyle: TBrushStyle;
    Eenheid: string;
begin
  if (Kind = 11) or (Kind = 12) then
  begin
    // milliampèremeter (11) en wattmeter (12): zoals de voltmeter, met mA of W
    if Kind = 12 then Eenheid := 'W' else Eenheid := 'mA';
    OldBrush := Canvas.Brush.Color; OldStyle := Canvas.Brush.Style; OldPen := Canvas.Pen.Color;
    Canvas.Pen.Width := 1;
    if FSymbolen = Afbeelding then
    begin
      // zoals de voltmeter, met mA of W in plaats van V
      DrawMeterIcon(Canvas, Bm, X, Y, Eenheid);
    end
    else
    begin
      // schemasymbool: cirkel met mA of W
      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := SymKnopKleur;
      Canvas.FillRect(Rect(X, Y - 1, X + 24, Y + 23));
      SymPen(Canvas, clBlack);
      Canvas.Line(X + 1, Y + 11, X + 3, Y + 11);
      Canvas.Line(X + 20, Y + 11, X + 22, Y + 11);
      Canvas.Brush.Color := clWhite;
      Canvas.Ellipse(X + 2, Y + 1, X + 22, Y + 21);
      Canvas.Brush.Style := bsClear;
      Canvas.Font.Name := 'Arial'; Canvas.Font.Size := 7;
      Canvas.Font.Style := [fsBold]; Canvas.Font.Color := clBlack;
      Canvas.TextOut(X + 12 - Canvas.TextWidth(Eenheid) div 2,
                     Y + 11 - Canvas.TextHeight(Eenheid) div 2, Eenheid);
    end;
    Canvas.Brush.Color := OldBrush; Canvas.Brush.Style := OldStyle; Canvas.Pen.Color := OldPen;
    Exit;
  end;
  if Kind = 10 then
  begin
    // slagboom: geen plaatje, altijd getekend (paal met rood-witte boom)
    OldBrush := Canvas.Brush.Color; OldStyle := Canvas.Brush.Style; OldPen := Canvas.Pen.Color;
    Canvas.Pen.Width := 1;
    Canvas.Brush.Style := bsSolid;
    Canvas.Pen.Color := clBlack;
    Canvas.Brush.Color := clGray;
    Canvas.Rectangle(X + 3, Y + 8, X + 8, Y + 22);
    Canvas.Rectangle(X + 1, Y + 20, X + 10, Y + 23);
    Canvas.Brush.Color := clWhite;
    Canvas.Rectangle(X + 7, Y + 9, X + 23, Y + 13);
    Canvas.Pen.Color := clRed;
    Canvas.Brush.Color := clRed;
    Canvas.Rectangle(X + 10, Y + 10, X + 13, Y + 12);
    Canvas.Rectangle(X + 16, Y + 10, X + 19, Y + 12);
    Canvas.Brush.Color := OldBrush; Canvas.Brush.Style := OldStyle; Canvas.Pen.Color := OldPen;
    Exit;
  end;
  if Kind = 9 then
  begin
    // verkeerslicht: geen plaatje, altijd getekend (kast met rood, oranje, groen)
    OldBrush := Canvas.Brush.Color; OldStyle := Canvas.Brush.Style; OldPen := Canvas.Pen.Color;
    Canvas.Pen.Width := 1;
    Canvas.Brush.Style := bsSolid;
    Canvas.Pen.Color := clBlack;
    Canvas.Brush.Color := $303030;
    Canvas.RoundRect(X + 7, Y + 1, X + 18, Y + 23, 4, 4);
    Canvas.Brush.Color := clRed;
    Canvas.Ellipse(X + 9, Y + 3, X + 16, Y + 10);
    Canvas.Brush.Color := $0080FF;
    Canvas.Ellipse(X + 9, Y + 9, X + 16, Y + 16);
    Canvas.Brush.Color := clLime;
    Canvas.Ellipse(X + 9, Y + 15, X + 16, Y + 22);
    Canvas.Brush.Color := OldBrush; Canvas.Brush.Style := OldStyle; Canvas.Pen.Color := OldPen;
    Exit;
  end;
  if Kind = 8 then
  begin
    // muziekdoos: geen plaatje, altijd getekend (klavier met een noot)
    OldBrush := Canvas.Brush.Color; OldStyle := Canvas.Brush.Style; OldPen := Canvas.Pen.Color;
    Canvas.Pen.Width := 1;
    Canvas.Brush.Style := bsSolid;
    Canvas.Pen.Color := clGray;
    Canvas.Brush.Color := clWhite;
    Canvas.Rectangle(X + 4, Y + 11, X + 21, Y + 21);
    Canvas.Line(X + 8, Y + 11, X + 8, Y + 21);
    Canvas.Line(X + 12, Y + 11, X + 12, Y + 21);
    Canvas.Line(X + 16, Y + 11, X + 16, Y + 21);
    Canvas.Pen.Color := clBlack;
    Canvas.Brush.Color := clBlack;
    Canvas.Rectangle(X + 7, Y + 11, X + 10, Y + 16);
    Canvas.Rectangle(X + 11, Y + 11, X + 14, Y + 16);
    // noot erboven
    Canvas.Ellipse(X + 9, Y + 5, X + 13, Y + 9);
    Canvas.Line(X + 12, Y + 7, X + 12, Y + 0);
    Canvas.Line(X + 12, Y + 0, X + 15, Y + 2);
    Canvas.Brush.Color := OldBrush; Canvas.Brush.Style := OldStyle; Canvas.Pen.Color := OldPen;
    Exit;
  end;
  if Kind = 7 then
  begin
    // wagentje: geen plaatje, altijd getekend (zijaanzicht op een weg)
    OldBrush := Canvas.Brush.Color; OldStyle := Canvas.Brush.Style; OldPen := Canvas.Pen.Color;
    Canvas.Pen.Width := 1;
    Canvas.Brush.Style := bsSolid;
    Canvas.Pen.Color := $00000080;
    Canvas.Brush.Color := $002828E0;
    Canvas.Rectangle(X + 8, Y + 6, X + 16, Y + 12);   // dak
    Canvas.Rectangle(X + 5, Y + 11, X + 19, Y + 17);  // carrosserie
    Canvas.Brush.Color := $00F0D8A0;
    Canvas.FillRect(Rect(X + 10, Y + 8, X + 14, Y + 11));   // raampje
    Canvas.Pen.Color := clBlack;
    Canvas.Brush.Color := $00404040;
    Canvas.Ellipse(X + 6, Y + 14, X + 11, Y + 19);    // wielen
    Canvas.Ellipse(X + 13, Y + 14, X + 18, Y + 19);
    // weg
    Canvas.Pen.Color := clGray;
    Canvas.Line(X + 5, Y + 21, X + 18, Y + 21);
    Canvas.Brush.Color := OldBrush; Canvas.Brush.Style := OldStyle; Canvas.Pen.Color := OldPen;
    Exit;
  end;
  if Kind = 6 then
  begin
    // persoon: geen plaatje, altijd getekend (poppetje dat stapt); halve
    // knop, de achtergrond tekent DrawHalfKnop
    OldBrush := Canvas.Brush.Color; OldStyle := Canvas.Brush.Style; OldPen := Canvas.Pen.Color;
    Canvas.Pen.Width := 2;
    Canvas.Pen.Color := $00404040;
    Canvas.Line(X + 11, Y + 13, X + 7, Y + 20);     // benen
    Canvas.Line(X + 11, Y + 13, X + 15, Y + 20);
    Canvas.Pen.Color := $0099CCFF;
    Canvas.Line(X + 11, Y + 8, X + 7, Y + 13);      // armen
    Canvas.Line(X + 11, Y + 8, X + 15, Y + 13);
    Canvas.Pen.Width := 1;
    Canvas.Pen.Color := clNavy;
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := $00D07020;
    Canvas.Rectangle(X + 8, Y + 7, X + 15, Y + 14);  // shirt
    Canvas.Brush.Color := $0099CCFF;
    Canvas.Ellipse(X + 8, Y, X + 15, Y + 7);         // hoofd
    // vloer
    Canvas.Pen.Color := clGray;
    Canvas.Line(X + 5, Y + 21, X + 18, Y + 21);
    Canvas.Brush.Color := OldBrush; Canvas.Brush.Style := OldStyle; Canvas.Pen.Color := OldPen;
    Exit;
  end;
  if Kind = 5 then
  begin
    // motor: geen plaatje, altijd getekend
    OldBrush := Canvas.Brush.Color; OldStyle := Canvas.Brush.Style; OldPen := Canvas.Pen.Color;
    if FSymbolen <> Afbeelding then
    begin
      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := SymKnopKleur;
      Canvas.FillRect(Rect(X, Y - 1, X + 24, Y + 23));
    end;
    DrawMotorSymbol(Canvas, X + 12, Y + 11, 9, 30, 0, False, FSymbolen);
    Canvas.Brush.Color := OldBrush; Canvas.Brush.Style := OldStyle; Canvas.Pen.Color := OldPen;
    Exit;
  end;
  if Kind = 4 then
  begin
    // schakelrelais: geen plaatje, altijd getekend (contact boven, spoel onder)
    OldBrush := Canvas.Brush.Color; OldStyle := Canvas.Brush.Style; OldPen := Canvas.Pen.Color;
    if FSymbolen <> Afbeelding then
    begin
      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := SymKnopKleur;
      Canvas.FillRect(Rect(X, Y - 1, X + 24, Y + 23));
    end;
    SymPen(Canvas, clBlack);
    Canvas.Line(X + 1, Y + 4, X + 6, Y + 4);          // contact: R1
    Canvas.Line(X + 6, Y + 4, X + 15, Y);             // mes
    Canvas.Line(X + 16, Y + 4, X + 16, Y + 1);        // vast contact
    Canvas.Line(X + 16, Y + 4, X + 23, Y + 4);        // R2
    Canvas.Pixels[X + 11, Y + 5] := clBlack;          // stippellijn
    Canvas.Pixels[X + 11, Y + 7] := clBlack;
    Canvas.Brush.Style := bsSolid;
    if FSymbolen = Afbeelding then Canvas.Brush.Color := RGBToColor(184, 115, 51)
    else Canvas.Brush.Color := clWhite;
    Canvas.Rectangle(X + 7, Y + 9, X + 16, Y + 19);   // spoel
    if FSymbolen = Afbeelding then
    begin
      Canvas.Pen.Color := RGBToColor(120, 70, 30);
      Canvas.Line(X + 8, Y + 12, X + 15, Y + 12);
      Canvas.Line(X + 8, Y + 15, X + 15, Y + 15);
      Canvas.Pen.Color := clBlack;
    end;
    Canvas.Line(X + 11, Y + 19, X + 11, Y + 23);      // R+
    Canvas.Line(X + 16, Y + 14, X + 22, Y + 14);      // R-
    Canvas.Brush.Color := OldBrush; Canvas.Brush.Style := OldStyle; Canvas.Pen.Color := OldPen;
    Exit;
  end;
  if FSymbolen = Afbeelding then
  begin
    if Kind = 3 then
    begin
      OldBrush := Canvas.Brush.Color; OldStyle := Canvas.Brush.Style; OldPen := Canvas.Pen.Color;
      DrawMeterIcon(Canvas, Bm, X, Y, 'V');
      Canvas.Brush.Color := OldBrush; Canvas.Brush.Style := OldStyle; Canvas.Pen.Color := OldPen;
      Exit;
    end;
    Canvas.Draw(X, Y, Bm);
    if Kind in [0, 1, 2] then
    begin
      // de knop van het plaatje houden, binnenin de nieuwe tekening
      OldBrush := Canvas.Brush.Color; OldStyle := Canvas.Brush.Style; OldPen := Canvas.Pen.Color;
      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := Bm.Canvas.Pixels[2, 2];
      Canvas.FillRect(Rect(X + 1, Y + 1, X + Bm.Width - 1, Y + Bm.Height - 1));
      DrawPictureIcon(Canvas, Kind, X, Y);
      Canvas.Brush.Color := OldBrush; Canvas.Brush.Style := OldStyle; Canvas.Pen.Color := OldPen;
    end;
    Exit;
  end;
  OldBrush := Canvas.Brush.Color; OldStyle := Canvas.Brush.Style; OldPen := Canvas.Pen.Color;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := SymKnopKleur;
  Canvas.FillRect(Rect(X, Y - 1, X + 24, Y + 23));
  case Kind of
    0: DrawLampSymbol(Canvas, X + 1, X + 21, Y + 11, 14, False, FSymbolen);
    1: begin
         SymPen(Canvas, clBlack);
         Canvas.Line(X + 1, Y + 11, X + 3, Y + 11);
         DrawRelaySymbol(Canvas, X + 3, X + 9, Y + 11, 12, X + 18, Y + 1, Y + 21, False);
       end;
    2: DrawBuzzerSymbol(Canvas, X + 1, X + 21, Y + 8, 8, False);
    3: begin
         // voltmeter: cirkel met V
         SymPen(Canvas, clBlack);
         Canvas.Line(X + 1, Y + 11, X + 4, Y + 11);
         Canvas.Line(X + 19, Y + 11, X + 22, Y + 11);
         Canvas.Brush.Color := clWhite;
         Canvas.Ellipse(X + 3, Y + 2, X + 21, Y + 20);
         Canvas.Brush.Style := bsClear;
         Canvas.Font.Name := 'Arial'; Canvas.Font.Size := 9;
         Canvas.Font.Style := [fsBold]; Canvas.Font.Color := clBlack;
         Canvas.TextOut(X + 12 - Canvas.TextWidth('V') div 2,
                        Y + 11 - Canvas.TextHeight('V') div 2, 'V');
       end;
  end;
  Canvas.Brush.Color := OldBrush; Canvas.Brush.Style := OldStyle; Canvas.Pen.Color := OldPen;
end;

// Knop met een vast plaatje (draad, dipschakelaar, teller, geheugen): bij
// schemasymbolen dezelfde lichte achtergrond als de symboolknoppen; het plaatje
// komt er transparant op (de achtergrondkleur is die van pixel 0,0).
procedure TjanSimLogicBox.DrawPlainIcon(Bm: TBitmap; BL, BT, X, Y: Integer);
var OldBrush: TColor;
    OldStyle: TBrushStyle;
    OldTr: Boolean;
    OldTrColor: TColor;
begin
  if FSymbolen = Afbeelding then
  begin
    Canvas.Draw(X, Y, Bm);
    if Bm = bmDipSwitsh then
    begin
      // twee schakelaartjes zoals op het paneel
      OldBrush := Canvas.Brush.Color; OldStyle := Canvas.Brush.Style;
      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := Bm.Canvas.Pixels[2, 2];
      Canvas.FillRect(Rect(X + 1, Y + 1, X + Bm.Width - 1, Y + Bm.Height - 1));
      DrawDipPicture(Canvas, Rect(X + 3, Y + 2, X + 12, Y + 22), True);
      DrawDipPicture(Canvas, Rect(X + 12, Y + 2, X + 21, Y + 22), False);
      Canvas.Brush.Color := OldBrush; Canvas.Brush.Style := OldStyle;
    end;
    Exit;
  end;
  OldBrush := Canvas.Brush.Color; OldStyle := Canvas.Brush.Style;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := SymKnopKleur;
  Canvas.FillRect(Rect(BL + 1, BT + 1, BL + 25, BT + 25));
  Canvas.Brush.Color := OldBrush; Canvas.Brush.Style := OldStyle;
  OldTr := Bm.Transparent; OldTrColor := Bm.TransparentColor;
  Bm.TransparentColor := Bm.Canvas.Pixels[0, 0];
  Bm.Transparent := True;
  Canvas.Draw(X, Y, Bm);
  Bm.Transparent := OldTr;
  Bm.TransparentColor := OldTrColor;
end;

// Knop van een poort in de balk: het vaste plaatje bij Afbeelding, anders het
// symbool in de gekozen stijl met korte aansluitdraden.
procedure TjanSimLogicBox.DrawGateIcon(AFunc: TjanLogicFunc; Bm: TBitmap; X, Y: Integer);
var R: TRect;
    S: string;
    M, Y1, Y2: Integer;
    OldPen, OldBrush: TColor;
    OldStyle: TBrushStyle;
begin
  if FSymbolen = Afbeelding then
  begin
    Canvas.Draw(X, Y, Bm);
    // binnen de knop van het plaatje: afgerond blok met het woord, zoals de
    // poort op het paneel
    OldBrush := Canvas.Brush.Color; OldStyle := Canvas.Brush.Style; OldPen := Canvas.Pen.Color;
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := Bm.Canvas.Pixels[2, 2];
    Canvas.FillRect(Rect(X + 1, Y + 1, X + Bm.Width - 1, Y + Bm.Height - 1));
    SymPen(Canvas, clBlack);
    if AFunc = jlfNOT then
      Canvas.Line(X + 1, Y + 11, X + 5, Y + 11)
    else
    begin
      Canvas.Line(X + 1, Y + 7, X + 5, Y + 7);
      Canvas.Line(X + 1, Y + 15, X + 5, Y + 15);
    end;
    Canvas.Line(X + 19, Y + 11, X + 23, Y + 11);
    Canvas.Brush.Color := RGBToColor(255, 250, 205);
    Canvas.Pen.Color := RGBToColor(89, 96, 106);
    Canvas.RoundRect(X + 4, Y + 3, X + 20, Y + 20, 5, 5);
    S := LogicFuncWoord(AFunc, StatTaalToBTaal(FBoxTaal));
    Canvas.Brush.Style := bsClear;
    Canvas.Font.Name := 'Arial'; Canvas.Font.Size := 6;
    Canvas.Font.Style := [fsBold]; Canvas.Font.Color := clNavy;
    // lange woorden (NIET, NICHT, ODER, AND, NAND, EX-OF) kleiner, zodat ze
    // in het blokje passen
    if Canvas.TextWidth(S) > 14 then Canvas.Font.Size := 5;
    if Canvas.TextWidth(S) > 14 then Canvas.Font.Style := [];
    M := Pos('-', S);
    if (Canvas.TextWidth(S) > 15) and (M > 0) then
    begin
      // EX-OF, NON-ET, NON-OU, OU-X: op twee regels
      Canvas.Font.Style := [fsBold];
      Y1 := Canvas.TextHeight(S) - 2;
      Canvas.TextOut(X + 12 - Canvas.TextWidth(Copy(S, 1, M - 1)) div 2,
                     Y + 11 - Y1, Copy(S, 1, M - 1));
      Canvas.TextOut(X + 12 - Canvas.TextWidth(Copy(S, M + 1, MaxInt)) div 2,
                     Y + 11, Copy(S, M + 1, MaxInt));
    end
    else
      Canvas.TextOut(X + 12 - Canvas.TextWidth(S) div 2,
                     Y + 11 - Canvas.TextHeight(S) div 2, S);
    Canvas.Brush.Color := OldBrush; Canvas.Brush.Style := OldStyle; Canvas.Pen.Color := OldPen;
    Exit;
  end;
  OldBrush := Canvas.Brush.Color; OldStyle := Canvas.Brush.Style;
  // lichte achtergrond: de zwarte symbolen zijn zo beter zichtbaar
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := SymKnopKleur;
  Canvas.FillRect(Rect(X, Y - 1, X + 24, Y + 23));
  Canvas.Brush.Color := OldBrush; Canvas.Brush.Style := OldStyle;
  R := Rect(X + 5, Y + 2, X + Bm.Width - 4, Y + Bm.Height - 2);
  M := (R.Top + R.Bottom) div 2;
  if AFunc = jlfNOT then
  begin
    Y1 := M; Y2 := -1;
  end
  else
  begin
    Y1 := R.Top + (R.Bottom - R.Top) div 4;
    Y2 := R.Bottom - 1 - (R.Bottom - R.Top) div 4;
  end;
  OldPen := Canvas.Pen.Color;
  Canvas.Pen.Color := clBlack;
  Canvas.Line(X + 1, Y1, R.Left, Y1);
  if Y2 >= 0 then Canvas.Line(X + 1, Y2, R.Left, Y2);
  Canvas.Line(R.Right - 1, M, X + Bm.Width - 1, M);
  Canvas.Pen.Color := OldPen;
  DrawGateSymbol(Canvas, R, AFunc, FSymbolen, rgb(250,250,150), Y1, Y2);
end;

procedure TjanSimLogicBox.SetPersoon(const Value: Boolean);
begin
  if Value <> FPersoon then
    FPersoon := Value;
  Invalidate;
end;

procedure TjanSimLogicBox.SetWagen(const Value: Boolean);
begin
  if Value <> FWagen then
    FWagen := Value;
  Invalidate;
end;

procedure TjanSimLogicBox.SetMuziek(const Value: Boolean);
begin
  if Value <> FMuziek then
    FMuziek := Value;
  Invalidate;
end;

procedure TjanSimLogicBox.SetVerkeer(const Value: Boolean);
begin
  if Value <> FVerkeer then
    FVerkeer := Value;
  Invalidate;
end;

procedure TjanSimLogicBox.SetSlagboom(const Value: Boolean);
begin
  if Value <> FSlagboom then
    FSlagboom := Value;
  Invalidate;
end;

procedure TjanSimLogicBox.SetMeter(const Value: Boolean);
begin
  if value<>FMeter then
  begin
    FMeter := Value;
  if Value=true then FOutputAantal:= FOutputAantal+1 else FOutputAantal:= FOutputAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetDipSwitsh(const Value: Boolean);
begin
  if value<>FDipSwitsh then
  begin
    FDipSwitsh := Value;
    if Value=true then FImputAantal:= FImputAantal+1 else FImputAantal:= FImputAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetLogicAnd(const Value: Boolean);
begin
  if value<>FLogicAnd then
  begin
    FLogicAnd := Value;
  if Value=true then FVerwerkingAantal:= FVerwerkingAantal+1 else FVerwerkingAantal:= FVerwerkingAantal-1;
  end;
  invalidate;
end;
procedure TjanSimLogicBox.SetLogicNot(const Value: Boolean);
begin
  if value<>FLogicNot then
  begin
    FLogicNot := Value;
  if Value=true then FVerwerkingAantal:= FVerwerkingAantal+1 else FVerwerkingAantal:= FVerwerkingAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetLogicOr(const Value: Boolean);
begin
  if value<>FLogicOr then
  begin
    FLogicOr := Value;
  if Value=true then FVerwerkingAantal:= FVerwerkingAantal+1 else FVerwerkingAantal:= FVerwerkingAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetLogicNand(const Value: Boolean);
begin
  if Value <> FLogicNand then begin FLogicNand := Value; Invalidate; end;
end;

procedure TjanSimLogicBox.SetLogicNor(const Value: Boolean);
begin
  if Value <> FLogicNor then begin FLogicNor := Value; Invalidate; end;
end;

procedure TjanSimLogicBox.SetLogicXor(const Value: Boolean);
begin
  if Value <> FLogicXor then begin FLogicXor := Value; Invalidate; end;
end;

procedure TjanSimLogicBox.SetTeller(const Value: Boolean);
begin
  if value<>FTeller then
  begin
    FTeller := Value;
  if Value=true then FVerwerkingAantal:= FVerwerkingAantal+1 else FVerwerkingAantal:= FVerwerkingAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetFlipFlopK(const Value: Boolean);
begin
  if Value <> FFlipFlopK then begin FFlipFlopK := Value; Invalidate; end;
end;

procedure TjanSimLogicBox.SetStappen(const Value: Boolean);
begin
  if value<>FStappen then
  begin
    FStappen := Value;
    if Value=true then FVerwerkingAantal:= FVerwerkingAantal+1 else FVerwerkingAantal:= FVerwerkingAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetStopwatch(const Value: Boolean);
begin
  if value<>FStopwatch then
  begin
    FStopwatch := Value;
    if Value=true then FVerwerkingAantal:= FVerwerkingAantal+1 else FVerwerkingAantal:= FVerwerkingAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetMemory(const Value: Boolean);
begin
  if value<>FMemory then
  begin
    FMemory := Value;
    if Value=true then FVerwerkingAantal:= FVerwerkingAantal+1 else FVerwerkingAantal:= FVerwerkingAantal-1;
  end;
  invalidate;
end;

// Een onderdeel dat in de balk gekozen is, hangt onzichtbaar aan de muis tot
// het op het paneel gezet wordt. Verdwijnt zijn knop intussen (ander niveau,
// instellingen), dan mag het niet als spook op het paneel achterblijven.
procedure TjanSimLogicBox.AnnuleerNieuwObject;
var
  a: Integer;
begin
  if FNew and (FParent <> nil) then
    for a := FParent.ControlCount - 1 downto 0 do
      if (FParent.Controls[a] <> Self) and (FParent.Controls[a].Tag = FObjectID) and
         not FParent.Controls[a].Visible then
      begin
        FParent.Controls[a].Free;
        Screen.Cursor := crDefault;
        Break;
      end;
  FNew := False;
  Invalidate;
end;

procedure TjanSimLogicBox.SetNewObject(const Value: Boolean);
begin
  if value<>FNew then
  begin
    FNew := Value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetRelais(const Value: Boolean);
begin
  if value<>FRelais then
  begin
    FRelais := Value;
  if Value=true then FOutputAantal:= FOutputAantal+1 else FOutputAantal:= FOutputAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetSchakelRelais(const Value: Boolean);
begin
  if value<>FSchakelRelais then
  begin
    FSchakelRelais := Value;
    if Value then FOutputAantal:= FOutputAantal+1 else FOutputAantal:= FOutputAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetSensor(const Value: Boolean);
begin
  if value<>FSensor then
  begin
    FSensor := Value;
    if Value=true then FImputAantal:= FImputAantal+1 else FImputAantal:= FImputAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetWarm(const Value: Boolean);
begin
  if value<>FWarm then
  begin
    FWarm := Value;
    if Value=true then FImputAantal:= FImputAantal+1 else FImputAantal:= FImputAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetSchakelaar(const Value: Boolean);
begin
  if value<>FSchakelaar then
  begin
    FSchakelaar := Value;
    if Value=true then FImputAantal:= FImputAantal+1 else FImputAantal:= FImputAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetPuls(const Value: Boolean);
begin
  if value<>FPuls then
  begin
    FPuls := Value;
    if Value=true then FImputAantal:= FImputAantal+1 else FImputAantal:= FImputAantal-1;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetParent(const Value: TWinControl);
begin
  if value<>FParent then
  begin
    FParent := Value;
  end;
  invalidate;
end;

procedure TjanSimLogicBox.SetObjectID(const Value: Integer);
begin
  if value<>FObjectID then
  begin
    FObjectID := Value;
  end;
  invalidate;
end;



procedure TjanSimLogicBox.SetOpen(const Value: Boolean);
begin
  if value <> FOpen then
  begin
    FOpen := Value;
  end;
  If FOpen=true then
    begin
    width:=45;
    //MoveObjekten(45);
    end
    else
    begin
    width:=0 ;
    //MoveObjekten(-45);
    end;
 //invalidate;
end;

procedure TjanSimLogicBox.SetStart(const Value: Boolean);
begin
  if value <> FStart then
  begin
    FStart := Value;
  end;
  If FStart=true then maakpanel ;
  invalidate;
end;

procedure TjanSimLogicBox.DoObjectMove(Obj: TControl; X, Y: Integer);
begin
  if Assigned(FOnObjectMove) then
    FOnObjectMove(Self, Obj, X, Y);
end;

procedure TjanSimLogicBox.StatusFromChild(Sender: TObject; const AText: string; APanel: Integer);
begin
  FLastStatusSender := Sender;
  DoStatusText(AText, APanel);
end;

// knop van de stappenteller: klein display met 123, altijd getekend
// knop flipflop: blok met FF, ingangen links en de uitgangen Q en niet-Q rechts
procedure TjanSimLogicBox.DrawFlipFlopIcon(X, Y: Integer);
var OldBrush, OldPen, OldFont: TColor;
    OldStyle: TBrushStyle;
    OldSize: Integer;
begin
  OldBrush := Canvas.Brush.Color; OldStyle := Canvas.Brush.Style; OldPen := Canvas.Pen.Color;
  OldFont := Canvas.Font.Color; OldSize := Canvas.Font.Size;
  Canvas.Pen.Width := 1;
  Canvas.Pen.Color := clBlack;
  Canvas.Line(X + 1, Y + 6, X + 5, Y + 6);
  Canvas.Line(X + 1, Y + 16, X + 5, Y + 16);
  Canvas.Line(X + 19, Y + 16, X + 23, Y + 16);
  Canvas.Pen.Color := clRed;                    // uitgang Q aan
  Canvas.Line(X + 19, Y + 6, X + 23, Y + 6);
  Canvas.Brush.Style := bsSolid;
  Canvas.Pen.Color := clGray;
  Canvas.Brush.Color := clCream;
  Canvas.RoundRect(X + 5, Y + 2, X + 19, Y + 21, 4, 4);
  Canvas.Brush.Style := bsClear;
  Canvas.Font.Name := 'Arial';
  Canvas.Font.Size := 6;
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Color := clNavy;
  Canvas.TextOut(X + 12 - Canvas.TextWidth('FF') div 2, Y + 11 - Canvas.TextHeight('FF') div 2, 'FF');
  Canvas.Font.Style := []; Canvas.Font.Size := OldSize; Canvas.Font.Color := OldFont;
  Canvas.Brush.Color := OldBrush; Canvas.Brush.Style := OldStyle; Canvas.Pen.Color := OldPen;
end;

procedure TjanSimLogicBox.DrawStappenIcon(X, Y: Integer);
var OldBrush, OldPen, OldFont: TColor;
    OldStyle: TBrushStyle;
    OldSize: Integer;
begin
  OldBrush := Canvas.Brush.Color; OldStyle := Canvas.Brush.Style; OldPen := Canvas.Pen.Color;
  OldFont := Canvas.Font.Color; OldSize := Canvas.Font.Size;
  Canvas.Pen.Width := 1;
  Canvas.Brush.Style := bsSolid;
  Canvas.Pen.Color := clGray;
  Canvas.Brush.Color := clCream;
  Canvas.Rectangle(X + 1, Y + 5, X + 23, Y + 17);
  Canvas.Brush.Style := bsClear;
  Canvas.Font.Name := 'Arial';
  Canvas.Font.Size := 7;
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Color := clBlue;
  Canvas.TextOut(X + 3, Y + 5, '123');
  // telingang links
  Canvas.Pen.Color := clNavy;
  Canvas.Line(X, Y + 20, X + 6, Y + 20);
  Canvas.Line(X + 6, Y + 20, X + 6, Y + 18);
  Canvas.Line(X + 6, Y + 18, X + 10, Y + 18);
  Canvas.Line(X + 10, Y + 18, X + 10, Y + 20);
  Canvas.Line(X + 10, Y + 20, X + 23, Y + 20);
  Canvas.Font.Style := []; Canvas.Font.Size := OldSize; Canvas.Font.Color := OldFont;
  Canvas.Brush.Color := OldBrush; Canvas.Brush.Style := OldStyle; Canvas.Pen.Color := OldPen;
end;

// knop stopwatch: wijzerplaat met knopje bovenaan en een wijzer
procedure TjanSimLogicBox.DrawStopwatchIcon(X, Y: Integer);
var OldBrush, OldPen: TColor;
    OldStyle: TBrushStyle;
begin
  OldBrush := Canvas.Brush.Color; OldStyle := Canvas.Brush.Style; OldPen := Canvas.Pen.Color;
  Canvas.Pen.Width := 1;
  Canvas.Brush.Style := bsSolid;
  // knopje bovenaan
  Canvas.Pen.Color := clNavy;
  Canvas.Brush.Color := clNavy;
  Canvas.Rectangle(X + 10, Y + 1, X + 14, Y + 4);
  // wijzerplaat
  Canvas.Pen.Color := clGray;
  Canvas.Brush.Color := clCream;
  Canvas.Ellipse(X + 3, Y + 3, X + 21, Y + 21);
  // wijzers en het middelpunt
  Canvas.Pen.Color := clBlue;
  Canvas.Pen.Width := 2;
  Canvas.Line(X + 12, Y + 12, X + 12, Y + 6);
  Canvas.Line(X + 12, Y + 12, X + 16, Y + 12);
  Canvas.Pen.Width := 1;
  Canvas.Brush.Color := OldBrush; Canvas.Brush.Style := OldStyle; Canvas.Pen.Color := OldPen;
end;

// halve knop in de componentenbalk (persoon, wagentje) met icoon Kind
procedure TjanSimLogicBox.DrawHalfKnop(const R: TRect; ADown: Boolean; Kind: Integer);
var
  Rb: TRect;
begin
  Rb := R;
  with Canvas do
  begin
    Brush.Style := bsSolid;
    Brush.Color := clSilver;
    if FSymbolen <> Afbeelding then Brush.Color := SymKnopKleur;
    if not ADown then
      Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
    else
      Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
    FillRect(Rb);
    Brush.Color := clSilver;
  end;
  DrawOutputIcon(Kind, nil, (R.Left + R.Right) div 2 - 12, R.Top + 2);
end;

// knop in de componentenbalk: verticale rail met + (rood) of massasymbool (blauw)
procedure TjanSimLogicBox.DrawRailButton(const R: TRect; APlus, ADown: Boolean);
var
  Rb: TRect;
  X: Integer;
  Col: TColor;
begin
  Rb := R;
  with Canvas do
  begin
    Brush.Style := bsSolid;
    Brush.Color := clSilver;
    if FSymbolen <> Afbeelding then Brush.Color := SymKnopKleur;
    if not ADown then
      Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
    else
      Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
    FillRect(Rb);
    if APlus then Col := clRed else Col := clBlue;
    Brush.Color := Col;
    X := (R.Left + R.Right) div 2 - 1;
    if APlus then
    begin
      // plusteken boven de rail
      FillRect(Rect(X, R.Top + 9, X + 2, R.Bottom - 3));
      FillRect(Rect(X - 3, R.Top + 4, X + 5, R.Top + 6));
      FillRect(Rect(X, R.Top + 1, X + 2, R.Top + 9));
    end
    else
    begin
      // rail met het massasymbool onderaan
      FillRect(Rect(X, R.Top + 3, X + 2, R.Bottom - 10));
      FillRect(Rect(X - 4, R.Bottom - 11, X + 6, R.Bottom - 9));
      FillRect(Rect(X - 2, R.Bottom - 8, X + 4, R.Bottom - 6));
      FillRect(Rect(X, R.Bottom - 5, X + 2, R.Bottom - 3));
    end;
    Brush.Color := clSilver;
  end;
end;



PROCEDURE TjanSimLogicBox.PaintBoxTop;
var
  B,H,LK,TOP,BK,HK,SPATIE: Integer;
  RC,RB: TRect;
  Bmp: TBitmap;
  Vert: Boolean;      // balk links of rechts: knoppen onder elkaar
  MaxR: Integer;      // rechterkant van de laatste kolom (Vert)

  // helper om de volgende "slot" te zetten. Boven of onder: naast elkaar;
  // past er geen knop meer naast, dan begint een nieuwe rij eronder.
  // Links of rechts: onder elkaar, met een nieuwe kolom ernaast (overloop).
  procedure NextX(Delta: Integer);
  begin
    if Vert then
    begin
      if BK > MaxR then MaxR := BK;
      TOP := TOP + Delta;
      if TOP + H > Height - 6 then
      begin
        TOP := FKnopTop;
        LK := LK + B + 4;
      end;
      HK := TOP + H;
    end
    else
    begin
      LK := LK + Delta;
      if LK + B > Width - 6 then
      begin
        LK := FKnopLeft;
        TOP := TOP + H + 4;
        HK := TOP + H;
      end;
    end;
    BK := LK + B;
  end;

  // ruimte tussen twee groepen, niet aan het begin van een rij of kolom
  procedure Gap(Delta: Integer);
  begin
    if Vert then
    begin
      if TOP > FKnopTop then NextX(Delta);
    end
    else if LK > FKnopLeft then NextX(Delta);
  end;

  // achtergrond van een groep knoppen: een rij of een kolom
  procedure GroepMaat(Bm: TBitmap; Aantal: Integer);
  begin
    if Vert then
    begin
      Bm.Width  := B + 7;
      Bm.Height := (Aantal * H) + ((Aantal-1) * Knopspatie) + 7;
    end
    else
    begin
      Bm.Width  := (Aantal * B) + ((Aantal-1) * Knopspatie) + 7;
      Bm.Height := H + 7;
    end;
  end;

  // de balk even hoog (boven/onder) of even breed (links/rechts) maken als
  // de rijen of kolommen knoppen; bij een balk boven of links schuiven de
  // objecten op het paneel mee, zodat ze op dezelfde plaats blijven
  procedure PasMaatAan(Rand: Integer);
  var Nodig, Oud, D: Integer;
  begin
    Nodig := Rand + 6;
    if Nodig < 36 then Nodig := 36;
    if Vert then
    begin
      if FRijFix or ((Nodig = FBalkBreedte) and (Width = Nodig)) then Exit;
    end
    else
      if FRijFix or ((Nodig = FBalkHoogte) and (Height = Nodig)) then Exit;
    FRijFix := True;
    try
      if Vert then
      begin
        Oud := Width;
        FBalkBreedte := Nodig;  // resize houdt deze breedte vast
        Width := Nodig;
        D := Width - Oud;       // alleen de echte verandering
        if (D <> 0) and (Align = alLeft) then ShiftPanelObjects(D, 0);
        if (D <> 0) and (FParent <> nil) then FParent.Invalidate;   // titel en linialen van het paneel
      end
      else
      begin
        Oud := Height;
        FBalkHoogte := Nodig;   // resize houdt deze hoogte vast
        Height := Nodig;
        D := Height - Oud;
        if (D <> 0) and (Align = alTop) then ShiftPanelObjects(0, D);
        if (D <> 0) and (FParent <> nil) then FParent.Invalidate;
      end;
      // deze tekenbeurt mag alleen binnen de oude maat tekenen: na afloop
      // de hele balk nog eens tekenen, anders blijft de nieuwe rij leeg
      Application.QueueAsyncCall(HertekenLater, 0);
    finally
      FRijFix := False;
    end;
  end;

begin
  if Align in [alTop, alBottom, alLeft, alRight] then
  begin
    Vert := Align in [alLeft, alRight];
    SPATIE := FSpatie;
    B := 26;                 // Breedte knop
    H := 26;                 // Hoogte knop
    LK := FKnopLeft;         // X1
    TOP := FKnopTop;         // Y1
    BK := LK + B;            // X2
    HK := TOP + H;           // Y2
    MaxR := BK;

    RC := Self.ClientRect;



    // teken een soort van TBevel
    Canvas.Brush.Style := bsClear;
    Canvas.FillRect(RC);

    // Tekenen van verhoogd effect (raised bevel)
    Canvas.Pen.Color := clWhite;
    Canvas.MoveTo(RC.Left, RC.Bottom - 1);
    Canvas.LineTo(RC.Left, RC.Top);
    Canvas.LineTo(RC.Right - 1, RC.Top);

    Canvas.Pen.Color := clGray;
    Canvas.MoveTo(RC.Right - 1, RC.Top);
    Canvas.LineTo(RC.Right - 1, RC.Bottom - 1);
    Canvas.LineTo(RC.Left, RC.Bottom - 1);

    // Optioneel: Binnenste rand voor diepte-effect
    InflateRect(RC, -2, -2);
    Canvas.Pen.Color := clSilver;
    Canvas.Rectangle(RC);

    with Canvas do
    begin
      bmp := TBitmap.Create;
      bmp.Canvas.Brush.Color := FBColor;   /// achtergrond kleur LogicBox met property BColor
      bmp.Width := Width;
      bmp.Height := Height;
      RB := ClientRect;
      bmp.Canvas.FillRect(RB);
      Frame3D(RB, clBtnHighlight, clBtnShadow, 1);
      Frame3D(RB, clBtnShadow, clBtnHighlight, 2);
      Draw(0, 0, bmp);
      bmp.Free;

      Brush.Color := clSilver;


       Brush.Color := clSilver;
      // ===========================================================
      // Connector (BESTAAND)
      // ===========================================================
      RCon := Rect(0, 0, 0, 0);   // verborgen knop: geen klik of hint op de oude plaats
      if FDraad = True then
      begin
        RCon := Rect(LK, TOP, LK + 29, TOP + 28);
        Rb := RCon;

        FHoverRect := RCon;
        FHoverText := 'Connector tool – verbindt componenten';

        DoStatusText(LangTr('Connector tool'),0);
       if not DCon then
          Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else
          Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);

        FillRect(Rb);
        DrawPlainIcon(bmCon, LK, TOP, LK+4, TOP+4);

        // was: TOP := TOP + H -15 +SPATIE+10;
        NextX(B  + SPATIE + 10);
        HK := TOP + H;
      end;

      // ===========================================================
      // GROEP: INPUT achtergrond (horizontale balk)
      // ===========================================================
      if OudeInvoerTonen and (A_Imput > 0) then
      begin
        bmp := TBitmap.Create;
        bmp.Canvas.Brush.Style := bsSolid;
        bmp.Canvas.Brush.Color := FBColor;

        // aantal knoppen * B + spacing ertussen + kleine marge
        GroepMaat(bmp, A_Imput);

        Rb := Rect(0, 0, bmp.Width, bmp.Height);
        bmp.Canvas.FillRect(Rb);

        Draw(LK-4, TOP-4, bmp);
        bmp.Free;

        Brush.Color := clSilver;
      end;

      // Begin invoer (nu horizontaal)
      if OudeInvoerTonen and (FDrukknop = True) then
      begin
        RButton := Rect(LK, TOP, BK, HK);
        Rb := RButton;

        if not DButton then
          Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else
          Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);

        FillRect(Rb);
        DrawInputIcon(0, bmButton, LK+1, TOP+2);

        // was: TOP := TOP + H + SPATIE;
        NextX(B + SPATIE);
        HK := TOP + H;
      end;

      if OudeInvoerTonen and (FSchakelaar = True) then
      begin
        RKnop := Rect(LK, TOP, BK, HK);
        Rb := RKnop;

        if not DKnop then
          Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else
          Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);

        FillRect(Rb);
        DrawInputIcon(1, bmKnop, LK+1, TOP+2);

        NextX(B + SPATIE);
        HK := TOP + H;
      end;

      if OudeInvoerTonen and (FSensor = True) then
      begin
        RSensor := Rect(LK, TOP, BK, HK);
        Rb := RSensor;

        if not DSensor then
          Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else
          Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);

        FillRect(Rb);
        DrawInputIcon(2, bmSensor, LK+1, TOP+2);

        NextX(B + SPATIE);
        HK := TOP + H;
      end;

      if OudeInvoerTonen and (FWarm = True) then
      begin
        RWarm := Rect(LK, TOP, BK, HK);
        Rb := RWarm;

        if not DWarm then
          Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else
          Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);

        FillRect(Rb);
        DrawInputIcon(3, bmWarm, LK+1, TOP+2);

        NextX(B + SPATIE);
        HK := TOP + H;
      end;

      if OudeInvoerTonen and (FPuls = True) then
      begin
        RPuls := Rect(LK, TOP, BK, HK);
        Rb := RPuls;

        if not DPuls then
          Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else
          Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);

        FillRect(Rb);
        DrawInputIcon(4, bmPuls, LK+1, TOP+2);

        NextX(B + SPATIE);
        HK := TOP + H;
      end;

      if OudeInvoerTonen and (FDipSwitsh = True) then
      begin
        RDipSwitsh := Rect(LK, TOP, BK, HK);
        Rb := RDipSwitsh;

        if not DDipSwitsh then
          Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else
          Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);

        FillRect(Rb);
        DrawPlainIcon(bmDipSwitsh, LK, TOP, LK+1, TOP+2);

        NextX(B + SPATIE);
        HK := TOP + H;
      end;

      // was: TOP := TOP + 20;
      if OudeInvoerTonen then Gap(20);

      // ===========================================================
      // GROEP: VERWERKING achtergrond (horizontale balk)
      // ===========================================================
      if A_Verwerking > 0 then
      begin
        bmp := TBitmap.Create;
        bmp.Canvas.Brush.Style := bsSolid;
        bmp.Canvas.Brush.Color := FBColor;

        GroepMaat(bmp, A_Verwerking);

        // kader rond de groep (zoals je deed met rect(LK-5,...))
        Rb := Rect(LK-5, TOP-5, LK-5 + bmp.Width + 10, TOP-5 + bmp.Height + 10);
        bmp.Canvas.FillRect(Rect(0, 0, bmp.Width, bmp.Height));
        Draw(LK-4, TOP-4, bmp);
        bmp.Free;
      end;

      Brush.Color := clSilver;

      // rechthoeken van knoppen die nu verborgen zijn wissen: anders toont
      // MouseMove hun hint boven de knop die op hun plaats gekomen is
      RLogicAnd := Rect(0, 0, 0, 0); RLogicOr := Rect(0, 0, 0, 0); RLogicNot := Rect(0, 0, 0, 0);
      RTeller := Rect(0, 0, 0, 0); RMemory := Rect(0, 0, 0, 0); RStappen := Rect(0, 0, 0, 0);
      RStopwatch := Rect(0, 0, 0, 0); RLight := Rect(0, 0, 0, 0); RMotor := Rect(0, 0, 0, 0);
      RDisplay := Rect(0, 0, 0, 0); RMeter := Rect(0, 0, 0, 0);
      if FLogicAnd = True then
      begin
        RLogicAnd := Rect(LK, TOP, BK, HK);
        Rb := RLogicAnd;
        if not DLogicAnd then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        DrawGateIcon(jlfAND, bmLogicAnd, LK+1, TOP+2);
        NextX(B + SPATIE);
      end;

      if FLogicOr = True then
      begin
        RLogicOr := Rect(LK, TOP, BK, HK);
        Rb := RLogicOr;
        if not DLogicOr then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        DrawGateIcon(jlfOR, bmLogicOr, LK+1, TOP+2);
        NextX(B + SPATIE);
      end;

      if FLogicNot = True then
      begin
        RLogicNot := Rect(LK, TOP, BK, HK);
        Rb := RLogicNot;
        if not DLogicNot then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        DrawGateIcon(jlfNOT, bmLogicNot, LK+1, TOP+2);
        NextX(B + SPATIE);
      end;

      // NEN, NOF en EX-OF
      RLogicNand := Rect(0, 0, 0, 0); RLogicNor := Rect(0, 0, 0, 0); RLogicXor := Rect(0, 0, 0, 0);
      if FLogicNand then
      begin
        RLogicNand := Rect(LK, TOP, BK, HK);
        Rb := RLogicNand;
        if not DLogicNand then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        DrawGateIcon(jlfNAND, bmLogicAnd, LK+1, TOP+2);
        NextX(B + SPATIE);
      end;
      if FLogicNor then
      begin
        RLogicNor := Rect(LK, TOP, BK, HK);
        Rb := RLogicNor;
        if not DLogicNor then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        DrawGateIcon(jlfNOR, bmLogicAnd, LK+1, TOP+2);
        NextX(B + SPATIE);
      end;
      if FLogicXor then
      begin
        RLogicXor := Rect(LK, TOP, BK, HK);
        Rb := RLogicXor;
        if not DLogicXor then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        DrawGateIcon(jlfXOR, bmLogicAnd, LK+1, TOP+2);
        NextX(B + SPATIE);
      end;

      if FTeller = True then
      begin
        RTeller := Rect(LK, TOP, BK, HK);
        Rb := RTeller;
        if not DTeller then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        DrawPlainIcon(bmTeller, LK, TOP, LK+1, TOP+2);
        NextX(B + SPATIE);
      end;

      if FMemory = True then
      begin
        RMemory := Rect(LK, TOP, BK, HK);
        Rb := RMemory;
        if not DMemory then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        DrawPlainIcon(bmMemory, LK, TOP, LK+1, TOP+2);
        NextX(B + SPATIE);
      end;


      RFlipFlop := Rect(0, 0, 0, 0);
      if FFlipFlopK then
      begin
        RFlipFlop := Rect(LK, TOP, BK, HK);
        Rb := RFlipFlop;
        if not DFlipFlop then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        DrawFlipFlopIcon(LK+1, TOP+2);
        NextX(B + SPATIE);
      end;

      if FStappen = True then
      begin
        RStappen := Rect(LK, TOP, BK, HK);
        Rb := RStappen;
        if not DStappen then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        DrawStappenIcon(LK+1, TOP+2);
        NextX(B + SPATIE);
      end;

      if FStopwatch = True then
      begin
        RStopwatch := Rect(LK, TOP, BK, HK);
        Rb := RStopwatch;
        if not DStopwatch then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        DrawStopwatchIcon(LK+1, TOP+2);
        NextX(B + SPATIE);
      end;
      Gap(20);

      // ===========================================================
      // GROEP: OUTPUT achtergrond (horizontale balk)
      // ===========================================================
      if A_Output > 0 then
      begin
        bmp := TBitmap.Create;
        bmp.Canvas.Brush.Style := bsSolid;
        bmp.Canvas.Brush.Color := FBColor;

        GroepMaat(bmp, A_Output);

        Rb := Rect(LK-3, TOP-5, LK-3 + bmp.Width + 8, TOP-5 + bmp.Height + 10);
        bmp.Canvas.FillRect(Rect(0, 0, bmp.Width, bmp.Height));
        Draw(LK-4, TOP-4, bmp);
        bmp.Free;
      end;

      Brush.Color := clSilver;

      if FLamp = True then
      begin
        RLight := Rect(LK, TOP, BK, HK);
        Rb := RLight;
        if not DLight then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        DrawOutputIcon(0, bmLight, LK+1, TOP+2);
        // de logische lamp werkt op 5 V: zo verschilt ze van de lamp met twee
        // klemmen uit de voedingskring
        Brush.Style := bsClear;
        Font.Name := 'Arial'; Font.Size := 6; Font.Style := [fsBold];
        Font.Color := clNavy;
        TextOut(BK - TextWidth('5V') - 1, HK - TextHeight('5V'), '5V');
        Brush.Style := bsSolid;
        Brush.Color := clSilver;
        NextX(B + SPATIE);
      end;

      // relais, schakelrelais en zoemer zonder klemmen staan niet meer in de
      // balk: ze zijn vervangen door de zoemer en het relais met twee klemmen
      // (bij de voeding). Oude panelen met deze onderdelen werken nog.

      if FMotor = True then
      begin
        RMotor := Rect(LK, TOP, BK, HK);
        Rb := RMotor;
        if not DMotor then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        DrawOutputIcon(5, nil, LK+1, TOP+2);
        NextX(B + SPATIE);
      end;

      if FDisplay = True then
      begin
        RDisplay := Rect(LK, TOP, BK, HK);
        Rb := RDisplay;
        if not DDisplay then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        DrawPlainIcon(bmDisplay, LK, TOP, LK+1, TOP+2);

        // was: TOP := TOP + H + 6;
        NextX(B + 6);
      end;

      Brush.Color := clSilver;

      if FMeter = True then
      begin
        RMeter := Rect(LK, TOP, BK, HK);
        Rb := RMeter;
        if not DMeter then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        DrawOutputIcon(3, bmMeter, LK+1, TOP+2);
        NextX(B + SPATIE);
      end;

      // milliampèremeter: zelfde soort knop, direct naast de voltmeter
      RAmpMeter := Rect(0, 0, 0, 0);
      if FAmpMeterK then
      begin
        RAmpMeter := Rect(LK, TOP, BK, HK);
        Rb := RAmpMeter;
        if not DAmpMeter then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        DrawOutputIcon(11, bmMeter, LK+1, TOP+2);
        NextX(B + SPATIE);
      end;

      // wattmeter: zelfde soort knop, direct naast de milliampèremeter
      RWattMeter := Rect(0, 0, 0, 0);
      if FWattMeterK then
      begin
        RWattMeter := Rect(LK, TOP, BK, HK);
        Rb := RWattMeter;
        if not DWattMeter then Frame3D(Rb, clBtnHighlight, clBtnShadow, 1)
        else Frame3D(Rb, clBtnShadow, clBtnHighlight, 1);
        FillRect(Rb);
        DrawOutputIcon(12, bmMeter, LK+1, TOP+2);
        NextX(B + SPATIE);
      end;

      // persoon, wagentje en muziekdoos: even breed als de andere knoppen
      RPersoon := Rect(0, 0, 0, 0);
      RWagen := Rect(0, 0, 0, 0);
      if FPersoon then
      begin
        RPersoon := Rect(LK, TOP, BK, HK);
        DrawHalfKnop(RPersoon, DPersoon, 6);
        NextX(B + SPATIE);
      end;
      if FWagen then
      begin
        RWagen := Rect(LK, TOP, BK, HK);
        DrawHalfKnop(RWagen, DWagen, 7);
        NextX(B + SPATIE);
      end;
      RMuziek := Rect(0, 0, 0, 0);
      if FMuziek then
      begin
        RMuziek := Rect(LK, TOP, BK, HK);
        DrawHalfKnop(RMuziek, DMuziek, 8);
        NextX(B + SPATIE);
      end;
      RVerkeer := Rect(0, 0, 0, 0);
      if FVerkeer then
      begin
        RVerkeer := Rect(LK, TOP, BK, HK);
        DrawHalfKnop(RVerkeer, DVerkeer, 9);
        NextX(B + SPATIE);
      end;
      RSlagboom := Rect(0, 0, 0, 0);
      if FSlagboom then
      begin
        RSlagboom := Rect(LK, TOP, BK, HK);
        DrawHalfKnop(RSlagboom, DSlagboom, 10);
        NextX(B + SPATIE);
      end;

      // voeding: + en - rail, bron, zekering, weerstand, lamp, schakelaar en
      // voltmeter met 2 klemmen als halve knoppen in een aparte groep
      Gap(8);
      if Vert then
      begin
        PlaatsVoeding(LK, TOP, H, SPATIE, True, Self.Height - 6, FKnopTop);
        if FVoedingRight > MaxR then MaxR := FVoedingRight;
        PasMaatAan(MaxR);
      end
      else
      begin
        PlaatsVoeding(LK, TOP, H, SPATIE, False, Self.Width - 6, FKnopLeft);
        PasMaatAan(FVoedingBottom);
      end;
    end;
  end;
end;

// willy paint box
procedure TjanSimLogicBox.Paint;
var
  R, Rb, RC: TRect;
  w, top, Lk, Rk, Bk, HK, v, SPATIE, B, H: integer;
  Bmp: TBitmap;
begin
  if visible = false then exit;
  ControlStyle := ControlStyle + [csOpaque];

  // boven, onder, links of rechts: dezelfde procedure
  if Align in [alTop, alBottom, alLeft, alRight] then PaintBoxTop;
end;

procedure TjanSimLogicBox.HertekenLater(Data: PtrInt);
begin
  Invalidate;
end;

procedure TjanSimLogicBox.resize;
begin
if FBalkHoogte < 36 then FBalkHoogte := 36;
if FBalkBreedte < 36 then FBalkBreedte := 36;
if (Align in [alTop, alBottom]) and (Height <> FBalkHoogte) then Height := FBalkHoogte;
if (Align in [alLeft, alRight]) and (Width <> FBalkBreedte) then Width := FBalkBreedte;
FFirst:=false;
// bij een kleiner venster tekent Windows de balk niet vanzelf opnieuw:
// zelf opnieuw tekenen, zodat de knoppen naar een tweede rij of kolom kunnen
if (Align in [alTop, alBottom, alLeft, alRight]) and not FRijFix then Invalidate;
end;

procedure TjanSimLogicBox.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure TjanSimLogicBox.ChildMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
   // niets doen: selectie enkel via popup
end;

procedure TjanSimLogicBox.ClearSelectedSender;
begin
  FSelectedSender := nil;
  // optioneel: ook hover sender wissen
  if FLastStatusSender <> nil then
    FLastStatusSender := nil;
end;

procedure TjanSimLogicBox.ApplyLanguageToSimObj(AComponent: TComponent);
begin
  if AComponent is TjanSimButton then
  begin
    TjanSimButton(AComponent).BTaal := Taal;
    TjanSimButton(AComponent).UpdateHintText;
  end
  else if AComponent is TjanSimKnop then
  begin
    TjanSimKnop(AComponent).BTaal := Taal;
    TjanSimKnop(AComponent).UpdateHintText;
  end
  else if AComponent is TjanSimSensor then
  begin
    TjanSimSensor(AComponent).BTaal := Taal;
    TjanSimSensor(AComponent).UpdateHintText;
  end
  else if AComponent is TjanSimWarm then
  begin
    TjanSimWarm(AComponent).BTaal := Taal;
    TjanSimWarm(AComponent).UpdateHintText;
  end
  else if AComponent is TjanSimPuls then
  begin
    TjanSimPuls(AComponent).BTaal := Taal;
    TjanSimPuls(AComponent).UpdateHintText;
  end
  else if AComponent is TjanLogicRun then
    TjanLogicRun(AComponent).BTaal := Taal
  else if AComponent is TjanSimMotor then
    TjanSimMotor(AComponent).BTaal := Taal
  else if AComponent is TjanSimPersoon then
    TjanSimPersoon(AComponent).BTaal := Taal
  else if AComponent is TjanSimEindschakelaar then
    TjanSimEindschakelaar(AComponent).BTaal := Taal
  else if AComponent is TjanSimStappenteller then
    TjanSimStappenteller(AComponent).BTaal := Taal
  else if AComponent is TjanVoedingsDeel then
    TjanVoedingsDeel(AComponent).BTaal := Taal
  else if AComponent is TjanRail then
    TjanRail(AComponent).BTaal := Taal
  else if AComponent is TjanMeter then
    TjanMeter(AComponent).BTaal := Taal
  else if AComponent is TjanDipSwitsh then
  begin
    TjanDipSwitsh(AComponent).BTaal := Taal;
    TjanDipSwitsh(AComponent).UpdateHintText;
  end
  else if AComponent is TjanLogic then
  begin
    TjanLogic(AComponent).BTaal := Taal;
    TjanLogic(AComponent).UpdateHintText;
  end
  else if AComponent is TjanTeller then
  begin
    TjanTeller(AComponent).BTaal := Taal;
    TjanTeller(AComponent).UpdateHintText;
  end
  else if AComponent is TjanMemory then
  begin
    TjanMemory(AComponent).BTaal := Taal;
    TjanMemory(AComponent).UpdateHintText;
  end
  else if AComponent is TjanSimLight then
  begin
    TjanSimLight(AComponent).BTaal := Taal;
    TjanSimLight(AComponent).UpdateHintText;
  end
  else if AComponent is TjanSimRelais then
  begin
    TjanSimRelais(AComponent).BTaal := Taal;
    TjanSimRelais(AComponent).UpdateHintText;
  end
 else if AComponent is TjanSimBuzzer then
  begin
    TjanSimBuzzer(AComponent).BTaal := Taal;
    TjanSimBuzzer(AComponent).UpdateHintText;
  end
  else if AComponent is TjanDisplay then
  begin
    TjanDisplay(AComponent).BTaal := Taal;
    TjanDisplay(AComponent).UpdateHintText;
  end;

  // aanpassen /uitbreiden
end;


procedure TjanSimLogicBox.Notification(AComponent: TComponent; Operation: TOperation);

  procedure HookSimObj(AObj: TObject);
  begin

    // Button
    if AObj is TjanSimButton then
    begin
      with TjanSimButton(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;

    // Knop
    if AObj is TjanSimKnop then
    begin
      with TjanSimKnop(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;

    // Sensor
    if AObj is TjanSimSensor then
    begin
      with TjanSimSensor(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;

    // Warm
    if AObj is TjanSimWarm then
    begin
      with TjanSimWarm(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;

    // DipSwitch
    if AObj is TjanDipSwitsh then
    begin
      with TjanDipSwitsh(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;

    // Puls
    if AObj is TjanSimPuls then
    begin
      with TjanSimPuls(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;

    // Logic
    if AObj is TjanLogic then
    begin
      with TjanLogic(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;

     // Tellerblok
    if AObj is TjanTeller then
    begin
      with TjanTeller(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;

     // Geheugenblok
    if AObj is TjanMemory then
    begin
      with TjanMemory(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;

     // TjanSimLight
    if AObj is TjanSimLight then
    begin
      with TjanSimLight(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;

     // TjanSimRelais
    if AObj is TjanSimRelais then
    begin
      with TjanSimRelais(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;

     // TjanSimBuzzer
    if AObj is TjanSimBuzzer then
    begin
      with TjanSimBuzzer(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;

    // Motor
    if AObj is TjanSimMotor then
    begin
      with TjanSimMotor(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;

    // bron, zekering, milliampèremeter
    if AObj is TjanVoedingsDeel then
    begin
      with TjanVoedingsDeel(AObj) do
      begin
        Box := Self;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;

    // Stappenteller
    if AObj is TjanSimStappenteller then
    begin
      with TjanSimStappenteller(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;

    // Eindschakelaar
    if AObj is TjanSimEindschakelaar then
    begin
      with TjanSimEindschakelaar(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;

    // Persoon
    if AObj is TjanSimPersoon then
    begin
      with TjanSimPersoon(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;

    // LogicRun
    if AObj is TjanLogicRun then
    begin
      with TjanLogicRun(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;

    // TjanDisplay
    if AObj is TjanDisplay then
    begin
      with TjanDisplay(AObj) do
      begin
        Box := Self;
        if not Assigned(OnEnter)  then OnEnter  := ChildMouseEnter;
        if not Assigned(OnExit)   then OnExit   := ChildMouseExit;
        if not Assigned(OnStatus) then OnStatus := StatusFromChild;
      end;
      Exit;
    end;
  end;

begin
  inherited Notification(AComponent, Operation);

  case Operation of
    opInsert:
      Begin
      HookSimObj(AComponent);
      ApplyLanguageToSimObj(AComponent);
      end;
    opRemove:
      begin
        if (FLastStatusSender = AComponent) then
          FLastStatusSender := nil;
        if (FSelectedSender = AComponent) then
          FSelectedSender := nil;
      end;
  end;
end;

procedure TjanSimLogicBox.ChildMouseEnter(Sender: TObject);
var
  s: string;
begin
  inherited;

  FLastStatusSender := Sender;

  s := '';
  if Sender is TjanSimButton then
    s := TjanSimButton(Sender).Naam
  else if Sender is TjanSimKnop then
    s := TjanSimKnop(Sender).Naam
  else if Sender is TjanSimSensor then
    s := TjanSimSensor(Sender).Naam
  else if Sender is TjanSimWarm then
    s := TjanSimWarm(Sender).Naam
  else if Sender is TjanDipSwitsh then
    s := TjanDipSwitsh(Sender).Naam
  else if Sender is TjanSimPuls then
    s := TjanSimPuls(Sender).Naam
  else if Sender is TjanTeller then
    s := TjanTeller(Sender).Naam
  else if Sender is TjanMemory then
    s := TjanMemory(Sender).Naam
  else if Sender is TjanSimLight then
    s := TjanSimLight(Sender).Naam
  else if Sender is TjanSimRelais then
    s := TjanSimRelais(Sender).Naam
  else if Sender is TjanSimBuzzer then
    s := TjanSimBuzzer(Sender).Naam
  else if Sender is TjanDisplay then
    s := TjanDisplay(Sender).Naam;
  // panel 0 = naam (kleurblok doet mainform nu obv FCurrentSender/Soort)
  if Assigned(FOnStatusText) then
    FOnStatusText(Self, s, 0);
    // aanpassen
  // panel 3 NIET meer hier doen (MainForm vult dat centraal)
end;

procedure TjanSimLogicBox.ChildMouseExit(Sender: TObject);
begin
  FLastStatusSender := nil;
   if Assigned(FOnStatusText) then
    FOnStatusText(Self, '', 0);
end;

{ TjanGroupSelect }

function GroupNormRect(const R: TRect): TRect;
begin
  Result := R;
  if R.Left > R.Right then
  begin
    Result.Left := R.Right;
    Result.Right := R.Left;
  end;
  if R.Top > R.Bottom then
  begin
    Result.Top := R.Bottom;
    Result.Bottom := R.Top;
  end;
end;
