program test_program_intrinsics;

var
  i:   Integer;
  d:   Double;
  s:   String;
  c:   Char;
  p:   ^Integer;

begin
  // Ordinal
  i := 5;
  Inc(i);
  WriteLn(i);             // 6
  Dec(i, 2);
  WriteLn(i);             // 4
  WriteLn(Odd(i));        // false
  WriteLn(Odd(3));        // true
  c := Chr(65);
  WriteLn(c);             // A
  WriteLn(Ord(c));        // 65
  WriteLn(Succ(i));       // 5
  WriteLn(Pred(i));       // 3

  // String
  s := 'Hello World';
  WriteLn(Length(s));               // 11
  WriteLn(Copy(s, 1, 5));           // Hello
  WriteLn(Pos('World', s));         // 7
  WriteLn(UpperCase(s));            // HELLO WORLD
  WriteLn(LowerCase(s));            // hello world
  WriteLn(Trim('  hi  '));          // hi
  WriteLn(IntToStr(42));            // 42
  WriteLn(StrToInt('99'));          // 99
  WriteLn(StrToIntDef('bad', 0));   // 0
  WriteLn(StringOfChar('*', 5));    // *****

  // Math
  WriteLn(Abs(-7));        // 7
  WriteLn(Sqr(4));         // 16
  WriteLn(Sqrt(9.0));      // 3
  WriteLn(Max(3, 7));      // 7
  WriteLn(Min(3, 7));      // 3
  WriteLn(Round(3.7));     // 4
  WriteLn(Trunc(3.9));     // 3

  // Memory
  New(p);
  p^ := 123;
  WriteLn(p^);            // 123
  WriteLn(Assigned(p));   // true
  Dispose(p);
  WriteLn(Assigned(p));   // false
end.
