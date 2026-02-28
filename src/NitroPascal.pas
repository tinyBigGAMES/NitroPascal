{===============================================================================
  NitroPascal™ - Modern Pascal * C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

(*
  NitroPascal — Phase 1

  A Pascal-flavored compiled language built on the Parse() toolkit.

  Usage:
    LNP := TNitroPascal.Create();
    LNP.SetSourceFile('hello.npp');
    LNP.SetOutputPath('output');
    LNP.SetTargetPlatform(tpWin64);
    LNP.SetBuildMode(bmExe);
    LNP.SetOptimizeLevel(olDebug);
    LNP.SetOutputCallback(...);
    LNP.SetStatusCallback(...);
    LNP.Compile(True);
*)

unit NitroPascal;

{$I NitroPascal.Defines.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Parse;

const
  NITROPASCAL_VERSION_MAJOR = 0;
  NITROPASCAL_VERSION_MINOR = 1;
  NITROPASCAL_VERSION_PATCH = 0;
  NITROPASCAL_VERSION_STR   = '0.1.0';

type

  { TNitroPascal }
  TNitroPascal = class(TParseOutputObject)
  private
    FParse:       TParse;
    FParsedUnits: TStringList;  // Tracks compiled unit deps (cycle detection)

    // Version info fields
    FAddVersionInfo: Boolean;
    FVIMajor: Word;
    FVIMinor: Word;
    FVIPatch: Word;
    FVIProductName: string;
    FVIDescription: string;
    FVIFilename: string;
    FVICompanyName: string;
    FVICopyright: string;
    FExeIcon: string;

    // Applies manifest, icon, and version info to the compiled output
    procedure ApplyPostBuildResources(const AExePath: string);

    // Extracts the unit names from a uses clause in a Pascal source file.
    // Returns an empty list if no uses clause is present.
    function ExtractUsesClause(const AFilename: string): TStringList;

    // Compiles a single unit dependency (codegen only — no Zig build).
    // Adds the generated .cpp to FParse for linking in the main build.
    // Returns False if compilation fails.
    function CompileUnitDep(const AUnitName, ASourceDir,
      AOutputPath: string): Boolean;

    // Recursively compiles all unit dependencies found in the uses clause
    // of ASourceFile, depth-first. Cycle-safe via FParsedUnits.
    function CompileUnitDeps(const ASourceFile,
      AOutputPath: string): Boolean;

  public
    constructor Create(); override;
    destructor Destroy(); override;

    // Source and output
    procedure SetSourceFile(const AFilename: string);
    procedure SetOutputPath(const APath: string);

    // Build configuration
    procedure SetTargetPlatform(const APlatform: TParseTargetPlatform);
    procedure SetBuildMode(const ABuildMode: TParseBuildMode);
    procedure SetOptimizeLevel(const ALevel: TParseOptimizeLevel);
    procedure SetSubsystem(const ASubsystem: TParseSubsystemType);

    // Version info configuration
    procedure SetAddVersionInfo(const AValue: Boolean);
    procedure SetVersionInfoMajor(const AValue: Word);
    procedure SetVersionInfoMinor(const AValue: Word);
    procedure SetVersionInfoPatch(const AValue: Word);
    procedure SetVersionInfoProductName(const AValue: string);
    procedure SetVersionInfoDescription(const AValue: string);
    procedure SetVersionInfoFilename(const AValue: string);
    procedure SetVersionInfoCompanyName(const AValue: string);
    procedure SetVersionInfoCopyright(const AValue: string);
    procedure SetExeIcon(const AValue: string);

    // Callbacks — forward into FParse
    procedure SetStatusCallback(const ACallback: TParseStatusCallback;
      const AUserData: Pointer = nil); override;
    procedure SetOutputCallback(const ACallback: TParseCaptureConsoleCallback;
      const AUserData: Pointer = nil); override;

    // Error access — delegates to FParse
    function HasErrors(): Boolean;
    function GetErrors(): TParseErrors;

    // Debug support
    procedure SetLineDirectives(const AEnabled: Boolean);

    // Pipeline
    function Compile(const ABuild: Boolean = True; const AAutoRun: Boolean = True): Boolean;
    function Run(): Cardinal;

    // Results
    function GetLastExitCode(): Cardinal;
    function GetVersionStr(): string;
  end;

implementation

uses
  System.IOUtils,
  NitroPascal.Lexer,
  NitroPascal.Grammar,
  NitroPascal.Semantics,
  NitroPascal.CodeGen;

{ TNitroPascal }

constructor TNitroPascal.Create();
begin
  inherited Create();

  FParse        := TParse.Create();
  FParsedUnits  := TStringList.Create();
  FParsedUnits.CaseSensitive := False;

  // Wire the complete NitroPascal language definition onto the internal instance
  ConfigLexer(FParse);
  ConfigGrammar(FParse);
  ConfigSemantics(FParse);
  ConfigCodeGen(FParse);

  // Enable #line directives so debuggers map generated C++ back to Pascal source
  FParse.SetLineDirectives(True);

  // Version info defaults
  FAddVersionInfo := False;
  FVIMajor        := 0;
  FVIMinor        := 0;
  FVIPatch        := 0;
  FVIProductName  := '';
  FVIDescription  := '';
  FVIFilename     := '';
  FVICompanyName  := '';
  FVICopyright    := '';
  FExeIcon        := '';
end;

destructor TNitroPascal.Destroy();
begin
  FreeAndNil(FParsedUnits);
  FreeAndNil(FParse);
  inherited Destroy();
end;

procedure TNitroPascal.ApplyPostBuildResources(const AExePath: string);
var
  LIconPath: string;
  LIsExe: Boolean;
  LIsDll: Boolean;
begin
  LIsExe := AExePath.EndsWith('.exe', True);
  LIsDll := AExePath.EndsWith('.dll', True);

  // Only applies to EXE and DLL files
  if not LIsExe and not LIsDll then
    Exit;

  // Add manifest (EXE only)
  if LIsExe then
  begin
    if TParseUtils.ResourceExist('EXE_MANIFEST') then
    begin
      if not TParseUtils.AddResManifestFromResource('EXE_MANIFEST', AExePath) then
        FParse.GetErrors().Add(esWarning, 'W980', 'Failed to add manifest to executable');
    end;
  end;

  // Add icon if specified (EXE only)
  if LIsExe and (FExeIcon <> '') then
  begin
    try
      LIconPath := FExeIcon;

      // Resolve relative paths against the source file directory
      if not TPath.IsPathRooted(LIconPath) then
        LIconPath := TPath.GetFullPath(
          TPath.Combine(TPath.GetDirectoryName(FExeIcon), LIconPath));

      if TFile.Exists(LIconPath) then
        TParseUtils.UpdateIconResource(AExePath, LIconPath)
      else
        FParse.GetErrors().Add(esWarning, 'W982',
          Format('Icon file not found: %s', [LIconPath]));
    except
      on E: Exception do
        FParse.GetErrors().Add(esWarning, 'W981',
          Format('Failed to add icon: %s', [E.Message]));
    end;
  end;

  // Add version info if enabled (EXE and DLL)
  if FAddVersionInfo then
  begin
    try
      TParseUtils.UpdateVersionInfoResource(
        AExePath,
        FVIMajor,
        FVIMinor,
        FVIPatch,
        FVIProductName,
        FVIDescription,
        FVIFilename,
        FVICompanyName,
        FVICopyright);
    except
      on E: Exception do
        FParse.GetErrors().Add(esWarning, 'W983',
          Format('Failed to add version info: %s', [E.Message]));
    end;
  end;
end;

procedure TNitroPascal.SetSourceFile(const AFilename: string);
begin
  FParse.SetSourceFile(AFilename);
end;

procedure TNitroPascal.SetOutputPath(const APath: string);
begin
  FParse.SetOutputPath(APath);
end;

procedure TNitroPascal.SetTargetPlatform(const APlatform: TParseTargetPlatform);
begin
  FParse.SetTargetPlatform(APlatform);
end;

procedure TNitroPascal.SetBuildMode(const ABuildMode: TParseBuildMode);
begin
  FParse.SetBuildMode(ABuildMode);
end;

procedure TNitroPascal.SetOptimizeLevel(const ALevel: TParseOptimizeLevel);
begin
  FParse.SetOptimizeLevel(ALevel);
end;

procedure TNitroPascal.SetSubsystem(const ASubsystem: TParseSubsystemType);
begin
  FParse.SetSubsystem(ASubsystem);
end;

procedure TNitroPascal.SetAddVersionInfo(const AValue: Boolean);
begin
  FAddVersionInfo := AValue;
end;

procedure TNitroPascal.SetVersionInfoMajor(const AValue: Word);
begin
  FVIMajor := AValue;
end;

procedure TNitroPascal.SetVersionInfoMinor(const AValue: Word);
begin
  FVIMinor := AValue;
end;

procedure TNitroPascal.SetVersionInfoPatch(const AValue: Word);
begin
  FVIPatch := AValue;
end;

procedure TNitroPascal.SetVersionInfoProductName(const AValue: string);
begin
  FVIProductName := AValue;
end;

procedure TNitroPascal.SetVersionInfoDescription(const AValue: string);
begin
  FVIDescription := AValue;
end;

procedure TNitroPascal.SetVersionInfoFilename(const AValue: string);
begin
  FVIFilename := AValue;
end;

procedure TNitroPascal.SetVersionInfoCompanyName(const AValue: string);
begin
  FVICompanyName := AValue;
end;

procedure TNitroPascal.SetVersionInfoCopyright(const AValue: string);
begin
  FVICopyright := AValue;
end;

procedure TNitroPascal.SetExeIcon(const AValue: string);
begin
  FExeIcon := AValue;
end;

procedure TNitroPascal.SetStatusCallback(const ACallback: TParseStatusCallback;
  const AUserData: Pointer);
begin
  inherited SetStatusCallback(ACallback, AUserData);
  FParse.SetStatusCallback(ACallback, AUserData);
end;

procedure TNitroPascal.SetOutputCallback(
  const ACallback: TParseCaptureConsoleCallback; const AUserData: Pointer);
begin
  inherited SetOutputCallback(ACallback, AUserData);
  FParse.SetOutputCallback(ACallback, AUserData);
end;

function TNitroPascal.HasErrors(): Boolean;
begin
  Result := FParse.HasErrors();
end;

function TNitroPascal.GetErrors(): TParseErrors;
begin
  Result := FParse.GetErrors();
end;

procedure TNitroPascal.SetLineDirectives(const AEnabled: Boolean);
begin
  FParse.SetLineDirectives(AEnabled);
end;

function TNitroPascal.ExtractUsesClause(const AFilename: string): TStringList;
var
  LLines:    TStringList;
  LI:        Integer;
  LLine:     string;
  LTrimmed:  string;
  LUsesBody: string;
  LIdx:      Integer;
  LNames:    TArray<string>;
  LName:     string;
  LInUses:   Boolean;
begin
  Result := TStringList.Create();
  LLines := TStringList.Create();
  try
    LLines.LoadFromFile(AFilename);
    LInUses := False;
    LUsesBody := '';
    for LI := 0 to LLines.Count - 1 do
    begin
      LLine    := LLines[LI];
      LTrimmed := LLine.Trim();
      // Skip blank lines and single-line comments
      if LTrimmed.IsEmpty or LTrimmed.StartsWith('//') or
         LTrimmed.StartsWith('{') or LTrimmed.StartsWith('(*') then
        Continue;
      if not LInUses then
      begin
        // Look for 'uses' keyword (case-insensitive) after program/unit/library header
        LIdx := LTrimmed.ToLower().IndexOf('uses');
        if LIdx >= 0 then
        begin
          LInUses  := True;
          LUsesBody := LTrimmed.Substring(LIdx + 4);  // text after 'uses'
        end;
      end
      else
        LUsesBody := LUsesBody + ' ' + LTrimmed;
      if LInUses then
      begin
        // Check if we've hit the closing semicolon
        LIdx := LUsesBody.IndexOf(';');
        if LIdx >= 0 then
        begin
          LUsesBody := LUsesBody.Substring(0, LIdx);
          LNames    := LUsesBody.Split([',']);
          for LName in LNames do
          begin
            LTrimmed := LName.Trim();
            if not LTrimmed.IsEmpty() then
              Result.Add(LTrimmed);
          end;
          Break;
        end;
      end;
    end;
  finally
    LLines.Free();
  end;
end;

function TNitroPascal.CompileUnitDep(const AUnitName, ASourceDir,
  AOutputPath: string): Boolean;
var
  LUnitFile:     string;
  LUnitNP:       TNitroPascal;
  LGeneratedCpp: string;
  LI:            Integer;
begin
  Result := False;
  // Locate unit source file alongside the main source
  LUnitFile := TPath.Combine(ASourceDir, AUnitName + '.pas');
  if not TFile.Exists(LUnitFile) then
  begin
    FParse.GetErrors().Add(esError, 'C010',
      Format('Unit source file not found: %s', [LUnitFile]));
    Exit;
  end;
  // Compile the unit: codegen only (ABuild=False), same output path
  LUnitNP := TNitroPascal.Create();
  try
    LUnitNP.SetStatusCallback(FStatusCallback.Callback, FStatusCallback.UserData);
    LUnitNP.SetSourceFile(LUnitFile);
    LUnitNP.SetOutputPath(AOutputPath);
    LUnitNP.SetBuildMode(bmLib);
    // Wire the np:: runtime include path so the unit can find np/np.hpp
    LUnitNP.FParse.AddIncludePath(TPath.Combine(
      TPath.GetDirectoryName(ParamStr(0)), 'res\runtime'));
    // Compile dependencies of this unit first (transitive, cycle-safe)
    if not LUnitNP.CompileUnitDeps(LUnitFile, AOutputPath) then
      Exit;
    // Run unit compile regardless of outcome so all messages are collected
    LUnitNP.FParse.Compile(False, False);
    // Always relay all messages (hints, warnings, errors) to main compiler
    for LI := 0 to LUnitNP.GetErrors().Count() - 1 do
      FParse.GetErrors().Add(
        LUnitNP.GetErrors().GetItems()[LI].Range,
        LUnitNP.GetErrors().GetItems()[LI].Severity,
        LUnitNP.GetErrors().GetItems()[LI].Code,
        LUnitNP.GetErrors().GetItems()[LI].Message);
    // Exit if unit compile failed
    if LUnitNP.HasErrors() then
      Exit;
    // Add unit's generated .cpp to the main build
    LGeneratedCpp := TPath.Combine(AOutputPath,
      TPath.Combine('generated', AUnitName + '.cpp'));
    FParse.AddSourceFile(LGeneratedCpp);
    // Also add the generated path to include paths for the header
    FParse.AddIncludePath(TPath.Combine(AOutputPath, 'generated'));
    Result := True;
  finally
    LUnitNP.Free();
  end;
end;

function TNitroPascal.CompileUnitDeps(const ASourceFile,
  AOutputPath: string): Boolean;
var
  LUnitNames: TStringList;
  LI:         Integer;
  LUnitName:  string;
  LSourceDir: string;
begin
  Result     := True;
  LSourceDir := TPath.GetDirectoryName(ASourceFile);
  LUnitNames := ExtractUsesClause(ASourceFile);
  try
    for LI := 0 to LUnitNames.Count - 1 do
    begin
      LUnitName := LUnitNames[LI];
      // Skip if already compiled (cycle detection)
      if FParsedUnits.IndexOf(LUnitName) >= 0 then
        Continue;
      FParsedUnits.Add(LUnitName);
      if not CompileUnitDep(LUnitName, LSourceDir, AOutputPath) then
      begin
        Result := False;
        Exit;
      end;
    end;
  finally
    LUnitNames.Free();
  end;
end;

function TNitroPascal.Compile(const ABuild: Boolean; const AAutoRun: Boolean): Boolean;
var
  LExePath:     string;
  LRuntimePath: string;
  LOutputPath:  string;
begin
  // Wire the np:: runtime library into every compile — include path so
  // generated code can #include "runtime.h", plus all .cpp translation units.
  LRuntimePath := TPath.Combine(
    TPath.GetDirectoryName(ParamStr(0)), 'res\runtime');
  FParse.AddIncludePath(LRuntimePath);
  // runtime.cpp is a unity build that #includes all module .cpp files
  FParse.AddSourceFile(TPath.Combine(LRuntimePath, 'runtime.cpp'));

  // Resolve output path (mirrors TParse.Compile default behaviour)
  LOutputPath := FParse.GetOutputPath();
  if LOutputPath = '' then
    LOutputPath := TPath.GetDirectoryName(FParse.GetSourceFile());

  // Compile all unit dependencies (codegen only) before the main build
  FParsedUnits.Clear();
  if not CompileUnitDeps(FParse.GetSourceFile(), LOutputPath) then
  begin
    Result := False;
    Exit;
  end;

  Result := FParse.Compile(ABuild, AAutoRun);

  // Apply post-build resources (manifest, icon, version info) on successful compile
  if Result then
  begin
    //LExePath := FParse.GetOutputFilename();
    LExePath := TPath.Combine(FParse.GetOutputPath(), 'zig-out/bin/' + FParse.GetOutputFilename());
    if LExePath <> '' then
      ApplyPostBuildResources(LExePath);
  end;
end;

function TNitroPascal.Run(): Cardinal;
begin
  Result := FParse.Run();
end;

function TNitroPascal.GetLastExitCode(): Cardinal;
begin
  Result := FParse.GetLastExitCode();
end;

function TNitroPascal.GetVersionStr(): string;
begin
  Result := NITROPASCAL_VERSION_STR;
end;

end.
