// janSimLogic.pas, deel: rails en de berekening van de voedingskring (ingevoegd met {$I jsl_rails_kring.inc})

// staat in jsl_magnetisme.inc: kompassen en veldplaten opnieuw tekenen
procedure MagneetVeranderd(AParent: TWinControl); forward;
// staat in jsl_magnetisme.inc: de zoemers echt laten zoemen (luidsprekers)
procedure ZoemersBijwerken(P: TWinControl); forward;

{ TjanRail }

const
  RailVolts: array[0..6] of Double = (0, 1, 2, 3, 3.3, 4, 5);

constructor TjanRail.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPlus := True;
  FVolt := RailMaxVolt;
  FTaal := 'NL';
  Width := RailWidth;
  Height := 200;
  HelpKeyword := 'voeding';   // F1: help over voeding & voltmeter
  ShowHint := True;
end;

destructor TjanRail.Destroy;
begin
  FreeAndNil(FMover);
  ElektronLijst(Self, False);
  inherited Destroy;
end;

procedure TjanRail.SetElektronen(const AY: array of Integer; const AI: array of Double);
var
  k: Integer;
  Aan, WasAan: Boolean;
begin
  WasAan := False;
  for k := 0 to High(FElekI) do
    if Abs(FElekI[k]) > ElektronMinA then WasAan := True;
  SetLength(FElekY, Length(AY));
  for k := 0 to High(AY) do FElekY[k] := AY[k];
  SetLength(FElekI, Length(AI));
  Aan := False;
  for k := 0 to High(AI) do
  begin
    FElekI[k] := AI[k];
    if Abs(AI[k]) > ElektronMinA then Aan := True;
  end;
  if Aan <> WasAan then
  begin
    ElektronLijst(Self, Aan);
    Invalidate;
  end;
end;

procedure TjanRail.InvalidateElektronen;
var
  R: TRect;
begin
  if (Parent = nil) or not Parent.HandleAllocated or (Length(FElekY) < 2) then Exit;
  R := Rect(LineX - 4, FElekY[0] - 4, LineX + 6, FElekY[High(FElekY)] + 5);
  InvalidateRect(Parent.Handle, @R, False);
end;

procedure TjanRail.PaintElektronen;
var
  k, X, Y, Y1, Y2: Integer;
  S: Double;
begin
  X := RailLineOfs;
  with Canvas do
  begin
    Pen.Width := 1;
    Pen.Color := RGBToColor(31, 95, 191);
    Brush.Style := bsSolid;
    Brush.Color := RGBToColor(31, 95, 191);
    for k := 0 to High(FElekI) do
    begin
      if (k + 1 > High(FElekY)) or (Abs(FElekI[k]) <= ElektronMinA) then Continue;
      Y1 := FElekY[k] - Top;
      Y2 := FElekY[k + 1] - Top;
      S := ElektronFase(FElekI[k]);
      while Y1 + S < Y2 do
      begin
        Y := Y1 + Round(S);
        Ellipse(X - 2, Y - 2, X + 4, Y + 4);
        S := S + ElektronAfstand;
      end;
    end;
  end;
end;

function TjanRail.GetLineX: Integer;
begin
  Result := Left + RailLineOfs;
end;

function TjanRail.GetSpanTop: Integer;
begin
  Result := Top + RailLabelH;
end;

function TjanRail.GetSpanBottom: Integer;
begin
  Result := Top + Height - 1;
  if not FPlus then
    Dec(Result, RailFootH);   // onderaan staat het massasymbool
end;

function TjanRail.Powered: Boolean;
begin
  Result := FPlus and (Volt >= RailMinVolt - 0.001);
end;

// + rail: de spanning van de bron (zie UpdateSupply); - rail: 0 V
function TjanRail.GetVolt: Double;
begin
  if FPlus then Result := FCalcVolt else Result := 0;
end;

// - rail blauw; + rail grijs bij 0 V, daarboven rood en feller naarmate de
// spanning hoger is
function TjanRail.RailColor: TColor;
begin
  if not FPlus then
    Result := clBlue
  else if Volt <= 0.001 then
    Result := clGray
  else
    Result := RGBToColor(110 + Round(145 * Volt / BronMaxVolt), 0, 0);
end;

procedure TjanRail.SetPlus(const Value: Boolean);
begin
  if FPlus = Value then Exit;
  FPlus := Value;
  UpdateHintText;
  Invalidate;
  if Assigned(Parent) then Parent.Invalidate;
end;

procedure TjanRail.SetVolt(const Value: Double);
var
  V: Double;
begin
  V := Value;
  if V < 0 then V := 0;
  if V > BronMaxVolt then V := BronMaxVolt;
  if Abs(V - FVolt) < 0.001 then Exit;
  FVolt := V;
  UpdateHintText;
  Invalidate;
  if Assigned(Parent) then Parent.Invalidate;   // kleur van de stekkers
end;

procedure TjanRail.SetTaal(const Value: string);
begin
  FTaal := Value;
  UpdateHintText;
end;

procedure TjanRail.UpdateHintText;
var
  V: string;
begin
  V := FormatFloat('0.0', Volt) + ' V';
  if FPlus then
    Hint := Tr(FTaal, '+ rail (voeding):', '+ rail (supply):', 'Rail + (alimentation) :',
        '+ Schiene (Versorgung):') + ' ' + V + #13#10 +
      Tr(FTaal,
        'Invoer rechts op de rail inpluggen. Onder 2V geen signaal.' + #13#10 +
          'De spanning komt van de bron (accu). Sleep de uiteinden om te verlengen.',
        'Plug inputs in on the right of the rail. Below 2V no signal.' + #13#10 +
          'The voltage comes from the source (battery). Drag the ends to resize.',
        'Branchez les entrées à droite du rail. Sous 2V pas de signal.' + #13#10 +
          'La tension vient de la source (batterie). Faites glisser les extrémités.',
        'Eingänge rechts an die Schiene stecken. Unter 2V kein Signal.' + #13#10 +
          'Die Spannung kommt von der Quelle (Akku). Enden ziehen zum Verlängern.')
  else
    Hint := Tr(FTaal,
      '- rail (massa)' + #13#10 + 'Uitvoer links op de rail inpluggen.' + #13#10 +
        'Sleep de uiteinden om te verlengen.',
      '- rail (ground)' + #13#10 + 'Plug outputs in on the left of the rail.' + #13#10 +
        'Drag the ends to resize.',
      'Rail - (masse)' + #13#10 + 'Branchez les sorties à gauche du rail.' + #13#10 +
        'Faites glisser les extrémités pour redimensionner.',
      '- Schiene (Masse)' + #13#10 + 'Ausgänge links an die Schiene stecken.' + #13#10 +
        'Enden ziehen zum Verlängern.');
end;

procedure TjanRail.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  if FPlus then
  begin
    FOnStatus(Self, Tr(FTaal, '+ rail', '+ rail', 'Rail +', '+ Schiene') + ' > ', 0);
    FOnStatus(Self, 'U = ' + FormatFloat('0.0', Volt) + ' V', 1);
  end
  else
  begin
    FOnStatus(Self, Tr(FTaal, '- rail', '- rail', 'Rail -', '- Schiene') + ' > ', 0);
    FOnStatus(Self, Tr(FTaal, 'Massa', 'Ground', 'Masse', 'Masse'), 1);
  end;
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

procedure TjanRail.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
  UpdateHintText;
  SendStatusToBar;
end;

procedure TjanRail.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
  if FDragMode = 0 then
    Cursor := crDefault;
  if Assigned(FOnStatus) then
  begin
    FOnStatus(Self, '', 0);
    FOnStatus(Self, '', 1);
    FOnStatus(Self, '', 2);
    FOnStatus(Self, '', 3);
  end;
end;

procedure TjanRail.Paint;
var
  X, T, B, TW: Integer;
  Col: TColor;
  S: string;
begin
  X := RailLineOfs;
  T := RailLabelH;
  B := Height;
  Col := RailColor;
  with Canvas do
  begin
    Brush.Style := bsSolid;
    Brush.Color := Col;
    // dopje bovenaan: daar kun je de rail langer of korter slepen
    FillRect(Rect(X - 3, T, X + 5, T + 2));
    if FPlus then
    begin
      FillRect(Rect(X, T, X + 2, B));
      FillRect(Rect(X - 3, B - 2, X + 5, B));     // dopje onderaan
    end
    else
    begin
      // - rail: onderaan het massasymbool, drie streepjes naar beneden
      FillRect(Rect(X, T, X + 2, B - RailFootH + 2));
      FillRect(Rect(X - 6, B - RailFootH + 1, X + 8, B - RailFootH + 3));
      FillRect(Rect(X - 4, B - RailFootH + 5, X + 6, B - RailFootH + 7));
      FillRect(Rect(X - 2, B - RailFootH + 9, X + 4, B - RailFootH + 11));
    end;
    // spanning bovenaan (+ rail: ingestelde spanning, - rail: 0V)
    if FPlus then
      S := FormatFloat('0.#', Volt) + 'V'
    else
      S := '0V';
    Brush.Style := bsClear;
    Font.Name := 'Arial';
    Font.Size := 7;
    Font.Style := [fsBold];
    Font.Color := Col;
    TW := TextWidth(S);
    TextOut((Self.Width - TW) div 2, 0, S);
    if FSelected then
    begin
      Brush.Style := bsClear;
      Pen.Color := clRed;
      Pen.Style := psDot;
      Pen.Width := 1;
      Rectangle(ClientRect);
      Pen.Style := psSolid;
    end;
    Brush.Style := bsSolid;
  end;
  PaintElektronen;
end;

// 1 = verplaatsen, 2 = bovenkant, 3 = onderkant
function TjanRail.HitMode(Y: Integer): Integer;
begin
  if Y <= RailLabelH + RailGrip then
    Result := 2
  else if (FPlus and (Y >= Height - RailGrip)) or
          ((not FPlus) and (Y >= Height - RailFootH - RailGrip)) then
    Result := 3
  else
    Result := 1;
end;

procedure TjanRail.BuildPopup;
var
  mi: TMenuItem;
begin
  if not Assigned(PopupMenu) then
    PopupMenu := TPopupMenu.Create(Self)
  else
    PopupMenu.Items.Clear;
  // (de spanning van een + rail komt van de bron: geen menu Spanning meer)

  mi := TMenuItem.Create(PopupMenu);
  if FLock then
    mi.Caption := Tr(FTaal, 'Ontgrendel', 'Unlock', 'Déverrouiller', 'Entsperren')
  else
    mi.Caption := Tr(FTaal, 'Vergrendel', 'Lock', 'Verrouiller', 'Sperren');
  mi.OnClick := LockClick;
  PopupMenu.Items.Add(mi);

  mi := TMenuItem.Create(PopupMenu);
  if FSelected then
    mi.Caption := Tr(FTaal, 'Deselecteer object', 'Deselect object', 'Désélectionner l''objet', 'Objekt abwählen')
  else
    mi.Caption := Tr(FTaal, 'Selecteer object', 'Select object', 'Sélectionner un objet', 'Objekt auswählen');
  mi.OnClick := SelectClick;
  PopupMenu.Items.Add(mi);
end;

procedure TjanRail.VoltClick(Sender: TObject);
begin
  Volt := RailVolts[TMenuItem(Sender).Tag];
  SendStatusToBar;
end;

procedure TjanRail.LockClick(Sender: TObject);
begin
  FLock := not FLock;
end;

procedure TjanRail.SelectClick(Sender: TObject);
begin
  if Assigned(FBox) then
    FBox.SelectObject(Self);
end;

