////////////////////////////////////////////////////////////////////////////////
// All code below is exclusively owned by author of Chess4Net - Pavel Perminov
// (packpaul@mail.ru, packpaul1@gmail.com).
// Any changes, modifications, borrowing and adaptation are a subject for
// explicit permition from the owner.

unit PGNProcessorUnit;

interface

uses
  Classes,
  //
  ChessRulesEngine, PosBaseUnit, PGNTraverserUnit;

type
  TOpening = (openNo, openNormal, openExtended, openExtendedPlus);

  TPGNProcessor = class
  private
    constructor FCreate;
    procedure FProceedPGN(const strBasename: string; bVariants, bChngest: boolean; bUniquePos: boolean;
      const color: TFigureColors; iNumPlys: integer; const strPlayerName: string;
      opening: TOpening; bStatPrunning: boolean; strRefBaseName: string);

  public
    constructor Create;
    class procedure Proceed(const basename: string; variants, chngest: boolean; uniquePos: boolean;
                            const color: TFigureColors; numPlys: integer; const player_name: string;
                            opening: TOpening; statPrunning: boolean; refBaseName: string);
  end;

implementation

uses
  SysUtils, Contnrs;

type
  TPosBaseCollector = class(TInterfacedObject, IPGNTraverserVisitable)
  private
    m_PosMoves: TStack;
    m_Contexts: TStack;
    m_lstMoveEstimations: TList;

    m_PosBase, m_RefPosBase: TPosBase;

    m_strPosBaseName: string;
    m_strReferencePosBaseName: string;
    m_ProceedColors: TFigureColors;
    m_bChangeEstimateion: boolean;
    m_bUseUniquePositions: boolean;
    m_bUseStatisticalPrunning: boolean;
    m_iUseNumberOfPlys: integer;

    m_bAddPos: boolean;
    m_bAddSimplePosMove: boolean;
    m_SimplePosMove: TPosMove;
    m_GenOpening: TOpening;

    m_bLineStartedFromPreviousPosition: boolean;
    m_lastPosMove: TPosMove;
    m_lastResultingPos: TChessPosition;
    m_iGameNumber: integer;

    procedure FClearPosMoves;
    procedure FClearContexts;
    procedure FClearMoveEstimations;

    procedure FProcessExtendedOpeningLine(const posMove: TPosMove);
    procedure FProcessOpeningLine(const posMove: TPosMove);
    procedure FReestimate(moveEsts: TList; nRec: integer);

  public
    constructor Create(const strPosBaseName: string; const strReferencePosBaseName: string = '');
    destructor Destroy; override;
    procedure Start;
    procedure DoPosMove(iPlyNumber: integer; const APosMove: TPosMove; const AResultingPos: TChessPosition);
    procedure StartLine(bFromPreviousPos: boolean);
    procedure EndLine;
    procedure Finish;

    property PosBaseName: string read m_strPosBaseName;

    property ProceedColors: TFigureColors read m_ProceedColors write m_ProceedColors;
    property ChangeEstimation: boolean read m_bChangeEstimateion write m_bChangeEstimateion;
    property UseUniquePositions: boolean read m_bUseUniquePositions write m_bUseUniquePositions;
    property GeneratedOpening: TOpening read m_GenOpening write m_GenOpening;
    property UseStatisticalPrunning: boolean read m_bUseStatisticalPrunning write m_bUseStatisticalPrunning;
    property UseNumberOfPlys: integer read m_iUseNumberOfPlys write m_iUseNumberOfPlys;
  end;

  PPosBaseCollectorContext = ^TPosBaseCollectorContext;
  TPosBaseCollectorContext = record
    bAddPos: boolean;
    iPosMovesCount: integer;
    PosMove: TPosMove;
    ResultingPos: TChessPosition;
  end;

var
  g_PosBaseCollector: TPosBaseCollector = nil;

procedure Reestimate(moveEsts: TList; nRec: integer);
begin
  if (Assigned(g_PosBaseCollector)) then
    g_PosBaseCollector.FReestimate(moveEsts, nRec); 
end;

////////////////////////////////////////////////////////////////////////////////
// TPGNProcessor

constructor TPGNProcessor.Create;
begin
  raise Exception.Create('TPGNProcessor cannot be instantiated directly!');
end;


constructor TPGNProcessor.FCreate;
begin
  inherited Create;
end;


