{===============================================================================
  NitroPascal™ - Modern Pascal * C Performance

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://nitropascal.org

  See LICENSE for license information
===============================================================================}

unit NitroPascal.Lexer;

{$I NitroPascal.Defines.inc}

interface

uses
  System.SysUtils,
  Parse;

procedure ConfigLexer(const AParse: TParse);

implementation

// --- Keywords ---

procedure RegisterKeywords(const AParse: TParse);
begin
  AParse.Config()
    .CaseSensitiveKeywords(False)
    .AddKeyword('program',        'keyword.program')
    .AddKeyword('unit',            'keyword.unit')
    .AddKeyword('library',         'keyword.library')
    .AddKeyword('uses',            'keyword.uses')
    .AddKeyword('interface',       'keyword.interface')
    .AddKeyword('implementation',  'keyword.implementation')
    .AddKeyword('exports',         'keyword.exports')
    .AddKeyword('var',       'keyword.var')
    .AddKeyword('begin',     'keyword.begin')
    .AddKeyword('end',       'keyword.end')
    .AddKeyword('procedure', 'keyword.procedure')
    .AddKeyword('function',  'keyword.function')
    .AddKeyword('if',        'keyword.if')
    .AddKeyword('then',      'keyword.then')
    .AddKeyword('else',      'keyword.else')
    .AddKeyword('while',     'keyword.while')
    .AddKeyword('for',       'keyword.for')
    .AddKeyword('to',        'keyword.to')
    .AddKeyword('downto',    'keyword.downto')
    .AddKeyword('do',        'keyword.do')
    .AddKeyword('writeln',   'keyword.writeln')
    .AddKeyword('write',     'keyword.write')
    .AddKeyword('string',    'keyword.string')
    .AddKeyword('integer',   'keyword.integer')
    .AddKeyword('boolean',   'keyword.boolean')
    .AddKeyword('double',    'keyword.double')
    .AddKeyword('true',      'keyword.true')
    .AddKeyword('false',     'keyword.false')
    .AddKeyword('and',       'keyword.and')
    .AddKeyword('or',        'keyword.or')
    .AddKeyword('not',       'keyword.not')
    .AddKeyword('div',       'keyword.div')
    .AddKeyword('mod',       'keyword.mod')
    .AddKeyword('repeat',    'keyword.repeat')
    .AddKeyword('until',     'keyword.until')
    .AddKeyword('exit',      'keyword.exit')
    .AddKeyword('break',     'keyword.break')
    .AddKeyword('continue',  'keyword.continue')
    .AddKeyword('case',      'keyword.case')
    .AddKeyword('of',        'keyword.of')
    .AddKeyword('const',     'keyword.const')
    .AddKeyword('type',      'keyword.type')
    .AddKeyword('readln',    'keyword.readln')
    .AddKeyword('read',      'keyword.read')
    .AddKeyword('nil',       'keyword.nil')
    .AddKeyword('xor',       'keyword.xor')
    .AddKeyword('shl',       'keyword.shl')
    .AddKeyword('shr',       'keyword.shr')
    .AddKeyword('byte',      'keyword.byte')
    .AddKeyword('word',      'keyword.word')
    .AddKeyword('longint',   'keyword.longint')
    .AddKeyword('int64',     'keyword.int64')
    .AddKeyword('cardinal',  'keyword.cardinal')
    .AddKeyword('single',    'keyword.single')
    .AddKeyword('real',      'keyword.real')
    .AddKeyword('char',      'keyword.char')
    .AddKeyword('shortint',  'keyword.shortint')
    .AddKeyword('smallint',  'keyword.smallint')
    .AddKeyword('array',     'keyword.array')
    .AddKeyword('set',       'keyword.set')
    .AddKeyword('record',    'keyword.record')
    .AddKeyword('out',       'keyword.out')
    .AddKeyword('setlength',   'keyword.setlength')
    .AddKeyword('include',     'keyword.include')
    .AddKeyword('exclude',     'keyword.exclude')
    .AddKeyword('in',          'keyword.in')
    // Ordinal intrinsics
    .AddKeyword('inc',         'keyword.inc')
    .AddKeyword('dec',         'keyword.dec')
    .AddKeyword('ord',         'keyword.ord')
    .AddKeyword('chr',         'keyword.chr')
    .AddKeyword('succ',        'keyword.succ')
    .AddKeyword('pred',        'keyword.pred')
    .AddKeyword('odd',         'keyword.odd')
    .AddKeyword('assigned',    'keyword.assigned')
    // String intrinsics
    .AddKeyword('length',      'keyword.length')
    .AddKeyword('copy',        'keyword.copy')
    .AddKeyword('pos',         'keyword.pos')
    .AddKeyword('inttostr',    'keyword.inttostr')
    .AddKeyword('strtoint',    'keyword.strtoint')
    .AddKeyword('strtointdef', 'keyword.strtointdef')
    .AddKeyword('floattostr',  'keyword.floattostr')
    .AddKeyword('strtofloat',  'keyword.strtofloat')
    .AddKeyword('uppercase',   'keyword.uppercase')
    .AddKeyword('lowercase',   'keyword.lowercase')
    .AddKeyword('trim',        'keyword.trim')
    .AddKeyword('trimleft',    'keyword.trimleft')
    .AddKeyword('trimright',   'keyword.trimright')
    .AddKeyword('delete',      'keyword.delete')
    .AddKeyword('insert',      'keyword.insert')
    .AddKeyword('stringofchar','keyword.stringofchar')
    .AddKeyword('upcase',      'keyword.upcase')
    .AddKeyword('booltostr',   'keyword.booltostr')
    // Math intrinsics
    .AddKeyword('abs',         'keyword.abs')
    .AddKeyword('sqr',         'keyword.sqr')
    .AddKeyword('sqrt',        'keyword.sqrt')
    .AddKeyword('sin',         'keyword.sin')
    .AddKeyword('cos',         'keyword.cos')
    .AddKeyword('tan',         'keyword.tan')
    .AddKeyword('arctan',      'keyword.arctan')
    .AddKeyword('ln',          'keyword.ln')
    .AddKeyword('exp',         'keyword.exp')
    .AddKeyword('power',       'keyword.power')
    .AddKeyword('round',       'keyword.round')
    .AddKeyword('trunc',       'keyword.trunc')
    .AddKeyword('ceil',        'keyword.ceil')
    .AddKeyword('floor',       'keyword.floor')
    .AddKeyword('max',         'keyword.max')
    .AddKeyword('min',         'keyword.min')
    .AddKeyword('random',      'keyword.random')
    .AddKeyword('randomize',   'keyword.randomize')
    .AddKeyword('int',         'keyword.int')
    .AddKeyword('frac',        'keyword.frac')
    // Memory intrinsics
    .AddKeyword('new',         'keyword.new')
    .AddKeyword('dispose',     'keyword.dispose')
    .AddKeyword('getmem',      'keyword.getmem')
    .AddKeyword('freemem',     'keyword.freemem')
    .AddKeyword('fillchar',    'keyword.fillchar')
    .AddKeyword('move',        'keyword.move')
    // System intrinsics
    .AddKeyword('sizeof',      'keyword.sizeof')
    .AddKeyword('halt',        'keyword.halt')
    // Exception handling
    .AddKeyword('try',                'keyword.try')
    .AddKeyword('except',             'keyword.except')
    .AddKeyword('finally',            'keyword.finally')
    .AddKeyword('raiseexception',     'keyword.raiseexception')
    .AddKeyword('raiseexceptioncode', 'keyword.raiseexceptioncode')
    .AddKeyword('getexceptioncode',   'keyword.getexceptioncode')
    .AddKeyword('getexceptionmessage','keyword.getexceptionmessage')
    // Additional string/conversion intrinsics
    .AddKeyword('stringreplace',  'keyword.stringreplace')
    .AddKeyword('format',         'keyword.format')
    .AddKeyword('comparestr',     'keyword.comparestr')
    .AddKeyword('sametext',       'keyword.sametext')
    .AddKeyword('quotedstr',      'keyword.quotedstr')
    .AddKeyword('low',            'keyword.low')
    .AddKeyword('high',           'keyword.high')
    .AddKeyword('reallocmem',     'keyword.reallocmem')
    .AddKeyword('abort',          'keyword.abort')
    .AddKeyword('paramcount',     'keyword.paramcount')
    .AddKeyword('paramstr',       'keyword.paramstr')
    // File I/O
    .AddKeyword('assign',          'keyword.assign')
    .AddKeyword('reset',           'keyword.reset')
    .AddKeyword('rewrite',         'keyword.rewrite')
    .AddKeyword('append',          'keyword.append')
    .AddKeyword('close',           'keyword.close')
    .AddKeyword('eof',             'keyword.eof')
    .AddKeyword('filesize',        'keyword.filesize')
    .AddKeyword('filepos',         'keyword.filepos')
    .AddKeyword('seek',            'keyword.seek')
    .AddKeyword('fileexists',      'keyword.fileexists')
    .AddKeyword('directoryexists', 'keyword.directoryexists')
    .AddKeyword('deletefile',      'keyword.deletefile')
    .AddKeyword('renamefile',      'keyword.renamefile')
    .AddKeyword('getcurrentdir',   'keyword.getcurrentdir')
    .AddKeyword('createdir',       'keyword.createdir');