procedure TjanRail.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
  Con: TjanConnector;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Parent = nil then Exit;
  if (Button = mbRight) and not FLock then
  begin
    BuildPopup;
    P := Mouse.CursorPos;
    PopupMenu.PopUp(P.X, P.Y);
    Exit;
  end;
  // met de knop Verbinding: een voedingsdraad vanaf de rail beginnen
  if (Button = mbLeft) and (Screen.Cursor = crDraad) then
  begin
    P := Parent.ScreenToClient(ClientToScreen(Point(X, Y)));
    if (P.Y >= SpanTop) and (P.Y <= SpanBottom) then
    begin
      FDragMode := 0;
      if FPlus then
      begin
        // het begin van de draad (midden van het blokje) precies op de lijn;
        // de draad wijst naar rechts, naar de invoer
        Maakdraad(P.Y - 4, LineX - 4, Parent);
        movecursor;
      end
      else
      begin
        // - rail: de uitvoer staat links, dus de draad wijst naar links
        Con := TjanConnector.Create(Parent);
        Con.Parent := Parent;
        Con.SetBounds(LineX - 4, P.Y - 4, 35, 25);
        Con.Tag := Parent.ControlCount;
        Con.PlaceEnds(Point(LineX, P.Y), Point(LineX - 30, P.Y + 16));
        Con.Visible := True;
        Con.BringToFront;
        // muisaanwijzer op het einde, zoals bij movecursor
        Application.ProcessMessages;
        Mouse.CursorPos := Parent.ClientToScreen(Point(LineX - 30, P.Y + 16));
      end;
    end;
    Exit;
  end;
  if (Button <> mbLeft) or FLock then Exit;
  FDragStart := Parent.ScreenToClient(ClientToScreen(Point(X, Y)));
  FStartRect := BoundsRect;
  FDragMode := HitMode(Y);
  if FDragMode = 1 then
  begin
    // ingeplugde componenten (met hun draden) schuiven mee
    FreeAndNil(FMover);
    FMover := TjanGroupSelect.Create(nil);
    TjanGroupSelect(FMover).Parent := Parent;
    TjanGroupSelect(FMover).BeginRailMove(Self);
  end;
end;

procedure TjanRail.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  P, Snapped: TPoint;
  DX, DY, NewTop, NewBottom: Integer;
  WorkR: TRect;
begin
  inherited MouseMove(Shift, X, Y);
  if Parent = nil then Exit;
  if FDragMode = 0 then
  begin
    // met de knop Verbinding: het pen-symbool houden (onder GTK2 wint de
    // cursor van het besturingselement van Screen.Cursor)
    if Screen.Cursor = crDraad then
      Cursor := crDraad
    else if FLock then
      Cursor := crDefault
    else if HitMode(Y) = 1 then
      Cursor := crSizeAll
    else
      Cursor := crSizeNS;
    Exit;
  end;
  if not (ssLeft in Shift) then Exit;

  P := Parent.ScreenToClient(ClientToScreen(Point(X, Y)));
  DX := P.X - FDragStart.X;
  DY := P.Y - FDragStart.Y;
  if Parent is TjanGridS then
    WorkR := TjanGridS(Parent).GetWorkAreaRect
  else
    WorkR := Parent.ClientRect;

  case FDragMode of
    1:
      begin
        // lijn en bovenkant van de rail op het raster laten springen
        if Parent is TjanGridS then
        begin
          Snapped := TjanGridS(Parent).SnapPointToRuler(
            Point(FStartRect.Left + RailLineOfs + DX, FStartRect.Top + RailLabelH + DY), WorkR);
          DX := Snapped.X - (FStartRect.Left + RailLineOfs);
          DY := Snapped.Y - (FStartRect.Top + RailLabelH);
        end;
        if FStartRect.Left + DX < WorkR.Left then DX := WorkR.Left - FStartRect.Left;
        if FStartRect.Top + DY < WorkR.Top then DY := WorkR.Top - FStartRect.Top;
        SetBounds(FStartRect.Left + DX, FStartRect.Top + DY, Width, Height);
        if Assigned(FMover) then
          TjanGroupSelect(FMover).RailMove(DX, DY);
      end;
    2:
      begin
        NewTop := FStartRect.Top + DY;
        if NewTop < WorkR.Top then NewTop := WorkR.Top;
        if FStartRect.Bottom - NewTop < RailLabelH + RailMinLen + RailFootH then
          NewTop := FStartRect.Bottom - RailLabelH - RailMinLen - RailFootH;
        SetBounds(Left, NewTop, Width, FStartRect.Bottom - NewTop);
      end;
    3:
      begin
        NewBottom := FStartRect.Bottom + DY;
        if NewBottom > WorkR.Bottom then NewBottom := WorkR.Bottom;
        if NewBottom - FStartRect.Top < RailLabelH + RailMinLen + RailFootH then
          NewBottom := FStartRect.Top + RailLabelH + RailMinLen + RailFootH;
        SetBounds(Left, FStartRect.Top, Width, NewBottom - FStartRect.Top);
      end;
  end;
  SendStatusToBar;
end;

procedure TjanRail.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if Assigned(FMover) then
  begin
    TjanGroupSelect(FMover).EndRailMove;
    FreeAndNil(FMover);
  end;
  FDragMode := 0;
  if Assigned(Parent) then
    Parent.Invalidate;
end;

// ============================================================
// Voedingskring: bron (accu), zekering en milliampèremeter
// ============================================================
//
// De kring: + van de bron -> (zekering, meter ...) -> + rail, en - rail ->
// - van de bron. Alle verbruikers die aan staan vormen samen de belasting
// (een weerstand per onderdeel, zie LoadAmps). UpdateSupply rekent met de
// wet van Ohm de stroom en de spanning op de rail uit:
//   I = E / (Ri + Rbelasting)    U(rail) = E - I * Ri
// Zonder gesloten kring (geen bron, - niet aangesloten, zekering
// doorgebrand) staat de + rail op 0 V.

const
  BronRi: array[0..3] of Double = (0, 0.5, 1, 2);            // ohm
  ZekeringMA: array[0..4] of Integer = (100, 250, 500, 1000, 2000);
  VoedingPinTol = 5;      // zo dicht bij een klem telt een draadeinde
  BronW = 112; BronH = 84;
  // wisselbron: vertraagde frequenties (Hz)
  WisselHz: array[0..2] of Double = (0.5, 1, 2);
  WisselStandaard = 1;    // 1 Hz
  ZekeringW = 40; ZekeringH = 58;
  AmpMeterW = 100; AmpMeterH = 51;
  // weerstand/contact: goed contact, lange dunne draad, slecht contact,
  // verbrand contact
  // 4..7: voorschakelweerstanden (bv. voor een led)
  WeerstandOhm: array[0..12] of Double = (0.05, 1, 2, 10, 100, 220, 470, 1000, 2200, 4700, 10000, 47000, 100000);
  WeerstandW = 100; WeerstandH = 42;
  // onderdelen met twee klemmen voor serie en parallel
  // lampen voor 12 V (0..5): 6 W, 3 W, 2,4 W, 1,2 W, 0,6 W, 0,3 W
  // lampen voor 5 V (6..9): 0,5 W, 0,25 W, 0,1 W, 0,05 W; die van 250 en
  // 500 ohm branden goed aan de uitgang van een poort (5 V, 50 ohm)
  Lamp2Ohm: array[0..9] of Double = (24, 48, 60, 120, 240, 480, 50, 100, 250, 500);
  Lamp2Standaard = 3;     // 120 ohm: 100 mA bij 12 V
  Lamp2Eerste5V = 6;
  Lamp2Standaard5V = 8;   // 250 ohm: 20 mA bij 5 V
  Lamp2W = 64; Lamp2H = 46;
  Schakelaar2W = 64; Schakelaar2H = 40;
  Voltmeter2W = 100; Voltmeter2H = 51;
  // led: drempelspanning per kleur (rood, geel, groen, blauw)
  LedVolt: array[0..3] of Double = (1.8, 2.0, 2.2, 3.0);
  LedRd = 15;             // ohm boven de drempel
  LedVolA = 0.020;        // vol licht bij 20 mA
  LedMaxA = 0.030;        // kapot boven 30 mA
  // oscilloscoop
  ScoopW = 180; ScoopH = 130;
  ScoopMax = 600;                                        // meetpunten in het geheugen
  ScoopBereik: array[0..1] of Double = (5, 12);          // V (boven en onder de nullijn)
  ScoopTijd: array[0..2] of Double = (2, 4, 8);          // s over het hele scherm
  // diode (1N4007): drempel, weerstand boven de drempel, maximale stroom
  DiodeVolt = 0.7;
  DiodeRd = 0.1;
  DiodeMaxA = 1.0;
  // transistor: versterking, drempel en weerstand basis-emitter, spanning
  // en weerstand collector-emitter als hij verzadigd is, maximale stromen
  TrBeta: array[0..2] of Integer = (50, 100, 200);
  TrBetaStd = 1;          // 100
  TrVbe = 0.7;
  TrRbe = 5;
  TrVceSat = 0.2;
  TrRce = 0.5;
  TrMaxIb = 0.1;          // kapot boven 100 mA basisstroom
  TrMaxIc = 1.0;          // kapot boven 1 A collectorstroom
  TrW = 120; TrH = 96;
  // LDR en NTC: weerstand met een schuifregelaar voor het licht of de temperatuur
  SensW = 120; SensH = 84;   // onderaan een schermpje met het licht of de temperatuur
  LdrDonker = 1000000;    // ohm bij 0 % licht (100 ohm bij 100 %)
  NtcR25 = 10000;         // ohm bij 25 °C
  NtcB = 3950;            // B-waarde in kelvin
  Led2W = 64; Led2H = 46;
  // condensator: capaciteit in microfarad
  CondUF: array[0..4] of Double = (100, 470, 1000, 2200, 4700);
  CondStandaard = 2;      // 1000 uF
  CondW = 64; CondH = 58;   // twee regels tekst onder het symbool
  // potentiometer: hele weerstand in ohm
  PotOhm: array[0..3] of Double = (470, 1000, 4700, 10000);
  PotStandaard = 1;       // 1 kohm
  PotW = 120; PotH = 64;

var
  // tijdstap van de voedingskring voor de condensatoren (s), en of deze
  // berekening de tijd ook echt laat verder lopen (alleen de cpu-timer)
  CondDt: Double = 0.05;
  CondStap: Boolean = False;
  CondLaatste: QWord = 0;
  // simulatietijd (s): loopt met de cpu-timer verder (wisselbron)
  SimTijd: Double = 0;

// naam van soort I van de weerstand (zie WeerstandOhm)
function WeerstandNaam(const ATaal: string; I: Integer): string;
begin
  case I of
    0: Result := Tr(ATaal, 'goed contact', 'good contact', 'bon contact', 'guter Kontakt');
    1: Result := Tr(ATaal, 'lange dunne draad', 'long thin wire', 'long fil fin', 'langer dünner Draht');
    2: Result := Tr(ATaal, 'slecht contact', 'poor contact', 'mauvais contact', 'schlechter Kontakt');
    3: Result := Tr(ATaal, 'verbrand contact', 'burnt contact', 'contact brûlé', 'verbrannter Kontakt');
  else
    Result := Tr(ATaal, 'voorschakelweerstand', 'series resistor', 'résistance série', 'Vorwiderstand');
  end;
end;

// naam van kleur I van de led (zie LedVolt)
function LedKleurNaam(const ATaal: string; I: Integer): string;
begin
  case I of
    0: Result := Tr(ATaal, 'rood', 'red', 'rouge', 'rot');
    1: Result := Tr(ATaal, 'geel', 'yellow', 'jaune', 'gelb');
    2: Result := Tr(ATaal, 'groen', 'green', 'vert', 'grün');
  else
    Result := Tr(ATaal, 'blauw', 'blue', 'bleu', 'blau');
  end;
