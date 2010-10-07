unit SkypeAPI_Skype;

interface

uses
  Classes, SysUtils, ExtCtrls, Contnrs, 
  //
  skypeapi,
  //
  SkypeAPI_Command;

type
  TAttachmentStatus = (apiAttachUnknown = -1, apiAttachSuccess = 0,
    apiAttachRefused = 2, apiAttachNotAvailable = 3, apiAttachAvailable = 4);
  TChatMessageStatus = (cmsUnknown = -1, cmsSending = 0, cmsSent = 1, cmsReceived = 2);

  IUser = interface
    function GetHandle: WideString;
    function GetFullName: WideString;
    function GetDisplayName: WideString;
    property Handle: WideString read GetHandle;
    property FullName: WideString read GetFullName;
    property DisplayName: WideString read GetDisplayName;
  end;

  IUserCollection = interface
    function GetCount: Integer;
    function GetItem(iIndex: Integer): IUser;
    property Count: Integer read GetCount;
    property Item[iIndex: Integer]: IUser read GetItem; default;
  end;  

  IChatMessage = interface
    function GetSender: IUser;
    function GetBody: WideString;
    property Sender: IUser read GetSender;
    property Body: WideString read GetBody;
  end;

  IApplicationStream = interface
  end;

  IApplicationStreamCollection = interface
  end;

  IApplication = interface
    procedure Delete;
    procedure Create;
    procedure Connect(const Username: WideString; WaitConnected: Boolean);
    procedure SendDatagram(const Text: WideString; const pStreams: IApplicationStreamCollection);
    function GetStreams: IApplicationStreamCollection;
    function GetConnectableUsers: IUserCollection;
    function GetConnectingUsers: IUserCollection;
    function GetName: WideString;
    property Streams: IApplicationStreamCollection read GetStreams;
    property ConnectableUsers: IUserCollection read GetConnectableUsers;
    property ConnectingUsers: IUserCollection read GetConnectingUsers;
    property Name: WideString read GetName;
  end;

  IClient = interface
    function GetIsRunning: Boolean;
    procedure Start(Minimized: Boolean; Nosplash: Boolean);
    property IsRunning: Boolean read GetIsRunning;
  end;

  ISkype = interface
    procedure Attach(Protocol: Integer; Wait: Boolean);
    function GetApplication(const Name: WideString): IApplication;
    function SendMessage(const Username: WideString; const Text: WideString): IChatMessage;
    function GetClient: IClient;
    function GetCurrentUser: IUser;
    function GetCurrentUserHandle: WideString;
    property Application[const Name: WideString]: IApplication read GetApplication;
    property Client: IClient read GetClient;
    property CurrentUser: IUser read GetCurrentUser;
    property CurrentUserHandle: WideString read GetCurrentUserHandle;
  end;

  TOnMessageStatus = procedure(ASender: TObject; const pMessage: IChatMessage;
    Status: TChatMessageStatus) of object;
  TOnAttachmentStatus = procedure(ASender: TObject; Status: TAttachmentStatus) of object;
  TOnApplicationDatagram = procedure(ASender: TObject; const pApp: IApplication;
    const pStream: IApplicationStream; const Text: WideString) of object;

  ESkype = class(Exception);

  TSkype = class(TDataModule, ISkype)
    FinishAttachmentTimer: TTimer;
    PendingSkypeAPICommandsTimer: TTimer;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure FinishAttachmentTimerTimer(Sender: TObject);
    procedure PendingSkypeAPICommandsTimerTimer(Sender: TObject);
  private
    m_SkypeAPI: TSkypeAPI;
    m_AttachmentStatus: TAttachmentStatus;
    m_iProtocol: integer;

    m_Command: TCommand;
    m_Listeners: TObjectList;
    m_PendingSkypeAPICommands: TStringList;

    m_Applications: TInterfaceList;
    m_Users: TInterfaceList;

    m_Client: IClient;

    FOnMessageStatus: TOnMessageStatus;
    FOnAttachmentStatus: TOnAttachmentStatus;
    FOnApplicationDatagram: TOnApplicationDatagram;

    procedure FSetOnMessageStatus(Value: TOnMessageStatus);

    function GetApplication(const Name: WideString): IApplication;
    function GetClient: IClient;
    function GetCurrentUser: IUser;
    function GetCurrentUserHandle: WideString;

    procedure FOnSkypeAPIAttachementStatus(ASender: TObject; Status: skypeapi.TAttachmentStatus);
    procedure FOnSkypeAPICommandReceived(ASender: TObject; const wstrCommand: WideString);

    procedure FDoAttachmentStatus(ASender: TObject; Status: TAttachmentStatus);
    procedure FDoApplicationDatagram(ASender: TObject; const pApp: IApplication;
      const pStream: IApplicationStream; const Text: WideString);

    procedure FFinishAttachment;

    procedure FProcessPendingSkypeAPICommandsForListeners;
    procedure FProcessSkypeAPICommandForListeners(const wstrCommand: WideString);

  public
    constructor Create(const strFriendlyName: string); reintroduce;
    destructor Destroy; override;

    class function Instance: TSkype;

    procedure Attach(Protocol: Integer; Wait: Boolean);
    function SendMessage(const Username: WideString; const Text: WideString): IChatMessage;

    procedure Log(const wstrLogMsg: WideString);
    procedure SendCommand(const wstrCommand: WideString); overload;
    function SendCommand(ACommand: TCommand): boolean; overload;

    function GetUserByHandle(const wstrHandle: WideString): IUser;

    procedure DoMessageStatus(const pMessage: IChatMessage;
      Status: TChatMessageStatus);

    property Application[const Name: WideString]: IApplication read GetApplication;
    property Client: IClient read GetClient;
    property CurrentUser: IUser read GetCurrentUser;
    property CurrentUserHandle: WideString read GetCurrentUserHandle;

    property OnMessageStatus: TOnMessageStatus read FOnMessageStatus write FSetOnMessageStatus;
    property OnAttachmentStatus: TOnAttachmentStatus read FOnAttachmentStatus
                                                     write FOnAttachmentStatus;
    property OnApplicationDatagram: TOnApplicationDatagram read FOnApplicationDatagram
                                                           write FOnApplicationDatagram;
  end;

