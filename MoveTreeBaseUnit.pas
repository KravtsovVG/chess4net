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
    procedure FInit(const AMove: TMoveAbs);
    function FEquals(const Other: TDataBag): boolean;
    function FIsMove: boolean;
    function FIsNearPointer: boolean;
    function FToNearPointer: Word;
    function FIsFarPointer: boolean;
    function FToFarPointer(const HiData, LowData: TDataBag): LongWord;
    function FConvertFromNearPointer(lwPointer: LongWord; out Data: TDataBag): boolean;
    function FConvertFromFarPointer(lwPointer: LongWord; out HiData, LowData: TDataBag): boolean;
  end;

  TMoveAbsArr = array of TMoveAbs;

  TDataBagsIterator = class
  private
    m_Moves: TMoveAbsArr;
    m_iIndex: integer;
    constructor FCreate(const Moves: TMoveAbsArr);
  public
    constructor Create;
    function HasNext: boolean;
    function GetNext: TDataBag;
    function GetLast: TDataBag;
  end;

  TInsertionPoint = object
  public
    lwAddress1: LongWord;
    lwAddress2: LongWord;
  private
    procedure FInit(lwAddress: LongWord); overload;
    procedure FInit(lwAAddress1, lwAAddress2: LongWord); overload;
  end;

  TMoveTreeAddress = record
    lwPosition: LongWord;
    wOffset: Word;
  end;

  TMoveTreeBaseCache = class
  private
    m_InitialPos: TChessPosition;
    m_InitialAddress: TMoveTreeAddress;
    m_PosAddresses: TObjectList;
    m_iLastItemIndex: integer; // PP: optimization?
    constructor FCreate(const InitialPos: TChessPosition; const InitialAddress: TMoveTreeAddress);
    function FGet(const Pos: TChessPosition; out Address: TMoveTreeAddress): boolean;
    procedure FAdd(const Pos: TChessPosition; const Address: TMoveTreeAddress);
  public
    constructor Create;
    destructor Destroy; override;
  end;


  TMovePosAddress = record
    move: TMoveAbs;
    pos: TChessPosition;
    address: TMoveTreeAddress;
  end;

  TMovePosAddressArr = array of TMovePosAddress;

  EMoveTreeBase = class(Exception);

  TMoveTreeBase = class
  private
    m_BaseStream: TStream;
    m_ChessRulesEngine: TChessRulesEngine;
    m_PosCache: TMoveTreeBaseCache;

    constructor FCreate;

    procedure FCreateFileStream(const BaseFileName: TFileName);
    procedure FCreateMemoryStream;
    procedure FDestroyStream;

    function FReadBagFromStream(out ABag: TDataBag): boolean; overload;
    function FReadBagFromStream(lwPosition: LongWord; out ABag: TDataBag): boolean; overload;
    procedure FWriteBagToStream(const ABag: TDataBag); overload;
    procedure FWriteBagToStream(lwPosition: LongWord; const ABag: TDataBag); overload;
    procedure FWriteBagToStreamEnd(const ABag: TDataBag);

    procedure FSaveDataToTree(const DataIterator: TDataBagsIterator);
    function FFindDataFromPosition(const DataIterator: TDataBagsIterator;
      lwPosition: LongWord): boolean; overload;
    function FFindDataFromPosition(const DataIterator: TDataBagsIterator;
      lwPosition: LongWord; out InsertionPoint: TInsertionPoint): boolean; overload;
    procedure FSaveDataFromPosition(const DataIterator: TDataBagsIterator;
      const InsertionPoint: TInsertionPoint);
    procedure FStartNearBranch(const Data: TDataBag; const InsertionPoint: TInsertionPoint);
    procedure FStartFarBranch(const DataHi, DataLow: TDataBag; const InsertionPoint: TInsertionPoint);

    procedure FFind(const Address: TMoveTreeAddress; out Datas: TMovePosAddressArr);

  protected
    constructor CreateForTest;

  public
    constructor Create(const strBaseName: string);
    destructor Destroy; override;
    procedure Add(const Moves: TMoveAbsArr);
    function Find(const Pos: TChessPosition; out Moves: TMoveAbsArr): boolean;
  end;

const
  _TDataBag: PDataBag = nil; // helper

implementation

