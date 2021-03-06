////////////////////////////////////////////////////////////////////////////////
// All code below is exclusively owned by author of Chess4Net - Pavel Perminov
// (packpaul@mail.ru, packpaul1@gmail.com).
// Any changes, modifications, borrowing and adaptation are a subject for
// explicit permition from the owner.

unit SkypeAPI_Application;

interface

uses
  Classes, SysUtils,
  //
  SkypeAPI_Object, SkypeAPI_Skype, SkypeAPI_Command;

type
  TApplication = class;
  

  TApplicationStream = class(TObjectInterfacedObject, IApplicationStream)
  private
    m_wstrHandle: WideString;

    m_Application: TApplication;

    m_DatagramListener: TListener;
    m_ReceivedListener: TListener;

    m_iDataLength: integer;

    procedure FCreateListeners;
    procedure FDestroyListeners;

    function Get_PartnerHandle: WideString;

    procedure Write(const Text: WideString);
    function Read: WideString;
    procedure SendDatagram(const Text: WideString);

    function Get_DataLength: Integer;

  public
    constructor Create(AApplication: TApplication; const wstrHandle: WideString);
    destructor Destroy; override;
    property Handle: WideString read m_wstrHandle;
    property DataLength: integer read Get_DataLength write m_iDataLength;
  end;


  TApplicationStreamCollection = class(TObjectInterfaceList, IApplicationStreamCollection)
  private
    function FGetCount: integer;
    procedure Add(const Stream: IApplicationStream);
    function FGetItem(iIndex: integer): IApplicationStream;

    function IApplicationStreamCollection.Get_Count = FGetCount;
    function Get_Item(Index: Integer): IApplicationStream;
    procedure IApplicationStreamCollection.Remove = FRemove;
    procedure FRemove(iIndex: integer);
    procedure IApplicationStreamCollection.RemoveAll = Clear;

  public
    destructor Destroy; override;
    property Count: integer read FGetCount;
    property Item[iIndex: Integer]: IApplicationStream read FGetItem; default;
  end;


  EApplication = class(Exception);

  TApplication = class(TInterfacedObject, IApplication)
  private
    m_wstrName: WideString;
    m_bCreated: boolean;
    m_Streams: IApplicationStreamCollection;
    m_StreamsListener: TListener;

    function GetStreams: IApplicationStreamCollection;
    function GetConnectableUsers: IUserCollection;
    function GetConnectingUsers: IUserCollection;
    function GetName: WideString;
    function FHasStreamsForUserName(const wstrUserName: WideString): boolean;
  public
    constructor Create(const wstrName: WideString);
    destructor Destroy; override;

    procedure Delete;
    procedure IApplication.Create = _Create;
    procedure _Create;
    procedure Connect(const Username: WideString; WaitConnected: Boolean);
    procedure SendDatagram(const Text: WideString; const pStreams: IApplicationStreamCollection);

    property Streams: IApplicationStreamCollection read m_Streams;
    property ConnectableUsers: IUserCollection read GetConnectableUsers;
    property ConnectingUsers: IUserCollection read GetConnectingUsers;
    property Name: WideString read GetName;
  end;

implementation

uses
  Forms,
  //
  SkypeAPI_User;

