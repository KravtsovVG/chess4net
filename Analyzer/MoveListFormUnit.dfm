object MoveListForm: TMoveListForm
  Left = 796
  Top = 209
  Width = 236
  Height = 423
  BorderStyle = bsSizeToolWin
  Caption = 'Move List'
  Color = clBtnFace
  Constraints.MinHeight = 150
  Constraints.MinWidth = 226
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnDeactivate = FormDeactivate
  DesignSize = (
    220
    387)
  PixelsPerInch = 96
  TextHeight = 13
  object BackSpeedButton: TSpeedButton
    Left = 81
    Top = 359
    Width = 23
    Height = 22
    Action = AnalyseChessBoard.TakebackMoveAction
    Anchors = [akLeft, akBottom]
    Glyph.Data = {
      76010000424D7601000000000000760000002800000020000000100000000100
      0400000000000001000000000000000000001000000000000000000000000000
      8000008000000080800080000000800080008080000080808000C0C0C0000000
      FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00DDDDDDDDDDDD
      DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
      DDDDDDDDDDDDDDDDDDDDDDDDDDDDD77DDDDDDDDDDDDDD77DDDDDDDDDDDD77722
      DDDDDDDDDDD77777DDDDDDDDD7772222DDDDDDDDD7777777DDDDDDD777222222
      DDDDDDD777777777DDDDDD7722222222DDDDDD7777777777DDDDD72222222222
      DDDDD77777777777DDDDD22222222222DDDDD77777777777DDDDDD2222222222
      DDDDDD7777777777DDDDDDDD22222222DDDDDDDD77777777DDDDDDDDDD222222
      DDDDDDDDDD777777DDDDDDDDDDDD2222DDDDDDDDDDDD7777DDDDDDDDDDDDDD22
      DDDDDDDDDDDDDD77DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD}
    NumGlyphs = 2
  end
  object ForthSpeedButton: TSpeedButton
    Left = 107
    Top = 359
    Width = 23
    Height = 22
    Action = AnalyseChessBoard.ForwardMoveAction
    Anchors = [akLeft, akBottom]
    Glyph.Data = {
      76010000424D7601000000000000760000002800000020000000100000000100
      0400000000000001000000000000000000001000000000000000000000000000
      8000008000000080800080000000800080008080000080808000C0C0C0000000
      FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00DDDDDDDDDDDD
      DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD77DDDDDDD
      DDDDDDD77DDDDDDDDDDDDDD7777DDDDDDDDDDDD7777DDDDDDDDDDDD722777DDD
      DDDDDDD777777DDDDDDDDDD72222777DDDDDDDD77777777DDDDDDDD722222277
      7DDDDDD7777777777DDDDDD72222222277DDDDD77777777777DDDDD722222222
      22DDDDD77777777777DDDDD722222222222DDDD777777777777DDDD722222222
      22DDDDD77777777777DDDDD722222222DDDDDDD777777777DDDDDDD7222222DD
      DDDDDDD7777777DDDDDDDDDD2222DDDDDDDDDDDD7777DDDDDDDDDDDD22DDDDDD
      DDDDDDDD77DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD}
    NumGlyphs = 2
  end
  object MovesStringGrid: TStringGrid
    Left = 0
    Top = 0
    Width = 220
    Height = 352
    Align = alTop
    Anchors = [akLeft, akTop, akRight, akBottom]
    ColCount = 3
    DefaultRowHeight = 20
    FixedCols = 0
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goEditing, goTabs]
    TabOrder = 0
    OnDrawCell = MovesStringGridDrawCell
    OnSelectCell = MovesStringGridSelectCell
    OnSetEditText = MovesStringGridSetEditText
    ColWidths = (
      24
      84
      86)
  end
end
