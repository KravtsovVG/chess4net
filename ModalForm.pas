unit ModalForm;

interface

uses
  Forms, TntForms, Dialogs, Classes, Windows;

type
  TModalForm = class;
  TModalFormClass = class of TModalForm;

  TModalFormID = (mfNone, mfMsgClose, mfMsgLeave, mfMsgAbort, mfMsgResign,
                  mfMsgDraw, mfMsgTakeBack, mfMsgAdjourn, mfConnecting, mfGameOptions,
                  mfLookFeel, mfCanPause, mfContinue, mfIncompatible
{$IFDEF SKYPE}
                  , mfSelectSkypeContact
{$ENDIF}
{$IFDEF MIRANDA}
                  , mfTransmitting, mfTransmitGame
{$ENDIF}

                  );

  TModalFormHandler = procedure(modSender: TModalForm; modID: TModalFormID) of object;

  TDialogs = class
  private
    IDCount: array[TModalFormID] of word;
    frmList: TList;
    function GetShowing: boolean;
  protected
    Handler: TModalFormHandler;
  public
    Owner: TForm;
    procedure MessageDlg(const wstrMsg: WideString; DlgType: TMsgDlgType;
      Buttons: TMsgDlgButtons; msgDlgID: TModalFormID);
    function CreateDialog(modalFormClass: TModalFormClass): TModalForm;
    procedure SetShowing(msgDlgID: TModalFormID);
    procedure UnsetShowing(msgDlgID: TModalFormID; msgDlg: TModalForm = nil);
    function InFormList(frm: TForm): boolean;
    procedure BringToFront;
    procedure MoveForms(dx, dy: integer);
    constructor Create(Owner: TForm; Handler: TModalFormHandler);
    destructor Destroy; override;
    property Showing: boolean read GetShowing;
  end;

  TModalForm = class(TTntForm)
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ButtonClick(Sender: TObject);
  private
    GenFormShow: TNotifyEvent;
    GenFormClose: TCloseEvent;
  protected
    Handler: TModalFormhandler;
    dlgOwner: TDialogs;
    function GetHandle: hWnd; virtual;
    function GetEnabled_: boolean; virtual;
    procedure SetEnabled_(flag: boolean); virtual;
    function GetLeft_: integer; virtual;
    procedure SetLeft_(x: integer); virtual;
    function GetTop_: integer; virtual;
    procedure SetTop_(y: integer); virtual;
  public
    procedure Show; virtual;
    constructor Create(Owner: TForm; modID: TModalFormID = mfNone; modHandler: TModalFormHandler = nil); reintroduce; overload;
    constructor Create(dlgOwner: TDialogs; modID: TModalFormID; modHandler: TModalFormHandler); reintroduce; overload;
    class function GetModalID : TModalFormID; virtual;

    property Handle: hWnd read GetHandle;
    property Enabled: boolean read GetEnabled_ write SetEnabled_;
    property Left: integer read GetLeft_ write SetLeft_;
    property Top: integer read GetTop_ write SetTop_;
  end;

implementation

uses
  SysUtils, StdCtrls, Controls,
  DialogUnit, GlobalsUnit;

procedure TModalForm.FormShow(Sender: TObject);
var
  frmOwner: TForm;
begin
  if (Assigned(Owner)) then
  begin
    frmOwner := (Owner as TForm);
    Left:= frmOwner.Left + (frmOwner.Width - Width) div 2;
    Top:= frmOwner.Top + (frmOwner.Height - Height) div 2;
  end;
  if Assigned(GenFormShow) then
    GenFormShow(Sender);
end;


procedure TModalForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(GenFormClose) then
    GenFormClose(Sender, Action);
  if Assigned(dlgOwner) then
    dlgOwner.UnsetShowing(GetModalID, self);
  if fsModal in FormState then
    exit;
  if Assigned(Handler) then
    Handler(self, GetModalID);
  Action := caFree;  
end;


procedure TModalForm.ButtonClick(Sender: TObject);
begin
  if fsModal in FormState then
    exit;  
  Close;
end;


constructor TModalForm.Create(Owner: TForm; modID: TModalFormID; modHandler: TModalFormHandler);
var
  i: integer;
begin
  if (Assigned(Owner)) then
    FormStyle := Owner.FormStyle;
  inherited Create(Owner);
  Handler := modhandler;

  GenFormShow := OnShow;
  GenFormClose := OnClose;
  OnShow := FormShow;
  OnClose := FormClose;

  for i := 0 to (ComponentCount - 1) do
    begin
      if (Components[i] is TButton) then
        (Components[i] as TButton).OnClick := ButtonClick;
    end;
