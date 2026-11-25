unit uWelkom;

{ Welkomstvenster bij het opstarten en een rondleiding in stappen door het
  hoofdscherm, voor wie Logic voor het eerst gebruikt.

  TWelkomForm: grote knoppen (begin met les 1, rondleiding, leerpad, leeg
  paneel), taalkeuze en een vinkje "Toon dit venster bij het opstarten".
  Het hoofdvenster doet de keuze via ShowModal en Keuze en wisselt de taal via OnTaal.

  TRondleiding: een tekstballon met Vorige / Volgende / Sluiten en een rood
  kader rond het onderdeel van het scherm waar de stap over gaat. Het kader
  bestaat uit vier smalle vensters zonder rand (werkt ook onder Linux). }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Graphics, uLangPo, uNiveau;

type
  TWelkomKeuze = (wkLes1, wkRondleiding, wkLeerpad, wkLeeg);
  TWelkomTaalEvent = procedure(AIndex: Integer) of object;

  { TWelkomForm }

  TWelkomForm = class(TForm)
  private
    FTaal: string;
    FTitel, FIntro, FTaalLabel, FNiveauLabel, FNiveauUitleg: TLabel;
    FTaalBox, FNiveauBox: TComboBox;
    FKnop: array[TWelkomKeuze] of TButton;
    FUitleg: array[TWelkomKeuze] of TLabel;
    FToon: TCheckBox;
    FKeuze: TWelkomKeuze;
    FOnTaal: TWelkomTaalEvent;
    FOnNiveau: TWelkomTaalEvent;
    FBezig: Boolean;
    function T(const NL, EN, FR, DE: string): string;
    procedure KnopClick(Sender: TObject);
    procedure TaalBoxChange(Sender: TObject);
    procedure NiveauBoxChange(Sender: TObject);
    procedure ToonNiveauUitleg;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  public
    constructor CreateWelkom(AOwner: TComponent; ATalen: TStrings; ATaalIndex: Integer);
    procedure SetTaal(const ATaal: string; ATaalIndex: Integer);
    // het niveau in de keuzelijst zetten (plaats in NiveauVolgorde van uNiveau)
    procedure SetNiveau(AIndex: Integer);
    // voor elke keer dat het venster getoond wordt: sluiten met het kruisje
    // is "Leeg paneel", en het vinkje volgt wat bewaard is
    procedure Voorbereid(AToon: Boolean);
    function ToonBijStart: Boolean;
    property Keuze: TWelkomKeuze read FKeuze;
    property OnTaal: TWelkomTaalEvent read FOnTaal write FOnTaal;
    // niveau gekozen: AIndex = plaats in NiveauVolgorde
    property OnNiveau: TWelkomTaalEvent read FOnNiveau write FOnNiveau;
  end;

  { TRondleiding }

  TRondStap = record
    Doel: TControl;
    Tekst: array[0..3] of string;   // NL, EN, FR, DE
  end;

  TRondleiding = class(TComponent)
  private
    FTaal: string;
    FStappen: array of TRondStap;
    FNr: Integer;
    FBallon: TForm;
    FKop, FTekst: TLabel;
    FVorige, FVolgende, FSluit, FLes1: TButton;
    FKader: array[0..3] of TForm;
    FOnLes1: TNotifyEvent;
    function T(const NL, EN, FR, DE: string): string;
    procedure MaakVensters;
    procedure ToonStap;
    procedure VorigeClick(Sender: TObject);
    procedure VolgendeClick(Sender: TObject);
    procedure SluitClick(Sender: TObject);
    procedure Les1Click(Sender: TObject);
    procedure BallonClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure VerbergKader;
  public
    destructor Destroy; override;
    procedure RondStap(ADoel: TControl; const NL, EN, FR, DE: string);
    procedure Start(const ATaal: string);
    procedure Stop;
    procedure SetTaal(const ATaal: string);
    function Bezig: Boolean;
    property OnLes1: TNotifyEvent read FOnLes1 write FOnLes1;
  end;

