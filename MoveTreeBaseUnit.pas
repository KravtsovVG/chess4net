////////////////////////////////////////////////////////////////////////////////
// All code below is exclusively owned by author of Chess4Net - Pavel Perminov
// (packpaul@mail.ru, packpaul1@gmail.com).
// Any changes, modifications, borrowing and adaptation are a subject for
// explicit permition from the owner.

unit MoveTreeBaseUnit;

interface

uses
  Classes, SysUtils, Contnrs,
  //
  ChessRulesEngine;

type
  PDataBag = ^TDataBag;
  TDataBag = packed object
  public
    btFirst: byte;
    btSecond: byte;
  private
    function FEquals(const Other: TDataBag): boolean;
    procedure FConvertFromMove(const AMove: TMoveAbs);
    function FIsMove: boolean;
    function FToMove: TMoveAbs;
    function FConvertFromNearPointer(lwPointer: LongWord; out Data: TDataBag): boolean;
    function FIsNearPointer: boolean;
    function FToNearPointer: Word;
    function FConvertFromFarPointer(lwPointer: LongWord; out HiData, LowData: TDataBag): boolean;
    function FIsFarPointer: boolean;
    function FToFarPointer(const HiData, LowData: TDataBag): LongWord;
    function FIsEndDataTag: boolean;
  end;

  TMoveTreeStream = class
  private
    m_InnerStream: TStream;
    m_wHeaderSize: Word;
    m_iDBVersion: integer;

    constructor FCreateFileStream(const BaseFileName: TFileName);
    constructor FCreateMemoryStream;

    function FGetSize: Int64;

    procedure FSetDBVersion;

    function FReadHeader(out wVersion: Word): boolean;
    procedure FWriteHeader(const wVersion: Word);

  public
    constructor Create;
    destructor Destroy; override;
    
    function ReadBagFromStream(out ABag: TDataBag): boolean; overload;
    function ReadBagFromStream(lwPosition: LongWord; out ABag: TDataBag): boolean; overload;
    procedure WriteBagToStream(const ABag: TDataBag); overload;
    procedure WriteBagToStream(lwPosition: LongWord; const ABag: TDataBag); overload;
    procedure WriteBagToStreamEnd(const ABag: TDataBag);

    property Size: Int64 read FGetSize;
  end;

  TMoveAbsArr = array of TMoveAbs;

  TMovesDataIterator = class
  private
    m_Moves: TMoveAbsArr;
    m_iIndex: integer;
    constructor FCreate(const Moves: TMoveAbsArr);
  public
    constructor Create;
    function HasNext: boolean;
    function GetNextMove: TMoveAbs;
    function GetLastMove: TMoveAbs;
    function GetNextDataBag: TDataBag;
    function GetLastDataBag: TDataBag;
  end;

  TInsertionPoint = object
  public
    lwAddress1: LongWord;
    lwAddress2: LongWord;
  private
    procedure FInit(lwAddress: LongWord); overload;
    procedure FInit(lwAAddress1, lwAAddress2: LongWord); overload;
  end;

  TMoveTreeAddress = packed object
  public
    lwPosition: LongWord;
    wOffset: Word;
  private
    procedure FInit(lwAPosition: LongWord; wAOffset: Word);
  end;

  TMoveTreeAddressArr = array of TMoveTreeAddress;

  TPosAddressItem = class
  private
    m_Pos: TChessPosition;
    m_Addresses: TMoveTreeAddressArr;
    constructor FCreate(const APos: TChessPosition; const AAddress: TMoveTreeAddress);
    procedure FAddAddress(const AAddress: TMoveTreeAddress);
    property Pos: TChessPosition read m_Pos;
    property Addresses: TMoveTreeAddressArr read m_Addresses;
  public
    constructor Create;
  end;

  TMoveTreeBaseCache = class
  private
    m_InitialPos: TChessPosition;
    m_InitialAddress: TMoveTreeAddress;
    m_PosAddresses: TObjectList;
    m_iLastItemIndex: integer; // PP: optimization?
    constructor FCreate(const InitialPos: TChessPosition; const InitialAddress: TMoveTreeAddress);
    function FGet(const Pos: TChessPosition; out AItem: TPosAddressItem): boolean;
    procedure FAdd(const Pos: TChessPosition; const Address: TMoveTreeAddress);
    procedure FClear;
  public
    constructor Create;
    destructor Destroy; override;
    function Get(const Pos: TChessPosition; out Addresses: TMoveTreeAddressArr): boolean;
  end;

  TMovePosAddress = object
  public
    move: TMoveAbs;
    pos: TChessPosition;
    address: TMoveTreeAddress;
  private
    procedure FInit(const AMove: TMoveAbs; const APos: TChessPosition;
      const AAddress: TMoveTreeAddress);
  end;

  TMovePosAddressArr = array of TMovePosAddress;

  EMoveTreeBase = class(Exception);

  TMoveTreeBase = class
  private
    m_BaseStream: TMoveTreeStream;
    m_ChessRulesEngine: TChessRulesEngine;
    m_PosCache: TMoveTreeBaseCache;
    m_InitialPos: TChessPosition;

    FOnAdded: TNotifyEvent;

    constructor FCreate;
    class function FGetBaseFileName(const strBaseName: string): TFileName;

    procedure FSetOnAdded(OnAddedEvent: TNotifyEvent); // cannot be overriden

    function FFindData(lwPosition: LongWord; const DataIterator: TMovesDataIterator;
      out InsertionPoint: TInsertionPoint): boolean; overload;
    procedure FFindData(const APos: TChessPosition; const Address: TMoveTreeAddress; out Datas: TMovePosAddressArr); overload;

    procedure FSaveData(const InsertionPoint: TInsertionPoint; const DataIterator: TMovesDataIterator);
    procedure FStartNearBranch(const InsertionPoint: TInsertionPoint; const Data: TDataBag);
    procedure FStartFarBranch(const InsertionPoint: TInsertionPoint; const DataHi, DataLow: TDataBag);

    procedure FDoAdded;

    property ChessRulesEngine: TChessRulesEngine read m_ChessRulesEngine;
    property BaseStream: TMoveTreeStream read m_BaseStream;

  protected
    constructor CreateForTest;
    constructor CreateForTestFarJump;
    procedure RFind(const Pos: TChessPosition; const Addresses: TMoveTreeAddressArr; out Moves: TMoveAbsArr);

  public
    constructor Create(const strBaseName: string);
    destructor Destroy; override;
    class function Exists(const strBaseName: string): boolean;
    procedure Add(const Moves: TMoveAbsArr);
    procedure Find(const Pos: TChessPosition; out Moves: TMoveAbsArr);

    property OnAdded: TNotifyEvent write FSetOnAdded;
    property PosCache: TMoveTreeBaseCache read m_PosCache;
  end;