end;

function LedRGB(I: Integer): TColor;
begin
  case I of
    0: Result := RGBToColor(255, 30, 30);
    1: Result := RGBToColor(255, 210, 0);
    2: Result := RGBToColor(0, 200, 40);
  else
    Result := RGBToColor(30, 100, 255);
  end;
end;

// "1000 µF"
function UFText(C: Double): string;
begin
  Result := FormatFloat('0', C) + ' µF';
end;

function OhmText(R: Double): string;
begin
  if R = 0 then Result := '0'
  else if R < 1 then Result := FormatFloat('0.00', R)
  else if R >= 999500 then
  begin
    Result := FormatFloat('0.##', R / 1000000) + ' MΩ';
    Exit;
  end
  else if R >= 2000 then
  begin
    // 2,2 k, 4,7 k, 10 k ... (1000 blijft 1000, zoals in de lessen)
    Result := FormatFloat('0.#', R / 1000) + ' kΩ';
    Exit;
  end
  else Result := FormatFloat('0', R);
  Result := Result + ' Ω';
end;

// getallen voor de berekeningen in de hints (wet van Ohm)
function AmpText(I: Double): string;
begin
  Result := FormatFloat('0.000', I) + ' A';
end;

function MilliAmpText(I: Double): string;
begin
  Result := FormatFloat('0', I * 1000) + ' mA';
end;

function VoltText(U: Double): string;
begin
  if U >= 10 then Result := FormatFloat('0.0', U)
  else if U >= 0.1 then Result := FormatFloat('0.00', U)
  else Result := FormatFloat('0.000', U);
  Result := Result + ' V';
end;

function WattText(P: Double): string;
begin
  if P >= 10 then Result := FormatFloat('0.0', P)
  else if P >= 0.1 then Result := FormatFloat('0.00', P)
  else Result := FormatFloat('0.000', P);
  Result := Result + ' W';
end;

// "I = 242 mA = 0,242 A"
function StroomRegel(I: Double): string;
begin
  Result := 'I = ' + MilliAmpText(I) + ' = ' + AmpText(I);
end;

// "P = U × I = 2,42 V × 0,242 A = 0,59 W"
function VermogenRegel(U, I: Double): string;
begin
  Result := 'P = U × I = ' + VoltText(U) + ' × ' + AmpText(I) + ' = ' + WattText(U * I);
end;

// hoogste spanning op een + rail van paneel P (0 als er geen is)
function MaxRailVolt(P: TWinControl): Double;
var
  i: Integer;
begin
  Result := 0;
  if P = nil then Exit;
  for i := 0 to P.ControlCount - 1 do
    if (P.Controls[i] is TjanRail) and P.Controls[i].Visible and
       (TjanRail(P.Controls[i]).Volt > Result) then
      Result := TjanRail(P.Controls[i]).Volt;
end;

// stroom (A) die verbruiker C bij 12 V trekt als hij aan staat; 0 als hij
// uit staat of niet aangesloten is. Bij een andere spanning evenredig
// (wet van Ohm: elke verbruiker is een vaste weerstand).
function LoadAmps12(C: TControl): Double;
const
  Segments: array[0..15] of Integer = (6, 2, 5, 5, 4, 5, 6, 3, 7, 6, 6, 5, 4, 5, 5, 4);
var
  i: Integer;
  P: TjanSimPersoon;
begin
  Result := 0;
  if not C.Visible then Exit;
  // uitvoer werkt alleen ingeplugd op (of met een draad aan) de - rail
  if IsRailOutput(C) and (RailOf(C) = nil) then Exit;
  if C is TjanSimLight then
  begin
    if TjanSimLight(C).Lit then
      if TjanSimLight(C).Kleur = lkLamp then Result := 0.100 else Result := 0.020;
  end
  else if C is TjanSchakelRelais then
  begin
    if TjanSchakelRelais(C).Lit then Result := 0.040;
  end
  else if C is TjanSimRelais then
  begin
    if TjanSimRelais(C).Lit then Result := 0.040;
  end
  else if C is TjanSimBuzzer then
  begin
    if TjanSimBuzzer(C).Lit then Result := 0.030;
  end
  else if C is TjanSimMotor then
  begin
    if TjanSimMotor(C).Inputs[0] <> TjanSimMotor(C).Inputs[1] then Result := 0.200;
  end
  else if C is TjanDisplay then
    Result := 0.010 * Segments[TjanDisplay(C).Bits and 15]
  else if C is TjanSimPersoon then
  begin
    P := TjanSimPersoon(C);
    for i := 0 to P.InputCount - 1 do
      if P.Inputs[i] then Result := Result + 0.020;
  end
  // poorten, tellers, geheugen en ingeplugde invoer: een klein beetje
  else if (IsRailInput(C) and (RailOf(C) <> nil)) or (C is TjanLogic) or
          (C is TjanTeller) or (C is TjanMemory) or (C is TjanSimStappenteller) or
          (C is TjanLogicRun) then
    Result := 0.001;
end;

// helderheid (0..1) van een lamp of led: spanning van de voeding / 12 V;
// zonder rails op het paneel altijd vol
function LampHelderheid(C: TControl): Double;
var
  i: Integer;
  U: Double;
begin
  Result := 1;
  if (C.Parent = nil) or not PanelHasRails(C.Parent) then Exit;
  U := 0;
  for i := 0 to C.Parent.ControlCount - 1 do
    if (C.Parent.Controls[i] is TjanRail) and C.Parent.Controls[i].Visible and
       (TjanRail(C.Parent.Controls[i]).Volt > U) then
      U := TjanRail(C.Parent.Controls[i]).Volt;
  // de logische lamp werkt op 5 V (zoals de uitgang van een poort): vanaf
  // 5 V brandt ze vol, daaronder zwakker
  Result := U / LogicLampVolt;
  if Result > 1 then Result := 1;
  if Result < 0.15 then Result := 0.15;
end;

// staat er een + rail onder spanning op paneel P? (dan werkt de uitvoer)
function SupplyOK(P: TWinControl): Boolean;
var
  i: Integer;
begin
  Result := False;
  if P = nil then Exit;
  for i := 0 to P.ControlCount - 1 do
    if (P.Controls[i] is TjanRail) and P.Controls[i].Visible and
       TjanRail(P.Controls[i]).Powered then
      Exit(True);
end;

// een draad (niet AExclude) met een uiteinde bij Pt; AOther = het andere einde
function WireAt(P: TWinControl; const Pt: TPoint; AExclude: TControl;
  out AOther: TPoint): TjanConnector;
var
  i: Integer;
  A, B: TPoint;
begin
  Result := nil;
  for i := 0 to P.ControlCount - 1 do
    if (P.Controls[i] is TjanConnector) and P.Controls[i].Visible and
       (P.Controls[i] <> AExclude) then
    begin
      TjanConnector(P.Controls[i]).EndCenters(A, B);
      if (Abs(A.X - Pt.X) <= VoedingPinTol) and (Abs(A.Y - Pt.Y) <= VoedingPinTol) then
      begin
        AOther := B;
        Exit(TjanConnector(P.Controls[i]));
      end;
      if (Abs(B.X - Pt.X) <= VoedingPinTol) and (Abs(B.Y - Pt.Y) <= VoedingPinTol) then
      begin
        AOther := A;
        Exit(TjanConnector(P.Controls[i]));
      end;
    end;
end;

// Rekent de voedingskring van paneel P uit als een netwerk (knooppuntmethode,
// wetten van Kirchhoff). Elke klem van een voedingsonderdeel en elke rail is
// een knooppunt; draden voegen knooppunten samen. Takken:
//   bron            E met inwendige weerstand Ri (Norton: stroom E/Ri, geleiding 1/Ri)
//   zekering, mA-meter, gesloten schakelaar: bijna 0 ohm (RKlein)
//   contact, lamp met 2 klemmen: hun weerstand
//   voltmeter met 2 klemmen: geen tak (neemt geen stroom)
//   verbruikers op de rails (lampen, led's, poorten ...): samen geleiding G
//     tussen de + rail en de - rail (zonder - rail: de - klem van de bron)
// Een zekering met te veel stroom smelt; dan wordt opnieuw gerekend.
// Zet de spanning van de rails, de klemspanning en stroom van de bron, en
// de stroom en klemspanningen van de andere onderdelen. AInval: gewijzigde
// onderdelen opnieuw tekenen.
procedure ElektronenRails(P: TWinControl; AU: Double; AToon: Boolean); forward;

const
  PoortUitOhm = 50;   // inwendige weerstand van een logische uitgang als bron van 5 V
  KnoopTol = 6;       // zo dicht bij het midden van een ingang hoort een los draadeinde bij die ingang

// midden van de ingang (groen vierkantje) van een blok zonder klemmen waar Pt
// binnen KnoopTol van ligt, anders Pt zelf (staat in jsl_draadlogica.inc)
function IngangBij(P: TWinControl; const Pt: TPoint): TPoint; forward;

// het schakelrelais waarvan Pt het contact R2 is, anders nil (dat contact geeft
// de spanning van de rail van R1 door; al de andere logische uitgangen zijn een
// bron van 5 V)
function RelaisContactOp(P: TWinControl; const Pt: TPoint): TControl;
var
  i: Integer;
  R: TRect;
begin
  Result := nil;
  if P = nil then Exit;
  for i := 0 to P.ControlCount - 1 do
    if (P.Controls[i] is TjanSchakelRelais) and P.Controls[i].Visible then
    begin
      R := P.Controls[i].BoundsRect;
      InflateRect(R, 8, 0);
      if PtInRect(R, Pt) then Exit(P.Controls[i]);
    end;
end;

procedure UpdateSupply(P: TWinControl; AInval: Boolean);
const
  RKlein = 0.001;   // ohm: zekering, meter, gesloten schakelaar, bron zonder Ri
  GMin = 1E-9;      // siemens naar de massa: houdt losse knooppunten op 0 V
type
  TTak = record
    A, B: Integer;        // knooppunten
    G: Double;            // geleiding (S)
    E: Double;            // bronspanning in de tak (bron, led, condensator)
    D: TjanVoedingsDeel;  // onderdeel (nil = verbruikers op de rails)
  end;
  // gestuurde stroombron (transistor die versterkt): de stroom
  // I = G x (V[P] - V[M] - Off) loopt in het onderdeel van knooppunt Van naar Naar
  TGest = record
    Van, Naar, P, M: Integer;
    G, Off: Double;
  end;
