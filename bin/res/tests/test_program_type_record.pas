program test_program_type_record;

// Record type declarations - global scope

type
  TPoint = record
    X: Integer;
    Y: Integer;
  end;

  TRect = record
    Left:   Integer;
    Top:    Integer;
    Right:  Integer;
    Bottom: Integer;
  end;

  // Multi-field shorthand: R, G, B declared on one line
  TColor = record
    R, G, B: Byte;
  end;

  // Nested record: a field whose type is another record
  TColoredPoint = record
    Pos:   TPoint;
    Color: TColor;
  end;

  // Simple type alias
  TMyInt = Integer;

// Global variables

var
  GPoint:        TPoint;
  GRect:         TRect;
  GColor:        TColor;
  GColoredPoint: TColoredPoint;
  GAlias:        TMyInt;

// Procedure: record passed by value (const)

procedure PrintPoint(const APoint: TPoint);
begin
  WriteLn(APoint.X);
  WriteLn(APoint.Y);
end;

// Procedure: record passed by reference (var) - mutates caller

procedure ShiftPoint(var APoint: TPoint; const ADX: Integer; const ADY: Integer);
begin
  APoint.X := APoint.X + ADX;
  APoint.Y := APoint.Y + ADY;
end;

// Procedure: record passed as out parameter

procedure MakeColor(out AColor: TColor; const AR: Byte; const AG: Byte; const AB: Byte);
begin
  AColor.R := AR;
  AColor.G := AG;
  AColor.B := AB;
end;

// Function: returns a record

function MakePoint(const AX: Integer; const AY: Integer): TPoint;
var
  LTemp: TPoint;
begin
  LTemp.X := AX;
  LTemp.Y := AY;
  Result  := LTemp;
end;

// Function: accepts nested record, reads nested field

function GetNestedX(const ACP: TColoredPoint): Integer;
begin
  Result := ACP.Pos.X;
end;

// Procedure: local record variables

procedure TestLocalRecords();
var
  LPt:   TPoint;
  LRect: TRect;
begin
  LPt.X := 100;
  LPt.Y := 200;
  WriteLn(LPt.X);
  WriteLn(LPt.Y);

  LRect.Left   := 0;
  LRect.Top    := 0;
  LRect.Right  := 640;
  LRect.Bottom := 480;
  WriteLn(LRect.Right);
  WriteLn(LRect.Bottom);
end;

// Main

begin
  // Basic global field assignment and read
  GPoint.X := 10;
  GPoint.Y := 20;
  WriteLn(GPoint.X);   // 10
  WriteLn(GPoint.Y);   // 20

  // Multiple fields on a rect
  GRect.Left   := 5;
  GRect.Top    := 10;
  GRect.Right  := 800;
  GRect.Bottom := 600;
  WriteLn(GRect.Left);    // 5
  WriteLn(GRect.Bottom);  // 600

  // Pass record by value (const param)
  PrintPoint(GPoint);  // 10 / 20

  // Pass record by reference (var param)
  ShiftPoint(GPoint, 3, 7);
  WriteLn(GPoint.X);  // 13
  WriteLn(GPoint.Y);  // 27

  // Pass record as out param
  MakeColor(GColor, 255, 128, 64);
  WriteLn(GColor.R);  // 255
  WriteLn(GColor.G);  // 128
  WriteLn(GColor.B);  // 64

  // Function returning a record
  GPoint := MakePoint(42, 99);
  WriteLn(GPoint.X);  // 42
  WriteLn(GPoint.Y);  // 99

  // Nested record field assignment and access
  GColoredPoint.Pos.X   := 7;
  GColoredPoint.Pos.Y   := 8;
  GColoredPoint.Color.R := 1;
  GColoredPoint.Color.G := 2;
  GColoredPoint.Color.B := 3;
  WriteLn(GColoredPoint.Pos.X);    // 7
  WriteLn(GColoredPoint.Color.B);  // 3

  // Function reading nested record
  WriteLn(GetNestedX(GColoredPoint));  // 7

  // Local record variables
  TestLocalRecords();  // 100 / 200 / 640 / 480

  // Type alias
  GAlias := 999;
  WriteLn(GAlias);  // 999
end.
