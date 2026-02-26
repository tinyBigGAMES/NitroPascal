program test_program_intrinsics;

var
  i:    Integer;
  d:    Double;
  s:    String;
  c:    Char;
  p:    ^Integer;
  LArr: array of Integer;
  LF:   TextFile;

begin
  // --- Ordinal ---
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

  // --- String (original) ---
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

  // --- String (new) ---
  WriteLn(CompareStr('abc', 'abc'));       // 0
  WriteLn(CompareStr('abc', 'abd') < 0);  // true
  WriteLn(SameText('Hello', 'hello'));     // true
  WriteLn(SameText('Hello', 'world'));     // false
  WriteLn(QuotedStr('hello'));             // 'hello'
  WriteLn(StringReplace('foo bar foo', 'foo', 'baz'));  // baz bar baz
  WriteLn(Format('%s is %d years old', 'Alice', 30));   // Alice is 30 years old

  // --- Math ---
  WriteLn(Abs(-7));        // 7
  WriteLn(Sqr(4));         // 16
  WriteLn(Sqrt(9.0));      // 3
  WriteLn(Max(3, 7));      // 7
  WriteLn(Min(3, 7));      // 3
  WriteLn(Round(3.7));     // 4
  WriteLn(Trunc(3.9));     // 3

  // --- Memory ---
  New(p);
  p^ := 123;
  WriteLn(p^);             // 123
  WriteLn(Assigned(p));    // true
  Dispose(p);
  WriteLn(Assigned(p));    // false

  // --- Low / High ---
  SetLength(LArr, 5);
  WriteLn(Low(LArr));      // 0
  WriteLn(High(LArr));     // 4

  // --- Abort ---
  try
    Abort();
    WriteLn('should not print');
  except
    WriteLn('Abort caught');   // Abort caught
  end;

  // --- ParamCount / ParamStr ---
  WriteLn(ParamCount());          // 0 (no args passed)
  WriteLn(ParamStr(0));           // path to executable (non-empty)

  // --- File I/O ---
  Assign(LF, 'test_intrinsics_tmp.txt');
  Rewrite(LF);
  WriteLn(LF, 'line one');
  WriteLn(LF, 'line two');
  Close(LF);
  WriteLn(FileExists('test_intrinsics_tmp.txt'));   // true
  Reset(LF);
  ReadLn(LF, s);
  WriteLn(s);     // line one
  ReadLn(LF, s);
  WriteLn(s);     // line two
  WriteLn(Eof(LF));   // true
  Close(LF);
  DeleteFile('test_intrinsics_tmp.txt');
  WriteLn(FileExists('test_intrinsics_tmp.txt'));   // false
end.
