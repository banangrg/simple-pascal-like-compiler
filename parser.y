%{
	#include "global.h"

	void yyerror(char const *s);

	data_type temp_data_type;
	array_info temp_array_info;

	list<int> list_of_ids;
	list<int> list_of_params;
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
%token T_ARRAY
%%

program : KW_PROGRAM ID '(' identifier_list ')' ';' { 
		symtable[$2].type = entry_type::PROGRAM_NAME;
		list_of_ids.clear(); 
	}
	declarations {
		gencode("jump", $2);
	}
	subprogram_declarations {
		print_label($2);
	}
	compound_statement
	'.' { 
			gencode(string("exit"));
			dump();
		}
	;
identifier_list : ID { list_of_ids.emplace_back($1); }
	| identifier_list ',' ID { list_of_ids.emplace_back($3); }
	;

declarations : declarations KW_VAR identifier_list ':' type ';' {
		entry_type etype = ( $5 == T_ARRAY ) ? entry_type::ARRAY : entry_type::VARIABLE;
		data_type dtype = ( $5 == T_ARRAY ) ? temp_data_type : static_cast<data_type>($5);

		for (list<int>::iterator it = list_of_ids.begin(); it != list_of_ids.end(); ++it)
		{
			symtable[*it].type = etype;
			symtable[*it].ainfo = temp_array_info;
			allocate(*it, dtype);
		}
		list_of_ids.clear();
	}
	| %empty
	;

type : standard_type {
		temp_array_info = {};
	}
	| KW_ARRAY '[' NUM '.''.' NUM ']' KW_OF standard_type { 
		//TODO: error if not integer index or idx < 0;
		temp_data_type = static_cast<data_type>($9);
		temp_array_info.start_index = atoi(symtable[$3].name.c_str());
		temp_array_info.end_index = atoi(symtable[$6].name.c_str());
		temp_array_info.size = temp_array_info.end_index - temp_array_info.start_index;
		$$ = T_ARRAY;
	 }
	;

standard_type : T_INTEGER { $$ = static_cast<int>(data_type::INTEGER); }
	| T_REAL { $$ = static_cast<int>(data_type::REAL); }
	;

subprogram_declarations : subprogram_declarations subprogram_declaration ';'
	| %empty
	;

subprogram_declaration : subprogram_head declarations compound_statement
	;

subprogram_head : KW_FUNCTION ID arguments ':' standard_type ';' {
		print_label($2);
		symtable[$2].type = entry_type::FUNCTION;
	}
	| KW_PROCEDURE ID arguments ';' {
		print_label($2);
		symtable[$2].type = entry_type::PROCEDURE;
		vector<entry> newtable;
		//symtable[$2].inner_table = &newtable;
	}
	;

arguments : '(' parameter_list ')'
	| %empty
	;

parameter_list : identifier_list ':' type
	| parameter_list ';' identifier_list ':' type {
		list_of_params = list<int>(list_of_ids.begin(), list_of_ids.end());
		list_of_ids.clear();
	}
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
		gencode(string("mov"), $3, $1);
	}
	| procedure_statement
	| compound_statement
	| KW_IF expression {
		int zero_pos = get_number(string("0"), data_type::INTEGER);
		int else_pos = insert_label();
		gencode(string("jne"), zero_pos, $2, else_pos);
		$1 = else_pos;
	} KW_THEN statement {
		int endif_pos = insert_label();
		gencode(string("jump"), endif_pos);
		print_label($1);
		$4 = endif_pos;
	} KW_ELSE statement {
		print_label($4);
	}
	| KW_WHILE {
		int loop_start_pos = insert_label();
		print_label(loop_start_pos);
		$1 = loop_start_pos;
	} expression {
		int after_loop_pos = insert_label();
		int zero_pos = get_number(string("0"), data_type::INTEGER);//TODO: consider promotion then selection of data type
		gencode(string("jeq"), zero_pos, $3, after_loop_pos);
		$2 = after_loop_pos;
	} KW_DO statement {
		gencode(string("jump"), $1);
		print_label($2);
	}
	;

