// janSimLogic.pas, deel: magnetisme: staafmagneet, kompas en veldplaat (ingevoegd met {$I jsl_magnetisme.inc})

const
  MagneetL = 96;            // lengte van de staafmagneet
  MagneetB = 24;            // breedte
  MagPoolIn = 12;           // de polen liggen zo ver binnen de uiteinden
  KompasD = 72;             // middellijn van het kompas
  AardVeld = 3.0e-6;        // veld van de aarde, naar boven (het noorden)
  KrachtDrempel = 3.0e-5;   // vanaf hier toont een magneet zijn krachtpijl
  VeldplaatW: array[0..2] of Integer = (360, 480, 600);
  VeldplaatH: array[0..2] of Integer = (240, 320, 400);
  VeldLijnenPerPool = 14;

type
  TMagPool = record
    P: TMagVec;
    Q: Double;              // +1 noordpool, -1 zuidpool
    Bron: TControl;
  end;
  TMagPolen = array of TMagPool;

function MagV(X, Y: Double): TMagVec;
begin
  Result.X := X;
  Result.Y := Y;
end;

function MagLen(const V: TMagVec): Double;
begin
  Result := Sqrt(Sqr(V.X) + Sqr(V.Y));
end;

// alle polen op het paneel (een onderdeel dat nog de muis volgt, telt niet mee)
function MagAllePolen(AParent: TWinControl): TMagPolen;
var
  i, n: Integer;
  C: TControl;
  PN, PZ: TMagVec;
begin
  SetLength(Result, 0);
  if AParent = nil then Exit;
  n := 0;
  for i := 0 to AParent.ControlCount - 1 do
  begin
    C := AParent.Controls[i];
    if (C is TjanMagneet) and C.Visible then
    begin
      TjanMagneet(C).Polen(PN, PZ);
      SetLength(Result, n + 2);
      Result[n].P := PN;     Result[n].Q := 1;  Result[n].Bron := C;
      Result[n + 1].P := PZ; Result[n + 1].Q := -1; Result[n + 1].Bron := C;
      Inc(n, 2);
    end
    else if (C is TjanSpoel) and C.Visible and (Abs(TjanSpoel(C).Sterkte) > 0.005) then
    begin
      // een spoel met stroom: de pool met + sterkte is PN
      TjanSpoel(C).Polen(PN, PZ);
      SetLength(Result, n + 2);
      Result[n].P := PN;     Result[n].Q := TjanSpoel(C).Sterkte;  Result[n].Bron := C;
      Result[n + 1].P := PZ; Result[n + 1].Q := -TjanSpoel(C).Sterkte; Result[n + 1].Bron := C;
      Inc(n, 2);
    end
    else if (C is TjanRelaisModel) and C.Visible and (Abs(TjanRelaisModel(C).Sterkte) > 0.005) then
    begin
      // de kern van het open relais: noordpool boven bij + sterkte
      TjanRelaisModel(C).Polen(PN, PZ);
      SetLength(Result, n + 2);
      Result[n].P := PN;     Result[n].Q := TjanRelaisModel(C).Sterkte;  Result[n].Bron := C;
      Result[n + 1].P := PZ; Result[n + 1].Q := -TjanRelaisModel(C).Sterkte; Result[n + 1].Bron := C;
      Inc(n, 2);
    end;
  end;
end;

// veld in punt (X, Y) van alle polen, behalve die van AZonder
function MagVeldIn(const Polen: TMagPolen; X, Y: Double; AZonder: TControl): TMagVec;
var
  i: Integer;
  dx, dy, r2, r3: Double;
begin
  Result := MagV(0, 0);
  for i := 0 to High(Polen) do
    if Polen[i].Bron <> AZonder then
    begin
      dx := X - Polen[i].P.X;
      dy := Y - Polen[i].P.Y;
      r2 := dx * dx + dy * dy;
      if r2 < 4 then r2 := 4;
      r3 := r2 * Sqrt(r2);
      Result.X := Result.X + Polen[i].Q * dx / r3;
      Result.Y := Result.Y + Polen[i].Q * dy / r3;
    end;
end;

// een magneet is verschoven, gedraaid, bijgekomen of weg: kompassen,
// veldplaten en de krachtpijlen van de magneten opnieuw tekenen
procedure MagneetVeranderd(AParent: TWinControl);
var
  i: Integer;
  C: TControl;
begin
  if (AParent = nil) or (csDestroying in AParent.ComponentState) then Exit;
  for i := 0 to AParent.ControlCount - 1 do
  begin
    C := AParent.Controls[i];
    if (C is TjanKompas) or (C is TjanVeldplaat) or (C is TjanMagneet) or (C is TjanSpoel) then
      C.Invalidate;
  end;
end;

// pijlpunt in (X, Y) in de richting (UX, UY) (eenheidsvector)
procedure MagPijlKop(ACanvas: TCanvas; X, Y, UX, UY: Double; AKop: Integer);
var
  P: array[0..2] of TPoint;
begin
  P[0] := Point(Round(X), Round(Y));
  P[1] := Point(Round(X - UX * AKop - UY * AKop * 0.5), Round(Y - UY * AKop + UX * AKop * 0.5));
  P[2] := Point(Round(X - UX * AKop + UY * AKop * 0.5), Round(Y - UY * AKop - UX * AKop * 0.5));
  ACanvas.Polygon(P);
end;

{ TjanMagneet }

constructor TjanMagneet.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := MagneetL;
  Height := MagneetB;
  HelpKeyword := 'magnetisme';
end;

destructor TjanMagneet.Destroy;
var
  P: TWinControl;
begin
  P := Parent;
  inherited Destroy;
  MagneetVeranderd(P);
end;

procedure TjanMagneet.CMVisibleChanged(var Msg: TLMessage);
begin
  inherited;
  MagneetVeranderd(Parent);
end;

procedure TjanMagneet.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
  MagneetVeranderd(Parent);
end;

function TjanMagneet.PinCount: Integer;
begin
  Result := 0;
end;

function TjanMagneet.PinPos(I: Integer): TPoint;
begin
  Result := Point(0, 0);
end;

function TjanMagneet.KanDraaien: Boolean;
begin
  Result := True;
end;

function TjanMagneet.StdMaat: TPoint;
begin
  Result := Point(MagneetL, MagneetB);
end;

procedure TjanMagneet.SetOmgekeerd(const Value: Boolean);
begin
  if Value = FOmgekeerd then Exit;
  FOmgekeerd := Value;
  UpdateHintText;
  Invalidate;
  MagneetVeranderd(Parent);
end;

procedure TjanMagneet.OmdraaiClick(Sender: TObject);
begin
  if not FLock then
    Omgekeerd := not Omgekeerd;
end;

procedure TjanMagneet.AddMenuItems(APop: TPopupMenu);
var
  Mi: TMenuItem;
begin
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Omdraaien (N en Z wisselen)', 'Turn round (swap N and S)',
    'Retourner (échanger N et S)', 'Umdrehen (N und S tauschen)');
  Mi.OnClick := OmdraaiClick;
  Mi.Enabled := not FLock;
  APop.Items.Add(Mi);
end;

procedure TjanMagneet.Polen(out PN, PZ: TMagVec);
var
  CX, CY, A: Double;
begin
  CX := Left + Width / 2;
  CY := Top + Height / 2;
  A := MagneetL / 2 - MagPoolIn;
  if FOmgekeerd then A := -A;
  if FGedraaid then
  begin
    PN := MagV(CX, CY + A);
    PZ := MagV(CX, CY - A);
  end
  else
  begin
    PN := MagV(CX + A, CY);
    PZ := MagV(CX - A, CY);
  end;
end;

function TjanMagneet.Kracht: TMagVec;
var
  Pl: TMagPolen;
  PN, PZ, BN, BZ: TMagVec;
begin
  Pl := MagAllePolen(Parent);
  Polen(PN, PZ);
  BN := MagVeldIn(Pl, PN.X, PN.Y, Self);
  BZ := MagVeldIn(Pl, PZ.X, PZ.Y, Self);
  Result := MagV(BN.X - BZ.X, BN.Y - BZ.Y);
end;

// 1 = de magneten trekken elkaar aan, -1 = ze stoten af, 0 = te ver
function MagneetKrachtSoort(M: TjanMagneet): Integer;
var
  F, D: TMagVec;
  i: Integer;
  C: TControl;
  Best, Afst: Double;
begin
  Result := 0;
  if M.Parent = nil then Exit;
  F := M.Kracht;
  if MagLen(F) <= KrachtDrempel then Exit;
  // de dichtste andere magneet bepaalt wat aantrekken is
  Best := 1e30;
  D := MagV(0, 0);
  for i := 0 to M.Parent.ControlCount - 1 do
  begin
    C := M.Parent.Controls[i];
    if (C <> M) and (C is TjanMagneet) and C.Visible then
    begin
      Afst := Sqr(C.Left + C.Width / 2 - M.Left - M.Width / 2) + Sqr(C.Top + C.Height / 2 - M.Top - M.Height / 2);
      if Afst < Best then
      begin
        Best := Afst;
        D := MagV(C.Left + C.Width / 2 - M.Left - M.Width / 2, C.Top + C.Height / 2 - M.Top - M.Height / 2);
      end;
    end;
  end;
  if F.X * D.X + F.Y * D.Y >= 0 then Result := 1 else Result := -1;
end;

procedure TjanMagneet.Paint;
var
  RN, RZ, R: TRect;
  Half: Integer;
  SN, SZ: string;
  F: TMagVec;
  L, UX, UY, S, CX, CY, SMax: Double;
