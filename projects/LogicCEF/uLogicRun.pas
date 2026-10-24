unit uLogicRun;

{ LogicRun-venster: het stappenprogramma van het LogicRun-blok bekijken,
  bewerken en laten lopen. Het venster staat naast Logic en hoort bij het
  blok dat op het paneel staat (er is er hoogstens één). Wordt het paneel
  opnieuw geladen (ook bij ongedaan maken), dan koppelt het venster zich
  vanzelf aan het nieuwe blok. Gewoon LCL-venster, zonder .lfm, zodat het
  ook onder Linux werkt. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, StdCtrls, ExtCtrls, Grids,
  Spin, janSimLogic, chatgridpcodeSmall;

type
  TLogicRunForm = class(TForm)
  private
    FGrid: TjanGridS;
    FBox: TjanSimLogicBox;
    FBlock: TjanLogicRun;
    FTaal: string;
    FShownProgram: string;     // programma zoals het nu in de tabel staat
    FUpdating: Boolean;
    FPoll: TTimer;
    PnlTop, PnlBottom, PnlNoBlock: TPanel;
    BtStart, BtPause, BtStop, BtStep, BtLoadEx, BtAdd, BtDel, BtPlace: TButton;
    LbStatus, LbDuur, LbMs, LbEx, LbNoBlock: TLabel;
    LbDin: array[0..3] of TLabel;
    CbDin: array[0..3] of TComboBox;
    SpDuur: TSpinEdit;
    CkHerhalen: TCheckBox;
    CbEx: TComboBox;
    SG: TStringGrid;
    function T(const NL, EN, FR, DE: string): string;
    procedure Bind(ABlock: TjanLogicRun);
    procedure PollTick(Sender: TObject);
    procedure BlockChanged(Sender: TObject);
    procedure FillAll;
    procedure FillStatus;
    procedure FillTexts;
    procedure StartClick(Sender: TObject);
    procedure PauseClick(Sender: TObject);
    procedure StopClick(Sender: TObject);
    procedure StepClick(Sender: TObject);
    procedure LoadExClick(Sender: TObject);
    procedure AddClick(Sender: TObject);
    procedure DelClick(Sender: TObject);
    procedure PlaceClick(Sender: TObject);
    procedure DuurChange(Sender: TObject);
    procedure HerhalenClick(Sender: TObject);
    procedure DinChange(Sender: TObject);
    procedure GridDrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect; aState: TGridDrawState);
    procedure GridMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure GridSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
    procedure GridEditingDone(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor CreateFor(AOwner: TComponent; AGrid: TjanGridS; ABox: TjanSimLogicBox);
    // taal: 'NL', 'ENG', 'FR' of 'DU'
    procedure SetTaal(const ATaal: string);
  end;

implementation

const
  ColTijd = 9;          // kolommen: 0 = stap, 1..8 = UIT0..UIT7, 9 = tijd

constructor TLogicRunForm.CreateFor(AOwner: TComponent; AGrid: TjanGridS; ABox: TjanSimLogicBox);

  function MakeButton(AParent: TWinControl; ALeft, ATop, AWidth: Integer; AClick: TNotifyEvent): TButton;
  begin
    Result := TButton.Create(Self);
    Result.Parent := AParent;
    Result.SetBounds(ALeft, ATop, AWidth, 28);
    Result.OnClick := AClick;
  end;

  function MakeLabel(AParent: TWinControl; ALeft, ATop: Integer): TLabel;
  begin
    Result := TLabel.Create(Self);
    Result.Parent := AParent;
    Result.Left := ALeft;
    Result.Top := ATop;
  end;

var
  i: Integer;
begin
  inherited CreateNew(AOwner);
  FGrid := AGrid;
  FBox := ABox;
  FTaal := 'NL';
  Caption := 'LogicRun';
  BorderStyle := bsSizeToolWin;
  Width := 560;
  Height := 470;
  Constraints.MinWidth := 520;
  Constraints.MinHeight := 360;
  Position := poDesigned;
  OnCloseQuery := @FormCloseQuery;

  // ---- bovenaan: bedienen en instellingen ----
  PnlTop := TPanel.Create(Self);
  PnlTop.Parent := Self;
  PnlTop.Align := alTop;
  PnlTop.Height := 76;
  PnlTop.BevelOuter := bvNone;
  BtStart := MakeButton(PnlTop, 8, 6, 74, @StartClick);
  BtPause := MakeButton(PnlTop, 86, 6, 74, @PauseClick);
  BtStop := MakeButton(PnlTop, 164, 6, 74, @StopClick);
  BtStep := MakeButton(PnlTop, 242, 6, 74, @StepClick);
  LbStatus := MakeLabel(PnlTop, 328, 12);
  LbStatus.Font.Style := [fsBold];

  LbDuur := MakeLabel(PnlTop, 8, 46);
  SpDuur := TSpinEdit.Create(Self);
  SpDuur.Parent := PnlTop;
  SpDuur.SetBounds(78, 41, 72, 28);
  SpDuur.MinValue := 50;
  SpDuur.MaxValue := 10000;
  SpDuur.Increment := 50;
  SpDuur.OnChange := @DuurChange;
  LbMs := MakeLabel(PnlTop, 154, 46);
  LbMs.Caption := 'ms';
  CkHerhalen := TCheckBox.Create(Self);
  CkHerhalen.Parent := PnlTop;
  CkHerhalen.SetBounds(184, 44, 90, 24);
  CkHerhalen.OnClick := @HerhalenClick;
  LbEx := MakeLabel(PnlTop, 282, 46);
  CbEx := TComboBox.Create(Self);
  CbEx.Parent := PnlTop;
  CbEx.Style := csDropDownList;
  CbEx.SetBounds(350, 41, 130, 28);
  BtLoadEx := MakeButton(PnlTop, 484, 41, 64, @LoadExClick);

  // ---- onderaan: stappen toevoegen/verwijderen en de ingangen ----
  PnlBottom := TPanel.Create(Self);
  PnlBottom.Parent := Self;
  PnlBottom.Align := alBottom;
  PnlBottom.Height := 84;
  PnlBottom.BevelOuter := bvNone;
  BtAdd := MakeButton(PnlBottom, 8, 6, 110, @AddClick);
  BtDel := MakeButton(PnlBottom, 122, 6, 110, @DelClick);
  for i := 0 to 3 do
  begin
    LbDin[i] := MakeLabel(PnlBottom, 8 + i * 136, 44);
    LbDin[i].Caption := 'DIN' + IntToStr(i + 1);
    CbDin[i] := TComboBox.Create(Self);
    CbDin[i].Parent := PnlBottom;
    CbDin[i].Style := csDropDownList;
    CbDin[i].SetBounds(48 + i * 136, 40, 84, 28);
    CbDin[i].Tag := i;
    CbDin[i].OnChange := @DinChange;
  end;

  // ---- geen blok op het paneel ----
  PnlNoBlock := TPanel.Create(Self);
  PnlNoBlock.Parent := Self;
  PnlNoBlock.Align := alClient;
  PnlNoBlock.BevelOuter := bvNone;
  LbNoBlock := MakeLabel(PnlNoBlock, 16, 24);
  LbNoBlock.WordWrap := True;
  LbNoBlock.AutoSize := False;
  LbNoBlock.SetBounds(16, 24, 500, 60);
  BtPlace := MakeButton(PnlNoBlock, 16, 90, 220, @PlaceClick);

  // ---- de stappentabel ----
  SG := TStringGrid.Create(Self);
  SG.Parent := Self;
  SG.Align := alClient;
  SG.ColCount := ColTijd + 1;
  SG.RowCount := 2;
  SG.FixedCols := 1;
  SG.FixedRows := 1;
  SG.DefaultColWidth := 44;
  SG.ColWidths[0] := 46;
  SG.ColWidths[ColTijd] := 64;
  SG.DefaultRowHeight := 24;
  SG.Options := [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goEditing];
  SG.OnDrawCell := @GridDrawCell;
  SG.OnMouseUp := @GridMouseUp;
  SG.OnSelectEditor := @GridSelectEditor;
  SG.OnEditingDone := @GridEditingDone;
  for i := 0 to 7 do
    SG.Cells[i + 1, 0] := 'UIT' + IntToStr(i);

  FPoll := TTimer.Create(Self);
  FPoll.Interval := 300;
  FPoll.OnTimer := @PollTick;
  FPoll.Enabled := True;

  FillTexts;
  Bind(FindLogicRun(FGrid));
end;

function TLogicRunForm.T(const NL, EN, FR, DE: string): string;
begin
  if FTaal = 'ENG' then Result := EN
  else if FTaal = 'FR' then Result := FR
  else if FTaal = 'DU' then Result := DE
  else Result := NL;
end;

procedure TLogicRunForm.SetTaal(const ATaal: string);
begin
  FTaal := ATaal;
  FillTexts;
  FShownProgram := '';
  FillAll;
end;

procedure TLogicRunForm.FillTexts;
var
  i, Keep: Integer;
begin
  BtStart.Caption := T('Start', 'Start', 'Marche', 'Start');
  BtPause.Caption := T('Pauze', 'Pause', 'Pause', 'Pause');
  BtStop.Caption := T('Stop', 'Stop', 'Arrêt', 'Stopp');
  BtStep.Caption := T('Stap', 'Step', 'Pas', 'Schritt');
  LbDuur.Caption := T('Stapduur', 'Step time', 'Durée', 'Schrittzeit');
  CkHerhalen.Caption := T('Herhalen', 'Repeat', 'Répéter', 'Wiederholen');
  LbEx.Caption := T('Voorbeeld', 'Example', 'Exemple', 'Beispiel');
  BtLoadEx.Caption := T('Laden', 'Load', 'Charger', 'Laden');
  BtAdd.Caption := T('+ stap', '+ step', '+ pas', '+ Schritt');
  BtDel.Caption := T('- stap', '- step', '- pas', '- Schritt');
  BtPlace.Caption := T('Blok op het paneel zetten', 'Put the block on the panel',
                       'Placer le bloc sur le panneau', 'Block auf das Panel setzen');
  LbNoBlock.Caption := T('Er staat nog geen LogicRun-blok op het paneel. Klik op de knop hieronder en daarna op het paneel om het te plaatsen.',
    'There is no LogicRun block on the panel yet. Click the button below and then on the panel to place it.',
    'Il n''y a pas encore de bloc LogicRun sur le panneau. Cliquez sur le bouton ci-dessous, puis sur le panneau pour le placer.',
    'Auf dem Panel steht noch kein LogicRun-Block. Klicken Sie auf die Schaltfläche unten und dann auf das Panel, um ihn zu platzieren.');
  SG.Cells[0, 0] := T('stap', 'step', 'pas', 'Schritt');
  SG.Cells[ColTijd, 0] := T('tijd x', 'time x', 'durée x', 'Zeit x');
  Keep := CbEx.ItemIndex;
  CbEx.Items.Clear;
  CbEx.Items.Add(T('Verkeerslicht', 'Traffic light', 'Feu tricolore', 'Ampel'));
  CbEx.Items.Add(T('Looplicht', 'Running light', 'Chenillard', 'Lauflicht'));
  CbEx.Items.Add(T('Motor links/rechts', 'Motor left/right', 'Moteur gauche/droite', 'Motor links/rechts'));
  CbEx.Items.Add(T('4-bitteller', '4-bit counter', 'Compteur 4 bits', '4-Bit-Zähler'));
  if Keep < 0 then Keep := 0;
  CbEx.ItemIndex := Keep;
  for i := 0 to 3 do
  begin
    Keep := CbDin[i].ItemIndex;
    CbDin[i].Items.Clear;
    CbDin[i].Items.Add('-');
    CbDin[i].Items.Add(T('start/stop', 'start/stop', 'marche/arrêt', 'Start/Stopp'));
    CbDin[i].Items.Add(T('reset', 'reset', 'remise à 0', 'Reset'));
    CbDin[i].Items.Add('+1');
    CbDin[i].ItemIndex := Keep;
  end;
end;

procedure TLogicRunForm.Bind(ABlock: TjanLogicRun);
begin
  if (FBlock <> nil) and (FBlock <> ABlock) then
  begin
    FBlock.OnChange := nil;
    FBlock.RemoveFreeNotification(Self);
  end;
  FBlock := ABlock;
  if FBlock <> nil then
  begin
    FBlock.OnChange := @BlockChanged;
    FBlock.FreeNotification(Self);
  end;
  PnlNoBlock.Visible := FBlock = nil;
  SG.Visible := FBlock <> nil;
  PnlTop.Enabled := FBlock <> nil;
  PnlBottom.Enabled := FBlock <> nil;
  FShownProgram := '';
  FillAll;
end;

procedure TLogicRunForm.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  // blok verwijderd of paneel opnieuw geladen: PollTick koppelt opnieuw
  if (Operation = opRemove) and (AComponent = FBlock) then
  begin
    FBlock := nil;
    Bind(nil);
  end;
end;

procedure TLogicRunForm.PollTick(Sender: TObject);
var
  B: TjanLogicRun;
begin
  // paneel opnieuw geladen (ook ongedaan maken) of blok verwijderd/geplaatst
  B := FindLogicRun(FGrid);
  if (B <> nil) and not B.Visible then B := nil;   // hangt nog aan de muis
  if B <> FBlock then
    Bind(B);
end;

procedure TLogicRunForm.BlockChanged(Sender: TObject);
begin
  FillAll;
end;

procedure TLogicRunForm.FillStatus;
begin
  if FBlock = nil then
    LbStatus.Caption := ''
  else if FBlock.CurrentStep < 0 then
    LbStatus.Caption := T('gestopt', 'stopped', 'arrêté', 'gestoppt')
  else if FBlock.Running then
    LbStatus.Caption := Format('%s %d/%d', [T('loopt: stap', 'running: step', 'en marche : pas', 'läuft: Schritt'),
      FBlock.CurrentStep + 1, FBlock.StepCount])
  else
    LbStatus.Caption := Format('%s %d/%d', [T('pauze: stap', 'paused: step', 'en pause : pas', 'Pause: Schritt'),
      FBlock.CurrentStep + 1, FBlock.StepCount]);
end;

procedure TLogicRunForm.FillAll;
var
  i: Integer;
begin
  FillStatus;
  if FBlock = nil then Exit;
  // alleen opnieuw opbouwen als het programma zelf veranderd is (niet bij
  // elke stap tijdens het lopen)
  if FBlock.ProgramText <> FShownProgram then
  begin
    FUpdating := True;
    try
      FShownProgram := FBlock.ProgramText;
      SG.RowCount := FBlock.StepCount + 1;
      for i := 0 to FBlock.StepCount - 1 do
      begin
        SG.Cells[0, i + 1] := IntToStr(i + 1);
        SG.Cells[ColTijd, i + 1] := IntToStr(FBlock.Steps[i].Tijd);
      end;
      if SpDuur.Value <> FBlock.StapDuur then
        SpDuur.Value := FBlock.StapDuur;
      CkHerhalen.Checked := FBlock.Herhalen;
      for i := 0 to 3 do
        CbDin[i].ItemIndex := Ord(FBlock.Din[i]);
    finally
      FUpdating := False;
    end;
  end;
  SG.Invalidate;
end;

procedure TLogicRunForm.GridDrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect; aState: TGridDrawState);
var
  C: TCanvas;
  On: Boolean;
  cx, cy: Integer;