implementation

uses
  Forms,
  //
  MainFormUnit,
  //
  SkypeAPI_Client, SkypeAPI_Application, SkypeAPI_User, SkypeAPI_ChatMessage;

{$R *.dfm}

type
  TProtocolCommand = class(TCommand)
  private
    m_iRequestedProtocol: integer;
    m_iReturnedProtocol: integer;
  protected
    function RGetCommand: WideString; override;
    function RProcessResponse(const wstrCommand: WideString): boolean; override;    
  public
    constructor Create(iRequestedProtocol: integer);
    property Protocol: integer read m_iReturnedProtocol;
  end;

const
  CMD_PROTOCOL: WideString = 'PROTOCOL';

////////////////////////////////////////////////////////////////////////////////
// TSkype

var
  g_SkypeInstance: TSkype = nil;

constructor TSkype.Create(const strFriendlyName: string);
begin
  if (Assigned(g_SkypeInstance)) then
    raise ESkype.Create('TSkype instance already exists!');

  m_SkypeAPI := TSkypeAPI.Create(strFriendlyName);

  inherited Create(nil);

  g_SkypeInstance := self;
end;


destructor TSkype.Destroy;
begin
  g_SkypeInstance := nil;

  m_SkypeAPI.Free;

  inherited;
end;


class function TSkype.Instance: TSkype;
begin
  Result := g_SkypeInstance;
end;


function TSkype.GetApplication(const Name: WideString): IApplication;
var
  i: integer;
begin
  Result := nil;

  if (not Assigned(m_Applications)) then
    m_Applications := TInterfaceList.Create;

  for i := 0 to m_Applications.Count - 1 do
  begin
    Result := IApplication(m_Applications[i]);
    if (Result.Name = Name) then
      exit;
  end;

  Result := TApplication.Create(Name);
  m_Applications.Add(Result);
end;


function TSkype.SendMessage(const Username: WideString; const Text: WideString): IChatMessage;
begin
  Result := nil;
  // TODO: keep till final versions not implemented!
end;


function TSkype.GetClient: IClient;
begin
  if (not Assigned(m_Client)) then
    m_Client := TClient.Create;

  Result := m_Client;
end;


function TSkype.GetCurrentUser: IUser;
begin
  Result := nil;
  // TODO:
end;


function TSkype.GetCurrentUserHandle: WideString;
begin
  Result := '';
  // TODO:
