(* EXPECT:
true
true
true
true
true
false
true
hello
42
hello
false
*)

program test_program_fileio2;

var
  LF:  TextFile;
  s:   String;
  i:   Integer;
  d:   Double;
  dir: String;

begin
  // --- GetCurrentDir ---
  dir := GetCurrentDir();
  WriteLn(Length(dir) > 0);          // true

  // --- CreateDir ---
  WriteLn(CreateDir('test_tmp_dir')); // true
  WriteLn(DirectoryExists('test_tmp_dir')); // true

  // --- RenameFile (rename dir is not portable; test with a file) ---
  Assign(LF, 'test_rename_src.txt');
  Rewrite(LF);
  Close(LF);
  WriteLn(FileExists('test_rename_src.txt'));         // true
  WriteLn(RenameFile('test_rename_src.txt', 'test_rename_dst.txt')); // true
  WriteLn(FileExists('test_rename_src.txt'));         // false
  WriteLn(FileExists('test_rename_dst.txt'));         // true
  DeleteFile('test_rename_dst.txt');

  // --- ReadLn(f, v) ---
  Assign(LF, 'test_read_tmp.txt');
  Rewrite(LF);
  WriteLn(LF, 'hello');
  WriteLn(LF, '42');
  Close(LF);
  Reset(LF);
  ReadLn(LF, s);
  WriteLn(s);                         // hello
  ReadLn(LF, s);
  WriteLn(s);                         // 42
  Close(LF);

  // --- Read(f, v) ---
  Reset(LF);
  Read(LF, s);
  WriteLn(s);                         // hello
  Close(LF);
  DeleteFile('test_read_tmp.txt');

  // --- DirectoryExists false case ---
  WriteLn(DirectoryExists('nonexistent_dir_xyz')); // false

  // cleanup
  DeleteFile('test_tmp_dir');
end.