begin
  if (FBlock = nil) or (aRow < 1) or (aRow > FBlock.StepCount) then Exit;
  C := SG.Canvas;
  // huidige stap: lichtblauw
  if (aCol > 0) and (aRow - 1 = FBlock.CurrentStep) then
  begin
    C.Brush.Color := RGBToColor(200, 225, 255);
    C.FillRect(aRect);
    if aCol = ColTijd then
      C.TextOut(aRect.Left + 6, aRect.Top + 4, SG.Cells[aCol, aRow]);
  end;
  if (aCol >= 1) and (aCol <= 8) then
  begin
    On := (FBlock.Steps[aRow - 1].Bits and (1 shl (aCol - 1))) <> 0;
    cx := (aRect.Left + aRect.Right) div 2;
    cy := (aRect.Top + aRect.Bottom) div 2;
    C.Pen.Color := clGray;
    if On then C.Brush.Color := clRed else C.Brush.Color := clWhite;
    C.Ellipse(cx - 7, cy - 7, cx + 7, cy + 7);
  end;
end;

procedure TLogicRunForm.GridMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  aCol, aRow: Integer;
  St: TLogicRunStep;
begin
  if (FBlock = nil) or (Button <> mbLeft) then Exit;
  SG.MouseToCell(X, Y, aCol, aRow);
  if (aRow < 1) or (aRow > FBlock.StepCount) or (aCol < 1) or (aCol > 8) then Exit;
  // klik op een vakje: die uitgang in die stap aan/uit
  St := FBlock.Steps[aRow - 1];
  St.Bits := St.Bits xor (1 shl (aCol - 1));
  FBlock.Steps[aRow - 1] := St;
