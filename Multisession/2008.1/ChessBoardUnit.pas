unit ChessBoardUnit;

// ��� ������� ������� ���������� ��������� {$DEFINE THREADED_CHESSCLOCK}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons;

type
  TFigureName = (K, Q, R, B, N, P);
  TFigure = (WK, WQ, WR, WB, WN, WP, ES,
              BK, BQ, BR, BB, BN, BP); // ES - Empty Square
  TFigureColor = (White, Black);
  TChessPosition = record // ��������� �������
    board: array[1..8, 1..8] of TFigure;
    color: TFigureColor; // ��� ���
    castling: set of (WhiteKingSide, WhiteQueenSide,  // ����������� ���������
                      BlackKingSide, BlackQueenSide);
    en_passant: 0..8; // ��������� ����������� ������ e.p. 0 - ���� e.p.
  end;
  TMode = (mView, mGame, mEdit); // ��������� �����
  TChessBoardEvent =
    (cbeMoved, cbeMate, cbeStaleMate, cbeInsuffMaterial, cbeKeyPressed,
     cbeClockSwitched, cbeTimeOut, cbeExit, cbeMenu, cbeActivate, cbeFormMoving, cbeRefreshAll); // �������� ���������� ����� �������
                                                                     // cbeRefreshAll �������������, ��� ���� �������� ���������� �����.
  TChessBoardHandler = procedure(e: TChessBoardEvent;
                                 d1: pointer = nil; d2: pointer = nil) of object;
  TAnimation = (aNo, aSlow, aQuick);

  TMoveAbs = record
    i0,j0,i,j: byte;
    prom_fig: TFigureName;
  end;

{$IFDEF THREADED_CHESSCLOCK}
  TChessBoard = class;
  TTimeLabelThread = class(TThread)
  private
    ChessBoard: TChessBoard;
    player_time: array[TFigureColor] of TDateTime;
  protected
    procedure Execute; override;
  public
    WhiteTime, BlackTime: string;
    constructor Create(ChessBoard: TChessBoard);
  end;
{$ENDIF}

  TChessBoard = class(TForm)
    PBoxBoard: TPaintBox;
    TimePanel: TPanel;
    WhiteLabel: TLabel;
    WhiteTimeLabel: TLabel;
    BlackLabel: TLabel;
    BlackTimeLabel: TLabel;
    GameTimer: TTimer;
    AnimateTimer: TTimer;
    WhiteFlagButton: TSpeedButton;
    BlackFlagButton: TSpeedButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure PBoxBoardPaint(Sender: TObject);
    procedure PBoxBoardDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure PBoxBoardDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure PBoxBoardEndDrag(Sender, Target: TObject; X, Y: Integer);
    procedure PBoxBoardMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PBoxBoardMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure PBoxBoardMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PBoxBoardStartDrag(Sender: TObject;
      var DragObject: TDragObject);
    procedure AnimateTimerTimer(Sender: TObject);
    procedure GameTimerTimer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormActivate(Sender: TObject);
    procedure FormMoving(var Msg: TWMMoving); message WM_MOVING;
    procedure FlagButtonClick(Sender: TObject);
    
  private
    Position: TChessPosition;
    mode_var: TMode;
    fig: TFigure;    // ��������������� ������
    i0,j0: integer;  // ���������� ���������� ������
    dx,dy: integer;  // ���������� �� ������� �� �������� ������ ����
    x0,y0: integer; // ���������� ���������� �������
    _flipped: boolean; // ����� ���������� ��� ���
    hilighted: boolean; // ��������� ��������� ����
    lastMove: TMoveAbs; // ��������� ��������� ���
    bmBuf: TBitmap;
    Handler: TChessBoardHandler;
    anim_dx, anim_dy: real; // ���������� ��� �������� ����������� ������
    anim_step, anim_step_num: integer; // ���������� ����� � ��������
    player_color: TFigureColor; // ���� ������ �������
    dragged_moved: boolean; // ��������� ��������� ��������������
    last_hilight: boolean; // ���� ��������� ���������� ����
    coord_show: boolean; // ���� ���������
    player_time: array[TFigureColor] of TDateTime; // ����� ����� � ������
    past_time: TDateTime; // ����� ������ ����������� ����
    unlimited_var: array[TFigureColor] of boolean; // ������ ��� ���������� ��������
    clock_color: TFigureColor; // ���� ����������� ������
    shuted: boolean; // ��������� �������� �������� ����
    auto_flag: boolean; // ��������� ���������
{$IFDEF THREADED_CHESSCLOCK}
    TimeLabelThread: TTimeLabelThread; // ���� ������������ ��� ������ � ����� � �������
{$ENDIF}
    procedure HilightLastMove;
    procedure AddPosMoveToList; // ��������� ������� � ��� �� �� � ������
    procedure DelPosList; // ������� ������� ������� �� ������
    procedure WhatSquare(const P: TPoint; var i: Integer; var j: Integer);
    procedure Animate(const i,j: integer); // ��������� ����������� ������ � (i0,j0) �� (i,j)
    procedure SetMode(const m: TMode);
    procedure ShowTime(const c: TFigureColor);
    function Move2Str(const pos: TChessPosition): string;
    procedure SetPlayerColor(const color: TFigureColor);
    procedure SetTime(color: TFigureColor; const tm: TDateTime);
    function GetTime(color: TFigureColor): TDateTime;
    procedure SetUnlimited(color: TFigureColor; const unl: boolean);
    function GetUnlimited(color: TFigureColor): boolean;
    procedure Evaluate;
    function CheckMove(const chp: TChessPosition; var chp_res: TChessPosition;
                             i0,j0,i,j: integer; var prom_fig: TFigureName): boolean;
    function CanMove(pos: TChessPosition): boolean;
    procedure SetHilightLastMove(const yes: boolean);
    procedure SetCoordinates(const yes: boolean);
    procedure SetFlipped(const f: boolean); // �������������� ������� ��� �����������
    function GetStayOnTop: boolean;
    procedure SetStayOnTop(onTop: boolean);
    procedure CancelAnimationDragging; // ������ �������� � �������������� ��� �������� ����� ��� ����������
    procedure SetAutoFlag(auto_flag: boolean);

  protected
    lstPosition: TList;
    bmHiddenBoard: TBitmap;
    procedure DrawBoard;
    procedure DrawHiddenBoard; virtual;
    procedure SetPositionRec(const pos: TChessPosition); virtual;
    function DoMove(i,j: integer; prom_fig: TFigureName = K): boolean; overload; virtual;

  public
    animation: TAnimation; // �������� ��������

    procedure TakeBack; // ������ ���� �������
    procedure SwitchClock(clock_color: TFigureColor);
    procedure ResetMoveList; // ������� ������ �������
    procedure Copy(cb: TChessBoard); // �������� ���� cb � self
    procedure Refresh;
    property Unlimited[color: TFigureColor]: boolean read GetUnlimited write SetUnlimited;
    property Time[color: TFigureColor]: TDateTime read GetTime write SetTime;
    property PlayerColor: TFigureColor read player_color write SetPlayerColor;
    property PositionColor: TFigureColor read Position.color; // ��� ��� � ������� �������
    property ClockColor: TFigureColor read clock_color;
    property Mode: TMode read mode_var write SetMode;
    property CoordinatesShown: boolean read coord_show write SetCoordinates;
    procedure InitPosition;
    procedure PPRandom;
    procedure StopClock;
    property flipped: boolean read _flipped write SetFlipped;
    property LastMoveHilighted: boolean read last_hilight write SetHilightLastMove;
    property StayOnTop: boolean read GetStayOnTop write SetStayOnTop;
    property AutoFlag: boolean read auto_flag write SetAutoFlag;

    function SetPosition(const posstr: string): boolean;
    function GetPosition: string;
    function GetPositionRec: TChessPosition;
    function GetLastMoveAbs: TMoveAbs; // ���������� ��������� ��������� ��� � ���. �����������
    function NMoveDone: integer; // ���������� ��������� �����
    function DoMove(move_str: string): boolean; overload;
    constructor Create(Owner: TComponent; h: TChessBoardHandler = nil); reintroduce;
    procedure Shut;
  end;

  TDeltaMove = array [TFigureName] of
    record
      longRange: boolean;
      dx,dy: array[1..8] of Integer;
    end;

  PPosMove = ^TPosMove;
  TPosMove = record
    pos: TChessPosition;
    move: TMoveAbs;
  end;

