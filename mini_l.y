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
%start input
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
		PROGRAM IDENT SEMICOLON block END_PROGRAM {
			if(!isError) {
				for(int i = 0; i < tn; ++i) {
					cout << "\t. t" << i << endl;
				}
				for(int i = 0; i < pn; ++i) {
					cout << "\t. p" << i << endl;
				}
				cout << code.str();
			}
		} 
		| error IDENT SEMICOLON block END_PROGRAM
		| PROGRAM error SEMICOLON block END_PROGRAM
		| PROGRAM IDENT error block END_PROGRAM
		| PROGRAM IDENT SEMICOLON block error
		;


block:
		declarationlist bBEGIN_PROGRAM statementlist
		| declarationlist error statementlist
		;
bBEGIN_PROGRAM:
		BEGIN_PROGRAM {
			code << ": START\n";
		}
declarationlist:
		declaration SEMICOLON declarationlist 
		| declaration SEMICOLON
		| declaration error
		;
statementlist:
		statement SEMICOLON statementlist
		| statement SEMICOLON
		| statement error
		;


declaration:
		identifierlist COLON INTEGER {
			while(ident_stack.size()) {
				code << "\t. " << ident_stack.top() << endl;
				ident_stack.pop();
			}
		}
		| identifierlist COLON ARRAY L_SQUARE NUMBER R_SQUARE OF INTEGER {
			if(atoi($5) <= 0) {
				string msg = "Error: declaring an array of size <= 0";
				yyerror(msg.c_str());
			}
			while(ident_stack.size()) {
				code << "\t.[] " << ident_stack.top() << ", " << atoi($5) << endl;
				declarations[ident_stack.top()] = atoi($5);
				ident_stack.pop();
			}
		}
		| identifierlist error ARRAY L_SQUARE NUMBER R_SQUARE OF INTEGER
		| identifierlist COLON error L_SQUARE NUMBER R_SQUARE OF INTEGER
		| identifierlist COLON ARRAY error NUMBER R_SQUARE OF INTEGER
		| identifierlist COLON ARRAY L_SQUARE error R_SQUARE OF INTEGER
		| identifierlist COLON ARRAY L_SQUARE NUMBER error OF INTEGER
		| identifierlist COLON ARRAY L_SQUARE NUMBER R_SQUARE error INTEGER
		| identifierlist COLON ARRAY L_SQUARE NUMBER R_SQUARE OF error
		;
identifierlist:
		dIDENT COMMA identifierlist
		| dIDENT
		;
dIDENT:
		IDENT {
			if(declarations.find("_"+string($1)) != declarations.end()) {
				string msg = "Error: "+string($1)+" was previously defined";
				yyerror(msg.c_str());
			}
			declarations["_"+string($1)] = -1;
			ident_stack.push("_"+string($1));
		}

statement:
		statement1
		| statement2
		| statement3
		| statement4
		| statement5
		;
statement1:
		var ASSIGN statement1or
		| var error statement1or
		;
statement1or:
		expression {
			string r = var_stack.top();
			if(index_stack.top() != "-1") {
				std::stringstream out;
				out << tn;
				code << "\t=[] t" << tn << ", " << r << ", " << index_stack.top() << endl;
				r = "t"+out.str();
				++tn;
			}
			var_stack.pop();
			index_stack.pop();
			string l = var_stack.top();
			if(index_stack.top() != "-1") {
				code << "\t[]= " << l << ", " << index_stack.top() << ", " << r << endl;
			}
			else {
				code << "\t= " << l << ", " << r << endl;
			}
			var_stack.pop();
			index_stack.pop();
		}
		| bool_exp tQUESTION expression tCOLON expression {
			string r = var_stack.top();
			if(index_stack.top() != "-1") {
				std::stringstream out;
				out << tn;
				code << "\t=[] t" << tn << ", " << r << ", " << index_stack.top() << endl;
				r = "t"+out.str();
				++tn;
			}
			var_stack.pop();
			index_stack.pop();
			string l = var_stack.top();
			if(index_stack.top() != "-1") {
				std::stringstream out;
				out << tn;
				code << "\t[]= " << l << ", " << index_stack.top() << ", " << r << endl;
				l = "t"+out.str();
				++tn;
			}
			else {
				code << "\t= " << l << ", " << r << endl;
			}
			var_stack.pop();
			index_stack.pop();
			code << ": L" << label_stack.top() << endl;
			label_stack.pop();
		}
		| bool_exp error expression tCOLON expression
		| bool_exp tQUESTION expression error expression
		;
