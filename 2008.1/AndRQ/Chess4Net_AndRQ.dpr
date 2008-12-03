library Chess4Net_AndRQ;
{*******************************
  plugin library for &RQ
********************************}

uses
  ConnectingUnit in '..\ConnectingUnit.pas' {ConnectingForm},
  GameOptionsUnit in '..\GameOptionsUnit.pas' {GameOptionsForm},
  ChessBoardUnit in '..\ChessBoardUnit.pas' {ChessBoard},
  PosBaseChessBoardUnit in '..\PosBaseChessBoardUnit.pas',
  PromotionUnit in '..\PromotionUnit.pas' {PromotionForm},
  LookFeelOptionsUnit in '..\LookFeelOptionsUnit.pas' {OptionsForm},
  DialogUnit in '..\DialogUnit.pas',
  ModalForm in '..\ModalForm.pas',
  CallExec in 'AndRQINC\CallExec.pas',
  plugin in 'AndRQINC\plugin.pas',
  pluginutil in 'AndRQINC\pluginutil.pas',
  ControlUnit in 'ControlUnit.pas',
  ManagerUnit in '..\ManagerUnit.pas' {Manager},
  ConnectorUnit in 'ConnectorUnit.pas',
  GlobalsLocalUnit in 'GlobalsLocalUnit.pas',
  InfoUnit in '..\InfoUnit.pas' {InfoForm},
  MessageDialogUnit in '..\MessageDialogUnit.pas',
  GlobalsUnit in '..\GlobalsUnit.pas',
  PosBaseUnit in '..\PosBaseUnit.pas',
  ContinueUnit in '..\ContinueUnit.pas' {ContinueForm};

{$R ..\Chess4Net.res}

exports
  pluginFun;

end.
