object AnalyseChessBoard: TAnalyseChessBoard
  Left = 429
  Top = 209
  Width = 364
  Height = 423
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = 'Chess4Net Analyzer 2011.0 gamma'
  Color = clBtnFace
  TransparentColorValue = clBackground
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'MS Sans Serif'
  Font.Style = [fsBold]
  KeyPreview = True
  Menu = MainMenu
  OldCreateOrder = False
  PopupMenu = PopupMenu
  OnCanResize = FormCanResize
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  DesignSize = (
    356
    377)
  PixelsPerInch = 96
  TextHeight = 16
  object ChessBoardPanel: TPanel
    Left = 0
    Top = 0
    Width = 356
    Height = 352
    Anchors = [akLeft, akTop, akRight, akBottom]
    BevelOuter = bvNone
    TabOrder = 0
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 358
    Width = 356
    Height = 19
    Panels = <>
  end
  object MainMenu: TTntMainMenu
    Images = ImageList
    object FileMenuItem: TTntMenuItem
      Caption = '&File'
      object OpenPGNMenuItem: TTntMenuItem
        Caption = '&Open PGN...'
        ShortCut = 16463
        OnClick = OpenPGNMenuItemClick
      end
      object SavePGNMenuItem: TTntMenuItem
        Caption = '&Save PGN...'
        Enabled = False
        ShortCut = 16467
      end
      object N2: TTntMenuItem
        Caption = '-'
      end
      object PastePGNMenuItem: TTntMenuItem
        Caption = '&Paste PGN'
        ShortCut = 16470
        OnClick = PastePGNMenuItemClick
      end
      object CopyPGNMenuItem: TTntMenuItem
        Caption = '&Copy PGN'
        Enabled = False
        ShortCut = 16451
      end
      object N1: TTntMenuItem
        Caption = '-'
      end
      object ExitMenuItem: TTntMenuItem
        Caption = 'E&xit'
        ShortCut = 32856
        OnClick = ExitMenuItemClick
      end
    end
    object ViewMenuItem: TTntMenuItem
      Caption = '&View'
      object ViewFlipBoardMenuItem: TTntMenuItem
        Caption = '&Flip Board'
        ShortCut = 70
        OnClick = ViewFlipBoardMenuItemClick
      end
      object N5: TTntMenuItem
        Caption = '-'
      end
      object ViewMoveListMenuItem: TTntMenuItem
        Action = MoveListAction
      end
      object ViewOpeningsDBManagerMenuItem: TTntMenuItem
        Action = OpeningsDBManagerAction
      end
      object ViewChessEngineInfoMenuItem: TTntMenuItem
        Action = ChessEngineInfoAction
      end
    end
    object PositionMenuItem: TTntMenuItem
      Caption = '&Position'
      object PositionInitialMenuItem: TTntMenuItem
        Caption = '&Initial'
        OnClick = PositionInitialMenuItemClick
      end
      object N4: TTntMenuItem
        Caption = '-'
      end
      object PositionTakebackMoveMenuItem: TTntMenuItem
        Action = TakebackMoveAction
        Caption = '&Takeback Move'
      end
      object PositionForwardMoveMenuItem: TTntMenuItem
        Action = ForwardMoveAction
        Caption = '&Forward Move'
      end
      object PositionSelectLineMenuItem: TTntMenuItem
        Action = SelectLineAction
        Caption = 'Select &Line...'
      end
    end
    object HelpMenuItem: TTntMenuItem
      Caption = '&Help'
      object ContentsMenuItem: TTntMenuItem
        Caption = 'Contents...'
        Enabled = False
      end
      object N3: TTntMenuItem
        Caption = '-'
      end
      object AboutMenuItem: TTntMenuItem
        Caption = 'About...'
        Enabled = False
      end
    end
  end
  object PopupMenu: TTntPopupMenu
    Images = ImageList
    Left = 32
    object PopupForwardMoveMenuItem: TTntMenuItem
      Action = ForwardMoveAction
      Caption = 'Forward Move'
    end
    object PopupTakebackMoveMenuItem: TTntMenuItem
      Action = TakebackMoveAction
      Caption = 'Takeback Move'
    end
    object PopupSelectLineMenuItem: TTntMenuItem
      Action = SelectLineAction
      Caption = 'Select &Line...'
    end
  end
  object OpenPGNDialog: TOpenDialog
    Filter = 'PGN Files (*.pgn)|*.pgn'
    Top = 32
  end
  object ActionList: TActionList
    Images = ImageList
    Left = 64
    object ChessEngineInfoAction: TAction
      Category = 'Views'
      Caption = 'Chess &Engine Info'
      OnExecute = ChessEngineInfoActionExecute
      OnUpdate = ChessEngineInfoActionUpdate
    end
    object MoveListAction: TAction
      Category = 'Views'
      Caption = '&Move List'
      OnExecute = MoveListActionExecute
      OnUpdate = MoveListActionUpdate
    end
    object TakebackMoveAction: TAction
      Category = 'Navigation'
      Hint = 'Takeback move'
      ImageIndex = 1
      ShortCut = 37
      OnExecute = TakebackMoveActionExecute
      OnUpdate = TakebackMoveActionUpdate
    end
    object ForwardMoveAction: TAction
      Category = 'Navigation'
      Hint = 'Forward move'
      ImageIndex = 0
      ShortCut = 39
      OnExecute = ForwardMoveActionExecute
      OnUpdate = ForwardMoveActionUpdate
    end
    object SelectLineAction: TAction
      Category = 'Navigation'
      Hint = 'Select line'
      ImageIndex = 2
      ShortCut = 16423
      SecondaryShortCuts.Strings = (
        'Ctrl+Space')
      OnExecute = SelectLineActionExecute
      OnUpdate = SelectLineActionUpdate
    end
    object SelectLineFromMoveListAction: TAction
      Category = 'Navigation'
      ShortCut = 13
      SecondaryShortCuts.Strings = (
        'Space')
      OnExecute = SelectLineFromMoveListActionExecute
      OnUpdate = SelectLineFromMoveListActionUpdate
    end
    object OpeningsDBManagerAction: TAction
      Category = 'Views'
      Caption = '&Openings DB Manager'
      OnExecute = OpeningsDBManagerActionExecute
      OnUpdate = OpeningsDBManagerActionUpdate
    end
  end
  object ImageList: TImageList
    Left = 1
    Top = 64
    Bitmap = {
      494C010103000400040010001000FFFFFFFFFF10FFFFFFFFFFFFFFFF424D3600
      0000000000003600000028000000400000001000000001002000000000000010
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000008080
      8000808080000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000080808000808080008080
      8000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000008080
      8000808080008080800080808000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000080808000808080000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000080808000008000000080
      0000808080008080800000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000008080
      8000008000000080000080808000808080008080800000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000808080008080800080808000008000000080
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000080808000808080008080800080808000008000000080
      0000008000000080000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000008080
      8000008000000080000000800000008000008080800080808000808080000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000008080800080808000808080000080000000800000008000000080
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000080808000800000008000000080000000008000000080
      0000008000000080000000800000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000008080
      8000008000000080000000800000008000000080000000800000808080008080
      8000808080000000000000000000000000000000000000000000000000008080
      8000808080008080800000800000008000000080000000800000008000000080
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000080808000800000000000000000000000008000000080
      0000008000000080000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000008080
      8000008000000080000000800000008000000080000000800000008000000080
      0000808080008080800000000000000000000000000000000000808080008080
      8000008000000080000000800000008000000080000000800000008000000080
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000080808000800000000000000000000000008000000080
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000008080
      8000008000000080000000800000008000000080000000800000008000000080
      0000008000000080000000000000000000000000000080808000008000000080
      0000008000000080000000800000008000000080000000800000008000000080
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000080808000800000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000008080
      8000008000000080000000800000008000000080000000800000008000000080
      0000008000000080000000800000000000000000000000800000008000000080
      0000008000000080000000800000008000000080000000800000008000000080
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000080808000800000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000008080
      8000008000000080000000800000008000000080000000800000008000000080
      0000008000000080000000000000000000000000000000000000008000000080
      0000008000000080000000800000008000000080000000800000008000000080
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000080808000800000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000008080
      8000008000000080000000800000008000000080000000800000008000000080
      0000000000000000000000000000000000000000000000000000000000000000
      0000008000000080000000800000008000000080000000800000008000000080
      0000000000000000000000000000000000000000000080808000808080008080
      8000808080008080800080808000800000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000008080
      8000008000000080000000800000008000000080000000800000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000800000008000000080000000800000008000000080
      0000000000000000000000000000000000000000000080808000800000008000
      0000800000008000000080000000800000008000000080000000800000008000
      0000800000008000000080000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000008000000080000000800000008000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000080000000800000008000000080
      0000000000000000000000000000000000000000000000000000800000008000
      0000800000008000000080000000800000008000000080000000800000008000
      0000800000008000000080000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000008000000080000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000008000000080
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000424D3E000000000000003E000000
      2800000040000000100000000100010000000000800000000000000000000000
      000000000000000000000000FFFFFF00FFFFFFFFFFFF0000FFFFFFFFFFFF0000
      E7FFFFFFFF8F0000E1FFFF9FFF830000E07FFE0FFC030000E01FF80FFC010000
      E007E00FFCC30000E003C00FFCCF0000E003800FFCFF0000E001800FFCFF0000
      E003C00FFCFF0000E00FF00F80FF0000E03FFC0F80010000F0FFFF0FC0010000
      F3FFFFCFFFFF0000FFFFFFFFFFFF000000000000000000000000000000000000
      000000000000}
  end
  object ApplicationEvents: TApplicationEvents
    OnIdle = ApplicationEventsIdle
    Left = 32
    Top = 32
  end
end
