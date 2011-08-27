////////////////////////////////////////////////////////////////////////////////
// All code below is exclusively owned by author of Chess4Net - Pavel Perminov
// (packpaul@mail.ru, packpaul1@gmail.com).
// Any changes, modifications, borrowing and adaptation are a subject for
// explicit permition from the owner.

unit PosBaseChessBoardUnit;

interface

uses
  Classes, Graphics,
  //
  PosBaseUnit, ChessBoardHeaderUnit, ChessRulesEngine, ChessBoardUnit;

type
  TPosBaseChessBoard = class;

  TPosBaseChessBoardLayer = class(TChessBoardLayerBase)
  private
    m_PosBaseChessBoard: TPosBaseChessBoard;  
  protected
    procedure RDraw; override;
  public
    constructor Create(const APosBaseChessBoard: TPosBaseChessBoard);
  end;

  TGameResult = (grWin, grWinTime, grDraw, grLost, grLostTime);

  // Extension of TChessBoard with Position DB
  TPosBaseChessBoard = class(TChessBoard)
  private
    m_bUseUserBase: boolean;
    _lstMovePrior: TList;
    m_PosBase, m_ExtPosBase: TPosBase;
    m_bTrainingMode: boolean;
    m_strPosBaseName, m_strExtPosBaseName: string;
    m_Layer: TPosBaseChessBoardLayer;

    procedure FSetTrainingMode(bEnabled: boolean);
    procedure FUseUserBase(bUseUserBase: boolean);
    procedure FReadFromBase;
    procedure FWriteGameToBase;
    procedure FClearMovePriorList;
    procedure FDrawHiddenBoard(ACanvas: TCanvas; iSquareSize: integer);

  protected
    procedure ROnAfterMoveDone; override;
    procedure ROnAfterSetPosition; override;

    procedure RSetMode(const Value: TMode); override;

  public
    constructor Create(voOwner: TComponent; vfHandler: TChessBoardHandler;
      const strPosBaseName: string = '');
    destructor Destroy; override;
    procedure WriteGameToBase(AGameResult: TGameResult);
    procedure SetExternalBase(const strExtPosBaseName: string);
    procedure UnsetExternalBase;
    procedure ResetMoveList; override;
    property pTrainingMode: boolean read m_bTrainingMode write FSetTrainingMode;
    property pUseUserBase: boolean read m_bUseUserBase write FUseUserBase;
    procedure PPRandom; reintroduce;
  end;

implementation

uses
  SysUtils;

type
  TPrior = (mpNo, mpHigh, mpMid, mpLow);

  PMovePrior = ^TMovePrior;
  TMovePrior = record
    move: TMoveAbs;
    prior: TPrior;
  end;

  TPosBaseOperator = class(TThread)
  private
    _enuOperation: (opRead, opWrite);
    _oChessBoard: TPosBaseChessBoard;
    constructor FCreateRead(voChessBoard: TPosBaseChessBoard;
      vbHidden: boolean; vbFreeOnTerminate: boolean = TRUE);
    constructor FCreateWrite(voChessBoard: TPosBaseChessBoard);
  protected
    procedure Execute; override;
  public
    class function CreateRead(voChessBoard: TPosBaseChessBoard;
      vbHidden: boolean; vbFreeOnTerminate: boolean = TRUE): TPosBaseOperator;
    class function CreateWrite(voChessBoard: TPosBaseChessBoard): TPosBaseOperator;
    procedure WaitFor;
  end;

var
  gameResult: TGameResult; // Not threadsafe
  gameID: word; // It's used for writing unique positions (not threadsafe)

const
  NUM_PRIORITIES = 3; // Maximal number of priorities
{$IFDEF RESTRICT_TRAINING_DB}
  MAX_PLY_TO_BASE = 60;
{$ELSE}
  MAX_PLY_TO_BASE = -1; // The whole game is saved to the DB
{$ENDIF}

////////////////////////////////////////////////////////////////////////////////
// TPosBaseChessBoard

constructor TPosBaseChessBoard.Create(voOwner: TComponent; vfHandler: TChessBoardHandler;
  const strPosBaseName: string = '');
begin
  inherited Create(voOwner, vfHandler);

  m_bUseUserBase := TRUE;
  m_strPosBaseName := strPosBaseName;
  _lstMovePrior := TList.Create;

  m_Layer := TPosBaseChessBoardLayer.Create(self);
  Layer := m_Layer;
