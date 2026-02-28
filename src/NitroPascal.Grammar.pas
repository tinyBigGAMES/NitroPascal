{===============================================================================
  NitroPascal™ - Modern Pascal * C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit NitroPascal.Grammar;

{$I NitroPascal.Defines.inc}

interface

uses
  Parse;

procedure ConfigGrammar(const AParse: TParse);

implementation

uses
  System.Classes,
  System.Rtti;

// =========================================================================
// PREFIX HANDLERS
// =========================================================================

// --- Literal Prefixes (identifier, integer, real, string) ---

procedure RegisterLiteralPrefixes(const AParse: TParse);
begin
  AParse.Config().RegisterLiteralPrefixes();
end;

// --- Nil Literal ---

procedure RegisterNilLiteral(const AParse: TParse);
begin
  AParse.Config().RegisterPrefix('keyword.nil', 'expr.nil',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();
      Result := LNode;
    end);
end;

// --- Boolean Literals ---

procedure RegisterBooleanLiterals(const AParse: TParse);
begin
  // true
  AParse.Config().RegisterPrefix('keyword.true', 'expr.bool',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();
      Result := LNode;
    end);

  // false
  AParse.Config().RegisterPrefix('keyword.false', 'expr.bool',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();
      Result := LNode;
    end);
end;

// --- Unary Not ---

procedure RegisterUnaryNot(const AParse: TParse);
begin
  AParse.Config().RegisterPrefix('keyword.not', 'expr.unary',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode();
      LNode.SetAttr('op', TValue.From<string>('!'));
      AParser.Consume();
      LNode.AddChild(TParseASTNode(AParser.ParseExpression(50)));
      Result := LNode;
    end);
  // Unary minus: -expr
  AParse.Config().RegisterPrefix('op.minus', 'expr.unary',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode();
      LNode.SetAttr('op', TValue.From<string>('-'));
      AParser.Consume();
      LNode.AddChild(TParseASTNode(AParser.ParseExpression(50)));
      Result := LNode;
    end);
  // Unary plus: +expr (no-op, but valid Pascal)
  AParse.Config().RegisterPrefix('op.plus', 'expr.unary',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode();
      LNode.SetAttr('op', TValue.From<string>('+'));
      AParser.Consume();
      LNode.AddChild(TParseASTNode(AParser.ParseExpression(50)));
      Result := LNode;
    end);
end;

// --- Grouped Expression: (expr) ---

procedure RegisterGroupedExpr(const AParse: TParse);
begin
  AParse.Config().RegisterPrefix('delimiter.lparen', 'expr.grouped',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      AParser.Consume();  // consume '('
      LNode := AParser.CreateNode('expr.grouped');
      LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));
      AParser.Expect('delimiter.rparen');
      Result := LNode;
    end);
end;

// --- Address-Of: @x ---

procedure RegisterAddrOf(const AParse: TParse);
begin
  AParse.Config().RegisterPrefix('op.addr', 'expr.addr',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();  // consume '@'
      // Power 0: consume the full postfix expression (e.g. arr[i], rec.field)
      LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));
      Result := LNode;
    end);
end;

// --- Char Literal: #65 ---

procedure RegisterCharLiteral(const AParse: TParse);
begin
  // #<integer> -> expr.char_literal; the ordinal value is stored as an attr
  AParse.Config().RegisterPrefix('op.hash', 'expr.char_literal',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode:    TParseASTNode;
      LOrdinal: string;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();  // consume '#'
      // The following token must be a decimal integer
      LOrdinal := AParser.CurrentToken().Text;
      LNode.SetAttr('char.ordinal', TValue.From<string>(LOrdinal));
      AParser.Consume();  // consume the integer
      Result := LNode;
    end);
end;

// --- Hex Literal: hex integer prefixed with dollar sign ---

procedure RegisterHexLiteral(const AParse: TParse);
begin
  // dollar + hex_digits -> expr.hex_literal; emit the decimal equivalent.
  // Mixed tokens: e.g. hex FF is one identifier token, but hex 1A is
  // tokenised as integer(1) + identifier(A). We therefore loop to collect
  // all consecutive integer/identifier tokens and concatenate them.
  AParse.Config().RegisterPrefix('op.dollar', 'expr.hex_literal',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode:   TParseASTNode;
      LHexStr: string;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();  // consume the dollar sign operator
      // Collect all adjacent integer/identifier tokens that form the hex string
      LHexStr := '';
      while AParser.Check(PARSE_KIND_INTEGER) or
            AParser.Check(PARSE_KIND_IDENTIFIER) do
      begin
        LHexStr := LHexStr + AParser.CurrentToken().Text;
        AParser.Consume();
      end;
      LNode.SetAttr('hex.digits', TValue.From<string>(LHexStr));
      Result := LNode;
    end);
end;

// --- Set Literal: [a, b, c] ---

procedure RegisterSetLiteral(const AParse: TParse);
begin
  AParse.Config().RegisterPrefix('delimiter.lbracket', 'expr.set_literal',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();  // consume '['
      if not AParser.Check('delimiter.rbracket') then
      begin
        LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));
        while AParser.Match('delimiter.comma') do
          LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));
      end;
      AParser.Expect('delimiter.rbracket');
      Result := LNode;
    end);
end;

// =========================================================================
// INFIX HANDLERS
// =========================================================================

// --- Assignment ---

