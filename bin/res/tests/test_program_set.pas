program test_program_set;

// Test set of T: declaration, type alias, set literal assignment,
// Include, Exclude, and the 'in' membership operator.
// set of Integer maps to np::Set<np::Integer>
// [a, b, c] maps to np::MakeSet({a, b, c})
// Include(s, e) maps to np::Include(s, e)
// Exclude(s, e) maps to np::Exclude(s, e)
// x in s maps to np::In(x, s)

type
  TIntSet = set of Integer;

var
  s: set of Integer;
  t: TIntSet;
  x: Integer;
  found: Boolean;

begin
  // Assign a set literal
  s := [1, 2, 3, 5];

  // Membership test using 'in'
  found := 3 in s;
  WriteLn(found);   // true

  found := 4 in s;
  WriteLn(found);   // false

  // Add element with Include
  Include(s, 4);
  found := 4 in s;
  WriteLn(found);   // true

  // Remove element with Exclude
  Exclude(s, 2);
  found := 2 in s;
  WriteLn(found);   // false

  // Use the type alias
  t := [10, 20, 30];
  found := 20 in t;
  WriteLn(found);   // true

  // Iterate known values and test membership
  for x := 1 to 5 do
  begin
    found := x in s;
    WriteLn(found);
  end;
end.