end;


destructor TPosBaseChessBoard.Destroy;
begin
  m_Layer.Free;

  FClearMovePriorList;
  _lstMovePrior.Free;

  pTrainingMode := FALSE;

  inherited;
end;


procedure TPosBaseChessBoard.FClearMovePriorList;
var
  i: integer;
begin
  for i := 0 to _lstMovePrior.Count - 1 do
    Dispose(_lstMovePrior[i]);
  _lstMovePrior.Clear;
end;


procedure Reestimate(lstMoveEsts: TList; viRec: integer);
var
  est: SmallInt;
  id: word;
begin
  id := LongWord(lstMoveEsts[viRec]) shr 16;
  if id = gameID then
    exit; // ������� ����������� � ������ ����� ������

  est := SmallInt(lstMoveEsts[viRec]);
  case gameResult of
    grWin:     inc(est, 2);
    grWinTime: inc(est);
    grDraw:       ;
    grLost:     dec(est, 2);
    grLostTime: dec(est);
  end;
  lstMoveEsts[viRec] := Pointer((gameID shl 16) or Word(est));
end;


procedure TPosBaseChessBoard.FSetTrainingMode(bEnabled: boolean);
begin
  if (m_bTrainingMode = bEnabled) then
    exit;

  m_bTrainingMode := bEnabled;
  try
    if (m_bTrainingMode) then
    begin
      if (m_strPosBaseName <> '') then
        m_PosBase := TPosBase.Create(m_strPosBaseName, Reestimate);
      if (m_strExtPosBaseName <> '') then
        m_ExtPosBase := TPosBase.Create(m_strExtPosBaseName);
      with TPosBaseOperator.CreateRead(self, FALSE, FALSE) do
      try
        WaitFor;
      finally
        Free;
      end;
    end
    else
    begin
      FreeAndNil(m_PosBase);
      FreeAndNil(m_ExtPosBase);
    end;

    RDrawBoard;

  except
    on Exception do
    begin
      FreeAndNil(m_PosBase);
      FreeAndNil(m_ExtPosBase);
      m_bTrainingMode := FALSE;
    end;
  end;
end;


procedure TPosBaseChessBoard.FUseUserBase(bUseUserBase: boolean);
begin
  if (m_bUseUserBase = bUseUserBase) then
    exit;
  m_bUseUserBase := bUseUserBase;
  TPosBaseOperator.CreateRead(self, FALSE);
end;


procedure TPosBaseChessBoard.FDrawHiddenBoard(ACanvas: TCanvas; iSquareSize: integer);
const
  ARROW_END_LENGTH = 10; // � ��������
  ARROW_END_ANGLE = 15 * (Pi / 180); // ���� ������ �������
  ARROW_INDENT = 7;

  HIGH_ARROW_COLOR = clRed;
  HIGH_ARROW_WIDTH = 2;
  MID_ARROW_COLOR =  clTeal;
  MID_ARROW_WIDTH = 2;
  LOW_ARROW_COLOR = clSkyBlue;
  LOW_ARROW_WIDTH = 1;

var
  i, x0, y0, x, y: integer;
  xa, ya, ca, sa: double;
  move: TMoveAbs;