type
  TPosAddressItem = class
  private
    m_Pos: TChessPosition;
    m_Address: TMoveTreeAddress;
  public
    constructor Create(const APos: TChessPosition; const AAddress: TMoveTreeAddress);
    property Pos: TChessPosition read m_Pos;
    property Address: TMoveTreeAddress read m_Address;
  end;

const
  BASE_FILE_EXT = 'mvt';
  TEST_STREAM_SIZE = 100 * 1024; // 100 Kb

  PROM_FIG_MARKER: array[TFigureName] of byte = ($00, $00, $40, $80, $C0, $00); // K, Q, R, B, N, P

  MOVE_DATA_MARKER = $00;
  NEAR_POINTER_DATA_MARKER = $80;
  NEAR_POINTER_DATA_MASK = NEAR_POINTER_DATA_MARKER - 1;
  FAR_POINTER_DATA_MARKER = $40;
  FAR_POINTER_DATA_MASK = FAR_POINTER_DATA_MARKER - 1;
  DATA_KIND_MASK = $C0;
  DATA_MASK = $3F;

  END_DATA_TAG: TDataBag = (btFirst: 0; btSecond: 0);

  INITIAL_ADDRESS: TMoveTreeAddress = (lwPosition: 0; wOffset: 0);

////////////////////////////////////////////////////////////////////////////////
// TMoveTreeBase

constructor TMoveTreeBase.FCreate;
begin
  inherited Create;

  m_ChessRulesEngine := TChessRulesEngine.Create;
  m_PosCache := TMoveTreeBaseCache.FCreate(m_ChessRulesEngine.Position^, INITIAL_ADDRESS);
end;


constructor TMoveTreeBase.Create(const strBaseName: string);
begin
  FCreate;
  FCreateFileStream(strBaseName + '.' + BASE_FILE_EXT);
end;


constructor TMoveTreeBase.CreateForTest;
begin
  FCreate;
  FCreateMemoryStream;
end;


destructor TMoveTreeBase.Destroy;
begin
  FDestroyStream;
  
  m_PosCache.Free;
  m_ChessRulesEngine.Free;
  
  inherited;
end;


procedure TMoveTreeBase.FCreateFileStream(const BaseFileName: TFileName);
var
  FileHandle: THandle;
begin
  if (not FileExists(BaseFileName)) then
  begin
    FileHandle := FileCreate(BaseFileName);
    FileClose(FileHandle);
  end;

  m_BaseStream := TFileStream.Create(BaseFileName, fmOpenReadWrite, fmShareDenyWrite);
end;


procedure TMoveTreeBase.FCreateMemoryStream;
begin
  m_BaseStream := TMemoryStream.Create;
  m_BaseStream.Size := TEST_STREAM_SIZE;
  m_BaseStream.Position := 0;
end;


procedure TMoveTreeBase.FDestroyStream;
begin
  FreeAndNil(m_BaseStream);
end;


function TMoveTreeBase.FReadBagFromStream(out ABag: TDataBag): boolean;
begin
  Result := (m_BaseStream.Read(ABag, SizeOf(ABag)) = SizeOf(ABag));
end;


function TMoveTreeBase.FReadBagFromStream(lwPosition: LongWord;
  out ABag: TDataBag): boolean;
begin
  m_BaseStream.Position := lwPosition;
  Result := (m_BaseStream.Read(ABag, SizeOf(ABag)) = SizeOf(ABag));
end;


procedure TMoveTreeBase.FWriteBagToStream(const ABag: TDataBag);
begin
  m_BaseStream.WriteBuffer(ABag, SizeOf(ABag));
end;


procedure TMoveTreeBase.FWriteBagToStream(lwPosition: LongWord; const ABag: TDataBag);
begin
  m_BaseStream.Position := lwPosition;
  m_BaseStream.WriteBuffer(ABag, SizeOf(ABag));
end;


procedure TMoveTreeBase.FWriteBagToStreamEnd(const ABag: TDataBag);
begin
  m_BaseStream.Seek(0, soEnd);
  m_BaseStream.WriteBuffer(ABag, SizeOf(ABag));
end;


procedure TMoveTreeBase.Add(const Moves: TMoveAbsArr);
var
  Iterator: TDataBagsIterator;
begin
  Iterator := TDataBagsIterator.FCreate(Moves);
  try
    FSaveDataToTree(Iterator);
  finally
    Iterator.Free;
  end;
end;


procedure TMoveTreeBase.FSaveDataToTree(const DataIterator: TDataBagsIterator);
var
  InsertionPoint: TInsertionPoint;
