(* EXPECT:
two
mid
B
Good job!
three - no else
*)

program test_program_case_of;

var
  x: integer;
  grade: integer;

begin
  // Test 1: Basic single-label arms with else
  x := 2;
  case x of
    1: writeln('one');
    2: writeln('two');
    3: writeln('three');
  else
    writeln('other');
  end;

  // Test 2: Multiple labels on one arm (comma-separated)
  x := 5;
  case x of
    1, 2, 3: writeln('low');
    4, 5, 6: writeln('mid');
    7, 8, 9: writeln('high');
  else
    writeln('out of range');
  end;

  // Test 3: begin..end body in an arm
  grade := 85;
  case grade of
    90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100: begin
      writeln('A');
      writeln('Excellent!');
    end;
    80, 81, 82, 83, 84, 85, 86, 87, 88, 89: begin
      writeln('B');
      writeln('Good job!');
    end;
  else
    begin
      writeln('C or below');
      writeln('Keep trying!');
    end;
  end;

  // Test 4: No else branch
  x := 3;
  case x of
    1: writeln('one - no else');
    2: writeln('two - no else');
    3: writeln('three - no else');
  end;
end.