type
  TAppCommand = class(TCommand)
  private
    m_Application: TApplication;
  protected
    property Application: TApplication read m_Application;
  public
    constructor Create(AApplication: TApplication);
  end;


  TAppCreateCommand = class(TAppCommand)
  protected
    function RGetCommand: WideString; override;
    function RProcessResponse(const wstrCommand: WideString): boolean; override;
  end;


  TAppDeleteCommand = class(TAppCommand)
  protected
    function RGetCommand: WideString; override;
    function RProcessResponse(const wstrCommand: WideString): boolean; override;
  end;


  TAppConnectableUsersCommand = class(TAppCommand)
  private
    m_Users: IUserCollection;
    procedure FBuildUserCollection(wstrUserHandles: WideString);
  protected
    function RGetCommand: WideString; override;
    function RProcessResponse(const wstrCommand: WideString): boolean; override;
  public
    procedure GetUsers(out Users: IUserCollection);
  end;


  TAppConnectCommand = class(TAppCommand)
  private
    m_wstrUserName: WideString;
  protected
    function RGetCommand: WideString; override;
    function RProcessResponse(const wstrCommand: WideString): boolean; override;
  public
    constructor Create(AApplication: TApplication; const wstrUserName: WideString);
  end;


  TAppConnectingUsersCommand = class(TAppCommand)
  private
    m_Users: IUserCollection;
    procedure FBuildUserCollection(wstrUserHandles: WideString);
  protected
    function RGetCommand: WideString; override;
    function RProcessResponse(const wstrCommand: WideString): boolean; override;
  public
    procedure GetUsers(out Users: IUserCollection);
  end;


  TAppConnectingListener = class(TListener)
  private
    m_State: (sConnectionEstablishing, sConnectionEstablished);

    m_wstrUserName: WideString;
    m_Application: TApplication;

    function FConnectionEstablishingParseCommand(const wstrCommand: WideString): boolean;
    function FConnectionEstablishedParseCommand(const wstrCommand: WideString): boolean;

  protected
    constructor RCreate; override;
    function RParseCommand(const wstrCommand: WideString): boolean; override;
    function RProcessCommand(const wstrCommand: WideString): boolean; override;

  public
    property UserName: WideString read m_wstrUserName write m_wstrUserName;
    property Application: TApplication read m_Application write m_Application;
  end;


  TAppStreamsListener = class(TListener)
  private
    m_wstrParsedStreamHandles: WideString;
    m_Application: TApplication;
  protected
    function RParseCommand(const wstrCommand: WideString): boolean; override;
    function RProcessCommand(const wstrCommand: WideString): boolean; override;
    procedure RDoNotify; override;
  public
    property Application: TApplication read m_Application write m_Application;
  end;


  TAppStreamCommand = class(TAppCommand)
  private
    m_Stream: TApplicationStream;
  protected
    property Stream: TApplicationStream read m_Stream;
  public
    constructor Create(AApplication: TApplication; AStream: TApplicationStream);
  end;


  TAppStreamWriteCommand = class(TAppStreamCommand)
  private
    m_wstrText: WideString;
  protected
    function RGetCommand: WideString; override;
    function RProcessResponse(const wstrCommand: WideString): boolean; override;
  public
    constructor Create(AApplication: TApplication;
      AStream: TApplicationStream; const wstrText: WideString);
  end;


  TAppStreamReadCommand = class(TAppStreamCommand)
  private
    m_wstrData: WideString;
  protected
    function RGetCommand: WideString; override;
    function RProcessResponse(const wstrCommand: WideString): boolean; override;
  public
    property Data: WideString read m_wstrData;  
  end;


  TAppStreamSendDatagramCommand = class(TAppStreamCommand)
  private
    m_wstrText: WideString;
  protected
    function RGetCommand: WideString; override;
    function RProcessResponse(const wstrCommand: WideString): boolean; override;
  public
    constructor Create(AApplication: TApplication;
      AStream: TApplicationStream; const wstrText: WideString);
  end;


  TAppStreamListener = class(TListener)
  private
    m_Application: TApplication;
    m_Stream: TApplicationStream;
  public
    property Application: TApplication read m_Application write m_Application;
    property Stream: TApplicationStream read m_Stream write m_Stream;
  end;


  TAppStreamReceivedListener = class(TAppStreamListener)
  private
    m_wstrParsedPacketSize: WideString;
  protected
    function RParseCommand(const wstrCommand: WideString): boolean; override;
    function RProcessCommand(const wstrCommand: WideString): boolean; override;
    procedure RDoNotify; override;
  end;


  TAppStreamDatagramListener = class(TAppStreamListener)
  private
    m_wstrParsedText: WideString;
    m_wstrText: WideString;
  protected
    function RParseCommand(const wstrCommand: WideString): boolean; override;
    function RProcessCommand(const wstrCommand: WideString): boolean; override;
    procedure RDoNotify; override;
  end;

const
  CMD_APPLICATION: WideString = 'APPLICATION';
  CMD_CREATE_APPLIATION: WideString = 'CREATE APPLICATION';
  CMD_DELETE_APPLIATION: WideString = 'DELETE APPLICATION';
  CMD_GET_APPLICATION: WideString = 'GET APPLICATION';
  CMD_ALTER_APPLICATION: WideString = 'ALTER APPLICATION';
  CMD_CONNECTABLE: WideString = 'CONNECTABLE';
  CMD_CONNECTING: WideString = 'CONNECTING';
  CMD_CONNECT: WideString = 'CONNECT';
  CMD_STREAMS: WideString = 'STREAMS';
  CMD_WRITE: WideString = 'WRITE';
  CMD_READ: WideString = 'READ';  
  CMD_RECEIVED: WideString = 'RECEIVED';
  CMD_DATAGRAM: WideString = 'DATAGRAM';

////////////////////////////////////////////////////////////////////////////////
// TApplication

constructor TApplication.Create(const wstrName: WideString);
begin
  inherited Create;
  m_wstrName := wstrName;
  m_Streams := TApplicationStreamCollection.Create;
end;


