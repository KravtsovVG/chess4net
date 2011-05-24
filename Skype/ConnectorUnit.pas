////////////////////////////////////////////////////////////////////////////////
// All code below is exclusively owned by author of Chess4Net - Pavel Perminov
// (packpaul@mail.ru, packpaul1@gmail.com).
// Any changes, modifications, borrowing and adaptation are a subject for
// explicit permition from the owner.

unit ConnectorUnit;

interface

uses
  Classes, TntClasses, ExtCtrls
{$IFDEF TESTING}
  , SkypeTS_TLB
{$ELSE}
  {$IFDEF SKYPE_API}
  , SkypeAPI_Skype
  {$ELSE SKYPE4COM}
  , SKYPE4COMLib_TLB
  {$ENDIF}
{$ENDIF}
  ;

type
  TContactsList = class(TTntStringList)
  private
    m_ConnectableUserCollection: IUserCollection;
    constructor FCreate(AConnectableUserCollection: IUserCollection);
    procedure FBuildData;
    function FGetHandle(iIndex: integer): WideString;
  public
    constructor Create;
    property Handle[iIndex: integer]: WideString read FGetHandle;
  end;


  TConnectorEvent = (ceConnected, ceDisconnected, ceData, ceError, ceSkypeError, ceShowConnectableUsers);

  TConnectorHandler = procedure(ce: TConnectorEvent; d1: pointer = nil;
                                d2: pointer = nil) of object;

  TSkypeState = (sAttaching, sAttached, sUserConnecting, sUserConnected);
  TSkypeStates = set of TSkypeState;

  TConnector = class
  private
    FHandler: TConnectorHandler;

    m_bConnected: boolean;

    m_strMsgSending, m_strUnformatedMsgSending: string; // ���������� ���������

    // m_iCntrMsgIn � m_iCntrMsgOut ���� ������� ��� ����������� ���� � ����������� �����������
    m_iCntrMsgIn: integer;  // ������� �������� ���������
    m_iCntrMsgOut: integer; // ������� ��������� ���������
    m_strMsgBuf: string; // ����� ���������

    m_iResendCount: integer;

    m_SendTimer: TTimer;
    m_UserConnectingTimer: TTimer;

    // Skype
    m_SkypeStates: TSkypeStates;
    m_wstrContactHandle: WideString;
    m_wstrlInBuffer: TTntStringList;
    m_SkypeApplicationStreams: IApplicationStreamCollection;

{$IFDEF DEBUG_LOG}
    _logFile: Text;

    procedure InitLog;
    procedure WriteToLog(const s: string);
    procedure CloseLog;
// SkypeLog >
    procedure LogApplicationStream(AApplicationStream: IApplicationStream);
// < SkypeLog
{$ENDIF}

    constructor FCreate(h: TConnectorHandler);

    procedure FDoHandler(ce: TConnectorEvent; d1: pointer = nil; d2: pointer = nil);

    function FFormatMsg(const msg: string): string;
    function FDeformatMsg(var wstrMsg: WideString; var n: integer): boolean;
    function FFilterMsg(wstrMsg: WideString): boolean;

    procedure FSendCommand(const wstrCommand: WideString);
    function FNotifySender(const wstrMsg: WideString): boolean;

    procedure FOnMessage(const wstrMessage: WideString);
    procedure FOnCommand(const wstrCommand: WideString);

    procedure FConnectIfNotConnected;
    function FIsUserConnected: boolean;
    procedure FSendInvitation;

    function FGetSkype: TSkype;
    procedure FBuildSkypeApplicationStreams;

    function FGetSkypeApplication: IApplication;
    function FGetUserHandle: WideString;

    procedure FSendTimerTimer(Sender: TObject);
    procedure FUserConnectingTimer(Sender: TObject);

    property SkypeApplication: IApplication read FGetSkypeApplication;

  protected
    procedure ROnCreate; virtual;
    procedure ROnDestroy; virtual;

  public
    class function Create(h: TConnectorHandler): TConnector; reintroduce;
    destructor Destroy; override;
    procedure Free;

    procedure ConnectToContact(const wstrContactHandle: WideString);

    procedure Close;

    procedure SendData(const d: string);
    procedure GetConnectableUsers(out AConnectableUsers: TContactsList);

    procedure CreateChildConnector(h: TConnectorHandler;
      out AConnector: TConnector); virtual;

    property connected: boolean read m_bConnected;

    property Skype: TSkype read FGetSkype;

    property ContactHandle: WideString read m_wstrContactHandle;
    property UserHandle: WideString read FGetUserHandle;
  end;

