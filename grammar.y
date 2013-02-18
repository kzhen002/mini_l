%{
	#include "heading.h"
	#include <map>
	#include <string>
	#include <sstream>
	#include <stack>

	using namespace std;

	int yyerror(const char*);
	int yylex(void);
	extern int column;
	extern int line;
	
	// code
	std::stringstream code;
	bool isError = false;

	// declaration variables
	map<string, int> declarations;
	stack<string> ident_stack;
	stack<int> size_stack;

	// block variables
	stack<string> var_stack;
	stack<string> comp_stack;
	stack<string> index_stack;
	stack<int> label_stack;
	stack<int> predicate_stack;

	stack<string> reverse_stack;

	unsigned int tn = 0;
	unsigned int pn = 0;
	unsigned int Ln = 0;
%}


%union {
	char* idval;
	char* nval;
}

%error-verbose
%token <idval> IDENT
%token <nval> NUMBER
%left PROGRAM
%left BEGIN_PROGRAM
%left END_PROGRAM
%left INTEGER
%left ARRAY
%left OF
%left IF
%left THEN
%left ENDIF
%left ELSE
%left WHILE
%left LOOP
%left ENDLOOP
%left READ
%left WRITE
%left AND
%left OR
%left NOT
%left TRUE
%left FALSE
%left SUB
%left ADD
%left MULT
%left DIV
%left EQ
%left NEQ
%left LT
%left GT
%left LTE
%left GTE
%left QUESTION
%left SEMICOLON
%left COLON
%left COMMA
%left L_PAREN
%left R_PAREN
%left L_SQUARE
%left R_SQUARE
%left ASSIGN

%% 
input:
  program ident semicolon block end_program {
    cout << "input -> program ident semicolon block end_program\n";
  }

block:
  declarationlist begin_program statementlist {
    cout << "block -> declarationlist begin_program statementlist\n";
  }
declarationlist:
  declaration semicolon declarationlist {
    cout << "declarationlist -> declaration semicolon declarationlist\n";
  }
  | declaration semicolon {
    cout << "declarationlist -> declaration semicolon\n";
  }
statementlist:
  statement semicolon statementlist {
    cout << "statementlist -> statement semicolon statementlist\n";
  }
  | statement semicolon {
    cout << "statementlist -> statement semicolon\n";
  }

declaration:
  identifierlist colon integer {
    cout << "declaration -> identifierlist colon integer\n";
  }
  | identifierlist colon array l_square number r_square of integer {
    cout << "declaration -> identifierlist colon array l_square number r_square of integer\n";
  }
identifierlist:
  ident comma identifierlist {
    cout << "identifierlist -> ident comma identifierlist\n";
  }
  | ident {
    cout << "identifierlist -> ident\n";
  }

statement:
  statement1
  | statement2
  | statement3
  | statement4
  | statement5  
statement1:
  var assign statement1or {
    cout << "statement1 -> var assign statement1or\n";
  }
statement1or:
  expression {
    cout << "statement1or -> expression\n";
  }
  | bool_exp question expression colon expression {
    cout << "statement1or -> bool_exp question expression colon expression\n";
  }
statement2:
  if bool_exp then statementlist statement2or {
   cout << "statement2 -> if bool_exp then statementlist statement2or\n";
  }
statement2or:
  else statementlist endif {
    cout << "statement2or -> else statementlist endif\n";
  }
  | endif {
    cout << "statement2or -> endif\n";
  }
statement3:
  while bool_exp loop statementlist endloop {
    cout << "statement3 -> while bool_exp loop statementlist endloop\n";
  }
statement4:
  read varlist {
    cout << "statement4 -> read varlist\n";
  }
statement5:
  write varlist {
    cout << "statement5 -> write varlist\n";
  }
varlist:
  var comma varlist {
    cout << "varlist -> var comma varlist\n";
  }
  | var {
    cout << "varlist -> var\n";
  }

bool_exp:
  relation_exp relation_explist {
    cout << "bool_exp -> relation_exp relation_explist\n";
  }
relation_explist:
  and_or relation_exp relation_explist {
    cout << "relation_explist -> and_or relation_exp relation_explist\n";
  }
  | {
    cout << "relation_explist -> \n";
  }
and_or:
  and {
    cout << "and_or -> AND\n";
  }
  | or {
    cout << "and_or -> OR\n";
  }

relation_exp:
  relation_exp1
  | relation_exp2
  | relation_exp3 
relation_exp1:
  expression comp expression {
    cout << "relation_exp1 -> expression comp expression\n";
  }
  | not expression comp expression {
    cout << "relation_exp1 -> not expression comp expression\n";
  }
