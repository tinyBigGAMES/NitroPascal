program test_program_repeat_until;
var
  i: integer;
begin
  i := 1;
  repeat
    writeln(i);
    i := i + 1;
  until i > 5;
end.
