(* EXPECT:
A
a
0
255
16
26
16
equal
*)

program test_program_char_hex;

// Test #ordinal char literals and $hex integer literals.
// #65 maps to static_cast<np::Char>(65)  -> 'A'
// $FF maps to 255 (decimal integer)

var
  c: Char;
  n: Integer;

begin
  // Char literal via ordinal
  c := #65;
  WriteLn(c);    // A

  c := #97;
  WriteLn(c);    // a

  c := #48;
  WriteLn(c);    // 0

  // Hex integer literals
  n := $FF;
  WriteLn(n);    // 255

  n := $10;
  WriteLn(n);    // 16

  n := $1A;
  WriteLn(n);    // 26

  // Hex in expression
  n := $0F + $01;
  WriteLn(n);    // 16

  // Char ordinal comparison
  if #65 = #65 then
    WriteLn('equal')   // equal
  else
    WriteLn('not equal');
end.