var
  Parts: array of TjanVoedingsDeel;
  Rails: array of TjanRail;
  Ouder: array of Integer;          // union-find over klemmen en rails
  NodeOf: array of Integer;         // klem/rail -> knooppunt
  Tak: array of TTak;
  Gest: array of TGest;
  Tr: TjanTransistor;
  NC, NB, NE: Integer;              // knooppunten van C, B en E
  Gm: array of array of Double;     // geleidingsmatrix
  Iv, V: array of Double;           // bronstromen, knooppuntspanningen
  CompGnd: array of Integer;        // massa per samenhangend deel
  NewVolt: array of Double;
  PinBase: array of Integer;        // eerste klem van onderdeel k in Ouder/NodeOf
  i, k, j, N, NP, NR, NK, A, B, Ronde, PlusR, Mass: Integer;
  C: TControl;
  Con: TjanConnector;
  Pa, Pb: TPoint;
  G, E, Gs, Amp, U, F, Hulp: Double;
  Smelt, Changed: Boolean;
  DelerKnoop: Integer;              // knooppunt bij het zoeken naar spanningsdelers
  IsDeler: Boolean;
  Z: TjanZekering;
  LoadItA, LoadItB: Integer;       // klem/rail waar de verbruikers aan hangen
  LoadG: Double;
  Toon: Boolean;
  Vraag, Sub: array of Double;     // stroom die een klem/rail uit de draden neemt
  Draad: array of TjanConnector;
  DrA, DrB, Buur, BuurDraad, Volg, OuderIt, OuderDraad: array of Integer;
  BuurStart: array of Integer;
  Gezien: array of Boolean;
  NI, ND, Kop, Staart, m: Integer;
  // logische uitgangen die met een draad een klem van de voedingskring voeden
  // (TjanConnector.FLogicBron), elk een eigen knooppunt vanaf NK + NR:
  // hoog = bron van 5 V t.o.v. de - rail, laag = 0 V; het contact R2 van een
  // schakelrelais geeft (dicht) de rail van R1 door
  NL: Integer;
  LogPt: array of TPoint;
  LogHoog: array of Boolean;
  LogRail: array of Integer;   // relaiscontact: de rail van R1 (index in Ouder), anders -1
  LogRelais: array of Boolean;
  RlC: TControl;
  RlR: TjanRail;
  // ingang zonder klem (poort, teller, display ...) waar twee of meer draden
  // uit de voedingskring samenkomen: een eigen knooppunt vanaf NK + NR + NL
  NJ: Integer;
  KnPt, KnIn, LosPt, LosIn: array of TPoint;

  // weerstand, minstens RKlein (een ideale bron of draad: bijna 0 ohm)
  function NietNul(R: Double): Double;
  begin
    if R < RKlein then Result := RKlein else Result := R;
  end;

  function Find(X: Integer): Integer;
  begin
    while Ouder[X] <> X do
    begin
      Ouder[X] := Ouder[Ouder[X]];
      X := Ouder[X];
    end;
    Result := X;
  end;

  procedure Union(X, Y: Integer);
  begin
    X := Find(X); Y := Find(Y);
    if X <> Y then Ouder[X] := Y;
  end;

  // klem of rail bij punt Pt: index in Ouder, anders -1
  function ItemAt(const Pt: TPoint): Integer;
  var
    q, pn: Integer;
    R: TjanRail;
  begin
    for q := 0 to NP - 1 do
    begin
      pn := Parts[q].PinAt(Pt);
      if pn >= 0 then Exit(PinBase[q] + pn);
    end;
    R := RailAtPoint(P, Pt);
    if R <> nil then
      for q := 0 to NR - 1 do
        if Rails[q] = R then Exit(NK + q);
    for q := 0 to NL - 1 do
      if NearPoint(Pt, LogPt[q]) then Exit(NK + NR + q);
    // knooppunt op een ingang: het punt zelf, of een eind dat met de hand
    // net naast het vierkantje van dezelfde ingang gelegd is
    for q := 0 to NJ - 1 do
      if NearPoint(Pt, KnPt[q]) or
         ((Abs(Pt.X - KnIn[q].X) <= KnoopTol) and (Abs(Pt.Y - KnIn[q].Y) <= KnoopTol) and
          NearPoint(IngangBij(P, Pt), KnIn[q])) then
        Exit(NK + NR + NL + q);
    Result := -1;
  end;

  // draad van een logische uitgang (LogPt) naar een knooppunt op een ingang:
  // een gewone signaaldraad, geen verbinding in de voedingskring
  function SignaalDraad(XA, XB: Integer): Boolean;
  var
    T: Integer;
  begin
    if XA > XB then
    begin
      T := XA; XA := XB; XB := T;
    end;
    Result := (XA >= NK + NR) and (XA < NK + NR + NL) and (XB >= NK + NR + NL);
  end;

  procedure AddTak(AA, AB: Integer; AG: Double; AD: TjanVoedingsDeel);
  begin
    SetLength(Tak, Length(Tak) + 1);
    Tak[High(Tak)].A := AA;
    Tak[High(Tak)].B := AB;
    Tak[High(Tak)].G := AG;
    Tak[High(Tak)].E := 0;
    Tak[High(Tak)].D := AD;
  end;

  // tak met een bronspanning AE van AB naar AA (zoals een bron: + aan AA)
  procedure AddTakE(AA, AB: Integer; AG, AE: Double; AD: TjanVoedingsDeel);
  begin
    AddTak(AA, AB, AG, AD);
    Tak[High(Tak)].E := AE;
  end;

  function PinNode(Q, K: Integer): Integer;
  begin
    Result := NodeOf[PinBase[Q] + K];
  end;

  // Gauss-eliminatie met spilkeuze: Gm * V = Iv
  procedure Solve;
  var
    r, s, t, Best: Integer;
    M, Tmp: Double;
    Row: array of Double;
  begin
    for r := 0 to N - 1 do
    begin
      Best := r;
      for s := r + 1 to N - 1 do
        if Abs(Gm[s][r]) > Abs(Gm[Best][r]) then Best := s;
      if Best <> r then
      begin
        Row := Gm[r]; Gm[r] := Gm[Best]; Gm[Best] := Row;
        Tmp := Iv[r]; Iv[r] := Iv[Best]; Iv[Best] := Tmp;
      end;
      if Abs(Gm[r][r]) < 1E-30 then Continue;
      for s := r + 1 to N - 1 do
      begin
        M := Gm[s][r] / Gm[r][r];
        if M = 0 then Continue;
        for t := r to N - 1 do
          Gm[s][t] := Gm[s][t] - M * Gm[r][t];
        Iv[s] := Iv[s] - M * Iv[r];
      end;
    end;
    for r := N - 1 downto 0 do
    begin
      M := Iv[r];
      for t := r + 1 to N - 1 do
        M := M - Gm[r][t] * V[t];
      if Abs(Gm[r][r]) < 1E-30 then V[r] := 0 else V[r] := M / Gm[r][r];
    end;
  end;

  procedure SetStroom(D: TjanVoedingsDeel; AI: Double);
  begin
    if Abs(D.FAmp - AI) > 0.00005 then
    begin
      D.FAmp := AI;
      if AInval then D.Invalidate;
      if D is TjanSpoel or (D is TjanRelaisModel) then MagneetVeranderd(P);   // de spoel is een (andere) magneet
    end;
    if (D is TjanAmpMeter) and (Abs(TjanAmpMeter(D).FStroom - Abs(AI)) > 0.00005) then
    begin
      TjanAmpMeter(D).FStroom := Abs(AI);
      if AInval then D.Invalidate;
    end
    else if (D is TjanWeerstand) and (Abs(TjanWeerstand(D).FStroom - Abs(AI)) > 0.00005) then
    begin
      TjanWeerstand(D).FStroom := Abs(AI);
      if AInval then D.Invalidate;
    end;
  end;

  procedure SetPinV(D: TjanVoedingsDeel; K: Integer; AV: Double);
  begin
    if Abs(D.FPinV[K] - AV) > 0.0005 then
    begin
      D.FPinV[K] := AV;
      if AInval then D.Invalidate;
    end;
    if D is TjanZekering then
    begin
      if K = 0 then TjanZekering(D).FInVolt := AV else TjanZekering(D).FUitVolt := AV;
    end
    else if D is TjanAmpMeter then
    begin
      if K = 0 then TjanAmpMeter(D).FInVolt := AV else TjanAmpMeter(D).FUitVolt := AV;
    end
    else if D is TjanWeerstand then
    begin
      if K = 0 then TjanWeerstand(D).FInVolt := AV else TjanWeerstand(D).FUitVolt := AV;
    end;
  end;

