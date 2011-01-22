object OpeningsDBManagerForm: TOpeningsDBManagerForm
  Left = 429
  Top = 58
  Width = 364
  Height = 147
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSizeToolWin
  Caption = 'Openings DB Manager'
  Color = clBtnFace
  Constraints.MinHeight = 97
  Constraints.MinWidth = 276
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  OnShow = FormShow
  DesignSize = (
    348
    111)
  PixelsPerInch = 96
  TextHeight = 13
  object OpeningsDBListBox: TListBox
    Left = 0
    Top = 0
    Width = 348
    Height = 73
    Align = alTop
    Anchors = [akLeft, akTop, akRight, akBottom]
    ItemHeight = 13
    TabOrder = 0
  end
  object AddDBButton: TButton
    Left = 185
    Top = 80
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = '&Add DB'
    TabOrder = 1
  end
  object RemoveDBButton: TButton
    Left = 264
    Top = 80
    Width = 80
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = '&Remove DB'
    TabOrder = 2
  end
  object DBEnabledCheckBox: TCheckBox
    Left = 8
    Top = 83
    Width = 81
    Height = 17
    Anchors = [akLeft, akBottom]
    Caption = 'DB Enabled'
    TabOrder = 3
    OnClick = DBEnabledCheckBoxClick
  end
end
