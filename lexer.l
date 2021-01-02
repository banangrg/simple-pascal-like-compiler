%{
	/* definitions of manifest constants */
	#include "global.h"
	#include "parser.h"
	char lexbuf[BSIZE];
	int lineno = 1;
	int tokenval = NONE;

	int install_id();
	int install_num();
	int everything_else();
%}

/* regular definitions, consider e notation for number */
delim       [ \t]
ws          {delim}+
letter      [A-Za-z]
digit       [0-9]
id          {letter}({letter}|{digit})*
number      {digit}+([.]{digit}+)?
relop		<>|<=|>=|=|<|>

%%
\n          	{lineno++;}
{ws}        	{/* no action and no return */}
(program)		{return KW_PROGRAM;}
(var)			{return KW_VAR;}
(array)			{return KW_ARRAY;}
(of)			{return KW_OF;}
(function)		{return KW_FUNCTION;}
(procedure)		{return KW_PROCEDURE;}
(begin)			{return KW_BEGIN;}
(end)			{return KW_END;}
(if)			{return KW_IF;}
(then)			{return KW_THEN;}
(else)			{return KW_ELSE;}
(while)			{return KW_WHILE;}
(do)			{return KW_DO;}
(integer)		{return T_INTEGER;}
(real)			{return T_REAL;}
":="			{printf("ASSIGNOP\n"); return ASSIGNOP;}
"<>"			{printf("RELOP <>\n"); return RELOP;}
"<="			{printf("RELOP <=\n"); return RELOP;}
">="			{printf("RELOP >=\n"); return RELOP;}
"<"				{printf("RELOP <\n"); return RELOP;}
">"				{printf("RELOP >\n"); return RELOP;}
"="				{printf("RELOP =\n"); return RELOP;}
"+"				{printf("SIGN +\n"); return SIGN;}
"-"				{printf("SIGN -\n"); return SIGN;}
"*"				{printf("MULOP *\n"); return MULOP;}
"/"				{printf("MULOP *\n"); return MULOP;}
(div)			{printf("MULOP DIV\n"); return MULOP;}
(mod)			{printf("MULOP MOD\n"); return MULOP;}
(and)			{printf("MULOP AND\n"); return MULOP;}
(or)			{printf("OR\n"); return OR;}
{id}        	{printf("ID = %s\n",yytext); return install_id();}
{number}    	{printf("NUM\n"); return install_num();}
<<EOF>>			{return DONE;}
.				{ return everything_else(); }
%%

int install_id() {
	/* procedure to install the lexeme, whose first character is pointed by yytext
	and whose length is yyleng, into the symbol table and return a pointer thereto */

	int pos = lookup (yytext);
	if (pos == 0) 
	{
		pos = insert (yytext, ID);
	}
	yylval = pos;
	return symtable[pos].token;
}

int install_num() {
	/* similar procedure to install a lexeme that is a number */
	sscanf(yytext, "%d", &yylval);
	return NUM;
}

int everything_else() {
	yylval = NONE;
	return yytext[0];
}

int lexan()
{
	return yylex();
}