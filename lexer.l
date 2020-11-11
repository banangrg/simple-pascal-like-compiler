%{
	/* definitions of manifest constants */
	#include "global.h"
	char lexbuf[BSIZE];
	int lineno = 1;
	int tokenval = NONE;

	int install_id();
	int install_num();
	int everything_else();
%}

/* regular definitions */
delim       [ \t]
ws          {delim}+
letter      [A-Za-z]
digit       [0-9]
id          {letter}({letter}|{digit})*
number      {digit}+


%%
\n          	{lineno++;}
{ws}        	{/* no action and no return */}
{id}        	{return install_id();}
{number}    	{return install_num();}
<<EOF>>			{return DONE;}
.				{return everything_else();}
%%

int install_id() {
	/* procedure to install the lexeme, whose first character is pointed by yytext
	and whose length is yyleng, into the symbol table and return a pointer thereto */

	int pos = lookup (yytext);
	if (pos == 0) 
	{
		pos = insert (yytext, ID);
	}
	tokenval = pos;
	return symtable[pos].token;
}

int install_num() {
	/* similar procedure to install a lexeme that is a number */
	sscanf(yytext, "%d", &tokenval);
	return NUM;
}

int everything_else() {
	tokenval = NONE;
	return yytext[0];
}

int lexan()
{
	return yylex();
}