const
  SQUARE_SIZE = 40; // �������� ��������� ������ � �������� ����
  CHB_X= 20; CHB_Y= 6;     // ���������� ������ ���� A8
  INITIAL_CHESS_POSITION = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -';
  EMPTY_CHESS_POSITION = '8/8/8/8/8/8/8/8 w - -';
  DELTA_MOVE: TDeltaMove = ((longRange: FALSE; // ������
                            dx: (1,0,-1,0, 1,-1,-1,1); dy: (0,1,0,-1, 1,1,-1,-1)),
                            (longRange: TRUE; // �����
                            dx: (1,0,-1,0, 1,-1,-1,1); dy: (0,1,0,-1, 1,1,-1,-1)),
                            (longRange: TRUE; // �����
                            dx: (1,0,-1,0, 0,0,0,0); dy: (0,1,0,-1, 0,0,0,0)),
                            (longRange: TRUE; // ����
                            dx: (1,-1,-1,1, 0,0,0,0); dy: (1,1,-1,-1, 0,0,0,0)),
                            (longRange: FALSE; // ����
                            dx: (2,1,-1,-2, 2,1,-1,-2); dy: (1,2,2,1, -1,-2,-2,-1)),
                            (longRange: FALSE; // �����
                            dx: (0,0,-1,1, 0,0,0,0); dy: (2,1,1,1, 0,0,0,0)));

var
  bmFigure: array[TFigure] of TBitmap;

implementation

{$J+}

{$R *.dfm}
{$R ChessSet}

uses
  StrUtils, Math, DateUtils,
  // Chess4Net
  PromotionUnit;

var
  bmChessBoard: TBitMap;

const
  RES_NAME: array[TFigure] of string[2] = ('WK', 'WQ', 'WR', 'WB', 'WN', 'WP',
                                      'ES', 'BK', 'BQ', 'BR', 'BB', 'BN', 'BP');

  HILIGHT_WIDTH = 1;
  HILIGHT_COLOR: TColor = clRed;
  HILIGHT_LAST_MOVE_WIDTH = 1;
  HILIGHT_LAST_MOVE_COLOR: TColor = clBlue;
  ANIMATION_SLOW = 30; // ����� �������� ���� � ������� >= 1
  ANIMATION_QUICK = 9;
  CHB_WIDTH = 4;
  TIME_COLOR = clBlack;
//  FULL_TIME_FORMAT = 'h:n:s"."z';
  HOUR_TIME_FORMAT = 'h:nn:ss';
  MIN_TIME_FORMAT = 'n:ss';
  ZEITNOT_BOARDER = 10; // ��� - ����������� �������
  ZEITNOT_COLOR = clMaroon;
  ZEITNOT_FORMAT = 's"."zzz';
//  CHEAT_TIME_CONST = 1.5; // > 1

  CHESS_BOARD_INSTANCES: integer = 0;


function FieldUnderAttack(const pos: TChessPosition; i0,j0: integer): boolean;
var
  f: TFigureName;
  ef: TFigure;
  l: byte;
  ti,tj: Integer;
  locLongRange: boolean;
begin
  for f:= R to N do
    for l:= 1 to 8 do
      with DELTA_MOVE[f], pos do
        begin
          if (dx[l] = 0) and (dy[l] = 0) then break; // ��� ���� �����������
          ti:= i0; tj:= j0;
          locLongRange:= FALSE;
          repeat
            ti:= ti + dx[l]; tj:= tj + dy[l];
            if not(ti in [1..8]) or not(tj in [1..8]) then break;
            ef:= board[ti,tj];
            if ((color = White) and (ef < ES)) or ((color = Black) and (ef > ES))
              then break;
            case ef of
              WK,BK:
                if locLongRange or (f = N) then break;
              WQ,BQ:
                if f = N then break;
              WR,BR:
                if f <> R then break;
              WB,BB:
                if f <> B then break;
              WN,BN:
                if f <> N then break;
              WP,BP:
                if locLongRange or (f <> B) or
                   ((color = White) and not(tj > j0)) or
                   ((color = Black) and not(tj < j0))
                          then break;
              ES:
                begin
                  locLongRange:= TRUE;
                  continue;
                end;
            end;
            Result:= TRUE; exit;
          until not longRange;
        end;
  Result:= FALSE;
end;


function CheckCheck(const pos: TChessPosition): boolean;
label
  l;
const
  i0: integer = 1; // ��� ���������� �������� ���������
  j0: integer = 1;
var
  i,j: integer;
begin
  with pos do
    begin
      if ((color = White) and (board[i0,j0] = WK)) or
         ((color = Black) and (board[i0,j0] = BK)) then goto l;
      // ����� ������ �� �����
      for i:= 1 to 8 do
        for j:= 1 to 8 do
          if ((color = White) and (board[i,j] = WK)) or
             ((color = Black) and (board[i,j] = BK)) then
            begin
              i0:= i; j0:= j;
              goto l;
            end;

l:     Result:= FieldUnderAttack(pos,i0,j0);
    end;
end;


function TChessBoard.CheckMove(const chp: TChessPosition; var chp_res: TChessPosition;
                                     i0,j0,i,j: integer; var prom_fig: TFigureName): boolean;
label
  here;
var
  ti,tj: integer;
  l: byte;
  f: TFigureName;
  fig: TFigure;
  pos: TChessPosition;
  PromotionForm: TPromotionForm;
begin
  Result:= FALSE;
  if not ((i0 in [1..8]) and (j0 in [1..8]) and
          (i in [1..8]) and (j in [1..8])) then exit;

  fig:= chp.board[i0,j0];
  if ((chp.color = White) and (fig > ES)) or
     ((chp.color = Black) and (fig < ES)) then exit;

  f:= TFigureName(ord(fig) - ord(chp.color) * ord(BK));

  for l:= 1 to 8 do
    with DELTA_MOVE[f], chp do
      begin
        if (dx[l] = 0) and (dy[l] = 0) then break; // ��� ���� �����������
        ti:= i0; tj:= j0;
        case f of
          P:
            begin
              if (l = 1) and
                 not(((color = White) and (j0 = 2) and (board[i0,3] = ES)) or
                     ((color = Black) and (j0 = 7) and (board[i0,6] = ES)))
                then continue; // ����� - �� �� 2/7 ���. - �� ������ ������� ���.
              case color of
                White:
                  begin
                    ti:= ti + dx[l]; tj:= tj + dy[l];
                  end;
                Black:
                  begin
                    ti:= ti - dx[l]; tj:= tj - dy[l];
                  end;
              end;
              if not(ti in [1..8]) or not(tj in [1..8]) then continue;
              if (l <= 2) and (board[ti,tj] <> ES)
                then continue; // ����� ������ ������ - �����
              if (l >= 3) and not(((color = White) and ((board[ti,tj] > ES) or
                                   ((j0 = 5) and (en_passant = ti)))) or
                                  ((color = Black) and ((board[ti,tj] < ES) or
                                   ((j0 = 4) and (en_passant = ti)))))
                then continue;
              if (ti = i) and (tj = j) then goto here;
            end;
          else
            repeat
              ti:= ti + dx[l]; tj:= tj + dy[l];
              if not(ti in [1..8]) or not(tj in [1..8]) or
                 ((color = White) and ((board[ti,tj] < ES) or
                  ((board[ti,tj] > ES) and ((ti <> i) or (tj <> j))))) or
                 ((color = Black) and ((board[ti,tj] > ES) or
                  ((board[ti,tj] < ES) and ((ti <> i) or (tj <> j)))))
                then break;
              if (ti = i) and (tj = j) then goto here;
            until not longRange;
        end; { case }
      end;

      if f = K then // �������� �� ����������� ���������
        with chp do
          begin
            if (i-i0 = 2) and (j = j0) and
               (((color = White) and (WhiteKingSide in castling)) or
                ((color = Black) and (BlackKingSide in castling)))
              then
                begin
                  if (board[6,j0] <> ES) or (board[7,j0] <> ES) or // 0-0
                     FieldUnderAttack(chp,5,j0) or
                     FieldUnderAttack(chp,6,j0)
                    then exit;
                end
              else
            if (i-i0 = -2) and (j = j0) and
               (((color = White) and (WhiteQueenSide in castling)) or
                ((color = Black) and (BlackQueenSide in castling)))
              then
                begin
                  if (board[4,j0] <> ES) or (board[3,j0] <> ES) or // 0-0-0
                     (board[2,j0] <> ES) or
                     FieldUnderAttack(chp,5,j0) or
                     FieldUnderAttack(chp,4,j0)
                    then exit;
                end
              else exit;
            goto here;
          end;
      exit; // ������������ ������ �� �� ��������
