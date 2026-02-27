(* EXPECT:
0
1
0
0
0
1
1024
3
0.75
4
3
0
*)

program test_program_math;

var
  d: Double;
  i: Integer;

begin
  // --- Transcendental ---
  WriteLn(Sin(0.0));          // 0
  WriteLn(Cos(0.0));          // 1
  WriteLn(Tan(0.0));          // 0
  WriteLn(ArcTan(0.0));       // 0
  WriteLn(Ln(1.0));           // 0
  WriteLn(Exp(0.0));          // 1
  WriteLn(Power(2.0, 10.0));  // 1024

  // --- Int / Frac ---
  d := 3.75;
  WriteLn(Int(d));            // 3
  WriteLn(Frac(d));           // 0.75

  // --- Ceil / Floor ---
  WriteLn(Ceil(3.2));         // 4
  WriteLn(Floor(3.9));        // 3

  // --- Random / Randomize ---
  Randomize();
  // Random(1) is always 0: rand() mod 1 = 0
  i := Random(1);
  WriteLn(i);                 // 0
end.