end;


procedure TSkype.Attach(Protocol: Integer; Wait: Boolean);
begin
  if (Wait) then
    raise ESkype.Create('Waiting attach not supported!');

  m_iProtocol := Protocol;
  m_SkypeAPI.Attach;
end;


procedure TSkype.FOnSkypeAPIAttachementStatus(ASender: TObject; Status: skypeapi.TAttachmentStatus);
begin
  ASender := ASender; // To avoid warning

  m_AttachmentStatus := apiAttachAvailable;

  case Status  of
    asAttachSuccess:
    begin
      if (not FinishAttachmentTimer.Enabled) then
        FinishAttachmentTimer.Enabled := TRUE;
      exit;
    end;

    asAttachPendingAuthorization:
      Log('** Attach pending');

    asAttachRefused:
    begin
      Log('** Attach refused');
      m_AttachmentStatus := apiAttachRefused;
    end;

    asAttachNotAvailable:
    begin
      Log('** Attach unavailable');
      m_AttachmentStatus := apiAttachNotAvailable;
    end;

    asAttachAvailable:
      Log('** Attach available');
  end;

  FinishAttachmentTimer.Enabled := FALSE;

  FDoAttachmentStatus(self, m_AttachmentStatus);
end;


procedure TSkype.FOnSkypeAPICommandReceived(ASender: TObject; const wstrCommand: WideString);
begin
  Log(WideString('->') + wstrCommand);

  if (Assigned(m_Command)) then
  begin
    if (not m_Command.HasResponse) then
    begin
      m_Command.ProcessResponse(wstrCommand);
      if (m_Command.HasResponse) then
        Log('Command processed: ' + m_Command.ClassName)
      else
        m_PendingSkypeAPICommands.Add(UTF8Encode(wstrCommand));
    end;
  end
  else
  begin
    FProcessPendingSkypeAPICommandsForListeners;
    FProcessSkypeAPICommandForListeners(wstrCommand);
  end;
end;


procedure TSkype.FProcessPendingSkypeAPICommandsForListeners;
var
  wstrCommand: WideString;
begin
  while (m_PendingSkypeAPICommands.Count > 0) do
  begin
    wstrCommand := UTF8Decode(m_PendingSkypeAPICommands[0]);
    m_PendingSkypeAPICommands.Delete(0);
    FProcessSkypeAPICommandForListeners(wstrCommand);
  end;
end;


procedure TSkype.FProcessSkypeAPICommandForListeners(const wstrCommand: WideString);
var
  i: integer;
  Listener: TListener;
begin
  for i := 0 to m_Listeners.Count - 1 do
  begin
    Listener := m_Listeners[i] as TListener;
    if (Listener.ProcessCommand(wstrCommand)) then
      Log('Command processed: ' + Listener.ClassName);
  end;
end;


procedure TSkype.SendCommand(const wstrCommand: WideString);
begin
  Log(WideString('<-') + wstrCommand);
  m_SkypeAPI.SendCommand(wstrCommand);
end;


function TSkype.SendCommand(ACommand: TCommand): boolean;
const
  COMMAND_TIMEOUT = 5000;
var
  iTimeOutTimer: integer;
begin
  Result := FALSE;

  if (Assigned(m_Command)) then
    exit;

  m_Command := ACommand;
  try
    Log('Processing command: ' + m_Command.ClassName);
    SendCommand(m_Command.Command);

    iTimeOutTimer := COMMAND_TIMEOUT;

    while ((not ACommand.HasResponse)) do
    begin
      if ((iTimeOutTimer <= 0) or (csDestroying in ComponentState)) then
        exit;
        
      Forms.Application.ProcessMessages;
      if (ACommand.HasResponse) then
        break;
        
      Sleep(1);

      dec(iTimeOutTimer);
    end;

  finally
    m_Command := nil;
  end;

  PendingSkypeAPICommandsTimer.Enabled := TRUE;

  Result := TRUE;
end;


procedure TSkype.PendingSkypeAPICommandsTimerTimer(Sender: TObject);
begin
  PendingSkypeAPICommandsTimer.Enabled := FALSE;
  if (Assigned(m_Command)) then
    exit;
  FProcessPendingSkypeAPICommandsForListeners;
end;


procedure TSkype.Log(const wstrLogMsg: WideString);
begin
  MainForm.Log(wstrLogMsg); 
  // TODO: Output to log