end;

// --- Operators & Delimiters ---

procedure RegisterOperators(const AParse: TParse);
begin
  AParse.Config()
    // Multi-char first for longest-match
    .AddOperator(':=', 'op.assign')
    .AddOperator('<>', 'op.neq')
    .AddOperator('<=', 'op.lte')
    .AddOperator('>=', 'op.gte')
    .AddOperator('=',  'op.eq')
    .AddOperator('<',  'op.lt')
    .AddOperator('>',  'op.gt')
    .AddOperator('+',  'op.plus')
    .AddOperator('-',  'op.minus')
    .AddOperator('*',  'op.multiply')
    .AddOperator('/',  'op.divide')
    .AddOperator(':',  'delimiter.colon')
    .AddOperator(';',  'delimiter.semicolon')
    .AddOperator('..', 'op.range')
    .AddOperator('.',  'delimiter.dot')
    .AddOperator(',',  'delimiter.comma')
    .AddOperator('(',  'delimiter.lparen')
    .AddOperator(')',  'delimiter.rparen')
    .AddOperator('[',  'delimiter.lbracket')
    .AddOperator(']',  'delimiter.rbracket')
    .AddOperator('^',  'op.deref')
    .AddOperator('@',  'op.addr')
    .AddOperator('#',  'op.hash')
    .AddOperator('$',  'op.dollar');