begin
  Half := MagneetL div 2;
  if FOmgekeerd then
  begin
    RN := TRc(0, 0, Half, MagneetB);
    RZ := TRc(Half, 0, MagneetL, MagneetB);
  end
  else
  begin
    RZ := TRc(0, 0, Half, MagneetB);
    RN := TRc(Half, 0, MagneetL, MagneetB);
  end;
  with Canvas do
  begin
    Brush.Style := bsSolid;
    Brush.Color := RGBToColor(215, 40, 40);
    FillRect(RN);
    Brush.Color := RGBToColor(40, 90, 200);
    FillRect(RZ);
    Pen.Color := clBlack;
    Pen.Width := 1;
    Pen.Style := psSolid;
    Brush.Style := bsClear;
    R := TRc(0, 0, MagneetL, MagneetB);
    Rectangle(R);
    Font.Name := 'Arial';
    Font.Size := 11;
    Font.Style := [fsBold];
    Font.Color := clWhite;
    SN := 'N';
    SZ := Tr(FTaal, 'Z', 'S', 'S', 'S');
    TextOut((RN.Left + RN.Right - TextWidth(SN)) div 2, (RN.Top + RN.Bottom - TextHeight(SN)) div 2, SN);
    TextOut((RZ.Left + RZ.Right - TextWidth(SZ)) div 2, (RZ.Top + RZ.Bottom - TextHeight(SZ)) div 2, SZ);
    // krachtpijl: hoe dichter de andere magneet, hoe langer
    F := Kracht;
    L := MagLen(F);
    if L > KrachtDrempel then
    begin
      UX := F.X / L;
      UY := F.Y / L;
      CX := Self.Width / 2;
      CY := Self.Height / 2;
      SMax := 15;
      if (Abs(UX) > 0.01) and ((Self.Width / 2 - 3) / Abs(UX) < SMax) then SMax := (Self.Width / 2 - 3) / Abs(UX);
      if (Abs(UY) > 0.01) and ((Self.Height / 2 - 3) / Abs(UY) < SMax) then SMax := (Self.Height / 2 - 3) / Abs(UY);
      S := 6 + 9 * (L - KrachtDrempel) / (3 * KrachtDrempel);
      if S > SMax then S := SMax;
      Pen.Color := clYellow;
      Pen.Width := 3;
      MoveTo(Round(CX - UX * S), Round(CY - UY * S));
      LineTo(Round(CX + UX * (S - 4)), Round(CY + UY * (S - 4)));
      Pen.Width := 1;
      Pen.Color := clBlack;
      Brush.Style := bsSolid;
      Brush.Color := clYellow;
      MagPijlKop(Canvas, CX + UX * (S + 3), CY + UY * (S + 3), UX, UY, 8);
      Brush.Style := bsClear;
    end;
  end;
  PaintSelection;
end;

procedure TjanMagneet.UpdateHintText;
var
  S: string;
begin
  case MagneetKrachtSoort(Self) of
    1: S := Tr(FTaal,
         'De magneten trekken elkaar aan: een noordpool en een zuidpool (ongelijke polen).',
         'The magnets attract each other: a north pole and a south pole (unlike poles).',
         'Les aimants s''attirent : un pôle nord et un pôle sud (pôles contraires).',
         'Die Magnete ziehen sich an: ein Nordpol und ein Südpol (ungleiche Pole).');
    -1: S := Tr(FTaal,
         'De magneten stoten elkaar af: twee dezelfde polen (gelijke polen).',
         'The magnets repel each other: two of the same poles (like poles).',
         'Les aimants se repoussent : deux pôles identiques (pôles semblables).',
         'Die Magnete stoßen sich ab: zwei gleiche Pole (gleichnamige Pole).');
  else
    S := Tr(FTaal,
      'Breng een tweede magneet dichtbij: de gele pijl toont de kracht.',
      'Bring a second magnet close: the yellow arrow shows the force.',
      'Approchez un deuxième aimant : la flèche jaune montre la force.',
      'Bringen Sie einen zweiten Magneten in die Nähe: Der gelbe Pfeil zeigt die Kraft.');
  end;
  Hint := Tr(FTaal, 'Staafmagneet', 'Bar magnet', 'Aimant droit', 'Stabmagnet') + #13#10 +
    Tr(FTaal,
      'Noordpool N (rood) en zuidpool Z (blauw). Buiten de magneet lopen de veldlijnen van N naar Z.',
      'North pole N (red) and south pole S (blue). Outside the magnet the field lines run from N to S.',
      'Pôle nord N (rouge) et pôle sud S (bleu). À l''extérieur de l''aimant, les lignes de champ vont de N à S.',
      'Nordpol N (rot) und Südpol S (blau). Außerhalb des Magneten laufen die Feldlinien von N nach S.') + #13#10 +
    S + #13#10 +
    Tr(FTaal, 'Rechtsklik: omdraaien of draaien.', 'Right-click: turn round or rotate.',
      'Clic droit : retourner ou pivoter.', 'Rechtsklick: umdrehen oder drehen.');
end;

