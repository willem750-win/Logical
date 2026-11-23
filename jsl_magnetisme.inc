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
