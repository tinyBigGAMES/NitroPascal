program test_program_arrays_static;

// Test static array declaration and indexed access.
// array[1..5] of Integer maps to std::array<np::Integer, 5>

var
  nums: array[1..5] of Integer;
  i: Integer;

begin
  nums[1] := 10;
  nums[2] := 20;
  nums[3] := 30;
  nums[4] := 40;
  nums[5] := 50;
  for i := 1 to 5 do
    WriteLn(nums[i]);
end.