relation_exp2:
  true {
    cout << "relation_exp2 -> true\n";
  }
  | not true {
    cout << "relation_exp2 -> not true\n";
  }
relation_exp3:
  false {
    cout << "relation_exp3 -> false\n";
  }
  | not false {
    cout << "relation_exp3 -> not false\n";
  }

comp:
  EQ {
    cout << "comp -> EQ\n";
  }
  | NEQ {
    cout << "comp -> NEQ\n";
  }
  | LT {
    cout << "comp -> LT\n";
  }
  | GT {
    cout << "comp -> GT\n";
  }
  | LTE {
    cout << "comp -> LTE\n";
  }
  | GTE {
    cout << "comp -> GTE\n";
  }

expression:
  minuslist term termlist {
    cout << "expression -> minuslist term termlist\n";
  }
minuslist:
  SUB minuslist {
    cout << "minuslist -> SUB minuslist\n";
  }
  | {
    cout << "minuslist -> \n";
  }
termlist:
  SUB term termlist {
    cout << "termlist -> SUB term termlist\n";
  }
  | ADD term termlist {
    cout << "termlist -> ADD term termlist\n";
  }
  | {
    cout << "termlist -> \n";
  }

term:
  factor factorlist {
    cout << "term -> factor factorlist\n";
  }
factorlist:
  MULT factor factorlist {
    cout << "factorlist -> MULT factor factorlist\n";
  }
  | DIV factor factorlist {
    cout << "factorlist -> DIV factor factorlist\n";
  }
  | {
    cout << "factorlist -> \n";
  }

factor:
  var {
    cout << "factor -> var\n";
  }
  | number {
    cout << "factor -> number\n";
  }
  | l_paren expression r_paren {
    cout << "factor -> l_paren expression r_paren\n";
  }

var:
  ident {
    cout << "var -> ident\n";
  }
  | ident l_square expression r_square {
    cout << "var -> ident l_square expression r_square\n";
  }

ident:
  IDENT {
    cout << "IDENT(" + string($1) + ")\n";
  }
number:
  NUMBER {
    cout << "NUMBER(" + string($1)  + ")\n";
  }
program:
  PROGRAM {
    cout << "program -> PROGRAM\n";
  }
begin_program:
  BEGIN_PROGRAM {
    cout << "begin_program -> BEGIN_PROGRAM\n";
  }
end_program:
  END_PROGRAM {
    cout << "end_program -> END_PROGRAM\n";
  }
integer:
  INTEGER {
    cout << "integer -> INTEGER\n";
  }
array:
  ARRAY {
    cout << "array -> ARRAY\n";
  }
of:
  OF {
    cout << "of -> OF\n";
  }
if:
  IF {
    cout << "if -> IF\n";
  }
then:
  THEN {
    cout << "then -> THEN\n";
  }
endif:
  ENDIF {
    cout << "endif -> ENDIF\n";
  }
else:
  ELSE {
    cout << "else -> ELSE\n";
  }
while:
  WHILE {
    cout << "while -> WHILE\n";
  }
loop:
  LOOP {
    cout << "loop -> LOOP\n";
  }
endloop:
  ENDLOOP {
    cout << "endloop -> ENDLOOP\n";
  }
read:
  READ {
    cout << "read -> READ\n";
  }
write:
  WRITE {
    cout << "write -> WRITE\n";
  }
and:
  AND {
    cout << "and -> AND\n";
  }
or:
  OR {
    cout << "or -> OR\n";
  }
not:
  NOT {
    cout << "not -> NOT\n";
  }
true:
  TRUE {
    cout << "true -> TRUE\n";
  }
false:
  FALSE {
    cout << "false -> FALSE\n";
  }
question:
  QUESTION {
    cout << "question -> QUESTION\n";
  }
semicolon:
  SEMICOLON {
    cout << "semicolon -> SEMICOLON\n";
  }
colon:
  COLON {
    cout << "colon -> COLON\n";
  }
comma:
  COMMA {
    cout << "comma -> COMMA\n";
  }
l_paren:
  L_PAREN {
    cout << "l_paren -> L_PAREN\n";
  }
r_paren:
  R_PAREN {
    cout << "r_paren -> R_PAREN\n";
  }
l_square:
  L_SQUARE {
    cout << "l_square -> L_SQUARE\n";
  }
r_square:
  R_SQUARE {
    cout << "r_square -> R_SQUARE\n";
  }
assign:
  ASSIGN {
    cout << "assign -> ASSIGN\n";
  }
%%


int yyerror(const char *msg) {
	printf("** Line %d, position %d: %s\n", line, column, msg);
	isError = true;
}
