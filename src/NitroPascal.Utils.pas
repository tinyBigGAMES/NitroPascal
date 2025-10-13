﻿{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit NitroPascal.Utils;

{$I NitroPascal.Defines.inc}

interface

uses
  WinAPI.Windows,
  System.SysUtils,
  System.IOUtils,
  System.AnsiStrings,
  System.Classes;

type

  { TNPCallback }
  TNPCallback<T> = record
    Callback: T;
    UserData: Pointer;
  end;

  { TNPCaptureConsoleCallback }
  TNPCaptureConsoleCallback = reference to procedure(const ALine: string; const AUserData: Pointer);

  { TNPVersionInfo }
  TNPVersionInfo = record
    Major: Word;
    Minor: Word;
    Patch: Word;
    Build: Word;
    VersionString: string;
  end;

  { TNPUtils }
  TNPUtils = class
  private class var
    FMarshaller: TMarshaller;
  private
    class function  EnableVirtualTerminalProcessing(): Boolean; static;
    class procedure InitConsole(); static;

  public
    class procedure FailIf(const Cond: Boolean; const Msg: string; const AArgs: array of const);

    class function  GetTickCount(): DWORD; static;
    class function  GetTickCount64(): UInt64; static;

    class function  CallI64(AFunction: Pointer; const AArgs: array of const): UInt64; static;
    class function  CallF32(AFunction: Pointer; const AArgs: array of const): Single; static;
    class function  CallF64(AFunction: Pointer; const AArgs: array of const): Double; static;

    class function  HasConsole(): Boolean; static;
    class procedure ClearToEOL(); static;
    class procedure Print(); overload; static;
    class procedure PrintLn(); overload; static;
    class procedure Print(const AText: string); overload; static;
    class procedure Print(const AText: string; const AArgs: array of const); overload; static;
    class procedure PrintLn(const AText: string); overload; static;
    class procedure PrintLn(const AText: string; const AArgs: array of const); overload; static;
    class procedure Pause(); static;

    class function  AsUTF8(const AValue: string; ALength: PCardinal=nil): Pointer; static;
    class function  ToAnsi(const AValue: string): AnsiString; static;


    class procedure ProcessMessages(); static;

    class function  RunExe(const AExe, AParams, AWorkDir: string; const AWait: Boolean = True; const AShowCmd: Word = SW_SHOWNORMAL): Cardinal; static;
    class procedure CaptureConsoleOutput(const ATitle: string; const ACommand: PChar; const AParameters: PChar; const AWorkDir: string; var AExitCode: DWORD; const AUserData: Pointer; const ACallback: TNPCaptureConsoleCallback); static;
    class procedure CaptureZigConsoleOutput(const ATitle: string; const ACommand: PChar; const AParameters: PChar; const AWorkDir: string; var AExitCode: DWORD; const AUserData: Pointer; const ACallback: TNPCaptureConsoleCallback); static;

    class function  CreateDirInPath(const AFilename: string): Boolean;
    class function  GetVersionInfo(out AVersionInfo: TNPVersionInfo; const AFilePath: string = ''): Boolean; static;
    class function  GetZigExePath(): string; static;

    class procedure CopyFilePreservingEncoding(const ASourceFile, ADestFile: string); static;
    class function  DetectFileEncoding(const AFilePath: string): TEncoding; static;
    class function  EnsureBOM(const AText: string): string; static;

  end;

  { TNPCommandBuilder }
  TNPCommandBuilder = class
  private
    FParams: TStringList;
  public
    constructor Create();
    destructor Destroy(); override;
    
    procedure Clear();
    procedure AddParam(const AParam: string); overload;
    procedure AddParam(const AFlag, AValue: string); overload;
    procedure AddQuotedParam(const AFlag, AValue: string); overload;
    procedure AddQuotedParam(const AValue: string); overload;
    procedure AddFlag(const AFlag: string);
    
    function ToString(): string; reintroduce;
    function GetParamCount(): Integer;
  end;

const
  LOAD_LIBRARY_SEARCH_DEFAULT_DIRS   = $00001000;
  LOAD_LIBRARY_SEARCH_USER_DIRS      = $00000400;
  LOAD_LIBRARY_SEARCH_APPLICATION_DIR= $00000200;
  LOAD_LIBRARY_SEARCH_SYSTEM32       = $00000800;

function AddDllDirectory(NewDirectory: LPCWSTR): Pointer; stdcall; external kernel32 name 'AddDllDirectory';
function RemoveDllDirectory(Cookie: Pointer): BOOL; stdcall; external kernel32 name 'RemoveDllDirectory';
function SetDefaultDllDirectories(DirectoryFlags: DWORD): BOOL; stdcall; external kernel32 name 'SetDefaultDllDirectories';
function GetEnvironmentStringsW(): PWideChar; stdcall; external kernel32 name 'GetEnvironmentStringsW';
function FreeEnvironmentStringsW(lpszEnvironmentBlock: PWideChar): BOOL; stdcall; external kernel32 name 'FreeEnvironmentStringsW';


implementation

{$IF DEFINED(MSWINDOWS) AND DEFINED(CPUX64)}
function ffi_call_win64_i64(AFunction: Pointer; AArgs: PUInt64; AArgCount: Cardinal): UInt64; assembler;
asm
  // Prologue with only RBX saved; compute aligned stack space so that
  // RSP is 16-byte aligned at the CALL site.
  push rbp
  mov  rbp, rsp
  push rbx

  // Volatile locals
  mov  r11, rcx        // AFunction
  mov  r10, rdx        // AArgs
  mov  eax, r8d        // AArgCount -> EAX

  // k = max(0, ArgCount-4)
  mov  ecx, eax
  sub  ecx, 4
  xor  edx, edx
  cmp  ecx, 0
  jle  @no_stack
  mov  edx, ecx
  shl  edx, 3          // edx = k * 8
@no_stack:
  // s = 32 + 8*k ; ensure s ≡ 8 (mod 16) because we've pushed RBX
  lea  ebx, [rdx + 32] // ebx = base space
  test ecx, 1          // if k even, add +8; if k odd, already ≡ 8
  jnz  @have_s
  add  ebx, 8
@have_s:
  sub  rsp, rbx        // allocate

  // Copy stack args (5..N) to [rsp+32]
  mov  ecx, eax
  cmp  ecx, 4
  jle  @load_regs
  sub  ecx, 4
  lea  rsi, [r10 + 32]   // src
  lea  rdi, [rsp + 32]   // dst
  rep  movsq

@load_regs:
  // Dual-load first 4 slots
  test eax, eax
  jz   @do_call
  mov  rcx, [r10]
  movsd xmm0, qword ptr [r10]

  cmp  eax, 1
  jle  @do_call
  mov  rdx, [r10 + 8]
  movsd xmm1, qword ptr [r10 + 8]

  cmp  eax, 2
  jle  @do_call
  mov  r8,  [r10 + 16]
  movsd xmm2, qword ptr [r10 + 16]

  cmp  eax, 3
  jle  @do_call
  mov  r9,  [r10 + 24]
  movsd xmm3, qword ptr [r10 + 24]

@do_call:
  call r11

  // Epilogue
  add  rsp, rbx
  pop  rbx
  pop  rbp
  ret
end;

procedure ffi_call_win64_f32(AFunction: Pointer; AArgs: PUInt64; AArgCount: Cardinal; AResult: PSingle); assembler;
asm
  push rbp
  mov  rbp, rsp
  push rbx

  mov  r11, rcx        // AFunction
  mov  r10, rdx        // AArgs
  mov  eax, r8d        // AArgCount
  mov  r9,  r9         // AResult already in R9 (keep)

  // k = max(0, ArgCount-4)
  mov  ecx, eax
  sub  ecx, 4
  xor  edx, edx
  cmp  ecx, 0
  jle  @no_stack
  mov  edx, ecx
  shl  edx, 3
@no_stack:
  // s = 32 + 8*k ; adjust for RBX push parity
  lea  ebx, [rdx + 32]
  test ecx, 1
  jnz  @have_s
  add  ebx, 8
@have_s:
  sub  rsp, rbx

  // Copy stack args
  mov  ecx, eax
  cmp  ecx, 4
  jle  @load_regs
  sub  ecx, 4
  lea  rsi, [r10 + 32]
  lea  rdi, [rsp + 32]
  rep  movsq

@load_regs:
  test eax, eax
  jz   @do_call
  mov  rcx, [r10]
  // For float params the low 32 bits contain the value; movsd is fine (callee reads low 32)
  movsd xmm0, qword ptr [r10]

  cmp  eax, 1
  jle  @do_call
  mov  rdx, [r10 + 8]
  movsd xmm1, qword ptr [r10 + 8]

  cmp  eax, 2
  jle  @do_call
  mov  r8,  [r10 + 16]
  movsd xmm2, qword ptr [r10 + 16]

  cmp  eax, 3
  jle  @do_call
  mov  r9,  [r10 + 24]
  movsd xmm3, qword ptr [r10 + 24]

@do_call:
  call r11

  // Store float result
  test r9, r9
  jz   @done
  movss dword ptr [r9], xmm0
@done:
  add  rsp, rbx
  pop  rbx
  pop  rbp
  ret
end;

procedure ffi_call_win64_f64(AFunction: Pointer; AArgs: PUInt64; AArgCount: Cardinal; AResult: PDouble); assembler;
asm
  push rbp
  mov  rbp, rsp
  push rbx

  mov  r11, rcx        // AFunction
  mov  r10, rdx        // AArgs
  mov  eax, r8d        // AArgCount
  mov  r9,  r9         // AResult already in R9

  // k = max(0, ArgCount-4)
  mov  ecx, eax
  sub  ecx, 4
  xor  edx, edx
  cmp  ecx, 0
  jle  @no_stack
  mov  edx, ecx
  shl  edx, 3
@no_stack:
  // s = 32 + 8*k ; adjust for RBX push parity
  lea  ebx, [rdx + 32]
  test ecx, 1
  jnz  @have_s
  add  ebx, 8
@have_s:
  sub  rsp, rbx

  // Copy stack args
  mov  ecx, eax
  cmp  ecx, 4
  jle  @load_regs
  sub  ecx, 4
  lea  rsi, [r10 + 32]
  lea  rdi, [rsp + 32]
  rep  movsq

@load_regs:
  test eax, eax
  jz   @do_call
  mov  rcx, [r10]
  movsd xmm0, qword ptr [r10]

  cmp  eax, 1
  jle  @do_call
  mov  rdx, [r10 + 8]
  movsd xmm1, qword ptr [r10 + 8]

  cmp  eax, 2
  jle  @do_call
  mov  r8,  [r10 + 16]
  movsd xmm2, qword ptr [r10 + 16]

  cmp  eax, 3
  jle  @do_call
  mov  r9,  [r10 + 24]
  movsd xmm3, qword ptr [r10 + 24]

@do_call:
  call r11

  // Store double result
  test r9, r9
  jz   @done
  movsd qword ptr [r9], xmm0
@done:
  add  rsp, rbx
  pop  rbx
  pop  rbp
  ret
end;
{$ENDIF}

{ TTiUtils }
class function TNPUtils.EnableVirtualTerminalProcessing(): Boolean;
var
  HOut: THandle;
  LMode: DWORD;
begin
  Result := False;

  HOut := GetStdHandle(STD_OUTPUT_HANDLE);
  if HOut = INVALID_HANDLE_VALUE then Exit;
  if not GetConsoleMode(HOut, LMode) then Exit;

  LMode := LMode or ENABLE_VIRTUAL_TERMINAL_PROCESSING;
  if not SetConsoleMode(HOut, LMode) then Exit;

  Result := True;
end;

class procedure TNPUtils.InitConsole();
begin
  {$IF DEFINED(MSWINDOWS) AND DEFINED(CPUX64)}
    EnableVirtualTerminalProcessing();
    SetConsoleCP(CP_UTF8);
    SetConsoleOutputCP(CP_UTF8);
  {$ENDIF}
end;

type
  TUInt64Array = array of UInt64;

class function TNPUtils.CallI64(AFunction: Pointer; const AArgs: array of const): UInt64;
var
  LSlots: TUInt64Array;
  I: Integer;
  L: UInt64;
begin
  SetLength(LSlots, Length(AArgs));
  for I := 0 to High(AArgs) do
  begin
    L := 0;
    case AArgs[I].VType of
      vtInteger:       L := UInt64(Int64(AArgs[I].VInteger));
      vtInt64:         L := UInt64(PInt64(AArgs[I].VInt64)^);
      vtBoolean:       L := Ord(AArgs[I].VBoolean);
      vtPointer:       L := UInt64(NativeUInt(AArgs[I].VPointer));
      vtPChar:         L := UInt64(NativeUInt(AArgs[I].VPChar));
      vtPWideChar:     L := UInt64(NativeUInt(AArgs[I].VPWideChar));
      vtClass:         L := UInt64(NativeUInt(AArgs[I].VClass));
      vtObject:        L := UInt64(NativeUInt(AArgs[I].VObject));
      vtWideChar:      L := UInt64(Ord(AArgs[I].VWideChar));
      vtChar:          L := UInt64(Ord(AArgs[I].VChar));
      vtAnsiString:    L := UInt64(NativeUInt(AArgs[I].VAnsiString));      // pointer to Ansi data
      vtUnicodeString: L := UInt64(NativeUInt(AArgs[I].VUnicodeString));   // pointer to UTF-16 data
      vtExtended:      Move(PExtended(AArgs[I].VExtended)^, L, 8);         // pass as double bits
      vtCurrency:      Move(PCurrency(AArgs[I].VCurrency)^, L, 8);
      vtVariant:       L := UInt64(NativeUInt(AArgs[I].VVariant));         // pointer to Variant
    else
      L := 0;
    end;
    LSlots[I] := L;
  end;

  if Length(LSlots) = 0 then
    Result := ffi_call_win64_i64(AFunction, nil, 0)
  else
    Result := ffi_call_win64_i64(AFunction, @LSlots[0], Length(LSlots));
end;

class function TNPUtils.CallF32(AFunction: Pointer; const AArgs: array of const): Single;
var
  LSlots: TUInt64Array;
  I: Integer;
  L: UInt64;
  S: Single;
begin
  SetLength(LSlots, Length(AArgs));
  for I := 0 to High(AArgs) do
  begin
    L := 0;
    case AArgs[I].VType of
      vtExtended:      begin S := Single(PExtended(AArgs[I].VExtended)^); Move(S, L, 4); end;
      vtInteger:       L := UInt64(Int64(AArgs[I].VInteger));
      vtInt64:         L := UInt64(PInt64(AArgs[I].VInt64)^);
      vtBoolean:       L := Ord(AArgs[I].VBoolean);
      vtPointer:       L := UInt64(NativeUInt(AArgs[I].VPointer));
      vtPChar:         L := UInt64(NativeUInt(AArgs[I].VPChar));
      vtPWideChar:     L := UInt64(NativeUInt(AArgs[I].VPWideChar));
      vtChar:          L := UInt64(Ord(AArgs[I].VChar));
      vtWideChar:      L := UInt64(Ord(AArgs[I].VWideChar));
      vtAnsiString:    L := UInt64(NativeUInt(AArgs[I].VAnsiString));
      vtUnicodeString: L := UInt64(NativeUInt(AArgs[I].VUnicodeString));
      vtCurrency:      Move(PCurrency(AArgs[I].VCurrency)^, L, 8);
      vtVariant:       L := UInt64(NativeUInt(AArgs[I].VVariant));
    else
      L := 0;
    end;
    LSlots[I] := L;
  end;

  if Length(LSlots) = 0 then
    ffi_call_win64_f32(AFunction, nil, 0, @Result)
  else
    ffi_call_win64_f32(AFunction, @LSlots[0], Length(LSlots), @Result);
end;

class function TNPUtils.CallF64(AFunction: Pointer; const AArgs: array of const): Double;
var
  LSlots: TUInt64Array;
  I: Integer;
  L: UInt64;
  D: Double;
begin
  SetLength(LSlots, Length(AArgs));
  for I := 0 to High(AArgs) do
  begin
    L := 0;
    case AArgs[I].VType of
      vtExtended:      begin D := Double(PExtended(AArgs[I].VExtended)^); Move(D, L, 8); end;
      vtInteger:       L := UInt64(Int64(AArgs[I].VInteger));
      vtInt64:         L := UInt64(PInt64(AArgs[I].VInt64)^);
      vtBoolean:       L := Ord(AArgs[I].VBoolean);
      vtPointer:       L := UInt64(NativeUInt(AArgs[I].VPointer));
      vtPChar:         L := UInt64(NativeUInt(AArgs[I].VPChar));
      vtPWideChar:     L := UInt64(NativeUInt(AArgs[I].VPWideChar));
      vtChar:          L := UInt64(Ord(AArgs[I].VChar));
      vtWideChar:      L := UInt64(Ord(AArgs[I].VWideChar));
      vtAnsiString:    L := UInt64(NativeUInt(AArgs[I].VAnsiString));
      vtUnicodeString: L := UInt64(NativeUInt(AArgs[I].VUnicodeString));
      vtCurrency:      Move(PCurrency(AArgs[I].VCurrency)^, L, 8);
      vtVariant:       L := UInt64(NativeUInt(AArgs[I].VVariant));
    else
      L := 0;
    end;
    LSlots[I] := L;
  end;

  if Length(LSlots) = 0 then
    ffi_call_win64_f64(AFunction, nil, 0, @Result)
  else
    ffi_call_win64_f64(AFunction, @LSlots[0], Length(LSlots), @Result);
end;

class procedure TNPUtils.FailIf(const Cond: Boolean; const Msg: string; const AArgs: array of const);
  begin
    if Cond then
      raise Exception.CreateFmt(Msg, AArgs);
  end;

class function TNPUtils.GetTickCount(): DWORD;
begin
  {$IF DEFINED(MSWINDOWS) AND DEFINED(CPUX64)}
  Result := WinApi.Windows.GetTickCount();
  {$ENDIF}
end;

class function TNPUtils.GetTickCount64(): UInt64;
begin
  {$IF DEFINED(MSWINDOWS) AND DEFINED(CPUX64)}
  Result := WinApi.Windows.GetTickCount64();
  {$ENDIF}
end;

class function TNPUtils.HasConsole(): Boolean;
begin
  {$IF DEFINED(MSWINDOWS) AND DEFINED(CPUX64)}
  Result := Boolean(GetConsoleWindow() <> 0);
  {$ENDIF}
end;

class procedure TNPUtils.ClearToEOL();
begin
  if not HasConsole() then Exit;
  Write(#27'[0K');
end;

class procedure  TNPUtils.Print();
begin
  Print('');
end;

class procedure  TNPUtils.PrintLn();
begin
  PrintLn('');
end;

class procedure TNPUtils.Print(const AText: string);
begin
  if not HasConsole() then Exit;
  Write(AText);
end;

class procedure TNPUtils.Print(const AText: string; const AArgs: array of const);
begin
  if not HasConsole() then Exit;
  Write(Format(AText, AArgs));
end;

class procedure TNPUtils.PrintLn(const AText: string);
begin
  if not HasConsole() then Exit;
  WriteLn(AText);
end;

class procedure  TNPUtils.PrintLn(const AText: string; const AArgs: array of const);
begin
  if not HasConsole() then Exit;
  WriteLn(Format(AText, AArgs));
end;

class procedure TNPUtils.Pause();
begin
  PrintLn('');
  Print('Press ENTER to continue...');
  ReadLn;
  PrintLn('');
end;

class function TNPUtils.AsUTF8(const AValue: string; ALength: PCardinal): Pointer;
begin
  Result := FMarshaller.AsUtf8(AValue).ToPointer;
  if Assigned(ALength) then
    ALength^ := System.AnsiStrings.StrLen(PAnsiChar(Result));

end;

class function TNPUtils.ToAnsi(const AValue: string): AnsiString;
var
  LBytes: TBytes;
begin
  LBytes := TEncoding.ANSI.GetBytes(AValue);
   if Length(LBytes) = 0 then
    Exit('');
  SetString(Result, PAnsiChar(@LBytes[0]), Length(LBytes));
end;

class procedure TNPUtils.ProcessMessages();
var
  LMsg: TMsg;
begin
  while Integer(PeekMessage(LMsg, 0, 0, 0, PM_REMOVE)) <> 0 do
  begin
    TranslateMessage(LMsg);
    DispatchMessage(LMsg);
  end;
end;

class function TNPUtils.RunExe(const AExe, AParams, AWorkDir: string; const AWait: Boolean; const AShowCmd: Word): Cardinal;
var
  LAppPath: string;
  LCmd: UnicodeString;
  LSI: STARTUPINFOW;
  LPI: PROCESS_INFORMATION;
  LExit: DWORD;
  LCreationFlags: DWORD;
  LWorkDirPW: PWideChar;
begin

  if AExe = '' then
    raise Exception.Create('RunExe: Executable path is empty');

  // Resolve the executable path against the workdir if only a filename was provided.
  if TPath.IsPathRooted(AExe) or (Pos('\', AExe) > 0) or (Pos('/', AExe) > 0) then
    LAppPath := AExe
  else if AWorkDir <> '' then
    LAppPath := TPath.Combine(AWorkDir, AExe)
  else
    LAppPath := AExe; // will rely on caller's current dir / PATH

  // Quote the app path and build a mutable command line.
  if AParams <> '' then
    LCmd := '"' + LAppPath + '" ' + AParams
  else
    LCmd := '"' + LAppPath + '"';
  UniqueString(LCmd);

  // Optional: ensure the exe exists when a workdir is provided.
  if (AWorkDir <> '') and (not TFile.Exists(LAppPath)) then
    raise Exception.CreateFmt('RunExe: Executable not found: %s', [LAppPath]);

  ZeroMemory(@LSI, SizeOf(LSI));
  ZeroMemory(@LPI, SizeOf(LPI));
  LSI.cb := SizeOf(LSI);
  LSI.dwFlags := STARTF_USESHOWWINDOW;
  LSI.wShowWindow := AShowCmd;

  if AWorkDir <> '' then
    LWorkDirPW := PWideChar(AWorkDir)
  else
    LWorkDirPW := nil;

  LCreationFlags := CREATE_UNICODE_ENVIRONMENT;

  // IMPORTANT: pass the resolved path in lpApplicationName so Windows won't search using the caller's current directory.
  if not CreateProcessW(
    PWideChar(LAppPath),   // lpApplicationName (explicit module path)
    PWideChar(LCmd),       // lpCommandLine (mutable, includes quoted path + params)
    nil,                   // lpProcessAttributes
    nil,                   // lpThreadAttributes
    False,                 // bInheritHandles
    LCreationFlags,        // dwCreationFlags
    nil,                   // lpEnvironment
    LWorkDirPW,            // lpCurrentDirectory (workdir for the child)
    LSI,                   // lpStartupInfo
    LPI                    // lpProcessInformation
  ) then
    raise Exception.CreateFmt('RunExe: CreateProcess failed (%d) %s', [GetLastError, SysErrorMessage(GetLastError)]);

  try
    if AWait then
    begin
      WaitForSingleObject(LPI.hProcess, INFINITE);
      LExit := 0;
      if GetExitCodeProcess(LPI.hProcess, LExit) then
        Result := LExit
      else
        raise Exception.CreateFmt('RunExe: GetExitCodeProcess failed (%d) %s', [GetLastError, SysErrorMessage(GetLastError)]);
    end
    else
      Result := 0;
  finally
    CloseHandle(LPI.hThread);
    CloseHandle(LPI.hProcess);
  end;
end;


class procedure TNPUtils.CaptureConsoleOutput(const ATitle: string; const ACommand: PChar; const AParameters: PChar; const AWorkDir: string; var AExitCode: DWORD; const AUserData: Pointer; const ACallback: TNPCaptureConsoleCallback);
const
  //CReadBuffer = 2400;
  CReadBuffer = 1024*2;
var
  saSecurity: TSecurityAttributes;
  hRead: THandle;
  hWrite: THandle;
  suiStartup: TStartupInfo;
  piProcess: TProcessInformation;
  pBuffer: array [0 .. CReadBuffer] of AnsiChar;
  dBuffer: array [0 .. CReadBuffer] of AnsiChar;
  dRead: DWORD;
  dRunning: DWORD;
  dAvailable: DWORD;
  CmdLine: string;
  LExitCode: DWORD;
  LWorkDirPtr: PChar;
  LLineAccumulator: TStringBuilder;
  LI: Integer;
  LChar: AnsiChar;
  LCurrentLine: string;
begin
  saSecurity.nLength := SizeOf(TSecurityAttributes);
  saSecurity.bInheritHandle := true;
  saSecurity.lpSecurityDescriptor := nil;
  if CreatePipe(hRead, hWrite, @saSecurity, 0) then
    try
      FillChar(suiStartup, SizeOf(TStartupInfo), #0);
      suiStartup.cb := SizeOf(TStartupInfo);
      suiStartup.hStdInput := hRead;
      suiStartup.hStdOutput := hWrite;
      suiStartup.hStdError := hWrite;
      suiStartup.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
      suiStartup.wShowWindow := SW_HIDE;
      if ATitle.IsEmpty then
        suiStartup.lpTitle := nil
      else
        suiStartup.lpTitle := PChar(ATitle);
      CmdLine := ACommand + ' ' + AParameters;
      if AWorkDir <> '' then
        LWorkDirPtr := PChar(AWorkDir)
      else
        LWorkDirPtr := nil;
      if CreateProcess(nil, PChar(CmdLine), @saSecurity, @saSecurity, true, NORMAL_PRIORITY_CLASS, nil, LWorkDirPtr, suiStartup, piProcess) then
        try
          LLineAccumulator := TStringBuilder.Create;
          try
            repeat
              dRunning := WaitForSingleObject(piProcess.hProcess, 100);
              PeekNamedPipe(hRead, nil, 0, nil, @dAvailable, nil);
              if (dAvailable > 0) then
                repeat
                  dRead := 0;
                  ReadFile(hRead, pBuffer[0], CReadBuffer, dRead, nil);
                  pBuffer[dRead] := #0;
                  OemToCharA(pBuffer, dBuffer);
                  
                  // Process character-by-character to find complete lines
                  LI := 0;
                  while LI < Integer(dRead) do
                  begin
                    LChar := dBuffer[LI];
                    
                    if (LChar = #13) or (LChar = #10) then
                    begin
                      // Found line terminator - emit accumulated line if not empty
                      if LLineAccumulator.Length > 0 then
                      begin
                        LCurrentLine := LLineAccumulator.ToString();
                        LLineAccumulator.Clear();
                        
                        if Assigned(ACallback) then
                          ACallback(LCurrentLine, AUserData);
                      end;
                      
                      // Skip paired CR+LF
                      if (LChar = #13) and (LI + 1 < Integer(dRead)) and (dBuffer[LI + 1] = #10) then
                        Inc(LI);
                    end
                    else
                    begin
                      // Accumulate character
                      LLineAccumulator.Append(string(LChar));
                    end;
                    
                    Inc(LI);
                  end;
                until (dRead < CReadBuffer);
              ProcessMessages;
            until (dRunning <> WAIT_TIMEOUT);
            
            // Emit any remaining partial line
            if LLineAccumulator.Length > 0 then
            begin
              LCurrentLine := LLineAccumulator.ToString();
              if Assigned(ACallback) then
                ACallback(LCurrentLine, AUserData);
            end;

            if GetExitCodeProcess(piProcess.hProcess, LExitCode) then
            begin
              AExitCode := LExitCode;
            end;

          finally
            FreeAndNil(LLineAccumulator);
          end;
        finally
          CloseHandle(piProcess.hProcess);
          CloseHandle(piProcess.hThread);
        end;
    finally
      CloseHandle(hRead);
      CloseHandle(hWrite);
    end;
end;

class procedure TNPUtils.CaptureZigConsoleOutput(const ATitle: string; const ACommand: PChar; const AParameters: PChar; const AWorkDir: string; var AExitCode: DWORD; const AUserData: Pointer; const ACallback: TNPCaptureConsoleCallback);
const
  CReadBuffer = 1024*2;
  CProgressBuffer = 1024*16;
type
  TZigProgressNode = record
    Completed: UInt32;
    EstimatedTotal: UInt32;
    TaskName: string;
    Parent: Byte;
  end;
  TZigProgressNodeArray = array of TZigProgressNode;
  
  function IsTTY(): Boolean;
  var
    LStdOut: THandle;
    LMode: DWORD;
  begin
    LStdOut := GetStdHandle(STD_OUTPUT_HANDLE);
    Result := (LStdOut <> INVALID_HANDLE_VALUE) and GetConsoleMode(LStdOut, LMode);
  end;
  
  function BuildEnvironmentWithProgress(const AProgressHandle: THandle): Pointer;
  var
    LEnvStrings: PWideChar;
    LCurrent: PWideChar;
    LEnvList: TStringList;
    LFinalEnv: string;
    LI: Integer;
    LSize: Integer;
  begin
    Result := nil;
    LEnvList := TStringList.Create();
    try
      // Get existing environment
      LEnvStrings := GetEnvironmentStringsW();
      if LEnvStrings = nil then
        Exit;
      
      try
        LCurrent := LEnvStrings;
        while LCurrent^ <> #0 do
        begin
          LEnvList.Add(LCurrent);
          Inc(LCurrent, Length(LCurrent) + 1);
        end;
      finally
        FreeEnvironmentStringsW(LEnvStrings);
      end;
      
      // Add ZIG_PROGRESS
      LEnvList.Add('ZIG_PROGRESS=' + IntToStr(AProgressHandle));
      
      // Build double-null terminated string
      LFinalEnv := '';
      for LI := 0 to LEnvList.Count - 1 do
        LFinalEnv := LFinalEnv + LEnvList[LI] + #0;
      LFinalEnv := LFinalEnv + #0;
      
      // Allocate and copy
      LSize := Length(LFinalEnv) * SizeOf(WideChar);
      Result := AllocMem(LSize);
      Move(PWideChar(LFinalEnv)^, Result^, LSize);
    finally
      FreeAndNil(LEnvList);
    end;
  end;
  
  procedure ParseProgressMessage(const ABuffer: PByte; const ABytesRead: DWORD; var ANodes: TZigProgressNodeArray);
  var
    LLen: Byte;
    LNodeIdx: Integer;
    LOffset: Integer;
    LNameBytes: array[0..39] of Byte;
    LUtf8Bytes: TBytes;
    LNameLen: Integer;
    LI: Integer;
    LExpectedSize: DWORD;
  begin
    SetLength(ANodes, 0);
    
    if ABytesRead < 1 then
      Exit;
    
    LLen := ABuffer[0];
    if (LLen > 253) or (LLen = 0) then
      Exit;
    
    LExpectedSize := 1 + (LLen * 48) + LLen;
    if ABytesRead < LExpectedSize then
      Exit;
    
    SetLength(ANodes, LLen);
    LOffset := 1;
    
    for LNodeIdx := 0 to LLen - 1 do
    begin
      Move(ABuffer[LOffset], ANodes[LNodeIdx].Completed, 4);
      Inc(LOffset, 4);
      
      Move(ABuffer[LOffset], ANodes[LNodeIdx].EstimatedTotal, 4);
      Inc(LOffset, 4);
      
      Move(ABuffer[LOffset], LNameBytes[0], 40);
      
      LNameLen := 0;
      for LI := 0 to 39 do
      begin
        if LNameBytes[LI] = 0 then
          Break;
        Inc(LNameLen);
      end;
      
      if LNameLen > 0 then
      begin
        SetLength(LUtf8Bytes, LNameLen);
        Move(LNameBytes[0], LUtf8Bytes[0], LNameLen);
        ANodes[LNodeIdx].TaskName := TEncoding.UTF8.GetString(LUtf8Bytes);
      end
      else
        ANodes[LNodeIdx].TaskName := '';
      
      Inc(LOffset, 40);
    end;
    
    for LNodeIdx := 0 to LLen - 1 do
    begin
      ANodes[LNodeIdx].Parent := ABuffer[LOffset];
      Inc(LOffset);
    end;
  end;
  
  procedure FormatAndCallbackProgress(const ANodes: TZigProgressNodeArray; const AUserData: Pointer; const ACallback: TNPCaptureConsoleCallback);
  var
    LI: Integer;
    LLine: string;
    //LProgressText: string;
    LLastNode: Integer;
  begin
    if Length(ANodes) = 0 then
      Exit;
    
    if not Assigned(ACallback) then
      Exit;
    
    // Find the last non-root node with progress
    LLastNode := -1;
    for LI := High(ANodes) downto 0 do
    begin
      if (ANodes[LI].EstimatedTotal > 0) or (ANodes[LI].Completed > 0) then
      begin
        LLastNode := LI;
        Break;
      end;
    end;
    
    // If found, send just that one with progress marker
    if LLastNode >= 0 then
    begin
      if ANodes[LLastNode].EstimatedTotal > 0 then
        LLine := Format('[%d/%d] %s', [ANodes[LLastNode].Completed, ANodes[LLastNode].EstimatedTotal, ANodes[LLastNode].TaskName])
      else
        LLine := Format('[%d] %s', [ANodes[LLastNode].Completed, ANodes[LLastNode].TaskName]);
      
      // Add special marker for progress lines
      ACallback(#1 + LLine, AUserData);
    end;
  end;

var
  saSecurity: TSecurityAttributes;
  hRead: THandle;
  hWrite: THandle;
  hProgressRead: THandle;
  hProgressWrite: THandle;
  suiStartup: TStartupInfo;
  piProcess: TProcessInformation;
  pBuffer: array [0 .. CReadBuffer] of AnsiChar;
  dBuffer: array [0 .. CReadBuffer] of AnsiChar;
  progressBuffer: array [0 .. CProgressBuffer] of Byte;
  dRead: DWORD;
  dProgressRead: DWORD;
  dRunning: DWORD;
  dAvailable: DWORD;
  dProgressAvailable: DWORD;
  CmdLine: string;
  BufferList: TStringList;
  Line: string;
  LExitCode: DWORD;
  LWorkDirPtr: PChar;
  LProgressNodes: TZigProgressNodeArray;
  LEnvBlock: Pointer;
begin
  saSecurity.nLength := SizeOf(TSecurityAttributes);
  saSecurity.bInheritHandle := true;
  saSecurity.lpSecurityDescriptor := nil;
  
  hProgressRead := 0;
  hProgressWrite := 0;
  LEnvBlock := nil;
  
  if CreatePipe(hRead, hWrite, @saSecurity, 0) then
    try
      // Try to create progress pipe (optional)
      if CreatePipe(hProgressRead, hProgressWrite, @saSecurity, 0) then
      begin
        // Build environment with ZIG_PROGRESS
        LEnvBlock := BuildEnvironmentWithProgress(hProgressWrite);
      end;
      
      FillChar(suiStartup, SizeOf(TStartupInfo), #0);
      suiStartup.cb := SizeOf(TStartupInfo);
      suiStartup.hStdInput := hRead;
      suiStartup.hStdOutput := hWrite;
      suiStartup.hStdError := hWrite;
      suiStartup.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
      suiStartup.wShowWindow := SW_HIDE;
      if ATitle.IsEmpty then
        suiStartup.lpTitle := nil
      else
        suiStartup.lpTitle := PChar(ATitle);
      
      // Add --color off if not TTY
      if not IsTTY() and (Pos('--color', string(AParameters)) = 0) then
        CmdLine := ACommand + ' ' + AParameters + ' --color off'
      else
        CmdLine := ACommand + ' ' + AParameters;
      
      if AWorkDir <> '' then
        LWorkDirPtr := PChar(AWorkDir)
      else
        LWorkDirPtr := nil;
      
      if CreateProcess(nil, PChar(CmdLine), @saSecurity, @saSecurity, true, NORMAL_PRIORITY_CLASS or CREATE_UNICODE_ENVIRONMENT, LEnvBlock, LWorkDirPtr, suiStartup, piProcess) then
        try
          BufferList := TStringList.Create;
          try
            repeat
              dRunning := WaitForSingleObject(piProcess.hProcess, 100);
              
              // Handle console output
              PeekNamedPipe(hRead, nil, 0, nil, @dAvailable, nil);
              if (dAvailable > 0) then
                repeat
                  dRead := 0;
                  ReadFile(hRead, pBuffer[0], CReadBuffer, dRead, nil);
                  pBuffer[dRead] := #0;
                  OemToCharA(pBuffer, dBuffer);
                  BufferList.Clear;
                  BufferList.Text := string(pBuffer);
                  for line in BufferList do
                  begin
                    if Assigned(ACallback) then
                    begin
                      ACallback(line, AUserData);
                    end;
                  end;
                until (dRead < CReadBuffer);
              
              // Handle progress pipe if available
              if hProgressRead <> 0 then
              begin
                PeekNamedPipe(hProgressRead, nil, 0, nil, @dProgressAvailable, nil);
                if (dProgressAvailable > 0) then
                begin
                  dProgressRead := 0;
                  ReadFile(hProgressRead, progressBuffer[0], CProgressBuffer, dProgressRead, nil);
                  if dProgressRead > 0 then
                  begin
                    ParseProgressMessage(@progressBuffer[0], dProgressRead, LProgressNodes);
                    FormatAndCallbackProgress(LProgressNodes, AUserData, ACallback);
                  end;
                end;
              end;
              
              ProcessMessages;
            until (dRunning <> WAIT_TIMEOUT);

            if GetExitCodeProcess(piProcess.hProcess, LExitCode) then
            begin
              AExitCode := LExitCode;
            end;

          finally
            FreeAndNil(BufferList);
          end;
        finally
          CloseHandle(piProcess.hProcess);
          CloseHandle(piProcess.hThread);
        end;
    finally
      if LEnvBlock <> nil then
        FreeMem(LEnvBlock);
      
      if hProgressRead <> 0 then
        CloseHandle(hProgressRead);
      if hProgressWrite <> 0 then
        CloseHandle(hProgressWrite);
      
      CloseHandle(hRead);
      CloseHandle(hWrite);
    end;
end;

class function TNPUtils.CreateDirInPath(const AFilename: string): Boolean;
var
  LPath: string;
begin
  // If AFilename is a directory, use it directly; otherwise, extract its directory part
  if TPath.HasExtension(AFilename) then
    LPath := TPath.GetDirectoryName(AFilename)
  else
    LPath := AFilename;

  if LPath.IsEmpty then
    Exit(False);

  if not TDirectory.Exists(LPath) then
    TDirectory.CreateDirectory(LPath);

  Result := True;
end;

class function TNPUtils.GetZigExePath(): string;
var
  LBase: string;
begin
  LBase := TPath.GetDirectoryName(ParamStr(0));
  Result := TPath.Combine(
    LBase,
    TPath.Combine('res', TPath.Combine('zig', 'zig.exe'))
  );
end;

class procedure TNPUtils.CopyFilePreservingEncoding(const ASourceFile, ADestFile: string);
var
  LSourceBytes: TBytes;
begin
  // Validate source file exists
  if not TFile.Exists(ASourceFile) then
    raise Exception.CreateFmt('CopyFilePreservingEncoding: Source file not found: %s', [ASourceFile]);

  // Ensure destination directory exists
  CreateDirInPath(ADestFile);

  // Read all bytes from source file
  LSourceBytes := TFile.ReadAllBytes(ASourceFile);
  
  // Write bytes to destination - this preserves EVERYTHING including BOM
  TFile.WriteAllBytes(ADestFile, LSourceBytes);
end;

class function TNPUtils.DetectFileEncoding(const AFilePath: string): TEncoding;
var
  LBytes: TBytes;
  LEncoding: TEncoding;
begin
  // Validate file exists
  if not TFile.Exists(AFilePath) then
    raise Exception.CreateFmt('DetectFileEncoding: File not found: %s', [AFilePath]);

  // Read a sample of bytes (first 4KB should be enough for BOM detection)
  LBytes := TFile.ReadAllBytes(AFilePath);

  if Length(LBytes) = 0 then
    Exit(TEncoding.Default);

  // Let TEncoding detect the encoding from BOM
  LEncoding := nil;
  TEncoding.GetBufferEncoding(LBytes, LEncoding, TEncoding.Default);

  Result := LEncoding;
end;

class function TNPUtils.EnsureBOM(const AText: string): string;
const
  UTF16_BOM = #$FEFF;
begin
  Result := AText;
  if (Length(Result) = 0) or (Result[1] <> UTF16_BOM) then
    Result := UTF16_BOM + Result;
end;

class function TNPUtils.GetVersionInfo(out AVersionInfo: TNPVersionInfo; const AFilePath: string): Boolean;
var
  LFileName: string;
  LInfoSize: DWORD;
  LHandle: DWORD;
  LBuffer: Pointer;
  LFileInfo: PVSFixedFileInfo;
  LLen: UINT;
begin
  // Initialize output
  AVersionInfo.Major := 0;
  AVersionInfo.Minor := 0;
  AVersionInfo.Patch := 0;
  AVersionInfo.Build := 0;
  AVersionInfo.VersionString := '';

  // Determine which file to query
  if AFilePath = '' then
    LFileName := ParamStr(0)
  else
    LFileName := AFilePath;

  // Get version info size
  LInfoSize := GetFileVersionInfoSize(PChar(LFileName), LHandle);
  if LInfoSize = 0 then
    Exit(False);

  // Allocate buffer and get version info
  GetMem(LBuffer, LInfoSize);
  try
    if not GetFileVersionInfo(PChar(LFileName), LHandle, LInfoSize, LBuffer) then
      Exit(False);

    // Query fixed file info
    if not VerQueryValue(LBuffer, '\', Pointer(LFileInfo), LLen) then
      Exit(False);

    // Extract version components
    AVersionInfo.Major := HiWord(LFileInfo.dwFileVersionMS);
    AVersionInfo.Minor := LoWord(LFileInfo.dwFileVersionMS);
    AVersionInfo.Patch := HiWord(LFileInfo.dwFileVersionLS);
    AVersionInfo.Build := LoWord(LFileInfo.dwFileVersionLS);

    // Format version string (Major.Minor.Patch)
    AVersionInfo.VersionString := Format('%d.%d.%d', [AVersionInfo.Major, AVersionInfo.Minor, AVersionInfo.Patch]);
    
    Result := True;
  finally
    FreeMem(LBuffer);
  end;
end;

{ TTiCommandBuilder }

constructor TNPCommandBuilder.Create();
begin
  inherited Create();
  
  FParams := TStringList.Create();
  FParams.Delimiter := ' ';
  FParams.StrictDelimiter := True;
end;

destructor TNPCommandBuilder.Destroy();
begin
  FreeAndNil(FParams);
  
  inherited Destroy();
end;

procedure TNPCommandBuilder.Clear();
begin
  FParams.Clear();
end;

procedure TNPCommandBuilder.AddParam(const AParam: string);
begin
  if AParam <> '' then
    FParams.Add(AParam);
end;

procedure TNPCommandBuilder.AddParam(const AFlag, AValue: string);
begin
  if AFlag <> '' then
  begin
    if AValue <> '' then
      FParams.Add(AFlag + AValue)
    else
      FParams.Add(AFlag);
  end
  else if AValue <> '' then
    FParams.Add(AValue);
end;

procedure TNPCommandBuilder.AddQuotedParam(const AFlag, AValue: string);
begin
  if AValue = '' then
    Exit;
  
  if AFlag <> '' then
    FParams.Add(AFlag + ' "' + AValue + '"')
  else
    FParams.Add('"' + AValue + '"');
end;

procedure TNPCommandBuilder.AddQuotedParam(const AValue: string);
begin
  AddQuotedParam('', AValue);
end;

procedure TNPCommandBuilder.AddFlag(const AFlag: string);
begin
  if AFlag <> '' then
    FParams.Add(AFlag);
end;

function TNPCommandBuilder.ToString(): string;
var
  LI: Integer;
begin
  if FParams.Count = 0 then
  begin
    Result := '';
    Exit;
  end;
  
  // Manually join with spaces to avoid TStringList.DelimitedText auto-quoting
  Result := FParams[0];
  for LI := 1 to FParams.Count - 1 do
    Result := Result + ' ' + FParams[LI];
end;

function TNPCommandBuilder.GetParamCount(): Integer;
begin
  Result := FParams.Count;
end;


procedure Startup();
var
  LPath: string;
begin
  LPath := '';
  {
  // include app dir + System32 + user dirs
  SetDefaultDllDirectories(LOAD_LIBRARY_SEARCH_DEFAULT_DIRS);

  // set custom paths
  LPath := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'res\yaml');
  AddDllDirectory(PChar(LPath));
  }

  TNPUtils.InitConsole();
end;

procedure Shutdown();
begin
end;

initialization
begin
  Startup();
end;

finalization
begin
  Shutdown();
end;

end.