procedure RegisterAssignment(const AParse: TParse);
begin
  // := (right-assoc, power 2)
  AParse.Config().RegisterInfixRight('op.assign', 2, 'expr.assign',
    function(AParser: TParseParserBase;
      ALeft: TParseASTNodeBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode();
      LNode.SetAttr('op', TValue.From<string>(':='));
      AParser.Consume();
      LNode.AddChild(TParseASTNode(ALeft));
      LNode.AddChild(TParseASTNode(
        AParser.ParseExpression(AParser.CurrentInfixPowerRight())));
      Result := LNode;
    end);
end;

// --- Arithmetic Operators ---

procedure RegisterArithmeticOps(const AParse: TParse);
begin
  // + (power 20)
  AParse.Config().RegisterBinaryOp('op.plus', 20, '+');

  // - (power 20)
  AParse.Config().RegisterBinaryOp('op.minus', 20, '-');

  // * (power 30)
  AParse.Config().RegisterBinaryOp('op.multiply', 30, '*');

  // / (power 30)
  AParse.Config().RegisterBinaryOp('op.divide', 30, '/');

  // div (power 30) -- maps to np::Div() for divide-by-zero protection
  AParse.Config().RegisterInfixLeft('keyword.div', 30, 'expr.div',
    function(AParser: TParseParserBase;
      ALeft: TParseASTNodeBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode('expr.div', AParser.CurrentToken());
      AParser.Consume();
      LNode.AddChild(TParseASTNode(ALeft));
      LNode.AddChild(TParseASTNode(
        AParser.ParseExpression(AParser.CurrentInfixPower())));
      Result := LNode;
    end);

  // mod (power 30) -- maps to np::Mod() for divide-by-zero protection
  AParse.Config().RegisterInfixLeft('keyword.mod', 30, 'expr.mod',
    function(AParser: TParseParserBase;
      ALeft: TParseASTNodeBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode('expr.mod', AParser.CurrentToken());
      AParser.Consume();
      LNode.AddChild(TParseASTNode(ALeft));
      LNode.AddChild(TParseASTNode(
        AParser.ParseExpression(AParser.CurrentInfixPower())));
      Result := LNode;
    end);
end;

// --- Comparison Operators ---

procedure RegisterComparisonOps(const AParse: TParse);
begin
  // = (power 10)
  AParse.Config().RegisterBinaryOp('op.eq', 10, '==');

  // <> (power 10)
  AParse.Config().RegisterBinaryOp('op.neq', 10, '!=');

  // < (power 10)
  AParse.Config().RegisterBinaryOp('op.lt', 10, '<');

  // > (power 10)
  AParse.Config().RegisterBinaryOp('op.gt', 10, '>');

  // <= (power 10)
  AParse.Config().RegisterBinaryOp('op.lte', 10, '<=');

  // >= (power 10)
  AParse.Config().RegisterBinaryOp('op.gte', 10, '>=');
end;

// --- Logical Operators ---

procedure RegisterLogicalOps(const AParse: TParse);
begin
  // and (power 8)
  AParse.Config().RegisterBinaryOp('keyword.and', 8, '&&');

  // or (power 6)
  AParse.Config().RegisterBinaryOp('keyword.or', 6, '||');

  // xor (power 8)
  AParse.Config().RegisterBinaryOp('keyword.xor', 8, '^');
end;

// --- Bitwise Shift Operators ---

procedure RegisterBitwiseShiftOps(const AParse: TParse);
begin
  // shl (power 25) -- maps to np::Shl()
  AParse.Config().RegisterInfixLeft('keyword.shl', 25, 'expr.shl',
    function(AParser: TParseParserBase;
      ALeft: TParseASTNodeBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode('expr.shl', AParser.CurrentToken());
      AParser.Consume();
      LNode.AddChild(TParseASTNode(ALeft));
      LNode.AddChild(TParseASTNode(
        AParser.ParseExpression(AParser.CurrentInfixPower())));
      Result := LNode;
    end);

  // shr (power 25) -- maps to np::Shr()
  AParse.Config().RegisterInfixLeft('keyword.shr', 25, 'expr.shr',
    function(AParser: TParseParserBase;
      ALeft: TParseASTNodeBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode('expr.shr', AParser.CurrentToken());
      AParser.Consume();
      LNode.AddChild(TParseASTNode(ALeft));
      LNode.AddChild(TParseASTNode(
        AParser.ParseExpression(AParser.CurrentInfixPower())));
      Result := LNode;
    end);
end;

// --- Function/Procedure Call (infix lparen) ---

procedure RegisterCallExpr(const AParse: TParse);
begin
  // ( as infix -- function/procedure call (left-assoc, power 40)
  AParse.Config().RegisterInfixLeft('delimiter.lparen', 40, 'expr.call',
    function(AParser: TParseParserBase;
      ALeft: TParseASTNodeBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode('expr.call', ALeft.GetToken());
      LNode.SetAttr('call.name',
        TValue.From<string>(ALeft.GetToken().Text));
      AParser.Consume();  // consume '('
      if not AParser.Check('delimiter.rparen') then
      begin
        LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));
        while AParser.Match('delimiter.comma') do
          LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));
      end;
      AParser.Expect('delimiter.rparen');
      Result := LNode;
    end);
end;

// --- In Operator: x in mySet ---

procedure RegisterInOperator(const AParse: TParse);
begin
  // 'in' as infix -- set membership test (left-assoc, power 10, same as comparisons)
  AParse.Config().RegisterInfixLeft('keyword.in', 10, 'expr.in',
    function(AParser: TParseParserBase;
      ALeft: TParseASTNodeBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode('expr.in', AParser.CurrentToken());
      AParser.Consume();  // consume 'in'
      LNode.AddChild(TParseASTNode(ALeft));
      LNode.AddChild(TParseASTNode(
        AParser.ParseExpression(AParser.CurrentInfixPower())));
      Result := LNode;
    end);
end;

// --- Array Index Expression: arr[i] ---

procedure RegisterArrayIndex(const AParse: TParse);
begin
  // '[' as infix -- array subscript (left-assoc, power 45)
  AParse.Config().RegisterInfixLeft('delimiter.lbracket', 45,
    'expr.array_index',
    function(AParser: TParseParserBase;
      ALeft: TParseASTNodeBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode('expr.array_index', ALeft.GetToken());
      AParser.Consume();  // consume '['
      LNode.AddChild(TParseASTNode(ALeft));
      LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));
      AParser.Expect('delimiter.rbracket');
      Result := LNode;
    end);
end;

// --- Field Access: rec.field ---

procedure RegisterFieldAccess(const AParse: TParse);
begin
  // '.' as infix -- record field access (left-assoc, power 45)
  AParse.Config().RegisterInfixLeft('delimiter.dot', 45,
    'expr.field_access',
    function(AParser: TParseParserBase;
      ALeft: TParseASTNodeBase): TParseASTNodeBase
    var
      LNode:     TParseASTNode;
      LFieldTok: TParseToken;
    begin
      AParser.Consume();  // consume '.'
      LFieldTok := AParser.CurrentToken();
      LNode := AParser.CreateNode('expr.field_access', LFieldTok);
      LNode.SetAttr('field.name', TValue.From<string>(LFieldTok.Text));
      LNode.AddChild(TParseASTNode(ALeft));
      AParser.Consume();  // consume field name identifier
      Result := LNode;
    end);
end;

// --- Pointer Dereference: p^ ---

procedure RegisterPointerDeref(const AParse: TParse);
begin
  // '^' as postfix-infix (left-assoc, power 50) -- no right-hand operand
  AParse.Config().RegisterInfixLeft('op.deref', 50, 'expr.deref',
    function(AParser: TParseParserBase;
      ALeft: TParseASTNodeBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      AParser.Consume();  // consume '^'
      LNode := AParser.CreateNode('expr.deref', ALeft.GetToken());
      LNode.AddChild(TParseASTNode(ALeft));
      Result := LNode;
    end);
end;

// =========================================================================
// STATEMENT HANDLERS
// =========================================================================

// --- Program Header ---
// BNF: ProgramDecl = "program" Identifier ";"
//                    [ "uses" UnitList ";" ]
//                    { VarBlock | ConstBlock | TypeBlock }
//                    { ProcDecl | FuncDecl }
//                    BeginBlock "." .
// AST: stmt.pascal_program
//        [stmt.uses_clause [stmt.uses_item ...]]
//        { decl nodes }
//        stmt.begin_block

procedure RegisterProgramStmt(const AParse: TParse);
begin
  AParse.Config().RegisterStatement('keyword.program', 'stmt.pascal_program',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode:     TParseASTNode;
      LUsesNode: TParseASTNode;
      LItemNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();  // consume 'program'
      LNode.SetAttr('decl.name',
        TValue.From<string>(AParser.CurrentToken().Text));
      AParser.Consume();  // consume program name
      AParser.Expect('delimiter.semicolon');
      // Optional uses clause: uses UnitA, UnitB;
      if AParser.Match('keyword.uses') then
      begin
        LUsesNode := AParser.CreateNode('stmt.uses_clause', AParser.CurrentToken());
        repeat
          LItemNode := AParser.CreateNode('stmt.uses_item', AParser.CurrentToken());
          LItemNode.SetAttr('decl.name',
            TValue.From<string>(AParser.CurrentToken().Text));
          AParser.Consume();  // consume unit name
          LUsesNode.AddChild(LItemNode);
        until not AParser.Match('delimiter.comma');
        AParser.Expect('delimiter.semicolon');
        LNode.AddChild(LUsesNode);
      end;
      // Any number of var/const/type/procedure/function declarations in any order
      while AParser.Check('keyword.var') or
            AParser.Check('keyword.const') or
            AParser.Check('keyword.type') or
            AParser.Check('keyword.procedure') or
            AParser.Check('keyword.function') do
        LNode.AddChild(TParseASTNode(AParser.ParseStatement()));
      // Main begin..end. block
      LNode.AddChild(TParseASTNode(AParser.ParseStatement()));
      AParser.Expect('delimiter.dot');
      Result := LNode;
    end);
end;

// --- Var Block ---

procedure RegisterVarBlock(const AParse: TParse);
begin
  AParse.Config().RegisterStatement('keyword.var', 'stmt.var_block',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode:      TParseASTNode;
      LVarNode:   TParseASTNode;
      LNames:     array[0..31] of TParseToken;
      LNameCount: Integer;
      LTypeText:  string;
      LArrayKind:   string;
      LElemType:    string;
      LArrayLow:    string;
      LArrayHigh:   string;
      LSetKind:     string;
      LPointerKind: string;
      LI:           Integer;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();  // consume 'var'
      // Parse one or more "a, b, c : type ;" declarations
      while AParser.Check(PARSE_KIND_IDENTIFIER) do
      begin
        // Collect all names before the colon
        LNameCount := 0;
        LNames[LNameCount] := AParser.CurrentToken();
        Inc(LNameCount);
        AParser.Consume();  // consume first identifier
        while AParser.Match('delimiter.comma') do
        begin
          LNames[LNameCount] := AParser.CurrentToken();
          Inc(LNameCount);
          AParser.Consume();  // consume next identifier
        end;
        AParser.Expect('delimiter.colon');
        // Initialise tracking fields for this declaration
        LArrayKind   := '';
        LElemType    := '';
        LArrayLow    := '';
        LArrayHigh   := '';
        LSetKind     := '';
        LPointerKind := '';
        if AParser.Check('keyword.array') then
        begin
          AParser.Consume();  // consume 'array'
          LTypeText := 'array';
          if AParser.Match('delimiter.lbracket') then
          begin
            // Static array: array[low..high] of T
            LArrayKind := 'static';
            LArrayLow  := AParser.CurrentToken().Text;
            AParser.Consume();   // consume low bound
            AParser.Expect('op.range');
            LArrayHigh := AParser.CurrentToken().Text;
            AParser.Consume();   // consume high bound
            AParser.Expect('delimiter.rbracket');
          end
          else
            LArrayKind := 'dynamic';
          AParser.Expect('keyword.of');
          LElemType := AParser.CurrentToken().Text;
          AParser.Consume();   // consume element type keyword
        end
        else if AParser.Check('keyword.set') then
        begin
          AParser.Consume();   // consume 'set'
          AParser.Expect('keyword.of');
          LTypeText := 'set';
          LSetKind  := 'set';
          LElemType := AParser.CurrentToken().Text;
          AParser.Consume();   // consume element type keyword
        end
        else if AParser.Check('op.deref') then
        begin
          // Pointer type: ^T
          AParser.Consume();    // consume '^'
          LTypeText    := 'pointer';
          LPointerKind := 'pointer';
          LElemType    := AParser.CurrentToken().Text;
          AParser.Consume();    // consume pointee type
        end
        else
        begin
          // Simple type: single keyword
          LTypeText := AParser.CurrentToken().Text;
          AParser.Consume();   // consume type keyword
        end;
        AParser.Expect('delimiter.semicolon');
        // Create one stmt.var_decl node per name, annotating attrs where needed
        for LI := 0 to LNameCount - 1 do
        begin
          LVarNode := AParser.CreateNode('stmt.var_decl', LNames[LI]);
          LVarNode.SetAttr('var.type_text', TValue.From<string>(LTypeText));
          if LArrayKind <> '' then
          begin
            LVarNode.SetAttr('var.array_kind',     TValue.From<string>(LArrayKind));
            LVarNode.SetAttr('var.elem_type_text', TValue.From<string>(LElemType));
            if LArrayKind = 'static' then
            begin
              LVarNode.SetAttr('var.array_low',  TValue.From<string>(LArrayLow));
              LVarNode.SetAttr('var.array_high', TValue.From<string>(LArrayHigh));
            end;
          end
          else if LSetKind <> '' then
          begin
            LVarNode.SetAttr('var.set_kind',       TValue.From<string>(LSetKind));
            LVarNode.SetAttr('var.elem_type_text', TValue.From<string>(LElemType));
          end
          else if LPointerKind <> '' then
          begin
            LVarNode.SetAttr('var.pointer_kind',   TValue.From<string>(LPointerKind));
            LVarNode.SetAttr('var.elem_type_text', TValue.From<string>(LElemType));
          end;
          LNode.AddChild(LVarNode);
        end;
      end;
      Result := LNode;
    end);
end;

// --- Procedure Declaration ---

procedure RegisterProcDecl(const AParse: TParse);
begin
  AParse.Config().RegisterStatement('keyword.procedure', 'stmt.proc_decl',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode:       TParseASTNode;
      LParamNode:  TParseASTNode;
      LNameTok:    TParseToken;
      LParamTok:   TParseToken;
      LModifier:   string;
      LFillIdx:    Integer;
      LParamNames: TStringList;
    begin
      LParamNames := TStringList.Create();
      try
      AParser.Consume();  // consume 'procedure'
      LNameTok := AParser.CurrentToken();
      LNode := AParser.CreateNode('stmt.proc_decl', LNameTok);
      LNode.SetAttr('decl.name', TValue.From<string>(LNameTok.Text));
      AParser.Consume();  // consume name
      // Parameter list
      if AParser.Match('delimiter.lparen') then
      begin
        while not AParser.Check('delimiter.rparen') do
        begin
          // Optional parameter modifier: var, const, out
          LModifier := '';
          if AParser.Match('keyword.var') then
            LModifier := 'var'
          else if AParser.Match('keyword.const') then
            LModifier := 'const'
          else if AParser.Match('keyword.out') then
            LModifier := 'out';
          // Collect comma-separated names: const A, B, C: Integer
          LParamNames.Clear();
          LParamNames.Add(AParser.CurrentToken().Text);
          AParser.Consume();  // consume first param name
          while AParser.Match('delimiter.comma') do
          begin
            LParamNames.Add(AParser.CurrentToken().Text);
            AParser.Consume();  // consume next param name
          end;
          AParser.Expect('delimiter.colon');
          // Emit one node per collected name, all sharing modifier and type
          for LFillIdx := 0 to LParamNames.Count - 1 do
          begin
            LParamNode := AParser.CreateNode('stmt.param_decl',
              AParser.CurrentToken());
            LParamNode.SetAttr('param.modifier', TValue.From<string>(LModifier));
            LParamNode.SetAttr('param.name', TValue.From<string>(LParamNames[LFillIdx]));
            LParamNode.SetAttr('param.type_text',
              TValue.From<string>(AParser.CurrentToken().Text));
            LNode.AddChild(LParamNode);
          end;
          AParser.Consume();  // consume type keyword
          if AParser.Check('delimiter.semicolon') then
            AParser.Consume()  // separator between params
          else
            Break;
        end;
        AParser.Expect('delimiter.rparen');
      end;
      AParser.Expect('delimiter.semicolon');
      // Parse trailing directives: overload
      if AParser.Match('keyword.overload') then
      begin
        LNode.SetAttr('decl.overload', TValue.From<Boolean>(True));
        AParser.Match('delimiter.semicolon');
      end;
      // Optional var/const/type declaration section before body
      while AParser.Check('keyword.var') or
            AParser.Check('keyword.const') or
            AParser.Check('keyword.type') do
        LNode.AddChild(TParseASTNode(AParser.ParseStatement()));
      // Body
      LNode.AddChild(TParseASTNode(AParser.ParseStatement()));
      AParser.Expect('delimiter.semicolon');  // ; after end
      Result := LNode;
      finally
        LParamNames.Free();
      end;
    end);
end;

// --- Function Declaration ---

procedure RegisterFuncDecl(const AParse: TParse);
begin
  AParse.Config().RegisterStatement('keyword.function', 'stmt.func_decl',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode:       TParseASTNode;
      LParamNode:  TParseASTNode;
      LNameTok:    TParseToken;
      LParamTok:   TParseToken;
      LModifier:   string;
      LFillIdx:    Integer;
      LParamNames: TStringList;
    begin
      LParamNames := TStringList.Create();
      try
      AParser.Consume();  // consume 'function'
      LNameTok := AParser.CurrentToken();
      LNode := AParser.CreateNode('stmt.func_decl', LNameTok);
      LNode.SetAttr('decl.name', TValue.From<string>(LNameTok.Text));
      AParser.Consume();  // consume name
      // Parameter list
      if AParser.Match('delimiter.lparen') then
      begin
        while not AParser.Check('delimiter.rparen') do
        begin
          // Optional parameter modifier: var, const, out
          LModifier := '';
          if AParser.Match('keyword.var') then
            LModifier := 'var'
          else if AParser.Match('keyword.const') then
            LModifier := 'const'
          else if AParser.Match('keyword.out') then
            LModifier := 'out';
          // Collect comma-separated names: const A, B, C: Integer
          LParamNames.Clear();
          LParamNames.Add(AParser.CurrentToken().Text);
          AParser.Consume();  // consume first param name
          while AParser.Match('delimiter.comma') do
          begin
            LParamNames.Add(AParser.CurrentToken().Text);
            AParser.Consume();  // consume next param name
          end;
          AParser.Expect('delimiter.colon');
          // Emit one node per collected name, all sharing modifier and type
          for LFillIdx := 0 to LParamNames.Count - 1 do
          begin
            LParamNode := AParser.CreateNode('stmt.param_decl',
              AParser.CurrentToken());
            LParamNode.SetAttr('param.modifier', TValue.From<string>(LModifier));
            LParamNode.SetAttr('param.name', TValue.From<string>(LParamNames[LFillIdx]));
            LParamNode.SetAttr('param.type_text',
              TValue.From<string>(AParser.CurrentToken().Text));
            LNode.AddChild(LParamNode);
          end;
          AParser.Consume();  // consume type keyword
          if AParser.Check('delimiter.semicolon') then
            AParser.Consume()  // separator between params
          else
            Break;
        end;
        AParser.Expect('delimiter.rparen');
      end;
      AParser.Expect('delimiter.colon');
      LNode.SetAttr('decl.return_type',
        TValue.From<string>(AParser.CurrentToken().Text));
      AParser.Consume();  // consume return type keyword
      AParser.Expect('delimiter.semicolon');
      // Parse trailing directives: overload
      if AParser.Match('keyword.overload') then
      begin
        LNode.SetAttr('decl.overload', TValue.From<Boolean>(True));
        AParser.Match('delimiter.semicolon');
      end;
      // Optional var/const/type declaration section before body
      while AParser.Check('keyword.var') or
            AParser.Check('keyword.const') or
            AParser.Check('keyword.type') do
        LNode.AddChild(TParseASTNode(AParser.ParseStatement()));
      // Body
      LNode.AddChild(TParseASTNode(AParser.ParseStatement()));
      AParser.Expect('delimiter.semicolon');  // ; after end
      Result := LNode;
      finally
        LParamNames.Free();
      end;
    end);
end;

// --- Begin..End Block ---

procedure RegisterBeginBlock(const AParse: TParse);
begin
  AParse.Config().RegisterStatement('keyword.begin', 'stmt.begin_block',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode:  TParseASTNode;
      LChild: TParseASTNodeBase;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();  // consume 'begin'
      while not AParser.Check('keyword.end') and
            not AParser.Check(PARSE_KIND_EOF) do
      begin
        LChild := AParser.ParseStatement();
        if LChild <> nil then
          LNode.AddChild(TParseASTNode(LChild));
      end;
      AParser.Expect('keyword.end');
      Result := LNode;
    end);
end;

// --- If/Then/Else ---

procedure RegisterIfStmt(const AParse: TParse);
begin
  AParse.Config().RegisterStatement('keyword.if', 'stmt.if',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();  // consume 'if'
      LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));
      AParser.Expect('keyword.then');
      LNode.AddChild(TParseASTNode(AParser.ParseStatement()));
      if AParser.Match('keyword.else') then
        LNode.AddChild(TParseASTNode(AParser.ParseStatement()));
      AParser.Match('delimiter.semicolon');
      Result := LNode;
    end);
end;

// --- While/Do ---

procedure RegisterWhileStmt(const AParse: TParse);
begin
  AParse.Config().RegisterStatement('keyword.while', 'stmt.while',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();  // consume 'while'
      LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));
      AParser.Expect('keyword.do');
      LNode.AddChild(TParseASTNode(AParser.ParseStatement()));
      AParser.Match('delimiter.semicolon');
      Result := LNode;
    end);
