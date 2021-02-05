%{
	#include "global.h"
	#include <cmath>

	void yyerror(char const *s);

	data_type temp_data_type;
	array_info temp_array_info;
	
	string callable_type;
	
	bool code_buffering = false;
	string callable_output_buffer = "";
	int symtable_pointer = -1;
	int callable_offset_top = 0;

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

program  : KW_PROGRAM ID '(' identifier_list ')' ';' { 
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
			symtable[*it].is_local = ( symtable_pointer >= 0 );
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
		if ((symtable[$3].dtype != data_type::INTEGER) || (symtable[$6].dtype != data_type::INTEGER)) error("Array range must be defined using integers.");
		if (stoi(symtable[$3].name) > stoi(symtable[$6].name)) error("Array start index cannot be lower than end index");

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

subprogram_declaration : {
		symtable_pointer = symtable.size();
 	} 
 	subprogram_head {
		 code_buffering = true;
	}
	declarations
	compound_statement {
		code_buffering = false;

		int enter_bytes = 0;
		if (callable_offset_top < 0) 
		{
			enter_bytes = std::abs(callable_offset_top);
		}
		int enter_pos = get_number(to_string(enter_bytes), data_type::INTEGER);
		gencode(string("enter"), enter_pos);
		cout<<callable_output_buffer;//buffered statements from compound statement
		gencode(string("leave"));
		gencode(string("return"));

		dump(symtable_pointer);
		symtable.erase(symtable.begin() + symtable_pointer + 1, symtable.end());
		symtable_pointer = -1;
		callable_output_buffer = "";
	}
	;

subprogram_head : KW_FUNCTION {
		callable_offset_top = 12;//oldBP at [0;4], retaddr at [4;8], fn_result_ptr at [12;16] regardless of type since its pointer
	}
	ID arguments ':' standard_type ';' {
		int return_pos = insert_tempvar(true);
		symtable[return_pos].name = symtable[$3].name;
		symtable[return_pos].is_local = true;
		allocate(return_pos, static_cast<data_type>($6), true);

		int retaddr_pos = insert_tempvar(true);
		symtable[retaddr_pos].name = "retaddr";
		symtable[retaddr_pos].is_local = true;
		allocate(retaddr_pos, data_type::INTEGER, true);

		int oldbp_pos = insert_tempvar(true);
		symtable[oldbp_pos].name = "old BP";
		symtable[oldbp_pos].is_local = true;
		allocate(oldbp_pos, data_type::INTEGER, true);

		print_label($3);
		symtable[$3].type = entry_type::FUNCTION;
		symtable[$3].dtype = static_cast<data_type>($6);
	}
	| KW_PROCEDURE {
		callable_offset_top = 8;
	}
	ID arguments ';' {
		int retaddr_pos = insert_tempvar(true);
		symtable[retaddr_pos].name = string("retaddr");
		symtable[retaddr_pos].is_local = true;
		allocate(retaddr_pos, data_type::INTEGER, true);

		int oldbp_pos = insert_tempvar(true);
		symtable[oldbp_pos].name = string("old BP");
		symtable[oldbp_pos].is_local = true;
		allocate(oldbp_pos, data_type::INTEGER, true);
		
		print_label($3);
		symtable[$3].type = entry_type::PROCEDURE;
	}
	;

arguments : '(' parameter_list ')' {
		callable_offset_top += list_of_params.size() * 4;
		for (list<int>::iterator it = list_of_params.begin(); it != list_of_params.end(); ++it)
		{
			allocate(*it, symtable[*it].dtype, true);
			if (symtable[*it].type == entry_type::ARRAY)
			{
				symtable[$0].argtypes.emplace_back(static_cast<int>(symtable[*it].type));//put "array", doesn't mean what dtype, they aren't convertable
			}
			else
			{
				symtable[$0].argtypes.emplace_back(static_cast<int>(symtable[*it].dtype));
			}
		}
		list_of_params.clear();
	}
	| %empty
	;

parameter_list : identifier_list ':' type {
		entry_type etype = ( $3 == T_ARRAY ) ? entry_type::ARRAY : entry_type::VARIABLE;
		data_type dtype = ( $3 == T_ARRAY ) ? temp_data_type : static_cast<data_type>($3);

		for (list<int>::iterator it = list_of_ids.begin(); it != list_of_ids.end(); ++it)
		{
			symtable[*it].is_local = true;
			symtable[*it].type = etype;
			symtable[*it].dtype = dtype;
			symtable[*it].ainfo = temp_array_info;
		}

		list_of_params.splice(list_of_params.end(), list_of_ids);
		list_of_ids.clear();
	}
	| parameter_list ';' identifier_list ':' type {
		entry_type etype = ( $5 == T_ARRAY ) ? entry_type::ARRAY : entry_type::VARIABLE;
		data_type dtype = ( $5 == T_ARRAY ) ? temp_data_type : static_cast<data_type>($5);

		for (list<int>::iterator it = list_of_ids.begin(); it != list_of_ids.end(); ++it)
		{
			symtable[*it].is_local = true;
			symtable[*it].type = etype;
			symtable[*it].dtype = dtype;
			symtable[*it].ainfo = temp_array_info;
		}

		list_of_params.splice(list_of_params.end(), list_of_ids);
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
		int pos = promote_assign(symtable[$1].dtype, $3, symtable_pointer >= 0);
		gencode(string("mov"), pos, $1);
	}
	| procedure_statement
	| compound_statement
	| KW_IF expression {
		int zero_pos = get_number(string("0"), data_type::INTEGER);
		int else_pos = insert_label(symtable_pointer >= 0);
		gencode(string("jne"), zero_pos, $2, else_pos);
		$1 = else_pos;
	} KW_THEN statement {
		int endif_pos = insert_label(symtable_pointer >= 0);
		gencode(string("jump"), endif_pos);
		print_label($1);
		$4 = endif_pos;
	} KW_ELSE statement {
		print_label($4);
	}
	| KW_WHILE {
		int loop_start_pos = insert_label(symtable_pointer >= 0);
		print_label(loop_start_pos);
		$1 = loop_start_pos;
	} expression {
		int after_loop_pos = insert_label(symtable_pointer >= 0);
		int zero_pos = get_number(string("0"), data_type::INTEGER);
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
			//TODO:error, only integer indices
			// plus not an array error etc.
		}
		int start_index_pos = get_number(to_string(symtable[$1].ainfo.start_index), data_type::INTEGER);
		int array_index_pos = insert_tempvar(symtable_pointer >= 0);
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

		int arr_el_ptr_pos = insert_tempvar(symtable_pointer >= 0); 
		allocate(arr_el_ptr_pos, symtable[$1].dtype, true);
		gencode(string("add"), array_index_pos, $1, arr_el_ptr_pos, false, true, true);
	 	$$ = arr_el_ptr_pos;
	 }
	;

procedure_statement : ID {
		callable_type = "Procedure ";
		//TODO: args expected for read/write
		if (symtable[$1].argtypes.size() > 0) error (callable_type + symtable[$1].name + " called without arguments, while " + to_string(symtable[$1].argtypes.size()) + " arguments expected");
		emit_procedure($1, list_of_expressions);
		list_of_expressions.clear();
 	}
	| ID '(' expression_list ')' {
		callable_type = "Procedure ";
		if (((symtable[$1].name) != "read") && ((symtable[$1].name) != "write") && (symtable[$1].argtypes.size() != list_of_expressions.size()))
		{
			error (callable_type + symtable[$1].name + " called with " + to_string(list_of_expressions.size()) + " arguments, while " + to_string(symtable[$1].argtypes.size()) + " arguments expected");
		}
		list<int>::iterator it1 = symtable[$1].argtypes.begin();
		list<int>::iterator it2 = list_of_expressions.begin();
		int argcounter = 1;
		//convert types and NUMs to VARs before call
		for (; it1 != symtable[$1].argtypes.end(); ++it1, ++it2)
		{
			bool expected_array = ( static_cast<entry_type>(*it1) == entry_type::ARRAY );
			bool passed_array = ( symtable[*it2].type == entry_type::ARRAY );
			//TODO: wrong dtype on array error
			data_type expected_dtype = static_cast<data_type>(*it1);

			if (passed_array != expected_array) {
				string err_msg = callable_type + symtable[$1].name + ", passed argument " + to_string(argcounter) + " is ";
				if (!passed_array) err_msg += "not ";
				err_msg += "an array, while ";
				if (!expected_array) err_msg += "not ";
				err_msg += "an array was expected.";
				error(err_msg); 
			}

			if (expected_dtype != symtable[*it2].dtype )
			{
				int promoted_pos = promote_assign(expected_dtype, *it2, symtable_pointer >= 0);
				it2 = list_of_expressions.erase(it2);//erase method returns iterator of previous element
				it2 = list_of_expressions.insert(it2, promoted_pos);
			}
			else if (symtable[*it2].type == entry_type::NUMBER)
			{
				int fn_num_arg_pos = insert_tempvar(symtable_pointer >= 0);
				allocate(fn_num_arg_pos, expected_dtype);
				gencode("mov", *it2, fn_num_arg_pos);
				it2 = list_of_expressions.erase(it2);//erase returns iterator of previous element
				it2 = list_of_expressions.insert(it2, fn_num_arg_pos);
			}
			argcounter++;
		}

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
		int relop_out_pos = insert_tempvar(symtable_pointer >= 0);
		allocate(relop_out_pos, data_type::INTEGER);

		int one_pos = get_number(string("1"), data_type::INTEGER);
		gencode(string("mov"), one_pos, relop_out_pos);

		int skip_false_pos = insert_label();
		tuple<int,int> operands_pos = promote($1, $3, symtable_pointer >= 0);
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
			int temp_pos = insert_tempvar(symtable_pointer >= 0);
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
		tuple<int,int> operands_pos = promote($1, $3, symtable_pointer >= 0);
		int temp_pos = insert_tempvar(symtable_pointer >= 0);
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
		tuple<int,int> operands_pos = promote($1, $3, symtable_pointer >= 0);
		int temp_pos = insert_tempvar(symtable_pointer >= 0);
		allocate(temp_pos, data_type::INTEGER);//TODO:convert to int operands
		gencode("or", std::get<0>(operands_pos), std::get<1>(operands_pos), temp_pos);
		$$ = temp_pos;
	}
	;
	
term : factor
	| term MULOP factor {
		tuple<int,int> operands_pos = promote($1, $3, symtable_pointer >= 0);
		data_type op_result_dtype = symtable[std::get<0>(operands_pos)].dtype;

		string command;
		switch (optable[$2].shortcut)
		{
			case 1: command = "mul";
				break;
			case 2: command = "div";
				break;
			case 3: command = "div";//TODO:conversion to int
				break;
			case 4: command = "mod";
				break;
			default: command = "and";
				op_result_dtype = data_type::INTEGER;//TODO:conversion to int
		}

		int temp_pos = insert_tempvar(symtable_pointer >= 0);
		allocate(temp_pos, op_result_dtype);

		gencode(command, std::get<0>(operands_pos), std::get<1>(operands_pos), temp_pos);
		$$ = temp_pos;
	}
	;

factor : variable {
		$$ = $1;//left to be explicit this time
		if (symtable[$1].type == entry_type::FUNCTION)
		{
			callable_type = "Function ";
			if (symtable[$1].argtypes.size() > 0) error (callable_type + symtable[$1].name + " called without arguments, while " + to_string(symtable[$1].argtypes.size()) + " arguments expected");
			int fn_result_pos = insert_tempvar(symtable_pointer >= 0);
			allocate(fn_result_pos, symtable[$1].dtype);
			list_of_expressions.emplace_back(fn_result_pos);
			emit_procedure($1, list_of_expressions);
			list_of_expressions.clear();
			$$ = fn_result_pos;
		}
 	}
	| ID '(' expression_list ')' {
		callable_type = "Function ";
		int fn_pos = $1;
		if (symtable[fn_pos].type != entry_type::FUNCTION)
		{
			fn_pos = lookup(symtable[fn_pos].name, true);
		}
		if (fn_pos == 0)
		{
			error(callable_type + " declaration of " + symtable[$1].name + " not found. Are you sure you declared it?");
		}

		string callable_type = "Function ";
		if (symtable[$1].argtypes.size() != list_of_expressions.size())	error (callable_type + symtable[$1].name + " called with " + to_string(list_of_expressions.size()) + " arguments, while " + to_string(symtable[$1].argtypes.size()) + " arguments expected");
		list<int>::iterator it1 = symtable[fn_pos].argtypes.begin();
		list<int>::iterator it2 = list_of_expressions.begin();
		int argcounter = 1;
		//convert types and NUMs to VARs before call
		for (; it1 != symtable[fn_pos].argtypes.end(); ++it1, ++it2)
		{
			bool expected_array = ( static_cast<entry_type>(*it1) == entry_type::ARRAY );
			bool passed_array = ( symtable[*it2].type == entry_type::ARRAY );
			//TODO: wrong dtype on array error
			data_type expected_dtype = static_cast<data_type>(*it1);

			if (passed_array != expected_array) {
				string err_msg = callable_type + symtable[$1].name + ", passed argument " + to_string(argcounter) + " is ";
				if (!passed_array) err_msg += "not ";
				err_msg += "an array, while ";
				if (!expected_array) err_msg += "not ";
				err_msg += "an array was expected.";
				error(err_msg); 
			}
			if (expected_dtype != symtable[*it2].dtype )
			{
				int promoted_pos = promote_assign(expected_dtype, *it2, symtable_pointer >= 0);
				it2 = list_of_expressions.erase(it2);//erase method returns iterator of previous element
				it2 = list_of_expressions.insert(it2, promoted_pos);
			}
			else if (symtable[*it2].type == entry_type::NUMBER)
			{
				int fn_num_arg_pos = insert_tempvar(symtable_pointer >= 0);
				allocate(fn_num_arg_pos, expected_dtype);
				gencode("mov", *it2, fn_num_arg_pos);
				it2 = list_of_expressions.erase(it2);//erase returns iterator of previous element
				it2 = list_of_expressions.insert(it2, fn_num_arg_pos);
			}
			argcounter++;
		}

		int fn_result_pos = insert_tempvar(symtable_pointer >= 0);
		allocate(fn_result_pos, symtable[fn_pos].dtype);
		list_of_expressions.emplace_back(fn_result_pos);
		emit_procedure(fn_pos, list_of_expressions);
		list_of_expressions.clear();
		$$ = fn_result_pos;
	}
	| NUM
	| '(' expression ')' {
		$$ = $2;
	}
	| NOT factor {
		int negated_pos = insert_tempvar(symtable_pointer >= 0);
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
			cout<<"Parsing successful!"<<endl;
			break;
		case 1:
			cout<<"Parsing failed! Syntax error. Line:"<<lineno<<endl;
			break;
		case 2:
			cout<<"Parsing failed! Out of memory."<<endl;
	}
}

void yyerror(char const *s){
	fprintf (stderr, "%s\n", s);
}