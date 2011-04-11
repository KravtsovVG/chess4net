////////////////////////////////////////////////////////////////////////////////
// All code below is exclusively owned by author of Chess4Net - Pavel Perminov
// (packpaul@mail.ru, packpaul1@gmail.com).
// Any changes, modifications, borrowing and adaptation are a subject for
// explicit permition from the owner.

unit ConnectorUnit;

interface

uses
  plugin,
  Classes, ExtCtrls;

type
  TConnectorEvent = (ceConnected, ceDisconnected, ceData, ceError);

  TConnectorHandler = procedure(ce: TConnectorEvent; d1: pointer = nil;
                                d2: pointer = nil) of object;

  TConnector = class(TDataModule)
    sendTimer: TTimer;
    procedure sendTimerTimer(Sender: TObject);
  private
    _connected : boolean;
    _handler: TConnectorHandler;

{$IFDEF DEBUG_LOG}
    _logFile: Text;

    procedure InitLog;
    procedure WriteToLog(const s: string);
    procedure CloseLog;
{$ENDIF}

  public
    property connected: boolean read _connected;
    procedure Close;
    procedure SendData(const d: string);
    procedure Free;
    class function Create(vpContactlistEntry: PTtkContactListEntry; h: TConnectorHandler): TConnector; reintroduce;
  end;

function EnableBroadcast: boolean;
procedure DisableBroadcast;

var
  trillianOwnerNick: string;  

implementation

{$R *.dfm}

{$J+} {$I-}

uses
  SysUtils, StrUtils,
  ControlUnit, GlobalsLocalUnit;

var
  connector: TConnector; // singleton

  gpContactlistEntry: PTtkContactListEntry;
  gMessageBroadcastID: integer;

  msg_sending, unformated_msg_sending: string; // ���������� ���������

  // cntrMsgIn � cntrMsgOut ���� ������� ��� ����������� ���� � ����������� �����������
  cntrMsgIn: integer;  // ������� �������� ���������
  cntrMsgOut: integer; // ������� ��������� ���������
  msg_buf: string; // ����� ���������

const
  CONNECTOR_INSTANCES: integer = 0;
  M_CHESS4NET = 'Chess4Net';
  // <���������> ::= PROMPT_HEAD <����� ���������> PROMPT_TAIL <���������>
  PROMPT_HEAD = 'Ch4N:';
  PROMPT_TAIL = '>';
  MSG_CLOSE = 'ext';
  MAX_RESEND_TRYS = 9; // ������������ ���������� ������� ��������


function SendMessage(const vMessage: string): boolean;
var
  sendMessage: TTtkMessage;
begin
  TrillianInitialize(sendMessage);
  sendMessage.medium := gpContactlistEntry.medium;
  sendMessage.connection_id := gpContactlistEntry.connection_id;
  sendMessage._type := 'outgoing_privateMessage';
  sendMessage.name := gpContactlistEntry.real_name;
  sendMessage.text := PAnsiChar(vMessage);

  Result := (PluginSend(GUID, 'messageSend', @sendMessage) = 0);
end;


// ���������������� �������� ���������. TRUE - ���� ������������� �������
function DeformatMsg(var msg: string; var n: integer): boolean;
var
  l: integer;
begin
  result := FALSE;
  if LeftStr(msg, length(PROMPT_HEAD)) = PROMPT_HEAD then
    begin
{$IFDEF DEBUG_LOG}
      connector.WriteToLog('>> ' + msg);
{$ENDIF}
      msg := RightStr(msg, length(msg) - length(PROMPT_HEAD));
      l := pos(PROMPT_TAIL, msg);
      if l = 0 then exit;
      try
        n := StrToInt(LeftStr(msg, l-1));
      except
        on Exception do exit;
      end;
      msg := AnsiReplaceStr(RightStr(msg, length(msg) - l), '&amp;', '&');
      result := TRUE;
    end;
end;


function FilterMsg(msg: string): boolean;
var
  cntrMsg: integer;