class procedure TPGNProcessor.Proceed(const basename: string; variants, chngest: boolean; uniquePos: boolean;
  const color: TFigureColors; numPlys: integer; const player_name: string;
  opening: TOpening; statPrunning: boolean; refBaseName: string);
begin
  with TPGNProcessor.FCreate do
  try
    FProceedPGN(basename, variants, chngest, uniquePos, color, numPlys, player_name,
      opening, statPrunning, refBaseName);
  finally
    Free;
  end;
end;


procedure TPGNProcessor.FProceedPGN(const strBasename: string; bVariants, bChngest: boolean; bUniquePos: boolean;
      const color: TFigureColors; iNumPlys: integer; const strPlayerName: string;
      opening: TOpening; bStatPrunning: boolean; strRefBaseName: string);
var
  PosBaseCollector: TPosBaseCollector;
begin
  PosBaseCollector := TPosBaseCollector.Create(strBasename, strRefBaseName);

  PosBaseCollector.ProceedColors := color;
  PosBaseCollector.ChangeEstimation := bChngest;
  PosBaseCollector.UseUniquePositions := bUniquePos;
  PosBaseCollector.GeneratedOpening := opening;
  PosBaseCollector.UseStatisticalPrunning := bStatPrunning;
  PosBaseCollector.UseNumberOfPlys := iNumPlys;

  with TPGNTraverser.Create(Input, PosBaseCollector) do
  try
    ProceedColors := color;
    PlayerName := strPlayerName;
    IncludeVariants := bVariants;
    Traverse;
    writeln('Games viewed: ', NumberOfGamesViewed);
    writeln('Positions viewed: ', NumberofPositionsViewed);
  finally
    Free;
  end;

end;

////////////////////////////////////////////////////////////////////////////////
// TPosBaseCollector

constructor TPosBaseCollector.Create(const strPosBaseName: string;
                                     const strReferencePosBaseName: string = '');
begin
  inherited Create;

  m_strPosBaseName := strPosBaseName;
  m_strReferencePosBaseName := strReferencePosBaseName;

  m_ProceedColors := [fcWhite, fcBlack];
  m_GenOpening := openNo;

  m_PosMoves := TStack.Create;
  m_lstMoveEstimations := TList.Create;
  m_Contexts := TStack.Create;

  g_PosBaseCollector := self;
end;


destructor TPosBaseCollector.Destroy;
begin
  g_PosBaseCollector := nil;

  m_PosBase.Free;
  m_RefPosBase.Free;

  FClearMoveEstimations;
  m_lstMoveEstimations.Free;

  FClearPosMoves;
  m_PosMoves.Free;

  FClearContexts;
  m_Contexts.Free;

  inherited;
end;


procedure TPosBaseCollector.DoPosMove(iPlyNumber: integer; const APosMove: TPosMove;
  const AResultingPos: TChessPosition);
begin // .DoPosMove
  m_lastPosMove := APosMove;
  m_lastResultingPos := AResultingPos;

  if (not (APosMove.pos.color in m_ProceedColors)) then
    exit;

    if (m_GenOpening <> openNo) then
      FProcessOpeningLine(APosMove);

    m_bAddPos := (m_bAddPos and ((m_iUseNumberOfPlys = 0) or (iPlyNumber <= m_iUseNumberOfPlys)));

    if (m_bAddPos) then
      m_PosBase.Add(APosMove);

    if (m_GenOpening in [openExtended, openExtendedPlus]) then
      FProcessExtendedOpeningLine(APosMove);
end;


procedure TPosBaseCollector.FProcessExtendedOpeningLine(const posMove: TPosMove);
var
  p_posMove: PPosMove;
begin
  if (m_bAddPos) then
  begin
    // Adding previous positions, which hadn't been added to DB before
    while (m_PosMoves.Count > 0) do
    begin
      m_PosBase.Add(PPosMove(m_PosMoves.Peek)^);
      Dispose(m_PosMoves.Pop);
    end;
    m_bAddSimplePosMove := FALSE;
  end
  else
  begin
    New(p_posMove);
    p_posMove^ := posMove;
    m_PosMoves.Push(p_posMove);
    if ((m_GenOpening = openExtendedPlus) and (not m_bAddSimplePosMove)) then
    begin
      m_bAddSimplePosMove := TRUE;
      m_SimplePosMove := posMove;
    end;
  end;
end;


procedure TPosBaseCollector.FProcessOpeningLine(const posMove: TPosMove);
var
  i: integer;
