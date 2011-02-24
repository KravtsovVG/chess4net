object AnalyseChessBoard: TAnalyseChessBoard
  Left = 429
  Top = 209
  Width = 364
  Height = 423
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = 'Chess4Net Analyzer <version>'
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
  OnActivate = FormActivate
  OnCanResize = FormCanResize
  OnCloseQuery = FormCloseQuery
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
    ParentShowHint = False
    ShowHint = True
    SimplePanel = True
  end
  object MainMenu: TTntMainMenu
    Images = ImageList
    object FileMenuItem: TTntMenuItem
      Caption = '&File'
      object FileNewMenuItem: TTntMenuItem
        Caption = '&New'
        object FileNewStandardMenuItem: TTntMenuItem
          Caption = '&Standard'
          ShortCut = 16462
          OnClick = FileNewStandardMenuItemClick
        end
        object FileNewCustomMenuItem: TTntMenuItem
          Caption = '&Custom...'
          OnClick = FileNewCustomMenuItemClick
        end
      end
      object N6: TTntMenuItem
        Caption = '-'
      end
      object FileOpenMenuItem: TTntMenuItem
        Caption = '&Open...'
        ShortCut = 16463
        OnClick = FileOpenMenuItemClick
      end
      object FileSaveMenuItem: TTntMenuItem
        Action = SaveAction
        Caption = '&Save'
      end
      object FileSaveAsMenuItem: TTntMenuItem
        Action = SaveAsAction
        Caption = 'Save &As...'
      end
      object N2: TTntMenuItem
        Caption = '-'
      end
      object FileCopyMenuItem: TTntMenuItem
        Action = CopyAction
        Caption = '&Copy'
      end
      object FilePasteMenuItem: TTntMenuItem
        Caption = '&Paste'
        ShortCut = 16470
        OnClick = FilePasteMenuItemClick
      end
      object FileCopyFENMenuItem: TTntMenuItem
        Caption = 'Copy &FEN'
        ShortCut = 32835
        OnClick = FileCopyFENMenuItemClick
      end
      object N1: TTntMenuItem
        Caption = '-'
      end
      object FileExitMenuItem: TTntMenuItem
        Caption = 'E&xit'
        ShortCut = 32856
        OnClick = FileExitMenuItemClick
      end
    end
    object ViewMenuItem: TTntMenuItem
      Caption = '&View'
      object ViewFlipBoardMenuItem: TTntMenuItem
        Caption = '&Flip Board'
        ShortCut = 16454
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
    object EditMenuItem: TTntMenuItem
      Caption = '&Edit'
      object EditDeleteLineMenuItem: TTntMenuItem
        Action = DeleteLineAction
        Caption = '&Delete Line'
      end
      object EditSetLineToMainMenuItem: TTntMenuItem
        Action = SetLineToMainAction
        Caption = 'Set Line To &Main'
      end
    end
    object PositionMenuItem: TTntMenuItem
      Caption = '&Position'
      object PositionInitialMenuItem: TTntMenuItem
        Action = InitialPositionAction
        Caption = '&Initial Position'
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
      object PositionReturnFromLineMenuItem: TTntMenuItem
        Action = ReturnFromLineAction
        Caption = '&Return From Line'
      end
      object PositionSelectLineMenuItem: TTntMenuItem
        Action = SelectLineAction
        Caption = 'Select &Line...'
      end
    end
    object HelpMenuItem: TTntMenuItem
      Caption = '&Help'
      object HelpContentsMenuItem: TTntMenuItem
        Caption = 'Contents...'
        Enabled = False
        Visible = False
      end
      object N3: TTntMenuItem
        Caption = '-'
      end
      object HelpAboutMenuItem: TTntMenuItem
        Caption = 'About...'
        OnClick = HelpAboutMenuItemClick
      end
    end
  end
  object PopupMenu: TTntPopupMenu
    Images = ImageList
    OnPopup = PopupMenuPopup
    Left = 32
    object PopupForwardMoveMenuItem: TTntMenuItem
      Action = ForwardMoveAction
      Caption = 'Forward Move'
    end
    object PopupSelectLineMenuItem: TTntMenuItem
      Action = SelectLineAction
      Caption = 'Select &Line...'
    end
    object PopupTakebackMoveMenuItem: TTntMenuItem
      Action = TakebackMoveAction
      Caption = 'Takeback Move'
    end
    object PopupInitialPositionMenuItem: TTntMenuItem
      Action = InitialPositionAction
      Caption = 'Initial Position'
    end
    object N7: TTntMenuItem
      Caption = '-'
    end
    object PopupDeleteLineMenuItem: TTntMenuItem
      Action = DeleteLineAction
      Caption = 'Delete Line'
    end
  end
  object OpenDialog: TOpenDialog
    DefaultExt = 'c4n'
    Filter = 
      'Supported Files (*.c4n *.pgn)|*.c4n;*.pgn|Chess4Net Files (*.c4n' +
      ')|*.c4n|PGN Files (*.pgn)|*.pgn'
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
    object InitialPositionAction: TAction
      Category = 'Navigation'
      Hint = 'Initial position'
      ImageIndex = 3
      ShortCut = 36
      OnExecute = InitialPositionActionExecute
      OnUpdate = InitialPositionActionUpdate
    end
    object ReturnFromLineAction: TAction
      Category = 'Navigation'
      Hint = 'Return from line'
      ImageIndex = 4
      ShortCut = 16421
      OnExecute = ReturnFromLineActionExecute
      OnUpdate = ReturnFromLineActionUpdate
    end
    object SaveAction: TAction
      Category = 'File'
      ShortCut = 16467
      OnExecute = SaveActionExecute
      OnUpdate = SaveActionUpdate
    end
    object SaveAsAction: TAction
      Category = 'File'
      OnExecute = SaveAsActionExecute
      OnUpdate = SaveAsActionUpdate
    end
    object DeleteLineAction: TAction
      Category = 'Edit'
      Hint = 'Delete line'
      ImageIndex = 5
      ShortCut = 46
      OnExecute = DeleteLineActionExecute
      OnUpdate = DeleteLineActionUpdate
    end
    object SetLineToMainAction: TAction
      Category = 'Edit'
      Hint = 'Set line to main'
      OnExecute = SetLineToMainActionExecute
      OnUpdate = SetLineToMainActionUpdate
    end
    object CopyAction: TAction
      Category = 'File'
      ShortCut = 16451
      OnExecute = CopyActionExecute
      OnUpdate = CopyActionUpdate
    end
  end
  object ImageList: TImageList
    Left = 1
    Top = 64
    Bitmap = {
      494C010106000900040010001000FFFFFFFFFF10FFFFFFFFFFFFFFFF424D3600
      0000000000003600000028000000400000003000000001002000000000000030
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
      0000000000000000000000000000000000000000000080808000808080008080
      8000808080008080800080808000808080008080800080808000808080008080
      8000808080008080800000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000080808000800000008000
      0000800000008000000080000000800000008000000080000000800000008000
      0000800000008000000080000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000800000008000
      0000800000008000000080000000800000008000000080000000800000008000
      0000800000008000000080000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000008080800080000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000008080800080000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000FF000000FF0000000000000000000000
      0000000000000000FF000000FF00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000008080800080000000000000000000
      0000000000000000000000000000000000000000000080808000808080008080
      8000808080008080800080808000808080000000FF000000FF00808080008080
      80000000FF000000FF0000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000808080008080800000000000000000008080800080000000000000000000
      0000000000000000000000000000000000000000000080808000800000008000
      000080000000800000008000000080000000800000000000FF000000FF000000
      FF000000FF008000000080000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000808080008080
      8000808080000080000000800000000000008080800080000000000000000000
      0000000000000000000000000000000000000000000000000000800000008000
      00008000000080000000800000008000000080000000800000000000FF000000
      FF00800000008000000080000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000080808000808080000080
      0000008000000080000000800000808080008080800080000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000FF000000FF000000
      FF000000FF000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000008000000080
      0000008000000080000000800000800000008000000080000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000FF000000FF00000000000000
      00000000FF000000FF0000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000080
      0000008000000080000000800000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000FF000000FF0000000000000000000000
      0000000000000000FF000000FF00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000080000000800000000000000000000000000000000000000000
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
      0000808080008080800000000000000000000000000080808000808080000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000808080008080800000000000000000000000000000000000000000008080
      8000008000000080000080808000808080008080800000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000808080008080800080808000008000000080
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000080808000808080008080800080808000008000000080
      0000008000000080000000000000000000000000000080808000008000000080
      0000000000000000000000000000000000000000000000000000808080008080
      8000808080000080000000800000000000000000000000000000000000008080
      8000008000000080000000800000008000008080800080808000808080000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000008080800080808000808080000080000000800000008000000080
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000080808000800000008000000080000000008000000080
      0000008000000080000000800000000000000000000080808000008000000080
      0000000000000000000000000000000000008080800080808000808080000080
      0000008000000080000000800000000000000000000000000000000000008080
      8000008000000080000000800000008000000080000000800000808080008080
      8000808080000000000000000000000000000000000000000000000000008080
      8000808080008080800000800000008000000080000000800000008000000080
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000080808000800000000000000000000000008000000080
      0000008000000080000000000000000000000000000080808000008000000080
      0000000000000000000080808000808080008080800000800000008000000080
      0000008000000080000000800000000000000000000000000000000000008080
      8000008000000080000000800000008000000080000000800000008000000080
      0000808080008080800000000000000000000000000000000000808080008080
      8000008000000080000000800000008000000080000000800000008000000080
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000080808000800000000000000000000000008000000080
      0000000000000000000000000000000000000000000080808000008000000080
      0000000000008080800080808000008000000080000000800000008000000080
      0000008000000080000000800000000000000000000000000000000000008080
      8000008000000080000000800000008000000080000000800000008000000080
      0000008000000080000000000000000000000000000080808000008000000080
      0000008000000080000000800000008000000080000000800000008000000080
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000080808000800000000000000000000000000000000000
      0000000000000000000000000000000000000000000080808000008000000080
      0000808080000080000000800000008000000080000000800000008000000080
      0000008000000080000000800000000000000000000000000000000000008080
      8000008000000080000000800000008000000080000000800000008000000080
      0000008000000080000000800000000000000000000000800000008000000080
      0000008000000080000000800000008000000080000000800000008000000080
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000080808000800000000000000000000000000000000000
      0000000000000000000000000000000000000000000080808000008000000080
      0000008000000080000000800000008000000080000000800000008000000080
      0000008000000080000000800000000000000000000000000000000000008080
      8000008000000080000000800000008000000080000000800000008000000080
      0000008000000080000000000000000000000000000000000000008000000080
      0000008000000080000000800000008000000080000000800000008000000080
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000080808000800000000000000000000000000000000000
      0000000000000000000000000000000000000000000080808000008000000080
      0000000000000080000000800000008000000080000000800000008000000080
      0000008000000080000000800000000000000000000000000000000000008080
      8000008000000080000000800000008000000080000000800000008000000080
      0000000000000000000000000000000000000000000000000000000000000000
      0000008000000080000000800000008000000080000000800000008000000080
      0000000000000000000000000000000000000000000080808000808080008080
      8000808080008080800080808000800000000000000000000000000000000000
      0000000000000000000000000000000000000000000080808000008000000080
      0000000000000000000000000000008000000080000000800000008000000080
      0000008000000080000000800000000000000000000000000000000000008080
      8000008000000080000000800000008000000080000000800000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000800000008000000080000000800000008000000080
      0000000000000000000000000000000000000000000080808000800000008000
      0000800000008000000080000000800000008000000080000000800000008000
      0000800000008000000080000000000000000000000080808000008000000080
      0000000000000000000000000000000000000000000000800000008000000080
      0000008000000080000000800000000000000000000000000000000000000000
      0000008000000080000000800000008000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000080000000800000008000000080
      0000000000000000000000000000000000000000000000000000800000008000
      0000800000008000000080000000800000008000000080000000800000008000
      0000800000008000000080000000000000000000000080808000008000000080
      0000000000000000000000000000000000000000000000000000000000000080
      0000008000000080000000800000000000000000000000000000000000000000
      0000008000000080000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000008000000080
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000008000000080
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000080000000800000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000424D3E000000000000003E000000
      2800000040000000300000000100010000000000800100000000000000000000
      000000000000000000000000FFFFFF0000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000FFFFFFFF00000000FFFFFFFF00000000
      8003FFFF000000008001FFFF00000000C001FFFF00000000FF3FFFFF00000000
      FF3FFE7900000000FF3F800300000000F33F800100000000C13FC00100000000
      803FFF8700000000C03FFF3300000000E1FFFE7900000000F9FFFFFF00000000
      FFFFFFFF00000000FFFFFFFF00000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      E7FFFFFFFF8FFFFFE1FFFF9FFF839FF3E07FFE0FFC038FC1E01FF80FFC018F01
      E007E00FFCC38C01E003C00FFCCF8801E003800FFCFF8001E001800FFCFF8001
      E003C00FFCFF8801E00FF00F80FF8E01E03FFC0F80018F81F0FFFF0FC0018FE1
      F3FFFFCFFFFFCFF9FFFFFFFFFFFFFFFF00000000000000000000000000000000
      000000000000}
  end
  object ApplicationEvents: TApplicationEvents
    OnIdle = ApplicationEventsIdle
    Left = 64
    Top = 32
  end
  object SaveDialog: TSaveDialog
    DefaultExt = 'c4n'
    Filter = 'Chess4Net Files (*.c4n)|*.c4n'
    Left = 32
    Top = 32
  end
end
