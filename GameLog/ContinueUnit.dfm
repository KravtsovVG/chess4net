object ContinueForm: TContinueForm
  Left = 935
  Top = 255
  BorderStyle = bsDialog
  ClientHeight = 75
  ClientWidth = 210
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object ContinueLabel: TLabel
    Left = 24
    Top = 12
    Width = 165
    Height = 13
    Caption = 'Press button to continue the game.'
  end
  object ContinueButton: TButton
    Left = 67
    Top = 38
    Width = 75
    Height = 25
    Cancel = True
    Caption = '&Continue'
    Default = True
    ModalResult = 1
    TabOrder = 0
    OnClick = ContinueButtonClick
  end
end