end;

// --- For/To/Downto/Do ---

procedure RegisterForStmt(const AParse: TParse);
begin
  AParse.Config().RegisterStatement('keyword.for', 'stmt.for',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();  // consume 'for'
      LNode.SetAttr('for.var',
        TValue.From<string>(AParser.CurrentToken().Text));
      AParser.Consume();  // consume loop variable
      AParser.Expect('op.assign');
      LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));  // start
      if AParser.Check('keyword.to') then
      begin
        LNode.SetAttr('for.dir', TValue.From<string>('to'));
        AParser.Consume();
      end
      else
      begin
        AParser.Expect('keyword.downto');
        LNode.SetAttr('for.dir', TValue.From<string>('downto'));
      end;
      LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));  // end
      AParser.Expect('keyword.do');
      LNode.AddChild(TParseASTNode(AParser.ParseStatement()));    // body
      AParser.Match('delimiter.semicolon');
      Result := LNode;
    end);
end;

// --- Writeln ---

procedure RegisterWriteln(const AParse: TParse);
begin
  AParse.Config().RegisterStatement('keyword.writeln', 'stmt.writeln',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();  // consume 'writeln'
      AParser.Expect('delimiter.lparen');
      LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));
      while AParser.Match('delimiter.comma') do
        LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));
      AParser.Expect('delimiter.rparen');
      AParser.Match('delimiter.semicolon');
      Result := LNode;
    end);