const
  _TDataBag: PDataBag = nil; // helper

implementation

type
  TDataFinder = class
  private
    m_Base: TMoveTreeBase;
    m_lwPosition: LongWord;
    m_lwLastPosition: LongWord;
    function FReadBagFromStream(out ABag: TDataBag): boolean; overload;
    function FReadBagFromStream(lwPosition: LongWord; out ABag: TDataBag): boolean; overload;
    function FJumpNear(const Data: TDataBag; out NextDataBag: TDataBag): boolean;
    function FJumpFar(const HiData: TDataBag; out NextDataBag: TDataBag): boolean;
    property Base: TMoveTreeBase read m_Base;
  protected
    function RFind(lwPosition: LongWord): boolean;
    function RIsDataFromJump: boolean;
    
    function RF1(const DataBag: TDataBag): boolean; virtual; abstract;
    function RF2(const DataBag: TDataBag): boolean; virtual; abstract;
    function RF3: boolean; virtual; abstract;
    procedure RP4; virtual;

    property Position: LongWord read m_lwPosition;
    property LastPosition: LongWord read m_lwLastPosition;
  public
    constructor Create(ABase: TMoveTreeBase);
  end;

  TInsertionPointDataFinder = class(TDataFinder)
  private
    m_DataIterator: TMovesDataIterator;
    m_InsertionPoint: TInsertionPoint;
  protected
    function RF1(const DataBag: TDataBag): boolean; override;
    function RF2(const DataBag: TDataBag): boolean; override;
    function RF3: boolean; override;
  public
    function Find(lwPosition: LongWord; const DataIterator: TMovesDataIterator;
      out InsertionPoint: TInsertionPoint): boolean;
  end;

  TNextLinesBuilderDataFinder = class(TDataFinder)
  private
    m_Datas: TMovePosAddressArr;
    m_wMovesCount: Word;
    m_Address: TMoveTreeAddress;
    function FGetChessRulesEngine: TChessRulesEngine;
    procedure FCollectDatas;
    function FF5(const DataBag: TDataBag; bJump: boolean): boolean;
    property ChessRulesEngine: TChessRulesEngine read FGetChessRulesEngine;
  protected
    function RF1(const DataBag: TDataBag): boolean; override;
    function RF2(const DataBag: TDataBag): boolean; override;
    function RF3: boolean; override;
    procedure RP4; override;
  public
    procedure Find(const APos: TChessPosition; const Address: TMoveTreeAddress;
      out Datas: TMovePosAddressArr);
  end;