implementation

const
  KaderDikte = 4;

// een extra taal (uLangPo) vertaalt elke regel apart: make-pot verzamelt de
// stukken tussen de LineEndings als aparte teksten
function PoRegels(const S: string): string;
var
  L: TStringList;
  i: Integer;
begin
  L := TStringList.Create;
  try
    L.Text := S;
    for i := 0 to L.Count - 1 do
      L[i] := PoTr(L[i]);
    Result := TrimRight(L.Text);
  finally
    L.Free;
  end;
end;

{ TWelkomForm }

constructor TWelkomForm.CreateWelkom(AOwner: TComponent; ATalen: TStrings; ATaalIndex: Integer);
var
  K: TWelkomKeuze;
  Y: Integer;
begin
  inherited CreateNew(AOwner);
  FKeuze := wkLeeg;   // ook als het venster met het kruisje dicht gaat
  FTaal := 'NL';
  BorderStyle := bsDialog;
  Position := poMainFormCenter;
  Width := 560;
  Height := 520;
  KeyPreview := True;
  OnKeyDown := @FormKeyDown;

  FTitel := TLabel.Create(Self);
  FTitel.Parent := Self;
  FTitel.SetBounds(20, 14, 520, 30);
  FTitel.Font.Size := 16;
  FTitel.Font.Style := [fsBold];

  FIntro := TLabel.Create(Self);
  FIntro.Parent := Self;
  FIntro.WordWrap := True;
  FIntro.AutoSize := False;
  FIntro.SetBounds(20, 52, 520, 54);

  FTaalLabel := TLabel.Create(Self);
  FTaalLabel.Parent := Self;
  FTaalLabel.SetBounds(20, 116, 200, 20);

  FTaalBox := TComboBox.Create(Self);
  FTaalBox.Parent := Self;
  FTaalBox.Style := csDropDownList;
  FTaalBox.SetBounds(230, 112, 180, 24);
  FTaalBox.Items.Assign(ATalen);
  FTaalBox.ItemIndex := ATaalIndex;
  FTaalBox.OnChange := @TaalBoxChange;

  // niveau van de onderdelenbalk: zelfde vorm als de taalkeuze, met een
  // regel uitleg eronder
  FNiveauLabel := TLabel.Create(Self);
  FNiveauLabel.Parent := Self;
  FNiveauLabel.SetBounds(20, 156, 200, 20);

  FNiveauBox := TComboBox.Create(Self);
  FNiveauBox.Parent := Self;
  FNiveauBox.Style := csDropDownList;
  FNiveauBox.SetBounds(230, 152, 250, 24);
  FNiveauBox.OnChange := @NiveauBoxChange;

  FNiveauUitleg := TLabel.Create(Self);
  FNiveauUitleg.Parent := Self;
  FNiveauUitleg.WordWrap := True;
  FNiveauUitleg.AutoSize := False;
  FNiveauUitleg.SetBounds(20, 192, 520, 40);
  FNiveauUitleg.Font.Color := clGrayText;

  Y := 238;   // ruimte voor een hogere keuzelijst (GTK2) en twee regels uitleg
  for K := Low(TWelkomKeuze) to High(TWelkomKeuze) do
  begin
    FKnop[K] := TButton.Create(Self);
    FKnop[K].Parent := Self;
    FKnop[K].SetBounds(20, Y, 200, 44);
    FKnop[K].Font.Style := [fsBold];
    FKnop[K].Tag := Ord(K);
    FKnop[K].OnClick := @KnopClick;
    FUitleg[K] := TLabel.Create(Self);
    FUitleg[K].Parent := Self;
    FUitleg[K].WordWrap := True;
    FUitleg[K].AutoSize := False;
    FUitleg[K].SetBounds(234, Y, 306, 70);
    Inc(Y, 76);
  end;
  FKnop[wkLes1].Default := True;

  FToon := TCheckBox.Create(Self);
  FToon.Parent := Self;
  FToon.SetBounds(20, Y + 6, 520, 24);
  FToon.Checked := True;
  Height := Y + 48;

  SetTaal('NL', ATaalIndex);
