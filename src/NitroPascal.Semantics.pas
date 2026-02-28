{===============================================================================
  NitroPascal™ - Modern Pascal * C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit NitroPascal.Semantics;

{$I NitroPascal.Defines.inc}

interface

uses
  Parse;

procedure ConfigSemantics(const AParse: TParse);

implementation

uses
  System.Rtti,
  Parse.Utils;

// =========================================================================
// SCOPE & STRUCTURE
// =========================================================================

// --- Program Root ---

procedure RegisterProgramRoot(const AParse: TParse);
begin
  AParse.Config().RegisterSemanticRule('program.root',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.PushScope('global', ANode.GetToken());
      ASem.VisitChildren(ANode);
      ASem.PopScope(ANode.GetToken());
    end);
end;

// --- Pascal Program ---

procedure RegisterPascalProgram(const AParse: TParse);
begin
  AParse.Config().RegisterSemanticRule('stmt.pascal_program',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);
end;

// --- Begin Block ---

procedure RegisterBeginBlock(const AParse: TParse);
begin
  AParse.Config().RegisterSemanticRule('stmt.begin_block',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);
end;

// =========================================================================
// DECLARATIONS
// =========================================================================

// --- Var Block ---

procedure RegisterVarBlock(const AParse: TParse);
begin
  AParse.Config().RegisterSemanticRule('stmt.var_block',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);
end;

// --- Const Block ---

procedure RegisterConstBlock(const AParse: TParse);
begin
  AParse.Config().RegisterSemanticRule('stmt.const_block',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  AParse.Config().RegisterSemanticRule('stmt.const_decl',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    var
      LTypeAttr: TValue;
      LTypeText: string;
      LTypeKind: string;
      LConstName: string;
      LStorage:   string;
    begin
      ANode.GetAttr('const.type_text', LTypeAttr);
      LTypeText := LTypeAttr.AsString;
      if LTypeText <> '' then
        LTypeKind := AParse.Config().TypeTextToKind(LTypeText)
      else
        LTypeKind := '';
      TParseASTNode(ANode).SetAttr(PARSE_ATTR_TYPE_KIND,
        TValue.From<string>(LTypeKind));
      // Storage class: global unless inside a routine scope
      if ASem.IsInsideRoutine() then
        LStorage := 'local'
      else
        LStorage := 'global';
      TParseASTNode(ANode).SetAttr(PARSE_ATTR_STORAGE_CLASS,
        TValue.From<string>(LStorage));
      LConstName := ANode.GetToken().Text;
      if not ASem.DeclareSymbol(LConstName, ANode) then
        ASem.AddSemanticError(ANode, 'S101',
          'Duplicate declaration: ' + LConstName);
      ASem.VisitChildren(ANode);
    end);
end;

// --- Var Declaration ---

procedure RegisterVarDecl(const AParse: TParse);
begin
  AParse.Config().RegisterSemanticRule('stmt.var_decl',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    var
      LTypeAttr:      TValue;
      LTypeText:      string;
      LTypeKind:      string;
      LVarName:       string;
      LStorage:       string;
      LArrayKindAttr: TValue;
      LArrayKind:     string;
    begin
      ANode.GetAttr('var.type_text', LTypeAttr);
      LTypeText := LTypeAttr.AsString;
      // If the grammar tagged this as an array type, use the specialised kind;
      // otherwise resolve normally via the type registry.
      if ANode.GetAttr('var.array_kind', LArrayKindAttr) then
      begin
        LArrayKind := LArrayKindAttr.AsString;
        if LArrayKind = 'static' then
          LTypeKind := 'type.array_static'
        else
          LTypeKind := 'type.array_dynamic';
      end
      else if ANode.GetAttr('var.set_kind', LArrayKindAttr) then
        // Set type: tag with a dedicated kind so the emitter can pick it up
        LTypeKind := 'type.set'
      else if ANode.GetAttr('var.pointer_kind', LArrayKindAttr) then
        // Pointer type: tag with a dedicated kind so the emitter can pick it up
        LTypeKind := 'type.pointer'
      else
        LTypeKind := AParse.Config().TypeTextToKind(LTypeText);
      TParseASTNode(ANode).SetAttr(PARSE_ATTR_TYPE_KIND,
        TValue.From<string>(LTypeKind));
      // Storage class: global unless inside a routine scope
      if ASem.IsInsideRoutine() then
        LStorage := 'local'
      else
        LStorage := 'global';
      TParseASTNode(ANode).SetAttr(PARSE_ATTR_STORAGE_CLASS,
        TValue.From<string>(LStorage));
      LVarName := ANode.GetToken().Text;
      if not ASem.DeclareSymbol(LVarName, ANode) then
        ASem.AddSemanticError(ANode, 'S100',
          'Duplicate declaration: ' + LVarName);
    end);
end;

// --- Procedure Declaration ---

// Builds a comma-separated string of param types for a proc/func decl node.
// Used to detect overloaded routines with identical parameter signatures.
function BuildParamSig(const ANode: TParseASTNodeBase): string;
var
  LAttr:  TValue;
  LChild: TParseASTNodeBase;
  LI:     Integer;
begin
  Result := '';
  for LI := 0 to ANode.ChildCount() - 1 do
  begin
    LChild := ANode.GetChild(LI);
    if LChild.GetNodeKind() <> 'stmt.param_decl' then
      Continue;
    LChild.GetAttr('param.type_text', LAttr);
    if Result <> '' then
      Result := Result + ',';
    Result := Result + LAttr.AsString;
  end;
end;

procedure RegisterProcDecl(const AParse: TParse);
begin
  AParse.Config().RegisterSemanticRule('stmt.proc_decl',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    var
      LAttr:       TValue;
      LName:       string;
      LI:          Integer;
      LIsOverload: Boolean;
      LIsCLinkage: Boolean;
      LToken:      TParseToken;
    begin
      ANode.GetAttr('decl.name', LAttr);
      LName := LAttr.AsString;
      // Check for overload/c_linkage directives
      ANode.GetAttr('decl.overload', LAttr);
      LIsOverload := LAttr.IsType<Boolean> and LAttr.AsBoolean;
      ANode.GetAttr('decl.c_linkage', LAttr);
      LIsCLinkage := LAttr.IsType<Boolean> and LAttr.AsBoolean;
      // Warn: overload + "C" combination -- drop "C", emit W200
      if LIsOverload and LIsCLinkage then
      begin
        TParseASTNode(ANode).SetAttr('decl.c_linkage', TValue.From<Boolean>(False));
        LToken := ANode.GetToken();
        ASem.GetErrors().Add(
          LToken.Filename, LToken.Line, LToken.Column,
          esWarning, 'W200',
          '"C" linkage ignored on overloaded routine -- C++ linkage used');
      end;
      // Declare symbol; suppress duplicate error for overloaded routines
      if not ASem.DeclareSymbol(LName, ANode) then
      begin
        if not LIsOverload then
          ASem.AddSemanticError(ANode, 'S100', 'Duplicate declaration: ' + LName)
        else
        begin
          // Overload is valid only if param types differ from existing declaration
          var LExistingNode: TParseASTNodeBase;
          if ASem.LookupSymbol(LName, LExistingNode) then
          begin
            if BuildParamSig(ANode) = BuildParamSig(LExistingNode) then
              ASem.AddSemanticError(ANode, 'S103',
                'Overloaded routine ''' + LName + ''' must differ in parameter types');
          end;
        end;
      end;
      ASem.PushScope(LName, ANode.GetToken());
      // Visit param children (all but last which is begin_block)
      for LI := 0 to ANode.ChildCount() - 2 do
        ASem.VisitNode(ANode.GetChild(LI));
      // Visit body (last child)
      if ANode.ChildCount() > 0 then
        ASem.VisitNode(ANode.GetChild(ANode.ChildCount() - 1));
      ASem.PopScope(ANode.GetToken());
    end);
end;

// --- Function Declaration ---

procedure RegisterFuncDecl(const AParse: TParse);
begin
  AParse.Config().RegisterSemanticRule('stmt.func_decl',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    var
      LAttr:       TValue;
      LName:       string;
      LReturnText: string;
      LReturnKind: string;
      LResultNode: TParseASTNode;
      LResultTok:  TParseToken;
      LI:          Integer;
      LIsOverload: Boolean;
      LIsCLinkage: Boolean;
      LToken:      TParseToken;
    begin
      ANode.GetAttr('decl.name', LAttr);
      LName := LAttr.AsString;
      // Check for overload/c_linkage directives
      ANode.GetAttr('decl.overload', LAttr);
      LIsOverload := LAttr.IsType<Boolean> and LAttr.AsBoolean;
      ANode.GetAttr('decl.c_linkage', LAttr);
      LIsCLinkage := LAttr.IsType<Boolean> and LAttr.AsBoolean;
      // Warn: overload + "C" combination -- drop "C", emit W200
      if LIsOverload and LIsCLinkage then
      begin
        TParseASTNode(ANode).SetAttr('decl.c_linkage', TValue.From<Boolean>(False));
        LToken := ANode.GetToken();
        ASem.GetErrors().Add(
          LToken.Filename, LToken.Line, LToken.Column,
          esWarning, 'W200',
          '"C" linkage ignored on overloaded routine -- C++ linkage used');
      end;
      // Declare symbol; suppress duplicate error for overloaded routines
      if not ASem.DeclareSymbol(LName, ANode) then
      begin
        if not LIsOverload then
          ASem.AddSemanticError(ANode, 'S100', 'Duplicate declaration: ' + LName)
        else
        begin
          // Overload is valid only if param types differ from existing declaration
          var LExistingNode: TParseASTNodeBase;
          if ASem.LookupSymbol(LName, LExistingNode) then
          begin
            if BuildParamSig(ANode) = BuildParamSig(LExistingNode) then
              ASem.AddSemanticError(ANode, 'S103',
                'Overloaded routine ''' + LName + ''' must differ in parameter types');
          end;
        end;
      end;
      ASem.PushScope(LName, ANode.GetToken());
      // Visit param children
      for LI := 0 to ANode.ChildCount() - 2 do
        ASem.VisitNode(ANode.GetChild(LI));
      // Declare implicit 'Result' variable
      ANode.GetAttr('decl.return_type', LAttr);
      LReturnText := LAttr.AsString;
      LReturnKind := AParse.Config().TypeTextToKind(LReturnText);
      LResultTok  := ANode.GetToken();
      LResultNode := TParseASTNode.CreateNode('stmt.var_decl', LResultTok);
      LResultNode.SetAttr('var.type_text',
        TValue.From<string>(LReturnText));
      LResultNode.SetAttr(PARSE_ATTR_TYPE_KIND,
        TValue.From<string>(LReturnKind));
      LResultNode.SetAttr(PARSE_ATTR_STORAGE_CLASS,
        TValue.From<string>('local'));
      ASem.DeclareSymbol('Result', LResultNode);
      // Visit body
      if ANode.ChildCount() > 0 then
        ASem.VisitNode(ANode.GetChild(ANode.ChildCount() - 1));
      ASem.PopScope(ANode.GetToken());
    end);
end;

// --- Forward Declarations (unit interface section) ---

procedure RegisterForwardDecls(const AParse: TParse);
begin
  AParse.Config().RegisterSemanticRule('stmt.proc_forward',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    var
      LAttr: TValue;
      LName: string;
    begin
      ANode.GetAttr('decl.name', LAttr);
      LName := LAttr.AsString;
      // Declare the symbol so it's visible; params belong to the
      // implementation body scope, not the global scope.
      ASem.DeclareSymbol(LName, ANode);
    end);

  AParse.Config().RegisterSemanticRule('stmt.func_forward',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    var
      LAttr: TValue;
      LName: string;
    begin
      ANode.GetAttr('decl.name', LAttr);
      LName := LAttr.AsString;
      ASem.DeclareSymbol(LName, ANode);
    end);
end;

// --- Parameter Declaration ---

procedure RegisterParamDecl(const AParse: TParse);
begin
  AParse.Config().RegisterSemanticRule('stmt.param_decl',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    var
      LTypeAttr:  TValue;
      LTypeText:  string;
      LTypeKind:  string;
      LParamName: string;
    begin
      ANode.GetAttr('param.type_text', LTypeAttr);
      LTypeText := LTypeAttr.AsString;
      LTypeKind := AParse.Config().TypeTextToKind(LTypeText);
      TParseASTNode(ANode).SetAttr(PARSE_ATTR_TYPE_KIND,
        TValue.From<string>(LTypeKind));
      TParseASTNode(ANode).SetAttr(PARSE_ATTR_STORAGE_CLASS,
        TValue.From<string>('param'));
      ANode.GetAttr('param.name', LTypeAttr);
      LParamName := LTypeAttr.AsString;
      if LParamName = '' then
        LParamName := ANode.GetToken().Text;
      if not ASem.DeclareSymbol(LParamName, ANode) then
        ASem.AddSemanticError(ANode, 'S100',
          'Duplicate declaration: ' + LParamName);
    end);
end;

// =========================================================================
// CONTROL FLOW
// =========================================================================

// --- If/While/For/Writeln/Write ---

procedure RegisterControlFlow(const AParse: TParse);
begin
  AParse.Config().RegisterSemanticRule('stmt.if',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  AParse.Config().RegisterSemanticRule('stmt.while',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  AParse.Config().RegisterSemanticRule('stmt.for',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  AParse.Config().RegisterSemanticRule('stmt.writeln',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  AParse.Config().RegisterSemanticRule('stmt.write',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  AParse.Config().RegisterSemanticRule('stmt.readln',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  AParse.Config().RegisterSemanticRule('stmt.read',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  AParse.Config().RegisterSemanticRule('stmt.repeat',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  AParse.Config().RegisterSemanticRule('stmt.exit',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  AParse.Config().RegisterSemanticRule('stmt.break',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  AParse.Config().RegisterSemanticRule('stmt.continue',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  AParse.Config().RegisterSemanticRule('stmt.case',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  AParse.Config().RegisterSemanticRule('stmt.case_arm',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  AParse.Config().RegisterSemanticRule('stmt.case_else',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  AParse.Config().RegisterSemanticRule('stmt.setlength',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  AParse.Config().RegisterSemanticRule('stmt.include',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  AParse.Config().RegisterSemanticRule('stmt.exclude',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);
end;

// =========================================================================
// EXPRESSIONS
// =========================================================================

// --- Expression Rules ---

procedure RegisterExprRules(const AParse: TParse);
begin
  // assign — visit children
  AParse.Config().RegisterSemanticRule('expr.assign',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  // binary — visit children
  AParse.Config().RegisterSemanticRule('expr.binary',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  // div — visit children
  AParse.Config().RegisterSemanticRule('expr.div',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  // mod — visit children
  AParse.Config().RegisterSemanticRule('expr.mod',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  // shl — visit children
  AParse.Config().RegisterSemanticRule('expr.shl',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  // shr — visit children
  AParse.Config().RegisterSemanticRule('expr.shr',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  // unary — visit children
  AParse.Config().RegisterSemanticRule('expr.unary',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  // grouped — visit children
  AParse.Config().RegisterSemanticRule('expr.grouped',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  // call — visit children
  AParse.Config().RegisterSemanticRule('expr.call',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  // array_index — visit children
  AParse.Config().RegisterSemanticRule('expr.array_index',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  // field_access — visit children (left-hand object only; field name is an attr)
  AParse.Config().RegisterSemanticRule('expr.field_access',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  // deref — visit children
  AParse.Config().RegisterSemanticRule('expr.deref',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  // addr — visit children
  AParse.Config().RegisterSemanticRule('expr.addr',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  // set_literal — visit children (the individual element expressions)
  AParse.Config().RegisterSemanticRule('expr.set_literal',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  // in — visit children (left = element, right = set)
  AParse.Config().RegisterSemanticRule('expr.in',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  // char_literal — type is char
  AParse.Config().RegisterSemanticRule('expr.char_literal',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      TParseASTNode(ANode).SetAttr(PARSE_ATTR_TYPE_KIND,
        TValue.From<string>('type.char'));
    end);

  // hex_literal — treated as integer
  AParse.Config().RegisterSemanticRule('expr.hex_literal',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      TParseASTNode(ANode).SetAttr(PARSE_ATTR_TYPE_KIND,
        TValue.From<string>('type.integer'));
    end);
end;

// --- Identifier Resolution ---

procedure RegisterIdentRule(const AParse: TParse);
begin
  AParse.Config().RegisterSemanticRule('expr.ident',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    var
      LDeclNode:  TParseASTNodeBase;
      LTypeAttr:  TValue;
      LIdentName: string;
    begin
      LIdentName := ANode.GetToken().Text;
      if ASem.LookupSymbol(LIdentName, LDeclNode) then
      begin
        TParseASTNode(ANode).SetAttr(PARSE_ATTR_DECL_NODE,
          TValue.From<TObject>(LDeclNode));
        if LDeclNode.GetAttr(PARSE_ATTR_TYPE_KIND, LTypeAttr) then
          TParseASTNode(ANode).SetAttr(PARSE_ATTR_TYPE_KIND, LTypeAttr);
      end
      else
        ASem.AddSemanticError(ANode, 'S200',
          'Undeclared identifier: ' + LIdentName);
    end);
end;

// --- Literal Types ---

procedure RegisterLiteralTypes(const AParse: TParse);
begin
  AParse.Config().RegisterSemanticRule('expr.integer',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      TParseASTNode(ANode).SetAttr(PARSE_ATTR_TYPE_KIND,
        TValue.From<string>('type.integer'));
    end);

  AParse.Config().RegisterSemanticRule('expr.real',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      TParseASTNode(ANode).SetAttr(PARSE_ATTR_TYPE_KIND,
        TValue.From<string>('type.real'));
    end);

  AParse.Config().RegisterSemanticRule('expr.string',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    var
      LTypeKind: string;
    begin
      // A single-character string literal is a Char in Pascal.
      // GetToken().Text includes the surrounding Pascal quotes, strip them first.
      LTypeKind := 'type.string';
      if (Length(ANode.GetToken().Text) = 3) and
         (ANode.GetToken().Text[1] = '''') then
        LTypeKind := 'type.char';
      TParseASTNode(ANode).SetAttr(PARSE_ATTR_TYPE_KIND,
        TValue.From<string>(LTypeKind));
    end);

  AParse.Config().RegisterSemanticRule('expr.bool',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      TParseASTNode(ANode).SetAttr(PARSE_ATTR_TYPE_KIND,
        TValue.From<string>('type.boolean'));
    end);

  AParse.Config().RegisterSemanticRule('expr.nil',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      TParseASTNode(ANode).SetAttr(PARSE_ATTR_TYPE_KIND,
        TValue.From<string>('type.nil'));
    end);
end;

// --- Type Block ---

procedure RegisterTypeDecls(const AParse: TParse);
begin
  // type block — visit children (the individual type_decl nodes)
  AParse.Config().RegisterSemanticRule('stmt.type_block',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  // individual type declaration — declare name then visit children (field_decls)
  AParse.Config().RegisterSemanticRule('stmt.type_decl',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    var
      LAttr: TValue;
      LName: string;
    begin
      ANode.GetAttr('decl.name', LAttr);
      LName := LAttr.AsString;
      if not ASem.DeclareSymbol(LName, ANode) then
        ASem.AddSemanticError(ANode, 'S102',
          'Duplicate type declaration: ' + LName);
      ASem.VisitChildren(ANode);
    end);

  // field declaration — no-op at semantic level; fields live in the struct scope
  AParse.Config().RegisterSemanticRule('stmt.field_decl',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      // Intentionally empty — fields are emitted directly by the type_decl emitter
    end);
end;

// --- Exception Handling ---

procedure RegisterExceptionRules(const AParse: TParse);
begin
  // try_stmt -- visit all sub-blocks
  AParse.Config().RegisterSemanticRule('stmt.try_stmt',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  // try_body -- visit body statements
  AParse.Config().RegisterSemanticRule('stmt.try_body',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  // except_body -- visit handler statements
  AParse.Config().RegisterSemanticRule('stmt.except_body',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  // finally_body -- visit cleanup statements
  AParse.Config().RegisterSemanticRule('stmt.finally_body',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  // raise -- visit message expression
  AParse.Config().RegisterSemanticRule('stmt.raise',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);

  // raise_code -- visit code and message expressions
  AParse.Config().RegisterSemanticRule('stmt.raise_code',
    procedure(ANode: TParseASTNodeBase; ASem: TParseSemanticBase)
    begin
      ASem.VisitChildren(ANode);
    end);
end;

// === Public Entry Point ===

procedure ConfigSemantics(const AParse: TParse);
begin
  // Scope & structure
  RegisterProgramRoot(AParse);
  RegisterPascalProgram(AParse);
  RegisterBeginBlock(AParse);

  // Declarations
  RegisterVarBlock(AParse);
  RegisterConstBlock(AParse);
  RegisterVarDecl(AParse);
  RegisterTypeDecls(AParse);
  RegisterProcDecl(AParse);
  RegisterFuncDecl(AParse);
  RegisterForwardDecls(AParse);
  RegisterParamDecl(AParse);

  // Control flow
  RegisterControlFlow(AParse);

  // Expressions
  RegisterExprRules(AParse);
  RegisterIdentRule(AParse);
  RegisterLiteralTypes(AParse);

  // Exception handling
  RegisterExceptionRules(AParse);
end;

end.