const
  BASE_FILE_EXT = 'mvt';

  DB_VERSION = 1;

  PROM_FIG_MARKER: array[TFigureName] of byte = ($00, $00, $40, $80, $C0, $00); // K, Q, R, B, N, P

  MOVE_DATA_MARKER = $00;
  MOVE_DATA_MASK = $3F;
  NEAR_POINTER_DATA_MARKER = $80;
  NEAR_POINTER_DATA_MASK = NEAR_POINTER_DATA_MARKER - 1;
  FAR_POINTER_DATA_MARKER = $40;
  FAR_POINTER_DATA_MASK = FAR_POINTER_DATA_MARKER - 1;
  DATA_KIND_MASK = MOVE_DATA_MARKER or NEAR_POINTER_DATA_MARKER or FAR_POINTER_DATA_MARKER;

  END_DATA_TAG: TDataBag = (btFirst: 0; btSecond: 0);

  INITIAL_ADDRESS: TMoveTreeAddress = (lwPosition: 0; wOffset: 0);

var
  g_bFarPointerTests: boolean = FALSE;

////////////////////////////////////////////////////////////////////////////////
// TMoveTreeBase

constructor TMoveTreeBase.FCreate;
begin
  inherited Create;

  m_ChessRulesEngine := TChessRulesEngine.Create;
  m_InitialPos := m_ChessRulesEngine.Position^;
  m_PosCache := TMoveTreeBaseCache.FCreate(m_InitialPos, INITIAL_ADDRESS);
end;


constructor TMoveTreeBase.Create(const strBaseName: string);
begin
  FCreate;
  m_BaseStream := TMoveTreeStream.FCreateFileStream(FGetBaseFileName(strBaseName));
end;


constructor TMoveTreeBase.CreateForTest;
begin
  FCreate;
  m_BaseStream := TMoveTreeStream.FCreateMemoryStream;
end;


constructor TMoveTreeBase.CreateForTestFarJump;
begin
  CreateForTest;
  g_bFarPointerTests := TRUE;  
end;


destructor TMoveTreeBase.Destroy;
begin
  m_BaseStream.Free;
  
  m_PosCache.Free;
  m_ChessRulesEngine.Free;
  
  inherited;
end;


class function TMoveTreeBase.Exists(const strBaseName: string): boolean;
begin
  Result := FileExists(FGetBaseFileName(strBaseName));
end;


class function TMoveTreeBase.FGetBaseFileName(const strBaseName: string): TFileName;
begin
  Result := strBaseName + '.' + BASE_FILE_EXT;
end;


procedure TMoveTreeBase.Add(const Moves: TMoveAbsArr);
var
  Iterator: TMovesDataIterator;
  InsertionPoint: TInsertionPoint;
begin
  m_PosCache.FClear;

  if (Length(Moves) = 0) then
    exit;

  Iterator := TMovesDataIterator.FCreate(Moves);
  try
    if (not FFindData(0, Iterator, InsertionPoint)) then
      FSaveData(InsertionPoint, Iterator);
  finally
    Iterator.Free;
  end;

  FDoAdded;
end;


procedure TMoveTreeBase.FSetOnAdded(OnAddedEvent: TNotifyEvent);
begin
  if (not Assigned(self)) then
    exit;

  if (Assigned(FOnAdded) and Assigned(OnAddedEvent) and (@FOnAdded <> @OnAddedEvent)) then
    raise EMoveTreeBase.Create('callback OnAdded() is already set')
  else
    FOnAdded := OnAddedEvent;
end;


procedure TMoveTreeBase.FDoAdded;
begin
  if (Assigned(FOnAdded)) then
    FOnAdded(self);
end;


function TMoveTreeBase.FFindData(lwPosition: LongWord;
  const DataIterator: TMovesDataIterator; out InsertionPoint: TInsertionPoint): boolean;
begin
  m_ChessRulesEngine.SetPosition(m_InitialPos);
  
  with TInsertionPointDataFinder.Create(self) do
  try
    Result := Find(lwPosition, DataIterator, InsertionPoint);
  finally
    Free;
  end;
end;


procedure TMoveTreeBase.FSaveData(const InsertionPoint: TInsertionPoint;
  const DataIterator: TMovesDataIterator);
var
  lwAddressOffset: LongWord;
  DataOffsetHi, DataOffsetLow: TDataBag;
  Address: TMoveTreeAddress;
  bRes: boolean;
begin
  lwAddressOffset := m_BaseStream.Size - (InsertionPoint.lwAddress2 - 1);
  if (lwAddressOffset > 0) then
  begin
    if (_TDataBag.FConvertFromNearPointer(lwAddressOffset, DataOffsetLow)) then
      FStartNearBranch(InsertionPoint, DataOffsetLow)
    else if (_TDataBag.FConvertFromFarPointer(lwAddressOffset, DataOffsetHi, DataOffsetLow)) then
      FStartFarBranch(InsertionPoint, DataOffsetHi, DataOffsetLow)
    else
      raise EMoveTreeBase.Create('Base file has become too big!');
  end;

  m_BaseStream.WriteBagToStreamEnd(DataIterator.GetLastDataBag);
  Address.FInit(m_BaseStream.Size, 0);
  while (DataIterator.HasNext) do
  begin
    with DataIterator.GetLastMove do
      bRes := m_ChessRulesEngine.DoMove(i0, j0, i, j, prom_fig);
    Assert(bRes);
    inc(Address.wOffset);
    m_PosCache.FAdd(m_ChessRulesEngine.Position^, Address);
    m_BaseStream.WriteBagToStream(DataIterator.GetNextDataBag);
  end;
  m_BaseStream.WriteBagToStream(END_DATA_TAG);
