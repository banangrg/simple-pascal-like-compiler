%{
	#include "global.h"

	void yyerror(char const *s);

	list<int> list_of_ids;
	list<int> list_of_expressions;
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

program : KW_PROGRAM ID '(' identifier_list ')' ';' { 
		symtable[$2].type = entry_type::PROGRAM_NAME;
		list_of_ids.clear(); 
	}
	declarations
	subprogram_declarations
	compound_statement
	'.' { 
			cout<<"exit"<<endl;
			dump();
		}
	;
identifier_list : ID { list_of_ids.emplace_back($1); }
	| identifier_list ',' ID { list_of_ids.emplace_back($3); }
	;

declarations : declarations KW_VAR identifier_list ':' type ';' {
		for (list<int>::iterator it = list_of_ids.begin(); it != list_of_ids.end(); ++it)
		{
			data_type dtype = static_cast<data_type>($5);
			symtable[*it].type = entry_type::VARIABLE;
			allocate(*it, dtype);
		}
		list_of_ids.clear();
	}
	| %empty
	;

type : standard_type
	| KW_ARRAY '[' NUM '.''.' NUM ']' KW_OF standard_type { /*array as type, dtype as inner info*/ }
	;

standard_type : T_INTEGER { $$ = static_cast<int>(data_type::INTEGER); }
	| T_REAL { $$ = static_cast<int>(data_type::REAL); }
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

compound_statement : { /* printf("S cm_stmt\n "); */ } KW_BEGIN optional_statements KW_END { /* printf("F cm_stmt\n "); */ }
	;

optional_statements : { /* printf("S opt_stmt1\n "); */ } statement_list { /* printf("F opt_stmt1\n "); */ }
	| %empty { /* printf("S+F opt_stmt2\n "); */ }
	;

statement_list : { /* printf("S stmt_list1\n "); */ } statement { /* printf("F stmt_list1\n "); */ }
	| statement_list ';' { /* printf("M stmt_list2\n "); */ } statement { /* printf("F stmt_list2\n "); */ }
	;

statement : variable ASSIGNOP expression { 
		int pos = promote_assign(symtable[$1].dtype, $3);
		gencode(string("mov"), 2, $3, $1);
	}
	| procedure_statement
	| compound_statement
	| KW_IF expression KW_THEN statement KW_ELSE statement
	| KW_WHILE expression KW_DO statement
	;

variable : ID { /* printf("F variable1\n "); */ }
	| ID '[' expression ']' { /* printf("F variable2\n "); */ }
	;

procedure_statement : ID { /* printf("F proc_stmt1\n "); */ }
	| ID '(' expression_list ')' { 
		emit_procedure($1, list_of_expressions);
		list_of_expressions.clear();
	}
	;

expression_list : expression { list_of_expressions.emplace_back($1); }
	| expression_list ',' expression { list_of_expressions.emplace_back($3); }
	;

expression : simple_expression 
	| simple_expression RELOP simple_expression
	;

simple_expression : term { /* cout<<"TERM -> $1 ADDR OF "<<$1<<"="<<symtable[$1].value<<endl; */ }
	| SIGN term { /* cout<<"STERM -> $$="<<$$<<",$2="<<$2<<endl; */ }
	| simple_expression SIGN term { 
		tuple<int,int> operands_pos = promote($1, $3);
		int temp_pos = insert_temp();
		symtable[temp_pos].type = entry_type::VARIABLE;
		allocate(temp_pos, data_type::INTEGER);
		gencode(string("add"), 3, std::get<0>(operands_pos), std::get<1>(operands_pos), temp_pos);
		$$ = temp_pos;
	}
	| simple_expression OR term
	;
	
term : factor
	| term MULOP factor
	;

factor : variable { /* cout<<"VAR $1 ADDR OF "<<$1<<"="<<symtable[$1].value<<endl; */ }
	| ID '(' expression_list ')'
	| NUM { /* cout<<"NUM VALUE "<<symtable[$1].value<<endl;*/ }
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