begin
  if (FFindDataFromPosition(DataIterator, 0, InsertionPoint)) then
    exit;
  FSaveDataFromPosition(DataIterator, InsertionPoint);
end;


function TMoveTreeBase.FFindDataFromPosition(const DataIterator: TDataBagsIterator;
  lwPosition: LongWord): boolean;
var
  DummyInsertionPoint: TInsertionPoint;
begin
  Result := FFindDataFromPosition(DataIterator, lwPosition, DummyInsertionPoint);
end;


function TMoveTreeBase.FFindDataFromPosition(const DataIterator: TDataBagsIterator;
  lwPosition: LongWord; out InsertionPoint: TInsertionPoint): boolean;

var
  lwLastPosition: LongWord;

  function NJumpNear(const Data: TDataBag; out NextDataBag: TDataBag): boolean;
  var
    lwPositionBase, lwJumpPosition: LongWord;
    DataBag: TDataBag;
    bRead: boolean;
  begin
    lwPositionBase := lwPosition - SizeOf(TDataBag);

    lwJumpPosition := lwPositionBase + Data.FToNearPointer;

    FReadBagFromStream(lwJumpPosition, DataBag);
    Assert(DataBag.FIsMove);

    Result := DataBag.FEquals(DataIterator.GetLast);
    if (Result) then
    begin
      lwLastPosition := lwPosition;
      FReadBagFromStream(lwPosition, NextDataBag);
    end
    else
    begin
      bRead := FReadBagFromStream(NextDataBag);
      Assert(bRead);
      lwLastPosition := lwJumpPosition + SizeOf(TDataBag);
    end;

    lwPosition := lwLastPosition + SizeOf(TDataBag);
  end;

  function NJumpFar(const HiData: TDataBag; out NextDataBag: TDataBag): boolean;
  var
    LowData: TDataBag;
    lwPositionBase, lwJumpPosition: LongWord;
    DataBag: TDataBag;
    bRead: boolean;
  begin
    lwPositionBase := lwPosition - SizeOf(TDataBag);

    FReadBagFromStream(lwPosition, LowData);
    inc(lwPosition, SizeOf(TDataBag));

    lwJumpPosition := lwPositionBase + _TDataBag.FToFarPointer(HiData, LowData);

    FReadBagFromStream(lwJumpPosition, DataBag);
    Assert(DataBag.FIsMove);

    FReadBagFromStream(NextDataBag);
    lwLastPosition := lwJumpPosition + SizeOf(TDataBag);

    Result := DataBag.FEquals(DataIterator.GetLast);
    if (Result) then
      exit;

    bRead := FReadBagFromStream(NextDataBag);
    Assert(bRead);
    inc(lwLastPosition, SizeOf(TDataBag));

    lwPosition := lwLastPosition + SizeOf(TDataBag);
  end;

var
  DataBag: TDataBag;
  DataBagFromStream: TDataBag;
  bHasDataFlag: boolean;
begin // .FFindDataFromPosition
  InsertionPoint.FInit(lwPosition, lwPosition + SizeOf(TDataBag));

  if (not DataIterator.HasNext) then
  begin
    Result := TRUE;
    exit;
  end;

  Result := FALSE;

  DataBag := DataIterator.GetNext;

  lwLastPosition := lwPosition;
  bHasDataFlag := FReadBagFromStream(lwPosition, DataBagFromStream);
  if (not bHasDataFlag) then
    exit;

  inc(lwPosition, SizeOf(TDataBag));

  repeat
    if (DataBagFromStream.FIsMove) then
    begin
      if (not DataBagFromStream.FEquals(DataBag)) then
      begin
        InsertionPoint.FInit(lwLastPosition, lwPosition);
        exit;
      end;
      if (lwLastPosition < lwPosition) then
        bHasDataFlag := FReadBagFromStream(DataBagFromStream)
      else
        bHasDataFlag := FReadBagFromStream(lwPosition, DataBagFromStream);
      Assert(bHasDataFlag);
      lwLastPosition := lwPosition;
      inc(lwPosition, SizeOf(TDataBag));
    end
    else if (DataBagFromStream.FIsNearPointer) then
    begin
      if (not NJumpNear(DataBagFromStream, DataBagFromStream)) then
        continue;
    end
    else if (DataBagFromStream.FIsFarPointer) then
    begin
      if (not NJumpFar(DataBagFromStream, DataBagFromStream)) then
        continue;
    end;

    bHasDataFlag := DataIterator.HasNext;
    if (bHasDataFlag) then
      DataBag := DataIterator.GetNext;

  until (not bHasDataFlag);

  Result := TRUE;