end;


procedure TMoveTreeBase.FStartNearBranch(const InsertionPoint: TInsertionPoint;
  const Data: TDataBag);
var
  SavedData: TDataBag;
  bRead: boolean;
begin
  bRead := m_BaseStream.ReadBagFromStream(InsertionPoint.lwAddress1, SavedData);
  Assert(bRead);

  m_BaseStream.WriteBagToStreamEnd(SavedData);

  m_BaseStream.WriteBagToStream(InsertionPoint.lwAddress1, Data);
end;


procedure TMoveTreeBase.FStartFarBranch(const InsertionPoint: TInsertionPoint;
  const DataHi, DataLow: TDataBag);
var
  SavedData1, SavedData2: TDataBag;
  bRead: boolean;
begin
  bRead := m_BaseStream.ReadBagFromStream(InsertionPoint.lwAddress1, SavedData1);
  Assert(bRead);

  bRead := m_BaseStream.ReadBagFromStream(InsertionPoint.lwAddress2, SavedData2);
  Assert(bRead);

  m_BaseStream.WriteBagToStreamEnd(SavedData1);
  m_BaseStream.WriteBagToStream(SavedData2);

  m_BaseStream.WriteBagToStream(InsertionPoint.lwAddress1, DataHi);
  m_BaseStream.WriteBagToStream(InsertionPoint.lwAddress2, DataLow);
end;


procedure TMoveTreeBase.Find(const Pos: TChessPosition; out Moves: TMoveAbsArr);
var
  Addresses: TMoveTreeAddressArr;
begin
  if (m_PosCache.Get(Pos, Addresses)) then
    RFind(Pos, Addresses, Moves)
  else
    SetLength(Moves, 0);
end;


procedure TMoveTreeBase.RFind(const Pos: TChessPosition;
  const Addresses: TMoveTreeAddressArr; out Moves: TMoveAbsArr);
var
  Datas: TMovePosAddressArr;
  i, j: integer;
  iMovesIndex: integer;
begin
  SetLength(Moves, 0);

  iMovesIndex := Low(Moves);

  for i := Low(Addresses) to High(Addresses) do
  begin
    FFindData(Pos, Addresses[i], Datas);
    SetLength(Moves, Length(Moves) + Length(Datas));
    for j := Low(Datas) to High(Datas) do
    begin
      Moves[iMovesIndex] := Datas[j].move;
      inc(iMovesIndex);
      m_PosCache.FAdd(Datas[j].pos, Datas[j].address);
    end;
  end;
  
end;


procedure TMoveTreeBase.FFindData(const APos: TChessPosition;
  const Address: TMoveTreeAddress; out Datas: TMovePosAddressArr);
begin
  with TNextLinesBuilderDataFinder.Create(self) do
  try
    Find(APos, Address, Datas);
  finally
    Free;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// TMovesDataIterator

constructor TMovesDataIterator.Create;
begin
  raise Exception.Create(ClassName + ' cannot be instaniated directly!');
end;


constructor TMovesDataIterator.FCreate(const Moves: TMoveAbsArr);
begin
  inherited Create;
  m_Moves := Moves;
end;


function TMovesDataIterator.HasNext: boolean;
begin
  Result := (m_iIndex < Length(m_Moves));
end;


function TMovesDataIterator.GetNextMove: TMoveAbs;
begin
  Result := m_Moves[m_iIndex];
  inc(m_iIndex);
end;


function TMovesDataIterator.GetLastMove: TMoveAbs;
begin
  Result := m_Moves[m_iIndex - 1];
end;


function TMovesDataIterator.GetNextDataBag: TDataBag;
begin
  Result.FConvertFromMove(GetNextMove);
end;


function TMovesDataIterator.GetLastDataBag: TDataBag;
begin
  Result.FConvertFromMove(GetLastMove);
end;

////////////////////////////////////////////////////////////////////////////////
// TDataBag

procedure TDataBag.FConvertFromMove(const AMove: TMoveAbs);
begin
  btFirst := ((AMove.j0 - 1) shl 3) or (AMove.i0 - 1);
  btSecond := (((AMove.j - 1) shl 3) or (AMove.i - 1)) or PROM_FIG_MARKER[AMove.prom_fig];
end;