begin
  if not connector.connected then
    begin
      if msg = MSG_INVITATION then
        begin
          SendMessage(MSG_INVITATION);
          connector._connected := TRUE;
          connector._handler(ceConnected);
          Result := TRUE;
        end
      else
        Result := FALSE;
    end
  else // connector.connected
    begin
      if msg_sending <> '' then
        begin
          msg_sending := '';
          unformated_msg_sending := '';
          inc(cntrMsgOut);
        end;
      if DeformatMsg(msg, cntrMsg) then
        begin
          Result := TRUE;
          if cntrMsg > cntrMsgIn then
            begin
              inc(cntrMsgIn);
              if cntrMsg > cntrMsgIn then
                begin
                  connector._handler(ceError); // ����� �����
                  exit;
                end
            end
          else
            exit; // ������� ������� � ����� ������� ��������
          if msg = MSG_CLOSE then
            begin
              connector._handler(ceDisconnected);
              connector._connected := FALSE;
            end
          else
            connector._handler(ceData, @msg);
        end
      else
        Result := FALSE;
    end;
end;

function NotifySender(const vMessage: string): boolean;
begin
  if not Assigned(connector) then
    begin
      Result := FALSE;
      exit;
    end;
  if (not connector.connected) and (vMessage = MSG_INVITATION) then
    begin
      Result := TRUE;
      exit;
    end;

  Result := (msg_sending = vMessage);
  if not Result then
    exit;

{$IFDEF DEBUG_LOG}
   connector.WriteToLog('<< ' + msg_sending);
{$ENDIF}
   msg_sending := '';
   unformated_msg_sending := '';
   inc(cntrMsgOut);
end;


function StripHTMLTags(const strHTML: string): string;
var
  P: PChar;
  InTag: Boolean;