tQUESTION:
		QUESTION {
			int r = predicate_stack.top();
			predicate_stack.pop();
			code << "\t?:= L" << Ln << ", p" << r << endl;
			label_stack.push(Ln);
			++Ln;
		}
		;
tCOLON:
		COLON {
			string r = var_stack.top();
			if(index_stack.top() != "-1") {
				std::stringstream out;
				out << tn;
				code << "\t=[] t" << tn << ", " << r << ", " << index_stack.top() << endl;
				r = "t"+out.str();
				++tn;
			}
			var_stack.pop();
			index_stack.pop();
			string l = var_stack.top();
			if(index_stack.top() != "-1") {
				std::stringstream out;
				out << tn;
				code << "\t[]= " << l << ", " << index_stack.top() << ", " << r << endl;
				l = "t"+out.str();
				++tn;
			}
			else {
				code << "\t= " << l << ", " << r << endl;
			}
			code << "\t:= L" << Ln << endl;
			code << ": L" << label_stack.top() << endl;
			label_stack.pop();
			label_stack.push(Ln);
			++Ln;
		}
		;
statement2:
		IF bool_exp tTHEN statementlist statement2or
		| IF bool_exp error statementlist statement2or
		;
tTHEN:
		THEN {
			int r = predicate_stack.top();
			predicate_stack.pop();
			code << "\t?:= L" << Ln << ", p" << r << endl;
			label_stack.push(Ln);
			++Ln;
		}
		;
statement2or:
		tELSE statementlist tENDIF
		| tENDIF
		;
tELSE:
		ELSE {
			code << "\t:= L" << Ln << endl;	
			code << ": L" << label_stack.top() << endl;
			label_stack.pop();
			label_stack.push(Ln);
			++Ln;
		}
		;
tENDIF:
		ENDIF {
			code << ": L" << label_stack.top() << endl;
			label_stack.pop();
		}
statement3:
		tWHILE bool_exp tLOOP statementlist tENDLOOP
		| tWHILE bool_exp error statementlist tENDLOOP
		| tWHILE bool_exp tLOOP statementlist error
		;
tWHILE:
		WHILE {
			code << ": L" << Ln << endl;
			label_stack.push(Ln);
			++Ln;
		}
		;
tLOOP:
		LOOP {
			int r = predicate_stack.top();
			predicate_stack.pop();
			code << "\t?:= L" << Ln << ", p" << r << endl;
			label_stack.push(Ln);
			++Ln;
		}
		;
tENDLOOP:
		ENDLOOP {
			int r = label_stack.top();
			label_stack.pop();
			int l = label_stack.top();
			label_stack.pop();
			code << "\t:= L" << l << "\n: L" << r << endl;
		}
		;
statement4:
		READ varlist {
			while(var_stack.size()) {
				if(index_stack.top() == "-1") {
					std::stringstream out;
					out << "\t.< " << var_stack.top() << endl;
					reverse_stack.push(out.str());			
				}
				else {
					std::stringstream out;
					out << "\t.[]< " << var_stack.top() << ", " << index_stack.top() << endl;
					reverse_stack.push(out.str());			
				}
				var_stack.pop();
				index_stack.pop();
			}
			while(reverse_stack.size()) {
				code << reverse_stack.top();
				reverse_stack.pop();
			}
		}
		;