implementation

{$I-}

uses
  StrUtils, SysUtils, {  Forms,   Windows, }
  GlobalsLocalUnit;

type
  TChildConnector = class;

  TBaseConnector = class(TConnector)
  private
    m_ShowContactsTimer: TTimer;

    m_lstChildConnectors: TList;

    procedure FOnSkypeAttachmentStatus(ASender: TObject; Status: TAttachmentStatus);
    procedure FOnMessageStatus(ASender: TObject; const pMessage: IChatMessage; Status: TChatMessageStatus);
    procedure FOnSkypeApplicationDatagram(ASender: TObject; const pApp: IApplication;
      const pStream: IApplicationStream; const Text: WideString);

    procedure FShowSkypeConnectableUsers;

    procedure FCreateTimers;
    procedure FDestroyTimers;

    procedure FShowContactsTimer(Sender: TObject);

    procedure FAddChildConnector(const AChildConnector: TChildConnector);
    procedure FRemoveChildConnector(const AChildConnector: TChildConnector);

  protected
    procedure ROnCreate; override;
    procedure ROnDestroy; override;

  public
    class function Create(h: TConnectorHandler): TBaseConnector; reintroduce;
    procedure CreateChildConnector(h: TConnectorHandler;
      out AConnector: TConnector); override;
  end;


  TChildConnector = class(TConnector)
  private
    m_BaseConnector: TBaseConnector;
    constructor FCreate(h: TConnectorHandler; const ABaseConnector: TBaseConnector);
  public
    destructor Destroy; override;
  end;

const
  // <���������> ::= PROMPT_HEAD <����� ���������> PROMPT_TAIL <���������>
  PROMPT_HEAD = 'Ch4N:';
  PROMPT_TAIL = '>';
  MSG_CLOSE = 'ext';
  MAX_RESEND_TRYS = 9; // ������������ ���������� ������� ��������

var
  g_iBaseConnectorInstances: integer = 0;
  g_Skype: TSkype = nil;

////////////////////////////////////////////////////////////////////////////////
// TConnector

constructor TConnector.FCreate(h: TConnectorHandler);
begin
  inherited Create;

  FHandler := h;
  m_iCntrMsgOut := 1;

  ROnCreate;
end;


class function TConnector.Create(h: TConnectorHandler): TConnector;
begin
  Result :=  TBaseConnector.Create(h);
end;


destructor TConnector.Destroy;
begin
  m_SkypeApplicationStreams := nil;

  ROnDestroy;

  inherited;
end;


procedure TConnector.Free;
begin
  Close;

  dec(g_iBaseConnectorInstances);

  if (g_iBaseConnectorInstances = 0) then
  begin
    inherited;
  end;
end;


procedure TConnector.Close;
begin
  if (m_bConnected) then
  begin
    m_strMsgSending := FFormatMsg(MSG_CLOSE);
    FSendCommand(m_strMsgSending);
    m_SendTimer.Enabled := FALSE;
    m_bConnected := FALSE;
    FDoHandler(ceDisconnected);
  end;
{$IFDEF DEBUG_LOG}
  CloseLog;
{$ENDIF}
end;


// �������������� ��������� ���������
function TConnector.FFormatMsg(const msg: string): string;
begin
  Result := PROMPT_HEAD + IntToStr(m_iCntrMsgOut) + PROMPT_TAIL + msg;
end;


// ���������������� �������� ���������. TRUE - ���� ������������� �������
function TConnector.FDeformatMsg(var wstrMsg: WideString; var n: integer): boolean;
var
  l: integer;