begin
  P := PChar(strHTML);
  Result := '';

  InTag := False;
  repeat
    if P^ = '<' then InTag := True
      else
    if InTag and (P^ = '>') then InTag := False
      else
    if not InTag then
      begin
        if (P^ in [#9, #32]) and ((P+1)^ in [#10, #13, #32, #9, '<']) then
        else
          Result := Result + P^;
      end;

    Inc(P);
  until (P^ = #0);

  // ��������������� ��������� ��������
  Result := StringReplace(Result, '&gt;',   '>',  [rfReplaceAll]);
  Result := StringReplace(Result, '&amp;',  '&',  [rfReplaceAll]);
//  Result := StringReplace(Result, '&quot;', '"',  [rfReplaceAll]);
//  Result := StringReplace(Result, '&apos;', '''', [rfReplaceAll]);
//  Result := StringReplace(Result, '&lt;',   '<',  [rfReplaceAll]);
  // ����� ����� �������� ������ ������� �� RFC, ���� �����
end;


function MessageBroadcastCallback(WindowID: Integer; SubWindow: PAnsiChar;
           Event: PAnsiChar; Data: Pointer; UserData : Pointer): Integer; cdecl;
const
  INCOMING_PRIVATE_MESSAGE = 'incoming_privateMessage';
  OUTGOING_PRIVATE_MESSAGE = 'outgoing_privateMessage';
var
  pMessage: PTtkMessage;
  messageText: string;
begin
  Result := 0;
  pMessage := Data;

  messageText := StripHTMLTags(pMessage.text);

  if (not Assigned(connector)) then
    begin
      if (string(pMessage._type) = OUTGOING_PRIVATE_MESSAGE) and
         (UpperCase(messageText) = START_PLUGIN_ALIAS) then
        StartFromAlias(pMessage);
      exit;
    end;

  if not ((string(pMessage.name) = gpContactlistEntry.real_name) and
          (string(pMessage.medium) = gpContactlistEntry.medium) and
          (pMessage.connection_id = gpContactlistEntry.connection_id)) then
    exit; // ��������� �� ��. �������� / ��. ����

  if (string(pMessage._type) = INCOMING_PRIVATE_MESSAGE) then
    begin
      if FilterMsg(messageText) then
        begin
          // TODO: �������� ���������
          // Trillian �� ����� ����������� ��������� ���������. �������� �� ������������ ASM ��� ���������� callstack(�)?
          // �� ������� ������ ����� ��������� � ��� ����������� ������
          pMessage.text^ := #0;
          pMessage.display_name^ := #0;
        end;
    end
  else
  if (string(pMessage._type) = OUTGOING_PRIVATE_MESSAGE) then
    begin
      trillianOwnerNick := pMessage.display_name;
        if NotifySender(messageText) then
        begin
          // TODO: �������� ���������
          pMessage.text^ := #0;
          pMessage.display_name^ := #0;
        end;
    end;
end;


function EnableBroadcast: boolean;
var
  messageBroadcast: TTtkMessageBroadcast;
begin
  trillianInitialize(messageBroadCast);
  messageBroadcast.callback := MessageBroadcastCallback;
  gMessageBroadcastID := PluginSend(GUID, 'messageBroadcastEnable', @messageBroadcast);
  Result := (gMessageBroadcastID >= 0);
end;


procedure DisableBroadcast;
var
  messageBroadcast: TTtkMessageBroadcast;
begin
  if gMessageBroadcastID >= 0 then
    begin
      trillianInitialize(messageBroadCast);
      MessageBroadcast.broadcast_id := gMessageBroadcastID;
      PluginSend(GUID, 'messageBroadcastDisable', @messageBroadCast);
    end;
end;


// �������������� ��������� ���������
function FormatMsg(const msg: string): string;
begin
  Result := PROMPT_HEAD + IntToStr(cntrMsgOut) + PROMPT_TAIL + msg;
end;


procedure TConnector.Close;
begin
  if _connected then
    begin
      msg_sending := FormatMsg(MSG_CLOSE);
      SendMessage(msg_sending);
      sendTimer.Enabled := FALSE;
      _connected := FALSE;
      _handler(ceDisconnected);
    end;
{$IFDEF DEBUG_LOG}
  CloseLog;
{$ENDIF}
end;


procedure TConnector.SendData(const d: string);
begin
  if d = MSG_CLOSE then
    connector._handler(ceError)
  else
    begin
      msg_buf := msg_buf + d;
      sendTimer.Enabled := TRUE; // �������� ��������� � ��������� �������� -> �� ����� �������
    end; { if d = MSG_CLOSE }
end;


class function TConnector.Create(vpContactlistEntry: PTtkContactListEntry; h: TConnectorHandler): TConnector;
begin
  if CONNECTOR_INSTANCES > 0 then
    raise Exception.Create('No more than 1 instance of TConnector is possible!'); // ***

  gpContactlistEntry := vpContactlistEntry;

//  if not EnableBroadcast then
//    raise Exception.Create('ERROR: Broadcast setting fault. Plugin not started!');

  if not Assigned(connector) then
    begin
      connector := inherited Create(nil); // Owner - ?
      connector._handler := h;
      // TODO: �������� connector � ������
      SendMessage(MSG_INVITATION);
    end;

  cntrMsgIn := 0;
  cntrMsgOut := 1;
  msg_sending := '';
  unformated_msg_sending := '';
  msg_buf := '';
  inc(CONNECTOR_INSTANCES);
  result := connector;

{$IFDEF DEBUG_LOG}
  connector.InitLog;
{$ENDIF}
end;


procedure TConnector.Free;
begin
  Close;
//  DisableBroadcast;
  dec(CONNECTOR_INSTANCES);
  // TODO: ������ connector �� ����
  if CONNECTOR_INSTANCES = 0 then
    begin
      inherited;
      connector := nil;
    end;
end;

{$IFDEF DEBUG_LOG}
procedure TConnector.InitLog;
begin
  AssignFile(_logFile, Chess4NetPath + 'Chess4Net_CONNECTORLOG.txt');
  Append(_logFile);
  if IOResult <> 0 then
    begin
      Rewrite(_logFile);
      if IOResult <> 0 then
        begin
          AssignFile(_logFile, Chess4NetPath + 'Chess4Net_CONNECTORLOG~.txt');
          Append(_logFile);
          if IOResult <> 0 then Rewrite(_logFile);
        end;
    end;

   WriteToLog('[' + DateTimeToStr(Now) + ']');
end;


procedure TConnector.WriteToLog(const s: string);
begin
  writeln(_logFile, s);
  Flush(_logFile);
end;


procedure TConnector.CloseLog;
begin
  CloseFile(_logFile);
end;
{$ENDIF}

procedure TConnector.sendTimerTimer(Sender: TObject);
const
  RESEND_COUNT : integer = 0;
begin
  if msg_sending = '' then
    begin
      sendTimer.Enabled := FALSE;
      if msg_buf <> '' then
        begin
          unformated_msg_sending := msg_buf;
          msg_sending := FormatMsg(msg_buf);
          msg_buf := '';
          SendMessage(msg_sending);
        end;
    end
  else
    begin
{$IFDEF DEBUG_LOG}
      WriteToLog('resend: ' + msg_sending);
{$ENDIF}
      inc(RESEND_COUNT);
      if RESEND_COUNT = MAX_RESEND_TRYS then
        begin
          RESEND_COUNT := 0;
          SendMessage(msg_sending);
        end;
    end;
end;

end.

