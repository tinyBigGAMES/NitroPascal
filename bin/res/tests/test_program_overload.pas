program test_program_overload;

(* ALLOW_WARNINGS *)

(* EXPECT:
7
4
42
*)

// Two overloaded functions -- Integer and Single variants
function Add(A, B: Integer): Integer; overload;
begin
  Result := A + B;
end;

function Add(A, B: Single): Single; overload;
begin
  Result := A + B;
end;

function Add(A, B: Double): Double; overload;
begin
  Result := A + B;
end;

// C linkage function (no overload)
function GetSize: Integer;
begin
  Result := 42;
end;

var
  LIntA:    Integer;
  LIntB:    Integer;
  LSingleA: Single;
  LSingleB: Single;

begin
  LIntA    := 3;
  LIntB    := 4;
  LSingleA := 1.5;
  LSingleB := 2.5;
  WriteLn(Add(LIntA, LIntB));
  WriteLn(Add(LSingleA, LSingleB));
  WriteLn(GetSize());
end.