begin
  if (not Assigned(ACanvas)) then
    exit;

  inherited;

  if (not (m_bTrainingMode and (Mode in [mGame, mAnalyse]) and
      (PlayerColor = PositionColor))) then
    exit;

  ACanvas.Pen.Style := psSolid;

  for i := 0 to _lstMovePrior.Count - 1 do
  begin
    case PMovePrior(_lstMovePrior[i]).prior of
      mpNo: continue;
      mpHigh:
        begin
          ACanvas.Pen.Color := HIGH_ARROW_COLOR;
          ACanvas.Pen.Width := HIGH_ARROW_WIDTH;
        end;
      mpMid:
        begin
          ACanvas.Pen.Color := MID_ARROW_COLOR;
          ACanvas.Pen.Width := MID_ARROW_WIDTH;
        end;
      mpLow:
        begin
          ACanvas.Pen.Color := LOW_ARROW_COLOR;
          ACanvas.Pen.Width := LOW_ARROW_WIDTH;
        end;
    end;

    move := PMovePrior(_lstMovePrior[i]).move;

    if (not flipped) then
    begin
      x0 := CHB_X + iSquareSize * (move.i0 - 1) + (iSquareSize div 2);
      y0 := CHB_Y + iSquareSize * (8 - move.j0) + (iSquareSize div 2);
      x := CHB_X + iSquareSize * (move.i - 1) + (iSquareSize div 2);
      y := CHB_Y + iSquareSize * (8 - move.j) + (iSquareSize div 2);
    end
    else
    begin
      x0 := CHB_X + iSquareSize * (8 - move.i0) + (iSquareSize div 2);
      y0 := CHB_Y + iSquareSize * (move.j0 - 1) + (iSquareSize div 2);
      x := CHB_X + iSquareSize * (8 - move.i) + (iSquareSize div 2);
      y := CHB_Y + iSquareSize * (move.j - 1) + (iSquareSize div 2);
    end;

    // Draw an arrow
    ca := (x - x0) / sqrt(sqr(x - x0) + sqr(y - y0));
    sa := (y - y0) / sqrt(sqr(x - x0) + sqr(y - y0));
    x0 := x0 + Round(ARROW_INDENT * ca);
    y0 := y0 + Round(ARROW_INDENT * sa);
    x := x - Round(ARROW_INDENT * ca);
    y := y - Round(ARROW_INDENT * sa);

    ACanvas.MoveTo(x0, y0);
    ACanvas.LineTo(x, y);

    xa := x + (-ARROW_END_LENGTH * cos(ARROW_END_ANGLE)) * ca -
              (ARROW_END_LENGTH * sin(ARROW_END_ANGLE)) * sa;
    ya := y + (-ARROW_END_LENGTH * cos(ARROW_END_ANGLE)) * sa +
              (ARROW_END_LENGTH * sin(ARROW_END_ANGLE)) * ca;

    ACanvas.LineTo(Round(xa), Round(ya));

    xa := x + (-ARROW_END_LENGTH * cos(ARROW_END_ANGLE)) * ca -
              (-ARROW_END_LENGTH * sin(ARROW_END_ANGLE)) * sa;
    ya := y + (-ARROW_END_LENGTH * cos(ARROW_END_ANGLE)) * sa +
              (-ARROW_END_LENGTH * sin(ARROW_END_ANGLE)) * ca;

    ACanvas.MoveTo(x, y);
    ACanvas.LineTo(Round(xa), Round(ya));
  end;

end;


procedure TPosBaseChessBoard.ROnAfterMoveDone;
begin
  inherited;
  
  if (m_bTrainingMode) then
  begin
    if (PlayerColor = PositionColor) then
      TPosBaseOperator.CreateRead(self, TRUE) // ������ �� ���� � ����� �� ������� �����
  end;
end;


procedure TPosBaseChessBoard.ROnAfterSetPosition;
begin
  inherited;

  if (m_bTrainingMode) then
  begin
    with TPosBaseOperator.CreateRead(self, FALSE, FALSE) do // Read from DB and output to the hidden board
    try
      WaitFor;
    finally
      Free;
    end;
  end;
end;


procedure TPosBaseChessBoard.SetExternalBase(const strExtPosBaseName: string);
begin
  if (m_bTrainingMode) then
  begin
    if (m_strExtPosBaseName = strExtPosBaseName) then
      exit;
    FreeAndNil(m_ExtPosBase);
    m_ExtPosBase := TPosBase.Create(strExtPosBaseName);
    TPosBaseOperator.CreateRead(self, FALSE);
  end;
  m_strExtPosBaseName := strExtPosBaseName;
end;


function EstComape(item1, item2: pointer): integer;
begin
  Result := SmallInt(PMoveEst(item2).estimate and $FFFF) - SmallInt(PMoveEst(item1).estimate and $FFFF);
end;