here:
  // ���������� ���� �� pos
  pos:= chp;
  with pos do
    begin
      case f of
        P:
          begin
            if (((color = White) and (j0 = 5)) or
                ((color = Black) and (j0 = 4))) and (i = en_passant)
              then board[i,j0]:= ES; // ������ ��� e.p. ����. �����
          end;
        K:
          begin
            if i-i0 = 2 then
              begin
                board[6,j0]:= board[8,j0]; // 0-0
                board[8,j0]:= ES;
              end
            else
            if i0-i = 2 then
              begin
                board[4,j0]:= board[1,j0]; // 0-0-0
                board[1,j0]:= ES;
              end;
            case color of
              White:
                castling:= castling - [WhiteKingSide, WhiteQueenSide];
              Black:
                castling:= castling - [BlackKingSide, BlackQueenSide];
            end;
          end;
        R:
          begin
            if ((i0 = 8) and (j0 = 1)) or ((i = 8) and (j = 1))
              then castling:= castling - [WhiteKingSide]
            else
            if ((i0 = 1) and (j0 = 1)) or ((i = 1) and (j = 1))
              then castling:= castling - [WhiteQueenSide]
            else
            if ((i0 = 8) and (j0 = 8)) or ((i = 8) and (j = 8))
              then castling:= castling - [BlackKingSide]
            else
            if ((i0 = 1) and (j0 = 8)) or ((i = 1) and (j = 8))
              then castling:= castling - [BlackQueenSide];
          end;
      end;
      if (f = P) and (abs(j-j0) = 2) and
         (((i > 1) and (((color = White) and (board[i-1,j] = BP)) or
                        ((color = Black) and (board[i-1,j] = WP)))) or
          ((i < 8) and (((color = White) and (board[i+1,j] = BP)) or
                        ((color = Black) and (board[i+1,j] = WP))))) then
        en_passant := i0 // ���. e.p.
      else
        en_passant := 0; // ����. e.p.
      // ������� ���
      board[i0,j0]:= ES; board[i,j]:= fig;
      if CheckCheck(pos) then exit; // ��� ���������� ��-�� ����
      if (f = P) and ((j = 1) or (j = 8)) then
        begin
          case prom_fig of
            Q..N: ;
            else
              begin
                if Showing then
                  begin
                    PromotionForm := TPromotionForm.Create(self);
                    prom_fig := PromotionForm.ShowPromotion(pos.color);
                    PromotionForm.Free;
                  end
                else
                  prom_fig := Q;
              end;
          end;
          board[i,j]:= TFigure(ord(color) * ord(BK) + ord(prom_fig));
        end;
      if color = White then color:= Black
        else color:= White;
    end;

  chp_res:= pos;
  Result:= TRUE;
end;


function TChessBoard.CanMove(pos: TChessPosition): boolean;
var
  i,j: integer;
  ti,tj: integer;
  l: byte;
  f: TFigureName;
  prom_fig: TFigureName;
begin
  with pos do
    for i:= 1 to 8 do
      for j:= 1 to 8 do
        begin
          if ((color = White) and (board[i,j] >= ES)) or
             ((color = Black) and (board[i,j] <= ES)) then continue;

          f:= TFigureName(ord(board[i,j]) - ord(color) * ord(BK));
          for l:= 1 to 8 do
            with DELTA_MOVE[f] do
              begin
                if (dx[l] = 0) and (dy[l] = 0) then break; // ��� ���� �����������
                ti:= i; tj:= j;
                repeat
                  case color of
                    White:
                      begin
                        ti:= ti + dx[l]; tj:= tj + dy[l];
                      end;
                    Black:
                      begin
                        ti:= ti - dx[l]; tj:= tj - dy[l];
                      end;
                  end;
                  if not ((ti in [1..8]) and (tj in [1..8])) then break;
                  prom_fig := Q;
                  if CheckMove(pos,pos, i,j,ti,tj, prom_fig) then
                    begin
                      Result:= TRUE;
                      exit;
                    end;
                until not longRange;
              end;
        end;
  Result:= FALSE;
end;


procedure TChessBoard.ShowTime(const c: TFigureColor);
var
  time_label: TLabel;
begin
  if c = White then time_label:= WhiteTimeLabel
    else time_label:= BlackTimeLabel;

  if unlimited_var[c] then
    begin
      time_label.Caption:= '';
      exit;
    end;

  time_label.Font.Color:= TIME_COLOR;

  LongTimeFormat:= MIN_TIME_FORMAT;
  if player_time[c] >= EncodeTime(1, 0, 0, 0) then
    LongTimeFormat:= HOUR_TIME_FORMAT
  else
    if (player_time[c] < EncodeTime(0, 0, ZEITNOT_BOARDER, 0)) and
       (player_time[c] > 0) then
      begin
        LongTimeFormat:= ZEITNOT_FORMAT;
        time_label.Font.Color:= ZEITNOT_COLOR;
      end;

  time_label.Caption:= TimeToStr(player_time[c]);
end;



procedure TChessBoard.SetFlipped(const f: boolean);
begin
  // TODO:
  _flipped:= f;
  DrawBoard;
end;


function TChessBoard.SetPosition(const posstr: string): boolean;
var
  i,j,k: integer;
  l: byte;
  pos: TChessPosition;
