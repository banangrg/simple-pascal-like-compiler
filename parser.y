%{
	#include "global.h"
	void yyerror(char const *s);
%}
%define parse.error verbose

%token KW_PROGRAM
%token KW_VAR
%token KW_ARRAY
%token KW_OF
%token KW_FUNCTION
%token KW_PROCEDURE
%token KW_BEGIN
%token KW_END
%token KW_IF
%token KW_THEN
%token KW_ELSE
%token KW_WHILE
%token KW_DO


%token ASSIGNOP
%token RELOP
%token MULOP
%token SIGN
%token OR
%token NOT

%token NUM
%token ID

%token T_REAL
%token T_INTEGER

%%

program : KW_PROGRAM ID '(' identifier_list ')' ';'
	declarations
	subprogram_declarations
	compound_statement
	'.'
	;
identifier_list : ID
	| identifier_list ',' ID
	;

declarations : declarations KW_VAR identifier_list ':' type ';'
	| %empty
	;

type : standard_type
	| KW_ARRAY '[' NUM '.''.' NUM ']' KW_OF standard_type
	;

standard_type : T_INTEGER
	| T_REAL
	;

subprogram_declarations : subprogram_declarations subprogram_declaration ';'
	| %empty
	;

subprogram_declaration : subprogram_head declarations compound_statement
	;

subprogram_head : KW_FUNCTION ID arguments ':' standard_type ';'
	| KW_PROCEDURE ID arguments ';'
	;

arguments : '(' parameter_list ')'
	| %empty
	;

parameter_list : identifier_list ':' type
	| parameter_list ';' identifier_list ':' type
	;

compound_statement : { printf("S cm_stmt\n "); } KW_BEGIN optional_statements KW_END { printf("F cm_stmt\n "); }
	;

optional_statements : { printf("S opt_stmt1\n "); } statement_list { printf("F opt_stmt1\n "); }
	| %empty { printf("S+F opt_stmt2\n "); }
	;

statement_list : { printf("S stmt_list1\n "); } statement { printf("F stmt_list1\n "); }
	| statement_list ';' { printf("M stmt_list2\n "); } statement { printf("F stmt_list2\n "); }
	;

statement : variable ASSIGNOP expression
	| procedure_statement
	| compound_statement
	| KW_IF expression KW_THEN statement KW_ELSE statement
	| KW_WHILE expression KW_DO statement
	;

variable : ID { printf("F variable1\n "); }
	| ID '[' expression ']' { printf("F variable2\n "); }
	;

procedure_statement : ID { printf("F proc_stmt1\n "); }
	| ID '(' expression_list ')' { printf("F proc_stmt2\n "); }
	;

expression_list : expression
	| expression_list ',' expression
	;

expression : simple_expression 
	| simple_expression RELOP simple_expression
	;

simple_expression : term
	| SIGN term
	| simple_expression SIGN term
	| simple_expression OR term
	;
	
term : factor
	| term MULOP factor
	;

factor : variable
	| ID '(' expression_list ')'
	| NUM
	| '(' expression ')'
	| NOT factor
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