procedure TjanMagneet.SendStatusToBar;
var
  S: string;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Tr(FTaal, 'Staafmagneet', 'Bar magnet', 'Aimant droit', 'Stabmagnet') + ' > ', 0);
  case MagneetKrachtSoort(Self) of
    1: S := Tr(FTaal, 'trekt aan', 'attracts', 'attire', 'zieht an');
    -1: S := Tr(FTaal, 'stoot af', 'repels', 'repousse', 'stößt ab');
  else
    S := '';
  end;
  FOnStatus(Self, S, 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

{ TjanKompas }

constructor TjanKompas.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := KompasD;
  Height := KompasD;
  HelpKeyword := 'magnetisme';
end;

function TjanKompas.PinCount: Integer;
begin
  Result := 0;
end;

function TjanKompas.PinPos(I: Integer): TPoint;
begin
  Result := Point(0, 0);
end;

// veld in het midden van het kompas: magneten plus de aarde (naar boven)
function KompasVeld(K: TjanKompas; out AMag: Double): TMagVec;
begin
  Result := MagVeldIn(MagAllePolen(K.Parent), K.Left + K.Width / 2, K.Top + K.Height / 2, nil);
  AMag := MagLen(Result);
  Result.Y := Result.Y - AardVeld;
end;

procedure TjanKompas.Paint;
var
  C, R, RN, W, L, UX, UY, Mag: Double;
  B: TMagVec;
  P: array[0..2] of TPoint;
  i: Integer;
  S: string;

  procedure Letter(const T: string; DX, DY: Integer);
  var
    LX, LY: Integer;
  begin
    LX := Round(C + DX * (R - 9)) - Canvas.TextWidth(T) div 2;
    LY := Round(C + DY * (R - 9)) - Canvas.TextHeight(T) div 2;
    Canvas.TextOut(LX, LY, T);
  end;

begin
  C := KompasD / 2;
  R := C - 2;
  with Canvas do
  begin
    // behuizing en windroos
    Pen.Color := RGBToColor(90, 70, 40);
    Pen.Width := 2;
    Brush.Style := bsSolid;
    Brush.Color := RGBToColor(250, 250, 245);
    Ellipse(1, 1, KompasD - 1, KompasD - 1);
    Pen.Width := 1;
    Pen.Color := RGBToColor(150, 150, 150);
    for i := 0 to 7 do
    begin
      UX := Cos(i * Pi / 4);
      UY := Sin(i * Pi / 4);
      MoveTo(Round(C + UX * (R - 3)), Round(C + UY * (R - 3)));
      LineTo(Round(C + UX * R), Round(C + UY * R));
    end;
    Brush.Style := bsClear;
    Font.Name := 'Arial';
    Font.Size := 7;
    Font.Style := [fsBold];
    Font.Color := RGBToColor(170, 0, 0);
    Letter('N', 0, -1);
    Font.Color := RGBToColor(80, 80, 80);
    Letter(Tr(FTaal, 'Z', 'S', 'S', 'S'), 0, 1);
    Letter(Tr(FTaal, 'O', 'E', 'E', 'O'), 1, 0);
    Letter(Tr(FTaal, 'W', 'W', 'O', 'W'), -1, 0);
    // de naald: de rode punt (noordpool van de naald) wijst langs het veld
    B := KompasVeld(Self, Mag);
    L := MagLen(B);
    if L < 1e-15 then
    begin
      UX := 0; UY := -1;
    end
    else
    begin
      UX := B.X / L; UY := B.Y / L;
    end;
    RN := R - 15;
    W := 5;
    Pen.Color := clBlack;
    Brush.Style := bsSolid;
    Brush.Color := RGBToColor(215, 30, 30);
    P[0] := Point(Round(C + UX * RN), Round(C + UY * RN));
    P[1] := Point(Round(C - UY * W), Round(C + UX * W));
    P[2] := Point(Round(C + UY * W), Round(C - UX * W));
    Polygon(P);
    Brush.Color := RGBToColor(225, 225, 225);
    P[0] := Point(Round(C - UX * RN), Round(C - UY * RN));
    Polygon(P);
    Brush.Color := RGBToColor(90, 70, 40);
    Ellipse(Round(C) - 2, Round(C) - 2, Round(C) + 3, Round(C) + 3);
  end;
  S := '';
  PaintSelection;
end;

procedure TjanKompas.UpdateHintText;
var
  Mag: Double;
  S: string;
begin
  KompasVeld(Self, Mag);
  if Mag < AardVeld / 4 then
    S := Tr(FTaal,
      'Er is geen magneet in de buurt: de naald wijst naar het noorden van de aarde (boven).',
      'There is no magnet nearby: the needle points to the Earth''s north (up).',
      'Aucun aimant à proximité : l''aiguille indique le nord de la Terre (en haut).',
      'Kein Magnet in der Nähe: Die Nadel zeigt nach Norden (oben).')
  else
    S := Format(Tr(FTaal,
      'Het veld van de magneten is hier %s keer zo sterk als dat van de aarde.',
      'Here the field of the magnets is %s times as strong as that of the Earth.',
      'Ici, le champ des aimants est %s fois plus fort que celui de la Terre.',
      'Hier ist das Feld der Magnete %s-mal so stark wie das der Erde.'),
      [FormatFloat('0.#', Mag / AardVeld)]);
  Hint := Tr(FTaal, 'Kompas', 'Compass', 'Boussole', 'Kompass') + #13#10 +
    Tr(FTaal,
      'De rode punt is de noordpool van de naald. Ze wijst langs het veld:' + #13#10 +
        'weg van een noordpool en naar een zuidpool.',
      'The red tip is the north pole of the needle. It points along the field:' + #13#10 +
        'away from a north pole and towards a south pole.',
      'La pointe rouge est le pôle nord de l''aiguille. Elle suit le champ :' + #13#10 +
        'elle s''éloigne d''un pôle nord et va vers un pôle sud.',
      'Die rote Spitze ist der Nordpol der Nadel. Sie zeigt entlang des Feldes:' + #13#10 +
        'weg von einem Nordpol und hin zu einem Südpol.') + #13#10 + S;
end;

procedure TjanKompas.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Tr(FTaal, 'Kompas', 'Compass', 'Boussole', 'Kompass') + ' > ', 0);
  FOnStatus(Self, '', 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

{ TjanVeldplaat }

constructor TjanVeldplaat.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMaat := 1;
  Width := VeldplaatW[FMaat];
  Height := VeldplaatH[FMaat];
  HelpKeyword := 'magnetisme';
end;

function TjanVeldplaat.PinCount: Integer;
begin
  Result := 0;
end;

function TjanVeldplaat.PinPos(I: Integer): TPoint;
begin
  Result := Point(0, 0);
end;

// de plaat ligt altijd onder de magneten en het kompas
procedure TjanVeldplaat.CMVisibleChanged(var Msg: TLMessage);
begin
  inherited;
  if Visible and (Parent <> nil) then
    SendToBack;
end;

procedure TjanVeldplaat.SetMaat(const Value: Integer);
begin
  if (Value < Low(VeldplaatW)) or (Value > High(VeldplaatW)) or (Value = FMaat) then Exit;
  FMaat := Value;
  SetBounds(Left, Top, VeldplaatW[FMaat], VeldplaatH[FMaat]);
  Invalidate;
end;

procedure TjanVeldplaat.MaatClick(Sender: TObject);
begin
  if not FLock then
    Maat := TMenuItem(Sender).Tag;
end;

procedure TjanVeldplaat.AddMenuItems(APop: TPopupMenu);
var
  Mi, Sub: TMenuItem;
  i: Integer;
begin
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Maat', 'Size', 'Taille', 'Größe');
  Mi.Enabled := not FLock;
  APop.Items.Add(Mi);
  for i := Low(VeldplaatW) to High(VeldplaatW) do
  begin
    Sub := TMenuItem.Create(APop);
    case i of
      0: Sub.Caption := Tr(FTaal, 'Klein', 'Small', 'Petite', 'Klein');
      1: Sub.Caption := Tr(FTaal, 'Middel', 'Medium', 'Moyenne', 'Mittel');
    else
      Sub.Caption := Tr(FTaal, 'Groot', 'Large', 'Grande', 'Groß');
    end;
    Sub.Caption := Sub.Caption + Format(' (%d x %d)', [VeldplaatW[i], VeldplaatH[i]]);
    Sub.Tag := i;
    Sub.RadioItem := True;
    Sub.Checked := i = FMaat;
    Sub.OnClick := MaatClick;
    Mi.Add(Sub);
  end;
end;

procedure TjanVeldplaat.Paint;
var
  Pl: TMagPolen;
  i, j, k, Stap, Richting, Einde, NL: Integer;
  X, Y, XM, YM, L, Ang, X0, Y0, PijlX, PijlY, PijlUX, PijlUY, DX, DY: Double;
  PN, PZ: TMagVec;
  B: TMagVec;
  Pts: array of TPoint;

  function Buiten(AX, AY: Double): Boolean;
  begin
    Result := (AX < X0 + 1) or (AY < Y0 + 1) or (AX > X0 + Width - 2) or (AY > Y0 + Height - 2);
  end;

  // dicht bij een pool met lading ATeken (+1 noord, -1 zuid)
  function BijPool(AX, AY: Double; ATeken: Integer): Boolean;
  var
    j: Integer;
  begin
    Result := False;
    for j := 0 to High(Pl) do
      if (Pl[j].Q * ATeken > 0) and (Sqr(AX - Pl[j].P.X) + Sqr(AY - Pl[j].P.Y) < 25) then
        Exit(True);
  end;

begin
  with Canvas do
  begin
    Brush.Style := bsSolid;
    Brush.Color := RGBToColor(250, 247, 232);
    FillRect(ClientRect);
    Pen.Color := RGBToColor(170, 160, 130);
    Pen.Width := 1;
    Pen.Style := psSolid;
    Brush.Style := bsClear;
    Rectangle(ClientRect);
    Font.Name := 'Arial';
    Font.Size := 7;
    Font.Style := [];
    Font.Color := RGBToColor(150, 140, 110);
    TextOut(6, 4, Tr(FTaal, 'veldlijnen', 'field lines', 'lignes de champ', 'Feldlinien'));
    if Parent = nil then
    begin
      PaintSelection;
      Exit;
    end;
    Pl := MagAllePolen(Parent);
    X0 := Left;
    Y0 := Top;
    Pen.Color := RGBToColor(80, 80, 80);
    // vanuit elke noordpool met het veld mee; vanuit elke zuidpool tegen het
    // veld in, maar die lijn alleen als ze de plaat verlaat (de andere komen
    // al uit een noordpool)
    for i := 0 to High(Pl) do
    begin
      // meer lijnen naarmate de pool sterker is (een staafmagneet: VeldLijnenPerPool)
      NL := Round(VeldLijnenPerPool * Sqrt(Abs(Pl[i].Q)));
      if NL > 2 * VeldLijnenPerPool then NL := 2 * VeldLijnenPerPool;
      j := i xor 1;
      DX := Pl[j].P.X - Pl[i].P.X;
      DY := Pl[j].P.Y - Pl[i].P.Y;
      L := Sqrt(DX * DX + DY * DY);
      if L > 0 then begin DX := DX / L; DY := DY / L; end;
      for k := 0 to NL - 1 do
      begin
        if Pl[i].Q > 0 then Richting := 1 else Richting := -1;
        Ang := 2 * Pi * (k + 0.5) / NL;
        // niet naar binnen, naar de andere pool van dezelfde magneet of spoel
        if (Cos(Ang) * DX + Sin(Ang) * DY > 0.6) then Continue;
        X := Pl[i].P.X + 7 * Cos(Ang);
        Y := Pl[i].P.Y + 7 * Sin(Ang);
        if Buiten(X, Y) then Continue;
        SetLength(Pts, 1);
        Pts[0] := Point(Round(X - X0), Round(Y - Y0));
        PijlX := 0; PijlY := 0; PijlUX := 0; PijlUY := 0;
        Stap := 0;
        Einde := 0;   // 1 = de plaat uit, 2 = bij een pool
        repeat
          // middelpuntsmethode: een halve stap vooruit kijken
          B := MagVeldIn(Pl, X, Y, nil);
          L := MagLen(B);
          if L < 1e-12 then Break;
          XM := X + Richting * B.X / L;
          YM := Y + Richting * B.Y / L;
          B := MagVeldIn(Pl, XM, YM, nil);
          L := MagLen(B);
          if L < 1e-12 then Break;
          X := X + Richting * 2 * B.X / L;
          Y := Y + Richting * 2 * B.Y / L;
          SetLength(Pts, Length(Pts) + 1);
          Pts[High(Pts)] := Point(Round(X - X0), Round(Y - Y0));
          Inc(Stap);
          if Stap = 22 then
          begin
            PijlX := X - X0; PijlY := Y - Y0;
            PijlUX := B.X / L; PijlUY := B.Y / L;
          end;
          if Buiten(X, Y) then Einde := 1
          else if BijPool(X, Y, -Richting) then Einde := 2
          else if Stap > 3000 then Einde := 2;
        until Einde > 0;
        if (Richting < 0) and (Einde <> 1) then Continue;
        Polyline(Pts);
        if Stap >= 22 then
        begin
          // een pijltje: de richting van het veld (van N naar Z)
          Brush.Style := bsSolid;
          Brush.Color := RGBToColor(80, 80, 80);
          if Richting > 0 then
            MagPijlKop(Canvas, PijlX, PijlY, PijlUX, PijlUY, 6)
          else
            MagPijlKop(Canvas, PijlX + 6 * PijlUX, PijlY + 6 * PijlUY, PijlUX, PijlUY, 6);
          Brush.Style := bsClear;
        end;
      end;
    end;
    // binnen een spoel lopen de veldlijnen recht, van Z naar N
    i := 0;
    while i < High(Pl) do
    begin
      if (Pl[i].Bron is TjanSpoel) and (Abs(Pl[i].Q) > 0.05) then
      begin
        if Pl[i].Q > 0 then begin PN := Pl[i].P; PZ := Pl[i + 1].P; end
        else begin PN := Pl[i + 1].P; PZ := Pl[i].P; end;
        DX := PN.X - PZ.X; DY := PN.Y - PZ.Y;
        L := Sqrt(DX * DX + DY * DY);
        if L > 0 then
        begin
          DX := DX / L; DY := DY / L;
          for k := -1 to 1 do
          begin
            MoveTo(Round(PZ.X - X0 - DY * k * 6), Round(PZ.Y - Y0 + DX * k * 6));
            LineTo(Round(PN.X - X0 - DY * k * 6), Round(PN.Y - Y0 + DX * k * 6));
            Brush.Style := bsSolid;
            Brush.Color := RGBToColor(80, 80, 80);
            MagPijlKop(Canvas, (PZ.X + PN.X) / 2 + DX * 3 - X0 - DY * k * 6, (PZ.Y + PN.Y) / 2 + DY * 3 - Y0 + DX * k * 6, DX, DY, 6);
            Brush.Style := bsClear;
          end;
        end;
      end;
      Inc(i, 2);
    end;
  end;
  PaintSelection;
end;

procedure TjanVeldplaat.UpdateHintText;
begin
  Hint := Tr(FTaal, 'Veldlijnenplaat', 'Field line sheet', 'Plaque de lignes de champ', 'Feldlinienplatte') + #13#10 +
    Tr(FTaal,
      'Zoals ijzervijlsel op papier: de lijnen tonen het magnetisch veld.' + #13#10 +
        'Ze lopen buiten de magneet van N naar Z. Waar ze dicht bij elkaar liggen, is het veld sterk.' + #13#10 +
        'Leg er magneten op. Rechtsklik: maat.',
      'Like iron filings on paper: the lines show the magnetic field.' + #13#10 +
        'Outside the magnet they run from N to S. Where they are close together, the field is strong.' + #13#10 +
        'Put magnets on it. Right-click: size.',
      'Comme de la limaille de fer sur du papier : les lignes montrent le champ magnétique.' + #13#10 +
        'À l''extérieur de l''aimant, elles vont de N à S. Là où elles sont serrées, le champ est fort.' + #13#10 +
        'Posez-y des aimants. Clic droit : taille.',
      'Wie Eisenfeilspäne auf Papier: Die Linien zeigen das Magnetfeld.' + #13#10 +
        'Außerhalb des Magneten laufen sie von N nach S. Wo sie dicht beieinander liegen, ist das Feld stark.' + #13#10 +
        'Legen Sie Magnete darauf. Rechtsklick: Größe.');
end;

procedure TjanVeldplaat.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Tr(FTaal, 'Veldlijnenplaat', 'Field line sheet', 'Plaque de lignes de champ', 'Feldlinienplatte') + ' > ', 0);
  FOnStatus(Self, '', 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

{ TjanSpoel }

const
  SpoelW = 120;
  SpoelH = 48;
  SpoelWindingen: array[0..2] of Integer = (100, 200, 400);
  SpoelOhmW: array[0..2] of Double = (2, 4, 8);
  SpoelK = 0.025;            // sterkte per ampère-winding (een magneet heeft 1)
  SpoelKernFactor = 5;       // een ijzeren kern maakt het veld zoveel sterker

constructor TjanSpoel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FWindIdx := 1;
  Width := SpoelW;
  Height := SpoelH;
  HelpKeyword := 'magnetisme';
end;

destructor TjanSpoel.Destroy;
var
  P: TWinControl;
begin
  P := Parent;
  inherited Destroy;
  MagneetVeranderd(P);
end;

procedure TjanSpoel.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
  MagneetVeranderd(Parent);
end;

function TjanSpoel.StdMaat: TPoint;
begin
  Result := Point(SpoelW, SpoelH);
end;

function TjanSpoel.ExtraBreedte: Integer;
begin
  Result := 0;
end;

// klem 0 links, klem 1 rechts (ook als ze andersom gewikkeld is)
function TjanSpoel.PinPos(I: Integer): TPoint;
begin
  if I = 0 then Result := TP(1, 17) else Result := TP(SpoelW - 8, 17);
end;

function TjanSpoel.Ohm: Double;
begin
  Result := SpoelOhmW[FWindIdx];
end;

function TjanSpoel.Windingen: Integer;
begin
  Result := SpoelWindingen[FWindIdx];
end;

function TjanSpoel.Sterkte: Double;
begin
  Result := SpoelK * Windingen * FAmp;
  if FKern then Result := Result * SpoelKernFactor;
  if FOmgekeerd then Result := -Result;
end;

procedure TjanSpoel.Polen(out PN, PZ: TMagVec);
var
  CX, CY, A: Double;
begin
  CX := Left + Width / 2;
  CY := Top + Height / 2;
  A := (SpoelW - 40) / 2 - 6;
  if FGedraaid then
  begin
    PN := MagV(CX, CY + A);
    PZ := MagV(CX, CY - A);
  end
  else
  begin
    PN := MagV(CX + A, CY);
    PZ := MagV(CX - A, CY);
  end;
end;

procedure TjanSpoel.SetWindIdx(const Value: Integer);
begin
  if (Value < Low(SpoelWindingen)) or (Value > High(SpoelWindingen)) or (Value = FWindIdx) then Exit;
  FWindIdx := Value;
  UpdateHintText;
  Invalidate;
  if Parent <> nil then UpdateSupply(Parent, True);
  MagneetVeranderd(Parent);
end;

procedure TjanSpoel.SetKern(const Value: Boolean);
begin
  if Value = FKern then Exit;
  FKern := Value;
  UpdateHintText;
  Invalidate;
  MagneetVeranderd(Parent);
end;

procedure TjanSpoel.SetOmgekeerd(const Value: Boolean);
begin
  if Value = FOmgekeerd then Exit;
  FOmgekeerd := Value;
  UpdateHintText;
  Invalidate;
  if Parent <> nil then UpdateSupply(Parent, True);
  MagneetVeranderd(Parent);
end;

procedure TjanSpoel.WindClick(Sender: TObject);
begin
  if not FLock then WindIdx := TMenuItem(Sender).Tag;
end;

procedure TjanSpoel.KernClick(Sender: TObject);
begin
  if not FLock then Kern := not Kern;
end;

procedure TjanSpoel.OmdraaiClick(Sender: TObject);
begin
  if not FLock then Omgekeerd := not Omgekeerd;
end;

procedure TjanSpoel.AddMenuItems(APop: TPopupMenu);
var
  Mi, Sub: TMenuItem;
  i: Integer;
begin
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Windingen', 'Turns', 'Spires', 'Windungen');
  Mi.Enabled := not FLock;
  APop.Items.Add(Mi);
  for i := Low(SpoelWindingen) to High(SpoelWindingen) do
  begin
    Sub := TMenuItem.Create(APop);
    Sub.Caption := IntToStr(SpoelWindingen[i]) + ' (' + OhmText(SpoelOhmW[i]) + ')';
    Sub.Tag := i;
    Sub.RadioItem := True;
    Sub.Checked := i = FWindIdx;
    Sub.OnClick := WindClick;
    Mi.Add(Sub);
  end;
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'IJzeren kern', 'Iron core', 'Noyau de fer', 'Eisenkern');
  Mi.Checked := FKern;
  Mi.Enabled := not FLock;
  Mi.OnClick := KernClick;
  APop.Items.Add(Mi);
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Andersom gewikkeld (N en Z wisselen)', 'Wound the other way (swap N and S)',
    'Enroulée dans l''autre sens (échanger N et S)', 'Andersherum gewickelt (N und S tauschen)');
  Mi.Enabled := not FLock;
  Mi.OnClick := OmdraaiClick;
  APop.Items.Add(Mi);