begin
  Result := FALSE;
  if LeftStr(wstrMsg, length(PROMPT_HEAD)) = PROMPT_HEAD then
    begin
{$IFDEF DEBUG_LOG}
      WriteToLog('>> ' + wstrMsg);
{$ENDIF}
      wstrMsg := RightStr(wstrMsg, length(wstrMsg) - length(PROMPT_HEAD));
      l := pos(PROMPT_TAIL, wstrMsg);
      if l = 0 then exit;
      try
        n := StrToInt(LeftStr(wstrMsg, l - 1));
      except
        on Exception do exit;
      end;
      wstrMsg := AnsiReplaceStr(RightStr(wstrMsg, length(wstrMsg) - l), '&amp;', '&'); // TODO: WideString
      result := TRUE;
    end;
end;


function TConnector.FFilterMsg(wstrMsg: WideString): boolean;
var
  iCntrMsg: integer;
  strMsg: string;
begin
  if (not connected) then
  begin
    m_wstrlInBuffer.Add(wstrMsg);
    Result := FALSE;
    exit;
  end;
  begin
    if (m_strMsgSending <> '') then
    begin
      m_strMsgSending := '';
      m_strUnformatedMsgSending := '';
      inc(m_iCntrMsgOut);
    end;
    if (FDeformatMsg(wstrMsg, iCntrMsg)) then
    begin
      Result := TRUE;
      if (iCntrMsg > m_iCntrMsgIn) then
      begin
        inc(m_iCntrMsgIn);
        if (iCntrMsg > m_iCntrMsgIn) then
        begin
          FDoHandler(ceError); // ����� �����
          exit;
        end;
      end
      else
        exit; // ������� ������� � ����� ������� ��������
      if (wstrMsg = MSG_CLOSE) then
      begin
        FDoHandler(ceDisconnected);
        m_bConnected := FALSE;
      end
      else
      begin
        strMsg := wstrMsg;
        FDoHandler(ceData, @strMsg);
      end
    end
    else
      Result := FALSE;
  end;
end;


procedure TConnector.FSendCommand(const wstrCommand: WideString);
begin
  SkypeApplication.SendDatagram(wstrCommand, m_SkypeApplicationStreams);
//  Log('Command ' + wstrCommand);
  FNotifySender(wstrCommand);
end;


procedure TConnector.FDoHandler(ce: TConnectorEvent; d1: pointer = nil; d2: pointer = nil);
begin
  if (Assigned(FHandler)) then
    FHandler(ce, d1, d2);
end;


function TConnector.FNotifySender(const wstrMsg: WideString): boolean;
begin
  Result := ((not connected) and (wstrMsg = MSG_INVITATION));
  if (Result) then
    exit;

  Result := (m_strMsgSending = wstrMsg);
  if (not Result) then
    exit;

{$IFDEF DEBUG_LOG}
   WriteToLog('<< ' + m_strMsgSending);
{$ENDIF}

   m_strMsgSending := '';
   m_strUnformatedMsgSending := '';
   inc(m_iCntrMsgOut);
end;


function TConnector.FGetSkypeApplication: IApplication;
begin
  Result := g_Skype.Application[SKYPE_APP_NAME];
end;


procedure TConnector.SendData(const d: string);
begin
  if (d = MSG_CLOSE) then
    FDoHandler(ceError)
  else
  begin
    m_strMsgBuf := m_strMsgBuf + d;
    m_SendTimer.Enabled := TRUE; // �������� ��������� � ��������� �������� -> �� ����� �������
  end; { if d = MSG_CLOSE }
end;


procedure TConnector.GetConnectableUsers(out AConnectableUsers: TContactsList);
begin
  AConnectableUsers := TContactsList.FCreate(SkypeApplication.ConnectableUsers);
end;


function TConnector.FGetUserHandle: WideString;
begin
  Result := Skype.CurrentUserHandle;
end;


function TConnector.FGetSkype: TSkype;
begin
  Result := g_Skype;
end;


procedure TConnector.ConnectToContact(const wstrContactHandle: WideString);
begin
  m_wstrContactHandle := wstrContactHandle;
  FSendInvitation;
end;


procedure TConnector.FSendInvitation;
begin
  if (m_wstrContactHandle <> '') then
    Skype.SendMessage(m_wstrContactHandle, MSG_INVITATION);
  // Log('invitation sent.');
end;


