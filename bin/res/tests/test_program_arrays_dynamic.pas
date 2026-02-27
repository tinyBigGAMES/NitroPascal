(* EXPECT:
100
200
300
400
500
*)

program test_program_arrays_dynamic;

// Test dynamic array declaration, SetLength, and indexed access.
// array of Integer maps to np::DynArray<np::Integer>
// SetLength maps to np::SetLength

var
  nums: array of Integer;
  i: Integer;

begin
  SetLength(nums, 5);
  nums[0] := 100;
  nums[1] := 200;
  nums[2] := 300;
  nums[3] := 400;
  nums[4] := 500;
  for i := 0 to 4 do
    WriteLn(nums[i]);
end.