function TDataBag.FToMove: TMoveAbs;
const
  COORD_MASK = $07;
  PROM_FIG_MASK = $C0;
var
  f: TFigureName;
begin
  Result.i0 := (btFirst and COORD_MASK) + 1;
  Result.j0 := ((btFirst shr 3) and COORD_MASK) + 1;
  Result.i := (btSecond and COORD_MASK) + 1;
  Result.j := ((btSecond shr 3) and COORD_MASK) + 1;

  for f := Q to N do
  begin
    if (PROM_FIG_MARKER[f] = (btSecond and PROM_FIG_MASK)) then
    begin
      Result.prom_fig := f;
      break;
    end;
  end;
end;


function TDataBag.FEquals(const Other: TDataBag): boolean;
begin
  Result := ((btFirst = Other.btFirst) and (btSecond = Other.btSecond));
end;


function TDataBag.FIsMove: boolean;
const
  _DATA_KIND_MASK = (DATA_KIND_MASK xor MOVE_DATA_MASK) and DATA_KIND_MASK;
begin
  Result := (((btFirst and _DATA_KIND_MASK) = MOVE_DATA_MARKER) and
             ((btFirst and MOVE_DATA_MASK) <> btSecond));
end;


function TDataBag.FIsNearPointer: boolean;
const
  _DATA_KIND_MASK = (DATA_KIND_MASK xor NEAR_POINTER_DATA_MASK) and DATA_KIND_MASK;
begin
  Result := ((btFirst and _DATA_KIND_MASK) = NEAR_POINTER_DATA_MARKER);
end;


function TDataBag.FIsFarPointer: boolean;
const
  _DATA_KIND_MASK = (DATA_KIND_MASK xor FAR_POINTER_DATA_MASK) and DATA_KIND_MASK;
begin
  Result := ((btFirst and _DATA_KIND_MASK) = FAR_POINTER_DATA_MARKER);
end;


function TDataBag.FToNearPointer: Word;
begin
  Result := ((btFirst and NEAR_POINTER_DATA_MASK) shl 8) or btSecond;
end;


function TDataBag.FToFarPointer(const HiData, LowData: TDataBag): LongWord;
begin
  Result := ((((((HiData.btFirst and FAR_POINTER_DATA_MASK) shl 8) or HiData.btSecond) shl 8) or
              LowData.btFirst) shl 8) or LowData.btSecond;
end;


function TDataBag.FConvertFromFarPointer(lwPointer: LongWord; out HiData, LowData: TDataBag): boolean;
const
  MAX_VALUE = (FAR_POINTER_DATA_MARKER shl 24) - 1;
begin
  Result := (lwPointer <= MAX_VALUE);
  if (not Result) then
    exit;

  LowData.btSecond := lwPointer and $FF;
  LowData.btFirst := (lwPointer shr 8) and $FF;
  HiData.btSecond := (lwPointer shr 16) and $FF;
  HiData.btFirst := ((lwPointer shr 24) and FAR_POINTER_DATA_MASK) or FAR_POINTER_DATA_MARKER;
end;


function TDataBag.FConvertFromNearPointer(lwPointer: LongWord; out Data: TDataBag): boolean;
const
  MAX_VALUE = (NEAR_POINTER_DATA_MARKER shl 8) - 1;
begin
  Result := (lwPointer <= MAX_VALUE) and (not g_bFarPointerTests);
  if (not Result) then
    exit;

  Data.btSecond := lwPointer and $FF;
  Data.btFirst := ((lwPointer shr 8) and NEAR_POINTER_DATA_MASK) or NEAR_POINTER_DATA_MARKER;
end;


function TDataBag.FIsEndDataTag: boolean;
begin
  Result := ((btFirst = END_DATA_TAG.btFirst) and (btSecond = END_DATA_TAG.btSecond));
end;

////////////////////////////////////////////////////////////////////////////////
// TInsertionPoint

procedure TInsertionPoint.FInit(lwAddress: LongWord);
begin
  lwAddress1 := lwAddress;
  lwAddress2 := lwAddress;
end;

procedure TInsertionPoint.FInit(lwAAddress1, lwAAddress2: LongWord);
begin
  lwAddress1 := lwAAddress1;
  lwAddress2 := lwAAddress2;
end;

////////////////////////////////////////////////////////////////////////////////
// TMoveTreeBaseCache

constructor TMoveTreeBaseCache.Create;
begin
  raise Exception.Create(ClassName + ' cannot be instaniated directly!');
end;


constructor TMoveTreeBaseCache.FCreate(const InitialPos: TChessPosition;
  const InitialAddress: TMoveTreeAddress);
begin
  inherited Create;

  m_InitialPos := InitialPos;
  m_InitialAddress := InitialAddress;
  m_PosAddresses := TObjectList.Create;

  FClear;
end;