begin
  if (Assigned(m_RefPosBase)) then
    m_bAddPos := m_RefPosBase.Find(posMove.pos, m_lstMoveEstimations)
  else
    m_bAddPos := m_PosBase.Find(posMove.pos, m_lstMoveEstimations);

  if (not m_bAddPos) then
    exit;

  i := m_lstMoveEstimations.Count - 1;
  while (i >= 0) do
  begin
    with PMoveEst(m_lstMoveEstimations[i]).move, posMove do
      m_bAddPos := ((i0 = move.i0) and (j0 = move.j0) and (i = move.i) and
                    (j = move.j) and (prom_fig = move.prom_fig));
    if (m_bAddPos) then
    begin
      if (m_bUseUniquePositions) then
        m_bAddPos := ((PMoveEst(m_lstMoveEstimations[i]).estimate and $FFFF) >= 2);
      if (m_bAddPos) then
        break;
    end;
    dec(i);
  end;
  if (i < 0) then
    m_bAddPos := FALSE;
end;


procedure TPosBaseCollector.StartLine(bFromPreviousPos: boolean);
var
  pContext: PPosBaseCollectorContext;
begin
  new(pContext);
  pContext.bAddPos := m_bAddPos;
  pContext.iPosMovesCount := m_PosMoves.Count;
  pContext.PosMove := m_lastPosMove;
  pContext.ResultingPos := m_lastResultingPos;

  m_Contexts.Push(pContext);

  m_bLineStartedFromPreviousPosition := bFromPreviousPos;
end;


procedure TPosBaseCollector.EndLine;
var
  pContext: PPosBaseCollectorContext;
begin
  pContext := m_Contexts.Pop;
  try
    m_lastPosMove := pContext.PosMove;
    m_lastResultingPos := pContext.ResultingPos;

    if (m_bLineStartedFromPreviousPosition) then
      m_bAddPos := ((m_GenOpening = openNo) or m_PosBase.Find(m_lastResultingPos)) // Opening
    else
      m_bAddPos := pContext.bAddPos; // Opening

    while (pContext.iPosMovesCount < m_PosMoves.Count) do // Deletion of subline stack
      Dispose(m_PosMoves.Pop);

  finally
    Dispose(pContext);
  end;
  
end;


procedure TPosBaseCollector.Finish;
begin
  if (m_bAddSimplePosMove) then
    m_PosBase.Add(m_SimplePosMove);
end;


procedure TPosBaseCollector.Start;
begin
  m_bAddPos := TRUE;
  m_bAddSimplePosMove := FALSE;

  FClearPosMoves;
  FClearMoveEstimations;
  FClearContexts;

  inc(m_iGameNumber);

  if (not Assigned(m_PosBase)) then
  begin
    if (m_bChangeEstimateion) then
      m_PosBase := TPosBase.Create(m_strPosBaseName, Reestimate)
    else
      m_PosBase := TPosBase.Create(m_strPosBaseName);

    if (m_strReferencePosBaseName <> '') then
      m_RefPosBase := TPosBase.Create(m_strReferencePosBaseName);
  end;

end;


procedure TPosBaseCollector.FClearPosMoves;
begin
  while (m_PosMoves.Count > 0) do
    Dispose(m_PosMoves.Pop);
end;


procedure TPosBaseCollector.FClearContexts;
begin
  while (m_Contexts.Count > 0) do
    Dispose(m_Contexts.Pop);
end;


procedure TPosBaseCollector.FClearMoveEstimations;
var
  i: integer;
begin
  for i := 0 to m_lstMoveEstimations.Count - 1 do
    Dispose(m_lstMoveEstimations[i]);
  m_lstMoveEstimations.Clear;
end;


procedure TPosBaseCollector.FReestimate(moveEsts: TList; nRec: integer);
var
  est : LongWord;
begin
  // Re-estimation is done here:
  // Re-estimation for a DB with GMs games
  est := LongWord(moveEsts[nRec]);
  if ((est and $FFFF) < $FFFF) then
    est := est + 1;
  // For statistical estimation: if position in bounds of one game comes more than one time -> don't change estimation
  if (m_bUseUniquePositions) then
  begin
    if ((est shr 16) >= m_iGameNumber) then // exclude repitition of "position + moves" in one game
      exit;
    est := (m_iGameNumber shl 16) or (est and $FFFF);
  end
  else
    est := est and $FFFF;

  moveEsts[nRec] := Pointer(est);
end;

end.
