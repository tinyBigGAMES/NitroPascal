program test_program_cpp_interop;

(* EXPECT:
42
100
5
3
*)

// Emit a static inline helper to the header file
cppstart header
static inline int cppMultiply(int a, int b) { return a * b; }
cppend

// Emit a regular function to the source file
cppstart source
int cppAdd(int a, int b) { return a + b; }
cppend

// Pull in an extra std:: header and use it
cppstart header
#include <algorithm>
static inline int cppMax(int a, int b) { return std::max(a, b); }
static inline int cppMin(int a, int b) { return std::min(a, b); }
cppend

var
  LResult: Integer;

begin
  // cpp() calling the header helper
  LResult := cpp('cppMultiply(6, 7)');
  WriteLn(LResult);

  // cpp() calling the source function
  LResult := cpp('cppAdd(68, 32)');
  WriteLn(LResult);

  // cpp() using std::max and std::min via the header block
  LResult := cpp('cppMax(3, 5)');
  WriteLn(LResult);

  LResult := cpp('cppMin(3, 5)');
  WriteLn(LResult);
end.
