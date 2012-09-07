unit PGNTraverserUnit;

interface

uses
  ChessRulesEngine;

type
  IPGNTraverserVisitable = interface
    procedure Start;
    procedure DoPosMove(iPlyNumber: integer; const APosMove: TPosMove; const AResultingPos: TChessPosition);
    procedure StartLine(bFromPreviousPos: boolean);
    procedure EndLine;
    procedure Finish;
  end;

  TFigureColors = set of TFigureColor;
  
  TPGNTraverser = class
  private
    m_pInput: ^Text;
    m_Visitable: IPGNTraverserVisitable;

    m_strPlayerName: string;
    m_ProceedColors: TFigureColors;
    n_game: integer;
    n_pos: integer;
    m_ChessRulesEngine: TChessRulesEngine;
    m_bIncludeVariants: boolean;

    procedure FProceedGameStr(const strGame: string);
    procedure FDoStart;
    procedure FDoPosMove(iPlyNumber: integer; const APosMove: TPosMove; const AResultingPos: TChessPosition);
    procedure FDoStartLine(bFromPreviousPos: boolean);
    procedure FDoEndLine;
    procedure FDoFinish;
  public
    constructor Create(const APGNInput: Text; AVisitable: IPGNTraverserVisitable);
    destructor Destroy; override;
    procedure Traverse;
    property PlayerName: string read m_strPlayerName write m_strPlayerName;
    property ProceedColors: TFigureColors read m_ProceedColors write m_ProceedColors;
    property NumberOfGamesViewed: integer read n_game;
    property NumberofPositionsViewed: integer read n_pos;
    property IncludeVariants: boolean read m_bIncludeVariants write m_bIncludeVariants;
  end;

implementation

uses
  Contnrs, SysUtils, StrUtils;

////////////////////////////////////////////////////////////////////////////////
// TPGNTraverser

constructor TPGNTraverser.Create(const APGNInput: Text; AVisitable: IPGNTraverserVisitable);
begin
  inherited Create;
  m_pInput := @APGNInput;
  m_Visitable := AVisitable;

  m_ProceedColors := [fcWhite, fcBlack];

  m_ChessRulesEngine := TChessRulesEngine.Create;
end;


destructor TPGNTraverser.Destroy;
begin
  m_ChessRulesEngine.Free;

  m_Visitable := nil;
  inherited;
end;


procedure TPGNTraverser.Traverse;
var
  strLine, strGame: string;
  PlayerExists: boolean;
  ProceedColorsSaved: TFigureColors;
begin
  strGame := '';

  ProceedColorsSaved := m_ProceedColors;
  PlayerExists := (m_strPlayerName = '');
  repeat
    ReadLn(m_pInput^, strLine);

    if (strLine <> '') and ((strLine[1] <> '[') or (strLine[length(strLine)] <> ']')) then
    begin
      strGame := strGame + ' ' + strLine;
      if (not Eof(m_pInput^)) then
        continue;
    end;

    if (strGame <> '') then
    begin
      if ((m_ProceedColors <> []) and PlayerExists) then
        FProceedGameStr(strGame);

      strGame := '';
      m_ProceedColors := ProceedColorsSaved;
      PlayerExists := (m_strPlayerName = '');
    end;

    if (m_strPlayerName <> '') then
    begin
      if (strLine = ('[White "' + m_strPlayerName + '"]')) then
      begin
        m_ProceedColors := ProceedColorsSaved * [fcWhite];
        PlayerExists := TRUE;
      end
      else if (strLine = ('[Black "' + m_strPlayerName + '"]')) then
      begin
        m_ProceedColors := ProceedColorsSaved * [fcBlack];
        PlayerExists := TRUE;
      end;
    end;

  until Eof(m_pInput^);

end;


procedure TPGNTraverser.FProceedGameStr(const strGame: string);
var
  n_ply: integer;
  bkpMove: string;
  movePlyStack: TStack;
  lastInvalidMove: boolean;

  procedure NProceedInner(var str: string);

    function NCutOutComments(const s: string): boolean;
    var
      i: integer;
    begin
      Result := TRUE;

      str := s + ' ' + str;
      for i := 1 to length(str) do
      begin
        if (str[i] = '}') then
        begin
          str := RightStr(str, length(str) - i);
          exit;
        end;