end;


procedure TSkype.DoMessageStatus(const pMessage: IChatMessage;
  Status: TChatMessageStatus);
begin
  if (Assigned(FOnMessageStatus)) then
    FOnMessageStatus(self, pMessage, Status);
end;


procedure TSkype.FDoAttachmentStatus(ASender: TObject; Status: TAttachmentStatus);
begin
  if (Assigned(FOnAttachmentStatus)) then
    FOnAttachmentStatus(ASender, Status);
end;


procedure TSkype.FDoApplicationDatagram(ASender: TObject; const pApp: IApplication;
  const pStream: IApplicationStream; const Text: WideString);
begin
  if (Assigned(FOnApplicationDatagram)) then
    FOnApplicationDatagram(ASender, pApp, pStream, Text);
end;

procedure TSkype.DataModuleCreate(Sender: TObject);
begin
  m_AttachmentStatus := apiAttachUnknown;
  m_Listeners := TObjectList.Create;
  m_PendingSkypeAPICommands := TStringList.Create;

  m_SkypeAPI.OnAttachmentStatus := FOnSkypeAPIAttachementStatus;
  m_SkypeAPI.OnCommandReceived := FOnSkypeAPICommandReceived;
end;

procedure TSkype.DataModuleDestroy(Sender: TObject);
begin
  while (Assigned(m_Command)) do
    Sleep(1); // Wait until all blocking commands are accomplished
  m_PendingSkypeAPICommands.Free;
  m_Listeners.Free;
  m_Applications.Free;
  m_Users.Free;
end;


procedure TSkype.FinishAttachmentTimerTimer(Sender: TObject);
begin
  FinishAttachmentTimer.Enabled := FALSE;
  FFinishAttachment;
end;


procedure TSkype.FFinishAttachment;
var
  Command: TProtocolCommand;
begin
  Command := TProtocolCommand.Create(999);
  try
    m_AttachmentStatus := apiAttachNotAvailable;
    if (not SendCommand(Command)) then
      exit;
    if (Command.Protocol >= m_iProtocol) then
    begin
      m_AttachmentStatus := apiAttachSuccess;
      Log('** Attach success');
    end;
    FDoAttachmentStatus(self, m_AttachmentStatus);    
  finally
    Command.Free;
  end;
end;


function TSkype.GetUserByHandle(const wstrHandle: WideString): IUser;
var
  i: integer;
begin
  // It is supposed that a user with a handle wstrHandle is a real user

  Result := nil;

  if (wstrHandle = '') then
    exit;

  if (not Assigned(m_Users)) then
    m_Users := TInterfaceList.Create;

  for i := 0 to m_Users.Count - 1 do
  begin
    Result := IUser(m_Users[i]);
    if (Result.Handle = wstrHandle) then
      exit;
  end;

  Result := TUser.Create(wstrHandle);
  m_Users.Add(Result);
end;


procedure TSkype.FSetOnMessageStatus(Value: TOnMessageStatus);
var
  iIndex: integer;
begin
  if (Assigned(FOnMessageStatus)) then
  begin
    iIndex := m_Listeners.FindInstanceOf(TChatMessageStatusListener, TRUE);
    if (iIndex >= 0) then
      m_Listeners.Delete(iIndex);
  end;

  FOnMessageStatus := Value;
  m_Listeners.Add(TChatMessageStatusListener.Create);
end;

////////////////////////////////////////////////////////////////////////////////
// TProtocolCommand

constructor TProtocolCommand.Create(iRequestedProtocol: integer);
begin
  inherited Create;
  m_iRequestedProtocol := iRequestedProtocol;
end;


function TProtocolCommand.RGetCommand: WideString;
begin
  Result := CMD_PROTOCOL + ' ' + IntToStr(m_iRequestedProtocol);
end;


function TProtocolCommand.RProcessResponse(const wstrCommand: WideString): boolean;
var
  wstrHead, wstrBody: WideString;
begin
  Assert(not HasResponse);

  Result := FALSE;

  RSplitCommandToHeadAndBody(wstrCommand, wstrHead, wstrBody);

  if (wstrHead <> CMD_PROTOCOL) then
    exit;

  m_iReturnedProtocol := StrToInt(wstrBody);

  Result := TRUE;
end;

end.