statement5:
		WRITE varlist {
			while(var_stack.size()) {
				if(index_stack.top() == "-1") {
					std::stringstream out;
					out << "\t.> " << var_stack.top() << endl;
					reverse_stack.push(out.str());			
				}
				else {
					std::stringstream out;
					out << "\t.[]> " << var_stack.top() << ", " << index_stack.top() << endl;
					reverse_stack.push(out.str());			
				}
				var_stack.pop();
				index_stack.pop();
			}
			while(reverse_stack.size()) {
				code << reverse_stack.top();
				reverse_stack.pop();
			}
		}
		;
varlist:
		var COMMA varlist
		| var
		;


bool_exp:
		relation_exp relation_explist {
			int r = predicate_stack.top();
			predicate_stack.pop();
			code << "\t== p" << pn << ", p" << r << ", 0" << endl;
			predicate_stack.push(pn);
			++pn;
		}
		;
relation_explist:
		AND relation_exp relation_explist {
			int r = predicate_stack.top();
			predicate_stack.pop();
			int l = predicate_stack.top();
			predicate_stack.pop();
			code << "\t&& p" << pn << ", p" << l << ", p" << r << endl;
			predicate_stack.push(pn);
			++pn;
		}
		| OR relation_exp relation_explist {
			int r = predicate_stack.top();
			predicate_stack.pop();
			int l = predicate_stack.top();
			predicate_stack.pop();
			code << "\t|| p" << pn << ", p" << l << ", p" << r << endl;
			predicate_stack.push(pn);
			++pn;
		}
		|
		;


relation_exp:
		relation_exp1
		| relation_exp2
		| relation_exp3
		;
relation_exp1:
		expression comp expression {
			string r = var_stack.top();
			if(index_stack.top() != "-1") {
				std::stringstream out;
				out << tn;
				code << "\t=[] t" << tn << ", " << r << ", " << index_stack.top() << endl;
				r = "t"+out.str();
				++tn;
			}
			var_stack.pop();
			index_stack.pop();
			string l = var_stack.top();
			if(index_stack.top() != "-1") {
				std::stringstream out;
				out << tn;
				code << "\t=[] t" << tn << ", " << l << ", " << index_stack.top() << endl;
				l = "t"+out.str();
				++tn;
			}
			var_stack.pop();
			index_stack.pop();
			string sign = comp_stack.top();
			comp_stack.pop();
			code << "\t" << sign << " p" << pn << ", " << l << ", " << r << endl;
			predicate_stack.push(pn);
			++pn;
		}	
		| NOT expression comp expression {
			string r = var_stack.top();
			if(index_stack.top() != "-1") {
				std::stringstream out;
				out << tn;
				code << "\t=[] t" << tn << ", " << r << ", " << index_stack.top() << endl;
				r = "t"+out.str();
				++tn;
			}
			var_stack.pop();
			index_stack.pop();
			string l = var_stack.top();
			if(index_stack.top() != "-1") {
				std::stringstream out;
				out << tn;
				code << "\t=[] t" << tn << ", " << l << ", " << index_stack.top() << endl;
				l = "t"+out.str();
				++tn;
			}
			var_stack.pop();
			index_stack.pop();
			string sign = comp_stack.top();
			comp_stack.pop();
			code << "\t" << sign << " p" << pn << ", " << l << ", " << r << endl;
			++pn;
			code << "\t== p" << pn << ", p" << pn-1 << ", 0" << endl;
			predicate_stack.push(pn);
			++pn;
		}	
		;
relation_exp2:
		TRUE {
			code << "\t== p" << pn << ", 1, 1" << endl;
			predicate_stack.push(pn);
			++pn;
		}
		| NOT TRUE {
			code << "\t== p" << pn << ", 1, 0" << endl;
			predicate_stack.push(pn);
			++pn;
		}
		| NOT error
		;
