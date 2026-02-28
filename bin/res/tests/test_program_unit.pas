(* EXPECT:
5
12
TRUE
FALSE
10
*)

program test_program_unit;

uses
  test_unit_mathutils;

var
  LSum:     Integer;
  LProduct: Integer;

begin
  LSum     := Add(2, 3);
  LProduct := Multiply(3, 4);

  WriteLn(LSum);              // 5
  WriteLn(LProduct);          // 12
  WriteLn(IsEven(LProduct));  // TRUE
  WriteLn(IsEven(LSum));      // FALSE

  // Chained call
  WriteLn(Add(Multiply(2, 3), Multiply(1, 4)));  // 10
end.