end;

constructor TModalForm.Create(dlgOwner: TDialogs; modID: TModalFormID; modHandler: TModalFormHandler);
begin
  self.dlgOwner := dlgOwner;
  Create(dlgOwner.Owner, modID, modHandler);
  dlgOwner.SetShowing(modID);
end;


class function TModalForm.GetModalID : TModalFormID;
begin
  Result := mfNone;
end;


function TModalForm.GetHandle: hWnd;
begin
  Result := inherited Handle;
end;


function TModalForm.GetEnabled_: boolean;
begin
  Result := inherited Enabled;
end;


procedure TModalForm.SetEnabled_(flag: boolean);
begin
  inherited Enabled := flag;
end;


procedure TModalForm.Show;
begin
  inherited Show;
end;


function TModalForm.GetLeft_: integer;
begin
  Result := inherited Left;
end;


procedure TModalForm.SetLeft_(x: integer);
begin
  inherited Left := x;
end;


function TModalForm.GetTop_: integer;
begin
  Result := inherited Top;
end;


procedure TModalForm.SetTop_(y: integer);
begin
  inherited Top := y;
end;

{-------------------------- TDialogs ------------------------------}

function TDialogs.GetShowing: boolean;
var
  i: TModalFormID;
begin
  Result := TRUE;
  for i := Low(TModalFormID) to High(TModalFormID) do
    begin
      if IDCount[i] > 0 then
        exit;
    end;
  Result := FALSE;
end;


procedure TDialogs.UnsetShowing(msgDlgID: TModalFormID; msgDlg: TModalForm = nil);
var
  i: integer;
begin
  dec(IDCount[msgDlgID]);

  if Assigned(msgDlg) then
    begin
      for i := 0 to frmList.Count - 1 do
        begin
          if TModalForm(frmList[i]).Handle = msgDlg.Handle then
            begin
              frmList.Delete(i);
              break;
            end;
        end; { for }
    end;
  if frmList.Count > 0 then
    begin
      TModalForm(frmList.Last).Enabled := TRUE;
      TModalForm(frmList.Last).SetFocus;
    end
  else
    begin
      if (Assigned(Owner)) then
      begin
        Owner.Enabled := TRUE;
        Owner.SetFocus;
      end;
    end;
end;


function TDialogs.InFormList(frm: TForm): boolean;
var
  i: integer;
begin
  for i := 0 to frmList.Count - 1 do
    begin
      if TModalForm(frmList[i]).Handle = frm.Handle then
        begin
          Result := TRUE;
          exit;
        end;
    end;
  Result := FALSE;
end;


procedure TDialogs.MessageDlg(const wstrMsg: WideString; DlgType: TMsgDlgType; Buttons: TMsgDlgButtons; msgDlgID: TModalFormID);
var
  DialogForm: TDialogForm;
begin
  if (msgDlgID <> mfNone) and (IDCount[msgDlgID] > 0) then
    exit;
  DialogForm := TDialogForm.Create(self, wstrMsg, DlgType, Buttons, msgDlgID, Handler);
  DialogForm.Caption := DIALOG_CAPTION;
  SetShowing(msgDlgID);
  DialogForm.Show;
  frmList.Add(DialogForm);
end;


function TDialogs.CreateDialog(modalFormClass: TModalFormClass): TModalForm;
begin
  Result := modalFormClass.Create(self, modalFormClass.GetModalID, Handler);
  frmList.Add(Result);
end;


constructor TDialogs.Create(Owner: TForm; Handler: TModalFormHandler);
var
  i: TModalFormID;
begin
  self.Owner := Owner;
  self.Handler := Handler;
  frmList := TList.Create;
  for i := Low(TModalFormID) to High(TModalFormID) do
    IDCount[i] := 0;
end;


destructor TDialogs.Destroy;
begin
  frmList.Free;
  inherited;
end;


procedure TDialogs.SetShowing(msgDlgID: TModalFormID);
begin
  inc(IDCount[msgDlgID]);
  if frmList.Count > 0 then
    TModalForm(frmList.Last).Enabled := FALSE;
end;


procedure TDialogs.BringToFront;
var
  i: integer;
begin
  if frmList.Count = 0 then
    exit;
  for i := 0 to frmList.Count - 1 do
    TModalForm(frmList[i]).Show;
  TModalForm(frmList.Last).SetFocus;
end;


procedure TDialogs.MoveForms(dx, dy: integer);
var
  i: integer;
begin
  for i := 0 to frmList.Count - 1 do
    with TModalForm(frmList[i]) do
      begin
        Left := Left + dx;
        Top := Top + dy;
      end;
end;

end.