end;

procedure TjanSpoel.Paint;
var
  i, N, X, L, R: Integer;
  S: Double;
  SN, SZ: string;
  RL, RR: TRect;

  procedure Pool(const APlek: TRect; AKleur: TColor; const AT: string);
  begin
    with Canvas do
    begin
      Brush.Style := bsSolid;
      Brush.Color := AKleur;
      FillRect(APlek);
      Font.Name := 'Arial';
      Font.Size := 7;
      Font.Style := [fsBold];
      Font.Color := clWhite;
      Brush.Style := bsClear;
      TextOut((APlek.Left + APlek.Right - TextWidth(AT)) div 2, (APlek.Top + APlek.Bottom - TextHeight(AT)) div 2, AT);
    end;
  end;

begin
  L := 20;
  R := SpoelW - 20;
  with Canvas do
  begin
    // aansluitdraadjes
    Pen.Color := clBlack;
    Pen.Width := 2;
    Pen.Style := psSolid;
    TLijn(6, 20, L + 2, 20);
    TLijn(R - 2, 20, SpoelW - 6, 20);
    // ijzeren kern, of een buisje van karton
    Pen.Width := 1;
    if FKern then
    begin
      Brush.Style := bsSolid;
      Brush.Color := RGBToColor(140, 140, 150);
      FillRect(TRc(L - 6, 13, R + 6, 28));
      Pen.Color := RGBToColor(80, 80, 90);
      Brush.Style := bsClear;
      Rectangle(TRc(L - 6, 13, R + 6, 28));
    end
    else
    begin
      Pen.Color := RGBToColor(190, 170, 130);
      Brush.Style := bsClear;
      Rectangle(TRc(L - 2, 13, R + 2, 28));
    end;
    // windingen van koperdraad
    case FWindIdx of
      0: N := 6;
      1: N := 9;
    else
      N := 13;
    end;
    Pen.Color := RGBToColor(184, 100, 30);
    Pen.Width := 2;
    Brush.Style := bsClear;
    for i := 0 to N - 1 do
    begin
      X := L + Round(i * (R - L - 6) / (N - 1));
      Ellipse(TRc(X, 6, X + 6, 35));
    end;
    Pen.Width := 1;
    Pen.Color := clBlack;
    // polen zodra er stroom loopt
    S := Sterkte;
    if Abs(S) > 0.01 then
    begin
      SN := 'N';
      SZ := Tr(FTaal, 'Z', 'S', 'S', 'S');
      RL := TRc(L - 2, 37, L + 12, 47);
      RR := TRc(R - 12, 37, R + 2, 47);
      if S > 0 then
      begin
        Pool(RR, RGBToColor(215, 40, 40), SN);
        Pool(RL, RGBToColor(40, 90, 200), SZ);
      end
      else
      begin
        Pool(RL, RGBToColor(215, 40, 40), SN);
        Pool(RR, RGBToColor(40, 90, 200), SZ);
      end;
    end;
  end;
  PaintPin(PinPos(0).X, PinPos(0).Y, FInVolt >= RailMinVolt);
  PaintPin(PinPos(1).X, PinPos(1).Y, FUitVolt >= RailMinVolt);
  PaintSelection;
end;

procedure TjanSpoel.UpdateHintText;
var
  S, Kant, KernT, KernX: string;
  St: Double;
begin
  St := Sterkte;
  if FKern then
  begin
    KernT := Tr(FTaal, 'met ijzeren kern', 'with iron core', 'avec noyau de fer', 'mit Eisenkern');
    KernX := Tr(FTaal, ' × 5 door de kern)', ' × 5 by the core)', ' × 5 par le noyau)', ' × 5 durch den Kern)');
  end
  else
  begin
    KernT := Tr(FTaal, 'zonder kern (lucht)', 'without core (air)', 'sans noyau (air)', 'ohne Kern (Luft)');
    KernX := ')';
  end;
  if Abs(St) <= 0.01 then
    S := Tr(FTaal, 'Er loopt geen stroom: de spoel is geen magneet.',
      'No current flows: the coil is not a magnet.',
      'Aucun courant ne passe : la bobine n''est pas un aimant.',
      'Es fließt kein Strom: Die Spule ist kein Magnet.')
  else
  begin
    if FGedraaid then
    begin
      if St > 0 then Kant := Tr(FTaal, 'onderaan', 'at the bottom', 'en bas', 'unten')
      else Kant := Tr(FTaal, 'bovenaan', 'at the top', 'en haut', 'oben');
    end
    else if St > 0 then Kant := Tr(FTaal, 'rechts', 'on the right', 'à droite', 'rechts')
    else Kant := Tr(FTaal, 'links', 'on the left', 'à gauche', 'links');
    S := Format(Tr(FTaal, 'De stroom maakt van de spoel een magneet: de noordpool zit %s.',
      'The current turns the coil into a magnet: the north pole is %s.',
      'Le courant fait de la bobine un aimant : le pôle nord est %s.',
      'Der Strom macht die Spule zu einem Magneten: Der Nordpol ist %s.'), [Kant]) + #13#10 +
      Format(Tr(FTaal, 'Sterkte: %s keer een staafmagneet (%d windingen × %s',
        'Strength: %s times a bar magnet (%d turns × %s',
        'Force : %s fois un aimant droit (%d spires × %s',
        'Stärke: %s-mal ein Stabmagnet (%d Windungen × %s'),
        [FormatFloat('0.##', Abs(St)), Windingen, AmpText(Abs(FAmp))]) + KernX;
  end;
  Hint := Tr(FTaal, 'Spoel', 'Coil', 'Bobine', 'Spule') + ': ' + IntToStr(Windingen) + ' ' +
    Tr(FTaal, 'windingen', 'turns', 'spires', 'Windungen') + ', ' + KernT + ', R = ' + OhmText(Ohm) + #13#10 +
    StroomRegel(FStroom) + #13#10 + S + #13#10 +
    Tr(FTaal,
      'Rechterhandregel: krom de vingers van je rechterhand met de stroom mee rond de spoel; je duim wijst naar de noordpool.',
      'Right-hand rule: curl the fingers of your right hand along the current round the coil; your thumb points to the north pole.',
      'Règle de la main droite : enroulez les doigts de la main droite dans le sens du courant ; le pouce indique le pôle nord.',
      'Rechte-Hand-Regel: Krümmen Sie die Finger der rechten Hand in Stromrichtung um die Spule; der Daumen zeigt zum Nordpol.') + #13#10 +
    Tr(FTaal, 'Rechtsklik: windingen, kern, andersom gewikkeld of draaien.',
      'Right-click: turns, core, wound the other way or rotate.',
      'Clic droit : spires, noyau, enroulée dans l''autre sens ou pivoter.',
      'Rechtsklick: Windungen, Kern, andersherum gewickelt oder drehen.');
