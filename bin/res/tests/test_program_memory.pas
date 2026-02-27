(* EXPECT:
42
7
99
0
true
4
1
8
*)

program test_program_memory;

var
  p: ^Integer;
  q: ^Byte;
  i: Integer;
  b: Byte;

begin
  // --- GetMem / FreeMem ---
  GetMem(p, 4);
  p^ := 42;
  WriteLn(p^);           // 42
  FreeMem(p);

  // --- ReallocMem ---
  GetMem(q, 1);
  q^ := 7;
  WriteLn(q^);           // 7
  ReallocMem(q, 2);
  q^ := 99;
  WriteLn(q^);           // 99
  FreeMem(q);

  // --- FillChar ---
  i := 0;
  FillChar(@i, 4, 0);
  WriteLn(i);            // 0

  // --- Move ---
  i := 12345;
  b := 0;
  Move(@i, @b, 1);
  WriteLn(b > 0);        // true (low byte of 12345 is non-zero)

  // --- SizeOf (using variables, type names not valid in expr position) ---
  WriteLn(SizeOf(i));        // 8 (64-bit Integer)
  WriteLn(SizeOf(b));        // 1 (Byte)
  WriteLn(SizeOf(p));        // 8 (pointer, 64-bit)
end.