end;


procedure TMoveTreeBase.FSaveDataFromPosition(const DataIterator: TDataBagsIterator;
  const InsertionPoint: TInsertionPoint);
var
  lwAddressOffset: LongWord;
  DataOffsetHi, DataOffsetLow: TDataBag;
begin
  lwAddressOffset := m_BaseStream.Size - (InsertionPoint.lwAddress2 - SizeOf(TDataBag));
  if (lwAddressOffset > 0) then
  begin
    if (_TDataBag.FConvertFromNearPointer(lwAddressOffset, DataOffsetLow)) then
      FStartNearBranch(DataOffsetLow, InsertionPoint)
    else if (_TDataBag.FConvertFromFarPointer(lwAddressOffset, DataOffsetHi, DataOffsetLow)) then
      FStartFarBranch(DataOffsetHi, DataOffsetLow, InsertionPoint)
    else
      raise EMoveTreeBase.Create('Base file has become too big!');
  end;

  FWriteBagToStreamEnd(DataIterator.GetLast);
  while (DataIterator.HasNext) do
    FWriteBagToStream(DataIterator.GetNext);
  FWriteBagToStream(END_DATA_TAG);
end;


procedure TMoveTreeBase.FStartNearBranch(const Data: TDataBag;
  const InsertionPoint: TInsertionPoint);
var
  SavedData: TDataBag;
  bRead: boolean;
begin
  bRead := FReadBagFromStream(InsertionPoint.lwAddress1, SavedData);
  Assert(bRead);

  FWriteBagToStreamEnd(SavedData);

  FWriteBagToStream(InsertionPoint.lwAddress1, Data);
end;


procedure TMoveTreeBase.FStartFarBranch(const DataHi, DataLow: TDataBag;
  const InsertionPoint: TInsertionPoint);
var
  SavedData1, SavedData2: TDataBag;
  bRead: boolean;
begin
  bRead := FReadBagFromStream(InsertionPoint.lwAddress1, SavedData1);
  Assert(bRead);

  bRead := FReadBagFromStream(InsertionPoint.lwAddress2, SavedData2);
  Assert(bRead);

  FWriteBagToStreamEnd(SavedData1);
  FWriteBagToStream(SavedData2);

  FWriteBagToStream(InsertionPoint.lwAddress1, DataHi);
  FWriteBagToStream(InsertionPoint.lwAddress2, DataLow);
end;


function TMoveTreeBase.Find(const Pos: TChessPosition; out Moves: TMoveAbsArr): boolean;
var
  Address: TMoveTreeAddress;
  Datas: TMovePosAddressArr;
  i: integer;
begin
  Result := FALSE;

  if (not m_PosCache.FGet(Pos, Address)) then
    exit;

  FFind(Address, Datas);

  SetLength(Moves, Length(Datas));
  for i := Low(Datas) to High(Datas) do
  begin
    Moves[i] := Datas[i].move;
    m_PosCache.FAdd(Datas[i].pos, Datas[i].address);
  end;

  Result := TRUE;
end;


procedure TMoveTreeBase.FFind(const Address: TMoveTreeAddress; out Datas: TMovePosAddressArr);
var
  lwLastPosition: LongWord;
  lwPosition: LongWord;
  DataBag: TDataBag;
  bHasDataFlag: boolean;
begin
  SetLength(Datas, 0);
  
(* // TODO:
  lwLastPosition := Address.lwPosition;
  lwPosition := lwLastPosition;

  bHasDataFlag := FReadBagFromStream(lwPosition, DataBag);
  if (not bHasDataFlag) then
    exit;

  inc(lwPosition, SizeOf(TDataBag));

  repeat
    if (DataBag.FIsMove) then
    begin
      if (lwLastPosition < lwPosition) then
        bHasDataFlag := FReadBagFromStream(DataBagFromStream)
      else
        bHasDataFlag := FReadBagFromStream(lwPosition, DataBagFromStream);
      Assert(bHasDataFlag);
      lwLastPosition := lwPosition;
      inc(lwPosition, SizeOf(TDataBag));
    end
    else if (DataBagFromStream.FIsNearPointer) then
    begin
      if (not NJumpNear(DataBagFromStream, DataBagFromStream)) then
        continue;
    end
    else if (DataBagFromStream.FIsFarPointer) then
    begin
      if (not NJumpFar(DataBagFromStream, DataBagFromStream)) then
        continue;
    end;

    bHasDataFlag := DataIterator.HasNext;
    if (bHasDataFlag) then
      DataBag := DataIterator.GetNext;

  until (not bHasDataFlag);

  Result := TRUE;
*)
end;