begin
  Result:= FALSE;
  l:= 1;
  for j:= 8 downto 1 do
    begin
      i:= 1;
      repeat
        case posstr[l] of
          'K': pos.board[i,j]:= WK;
          'Q': pos.board[i,j]:= WQ;
          'R': pos.board[i,j]:= WR;
          'B': pos.board[i,j]:= WB;
          'N': pos.board[i,j]:= WN;
          'P': pos.board[i,j]:= WP;

          'k': pos.board[i,j]:= BK;
          'q': pos.board[i,j]:= BQ;
          'r': pos.board[i,j]:= BR;
          'b': pos.board[i,j]:= BB;
          'n': pos.board[i,j]:= BN;
          'p': pos.board[i,j]:= BP;

          '1'..'8':      // ������� ������ �����
            begin
              k:= StrToInt(posstr[l]);
              repeat
                pos.board[i,j]:= ES;
                dec(k); inc(i);
              until k = 0;
              dec(i);
            end;

          ' ': break;  // ������� ��������� - ����� �� �����

          else exit; // ������ � posstr
        end;
        inc(i); inc(l);
      until (posstr[l] = '/') or (i > 8); // ������ �� ��������� '/' ��� ���� �� �����������
      inc(l);
    end;

  case posstr[l] of
    'w': pos.color:= White;
    'b': pos.color:= Black;
    else exit;
  end;

  inc(l,2);
  pos.castling:= [];
  while posstr[l] <> ' ' do
    begin
      with pos do
        case posstr[l] of
          'K': castling:= castling + [WhiteKingSide];
          'Q': castling:= castling + [WhiteQueenSide];
          'k': castling:= castling + [BlackKingSide];
          'q': castling:= castling + [BlackQueenSide];
          '-':
            if castling <> [] then exit
              else
                begin
                  inc(l);
                  break;
                end;
          else exit;
        end;
      inc(l);
    end;

  inc(l);
  with pos do
    case posstr[l] of
      'a'..'h': en_passant:= ord(posstr[l]) - ord('a') + 1;
      '-': en_passant:= 0;
      else exit;
    end;

  if Trim(RightStr(posstr, length(posstr) - l)) <> '' then exit;

  CancelAnimationDragging;
  SetPositionRec(pos);
  clock_color:= Position.color;
  lastMove.i0:= 0; // ����������� ���� ��� �� ����
  Result:= TRUE;
  DrawBoard;
end;


function TChessBoard.GetPosition: string;
var
  i,j: Integer;
  k: byte;
  fig: char;
begin
  Result:= '';

  with Position do
    begin
      // ����������� �����
      for j:= 8 downto 1 do
        begin
          k:= 0;
          for i:= 1 to 8 do
            begin
              case board[i,j] of
                WK: fig:= 'K';
                WQ: fig:= 'Q';
                WR: fig:= 'R';
                WB: fig:= 'B';
                WN: fig:= 'N';
                WP: fig:= 'P';
                BK: fig:= 'k';
                BQ: fig:= 'q';
                BR: fig:= 'r';
                BB: fig:= 'b';
                BN: fig:= 'n';
                BP: fig:= 'p';
                ES:
                  begin
                    inc(k);
                    continue;
                  end;
              end;

              if k > 0 then
                begin
                  Result:= Result + IntToStr(k);
                  k:= 0;
                end;

              Result:= Result + fig;
            end;

          if k > 0 then Result:= Result + IntToStr(k);
          if j = 1 then Result:= Result + ' '
            else Result:= Result + '/'; // i <= 7
        end;

        if color = White then Result:= Result + 'w '
          else Result:= Result + 'b '; // color = Black
        // ���������
        if castling = [] then Result:= Result + '-'
          else
            begin
              if WhiteKingSide in castling then Result:= Result + 'K';
              if WhiteQueenSide in castling then Result:= Result + 'Q';
              if BlackKingSide in castling then Result:= Result + 'k';
              if BlackQueenSide in castling then Result:= Result + 'q';
            end;
        // en-passant
        if en_passant = 0 then Result:= Result + ' -'
          else Result:= Result + ' ' + Chr(Ord('a')-1 + en_passant);
    end;
end;


function TChessBoard.GetPositionRec: TChessPosition;
begin
  Result := Position;
end;


function TChessBoard.GetLastMoveAbs: TMoveAbs;
begin
  Result.i0 := lastMove.i0;
  Result.j0 := lastMove.j0;
  Result.i := lastMove.i;
  Result.j := lastMove.j;
  Result.prom_fig := lastMove.prom_fig;
end;


procedure TChessBoard.FormCreate(Sender: TObject);
var
  fig: TFigure;
begin
  if CHESS_BOARD_INSTANCES = 0 then
    begin
      bmChessBoard := TBitMap.Create;
      bmChessBoard.LoadFromResourceName(HInstance, 'BOARD');
      for fig:= low(fig) to high(fig) do
        begin
          bmFigure[fig] := TBitMap.Create;
          bmFigure[fig].LoadFromResourceName(HInstance, RES_NAME[fig]);
          bmFigure[fig].Transparent:= TRUE;
        end;
      BlackFlagButton.Glyph := WhiteFlagButton.Glyph; // ���� �� ������ ������� 
      coord_show:= TRUE; last_hilight:= FALSE; animation:= aQuick;
    end;
  inc(CHESS_BOARD_INSTANCES);

  // ������������� �������
  bmHiddenBoard:= TBitMap.Create;
  with bmHiddenBoard do
    begin
      Palette:= bmChessBoard.Palette;
      Canvas.Font:= PBoxBoard.Font; // �������������� ������ ��������� �������� � ����������
      Canvas.Brush.Style:= bsClear;
      Width:= bmChessBoard.Width;
      Height:= bmChessBoard.Height;
    end;

  bmBuf:= TBitMap.Create; bmBuf.Palette:= bmChessBoard.Palette;

  // ������������� �����
  SetUnlimited(White, TRUE); SetUnlimited(Black, TRUE);

  // ������������� ������ �������
  lstPosition := TList.Create;

  InitPosition;
end;


procedure TChessBoard.DrawHiddenBoard;
var
  i,j,x,y: integer;
begin
  with bmHiddenBoard do // ���������� ������ ����� �� �������
    begin
      Canvas.CopyRect(Bounds(0,0, Width,Height), bmChessBoard.Canvas, Bounds(0,0, Width,Height));
      Canvas.Brush.Color := self.Color;
      Canvas.FloodFill(0,0, Canvas.Pixels[0,0], fsSurface);
    end;

  if coord_show then
    with bmHiddenBoard, bmHiddenBoard.Canvas do
      begin
        x:= CHB_X + SQUARE_SIZE div 2;
        y:= (bmHiddenBoard.Height + CHB_Y + 8 * SQUARE_SIZE + CHB_WIDTH) div 2;
        if _flipped then j := ord('h')
          else j:= ord('a');
        for i:= 1 to 8 do // �����
          begin
            TextOut(x - TextWidth(chr(j)) div 2,
                    y + 1 - TextHeight(chr(j)) div 2 , chr(j));
            x := x + SQUARE_SIZE;
            if _flipped then dec(j)
              else inc(j);
          end;
        x:= (CHB_X - CHB_WIDTH) div 2;
        y:= CHB_Y + SQUARE_SIZE div 2;
        if _flipped then j:= ord('1')
          else j := ord('8');
        for i := 1 to 8 do // �����
          begin
            TextOut(x - TextWidth(chr(j)) div 2,
                    y - TextHeight(chr(j)) div 2, chr(j));
            y:= y + SQUARE_SIZE;
            if _flipped then inc(j)
              else dec(j);
          end;
    end;

  for i:= 1 to 8 do
    for j:= 1 to 8 do
      begin
        if Position.board[i,j] = ES then continue; // ������ �� ��������
        if not _flipped then // ��������� ������ ������ �� ������� � ����������
          bmHiddenBoard.Canvas.Draw(CHB_X + SQUARE_SIZE * (i-1),
                                    CHB_Y + SQUARE_SIZE * (8-j),
                                    bmFigure[Position.board[i,j]])

          else // ׸���� �����
            bmHiddenBoard.Canvas.Draw(CHB_X + SQUARE_SIZE * (8-i),
                                      CHB_Y + SQUARE_SIZE * (j-1),
                                      bmFigure[Position.board[i,j]]);
      end;
end;


procedure TChessBoard.DrawBoard;
begin
  DrawHiddenBoard;
  PBoxBoardPaint(nil);
end;


procedure TChessBoard.PBoxBoardPaint(Sender: TObject);
begin
  PBoxBoard.Canvas.Draw(0,0, bmHiddenBoard); // ����� ������� ����� �� �����
end;


constructor TChessBoard.Create(Owner: TComponent; h: TChessBoardHandler);
begin
  inherited Create(Owner);
  Handler:= h;