end;

// --- Write ---

procedure RegisterWrite(const AParse: TParse);
begin
  AParse.Config().RegisterStatement('keyword.write', 'stmt.write',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();  // consume 'write'
      AParser.Expect('delimiter.lparen');
      LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));
      while AParser.Match('delimiter.comma') do
        LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));
      AParser.Expect('delimiter.rparen');
      AParser.Match('delimiter.semicolon');
      Result := LNode;
    end);
end;

// --- Readln ---

procedure RegisterReadln(const AParse: TParse);
begin
  AParse.Config().RegisterStatement('keyword.readln', 'stmt.readln',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();  // consume 'readln'
      if AParser.Match('delimiter.lparen') then
      begin
        if not AParser.Check('delimiter.rparen') then
        begin
          LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));
          while AParser.Match('delimiter.comma') do
            LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));
        end;
        AParser.Expect('delimiter.rparen');
      end;
      AParser.Match('delimiter.semicolon');
      Result := LNode;
    end);
end;

// --- Read ---

procedure RegisterRead(const AParse: TParse);
begin
  AParse.Config().RegisterStatement('keyword.read', 'stmt.read',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();  // consume 'read'
      if AParser.Match('delimiter.lparen') then
      begin
        if not AParser.Check('delimiter.rparen') then
        begin
          LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));
          while AParser.Match('delimiter.comma') do
            LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));
        end;
        AParser.Expect('delimiter.rparen');
      end;
      AParser.Match('delimiter.semicolon');
      Result := LNode;
    end);
end;

// --- Repeat..Until ---

procedure RegisterRepeatStmt(const AParse: TParse);
begin
  AParse.Config().RegisterStatement('keyword.repeat', 'stmt.repeat',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode:  TParseASTNode;
      LChild: TParseASTNodeBase;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();  // consume 'repeat'
      // Parse statement sequence until 'until'
      while not AParser.Check('keyword.until') and
            not AParser.Check(PARSE_KIND_EOF) do
      begin
        LChild := AParser.ParseStatement();
        if LChild <> nil then
          LNode.AddChild(TParseASTNode(LChild));
      end;
      AParser.Expect('keyword.until');
      LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));  // condition
      AParser.Match('delimiter.semicolon');
      Result := LNode;
    end);
end;

// --- Exit ---

procedure RegisterExitStmt(const AParse: TParse);
begin
  AParse.Config().RegisterStatement('keyword.exit', 'stmt.exit',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();  // consume 'exit'
      // Optional: exit(value)
      if AParser.Match('delimiter.lparen') then
      begin
        LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));
        AParser.Expect('delimiter.rparen');
      end;
      AParser.Match('delimiter.semicolon');
      Result := LNode;
    end);
end;

// --- Break ---

procedure RegisterBreakStmt(const AParse: TParse);
begin
  AParse.Config().RegisterStatement('keyword.break', 'stmt.break',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();  // consume 'break'
      AParser.Match('delimiter.semicolon');
      Result := LNode;
    end);
end;

// --- Const Block ---

procedure RegisterConstBlock(const AParse: TParse);
begin
  AParse.Config().RegisterStatement('keyword.const', 'stmt.const_block',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode:      TParseASTNode;
      LConstNode: TParseASTNode;
      LNameTok:   TParseToken;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();  // consume 'const'
      while AParser.Check(PARSE_KIND_IDENTIFIER) do
      begin
        LNameTok := AParser.CurrentToken();
        AParser.Consume();  // consume name
        LConstNode := AParser.CreateNode('stmt.const_decl', LNameTok);
        if AParser.Match('delimiter.colon') then
        begin
          // Typed constant: name : type = value
          LConstNode.SetAttr('const.type_text',
            TValue.From<string>(AParser.CurrentToken().Text));
          AParser.Consume();  // consume type keyword
        end
        else
          LConstNode.SetAttr('const.type_text', TValue.From<string>(''));
        AParser.Expect('op.eq');
        LConstNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));
        AParser.Expect('delimiter.semicolon');
        LNode.AddChild(LConstNode);
      end;
      Result := LNode;
    end);
end;

// --- Case..Of ---

