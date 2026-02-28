{===============================================================================
  NitroPascal™ - Modern Pascal * C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit NitroPascal.CodeGen;

{$I NitroPascal.Defines.inc}

interface

uses
  Parse;

procedure ConfigCodeGen(const AParse: TParse);

implementation

uses
  System.SysUtils,
  System.Rtti;

// =========================================================================
// TYPE MAPPING
// =========================================================================

procedure RegisterTypeToIR(const AParse: TParse);
begin
  AParse.Config().SetTypeToIR(
    function(const ATypeKind: string): string
    begin
      if ATypeKind = 'type.integer' then
        Result := 'np::Integer'
      else if ATypeKind = 'type.string' then
        Result := 'np::String'
      else if ATypeKind = 'type.boolean' then
        Result := 'np::Boolean'
      else if ATypeKind = 'type.double' then
        Result := 'np::Double'
      else if ATypeKind = 'type.single' then
        Result := 'np::Single'
      else if ATypeKind = 'type.char' then
        Result := 'np::Char'
      else if ATypeKind = 'type.byte' then
        Result := 'np::Byte'
      else if ATypeKind = 'type.word' then
        Result := 'np::Word'
      else if ATypeKind = 'type.cardinal' then
        Result := 'np::Cardinal'
      else if ATypeKind = 'type.int64' then
        Result := 'np::Int64'
      else if ATypeKind = 'type.shortint' then
        Result := 'np::ShortInt'
      else if ATypeKind = 'type.smallint' then
        Result := 'np::SmallInt'
      else if ATypeKind = 'type.void' then
        Result := 'void'
      else if ATypeKind = 'type.textfile' then
        Result := 'np::TextFile'
      else if ATypeKind = 'type.binaryfile' then
        Result := 'np::BinaryFile'
      else
        Result := 'np::Double';
    end);
end;

// =========================================================================
// PRIVATE HELPERS
// =========================================================================

// Resolves a Pascal type text to its C++ IR string.
// If the type is unknown (user-defined, e.g. a record struct), the raw Pascal
// type name is returned directly as the C++ name, since struct names match.
function ResolveTypeIR(const AParse: TParse; const ATypeText: string): string;
var
  LKind: string;
begin
  LKind := AParse.Config().TypeTextToKind(ATypeText);
  if LKind <> 'type.unknown' then
    Result := AParse.Config().TypeToIR(LKind)
  else
    Result := ATypeText;
end;

// =========================================================================
// PROGRAM STRUCTURE
// =========================================================================

// --- Program Root ---

procedure RegisterProgramRoot(const AParse: TParse);
begin
  AParse.Config().RegisterEmitter('program.root',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    begin
      AGen.EmitLine('#pragma once', sfHeader);
      AGen.EmitLine('#include "runtime.h"', sfHeader);
      AGen.EmitChildren(ANode);
    end);
end;

// --- Pascal Program ---

procedure RegisterPascalProgram(const AParse: TParse);
begin
  AParse.Config().RegisterEmitter('stmt.pascal_program',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    var
      LI:        Integer;
      LJ:        Integer;
      LChild:    TParseASTNodeBase;
      LUsesNode: TParseASTNodeBase;
      LItemNode: TParseASTNodeBase;
      LUnitName: string;
      LAttr:     TValue;
    begin
      // Emit #include for each unit in the uses clause (if present)
      for LI := 0 to ANode.ChildCount() - 1 do
      begin
        LChild := ANode.GetChild(LI);
        if LChild.GetNodeKind() = 'stmt.uses_clause' then
        begin
          LUsesNode := LChild;
          for LJ := 0 to LUsesNode.ChildCount() - 1 do
          begin
            LItemNode := LUsesNode.GetChild(LJ);
            LItemNode.GetAttr('decl.name', LAttr);
            LUnitName := LAttr.AsString;
            AGen.Include(LUnitName + '.h', sfHeader);
          end;
          Break;
        end;
      end;
      // Emit all children except the last (main begin_block),
      // skipping the uses_clause which was handled above
      for LI := 0 to ANode.ChildCount() - 2 do
      begin
        LChild := ANode.GetChild(LI);
        if LChild.GetNodeKind() <> 'stmt.uses_clause' then
          AGen.EmitNode(LChild);
      end;
      // Wrap last child in main()
      AGen.Func('main', 'int');
      AGen.Param('argc', 'int');
      AGen.Param('argv', 'char**');
      // Initialise command-line parameter support
      AGen.Stmt('np::InitCommandLine(argc, argv);');
      AGen.EmitNode(ANode.GetChild(ANode.ChildCount() - 1));
      AGen.Return(AGen.Lit(0));
      AGen.EndFunc();
    end);
end;

// =========================================================================
// DECLARATIONS
// =========================================================================

// --- Var Block ---

procedure RegisterVarBlock(const AParse: TParse);
begin
  AParse.Config().RegisterEmitter('stmt.var_block',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    begin
      AGen.EmitChildren(ANode);
    end);
end;

// --- Var Declaration ---

procedure RegisterVarDecl(const AParse: TParse);
begin
  AParse.Config().RegisterEmitter('stmt.var_decl',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    var
      LTypeAttr:    TValue;
      LStorageAttr: TValue;
      LTypeKind:    string;
      LStorage:     string;
      LCppType:     string;
      LVarName:     string;
      LElemType:    string;
      LElemCppType: string;
      LArrayLow:    string;
      LArrayHigh:   string;
      LArraySize:   Integer;
    begin
      ANode.GetAttr(PARSE_ATTR_TYPE_KIND, LTypeAttr);
      ANode.GetAttr(PARSE_ATTR_STORAGE_CLASS, LStorageAttr);
      LTypeKind := LTypeAttr.AsString;
      LStorage  := LStorageAttr.AsString;
      // Resolve the variable's C++ type from its type kind.
      if LTypeKind = 'type.array_static' then
      begin
        // std::array<ElemType, Size>  where Size = high - low + 1
        ANode.GetAttr('var.elem_type_text', LTypeAttr);
        LElemType    := LTypeAttr.AsString;
        LElemCppType := ResolveTypeIR(AParse, LElemType);
        ANode.GetAttr('var.array_low',  LTypeAttr);
        LArrayLow    := LTypeAttr.AsString;
        ANode.GetAttr('var.array_high', LTypeAttr);
        LArrayHigh   := LTypeAttr.AsString;
        LArraySize   := StrToIntDef(LArrayHigh, 0) - StrToIntDef(LArrayLow, 0) + 1;
        LCppType     := Format('std::array<%s, %d>', [LElemCppType, LArraySize]);
      end
      else if LTypeKind = 'type.array_dynamic' then
      begin
        // np::DynArray<ElemType>
        ANode.GetAttr('var.elem_type_text', LTypeAttr);
        LElemType    := LTypeAttr.AsString;
        LElemCppType := ResolveTypeIR(AParse, LElemType);
        LCppType     := Format('np::DynArray<%s>', [LElemCppType]);
      end
      else if LTypeKind = 'type.set' then
      begin
        // np::Set<ElemType>
        ANode.GetAttr('var.elem_type_text', LTypeAttr);
        LElemType    := LTypeAttr.AsString;
        LElemCppType := ResolveTypeIR(AParse, LElemType);
        LCppType     := Format('np::Set<%s>', [LElemCppType]);
      end
      else if LTypeKind = 'type.pointer' then
      begin
        // ElemType*
        ANode.GetAttr('var.elem_type_text', LTypeAttr);
        LElemType    := LTypeAttr.AsString;
        LElemCppType := ResolveTypeIR(AParse, LElemType);
        LCppType     := LElemCppType + '*';
      end
      else if LTypeKind <> 'type.unknown' then
        // Known primitive or built-in type
        LCppType := AParse.Config().TypeToIR(LTypeKind)
      else
      begin
        // 'type.unknown' means the type is user-defined (e.g. a record struct);
        // use the raw Pascal type name directly as the C++ struct name.
        ANode.GetAttr('var.type_text', LTypeAttr);
        LCppType := LTypeAttr.AsString;
      end;
      LVarName  := ANode.GetToken().Text;
      if LStorage = 'global' then
        AGen.Global(LVarName, LCppType, '')
      else
        AGen.DeclVar(LVarName, LCppType);
    end);
end;

// --- Type Declaration ---

procedure RegisterTypeDecl(const AParse: TParse);
begin
  // type block -- emit children
  AParse.Config().RegisterEmitter('stmt.type_block',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    begin
      AGen.EmitChildren(ANode);
    end);

  // individual type declaration -- record becomes C++ struct, alias becomes 'using'
  AParse.Config().RegisterEmitter('stmt.type_decl',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    var
      LAttr:      TValue;
      LDeclName:  string;
      LTypeKind:  string;
      LAliasText: string;
      LCppType:   string;
      LFieldNode: TParseASTNodeBase;
      LFieldType: string;
      LFieldKind: string;
      LFieldName: string;
      LI:         Integer;
      LArrayLow:  string;
      LArrayHigh: string;
      LArraySize: Integer;
    begin
      ANode.GetAttr('decl.name', LAttr);
      LDeclName := LAttr.AsString;
      ANode.GetAttr('type.kind', LAttr);
      LTypeKind := LAttr.AsString;
      if LTypeKind = 'record' then
      begin
        // Emit complete struct definition into the header
        AGen.EmitLine('struct %s {', [LDeclName], sfHeader);
        for LI := 0 to ANode.ChildCount() - 1 do
        begin
          LFieldNode := ANode.GetChild(LI);
          if LFieldNode.GetNodeKind() = 'stmt.field_decl' then
          begin
            LFieldNode.GetAttr('field.type_text', LAttr);
            LFieldType := LAttr.AsString;
            LFieldKind := AParse.Config().TypeTextToKind(LFieldType);
            // 'type.unknown' means the field type is user-defined (e.g. a nested
            // record); use the raw Pascal name directly as the C++ struct name.
            if LFieldKind <> 'type.unknown' then
              LCppType := AParse.Config().TypeToIR(LFieldKind)
            else
              LCppType := LFieldType;
            LFieldName := LFieldNode.GetToken().Text;
            AGen.EmitLine('  %s %s{};', [LCppType, LFieldName], sfHeader);
          end;
        end;
        AGen.EmitLine('};', sfHeader);
        AGen.EmitLine('', sfHeader);
      end
      else if LTypeKind = 'alias' then
      begin
        ANode.GetAttr('type.alias_text', LAttr);
        LAliasText := LAttr.AsString;
        // Resolve the alias target; fall back to raw name for user-defined types
        LCppType := ResolveTypeIR(AParse, LAliasText);
        AGen.EmitLine('using %s = %s;', [LDeclName, LCppType], sfHeader);
        AGen.EmitLine('', sfHeader);
      end
      else if LTypeKind = 'array.static' then
      begin
        // Static array type alias: using TName = std::array<ElemType, Size>;
        ANode.GetAttr('type.elem_type_text', LAttr);
        LFieldType := LAttr.AsString;
        LCppType   := ResolveTypeIR(AParse, LFieldType);
        ANode.GetAttr('type.array_low',  LAttr);
        LArrayLow  := LAttr.AsString;
        ANode.GetAttr('type.array_high', LAttr);
        LArrayHigh := LAttr.AsString;
        LArraySize := StrToIntDef(LArrayHigh, 0) - StrToIntDef(LArrayLow, 0) + 1;
        AGen.EmitLine('using %s = std::array<%s, %d>;',
          [LDeclName, LCppType, LArraySize], sfHeader);
        AGen.EmitLine('', sfHeader);
      end
      else if LTypeKind = 'array.dynamic' then
      begin
        // Dynamic array type alias: using TName = np::DynArray<ElemType>;
        ANode.GetAttr('type.elem_type_text', LAttr);
        LFieldType := LAttr.AsString;
        LCppType   := ResolveTypeIR(AParse, LFieldType);
        AGen.EmitLine('using %s = np::DynArray<%s>;',
          [LDeclName, LCppType], sfHeader);
        AGen.EmitLine('', sfHeader);
      end
      else if LTypeKind = 'set' then
      begin
        // Set type alias: using TName = np::Set<ElemType>;
        ANode.GetAttr('type.elem_type_text', LAttr);
        LFieldType := LAttr.AsString;
        LCppType   := ResolveTypeIR(AParse, LFieldType);
        AGen.EmitLine('using %s = np::Set<%s>;',
          [LDeclName, LCppType], sfHeader);
        AGen.EmitLine('', sfHeader);
      end
      else if LTypeKind = 'pointer' then
      begin
        // Pointer type alias: using PName = ElemType*;
        ANode.GetAttr('type.elem_type_text', LAttr);
        LFieldType := LAttr.AsString;
        LCppType   := ResolveTypeIR(AParse, LFieldType);
        AGen.EmitLine('using %s = %s*;',
          [LDeclName, LCppType], sfHeader);
        AGen.EmitLine('', sfHeader);
      end;
    end);

  // field_decl -- no-op; fields are emitted directly by the type_decl emitter above
  AParse.Config().RegisterEmitter('stmt.field_decl',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    begin
      // Intentionally empty -- fields are emitted by the stmt.type_decl emitter
    end);
end;

// --- Const Block ---

procedure RegisterConstBlock(const AParse: TParse);
begin
  AParse.Config().RegisterEmitter('stmt.const_block',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    begin
      AGen.EmitChildren(ANode);
    end);

  AParse.Config().RegisterEmitter('stmt.const_decl',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    var
      LTypeAttr:    TValue;
      LStorageAttr: TValue;
      LTypeText:    string;
      LStorage:     string;
      LCppType:     string;
      LConstName:   string;
      LValueStr:    string;
    begin
      ANode.GetAttr('const.type_text', LTypeAttr);
      ANode.GetAttr(PARSE_ATTR_STORAGE_CLASS, LStorageAttr);
      LTypeText  := LTypeAttr.AsString;
      LStorage   := LStorageAttr.AsString;
      LConstName := ANode.GetToken().Text;
      LValueStr  := AParse.Config().ExprToString(ANode.GetChild(0));
      if LTypeText = '' then
        // Untyped constant -- let C++ deduce the type
        LCppType := 'auto'
      else
        LCppType := ResolveTypeIR(AParse, LTypeText);
      if LStorage = 'global' then
        AGen.EmitLine('constexpr %s %s = %s;', [LCppType, LConstName, LValueStr])
      else
        AGen.Stmt('constexpr %s %s = %s;', [LCppType, LConstName, LValueStr]);
    end);
end;

// --- Procedure Declaration ---

procedure RegisterProcDecl(const AParse: TParse);
begin
  AParse.Config().RegisterEmitter('stmt.proc_decl',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    var
      LAttr:         TValue;
      LNodeName:     string;
      LParams:       string;
      LI:            Integer;
      LChild:        TParseASTNodeBase;
      LParamAttr:    TValue;
      LModifierAttr: TValue;
      LParamType:    string;
      LModifier:     string;
      LCppType:      string;
      LParamName:    string;
    begin
      ANode.GetAttr('decl.name', LAttr);
      LNodeName := LAttr.AsString;
      // Build param string for forward declaration
      LParams := '';
      for LI := 0 to ANode.ChildCount() - 2 do
      begin
        LChild := ANode.GetChild(LI);
        if LChild.GetNodeKind() <> 'stmt.param_decl' then
          Continue;
        LChild.GetAttr('param.type_text', LParamAttr);
        LChild.GetAttr('param.modifier', LModifierAttr);
        LParamType := LParamAttr.AsString;
        LModifier  := LModifierAttr.AsString;
        LCppType   := ResolveTypeIR(AParse, LParamType);
        // var/out params are passed by reference in C++
        if (LModifier = 'var') or (LModifier = 'out') then
          LCppType := LCppType + '&';
        LChild.GetAttr('param.name', LAttr);
        LParamName := LAttr.AsString;
        if LParamName = '' then LParamName := LChild.GetToken().Text;
        if LParams <> '' then
          LParams := LParams + ', ';
        LParams := LParams + LCppType + ' ' + LParamName;
      end;
      // Forward declaration to header (suppressed inside unit implementation)
      ANode.GetAttr('decl.suppress_forward', LAttr);
      if not (LAttr.IsType<Boolean> and LAttr.AsBoolean) then
        AGen.EmitLine('void %s(%s);', [LNodeName, LParams], sfHeader);
      // Full definition to source
      AGen.Func(LNodeName, 'void');
      for LI := 0 to ANode.ChildCount() - 2 do
      begin
        LChild := ANode.GetChild(LI);
        if LChild.GetNodeKind() <> 'stmt.param_decl' then
          Continue;
        LChild.GetAttr('param.type_text', LParamAttr);
        LChild.GetAttr('param.modifier', LModifierAttr);
        LParamType := LParamAttr.AsString;
        LModifier  := LModifierAttr.AsString;
        LCppType   := ResolveTypeIR(AParse, LParamType);
        // var/out params are passed by reference in C++
        if (LModifier = 'var') or (LModifier = 'out') then
          LCppType := LCppType + '&';
        LChild.GetAttr('param.name', LAttr);
        LParamName := LAttr.AsString;
        if LParamName = '' then LParamName := LChild.GetToken().Text;
        AGen.Param(LParamName, LCppType);
      end;
      // Emit any var/const declaration blocks (children between params and body)
      for LI := 0 to ANode.ChildCount() - 2 do
      begin
        LChild := ANode.GetChild(LI);
        if (LChild.GetNodeKind() = 'stmt.var_block') or
           (LChild.GetNodeKind() = 'stmt.const_block') then
          AGen.EmitNode(LChild);
      end;
      // Body is last child
      AGen.EmitNode(ANode.GetChild(ANode.ChildCount() - 1));
      AGen.EndFunc();
    end);
end;

// --- Function Declaration ---

procedure RegisterFuncDecl(const AParse: TParse);
begin
  AParse.Config().RegisterEmitter('stmt.func_decl',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    var
      LAttr:         TValue;
      LNodeName:     string;
      LReturnText:   string;
      LCppReturn:    string;
      LParams:       string;
      LI:            Integer;
      LChild:        TParseASTNodeBase;
      LParamAttr:    TValue;
      LModifierAttr: TValue;
      LParamType:    string;
      LModifier:     string;
      LCppType:      string;
      LParamName:    string;
    begin
      ANode.GetAttr('decl.name', LAttr);
      LNodeName := LAttr.AsString;
      ANode.GetAttr('decl.return_type', LAttr);
      LReturnText := LAttr.AsString;
      LCppReturn  := ResolveTypeIR(AParse, LReturnText);
      // Build param string for forward declaration
      LParams := '';
      for LI := 0 to ANode.ChildCount() - 2 do
      begin
        LChild := ANode.GetChild(LI);
        if LChild.GetNodeKind() <> 'stmt.param_decl' then
          Continue;
        LChild.GetAttr('param.type_text', LParamAttr);
        LChild.GetAttr('param.modifier', LModifierAttr);
        LParamType := LParamAttr.AsString;
        LModifier  := LModifierAttr.AsString;
        LCppType   := ResolveTypeIR(AParse, LParamType);
        // var/out params are passed by reference in C++
        if (LModifier = 'var') or (LModifier = 'out') then
          LCppType := LCppType + '&';
        LChild.GetAttr('param.name', LAttr);
        LParamName := LAttr.AsString;
        if LParamName = '' then LParamName := LChild.GetToken().Text;
        if LParams <> '' then
          LParams := LParams + ', ';
        LParams := LParams + LCppType + ' ' + LParamName;
      end;
      // Forward declaration to header (suppressed inside unit implementation)
      ANode.GetAttr('decl.suppress_forward', LAttr);
      if not (LAttr.IsType<Boolean> and LAttr.AsBoolean) then
        AGen.EmitLine('%s %s(%s);', [LCppReturn, LNodeName, LParams], sfHeader);
      // Full definition to source
      AGen.Func(LNodeName, LCppReturn);
      for LI := 0 to ANode.ChildCount() - 2 do
      begin
        LChild := ANode.GetChild(LI);
        if LChild.GetNodeKind() <> 'stmt.param_decl' then
          Continue;
        LChild.GetAttr('param.type_text', LParamAttr);
        LChild.GetAttr('param.modifier', LModifierAttr);
        LParamType := LParamAttr.AsString;
        LModifier  := LModifierAttr.AsString;
        LCppType   := ResolveTypeIR(AParse, LParamType);
        // var/out params are passed by reference in C++
        if (LModifier = 'var') or (LModifier = 'out') then
          LCppType := LCppType + '&';
        LChild.GetAttr('param.name', LAttr);
        LParamName := LAttr.AsString;
        if LParamName = '' then LParamName := LChild.GetToken().Text;
        AGen.Param(LParamName, LCppType);
      end;
      // Declare Result variable
      AGen.DeclVar('Result', LCppReturn, '{}');
      // Emit any var/const declaration blocks (children between params and body)
      for LI := 0 to ANode.ChildCount() - 2 do
      begin
        LChild := ANode.GetChild(LI);
        if (LChild.GetNodeKind() = 'stmt.var_block') or
           (LChild.GetNodeKind() = 'stmt.const_block') then
          AGen.EmitNode(LChild);
      end;
      // Body
      AGen.EmitNode(ANode.GetChild(ANode.ChildCount() - 1));
      AGen.Return(AGen.Get('Result'));
      AGen.EndFunc();
    end);
end;

// --- Parameter Declaration (no-op, handled by proc/func emitters) ---

procedure RegisterParamDecl(const AParse: TParse);
begin
  AParse.Config().RegisterEmitter('stmt.param_decl',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    begin
      // Intentionally empty -- params emitted by proc/func emitters
    end);
end;

// =========================================================================
// CONTROL FLOW
// =========================================================================

// --- Loop control helper ---
// Recursively inspects ANode and its descendants to determine if any
// stmt.break or stmt.continue node is present. Used by loop emitters to
// decide whether the body lambda must return np::LoopControl::Normal on
// its fallthrough path (C++ requires all paths return the same type).

function HasLoopControl(const ANode: TParseASTNodeBase): Boolean;
var
  LI: Integer;
begin
  Result := False;
  if ANode = nil then
    Exit;
  if (ANode.GetNodeKind() = 'stmt.break') or
     (ANode.GetNodeKind() = 'stmt.continue') then
  begin
    Result := True;
    Exit;
  end;
  for LI := 0 to ANode.ChildCount() - 1 do
  begin
    if HasLoopControl(ANode.GetChild(LI)) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

// --- Begin Block ---

procedure RegisterBeginBlock(const AParse: TParse);
begin
  AParse.Config().RegisterEmitter('stmt.begin_block',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    begin
      AGen.EmitChildren(ANode);
    end);
end;

// --- If/Else ---

procedure RegisterIfStmt(const AParse: TParse);
begin
  AParse.Config().RegisterEmitter('stmt.if',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    var
      LCondStr: string;
    begin
      LCondStr := AParse.Config().ExprToString(ANode.GetChild(0));
      AGen.IfStmt(LCondStr);
      AGen.EmitNode(ANode.GetChild(1));
      if ANode.ChildCount() >= 3 then
      begin
        AGen.ElseStmt();
        AGen.EmitNode(ANode.GetChild(2));
      end;
      AGen.EndIf();
    end);
end;

// --- While ---
// Emits np::WhileLoop([&]() { return cond; }, [&]() { body });
// break/continue inside the body lambda return LoopControl values.

procedure RegisterWhileStmt(const AParse: TParse);
begin
  AParse.Config().RegisterEmitter('stmt.while',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    var
      LCondStr: string;
    begin
      LCondStr := AParse.Config().ExprToString(ANode.GetChild(0));
      AGen.Stmt('np::WhileLoop([&]() { return %s; }, [&]() {', [LCondStr]);
      AGen.IndentIn();
      AGen.EmitNode(ANode.GetChild(1));
      // If the body contains break/continue the lambda return type is deduced
      // as LoopControl -- all fallthrough paths must also return LoopControl.
      if HasLoopControl(ANode.GetChild(1)) then
        AGen.Stmt('return np::LoopControl::Normal;');
      AGen.IndentOut();
      AGen.Stmt('});');
    end);
end;

// --- For ---
// Emits np::ForLoop / np::ForLoopDownto with lambda body.
// The loop variable is declared before the call so it is visible inside.

procedure RegisterForStmt(const AParse: TParse);
begin
  AParse.Config().RegisterEmitter('stmt.for',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    var
      LAttr:     TValue;
      LVarName:  string;
      LDir:      string;
      LStartStr: string;
      LEndStr:   string;
    begin
      ANode.GetAttr('for.var', LAttr);
      LVarName  := LAttr.AsString;
      ANode.GetAttr('for.dir', LAttr);
      LDir      := LAttr.AsString;
      LStartStr := AParse.Config().ExprToString(ANode.GetChild(0));
      LEndStr   := AParse.Config().ExprToString(ANode.GetChild(1));
      if LDir = 'to' then
        AGen.Stmt('np::ForLoop(%s, %s, [&](np::Integer %s) {',
          [LStartStr, LEndStr, LVarName])
      else
        AGen.Stmt('np::ForLoopDownto(%s, %s, [&](np::Integer %s) {',
          [LStartStr, LEndStr, LVarName]);
      AGen.IndentIn();
      AGen.EmitNode(ANode.GetChild(2));
      // If the body contains break/continue the lambda return type is deduced
      // as LoopControl -- all fallthrough paths must also return LoopControl.
      if HasLoopControl(ANode.GetChild(2)) then
        AGen.Stmt('return np::LoopControl::Normal;');
      AGen.IndentOut();
      AGen.Stmt('});');
    end);
end;

// --- Repeat..Until ---
// Children: [stmt0..stmtN-1, condition_expr]
// Emits: np::RepeatUntil([&]() { body }, [&]() { return cond; });

procedure RegisterRepeatStmt(const AParse: TParse);
begin
  AParse.Config().RegisterEmitter('stmt.repeat',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    var
      LCondStr: string;
      LLast:    Integer;
      LI:       Integer;
    begin
      LLast    := ANode.ChildCount() - 1;
      LCondStr := AParse.Config().ExprToString(ANode.GetChild(LLast));
      AGen.Stmt('np::RepeatUntil([&]() {');
      AGen.IndentIn();
      for LI := 0 to LLast - 1 do
        AGen.EmitNode(ANode.GetChild(LI));
      // If the body contains break/continue the lambda return type is deduced
      // as LoopControl -- all fallthrough paths must also return LoopControl.
      if HasLoopControl(ANode) then
        AGen.Stmt('return np::LoopControl::Normal;');
      AGen.IndentOut();
      AGen.Stmt('}, [&]() { return %s; });', [LCondStr]);
    end);
end;

// --- Case..Of ---
// Emits a native C++ switch statement.
// Multiple labels on one arm emit multiple consecutive C++ case labels.
// Each arm emits a break to prevent C++ fallthrough.
// The else branch emits as default:.

procedure RegisterCaseStmt(const AParse: TParse);
begin
  // --- stmt.case ---
  AParse.Config().RegisterEmitter('stmt.case',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    var
      LSelectorStr: string;
      LI:           Integer;
    begin
      LSelectorStr := AParse.Config().ExprToString(ANode.GetChild(0));
      AGen.Stmt('switch (%s) {', [LSelectorStr]);
      AGen.IndentIn();
      for LI := 1 to ANode.ChildCount() - 1 do
        AGen.EmitNode(ANode.GetChild(LI));
      AGen.IndentOut();
      AGen.Stmt('}');
    end);

  // --- stmt.case_arm ---
  AParse.Config().RegisterEmitter('stmt.case_arm',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    var
      LAttr:       TValue;
      LLabelCount: Integer;
      LLabelStr:   string;
      LI:          Integer;
    begin
      ANode.GetAttr('case.label_count', LAttr);
      LLabelCount := LAttr.AsInteger;
      // Emit one C++ case label per Pascal label
      for LI := 0 to LLabelCount - 1 do
      begin
        LLabelStr := AParse.Config().ExprToString(ANode.GetChild(LI));
        AGen.Stmt('case %s:', [LLabelStr]);
      end;
      AGen.Stmt('{');
      AGen.IndentIn();
      // Emit body statements (all children after the label nodes)
      for LI := LLabelCount to ANode.ChildCount() - 1 do
        AGen.EmitNode(ANode.GetChild(LI));
      // Always emit break to prevent C++ fallthrough
      AGen.Stmt('break;');
      AGen.IndentOut();
      AGen.Stmt('}');
    end);

  // --- stmt.case_else ---
  AParse.Config().RegisterEmitter('stmt.case_else',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    begin
      AGen.Stmt('default:');
      AGen.Stmt('{');
      AGen.IndentIn();
      AGen.EmitChildren(ANode);
      AGen.IndentOut();
      AGen.Stmt('}');
    end);
end;

// --- Exit / Break / Continue ---
// exit        -> return;
// exit(value) -> return value;
// break       -> return np::LoopControl::Break;
// continue    -> return np::LoopControl::Continue;

procedure RegisterExitBreakContinue(const AParse: TParse);
begin
  AParse.Config().RegisterEmitter('stmt.exit',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    begin
      if ANode.ChildCount() > 0 then
        AGen.Return(AParse.Config().ExprToString(ANode.GetChild(0)))
      else
        AGen.Return();
    end);

  AParse.Config().RegisterEmitter('stmt.break',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    begin
      AGen.Return('np::LoopControl::Break');
    end);

  AParse.Config().RegisterEmitter('stmt.continue',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    begin
      AGen.Return('np::LoopControl::Continue');
    end);
end;

// =========================================================================
// I/O
// =========================================================================

// --- String Literal ---
// A single-character Pascal string literal (e.g. '*') is a np::Char (char16_t)
// and must be emitted as u'*'. Multi-character literals are np::String.

procedure RegisterStringLiteral(const AParse: TParse);
begin
  AParse.Config().RegisterExprOverride('expr.string',
    function(const ANode: TParseASTNodeBase;
      const ADefault: TParseExprToStringFunc): string
    var
      LText: string;
    begin
      // GetToken().Text holds the raw Pascal token including surrounding quotes,
      // e.g. '*' -> text is '*' (3 chars). Strip the outer single quotes first.
      LText := ANode.GetToken().Text;
      if (Length(LText) >= 2) and
         (LText[1] = '''') and (LText[Length(LText)] = '''') then
        LText := Copy(LText, 2, Length(LText) - 2);
      if Length(LText) = 1 then
        // Single character: emit as char16_t literal for np::Char compatibility
        Result := 'u''' + LText + ''''
      else
        // Multi-character string: emit as a standard quoted C++ string literal.
        // Do NOT call ADefault here -- it re-enters this override causing a stack overflow.
        Result := '"' + LText + '"';
    end);
end;

// --- Nil Literal ---

procedure RegisterNilLiteral(const AParse: TParse);
begin
  AParse.Config().RegisterExprOverride('expr.nil',
    function(const ANode: TParseASTNodeBase;
      const ADefault: TParseExprToStringFunc): string
    begin
      // Pascal nil maps to C++ nullptr
      Result := 'nullptr';
    end);
end;

procedure RegisterBoolLiteral(const AParse: TParse);
begin
  AParse.Config().RegisterExprOverride('expr.bool',
    function(const ANode: TParseASTNodeBase;
      const ADefault: TParseExprToStringFunc): string
    begin
      // Pascal True/False (case-insensitive) -> C++ lowercase true/false
      if SameText(ANode.GetToken().Text, 'true') then
        Result := 'true'
      else
        Result := 'false';
    end);
end;

// --- Runtime Operator Overrides ---
// div, mod, shl, shr emit np:: calls instead of raw C++ operators

procedure RegisterRuntimeOperators(const AParse: TParse);
begin
  // div -- np::Div() provides divide-by-zero protection
  AParse.Config().RegisterExprOverride('expr.div',
    function(const ANode: TParseASTNodeBase;
      const ADefault: TParseExprToStringFunc): string
    begin
      Result := Format('np::Div(%s, %s)', [
        ADefault(ANode.GetChild(0)),
        ADefault(ANode.GetChild(1))]);
    end);

  // mod -- np::Mod() provides divide-by-zero protection
  AParse.Config().RegisterExprOverride('expr.mod',
    function(const ANode: TParseASTNodeBase;
      const ADefault: TParseExprToStringFunc): string
    begin
      Result := Format('np::Mod(%s, %s)', [
        ADefault(ANode.GetChild(0)),
        ADefault(ANode.GetChild(1))]);
    end);

  // shl -- np::Shl()
  AParse.Config().RegisterExprOverride('expr.shl',
    function(const ANode: TParseASTNodeBase;
      const ADefault: TParseExprToStringFunc): string
    begin
      Result := Format('np::Shl(%s, %s)', [
        ADefault(ANode.GetChild(0)),
        ADefault(ANode.GetChild(1))]);
    end);

  // shr -- np::Shr()
  AParse.Config().RegisterExprOverride('expr.shr',
    function(const ANode: TParseASTNodeBase;
      const ADefault: TParseExprToStringFunc): string
    begin
      Result := Format('np::Shr(%s, %s)', [
        ADefault(ANode.GetChild(0)),
        ADefault(ANode.GetChild(1))]);
    end);
end;

// --- Structure Expression Overrides ---
// arr[i], rec.field, p^, @x, set literal, in, char literal, hex literal

procedure RegisterStructureExprOverrides(const AParse: TParse);
begin
  // arr[i] -- subtract the array's declared low bound so Delphi 1-based
  // (or any-based) indexing maps correctly to 0-based C++ storage.
  // The low bound is read from the var decl node stored on the ident's
  // PARSE_ATTR_DECL_NODE attribute, which is populated by the semantic pass.
  AParse.Config().RegisterExprOverride('expr.array_index',
    function(const ANode: TParseASTNodeBase;
      const ADefault: TParseExprToStringFunc): string
    var
      LArrayExpr: TParseASTNodeBase;
      LDeclAttr:  TValue;
      LDeclNode:  TParseASTNodeBase;
      LLowAttr:   TValue;
      LArrayStr:  string;
      LIndexStr:  string;
      LLow:       Integer;
    begin
      LArrayExpr := ANode.GetChild(0);
      LIndexStr  := ADefault(ANode.GetChild(1));
      LArrayStr  := ADefault(LArrayExpr);
      // Attempt to retrieve the declaration node for the array variable
      LLow := 0;
      if LArrayExpr.GetAttr(PARSE_ATTR_DECL_NODE, LDeclAttr) then
      begin
        LDeclNode := TParseASTNodeBase(LDeclAttr.AsObject);
        if (LDeclNode <> nil) and LDeclNode.GetAttr('var.array_low', LLowAttr) then
          LLow := StrToIntDef(LLowAttr.AsString, 0);
      end;
      if LLow <> 0 then
        Result := Format('%s[(%s) - %d]', [LArrayStr, LIndexStr, LLow])
      else
        Result := Format('%s[%s]', [LArrayStr, LIndexStr]);
    end);

  // rec.field -- dot access
  AParse.Config().RegisterExprOverride('expr.field_access',
    function(const ANode: TParseASTNodeBase;
      const ADefault: TParseExprToStringFunc): string
    var
      LAttr:      TValue;
      LFieldName: string;
    begin
      ANode.GetAttr('field.name', LAttr);
      LFieldName := LAttr.AsString;
      Result := Format('%s.%s', [ADefault(ANode.GetChild(0)), LFieldName]);
    end);

  // p^ -- pointer dereference
  AParse.Config().RegisterExprOverride('expr.deref',
    function(const ANode: TParseASTNodeBase;
      const ADefault: TParseExprToStringFunc): string
    begin
      Result := Format('(*%s)', [ADefault(ANode.GetChild(0))]);
    end);

  // @x -- address-of
  AParse.Config().RegisterExprOverride('expr.addr',
    function(const ANode: TParseASTNodeBase;
      const ADefault: TParseExprToStringFunc): string
    begin
      Result := Format('(&%s)', [ADefault(ANode.GetChild(0))]);
    end);

  // [a, b, c] set literal -- np::MakeSet({a, b, c})
  // Note: type parameter T is inferred by C++ from the brace-enclosed elements.
  AParse.Config().RegisterExprOverride('expr.set_literal',
    function(const ANode: TParseASTNodeBase;
      const ADefault: TParseExprToStringFunc): string
    var
      LElems: string;
      LI:     Integer;
    begin
      LElems := '';
      for LI := 0 to ANode.ChildCount() - 1 do
      begin
        if LElems <> '' then
          LElems := LElems + ', ';
        LElems := LElems + ADefault(ANode.GetChild(LI));
      end;
      Result := Format('np::MakeSet({%s})', [LElems]);
    end);

  // x in mySet -- np::In(x, mySet)
  AParse.Config().RegisterExprOverride('expr.in',
    function(const ANode: TParseASTNodeBase;
      const ADefault: TParseExprToStringFunc): string
    begin
      Result := Format('np::In(%s, %s)', [
        ADefault(ANode.GetChild(0)),
        ADefault(ANode.GetChild(1))]);
    end);

  // #65 char literal -- static_cast<np::Char>(65)
  AParse.Config().RegisterExprOverride('expr.char_literal',
    function(const ANode: TParseASTNodeBase;
      const ADefault: TParseExprToStringFunc): string
    var
      LAttr:    TValue;
      LOrdinal: string;
    begin
      ANode.GetAttr('char.ordinal', LAttr);
      LOrdinal := LAttr.AsString;
      Result := Format('static_cast<np::Char>(%s)', [LOrdinal]);
    end);

  // $FF hex literal -- convert hex string to decimal integer at compile time
  AParse.Config().RegisterExprOverride('expr.hex_literal',
    function(const ANode: TParseASTNodeBase;
      const ADefault: TParseExprToStringFunc): string
    var
      LAttr:   TValue;
      LHexStr: string;
      LDecVal: Int64;
    begin
      ANode.GetAttr('hex.digits', LAttr);
      LHexStr := LAttr.AsString;
      LDecVal := StrToInt64('$' + LHexStr);
      Result  := IntToStr(LDecVal);
    end);
end;

// --- Writeln ---

procedure RegisterWriteln(const AParse: TParse);
begin
  AParse.Config().RegisterEmitter('stmt.writeln',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    var
      LArgs: TArray<string>;
      LI:    Integer;
    begin
      SetLength(LArgs, ANode.ChildCount());
      for LI := 0 to ANode.ChildCount() - 1 do
        LArgs[LI] := AParse.Config().ExprToString(ANode.GetChild(LI));
      AGen.Call('np::WriteLn', LArgs);
    end);
end;

// --- Readln ---

procedure RegisterReadln(const AParse: TParse);
begin
  AParse.Config().RegisterEmitter('stmt.readln',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    var
      LArgs: TArray<string>;
      LI:    Integer;
    begin
      SetLength(LArgs, ANode.ChildCount());
      for LI := 0 to ANode.ChildCount() - 1 do
        LArgs[LI] := AParse.Config().ExprToString(ANode.GetChild(LI));
      AGen.Call('np::ReadLn', LArgs);
    end);
end;

// --- Read ---

procedure RegisterRead(const AParse: TParse);
begin
  AParse.Config().RegisterEmitter('stmt.read',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    var
      LArgs: TArray<string>;
      LI:    Integer;
    begin
      SetLength(LArgs, ANode.ChildCount());
      for LI := 0 to ANode.ChildCount() - 1 do
        LArgs[LI] := AParse.Config().ExprToString(ANode.GetChild(LI));
      AGen.Call('np::Read', LArgs);
    end);
end;

// --- Write ---

procedure RegisterWrite(const AParse: TParse);
begin
  AParse.Config().RegisterEmitter('stmt.write',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    var
      LArgs: TArray<string>;
      LI:    Integer;
    begin
      SetLength(LArgs, ANode.ChildCount());
      for LI := 0 to ANode.ChildCount() - 1 do
        LArgs[LI] := AParse.Config().ExprToString(ANode.GetChild(LI));
      AGen.Call('np::Write', LArgs);
    end);
end;

// =========================================================================
// EXPRESSIONS AS STATEMENTS
// =========================================================================

// --- Assignment Expression ---

procedure RegisterAssignEmitter(const AParse: TParse);
begin
  AParse.Config().RegisterEmitter('expr.assign',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    begin
      AGen.Assign(
        AParse.Config().ExprToString(ANode.GetChild(0)),
        AParse.Config().ExprToString(ANode.GetChild(1)));
    end);
end;

// --- Call Expression ---

procedure RegisterCallEmitter(const AParse: TParse);
begin
  AParse.Config().RegisterEmitter('expr.call',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    var
      LAttr:    TValue;
      LCallName: string;
      LArgs:    TArray<string>;
      LI:       Integer;
    begin
      // call.name is set by grammar to the exact C++ name (np::Foo or user name).
      ANode.GetAttr('call.name', LAttr);
      LCallName := LAttr.AsString;
      SetLength(LArgs, ANode.ChildCount());
      for LI := 0 to ANode.ChildCount() - 1 do
        LArgs[LI] := AParse.Config().ExprToString(ANode.GetChild(LI));
      AGen.Call(LCallName, LArgs);
    end);
end;

// --- SetLength ---

procedure RegisterSetLength(const AParse: TParse);
begin
  AParse.Config().RegisterEmitter('stmt.setlength',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    var
      LArgs: TArray<string>;
    begin
      SetLength(LArgs, 2);
      LArgs[0] := AParse.Config().ExprToString(ANode.GetChild(0));
      LArgs[1] := AParse.Config().ExprToString(ANode.GetChild(1));
      AGen.Call('np::SetLength', LArgs);
    end);
end;

// --- Try..Except..Finally ---
// Emit strategy:
//   try..except          -> try { body } catch (...) { np::CatchException(); handler }
//   try..finally         -> try { body } catch (...) { finally_body; throw; } finally_body
//   try..except..finally -> try { body } catch (...) { np::CatchException(); handler }
//                           finally_body

procedure RegisterTryStmt(const AParse: TParse);
begin
  // Sub-block emitters -- simply emit their children
  AParse.Config().RegisterEmitter('stmt.try_body',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    begin
      AGen.EmitChildren(ANode);
    end);

  AParse.Config().RegisterEmitter('stmt.except_body',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    begin
      AGen.EmitChildren(ANode);
    end);

  AParse.Config().RegisterEmitter('stmt.finally_body',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    begin
      AGen.EmitChildren(ANode);
    end);

  AParse.Config().RegisterEmitter('stmt.try_stmt',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    var
      LTryBody:     TParseASTNodeBase;
      LExceptBody:  TParseASTNodeBase;
      LFinallyBody: TParseASTNodeBase;
      LI:           Integer;
      LHasExcept:   Boolean;
      LHasFinally:  Boolean;
    begin
      // Locate sub-block children by kind
      LTryBody     := nil;
      LExceptBody  := nil;
      LFinallyBody := nil;
      for LI := 0 to ANode.ChildCount() - 1 do
      begin
        if ANode.GetChild(LI).GetNodeKind() = 'stmt.try_body' then
          LTryBody := ANode.GetChild(LI)
        else if ANode.GetChild(LI).GetNodeKind() = 'stmt.except_body' then
          LExceptBody := ANode.GetChild(LI)
        else if ANode.GetChild(LI).GetNodeKind() = 'stmt.finally_body' then
          LFinallyBody := ANode.GetChild(LI);
      end;
      LHasExcept  := LExceptBody  <> nil;
      LHasFinally := LFinallyBody <> nil;
      // Emit the appropriate lambda-based wrapper. The runtime functions
      // (TryCatch, TryFinally, TryCatchFinally) install hardware exception
      // handlers and use setjmp/longjmp to catch hardware faults in addition
      // to C++ software exceptions.
      if LHasExcept and LHasFinally then
      begin
        // np::TryCatchFinally(tryFn, catchFn, finallyFn)
        AGen.Stmt('np::TryCatchFinally([&]() {');
        AGen.IndentIn();
        if LTryBody <> nil then AGen.EmitNode(LTryBody);
        AGen.IndentOut();
        AGen.Stmt('}, [&]() {');
        AGen.IndentIn();
        AGen.EmitNode(LExceptBody);
        AGen.IndentOut();
        AGen.Stmt('}, [&]() {');
        AGen.IndentIn();
        AGen.EmitNode(LFinallyBody);
        AGen.IndentOut();
        AGen.Stmt('});');
      end
      else if LHasExcept then
      begin
        // np::TryCatch(tryFn, catchFn)
        AGen.Stmt('np::TryCatch([&]() {');
        AGen.IndentIn();
        if LTryBody <> nil then AGen.EmitNode(LTryBody);
        AGen.IndentOut();
        AGen.Stmt('}, [&]() {');
        AGen.IndentIn();
        AGen.EmitNode(LExceptBody);
        AGen.IndentOut();
        AGen.Stmt('});');
      end
      else if LHasFinally then
      begin
        // np::TryFinally(tryFn, finallyFn) -- exception re-propagates after finally
        AGen.Stmt('np::TryFinally([&]() {');
        AGen.IndentIn();
        if LTryBody <> nil then AGen.EmitNode(LTryBody);
        AGen.IndentOut();
        AGen.Stmt('}, [&]() {');
        AGen.IndentIn();
        AGen.EmitNode(LFinallyBody);
        AGen.IndentOut();
        AGen.Stmt('});');
      end;
    end);
end;

// --- RaiseException / RaiseExceptionCode ---

procedure RegisterRaiseStmt(const AParse: TParse);
begin
  // raiseexception(msg) -- np::RaiseException throws internally
  AParse.Config().RegisterEmitter('stmt.raise',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    var
      LArgs: TArray<string>;
    begin
      SetLength(LArgs, 1);
      LArgs[0] := AParse.Config().ExprToString(ANode.GetChild(0));
      AGen.Call('np::RaiseException', LArgs);
    end);

  // raiseexceptioncode(code, msg) -- both args forwarded to the two-arg overload
  AParse.Config().RegisterEmitter('stmt.raise_code',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    var
      LArgs: TArray<string>;
    begin
      SetLength(LArgs, 2);
      LArgs[0] := AParse.Config().ExprToString(ANode.GetChild(0));  // code
      LArgs[1] := AParse.Config().ExprToString(ANode.GetChild(1));  // message
      AGen.Call('np::RaiseException', LArgs);
    end);
end;

// --- Include / Exclude ---

procedure RegisterIncludeExclude(const AParse: TParse);
begin
  AParse.Config().RegisterEmitter('stmt.include',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    var
      LArgs: TArray<string>;
    begin
      SetLength(LArgs, 2);
      LArgs[0] := AParse.Config().ExprToString(ANode.GetChild(0));
      LArgs[1] := AParse.Config().ExprToString(ANode.GetChild(1));
      AGen.Call('np::Include', LArgs);
    end);

  AParse.Config().RegisterEmitter('stmt.exclude',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    var
      LArgs: TArray<string>;
    begin
      SetLength(LArgs, 2);
      LArgs[0] := AParse.Config().ExprToString(ANode.GetChild(0));
      LArgs[1] := AParse.Config().ExprToString(ANode.GetChild(1));
      AGen.Call('np::Exclude', LArgs);
    end);
end;

// === Public Entry Point ===


// =========================================================================
// COMPILATION UNIT STRUCTURES
// =========================================================================

// --- Pascal Unit ---
// Emits interface section to sfHeader, implementation section to sfSource.
// Header gets: #pragma once, #include for np runtime, forward decls.
// Source gets: #include "UnitName.h", full function bodies.

procedure RegisterPascalUnit(const AParse: TParse);
begin
  AParse.Config().RegisterEmitter('stmt.pascal_unit',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    var
      LI:        Integer;
      LJ:        Integer;
      LChild:    TParseASTNodeBase;
      LItemNode: TParseASTNodeBase;
      LUnitName: string;
      LAttr:     TValue;
    begin
      ANode.GetAttr('decl.name', LAttr);
      LUnitName := LAttr.AsString;
      // Header guard and runtime include go to sfHeader
      AGen.EmitLine('#include "runtime.h"', sfHeader);
      // Emit #include for each unit in the uses clause to sfHeader
      for LI := 0 to ANode.ChildCount() - 1 do
      begin
        LChild := ANode.GetChild(LI);
        if LChild.GetNodeKind() = 'stmt.uses_clause' then
        begin
          for LJ := 0 to LChild.ChildCount() - 1 do
          begin
            LItemNode := LChild.GetChild(LJ);
            LItemNode.GetAttr('decl.name', LAttr);
            AGen.Include(LAttr.AsString + '.h', sfHeader);
          end;
          Break;
        end;
      end;
      // Self-include in source file
      AGen.Include(LUnitName + '.h', sfSource);
      // Walk interface and implementation sections
      for LI := 0 to ANode.ChildCount() - 1 do
      begin
        LChild := ANode.GetChild(LI);
        if LChild.GetNodeKind() = 'stmt.unit_interface' then
          AGen.EmitNode(LChild)
        else if LChild.GetNodeKind() = 'stmt.unit_implementation' then
          AGen.EmitNode(LChild);
        // uses_clause already handled above — skip
      end;
    end);
end;

// --- Unit Interface Section ---
// Forward declarations: proc/func prototypes to sfHeader,
// var/const/type declarations also to sfHeader.

procedure RegisterUnitInterface(const AParse: TParse);
begin
  AParse.Config().RegisterEmitter('stmt.unit_interface',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    var
      LI:    Integer;
      LChild: TParseASTNodeBase;
      LKind:  string;
      LName:  string;
    begin
      for LI := 0 to ANode.ChildCount() - 1 do
      begin
        LChild := ANode.GetChild(LI);
        LKind  := LChild.GetNodeKind();
        if (LKind = 'stmt.proc_forward') or (LKind = 'stmt.func_forward') then
        begin
          // Emit prototype to header — node emitters handle the signature
          LName := LChild.GetNodeKind();  // unused, suppress hint
          // Build prototype by emitting the node — CodeGen handles proc/func
          // forward nodes by emitting only the signature line
          AGen.EmitNode(LChild);
        end
        else
          // var/const/type blocks — emit to header
          AGen.EmitNode(LChild);
      end;
    end);
end;

// --- Procedure Forward Declaration (interface prototype) ---

procedure RegisterProcForward(const AParse: TParse);
begin
  AParse.Config().RegisterEmitter('stmt.proc_forward',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    var
      LI:         Integer;
      LParamNode: TParseASTNodeBase;
      LName:      string;
      LParamName: string;
      LParamType: string;
      LModifier:  string;
      LSig:       string;
      LAttr:      TValue;
    begin
      ANode.GetAttr('decl.name', LAttr);
      LName := LAttr.AsString;
      LSig := 'void ' + LName + '(';
      for LI := 0 to ANode.ChildCount() - 1 do
      begin
        LParamNode := ANode.GetChild(LI);
        if LParamNode.GetNodeKind() = 'stmt.param_decl' then
        begin
          if LI > 0 then LSig := LSig + ', ';
          LParamNode.GetAttr('param.modifier', LAttr);
          LModifier  := LAttr.AsString;
          LParamNode.GetAttr('param.type_text', LAttr);
          LParamType := ResolveTypeIR(AParse, LAttr.AsString);
          LParamNode.GetAttr('param.name', LAttr);
          LParamName := LAttr.AsString;
          if LParamName = '' then
            LParamName := LParamNode.GetToken().Text;
          if LModifier = 'var' then
            LSig := LSig + LParamType + '& ' + LParamName
          else
            LSig := LSig + LParamType + ' ' + LParamName;
        end;
      end;
      LSig := LSig + ');';
      AGen.EmitLine(LSig, sfHeader);
    end);
end;

// --- Function Forward Declaration (interface prototype) ---

procedure RegisterFuncForward(const AParse: TParse);
begin
  AParse.Config().RegisterEmitter('stmt.func_forward',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    var
      LI:         Integer;
      LParamNode: TParseASTNodeBase;
      LName:      string;
      LRetType:   string;
      LParamName: string;
      LParamType: string;
      LModifier:  string;
      LSig:       string;
      LAttr:      TValue;
    begin
      ANode.GetAttr('decl.name', LAttr);
      LName    := LAttr.AsString;
      ANode.GetAttr('decl.return_type', LAttr);
      LRetType := ResolveTypeIR(AParse, LAttr.AsString);
      LSig := LRetType + ' ' + LName + '(';
      for LI := 0 to ANode.ChildCount() - 1 do
      begin
        LParamNode := ANode.GetChild(LI);
        if LParamNode.GetNodeKind() = 'stmt.param_decl' then
        begin
          if LI > 0 then LSig := LSig + ', ';
          LParamNode.GetAttr('param.modifier', LAttr);
          LModifier  := LAttr.AsString;
          LParamNode.GetAttr('param.type_text', LAttr);
          LParamType := ResolveTypeIR(AParse, LAttr.AsString);
          LParamNode.GetAttr('param.name', LAttr);
          LParamName := LAttr.AsString;
          if LParamName = '' then
            LParamName := LParamNode.GetToken().Text;
          if LModifier = 'var' then
            LSig := LSig + LParamType + '& ' + LParamName
          else
            LSig := LSig + LParamType + ' ' + LParamName;
        end;
      end;
      LSig := LSig + ');';
      AGen.EmitLine(LSig, sfHeader);
    end);
end;

// --- Unit Implementation Section ---
// Full proc/func bodies go to sfSource.

procedure RegisterUnitImplementation(const AParse: TParse);
begin
  AParse.Config().RegisterEmitter('stmt.unit_implementation',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    var
      LI:     Integer;
      LChild: TParseASTNodeBase;
      LKind:  string;
    begin
      // Emit children but suppress header forward declarations for func/proc —
      // the interface section already emitted the prototypes.
      for LI := 0 to ANode.ChildCount() - 1 do
      begin
        LChild := ANode.GetChild(LI);
        LKind  := LChild.GetNodeKind();
        if (LKind = 'stmt.func_decl') or (LKind = 'stmt.proc_decl') then
          TParseASTNode(LChild).SetAttr('decl.suppress_forward',
            TValue.From<Boolean>(True));
        AGen.EmitNode(LChild);
      end;
    end);
end;

// --- Pascal Library ---
// Like a program but builds as bmDll. No main(), optional exports clause.

procedure RegisterPascalLibrary(const AParse: TParse);
begin
  AParse.Config().RegisterEmitter('stmt.pascal_library',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    var
      LI:       Integer;
      LJ:       Integer;
      LChild:   TParseASTNodeBase;
      LItemNode: TParseASTNodeBase;
      LKind:    string;
      LAttr:    TValue;
    begin
      AGen.EmitLine('#include "runtime.h"', sfHeader);
      // Emit #include for uses clause units
      for LI := 0 to ANode.ChildCount() - 1 do
      begin
        LChild := ANode.GetChild(LI);
        if LChild.GetNodeKind() = 'stmt.uses_clause' then
        begin
          for LJ := 0 to LChild.ChildCount() - 1 do
          begin
            LItemNode := LChild.GetChild(LJ);
            LItemNode.GetAttr('decl.name', LAttr);
            AGen.Include(LAttr.AsString + '.h', sfHeader);
          end;
          Break;
        end;
      end;
      // Emit all non-structural children (var/const/type/proc/func)
      for LI := 0 to ANode.ChildCount() - 1 do
      begin
        LChild := ANode.GetChild(LI);
        LKind  := LChild.GetNodeKind();
        if (LKind <> 'stmt.uses_clause') and
           (LKind <> 'stmt.exports_clause') and
           (LKind <> 'stmt.begin_block') then
          AGen.EmitNode(LChild);
      end;
      // Emit init block if present (library initialisation body)
      for LI := 0 to ANode.ChildCount() - 1 do
      begin
        LChild := ANode.GetChild(LI);
        if LChild.GetNodeKind() = 'stmt.begin_block' then
          AGen.EmitNode(LChild);
      end;
    end);
end;

// --- C++ Interop Emitters ---
// stmt.cpp_block  — emits raw captured text to header or source
// expr.cpp_inline — emits the raw string verbatim as a C++ expression

procedure RegisterCppInterop(const AParse: TParse);
begin
  AParse.Config().RegisterEmitter('stmt.cpp_block',
    procedure(ANode: TParseASTNodeBase; AGen: TParseIRBase)
    var
      LAttr:   TValue;
      LText:   string;
      LTarget: TParseSourceFile;
    begin
      ANode.GetAttr('cpp.text',   LAttr);
      LText := LAttr.AsString;
      ANode.GetAttr('cpp.target', LAttr);
      if LAttr.AsString = 'header' then
        LTarget := sfHeader
      else
        LTarget := sfSource;
      AGen.EmitRaw(LText, LTarget);
    end);

  AParse.Config().RegisterExprOverride('expr.cpp_inline',
    function(const ANode: TParseASTNodeBase;
      const ADefault: TParseExprToStringFunc): string
    var
      LAttr: TValue;
    begin
      ANode.GetAttr('cpp.text', LAttr);
      Result := LAttr.AsString;
    end);
end;


procedure ConfigCodeGen(const AParse: TParse);
begin
  // Type mapping -- np:: aliases for all Delphi types
  RegisterTypeToIR(AParse);

  // Program structure
  RegisterProgramRoot(AParse);
  RegisterPascalProgram(AParse);
  RegisterPascalUnit(AParse);
  RegisterUnitInterface(AParse);
  RegisterProcForward(AParse);
  RegisterFuncForward(AParse);
  RegisterUnitImplementation(AParse);
  RegisterPascalLibrary(AParse);

  // Declarations
  RegisterVarBlock(AParse);
  RegisterVarDecl(AParse);
  RegisterConstBlock(AParse);
  RegisterTypeDecl(AParse);
  RegisterProcDecl(AParse);
  RegisterFuncDecl(AParse);
  RegisterParamDecl(AParse);

  // Control flow
  RegisterBeginBlock(AParse);
  RegisterIfStmt(AParse);
  RegisterWhileStmt(AParse);
  RegisterForStmt(AParse);

  // I/O
  RegisterStringLiteral(AParse);
  RegisterNilLiteral(AParse);
  RegisterBoolLiteral(AParse);
  RegisterRuntimeOperators(AParse);
  RegisterStructureExprOverrides(AParse);
  RegisterWriteln(AParse);
  RegisterWrite(AParse);
  RegisterReadln(AParse);
  RegisterRead(AParse);

  // Additional control flow
  RegisterRepeatStmt(AParse);
  RegisterCaseStmt(AParse);
  RegisterExitBreakContinue(AParse);

  // Expressions as statements
  RegisterAssignEmitter(AParse);
  RegisterCallEmitter(AParse);
  RegisterSetLength(AParse);
  RegisterIncludeExclude(AParse);
  RegisterTryStmt(AParse);
  RegisterRaiseStmt(AParse);
  RegisterCppInterop(AParse);
end;

end.