destructor TApplication.Destroy;
begin
  TSkype.Instance.ListenersManager.DestroyListener(m_StreamsListener);
  m_Streams := nil;
  inherited;
end;


procedure TApplication._Create;
var
  Command: TAppCreateCommand;
begin
  if (m_bCreated) then
    exit;

  Command := TAppCreateCommand.Create(self);
  try
    if (TSkype.Instance.SendCommand(Command)) then
    begin
      m_bCreated := TRUE;
      m_StreamsListener := TSkype.Instance.ListenersManager.CreateListener(
        TAppStreamsListener);
      (m_StreamsListener as TAppStreamsListener).Application := self;
    end;
  finally
    Command.Free;
  end;
end;


procedure TApplication.Delete;
var
  Command: TAppDeleteCommand;
begin
  if (not m_bCreated) then
    exit;

  Command := TAppDeleteCommand.Create(self);
  try
    if (TSkype.Instance.SendCommand(Command)) then
    begin
      m_bCreated := FALSE;
      TSkype.Instance.ListenersManager.DestroyListener(m_StreamsListener);
    end;
  finally
    Command.Free;
  end;
end;


procedure TApplication.Connect(const Username: WideString; WaitConnected: Boolean);
const
  WAIT_CONNECTED_TIMEOUT = 10000;
var
  strUserName: string;
  Command: TAppConnectCommand;
//  Listener: TAppConnectingListener;
  iTimeOutTimer: integer;
begin
  if (not m_bCreated) then
    exit;

  strUserName := LowerCase(Trim(UserName));
  if (strUserName = '') then
    exit;

  Command := TAppConnectCommand.Create(self, strUserName);
  try
    if (not TSkype.Instance.SendCommand(Command)) then
      exit;
  finally
    Command.Free;
  end;
{
  Listener := TSkype.Instance.ListenersManager.CreateListener(
    TAppConnectingListener) as TAppConnectingListener;
  Listener.UserName := strUserName;
  Listener.Application := self;
}
  if (not WaitConnected) then
    exit;

  iTimeOutTimer := WAIT_CONNECTED_TIMEOUT;

  while (not FHasStreamsForUserName(strUserName)) do
  begin
    if (iTimeOutTimer <= 0) then
    begin
      TSkype.Instance.Log('TApplication.Connect(): timeout occured!');
      exit;
    end;

    Forms.Application.ProcessMessages;
    Sleep(1);

    dec(iTimeOutTimer);
  end;
end;


function TApplication.FHasStreamsForUserName(const wstrUserName: WideString): boolean;
var
  wstrStreamHandlePrefix: WideString;
  Streams: TApplicationStreamCollection;
  Stream: TApplicationStream;
  i: integer;
begin
  Result := FALSE;

  wstrStreamHandlePrefix := wstrUserName + ':';

  Streams := m_Streams._Object as TApplicationStreamCollection;
  for i := 0 to Streams.Count - 1 do
  begin
    Stream := Streams[i]._Object as TApplicationStream;
    Result := (Pos(wstrStreamHandlePrefix, Stream.Handle) = 1);
    if (Result) then
      exit;
  end;
end;


procedure TApplication.SendDatagram(const Text: WideString; const pStreams: IApplicationStreamCollection);
var
  i: integer;
begin
  for i := 1 to pStreams.Count do
    pStreams[i].SendDatagram(Text);
end;


function TApplication.GetStreams: IApplicationStreamCollection;
begin
  Result := m_Streams;
end;


function TApplication.GetConnectableUsers: IUserCollection;
var
  Command: TAppConnectableUsersCommand;
begin
  Result := nil;

  Command := TAppConnectableUsersCommand.Create(self);
  try
    if (TSkype.Instance.SendCommand(Command)) then
      Command.GetUsers(Result)
    else
      Result := TUserCollection.Create; // Empty collection 
  finally
    Command.Free;
  end;
end;


function TApplication.GetConnectingUsers: IUserCollection;
var
  Command: TAppConnectingUsersCommand;
begin
  Result := nil;

  Command := TAppConnectingUsersCommand.Create(self);
  try
    if (TSkype.Instance.SendCommand(Command)) then
      Command.GetUsers(Result)
    else
      Result := TUserCollection.Create; // Empty collection
  finally
    Command.Free;
  end;
end;


function TApplication.GetName: WideString;
begin
  Result := m_wstrName;
end;


////////////////////////////////////////////////////////////////////////////////

// TAppCommand


constructor TAppCommand.Create(AApplication: TApplication);

begin

  inherited Create;

  m_Application := AApplication;

end;


////////////////////////////////////////////////////////////////////////////////