procedure TPosBaseChessBoard.FReadFromBase;

  procedure ClasterMoves(var rlstMove: TList); // ������������� �����
  var
    i, j, num_clast, i_min, j_min, curr_assoc: integer;
    modus_min: double;
    clastWeights: array of record
      grav: double;
      assoc: integer;
    end;
    mp: PMovePrior;
    p: TPrior;
  begin
    if rlstMove.Count = 0 then
      exit;

    rlstMove.Sort(EstComape);
    SetLength(clastWeights, rlstMove.Count);

    num_clast := rlstMove.Count;
    for i := 0 to num_clast - 1 do
      begin
        clastWeights[i].assoc := i + 1;
        clastWeights[i].grav := SmallInt(PMoveEst(rlstMove[i]).estimate and $FFFF);
      end;

    repeat
      i_min := 0;
      j_min := 0;
      modus_min := $7FFF; // $7FFF - ����. �������� ��� ������
      curr_assoc := 0; // ������� ��������������� �������

      for i := 0 to length(clastWeights) - 2 do
        begin
          if curr_assoc = clastWeights[i].assoc then
            continue;
          curr_assoc := clastWeights[i].assoc;
          for j := i + 1 to length(clastWeights) - 1 do
            if (clastWeights[j].assoc <> clastWeights[j-1].assoc) and
               (curr_assoc <> clastWeights[j].assoc) and
               (abs(clastWeights[i].grav - clastWeights[j].grav) <= modus_min) then
              begin
                i_min := i;
                j_min := j;
                modus_min := abs(clastWeights[i].grav - clastWeights[j].grav);
              end;
         end;

       if (num_clast > Ord(High(TPrior))) or (modus_min = 0.0) then
         begin
           for i := High(clastWeights) downto j_min do
             if clastWeights[i].assoc = clastWeights[j_min].assoc then
               clastWeights[i].assoc := clastWeights[i_min].assoc;
           clastWeights[i_min].grav := (clastWeights[i_min].grav + clastWeights[j_min].grav) / 2;
         end;

       dec(num_clast);
    until (num_clast <= Ord(High(TPrior))) and ((modus_min <> 0.0) or (num_clast < 1));

    p := mpHigh;
    for i := 0 to rlstMove.Count - 1 do
      begin
        new(mp);
        if (i > 0) and (clastWeights[i].assoc > clastWeights[i-1].assoc) then
          p := Succ(p); 
        mp.move := PMoveEst(rlstMove[i]).move;
        mp.prior := p;
        Dispose(rlstMove[i]);
        rlstMove[i] := mp;
      end;

    SetLength(clastWeights, 0);
  end;

var
  lstUsrMove, lstExtMove: TList;

  procedure MergeMoves;
    function NEqualMoves(i,j: integer): boolean;
    begin
      with PMovePrior(lstExtMove[i])^, PMovePrior(_lstMovePrior[j]).move do
        Result := (i0 = move.i0) and (j0 = move.j0) and (j = move.j) and (i = move.i) and
                  (prom_fig = move.prom_fig);
    end;

  var
    i, j, n: integer;
  const
    PRIOR_CALC: array[TPrior, TPrior] of TPrior =
      ((mpNo, mpNo, mpNo, mpNo),        // UsrPrior = mpNo - ?, �.�. ��� ����� �� ���.
       (mpHigh, mpHigh, mpHigh, mpMid), // UsrPrior = mpHigh
       (mpMid, mpMid, mpMid, mpMid),    // UsrPrior = mpMid
       (mpLow, mpMid, mpLow, mpLow));   // UsrPrior = mpLow
  begin
    for i := 0 to lstUsrMove.Count - 1 do
      _lstMovePrior.Add(lstUsrMove[i]);

  // �������� �������
  n := _lstMovePrior.Count;
  for i := 0 to lstExtMove.Count - 1 do
    begin
      j := n - 1;
      while (j >= 0) do
        begin
          if NEqualMoves(i,j) then
            begin
              PMovePrior(_lstMovePrior[j]).prior :=
                PRIOR_CALC[PMovePrior(_lstMovePrior[j]).prior, PMovePrior(lstExtMove[j]).prior];
              Dispose(lstExtMove[i]);
              break;
            end;
          dec(j);
        end;
      if j < 0 then
        _lstMovePrior.Add(lstExtMove[i]);
    end; { for }
  end;

begin // .FReadFromBase
  FClearMovePriorList;

  lstExtMove := nil;
  lstUsrMove := TList.Create;
  try
    lstExtMove := TList.Create;

    if (m_bUseUserBase or (not Assigned(m_ExtPosBase))) then
    begin
      if (Assigned(m_PosBase)) then
        m_PosBase.Find(Position^, lstUsrMove);
    end;
    if (Assigned(m_ExtPosBase)) then
      m_ExtPosBase.Find(Position^, lstExtMove);

    // TODO: Handle wrong DB

    ClasterMoves(lstUsrMove);
    ClasterMoves(lstExtMove);

    MergeMoves;

  finally
    lstExtMove.Free;
    lstUsrMove.Free;
  end;