end;


procedure TChessBoard.FormDestroy(Sender: TObject);
var
  fig: TFigure;
  i: integer;
begin
  for i := 0 to lstPosition.Count - 1 do
    dispose(lstPosition[i]);
  lstPosition.Free;
  bmHiddenBoard.Free;
  bmBuf.Free;

  dec(CHESS_BOARD_INSTANCES);
  if CHESS_BOARD_INSTANCES = 0 then
    begin
      for fig:= low(fig) to high(fig) do bmFigure[fig].Free;
      bmChessBoard.Free;
    end;
end;

procedure TChessBoard.PBoxBoardDragDrop(Sender, Source: TObject; X,
  Y: Integer);
var
  i,j: Integer;
begin
  WhatSquare(Point(X,Y), i, j);
  case Mode of
    mGame:
      if DoMove(i,j) then
        begin
          SwitchClock(PositionColor);
          dragged_moved:= TRUE;
        end;
    mEdit:
      begin
        Position.board[i0,j0]:= ES; Position.board[i,j]:= fig;
      end;
  end;
end;


procedure TChessBoard.PBoxBoardDragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
var
  rect: TRect;
  i,j: Integer;
begin
  case State of
    dsDragEnter:
      hilighted:= FALSE;
    dsDragMove:
      begin
        // ������������ �������� �� bmHiddenBoard
        bmHiddenBoard.Canvas.Draw(x0-dx, y0-dy, bmBuf);
        // ���������� ����� �������� � �����
        bmBuf.Canvas.CopyRect(Bounds(0, 0, SQUARE_SIZE, SQUARE_SIZE),
          bmHiddenBoard.Canvas, Bounds(X-dx, Y-dy, SQUARE_SIZE, SQUARE_SIZE));
        // ���������� ��������������� ������ � ����� �������
        bmHiddenBoard.Canvas.Draw(X-dx, Y-dy, bmFigure[fig]);
        // ��������� ����� �������� �� �����
        rect:= Bounds(Min(x0,X) - dx, Min(y0,Y) - dy,
          abs(X-x0) + SQUARE_SIZE, abs(Y-y0) + SQUARE_SIZE);
        PBoxBoard.Canvas.CopyRect(rect, bmHiddenBoard.Canvas, rect);

        x0:= X; y0:= Y;

        WhatSquare(Point(X,Y), i,j);
        if (i in [1..8]) and (j in [1..8]) then Accept:= TRUE
          else Accept:= FALSE;
      end;
  end;
end;

procedure TChessBoard.PBoxBoardEndDrag(Sender, Target: TObject; X,
  Y: Integer);
begin
  if hilighted then
    with bmHiddenBoard.Canvas do
      begin
        Pen.Color:= HILIGHT_COLOR;
        Pen.Width := HILIGHT_WIDTH;
        x0:= x0 - dx;
        y0:= y0 - dy;
        MoveTo(x0,y0);
        LineTo(x0 + SQUARE_SIZE - 1, y0);
        LineTo(x0 + SQUARE_SIZE - 1, y0 + SQUARE_SIZE - 1);
        LineTo(x0, y0 + SQUARE_SIZE - 1);
        LineTo(x0,y0);

        PBoxBoardPaint(nil);
      end
  else
    begin
      DrawBoard;
      if dragged_moved then
        begin
          HilightLastMove;
          Evaluate;
          dragged_moved:= FALSE;
        end;
    end;
end;


procedure TChessBoard.WhatSquare(const P: TPoint;
                                     var i: Integer; var j: Integer);
  begin
    with P do
      begin
        i:= (X - CHB_X + SQUARE_SIZE) div SQUARE_SIZE;
        j:= 8 - (Y - CHB_Y) div SQUARE_SIZE;
        if _flipped then
          begin
            i:= 9-i; j:= 9-j;
          end;
    end;
  end;


procedure TChessBoard.PBoxBoardMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  i,j: Integer;
  f: TFigure;
begin
  WhatSquare(Point(X,Y), i,j);
  if not (i in [1..8]) or not (j in [1..8]) then exit;
  f:= Position.board[i,j];
  case Mode of
    mGame:
      if (Button <> mbLeft) or (Position.color <> player_color) or
         (((Position.color <> White) or (f >= ES)) and
          ((Position.color <> Black) or (f <= ES))) then exit;
    else exit;
  end;

  if anim_step < anim_step_num then
    begin
      anim_step:= anim_step_num;
      AnimateTimerTimer(nil);
    end;

  if (i = i0) and (j = j0) then hilighted:= hilighted xor TRUE
    else hilighted:= TRUE;

  fig:= f;
  i0:= i; j0:= j;

  dx:= (X - CHB_X) mod SQUARE_SIZE;
  dy:= (Y - CHB_Y) mod SQUARE_SIZE;
  x0:= X; y0:= Y;

  dragged_moved:= TRUE;
  PBoxBoard.BeginDrag(FALSE);
end;


procedure TChessBoard.PBoxBoardMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  f: TFigure;
  i,j: Integer;
begin
  WhatSquare(Point(X,Y), i,j);
  if not ((i in [1..8]) and (j in [1..8])) then
    begin
      PBoxBoard.Cursor:= crDefault;
      exit;
    end;
  f:= Position.board[i,j];
  case Mode of
    mGame:
      if (player_color = Position.color) and
         (((Position.color = White) and (f < ES)) or
          ((Position.color = Black) and (f > ES))) then
        PBoxBoard.Cursor:= crHandPoint
      else
        PBoxBoard.Cursor:= crDefault;

    else
      PBoxBoard.Cursor:= crDefault;
  end;
end;


function TChessBoard.DoMove(i,j: integer; prom_fig: TFigureName = K): boolean;
var
  m: string;
  newPosition: TChessPosition;
begin
  Result:= CheckMove(Position, newPosition, i0,j0,i,j, prom_fig);
  if not Result then exit;
  // ����������� ���������� ����
  lastMove.i0:= i0; lastMove.j0:= j0;
  lastMove.i:= i; lastMove.j:= j;
  lastMove.prom_fig := prom_fig;

  AddPosMoveToList;

  m := Move2Str(newPosition);
  Position := newPosition;

  if Assigned(Handler) and
     ((Mode = mGame) and (Position.color <> player_color)) then Handler(cbeMoved, @m, self);
end;


function TChessBoard.DoMove(move_str: string): boolean;
label
  l1, l2;
var
  l: byte;
  f, prom_f: TFigureName;
  i,j, ti,tj: integer;
begin
  // ������ ��������
  if AnimateTimer.Enabled then
    begin
      AnimateTimer.Enabled := FALSE;
      anim_step := anim_step_num;
      AnimateTimerTimer(nil);
    end;
  // �������� �� ���������
  if move_str = '0-0' then
    if Position.color = White then move_str:= 'Ke1g1'
      else move_str:= 'Ke8g8'
  else
    if move_str = '0-0-0' then
      if Position.color = White then move_str:= 'Ke1c1'
        else move_str:= 'Ke8c8';

  i0 := 0; j0 := 0; i := 0; j := 0;

  l:= length(move_str);
  prom_f := K;
  case move_str[l] of
    'Q': prom_f := Q;
    'R': prom_f := R;
    'B': prom_f := B;
    'N': prom_f := N;
    else goto l1;
  end;
  dec(l);