//       writeln(' n_pos: ', n_pos);
      end;
      Assert(FALSE);

      Result := FALSE;
    end; // \NCutOutComments

    type
      PMovePly = ^TMovePly;
      TMovePly = record
        move: string;
        ply: integer;
      end;

    function NStartLine(const s: string): boolean;
    var
      n: integer;
      i: integer;
      movePly: PMovePly;
    begin
      Result := TRUE;

      if ((length(s) > 1) and (s[2] = '{')) then
      begin
        str := '( {' + str;
        exit;
      end;

      if (not m_bIncludeVariants) then
      begin
        n := 1;
        i := 1;
        repeat
          case str[i] of
            '{':
            begin
              repeat
                inc(i);
              until (i > length(str)) or (str[i] = '}');
            end;

            '(':
              inc(n);

            ')':
            begin
              dec(n);
              if (n = 0) then
              begin
                str := RightStr(str, length(str) - i);
                exit;
              end;
            end;

          end; { case }

          inc(i);

        until (i > length(str));

        Assert(FALSE);
      end; // if (not m_bIncludeVariants)

      New(movePly);
      movePly.move := bkpMove;
      movePly.ply := n_ply;

      if (not lastInvalidMove) then
      begin
        m_ChessRulesEngine.TakeBack;
        dec(n_ply);
      end
      else
        inc(movePly.ply);

      movePlyStack.Push(movePly);

      FDoStartLine(not lastInvalidMove);

      if (RightStr(s, length(s) - 1) = '') then
        exit;

      Result := FALSE;
    end; // \NStartLine

    function NextWord: string;
    var
      l : integer;
    begin
      str := TrimLeft(str);
      l := pos(' ', str);
      if (l = 0) then
      begin
        Result := str;
        str := '';
      end
      else
      begin
        Result := LeftStr(str, l - 1);
        str := RightStr(str, length(str) - l);
      end;
    end; // \NextWord

    procedure NTakeBackLine;
    var
      movePly: PMovePly;
    begin
      movePly := PMovePly(movePlyStack.Pop);

      while (movePly.ply <= n_ply) do
      begin
        m_ChessRulesEngine.TakeBack;
        dec(n_ply);
      end;

      if (m_ChessRulesEngine.DoMove(movePly.move)) then
        inc(n_ply)
      else
        lastInvalidMove := TRUE;

      FDoEndLine;

      bkpMove := movePly.move;

      movePly.move := '';
      Dispose(movePly);
    end; // \NTakeBackLine

  var
    s: string;
    i: integer;
    n: integer;
//    movePly: PMovePly;
    posMove: TPosMove;
//    p_posMove: PPosMove;
    bTakebackLineFlag: boolean;
  begin // \NProceedInner
    s := NextWord;
    if (s = '') or (s = '*') or (s = '1-0') or (s = '0-1') or (s = '1/2-1/2') then
      exit;

    if (s[1] = '{') then // Cuts out comments
    begin
      if (NCutOutComments(s)) then
        exit;
    end;

    if (s[1] = '(') then
    begin
      if (NStartLine(s)) then
        exit;
    end;

    if (s = ')') then
    begin
      bTakebackLineFlag := TRUE;
      s := '';
    end
    else
    begin
      bTakebackLineFlag := FALSE;
      while ((s <> '') and (s[length(s)] = ')')) do
      begin
        str := ') ' + str;
        s := LeftStr(s, length(s) - 1);
      end;
    end;

    for i := length(s) downto 1 do
    begin
      if (s[i] = '.') then
      begin
        str := RightStr(s, length(s) - i) + ' ' + str;
        s := LeftStr(s, i);
        break;
      end;
    end;

    if (RightStr(s, 2) = '..') then // 21... => 21.
      s := LeftStr(s, length(s) - 2);

    if (s <> '') and
       (not ((s[length(s)] = '.') and TryStrToInt(LeftStr(s, length(s) - 1), n) and
             (n = (n_ply shr 1) + 1))) and
       (s[1] <> '$') then
    begin
      s := StringReplace(s, 'O-O-O', '0-0-0', []);
      s := StringReplace(s, 'O-O', '0-0', []);
      s := StringReplace(s, 'x', '', []);
      s := StringReplace(s, '+', '', []);
      s := StringReplace(s, '#', '', []);
      s := StringReplace(s, '=', '', []);

      posMove.pos := m_ChessRulesEngine.Position^;
      if (m_ChessRulesEngine.DoMove(s)) then
      begin
        posMove.move := m_ChessRulesEngine.lastMove^;

        bkpMove := s;

        inc(n_ply);
        inc(n_pos);

        FDoPosMove(n_ply, posMove, m_ChessRulesEngine.Position^);

        lastInvalidMove := FALSE;

//        writeln(n_ply, 'p. ' + s + #9 + ChessBoard.GetPosition); // DEBUG:
      end
      else
      begin
//        writeln(s, ' n_pos: ', n_pos); // DEBUG:
        Assert(not lastInvalidMove);
        lastInvalidMove := TRUE;
      end; // if (ChessRulesEngine.DoMove(s))

      bkpMove := s;
    end; { if (s <> '') ...}

    if (bTakebackLineFlag) then
      NTakeBackLine;

  end; // \NProceedInner

var
  str: string;
  i: integer;
begin // .FProceedGameStr
  inc(n_game);

  m_ChessRulesEngine.InitNewGame;

  movePlyStack := TStack.Create;
  try
    FDoStart;

    n_ply := 0;
    bkpMove := '';
    lastInvalidMove := TRUE;

    str := strGame;
    repeat
      NProceedInner(str);
    until (str = '');

    FDoFinish;

    Assert(movePlyStack.Count = 0);

  finally
    movePlyStack.Free;
  end;

end;


procedure TPGNTraverser.FDoPosMove(iPlyNumber: integer; const APosMove: TPosMove;
  const AResultingPos: TChessPosition);
begin
  if (Assigned(m_Visitable)) then
    m_Visitable.DoPosMove(iPlyNumber, APosMove, AResultingPos);
end;


procedure TPGNTraverser.FDoStartLine(bFromPreviousPos: boolean);
begin
  if (Assigned(m_Visitable)) then
    m_Visitable.StartLine(bFromPreviousPos);
end;


procedure TPGNTraverser.FDoEndLine;
begin
  if (Assigned(m_Visitable)) then
    m_Visitable.EndLine;
end;


procedure TPGNTraverser.FDoStart;
begin
  if (Assigned(m_Visitable)) then
    m_Visitable.Start;
end;


procedure TPGNTraverser.FDoFinish;
begin
  if (Assigned(m_Visitable)) then
    m_Visitable.Finish;
end;

end.