// TAppCreateCommand


function TAppCreateCommand.RGetCommand: WideString;

begin

  Result := CMD_CREATE_APPLIATION + ' ' + Application.Name;

end;



function TAppCreateCommand.RProcessResponse(const wstrCommand: WideString): boolean;
begin

  Assert(not HasResponse);

  

  Result := SameText(Command, wstrCommand);

{

  Other responses:

  ERROR 536 CREATE: no object or type given

  ERROR 537 CREATE: Unknown object type given
  ERROR 540 CREATE APPLICATION: Missing or invalid name
  ERROR 541 APPLICATION: operation failed - in case an application with this name already exists
}

end;


////////////////////////////////////////////////////////////////////////////////

// TAppDeleteCommand


function TAppDeleteCommand.RGetCommand: WideString;

begin

  Result := CMD_DELETE_APPLIATION + ' ' + Application.Name;

end;



function TAppDeleteCommand.RProcessResponse(const wstrCommand: WideString): boolean;
begin
  Assert(not HasResponse);

  Result := SameText(Command, wstrCommand);
{

  Other responses:
  ERROR 538 DELETE: no object or type given
  ERROR 539 DELETE: Unknown object type given
  ERROR 542 DELETE APPLICATION : missing or invalid application name
  ERROR 541 APPLICATION: operation failed
}
end;


////////////////////////////////////////////////////////////////////////////////

// TAppConnectableUsersCommand


function TAppConnectableUsersCommand.RGetCommand: WideString;

begin

  Result := CMD_GET_APPLICATION + ' ' + Application.Name + ' ' + CMD_CONNECTABLE;

end;



function TAppConnectableUsersCommand.RProcessResponse(const wstrCommand: WideString): boolean;
var
  wstrHead, wstrBody: WideString;
  wstrAppName: WideString;
begin
  Assert(not HasResponse);

  Result := FALSE;

  RSplitCommandToHeadAndBody(wstrCommand, wstrHead, wstrBody);
  if (wstrHead <> CMD_APPLICATION) then
    exit;

  wstrAppName := RNextToken(wstrBody, wstrBody);
  if (wstrAppName <> Application.Name) then
    exit;

  RSplitCommandToHeadAndBody(wstrBody, wstrHead, wstrBody);
  if (wstrHead <> CMD_CONNECTABLE) then
    exit;

  FBuildUserCollection(wstrBody);

  Result := TRUE;
end;


procedure TAppConnectableUsersCommand.FBuildUserCollection(wstrUserHandles: WideString);
var
  wstrHandle: WideString;
  User: IUser;
  Users: TUserCollection;
begin
  Assert(not Assigned(m_Users));

  Users := TUserCollection.Create;

  wstrHandle := RNextToken(wstrUserHandles, wstrUserHandles);
  while (wstrHandle <> '') do
  begin
    User := TSkype.Instance.GetUserByHandle(wstrHandle);
    if (Assigned(User)) then
      Users.Add(User);
    wstrHandle := RNextToken(wstrUserHandles, wstrUserHandles);
  end;

  m_Users := Users;
end;


procedure TAppConnectableUsersCommand.GetUsers(out Users: IUserCollection);
begin
  Users := m_Users;
  m_Users := nil;
end;

////////////////////////////////////////////////////////////////////////////////
// TAppConnectingUsersCommand

function TAppConnectingUsersCommand.RGetCommand: WideString;
begin

  Result := CMD_GET_APPLICATION + ' ' + Application.Name + ' ' + CMD_CONNECTING;

end;



function TAppConnectingUsersCommand.RProcessResponse(const wstrCommand: WideString): boolean;
var
  wstrHead, wstrBody: WideString;
  wstrAppName: WideString;
begin
  Assert(not HasResponse);

  Result := FALSE;

  RSplitCommandToHeadAndBody(wstrCommand, wstrHead, wstrBody);
  if (wstrHead <> CMD_APPLICATION) then
    exit;

  wstrAppName := RNextToken(wstrBody, wstrBody);
  if (wstrAppName <> Application.Name) then
    exit;

  RSplitCommandToHeadAndBody(wstrBody, wstrHead, wstrBody);
  if (wstrHead <> CMD_CONNECTING) then
    exit;

  FBuildUserCollection(wstrBody);

  Result := TRUE;
end;


procedure TAppConnectingUsersCommand.FBuildUserCollection(wstrUserHandles: WideString);
var
  wstrHandle: WideString;
  User: IUser;
  Users: TUserCollection;
