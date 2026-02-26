program test_program_const_block;

const
  MAX_VALUE = 100;
  APP_NAME  = 'NitroPascal';

const
  PI: double  = 3.14159;
  LIMIT: integer = 50;

var
  x: integer;

procedure PrintMax();
const
  LOCAL_LABEL = 'Max is:';
begin
  writeln(LOCAL_LABEL, MAX_VALUE);
end;

function DoubleLimit(): integer;
const
  FACTOR = 2;
begin
  Result := LIMIT * FACTOR;
end;

begin
  // Test global untyped constants
  writeln(APP_NAME);
  writeln(MAX_VALUE);

  // Test global typed constants
  writeln(PI);
  writeln(LIMIT);

  // Test local const in procedure
  PrintMax();

  // Test local const in function
  x := DoubleLimit();
  writeln(x);

  // Test constant used in expression
  x := MAX_VALUE + LIMIT;
  writeln(x);
end.
