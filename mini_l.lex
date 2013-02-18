/*
name: Chris Rosario
sid: XXX-XX-9897
email: crosario@cs.ucr.edu
class: CS152 Compilers
title: Project 2 Parser Generation
*/

/* Lexical Specification for the MINI-L Language */
%{
	#include "heading.h"
	#include "y.tab.h"
	//int yyerror(char *s);
	int line = 1;
	int column = 1;
%}

%%
\/\/.*                                {column+=yyleng;}
(" "|[[:blank:]])	                    {column++;}
\n		 			                          {line++; column = 1;}

program				                        {column+=7; return PROGRAM;}
beginprogram		                      {column+=12; return BEGIN_PROGRAM;}
endprogram			                      {column+=10; return END_PROGRAM;}
integer				                        {column+=7; return INTEGER;}
array				                          {column+=5; return ARRAY;}
of					                          {column+=2; return OF;}
if					                          {column+=2; return IF;}
then				                          {column+=4; return THEN;}
endif				                          {column+=5; return ENDIF;}
else				                          {column+=4; return ELSE;}
while				                          {column+=5; return WHILE;}
loop				                          {column+=4; return LOOP;}
endloop				                        {column+=7; return ENDLOOP;}
read				                          {column+=4; return READ;}
write				                          {column+=5; return WRITE;}
and					                          {column+=3; return AND;}
or					                          {column+=2;	return OR;}
not					                          {column+=3; return NOT;}
true				                          {column+=4; return TRUE;}
false				                          {column+=5; return FALSE;}

\-					                          {column++; return SUB;}
\+					                          {column++; return ADD;}
\*					                          {column++; return MULT;}
\/					                          {column++; return DIV;}
	
\=					                          {column++; return EQ;}
\!\=				                          {column+=2; return NEQ;}
\<					                          {column++; return LT;}
\>					                          {column++; return GT;}
\<\=				                          {column+=2; return LTE;}
\>\=				                          {column+=2; return GTE;}
\?					                          {column++; return QUESTION;}
	
\;					                          {column++; return SEMICOLON;}
\:					                          {column++; return COLON;}
\,					                          {column++; return COMMA;}
\(					                          {column++; return L_PAREN;}
\)					                          {column++; return R_PAREN;}
"["					                          {column++; return L_SQUARE;}
\]					                          {column++; return R_SQUARE;}
\:\=				                          {column++; return ASSIGN;}

##.*$                                 {}

([0-9])+			                        {column+=yyleng; yylval.nval = yytext; return NUMBER;}
([[:digit:]]|\_)([[:alnum:]]|\_)*	    printf("Error at line %d, column %d: identifier \"%s\" must begin with a letter\n",line,column,yytext); column+=yyleng; exit(0);
([[:alnum:]]|\_)*\_		                printf("Error at line %d, column %d: identifier \"%s\" cannot end with an underscore\n",line,column,yytext); column+=yyleng; exit(0);
[[:alpha:]]([[:alnum:]]|\_)*	        {column+=yyleng; yylval.idval = yytext; return IDENT;}

.			                                printf("Error at line %d, column %d: unrecognized symbol \"%s\"\n",line,column,yytext); column++; exit(0);
