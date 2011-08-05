////////////////////////////////////////////////////////////////////////////////
// All code below is exclusively owned by author of Chess4Net - Pavel Perminov
// (packpaul@mail.ru, packpaul1@gmail.com).
// Any changes, modifications, borrowing and adaptation are a subject for
// explicit permition from the owner.

unit EnvironmentSetterUnit;

interface

type
  TEnvironmentSetter = class
  private
    m_bIsTesting: boolean;
    
    function FGetApplicationPath: string;
    function FGetStartMenuPath: string;
    function FGetGamesLogPath: string;
    function FGetIniFilePath: string;

    procedure FCreateLinkForGameLogFile;
    function FCheckForGameLogFile: boolean;

    function FIsRunFromInstalledApplication: boolean;

  protected
    constructor RCreate;
    procedure RSetEnvironment;
    property IsTesting: boolean read m_bIsTesting write m_bIsTesting;

  public
    constructor Create;
    class procedure SetEnvironment;
  end;

implementation

uses
  Forms, SysUtils, ShlObj, Windows, ComObj, ActiveX, Registry,
  //
  GlobalsLocalUnit, GlobalsUnit;

const
  PATH_ADDON = 'Chess4Net\Skype\';
  REGISTRY_KEY = 'Software\Chess4Net\Skype';
  GAME_LOG_LINK_NAME = 'Game log';

function GetSpecialFolderPath(out strPath: string; iFolderCSIDL: integer): boolean;
var
  arrPathCh: array[0..MAX_PATH] of char;
begin
  FillChar(arrPathCh, Length(arrPathCh), 0);
  Result := SHGetSpecialFolderPath(Application.Handle, arrPathCh, iFolderCSIDL, TRUE);
  if (Result) then
    strPath := arrPathCh;
end;

////////////////////////////////////////////////////////////////////////////////
// TEnvironmentSetter


constructor TEnvironmentSetter.Create;
begin
  raise Exception.Create('TEnvironmentSetter cannot be instantiated directly!')
end;


constructor TEnvironmentSetter.RCreate;
begin
  inherited Create;
end;


class procedure TEnvironmentSetter.SetEnvironment;
begin
  with TEnvironmentSetter.RCreate do
  try
    RSetEnvironment;
  finally
    Free;
  end;
end;


procedure TEnvironmentSetter.RSetEnvironment;
const
  ENVIRONMENT_SET: boolean = FALSE;
begin
  if (ENVIRONMENT_SET and (not IsTesting)) then
    exit;

  Chess4NetPath := FGetApplicationPath;

  if (FIsRunFromInstalledApplication) then
  begin
    Chess4NetIniFilePath := FGetIniFilePath;
    Chess4NetGamesLogPath := FGetGamesLogPath;
  end
  else
  begin
    Chess4NetIniFilePath := FGetApplicationPath;
    Chess4NetGamesLogPath := FGetApplicationPath;
  end;

  ENVIRONMENT_SET := TRUE;
end;


function TEnvironmentSetter.FIsRunFromInstalledApplication: boolean;
var
  strInstalledApplicationPath: string;
begin
  Result := FALSE;

  with TRegistry.Create(KEY_READ) do
  try
    RootKey := HKEY_LOCAL_MACHINE;
    if (not OpenKeyReadOnly(REGISTRY_KEY)) then
      exit;
    strInstalledApplicationPath := ReadString('');
  finally
    Free;
  end;

  Result := SameFileName(Application.ExeName, strInstalledApplicationPath);
end;


function TEnvironmentSetter.FGetApplicationPath: string;
begin
  Result := ExtractFilePath(Application.ExeName);
end;


function TEnvironmentSetter.FGetStartMenuPath: string;
begin
  if (GetSpecialFolderPath(Result, CSIDL_STARTMENU)) then
    Result := IncludeTrailingPathDelimiter(Result) + PATH_ADDON
  else
    Result := '';
end;


function TEnvironmentSetter.FGetGamesLogPath: string;
begin
  if (GetSpecialFolderPath(Result, CSIDL_PERSONAL)) then
    Result := IncludeTrailingPathDelimiter(Result) + PATH_ADDON
  else
    Result := '';
end;


function TEnvironmentSetter.FGetIniFilePath: string;
begin
  if (GetSpecialFolderPath(Result, CSIDL_APPDATA)) then
    Result := IncludeTrailingPathDelimiter(Result) + PATH_ADDON
  else
    Result := '';
end;


procedure TEnvironmentSetter.FCreateLinkForGameLogFile;
var
  IObject: IUnknown;
  ISLink: IShellLink;
  IPFile: IPersistFile;
  wstrLinkName: WideString;
begin
  wstrLinkName := FGetStartMenuPath + ChangeFileExt(GAME_LOG_FILE, '.lnk');
  if (not FileExists(wstrLinkName)) then
    exit;

  if (not FCheckForGameLogFile) then
    exit;

  IObject := CreateComObject(CLSID_ShellLink);
  ISLink := IObject as IShellLink;
  IPFile := IObject as IPersistFile;

  ISLink.SetPath(PChar(FGetGamesLogPath + GAME_LOG_FILE));
  ISLink.SetWorkingDirectory(PChar(FGetGamesLogPath));

  if (not ForceDirectories(FGetStartMenuPath)) then
    exit;

  IPFile.Save(PWChar(wstrLinkName), FALSE);
end;


function TEnvironmentSetter.FCheckForGameLogFile: boolean;
var
  F: TextFile;
begin
  if (FileExists(FGetGamesLogPath + GAME_LOG_FILE)) then
  begin
    Result := TRUE;
    exit;
  end;

  Result := FALSE;

  if (not ForceDirectories(FGetGamesLogPath)) then
    exit;

  AssignFile(F, FGetGamesLogPath + GAME_LOG_FILE);
{$I-}
  Rewrite(F);
  if (IOResult <> 0) then
    exit;
  CloseFile(F);
{$I+}

  Result := TRUE;
end;

initialization
  TEnvironmentSetter.SetEnvironment;

end.
