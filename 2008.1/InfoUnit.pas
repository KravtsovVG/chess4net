unit InfoUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ShellAPI;

type
  TInfoForm = class(TForm)
    OkButton: TButton;
    PluginNameLabel: TLabel;
    PlayingViaLabel: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    URLLabel: TLabel;
    EMailLabel: TLabel;
    procedure OkButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure EMailLabelClick(Sender: TObject);
    procedure URLLabelClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  end;

procedure ShowInfo;

implementation

{$R *.dfm}

uses
  GlobalsLocalUnit;

var
  infoForm: TInfoForm = nil;

procedure ShowInfo;
begin
  if not Assigned(infoForm) then
    begin
      infoForm := TInfoForm.Create(Application);
      infoForm.Icon := pluginIcon;
      infoForm.Caption := PLUGIN_NAME;
    end;
  if not infoForm.Showing then
    infoForm.Show
  else
    infoForm.SetFocus;
end;

procedure TInfoForm.OkButtonClick(Sender: TObject);
begin
  Close;
end;

procedure TInfoForm.FormCreate(Sender: TObject);
begin
  PlayingViaLabel.Caption := PLUGIN_PLAYING_VIA; 
  PluginNameLabel.Caption := PLUGIN_INFO_NAME;
  URLLabel.Caption := PLUGIN_URL;
  EMailLabel.Caption := PLUGIN_EMAIL;
end;

procedure TInfoForm.URLLabelClick(Sender: TObject);
begin
  ShellExecute(Handle, nil, PChar(URLLabel.Caption), nil, nil, SW_SHOWNORMAL);
end;

procedure TInfoForm.EMailLabelClick(Sender: TObject);
var
  shellStr: string;
begin
  shellStr := 'mailto:' + EMailLabel.Caption;
  ShellExecute(Handle, nil, PChar(shellStr), nil, nil, SW_SHOWNORMAL);
end;

procedure TInfoForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  infoForm := nil;
  Action := caFree;
end;

end.