procedure RegisterCaseStmt(const AParse: TParse);
begin
  AParse.Config().RegisterStatement('keyword.case', 'stmt.case',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode:       TParseASTNode;
      LArmNode:    TParseASTNode;
      LElseNode:   TParseASTNode;
      LLabelCount: Integer;
      LChild:      TParseASTNodeBase;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();  // consume 'case'
      // Selector expression
      LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));
      AParser.Expect('keyword.of');
      // Parse case arms until 'else' or 'end'
      while not AParser.Check('keyword.else') and
            not AParser.Check('keyword.end') and
            not AParser.Check(PARSE_KIND_EOF) do
      begin
        LArmNode := AParser.CreateNode('stmt.case_arm', AParser.CurrentToken());
        LLabelCount := 0;
        // Parse label list: expr { "," expr } ":"
        LArmNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));
        Inc(LLabelCount);
        while AParser.Match('delimiter.comma') do
        begin
          LArmNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));
          Inc(LLabelCount);
        end;
        AParser.Expect('delimiter.colon');
        LArmNode.SetAttr('case.label_count', TValue.From<Integer>(LLabelCount));
        // Single body statement -- use begin..end for multiple statements
        LChild := AParser.ParseStatement();
        if LChild <> nil then
          LArmNode.AddChild(TParseASTNode(LChild));
        // Consume the trailing semicolon that may follow end; in a begin..end arm
        AParser.Match('delimiter.semicolon');
        LNode.AddChild(LArmNode);
      end;
      // Optional else branch
      if AParser.Match('keyword.else') then
      begin
        LElseNode := AParser.CreateNode('stmt.case_else', AParser.CurrentToken());
        while not AParser.Check('keyword.end') and
              not AParser.Check(PARSE_KIND_EOF) do
        begin
          LChild := AParser.ParseStatement();
          if LChild <> nil then
            LElseNode.AddChild(TParseASTNode(LChild));
          // Consume trailing semicolon after end; in a begin..end else body
          AParser.Match('delimiter.semicolon');
        end;
        LNode.AddChild(LElseNode);
      end;
      AParser.Expect('keyword.end');
      AParser.Match('delimiter.semicolon');
      Result := LNode;
    end);
end;

// --- Continue ---

procedure RegisterContinueStmt(const AParse: TParse);
begin
  AParse.Config().RegisterStatement('keyword.continue', 'stmt.continue',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();  // consume 'continue'
      AParser.Match('delimiter.semicolon');
      Result := LNode;
    end);
end;

// --- Type Block ---

procedure RegisterTypeBlock(const AParse: TParse);
begin
  AParse.Config().RegisterStatement('keyword.type', 'stmt.type_block',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode:         TParseASTNode;
      LDeclNode:     TParseASTNode;
      LFieldNode:    TParseASTNode;
      LNameTok:      TParseToken;
      LFieldTypeTok: TParseToken;
      LFieldNames:   array[0..31] of TParseToken;
      LFieldCount:   Integer;
      LFI:           Integer;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();  // consume 'type'
      while AParser.Check(PARSE_KIND_IDENTIFIER) do
      begin
        LNameTok := AParser.CurrentToken();
        AParser.Consume();   // consume type name
        AParser.Expect('op.eq');
        LDeclNode := AParser.CreateNode('stmt.type_decl', LNameTok);
        LDeclNode.SetAttr('decl.name', TValue.From<string>(LNameTok.Text));
        if AParser.Check('keyword.record') then
        begin
          AParser.Consume();  // consume 'record'
          LDeclNode.SetAttr('type.kind', TValue.From<string>('record'));
          // Parse field declarations until 'end'
          while not AParser.Check('keyword.end') and
                not AParser.Check(PARSE_KIND_EOF) do
          begin
            // Collect comma-separated field names before the colon
            LFieldCount    := 0;
            LFieldNames[0] := AParser.CurrentToken();
            Inc(LFieldCount);
            AParser.Consume();  // consume first field name
            while AParser.Match('delimiter.comma') do
            begin
              LFieldNames[LFieldCount] := AParser.CurrentToken();
              Inc(LFieldCount);
              AParser.Consume();  // consume additional field name
            end;
            AParser.Expect('delimiter.colon');
            LFieldTypeTok := AParser.CurrentToken();
            AParser.Consume();  // consume type keyword
            AParser.Expect('delimiter.semicolon');
            // One stmt.field_decl node per collected name
            for LFI := 0 to LFieldCount - 1 do
            begin
              LFieldNode := AParser.CreateNode('stmt.field_decl',
                LFieldNames[LFI]);
              LFieldNode.SetAttr('field.type_text',
                TValue.From<string>(LFieldTypeTok.Text));
              LDeclNode.AddChild(LFieldNode);
            end;
          end;
          AParser.Expect('keyword.end');
        end
        else if AParser.Check('keyword.array') then
        begin
          AParser.Consume();  // consume 'array'
          if AParser.Match('delimiter.lbracket') then
          begin
            // Static array type alias: type TArr = array[1..10] of Integer
            LDeclNode.SetAttr('type.kind', TValue.From<string>('array.static'));
            LDeclNode.SetAttr('type.array_low',
              TValue.From<string>(AParser.CurrentToken().Text));
            AParser.Consume();   // consume low bound
            AParser.Expect('op.range');
            LDeclNode.SetAttr('type.array_high',
              TValue.From<string>(AParser.CurrentToken().Text));
            AParser.Consume();   // consume high bound
            AParser.Expect('delimiter.rbracket');
          end
          else
            LDeclNode.SetAttr('type.kind', TValue.From<string>('array.dynamic'));
          AParser.Expect('keyword.of');
          LDeclNode.SetAttr('type.elem_type_text',
            TValue.From<string>(AParser.CurrentToken().Text));
          AParser.Consume();   // consume element type keyword
        end
        else if AParser.Check('keyword.set') then
        begin
          AParser.Consume();   // consume 'set'
          AParser.Expect('keyword.of');
          LDeclNode.SetAttr('type.kind',
            TValue.From<string>('set'));
          LDeclNode.SetAttr('type.elem_type_text',
            TValue.From<string>(AParser.CurrentToken().Text));
          AParser.Consume();   // consume element type keyword
        end
        else if AParser.Check('op.deref') then
        begin
          // Pointer type alias: type PMyInt = ^Integer;
          AParser.Consume();   // consume '^'
          LDeclNode.SetAttr('type.kind', TValue.From<string>('pointer'));
          LDeclNode.SetAttr('type.elem_type_text',
            TValue.From<string>(AParser.CurrentToken().Text));
          AParser.Consume();   // consume pointee type
        end
        else
        begin
          // Simple type alias: type TMyInt = Integer;
          LDeclNode.SetAttr('type.kind', TValue.From<string>('alias'));
          LDeclNode.SetAttr('type.alias_text',
            TValue.From<string>(AParser.CurrentToken().Text));
          AParser.Consume();  // consume aliased type name
        end;
        AParser.Expect('delimiter.semicolon');
        LNode.AddChild(LDeclNode);
      end;
      Result := LNode;
    end);
end;

// --- SetLength ---

procedure RegisterSetLength(const AParse: TParse);
begin
  AParse.Config().RegisterStatement('keyword.setlength', 'stmt.setlength',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();   // consume 'SetLength'
      AParser.Expect('delimiter.lparen');
      LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));  // array var
      AParser.Expect('delimiter.comma');
      LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));  // new length
      AParser.Expect('delimiter.rparen');
      AParser.Match('delimiter.semicolon');
      Result := LNode;
    end);
end;

// --- Include ---

procedure RegisterIncludeStmt(const AParse: TParse);
begin
  AParse.Config().RegisterStatement('keyword.include', 'stmt.include',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();   // consume 'Include'
      AParser.Expect('delimiter.lparen');
      LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));  // set var
      AParser.Expect('delimiter.comma');
      LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));  // element
      AParser.Expect('delimiter.rparen');
      AParser.Match('delimiter.semicolon');
      Result := LNode;
    end);
end;

// --- Exclude ---

procedure RegisterExcludeStmt(const AParse: TParse);
begin
  AParse.Config().RegisterStatement('keyword.exclude', 'stmt.exclude',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();   // consume 'Exclude'
      AParser.Expect('delimiter.lparen');
      LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));  // set var
      AParser.Expect('delimiter.comma');
      LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));  // element
      AParser.Expect('delimiter.rparen');
      AParser.Match('delimiter.semicolon');
      Result := LNode;
    end);
end;

// --- Intrinsic Function Calls ---
// Each intrinsic keyword is registered as a prefix that produces an expr.call
// node with call.name set to the fully-qualified np:: C++ name. The codegen
// emitter emits it verbatim -- no further name mapping is required.

procedure RegisterOneIntrinsic(const AParse: TParse;
  const AKeyword: string; const ACppName: string);
begin
  AParse.Config().RegisterPrefix(AKeyword, 'expr.call',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode('expr.call', AParser.CurrentToken());
      // Store the fully-qualified C++ name so codegen emits it verbatim.
      LNode.SetAttr('call.name', TValue.From<string>(ACppName));
      AParser.Consume();  // consume the keyword
      AParser.Expect('delimiter.lparen');
      if not AParser.Check('delimiter.rparen') then
      begin
        LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));
        while AParser.Match('delimiter.comma') do
          LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));
      end;
      AParser.Expect('delimiter.rparen');
      Result := LNode;
    end);
