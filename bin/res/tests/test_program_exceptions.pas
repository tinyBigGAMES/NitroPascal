program test_program_exceptions;

// Comprehensive exception test covering:
//   software exceptions, raiseexceptioncode, try/finally,
//   try/except/finally, nested try, hardware div-by-zero,
//   local/param/global capture, routine with try, sequential try,
//   exception propagation.

var
  gValue: integer;
  x:      integer;
  localA: integer;
  localB: integer;
  LMsg:   string;
  LCode:  integer;
  LDone:  boolean;

// Helper: returns zero at runtime -- prevents compiler constant-folding
// the divide so the hardware exception actually fires.
function GetZero(): integer;
begin
  Result := 0;
end;

// Test local variable capture inside a routine try block
procedure TestLocalCapture();
var
  LLocalVar: integer;
begin
  LLocalVar := 100;
  writeln('Before: localVar=', LLocalVar);
  try
    writeln('Inside try: localVar=', LLocalVar);
    LLocalVar := 200;
    writeln('After modify: localVar=', LLocalVar);
  except
    writeln('Should not reach');
  end;
  writeln('After try: localVar=', LLocalVar);
end;

// Test parameter capture inside a routine try block
procedure TestParamCapture(const AValue: integer);
begin
  try
    writeln('Param in try: value=', AValue);
  except
    writeln('Should not reach');
  end;
end;

// Routine with try that computes a result
function ComputeWithTry(const AA: integer; const AB: integer): integer;
begin
  Result := 0;
  try
    Result := AA + AB;
  except
    Result := -1;
  end;
end;

// Routine that raises -- for propagation test
procedure ThrowingRoutine();
begin
  raiseexception('Propagated error');
end;

// Test exception propagation from nested routine
procedure TestPropagation();
begin
  try
    ThrowingRoutine();
  except
    writeln('Caught propagated: code=', getexceptioncode());
  end;
end;

begin
  // --- Test 1: Basic try/except ---
  writeln('=== Basic try/except ===');
  try
    raiseexception('Test error');
    writeln('Should not print');
  except
    writeln('Exception caught: code=', getexceptioncode(), ' msg=', getexceptionmessage());
  end;

  // --- Test 2: try/finally without exception ---
  writeln('=== Try/finally (no exception) ===');
  try
    writeln('In try block');
  finally
    writeln('In finally block');
  end;
  writeln('After try');

  // --- Test 3: try/except/finally ---
  writeln('=== Try/except/finally ===');
  try
    writeln('In try block');
    raiseexception('Error!');
  except
    writeln('In except block: code=', getexceptioncode());
  finally
    writeln('In finally block');
  end;

  // --- Test 4: raiseexceptioncode ---
  writeln('=== raiseexceptioncode ===');
  try
    raiseexceptioncode(42, 'Custom error');
  except
    writeln('Custom code: ', getexceptioncode(), ' msg=', getexceptionmessage());
  end;

  // --- Test 5: Nested try blocks ---
  writeln('=== Nested try ===');
  try
    try
      raiseexception('Inner error');
    except
      writeln('Inner exception caught');
    end;
  finally
    writeln('Outer finally');
  end;

  // --- Test 6: Hardware exception (div by zero) ---
  writeln('=== Hardware exception (div by zero) ===');
  try
    x := 10 div GetZero();
    writeln('Should not print: ', x);
  except
    writeln('Hardware exception caught: code=', getexceptioncode(), ' msg=', getexceptionmessage());
  end;

  // --- Test 7: Local variable capture in routine ---
  writeln('=== Local variable capture ===');
  TestLocalCapture();

  // --- Test 8: Parameter capture ---
  writeln('=== Parameter capture ===');
  TestParamCapture(42);

  // --- Test 9: Global variable access in try ---
  writeln('=== Global variable in try ===');
  gValue := 999;
  try
    writeln('Global in try: gValue=', gValue);
  except
    writeln('Should not reach');
  end;

  // --- Test 10: Routine with try that computes result ---
  writeln('=== Routine with try modifying local ===');
  x := ComputeWithTry(10, 20);
  writeln('Result: ', x);

  // --- Test 11: Multiple sequential try blocks sharing locals ---
  writeln('=== Multiple sequential try blocks ===');
  localA := 0;
  localB := 0;
  try
    localA := 10;
    writeln('First try ok');
  except
    writeln('Should not reach');
  end;
  try
    localB := 20;
    writeln('Second try ok');
  except
    writeln('Should not reach');
  end;
  writeln('localA=', localA, ' localB=', localB);

  // --- Test 12: Exception propagation from nested routine ---
  writeln('=== Exception propagation ===');
  TestPropagation();

  writeln('Done');
end.
