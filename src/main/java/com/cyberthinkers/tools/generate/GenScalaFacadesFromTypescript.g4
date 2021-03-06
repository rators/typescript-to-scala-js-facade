/*
 ANTLR4 grammar taken from TypeScript Documentation:
 https://github.com/Microsoft/TypeScript/blob/master/doc/spec.md
 https://github.com/Microsoft/TypeScript/blob/master/doc/spec.md#3.2.7
 https://www.typescriptlang.org/docs/tutorial.html
 https://basarat.gitbooks.io/typescript/content/
 https://github.com/Microsoft/TypeScript/wiki/What's-new-in-TypeScript
 https://www.typescriptlang.org/play/index.html
 missing a lot of stuff, but may be useful->
     https://github.com/vandermore/Randori-Jackalope/blob/master/antlr4/TypeScript.g4
 IntelliJ with antlr4 plugin used: http://plugins.jetbrains.com/plugin/7358?pr=
 to develop this grammar
 https://www.typescriptlang.org/docs/handbook/namespaces.html << namespace vs. modules
*/
grammar GenScalaFacadesFromTypescript;

@lexer::members {
    private boolean strictMode = true;
    public boolean getStrictMode() {
        return this.strictMode;
    }
}

typescriptAmbientDeclarations
 :  declarationScriptElement* EOF
 ;

// see https://www.typescriptlang.org/docs/handbook/declaration-files/templates/global-modifying-module-d-ts.html
// 'global' (I think) is optional, the default module namespace is global

declarationScriptElement
 : 'declare' ambientModuleOrNamespace                                #declareModuleOrNamespace
 | 'declare' ambientStatement lineEnd                                #declareStatement
 | 'declare' 'global' '{' ambientModuleOrNamespace '}'               #declareGlobalModuleOrNamespace
  // interface doens't need to be preceeded by 'declare'
 | interfaceDeclaration                                              #declareInterface
 | exportDef                                                         #declareExport
 | importDef                                                         #declareImport
 ;

exportDef
 : 'export' 'declare' ambientStatement lineEnd
 | 'export' 'as' 'namespace' bindingIdentifier lineEnd // << this is legacy and invalid now, but some ts files still have it
 | exportIdentifier
 ;

importDef
 : 'import' importName 'as' bindingIdentifier 'from' bindingIdentifier lineEnd
 ;

importName
 : bindingIdentifier
 | '*'
 ;

//_______________________________ modules, Namespaces, and Statements

ambientModuleOrNamespace
 : ('module' | 'namespace')? ambientModuleName '{' (el+=ambientItem)* '}'
 ;

ambientModuleName
 : identifierPath
 ;

ambientItem
 : ambientBracesItem
 | ambientStatement lineEnd?
 ;

ambientBracesItem
 : interfaceDeclaration
 | classDeclaration
 | ambientModuleOrNamespace // nested moduels and namespaces
 ;

ambientStatement
 : variableDeclaration
 | typeDeclaration
 | functionDeclaration
 | enumDeclaration
 | exportIdentifier
 // | importAliasDeclaration FIXME
 ;

variableDeclaration
 : ('var' | 'let' | 'const') variableList
 ;

variableList
: variableName (',' variableName )*
;

variableName
 : bindingIdentifier typeAnnotation?
 ;

functionDeclaration
 : 'function' bindingIdentifier callSignature
 ;

classDeclaration
 : 'abstract'? 'class' className  '{' (ambientClassBodyElement lineEnd)* '}'
 ;

className
 : bindingIdentifier typeParameters? classHeritage
 ;


ambientClassBodyElement
 : ambientConstructorDeclaration     #ambientClassBodyElementConstructor
 | ambientPropertyMemberDeclaration  #ambientClassBodyElementProperty
 | indexSignature                    #ambientClassBodyElementIndex
 ;

ambientConstructorDeclaration
 : 'constructor' '(' parameterList? ')'
 ;

ambientPropertyMemberDeclaration
 : accessibilityModifier optStatic typeMember
 ;

optStatic
  : 'static' #optStaticDef
  |          #optStaticNotDef
  ;

exportIdentifier
 : 'export' '=' bindingIdentifier lineEnd
 ;