begin
  Assert(not Assigned(m_Users));

  Users := TUserCollection.Create;

  wstrHandle := RNextToken(wstrUserHandles, wstrUserHandles);
  while (wstrHandle <> '') do
  begin
    User := TSkype.Instance.GetUserByHandle(wstrHandle);
    if (Assigned(User)) then
      Users.Add(User);
    wstrHandle := RNextToken(wstrUserHandles, wstrUserHandles);
  end;

  m_Users := Users;
end;


procedure TAppConnectingUsersCommand.GetUsers(out Users: IUserCollection);
begin
  Users := m_Users;
  m_Users := nil;
end;

////////////////////////////////////////////////////////////////////////////////
// TAppConnectCommand

constructor TAppConnectCommand.Create(AApplication: TApplication; const wstrUserName: WideString);
begin
  inherited Create(AApplication);
  m_wstrUserName := wstrUserName;
end;


function TAppConnectCommand.RGetCommand: WideString;
begin
  Result := CMD_ALTER_APPLICATION + ' ' + m_Application.Name + ' ' +
    CMD_CONNECT + ' ' + m_wstrUserName;
end;


function TAppConnectCommand.RProcessResponse(const wstrCommand: WideString): boolean;
var
  wstrHead, wstrBody: WideString;
  wstrAppName, wstrUserName: WideString;
begin
  Assert(not HasResponse);

  Result := FALSE;

  RSplitCommandToHeadAndBody(wstrCommand, wstrHead, wstrBody, 2);
  if (wstrHead <> CMD_ALTER_APPLICATION) then
    exit;

  wstrAppName := RNextToken(wstrBody, wstrBody);
  if (wstrAppName <> Application.Name) then
    exit;

  RSplitCommandToHeadAndBody(wstrBody, wstrHead, wstrBody);
  if (wstrHead <> CMD_CONNECT) then
    exit;

  wstrUserName := RNextToken(wstrBody, wstrBody);
  if (wstrUserName <> m_wstrUserName) then
    exit;

  Result := TRUE;
end;

////////////////////////////////////////////////////////////////////////////////
// TAppConnectingListener

constructor TAppConnectingListener.RCreate;
begin
  inherited RCreate;
  m_State := sConnectionEstablishing;  
end;

function TAppConnectingListener.RParseCommand(const wstrCommand: WideString): boolean;
begin
  Result := FALSE;

  case m_State of
    sConnectionEstablishing, sConnectionEstablished:
    begin
      Result := FConnectionEstablishingParseCommand(wstrCommand);
      Result := (Result or FConnectionEstablishedParseCommand(wstrCommand));
    end;
  end;
end;


function TAppConnectingListener.FConnectionEstablishingParseCommand(
  const wstrCommand: WideString): boolean;
var
  wstrHead, wstrBody: WideString;
  wstrAppName, wstrUserName: WideString;
begin
  Result := FALSE;

  RSplitCommandToHeadAndBody(wstrCommand, wstrHead, wstrBody);
  if (wstrHead <> CMD_APPLICATION) then
    exit;

  wstrAppName := RNextToken(wstrBody, wstrBody);
  if (wstrAppName <> Application.Name) then
    exit;

  RSplitCommandToHeadAndBody(wstrBody, wstrHead, wstrBody);
  if (wstrHead <> CMD_CONNECTING) then
    exit;

  wstrUserName := RNextToken(wstrBody, wstrBody);
  if (wstrUserName <> m_wstrUserName) then
    exit;

  Result := TRUE;
end;


function TAppConnectingListener.FConnectionEstablishedParseCommand(
  const wstrCommand: WideString): boolean;
var
  wstrHead, wstrBody: WideString;
  wstrAppName: WideString;
begin
  Result := FALSE;

  RSplitCommandToHeadAndBody(wstrCommand, wstrHead, wstrBody);
  if (wstrHead <> CMD_APPLICATION) then
    exit;

  wstrAppName := RNextToken(wstrBody, wstrBody);
  if (wstrAppName <> Application.Name) then
    exit;

  RSplitCommandToHeadAndBody(wstrBody, wstrHead, wstrBody);
  if (wstrHead <> CMD_CONNECTING) then
    exit;

  if (RNextToken(wstrBody, wstrBody) <> '') then
    exit;

  Result := TRUE;
end;


function TAppConnectingListener.RProcessCommand(const wstrCommand: WideString): boolean;
var
  DummyListener: TListener;
begin
  Result := FALSE;

  case m_State of
    sConnectionEstablishing, sConnectionEstablished:
    begin
      Result := FConnectionEstablishingParseCommand(wstrCommand);
      if (Result) then
      begin
        m_State := sConnectionEstablished;
        exit;
      end;

      Result := FConnectionEstablishedParseCommand(wstrCommand);
      if (Result) then
      begin
        DummyListener := self;
        TSkype.Instance.ListenersManager.DestroyListener(DummyListener);
      end;
    end;
  end;

