%{
	/* definitions of manifest constants */
	#include "global.h"
	#include "parser.hpp"
	char lexbuf[BSIZE];
	int lineno = 1;
	int tokenval = NONE;

	int install_id();
	int install_num(data_type dtype);
	int everything_else();
%}

%option noyywrap

/* regular definitions, consider e notation for number */
delim       [ \t]
ws          {delim}+
letter      [A-Za-z]
digit       [0-9]
id          {letter}({letter}|{digit})*
number      {digit}+
fnumber     {digit}+([.]{digit}+)?
relop		<>|<=|>=|=|<|>

%%
\n          	{lineno++;}
{ws}        	{/* no action and no return */}
":="			{return ASSIGNOP;}
{relop}			{yylval = lookup_op(string(yytext)); return RELOP;}
"+"				{yylval = lookup_op(string(yytext)); return SIGN;}
"-"				{yylval = lookup_op(string(yytext)); return SIGN;}
"*"				{yylval = lookup_op(string(yytext)); return MULOP;}
"/"				{yylval = lookup_op(string(yytext)); return MULOP;}
(div)			{yylval = lookup_op(string(yytext)); return MULOP;}
(mod)			{yylval = lookup_op(string(yytext)); return MULOP;}
(and)			{yylval = lookup_op(string(yytext)); return MULOP;}
(or)			{return OR;}
(not)			{return NOT;}
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
{id}        	{return install_id();}
{number}    	{return install_num(data_type::INTEGER);}
{fnumber}    	{return install_num(data_type::REAL);}
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
	yylval = pos;
	return symtable[pos].token;
}

int install_num(data_type dtype) {
	/* similar procedure to install a lexeme that is a number */
	int pos = lookup (yytext);
	if (pos == 0) 
	{
		pos = insert (yytext, NUM);
		symtable[pos].type = entry_type::NUMBER;
		symtable[pos].dtype = dtype;
	}
	yylval = pos;
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