numericLiteral
 : DecimalLiteral
 | HexIntegerLiteral
 | OctalIntegerLiteral
 ;

//_______________________________ A.1 Types

typeDeclaration
 : 'type' typeDef '=' (type | typeDef)
 ;

typeDef // can't extend anything at the top level
 : bindingIdentifier typeParameters?
 | '{''[' bindingIdentifier 'in' 'keyof'  bindingIdentifier typeParameters? ']' '?'? ':' typeDef '}'
 ;

typeParameters
 : '<' typeParameterList '>'
 ;

typeParameterList
 : typeParameter ( ',' typeParameter )*
 ;

typeParameter
 : bindingIdentifier constraint?
 ;

constraint
 : ('extends' | 'in') type
 ;

typeArguments
 : '<' typeArgumentList '>'
 ;

typeArgumentList
 : type (',' type )*
 ;

type
 : unionOrIntersectionOrPrimaryType
 | functionType
 | constructorType //<< FIXME-it's in the wrong place
 ;

unnamedInterface
 : '{' typeBody? '}'
 ;

unionOrIntersectionOrPrimaryType //FIXME-not sure if the following presidence is correct
 : unionOrIntersectionOrPrimaryType '|' unionOrIntersectionOrPrimaryType
 | unionOrIntersectionOrPrimaryType '&' unionOrIntersectionOrPrimaryType
 | '(' unionOrIntersectionOrPrimaryType ')'
 | primaryOrArray
 | unnamedInterface
 ;

primaryOrArray
 : 'keyof'? primaryType
 | primaryType typeArguments? arrayDim*
 ;

nestedType // FIXME: missing reference to this production
  : '<' type '>'
  ;

arrayDim
 : ('[' ']') // array dimension could be > 1
 ;

primaryType
 : parenthesizedType
 | bindingIdentifier
 | identifier typeGuard
 | typeReference
 | objectType
 | tupleType
 | typeQuery
 | thisType
 | numericLiteral
 | typeDef
 ;

typeGuard
 : 'is' type
 ;

parenthesizedType
 : '(' type ')'
 ;

typeReference
 : identifierPath typeArguments?
 ;

objectType
 : '{' typeBody? lineEnd '}'
 ;

typeBody
 : typeMemberList
 ;

typeMemberList
 : typeMember ((';' | ',') typeMember )*
 ;

typeMember
 : propertySignature
 | callSignature
 | constructSignature // FIXME this should not be defined for interfaces (but this isn't a full compiler either)
 | indexSignature
 | methodSignature
 | bindingIdentifier callSignature  //// FIXME - not sure about this
 ;

tupleType
 : '[' tupleTypeElements ']'
 ;

tupleTypeElements
 : type (',' type)*
 ;

functionType
 : typeParameters? '(' parameterList? ')' '=>' type
 ;

constructorType
 : 'new' typeParameters? '(' parameterList? ')' '=>' type
 ;

typeQuery
 : 'typeof' identifierPath
 ;

thisType
 : 'this'
 ;

propertySignature
 : optionalBindingIdentifier typeAnnotation?
 ;

typeAnnotation
 : ':' type
 ;

callSignature // is this missing a binding identifier?
 : typeParameters? '(' parameterList? ')' typeAnnotation?
 ;

parameterList
 : requiredParameterList (',' ((optionalParameterList (',' restParameter)? | restParameter)))?
 | optionalParameterList (',' restParameter)?
 | restParameter
 ;

requiredParameterList
 : requiredParameter (',' requiredParameter)*
 ;

requiredParameter
 : accessibilityModifier bindingIdentifier typeAnnotation?
 | bindingIdentifier ':' StringLiteral
 ;

accessibilityModifier
 : 'public'     #publicModifier
 | 'private'    #privateModifier
 | 'protected'  #protectedModifier
 |              #publicModifier // defaults to 'public'
 ;

optionalParameterList
 : optionalParameter (',' optionalParameter)*
 ;

optionalParameter // (initializer removed because it's only used when there's a function body)
 : accessibilityModifier optionalBindingIdentifier typeAnnotation?
 | optionalBindingIdentifier ':' StringLiteral  // << FIXME - not sure about this
 ;

