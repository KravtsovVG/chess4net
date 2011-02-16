unit GameChessBoardTestsUnit;

interface

uses
  TestFramework, GUITesting,
  //
  GameChessBoardUnit;

type
  TGameChessBoardTests = class(TGuiTestCase)
  private
    m_TestResult: TTestResult;
    m_ChessBoard: TGameChessBoard;

    function FWasStopped: boolean;
    procedure FChessBoardHandler(e: TGameChessBoardEvent;
      d1: pointer = nil; d2: pointer = nil);

  public
    class function Suite: ITestSuite; override;
    procedure RunTest(testResult: TTestResult); override;

    procedure SetUp; override;
    procedure TearDown; override;

  published
    procedure TestResizing;
  end;

implementation

uses
  Forms, SysUtils;

////////////////////////////////////////////////////////////////////////////////
// TGameChessBoardTests

class function TGameChessBoardTests.Suite: ITestSuite;
var
  TestSuite: TTestSuite;
begin
  TestSuite := TTestSuite.Create('TGameChessBoard');

  TestSuite.AddTests(self);
  // or
  // TestSuite.AddTest(TChessRulesEngineTests.Create(<method name>));

  Result := TestSuite;
end;


procedure TGameChessBoardTests.RunTest(testResult: TTestResult);
begin
  m_TestResult := testResult;
  try
    inherited;
  finally
    m_TestResult := nil;
  end;
end;


procedure TGameChessBoardTests.SetUp;
begin
  inherited;
  m_ChessBoard := TGameChessBoard.Create(nil, FChessBoardHandler);
  GUI := m_ChessBoard;
  ActionDelay := 100;
  m_ChessBoard.Show;
end;


procedure TGameChessBoardTests.TearDown;
begin
  m_ChessBoard.Release;
  inherited;
end;


procedure TGameChessBoardTests.TestResizing;
begin
{$IFNDEF DEVELOP}
  exit;
{$ENDIF}

  while m_ChessBoard.Showing do
  begin
    Sleep(1);
    Application.ProcessMessages;
    if (FWasStopped) then
      break;
  end;
end;


function TGameChessBoardTests.FWasStopped: boolean;
begin
  Result := (Assigned(m_TestResult) and m_TestResult.WasStopped);
end;


procedure TGameChessBoardTests.FChessBoardHandler(e: TGameChessBoardEvent;
  d1: pointer = nil; d2: pointer = nil);
begin
  case e of
    cbeExit:
      m_ChessBoard.Shut; 
  end;
end;


initialization
  TestFramework.RegisterTest(TGameChessBoardTests.Suite);

end.
