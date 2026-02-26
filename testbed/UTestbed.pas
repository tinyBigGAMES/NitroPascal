{===============================================================================
  NitroPascal™ - Modern Pascal * C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
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
  Parse,
  NitroPascal;

// ---------------------------------------------------------------------------
// TestFile — compile and run a NitroPascal source file by base test name
// ---------------------------------------------------------------------------

procedure TestFile(
  const ATestName: string;
  const APlatform: TParseTargetPlatform = tpWin64;
  const ALevel: TParseOptimizeLevel = olDebug); overload;
var
  LNP: TNitroPascal;
  LError: TParseError;
begin
  LNP := TNitroPascal.Create();
  try
    LNP.SetSourceFile('..\bin\res\tests\' + ATestName + '.pas');
    LNP.SetOutputPath('output');
    LNP.SetTargetPlatform(APlatform);
    LNP.SetBuildMode(bmExe);
    LNP.SetOptimizeLevel(ALevel);

    LNP.SetOutputCallback(
      procedure(const ALine: string; const AUserData: Pointer)
      begin
        TParseUtils.Print(ALine);
      end);

    LNP.SetStatusCallback(
      procedure(const AText: string; const AUserData: Pointer)
      begin
        TParseUtils.PrintLn(AText);
      end);

    if not LNP.Compile(True) then
    begin
      TParseUtils.PrintLn('');
      TParseUtils.PrintLn(COLOR_RED + 'NitroPascal compilation failed.');

      if LNP.HasErrors() then
      begin
        TParseUtils.PrintLn(COLOR_RED + 'Errors: ' +
          IntToStr(LNP.GetErrors().ErrorCount()));
        for LError in LNP.GetErrors().GetItems() do
          TParseUtils.PrintLn(COLOR_RED + '  ' + LError.ToFullString());
      end
      else
        TParseUtils.PrintLn(COLOR_RED +
          'No error details collected (check build output above).');

      Exit;
    end;

    // Display warnings even on success
    if LNP.HasErrors() then
      for LError in LNP.GetErrors().GetItems() do
        TParseUtils.PrintLn(COLOR_YELLOW + '  ' + LError.ToFullString());

    if LNP.GetLastExitCode() <> 0 then
      TParseUtils.PrintLn(COLOR_RED + 'Program exited with code: ' +
        IntToStr(LNP.GetLastExitCode()));

  finally
    LNP.Free();
  end;
end;

// ---------------------------------------------------------------------------
// RunTestbed
// ---------------------------------------------------------------------------

procedure TestFile(
  const ATestNum: Integer;
  const APlatform: TParseTargetPlatform = tpWin64;
  const ALevel: TParseOptimizeLevel = olDebug); overload;
var
  LTestName: string;
begin

  case ATestNum of
    00: LTestName := 'test_program_testbed';
    01: LTestName := 'test_program_repeat_until';
    02: LTestName := 'test_program_exit_break_continue';
    03: LTestName := 'test_program_case_of';
    04: LTestName := 'test_program_const_block';
    05: LTestName := 'test_program_type_record';
    06: LTestName := 'test_program_arrays_static';
    07: LTestName := 'test_program_arrays_dynamic';
    08: LTestName := 'test_program_set';
    09: LTestName := 'test_program_char_hex';
    10: LTestName := 'test_program_pointers';
    11: LTestName := 'test_program_intrinsics';
    12: LTestName := 'test_program_exceptions';
  else
    LTestName := '';
  end;

  if not LTestName.IsEmpty then
    TestFile(LTestName, APlatform, ALevel);
end;

procedure RunTestbed();
var
  LPlatform: TParseTargetPlatform;
  LLevel: TParseOptimizeLevel;
  LTestNum: Integer;
begin
  try

    { Language }
    LPlatform := tpWin64;
    //LPlatform := tpLinux64;

    LLevel := olDebug;
    //LLevel := olReleaseSmall;

    LTestNum := 11;

    TestFile(LTestNum, LPlatform, LLevel);

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
