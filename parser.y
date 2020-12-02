%{
	#include "global.h"
	void yyerror(char const *s);
%}

%token NUM
%token DIV
%token MOD
%token ID

%%
list : expr ';' list
	| /* empty */
	;
expr : expr '+' term	{ emit('+', NONE); /* why not $2 */ }
	| expr '-' term		{ emit('-', NONE); }
	| term
	;
term : term '*' factor	{ emit('*', NONE); }
	| term '/' factor	{ emit('/', NONE); }
	| term DIV factor	{ emit(DIV, NONE); }
	| term MOD factor	{ emit(MOD, NONE); }
	| factor
	;
factor : '(' expr ')'
	| ID	{ emit(ID, yylval); }
	| NUM	{ emit(NUM, yylval); }
	;
%%
void parse(){
	int parsing_result = yyparse();
	switch (parsing_result) {
		case 0:
			printf("Parsing successful!");
			break;
		case 1:
			printf("Parsing failed! Syntax error.");
			break;
		case 2:
			printf("Parsing failed! Out of memory.");
	}
}

void yyerror(char const *s){
	fprintf (stderr, "%s\n", s);
}