end;

procedure RegisterIntrinsicCalls(const AParse: TParse);
begin
  // Ordinal
  RegisterOneIntrinsic(AParse, 'keyword.inc',          'np::Inc');
  RegisterOneIntrinsic(AParse, 'keyword.dec',          'np::Dec');
  RegisterOneIntrinsic(AParse, 'keyword.ord',          'np::Ord');
  RegisterOneIntrinsic(AParse, 'keyword.chr',          'np::Chr');
  RegisterOneIntrinsic(AParse, 'keyword.succ',         'np::Succ');
  RegisterOneIntrinsic(AParse, 'keyword.pred',         'np::Pred');
  RegisterOneIntrinsic(AParse, 'keyword.odd',          'np::Odd');
  RegisterOneIntrinsic(AParse, 'keyword.assigned',     'np::Assigned');
  // String
  RegisterOneIntrinsic(AParse, 'keyword.length',       'np::Length');
  RegisterOneIntrinsic(AParse, 'keyword.copy',         'np::Copy');
  RegisterOneIntrinsic(AParse, 'keyword.pos',          'np::Pos');
  RegisterOneIntrinsic(AParse, 'keyword.inttostr',     'np::IntToStr');
  RegisterOneIntrinsic(AParse, 'keyword.strtoint',     'np::StrToInt');
  RegisterOneIntrinsic(AParse, 'keyword.strtointdef',  'np::StrToIntDef');
  RegisterOneIntrinsic(AParse, 'keyword.floattostr',   'np::FloatToStr');
  RegisterOneIntrinsic(AParse, 'keyword.strtofloat',   'np::StrToFloat');
  RegisterOneIntrinsic(AParse, 'keyword.uppercase',    'np::UpperCase');
  RegisterOneIntrinsic(AParse, 'keyword.lowercase',    'np::LowerCase');
  RegisterOneIntrinsic(AParse, 'keyword.trim',         'np::Trim');
  RegisterOneIntrinsic(AParse, 'keyword.trimleft',     'np::TrimLeft');
  RegisterOneIntrinsic(AParse, 'keyword.trimright',    'np::TrimRight');
  RegisterOneIntrinsic(AParse, 'keyword.delete',       'np::Delete');
  RegisterOneIntrinsic(AParse, 'keyword.insert',       'np::Insert');
  RegisterOneIntrinsic(AParse, 'keyword.stringofchar', 'np::StringOfChar');
  RegisterOneIntrinsic(AParse, 'keyword.upcase',       'np::UpCase');
  RegisterOneIntrinsic(AParse, 'keyword.booltostr',    'np::BoolToStr');
  // Math
  RegisterOneIntrinsic(AParse, 'keyword.abs',          'np::Abs');
  RegisterOneIntrinsic(AParse, 'keyword.sqr',          'np::Sqr');
  RegisterOneIntrinsic(AParse, 'keyword.sqrt',         'np::Sqrt');
  RegisterOneIntrinsic(AParse, 'keyword.sin',          'np::Sin');
  RegisterOneIntrinsic(AParse, 'keyword.cos',          'np::Cos');
  RegisterOneIntrinsic(AParse, 'keyword.tan',          'np::Tan');
  RegisterOneIntrinsic(AParse, 'keyword.arctan',       'np::ArcTan');
  RegisterOneIntrinsic(AParse, 'keyword.ln',           'np::Ln');
  RegisterOneIntrinsic(AParse, 'keyword.exp',          'np::Exp');
  RegisterOneIntrinsic(AParse, 'keyword.power',        'np::Power');
  RegisterOneIntrinsic(AParse, 'keyword.round',        'np::Round');
  RegisterOneIntrinsic(AParse, 'keyword.trunc',        'np::Trunc');
  RegisterOneIntrinsic(AParse, 'keyword.ceil',         'np::Ceil');
  RegisterOneIntrinsic(AParse, 'keyword.floor',        'np::Floor');
  RegisterOneIntrinsic(AParse, 'keyword.max',          'np::Max');
  RegisterOneIntrinsic(AParse, 'keyword.min',          'np::Min');
  RegisterOneIntrinsic(AParse, 'keyword.random',       'np::Random');
  RegisterOneIntrinsic(AParse, 'keyword.randomize',    'np::Randomize');
  RegisterOneIntrinsic(AParse, 'keyword.int',          'np::Int');
  RegisterOneIntrinsic(AParse, 'keyword.frac',         'np::Frac');
  // Memory
  RegisterOneIntrinsic(AParse, 'keyword.new',          'np::New');
  RegisterOneIntrinsic(AParse, 'keyword.dispose',      'np::Dispose');
  RegisterOneIntrinsic(AParse, 'keyword.getmem',       'np::GetMem');
  RegisterOneIntrinsic(AParse, 'keyword.freemem',      'np::FreeMem');
  RegisterOneIntrinsic(AParse, 'keyword.fillchar',     'np::FillChar');
  RegisterOneIntrinsic(AParse, 'keyword.move',         'np::Move');
  // System
  RegisterOneIntrinsic(AParse, 'keyword.sizeof',       'sizeof');
  RegisterOneIntrinsic(AParse, 'keyword.halt',         'std::exit');
  // Additional string/conversion intrinsics
  RegisterOneIntrinsic(AParse, 'keyword.stringreplace', 'np::StringReplace');
  RegisterOneIntrinsic(AParse, 'keyword.format',        'np::Format');
  RegisterOneIntrinsic(AParse, 'keyword.comparestr',    'np::CompareStr');
  RegisterOneIntrinsic(AParse, 'keyword.sametext',      'np::SameText');
  RegisterOneIntrinsic(AParse, 'keyword.quotedstr',     'np::QuotedStr');
  RegisterOneIntrinsic(AParse, 'keyword.low',           'np::Low');
  RegisterOneIntrinsic(AParse, 'keyword.high',          'np::High');
  RegisterOneIntrinsic(AParse, 'keyword.reallocmem',    'np::ReallocMem');
  RegisterOneIntrinsic(AParse, 'keyword.abort',         'np::Abort');
  RegisterOneIntrinsic(AParse, 'keyword.paramcount',    'np::ParamCount');
  RegisterOneIntrinsic(AParse, 'keyword.paramstr',      'np::ParamStr');
  // Exception intrinsics (expression form)
  RegisterOneIntrinsic(AParse, 'keyword.getexceptioncode',    'np::GetExceptionCode');
  RegisterOneIntrinsic(AParse, 'keyword.getexceptionmessage', 'np::GetExceptionMessage');
  // File I/O
  RegisterOneIntrinsic(AParse, 'keyword.assign',          'np::Assign');
  RegisterOneIntrinsic(AParse, 'keyword.reset',           'np::Reset');
  RegisterOneIntrinsic(AParse, 'keyword.rewrite',         'np::Rewrite');
  RegisterOneIntrinsic(AParse, 'keyword.append',          'np::Append');
  RegisterOneIntrinsic(AParse, 'keyword.close',           'np::Close');
  RegisterOneIntrinsic(AParse, 'keyword.eof',             'np::Eof');
  RegisterOneIntrinsic(AParse, 'keyword.filesize',        'np::FileSize');
  RegisterOneIntrinsic(AParse, 'keyword.filepos',         'np::FilePos');
  RegisterOneIntrinsic(AParse, 'keyword.seek',            'np::Seek');
  RegisterOneIntrinsic(AParse, 'keyword.fileexists',      'np::FileExists');
  RegisterOneIntrinsic(AParse, 'keyword.directoryexists', 'np::DirectoryExists');
  RegisterOneIntrinsic(AParse, 'keyword.deletefile',      'np::DeleteFile');
  RegisterOneIntrinsic(AParse, 'keyword.renamefile',      'np::RenameFile');
  RegisterOneIntrinsic(AParse, 'keyword.getcurrentdir',   'np::GetCurrentDir');
  RegisterOneIntrinsic(AParse, 'keyword.createdir',       'np::CreateDir');
end;

// --- Try..Except..Finally ---
// BNF: TryStmt = "try" StatementSeq
//               ( "except" StatementSeq [ "finally" StatementSeq ]
//               | "finally" StatementSeq ) "end" [";"] .
// AST: stmt.try_stmt
//        stmt.try_body    -- always present
//        stmt.except_body -- present when except clause exists
//        stmt.finally_body -- present when finally clause exists