end;

procedure TLogicRunForm.GridSelectEditor(Sender: TObject; aCol, aRow: Integer; var Editor: TWinControl);
begin
  // alleen de kolom "tijd x" is een invulvak
  if aCol <> ColTijd then
    Editor := nil;
end;

procedure TLogicRunForm.GridEditingDone(Sender: TObject);
var
  St: TLogicRunStep;
  V, R: Integer;
begin
  if (FBlock = nil) or FUpdating then Exit;
  R := SG.Row;
  if (SG.Col <> ColTijd) or (R < 1) or (R > FBlock.StepCount) then Exit;
  V := StrToIntDef(Trim(SG.Cells[ColTijd, R]), -1);
  if V < 1 then V := 1;
  if V > 99 then V := 99;
  St := FBlock.Steps[R - 1];
  if St.Tijd <> V then
  begin
    St.Tijd := V;
    FBlock.Steps[R - 1] := St;
  end
  else
    SG.Cells[ColTijd, R] := IntToStr(V);
end;

procedure TLogicRunForm.StartClick(Sender: TObject);
begin
  if FBlock <> nil then FBlock.Start;
end;

procedure TLogicRunForm.PauseClick(Sender: TObject);
begin
  if FBlock <> nil then FBlock.Pause;
end;

procedure TLogicRunForm.StopClick(Sender: TObject);
begin
  if FBlock <> nil then FBlock.StopRun;