end;

// --- String Styles ---

procedure RegisterStringStyles(const AParse: TParse);
begin
  AParse.Config()
    .AddStringStyle('''', '''', PARSE_KIND_STRING, False);
end;

// --- Comments ---

procedure RegisterComments(const AParse: TParse);
begin
  AParse.Config()
    .AddLineComment('//')
    .AddBlockComment('{', '}')
    .AddBlockComment('(*', '*)');
end;

// --- Structural Tokens ---

procedure RegisterStructural(const AParse: TParse);
begin
  AParse.Config()
    .SetStatementTerminator('delimiter.semicolon')
    .SetBlockOpen('keyword.begin')
    .SetBlockClose('keyword.end');
end;

// --- Type Keywords & Literal Types ---

procedure RegisterTypes(const AParse: TParse);
begin
  AParse.Config()
    .AddTypeKeyword('string',   'type.string')
    .AddTypeKeyword('integer',  'type.integer')
    .AddTypeKeyword('boolean',  'type.boolean')
    .AddTypeKeyword('double',   'type.double')
    // Integer-family aliases
    .AddTypeKeyword('byte',     'type.byte')
    .AddTypeKeyword('word',     'type.word')
    .AddTypeKeyword('longint',  'type.integer')   // LongInt = Int32 = Integer
    .AddTypeKeyword('int64',    'type.int64')
    .AddTypeKeyword('cardinal', 'type.cardinal')
    .AddTypeKeyword('shortint', 'type.shortint')
    .AddTypeKeyword('smallint', 'type.smallint')
    // Float-family aliases
    .AddTypeKeyword('single',   'type.single')
    .AddTypeKeyword('real',     'type.double')    // Real = Double in Delphi
    // Char type
    .AddTypeKeyword('char',     'type.char')
    // File types
    .AddTypeKeyword('textfile',   'type.textfile')
    .AddTypeKeyword('binaryfile', 'type.binaryfile')
    .AddLiteralType('expr.integer', 'type.integer')
    .AddLiteralType('expr.real',    'type.double')
    .AddLiteralType('expr.string',  'type.string')
    .AddLiteralType('expr.bool',    'type.boolean');
end;

// --- Expression Overrides ---

procedure RegisterExprOverrides(const AParse: TParse);
var
  LOverride: TParseExprOverride;
begin
  // Pascal single-quoted strings -> C++ double-quoted
  LOverride :=
    function(const ANode: TParseASTNodeBase;
      const ADefault: TParseExprToStringFunc): string
    var
      LInner: string;
      LText:  string;
    begin
      LText := ANode.GetToken().Text;
      if (Length(LText) >= 2) and (LText[1] = #39) and
         (LText[Length(LText)] = #39) then
        LInner := Copy(LText, 2, Length(LText) - 2)
      else
        LInner := LText;
      LInner := LInner.Replace(#39#39, #39);
      Result := '"' + LInner + '"';
    end;
  AParse.Config().RegisterExprOverride('expr.string', LOverride);
end;

// === Public Entry Point ===

procedure ConfigLexer(const AParse: TParse);
begin
  RegisterKeywords(AParse);
  RegisterOperators(AParse);
  RegisterStringStyles(AParse);
  RegisterComments(AParse);
  RegisterStructural(AParse);
  RegisterTypes(AParse);
  RegisterExprOverrides(AParse);
end;

end.
