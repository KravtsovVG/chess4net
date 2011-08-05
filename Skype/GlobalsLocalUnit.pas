////////////////////////////////////////////////////////////////////////////////
// All code below is exclusively owned by author of Chess4Net - Pavel Perminov
// (packpaul@mail.ru, packpaul1@gmail.com).
// Any changes, modifications, borrowing and adaptation are a subject for
// explicit permition from the owner.

unit GlobalsLocalUnit;

interface

uses
  Graphics;

const
  CHESS4NET = 'Chess4Net';

  CHESS4NET_VERSION = 201101; // 2011.1
  CHESS4NET_TITLE = 'Chess4Net 2011.1 [Skype] (http://chess4net.ru)';
  MSG_INVITATION = 'Wellcome to Chess4Net. If you don''t have it, please download it from http://chess4net.ru';

  DIALOG_CAPTION = CHESS4NET;

  PLUGIN_PLAYING_OVER = 'Plugin for playing chess over Skype';

  PLUGIN_INFO_NAME = 'Chess4Net 2011.1';
  PLUGIN_URL = 'http://chess4net.ru';
  PLUGIN_EMAIL = 'packpaul@mail.ru';

  SKYPE_APP_NAME = 'Chess4Net_Skype';

var
  Chess4NetPath: string;
  Chess4NetIniFilePath: string;
  Chess4NetGamesLogPath: string;

  Chess4NetIcon: TIcon;

implementation

uses
  Forms,
  //
  EnvironmentSetterUnit;

initialization
  Chess4NetIcon := Application.Icon;
  TEnvironmentSetter.SetEnvironment;

end.