procedure RegisterTryStmt(const AParse: TParse);
begin
  AParse.Config().RegisterStatement('keyword.try', 'stmt.try_stmt',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode:        TParseASTNode;
      LTryBody:     TParseASTNode;
      LExceptBody:  TParseASTNode;
      LFinallyBody: TParseASTNode;
      LChild:       TParseASTNodeBase;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();  // consume 'try'
      // --- try body: parse statements until except/finally/end ---
      LTryBody := AParser.CreateNode('stmt.try_body', AParser.CurrentToken());
      while not AParser.Check('keyword.except') and
            not AParser.Check('keyword.finally') and
            not AParser.Check('keyword.end') and
            not AParser.Check(PARSE_KIND_EOF) do
      begin
        LChild := AParser.ParseStatement();
        if LChild <> nil then
          LTryBody.AddChild(TParseASTNode(LChild));
      end;
      LNode.AddChild(LTryBody);
      // --- except block (optional) ---
      if AParser.Match('keyword.except') then
      begin
        LExceptBody := AParser.CreateNode('stmt.except_body',
          AParser.CurrentToken());
        while not AParser.Check('keyword.finally') and
              not AParser.Check('keyword.end') and
              not AParser.Check(PARSE_KIND_EOF) do
        begin
          LChild := AParser.ParseStatement();
          if LChild <> nil then
            LExceptBody.AddChild(TParseASTNode(LChild));
        end;
        LNode.AddChild(LExceptBody);
      end;
      // --- finally block (optional) ---
      if AParser.Match('keyword.finally') then
      begin
        LFinallyBody := AParser.CreateNode('stmt.finally_body',
          AParser.CurrentToken());
        while not AParser.Check('keyword.end') and
              not AParser.Check(PARSE_KIND_EOF) do
        begin
          LChild := AParser.ParseStatement();
          if LChild <> nil then
            LFinallyBody.AddChild(TParseASTNode(LChild));
        end;
        LNode.AddChild(LFinallyBody);
      end;
      AParser.Expect('keyword.end');
      AParser.Match('delimiter.semicolon');
      Result := LNode;
    end);
end;

// --- RaiseException / RaiseExceptionCode ---
// BNF: RaiseStmt = ( "raiseexception" "(" Expression ")"
//                  | "raiseexceptioncode" "(" Expression "," Expression ")" ) [";"] .

procedure RegisterRaiseStmt(const AParse: TParse);
begin
  // raiseexception(message)
  AParse.Config().RegisterStatement('keyword.raiseexception', 'stmt.raise',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();  // consume 'raiseexception'
      AParser.Expect('delimiter.lparen');
      LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));  // message
      AParser.Expect('delimiter.rparen');
      AParser.Match('delimiter.semicolon');
      Result := LNode;
    end);

  // raiseexceptioncode(code, message)
  AParse.Config().RegisterStatement('keyword.raiseexceptioncode', 'stmt.raise_code',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();  // consume 'raiseexceptioncode'
      AParser.Expect('delimiter.lparen');
      LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));  // code
      AParser.Expect('delimiter.comma');
      LNode.AddChild(TParseASTNode(AParser.ParseExpression(0)));  // message
      AParser.Expect('delimiter.rparen');
      AParser.Match('delimiter.semicolon');
      Result := LNode;
    end);
end;


// --- Unit Declaration ---
// BNF: UnitDecl = "unit" Identifier ";"
//                 [ "uses" UnitList ";" ]
//                 "interface"
//                   { VarBlock | ConstBlock | TypeBlock | ProcForward | FuncForward }
//                 "implementation"
//                   { VarBlock | ConstBlock | TypeBlock | ProcDecl | FuncDecl }
//                 "end" "." .
// AST: stmt.pascal_unit
//        [stmt.uses_clause [stmt.uses_item ...]]
//        stmt.unit_interface  { decl nodes }
//        stmt.unit_implementation { decl nodes }

procedure RegisterUnitStmt(const AParse: TParse);
begin
  AParse.Config().RegisterStatement('keyword.unit', 'stmt.pascal_unit',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode:       TParseASTNode;
      LUsesNode:   TParseASTNode;
      LItemNode:   TParseASTNode;
      LIntfNode:   TParseASTNode;
      LImplNode:   TParseASTNode;
      LFwdNode:    TParseASTNode;
      LParamNode:  TParseASTNode;
      LNameTok:    TParseToken;
      LParamTok:   TParseToken;
      LModifier:   string;
      LFillIdx:    Integer;
      LParamNames: TStringList;
    begin
      LParamNames := TStringList.Create();
      try
      LNode := AParser.CreateNode();
      AParser.Consume();  // consume 'unit'
      LNode.SetAttr('decl.name',
        TValue.From<string>(AParser.CurrentToken().Text));
      AParser.Consume();  // consume unit name
      AParser.Expect('delimiter.semicolon');
      // Optional uses clause
      if AParser.Match('keyword.uses') then
      begin
        LUsesNode := AParser.CreateNode('stmt.uses_clause', AParser.CurrentToken());
        repeat
          LItemNode := AParser.CreateNode('stmt.uses_item', AParser.CurrentToken());
          LItemNode.SetAttr('decl.name',
            TValue.From<string>(AParser.CurrentToken().Text));
          AParser.Consume();  // consume unit name
          LUsesNode.AddChild(LItemNode);
        until not AParser.Match('delimiter.comma');
        AParser.Expect('delimiter.semicolon');
        LNode.AddChild(LUsesNode);
      end;
      // Interface section -- forward declarations only (no bodies)
      AParser.Expect('keyword.interface');
      LIntfNode := AParser.CreateNode('stmt.unit_interface', AParser.CurrentToken());
      while AParser.Check('keyword.var') or
            AParser.Check('keyword.const') or
            AParser.Check('keyword.type') or
            AParser.Check('keyword.procedure') or
            AParser.Check('keyword.function') do
      begin
        if AParser.Check('keyword.var') or
           AParser.Check('keyword.const') or
           AParser.Check('keyword.type') then
          LIntfNode.AddChild(TParseASTNode(AParser.ParseStatement()))
        else if AParser.Check('keyword.procedure') then
        begin
          // Forward procedure: "procedure Name[(params)];"  -- no body
          AParser.Consume();  // consume 'procedure'
          LNameTok := AParser.CurrentToken();
          LFwdNode := AParser.CreateNode('stmt.proc_forward', LNameTok);
          LFwdNode.SetAttr('decl.name', TValue.From<string>(LNameTok.Text));
          AParser.Consume();  // consume name
          if AParser.Match('delimiter.lparen') then
          begin
            while not AParser.Check('delimiter.rparen') do
            begin
              LModifier := '';
              if AParser.Match('keyword.var') then LModifier := 'var'
              else if AParser.Match('keyword.const') then LModifier := 'const'
              else if AParser.Match('keyword.out') then LModifier := 'out';
              // Collect comma-separated names: const A, B: Integer
              LParamNames.Clear();
              LParamNames.Add(AParser.CurrentToken().Text);
              AParser.Consume();  // consume first param name
              while AParser.Match('delimiter.comma') do
              begin
                LParamNames.Add(AParser.CurrentToken().Text);
                AParser.Consume();  // consume next param name
              end;
              AParser.Expect('delimiter.colon');
              // Emit one node per collected name, all sharing modifier and type
              for LFillIdx := 0 to LParamNames.Count - 1 do
              begin
                LParamNode := AParser.CreateNode('stmt.param_decl',
                  AParser.CurrentToken());
                LParamNode.SetAttr('param.modifier', TValue.From<string>(LModifier));
                LParamNode.SetAttr('param.name', TValue.From<string>(LParamNames[LFillIdx]));
                LParamNode.SetAttr('param.type_text',
                  TValue.From<string>(AParser.CurrentToken().Text));
                LFwdNode.AddChild(LParamNode);
              end;
              AParser.Consume();  // consume type
              if AParser.Check('delimiter.semicolon') then
                AParser.Consume()  // separator between params
              else
                Break;
            end;
            AParser.Expect('delimiter.rparen');
          end;
          AParser.Expect('delimiter.semicolon');
          // Parse trailing directives: overload
          if AParser.Match('keyword.overload') then
          begin
            LFwdNode.SetAttr('decl.overload', TValue.From<Boolean>(True));
            AParser.Match('delimiter.semicolon');
          end;
          LIntfNode.AddChild(LFwdNode);
        end
        else  // keyword.function forward
        begin
          // Forward function: "function Name[(params)]: ReturnType;"  -- no body
          AParser.Consume();  // consume 'function'
          LNameTok := AParser.CurrentToken();
          LFwdNode := AParser.CreateNode('stmt.func_forward', LNameTok);
          LFwdNode.SetAttr('decl.name', TValue.From<string>(LNameTok.Text));
          AParser.Consume();  // consume name
          if AParser.Match('delimiter.lparen') then
          begin
            while not AParser.Check('delimiter.rparen') do
            begin
              LModifier := '';
              if AParser.Match('keyword.var') then LModifier := 'var'
              else if AParser.Match('keyword.const') then LModifier := 'const'
              else if AParser.Match('keyword.out') then LModifier := 'out';
              // Collect comma-separated names: const A, B: Integer
              LParamNames.Clear();
              LParamNames.Add(AParser.CurrentToken().Text);
              AParser.Consume();  // consume first param name
              while AParser.Match('delimiter.comma') do
              begin
                LParamNames.Add(AParser.CurrentToken().Text);
                AParser.Consume();  // consume next param name
              end;
              AParser.Expect('delimiter.colon');
              // Emit one node per collected name, all sharing modifier and type
              for LFillIdx := 0 to LParamNames.Count - 1 do
              begin
                LParamNode := AParser.CreateNode('stmt.param_decl',
                  AParser.CurrentToken());
                LParamNode.SetAttr('param.modifier', TValue.From<string>(LModifier));
                LParamNode.SetAttr('param.name', TValue.From<string>(LParamNames[LFillIdx]));
                LParamNode.SetAttr('param.type_text',
                  TValue.From<string>(AParser.CurrentToken().Text));
                LFwdNode.AddChild(LParamNode);
              end;
              AParser.Consume();  // consume type
              if AParser.Check('delimiter.semicolon') then
                AParser.Consume()  // separator between params
              else
                Break;
            end;
            AParser.Expect('delimiter.rparen');
          end;
          AParser.Expect('delimiter.colon');
          LFwdNode.SetAttr('decl.return_type',
            TValue.From<string>(AParser.CurrentToken().Text));
          AParser.Consume();  // consume return type
          AParser.Expect('delimiter.semicolon');
          // Parse trailing directives: overload
          if AParser.Match('keyword.overload') then
          begin
            LFwdNode.SetAttr('decl.overload', TValue.From<Boolean>(True));
            AParser.Match('delimiter.semicolon');
          end;
          LIntfNode.AddChild(LFwdNode);
        end;
      end;
      LNode.AddChild(LIntfNode);
      // Implementation section -- full proc/func bodies
      AParser.Expect('keyword.implementation');
      LImplNode := AParser.CreateNode('stmt.unit_implementation', AParser.CurrentToken());
      while AParser.Check('keyword.var') or
            AParser.Check('keyword.const') or
            AParser.Check('keyword.type') or
            AParser.Check('keyword.procedure') or
            AParser.Check('keyword.function') do
        LImplNode.AddChild(TParseASTNode(AParser.ParseStatement()));
      LNode.AddChild(LImplNode);
      AParser.Expect('keyword.end');
      AParser.Expect('delimiter.dot');
      Result := LNode;
      finally
        LParamNames.Free();
      end;
    end);
