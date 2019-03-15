parser grammar ClientScriptParser;

@members {
boolean inCalc = false;
boolean inCallExpr = false;

boolean inCondition = false;

boolean requireCalc = false;

public void setRequireCalc(boolean requireCalc) {
    this.requireCalc = requireCalc;
}
}

@lexer::header {package com.neptune.jagintellij.parser;}

options { tokenVocab = ClientScriptLexer; }

file
    :   script*
    ;

script
    :   scriptDeclaration statement*
    ;

scriptDeclaration
    :   SCRIPT_DECLARATION formalArgs? formalReturns?
    ;

formalArgs
    :   '(' formalArg (',' formalArg)* ')'
    ;

formalArg
    :   type LOCAL_VAR
    ;

formalReturns
    :   '(' type (',' type)* ')'
    ;

// Statements
statement
    :   blockStatement
    |   returnStatement
    |   ifStatement
    |   whileStatement
    |   forStatement
    |   switchStatement
    |   declarationStatement ';' // ';' because it's used in for loop which manually specified it
    |   assignmentStatement ';' // same as above
    |   expressionStatement
    |   emptyStatement
    ;

blockStatement
    :   '{' statement* '}'
    ;

emptyStatement
    :   ';'
    ;

returnStatement
    :   RETURN ('(' exprList ')') ';'
    ;

declarationStatement
    :   defType LOCAL_VAR EQUAL expr        # NormalDeclarationStatement
    |   defType LOCAL_VAR '(' expr ')'      # ArrayDeclarationStatement
    ;

assignmentStatement
    :   assignableIdentifier EQUAL expr         # SingleAssignmentStatement
    |   assignableIdentifierList EQUAL exprList # MultiAssignmentStatement
    ;

ifStatement
    :   IF {inCondition=true;} parenthesis {inCondition=false;} statement (ELSE statement)?
    ;

whileStatement
    :   WHILE {inCondition=true;} parenthesis {inCondition=false;} statement
    ;

forStatement
    :   FOR '(' forControl ')' statement
    ;

forControl
    :   initializer=forInit ';'
        {inCondition=true;} condition=expr {inCondition=false;} ';'
        incrementer=assignmentStatement
    ;

forInit
    :   declarationStatement
    |   assignmentStatement
    ;

switchStatement
    :   (SWITCH | SWITCH_TYPE) parenthesis '{' switchBlock* '}'
    ;

switchBlock
    :   CASE switchCaseList ':' statement?
    ;

switchCase
    :   (constant | DEFAULT)
    ;

switchCaseList
    :   switchCase (',' switchCase)*
    ;

expressionStatement
    :   expr ';'
    ;

exprList
    :   expr (',' expr)*
    ;

parenthesis
    :   '(' expr ')'
    ;

// Expressions
// Followings Java's operator precedence: https://docs.oracle.com/javase/tutorial/java/nutsandbolts/operators.html
expr
    :   op=('+' | '-') expr                                         # UnaryExpression
    |   expr {!requireCalc || inCalc}? op=('*' | '/' | '%') expr    # MultiplicativeExpression
    |   expr {!requireCalc || inCalc}? op=('+' | '-') expr          # AdditiveExpression
    |   expr {inCondition}? op=('<' | '>' | '>=' | '<=') expr       # RelationalExpression
    |   expr {inCondition}? op=('==' | '!=') expr                   # EqualityExpression
    |   expr {!requireCalc || inCalc}? '&' expr                     # BitwiseAndExpression
    |   expr {!requireCalc || inCalc}? '|' expr                     # BitwiseOrExpression
    |   expr {inCondition}? '||' expr                               # OrExpression
    |   expr {inCondition}? '&&' expr                               # AndExpression
    |   {inCallExpr}? type                                          # TypeExpression
    |   assignableIdentifier                                        # AssignableExpression
    |   LOCAL_VAR '(' expr ')'                                      # ArrayExpression
    |   constant                                                    # ScalarExpression
    |   parenthesis                                                 # ParenthesisExpression
    |   callExpr                                                    # CallExpression
    |   ID                                                          # IdentiferExpression
    ;

callExpr
    :   {!inCalc}? name=CALC {inCalc=true;} '(' exprList ')' {inCalc=false;}                # SpecialWordExpression
    |   identifier=(ID | TYPE) '(' {inCallExpr=true;} exprList? {inCallExpr=false;} ')'     # PrimaryCallExpression
    |   '.' ID ('(' {inCallExpr=true;} exprList? {inCallExpr=false;} ')')?                  # SecondaryCallExpression
    |   '~' ID ('(' {inCallExpr=true;} exprList? {inCallExpr=false;} ')')?                  # ProcCallExpression
    ;

constant
    :   NULL
    |   CONSTANT_VAR
    |   literalConstant
    ;

literalConstant
    :   booleanConstant
    |   numericConstant
    |   stringConstant
    ;

booleanConstant
    :   TRUE
    |   FALSE
    ;

numericConstant
    :   COORD_GRID      # CoordGridNumericConstant
    |   INT             # NormalNumericConstant
    |   HEX             # HexNumericConstant
    |   INT ':' INT     # ComponentIntNumericConstant // TODO move somewhere else?
    |   ID  ':' ID      # ComponentIdNumericConstant  // TODO move somewhere else?
    ;

stringConstant
    :   STRING
    ;

assignableIdentifier
    :   LOCAL_VAR
    |   GAME_VAR
    ;

assignableIdentifierList
    :   assignableIdentifier (',' assignableIdentifier)*
    ;

defType
    :	DEF_INT
    |   DEF_STRING
    |   DEF_TYPE
    ;

type
    :	TYPEINT
    |   TYPESTRING
    |   TYPE
    ;