end;

procedure TLogicRunForm.StepClick(Sender: TObject);
begin
  if FBlock <> nil then
  begin
    FBlock.Pause;
    FBlock.StepOnce;
  end;
end;

procedure TLogicRunForm.DuurChange(Sender: TObject);
begin
  if (FBlock = nil) or FUpdating then Exit;
  if SpDuur.Value <> FBlock.StapDuur then
    FBlock.StapDuur := SpDuur.Value;
end;

procedure TLogicRunForm.HerhalenClick(Sender: TObject);
begin
  if (FBlock = nil) or FUpdating then Exit;
  FBlock.Herhalen := CkHerhalen.Checked;
end;

procedure TLogicRunForm.DinChange(Sender: TObject);
var
  i: Integer;
begin
  if (FBlock = nil) or FUpdating then Exit;
  i := TComboBox(Sender).Tag;
  if TComboBox(Sender).ItemIndex >= 0 then
    FBlock.Din[i] := TLogicRunDin(TComboBox(Sender).ItemIndex);
end;

procedure TLogicRunForm.AddClick(Sender: TObject);
begin
  if FBlock = nil then Exit;
  // nieuwe stap na de geselecteerde stap
  FBlock.InsertStep(SG.Row, 0, 1);
  if SG.Row + 1 < SG.RowCount then
    SG.Row := SG.Row + 1;
