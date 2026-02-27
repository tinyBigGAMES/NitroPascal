(* EXPECT:
3.14
0
-1.5
2.5
-0.5
True
False
-1
0
*)

program test_program_conversion;

var
  d: Double;

begin
  // --- FloatToStr ---
  WriteLn(FloatToStr(3.14));       // 3.14
  WriteLn(FloatToStr(0.0));        // 0
  WriteLn(FloatToStr(-1.5));       // -1.5

  // --- StrToFloat ---
  d := StrToFloat('2.5');
  WriteLn(d);                      // 2.5
  d := StrToFloat('-0.5');
  WriteLn(d);                      // -0.5

  // --- BoolToStr (default useBoolStrs=true -> "True"/"False") ---
  WriteLn(BoolToStr(True));        // True
  WriteLn(BoolToStr(False));       // False
  WriteLn(BoolToStr(True, False)); // -1
  WriteLn(BoolToStr(False, False));// 0
end.
