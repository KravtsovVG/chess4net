unit GlobalsSkypeUnit;

{$MODE Delphi}

interface

const
  CHESS4NET_VERSION = 201001; // 2010.1
{$IFDEF LCLwin32}
  CHESS4NET_TITLE = 'Chess4Net 2010.1 [Skype] (http://chess4net.ru)';
{$ENDIF}
{$IFDEF LCLgtk2}
  CHESS4NET_TITLE = 'Chess4Net 2010.1 [Skype]';
{$ENDIF}

  MSG_INVITATION = 'Wellcome to Chess4Net. If you don''t have it, please download it from http://chess4net.ru';
  SKYPE_APP_NAME = 'Chess4Net_Skype';

  PLUGIN_URL = 'http://chess4net.ru';
  PLUGIN_EMAIL = 'packpaul@mail.ru';

implementation

uses
  GlobalsUnit;

initialization
{$IFDEF WINDOWS}
//  Chess4NetPath := ExtractFileDir(Application.ExeName) + DirectorySeparator;
  Chess4NetPath := '.' + DirectorySeparator; // TODO: change
{$ELSE} {$IFDEF UNIX}
//  Chess4NetPath := '~/.Chess4Net/';
  Chess4NetPath := '.' + DirectorySeparator; // TODO: change
{$ELSE}
  Assert(FALSE);
{$ENDIF} {$ENDIF}

end.
