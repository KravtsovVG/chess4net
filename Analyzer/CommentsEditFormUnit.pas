unit CommentsEditFormUnit;

interface

uses
  Forms, StdCtrls, TntStdCtrls, Classes, Controls, Messages;

type
  TCommentsEditForm = class;
  
  TTntMemo = class(TntStdCtrls.TTntMemo)
  private
    function FGetCommentsEditForm: TCommentsEditForm;
    procedure CNKeyDown(var Message: TWMKeyDown); message CN_KEYDOWN;
    property CommentsEditForm: TCommentsEditForm read FGetCommentsEditForm;
  end;

  TCommentsEditForm = class(TForm)
    OkButton: TButton;
    CommentsMemo: TTntMemo;
    CancelButton: TButton;
    procedure CommentsMemoChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    function FGetFormattedComments: WideString;
    procedure FSetComments(const wstrValue: WideString);
    property Comments: WideString read FGetFormattedComments write FSetComments;
  public
    class function Edit(var wstrComments: WideString): boolean;
  end;

implementation

uses
  Windows,
  //
  WinControlHlpUnit;

{$R *.dfm}

////////////////////////////////////////////////////////////////////////////////
// TCommentsEditForm

class function TCommentsEditForm.Edit(var wstrComments: WideString): boolean;
begin
  Result := FALSE;

  with TCommentsEditForm.Create(nil) do
  try
    Comments := wstrComments;
    if (ShowModal <> mrOk) then
      exit;
    wstrComments := Comments;
  finally
    Release;
  end;

  Result := TRUE;
end;


function TCommentsEditForm.FGetFormattedComments: WideString;
var
  iPos: integer;
  bInsertSpaceFlag: boolean;

  procedure NCollectToWords(var wstrDest: WideString; wchSrc: WideChar);
  begin
    if (wchSrc = ' ') then
    begin
      bInsertSpaceFlag := (iPos > 1);
      exit;
    end;

    if (bInsertSpaceFlag) then
    begin
      bInsertSpaceFlag := FALSE;
      wstrDest[iPos] := ' ';
      inc(iPos);
    end;

    wstrDest[iPos] := wchSrc;
    inc(iPos);
  end;

var
  iLen: integer;
  i, j: integer;
  wstrSource: WideString;
begin // .FGetFormattedComments
  iLen := 0;
  for i := 0 to CommentsMemo.Lines.Count - 1 do
    inc(iLen, Length(CommentsMemo.Lines[i]));

  SetLength(Result, iLen);

  iPos := 1;
  bInsertSpaceFlag := FALSE;

  for i := 0 to CommentsMemo.Lines.Count - 1 do
  begin
    wstrSource := CommentsMemo.Lines[i];
    for j := 1 to Length(wstrSource) do
      NCollectToWords(Result, wstrSource[j]);
    bInsertSpaceFlag := TRUE;      
  end;

  SetLength(Result, iPos - 1);

end;


procedure TCommentsEditForm.FSetComments(const wstrValue: WideString);
begin
  CommentsMemo.Text := wstrValue;
end;

procedure TCommentsEditForm.CommentsMemoChange(Sender: TObject);
begin
  OkButton.Enabled := TRUE;
end;


procedure TCommentsEditForm.FormShow(Sender: TObject);
begin
  OkButton.Enabled := FALSE;
end;

////////////////////////////////////////////////////////////////////////////////
// TTntMemo

procedure TTntMemo.CNKeyDown(var Message: TWMKeyDown);
begin
  case Message.CharCode of
    VK_RETURN:
    begin
      if ((GetKeyState(VK_CONTROL) and (not $7FFF)) <> 0) then
      begin
        Message.Result := 1;
        CommentsEditForm.OkButton.Click;
      end;
    end;

    VK_ESCAPE:
    begin
      Message.Result := 1;
      CommentsEditForm.CancelButton.Click;
      exit;
    end;

  end;

  TWinControlHlp.CNKeyDown(self, Message);  
end;


function TTntMemo.FGetCommentsEditForm: TCommentsEditForm;
begin
  Result := Owner as TCommentsEditForm;
end;

end.