destructor TMoveTreeBaseCache.Destroy;
begin
  m_PosAddresses.Free;
  inherited;
end;


function TMoveTreeBaseCache.Get(const Pos: TChessPosition; out Addresses: TMoveTreeAddressArr): boolean;
var
  Item: TPosAddressItem;
begin
  Result := FGet(Pos, Item);
  if (Result) then
    Addresses := Item.Addresses;
end;


function TMoveTreeBaseCache.FGet(const Pos: TChessPosition; out AItem: TPosAddressItem): boolean;
var
  i: integer;
  Item: TPosAddressItem;
begin
  Result := TRUE;

  for i := m_iLastItemIndex to m_PosAddresses.Count - 1 do
  begin
    Item := TPosAddressItem(m_PosAddresses[i]);
    if (Pos.Equals(Item.Pos)) then
    begin
      AItem := Item;
      m_iLastItemIndex := i;
      exit;
    end;
  end;

  for i := m_iLastItemIndex - 1 downto 0 do
  begin
    Item := TPosAddressItem(m_PosAddresses[i]);
    if (Pos.Equals(Item.Pos)) then
    begin
      AItem := Item;
      m_iLastItemIndex := i;
      exit;
    end;
  end;

  Result := FALSE;
end;


procedure TMoveTreeBaseCache.FAdd(const Pos: TChessPosition; const Address: TMoveTreeAddress);
var
  Item: TPosAddressItem;
begin
  if (FGet(Pos, Item)) then
    Item.FAddAddress(Address)
  else
  begin
    m_PosAddresses.Add(TPosAddressItem.FCreate(Pos, Address));
    m_iLastItemIndex := m_PosAddresses.Count - 1;
  end;
end;


procedure TMoveTreeBaseCache.FClear;
begin
  m_PosAddresses.Clear;
  m_iLastItemIndex := 0;
  FAdd(m_InitialPos, m_InitialAddress);
end;

////////////////////////////////////////////////////////////////////////////////
// TPosAddressItem

constructor TPosAddressItem.Create;
begin
  raise Exception.Create(ClassName + ' cannot be instaniated directly!');
end;


constructor TPosAddressItem.FCreate(const APos: TChessPosition; const AAddress: TMoveTreeAddress);
begin
  inherited Create;

  m_Pos := APos;
  FAddAddress(AAddress);
end;


procedure TPosAddressItem.FAddAddress(const AAddress: TMoveTreeAddress);
begin
  SetLength(m_Addresses, Length(m_Addresses) + 1);
  m_Addresses[High(m_Addresses)] := AAddress;
end;

////////////////////////////////////////////////////////////////////////////////
// TMoveTreeAddress

procedure TMoveTreeAddress.FInit(lwAPosition: LongWord; wAOffset: Word);
begin
  self.lwPosition := lwAPosition;
  self.wOffset := wAOffset;
end;

////////////////////////////////////////////////////////////////////////////////
// TMovePosAddress

procedure TMovePosAddress.FInit(const AMove: TMoveAbs; const APos: TChessPosition;
  const AAddress: TMoveTreeAddress);
begin
  self.move := AMove;
  self.pos := APos;
  self.address := AAddress;
end;


////////////////////////////////////////////////////////////////////////////////
// TDataFinder

constructor TDataFinder.Create(ABase: TMoveTreeBase);
begin
  inherited Create;
  m_Base := ABase;
end;

function TDataFinder.FReadBagFromStream(out ABag: TDataBag): boolean;
begin
  Result := m_Base.BaseStream.ReadBagFromStream(ABag);
end;


function TDataFinder.FReadBagFromStream(lwPosition: LongWord; out ABag: TDataBag): boolean;
begin
  Result := m_Base.BaseStream.ReadBagFromStream(lwPosition, ABag);
end;


function TDataFinder.FJumpNear(const Data: TDataBag; out NextDataBag: TDataBag): boolean;
var
  lwPositionBase, lwJumpPosition: LongWord;
  DataBag: TDataBag;
  bRead: boolean;
begin
  lwPositionBase := m_lwPosition - 1;

  lwJumpPosition := lwPositionBase + Data.FToNearPointer;

  FReadBagFromStream(lwJumpPosition, DataBag);
  Assert(DataBag.FIsMove);

  Result := RF1(DataBag);
  if (Result) then
  begin
    m_lwLastPosition := m_lwPosition;
    FReadBagFromStream(m_lwPosition, NextDataBag);
  end
  else
  begin
    bRead := FReadBagFromStream(NextDataBag);
    Assert(bRead);
    m_lwLastPosition := lwJumpPosition + 1;
  end;

  m_lwPosition := m_lwLastPosition + 1;

  if (not Result) then
    RP4;
end;