relation_exp3:
		FALSE {
			code << "\t== p" << pn << ", 1, 0" << endl;
			predicate_stack.push(pn);
			++pn;
		}
		| NOT FALSE {
			code << "\t== p" << pn << ", 1, 1" << endl;
			predicate_stack.push(pn);
			++pn;
		}
		;


comp:
		EQ {
			comp_stack.push("==");	
		}	
		| NEQ {
			comp_stack.push("!=");	
		}	
		| LT {
			comp_stack.push("<");	
		}	
		| GT {
			comp_stack.push(">");	
		}	
		| LTE {
			comp_stack.push("<=");	
		}	
		| GTE {
			comp_stack.push(">=");	
		}
		;


expression:
		term termlist {
		}
		;
termlist:
		ADD term termlist {
				string r = var_stack.top();
				if(index_stack.top() != "-1") {
					std::stringstream out;
					out << tn;
					code << "\t=[] t" << tn << ", " << r << ", " << index_stack.top() << endl;
					r = "t"+out.str();
					++tn;
				}
				var_stack.pop();
				index_stack.pop();
				string l = var_stack.top();
				if(index_stack.top() != "-1") {
					std::stringstream out;
					out << tn;
					code << "\t=[] t" << tn << ", " << l << ", " << index_stack.top() << endl;
					l = "t"+out.str();
					++tn;
				}
				var_stack.pop();
				index_stack.pop();
				code <<  "\t+ t" << tn << ", " << l << ", " << r << endl;
				std::stringstream out;
				out << tn;
				var_stack.push("t"+out.str());
				index_stack.push("-1");
				++tn;
		}
		| SUB term termlist {
				string r = var_stack.top();
				if(index_stack.top() != "-1") {
					std::stringstream out;
					out << tn;
					code << "\t=[] t" << tn << ", " << r << ", " << index_stack.top() << endl;
					r = "t"+out.str();
					++tn;
				}
				var_stack.pop();
				index_stack.pop();
				string l = var_stack.top();
				if(index_stack.top() != "-1") {
					std::stringstream out;
					out << tn;
					code << "\t=[] t" << tn << ", " << l << ", " << index_stack.top() << endl;
					l = "t"+out.str();
					++tn;
				}
				var_stack.pop();
				index_stack.pop();
				code <<  "\t- t" << tn << ", " << l << ", " << r << endl;
				std::stringstream out;
				out << tn;
				var_stack.push("t"+out.str());
				index_stack.push("-1");
				++tn;
		}
		|
		;


term:
		factor factorlist
		;
factorlist:
		MULT factor factorlist {
				string r = var_stack.top();
				if(index_stack.top() != "-1") {
					std::stringstream out;
					out << tn;
					code << "\t=[] t" << tn << ", " << r << ", " << index_stack.top() << endl;
					r = "t"+out.str();
					++tn;
				}
				var_stack.pop();
				index_stack.pop();
				string l = var_stack.top();
				if(index_stack.top() != "-1") {
					std::stringstream out;
					out << tn;
					code << "\t=[] t" << tn << ", " << l << ", " << index_stack.top() << endl;
					l = "t"+out.str();
					++tn;
				}
				var_stack.pop();
				index_stack.pop();
				code <<  "\t* t" << tn << ", " << l << ", " << r << endl;
				std::stringstream out;
				out << tn;
				var_stack.push("t"+out.str());
				index_stack.push("-1");
				++tn;
		}
		| DIV factor factorlist {
				string r = var_stack.top();
				if(index_stack.top() != "-1") {
					std::stringstream out;
					out << tn;
					code << "\t=[] t" << tn << ", " << r << ", " << index_stack.top() << endl;
					r = "t"+out.str();
					++tn;
				}
				var_stack.pop();
				index_stack.pop();
				string l = var_stack.top();
				if(index_stack.top() != "-1") {
					std::stringstream out;
					out << tn;
					code << "\t=[] t" << tn << ", " << l << ", " << index_stack.top() << endl;
					l = "t"+out.str();
					++tn;
				}
				var_stack.pop();
				index_stack.pop();
				code <<  "\t/ t" << tn << ", " << l << ", " << r << endl;
				std::stringstream out;
				out << tn;
				var_stack.push("t"+out.str());
				index_stack.push("-1");
				++tn;
		}
		|
		;