end;

////////////////////////////////////////////////////////////////////////////////
// TApplicationStream

constructor TApplicationStream.Create(AApplication: TApplication;
  const wstrHandle: WideString);
begin
  inherited Create;
  m_Application := AApplication;
  m_wstrHandle := wstrHandle;
  FCreateListeners;
end;


destructor TApplicationStream.Destroy;
begin
  FDestroyListeners;
  inherited;
end;


procedure TApplicationStream.FCreateListeners;
begin
  m_DatagramListener := TSkype.Instance.ListenersManager.CreateListener(
    TAppStreamDatagramListener);
  with (m_DatagramListener as TAppStreamDatagramListener) do
  begin
    Application := self.m_Application;
    Stream := self;
  end;

  m_ReceivedListener := TSkype.Instance.ListenersManager.CreateListener(
    TAppStreamReceivedListener);
  with (m_ReceivedListener as TAppStreamReceivedListener) do
  begin
    Application := self.m_Application;
    Stream := self;
  end;

end;


procedure TApplicationStream.FDestroyListeners;
begin
  TSkype.Instance.ListenersManager.DestroyListener(m_ReceivedListener);
  TSkype.Instance.ListenersManager.DestroyListener(m_DatagramListener);
end;


function TApplicationStream.Get_PartnerHandle: WideString;
var
  iPos: integer;
begin
  iPos := LastDelimiter(':', m_wstrHandle);
  Assert(iPos > 1);
  Result :=  Copy(m_wstrHandle, 1, iPos - 1);
end;


function TApplicationStream.Read: WideString;
var
  Command: TAppStreamReadCommand;
begin
  Result := '';

  Command := TAppStreamReadCommand.Create(m_Application, self);
  try
    if (TSkype.Instance.SendCommand(Command)) then
    begin
      Result := Command.Data;
    end;

  finally
    Command.Free;
  end;

end;


procedure TApplicationStream.Write(const Text: WideString);
var
  Command: TAppStreamWriteCommand;
begin
  Command := TAppStreamWriteCommand.Create(m_Application, self, Text);
  try
    if (TSkype.Instance.SendCommand(Command)) then
    begin
      // Skype will returns in turn:
      // "APPLICATION <app. name> SENDING <stream handle> <message length + 2>" - message has been queued for sending
      // "APPLICATION <app. name> SENDING" - the message has been sent
      // Use a listener for additional notification for the client
    end;

  finally
    Command.Free;
  end;

end;


procedure TApplicationStream.SendDatagram(const Text: WideString);
var
  Command: TAppStreamSendDatagramCommand;
begin
  Command := TAppStreamSendDatagramCommand.Create(m_Application, self, Text);
  try
    if (TSkype.Instance.SendCommand(Command)) then
    begin
      // Skype will returns in turn:
      // "APPLICATION <app. name> SENDING <stream handle>=<data size>" - when data is transmited
      // "APPLICATION <app. name> SENDING" - when data is sent
      // Use a listener for additional notification for the client
    end;

  finally
    Command.Free;
  end;

end;


function TApplicationStream.Get_DataLength: Integer;
begin
  Result := m_iDataLength;
end;

////////////////////////////////////////////////////////////////////////////////
// TApplicationStreamCollection

destructor TApplicationStreamCollection.Destroy;
begin
  inherited;
end;


function TApplicationStreamCollection.FGetCount: Integer;
begin
  Result := inherited Count;
end;


procedure TApplicationStreamCollection.Add(const Stream: IApplicationStream);
begin
  inherited Add(Stream);
end;


function TApplicationStreamCollection.FGetItem(iIndex: Integer): IApplicationStream;
begin
  Result := IApplicationStream(inherited Items[iIndex]);
end;


function TApplicationStreamCollection.Get_Item(Index: Integer): IApplicationStream;
begin
  Result := FGetItem(Index - 1);
end;


procedure TApplicationStreamCollection.FRemove(iIndex: integer);
begin
  Delete(iIndex - 1);
end;

////////////////////////////////////////////////////////////////////////////////
// TAppStreamCommand

constructor TAppStreamCommand.Create(AApplication: TApplication;
  AStream: TApplicationStream);
begin
  inherited Create(AApplication);
  m_Stream := AStream;
end;

////////////////////////////////////////////////////////////////////////////////
// TAppStreamSendDatagramCommand

constructor TAppStreamSendDatagramCommand.Create(AApplication: TApplication;
  AStream: TApplicationStream; const wstrText: WideString);
