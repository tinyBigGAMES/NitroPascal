program Testbed;

var
  greeting: string;
  count: integer;
  total: integer;
  i: integer;

procedure PrintBanner(msg: string);
begin
  writeln('--- ', msg, ' ---');
end;

function Add(a: integer; b: integer): integer;
begin
  Result := a + b;
end;

begin
  greeting := 'Hello from NitroPascal!';
  count := 5;

  PrintBanner(greeting);

  total := Add(10, 32);
  writeln('10 + 32 = ', total);

  if total > 40 then
    writeln('Total is greater than 40')
  else
    writeln('Total is 40 or less');

  writeln('Counting to ', count, ':');
  for i := 1 to count do
    writeln('  Step ', i);

  i := 0;
  while i < 3 do
  begin
    writeln('While pass: ', i + 1);
    i := i + 1;
  end;
end.
