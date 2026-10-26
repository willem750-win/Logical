unit uAbout;

{ About-venster van Logic. Het venster wordt volledig in code opgebouwd
  (geen .lfm), zodat het zowel onder Windows als Linux werkt. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, StdCtrls, ExtCtrls,
  LCLIntf, chatgridpcodeSmall;

const
  AppVersion = '1.6.0';
  AppAuthor  = 'Willy Jansen';
  AppEmail   = 'willyjansen@telenet.be';
  AppUrl     = 'https://github.com/willem750-win/Logical';

procedure ShowAbout(ALang: chatgridpcodeSmall.TLanguage);

implementation

uses
  uUpdate;

type
  TAboutForm = class(TForm)
  private
    FLang: chatgridpcodeSmall.TLanguage;
    procedure AutoClick(Sender: TObject);
    procedure CheckClick(Sender: TObject);
    procedure UrlClick(Sender: TObject);
    procedure MailClick(Sender: TObject);
    procedure UrlEnter(Sender: TObject);
    procedure UrlLeave(Sender: TObject);
  end;

procedure TAboutForm.UrlClick(Sender: TObject);
begin
  OpenURL(AppUrl);
end;

procedure TAboutForm.MailClick(Sender: TObject);
begin
  OpenURL('mailto:' + AppEmail);
end;

procedure TAboutForm.AutoClick(Sender: TObject);
begin
  SetAutoUpdate(TCheckBox(Sender).Checked);
end;

procedure TAboutForm.CheckClick(Sender: TObject);
begin
  ManualUpdateCheck(FLang);
end;

procedure TAboutForm.UrlEnter(Sender: TObject);
begin
  TLabel(Sender).Font.Style := [fsUnderline];
end;

procedure TAboutForm.UrlLeave(Sender: TObject);
begin
  TLabel(Sender).Font.Style := [];
end;

procedure ShowAbout(ALang: chatgridpcodeSmall.TLanguage);
var
  F: TAboutForm;
  PLeft, PText, PBottom, PUpd: TPanel;
  PrevLabel: TLabel;
  Img: TImage;
  L: TLabel;
  BOk, BCheck: TButton;
  CbAuto: TCheckBox;
  sCaption, sVersion, sDesc, sCredit, sLicense, sAuto, sCheck: string;

  // labels worden van boven naar beneden toegevoegd; elk label hangt aan de
  // onderkant van het vorige (met alTop en een grote Top liep de volgorde
  // onder Windows door elkaar)
  function AddLabel(const AText: string; ASpaceAbove: Integer): TLabel;
  begin
    Result := TLabel.Create(F);
    Result.Parent := PText;
    Result.AnchorSideLeft.Control := PText;
    Result.AnchorSideRight.Control := PText;
    Result.AnchorSideRight.Side := asrBottom;
    if PrevLabel = nil then
      Result.AnchorSideTop.Control := PText
    else
    begin
      Result.AnchorSideTop.Control := PrevLabel;
      Result.AnchorSideTop.Side := asrBottom;
    end;
    Result.Anchors := [akTop, akLeft, akRight];
    Result.BorderSpacing.Top := ASpaceAbove;
    PrevLabel := Result;
    Result.WordWrap := True;
    Result.AutoSize := True;
    Result.Caption := AText;
  end;

begin
  case ALang of
    chatgridpcodeSmall.lgEnglish:
      begin
        sCaption := 'About Logic';
        sVersion := 'Version ';
        sDesc    := 'Simulator for digital circuits: build a circuit with switches, '
                  + 'gates, counters, memories and displays, and watch it work.';
        sCredit  := 'Based on the freeware components by Jan Verhoeven.';
        sLicense := 'Released under the MIT license.';
        sAuto    := 'Check for updates automatically';
        sCheck   := 'Check for updates';
      end;
    chatgridpcodeSmall.lgFrench:
      begin
        sCaption := 'À propos de Logic';
        sVersion := 'Version ';
        sDesc    := 'Simulateur de circuits numériques : construisez un circuit avec '
                  + 'des interrupteurs, des portes, des compteurs, des mémoires et des '
                  + 'afficheurs, et regardez-le fonctionner.';
        sCredit  := 'Basé sur les composants freeware de Jan Verhoeven.';
        sLicense := 'Publié sous licence MIT.';
        sAuto    := 'Rechercher automatiquement les mises à jour';
        sCheck   := 'Rechercher les mises à jour';
      end;
    chatgridpcodeSmall.lgGerman:
      begin
        sCaption := 'Über Logic';
        sVersion := 'Version ';
        sDesc    := 'Simulator für digitale Schaltungen: Bauen Sie eine Schaltung mit '
                  + 'Schaltern, Gattern, Zählern, Speichern und Anzeigen und sehen Sie '
                  + 'ihr bei der Arbeit zu.';
        sCredit  := 'Basiert auf den Freeware-Komponenten von Jan Verhoeven.';
        sLicense := 'Veröffentlicht unter der MIT-Lizenz.';
        sAuto    := 'Automatisch nach Updates suchen';
        sCheck   := 'Nach Updates suchen';
      end;
  else // lgDutch
    begin
      sCaption := 'Over Logic';
      sVersion := 'Versie ';
      sDesc    := 'Simulator voor digitale schakelingen: bouw een schakeling met '
                + 'schakelaars, poorten, tellers, geheugens en displays, en zie ze werken.';
      sCredit  := 'Gebaseerd op de freeware-componenten van Jan Verhoeven.';
      sLicense := 'Uitgebracht onder de MIT-licentie.';
      sAuto    := 'Automatisch zoeken naar updates';
      sCheck   := 'Zoeken naar updates';
    end;
  end;

  PrevLabel := nil;
  F := TAboutForm.CreateNew(nil);
  try
    F.FLang := ALang;
    F.Caption := sCaption;
    F.BorderStyle := bsDialog;
    F.Position := poMainFormCenter;
    F.ClientWidth := 480;
    F.ClientHeight := 350;

    // onderaan: OK-knop
    PBottom := TPanel.Create(F);
    PBottom.Parent := F;
    PBottom.Align := alBottom;
    PBottom.Height := 48;
    PBottom.BevelOuter := bvNone;

    BOk := TButton.Create(F);
    BOk.Parent := PBottom;
    BOk.Caption := 'OK';
    BOk.ModalResult := mrOK;
    BOk.Default := True;
    BOk.Cancel := True;
    BOk.Width := 80;
    BOk.Align := alRight;
    BOk.BorderSpacing.Around := 10;

    // links onderaan: updates
    BCheck := TButton.Create(F);
    BCheck.Parent := PBottom;
    BCheck.Caption := sCheck;
    BCheck.AutoSize := True;
    BCheck.Align := alLeft;
    BCheck.BorderSpacing.Around := 10;
    BCheck.OnClick := @F.CheckClick;

    // eigen rij voor het vinkje, boven de knoppen
    PUpd := TPanel.Create(F);
    PUpd.Parent := F;
    PUpd.Align := alBottom;
    PUpd.Top := 0;   // boven de knoppenrij
    PUpd.Height := 26;
    PUpd.BevelOuter := bvNone;

    CbAuto := TCheckBox.Create(F);
    CbAuto.Parent := PUpd;
    CbAuto.Caption := sAuto;
    CbAuto.Align := alLeft;
    CbAuto.BorderSpacing.Left := 12;
    CbAuto.Checked := GetAutoUpdate;
    CbAuto.OnClick := @F.AutoClick;

    // links: programma-icoon
    PLeft := TPanel.Create(F);
    PLeft.Parent := F;
    PLeft.Align := alLeft;
    PLeft.Width := 88;
    PLeft.BevelOuter := bvNone;

    Img := TImage.Create(F);
    Img.Parent := PLeft;
    Img.SetBounds(16, 16, 56, 56);
    Img.Stretch := True;
    Img.Proportional := True;
    Img.Picture.Assign(Application.Icon);

    // rechts: tekst
    PText := TPanel.Create(F);
    PText.Parent := F;
    PText.Align := alClient;
    PText.BevelOuter := bvNone;
    PText.BorderSpacing.Right := 16;

    L := AddLabel('Logic', 12);
    L.Font.Size := 16;
    L.Font.Style := [fsBold];
    AddLabel(sVersion + AppVersion, 0);
    AddLabel('© 2026 ' + AppAuthor, 0);
    L := AddLabel(AppEmail, 0);
    L.Font.Color := clBlue;
    L.Cursor := crHandPoint;
    L.OnClick := @F.MailClick;
    L.OnMouseEnter := @F.UrlEnter;
    L.OnMouseLeave := @F.UrlLeave;
    AddLabel(sDesc, 12);
    AddLabel(sCredit, 10);
    AddLabel(sLicense, 4);

    L := AddLabel(AppUrl, 10);
    L.Font.Color := clBlue;
    L.Cursor := crHandPoint;
    L.OnClick := @F.UrlClick;
    L.OnMouseEnter := @F.UrlEnter;
    L.OnMouseLeave := @F.UrlLeave;

    F.ShowModal;
  finally
    F.Free;
  end;
end;

end.