begin
  inherited Create(AApplication, AStream);
  m_wstrText := wstrText;
end;


function TAppStreamSendDatagramCommand.RGetCommand: WideString;
begin
  Result := CMD_ALTER_APPLICATION + ' ' + Application.Name + ' ' + CMD_DATAGRAM + ' ' +
    Stream.Handle + ' ' + m_wstrText;
end;


function TAppStreamSendDatagramCommand.RProcessResponse(const wstrCommand: WideString): boolean;
var
  wstrHead, wstrBody: WideString;
  wstrAppName, wstrStreamHandle: WideString;
begin
  Assert(not HasResponse);

  Result := FALSE;

  RSplitCommandToHeadAndBody(wstrCommand, wstrHead, wstrBody, 2);
  if (wstrHead <> CMD_ALTER_APPLICATION) then
    exit;

  wstrAppName := RNextToken(wstrBody, wstrBody);
  if (wstrAppName <> Application.Name) then
    exit;

  RSplitCommandToHeadAndBody(wstrBody, wstrHead, wstrBody);
  if (wstrHead <> CMD_DATAGRAM) then
    exit;

  wstrStreamHandle := RNextToken(wstrBody, wstrBody);
  if (wstrStreamHandle <> Stream.Handle) then
    exit;

  Result := TRUE;
end;

////////////////////////////////////////////////////////////////////////////////
// TAppStreamWriteCommand

constructor TAppStreamWriteCommand.Create(AApplication: TApplication;
  AStream: TApplicationStream; const wstrText: WideString);
begin
  inherited Create(AApplication, AStream);
  m_wstrText := wstrText;
end;


function TAppStreamWriteCommand.RGetCommand: WideString;
begin
  Result := CMD_ALTER_APPLICATION + ' ' + Application.Name + ' ' + CMD_WRITE + ' ' +
    Stream.Handle + ' ' + m_wstrText;
end;


function TAppStreamWriteCommand.RProcessResponse(const wstrCommand: WideString): boolean;
var
  wstrHead, wstrBody: WideString;
  wstrAppName, wstrStreamHandle: WideString;
begin
  Assert(not HasResponse);

  Result := FALSE;

  RSplitCommandToHeadAndBody(wstrCommand, wstrHead, wstrBody, 2);
  if (wstrHead <> CMD_ALTER_APPLICATION) then
    exit;

  wstrAppName := RNextToken(wstrBody, wstrBody);
  if (wstrAppName <> Application.Name) then
    exit;

  RSplitCommandToHeadAndBody(wstrBody, wstrHead, wstrBody);
  if (wstrHead <> CMD_WRITE) then
    exit;

  wstrStreamHandle := RNextToken(wstrBody, wstrBody);
  if (wstrStreamHandle <> Stream.Handle) then
    exit;

  Result := TRUE;
end;


////////////////////////////////////////////////////////////////////////////////
// TAppStreamReadCommand

function TAppStreamReadCommand.RGetCommand: WideString;
begin
  Result := CMD_ALTER_APPLICATION + ' ' + Application.Name + ' ' + CMD_READ + ' ' +
    Stream.Handle;
end;


function TAppStreamReadCommand.RProcessResponse(const wstrCommand: WideString): boolean;
var
  wstrHead, wstrBody: WideString;
  wstrAppName, wstrStreamHandle: WideString;
begin
  Assert(not HasResponse);

  Result := FALSE;

  RSplitCommandToHeadAndBody(wstrCommand, wstrHead, wstrBody, 2);
  if (wstrHead <> CMD_ALTER_APPLICATION) then
    exit;

  wstrAppName := RNextToken(wstrBody, wstrBody);
  if (wstrAppName <> Application.Name) then
    exit;

  RSplitCommandToHeadAndBody(wstrBody, wstrHead, wstrBody);
  if (wstrHead <> CMD_READ) then
    exit;

  wstrStreamHandle := RNextToken(wstrBody, wstrBody);
  if (wstrStreamHandle <> Stream.Handle) then
    exit;

  m_wstrData := wstrBody;

  Result := TRUE;
end;

////////////////////////////////////////////////////////////////////////////////
// TAppStreamDatagramListener

function TAppStreamDatagramListener.RParseCommand(const wstrCommand: WideString): boolean;
var
  wstrHead, wstrBody: WideString;
  wstrAppName, wstrStreamHandle: WideString;