function TDataFinder.FJumpFar(const HiData: TDataBag; out NextDataBag: TDataBag): boolean;
var
  LowData: TDataBag;
  lwPositionBase, lwJumpPosition: LongWord;
  DataBag: TDataBag;
  bRead: boolean;
begin
  lwPositionBase := m_lwPosition - 1;

  FReadBagFromStream(m_lwPosition, LowData);
  inc(m_lwPosition);

  lwJumpPosition := lwPositionBase + _TDataBag.FToFarPointer(HiData, LowData);

  FReadBagFromStream(lwJumpPosition, DataBag);
  Assert(DataBag.FIsMove);

  FReadBagFromStream(NextDataBag);
  m_lwLastPosition := lwJumpPosition + 1;

  Result := RF1(DataBag);
  if (Result) then
    exit;

  bRead := FReadBagFromStream(NextDataBag);
  Assert(bRead);
  inc(m_lwLastPosition);

  m_lwPosition := m_lwLastPosition + 1;

  RP4;
end;


function TDataFinder.RFind(lwPosition: LongWord): boolean;
var
  DataBagFromStream: TDataBag;
  bHasDataFlag: boolean;
begin
  Result := FALSE;

  m_lwPosition := lwPosition;
  m_lwLastPosition := lwPosition;

  if (not RF3) then
    exit;

  if (not FReadBagFromStream(m_lwPosition, DataBagFromStream)) then
    exit;

  bHasDataFlag := TRUE;
  inc(m_lwPosition);

  while (bHasDataFlag) do
  begin
    if (DataBagFromStream.FIsMove) then
    begin
      if (not RF2(DataBagFromStream)) then
        exit;
      if (RIsDataFromJump) then
        bHasDataFlag := FReadBagFromStream(m_lwPosition, DataBagFromStream)
      else
        bHasDataFlag := FReadBagFromStream(DataBagFromStream);

      Assert(bHasDataFlag);
      m_lwLastPosition := m_lwPosition;
      inc(m_lwPosition);
    end
    else if (DataBagFromStream.FIsNearPointer) then
    begin
      if (not FJumpNear(DataBagFromStream, DataBagFromStream)) then
        continue;
    end
    else if (DataBagFromStream.FIsFarPointer) then
    begin
      if (not FJumpFar(DataBagFromStream, DataBagFromStream)) then
        continue;
    end
    else if (DataBagFromStream.FIsEndDataTag) then
      break
    else
      Assert(FALSE);

    bHasDataFlag := RF3;
  end;

  Result := TRUE;

end;


function TDataFinder.RIsDataFromJump: boolean;
begin
  Result := (m_lwLastPosition > m_lwPosition);
end;


procedure TDataFinder.RP4;
begin
end;

////////////////////////////////////////////////////////////////////////////////
// TInsertionPointDataFinder

function TInsertionPointDataFinder.Find(lwPosition: LongWord;
  const DataIterator: TMovesDataIterator; out InsertionPoint: TInsertionPoint): boolean;
begin
  m_DataIterator := DataIterator;
  m_InsertionPoint.FInit(lwPosition, lwPosition + 1);

  Result := RFind(lwPosition);

  InsertionPoint := m_InsertionPoint;
end;


function TInsertionPointDataFinder.RF1(const DataBag: TDataBag): boolean;
var
  bRes: boolean;
begin
  Result := DataBag.FEquals(m_DataIterator.GetLastDataBag);
  if (not Result) then
    exit;

  with m_DataIterator.GetLastMove do
    bRes := Base.ChessRulesEngine.DoMove(i0, j0, i, j, prom_fig);
  Assert(bRes);
end;


function TInsertionPointDataFinder.RF2(const DataBag: TDataBag): boolean;
begin
  Result := RF1(DataBag);
  if (not Result) then
    m_InsertionPoint.FInit(LastPosition, Position);
end;


function TInsertionPointDataFinder.RF3: boolean;
begin
  Result := m_DataIterator.HasNext;
  if (Result) then
    m_DataIterator.GetNextMove;
end;

////////////////////////////////////////////////////////////////////////////////
// TNextLinesBuilderDataFinder

procedure TNextLinesBuilderDataFinder.Find(const APos: TChessPosition;
  const Address: TMoveTreeAddress; out Datas: TMovePosAddressArr);
begin
  SetLength(m_Datas, 0);

  m_wMovesCount := Address.wOffset;

  m_Address := Address;
  m_Address.wOffset := 0;

  ChessRulesEngine.SetPosition(APos);

  RFind(Address.lwPosition);

  Datas := m_Datas;
end;


function TNextLinesBuilderDataFinder.FF5(const DataBag: TDataBag; bJump: boolean): boolean;
var
  bRes: boolean;
