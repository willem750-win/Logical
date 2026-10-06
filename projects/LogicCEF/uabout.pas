unit uAbout;

{ About-venster van Logic. Het venster wordt volledig in code opgebouwd
  (geen .lfm), zodat het zowel onder Windows als Linux werkt. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, StdCtrls, ExtCtrls,
  LCLIntf, chatgridpcodeSmall;

const
  AppVersion = '1.0.0';
  AppUrl     = 'https://github.com/willem750-win/Logical';

procedure ShowAbout(ALang: chatgridpcodeSmall.TLanguage);

implementation

type
  TAboutForm = class(TForm)
  private
    procedure UrlClick(Sender: TObject);
    procedure UrlEnter(Sender: TObject);
    procedure UrlLeave(Sender: TObject);
  end;

procedure TAboutForm.UrlClick(Sender: TObject);
begin
  OpenURL(AppUrl);
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
  PLeft, PText, PBottom: TPanel;
  Img: TImage;
  L: TLabel;
  BOk: TButton;
  sCaption, sVersion, sDesc, sCredit, sLicense: string;

  // labels worden van boven naar beneden toegevoegd; alTop + Top groot
  // zorgt dat elk nieuw label onder het vorige komt
  function AddLabel(const AText: string; ASpaceAbove: Integer): TLabel;
  begin
    Result := TLabel.Create(F);
    Result.Parent := PText;
    Result.Align := alTop;
    Result.Top := MaxInt div 2;
    Result.BorderSpacing.Top := ASpaceAbove;
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
      end;
  else // lgDutch
    begin
      sCaption := 'Over Logic';
      sVersion := 'Versie ';
      sDesc    := 'Simulator voor digitale schakelingen: bouw een schakeling met '
                + 'schakelaars, poorten, tellers, geheugens en displays, en zie ze werken.';
      sCredit  := 'Gebaseerd op de freeware-componenten van Jan Verhoeven.';
      sLicense := 'Uitgebracht onder de MIT-licentie.';
    end;
  end;

  F := TAboutForm.CreateNew(nil);
  try
    F.Caption := sCaption;
    F.BorderStyle := bsDialog;
    F.Position := poMainFormCenter;
    F.ClientWidth := 460;
    F.ClientHeight := 300;

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
