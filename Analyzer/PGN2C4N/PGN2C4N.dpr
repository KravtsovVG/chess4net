////////////////////////////////////////////////////////////////////////////////
// All code below is exclusively owned by author of Chess4Net - Pavel Perminov
// (packpaul@mail.ru, packpaul1@gmail.com).
// Any changes, modifications, borrowing and adaptation are a subject for
// explicit permition from the owner.

program PGN2C4N;

{$APPTYPE CONSOLE}

uses
  Windows, SysUtils,
  //
  PGN2C4NConvertorUnit in 'PGN2C4NConvertorUnit.pas',
  PGNParserUnit in '..\PGNParserUnit.pas',
  PGNWriterUnit in '..\PGNWriterUnit.pas',
  ChessRulesEngine in '..\..\ChessRulesEngine.pas',
  PlysTreeUnit in '..\PlysTreeUnit.pas',
  PlysProviderIntfUnit in '..\PlysProviderIntfUnit.pas',
  NonRefInterfacedObjectUnit in '..\..\NonRefInterfacedObjectUnit.pas';

procedure ShowHelp;
begin
  writeln;
  writeln('Converts files from PGN to C4N format.');
  writeln;
  writeln('PGN2C4N <input PGN file> <output C4N file>');
//  writeln;
//  writeln('-V', #9, 'proceed also variants.');
end;


procedure ShowError;
begin
  writeln('ERROR: wrong parameters or input file cannot be opened.');
  writeln;
  Halt(1);
end;

var
  InputFile, OutputFile: TFileName;

begin
  if (ParamCount = 0) then
  begin
    ShowHelp;
    Halt(0);
  end
  else if (ParamCount <> 2) then
  begin
    ShowError;
    Halt(1);    
  end;

  SetThreadLocale(1036); // TODO: set LCID over parameters

  InputFile := ParamStr(1);
  OutputFile := ParamStr(2);

  TPGN2C4nConvertor.Convert(InputFile, OutputFile);
end.