l1:
  if move_str[l] in ['1'..'8'] then
    begin
      j:= StrToInt(move_str[l]);
      dec(l);
    end;
  if move_str[l] in ['a'..'h'] then
    begin
      i:= ord(move_str[l]) - ord('a') + 1;
      dec(l);
    end;
  if (l > 0) and (move_str[l] in ['1'..'8']) then
    begin
      j0:= StrToInt(move_str[l]);
      dec(l);
    end;
  if (l > 0) and (move_str[l] in ['a'..'h']) then
    begin
      i0:= ord(move_str[l]) - ord('a') + 1;
      dec(l);
    end;

  if l = 0 then f:= P
    else
      case move_str[l] of
        'K': f:= K;
        'Q': f:= Q;
        'R': f:= R;
        'B': f:= B;
        'N': f:= N;
      end;

  with Position do
    begin
      fig:= TFigure(ord(f) + ord(Position.color) * ord(BK));

      case f of
        K..N: // ��� �� - �
          begin
            for l:= 1 to 8 do
              with DELTA_MOVE[f] do
                begin
                  if (dx[l] = 0) and (dy[l] = 0) then break; // ��� ���� �����������
                  ti:= i; tj:= j;
                  repeat
                    ti:= ti + dx[l]; tj:= tj + dy[l];
                    if not ((ti in [1..8]) and (tj in [1..8])) or
                       ((board[ti,tj] <> ES) and (board[ti,tj] <> fig)) then break;

                    if ((i0 = 0) or (i0 = ti)) and ((j0 = 0) or (j0 = tj)) and
                       (board[ti,tj] = fig) then
                      begin // ������� ������ �������
                        i0:= ti; j0:= tj;
                        goto l2;
                      end;
                  until (f = K) or (f = N); // ���� �� ��� �, �� �����
                end;
          end;
        P:    // ��� ������
          begin
            if (i0 <> 0) and (i0 <> i) then // ������ ������
              begin
                for l:= 2 to 7 do
                  if (board[i0,l] = fig) and ((j0 = 0) or (j0 = l)) then
                    if color = White then
                      begin
                        if ((board[i,l+1] > ES) or
                            ((l = 5) and (en_passant = i))) and
                           ((j = 0) or (j = l+1)) and (abs(i-i0) = 1) then
                          begin
                            j0:= l; j:= l+1;
                            goto l2;
                          end;
                      end
                    else // color = Black
                      if ((board[i,l-1] < ES) or
                          ((l = 4) and (en_passant = i))) and
                         ((j = 0) or (j = l-1)) and (abs(i-i0) = 1) then
                        begin
                          j0:= l; j:= l-1;
                          goto l2;
                        end;
              end
            else  // ��� �����
              begin
                i0:= i;
                if color = White then
                  begin
                    if board[i,j-1] = fig then j0:= j-1
                      else
                        if (j = 4) and (board[i,3] = ES) and
                           (board[i,2] = fig) then j0:= 2;
                  end
                else // color = Black
                  if board[i,j+1] = fig then j0:= j+1
                    else
                      if (j = 5) and (board[i,6] = ES) and
                         (board[i,7] = fig) then j0:= 7;
              end;
          end;
      end;
    end;
l2:
  Result := DoMove(i,j,prom_f);
  if Result then
    begin
      Animate(i,j);
      SwitchClock(PositionColor);
    end;
end;


procedure TChessBoard.PBoxBoardMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  i,j: integer;
begin
  case Button of
    mbLeft:
      case Mode of
        mGame:
          begin
            if not hilighted then exit;
            WhatSquare(Point(X,Y), i,j);
            if dragged_moved then DrawBoard
              else
                begin
                  hilighted:= FALSE;
                  if DoMove(i,j) then
                    begin
                      Animate(i,j);
                      SwitchClock(PositionColor);
                    end
                  else
                    DrawBoard;
                end;
          end;
        mEdit: ;
      end;
    mbRight:
      if Assigned(Handler) then Handler(cbeMenu, self);
  end;
end;

procedure TChessBoard.PBoxBoardStartDrag(Sender: TObject;
  var DragObject: TDragObject);
begin
  // ���������� ����������� ������� ���� � bmBuf
  bmBuf.Width:= SQUARE_SIZE; bmBuf.Height:= SQUARE_SIZE;
  if ((i0 + j0) and 1) = 0
    then
      bmBuf.Canvas.CopyRect(Bounds(0,0, SQUARE_SIZE, SQUARE_SIZE),
        bmFigure[ES].Canvas, Bounds(0,0, SQUARE_SIZE, SQUARE_SIZE))
  else
    bmBuf.Canvas.CopyRect(Bounds(0,0, SQUARE_SIZE, SQUARE_SIZE),
      bmFigure[ES].Canvas, Bounds(SQUARE_SIZE,0, SQUARE_SIZE, SQUARE_SIZE));

  dragged_moved:= FALSE;
end;


procedure TChessBoard.Animate(const i,j: integer);
var
  x,y: integer;
begin
  if not Showing then exit;

  case animation of
    aNo: anim_step_num:= 1;
    aSlow: anim_step_num:= ANIMATION_SLOW;
    aQuick: anim_step_num:= ANIMATION_QUICK;
  end;

  if _flipped then
    begin
      x0:= (8 - i0) * SQUARE_SIZE + CHB_X;
      y0:= (j0 - 1) * SQUARE_SIZE + CHB_Y;
      x:= (8 - i) * SQUARE_SIZE + CHB_X;
      y:= (j - 1) * SQUARE_SIZE + CHB_Y;
    end
  else
    begin
      x0:= (i0 - 1) * SQUARE_SIZE + CHB_X;
      y0:= (8 - j0) * SQUARE_SIZE + CHB_Y;
      x:= (i - 1) * SQUARE_SIZE + CHB_X;
      y:= (8 - j) * SQUARE_SIZE + CHB_Y;
    end;

  anim_dx:= (x-x0) / anim_step_num;
  anim_dy:= (y-y0) / anim_step_num;

  anim_step:= 0;

  // ���������� ����������� ������� ���� � bmBuf
  bmBuf.Width := SQUARE_SIZE;
  bmBuf.Height := SQUARE_SIZE;
  if ((i0 + j0) and 1) = 0
    then
      bmBuf.Canvas.CopyRect(Bounds(0,0, SQUARE_SIZE, SQUARE_SIZE),
        bmFigure[ES].Canvas, Bounds(0,0, SQUARE_SIZE, SQUARE_SIZE))
  else
    bmBuf.Canvas.CopyRect(Bounds(0,0, SQUARE_SIZE, SQUARE_SIZE),
      bmFigure[ES].Canvas, Bounds(SQUARE_SIZE,0, SQUARE_SIZE, SQUARE_SIZE));

  AnimateTimer.Enabled:= TRUE;
end;


procedure TChessBoard.AnimateTimerTimer(Sender: TObject);
var
  X,Y: integer;
  rect: TRect;
begin
  inc(anim_step);
  if anim_step < anim_step_num then
    begin
      X:= round(x0 + anim_dx * anim_step);
      Y:= round(y0 + anim_dy * anim_step);
      dx:= X - x0 - round(anim_dx * (anim_step - 1));
      dy:= Y - y0 - round(anim_dy * (anim_step - 1));

      // ������������ �������� �� bmHiddenBoard
      bmHiddenBoard.Canvas.Draw(X-dx, Y-dy, bmBuf);
      // ���������� ����� �������� � �����
      bmBuf.Canvas.CopyRect(Bounds(0, 0, SQUARE_SIZE, SQUARE_SIZE),
        bmHiddenBoard.Canvas, Bounds(X, Y, SQUARE_SIZE, SQUARE_SIZE));
      // ���������� ��������������� ������ � ����� �������
      bmHiddenBoard.Canvas.Draw(X, Y, bmFigure[fig]);
      // ��������� ����� �������� �� �����
      rect:= Bounds(Min(X-dx, X), Min(Y-dy, Y),
        abs(dx) + SQUARE_SIZE, abs(dy) + SQUARE_SIZE);
      PBoxBoard.Canvas.CopyRect(rect, bmHiddenBoard.Canvas, rect);
    end
  else
    begin
      AnimateTimer.Enabled := FALSE;