restParameter
 : '...' bindingIdentifier typeAnnotation?
 ;

constructSignature
 : 'new' typeParameters? '(' parameterList? ')' typeAnnotation?
 ;

indexSignature
 : '[' bindingIdentifier ':'
       ('string' | 'number')
   ']'
  typeAnnotation
 ;

methodSignature
 : optionalBindingIdentifier callSignature
 ;

//_______________________________ A.2 Expressions

/// FIXME: need constant expressions here for enum
constExpression
 : numericLiteral
 ;

interfaceDeclaration
 : 'interface' interfaceName '{' (typeMember lineEnd)* '}'
 ;

interfaceName // fixme, need to check if access modifiers can be applied
 : bindingIdentifier typeParameters? extendsClause?
 ;

//ambientIntefaceBodyElement // similar to ambientClassBodyElement but no constructor
// : propertySignature
// | indexSignature
// | callSignature
// ;

extendsClause
 : 'extends' classOrInterfaceTypeList
 ;

classOrInterfaceTypeList
 : typeReference (',' typeReference)*
 ;

//_______________________________ A.6 Classes

classHeritage
 : extendsClause? implementsClause?
 ;

implementsClause
 : 'implements' classOrInterfaceTypeList
 ;

//_______________________________ A.7 Enums

enumDeclaration // const enum treated significantly different from plain enum
 : 'const'? 'enum' bindingIdentifier '{' enumBody? '}'
 ;

enumBody // allow for trailing ','
 : enumMemberList ','?
 ;

enumMemberList
 : enumMember (',' enumMember)*
 ;

enumMember
 : bindingIdentifier ('=' enumValue)?
 ;

enumValue
 : constExpression
 ;

////////////////////// identifierPath
identifierPath
 : ident += bindingIdentifier ('.' ident += bindingIdentifier)*
 ;

/////////////////////////////// <<<<<<<<<<<<<<<<<<<<<<<<<<<< plug this rule in............ FIXME
optionalParam
 : '?' #optionalModifier
 |     #requiredParam
 ;

optionalBindingIdentifier
 : bindingIdentifier optionalParam
 ;

bindingIdentifier
 : identifier     #basicIdentifier
 | StringLiteral  #stringLiteralIdentifier
 ;

identifier // unicode not implemented yet
 : Identifier
  | 'as'
  | 'from'
  | 'global'
  | 'module'
  | 'import'
  | 'is'
  | 'in'
  | 'number'
  | 'namespace'
  | 'type'
  | 'typeof'
  | 'string'
 ;

///////////////////////////////////////////////////////////////////////////////////

lineEnd
 : ';'
 | ','
 | LineTerminator
 ;

LineTerminator
 : '\r'? '\n' -> channel(HIDDEN)
 ;

// Tokens

Abstract    : 'abstract';
As          : 'as';
Class       : 'class';
Const       : 'const';
Constructor : 'constructor';
Declare     : 'declare';
Enum        : 'enum';
Export      : 'export';
Extends     : 'extends';
From        : 'from';
Function    : 'function';
Global      : 'global';
Implements  : 'implements';
Import      : 'import';
Interface   : 'interface';
Keyof       : 'keyof';
Let         : 'let';
Module      : 'module';
Var         : 'var';
In          : 'in';
Is          : 'is';

Public      : 'public';
Protected   : 'protected';
Private     : 'private';
Static      : 'static';
Readonly    : 'readonly'; // << new keyword not in spec

New         : 'new';
Typeof      : 'typeof';
This        : 'this';
Type        : 'type';

//Any         : 'any';
//Boolean     : 'boolean';
//Symbol      : 'symbol';
//Void        : 'void';

Number      : 'number';
String      : 'string';

ThickArrow                : '=>';
DotDotDot                 : '...';
OpenBracket               : '[';
CloseBracket              : ']';
OpenParen                 : '(';
CloseParen                : ')';
OpenBrace                 : '{';
CloseBrace                : '}';
SemiColon                 : ';';
Comma                     : ',';
Assign                    : '=';
QuestionMark              : '?';
Colon                     : ':';
Dot                       : '.';
PlusPlus                  : '++';
MinusMinus                : '--';
Plus                      : '+';
Minus                     : '-';
BitNot                    : '~';
Not                       : '!';
Multiply                  : '*';
Divide                    : '/';
Modulus                   : '%';

