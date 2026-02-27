(* EXPECT:
Hello
def
Hello World
abce
*)

program test_program_string2;

var
  s: String;

begin
  // --- Delete ---
  s := 'Hello World';
  Delete(s, 6, 6);         // delete ' World'
  WriteLn(s);              // Hello

  s := 'abcdef';
  Delete(s, 1, 3);         // delete 'abc'
  WriteLn(s);              // def

  // --- Insert ---
  s := 'Hello';
  Insert(' World', s, 6);  // insert at end
  WriteLn(s);              // Hello World

  s := 'ace';
  Insert('b', s, 2);       // insert 'b' at position 2
  WriteLn(s);              // abce
end.