begin
  if (bJump or RIsDataFromJump) then
    inc(m_Address.wOffset)
  else
    m_Address.FInit(Position, 0);

  Result := (m_wMovesCount > 0);
  if (Result)  then
    dec(m_wMovesCount)
  else
  begin
    with DataBag.FToMove do
      bRes := ChessRulesEngine.DoMove(i0, j0, i, j, prom_fig);
    Assert(bRes);
    FCollectDatas;
    ChessRulesEngine.TakeBack;
  end;
end;


function TNextLinesBuilderDataFinder.RF1(const DataBag: TDataBag): boolean;
begin
  Result := FF5(DataBag, TRUE);
end;


function TNextLinesBuilderDataFinder.RF2(const DataBag: TDataBag): boolean;
begin
  Result := FF5(DataBag, FALSE);
end;


function TNextLinesBuilderDataFinder.RF3: boolean;
begin
  Result := TRUE;
end;


procedure TNextLinesBuilderDataFinder.RP4;
begin
  m_Address.FInit(LastPosition, 0);
end;


function TNextLinesBuilderDataFinder.FGetChessRulesEngine: TChessRulesEngine;
begin
  Result := Base.ChessRulesEngine;
end;


procedure TNextLinesBuilderDataFinder.FCollectDatas;
var
  Data: TMovePosAddress;
begin
  Data.FInit(ChessRulesEngine.lastMove^, ChessRulesEngine.Position^, m_Address);
  SetLength(m_Datas, Length(m_Datas) + 1);
  m_Datas[High(m_Datas)] := Data;
end;

////////////////////////////////////////////////////////////////////////////////
// TMoveTreeStream

constructor TMoveTreeStream.Create;
begin
  raise Exception.Create(ClassName + ' cannot be instaniated directly!');
end;


constructor TMoveTreeStream.FCreateFileStream(const BaseFileName: TFileName);
var
  FileHandle: THandle;
begin
  inherited Create;

  if (not FileExists(BaseFileName)) then
  begin
    FileHandle := FileCreate(BaseFileName);
    FileClose(FileHandle);
  end;

  m_InnerStream := TFileStream.Create(BaseFileName, fmOpenReadWrite, fmShareDenyWrite);

  FSetDBVersion;
end;


constructor TMoveTreeStream.FCreateMemoryStream;
begin
  inherited Create;

  m_InnerStream := TMemoryStream.Create;
  FSetDBVersion;
end;


destructor TMoveTreeStream.Destroy;
begin
  m_InnerStream.Free;
  inherited;
end;


procedure TMoveTreeStream.FSetDBVersion;
var
  wVersion: Word;
begin
  m_iDBVersion := DB_VERSION; // default version

  if (m_InnerStream.Size > 0) then
  begin
    if (not FReadHeader(wVersion)) then
      raise EMoveTreeBase.Create('Wrong MVT base format!');
    m_iDBVersion := wVersion;
  end
  else
  begin
    wVersion := m_iDBVersion;
    FWriteHeader(wVersion);
  end;

  m_wHeaderSize := SizeOf(wVersion);
end;


function TMoveTreeStream.FReadHeader(out wVersion: Word): boolean;
begin
  m_InnerStream.Position := 0;
  Result := (m_InnerStream.Read(wVersion, SizeOf(wVersion)) = SizeOf(wVersion));
end;


procedure TMoveTreeStream.FWriteHeader(const wVersion: Word);
begin
  m_InnerStream.Position := 0;
  m_InnerStream.Write(wVersion, SizeOf(wVersion));
end;


function TMoveTreeStream.ReadBagFromStream(out ABag: TDataBag): boolean;
begin
  Result := (m_InnerStream.Read(ABag, SizeOf(ABag)) = SizeOf(ABag));
end;


function TMoveTreeStream.ReadBagFromStream(lwPosition: LongWord;
  out ABag: TDataBag): boolean;
begin
  m_InnerStream.Position := SizeOf(TDataBag) * lwPosition + m_wHeaderSize;
  Result := (m_InnerStream.Read(ABag, SizeOf(ABag)) = SizeOf(ABag));
end;


procedure TMoveTreeStream.WriteBagToStream(const ABag: TDataBag);
begin
  m_InnerStream.WriteBuffer(ABag, SizeOf(ABag));
end;


procedure TMoveTreeStream.WriteBagToStream(lwPosition: LongWord; const ABag: TDataBag);
begin
  m_InnerStream.Position := SizeOf(TDataBag) * lwPosition + m_wHeaderSize;
  m_InnerStream.WriteBuffer(ABag, SizeOf(ABag));
end;


procedure TMoveTreeStream.WriteBagToStreamEnd(const ABag: TDataBag);
begin
  m_InnerStream.Seek(0, soEnd);
  m_InnerStream.WriteBuffer(ABag, SizeOf(ABag));
end;


function TMoveTreeStream.FGetSize: Int64;
begin
  Result := (m_InnerStream.Size - m_wHeaderSize) div SizeOf(TDataBag);
end;

end.