end;

procedure TjanSpoel.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Tr(FTaal, 'Spoel', 'Coil', 'Bobine', 'Spule') + ' > ', 0);
  FOnStatus(Self, IntToStr(Windingen) + ' ' + Tr(FTaal, 'windingen', 'turns', 'spires', 'Windungen') +
    '   I = ' + FormatFloat('0', FStroom * 1000) + ' mA', 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

{ TjanIJzer }

const
  IJzerL = 44;              // lengte van de spijker
  IJzerB = 12;
  IJzerDrempel = 3.2e-9;    // kracht (helling van B²) die nodig is om hem te verschuiven
  IJzerContact = 9;         // zo dicht bij een pool raakt hij de magneet

function IJzerVeld2(const Pl: TMagPolen; X, Y: Double): Double;
var
  B: TMagVec;
begin
  B := MagVeldIn(Pl, X, Y, nil);
  Result := Sqr(B.X) + Sqr(B.Y);
end;

constructor TjanIJzer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := IJzerL;
  Height := IJzerB;
  HelpKeyword := 'magnetisme';
  FTimer := TTimer.Create(Self);
  FTimer.Interval := 40;
  FTimer.OnTimer := Tik;
  FTimer.Enabled := True;
end;

procedure TjanIJzer.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
  // verschoven door de gebruiker (of geladen): dat is zijn nieuwe plaats
  if not FTrekt then
  begin
    FThuis := Point(ALeft, ATop);
    FVast := False;
  end;
end;

function TjanIJzer.PinCount: Integer;
begin
  Result := 0;
end;

function TjanIJzer.PinPos(I: Integer): TPoint;
begin
  Result := Point(0, 0);
end;

function TjanIJzer.KanDraaien: Boolean;
begin
  Result := True;
end;

function TjanIJzer.StdMaat: TPoint;
begin
  Result := Point(IJzerL, IJzerB);
end;

// de helling van B² aan het uiteinde waar ze het grootst is
function TjanIJzer.Krachtvector: TMagVec;
const
  H = 1.5;
var
  Pl: TMagPolen;
  e: Integer;
  CX, CY, A, EX, EY, GX, GY, Best: Double;
begin
  Result := MagV(0, 0);
  Pl := MagAllePolen(Parent);
  if Length(Pl) = 0 then Exit;
  CX := Left + Width / 2;
  CY := Top + Height / 2;
  A := IJzerL / 2 - 3;
  Best := -1;
  for e := -1 to 1 do
  begin
    if FGedraaid then
    begin
      EX := CX; EY := CY + e * A;
    end
    else
    begin
      EX := CX + e * A; EY := CY;
    end;
    GX := (IJzerVeld2(Pl, EX + H, EY) - IJzerVeld2(Pl, EX - H, EY)) / (2 * H);
    GY := (IJzerVeld2(Pl, EX, EY + H) - IJzerVeld2(Pl, EX, EY - H)) / (2 * H);
    if Sqr(GX) + Sqr(GY) > Best then
    begin
      Best := Sqr(GX) + Sqr(GY);
      Result := MagV(GX, GY);
    end;
  end;
end;

function TjanIJzer.Trekkracht: Double;
begin
  if Parent = nil then Result := 0
  else Result := MagLen(Krachtvector) / IJzerDrempel;
end;

procedure TjanIJzer.Tik(Sender: TObject);
var
  F: TMagVec;
  L: Double;
  Pl: TMagPolen;
  i: Integer;
  R: TRect;
  CX, CY, A, EX, EY: Double;
  Raakt: Boolean;

  function OverlaptIets: Boolean;
  var
    j: Integer;
    D: TControl;
  begin
    Result := False;
    for j := 0 to Parent.ControlCount - 1 do
    begin
      D := Parent.Controls[j];
      if (D <> Self) and D.Visible and
         ((D is TjanMagneet) or ((D is TjanIJzer) and TjanIJzer(D).Vast)) and
         IntersectRect(R, BoundsRect, D.BoundsRect) then
        Exit(True);
    end;
  end;

begin
  if (Parent = nil) or not Visible or FDoMove or FLock or FVast then Exit;
  if not FTrekt then
  begin
    if Trekkracht < 1 then Exit;
    FTrekt := True;
    FV := 0.5;
    FX := Left;
    FY := Top;
  end;
  F := Krachtvector;
  L := MagLen(F);
  if L / IJzerDrempel < 0.3 then
  begin
    // het veld is weg (de stroom is uitgezet): hij blijft liggen
    FTrekt := False;
    Exit;
  end;
  // versnellen naar de magneet toe
  FV := FV * 1.35 + 0.5;
  if FV > 12 then FV := 12;
  FX := FX + FV * F.X / L;
  FY := FY + FV * F.Y / L;
  SetBounds(Round(FX), Round(FY), Width, Height);
  // raakt hij een pool, een magneet of een spijker die al vastzit?
  Raakt := False;
  Pl := MagAllePolen(Parent);
  CX := Left + Width / 2;
  CY := Top + Height / 2;
  A := IJzerL / 2 - 3;
  // afstand van elke pool tot de spijker (een lijnstuk van punt tot kop)
  for i := 0 to High(Pl) do
  begin
    if FGedraaid then
    begin
      EX := CX;
      EY := Pl[i].P.Y;
      if EY < CY - A then EY := CY - A;
      if EY > CY + A then EY := CY + A;
    end
    else
    begin
      EY := CY;
      EX := Pl[i].P.X;
      if EX < CX - A then EX := CX - A;
      if EX > CX + A then EX := CX + A;
    end;
    if Sqr(EX - Pl[i].P.X) + Sqr(EY - Pl[i].P.Y) < Sqr(IJzerContact) then
      Raakt := True;
  end;
  // tegen een magneet of een spijker die al vastzit: terug tot hij hem net raakt
  if OverlaptIets then
  begin
    Raakt := True;
    i := 0;
    while OverlaptIets and (i < 16) do
    begin
      FX := FX - F.X / L;
      FY := FY - F.Y / L;
      SetBounds(Round(FX), Round(FY), Width, Height);
      Inc(i);
    end;
  end;
  if Raakt then
  begin
    FVast := True;
    FTrekt := False;
    FV := 0;
    UpdateHintText;
  end;
  Invalidate;
end;

procedure TjanIJzer.Terugleggen;
begin
  FTrekt := False;
  FVast := False;
  SetBounds(FThuis.X, FThuis.Y, Width, Height);
  Invalidate;
end;

procedure TjanIJzer.TerugClick(Sender: TObject);
begin
  if not FLock then Terugleggen;
end;

procedure TjanIJzer.AddMenuItems(APop: TPopupMenu);
var
  Mi: TMenuItem;
begin
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Terugleggen', 'Put back', 'Remettre en place', 'Zurücklegen');
  Mi.Enabled := not FLock;
  Mi.OnClick := TerugClick;
  APop.Items.Add(Mi);
end;

procedure TjanIJzer.Paint;
var
  P: array[0..2] of TPoint;
begin
  with Canvas do
  begin
    Pen.Color := RGBToColor(60, 60, 70);
    Pen.Width := 1;
    Pen.Style := psSolid;
    Brush.Style := bsSolid;
    // kop
    Brush.Color := RGBToColor(100, 100, 110);
    FillRect(TRc(0, 0, 5, IJzerB));
    // schacht
    Brush.Color := RGBToColor(150, 150, 160);
    FillRect(TRc(5, 4, IJzerL - 9, IJzerB - 4));
    Brush.Style := bsClear;
    Rectangle(TRc(0, 0, 5, IJzerB));
    Rectangle(TRc(5, 4, IJzerL - 9, IJzerB - 4));
    // punt
    Brush.Style := bsSolid;
    Brush.Color := RGBToColor(150, 150, 160);
    P[0] := TP(IJzerL - 9, 4);
    P[1] := TP(IJzerL - 1, IJzerB div 2);
    P[2] := TP(IJzerL - 9, IJzerB - 4);
    Polygon(P);
  end;
  PaintSelection;
end;

procedure TjanIJzer.UpdateHintText;
var
  S: string;
begin
  if FVast then
    S := Tr(FTaal, 'Hij hangt vast aan de magneet. Rechtsklik: terugleggen.',
      'It is stuck to the magnet. Right-click: put back.',
      'Il est collé à l''aimant. Clic droit : remettre en place.',
      'Er hängt am Magneten. Rechtsklick: zurücklegen.')
  else
    S := Format(Tr(FTaal, 'Trekkracht hier: %s %% van wat nodig is om hem te verschuiven.',
      'Pulling force here: %s %% of what is needed to move it.',
      'Force d''attraction ici : %s %% de ce qu''il faut pour le déplacer.',
      'Zugkraft hier: %s %% dessen, was nötig ist, um ihn zu verschieben.'),
      [FormatFloat('0', Trekkracht * 100)]);
  Hint := Tr(FTaal, 'Spijker (ijzer)', 'Nail (iron)', 'Clou (fer)', 'Nagel (Eisen)') + #13#10 +
    Tr(FTaal,
      'Een magneet of een spoel met stroom trekt hem aan zodra het veld sterk genoeg is.' + #13#10 +
        'Hoe dichter bij een pool, hoe groter de kracht.',
      'A magnet or a coil with a current pulls it as soon as the field is strong enough.' + #13#10 +
        'The closer to a pole, the larger the force.',
      'Un aimant ou une bobine parcourue par un courant l''attire dès que le champ est assez fort.' + #13#10 +
        'Plus il est près d''un pôle, plus la force est grande.',
      'Ein Magnet oder eine Spule mit Strom zieht ihn an, sobald das Feld stark genug ist.' + #13#10 +
        'Je näher an einem Pol, desto größer die Kraft.') + #13#10 + S;
end;

procedure TjanIJzer.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Tr(FTaal, 'Spijker (ijzer)', 'Nail (iron)', 'Clou (fer)', 'Nagel (Eisen)') + ' > ', 0);
  FOnStatus(Self, FormatFloat('0', Trekkracht * 100) + ' %', 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

{ TjanRelaisModel }

const
  RelaisW = 170;
  RelaisH = 140;
  RelaisSpoelR = 120;        // ohm: 100 mA bij 12 V
  RelaisAantrek = 0.035;     // A: vanaf hier trekt de kern het anker aan
  RelaisHoud = 0.020;        // A: een aangetrokken anker blijft tot hier
  RelaisSterkteK = 40;       // magnetische sterkte per ampère (met de kern)

constructor TjanRelaisModel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := RelaisW;
  Height := RelaisH;
  HelpKeyword := 'magnetisme';
  FTimer := TTimer.Create(Self);
  FTimer.Interval := 40;
  FTimer.OnTimer := Tik;
  FTimer.Enabled := True;
end;

procedure TjanRelaisModel.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
  MagneetVeranderd(Parent);
end;

function TjanRelaisModel.PinCount: Integer;
begin
  Result := 5;
end;

function TjanRelaisModel.PinPos(I: Integer): TPoint;
begin
  case I of
    0: Result := Point(20, RelaisH - 8);
    1: Result := Point(150, RelaisH - 8);
    2: Result := Point(RelaisW - 8, 50);
    3: Result := Point(1, 59);
  else
    Result := Point(1, 13);
  end;
end;

function TjanRelaisModel.MaakDicht: Boolean;
begin
  Result := FPos >= 0.9;
end;

function TjanRelaisModel.VerbreekDicht: Boolean;
begin
  Result := FPos <= 0.15;
end;

function TjanRelaisModel.SpoelOhm: Double;
begin
  Result := RelaisSpoelR;
end;

function TjanRelaisModel.Sterkte: Double;
begin
  Result := RelaisSterkteK * FAmp;
end;

procedure TjanRelaisModel.Polen(out PN, PZ: TMagVec);
begin
  // de kern staat rechtop: x = 83, van y = 64 tot 112
  PN := MagV(Left + 83, Top + 68);
  PZ := MagV(Left + 83, Top + 108);
end;

// het anker beweegt met een veer en een beetje traagheid: zo trilt het in
// een bel echt heen en weer
procedure TjanRelaisModel.Tik(Sender: TObject);
var
  Trek: Boolean;
  OudM, OudV: Boolean;
  OudPos: Double;
begin
  if (Parent = nil) or not Visible then Exit;
  if FPos >= 0.9 then Trek := Abs(FAmp) >= RelaisHoud
  else Trek := Abs(FAmp) >= RelaisAantrek;
  if (FPos <= 0) and (FV = 0) and not Trek then
  begin
    if FTrilt > 0 then begin Dec(FTrilt); Invalidate; end;
    Exit;
  end;
  if (FPos >= 1) and (FV = 0) and Trek then
  begin
    if FTrilt > 0 then begin Dec(FTrilt); Invalidate; end;
    Exit;
  end;
  OudM := MaakDicht;
  OudV := VerbreekDicht;
  OudPos := FPos;
  if Trek then FV := FV + 0.06 else FV := FV - 0.04;
  FV := FV * 0.85;
  FPos := FPos + FV;
  if FPos >= 1 then begin FPos := 1; FV := 0; end;
  if FPos <= 0 then begin FPos := 0; FV := 0; end;
  // heen en weer zonder aan te komen: een bel
  if (FPos > 0.05) and (FPos < 0.95) and (Abs(FPos - OudPos) > 0.001) then FTrilt := 12
  else if FTrilt > 0 then Dec(FTrilt);
  Invalidate;
  if (OudM <> MaakDicht) or (OudV <> VerbreekDicht) then
  begin
    UpdateHintText;
    UpdateSupply(Parent, True);
  end;
end;

procedure TjanRelaisModel.Paint;
var
  i, TipY, HX, HY, VX, VY: Integer;
  S: Double;

  function LeverY(X: Integer): Integer;
  begin
    Result := HY + Round((HX - X) * (TipY - HY) / (HX - 12));
  end;

  procedure Pool(const APlek: TRect; AKleur: TColor; const AT: string);
  begin
    with Canvas do
    begin
      Brush.Style := bsSolid;
      Brush.Color := AKleur;
      FillRect(APlek);
      Font.Name := 'Arial';
      Font.Size := 7;
      Font.Style := [fsBold];
      Font.Color := clWhite;
      Brush.Style := bsClear;
      TextOut((APlek.Left + APlek.Right - TextWidth(AT)) div 2, (APlek.Top + APlek.Bottom - TextHeight(AT)) div 2, AT);
    end;
  end;

begin
  HX := 148;
  HY := 53;
  TipY := 22 + Round(FPos * 36);
  with Canvas do
  begin
    Pen.Style := psSolid;
    Pen.Width := 1;
    // juk: onder en rechts, met het scharnier bovenaan
    Brush.Style := bsSolid;
    Brush.Color := RGBToColor(140, 140, 150);
    FillRect(Rect(74, 112, 152, 120));
    FillRect(Rect(144, 58, 152, 120));
    // kern
    FillRect(Rect(74, 64, 92, 112));
    Pen.Color := RGBToColor(80, 80, 90);
    Brush.Style := bsClear;
    Rectangle(Rect(74, 64, 92, 112));
    // windingen
    Pen.Color := RGBToColor(184, 100, 30);
    Pen.Width := 2;
    i := 68;
    while i <= 104 do
    begin
      Ellipse(Rect(66, i, 101, i + 7));
      Inc(i, 5);
    end;
    // aansluitdraadjes van de spoel naar de klemmen onderaan
    Pen.Color := clBlack;
    MoveTo(PinPos(0).X + 3, PinPos(0).Y); LineTo(PinPos(0).X + 3, 106); LineTo(67, 106);
    MoveTo(PinPos(1).X + 3, PinPos(1).Y); LineTo(PinPos(1).X + 3, 127); LineTo(104, 127); LineTo(104, 72); LineTo(100, 72);
    // vaste contacten links: verbreekcontact boven, maakcontact onder
    MoveTo(PinPos(4).X + 6, PinPos(4).Y + 3); LineTo(22, PinPos(4).Y + 3);
    MoveTo(PinPos(3).X + 6, PinPos(3).Y + 3); LineTo(22, PinPos(3).Y + 3);
    // gemeenschappelijk contact rechts naar het scharnier
    MoveTo(PinPos(2).X, PinPos(2).Y + 3); LineTo(HX, HY);
    Pen.Width := 1;
    Brush.Style := bsSolid;
    if VerbreekDicht then Brush.Color := RGBToColor(230, 60, 60) else Brush.Color := RGBToColor(200, 200, 200);
    Ellipse(Rect(14, PinPos(4).Y + 4, 22, PinPos(4).Y + 9));
    if MaakDicht then Brush.Color := RGBToColor(230, 60, 60) else Brush.Color := RGBToColor(200, 200, 200);
    Ellipse(Rect(14, PinPos(3).Y - 3, 22, PinPos(3).Y + 2));
    // veer van het anker naar boven
    Pen.Color := RGBToColor(90, 90, 90);
    VX := 122;
    VY := LeverY(VX);
    MoveTo(VX, VY);
    for i := 1 to 8 do
      LineTo(VX + 4 * (2 * (i mod 2) - 1), VY - Round(i * (VY - 6) / 9));
    LineTo(VX, 6);
    Brush.Color := RGBToColor(120, 120, 120);
    FillRect(Rect(VX - 8, 2, VX + 9, 6));
    // het anker (ijzer) op het scharnier
    Pen.Color := RGBToColor(70, 70, 80);
    Pen.Width := 6;
    MoveTo(HX, HY);
    LineTo(14, TipY);
    Pen.Width := 1;
    Brush.Color := clBlack;
    Ellipse(Rect(HX - 3, HY - 3, HX + 4, HY + 4));
    // trilt het anker: de bel rinkelt
    if FTrilt > 0 then
    begin
      Pen.Color := RGBToColor(200, 120, 0);
      Pen.Width := 2;
      Brush.Style := bsClear;
      Arc(30, 22, 50, 46, 50, 22, 50, 46);
      Arc(38, 16, 62, 52, 62, 16, 62, 52);
      Pen.Width := 1;
    end;
    // namen van de contacten
    Brush.Style := bsClear;
    Font.Name := 'Arial';
    Font.Size := 6;
    Font.Style := [];
    Font.Color := RGBToColor(60, 60, 60);
    TextOut(10, PinPos(4).Y - 10, Tr(FTaal, 'verbreek', 'NC', 'repos', 'Öffner'));
    TextOut(10, PinPos(3).Y + 10, Tr(FTaal, 'maak', 'NO', 'travail', 'Schließer'));
    TextOut(PinPos(2).X - 4, PinPos(2).Y - 10, 'C');
    // polen van de kern als er stroom loopt
    S := Sterkte;
    if Abs(S) > 0.05 then
    begin
      if S > 0 then
      begin
        Pool(Rect(52, 64, 64, 74), RGBToColor(215, 40, 40), 'N');
        Pool(Rect(52, 100, 64, 110), RGBToColor(40, 90, 200), Tr(FTaal, 'Z', 'S', 'S', 'S'));
      end
      else
      begin
        Pool(Rect(52, 64, 64, 74), RGBToColor(40, 90, 200), Tr(FTaal, 'Z', 'S', 'S', 'S'));
        Pool(Rect(52, 100, 64, 110), RGBToColor(215, 40, 40), 'N');
      end;
    end;
  end;
  for i := 0 to 4 do
    PaintPin(PinPos(i).X, PinPos(i).Y, FPinV[i] >= RailMinVolt);
  PaintSelection;
end;

procedure TjanRelaisModel.UpdateHintText;
var
  S: string;
begin
  if MaakDicht then
    S := Tr(FTaal, 'Het anker is aangetrokken: het maakcontact is dicht, het verbreekcontact open.',
      'The armature is pulled in: the NO contact is closed, the NC contact open.',
      'L''armature est attirée : le contact travail est fermé, le contact repos ouvert.',
      'Der Anker ist angezogen: Der Schließer ist geschlossen, der Öffner offen.')
  else if VerbreekDicht then
    S := Tr(FTaal, 'Het anker rust: het verbreekcontact is dicht, het maakcontact open.',
      'The armature is at rest: the NC contact is closed, the NO contact open.',
      'L''armature est au repos : le contact repos est fermé, le contact travail ouvert.',
      'Der Anker ruht: Der Öffner ist geschlossen, der Schließer offen.')
  else
    S := Tr(FTaal, 'Het anker beweegt: beide contacten zijn open.',
      'The armature is moving: both contacts are open.',
      'L''armature bouge : les deux contacts sont ouverts.',
      'Der Anker bewegt sich: Beide Kontakte sind offen.');
  Hint := Tr(FTaal, 'Relais (open model)', 'Relay (open model)', 'Relais (modèle ouvert)', 'Relais (offenes Modell)') + #13#10 +
    Format(Tr(FTaal, 'Spoel: %s; stroom %s (het anker komt vanaf %s).',
      'Coil: %s; current %s (the armature moves from %s).',
      'Bobine : %s ; courant %s (l''armature bouge à partir de %s).',
      'Spule: %s; Strom %s (der Anker bewegt sich ab %s).'),
      [OhmText(RelaisSpoelR), AmpText(Abs(FAmp)), AmpText(RelaisAantrek)]) + #13#10 +
    S + #13#10 +
    Tr(FTaal,
      'Klemmen: onderaan de spoel, rechts het gemeenschappelijke contact C, links het maakcontact en het verbreekcontact.' + #13#10 +
        'Zet je de spoel in serie met het eigen verbreekcontact, dan trilt het anker: een elektrische bel.',
      'Terminals: the coil at the bottom, the common contact C on the right, the NO and NC contacts on the left.' + #13#10 +
        'Put the coil in series with its own NC contact and the armature vibrates: an electric bell.',
      'Bornes : la bobine en bas, le contact commun C à droite, les contacts travail et repos à gauche.' + #13#10 +
        'Mettez la bobine en série avec son propre contact repos : l''armature vibre, c''est une sonnette électrique.',
      'Klemmen: unten die Spule, rechts der gemeinsame Kontakt C, links Schließer und Öffner.' + #13#10 +
        'Schaltet man die Spule in Reihe mit ihrem eigenen Öffner, vibriert der Anker: eine elektrische Klingel.');
end;

procedure TjanRelaisModel.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Tr(FTaal, 'Relais (open model)', 'Relay (open model)', 'Relais (modèle ouvert)', 'Relais (offenes Modell)') + ' > ', 0);
  FOnStatus(Self, 'I = ' + FormatFloat('0', Abs(FAmp) * 1000) + ' mA', 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;

{ TjanSchommel }

const
  SchommelW = 240;
  SchommelH = 150;
  SchommelL = 82;            // lengte van de ophangdraadjes
  SchommelK = 2.7;           // tan(uitslag) per eenheid kracht
  SchommelMax = 0.55;        // grootste uitslag (radialen): het staafje blijft tussen de polen

constructor TjanSchommel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := SchommelW;
  Height := SchommelH;
  HelpKeyword := 'magnetisme';
  FTimer := TTimer.Create(Self);
  FTimer.Interval := 40;
  FTimer.OnTimer := Tik;
  FTimer.Enabled := True;
end;

function TjanSchommel.KanDraaien: Boolean;
begin
  Result := False;
end;

function TjanSchommel.StdMaat: TPoint;
begin
  Result := Point(SchommelW, SchommelH);
end;

function TjanSchommel.ExtraBreedte: Integer;
begin
  Result := 0;
end;

function TjanSchommel.PinPos(I: Integer): TPoint;
begin
  if I = 0 then Result := Point(1, 1) else Result := Point(132, 1);
end;

function TjanSchommel.Ohm: Double;
begin
  Result := 2;
end;

// de stroom van klem 0 naar klem 1 gaat het scherm in; met de noordpool
// boven loopt het veld omlaag, en dan duwt de kracht het staafje naar links
function TjanSchommel.Kracht: Double;
var
  B: Double;
begin
  if FSterk then B := 2 else B := 1;
  if FOmgekeerd then B := -B;
  Result := -B * FAmp;
end;

function TjanSchommel.DoelHoek: Double;
begin
  Result := ArcTan(SchommelK * Kracht);
  if Result > SchommelMax then Result := SchommelMax;
  if Result < -SchommelMax then Result := -SchommelMax;
end;

// het staafje zwaait als een slinger naar zijn nieuwe stand
procedure TjanSchommel.Tik(Sender: TObject);
var
  Doel: Double;
begin
  if (Parent = nil) or not Visible then Exit;
  Doel := DoelHoek;
  if (Abs(Doel - FHoek) < 0.002) and (Abs(FHoekV) < 0.002) then
  begin
    if (FHoek <> Doel) or (FHoekV <> 0) then
    begin
      FHoek := Doel;
      FHoekV := 0;
      Invalidate;
    end;
    Exit;
  end;
  FHoekV := (FHoekV + (Doel - FHoek) * 0.15) * 0.8;
  FHoek := FHoek + FHoekV;
  if FHoek > SchommelMax then begin FHoek := SchommelMax; FHoekV := 0; end;
  if FHoek < -SchommelMax then begin FHoek := -SchommelMax; FHoekV := 0; end;
  Invalidate;
end;

procedure TjanSchommel.SetOmgekeerd(const Value: Boolean);
begin
  if Value = FOmgekeerd then Exit;
  FOmgekeerd := Value;
  UpdateHintText;
  Invalidate;
end;

procedure TjanSchommel.SetSterk(const Value: Boolean);
begin
  if Value = FSterk then Exit;
  FSterk := Value;
  UpdateHintText;
  Invalidate;
end;

procedure TjanSchommel.OmdraaiClick(Sender: TObject);
begin
  if not FLock then Omgekeerd := not Omgekeerd;
end;

procedure TjanSchommel.SterkClick(Sender: TObject);
begin
  if not FLock then Sterk := not Sterk;
end;

procedure TjanSchommel.AddMenuItems(APop: TPopupMenu);
var
  Mi: TMenuItem;
begin
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Magneet omdraaien (N en Z wisselen)', 'Turn the magnet round (swap N and S)',
    'Retourner l''aimant (échanger N et S)', 'Magnet umdrehen (N und S tauschen)');
  Mi.Enabled := not FLock;
  Mi.OnClick := OmdraaiClick;
  APop.Items.Add(Mi);
  Mi := TMenuItem.Create(APop);
  Mi.Caption := Tr(FTaal, 'Sterke magneet', 'Strong magnet', 'Aimant puissant', 'Starker Magnet');
  Mi.Checked := FSterk;
  Mi.Enabled := not FLock;
  Mi.OnClick := SterkClick;
  APop.Items.Add(Mi);