end;

function TWelkomForm.T(const NL, EN, FR, DE: string): string;
begin
  if FTaal = 'ENG' then Result := PoTr(EN)   // of een extra taal (uLangPo)
  else if FTaal = 'FR' then Result := FR
  else if FTaal = 'DU' then Result := DE
  else Result := NL;
end;

procedure TWelkomForm.SetTaal(const ATaal: string; ATaalIndex: Integer);
var
  i, Oud: Integer;
begin
  FTaal := ATaal;
  FBezig := True;
  try
    if (ATaalIndex >= 0) and (ATaalIndex < FTaalBox.Items.Count) then
      FTaalBox.ItemIndex := ATaalIndex;
    // de namen van de niveaus in de nieuwe taal; de keuze blijft
    Oud := FNiveauBox.ItemIndex;
    FNiveauBox.Items.Clear;
    for i := Low(NiveauVolgorde) to High(NiveauVolgorde) do
      FNiveauBox.Items.Add(NiveauNaam(FTaal, NiveauVolgorde[i]));
    if Oud < 0 then Oud := NiveauIndex(nvEigen);
    FNiveauBox.ItemIndex := Oud;
  finally
    FBezig := False;
  end;
  FNiveauLabel.Caption := T('Niveau:', 'Level:', 'Niveau :', 'Stufe:');
  ToonNiveauUitleg;
  Caption := T('Welkom', 'Welcome', 'Bienvenue', 'Willkommen');
  FTitel.Caption := T('Welkom bij Logic', 'Welcome to Logic', 'Bienvenue dans Logic', 'Willkommen bei Logic');
  FIntro.Caption := T(
    'Met Logic bouw je schakelingen op het scherm: schakelaars, lampen, poorten, bronnen en meer. Start de simulatie en je ziet ze werken. Waar wil je beginnen?',
    'With Logic you build circuits on the screen: switches, lamps, gates, sources and more. Start the simulation and you see them work. Where do you want to begin?',
    'Avec Logic, vous construisez des circuits à l''écran : interrupteurs, lampes, portes, sources et plus. Lancez la simulation et vous les voyez fonctionner. Par où voulez-vous commencer ?',
    'Mit Logic bauen Sie Schaltungen auf dem Bildschirm: Schalter, Lampen, Gatter, Quellen und mehr. Starten Sie die Simulation und Sie sehen sie arbeiten. Wo möchten Sie beginnen?');
  FTaalLabel.Caption := T('Taal / Language:', 'Language:', 'Langue / Language :', 'Sprache / Language:');
  FKnop[wkLes1].Caption := T('Begin met les 1', 'Start with lesson 1', 'Commencer la leçon 1', 'Mit Lektion 1 beginnen');
  FUitleg[wkLes1].Caption := T(
    'Je eerste schakeling: een schakelaar en een lamp. De les opent in de help, het voorbeeld staat meteen op het paneel.',
    'Your first circuit: a switch and a lamp. The lesson opens in the help, the example is placed straight on the panel.',
    'Votre premier circuit : un interrupteur et une lampe. La leçon s''ouvre dans l''aide, l''exemple est placé tout de suite sur le panneau.',
    'Ihre erste Schaltung: ein Schalter und eine Lampe. Die Lektion öffnet sich in der Hilfe, das Beispiel steht gleich auf dem Panel.');
  FKnop[wkRondleiding].Caption := T('Rondleiding', 'Guided tour', 'Visite guidée', 'Rundgang');
  FUitleg[wkRondleiding].Caption := T(
    'Een korte rondleiding in stappen: wat is wat op het scherm, en waar vind je wat.',
    'A short step-by-step tour: what is what on the screen, and where to find things.',
    'Une courte visite pas à pas : ce qui est quoi à l''écran, et où trouver chaque chose.',
    'Ein kurzer Rundgang in Schritten: Was ist was auf dem Bildschirm, und wo finden Sie was.');
  FKnop[wkLeerpad].Caption := T('Leerpad bekijken', 'View the learning path', 'Voir le parcours', 'Lernpfad ansehen');
  FUitleg[wkLeerpad].Caption := T(
    'Alle lessen op een rij, van de eerste schakeling tot energie, voeding, elektronica en magnetisme.',
    'All lessons in a row, from the first circuit to energy, power supply, electronics and magnetism.',
    'Toutes les leçons à la suite, du premier circuit à l''énergie, l''alimentation, l''électronique et le magnétisme.',
    'Alle Lektionen der Reihe nach, von der ersten Schaltung bis Energie, Stromversorgung, Elektronik und Magnetismus.');
  FKnop[wkLeeg].Caption := T('Leeg paneel', 'Empty panel', 'Panneau vide', 'Leeres Panel');
  FUitleg[wkLeeg].Caption := T(
    'Ik ken Logic al: meteen beginnen met een leeg paneel.',
    'I already know Logic: start right away with an empty panel.',
    'Je connais déjà Logic : commencer tout de suite avec un panneau vide.',
    'Ich kenne Logic schon: gleich mit einem leeren Panel beginnen.');
  FToon.Caption := T(
    'Toon dit venster bij het opstarten (later terug te vinden onder Paneelkeuze)',
    'Show this window at startup (you can find it later under Panel choice)',
    'Afficher cette fenêtre au démarrage (à retrouver ensuite sous Choix du panneau)',
    'Dieses Fenster beim Start zeigen (später unter Panelwahl zu finden)');
