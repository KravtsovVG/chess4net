object CreditsForm: TCreditsForm
  Left = 546
  Top = 357
  BorderStyle = bsDialog
  ClientHeight = 129
  ClientWidth = 427
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Microsoft Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object CreditsLabel: TTntLabel
    Left = 64
    Top = 16
    Width = 361
    Height = 13
    AutoSize = False
    Caption = 'If you liked plying Chess4Net give your credits at'
  end
  object Chess4NetImage: TImage
    Left = 16
    Top = 16
    Width = 33
    Height = 33
    Picture.Data = {
      055449636F6E0000010001002020100000000000E80200001600000028000000
      2000000040000000010004000000000080020000000000000000000000000000
      0000000000000000000080000080000000808000800000008000800080800000
      C0C0C000808080000000FF0000FF000000FFFF00FF000000FF00FF00FFFF0000
      FFFFFF0077799977999799999977799977777777777999779997999999777999
      7777777777799979999799977777799977777777777999799997999777777999
      7777777777799979999799977777799977777777777999999997999777777999
      7777777777799999999799999977799977777777777999999997999999777999
      7777777777799999999799977777799977777777777999939993999110777999
      7777777777799997999399911107799977777777777999FF999B999999099999
      9977777777799933999199999909999999777777777711333333333110077777
      77777777777777133333111117777777777777777777113FFF7B333100077777
      7777777777731111113311111131777777777777733133110033001133330777
      777777773313B331007300133BBB1077777777773137BB31003300133BFF3117
      7999777713FF7B31033130133BFF73077999777713FF7331370131013B7F7307
      7799977713FFB3117300330133B739999999997713BB31173103311011333399
      9999999711333331131331031113319997799977101333003333310011330079
      9979997773000017773177770000177799799977777777771331317777777777
      7997999777777777111111777777777777999997777777777711777777777777
      7779999777777777771177777777777777779999777777777777777777777777
      7777799900000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000}
  end
  object Label1: TLabel
    Left = 64
    Top = 36
    Width = 33
    Height = 13
    AutoSize = False
    Caption = 'URLs:'
  end
  object URLLabel: TLabel
    Left = 100
    Top = 36
    Width = 65
    Height = 13
    Cursor = crHandPoint
    Caption = 'http://<URL>'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsUnderline]
    ParentFont = False
    OnClick = URLLabelClick
  end
  object URL2Label: TLabel
    Left = 100
    Top = 52
    Width = 71
    Height = 13
    Cursor = crHandPoint
    Caption = 'http://<URL2>'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsUnderline]
    ParentFont = False
    OnClick = URLLabelClick
  end
  object CloseButton: TTntButton
    Left = 171
    Top = 75
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Cancel = True
    Caption = '&Close'
    Default = True
    ModalResult = 1
    TabOrder = 0
    OnClick = CloseButtonClick
  end
  object cbDontShowAgain: TTntCheckBox
    Left = 8
    Top = 106
    Width = 369
    Height = 17
    Anchors = [akLeft, akBottom]
    Caption = 'Don'#39't show it again'
    TabOrder = 1
  end
end
