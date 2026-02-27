(* EXPECT:
3
0
1
20
30
*)

program test_program_fileio3;

var
  LF:  BinaryFile;
  LVal: Integer;
  LPos: Integer;
  LSz:  Integer;

begin
  // --- Write some integers to a binary file ---
  Assign(LF, 'test_binary_tmp.bin');
  Rewrite(LF);
  LVal := 10;
  BlockWrite(LF, LVal, 1);
  LVal := 20;
  BlockWrite(LF, LVal, 1);
  LVal := 30;
  BlockWrite(LF, LVal, 1);
  Close(LF);

  // --- FileSize / FilePos / Seek ---
  Reset(LF);
  LSz := FileSize(LF);
  WriteLn(LSz);              // 3  (3 records of sizeof(Integer) bytes)

  LPos := FilePos(LF);
  WriteLn(LPos);             // 0  (at start)

  Seek(LF, 1);
  LPos := FilePos(LF);
  WriteLn(LPos);             // 1  (after seek to record 1)

  BlockRead(LF, LVal, 1);
  WriteLn(LVal);             // 20 (record at index 1)

  Seek(LF, 2);
  BlockRead(LF, LVal, 1);
  WriteLn(LVal);             // 30 (record at index 2)

  Close(LF);
  DeleteFile('test_binary_tmp.bin');
end.