begin
  if P = nil then Exit;
  // onderdelen, rails en de belasting door de verbruikers op de rails
  NP := 0; NR := 0;
  G := 0;
  SetLength(Parts, 0);
  SetLength(Rails, 0);
  for i := 0 to P.ControlCount - 1 do
  begin
    C := P.Controls[i];
    if not C.Visible then Continue;
    if C is TjanRail then
    begin
      SetLength(Rails, NR + 1);
      Rails[NR] := TjanRail(C);
      Inc(NR);
    end
    else if (C is TjanVoedingsDeel) and (TjanVoedingsDeel(C).PinCount = 0) then
      Continue   // magneet, kompas, veldplaat: niet in de kring
    else if C is TjanVoedingsDeel then
    begin
      SetLength(Parts, NP + 1);
      Parts[NP] := TjanVoedingsDeel(C);
      Inc(NP);
    end
    else
      G := G + LoadAmps12(C) / BronMaxVolt;
  end;

  // knooppunten: klemmen (PinCount per onderdeel) en rails, samengevoegd door draden
  SetLength(PinBase, NP + 1);
  NK := 0;
  for k := 0 to NP - 1 do
  begin
    PinBase[k] := NK;
    NK := NK + Parts[k].PinCount;
  end;
  PinBase[NP] := NK;
  // logische uitgangen die een klem voeden: het eind van de draad dat geen
  // klem of rail is (draden van dezelfde uitgang delen één knooppunt)
  NJ := 0;
  NL := 0;
  SetLength(LogPt, 0); SetLength(LogHoog, 0); SetLength(LogRail, 0); SetLength(LogRelais, 0);
  for i := 0 to P.ControlCount - 1 do
    if (P.Controls[i] is TjanConnector) and P.Controls[i].Visible and
       TjanConnector(P.Controls[i]).FLogicBron then
    begin
      Con := TjanConnector(P.Controls[i]);
      Con.EndCenters(Pa, Pb);
      A := ItemAt(Pa);
      B := ItemAt(Pb);
      if (A >= 0) = (B >= 0) then Continue;
      if A >= 0 then Pa := Pb;
      j := ItemAt(Pa);   // al een knooppunt van een andere draad?
      if j >= NK + NR then
      begin
        if Con.Power then LogHoog[j - NK - NR] := True;
        Continue;
      end;
      SetLength(LogPt, NL + 1); SetLength(LogHoog, NL + 1);
      SetLength(LogRail, NL + 1); SetLength(LogRelais, NL + 1);
      LogPt[NL] := Pa;
      LogHoog[NL] := Con.Power;
      LogRail[NL] := -1;
      RlC := RelaisContactOp(P, Pa);
      LogRelais[NL] := RlC <> nil;
      if RlC <> nil then
      begin
        RlR := SchakelPlusRail(RlC);
        for k := 0 to NR - 1 do
          if Rails[k] = RlR then LogRail[NL] := NK + k;
      end;
      Inc(NL);
    end;
  // Knooppunt op een ingang zonder klem. Een poort, teller of display is geen
  // onderdeel van de voedingskring: een draad van een klem naar zo een ingang
  // eindigt "los". Komen daar twee of meer zulke draden samen (bijvoorbeeld
  // twee schakelaars parallel op een ingang), dan is dat punt een knooppunt,
  // zoals in een echte schakeling. Zonder dit knooppunt las elke draad alleen
  // de spanning van zijn eigen klem en ging de ingang flikkeren.
  SetLength(KnPt, 0); SetLength(KnIn, 0); SetLength(LosPt, 0); SetLength(LosIn, 0);
  for i := 0 to P.ControlCount - 1 do
    if (P.Controls[i] is TjanConnector) and P.Controls[i].Visible then
    begin
      Con := TjanConnector(P.Controls[i]);
      Con.EndCenters(Pa, Pb);
      A := ItemAt(Pa);
      B := ItemAt(Pb);
      if (A >= 0) = (B >= 0) then Continue;
      if A >= 0 then Pa := Pb   // Pa = het eind dat op geen klem of rail ligt
      else A := B;              // A = het eind dat er wel op ligt
      // begint op een logische uitgang die ook een klem voedt: een gewone
      // signaaldraad, die hoort niet in de voedingskring
      if A >= NK + NR then Continue;
      // voedingsdraad (rail -> voedingsbolletje): geen signaal, zie Connect
      if (A >= NK) and PowerDotAt(P, Pa) then Continue;
      SetLength(LosPt, Length(LosPt) + 1);
      LosPt[High(LosPt)] := Pa;
    end;
  // Een eind dat met de hand gelegd is (het begin van een draad springt niet
  // vanzelf op het vierkantje) ligt soms enkele pixels naast de ingang. Voor
  // einden met een buur dichtbij telt daarom het midden van de ingang.
  SetLength(LosIn, Length(LosPt));
  for i := 0 to High(LosPt) do LosIn[i] := LosPt[i];
  for i := 0 to High(LosPt) do
    for j := i + 1 to High(LosPt) do
      if (Abs(LosPt[i].X - LosPt[j].X) <= 2 * KnoopTol) and
         (Abs(LosPt[i].Y - LosPt[j].Y) <= 2 * KnoopTol) then
      begin
        LosIn[i] := IngangBij(P, LosPt[i]);
        LosIn[j] := IngangBij(P, LosPt[j]);
      end;
  for i := 0 to High(LosPt) do
  begin
    if ItemAt(LosPt[i]) >= 0 then Continue;   // hoort al bij een knooppunt
    for j := i + 1 to High(LosPt) do
      if NearPoint(LosPt[i], LosPt[j]) or NearPoint(LosIn[i], LosIn[j]) then
      begin
        SetLength(KnPt, NJ + 1); SetLength(KnIn, NJ + 1);
        KnPt[NJ] := LosPt[i];
        KnIn[NJ] := LosIn[i];
        Inc(NJ);
        Break;
      end;
  end;
  SetLength(Ouder, NK + NR + NL + NJ);
  for i := 0 to High(Ouder) do Ouder[i] := i;
  for i := 0 to P.ControlCount - 1 do
    if (P.Controls[i] is TjanConnector) and P.Controls[i].Visible then
    begin
      Con := TjanConnector(P.Controls[i]);
      Con.EndCenters(Pa, Pb);
      A := ItemAt(Pa);
      B := ItemAt(Pb);
      if (A >= 0) and (B >= 0) and not SignaalDraad(A, B) then Union(A, B);
    end;
  SetLength(NodeOf, Length(Ouder));
  for i := 0 to High(NodeOf) do NodeOf[i] := -1;
  N := 0;
  for i := 0 to High(Ouder) do
  begin
    j := Find(i);
    if NodeOf[j] < 0 then
    begin
      NodeOf[j] := N;
      Inc(N);
    end;
    NodeOf[i] := NodeOf[j];
  end;

  // de rail waar de verbruikers op staan: eerste + rail en eerste - rail
  PlusR := -1; Mass := -1;
  LoadItA := -1; LoadItB := -1; LoadG := 0;
  for k := 0 to NR - 1 do
    if Rails[k].Plus then
    begin
      if PlusR < 0 then
      begin
        PlusR := NodeOf[NK + k];
        LoadItA := NK + k;
      end;
    end
    else if Mass < 0 then
    begin
      Mass := NodeOf[NK + k];
      LoadItB := NK + k;
    end;

  // een weerstand die een knooppunt deelt met een LDR of NTC, zonder rail of
  // bron op dat knooppunt, vormt er een spanningsdeler mee
  for k := 0 to NP - 1 do
    if (Parts[k].ClassType = TjanWeerstand) then
    begin
      IsDeler := False;
      for A := 0 to 1 do
      begin
        DelerKnoop := PinNode(k, A);
        for j := 0 to NP - 1 do
          if (Parts[j] is TjanSensorR) and ((PinNode(j, 0) = DelerKnoop) or (PinNode(j, 1) = DelerKnoop)) then
          begin
            IsDeler := True;
            for i := 0 to NR - 1 do
              if NodeOf[NK + i] = DelerKnoop then IsDeler := False;
            for i := 0 to NP - 1 do
              if (Parts[i] is TjanBron) and ((PinNode(i, 0) = DelerKnoop) or (PinNode(i, 1) = DelerKnoop)) then
                IsDeler := False;
            if IsDeler then Break;
          end;
        if IsDeler then Break;
      end;
      TjanWeerstand(Parts[k]).Deler := IsDeler;
    end;

  SetLength(V, N);
  SetLength(NewVolt, NR);
  // een relais (schemasymbool) mag per berekening hoogstens een keer omschakelen
  for k := 0 to NP - 1 do
    if Parts[k] is TjanRelais2 then TjanRelais2(Parts[k]).Gewisseld := False;
  for Ronde := 1 to 40 do
  begin
    // takken
    SetLength(Tak, 0);
    SetLength(Gest, 0);
    for k := 0 to NP - 1 do
    begin
      if Parts[k] is TjanBron then
        AddTakE(PinNode(k, 0), PinNode(k, 1), 1 / NietNul(TjanBron(Parts[k]).Ri),
          TjanBron(Parts[k]).Emk, Parts[k])
      else if Parts[k] is TjanLed2 then
      begin
        // boven de drempel: drempelspanning met een kleine weerstand
        if TjanLed2(Parts[k]).FGeleidt and not TjanLed2(Parts[k]).Doorgebrand then
          AddTakE(PinNode(k, 0), PinNode(k, 1), 1 / TjanLed2(Parts[k]).Rd, TjanLed2(Parts[k]).Drempel, Parts[k]);
      end
      else if Parts[k] is TjanCondensator then
        // stap van de tijd (impliciete Euler): geleiding C/dt met als
        // bronspanning de spanning van de vorige stap
        AddTakE(PinNode(k, 0), PinNode(k, 1), TjanCondensator(Parts[k]).Farad / CondDt,
          TjanCondensator(Parts[k]).FU, Parts[k])
      else if Parts[k] is TjanZekering then
      begin
        if not TjanZekering(Parts[k]).Doorgebrand then
          AddTak(PinNode(k, 0), PinNode(k, 1), 1 / RKlein, Parts[k]);
      end
      else if Parts[k] is TjanAmpMeter then
        AddTak(PinNode(k, 0), PinNode(k, 1), 1 / RKlein, Parts[k])
      else if Parts[k] is TjanSpoel then
        // spoel: een kleine weerstand met de geïnduceerde spanning (+ aan klem 1)
        AddTakE(PinNode(k, 1), PinNode(k, 0), 1 / TjanSpoel(Parts[k]).Ohm, TjanSpoel(Parts[k]).Emf, Parts[k])
      else if Parts[k] is TjanWeerstand then
        AddTak(PinNode(k, 0), PinNode(k, 1), 1 / TjanWeerstand(Parts[k]).Ohm, Parts[k])
      else if Parts[k] is TjanPotmeter then
      begin
        // twee weerstanden: A tot de loper en de loper tot B
        AddTak(PinNode(k, 0), PinNode(k, 2), 1 / NietNul(TjanPotmeter(Parts[k]).OhmAL), Parts[k]);
        AddTak(PinNode(k, 2), PinNode(k, 1), 1 / NietNul(TjanPotmeter(Parts[k]).OhmLB), Parts[k]);
      end
      else if Parts[k] is TjanSensorR then
        AddTak(PinNode(k, 0), PinNode(k, 1), 1 / TjanSensorR(Parts[k]).Ohm, Parts[k])
      else if Parts[k] is TjanLamp2 then
        AddTak(PinNode(k, 0), PinNode(k, 1), 1 / TjanLamp2(Parts[k]).Ohm, Parts[k])
      else if Parts[k] is TjanPuls2 then
      begin
        if TjanPuls2(Parts[k]).Aan then
          AddTak(PinNode(k, 0), PinNode(k, 1), 1 / RKlein, Parts[k]);
      end
      else if Parts[k] is TjanDip2 then
      begin
        // dipschakelaar: de linkse klem naar elke uitgang die aan staat
        for j := 1 to 4 do
          if TjanDip2(Parts[k]).BitAan(j) then
            AddTak(PinNode(k, 0), PinNode(k, j), 1 / RKlein, Parts[k]);
      end
      else if Parts[k] is TjanRelaisModel then
      begin
        // open relais: de spoel is een weerstand, C naar het gesloten contact
        AddTak(PinNode(k, 0), PinNode(k, 1), 1 / TjanRelaisModel(Parts[k]).SpoelOhm, Parts[k]);
        if TjanRelaisModel(Parts[k]).MaakDicht then
          AddTak(PinNode(k, 2), PinNode(k, 3), 1 / RKlein, Parts[k])
        else if TjanRelaisModel(Parts[k]).VerbreekDicht then
          AddTak(PinNode(k, 2), PinNode(k, 4), 1 / RKlein, Parts[k]);
      end
      else if Parts[k] is TjanTransformator then
        with TjanTransformator(Parts[k]) do
        begin
          // transformator: n = N2 / N1 maal de koppeling (0 bij gelijkspanning).
          // Primaire: een kleine magnetiseringsstroom (bij gelijkspanning 40 ohm);
          // secundaire: n x U1 achter 1 ohm; de primaire stroom volgt n x I2.
          Hulp := Verhouding * Koppeling;
          AddTak(PinNode(k, 0), PinNode(k, 1), Koppeling * 0.001 + (1 - Koppeling) / 40, Parts[k]);
          AddTak(PinNode(k, 2), PinNode(k, 3), 1, Parts[k]);
          SetLength(Gest, Length(Gest) + 3);
          with Gest[High(Gest) - 2] do
          begin
            Van := PinNode(k, 3); Naar := PinNode(k, 2); P := PinNode(k, 0); M := PinNode(k, 1);
            G := Hulp; Off := 0;
          end;
          with Gest[High(Gest) - 1] do
          begin
            Van := PinNode(k, 0); Naar := PinNode(k, 1); P := PinNode(k, 0); M := PinNode(k, 1);
            G := Hulp * Hulp; Off := 0;
          end;
          with Gest[High(Gest)] do
          begin
            Van := PinNode(k, 0); Naar := PinNode(k, 1); P := PinNode(k, 2); M := PinNode(k, 3);
            G := -Hulp; Off := 0;
          end;
        end
      else if Parts[k] is TjanStappenmotor then
      begin
        // stappenmotor: vier spoelen van A, B, C, D naar de gemeenschappelijke klem
        for j := 0 to 3 do
          AddTak(PinNode(k, j), PinNode(k, 4), 1 / TjanStappenmotor(Parts[k]).SpoelOhm, Parts[k]);
      end
      else if Parts[k] is TjanServo then
      begin
        // servo: de motor tussen + en -, de ingang S met 1 megaohm naar -
        AddTak(PinNode(k, 0), PinNode(k, 1), 1 / TjanServo(Parts[k]).MotorOhm, Parts[k]);
        AddTak(PinNode(k, 2), PinNode(k, 1), 1 / 1000000, Parts[k]);
      end
      else if (Parts[k] is TjanSchakelaar2) and TjanSchakelaar2(Parts[k]).Wissel then
      begin
        // wisselschakelaar: het midden (klem 2) naar B (klem 1) of A (klem 0)
        if TjanSchakelaar2(Parts[k]).Aan then
          AddTak(PinNode(k, 2), PinNode(k, 1), 1 / RKlein, Parts[k])
        else
          AddTak(PinNode(k, 2), PinNode(k, 0), 1 / RKlein, Parts[k]);
      end
      else if Parts[k] is TjanSchakelaar2 then
      begin
        if TjanSchakelaar2(Parts[k]).Aan then
          AddTak(PinNode(k, 0), PinNode(k, 1), 1 / RKlein, Parts[k]);
      end
      else if (Parts[k] is TjanTransistor) and not TjanTransistor(Parts[k]).Doorgebrand then
      begin
        // NPN: B-E is een diode van B naar E; C-E verzadigd een kleine
        // spanning van C naar E, versterkend een gestuurde stroom van C naar E.
        // PNP: alles omgekeerd (E is de + kant).
        Tr := TjanTransistor(Parts[k]);
        NC := PinNode(k, 0); NB := PinNode(k, 1); NE := PinNode(k, 2);
        if Tr.FBeAan then
        begin
          if Tr.PNP then AddTakE(NE, NB, 1 / TrRbe, TrVbe, Parts[k])
          else AddTakE(NB, NE, 1 / TrRbe, TrVbe, Parts[k]);
          if Tr.FVerzadigd then
          begin
            if Tr.PNP then AddTakE(NE, NC, 1 / TrRce, TrVceSat, Parts[k])
            else AddTakE(NC, NE, 1 / TrRce, TrVceSat, Parts[k]);
          end
          else
          begin
            SetLength(Gest, Length(Gest) + 1);
            with Gest[High(Gest)] do
            begin
              G := Tr.Beta / TrRbe;
              Off := TrVbe;
              if Tr.PNP then
              begin
                Van := NE; Naar := NC; P := NE; M := NB;
              end
              else
              begin
                Van := NC; Naar := NE; P := NB; M := NE;
              end;
            end;
          end;
        end;
      end;
    end;

    // logische uitgangen: een bron van 5 V (hoog) of 0 V (laag) t.o.v. de
    // - rail, met een kleine inwendige weerstand; een relaiscontact (dicht)
    // verbindt met de rail van R1
    for i := 0 to NL - 1 do
      if LogRelais[i] then
      begin
        if LogHoog[i] and (LogRail[i] >= 0) then
          AddTak(NodeOf[NK + NR + i], NodeOf[LogRail[i]], 1 / RKlein, nil);
      end
      else if Mass >= 0 then
      begin
        if LogHoog[i] then
          AddTakE(NodeOf[NK + NR + i], Mass, 1 / PoortUitOhm, LogicLampVolt, nil)
        else
          AddTak(NodeOf[NK + NR + i], Mass, 1 / PoortUitOhm, nil);
      end;

    // samenhangende delen (alle takken, ook de belasting); per deel is de
    // - klem van de eerste bron de massa (0 V)
    SetLength(Ouder, N);
    for i := 0 to N - 1 do Ouder[i] := i;
    for k := 0 to High(Tak) do Union(Tak[k].A, Tak[k].B);
    for k := 0 to High(Gest) do Union(Gest[k].Van, Gest[k].Naar);
    // verbruikers: tussen de + rail en de - rail; zonder - rail naar de
    // massa van het deel van de + rail
    j := Mass;
    if (PlusR >= 0) and (j < 0) then
      for k := 0 to NP - 1 do
        if (Parts[k] is TjanBron) and (Find(PinNode(k, 0)) = Find(PlusR)) then
        begin
          j := PinNode(k, 1);
          if Mass < 0 then LoadItB := PinBase[k] + 1;
          Break;
        end;
    LoadG := 0;
    if (PlusR >= 0) and (j >= 0) and (j <> PlusR) and (G > 0) then
    begin
      LoadG := G;
      AddTak(PlusR, j, G, nil);
      Union(PlusR, j);
    end;
    SetLength(CompGnd, N);
    for i := 0 to N - 1 do CompGnd[i] := -1;
    for k := 0 to NP - 1 do
      if Parts[k] is TjanBron then
      begin
        i := Find(PinNode(k, 1));
        if CompGnd[i] < 0 then CompGnd[i] := PinNode(k, 1);
      end;
    // de secundaire kring van een transformator is gescheiden: eigen massa
    for k := 0 to NP - 1 do
      if Parts[k] is TjanTransformator then
      begin
        i := Find(PinNode(k, 3));
        if CompGnd[i] < 0 then CompGnd[i] := PinNode(k, 3);
      end;

    // matrix opbouwen
    SetLength(Gm, N, N);
    SetLength(Iv, N);
    for i := 0 to N - 1 do
    begin
      for j := 0 to N - 1 do Gm[i][j] := 0;
      Gm[i][i] := GMin;
      Iv[i] := 0;
      if CompGnd[Find(i)] = i then Gm[i][i] := Gm[i][i] + 1;   // massa
    end;
    for k := 0 to High(Tak) do
    begin
      A := Tak[k].A; B := Tak[k].B;
      if A = B then Continue;
      Gm[A][A] := Gm[A][A] + Tak[k].G;
      Gm[B][B] := Gm[B][B] + Tak[k].G;
      Gm[A][B] := Gm[A][B] - Tak[k].G;
      Gm[B][A] := Gm[B][A] - Tak[k].G;
      if Tak[k].E <> 0 then
      begin
        // bronstroom E/Ri van de - klem naar de + klem
        F := Tak[k].E * Tak[k].G;
        Iv[A] := Iv[A] + F;
        Iv[B] := Iv[B] - F;
      end;
    end;
    // gestuurde stroombronnen: de stroom verlaat Van en komt in Naar
    for k := 0 to High(Gest) do
      with Gest[k] do
      begin
        Gm[Van][P] := Gm[Van][P] + G;
        Gm[Van][M] := Gm[Van][M] - G;
        Iv[Van] := Iv[Van] + G * Off;
        Gm[Naar][P] := Gm[Naar][P] - G;
        Gm[Naar][M] := Gm[Naar][M] + G;
        Iv[Naar] := Iv[Naar] - G * Off;
      end;
    Solve;

    // te veel stroom door een zekering: ze smelt, opnieuw rekenen
    Smelt := False;
    for k := 0 to NP - 1 do
      if (Parts[k] is TjanZekering) and not TjanZekering(Parts[k]).Doorgebrand then
      begin
        Z := TjanZekering(Parts[k]);
        Amp := Abs(V[PinNode(k, 0)] - V[PinNode(k, 1)]) / RKlein;
        if Amp > Z.NominaalA + 0.000001 then
        begin
          Z.Doorgebrand := True;
          Smelt := True;
        end;
      end;
    // led: geleidt ze (niet)? Klopt de toestand niet, dan opnieuw rekenen;
    // te veel stroom: kapot
    for k := 0 to NP - 1 do
      if (Parts[k] is TjanLed2) and not TjanLed2(Parts[k]).Doorgebrand then
        with TjanLed2(Parts[k]) do
        begin
          U := V[PinNode(k, 0)] - V[PinNode(k, 1)];
          if FGeleidt then
          begin
            Amp := (U - Drempel) / Rd;
            if Amp < 0 then
            begin
              FGeleidt := False;
              Smelt := True;
            end
            else if Amp > MaxA + 0.000001 then
            begin
              FGeleidt := False;
              Doorgebrand := True;
              Smelt := True;
            end;
          end
          else if U > Drempel + 0.000001 then
          begin
            FGeleidt := True;
            Smelt := True;
          end;
        end;
    // transistor: klopt de toestand (spert, versterkt, verzadigd)? Zo niet,
    // opnieuw rekenen; te veel stroom: kapot
    for k := 0 to NP - 1 do
      if (Parts[k] is TjanTransistor) and not TjanTransistor(Parts[k]).Doorgebrand then
      begin
        Tr := TjanTransistor(Parts[k]);
        if Tr.PNP then Hulp := -1 else Hulp := 1;
        NC := PinNode(k, 0); NB := PinNode(k, 1); NE := PinNode(k, 2);
        U := Hulp * (V[NB] - V[NE]);      // Ube
        F := Hulp * (V[NC] - V[NE]);      // Uce
        if Tr.FBeAan then
        begin
          Amp := (U - TrVbe) / TrRbe;     // basisstroom
          if Amp < 0 then
          begin
            Tr.FBeAan := False;
            Tr.FVerzadigd := False;
            Smelt := True;
          end
          else if Tr.FVerzadigd then
          begin
            E := (F - TrVceSat) / TrRce;  // collectorstroom
            if (Amp > TrMaxIb) or (E > TrMaxIc) then
            begin
              Tr.FDoorgebrand := True; Tr.FBeAan := False; Tr.FVerzadigd := False;
              Smelt := True;
            end
            else if E > Tr.Beta * Amp + 0.000001 then
            begin
              // de basisstroom is te klein om zoveel door te laten: versterkt
              Tr.FVerzadigd := False;
              Smelt := True;
            end;
          end
          else if Amp > TrMaxIb then
          begin
            Tr.FDoorgebrand := True; Tr.FBeAan := False;
            Smelt := True;
          end
          else if F < TrVceSat - 0.000001 then
          begin
            // de kring laat niet beta x Ib door: verzadigd
            Tr.FVerzadigd := True;
            Smelt := True;
          end
          else if Tr.Beta * Amp > TrMaxIc then
          begin
            // er gaat echt beta x Ib door de collector: te veel
            Tr.FDoorgebrand := True; Tr.FBeAan := False;
            Smelt := True;
          end;
        end
        else if U > TrVbe + 0.000001 then
        begin
          // eerst verzadigd proberen: een stroombron in een collector die (nog)
          // nergens heen kan, geeft onzinnige spanningen (en kapotte leds)
          Tr.FBeAan := True;
          Tr.FVerzadigd := True;
          Smelt := True;
        end;
      end;
    // relais (schemasymbool): trekt aan vanaf 35 mA, valt af onder 20 mA
    for k := 0 to NP - 1 do
      if (Parts[k] is TjanRelais2) and not TjanRelais2(Parts[k]).Gewisseld then
        with TjanRelais2(Parts[k]) do
        begin
          Amp := Abs(V[PinNode(k, 0)] - V[PinNode(k, 1)]) / SpoelOhm;
          if (not Aan and (Amp >= 0.035)) or (Aan and (Amp < 0.020)) then
          begin
            Aan := not Aan;
            Gewisseld := True;
            Smelt := True;
            Invalidate;
          end;
        end;
    if not Smelt then Break;
  end;

  // resultaten: klemspanningen en stromen van de onderdelen
  for k := 0 to NP - 1 do
  begin
    for j := 0 to Parts[k].PinCount - 1 do
      if j <= High(Parts[k].FPinV) then
        SetPinV(Parts[k], j, V[PinNode(k, j)]);
    A := PinNode(k, 0); B := PinNode(k, 1);
    U := V[A] - V[B];
    if Parts[k] is TjanScoop then
      TjanScoop(Parts[k]).Meet(U);
    if Parts[k] is TjanBron then
    begin
      Gs := 1 / NietNul(TjanBron(Parts[k]).Ri);
      E := TjanBron(Parts[k]).Emk;
      Amp := (E - U) * Gs;
      if Abs(Amp) < 0.00001 then Amp := 0;
      if (Abs(TjanBron(Parts[k]).FKlem - U) > 0.0005) or
         (Abs(TjanBron(Parts[k]).FStroom - Amp) > 0.00005) then
      begin
        TjanBron(Parts[k]).FKlem := U;
        TjanBron(Parts[k]).FStroom := Amp;
        if AInval then Parts[k].Invalidate;
      end;
    end
    else if (Parts[k] is TjanZekering) and TjanZekering(Parts[k]).Doorgebrand then
      SetStroom(Parts[k], 0)
    else if (Parts[k] is TjanZekering) or (Parts[k] is TjanAmpMeter) then
      SetStroom(Parts[k], U / RKlein)
    else if Parts[k] is TjanSpoel then
      SetStroom(Parts[k], (U + TjanSpoel(Parts[k]).Emf) / TjanSpoel(Parts[k]).Ohm)
    else if Parts[k] is TjanWeerstand then
      SetStroom(Parts[k], U / TjanWeerstand(Parts[k]).Ohm)
    else if Parts[k] is TjanPotmeter then
      with TjanPotmeter(Parts[k]) do
      begin
        Amp := (V[PinNode(k, 0)] - V[PinNode(k, 2)]) / NietNul(OhmAL);
        Hulp := (V[PinNode(k, 2)] - V[PinNode(k, 1)]) / NietNul(OhmLB);
        if (Abs(FIa - Amp) > 0.00005) or (Abs(FIb - Hulp) > 0.00005) then
        begin
          FIa := Amp;
          FIb := Hulp;
          if AInval then Invalidate;
        end;
        SetStroom(Parts[k], Amp);
      end
    else if Parts[k] is TjanSensorR then
      SetStroom(Parts[k], U / TjanSensorR(Parts[k]).Ohm)
    else if Parts[k] is TjanLamp2 then
      SetStroom(Parts[k], U / TjanLamp2(Parts[k]).Ohm)
    else if Parts[k] is TjanPuls2 then
    begin
      if TjanPuls2(Parts[k]).Aan then SetStroom(Parts[k], U / RKlein) else SetStroom(Parts[k], 0);
    end
    else if Parts[k] is TjanDip2 then
      with TjanDip2(Parts[k]) do
      begin
        Hulp := 0;
        for j := 1 to 4 do
        begin
          if BitAan(j) then FIs[j] := (V[PinNode(k, 0)] - V[PinNode(k, j)]) / RKlein else FIs[j] := 0;
          Hulp := Hulp + FIs[j];
        end;
        SetStroom(Parts[k], Hulp);
      end
    else if Parts[k] is TjanRelaisModel then
      with TjanRelaisModel(Parts[k]) do
      begin
        SetStroom(Parts[k], (V[PinNode(k, 0)] - V[PinNode(k, 1)]) / SpoelOhm);
        if MaakDicht then FIc := (V[PinNode(k, 2)] - V[PinNode(k, 3)]) / RKlein
        else if VerbreekDicht then FIc := (V[PinNode(k, 2)] - V[PinNode(k, 4)]) / RKlein
        else FIc := 0;
      end
    else if Parts[k] is TjanTransformator then
      with TjanTransformator(Parts[k]) do
      begin
        Hulp := Verhouding * Koppeling;
        F := V[PinNode(k, 2)] - V[PinNode(k, 3)];
        Amp := Hulp * U - F;   // secundaire stroom (uit klem 2)
        SetStroom(Parts[k], U * (Koppeling * 0.001 + (1 - Koppeling) / 40) + Hulp * Amp);
        Meet(U, F, Parts[k].FAmp, Amp);
      end
    else if Parts[k] is TjanServo then
      SetStroom(Parts[k], U / TjanServo(Parts[k]).MotorOhm)
    else if Parts[k] is TjanStappenmotor then
    begin
      Hulp := 0;
      for j := 0 to 3 do
        Hulp := Hulp + Abs(V[PinNode(k, j)] - V[PinNode(k, 4)]) / TjanStappenmotor(Parts[k]).SpoelOhm;
      SetStroom(Parts[k], Hulp);
    end
    else if (Parts[k] is TjanSchakelaar2) and TjanSchakelaar2(Parts[k]).Wissel then
    begin
      // stroom van het midden naar het gekozen contact
      if TjanSchakelaar2(Parts[k]).Aan then j := 1 else j := 0;
      SetStroom(Parts[k], (V[PinNode(k, 2)] - V[PinNode(k, j)]) / RKlein);
    end
    else if (Parts[k] is TjanSchakelaar2) and TjanSchakelaar2(Parts[k]).Aan then
      SetStroom(Parts[k], U / RKlein)
    else if Parts[k] is TjanLed2 then
    begin
      if TjanLed2(Parts[k]).FGeleidt and not TjanLed2(Parts[k]).Doorgebrand then
        Amp := (U - TjanLed2(Parts[k]).Drempel) / TjanLed2(Parts[k]).Rd
      else
        Amp := 0;
      if Amp < 0 then Amp := 0;
      SetStroom(Parts[k], Amp);
    end
    else if Parts[k] is TjanCondensator then
    begin
      Hulp := TjanCondensator(Parts[k]).FU;
      SetStroom(Parts[k], (U - Hulp) * TjanCondensator(Parts[k]).Farad / CondDt);
      // de tijd loopt verder: de nieuwe spanning onthouden
      if CondStap and (Abs(Hulp - U) > 0.00001) then
      begin
        if Abs(Hulp - U) > 0.005 then Parts[k].Invalidate;
        TjanCondensator(Parts[k]).FU := U;
      end;
    end
    else if Parts[k] is TjanTransistor then
    begin
      Tr := TjanTransistor(Parts[k]);
      Amp := 0; Hulp := 0;
      if Tr.FBeAan and not Tr.Doorgebrand then
      begin
        if Tr.PNP then F := -1 else F := 1;
        NC := PinNode(k, 0); NB := PinNode(k, 1); NE := PinNode(k, 2);
        Amp := (F * (V[NB] - V[NE]) - TrVbe) / TrRbe;
        if Amp < 0 then Amp := 0;
        if Tr.FVerzadigd then Hulp := (F * (V[NC] - V[NE]) - TrVceSat) / TrRce
        else Hulp := Tr.Beta * Amp;
        if Hulp < 0 then Hulp := 0;
      end;
      if (Abs(Tr.FIb - Amp) > 0.000005) or (Abs(Tr.FIc - Hulp) > 0.00005) then
      begin
        Tr.FIb := Amp;
        Tr.FIc := Hulp;
        if AInval then Tr.Invalidate;
      end;
      SetStroom(Parts[k], Hulp);
    end
    else
      SetStroom(Parts[k], 0);
  end;

  // uitgangen van een echt Arduino-board: de pin volgt de lamp
  if BoardVerbonden then
    for k := 0 to NP - 1 do
      if Parts[k] is TjanBoardUit then TjanBoardUit(Parts[k]).Stuur;

  // zoemers met geluid: zoemen via de luidsprekers zolang er een aan staat
  ZoemersBijwerken(P);

  // de + rails: spanning t.o.v. de - rail (zonder - rail: t.o.v. de massa)
  for k := 0 to NR - 1 do
  begin
    NewVolt[k] := 0;
    if not Rails[k].Plus then Continue;
    i := NodeOf[NK + k];
    if Mass >= 0 then Hulp := V[Mass] else Hulp := 0;
    U := V[i] - Hulp;
    if U < 0.0005 then U := 0;
    NewVolt[k] := U;
  end;

  // nieuwe spanning op de rails
  Changed := False;
  for k := 0 to NR - 1 do
    if Abs(Rails[k].FCalcVolt - NewVolt[k]) > 0.0005 then
    begin
      Rails[k].FCalcVolt := NewVolt[k];
      Changed := True;
      if AInval then
      begin
        Rails[k].UpdateHintText;
        Rails[k].Invalidate;
      end;
    end;
  if Changed and AInval then
    P.Invalidate;   // kleur van de stekkers

  // stroom per draad, voor de elektronen (alleen als een bron ze toont).
  // Elke klem/rail neemt een stroom uit de draden (de stroom door het
  // onderdeel); per knooppunt volgt de stroom in de draden uit de
  // stroomwet van Kirchhoff, over een opspannende boom van de draden.
  Toon := False;
  for k := 0 to NP - 1 do
    if (Parts[k] is TjanBron) and TjanBron(Parts[k]).Elektronen then Toon := True;
  NI := NK + NR + NL + NJ;
  SetLength(Draad, 0); SetLength(DrA, 0); SetLength(DrB, 0);
  ND := 0;
  for i := 0 to P.ControlCount - 1 do
    if (P.Controls[i] is TjanConnector) then
    begin
      Con := TjanConnector(P.Controls[i]);
      A := -1; B := -1;
      if Toon and Con.Visible then
      begin
        Con.EndCenters(Pa, Pb);
        A := ItemAt(Pa);
        B := ItemAt(Pb);
      end;
      Con.FStroomNieuw := 0;
      if (A < 0) or (B < 0) or (A = B) or SignaalDraad(A, B) then
      begin
        Continue;
      end;
      SetLength(Draad, ND + 1); SetLength(DrA, ND + 1); SetLength(DrB, ND + 1);
      Draad[ND] := Con; DrA[ND] := A; DrB[ND] := B;
      Inc(ND);
    end;
  // spanning over de verbruikers op de rails
  U := 0;
  if (LoadG > 0) and (LoadItA >= 0) and (LoadItB >= 0) then
    U := V[NodeOf[LoadItA]] - V[NodeOf[LoadItB]];
  if ND = 0 then
  begin
    ElektronenRails(P, U, Toon);
    Exit;
  end;
  SetLength(Vraag, NI);
  for i := 0 to NI - 1 do Vraag[i] := 0;
  for k := 0 to NP - 1 do
  begin
    if Parts[k] is TjanBron then Amp := -TjanBron(Parts[k]).FStroom else Amp := Parts[k].FAmp;
    Vraag[PinBase[k]] := Amp;
    Vraag[PinBase[k] + 1] := -Amp;
    if Parts[k] is TjanPotmeter then
      with TjanPotmeter(Parts[k]) do
      begin
        // A neemt FIa uit de draden, B geeft FIb terug, de loper het verschil
        Vraag[PinBase[k]] := FIa;
        Vraag[PinBase[k] + 1] := -FIb;
        Vraag[PinBase[k] + 2] := FIb - FIa;
      end;
    if Parts[k] is TjanDip2 then
      with TjanDip2(Parts[k]) do
      begin
        // de linkse klem neemt alles, elke uitgang geeft zijn deel terug
        Vraag[PinBase[k]] := Amp;
        for j := 1 to 4 do Vraag[PinBase[k] + j] := -FIs[j];
      end;
    if Parts[k] is TjanTransformator then
    begin
      // de secundaire stroom komt uit klem 2 en gaat terug in klem 3
      Vraag[PinBase[k] + 2] := -TjanTransformator(Parts[k]).I2;
      Vraag[PinBase[k] + 3] := TjanTransformator(Parts[k]).I2;
    end;
    if Parts[k] is TjanRelaisModel then
      with TjanRelaisModel(Parts[k]) do
      begin
        // C neemt de contactstroom uit de draden, het gesloten contact geeft hem terug
        Vraag[PinBase[k] + 2] := FIc;
        if MaakDicht then Vraag[PinBase[k] + 3] := -FIc
        else if VerbreekDicht then Vraag[PinBase[k] + 4] := -FIc;
      end;
    if Parts[k] is TjanStappenmotor then
    begin
      // elke spoel neemt haar stroom uit de draden, de gemeenschappelijke klem geeft de som terug
      Hulp := 0;
      for j := 0 to 3 do
      begin
        F := (V[PinNode(k, j)] - V[PinNode(k, 4)]) / TjanStappenmotor(Parts[k]).SpoelOhm;
        Vraag[PinBase[k] + j] := F;
        Hulp := Hulp + F;
      end;
      Vraag[PinBase[k] + 4] := -Hulp;
    end;
    if Parts[k] is TjanServo then
    begin
      // + en S nemen stroom uit de draden, - geeft de som terug
      F := (V[PinNode(k, 2)] - V[PinNode(k, 1)]) / 1000000;
      Vraag[PinBase[k] + 2] := F;
      Vraag[PinBase[k] + 1] := -Amp - F;
    end;
    if (Parts[k] is TjanSchakelaar2) and TjanSchakelaar2(Parts[k]).Wissel then
    begin
      // het midden neemt de stroom uit de draden, het gekozen contact geeft
      // hem terug, het andere contact doet niets
      Vraag[PinBase[k]] := 0;
      Vraag[PinBase[k] + 1] := 0;
      Vraag[PinBase[k] + 2] := Amp;
      if TjanSchakelaar2(Parts[k]).Aan then
        Vraag[PinBase[k] + 1] := -Amp
      else
        Vraag[PinBase[k]] := -Amp;
    end;
    if Parts[k] is TjanTransistor then
      with TjanTransistor(Parts[k]) do
      begin
        // NPN: C en B nemen stroom uit de draden, E geeft de som terug
        if PNP then F := -1 else F := 1;
        Vraag[PinBase[k]] := F * FIc;
        Vraag[PinBase[k] + 1] := F * FIb;
        Vraag[PinBase[k] + 2] := -F * (FIb + FIc);
      end;
  end;
  if (LoadG > 0) and (LoadItA >= 0) and (LoadItB >= 0) then
  begin
    Amp := LoadG * (V[NodeOf[LoadItA]] - V[NodeOf[LoadItB]]);
    Vraag[LoadItA] := Vraag[LoadItA] + Amp;
    Vraag[LoadItB] := Vraag[LoadItB] - Amp;
  end;
  // logische uitgangen: de stroom die de uitgang de draad in stuurt, komt van
  // de - rail (de niet getekende voeding van de poort) of, bij een relais-
  // contact, van de rail van R1
  for i := 0 to NL - 1 do
    if LogRelais[i] then
    begin
      if LogHoog[i] and (LogRail[i] >= 0) then
      begin
        Amp := (V[NodeOf[LogRail[i]]] - V[NodeOf[NK + NR + i]]) / RKlein;
        Vraag[NK + NR + i] := Vraag[NK + NR + i] - Amp;
        Vraag[LogRail[i]] := Vraag[LogRail[i]] + Amp;
      end;
    end
    else if (Mass >= 0) and (LoadItB >= 0) then
    begin
      if LogHoog[i] then E := LogicLampVolt else E := 0;
      Amp := (E - (V[NodeOf[NK + NR + i]] - V[Mass])) / PoortUitOhm;
      Vraag[NK + NR + i] := Vraag[NK + NR + i] - Amp;
      Vraag[LoadItB] := Vraag[LoadItB] + Amp;
    end;
  // buren per klem/rail (lijst met beginpunten)
  SetLength(BuurStart, NI + 1);
  for i := 0 to NI do BuurStart[i] := 0;
  for m := 0 to ND - 1 do
  begin
    Inc(BuurStart[DrA[m] + 1]);
    Inc(BuurStart[DrB[m] + 1]);
  end;
  for i := 1 to NI do BuurStart[i] := BuurStart[i] + BuurStart[i - 1];
  SetLength(Buur, 2 * ND); SetLength(BuurDraad, 2 * ND);
  SetLength(Volg, NI);
  for i := 0 to NI - 1 do Volg[i] := BuurStart[i];
  for m := 0 to ND - 1 do
  begin
    Buur[Volg[DrA[m]]] := DrB[m]; BuurDraad[Volg[DrA[m]]] := m; Inc(Volg[DrA[m]]);
    Buur[Volg[DrB[m]]] := DrA[m]; BuurDraad[Volg[DrB[m]]] := m; Inc(Volg[DrB[m]]);
  end;
  // breedte-eerst door elk deel; Volg wordt de bezoekvolgorde
  SetLength(Gezien, NI); SetLength(OuderIt, NI); SetLength(OuderDraad, NI);
  for i := 0 to NI - 1 do
  begin
    Gezien[i] := False; OuderIt[i] := -1; OuderDraad[i] := -1;
  end;
  Staart := 0;
  for i := 0 to NI - 1 do
    if not Gezien[i] then
    begin
      Gezien[i] := True;
      Kop := Staart;
      Volg[Staart] := i; Inc(Staart);
      while Kop < Staart do
      begin
        A := Volg[Kop]; Inc(Kop);
        for j := BuurStart[A] to BuurStart[A + 1] - 1 do
          if not Gezien[Buur[j]] then
          begin
            B := Buur[j];
            Gezien[B] := True;
            OuderIt[B] := A;
            OuderDraad[B] := BuurDraad[j];
            Volg[Staart] := B; Inc(Staart);
          end;
      end;
    end;
  // van de bladeren naar de wortel: de stroom in de draad naar een klem is
  // alles wat die klem en alles daarachter uit de draden neemt
  SetLength(Sub, NI);
  for i := 0 to NI - 1 do Sub[i] := Vraag[i];
  SetLength(Gezien, ND);
  for m := 0 to ND - 1 do Gezien[m] := False;
  for k := NI - 1 downto 0 do
  begin
    B := Volg[k];
    A := OuderIt[B];
    if A < 0 then Continue;
    m := OuderDraad[B];
    Gezien[m] := True;
    // stroom van A naar B door draad m
    if DrA[m] = A then Draad[m].FStroomNieuw := Sub[B] else Draad[m].FStroomNieuw := -Sub[B];
    Sub[A] := Sub[A] + Sub[B];
  end;
  for m := 0 to ND - 1 do
    if not Gezien[m] then Draad[m].FStroomNieuw := 0;
  ElektronenRails(P, U, Toon);