end;

procedure TLogicRunForm.DelClick(Sender: TObject);
begin
  if (FBlock = nil) or (SG.Row < 1) then Exit;
  FBlock.DeleteStep(SG.Row - 1);
end;

procedure TLogicRunForm.PlaceClick(Sender: TObject);
begin
  if (FBox <> nil) and (FindLogicRun(FGrid) = nil) then
    FBox.NewLogicRun;
end;

// voorbeelden: bitpatroon en tijd per stap
procedure TLogicRunForm.LoadExClick(Sender: TObject);

  procedure Fill(const ABits: array of Byte; const ATijd: array of Integer; ADuur: Integer);
  var
    i: Integer;
    S: string;
  begin
    // in één keer, zodat ongedaan maken het als één wijziging ziet
    S := '';
    for i := 0 to High(ABits) do
    begin
      if i > 0 then S := S + ',';
      S := S + Format('%d:%d', [ABits[i], ATijd[i]]);
    end;
    FBlock.SetProgramText(Format('%d;1;1;2;3;0;%s', [ADuur, S]));
  end;

begin
  if FBlock = nil then Exit;
  FBlock.StopRun;
  case CbEx.ItemIndex of
    // UIT0 rood, UIT1 oranje, UIT2 groen
    0: Fill([1, 4, 2], [6, 6, 2], 500);
    1: Fill([1, 2, 4, 8, 16, 32, 64, 128], [1, 1, 1, 1, 1, 1, 1, 1], 200);
    // UIT0 motor links, UIT1 motor rechts
    2: Fill([1, 0, 2, 0], [4, 1, 4, 1], 500);
    3: Fill([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
            [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], 500);
  end;
end;

procedure TLogicRunForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  // niet vrijgeven, alleen verbergen (het hoofdvenster bewaart het venster)
  CanClose := False;
  Hide;
end;

end.