end;

function TWelkomForm.ToonBijStart: Boolean;
begin
  Result := FToon.Checked;
end;

procedure TWelkomForm.KnopClick(Sender: TObject);
var
  K: TWelkomKeuze;
begin
  K := TWelkomKeuze(TButton(Sender).Tag);
  FKeuze := K;
  ModalResult := mrOk;
end;

procedure TWelkomForm.TaalBoxChange(Sender: TObject);
begin
  if FBezig then Exit;
  if Assigned(FOnTaal) then FOnTaal(FTaalBox.ItemIndex);
end;

procedure TWelkomForm.ToonNiveauUitleg;
var
  i: Integer;
begin
  i := FNiveauBox.ItemIndex;
  if (i >= Low(NiveauVolgorde)) and (i <= High(NiveauVolgorde)) then
    FNiveauUitleg.Caption := NiveauUitleg(FTaal, NiveauVolgorde[i])
  else
    FNiveauUitleg.Caption := '';
end;

procedure TWelkomForm.NiveauBoxChange(Sender: TObject);
begin
  ToonNiveauUitleg;
  if FBezig then Exit;
  if Assigned(FOnNiveau) then FOnNiveau(FNiveauBox.ItemIndex);
end;

procedure TWelkomForm.SetNiveau(AIndex: Integer);
begin
  FBezig := True;
  try
    if (AIndex >= 0) and (AIndex < FNiveauBox.Items.Count) then
      FNiveauBox.ItemIndex := AIndex;
  finally
    FBezig := False;
  end;
  ToonNiveauUitleg;
end;

procedure TWelkomForm.Voorbereid(AToon: Boolean);
begin
  FKeuze := wkLeeg;
  FToon.Checked := AToon;
end;

procedure TWelkomForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = 27 then   // Esc: zoals Leeg paneel
  begin
    Key := 0;
    FKeuze := wkLeeg;
    ModalResult := mrCancel;
  end;
end;

{ TRondleiding }

destructor TRondleiding.Destroy;
begin
  Stop;
  inherited Destroy;
end;

function TRondleiding.T(const NL, EN, FR, DE: string): string;
begin
  if FTaal = 'ENG' then Result := PoTr(EN)
  else if FTaal = 'FR' then Result := FR
  else if FTaal = 'DU' then Result := DE
  else Result := NL;
end;

procedure TRondleiding.RondStap(ADoel: TControl; const NL, EN, FR, DE: string);
var
  N: Integer;