//    SwitchClock(PositionColor);
      DrawBoard;
      HilightLastMove;
      Evaluate;
    end;
end;


procedure TChessBoard.InitPosition;
begin
  case Mode of
    mGame, mView:
      begin
        SetPosition(INITIAL_CHESS_POSITION);
        ResetMoveList;
      end;
    mEdit:
      SetPosition(EMPTY_CHESS_POSITION);
  end;
  DrawBoard;
end;


procedure TChessBoard.SetMode(const m: TMode);
begin
  mode_var := m;
  DrawBoard; HilightLastMove;
  if mode_var <> mGame then
    begin
      WhiteFlagButton.Visible := FALSE;
      BlackFlagButton.Visible := FALSE;
    end;
end;


procedure TChessBoard.SetTime(color: TFigureColor; const tm: TDateTime);
begin
  if not Unlimited[color] then
    begin
      if not auto_flag then
        case color of
          White:
            WhiteFlagButton.Visible := ((player_color = Black) and (tm = 0.0));
          Black:
            BlackFlagButton.Visible := ((player_color = White) and (tm = 0.0));
        end;
      player_time[color]:= tm;
      ShowTime(color);
    end;
end;


function TChessBoard.GetTime(color: TFigureColor): TDateTime;
begin
  Result:= player_time[color];
end;


procedure TChessBoard.GameTimerTimer(Sender: TObject);
begin
  if unlimited_var[clock_color] then
    begin
      GameTimer.Enabled := FALSE;
      exit;
    end;
  // ToDo - �������� �� ���������
  player_time[clock_color] := player_time[clock_color] - (Now - past_time);
  if player_time[clock_color] <= 0.0 then
    begin
      player_time[clock_color] := 0.0;
      ShowTime(clock_color);
      if (not auto_flag) and (player_color <> clock_color) then
        case clock_color of
          White:
            WhiteFlagButton.Visible := TRUE;
          Black:
            BlackFlagButton.Visible := TRUE;
        end;
      if (player_color <> clock_color) and Assigned(Handler) and (Mode = mGame) and (auto_flag) then
        Handler(cbeTimeOut, self);
      GameTimer.Enabled := FALSE;
    end;
{$IFNDEF THREADED_CHESSCLOCK}
  ShowTime(clock_color);
{$ENDIF}

  past_time:= Now;
end;


procedure TChessBoard.SetUnlimited(color: TFigureColor; const unl: boolean);
begin
  unlimited_var[color]:= unl;
  ShowTime(color);
end;


function TChessBoard.GetUnlimited(color: TFigureColor): boolean;
begin
  Result:= unlimited_var[color];
end;


procedure TChessBoard.SwitchClock(clock_color: TFigureColor);
begin
  self.clock_color := clock_color;
  if not GameTimer.Enabled then
    begin
      past_time := Now;
      GameTimer.Enabled := TRUE;
    end;
  if Assigned(Handler) and (Mode = mGame) then
    Handler(cbeClockSwitched, self);
  ShowTime(clock_color);

{$IFDEF THREADED_CHESSCLOCK}
  if not Assigned(TimeLabelThread) then
    TimeLabelThread := TTimeLabelThread.Create(self);
{$ENDIF}
end;


procedure TChessBoard.HilightLastMove;
var
  i, j, l,
  i0, j0, x, y: integer;
begin
  // ����� ���������� ���������� ����
  if last_hilight  and (lastMove.i0 <> 0) and
     ((Mode = mGame) or (Mode = mView)) then
    begin
      if _flipped then
        begin
          i0:= 9 - lastMove.i0; j0:= lastMove.j0;
          i:= 9 - lastMove.i; j:= lastMove.j;
        end
      else
        begin
          i0:= lastMove.i0; j0:= 9 - lastMove.j0;
          i:= lastMove.i; j:= 9 - lastMove.j;
        end;

       x:= SQUARE_SIZE * (i0 - 1) + CHB_X;
       y:= SQUARE_SIZE * (j0 - 1) + CHB_Y;
       bmHiddenBoard.Canvas.Pen.Color := HILIGHT_LAST_MOVE_COLOR;
       bmHiddenBoard.Canvas.Pen.Width := HILIGHT_LAST_MOVE_WIDTH;

       for l:= 1 to 2 do
         with bmHiddenBoard.Canvas do
           begin
             MoveTo(x,y);
             LineTo(x + SQUARE_SIZE - 1, y);
             LineTo(x + SQUARE_SIZE - 1, y + SQUARE_SIZE - 1);
             LineTo(x,y + SQUARE_SIZE - 1);
             LineTo(x,y);

             x:= SQUARE_SIZE * (i - 1) + CHB_X;
             y:= SQUARE_SIZE * (j - 1) + CHB_Y;
           end;
      PBoxBoardPaint(nil);
    end;
end;


function TChessBoard.Move2Str(const pos: TChessPosition): string;
var
  f: TFigureName;
  l: byte;
  ti, tj: integer;
  ambig, hor, ver: boolean;
{
  est: TMoveEstimate;
label
  check;
}
begin
  if lastMove.i0 = 0 then // ��� �� �����
    begin
      Result:= '';
      exit;
    end;

  f:= TFigureName(ord(fig) + (ord(pos.color) - 1) * ord(BK));
  // ��� ������
  if f = P then
    with pos do
      begin
        if lastMove.i - lastMove.i0 = 0 then // ���
          Result:= chr(ord('a') + lastMove.i - 1) + IntToStr(lastMove.j)
        else // ������
          begin
            Result:= chr(ord('a') + lastMove.i0 - 1) + chr(ord('a') + lastMove.i - 1);

            for l := 2 to 7 do // �������� �� ��������������� ������
              if (((board[lastMove.i0, l] = WP)  and ((Position.board[lastMove.i, l+1] > ES) or
                  ((Position.en_passant = lastMove.i) and (l = 5)))) and (color = Black)) or
                 (((board[lastMove.i0, l] = BP)  and ((Position.board[lastMove.i, l-1] < ES) or
                  ((Position.en_passant = lastMove.i) and (l = 4)))) and (color = White))
                then Result:= Result + IntToStr(lastMove.j);
          end;

        if (lastMove.j = 8) or (lastMove.j = 1) then // ����� ������������
          case board[lastMove.i,lastMove.j] of
            WQ,BQ: Result:= Result + 'Q';
            WR,BR: Result:= Result + 'R';
            WB,BB: Result:= Result + 'B';
            WN,BN: Result:= Result + 'N';
          end;
        exit;
      end;
{
          goto check;
}
      // <������>
  case f of
    K: Result:= 'K';
    Q: Result:= 'Q';
    R: Result:= 'R';
    B: Result:= 'B';
    N: Result:= 'N';
  end;
  // [<���������>][<�����������>]
  ambig:= FALSE; hor:= FALSE; ver:= FALSE;
  for l:= 1 to 8 do
    with pos, DELTA_MOVE[f] do
      begin
        if (dx[l] = 0) and (dy[l] = 0) then break; // ��� ���� �����������
        ti:= lastMove.i; tj:= lastMove.j;
        repeat
          ti:= ti + dx[l]; tj:= tj + dy[l];
          if not (ti in [1..8]) or not (tj in [1..8]) or
             ((board[ti,tj] <> ES) and (board[ti,tj] <> fig)) then break;
          if (board[ti,tj] = fig) then
            begin
              ambig:= TRUE;
              ver:= ver or (ti = lastMove.i0); hor:= hor or (tj = lastMove.j0);
              break;
            end;
        until (f = K) or (f = N); // ���� �� ��� �, �� �����
      end;

  if ambig then
    begin
      if not ver or hor then Result:= Result + chr(ord('a') + lastMove.i0 - 1);
      if ver then Result:= Result + IntToStr(lastMove.j0);
    end;
{
  // <������>
  if taken then Result:= Result + ':';
}
  // <�������� ����>
  Result:= Result + chr(ord('a') + lastMove.i - 1) + IntToStr(lastMove.j);

  // <�������� ���������> | <������� ���������>
  if f = K then
    begin
      if lastMove.i - lastMove.i0 = 2 then Result:= '0-0'
        else
          if lastMove.i0 - lastMove.i = 2 then Result:= '0-0-0';
    end;
{
check: //<���>
        if CheckCheck(pos) then Result:= Result + '+';

  // <������>
      for est:= Low(est) to High(est) do
        if estimate = est then
          begin
            Result:= Result + MOVE_ESTIMATE[est];
            break
          end;
}
end;


