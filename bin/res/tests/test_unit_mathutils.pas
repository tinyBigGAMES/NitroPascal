{===============================================================================
  NitroPascal(tm) - Modern Pascal * C Performance

  Copyright (c) 2025-present tinyBigGAMES(tm) LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit test_unit_mathutils;

interface

  function Add(const A, B: Integer): Integer;
  function Multiply(const A, B: Integer): Integer;
  function IsEven(const AValue: Integer): Boolean;

implementation

function Add(const A, B: Integer): Integer;
begin
  Result := A + B;
end;

function Multiply(const A, B: Integer): Integer;
begin
  Result := A * B;
end;

function IsEven(const AValue: Integer): Boolean;
begin
  Result := (AValue mod 2) = 0;
end;

end.