end;

procedure TjanSchommel.Paint;
var
  i, X, RX, RY: Integer;
  F, L: Double;
  BovenKl, OnderKl: TColor;
  BovenT, OnderT: string;
  Omlaag: Boolean;

  procedure Pijlkop(AX, AY, DX, DY: Integer);
  begin
    Canvas.Polygon([Point(AX, AY), Point(AX - 4 * DX - 3 * DY, AY - 4 * DY - 3 * DX),
      Point(AX - 4 * DX + 3 * DY, AY - 4 * DY + 3 * DX)]);
  end;

begin
  if FOmgekeerd then
  begin
    BovenKl := RGBToColor(40, 90, 200); OnderKl := RGBToColor(215, 40, 40);
    BovenT := Tr(FTaal, 'Z', 'S', 'S', 'S'); OnderT := 'N';
  end
  else
  begin
    BovenKl := RGBToColor(215, 40, 40); OnderKl := RGBToColor(40, 90, 200);
    BovenT := 'N'; OnderT := Tr(FTaal, 'Z', 'S', 'S', 'S');
  end;
  Omlaag := not FOmgekeerd;   // veldlijnen van N naar Z
  with Canvas do
  begin
    Pen.Style := psSolid;
    Pen.Width := 1;
    // U-magneet, van opzij: twee poolstukken en de rug rechts
    Brush.Style := bsSolid;
    Brush.Color := RGBToColor(150, 150, 150);
    FillRect(Rect(122, 36, 134, 144));
    Brush.Color := BovenKl;
    FillRect(Rect(14, 36, 134, 56));
    Brush.Color := OnderKl;
    FillRect(Rect(14, 124, 134, 144));
    if FSterk then
    begin
      Pen.Color := clBlack;
      Pen.Width := 2;
      Brush.Style := bsClear;
      Rectangle(Rect(14, 36, 134, 144));
      Pen.Width := 1;
    end;
    Brush.Style := bsClear;
    Font.Name := 'Arial';
    Font.Size := 9;
    Font.Style := [fsBold];
    Font.Color := clWhite;
    TextOut(20, 39, BovenT);
    TextOut(20, 127, OnderT);
    // veldlijnen tussen de polen
    Pen.Color := RGBToColor(110, 110, 110);
    Brush.Style := bsSolid;
    Brush.Color := RGBToColor(110, 110, 110);
    for i := 0 to 3 do
    begin
      case i of
        0: X := 26;
        1: X := 44;
        2: X := 96;
      else
        X := 112;
      end;
      Pen.Style := psDot;
      MoveTo(X, 58); LineTo(X, 122);
      Pen.Style := psSolid;
      if Omlaag then Pijlkop(X, 94, 0, 1) else Pijlkop(X, 86, 0, -1);
    end;
    // ophanging: de klemmen bovenaan en een staafje als as
    Pen.Color := clBlack;
    Pen.Width := 2;
    MoveTo(PinPos(0).X + 6, PinPos(0).Y + 3); LineTo(PinPos(1).X, PinPos(1).Y + 3);
    MoveTo(70, 4); LineTo(70, 9);
    Pen.Width := 1;
    // het staafje (van opzij gezien: een rondje) aan zijn draadjes
    RX := 70 + Round(SchommelL * Sin(FHoek));
    RY := 8 + Round(SchommelL * Cos(FHoek));
    MoveTo(70, 8); LineTo(RX, RY);
    Brush.Style := bsSolid;
    Brush.Color := RGBToColor(200, 120, 50);
    Pen.Color := RGBToColor(120, 60, 20);
    Ellipse(RX - 8, RY - 8, RX + 9, RY + 9);
    // stroomrichting: kruisje = het scherm in, stip = het scherm uit
    Pen.Color := clBlack;
    if FAmp > 0.0005 then
    begin
      Pen.Width := 2;
      MoveTo(RX - 4, RY - 4); LineTo(RX + 5, RY + 5);
      MoveTo(RX + 4, RY - 4); LineTo(RX - 5, RY + 5);
      Pen.Width := 1;
    end
    else if FAmp < -0.0005 then
    begin
      Brush.Color := clBlack;
      Ellipse(RX - 2, RY - 2, RX + 3, RY + 3);
    end;
    // krachtpijl
    F := Kracht;
    if Abs(F) > 0.002 then
    begin
      L := 10 + 200 * Abs(F);
      if L > 34 then L := 34;
      if F > 0 then X := 1 else X := -1;
      Pen.Color := clYellow;
      Pen.Width := 3;
      MoveTo(RX + X * 10, RY);
      LineTo(RX + X * Round(L), RY);
      Pen.Width := 1;
      Pen.Color := clBlack;
      Brush.Color := clYellow;
      Pijlkop(RX + X * (Round(L) + 5), RY, X, 0);
    end;
  end;
  TekenSchuin;
  PaintPin(PinPos(0).X, PinPos(0).Y, FInVolt >= RailMinVolt);
  PaintPin(PinPos(1).X, PinPos(1).Y, FUitVolt >= RailMinVolt);
  PaintSelection;