procedure TConnector.ROnCreate;
begin
  m_wstrlInBuffer := TTntStringList.Create;

  m_SendTimer := TTimer.Create(nil);
  m_SendTimer.Enabled := FALSE;
  m_SendTimer.Interval := 100;
  m_SendTimer.OnTimer := FSendTimerTimer;

  m_UserConnectingTimer := TTimer.Create(nil);
  m_UserConnectingTimer.Enabled := FALSE;
  m_UserConnectingTimer.Interval := 500;
  m_UserConnectingTimer.OnTimer := FUserConnectingTimer;
end;


procedure TConnector.ROnDestroy;
begin
  FreeAndNil(m_UserConnectingTimer);
  FreeAndNil(m_SendTimer);

  FreeAndNil(m_wstrlInBuffer);
end;


procedure TConnector.FSendTimerTimer(Sender: TObject);
begin
  if (m_strMsgSending = '') then
  begin
    m_SendTimer.Enabled := FALSE;
    if (m_strMsgBuf <> '') then
    begin
      m_strUnformatedMsgSending := m_strMsgBuf;
      m_strMsgSending := FFormatMsg(m_strMsgBuf);
      m_strMsgBuf := '';
      FSendCommand(m_strMsgSending);
    end;
  end
  else
  begin
{$IFDEF DEBUG_LOG}
    WriteToLog('resend: ' + m_strMsgSending);
{$ENDIF}
    inc(m_iResendCount);
    if (m_iResendCount = MAX_RESEND_TRYS) then
    begin
      m_iResendCount := 0;
      FSendCommand(m_strMsgSending);
    end;
  end;
end;


procedure TConnector.FUserConnectingTimer(Sender: TObject);
var
  i: integer;
begin
  m_UserConnectingTimer.Enabled := FALSE;

  if (FIsUserConnected) then
  begin
    Exclude(m_SkypeStates, sUserConnecting);
    Include(m_SkypeStates, sUserConnected);

    FBuildSkypeApplicationStreams;

    FSendInvitation;

    m_bConnected := TRUE;
    FDoHandler(ceConnected);

    for i := 0 to m_wstrlInBuffer.Count - 1 do
      FFilterMsg(m_wstrlInBuffer[i]);
    m_wstrlInBuffer.Clear;
  end
  else
    m_UserConnectingTimer.Enabled := TRUE;
end;


procedure TConnector.FBuildSkypeApplicationStreams;
var
  i: integer;
  AApplicationStream: IApplicationStream;
begin
{$IFDEF DEBUG_LOG} // SkypeLog >
  WriteToLog('TConnector.FBuildSkypeApplicationStreams()');
{$ENDIF} // < SkypeLog

  m_SkypeApplicationStreams := CoApplicationStreamCollection.Create;

  for i := 1 to SkypeApplication.Streams.Count do
  begin
    AApplicationStream := SkypeApplication.Streams[i];
{$IFDEF DEBUG_LOG} // SkypeLog >
    WriteToLog('Stream #' + IntToStr(i) + ':');
    LogApplicationStream(AApplicationStream);
{$ENDIF} // < SkypeLog
    if (AApplicationStream.PartnerHandle = ContactHandle) then
    begin
      m_SkypeApplicationStreams.Add(AApplicationStream);
      break;
    end;
  end;

end;


procedure TConnector.CreateChildConnector(h: TConnectorHandler; out AConnector: TConnector);
begin
  AConnector := nil;
end;


procedure TConnector.FOnMessage(const wstrMessage: WideString);
begin
//        Log('Received message: ' + wstrMessage);
  if (wstrMessage = MSG_INVITATION) then
  begin
//          Log('invitation received');
    FConnectIfNotConnected;
  end;

end;


procedure TConnector.FOnCommand(const wstrCommand: WideString);
begin
  FConnectIfNotConnected;
  FFilterMsg(wstrCommand);
//  Log(WideFormat('FSkypeApplicationDatagram(): Command - %s', [Text]));
end;


procedure TConnector.FConnectIfNotConnected;
begin
  if (not ((sUserConnecting in m_SkypeStates) or FIsUserConnected)) then
  begin
    Include(m_SkypeStates, sUserConnecting);
    SkypeApplication.Connect(m_wstrContactHandle, TRUE);
    m_UserConnectingTimer.Enabled := TRUE;
//    Log('Connecting user started.');
  end;
end;