end;

// spanning op klem APin van voedingsonderdeel D (voor een draad die daar begint)
function VoedingsPinVolt(D: TjanVoedingsDeel; APin: Integer): Double;
begin
  if (APin >= 0) and (APin <= High(D.FPinV)) and (APin < D.PinCount) then
    Result := D.FPinV[APin]
  else
    Result := 0;
end;

// regel in het paneelbestand voor bron, zekering of milliampèremeter
function VoedingFileLine(C: TControl): string;
begin
  if C is TjanWisselbron then
    Result := Format('TjanWisselbron;%d;%d;%d;%d;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width,
      Round(TjanBron(C).Volt * 10), TjanBron(C).RiIdx, Ord(TjanBron(C).Elektronen), TjanWisselbron(C).FreqIdx])
  else if C is TjanBron then
    Result := Format('TjanBron;%d;%d;%d;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width,
      Round(TjanBron(C).Volt * 10), TjanBron(C).RiIdx, Ord(TjanBron(C).Elektronen)])
  else if C is TjanZekering then
    Result := Format('TjanZekering;%d;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width,
      TjanZekering(C).NomIdx])
  else if C is TjanRelais2 then
    Result := Format('TjanRelais2;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width])
  else if C is TjanRelaisModel then
    Result := Format('TjanRelaisModel;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width])
  else if C is TjanIJzer then
    Result := Format('TjanIJzer;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width])
  else if C is TjanZoemer2 then
    Result := Format('TjanZoemer2;%d;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width, Ord(TjanZoemer2(C).Geluid)])
  else if C is TjanVentilator then
    Result := Format('TjanVentilator;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width])
  else if C is TjanStappenmotor then
    Result := Format('TjanStappenmotor;%d;%d;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width,
      TjanStappenmotor(C).StapIdx, TjanStappenmotor(C).HalveStappen])
  else if C is TjanServo then
    Result := Format('TjanServo;%d;%d;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width,
      TjanServo(C).Pin, Round(TjanServo(C).Hoek)])
  else if C is TjanTransformator then
    Result := Format('TjanTransformator;%d;%d;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width,
      TjanTransformator(C).N1Idx, TjanTransformator(C).N2Idx])
  else if C is TjanDraaimagneet then
    Result := Format('TjanDraaimagneet;%d;%d;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width,
      TjanDraaimagneet(C).ToerIdx, Ord(TjanDraaimagneet(C).Draait)])
  else if C is TjanNulmeter then
    Result := Format('TjanNulmeter;%d;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width, TjanNulmeter(C).BereikIdx])
  else if C is TjanElektromotor then
    Result := Format('TjanElektromotor;%d;%d;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width,
      Ord(TjanElektromotor(C).Omgekeerd), Ord(TjanElektromotor(C).GeenCollector)])
  else if C is TjanSchommel then
    Result := Format('TjanSchommel;%d;%d;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width,
      Ord(TjanSchommel(C).Omgekeerd), Ord(TjanSchommel(C).Sterk)])
  else if C is TjanSpoel then
    Result := Format('TjanSpoel;%d;%d;%d;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width,
      TjanSpoel(C).WindIdx, Ord(TjanSpoel(C).Kern), Ord(TjanSpoel(C).Omgekeerd)])
  else if C is TjanWeerstand then
    Result := Format('TjanWeerstand;%d;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width,
      TjanWeerstand(C).Soort])
  else if C is TjanBoardUit then
    Result := Format('TjanBoardUit;%d;%d;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width, TjanBoardUit(C).Pin,
      Ord(TjanBoardUit(C).Kleur)])
  else if C is TjanLamp2 then
    Result := Format('TjanLamp2;%d;%d;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width,
      TjanLamp2(C).Soort, Ord(TjanLamp2(C).Kleur)])
  else if C is TjanPuls2 then
    Result := Format('TjanPuls2;%d;%d;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width, TjanPuls2(C).Interval, Ord(TjanPuls2(C).Loopt)])
  else if C is TjanMagneet then
    Result := Format('TjanMagneet;%d;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width, Ord(TjanMagneet(C).Omgekeerd)])
  else if C is TjanKompas then
    Result := Format('TjanKompas;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width])
  else if C is TjanVeldplaat then
    Result := Format('TjanVeldplaat;%d;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width, TjanVeldplaat(C).Maat])
  else if C is TjanDip2 then
    Result := Format('TjanDip2;%d;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width, TjanDip2(C).Waarde])
  else if C is TjanBoardIn then
    Result := Format('TjanBoardIn;%d;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width, TjanBoardIn(C).Pin])
  else if C is TjanWissel2 then
    Result := Format('TjanWissel2;%d;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width,
      Ord(TjanSchakelaar2(C).Aan)])
  else if C is TjanSchakelaar2 then
    Result := Format('TjanSchakelaar2;%d;%d;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width,
      Ord(TjanSchakelaar2(C).Aan), TjanSchakelaar2(C).Soort])
  else if C is TjanScoop then
    Result := Format('TjanScoop;%d;%d;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width,
      TjanScoop(C).BereikIdx, TjanScoop(C).TijdIdx])
  else if C is TjanVoltmeter2 then
    Result := Format('TjanVoltmeter2;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width])
  else if C is TjanDiode then
    Result := Format('TjanDiode;%d;%d;%d;%d;0;%d;%d;', [C.Height, C.Left, C.Top, C.Width,
      Ord(TjanDiode(C).Doorgebrand), Ord(TjanDiode(C).Omgekeerd)])
  else if C is TjanLed2 then
    Result := Format('TjanLed2;%d;%d;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width,
      TjanLed2(C).Kleur, Ord(TjanLed2(C).Doorgebrand)])
  else if C is TjanCondensator then
    Result := Format('TjanCondensator;%d;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width,
      TjanCondensator(C).Soort])
  else if C is TjanLDR then
    Result := Format('TjanLDR;%d;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width, TjanSensorR(C).Stand])
  else if C is TjanNTC then
    Result := Format('TjanNTC;%d;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width, TjanSensorR(C).Stand])
  else if C is TjanTransistor then
    Result := Format('TjanTransistor;%d;%d;%d;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width,
      Ord(TjanTransistor(C).PNP), TjanTransistor(C).BetaIdx, Ord(TjanTransistor(C).Doorgebrand)])
  else if C is TjanWattMeter then
    Result := Format('TjanWattMeter;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width])
  else if C is TjanPotmeter then
    Result := Format('TjanPotmeter;%d;%d;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width,
      TjanPotmeter(C).Soort, TjanPotmeter(C).Procent])
  else
    Result := Format('TjanAmpMeter;%d;%d;%d;%d;', [C.Height, C.Left, C.Top, C.Width]);
  // rechtop gezet: extra veld V achteraan (oudere versies negeren het)
  if (C is TjanVoedingsDeel) and TjanVoedingsDeel(C).Gedraaid then
    Result := Result + 'V;';
end;