variable : ID { /* printf("F variable1\n "); */ }
	| ID '[' expression ']' {
		if (symtable[$3].dtype != data_type::INTEGER)
		{
			//error, only integer indices
			// plus not an array error etc.
		}
		int start_index_pos = get_number(to_string(symtable[$1].ainfo.start_index), data_type::INTEGER);
		int array_index_pos = insert_tempvar();
		allocate(array_index_pos, data_type::INTEGER);
		gencode(string("sub"), $3, start_index_pos, array_index_pos);

		int address_multiplier_pos;
		if (symtable[$1].dtype == data_type::INTEGER)
		{
			address_multiplier_pos = get_number(string("4"), data_type::INTEGER);
		}
		else
		{
			address_multiplier_pos = get_number(string("8"), data_type::INTEGER);
		}
		gencode(string("mul"), array_index_pos, address_multiplier_pos, array_index_pos);

		int arr_el_ptr_pos = insert_tempvar(); 
		allocate(arr_el_ptr_pos, symtable[$1].dtype, true);
		gencode(string("add"), array_index_pos, $1, arr_el_ptr_pos, false, true, true);
	 	$$ = arr_el_ptr_pos;
	 }
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
	| simple_expression RELOP simple_expression {
		string command;
		switch (optable[$2].shortcut)
		{
			case 1: command = "jne";
				break;
			case 2: command = "jle";
				break;
			case 3: command = "jge";
				break;
			case 4: command = "je";
				break;
			case 5: command = "jg";
				break;
			default: command = "jl";
				break;
		}
		int relop_out_pos = insert_tempvar();
		allocate(relop_out_pos, data_type::INTEGER);

		int one_pos = get_number(string("1"), data_type::INTEGER);
		gencode(string("mov"), one_pos, relop_out_pos);

		int skip_false_pos = insert_label();
		tuple<int,int> operands_pos = promote($1, $3);
		gencode(command, std::get<0>(operands_pos), std::get<1>(operands_pos), skip_false_pos);

		int zero_pos = get_number(string("0"), data_type::INTEGER);
		gencode(string("mov"), zero_pos, relop_out_pos);
		print_label(skip_false_pos);
		$$ = relop_out_pos;
	}
	;

simple_expression : term
	| SIGN term { 
		if (optable[$1].name == "sub")
		{
			int temp_pos = insert_tempvar();
			allocate(temp_pos, symtable[$2].dtype);
			string zero_number_name = "0";
			if (symtable[$2].dtype == data_type::REAL)
			{
				zero_number_name = "0.0";
			}
			int zero_pos = get_number(zero_number_name, symtable[$2].dtype);
			symtable[zero_pos].dtype = symtable[$2].dtype;
			gencode(string("sub"), zero_pos, $2);
		}
	}
	| simple_expression SIGN term { 
		tuple<int,int> operands_pos = promote($1, $3);
		int temp_pos = insert_tempvar();
		allocate(temp_pos, symtable[std::get<0>(operands_pos)].dtype);

		string command;
		switch (optable[$2].shortcut)
		{
			case 1: command = "add";
				break;
			default: command = "sub";
		}

		gencode(command, std::get<0>(operands_pos), std::get<1>(operands_pos), temp_pos);
		$$ = temp_pos;
	}
	| simple_expression OR term {
		tuple<int,int> operands_pos = promote($1, $3);
		int temp_pos = insert_tempvar();
		allocate(temp_pos, data_type::INTEGER);//TODO: consider if 'or' result will be always int?
		gencode("or", std::get<0>(operands_pos), std::get<1>(operands_pos), temp_pos);
		$$ = temp_pos;
	}
	;
	
term : factor
	| term MULOP factor {
		tuple<int,int> operands_pos = promote($1, $3);
		data_type op_result_dtype = symtable[std::get<0>(operands_pos)].dtype;

		string command;
		switch (optable[$2].shortcut)
		{
			case 1: command = "mul";
				break;
			case 2: command = "div";//TODO: a real div being '/', so what about 'div' operator?
				break;
			case 3: command = "div";
				break;
			case 4: command = "mod";
				break;
			default: command = "and";
				op_result_dtype = data_type::INTEGER;
		}

		int temp_pos = insert_tempvar();
		allocate(temp_pos, op_result_dtype);

		gencode(command, std::get<0>(operands_pos), std::get<1>(operands_pos), temp_pos);
		$$ = temp_pos;
	}
	;

factor : variable { /* cout<<"VAR $1 ADDR OF "<<$1<<"="<<symtable[$1].value<<endl; */ }
	| ID '(' expression_list ')'
	| NUM { /* cout<<"NUM VALUE "<<symtable[$1].value<<endl; */ }
	| '(' expression ')' {
		$$ = $2;
	}
	| NOT factor {
		int negated_pos = insert_tempvar();
		allocate(negated_pos, data_type::INTEGER);
		gencode(string("not"), $2, negated_pos);
		$$ = negated_pos;
	}
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