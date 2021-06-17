%{
	#include<stdio.h>
	#include "symbol_table.h"
	#include"syntactic_analyzer.tab.h"
	#define _BOOL_ 1
	#define _INT_ 2
	#define _LONG_ 3
	#define _FLOAT_ 4
	#define _DOUBLE_ 5
	#define _CHAR_ 6
	#define _STRING_ 7
%}

DIGIT [0-9]
LETTER [a-zA-Z]
SUFFIX (u|U|L|l)*

%%

 /* reserved words */
"set size"          { return SET; }
"smarttile"         { return SMARTTILE; }
"tile"              { return TILE; }
"section"           { return SECTION; }
"sasageyo"          { return MAIN; }
 /* "end"               { return END; } */
 /* "new"               { return NEW; } */
"join"              { return JOIN; }
"for"               { return FOR; }
"while"             { return WHILE; }
"if"                { return IF; }
"container"         { return CONTAINER; }
"int"               { yylval.INT -> type = _INT_; return INT; }
"char"              { yylval.CHAR -> type = _CHAR_; return CHAR; }
"string"            { yylval.STRING -> type = _STRING_; return STRING; }
"float"             { yylval.FLOAT -> type = _FLOAT_; return FLOAT; }
"bool"              { yylval.BOOL -> type  = _BOOL_; return BOOL; }
"double"            { yylval.DOUBLE -> type = _DOUBLE_; return DOUBLE;}
"long"              { yylval.LONG -> type = _LONG_; return LONG; }
"else"              { return ELSE;}
"RandomWalk"        { return ALGORITHM; }
"DirectionalTunnel" { return ALGORITHM; }
"rule"              { return RULE; }
"++"                { return PLUSPLUS; }
"--"                { return MINUSMINUS; }

 /* constans */
"true"|"false"                     { return CONST_BOOL; }
{DIGIT}+L                          { return CONST_LONG; }
{DIGIT}+                           { /*yylval.CONST_INT -> value._int = atoi(yytext);*/ return CONST_INT; }
{DIGIT}+"."{DIGIT}+D?          	   { yylval.CONST_DOUBLE -> value._double = atof(yytext); return CONST_DOUBLE; }
{DIGIT}+"."{DIGIT}+F               { return CONST_FLOAT; }
{LETTER}({LETTER}|{DIGIT}|[_\-$])* { 
		yylval.IDENTIFIER = (symrec*)malloc(sizeof(symrec));
		strcpy(yylval.IDENTIFIER -> name, yytext); 
		return IDENTIFIER; 
	}
\"(\\.|[^\\"])*\"                  { return CONST_STRING; }
'(\\.|[^\\"])*'                    { return CONST_CHAR; }

 /* operators */
"+"  { return '+'; }
"*"  { return '*'; }
"/"  { return '/'; }
"-"  { return '-'; }
"%"  { return '%'; }
"="  { return '='; }
"<"  { return GREATER; }
">"  { return LESS; }
">=" { return GREATER_EQ; }
"<=" { return LESS_EQ; }
"&&" { return AND_OP; }
"!"  { return '!'; }
"!=" { return NEQ; }
"||" { return OR_OP; }
";"  { return ';'; }
","  { return ','; }
"("  { return '('; }
")"  { return ')'; }
"{"  { return '{'; }
"}"  { return '}'; }
"["  { return '['; }
"]"  { return ']'; }
":"  { return ':'; }

.
"//"*
%%

