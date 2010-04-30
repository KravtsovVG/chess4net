program IMEClient;

(*
{$IFDEF FASTMM4}
  FastMM4,
{$ENDIF}
*)

uses
{$IFDEF FASTMM4}
  FastMM4,
{$ENDIF}
  Forms,
  IMEClient.MainForm in 'IMEClient.MainForm.pas' {MainForm},
  IMEClient.ModelModule in 'IMEClient.ModelModule.pas' {ModelModule: TDataModule},
  IMEClient.Headers in 'IMEClient.Headers.pas',
  IMEClient.PluginSurrogate in 'IMEClient.PluginSurrogate.pas',
  IMEClient.PluginSurrogate.MI in 'MI\IMEClient.PluginSurrogate.MI.pas';

{$R *.res}

var
  MainForm: TMainForm;
  ModelModule: TModelModule;

begin
  Application.Initialize;
  Application.Title := 'IMEClient';

  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TModelModule, ModelModule);
  ModelModule.SetView(MainForm);

  Application.Run;
end.