begin
  N := Length(FStappen);
  SetLength(FStappen, N + 1);
  FStappen[N].Doel := ADoel;
  FStappen[N].Tekst[0] := NL;
  FStappen[N].Tekst[1] := EN;
  FStappen[N].Tekst[2] := FR;
  FStappen[N].Tekst[3] := DE;
end;

procedure TRondleiding.MaakVensters;
var
  i: Integer;
  Onder: TPanel;
begin
  if FBallon <> nil then Exit;
  FBallon := TForm.CreateNew(Self);
  FBallon.BorderStyle := bsToolWindow;
  FBallon.FormStyle := fsStayOnTop;
  FBallon.Position := poDesigned;
  FBallon.Width := 380;
  FBallon.Height := 210;
  FBallon.Color := RGBToColor(255, 252, 220);
  FBallon.OnClose := @BallonClose;

  Onder := TPanel.Create(FBallon);
  Onder.Parent := FBallon;
  Onder.Align := alBottom;
  Onder.Height := 40;
  Onder.BevelOuter := bvNone;
  Onder.ParentColor := True;

  FKop := TLabel.Create(FBallon);
  FKop.Parent := FBallon;
  FKop.Align := alTop;
  FKop.BorderSpacing.Around := 8;
  FKop.Font.Style := [fsBold];

  FTekst := TLabel.Create(FBallon);
  FTekst.Parent := FBallon;
  FTekst.Align := alClient;
  FTekst.WordWrap := True;
  FTekst.BorderSpacing.Left := 8;
  FTekst.BorderSpacing.Right := 8;

  FVorige := TButton.Create(FBallon);
  FVorige.Parent := Onder;
  FVorige.SetBounds(8, 6, 84, 28);
  FVorige.OnClick := @VorigeClick;

  FVolgende := TButton.Create(FBallon);
  FVolgende.Parent := Onder;
  FVolgende.SetBounds(98, 6, 84, 28);
  FVolgende.OnClick := @VolgendeClick;
  FVolgende.Default := True;

  FLes1 := TButton.Create(FBallon);
  FLes1.Parent := Onder;
  FLes1.SetBounds(188, 6, 110, 28);
  FLes1.OnClick := @Les1Click;

  FSluit := TButton.Create(FBallon);
  FSluit.Parent := Onder;
  FSluit.SetBounds(FBallon.Width - 82, 6, 74, 28);
  FSluit.Anchors := [akTop, akRight];
  FSluit.OnClick := @SluitClick;
  FSluit.Cancel := True;

  for i := 0 to 3 do
  begin
    FKader[i] := TForm.CreateNew(Self);
    FKader[i].BorderStyle := bsNone;
    FKader[i].FormStyle := fsStayOnTop;
    FKader[i].Position := poDesigned;
    FKader[i].ShowInTaskBar := stNever;
    FKader[i].Color := clRed;
  end;
end;

procedure TRondleiding.VerbergKader;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if FKader[i] <> nil then FKader[i].Hide;
end;

procedure TRondleiding.ToonStap;
var
  D: TControl;
  R: TRect;
  P: TPoint;
  W: TRect;
  X, Y, i: Integer;