end;


procedure TPosBaseChessBoard.WriteGameToBase(AGameResult: TGameResult);
begin
  if (not m_bTrainingMode) then
    exit;
  gameResult := AGameResult;
  TPosBaseOperator.CreateWrite(self);
end;


procedure TPosBaseChessBoard.FWriteGameToBase;
var
  ply: integer;
begin
  if (not Assigned(m_PosBase)) then
    exit;

  gameID := Random($FFFF) + 1;

  if (PlayerColor = RGetColorStarts) then
    ply := 0
  else
    ply := 1;

  while ((ply < PositionsList.Count) and ((MAX_PLY_TO_BASE < 0) or (ply <= MAX_PLY_TO_BASE))) do
  begin
    m_PosBase.Add(PPosMove(PositionsList[ply])^);
    inc(ply, 2);
  end;
end;


procedure TPosBaseChessBoard.UnsetExternalBase;
begin
  FreeAndNil(m_ExtPosBase);
end;


procedure TPosBaseChessBoard.PPRandom;
var
  PosBaseOperator: TPosBaseOperator;
begin
  inherited;
  if (m_bTrainingMode) then
  begin
    PosBaseOperator := TPosBaseOperator.CreateRead(self, FALSE, FALSE); // ������ �� ���� � ����� �� ������� �����
    PosBaseOperator.WaitFor;
    PosBaseOperator.Free;
  end;
end;


procedure TPosBaseChessBoard.RSetMode(const Value: TMode);
var
  SavedMode: TMode;
begin
  if (Value = Mode) then
    exit;

  SavedMode := Mode;

  inherited;

  if (SavedMode = mEdit) then
    ROnAfterSetPosition;
end;


procedure TPosBaseChessBoard.ResetMoveList;
begin
  inherited;
  if (Mode = mEdit) then
    FClearMovePriorList;
end;

////////////////////////////////////////////////////////////////////////////////
// TPosBaseOperator

constructor TPosBaseOperator.FCreateRead(voChessBoard: TPosBaseChessBoard; vbHidden: boolean; vbFreeOnTerminate: boolean = TRUE);
begin
  _enuOperation := opRead;
  _oChessBoard := voChessBoard;

  inherited Create(TRUE);
  Priority := tpNormal;
  FreeOnTerminate := vbFreeOnTerminate;
  Resume;
end;


constructor TPosBaseOperator.FCreateWrite(voChessBoard: TPosBaseChessBoard);
begin
  _oChessBoard := voChessBoard;
  _enuOperation := opWrite;
  inherited Create(TRUE);
  Priority := tpNormal;
  FreeOnTerminate := TRUE;
  Resume;
end;


class function TPosBaseOperator.CreateRead(voChessBoard: TPosBaseChessBoard;
  vbHidden: boolean; vbFreeOnTerminate: boolean = TRUE): TPosBaseOperator;
begin
  Result := nil;
  if (voChessBoard.Mode = mEdit) then
    exit;

  Result := TPosBaseOperator.FCreateRead(voChessBoard, vbHidden, vbFreeOnTerminate);
end;


class function TPosBaseOperator.CreateWrite(voChessBoard: TPosBaseChessBoard): TPosBaseOperator;
begin
  Result := nil;
  if (voChessBoard.Mode = mEdit) then
    exit;

  Result := TPosBaseOperator.FCreateWrite(voChessBoard);
end;

                                
procedure TPosBaseOperator.Execute;
begin
  case _enuOperation of
    opRead:
    begin
      _oChessBoard.FReadFromBase;
      Synchronize(_oChessBoard.m_Layer.DoUpdate);
    end;
    opWrite:
      _oChessBoard.FWriteGameToBase;
  end;
end;


procedure TPosBaseOperator.WaitFor;
begin
  if (not Assigned(self)) then
    exit;
  inherited WaitFor;
end;

////////////////////////////////////////////////////////////////////////////////
// TPosBaseChessBoardLayer

constructor TPosBaseChessBoardLayer.Create(const APosBaseChessBoard: TPosBaseChessBoard);
begin
  inherited Create;
  m_PosBaseChessBoard := APosBaseChessBoard;
end;


procedure TPosBaseChessBoardLayer.RDraw;
begin
  m_PosBaseChessBoard.FDrawHiddenBoard(Canvas, SquareSize);
end;


initialization
  Randomize;

end.
