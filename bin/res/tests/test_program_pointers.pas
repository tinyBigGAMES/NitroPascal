(* EXPECT:
99
7
10
20
30
40
50
30
*)

program test_program_pointers;

// Tests: pointer var decls, pointer type aliases, array 1-based indexing

type
  PInteger = ^Integer;

var
  n:   Integer;
  p:   ^Integer;
  q:   PInteger;
  arr: array[1..5] of Integer;
  i:   Integer;

begin
  // Basic pointer usage
  n := 42;
  p := @n;
  p^ := 99;
  WriteLn(n);       // 99

  q := @n;
  q^ := 7;
  WriteLn(n);       // 7

  // Array 1-based indexing
  for i := 1 to 5 do
    arr[i] := i * 10;

  for i := 1 to 5 do
    WriteLn(arr[i]);  // 10 20 30 40 50

  // Pointer to array element
  p := @arr[3];
  WriteLn(p^);      // 30
end.