end;

// rechts een klein schuin tekeningetje: het staafje (een stuk dik koperdraad)
// hangt aan twee draadjes in de opening van de U-magneet; de stroom loopt via
// het ene draadje door het staafje en via het andere terug
procedure TjanSchommel.TekenSchuin;
const
  OX = 150; OY = 40; DX = 24; DY = -14;
var
  S, MX, MY: Double;
  E1, E2, H1, H2: TPoint;
  BovenKl, OnderKl, BovenL, OnderL: TColor;
  BovenT, OnderT: string;
  UX, UY: Double;

  function Pt(AX, AY: Double): TPoint;
  begin
    Result := Point(Round(AX), Round(AY));
  end;

begin
  if FOmgekeerd then
  begin
    BovenKl := RGBToColor(40, 90, 200); OnderKl := RGBToColor(215, 40, 40);
    BovenL := RGBToColor(150, 175, 230); OnderL := RGBToColor(240, 160, 160);
    BovenT := Tr(FTaal, 'Z', 'S', 'S', 'S'); OnderT := 'N';
  end
  else
  begin
    BovenKl := RGBToColor(215, 40, 40); OnderKl := RGBToColor(40, 90, 200);
    BovenL := RGBToColor(240, 160, 160); OnderL := RGBToColor(150, 175, 230);
    BovenT := 'N'; OnderT := Tr(FTaal, 'Z', 'S', 'S', 'S');
  end;
  // het staafje: midden in de opening, iets opzij als het uitzwaait
  S := 22 * Sin(FHoek);
  MX := OX + 30 + DX / 2;
  MY := OY + 50 + DY / 2;
  H1 := Pt(MX - 0.85 * DX, MY - 0.85 * DY - 58);
  H2 := Pt(MX + 0.85 * DX, MY + 0.85 * DY - 58);
  E1 := Pt(MX + S - 0.85 * DX, MY - 0.85 * DY);
  E2 := Pt(MX + S + 0.85 * DX, MY + 0.85 * DY);
  with Canvas do
  begin
    Pen.Style := psSolid;
    Pen.Width := 1;
    Pen.Color := RGBToColor(90, 90, 90);
    Brush.Style := bsSolid;
    // rug van de U (zijvlak) en de bovenkant van het onderste poolstuk
    Brush.Color := RGBToColor(120, 120, 120);
    Polygon([Point(OX + 64, OY + 14), Point(OX + 64 + DX, OY + 14 + DY),
      Point(OX + 64 + DX, OY + 86 + DY), Point(OX + 64, OY + 86)]);
    Brush.Color := OnderL;
    Polygon([Point(OX, OY + 74), Point(OX + 64, OY + 74),
      Point(OX + 64 + DX, OY + 74 + DY), Point(OX + DX, OY + 74 + DY)]);
    // ophanging en het achterste draadje
    Pen.Color := clBlack;
    Pen.Width := 2;
    MoveTo(H1.X, H1.Y); LineTo(H2.X, H2.Y);
    Pen.Width := 1;
    MoveTo(H2.X, H2.Y); LineTo(E2.X, E2.Y);
    // het staafje van koper
    Pen.Color := RGBToColor(150, 80, 25);
    Pen.Width := 5;
    MoveTo(E1.X, E1.Y); LineTo(E2.X, E2.Y);
    Pen.Width := 1;
    // stroomrichting langs het staafje
    if Abs(FAmp) > 0.0005 then
    begin
      if FAmp > 0 then begin UX := DX; UY := DY; end else begin UX := -DX; UY := -DY; end;
      UX := UX / Sqrt(DX * DX + DY * DY);
      UY := UY / Sqrt(DX * DX + DY * DY);
      Pen.Color := clBlack;
      Brush.Color := RGBToColor(220, 0, 0);
      Polygon([Pt(MX + S + 7 * UX, MY + 7 * UY - 6), Pt(MX + S - 4 * UX - 4 * UY, MY - 4 * UY + 4 * UX - 6),
        Pt(MX + S - 4 * UX + 4 * UY, MY - 4 * UY - 4 * UX - 6)]);
    end;
    // het bovenste poolstuk, de voorkant van de rug en van het onderste poolstuk
    Pen.Color := RGBToColor(90, 90, 90);
    Brush.Color := BovenL;
    Polygon([Point(OX, OY + 14), Point(OX + 64, OY + 14),
      Point(OX + 64 + DX, OY + 14 + DY), Point(OX + DX, OY + 14 + DY)]);
    Brush.Color := BovenKl;
    FillRect(Rect(OX, OY + 14, OX + 56, OY + 27));
    Brush.Color := RGBToColor(150, 150, 150);
    FillRect(Rect(OX + 56, OY + 14, OX + 64, OY + 87));
    Brush.Color := OnderKl;
    FillRect(Rect(OX, OY + 74, OX + 56, OY + 87));
    Brush.Style := bsClear;
    Font.Name := 'Arial';
    Font.Size := 7;
    Font.Style := [fsBold];
    Font.Color := clWhite;
    TextOut(OX + 3, OY + 14, BovenT);
    TextOut(OX + 3, OY + 74, OnderT);
    // het voorste draadje
    Pen.Color := clBlack;
    MoveTo(H1.X, H1.Y); LineTo(E1.X, E1.Y);
    // uitleg onder het tekeningetje
    Font.Size := 6;
    Font.Style := [];
    Font.Color := RGBToColor(90, 90, 90);
    TextOut(OX - 4, OY + 92, Tr(FTaal, 'schuin gezien', 'seen at an angle', 'vue en biais', 'schräg gesehen'));
    TextOut(OX - 4, OY + 101, Tr(FTaal, 'links: van opzij', 'left: from the side', 'à gauche : de côté', 'links: von der Seite'));
  end;
