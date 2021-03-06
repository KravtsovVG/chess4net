////////////////////////////////////////////////////////////////////////////////
// All code below is exclusively owned by author of Chess4Net - Pavel Perminov
// (packpaul@mail.ru, packpaul1@gmail.com).
// Any changes, modifications, borrowing and adaptation are a subject for
// explicit permition from the owner.

{$MODE Delphi}

interface

uses
  LCLIntf, SysUtils, Classes, Graphics, Controls, Forms,
  ExtCtrls, StdCtrls, Buttons, LResources,
  //
  ModalFormBase, ModalForm;

type
  TContinueHandler = procedure of object;

  TContinueForm = class(TModalForm)
    ContinueButton: TButton;
    ContinueLabel: TLabel;
    procedure ContinueButtonClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    ContinueHandler: TContinueHandler;
    shuted: boolean;
  public
    procedure Shut;
    function GetModalID : TModalFormID; override;
    constructor Create(Owner: TForm; h: TContinueHandler = nil); reintroduce; overload;
  end;


implementation

uses
  GlobalsUnit;

procedure TContinueForm.ContinueButtonClick(Sender: TObject);
begin
  Close;
end;


constructor TContinueForm.Create(Owner: TForm; h: TContinueHandler = nil);
begin
  self.FormStyle := Owner.FormStyle;
  inherited Create(Owner);
  shuted := FALSE;
  ContinueHandler := h;
end;


procedure TContinueForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  if not shuted then
    begin
      ModalResult := ContinueButton.ModalResult;
      if Assigned(ContinueHandler) then
        ContinueHandler;
    end
  else
    ModalResult := mrNone;
end;


procedure TContinueForm.Shut;
begin
  shuted:= TRUE;
  Close;
end;

function TContinueForm.GetModalID: TModalFormID;
begin
  Result := mfContinue;
end;

procedure TContinueForm.FormCreate(Sender: TObject);
begin
  Caption := DIALOG_CAPTION;
end;

initialization
  {$i ContinueUnit.lrs}

end.
