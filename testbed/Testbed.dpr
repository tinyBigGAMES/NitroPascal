{===============================================================================
  NitroPascal™ - Modern Pascal * C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

program Testbed;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  UTestbed in 'UTestbed.pas',
  NitroPascal.CodeGen in '..\src\NitroPascal.CodeGen.pas',
  NitroPascal.Grammar in '..\src\NitroPascal.Grammar.pas',
  NitroPascal.Lexer in '..\src\NitroPascal.Lexer.pas',
  NitroPascal in '..\src\NitroPascal.pas',
  NitroPascal.Semantics in '..\src\NitroPascal.Semantics.pas';

begin
  RunTestbed();
end.
