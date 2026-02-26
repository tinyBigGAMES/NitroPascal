program test_program_exit_break_continue;
var
  i: integer;

procedure TestExit;
begin
  exit;
end;

function TestExitValue: integer;
begin
  exit(42);
end;

begin
  i := 1;
  repeat
    if i = 3 then
      break;
    i := i + 1;
  until i > 10;
  writeln(i);

  i := 0;
  while i < 10 do
  begin
    i := i + 1;
    if i = 5 then
      continue;
    writeln(i);
  end;
end.