factor:
		var
		| SUB var {
			string r = var_stack.top();
			if(index_stack.top() != "-1") {
				std::stringstream out;
				out << tn;
				code << "\t=[] t" << tn << ", " << r << ", " << index_stack.top() << endl;
				r = "t"+out.str();
				++tn;
			}
			var_stack.pop();
			code << "\t- t" << tn << ", 0, " << r << endl;
			std::stringstream out;
			out << tn;
			var_stack.push("t"+out.str());
			index_stack.push("-1");
			++tn;
		}
		| NUMBER {
			var_stack.push(string($1));
			index_stack.push("-1");
		}
		| SUB fNUMBER
		| SUB error
		| L_PAREN expression R_PAREN
		| L_PAREN expression error
		| SUB L_PAREN expression R_PAREN {
			string r = var_stack.top();
			var_stack.pop();
			code << "\t- t" << tn << ", 0, " << r << endl;
			std::stringstream out;
			out << tn;
			var_stack.push("t"+out.str());
			index_stack.push("-1");
			++tn;
		}
		| SUB L_PAREN expression error
		;
fNUMBER:
		NUMBER {
			code << "\t- t" << tn << ", 0, " << string($1) << endl;
			std::stringstream out;
			out << tn;
			var_stack.push("t"+out.str());
			index_stack.push("-1");
			++tn;
		}
		;


var:
		vIDENT {
			map<string, int>::iterator it;
			it = declarations.find(var_stack.top());
			if(it != declarations.end()) {
				if( (*it).second != -1) {
					string msg = "Error: array "+(var_stack.top()).substr(1, var_stack.top().length()-1)+" requires an index";
					yyerror(msg.c_str());
				}
			}
			index_stack.push("-1");
		}	
		| vIDENT vL_SQUARE expression R_SQUARE {
			index_stack.pop();
			index_stack.push(var_stack.top());
			var_stack.pop();
		}
		;
vL_SQUARE:
		L_SQUARE {
			map<string, int>::iterator it;
			it = declarations.find(var_stack.top());
			if(it != declarations.end()) {
				if( (*it).second == -1) {
					string msg = "Error: variable "+(var_stack.top()).substr(1, var_stack.top().length()-1)+" does not require an index";
					yyerror(msg.c_str());
				}
			}
		}
		;
			
vIDENT:
		IDENT {
			if(declarations.find("_"+string($1)) == declarations.end()) {
				string msg = "Error: "+string($1)+" was not declared";
				yyerror(msg.c_str());
			}
			else if(string($1) == "program" ||
					string($1) == "endprogram" ||
					string($1) == "integer" ||
					string($1) == "array" ||
					string($1) == "of" ||
					string($1) == "if" ||
					string($1) == "then" ||
					string($1) == "else" ||
					string($1) == "endif" ||
					string($1) == "while" ||
					string($1) == "loop" ||
					string($1) == "endloop" ||
					string($1) == "read" ||
					string($1) == "write" ||
					string($1) == "and" ||
					string($1) == "or" ||
					string($1) == "not" ||
					string($1) == "true" ||
					string($1) == "false") {
				string msg = "Error: "+string($1)+" is a keyword";
				yyerror(msg.c_str());
			}
			var_stack.push("_"+string($1));
		}
		;
%%


int yyerror(const char *msg) {
	printf("** Line %d, position %d: %s\n", line, column, msg);
	isError = true;
}