begin
  if (FNr < 0) or (FNr > High(FStappen)) then Exit;
  D := FStappen[FNr].Doel;
  FKop.Caption := Format(T('Stap %d van %d', 'Step %d of %d', 'Étape %d sur %d', 'Schritt %d von %d'),
    [FNr + 1, Length(FStappen)]);
  if FTaal = 'ENG' then FTekst.Caption := PoRegels(FStappen[FNr].Tekst[1])
  else if FTaal = 'FR' then FTekst.Caption := FStappen[FNr].Tekst[2]
  else if FTaal = 'DU' then FTekst.Caption := FStappen[FNr].Tekst[3]
  else FTekst.Caption := FStappen[FNr].Tekst[0];
  FBallon.Caption := T('Rondleiding', 'Guided tour', 'Visite guidée', 'Rundgang');
  FVorige.Caption := T('< Vorige', '< Back', '< Précédent', '< Zurück');
  if FNr = High(FStappen) then
    FVolgende.Caption := T('Klaar', 'Done', 'Terminé', 'Fertig')
  else
    FVolgende.Caption := T('Volgende >', 'Next >', 'Suivant >', 'Weiter >');
  FLes1.Caption := T('Begin met les 1', 'Start lesson 1', 'Leçon 1', 'Lektion 1');
  FSluit.Caption := T('Sluiten', 'Close', 'Fermer', 'Schließen');
  FVorige.Enabled := FNr > 0;
  FLes1.Visible := (FNr = High(FStappen)) and Assigned(FOnLes1);

  W := Screen.WorkAreaRect;
  if (D <> nil) and D.IsVisible then
  begin
    P := D.ClientToScreen(Point(0, 0));
    R := Rect(P.X - KaderDikte, P.Y - KaderDikte, P.X + D.Width + KaderDikte, P.Y + D.Height + KaderDikte);
    // vier randen
    FKader[0].SetBounds(R.Left, R.Top, R.Right - R.Left, KaderDikte);
    FKader[1].SetBounds(R.Left, R.Bottom - KaderDikte, R.Right - R.Left, KaderDikte);
    FKader[2].SetBounds(R.Left, R.Top, KaderDikte, R.Bottom - R.Top);
    FKader[3].SetBounds(R.Right - KaderDikte, R.Top, KaderDikte, R.Bottom - R.Top);
    for i := 0 to 3 do FKader[i].Show;
    // de ballon onder het doel, of erboven als er onder geen plaats is;
    // bij een groot doel (het paneel) in het midden ervan
    if R.Bottom - R.Top > W.Bottom - W.Top - FBallon.Height - 60 then
    begin
      X := (R.Left + R.Right - FBallon.Width) div 2;
      Y := (R.Top + R.Bottom - FBallon.Height) div 2;
    end
    else
    begin
      X := R.Left;
      if R.Bottom + 12 + FBallon.Height <= W.Bottom then
        Y := R.Bottom + 12
      else
        Y := R.Top - 12 - FBallon.Height - 30;
    end;
  end
  else
  begin
    VerbergKader;
    X := (W.Left + W.Right - FBallon.Width) div 2;
    Y := (W.Top + W.Bottom - FBallon.Height) div 2;
  end;
  if X + FBallon.Width > W.Right then X := W.Right - FBallon.Width;
  if X < W.Left then X := W.Left;
  if Y < W.Top then Y := W.Top;
  FBallon.SetBounds(X, Y, FBallon.Width, FBallon.Height);
  FBallon.Show;
  FBallon.BringToFront;
end;

procedure TRondleiding.Start(const ATaal: string);
begin
  if Length(FStappen) = 0 then Exit;
  FTaal := ATaal;
  MaakVensters;
  FNr := 0;
  ToonStap;
end;

procedure TRondleiding.SetTaal(const ATaal: string);
begin
  FTaal := ATaal;
  if Bezig then ToonStap;
end;

function TRondleiding.Bezig: Boolean;
begin
  Result := (FBallon <> nil) and FBallon.Visible;
end;

procedure TRondleiding.Stop;
begin
  VerbergKader;
  if FBallon <> nil then FBallon.Hide;
end;

procedure TRondleiding.VorigeClick(Sender: TObject);
begin
  if FNr > 0 then
  begin
    Dec(FNr);
    ToonStap;
  end;
end;

procedure TRondleiding.VolgendeClick(Sender: TObject);
begin
  if FNr < High(FStappen) then
  begin
    Inc(FNr);
    ToonStap;
  end
  else
    Stop;
end;

procedure TRondleiding.SluitClick(Sender: TObject);
begin
  Stop;
end;

procedure TRondleiding.Les1Click(Sender: TObject);
begin
  Stop;
  if Assigned(FOnLes1) then FOnLes1(Self);
end;

procedure TRondleiding.BallonClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caHide;
  VerbergKader;
end;

end.