function TConnector.FIsUserConnected: boolean;

  function NUserInConnecting(const wstrUserHandle: WideString): boolean;
  var
    i: integer;
    UserCollection: IUserCollection;
  begin
    Result := FALSE;
    UserCollection := SkypeApplication.ConnectingUsers;
    for i := 1 to UserCollection.Count do
      if (UserCollection.Item[i].Handle = wstrUserHandle) then
      begin
        Result := TRUE;
        exit;
      end;
  end;

begin // TBaseConnector.FIsUserConnected
  Result := (sUserConnected in m_SkypeStates) or
    ((sUserConnecting in m_SkypeStates) and (not NUserInConnecting(self.m_wstrContactHandle)));
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

// SkypeLog >
procedure TConnector.LogApplicationStream(AApplicationStream: IApplicationStream);
begin
  WriteToLog('Addr: $' + IntToHex(Integer(AApplicationStream), 8));
  WriteToLog('PartnerHandle: ' + AApplicationStream.PartnerHandle);
end;
// < SkypeLog
{$ENDIF}

////////////////////////////////////////////////////////////////////////////////
// TBaseConnector

class function TBaseConnector.Create(h: TConnectorHandler): TBaseConnector;
begin
  Result := nil;

  if (g_iBaseConnectorInstances > 0) then
    raise Exception.Create('No more than 1 instance of TBaseConnector is possible!');

  try
{$IFDEF TESTING}
    g_Skype := TSkype.Create(nil);
    g_Skype.Connect;
{$ELSE}
  {$IFDEF SKYPE_API}
    g_Skype := TSkype.Create(SKYPE_APP_NAME);
  {$ELSE}
    g_Skype := TSkype.Create(nil);
  {$ENDIF}
{$ENDIF}
  except
    h(ceSkypeError);
    exit;
  end;

  if (not g_Skype.Client.IsRunning) then
    g_Skype.Client.Start(TRUE, TRUE);
  // TODO: handle here cases when Skype cannot start

  Result := TBaseConnector.FCreate(h);
  inc(g_iBaseConnectorInstances);

{$IFDEF DEBUG_LOG}
  Result.InitLog;
{$ENDIF}
end;


procedure TBaseConnector.ROnCreate;
begin
  inherited;

  m_lstChildConnectors := TList.Create;

  FCreateTimers;

  if (Assigned(g_Skype)) then
  begin
    Skype.OnAttachmentStatus := FOnSkypeAttachmentStatus;
    Skype.OnMessageStatus := FOnMessageStatus;
    Skype.OnApplicationDatagram := FOnSkypeApplicationDatagram;
  end;

  m_SkypeStates := [sAttaching];
  Skype.Attach(5, FALSE);

  m_ShowContactsTimer.Enabled := TRUE;
end;


procedure TBaseConnector.FCreateTimers;
begin
  m_ShowContactsTimer := TTimer.Create(nil);
  m_ShowContactsTimer.Enabled := FALSE;
  m_ShowContactsTimer.Interval := 500;
  m_ShowContactsTimer.OnTimer := FShowContactsTimer;
end;


procedure TBaseConnector.FDestroyTimers;
begin
  FreeAndNil(m_ShowContactsTimer);
end;


procedure TBaseConnector.FOnMessageStatus(ASender: TObject;
  const pMessage: IChatMessage; Status: TChatMessageStatus);
var
  i: integer;
begin
  case Status of
    cmsReceived:
    begin
      if (pMessage.Sender.Handle = m_wstrContactHandle) then
      begin
        FOnMessage(pMessage.Body);
        exit;
      end;

      for i := 0 to m_lstChildConnectors.Count - 1 do
      begin
        with TChildConnector(m_lstChildConnectors[i]) do
        begin
          if (pMessage.Sender.Handle = ContactHandle) then
          begin
            FOnMessage(pMessage.Body);
            break;
          end;
        end;
      end; // for
    end;
  end; // case
end;


procedure TBaseConnector.FOnSkypeAttachmentStatus(ASender: TObject; Status: TAttachmentStatus);
begin
// Log(Skype.Convert.AttachmentStatusToText(Status));
  case Status of
    apiAttachAvailable:
    begin
      Skype.Attach(5, FALSE);
//      Log('attaching Skype');
    end;

    apiAttachSuccess:
    begin
      m_SkypeStates := [sAttached];
