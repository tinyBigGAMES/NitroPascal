﻿{===============================================================================
  NitroPascal - Modern Pascal • C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

program ProgramFunctions;

function Add(const A: Integer; const B: Integer): Integer;
begin
  Result := A + B;
end;

procedure PrintValue(const AValue: Integer);
var
  LValue: Integer;
begin
  LValue := AValue;
  WriteLn('PrintValue received: ', LValue);
end;

var
  GSum: Integer;

begin
  WriteLn('=== ProgramFunctions ===');
  GSum := Add(10, 20);
  WriteLn('Add(10, 20) = ', GSum);
  PrintValue(GSum);
end.