LessThan                  : '<';
MoreThan                  : '>';
LessThanEquals            : '<=';
GreaterThanEquals         : '>=';
Equals                    : '==';
NotEquals                 : '!=';
IdentityEquals            : '===';
IdentityNotEquals         : '!==';
/* FIXME: this should be added after constant expressions are addded
RightShiftLogical         : '>>>';
RightShiftArithmetic      : '>>';
LeftShiftArithmetic       : '<<';
*/
BitAnd                    : '&';
BitXOr                    : '^';
BitOr                     : '|';
And                       : '&&';
Or                        : '||';
MultiplyAssign            : '*=';
DivideAssign              : '/=';
ModulusAssign             : '%=';
PlusAssign                : '+=';
MinusAssign               : '-=';
LeftShiftArithmeticAssign : '<<=';
RightShiftArithmeticAssign: '>>=';
RightShiftLogicalAssign   : '>>>=';
BitAndAssign              : '&=';
BitXorAssign              : '^=';
BitOrAssign               : '|=';

/// 7.8.2 Boolean Literals
BooleanLiteral
 : 'true'
 | 'false'
 ;

/// 7.8.3 Numeric Literals
DecimalLiteral
 : DecimalIntegerLiteral '.' DecimalDigit* ExponentPart?
 | '.' DecimalDigit+ ExponentPart?
 | DecimalIntegerLiteral ExponentPart?
 ;

/// 7.8.3 Numeric Literals
HexIntegerLiteral
 : '0' [xX] HexDigit+
 ;

OctalIntegerLiteral
 : {!strictMode}? '0' OctalDigit+
 ;

Identifier
 : Letter LetterOrDigit*
 ;

fragment
Letter
 : [a-zA-Z$_]
 ;

fragment
LetterOrDigit
 : [a-zA-Z0-9$_]
 ;

/// 7.8.4 String Literals
StringLiteral
 : '"' DoubleStringCharacter* '"'
 | '\'' SingleStringCharacter* '\''
 ;

fragment DoubleStringCharacter
 : ~["\\\r\n]
 | '\\' EscapeSequence
 | LineContinuation
 ;
fragment SingleStringCharacter
 : ~['\\\r\n]
 | '\\' EscapeSequence
 | LineContinuation
 ;
fragment EscapeSequence
 : CharacterEscapeSequence
 | '0' // no digit ahead! TODO
 | HexEscapeSequence
 | UnicodeEscapeSequence
 ;
fragment CharacterEscapeSequence
 : SingleEscapeCharacter
 | NonEscapeCharacter
 ;
fragment HexEscapeSequence
 : 'x' HexDigit HexDigit
 ;
fragment UnicodeEscapeSequence
 : 'u' HexDigit HexDigit HexDigit HexDigit
 ;
fragment SingleEscapeCharacter
 : ['"\\bfnrtv]
 ;

fragment NonEscapeCharacter
 : ~['"\\bfnrtv0-9xu\r\n]
 ;
fragment EscapeCharacter
 : SingleEscapeCharacter
 | DecimalDigit
 | [xu]
 ;
fragment LineContinuation
 : '\\' LineTerminatorSequence
 ;
fragment LineTerminatorSequence
 : '\r\n'
 | LineTerminator
 ;
fragment DecimalDigit
 : [0-9]
 ;
fragment HexDigit
 : [0-9a-fA-F]
 ;
fragment OctalDigit
 : [0-7]
 ;
fragment DecimalIntegerLiteral
 : '0'
 | [1-9] DecimalDigit*
 ;
fragment ExponentPart
 : [eE] [+-]? DecimalDigit+
 ;
//
// Whitespace and comments
//
WS:  [ \t]+ -> skip
  ;
Documentation
 :  '/**' .*? '*/' -> skip // FIXME needs DOCUMENTATION channel to copy docs to scala facade
 ;
Comment
 :   '/*' .*? '*/' -> skip
 ;
LineComment
 :   '//' ~[\r\n]* -> skip
 ;