//      Log('Skype attached');      
    end;
  end; // case
end;


procedure TBaseConnector.FOnSkypeApplicationDatagram(ASender: TObject; const pApp: IApplication;
  const pStream: IApplicationStream; const Text: WideString);
var
  i: integer;
begin
{$IFDEF DEBUG_LOG} // SkypeLog >
  WriteToLog('TBaseConnector.FOnSkypeApplicationDatagram()');
  LogApplicationStream(pStream); 
{$ENDIF} // < SkypeLog

  if (pApp.Name <> SKYPE_APP_NAME) then
    exit;

  if (pStream.PartnerHandle = m_wstrContactHandle) then
  begin
    FOnCommand(Text);
    exit;
  end;

  for i := 0 to m_lstChildConnectors.Count - 1 do
  begin
    with TChildConnector(m_lstChildConnectors[i]) do
    begin
      if (pStream.PartnerHandle = ContactHandle) then
      begin
        FOnCommand(Text);
        break;
      end;
    end;
  end; // for

end;


procedure TBaseConnector.FShowContactsTimer(Sender: TObject);
begin
  if (sAttached in m_SkypeStates) then
  begin
    m_ShowContactsTimer.Enabled := FALSE;
    SkypeApplication.Create;
    FShowSkypeConnectableUsers;
  end;
end;


procedure TBaseConnector.FShowSkypeConnectableUsers;
begin
  FDoHandler(ceShowConnectableUsers);
end;


procedure TBaseConnector.ROnDestroy;
var
  App: IApplication;
begin
  App := SkypeApplication;
  App.Delete;
  App := nil;

{$IFDEF TESTING}
  Skype.Disconnect;
{$ENDIF}
  FreeAndNil(g_Skype);

  FDestroyTimers;

  FreeAndNil(m_lstChildConnectors);

  inherited;
end;


procedure TBaseConnector.CreateChildConnector(h: TConnectorHandler;
  out AConnector: TConnector);
begin
  AConnector := TChildConnector.FCreate(h, self);
end;


procedure TBaseConnector.FAddChildConnector(const AChildConnector: TChildConnector);
begin
  m_lstChildConnectors.Add(AChildConnector);
end;


procedure TBaseConnector.FRemoveChildConnector(const AChildConnector: TChildConnector);
begin
  m_lstChildConnectors.Remove(AChildConnector);
end;

////////////////////////////////////////////////////////////////////////////////
// TChildConnector

constructor TChildConnector.FCreate(h: TConnectorHandler;
  const ABaseConnector: TBaseConnector);
begin
  inherited FCreate(h);
  m_BaseConnector := ABaseConnector;
  m_BaseConnector.FAddChildConnector(self);
end;


destructor TChildConnector.Destroy;
begin
  m_BaseConnector.FRemoveChildConnector(self);
  inherited;
end;

////////////////////////////////////////////////////////////////////////////////
// TContactsList

constructor TContactsList.Create;
begin
  raise Exception.Create('TContactsList cannot be instantiated directly!');
end;


constructor TContactsList.FCreate(AConnectableUserCollection: IUserCollection);
begin
  inherited Create;
  m_ConnectableUserCollection := AConnectableUserCollection;
  FBuildData;
end;


procedure TContactsList.FBuildData;
var
  i: integer;
  wstrUserName: WideString;
begin
  for i := 1 to m_ConnectableUserCollection.Count do
  begin
    wstrUserName := m_ConnectableUserCollection.Item[i].DisplayName;
    if (Trim(wstrUserName) = '') then
      wstrUserName := m_ConnectableUserCollection.Item[i].FullName;
    if (Trim(wstrUserName) = '') then
      wstrUserName := m_ConnectableUserCollection.Item[i].Handle;

    AddObject(wstrUserName, TObject(i));
  end;
end;


function TContactsList.FGetHandle(iIndex: integer): WideString;
var
  iContactIndex: integer;
begin
  iContactIndex := Integer(GetObject(iIndex));
  Result := m_ConnectableUserCollection.Item[iContactIndex].Handle;
end;


initialization

finalization
  if (Assigned(g_Skype)) then
  begin
{$IFDEF TESTING}
    g_Skype.Disconnect;
{$ENDIF}
    FreeAndNil(g_Skype);
  end;

end.