////////////////////////////////////////////////////////////////////////////////
// TDataBagsIterator

constructor TDataBagsIterator.Create;
begin
  raise Exception.Create(ClassName + ' cannot be instaniated directly!');
end;


constructor TDataBagsIterator.FCreate(const Moves: TMoveAbsArr);
begin
  inherited Create;
  m_Moves := Moves;
end;


function TDataBagsIterator.HasNext: boolean;
begin
  Result := (m_iIndex < Length(m_Moves));
end;


function TDataBagsIterator.GetNext: TDataBag;
begin
  Result.FInit(m_Moves[m_iIndex]);
  inc(m_iIndex)
end;


function TDataBagsIterator.GetLast: TDataBag;
begin
  Result.FInit(m_Moves[m_iIndex - 1]);
end;

////////////////////////////////////////////////////////////////////////////////
// TDataBag

procedure TDataBag.FInit(const AMove: TMoveAbs);
begin
  btFirst := 8 * (AMove.j0 - 1) + AMove.i0 - 1;
  btSecond := (8 * (AMove.j - 1) + AMove.i - 1) or PROM_FIG_MARKER[AMove.prom_fig];
end;


function TDataBag.FEquals(const Other: TDataBag): boolean;
begin
  Result := ((btFirst = Other.btFirst) and (btSecond = Other.btSecond));
end;


function TDataBag.FIsMove: boolean;
begin
  Result := ((btFirst and DATA_KIND_MASK) = MOVE_DATA_MARKER);
end;


function TDataBag.FIsNearPointer: boolean;
begin
  Result := ((btFirst and DATA_KIND_MASK) = NEAR_POINTER_DATA_MARKER);
end;


function TDataBag.FIsFarPointer: boolean;
begin
  Result := ((btFirst and DATA_KIND_MASK) = FAR_POINTER_DATA_MARKER);
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
  Result := (lwPointer <= MAX_VALUE);
  if (not Result) then
    exit;

  Data.btSecond := lwPointer and $FF;
  Data.btFirst := ((lwPointer shr 8) and NEAR_POINTER_DATA_MASK) or NEAR_POINTER_DATA_MARKER;
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
end;


destructor TMoveTreeBaseCache.Destroy;
begin
  m_PosAddresses.Free;
  inherited;
end;


function TMoveTreeBaseCache.FGet(const Pos: TChessPosition; out Address: TMoveTreeAddress): boolean;
var
  i: integer;
  Item: TPosAddressItem;
begin
  Result := TRUE;

  if (m_InitialPos.Equals(Pos)) then
  begin
    Address := m_InitialAddress;
    exit;
  end;

  for i := m_iLastItemIndex to m_PosAddresses.Count - 1 do
  begin
    Item := TPosAddressItem(m_PosAddresses[i]);
    if (Pos.Equals(Item.Pos)) then
    begin
      Address := Item.Address;
      m_iLastItemIndex := i;
    end;
    exit;
  end;

  for i := m_iLastItemIndex - 1 downto 0 do
  begin
    Item := TPosAddressItem(m_PosAddresses[i]);
    if (Pos.Equals(Item.Pos)) then
    begin
      Address := Item.Address;
      m_iLastItemIndex := i;
    end;
    exit;
  end;

  Result := FALSE;
end;


procedure TMoveTreeBaseCache.FAdd(const Pos: TChessPosition; const Address: TMoveTreeAddress);
var
  DummyAddress: TMoveTreeAddress;
begin
  if (FGet(Pos, DummyAddress)) then
    exit;

  m_PosAddresses.Add(TPosAddressItem.Create(Pos, Address));
  m_iLastItemIndex := m_PosAddresses.Count - 1;
end;

////////////////////////////////////////////////////////////////////////////////
// TPosAddressItem

constructor TPosAddressItem.Create(const APos: TChessPosition; const AAddress: TMoveTreeAddress);
begin
  inherited Create;
  m_Pos := Pos;
  m_Address := AAddress;
end;

end.