end;

// --- Library Declaration ---
// BNF: LibraryDecl = "library" Identifier ";"
//                    [ "uses" UnitList ";" ]
//                    { VarBlock | ConstBlock | TypeBlock }
//                    { ProcDecl | FuncDecl }
//                    [ "exports" ExportList ";" ]
//                    [ BeginBlock ]
//                    "end" "." .
// AST: stmt.pascal_library
//        [stmt.uses_clause [stmt.uses_item ...]]
//        { decl nodes }
//        [stmt.exports_clause [stmt.exports_item ...]]
//        [stmt.begin_block]

procedure RegisterLibraryStmt(const AParse: TParse);
begin
  AParse.Config().RegisterStatement('keyword.library', 'stmt.pascal_library',
    function(AParser: TParseParserBase): TParseASTNodeBase
    var
      LNode:     TParseASTNode;
      LUsesNode: TParseASTNode;
      LExpNode:  TParseASTNode;
      LItemNode: TParseASTNode;
    begin
      LNode := AParser.CreateNode();
      AParser.Consume();  // consume 'library'
      LNode.SetAttr('decl.name',
        TValue.From<string>(AParser.CurrentToken().Text));
      AParser.Consume();  // consume library name
      AParser.Expect('delimiter.semicolon');
      // Optional uses clause
      if AParser.Match('keyword.uses') then
      begin
        LUsesNode := AParser.CreateNode('stmt.uses_clause', AParser.CurrentToken());
        repeat
          LItemNode := AParser.CreateNode('stmt.uses_item', AParser.CurrentToken());
          LItemNode.SetAttr('decl.name',
            TValue.From<string>(AParser.CurrentToken().Text));
          AParser.Consume();  // consume unit name
          LUsesNode.AddChild(LItemNode);
        until not AParser.Match('delimiter.comma');
        AParser.Expect('delimiter.semicolon');
        LNode.AddChild(LUsesNode);
      end;
      // Optional var/const/type blocks
      while AParser.Check('keyword.var') or
            AParser.Check('keyword.const') or
            AParser.Check('keyword.type') do
        LNode.AddChild(TParseASTNode(AParser.ParseStatement()));
      // Zero or more procedure/function declarations
      while AParser.Check('keyword.procedure') or
            AParser.Check('keyword.function') do
        LNode.AddChild(TParseASTNode(AParser.ParseStatement()));
      // Optional exports clause
      if AParser.Match('keyword.exports') then
      begin
        LExpNode := AParser.CreateNode('stmt.exports_clause', AParser.CurrentToken());
        repeat
          LItemNode := AParser.CreateNode('stmt.exports_item', AParser.CurrentToken());
          LItemNode.SetAttr('decl.name',
            TValue.From<string>(AParser.CurrentToken().Text));
          AParser.Consume();  // consume export name
          LExpNode.AddChild(LItemNode);
        until not AParser.Match('delimiter.comma');
        AParser.Expect('delimiter.semicolon');
        LNode.AddChild(LExpNode);
      end;
      // Optional begin..end block
      if AParser.Check('keyword.begin') then
        LNode.AddChild(TParseASTNode(AParser.ParseStatement()));
      AParser.Expect('keyword.end');
      AParser.Expect('delimiter.dot');
      Result := LNode;
    end);
end;

// === Public Entry Point ===

procedure ConfigGrammar(const AParse: TParse);
begin
  // Prefix handlers
  RegisterLiteralPrefixes(AParse);
  RegisterNilLiteral(AParse);
  RegisterBooleanLiterals(AParse);
  RegisterUnaryNot(AParse);
  RegisterGroupedExpr(AParse);
  RegisterAddrOf(AParse);
  RegisterCharLiteral(AParse);
  RegisterHexLiteral(AParse);
  RegisterSetLiteral(AParse);

  // Infix handlers
  RegisterAssignment(AParse);
  RegisterArithmeticOps(AParse);
  RegisterComparisonOps(AParse);
  RegisterLogicalOps(AParse);
  RegisterBitwiseShiftOps(AParse);
  RegisterCallExpr(AParse);
  RegisterArrayIndex(AParse);
  RegisterFieldAccess(AParse);
  RegisterPointerDeref(AParse);
  RegisterInOperator(AParse);

  // Statement handlers
  RegisterProgramStmt(AParse);
  RegisterUnitStmt(AParse);
  RegisterLibraryStmt(AParse);
  RegisterVarBlock(AParse);
  RegisterConstBlock(AParse);
  RegisterProcDecl(AParse);
  RegisterFuncDecl(AParse);
  RegisterBeginBlock(AParse);
  RegisterIfStmt(AParse);
  RegisterWhileStmt(AParse);
  RegisterForStmt(AParse);
  RegisterWriteln(AParse);
  RegisterWrite(AParse);
  RegisterRepeatStmt(AParse);
  RegisterReadln(AParse);
  RegisterRead(AParse);
  RegisterExitStmt(AParse);
  RegisterBreakStmt(AParse);
  RegisterContinueStmt(AParse);
  RegisterCaseStmt(AParse);
  RegisterTypeBlock(AParse);
  RegisterSetLength(AParse);
  RegisterIncludeStmt(AParse);
  RegisterExcludeStmt(AParse);
  RegisterIntrinsicCalls(AParse);
  RegisterTryStmt(AParse);
  RegisterRaiseStmt(AParse);
end;

end.