end;

procedure TjanSchommel.UpdateHintText;
var
  S: string;
  F: Double;
begin
  F := Kracht;
  if Abs(FAmp) <= 0.0005 then
    S := Tr(FTaal, 'Er loopt geen stroom: geen kracht, het staafje hangt recht.',
      'No current flows: no force, the rod hangs straight.',
      'Aucun courant : pas de force, la tige pend droite.',
      'Es fließt kein Strom: keine Kraft, der Stab hängt gerade.')
  else
  begin
    if FAmp > 0 then
      S := Tr(FTaal, 'De stroom gaat het scherm in (kruisje).', 'The current goes into the screen (cross).',
        'Le courant entre dans l''écran (croix).', 'Der Strom fließt in den Bildschirm hinein (Kreuz).')
    else
      S := Tr(FTaal, 'De stroom komt het scherm uit (stip).', 'The current comes out of the screen (dot).',
        'Le courant sort de l''écran (point).', 'Der Strom kommt aus dem Bildschirm heraus (Punkt).');
    if F > 0 then
      S := S + ' ' + Tr(FTaal, 'De kracht duwt het staafje naar rechts.', 'The force pushes the rod to the right.',
        'La force pousse la tige vers la droite.', 'Die Kraft schiebt den Stab nach rechts.')
    else
      S := S + ' ' + Tr(FTaal, 'De kracht duwt het staafje naar links.', 'The force pushes the rod to the left.',
        'La force pousse la tige vers la gauche.', 'Die Kraft schiebt den Stab nach links.');
  end;
  Hint := Tr(FTaal, 'Stroomschommel', 'Current swing', 'Balançoire électrique', 'Leiterschaukel') + #13#10 +
    Tr(FTaal,
      'Een koperen staafje (een stuk dik koperdraad) hangt aan twee draadjes tussen de polen van een U-magneet.' + #13#10 +
        'De stroom loopt via het ene draadje door het staafje en via het andere terug.' + #13#10 +
        'Links zie je het van opzij (het staafje is het rondje), rechts schuin.',
      'A copper rod (a piece of thick copper wire) hangs on two thin wires between the poles of a U-magnet.' + #13#10 +
        'The current flows down one thin wire, through the rod and back up the other.' + #13#10 +
        'On the left you see it from the side (the rod is the circle), on the right at an angle.',
      'Une tige de cuivre (un morceau de gros fil de cuivre) pend à deux fils fins entre les pôles d''un aimant en U.' + #13#10 +
        'Le courant descend par un fil, traverse la tige et remonte par l''autre.' + #13#10 +
        'À gauche on la voit de côté (la tige est le cercle), à droite en biais.',
      'Ein Kupferstab (ein Stück dicker Kupferdraht) hängt an zwei dünnen Drähten zwischen den Polen eines U-Magneten.' + #13#10 +
        'Der Strom fließt über den einen Draht durch den Stab und über den anderen zurück.' + #13#10 +
        'Links sieht man ihn von der Seite (der Stab ist der Kreis), rechts schräg.') + #13#10 +
    StroomRegel(FStroom) + #13#10 + S + #13#10 +
    Tr(FTaal,
      'Linkerhandregel: de veldlijnen (van N naar Z) komen in je handpalm, je vingers wijzen met de stroom mee; je duim wijst de kracht aan.',
      'Left-hand rule: the field lines (from N to S) enter your palm, your fingers point along the current; your thumb shows the force.',
      'Règle de la main gauche : les lignes de champ (de N à S) entrent dans la paume, les doigts suivent le courant ; le pouce indique la force.',
      'Linke-Hand-Regel: Die Feldlinien (von N nach S) treten in die Handfläche, die Finger zeigen in Stromrichtung; der Daumen zeigt die Kraft.') + #13#10 +
    Tr(FTaal, 'Rechtsklik: magneet omdraaien of sterke magneet.',
      'Right-click: turn the magnet round or strong magnet.',
      'Clic droit : retourner l''aimant ou aimant puissant.',
      'Rechtsklick: Magnet umdrehen oder starker Magnet.');
end;

procedure TjanSchommel.SendStatusToBar;
begin
  if not Assigned(FOnStatus) then Exit;
  FOnStatus(Self, Tr(FTaal, 'Stroomschommel', 'Current swing', 'Balançoire électrique', 'Leiterschaukel') + ' > ', 0);
  FOnStatus(Self, 'I = ' + FormatFloat('0', FStroom * 1000) + ' mA', 1);
  FOnStatus(Self, Format('X=%d Y=%d', [Left, Top]), 2);
end;
