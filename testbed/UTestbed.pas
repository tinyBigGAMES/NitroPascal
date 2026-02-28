{===============================================================================
  NitroPascal(tm) - Modern Pascal * C Performance

  Copyright (c) 2025-present tinyBigGAMES(tm) LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit UTestbed;

interface

procedure RunTestbed();

implementation

uses
  System.SysUtils,
  System.IOUtils,
  Parse,
  NitroPascal,
  NitroPascal.Tester;

procedure StatusCallback(const AText: string; const AUserData: Pointer);
begin
  WriteLn(AText);
end;

procedure ShowErrors(const ACompiler: TNitroPascal);
var
  LError: TParseError;
begin
  if not ACompiler.HasErrors() then Exit;

  TParseUtils.PrintLn('');
  TParseUtils.PrintLn('--- Errors ---');
  for LError in ACompiler.GetErrors().GetItems() do
  begin
    case LError.Severity of
      esHint:
        TParseUtils.PrintLn(COLOR_CYAN   + '  ' + LError.ToFullString());
      esWarning:
        TParseUtils.PrintLn(COLOR_YELLOW + '  ' + LError.ToFullString());
      esError,
      esFatal:
        TParseUtils.PrintLn(COLOR_RED    + '  ' + LError.ToFullString());
    end;
  end;
end;

procedure RegisterTests(const ATester: TNPTester);
begin
  // Register all tests - ACanRun=True: build and run, False: build only
  {00} ATester.RegisterTest('test_program_testbed',             True);
  {01} ATester.RegisterTest('test_program_repeat_until',        True);
  {02} ATester.RegisterTest('test_program_exit_break_continue', True);
  {03} ATester.RegisterTest('test_program_case_of',             True);
  {04} ATester.RegisterTest('test_program_const_block',         True);
  {05} ATester.RegisterTest('test_program_type_record',         True);
  {06} ATester.RegisterTest('test_program_arrays_static',       True);
  {07} ATester.RegisterTest('test_program_arrays_dynamic',      True);
  {08} ATester.RegisterTest('test_program_set',                 True);
  {09} ATester.RegisterTest('test_program_char_hex',            True);
  {10} ATester.RegisterTest('test_program_pointers',            True);
  {11} ATester.RegisterTest('test_program_intrinsics',          True);
  {12} ATester.RegisterTest('test_program_exceptions',          True);
  {13} ATester.RegisterTest('test_program_math',                True);
  {14} ATester.RegisterTest('test_program_conversion',          True);
  {15} ATester.RegisterTest('test_program_memory',              True);
  {16} ATester.RegisterTest('test_program_string2',             True);
  {17} ATester.RegisterTest('test_program_fileio2',             True);
  {18} ATester.RegisterTest('test_program_fileio3',             True);
  {19} ATester.RegisterTest('test_program_unit',                True);
end;

procedure RunTests(const ATestName: string; const APlatform: TParseTargetPlatform = tpWin64; const AOptLevel: TParseOptimizeLevel = olDebug); overload;
const
  CTestFolder = '..\bin\res\tests';
var
  LTester:     TNPTester;
  LTestFolder: string;
begin
  LTestFolder := TPath.Combine(ExtractFilePath(ParamStr(0)), CTestFolder);

  LTester := TNPTester.Create();
  try
    LTester.TestFolder     := LTestFolder;
    LTester.OutputPath     := 'output';
    LTester.Verbose        := True;
    LTester.TargetPlatform := APlatform;
    LTester.OptimizeLevel  := AOptLevel;

    RegisterTests(LTester);

    if ATestName.IsEmpty() then
      LTester.RunAllTests()
    else
      LTester.RunTest(ATestName, True);

  finally
    LTester.Free();
  end;
end;

procedure RunTests(const AIndex: Integer; const APlatform: TParseTargetPlatform = tpWin64; const AOptLevel: TParseOptimizeLevel = olDebug); overload;
const
  CTestFolder = '..\bin\res\tests';
var
  LTester:     TNPTester;
  LTestFolder: string;
begin
  LTestFolder := TPath.Combine(ExtractFilePath(ParamStr(0)), CTestFolder);

  LTester := TNPTester.Create();
  try
    LTester.TestFolder     := LTestFolder;
    LTester.OutputPath     := 'output';
    LTester.Verbose        := True;
    LTester.TargetPlatform := APlatform;
    LTester.OptimizeLevel  := AOptLevel;

    RegisterTests(LTester);

    if AIndex < 0 then
      LTester.RunAllTests()
    else
      LTester.RunTestByIndex(AIndex);

  finally
    LTester.Free();
  end;
end;

procedure RunTestbed();
var
  LPlatform:  TParseTargetPlatform;
  LOptLevel:  TParseOptimizeLevel;
  LTestIndex: Integer;
begin
  try
    LOptLevel := olDebug;
   //LOptLevel := olReleaseSafe;
   //LOptLevel := olReleaseFast;
   //LOptLevel := olReleaseSmall;

    //LPlatform := tpWin64;
    LPlatform := tpLinux64;

    //LTest := 'test_program_intrinsics';
    //LTest := 'test_program_exceptions';

    //RunTests(LTest, LPlatform, LOptLevel);

    LTestIndex := -1;

    RunTests(LTestIndex, LPlatform, LOptLevel);

  except
    on E: Exception do
    begin
      TParseUtils.PrintLn('');
      TParseUtils.PrintLn(COLOR_RED + 'EXCEPTION: ' + E.Message);
    end;
  end;

  if TParseUtils.RunFromIDE() then
    TParseUtils.Pause();
end;

end.