procedure TChessBoard.Copy(cb: TChessBoard);
begin
  Position:= cb.Position;
  _flipped:= cb._flipped;

  lastMove.i0:= cb.lastMove.i0; lastMove.j0:= cb.lastMove.j0;
  lastMove.i:= cb.lastMove.i; lastMove.j:= cb.lastMove.j;
{
  player_nick:= cb.player_nick;
}
  player_color:= cb.player_color;

  player_time:= cb.player_time;
  clock_color:= cb.clock_color;
  unlimited_var:= cb.unlimited_var;

  mode_var:= cb.mode_var;

  Refresh;
end;


procedure TChessBoard.Refresh;
begin
  DrawBoard; HilightLastMove;
  ShowTime(White); ShowTime(Black);
end;


procedure TChessBoard.SetPlayerColor(const color: TFigureColor);
begin
  CancelAnimationDragging;
  player_color:= color;
  if player_color = White then SetFlipped(FALSE)
    else SetFlipped(TRUE); // player_color = Black
end;


procedure TChessBoard.StopClock;
begin
  GameTimer.Enabled := FALSE;
  WhiteFlagButton.Visible := FALSE;
  BlackFlagButton.Visible := FALSE;  
end;


procedure TChessBoard.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if not shuted and Assigned(Handler) then
    begin
      Handler(cbeExit, self);
      Action:= caNone;
    end
  else shuted:= FALSE;
end;


procedure TChessBoard.Shut;
begin
  shuted:= TRUE;
  Close;
end;


procedure TChessBoard.Evaluate;
begin
  if Assigned(Handler) and not CanMove(Position) then
     if CheckCheck(Position) then Handler(cbeMate, self)
       else Handler(cbeStaleMate, self);
  // TODO: ������ ������� �� ����������� ����������� �����
end;


procedure TChessBoard.PPRandom;
const
  FIG: array[0..5] of TFigureName = (B,B,Q,R,N,N);
  SQR: array[0..5] of byte = (2,3,4,6,7,0);
var
  rnd_sqr: array[0..5] of byte;
  i,j: integer;
  f: boolean;
begin
  InitPosition;
  If Random(2) = 0 then SQR[5] := 1 // � ����� ������� ��������� �����
    else SQR[5] := 8;
  for i := 0 to 5 do
    begin
      repeat
        rnd_sqr[i] := SQR[Random(6)];
        f := FALSE;
        for j := 0 to i-1 do f := f or (rnd_sqr[i] = rnd_sqr[j]);
      until not (f or ((i = 1) and (((rnd_sqr[0] xor rnd_sqr[1]) and 1) = 0)));
      Position.board[rnd_sqr[i], 1] := TFigure(ord(FIG[i]));
      Position.board[rnd_sqr[i], 8] := TFigure(ord(BK) + ord(FIG[i]));
    end;
  DrawBoard;
end;


procedure TChessBoard.TakeBack;
begin
  if lstPosition.Count = 0 then
    exit;
  SetPositionRec(PPosMove(lstPosition[lstPosition.Count - 1]).pos);
  DelPosList;
  // TODO: ��������
  DrawBoard;
end;


procedure TChessBoard.AddPosMoveToList;
var
  pm: PPosMove;
begin
  new(pm);
  pm.pos := GetPositionRec;
  pm.move := GetLastMoveAbs;
  lstPosition.Add(pm);
end;


procedure TChessBoard.DelPosList;
var
   i: integer;
begin
  i := lstPosition.Count - 1;
  if i >= 0 then
    begin
      dispose(lstPosition[i]);
      lstPosition.Delete(i);
    end;
end;


procedure TChessBoard.ResetMoveList;
var
  i: integer;
begin
  for i := 0 to lstPosition.Count - 1 do
    dispose(lstPosition[i]);
  lstPosition.Clear;
end;


procedure TChessBoard.SetHilightLastMove(const yes: boolean);
begin
  last_hilight := yes;
  DrawBoard; HilightLastMove;
end;


procedure TChessBoard.SetCoordinates(const yes: boolean);
begin
  coord_show := yes;
  DrawBoard; HilightLastMove;
end;


function TChessBoard.NMoveDone: integer;
begin
  Result := (lstPosition.Count + 1) shr 1; // div 2
end;


procedure TChessBoard.SetPositionRec(const pos: TChessPosition);
begin
  Position := pos;
end;


{$IFDEF THREADED_CHESSCLOCK}
procedure TTimeLabelThread.Execute;
begin
  while ChessBoard.GameTimer.Enabled do
    begin
      if self.player_time[White] <> ChessBoard.player_time[White] then
        ChessBoard.ShowTime(White);
      if self.player_time[Black] <> ChessBoard.player_time[Black] then
        ChessBoard.ShowTime(Black);
      Sleep(ChessBoard.GameTimer.Interval div 2);
    end;
  ChessBoard.TimeLabelThread := nil;  
end;


constructor TTimeLabelThread.Create(ChessBoard: TChessBoard);
begin
  self.ChessBoard := ChessBoard;
  self.player_time[White] := ChessBoard.player_time[White];
  self.player_time[Black] := ChessBoard.player_time[Black];

  inherited Create(TRUE);
//Priority := tpNormal;
  FreeOnTerminate := TRUE;
  Resume;
end;
{$ENDIF}

procedure TChessBoard.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Assigned(Handler) then
    Handler(cbeKeyPressed, Pointer(Key), self);
end;


function TChessBoard.GetStayOnTop: boolean;
begin
  Result := (self.FormStyle = fsStayOnTop);
end;


procedure TChessBoard.SetStayOnTop(onTop: boolean);
begin
  if onTop then
    self.FormStyle := fsStayOnTop
  else
    self.FormStyle := fsNormal;
end;


procedure TChessBoard.FormActivate(Sender: TObject);
begin
  if Assigned(Handler) then
    Handler(cbeActivate, self);
end;


procedure TChessBoard.FormMoving(var Msg: TWMMoving);
begin
  // TODO: �������� ��������� ������ ����� �� ������� ������.
  if Assigned(Handler) then
    Handler(cbeFormMoving, Pointer(Msg.DragRect.Left - Left), Pointer(Msg.DragRect.Top - Top));
  inherited;
end;


procedure TChessBoard.CancelAnimationDragging;
begin
  // ������ �������� � ��������������
  if AnimateTimer.Enabled then
    begin
      AnimateTimer.Enabled := FALSE;
      // anim_step := anim_step_num;
      // AnimateTimerTimer(nil);
    end;
  if PBoxBoard.Dragging then
    begin
      dragged_moved := FALSE;
      PBoxBoard.EndDrag(FALSE);
    end;

end;


procedure TChessBoard.FlagButtonClick(Sender: TObject);
begin
  if Assigned(Handler) and (Mode = mGame) then
    Handler(cbeTimeOut, self);
end;


procedure TChessBoard.SetAutoFlag(auto_flag: boolean);
begin
  self.auto_flag := auto_flag;
  if auto_flag then
    begin
      WhiteFlagButton.Visible := FALSE;
      BlackFlagButton.Visible := FALSE;
    end;
end;

initialization

begin
  Randomize; // ��� PP Random
end;

finalization

end.