begin
  Result := FALSE;

  RSplitCommandToHeadAndBody(wstrCommand, wstrHead, wstrBody);
  if (wstrHead <> CMD_APPLICATION) then
    exit;

  wstrAppName := RNextToken(wstrBody, wstrBody);
  if (wstrAppName <> Application.Name) then
    exit;

  RSplitCommandToHeadAndBody(wstrBody, wstrHead, wstrBody);
  if (wstrHead <> CMD_DATAGRAM) then
    exit;

  wstrStreamHandle := RNextToken(wstrBody, wstrBody);
  if (wstrStreamHandle <> Stream.Handle) then
    exit;

  m_wstrParsedText := wstrBody;

  Result := TRUE;
end;


function TAppStreamDatagramListener.RProcessCommand(const wstrCommand: WideString): boolean;
begin
  Result := RParseCommand(wstrCommand);

  if (not Result) then
    exit;

  m_wstrText := m_wstrParsedText;
end;


procedure TAppStreamDatagramListener.RDoNotify;
begin
  TSkype.Instance.DoApplicationDatagram(Application, Stream, m_wstrText);
end;

////////////////////////////////////////////////////////////////////////////////
// TAppStreamReceivedListener

function TAppStreamReceivedListener.RParseCommand(const wstrCommand: WideString): boolean;
var
  wstrHead, wstrBody: WideString;
  wstrAppName, wstrStreamHandle: WideString;
begin
  Result := FALSE;

  RSplitCommandToHeadAndBody(wstrCommand, wstrHead, wstrBody);
  if (wstrHead <> CMD_APPLICATION) then
    exit;

  wstrAppName := RNextToken(wstrBody, wstrBody);
  if (wstrAppName <> Application.Name) then
    exit;

  RSplitCommandToHeadAndBody(wstrBody, wstrHead, wstrBody);
  if (wstrHead <> CMD_RECEIVED) then
    exit;

  wstrStreamHandle := RNextToken(wstrBody, wstrBody, '=');
  if (wstrStreamHandle <> Stream.Handle) then
    exit;

  m_wstrParsedPacketSize := wstrBody;

  Result := TRUE;
end;


function TAppStreamReceivedListener.RProcessCommand(const wstrCommand: WideString): boolean;
var
  iDataLength: integer;
begin
  Result := RParseCommand(wstrCommand);

  if (not Result) then
    exit;

  iDataLength := StrToIntDef(m_wstrParsedPacketSize, 0);
  Stream.DataLength := iDataLength;
end;


procedure TAppStreamReceivedListener.RDoNotify;
var
  Streams: IApplicationStreamCollection;
begin
  Streams := TApplicationStreamCollection.Create;
  Streams.Add(Stream);
  TSkype.Instance.DoApplicationReceiving(Application, Streams);
end;

////////////////////////////////////////////////////////////////////////////////
// TAppStreamsListener

function TAppStreamsListener.RParseCommand(const wstrCommand: WideString): boolean;
var
  wstrHead, wstrBody: WideString;
  wstrAppName: WideString;
begin
  Result := FALSE;

  RSplitCommandToHeadAndBody(wstrCommand, wstrHead, wstrBody);
  if (wstrHead <> CMD_APPLICATION) then
    exit;

  wstrAppName := RNextToken(wstrBody, wstrBody);
  if (wstrAppName <> Application.Name) then
    exit;

  RSplitCommandToHeadAndBody(wstrBody, wstrHead, wstrBody);
  if (wstrHead <> CMD_STREAMS) then
    exit;

  m_wstrParsedStreamHandles := wstrBody;

  Result := TRUE;
end;


function TAppStreamsListener.RProcessCommand(const wstrCommand: WideString): boolean;
var
  wstr: WideString;
  strHandle: string;
  Streams: TApplicationStreamCollection;
  i: integer;
  Stream: TApplicationStream;
  iIndex: integer;
begin
  Result := RParseCommand(wstrCommand);
  if (not Result) then
    exit; 

  with TStringList.Create do
  try
    strHandle := RNextToken(m_wstrParsedStreamHandles, wstr);
    while (strHandle <> '') do
    begin
      Add(strHandle);
      strHandle := RNextToken(wstr, wstr);
    end;

    Streams := m_Application.Streams._Object as TApplicationStreamCollection;

    for i := Streams.Count - 1 downto 0 do
    begin
      Stream := Streams[i]._Object as TApplicationStream;
      if (Find(Stream.Handle, iIndex)) then
        Delete(iIndex)
      else
        Streams.Delete(i);      
    end;

    for i := 0 to Count - 1 do
    begin
      strHandle := Strings[i];
      Streams.Add(TApplicationStream.Create(m_Application, strHandle));
    end;

  finally
    Free;
  end;
end;


procedure TAppStreamsListener.RDoNotify;
begin
  TSkype.Instance.DoApplicationStreams(m_Application, m_Application.Streams);
end;

end.
